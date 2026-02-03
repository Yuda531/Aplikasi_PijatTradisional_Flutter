import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../models/enums/booking_status.dart';
import '../models/enums/service_type.dart';
import '../services/firestore_service.dart';
import '../core/constants/app_constants.dart';

/// Provider for booking state management.
class BookingProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  // Stream subscriptions for proper lifecycle management
  StreamSubscription? _customerBookingsSubscription;
  StreamSubscription? _allBookingsSubscription;
  StreamSubscription? _todayBookingsSubscription;

  List<BookingModel> _bookings = [];
  List<BookingModel> _allBookings = [];
  List<BookingModel> _todayBookings = [];
  List<int> _bookedSlots = [];
  bool _isLoading = false;
  String? _error;

  // Booking form state - now supports multiple services
  Set<ServiceType> _selectedServices = {};
  DateTime? _selectedDate;
  int? _selectedTimeSlot;

  List<BookingModel> get bookings => _bookings;
  List<BookingModel> get allBookings => _allBookings;
  List<BookingModel> get todayBookings => _todayBookings;
  List<int> get bookedSlots => _bookedSlots;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Set<ServiceType> get selectedServices => _selectedServices;
  DateTime? get selectedDate => _selectedDate;
  int? get selectedTimeSlot => _selectedTimeSlot;

  /// Check if at least one service is selected.
  bool get hasSelectedServices => _selectedServices.isNotEmpty;

  /// Get total price of selected services.
  int get totalPrice => _selectedServices.fold<int>(0, (total, s) => total + s.price);

  /// Get formatted total price.
  String get formattedTotalPrice => 'Rp ${totalPrice.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      )}';

  /// Check if booking form is complete.
  bool get isFormComplete =>
      _selectedServices.isNotEmpty && _selectedDate != null && _selectedTimeSlot != null;

  /// Get available time slots for the selected date.
  List<int> get availableSlots {
    final slots = <int>[];
    for (int hour = AppConstants.openingHour; hour < AppConstants.closingHour; hour++) {
      if (!_bookedSlots.contains(hour)) {
        // Check if slot is in the future
        if (_selectedDate != null) {
          final slotDateTime = DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            hour,
          );
          final minBookingTime = DateTime.now().add(
            Duration(hours: AppConstants.minBookingNoticeHours),
          );
          if (slotDateTime.isAfter(minBookingTime)) {
            slots.add(hour);
          }
        }
      }
    }
    return slots;
  }

  /// Load customer bookings with proper error handling.
  void loadCustomerBookings(String customerId) {
    // Cancel existing subscription to prevent memory leaks
    _customerBookingsSubscription?.cancel();
    
    debugPrint('BookingProvider: Loading bookings for customer: $customerId');
    
    _customerBookingsSubscription = _firestoreService
        .getCustomerBookings(customerId)
        .listen(
          (bookings) {
            debugPrint('BookingProvider: Received ${bookings.length} customer bookings');
            _bookings = bookings;
            _clearError();
            notifyListeners();
          },
          onError: (error) {
            debugPrint('BookingProvider: Error loading customer bookings: $error');
            _setError('Gagal memuat pesanan: ${error.toString()}');
          },
        );
  }

  /// Load all bookings (for therapist/admin) with proper error handling.
  void loadAllBookings() {
    // Cancel existing subscription to prevent memory leaks
    _allBookingsSubscription?.cancel();
    
    debugPrint('BookingProvider: Loading all bookings');
    
    _allBookingsSubscription = _firestoreService
        .getAllBookings()
        .listen(
          (bookings) {
            debugPrint('BookingProvider: Received ${bookings.length} total bookings');
            _allBookings = bookings;
            _clearError();
            notifyListeners();
          },
          onError: (error) {
            debugPrint('BookingProvider: Error loading all bookings: $error');
            _setError('Gagal memuat pesanan: ${error.toString()}');
          },
        );
  }

  /// Load today's bookings with proper error handling.
  void loadTodayBookings() {
    // Cancel existing subscription to prevent memory leaks
    _todayBookingsSubscription?.cancel();
    
    debugPrint('BookingProvider: Loading today bookings');
    
    _todayBookingsSubscription = _firestoreService
        .getTodayBookings()
        .listen(
          (bookings) {
            debugPrint('BookingProvider: Received ${bookings.length} today bookings');
            _todayBookings = bookings;
            _clearError();
            notifyListeners();
          },
          onError: (error) {
            debugPrint('BookingProvider: Error loading today bookings: $error');
            _setError('Gagal memuat jadwal hari ini: ${error.toString()}');
          },
        );
  }

  /// Toggle service selection (multi-select).
  void toggleService(ServiceType service) {
    if (_selectedServices.contains(service)) {
      _selectedServices.remove(service);
    } else {
      // Limit to 3 services max
      if (_selectedServices.length < 3) {
        _selectedServices.add(service);
      }
    }
    notifyListeners();
  }

  /// Set selected date and load booked slots.
  Future<void> setSelectedDate(DateTime? date) async {
    _selectedDate = date;
    _selectedTimeSlot = null; // Reset time slot when date changes
    if (date != null) {
      await _loadBookedSlots(date);
    } else {
      _bookedSlots = [];
    }
    notifyListeners();
  }

  /// Set selected time slot.
  void setSelectedTimeSlot(int? hour) {
    _selectedTimeSlot = hour;
    notifyListeners();
  }

  /// Load booked slots for a date.
  Future<void> _loadBookedSlots(DateTime date) async {
    try {
      _bookedSlots = await _firestoreService.getBookedSlotsForDate(date);
      debugPrint('BookingProvider: Loaded ${_bookedSlots.length} booked slots for $date');
    } catch (e) {
      debugPrint('BookingProvider: Error loading booked slots: $e');
      _bookedSlots = [];
    }
  }

  /// Create a new booking.
  Future<bool> createBooking({
    required String customerId,
    required String customerName,
  }) async {
    if (!isFormComplete) {
      _setError('Lengkapi semua data pemesanan');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final scheduledDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTimeSlot!,
      );

      // Check if slot is still available
      final isAvailable = await _firestoreService.isTimeSlotAvailable(scheduledDateTime);
      if (!isAvailable) {
        _setError('Slot waktu sudah terisi. Silakan pilih waktu lain');
        return false;
      }

      final booking = BookingModel.create(
        customerId: customerId,
        customerName: customerName,
        serviceTypes: _selectedServices.toList(),
        scheduledDateTime: scheduledDateTime,
      );

      final bookingId = await _firestoreService.createBooking(booking);
      debugPrint('BookingProvider: Created booking with ID: $bookingId');
      
      resetForm();
      return true;
    } catch (e) {
      debugPrint('BookingProvider: Error creating booking: $e');
      _setError('Gagal membuat pemesanan: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Cancel a booking.
  Future<bool> cancelBooking(String bookingId) async {
    _setLoading(true);
    _clearError();

    try {
      await _firestoreService.cancelBooking(bookingId);
      return true;
    } catch (e) {
      _setError('Gagal membatalkan pemesanan');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Reschedule a booking.
  Future<bool> rescheduleBooking(String bookingId, DateTime newDateTime) async {
    _setLoading(true);
    _clearError();

    try {
      // Check if new slot is available
      final isAvailable = await _firestoreService.isTimeSlotAvailable(newDateTime);
      if (!isAvailable) {
        _setError('Slot waktu sudah terisi');
        return false;
      }

      await _firestoreService.rescheduleBooking(bookingId, newDateTime);
      return true;
    } catch (e) {
      _setError('Gagal mengubah jadwal');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update booking status (Therapist/Admin).
  Future<bool> updateBookingStatus(String bookingId, BookingStatus status) async {
    _setLoading(true);
    _clearError();

    try {
      await _firestoreService.updateBookingStatus(bookingId, status);
      return true;
    } catch (e) {
      _setError('Gagal mengubah status');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Reset booking form.
  void resetForm() {
    _selectedServices = {};
    _selectedDate = null;
    _selectedTimeSlot = null;
    _bookedSlots = [];
    notifyListeners();
  }

  /// Get upcoming bookings (not cancelled or completed).
  List<BookingModel> get upcomingBookings {
    return _bookings.where((b) => 
      b.status.canCancel && b.scheduledDateTime.isAfter(DateTime.now())
    ).toList();
  }

  /// Get past bookings.
  List<BookingModel> get pastBookings {
    return _bookings.where((b) => 
      b.scheduledDateTime.isBefore(DateTime.now()) || 
      b.status == BookingStatus.completed ||
      b.status == BookingStatus.cancelled
    ).toList();
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

  /// Clear all booking data and cancel subscriptions.
  /// Call this when user logs out or changes.
  void clearAllData() {
    debugPrint('BookingProvider: Clearing all data');
    
    // Cancel all subscriptions
    _customerBookingsSubscription?.cancel();
    _allBookingsSubscription?.cancel();
    _todayBookingsSubscription?.cancel();
    
    _customerBookingsSubscription = null;
    _allBookingsSubscription = null;
    _todayBookingsSubscription = null;
    
    // Clear all data lists
    _bookings = [];
    _allBookings = [];
    _todayBookings = [];
    _bookedSlots = [];
    
    // Clear form state
    _selectedServices = {};
    _selectedDate = null;
    _selectedTimeSlot = null;
    
    // Clear error and loading state
    _error = null;
    _isLoading = false;
    
    notifyListeners();
  }

  /// Dispose all stream subscriptions.
  @override
  void dispose() {
    _customerBookingsSubscription?.cancel();
    _allBookingsSubscription?.cancel();
    _todayBookingsSubscription?.cancel();
    super.dispose();
  }
}
