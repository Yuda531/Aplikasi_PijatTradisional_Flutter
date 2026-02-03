import '../constants/app_strings.dart';

/// Form field validators for authentication and profile forms.
class Validators {
  Validators._();

  /// Validates that a field is not empty.
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.required;
    }
    return null;
  }

  /// Validates email format.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.required;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return AppStrings.invalidEmail;
    }
    return null;
  }

  /// Validates password length.
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.required;
    }
    if (value.length < 6) {
      return AppStrings.passwordTooShort;
    }
    return null;
  }

  /// Validates password confirmation matches.
  static String? Function(String?) confirmPassword(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return AppStrings.required;
      }
      if (value != password) {
        return AppStrings.passwordMismatch;
      }
      return null;
    };
  }

  /// Validates age is a valid number.
  static String? age(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Age is optional
    }
    final age = int.tryParse(value);
    if (age == null || age < 1 || age > 120) {
      return 'Usia tidak valid';
    }
    return null;
  }
}
