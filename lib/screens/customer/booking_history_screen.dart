import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/booking/booking_card.dart';
import '../../widgets/common/loading_widget.dart';

/// Booking history screen showing all customer bookings.
class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.bookingHistory),
          automaticallyImplyLeading: false,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'Mendatang'),
              Tab(text: 'Riwayat'),
            ],
          ),
        ),
        body: Consumer<BookingProvider>(
          builder: (context, bookingProvider, child) {
            return TabBarView(
              children: [
                _BookingList(
                  bookings: bookingProvider.upcomingBookings,
                  emptyMessage: 'Tidak ada pesanan mendatang',
                  emptyIcon: Icons.event_available,
                  showActions: true,
                ),
                _BookingList(
                  bookings: bookingProvider.pastBookings,
                  emptyMessage: 'Belum ada riwayat pesanan',
                  emptyIcon: Icons.history,
                  showActions: false,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Booking list widget.
class _BookingList extends StatelessWidget {
  final List<BookingModel> bookings;
  final String emptyMessage;
  final IconData emptyIcon;
  final bool showActions;

  const _BookingList({
    required this.bookings,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.showActions,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return EmptyStateWidget(
        icon: emptyIcon,
        title: emptyMessage,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return BookingCard(
          booking: booking,
          showActions: showActions,
          onCancel: showActions ? () => _showCancelDialog(context, booking) : null,
          onReschedule: showActions ? () => _showRescheduleDialog(context, booking) : null,
        );
      },
    );
  }

  void _showCancelDialog(BuildContext context, BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Pesanan'),
        content: const Text('Apakah Anda yakin ingin membatalkan pesanan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context.read<BookingProvider>().cancelBooking(booking.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? AppStrings.bookingCancelled : 'Gagal membatalkan pesanan',
                    ),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog(BuildContext context, BookingModel booking) {
    // TODO: Implement reschedule dialog with date/time picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur jadwal ulang akan segera tersedia'),
      ),
    );
  }
}
