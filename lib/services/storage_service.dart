import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Service responsible for local data persistence using SharedPreferences.
class StorageService {
  static const String _userKey = 'current_user';
  static const String _checkInsKey = 'check_ins';
  static const String _isLoggedInKey = 'is_logged_in';

  SharedPreferences? _prefs;

  /// Initializes the SharedPreferences instance.
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Ensures the service is initialized.
  Future<SharedPreferences> _getPrefs() async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  // ==================== User Management ====================

  /// Saves the current user to local storage.
  Future<void> saveUser(User user) async {
    final prefs = await _getPrefs();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await prefs.setBool(_isLoggedInKey, true);
  }

  /// Retrieves the current user from local storage.
  Future<User?> getUser() async {
    final prefs = await _getPrefs();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;

    try {
      return User.fromJson(jsonDecode(userJson));
    } catch (e) {
      return null;
    }
  }

  /// Checks if a user is currently logged in.
  Future<bool> isLoggedIn() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  /// Clears user data (logout).
  Future<void> clearUser() async {
    final prefs = await _getPrefs();
    await prefs.remove(_userKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  // ==================== Check-in History Management ====================

  /// Saves a new check-in to the history.
  Future<void> saveCheckIn(CheckIn checkIn) async {
    final prefs = await _getPrefs();
    final checkIns = await getCheckIns();
    checkIns.insert(0, checkIn); // Add to the beginning for chronological order

    final jsonList = checkIns.map((c) => c.toJson()).toList();
    await prefs.setString(_checkInsKey, jsonEncode(jsonList));
  }

  /// Retrieves all check-ins from history.
  Future<List<CheckIn>> getCheckIns() async {
    final prefs = await _getPrefs();
    final checkInsJson = prefs.getString(_checkInsKey);
    if (checkInsJson == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(checkInsJson);
      return jsonList.map((json) => CheckIn.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Clears all check-in history.
  Future<void> clearCheckIns() async {
    final prefs = await _getPrefs();
    await prefs.remove(_checkInsKey);
  }

  /// Clears all stored data.
  Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.clear();
  }
}
