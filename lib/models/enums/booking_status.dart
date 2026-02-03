import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

/// Booking status enum with associated colors and labels.
enum BookingStatus {
  pending,
  confirmed,
  completed,
  cancelled;

  /// Get display name in Indonesian.
  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return AppStrings.pending;
      case BookingStatus.confirmed:
        return AppStrings.confirmed;
      case BookingStatus.completed:
        return AppStrings.completed;
      case BookingStatus.cancelled:
        return AppStrings.cancelled;
    }
  }

  /// Get color for this status.
  Color get color {
    switch (this) {
      case BookingStatus.pending:
        return AppColors.pending;
      case BookingStatus.confirmed:
        return AppColors.confirmed;
      case BookingStatus.completed:
        return AppColors.completed;
      case BookingStatus.cancelled:
        return AppColors.cancelled;
    }
  }

  /// Check if booking can be cancelled.
  bool get canCancel => this == BookingStatus.pending || this == BookingStatus.confirmed;

  /// Check if booking can be rescheduled.
  bool get canReschedule => this == BookingStatus.pending || this == BookingStatus.confirmed;

  /// Create BookingStatus from string.
  static BookingStatus fromString(String value) {
    return BookingStatus.values.firstWhere(
      (status) => status.name == value.toLowerCase(),
      orElse: () => BookingStatus.pending,
    );
  }
}
