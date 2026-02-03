/// User roles in the application.
enum UserRole {
  customer,
  therapist,
  admin;

  /// Get display name in Indonesian.
  String get displayName {
    switch (this) {
      case UserRole.customer:
        return 'Pelanggan';
      case UserRole.therapist:
        return 'Terapis';
      case UserRole.admin:
        return 'Admin';
    }
  }

  /// Create UserRole from string.
  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value.toLowerCase(),
      orElse: () => UserRole.customer,
    );
  }
}
