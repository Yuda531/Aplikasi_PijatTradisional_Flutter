import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/booking_model.dart';
import '../../models/enums/booking_status.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/common/loading_widget.dart';

/// Appointments screen for therapist to view and manage bookings.
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _showAllDates = false;

  @override
  void initState() {
    super.initState();
    // Ensure data is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().loadAllBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appointments),
        automaticallyImplyLeading: false,
        actions: [
          // Toggle between date filter and all bookings
          IconButton(
            icon: Icon(_showAllDates ? Icons.filter_list : Icons.filter_list_off),
            tooltip: _showAllDates ? 'Filter by date' : 'Show all dates',
            onPressed: () {
              setState(() {
                _showAllDates = !_showAllDates;
              });
            },
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<BookingProvider>().loadAllBookings();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Date selector (only shown when date filter is active)
          if (!_showAllDates)
            _DateSelector(
              selectedDate: _selectedDate,
              onDateChanged: (date) => setState(() => _selectedDate = date),
            ),
          
          // Appointments list
          Expanded(
            child: Consumer<BookingProvider>(
              builder: (context, bookingProvider, child) {
                // Show loading state
                if (bookingProvider.isLoading && bookingProvider.allBookings.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // Show error state
                if (bookingProvider.error != null && bookingProvider.allBookings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          bookingProvider.error!,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            bookingProvider.clearError();
                            bookingProvider.loadAllBookings();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                // Filter appointments based on mode
                final appointments = _showAllDates
                    ? bookingProvider.allBookings
                    : bookingProvider.allBookings
                        .where((b) =>
                            b.scheduledDateTime.year == _selectedDate.year &&
                            b.scheduledDateTime.month == _selectedDate.month &&
                            b.scheduledDateTime.day == _selectedDate.day)
                        .toList();

                if (appointments.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.event_available,
                    title: 'Tidak ada jadwal',
                    subtitle: _showAllDates 
                        ? 'Belum ada pesanan yang masuk'
                        : 'Tidak ada pesanan untuk tanggal ini',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    bookingProvider.loadAllBookings();
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: appointments.length,
                    itemBuilder: (context, index) {
                      final booking = appointments[index];
                      return _AppointmentCard(
                        booking: booking,
                        showDate: _showAllDates,
                        onStatusChanged: (status) => _updateStatus(booking, status),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(BookingModel booking, BookingStatus status) async {
    final success = await context.read<BookingProvider>().updateBookingStatus(
      booking.id,
      status,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Status berhasil diubah' : 'Gagal mengubah status',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }
}

/// Date selector widget.
class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final void Function(DateTime) onDateChanged;

  const _DateSelector({
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => onDateChanged(
              selectedDate.subtract(const Duration(days: 1)),
            ),
            icon: const Icon(Icons.chevron_left),
          ),
          GestureDetector(
            onTap: () => _showDatePicker(context),
            child: Column(
              children: [
                Text(
                  DateFormat('EEEE', 'id_ID').format(selectedDate),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                Text(
                  DateFormat('d MMMM yyyy', 'id_ID').format(selectedDate),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => onDateChanged(
              selectedDate.add(const Duration(days: 1)),
            ),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  void _showDatePicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      onDateChanged(picked);
    }
  }
}

/// Appointment card with status actions.
class _AppointmentCard extends StatelessWidget {
  final BookingModel booking;
  final bool showDate;
  final void Function(BookingStatus) onStatusChanged;

  const _AppointmentCard({
    required this.booking,
    this.showDate = false,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm', 'id_ID');
    final dateFormat = DateFormat('d MMM yyyy', 'id_ID');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.access_time, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              timeFormat.format(booking.scheduledDateTime),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (showDate)
                              Text(
                                dateFormat.format(booking.scheduledDateTime),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: booking.status.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking.status.displayName,
                    style: TextStyle(
                      color: booking.status.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              booking.customerName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              booking.servicesDisplayName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const Divider(height: 24),
            
            // Status actions
            if (booking.status == BookingStatus.pending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onStatusChanged(BookingStatus.cancelled),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      child: const Text('Tolak'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onStatusChanged(BookingStatus.confirmed),
                      child: const Text('Konfirmasi'),
                    ),
                  ),
                ],
              )
            else if (booking.status == BookingStatus.confirmed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => onStatusChanged(BookingStatus.completed),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                  child: const Text('Tandai Selesai'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
