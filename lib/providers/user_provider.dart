import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/enums/user_role.dart';
import '../services/firestore_service.dart';

/// Provider for user profile management.
class UserProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _user;
  List<UserModel> _allUsers = [];
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  List<UserModel> get allUsers => _allUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load user data.
  Future<void> loadUser(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _firestoreService.getUser(userId);
    } catch (e) {
      _setError('Gagal memuat data pengguna');
    } finally {
      _setLoading(false);
    }
  }

  /// Update user profile.
  Future<bool> updateProfile({
    required String userId,
    required String name,
    int? age,
    String? occupation,
    String? address,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      if (_user == null) return false;

      final updatedUser = _user!.copyWith(
        name: name,
        age: age,
        occupation: occupation,
        address: address,
      );

      await _firestoreService.updateUser(updatedUser);
      _user = updatedUser;
      return true;
    } catch (e) {
      _setError('Gagal memperbarui profil');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Load all users (Admin only).
  void loadAllUsers() {
    _firestoreService.getAllUsers().listen((users) {
      _allUsers = users;
      notifyListeners();
    });
  }

  /// Update user role (Admin only).
  Future<bool> updateUserRole(String userId, UserRole role) async {
    _setLoading(true);
    _clearError();

    try {
      await _firestoreService.updateUserRole(userId, role);
      // Update local list
      final index = _allUsers.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _allUsers[index] = _allUsers[index].copyWith(role: role);
      }
      return true;
    } catch (e) {
      _setError('Gagal mengubah role pengguna');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Stream user data.
  void streamUser(String userId) {
    _firestoreService.streamUser(userId).listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  void setUser(UserModel? user) {
    _user = user;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}
