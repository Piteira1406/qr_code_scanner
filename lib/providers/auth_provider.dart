import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/models.dart';
import '../services/services.dart';

/// Authentication states for the app.
enum AuthState { initial, loading, authenticated, unauthenticated, error }

/// Provider responsible for managing authentication state.
/// Uses Firebase Auth for real authentication.
class AuthProvider extends ChangeNotifier {
  final StorageService _storageService;
  final FirebaseService _firebaseService;
  StreamSubscription<fb.User?>? _authSubscription;

  AuthState _state = AuthState.initial;
  User? _currentUser;
  String? _errorMessage;

  AuthProvider({
    StorageService? storageService,
    FirebaseService? firebaseService,
  }) : _storageService = storageService ?? StorageService(),
       _firebaseService = firebaseService ?? FirebaseService();

  // Getters
  AuthState get state => _state;
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;

  /// Returns true if the current user is a professor.
  bool get isProfessor => _currentUser?.isProfessor ?? false;

  /// Returns true if the current user is a student.
  bool get isAluno => _currentUser?.isAluno ?? true;

  /// Initializes the auth provider by checking for existing session.
  /// Listens to Firebase Auth state changes.
  Future<void> init() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      await _storageService.init();

      // Listen to Firebase auth state changes
      _authSubscription = _firebaseService.authStateChanges.listen(
        _onAuthStateChanged,
        onError: (error) {
          _state = AuthState.error;
          _errorMessage = 'Erro de autenticação';
          notifyListeners();
        },
      );

      // Check current auth state
      final firebaseUser = _firebaseService.currentFirebaseUser;
      if (firebaseUser != null) {
        // User is logged in, get user data from Firestore
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

  /// Handles auth state changes from Firebase.
  void _onAuthStateChanged(fb.User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      _state = AuthState.unauthenticated;
    } else if (_currentUser == null) {
      // User signed in but we don't have local data
      final savedUser = await _storageService.getUser();
      if (savedUser != null && savedUser.id == firebaseUser.uid) {
        _currentUser = savedUser;
        _state = AuthState.authenticated;
      }
    }
    notifyListeners();
  }

  /// Attempts to log in with Firebase Auth.
  /// Role is determined by email prefix: prof.* = professor, otherwise = aluno
  Future<bool> login(String emailOrId, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Ensure email format
      final email = emailOrId.contains('@') ? emailOrId : '$emailOrId@istec.pt';

      // Sign in with Firebase Auth
      final user = await _firebaseService.signInWithEmailAndPassword(
        email,
        password,
      );

      if (user != null) {
        _currentUser = user;
        await _storageService.saveUser(user);
        _state = AuthState.authenticated;
        notifyListeners();
        return true;
      } else {
        _state = AuthState.error;
        _errorMessage = 'Falha na autenticação';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Registers a new user with Firebase Auth.
  Future<bool> register(String email, String password, String name) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _firebaseService.registerWithEmailAndPassword(
        email,
        password,
        name,
      );

      if (user != null) {
        _currentUser = user;
        await _storageService.saveUser(user);
        _state = AuthState.authenticated;
        notifyListeners();
        return true;
      } else {
        _state = AuthState.error;
        _errorMessage = 'Falha no registo';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Logs out the current user from Firebase.
  Future<void> logout() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      await _firebaseService.signOut();
      await _storageService.clearUser();
      _currentUser = null;
      _state = AuthState.unauthenticated;
    } catch (e) {
      _errorMessage = 'Erro ao terminar sessão';
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  /// Clears any error message.
  void clearError() {
    _errorMessage = null;
    if (_state == AuthState.error) {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }
}
