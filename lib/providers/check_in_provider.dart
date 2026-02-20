import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/models.dart';
import '../services/services.dart';

/// States for the check-in process.
enum CheckInState {
  idle,
  scanning,
  validatingLocation,
  processing,
  success,
  error,
}

/// Types of errors that can occur during check-in.
enum CheckInErrorType {
  invalidQRCode, // "QR Code Inválido"
  invalidLocation, // "Localização Incorreta"
  noConnection, // "Sem Conexão"
  permissionDenied,
  unknown,
}

/// Provider responsible for managing the check-in process.
/// Uses Firestore for persistent storage with real-time sync.
class CheckInProvider extends ChangeNotifier {
  final LocationService _locationService;
  final ConnectivityService _connectivityService;
  final StorageService _storageService;
  final FirebaseService _firebaseService;
  StreamSubscription<List<CheckIn>>? _checkInsSubscription;
  String? _currentUserId;

  CheckInState _state = CheckInState.idle;
  CheckInErrorType? _errorType;
  String? _errorMessage;
  Event? _currentEvent;
  Position? _currentPosition;
  double? _distanceToEvent;
  List<CheckIn> _checkInHistory = [];

  CheckInProvider({
    LocationService? locationService,
    ConnectivityService? connectivityService,
    StorageService? storageService,
    FirebaseService? firebaseService,
  }) : _locationService = locationService ?? LocationService(),
       _connectivityService = connectivityService ?? ConnectivityService(),
       _storageService = storageService ?? StorageService(),
       _firebaseService = firebaseService ?? FirebaseService();

  // Getters
  CheckInState get state => _state;
  CheckInErrorType? get errorType => _errorType;
  String? get errorMessage => _errorMessage;
  Event? get currentEvent => _currentEvent;
  Position? get currentPosition => _currentPosition;
  double? get distanceToEvent => _distanceToEvent;
  List<CheckIn> get checkInHistory => List.unmodifiable(_checkInHistory);

  bool get isProcessing =>
      _state == CheckInState.scanning ||
      _state == CheckInState.validatingLocation ||
      _state == CheckInState.processing;

  /// Initializes the provider with user ID for Firestore queries.
  Future<void> init({String? userId}) async {
    await _storageService.init();
    _currentUserId = userId;

    if (userId != null) {
      // Subscribe to real-time check-in updates from Firestore
      _checkInsSubscription = _firebaseService
          .getUserCheckIns(userId)
          .listen(
            (checkIns) {
              _checkInHistory = checkIns;
              notifyListeners();
            },
            onError: (error) {
              debugPrint('Error loading check-ins: $error');
              // Fall back to local storage
              loadHistory();
            },
          );
    } else {
      await loadHistory();
    }
  }

  /// Sets the current user ID for Firestore queries.
  void setUserId(String? userId) {
    if (userId != _currentUserId) {
      _checkInsSubscription?.cancel();
      _currentUserId = userId;

      if (userId != null) {
        _checkInsSubscription = _firebaseService.getUserCheckIns(userId).listen(
          (checkIns) {
            _checkInHistory = checkIns;
            notifyListeners();
          },
        );
      } else {
        _checkInHistory = [];
        notifyListeners();
      }
    }
  }

  /// Loads the check-in history from local storage.
  Future<void> loadHistory() async {
    try {
      _checkInHistory = await _storageService.getCheckIns();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading check-in history: $e');
    }
  }

  /// Starts the scanning process.
  void startScanning() {
    _state = CheckInState.scanning;
    _clearErrors();
    notifyListeners();
  }

