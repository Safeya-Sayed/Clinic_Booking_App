import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';



class AuthProvider with ChangeNotifier {


  final AuthService _authService = AuthService();


  bool _isLoading = false;
  String? _error;

  bool _isLoggedIn = false;
  bool _isInitializing = true;

  String? _userId;
  UserModel? _user;

  // getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _isLoggedIn;
  bool get isInitializing => _isInitializing;
  String get userId => _userId ?? "";
  UserModel? get user => _user;
  bool get isAssistant => _user?.role == 'assistant';

  // =========================
  // Register
  // =========================
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    _setLoading(true);

    final result = await _authService.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
    );

    _setLoading(false);

    if (result != null) {
      _setResponse(result);
      return false;
    }

    _clearError();

    return true;
  }

  // =========================
  // Login
  // =========================
  Future<bool> login(
      String email,
      String password,
      String role,
      ) async {
    _setLoading(true);

    final result = await _authService.login(
      email: email,
      password: password,
      role:role,
    );

    if (result != null) {
      _setLoading(false);
      _setResponse(result);
      return false;
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      _setLoading(false);
      _setResponse("Failed to retrieve user after login.");
      return false;
    }

    _userId = firebaseUser.uid;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();

if (!doc.exists) {
await FirebaseAuth.instance.signOut();
_userId = null;
_user = null;
_setLoading(false);
_setResponse("User data not found.");
return false;
}

_user = UserModel.fromMap(doc.data()!, _userId!);
if (_user!.role != role) {
await FirebaseAuth.instance.signOut();
_userId = null;
_user = null;
_setLoading(false);
_setResponse("Wrong account type.");
return false;
}

    // save login state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userId', _userId!);

    _isLoggedIn = true;

    _setLoading(false);
    _clearError();

    return true;
    } catch (e) {
      await FirebaseAuth.instance.signOut();
      _userId = null;
      _user = null;
      _isLoggedIn = false;
      _setLoading(false);
      _setResponse("Failed to load user data.");
      return false;
    }
  }

  // =========================
  // Check Login State (Auto Login)
  // =========================
  Future<void> checkLoginStatus() async {
    try {
      // Firebase Auth is the source of truth; SharedPreferences can become stale.
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        _isLoggedIn = false;
        _userId = null;
        _user = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('isLoggedIn');
        await prefs.remove('userId');
        return;
      }

      _userId = firebaseUser.uid;
      final userData = await _authService.getUserData(_userId!);
      _user = userData;
      _isLoggedIn = userData != null;

      if (userData == null) {
        await FirebaseAuth.instance.signOut();
        _userId = null;

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('isLoggedIn');
        await prefs.remove('userId');
      }

      if (_isLoggedIn) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userId', _userId!);
      }
    } catch (e) {
      _error = 'Failed to restore your session.';
      _isLoggedIn = false;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  // =========================
  // Logout
  // =========================
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _isLoggedIn = false;
    _userId = null;
    _user = null;

    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setResponse(String errorMsg) {
    _error = errorMsg;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}