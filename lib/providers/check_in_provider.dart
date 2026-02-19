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
class CheckInProvider extends ChangeNotifier {
  final LocationService _locationService;
  final ConnectivityService _connectivityService;
  final StorageService _storageService;

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
  }) : _locationService = locationService ?? LocationService(),
       _connectivityService = connectivityService ?? ConnectivityService(),
       _storageService = storageService ?? StorageService();

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

  /// Initializes the provider by loading check-in history.
  Future<void> init() async {
    await _storageService.init();
    await loadHistory();
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
  /// DEMO MODE: Location validation is performed but any QR code is accepted.
  /// The event location is set to the user's current position for demonstration.
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

    // Step 2: Get user's current location first (needed for demo mode)
    _state = CheckInState.validatingLocation;
    notifyListeners();

    try {
      _currentPosition = await _locationService.getCurrentPosition();
    } on LocationServiceException catch (e) {
      _setError(CheckInErrorType.permissionDenied, e.message);
      return false;
    } catch (e) {
      _setError(CheckInErrorType.unknown, 'Erro ao obter localização');
      return false;
    }

    // Step 3: Parse QR Code (demo mode - accepts any QR code)
    _state = CheckInState.processing;
    notifyListeners();

    try {
      _currentEvent = Event.fromQRCode(qrData);

      // ============================================================
      // DEMO MODE: Override event location with user's current position
      // This ensures location validation always passes for demonstration
      // ============================================================
      _currentEvent = Event(
        id: _currentEvent!.id,
        name: _currentEvent!.name,
        description: _currentEvent!.description,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        startTime: _currentEvent!.startTime,
        endTime: _currentEvent!.endTime,
        location: _currentEvent!.location,
      );
      // ============================================================
    } catch (e) {
      _setError(CheckInErrorType.invalidQRCode, 'QR Code Inválido');
      return false;
    }

    // Step 4: Validate location (will pass in demo mode since we set event coords = user coords)
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

    // Step 5: Create and save check-in
    _state = CheckInState.processing;
    notifyListeners();

    try {
      final checkIn = CheckIn.fromEvent(
        event: _currentEvent!,
        userLatitude: _currentPosition!.latitude,
        userLongitude: _currentPosition!.longitude,
        distance: _distanceToEvent!,
      );

      await _storageService.saveCheckIn(checkIn);
      _checkInHistory.insert(0, checkIn);

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
    final mockQRData =
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
  static String generateQRCodeData(Event event) {
    return '${event.id}|'
        '${event.name}|'
        '${event.description}|'
        '${event.latitude}|'
        '${event.longitude}|'
        '${event.startTime.toIso8601String()}|'
        '${event.endTime.toIso8601String()}|'
        '${event.location}';
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
    _locationService.dispose();
    _connectivityService.dispose();
    super.dispose();
  }
}
