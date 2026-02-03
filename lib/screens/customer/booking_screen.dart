import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../models/enums/service_type.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/booking/service_card.dart';
import '../../widgets/booking/time_slot_picker.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';

/// Booking screen for creating new appointments.
class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    // Reset form when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().resetForm();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _confirmBooking() async {
    final authProvider = context.read<AuthProvider>();
    final bookingProvider = context.read<BookingProvider>();

    if (authProvider.user == null) return;

    final success = await bookingProvider.createBooking(
      customerId: authProvider.user!.id,
      customerName: authProvider.user!.name,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.bookingSuccess),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (bookingProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(bookingProvider.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.bookNow),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _previousStep,
        ),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, child) {
          return LoadingOverlay(
            isLoading: bookingProvider.isLoading,
            child: Column(
              children: [
                // Progress indicator
                _StepIndicator(currentStep: _currentStep),
                
                // Page content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _ServiceSelectionStep(
                        selectedServices: bookingProvider.selectedServices,
                        onServiceToggled: bookingProvider.toggleService,
                        totalPrice: bookingProvider.formattedTotalPrice,
                      ),
                      _DateSelectionStep(
                        selectedDate: bookingProvider.selectedDate,
                        onDateSelected: bookingProvider.setSelectedDate,
                      ),
                      _TimeSelectionStep(
                        bookedSlots: bookingProvider.bookedSlots,
                        selectedSlot: bookingProvider.selectedTimeSlot,
                        selectedDate: bookingProvider.selectedDate,
                        onSlotSelected: bookingProvider.setSelectedTimeSlot,
                      ),
                    ],
                  ),
                ),

                // Navigation buttons
                _NavigationButtons(
                  currentStep: _currentStep,
                  canProceed: _canProceed(bookingProvider),
                  onNext: _nextStep,
                  onConfirm: _confirmBooking,
                  isLoading: bookingProvider.isLoading,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _canProceed(BookingProvider provider) {
    switch (_currentStep) {
      case 0:
        return provider.hasSelectedServices;
      case 1:
        return provider.selectedDate != null;
      case 2:
        return provider.selectedTimeSlot != null;
      default:
        return false;
    }
  }
}

/// Step indicator widget.
class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _StepDot(isActive: currentStep >= 0, label: 'Layanan'),
          _StepLine(isActive: currentStep >= 1),
          _StepDot(isActive: currentStep >= 1, label: 'Tanggal'),
          _StepLine(isActive: currentStep >= 2),
          _StepDot(isActive: currentStep >= 2, label: 'Waktu'),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool isActive;
  final String label;

  const _StepDot({required this.isActive, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.primary : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: isActive
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool isActive;

  const _StepLine({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isActive ? AppColors.primary : Colors.grey.shade300,
      ),
    );
  }
}

/// Service selection step - supports multi-select (up to 3 services).
class _ServiceSelectionStep extends StatelessWidget {
  final Set<ServiceType> selectedServices;
  final void Function(ServiceType) onServiceToggled;
  final String totalPrice;

  const _ServiceSelectionStep({
    required this.selectedServices,
    required this.onServiceToggled,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.selectService,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Pilih 1-3 layanan yang Anda inginkan',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          ...ServiceType.values.map(
            (service) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ServiceCardMultiSelect(
                serviceType: service,
                isSelected: selectedServices.contains(service),
                onTap: () => onServiceToggled(service),
              ),
            ),
          ),
          if (selectedServices.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total (${selectedServices.length} layanan)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        totalPrice,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  if (selectedServices.length >= 3)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Maks. 3 layanan',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.warning,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Date selection step.
class _DateSelectionStep extends StatelessWidget {
  final DateTime? selectedDate;
  final Future<void> Function(DateTime?) onDateSelected;

  const _DateSelectionStep({
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final minDate = now.add(const Duration(days: 1));
    final maxDate = now.add(Duration(days: AppConstants.maxBookingDaysAhead));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.selectDate,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Pilih tanggal kunjungan',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          Card(
            child: CalendarDatePicker(
              initialDate: selectedDate ?? minDate,
              firstDate: minDate,
              lastDate: maxDate,
              onDateChanged: (date) => onDateSelected(date),
            ),
          ),
          if (selectedDate != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(selectedDate!),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Time selection step.
class _TimeSelectionStep extends StatelessWidget {
  final List<int> bookedSlots;
  final int? selectedSlot;
  final DateTime? selectedDate;
  final void Function(int) onSlotSelected;

  const _TimeSelectionStep({
    required this.bookedSlots,
    required this.selectedSlot,
    required this.selectedDate,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.selectTime,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Jam operasional: ${AppConstants.openingHour}:00 - ${AppConstants.closingHour}:00',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          TimeSlotPicker(
            bookedSlots: bookedSlots,
            selectedSlot: selectedSlot,
            selectedDate: selectedDate,
            onSlotSelected: onSlotSelected,
          ),
          const SizedBox(height: 24),
          
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _LegendItem(color: AppColors.primary, label: 'Dipilih'),
              _LegendItem(color: Colors.grey.shade200, label: 'Terisi'),
              _LegendItem(
                color: AppColors.background,
                label: 'Tersedia',
                hasBorder: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool hasBorder;

  const _LegendItem({
    required this.color,
    required this.label,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: hasBorder ? Border.all(color: Colors.grey.shade300) : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Navigation buttons.
class _NavigationButtons extends StatelessWidget {
  final int currentStep;
  final bool canProceed;
  final VoidCallback onNext;
  final VoidCallback onConfirm;
  final bool isLoading;

  const _NavigationButtons({
    required this.currentStep,
    required this.canProceed,
    required this.onNext,
    required this.onConfirm,
    required this.isLoading,
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
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: FullWidthButton(
          text: currentStep == 2 ? AppStrings.confirmBooking : 'Lanjut',
          onPressed: canProceed ? (currentStep == 2 ? onConfirm : onNext) : null,
          isLoading: isLoading,
        ),
      ),
    );
  }
}
