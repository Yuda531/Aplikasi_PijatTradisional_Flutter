import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/booking_model.dart';
import '../../models/enums/booking_status.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/common/loading_widget.dart';

/// Booking management screen for admin to view and manage all bookings.
class BookingManagementScreen extends StatefulWidget {
  const BookingManagementScreen({super.key});

  @override
  State<BookingManagementScreen> createState() => _BookingManagementScreenState();
}

class _BookingManagementScreenState extends State<BookingManagementScreen> {
  BookingStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pemesanan'),
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<BookingStatus?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (status) => setState(() => _filterStatus = status),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Semua'),
              ),
              ...BookingStatus.values.map(
                (status) => PopupMenuItem(
                  value: status,
                  child: Text(status.displayName),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, child) {
          var bookings = bookingProvider.allBookings;
          
          if (_filterStatus != null) {
            bookings = bookings.where((b) => b.status == _filterStatus).toList();
          }

          if (bookings.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.calendar_today,
              title: 'Tidak ada pemesanan',
              subtitle: _filterStatus != null
                  ? 'Tidak ada pemesanan dengan status ${_filterStatus!.displayName}'
                  : null,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return _AdminBookingCard(
                booking: booking,
                onStatusChanged: (status) => _updateStatus(booking, status),
              );
            },
          );
        },
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

/// Admin booking card with full control.
class _AdminBookingCard extends StatelessWidget {
  final BookingModel booking;
  final void Function(BookingStatus) onStatusChanged;

  const _AdminBookingCard({
    required this.booking,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy', 'id_ID');
    final timeFormat = DateFormat('HH:mm', 'id_ID');

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.customerName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        booking.servicesDisplayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
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
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(booking.scheduledDateTime),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  timeFormat.format(booking.scheduledDateTime),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              booking.formattedTotalPrice,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Divider(height: 24),
            
            // Status selector
            Text(
              'Ubah Status:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: BookingStatus.values.map((status) {
                final isSelected = booking.status == status;
                return ChoiceChip(
                  label: Text(
                    status.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : status.color,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: status.color,
                  backgroundColor: status.color.withOpacity(0.1),
                  onSelected: isSelected ? null : (_) => onStatusChanged(status),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
