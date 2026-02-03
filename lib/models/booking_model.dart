import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums/booking_status.dart';
import 'enums/service_type.dart';

/// Booking model representing a service booking.
/// Supports multiple services per booking (2-3 services).
class BookingModel {
  final String id;
  final String customerId;
  final String customerName;
  final List<ServiceType> serviceTypes;
  final DateTime scheduledDateTime;
  final BookingStatus status;
  final int totalPrice;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BookingModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.serviceTypes,
    required this.scheduledDateTime,
    required this.status,
    required this.totalPrice,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a new booking with pending status.
  factory BookingModel.create({
    required String customerId,
    required String customerName,
    required List<ServiceType> serviceTypes,
    required DateTime scheduledDateTime,
  }) {
    final now = DateTime.now();
    final totalPrice = serviceTypes.fold<int>(0, (sum, s) => sum + s.price);
    return BookingModel(
      id: '',
      customerId: customerId,
      customerName: customerName,
      serviceTypes: serviceTypes,
      scheduledDateTime: scheduledDateTime,
      status: BookingStatus.pending,
      totalPrice: totalPrice,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create BookingModel from Firestore document.
  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle both old (single service) and new (multiple services) format
    List<ServiceType> services = [];
    if (data['serviceTypes'] != null) {
      // New format: list of services
      services = (data['serviceTypes'] as List)
          .map((s) => ServiceType.fromString(s.toString()))
          .toList();
    } else if (data['serviceType'] != null) {
      // Old format: single service (backwards compatibility)
      services = [ServiceType.fromString(data['serviceType'] ?? 'bodyMassage')];
    }
    
    return BookingModel(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      serviceTypes: services,
      scheduledDateTime: (data['scheduledDateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: BookingStatus.fromString(data['status'] ?? 'pending'),
      totalPrice: data['totalPrice'] ?? data['price'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document.
  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'serviceTypes': serviceTypes.map((s) => s.name).toList(),
      'scheduledDateTime': Timestamp.fromDate(scheduledDateTime),
      'status': status.name,
      'totalPrice': totalPrice,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields.
  BookingModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    List<ServiceType>? serviceTypes,
    DateTime? scheduledDateTime,
    BookingStatus? status,
    int? totalPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      serviceTypes: serviceTypes ?? this.serviceTypes,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Get display name for all services.
  String get servicesDisplayName => serviceTypes.map((s) => s.displayName).join(', ');

  /// Get formatted total price.
  String get formattedTotalPrice => 'Rp ${totalPrice.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      )}';

  /// Get total duration in minutes.
  int get totalDurationMinutes => serviceTypes.fold<int>(0, (sum, s) => sum + s.durationMinutes);

  /// Check if booking is in the past.
  bool get isPast => scheduledDateTime.isBefore(DateTime.now());

  /// Check if booking is today.
  bool get isToday {
    final now = DateTime.now();
    return scheduledDateTime.year == now.year &&
        scheduledDateTime.month == now.month &&
        scheduledDateTime.day == now.day;
  }

  @override
  String toString() {
    return 'BookingModel(id: $id, customer: $customerName, services: $servicesDisplayName, date: $scheduledDateTime, status: ${status.name})';
  }
}