  /// Processes a scanned QR code and validates the check-in.
  ///
  /// Validates:
  /// 1. Network connectivity
  /// 2. QR code format (must be ISTEC format)
  /// 3. User location (must be within 100m of event location)
  Future<bool> processQRCode(String qrData) async {
    _clearErrors();

    // Step 1: Check connectivity
    _state = CheckInState.processing;
    notifyListeners();

    final isConnected = await _connectivityService.isConnected();
    if (!isConnected) {
      _setError(CheckInErrorType.noConnection, 'Sem Conexão');
      return false;
    }

    // Step 2: Parse QR Code (strict ISTEC format validation)
    _state = CheckInState.processing;
    notifyListeners();

    try {
      _currentEvent = Event.fromQRCode(qrData);
    } catch (e) {
      _setError(
        CheckInErrorType.invalidQRCode,
        'QR Code Inválido - Este QR Code não é válido para o sistema ISTEC',
      );
      return false;
    }

    // Step 3: Validate user location against event location
    _state = CheckInState.validatingLocation;
    notifyListeners();

    try {
      final locationResult = await _locationService.validateLocation(
        eventLatitude: _currentEvent!.latitude,
        eventLongitude: _currentEvent!.longitude,
      );

      _currentPosition = locationResult.position;
      _distanceToEvent = locationResult.distance;

      if (!locationResult.isValid) {
        _setError(
          CheckInErrorType.invalidLocation,
          'Localização Incorreta - Distância: ${locationResult.distance.toStringAsFixed(0)}m (máximo: ${LocationService.maxCheckInDistanceMeters.toInt()}m)',
        );
        return false;
      }
    } on LocationServiceException catch (e) {
      _setError(CheckInErrorType.permissionDenied, e.message);
      return false;
    } catch (e) {
      _setError(CheckInErrorType.unknown, 'Erro ao obter localização');
      return false;
    }

    // Step 4: Create and save check-in to Firestore
    _state = CheckInState.processing;
    notifyListeners();

    try {
      final checkIn = CheckIn.fromEvent(
        event: _currentEvent!,
        userLatitude: _currentPosition!.latitude,
        userLongitude: _currentPosition!.longitude,
        distance: _distanceToEvent!,
      );

      // Save to Firestore if user is logged in
      if (_currentUserId != null) {
        await _firebaseService.saveCheckIn(checkIn, _currentUserId!);
      }

      // Also save locally as backup
      await _storageService.saveCheckIn(checkIn);

      // Update local list if not using real-time sync
      if (_currentUserId == null) {
        _checkInHistory.insert(0, checkIn);
      }

      _state = CheckInState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(CheckInErrorType.unknown, 'Erro ao guardar check-in');
      return false;
    }
  }

  /// Validates a mock QR code for testing purposes.
  /// Creates a mock event at the specified coordinates.
  Future<bool> processMockCheckIn({
    required String eventName,
    required double eventLatitude,
    required double eventLongitude,
  }) async {
    // Generate QR data in ISTEC format
    final mockQRData =
        'ISTEC|'
        'mock_${DateTime.now().millisecondsSinceEpoch}|'
        '$eventName|'
        'Evento de demonstração|'
        '$eventLatitude|'
        '$eventLongitude|'
        '${DateTime.now().toIso8601String()}|'
        '${DateTime.now().add(const Duration(hours: 2)).toIso8601String()}|'
        'Campus ISTEC';

    return processQRCode(mockQRData);
  }

  /// Returns mock event data for demonstration.
  /// Uses ISTEC campus coordinates as reference.
  static Event getMockEvent() {
    return Event(
      id: 'demo_event_001',
      name: 'Aula de Programação Web',
      description: 'Aula prática de desenvolvimento Flutter',
      // ISTEC Lisbon approximate coordinates
      latitude: 38.7223,
      longitude: -9.1393,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(hours: 2)),
      location: 'Sala A1 - Campus ISTEC',
    );
  }

  /// Generates a QR code string for a given event.
  /// Format: ISTEC|eventId|eventName|description|latitude|longitude|startTime|endTime|location
  static String generateQRCodeData(Event event) {
    return event.toQRCodeData();
  }

  /// Resets the check-in state to idle.
  void reset() {
    _state = CheckInState.idle;
    _clearErrors();
    _currentEvent = null;
    _currentPosition = null;
    _distanceToEvent = null;
    notifyListeners();
  }

  /// Sets an error state with the specified type and message.
  void _setError(CheckInErrorType type, String message) {
    _state = CheckInState.error;
    _errorType = type;
    _errorMessage = message;
    notifyListeners();
  }

  /// Clears any existing error state.
  void _clearErrors() {
    _errorType = null;
    _errorMessage = null;
  }

  /// Clears all check-in history.
  Future<void> clearHistory() async {
    await _storageService.clearCheckIns();
    _checkInHistory.clear();
    notifyListeners();
  }

  /// Disposes of resources.
  @override
  void dispose() {
    _checkInsSubscription?.cancel();
    _locationService.dispose();
    _connectivityService.dispose();
    super.dispose();
  }
}
