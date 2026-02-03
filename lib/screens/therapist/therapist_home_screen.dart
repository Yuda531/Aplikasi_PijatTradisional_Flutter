import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/booking_model.dart';
import '../../models/enums/booking_status.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/booking/booking_card.dart';
import 'appointments_screen.dart';

/// Therapist home screen with today's appointments overview.
class TherapistHomeScreen extends StatefulWidget {
  const TherapistHomeScreen({super.key});

  @override
  State<TherapistHomeScreen> createState() => _TherapistHomeScreenState();
}

class _TherapistHomeScreenState extends State<TherapistHomeScreen> {
  int _currentIndex = 0;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    debugPrint('TherapistHomeScreen: Loading data...');
    final bookingProvider = context.read<BookingProvider>();
    bookingProvider.loadTodayBookings();
    bookingProvider.loadAllBookings();
    
    // Mark initial load as complete after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isInitialLoad = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const _TherapistHomeTab(),
      const AppointmentsScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: AppStrings.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: AppStrings.appointments,
          ),
        ],
      ),
    );
  }
}

/// Home tab for therapist.
class _TherapistHomeTab extends StatelessWidget {
  const _TherapistHomeTab();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final bookingProvider = context.watch<BookingProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Therapist Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          debugPrint('TherapistHomeTab: Refreshing data...');
          context.read<BookingProvider>().loadTodayBookings();
          context.read<BookingProvider>().loadAllBookings();
          // Wait for data to load
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome card
              _TherapistWelcomeCard(userName: user?.name ?? 'Terapis'),
              const SizedBox(height: 24),

              // Error display
              if (bookingProvider.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bookingProvider.error!,
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AppColors.error),
                        onPressed: () {
                          context.read<BookingProvider>().loadTodayBookings();
                          context.read<BookingProvider>().loadAllBookings();
                        },
                      ),
                    ],
                  ),
                ),

              // Stats cards
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Hari Ini',
                      value: '${bookingProvider.todayBookings.length}',
                      icon: Icons.today,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Pending',
                      value: '${bookingProvider.todayBookings.where((b) => b.status.name == 'pending').length}',
                      icon: Icons.pending_actions,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Additional stats for all bookings
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Pesanan',
                      value: '${bookingProvider.allBookings.length}',
                      icon: Icons.list_alt,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Dikonfirmasi',
                      value: '${bookingProvider.todayBookings.where((b) => b.status.name == 'confirmed').length}',
                      icon: Icons.check_circle_outline,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Today's appointments
              Text(
                'Jadwal Hari Ini',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),

              if (bookingProvider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (bookingProvider.todayBookings.isEmpty)
                const _EmptyTodayAppointments()
              else
                ...bookingProvider.todayBookings.map(
                  (booking) => BookingCardCompact(
                    booking: booking,
                    onTap: () => _showBookingDetails(context, booking),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Berhasil keluar'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _showBookingDetails(BuildContext context, BookingModel booking) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _BookingDetailsSheet(booking: booking),
    );
  }
}

/// Welcome card for therapist.
class _TherapistWelcomeCard extends StatelessWidget {
  final String userName;

  const _TherapistWelcomeCard({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang,',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                ),
                Text(
                  userName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now()),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.spa,
            size: 60,
            color: Colors.white24,
          ),
        ],
      ),
    );
  }
}

/// Stat card widget.
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

/// Empty today appointments widget.
class _EmptyTodayAppointments extends StatelessWidget {
  const _EmptyTodayAppointments();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available,
            size: 48,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Tidak ada jadwal hari ini',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

/// Booking details bottom sheet.
class _BookingDetailsSheet extends StatelessWidget {
  final BookingModel booking;

  const _BookingDetailsSheet({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Detail Pesanan',
                style: Theme.of(context).textTheme.titleLarge,
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
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _DetailRow(label: 'Pelanggan', value: booking.customerName),
          _DetailRow(label: 'Layanan', value: booking.servicesDisplayName),
          _DetailRow(
            label: 'Waktu',
            value: DateFormat('HH:mm', 'id_ID').format(booking.scheduledDateTime),
          ),
          _DetailRow(label: 'Harga', value: booking.formattedTotalPrice),
          const SizedBox(height: 16),
          if (booking.status.name == 'pending' || booking.status.name == 'confirmed')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(context, 'confirmed'),
                    child: const Text('Konfirmasi'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(context, 'completed'),
                    child: const Text('Selesai'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _updateStatus(BuildContext context, String status) async {
    Navigator.pop(context);
    final bookingProvider = context.read<BookingProvider>();
    
    // Convert string status to BookingStatus enum
    BookingStatus newStatus;
    switch (status) {
      case 'confirmed':
        newStatus = BookingStatus.confirmed;
        break;
      case 'completed':
        newStatus = BookingStatus.completed;
        break;
      case 'cancelled':
        newStatus = BookingStatus.cancelled;
        break;
      default:
        newStatus = BookingStatus.pending;
    }
    
    final success = await bookingProvider.updateBookingStatus(booking.id, newStatus);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Status berhasil diubah' : 'Gagal mengubah status'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
