import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/booking_model.dart';
import '../models/user_model.dart';
import '../models/enums/booking_status.dart';
import '../models/enums/user_role.dart';

/// Service for handling Firestore database operations.
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(AppConstants.usersCollection);

  CollectionReference<Map<String, dynamic>> get _bookingsCollection =>
      _firestore.collection(AppConstants.bookingsCollection);

  // ============== USER OPERATIONS ==============

  /// Create a new user document.
  Future<void> createUser(UserModel user) async {
    await _usersCollection.doc(user.id).set(user.toFirestore());
  }

  /// Get user by ID.
  Future<UserModel?> getUser(String userId) async {
    final doc = await _usersCollection.doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Update user profile.
  Future<void> updateUser(UserModel user) async {
    await _usersCollection.doc(user.id).update(user.toFirestore());
  }

  /// Update user role (Admin only).
  Future<void> updateUserRole(String userId, UserRole role) async {
    await _usersCollection.doc(userId).update({'role': role.name});
  }

  /// Get all users (Admin only).
  Stream<List<UserModel>> getAllUsers() {
    return _usersCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  /// Stream user data.
  Stream<UserModel?> streamUser(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  // ============== BOOKING OPERATIONS ==============

  /// Create a new booking.
  Future<String> createBooking(BookingModel booking) async {
    final docRef = await _bookingsCollection.add(booking.toFirestore());
    return docRef.id;
  }

  /// Get booking by ID.
  Future<BookingModel?> getBooking(String bookingId) async {
    final doc = await _bookingsCollection.doc(bookingId).get();
    if (!doc.exists) return null;
    return BookingModel.fromFirestore(doc);
  }

  /// Update booking.
  Future<void> updateBooking(BookingModel booking) async {
    await _bookingsCollection.doc(booking.id).update(booking.toFirestore());
  }

  /// Update booking status.
  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    await _bookingsCollection.doc(bookingId).update({
      'status': status.name,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Cancel booking.
  Future<void> cancelBooking(String bookingId) async {
    await updateBookingStatus(bookingId, BookingStatus.cancelled);
  }

  /// Reschedule booking.
  Future<void> rescheduleBooking(String bookingId, DateTime newDateTime) async {
    await _bookingsCollection.doc(bookingId).update({
      'scheduledDateTime': Timestamp.fromDate(newDateTime),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Get bookings for a specific customer.
  /// Note: Sorting is done in Dart to avoid composite index requirement.
  Stream<List<BookingModel>> getCustomerBookings(String customerId) {
    return _bookingsCollection
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => BookingModel.fromFirestore(doc))
              .toList();
          // Sort in Dart to avoid composite index requirement
          bookings.sort((a, b) => b.scheduledDateTime.compareTo(a.scheduledDateTime));
          return bookings;
        });
  }

  /// Get all bookings (for therapist/admin).
  /// Note: Sorting is done in Dart to ensure it works without indexes.
  Stream<List<BookingModel>> getAllBookings() {
    return _bookingsCollection
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => BookingModel.fromFirestore(doc))
              .toList();
          // Sort in Dart to avoid index requirement
          bookings.sort((a, b) => b.scheduledDateTime.compareTo(a.scheduledDateTime));
          return bookings;
        });
  }

  /// Get bookings for a specific date.
  /// Note: Sorting is done in Dart to avoid composite index requirement.
  Stream<List<BookingModel>> getBookingsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _bookingsCollection
        .where('scheduledDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('scheduledDateTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => BookingModel.fromFirestore(doc))
              .toList();
          // Sort in Dart
          bookings.sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
          return bookings;
        });
  }

  /// Get today's bookings.
  Stream<List<BookingModel>> getTodayBookings() {
    return getBookingsForDate(DateTime.now());
  }

  /// Get upcoming bookings (not cancelled or completed).
  /// Note: Filter by status is done in Dart to avoid composite index requirement.
  Stream<List<BookingModel>> getUpcomingBookings() {
    return _bookingsCollection
        .where('scheduledDateTime', isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('scheduledDateTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromFirestore(doc))
            .where((booking) =>
                booking.status == BookingStatus.pending ||
                booking.status == BookingStatus.confirmed)
            .toList());
  }

  /// Check if a time slot is available.
  /// Note: Filter by status is done in Dart to avoid composite index requirement.
  Future<bool> isTimeSlotAvailable(DateTime dateTime) async {
    final startOfHour = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
    );
    final endOfHour = startOfHour.add(const Duration(hours: 1));

    final snapshot = await _bookingsCollection
        .where('scheduledDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfHour))
        .where('scheduledDateTime', isLessThan: Timestamp.fromDate(endOfHour))
        .get();

    // Filter by status in Dart to avoid composite index requirement
    final activeBookings = snapshot.docs.where((doc) {
      final status = doc.data()['status'] as String?;
      return status == 'pending' || status == 'confirmed';
    });

    return activeBookings.isEmpty;
  }

  /// Get booked slots for a date.
  /// Note: Filter by status is done in Dart to avoid composite index requirement.
  Future<List<int>> getBookedSlotsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final snapshot = await _bookingsCollection
        .where('scheduledDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('scheduledDateTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    // Filter by status in Dart to avoid composite index requirement
    return snapshot.docs
        .where((doc) {
          final status = doc.data()['status'] as String?;
          return status == 'pending' || status == 'confirmed';
        })
        .map((doc) {
          final dateTime = (doc.data()['scheduledDateTime'] as Timestamp).toDate();
          return dateTime.hour;
        })
        .toList();
  }
}
