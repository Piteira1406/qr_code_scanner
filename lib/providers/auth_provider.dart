import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Authentication states for the app.
enum AuthState { initial, loading, authenticated, unauthenticated, error }

/// Provider responsible for managing authentication state.
class AuthProvider extends ChangeNotifier {
  final StorageService _storageService;

  AuthState _state = AuthState.initial;
  User? _currentUser;
  String? _errorMessage;

  AuthProvider({StorageService? storageService})
    : _storageService = storageService ?? StorageService();

  // Getters
  AuthState get state => _state;
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;

  /// Initializes the auth provider by checking for existing session.
  Future<void> init() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      await _storageService.init();
      final isLoggedIn = await _storageService.isLoggedIn();

      if (isLoggedIn) {
        _currentUser = await _storageService.getUser();
        if (_currentUser != null) {
          _state = AuthState.authenticated;
        } else {
          _state = AuthState.unauthenticated;
        }
      } else {
        _state = AuthState.unauthenticated;
      }
    } catch (e) {
      _state = AuthState.unauthenticated;
      _errorMessage = 'Erro ao inicializar sessão';
    }

    notifyListeners();
  }

  /// Attempts to log in with the provided credentials.
  /// For demonstration purposes, uses mock validation.
  Future<bool> login(String emailOrId, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Mock validation - In production, this would call an API
      if (!_validateCredentials(emailOrId, password)) {
        _state = AuthState.error;
        _errorMessage = 'Credenciais inválidas';
        notifyListeners();
        return false;
      }

      // Create mock user based on credentials
      _currentUser = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: emailOrId.contains('@') ? emailOrId : '$emailOrId@istec.pt',
        name: _getNameFromEmail(emailOrId),
        studentNumber: emailOrId.contains('@')
            ? emailOrId.split('@').first
            : emailOrId,
      );

      await _storageService.saveUser(_currentUser!);
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Erro ao iniciar sessão';
      notifyListeners();
      return false;
    }
  }

  /// Logs out the current user.
  Future<void> logout() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      await _storageService.clearUser();
      _currentUser = null;
      _state = AuthState.unauthenticated;
    } catch (e) {
      _errorMessage = 'Erro ao terminar sessão';
    }

    notifyListeners();
  }

  /// Clears any error message.
  void clearError() {
    _errorMessage = null;
    if (_state == AuthState.error) {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  /// Mock credential validation.
  /// In production, this would validate against a server.
  bool _validateCredentials(String emailOrId, String password) {
    // Basic validation rules
    if (emailOrId.isEmpty || password.isEmpty) {
      return false;
    }

    // For demo: accept any non-empty credentials with password length >= 4
    if (password.length < 4) {
      return false;
    }

    return true;
  }

  /// Extracts a name from an email or ID.
  String _getNameFromEmail(String emailOrId) {
    final baseName = emailOrId.contains('@')
        ? emailOrId.split('@').first
        : emailOrId;

    // Capitalize first letter
    if (baseName.isEmpty) return 'Estudante';
    return baseName[0].toUpperCase() + baseName.substring(1);
  }
}
