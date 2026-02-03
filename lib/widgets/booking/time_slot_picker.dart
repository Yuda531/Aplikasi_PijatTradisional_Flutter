import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// Time slot picker widget for booking.
class TimeSlotPicker extends StatelessWidget {
  final List<int> bookedSlots;
  final int? selectedSlot;
  final DateTime? selectedDate;
  final void Function(int) onSlotSelected;

  const TimeSlotPicker({
    super.key,
    required this.bookedSlots,
    required this.selectedSlot,
    required this.selectedDate,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2,
      ),
      itemCount: AppConstants.totalDailySlots,
      itemBuilder: (context, index) {
        final hour = AppConstants.openingHour + index;
        final isBooked = bookedSlots.contains(hour);
        final isSelected = selectedSlot == hour;
        final isPast = _isSlotInPast(hour);
        final isAvailable = !isBooked && !isPast;

        return TimeSlotChip(
          hour: hour,
          isSelected: isSelected,
          isBooked: isBooked,
          isPast: isPast,
          onTap: isAvailable ? () => onSlotSelected(hour) : null,
        );
      },
    );
  }

  bool _isSlotInPast(int hour) {
    if (selectedDate == null) return false;
    
    final slotDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      hour,
    );
    final minBookingTime = DateTime.now().add(
      const Duration(hours: AppConstants.minBookingNoticeHours),
    );
    return slotDateTime.isBefore(minBookingTime);
  }
}

/// Individual time slot chip.
class TimeSlotChip extends StatelessWidget {
  final int hour;
  final bool isSelected;
  final bool isBooked;
  final bool isPast;
  final VoidCallback? onTap;

  const TimeSlotChip({
    super.key,
    required this.hour,
    required this.isSelected,
    required this.isBooked,
    required this.isPast,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getBorderColor(),
            width: isSelected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _getTextColor(),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
            if (isBooked)
              Text(
                'Terisi',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (isSelected) return AppColors.primary;
    if (isBooked) return Colors.grey.shade200;
    if (isPast) return Colors.grey.shade100;
    return AppColors.background;
  }

  Color _getBorderColor() {
    if (isSelected) return AppColors.primary;
    if (isBooked || isPast) return Colors.grey.shade300;
    return AppColors.primary.withOpacity(0.3);
  }

  Color _getTextColor() {
    if (isSelected) return Colors.white;
    if (isBooked || isPast) return AppColors.textSecondary;
    return AppColors.textPrimary;
  }
}
