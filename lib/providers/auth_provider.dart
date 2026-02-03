import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/enums/user_role.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

/// Provider for authentication state management.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  User? _firebaseUser;
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  User? get firebaseUser => _firebaseUser;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _firebaseUser != null;
  bool get isInitialized => _isInitialized;
  UserRole? get userRole => _user?.role;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((User? user) async {
      debugPrint('AuthProvider: Auth state changed - user: ${user?.uid}');
      _firebaseUser = user;
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        _user = null;
      }
      _isInitialized = true;
      notifyListeners();
    });
  }

  Future<void> _loadUserData(String userId) async {
    try {
      _user = await _firestoreService.getUser(userId);
      debugPrint('AuthProvider: Loaded user data for $userId: ${_user?.name}');
    } catch (e) {
      debugPrint('AuthProvider: Error loading user data: $e');
      _error = 'Gagal memuat data pengguna';
    }
  }

  /// Sign in with email and password.
  Future<bool> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('AuthProvider: Attempting sign in for $email');
      await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );
      debugPrint('AuthProvider: Sign in successful');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AuthProvider: Sign in failed: $e');
      _error = _cleanErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register with email and password.
  Future<bool> registerWithEmailPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('AuthProvider: Attempting registration for $email');
      final credential = await _authService.registerWithEmailPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create user document in Firestore
        final newUser = UserModel.newUser(
          id: credential.user!.uid,
          email: email,
          name: name,
        );
        await _firestoreService.createUser(newUser);
        await _authService.updateDisplayName(name);
        _user = newUser;
        debugPrint('AuthProvider: Registration successful');
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AuthProvider: Registration failed: $e');
      _error = _cleanErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with Google - currently disabled.
  Future<bool> signInWithGoogle() async {
    _error = 'Google Sign-In tidak tersedia saat ini. Gunakan email/password.';
    notifyListeners();
    return false;
  }

  /// Sign out.
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _authService.signOut();
      _user = null;
      debugPrint('AuthProvider: Sign out successful');
    } catch (e) {
      debugPrint('AuthProvider: Sign out error: $e');
      _error = _cleanErrorMessage(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send password reset email.
  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _cleanErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Refresh user data from Firestore.
  Future<void> refreshUser() async {
    if (_firebaseUser != null) {
      await _loadUserData(_firebaseUser!.uid);
      notifyListeners();
    }
  }

  /// Clean up error message (remove "Exception: " prefix if present)
  String _cleanErrorMessage(String error) {
    if (error.startsWith('Exception: ')) {
      return error.substring(11);
    }
    return error;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
