import 'package:firebase_auth/firebase_auth.dart';

/// Service for handling Firebase Authentication operations.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current user.
  User? get currentUser => _auth.currentUser;

  /// Check if user is logged in.
  bool get isLoggedIn => currentUser != null;

  /// Sign in with email and password.
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Handle generic exceptions
      throw 'Gagal masuk. Periksa email dan kata sandi Anda.';
    }
  }

  /// Register with email and password.
  Future<UserCredential> registerWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Handle generic exceptions
      throw 'Gagal mendaftar. Coba lagi nanti.';
    }
  }

  /// Sign in with Google - disabled for now due to build issues.
  /// Re-enable by adding google_sign_in package when path issues are resolved.
  Future<UserCredential?> signInWithGoogle() async {
    throw UnimplementedError(
      'Google Sign-In is disabled. Use email/password instead.',
    );
  }

  /// Sign out from all providers.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Update user display name.
  Future<void> updateDisplayName(String name) async {
    await currentUser?.updateDisplayName(name);
  }

  /// Handle Firebase Auth exceptions with user-friendly messages.
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Email tidak terdaftar';
      case 'wrong-password':
        return 'Kata sandi salah';
      case 'invalid-credential':
        return 'Email atau kata sandi salah';
      case 'email-already-in-use':
        return 'Email sudah digunakan';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'weak-password':
        return 'Kata sandi terlalu lemah';
      case 'user-disabled':
        return 'Akun telah dinonaktifkan';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti';
      case 'operation-not-allowed':
        return 'Operasi tidak diizinkan';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah';
      default:
        return e.message ?? 'Terjadi kesalahan';
    }
  }
}
