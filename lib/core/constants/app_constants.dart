/// Business rules and configuration constants.
class AppConstants {
  AppConstants._();

  // Operating hours
  static const int openingHour = 11; // 11:00 AM
  static const int closingHour = 17; // 5:00 PM (last slot at 4:00 PM for 1-hour service)
  static const int slotDurationMinutes = 60;
  static const int totalDailySlots = 6;

  // Service prices (IDR)
  static const int bodyMassagePrice = 150000;
  static const int bodyScrubPrice = 150000;
  static const int cuppingTherapyPrice = 150000;

  // Service duration (minutes)
  static const int serviceDuration = 60;

  // Firestore collections
  static const String usersCollection = 'users';
  static const String bookingsCollection = 'bookings';

  // Time slots for booking
  static List<String> get timeSlots {
    final slots = <String>[];
    for (int hour = openingHour; hour < closingHour; hour++) {
      slots.add('${hour.toString().padLeft(2, '0')}:00');
    }
    return slots;
  }

  // Minimum booking notice (hours ahead)
  static const int minBookingNoticeHours = 2;

  // Maximum future booking days
  static const int maxBookingDaysAhead = 30;
}
