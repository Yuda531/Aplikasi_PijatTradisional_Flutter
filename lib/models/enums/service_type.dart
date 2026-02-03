import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';

/// Types of services offered.
enum ServiceType {
  bodyMassage,
  bodyScrub,
  cuppingTherapy;

  /// Get display name in Indonesian.
  String get displayName {
    switch (this) {
      case ServiceType.bodyMassage:
        return AppStrings.bodyMassage;
      case ServiceType.bodyScrub:
        return AppStrings.bodyScrub;
      case ServiceType.cuppingTherapy:
        return AppStrings.cuppingTherapy;
    }
  }

  /// Get price for this service.
  int get price {
    switch (this) {
      case ServiceType.bodyMassage:
        return AppConstants.bodyMassagePrice;
      case ServiceType.bodyScrub:
        return AppConstants.bodyScrubPrice;
      case ServiceType.cuppingTherapy:
        return AppConstants.cuppingTherapyPrice;
    }
  }

  /// Get duration in minutes.
  int get durationMinutes => AppConstants.serviceDuration;

  /// Get formatted price string.
  String get formattedPrice => 'Rp ${price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      )}';

  /// Create ServiceType from string.
  static ServiceType fromString(String value) {
    return ServiceType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ServiceType.bodyMassage,
    );
  }
}
