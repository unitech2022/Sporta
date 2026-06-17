import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/gradient_page_header.dart';
import '../cubit/book_court/book_court_cubit.dart';
import '../widgets/book_court/booking_action_buttons.dart';
import '../widgets/book_court/booking_date_picker.dart';
import '../widgets/book_court/booking_date_utils.dart';
import '../widgets/book_court/booking_summary_card.dart';
import '../widgets/book_court/court_info_card.dart';
import '../widgets/book_court/court_number_picker.dart';
import '../widgets/book_court/duration_picker.dart';
import '../widgets/book_court/time_slots_grid.dart';

/// Court booking screen. Provides a [BookCourtCubit] and renders the booking
/// flow (date → court → duration → time → confirm) from its state.
class BookCourtPage extends StatelessWidget {
  const BookCourtPage({
    super.key,
    required this.onBack,
    this.courtId,
    this.onComplete,
  });

  final VoidCallback onBack;
  final String? courtId;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BookCourtCubit>(
      create: (_) => getIt<BookCourtCubit>()..loadCourt(courtId),
      child: _BookCourtView(onBack: onBack, onComplete: onComplete),
    );
  }
}

class _BookCourtView extends StatefulWidget {
  const _BookCourtView({required this.onBack, this.onComplete});

  final VoidCallback onBack;
  final VoidCallback? onComplete;

  @override
  State<_BookCourtView> createState() => _BookCourtViewState();
}

class _BookCourtViewState extends State<_BookCourtView> {
  // Cached once: the next 15 days and the daily opening slots (06:00–23:00).
  late final List<DateTime> _dates;
  late final List<String> _timeSlots;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _dates = List.generate(15, (i) => today.add(Duration(days: i)));
    _timeSlots =
        List.generate(18, (i) => '${(6 + i).toString().padLeft(2, '0')}:00');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocConsumer<BookCourtCubit, BookCourtState>(
          listenWhen: (prev, curr) => prev.submission != curr.submission,
          listener: _onSubmissionChanged,
          builder: (context, state) {
            switch (state.status) {
              case BookCourtStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case BookCourtStatus.failure:
                return Center(child: Text(state.error ?? 'الملعب غير موجود'));
              case BookCourtStatus.ready:
                return _buildContent(context, state);
            }
          },
        ),
      ),
    );
  }

  void _onSubmissionChanged(BuildContext context, BookCourtState state) {
    if (state.submission == BookingSubmission.success) {
      _showSnack('تم تأكيد الحجز بنجاح', success: true);
      widget.onComplete?.call();
    } else if (state.submission == BookingSubmission.failure) {
      _showSnack(state.bookingError ?? 'تعذّر إتمام الحجز', success: false);
    }
  }

  Widget _buildContent(BuildContext context, BookCourtState state) {
    final cubit = context.read<BookCourtCubit>();
    final court = state.court!;
    return Column(
      children: [
        GradientPageHeader(
          title: 'حجز الملعب',
          subtitle: court.name,
          onBack: widget.onBack,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CourtInfoCard(court: court),
                const SizedBox(height: AppSizes.xl),
                BookingDatePicker(
                  dates: _dates,
                  selectedDate: state.selectedDate,
                  onSelect: cubit.selectDate,
                ),
                if (state.selectedDate != null) ...[
                  const SizedBox(height: AppSizes.xl),
                  CourtNumberPicker(
                    selected: state.selectedCourtNumber,
                    onSelect: cubit.selectCourtNumber,
                  ),
                ],
                if (state.selectedCourtNumber != null) ...[
                  const SizedBox(height: AppSizes.xl),
                  DurationPicker(
                    durations: court.availableDurations,
                    selected: state.selectedDuration,
                    onSelect: cubit.selectDuration,
                  ),
                ],
                if (state.selectedDuration != null) ...[
                  const SizedBox(height: AppSizes.xl),
                  TimeSlotsGrid(
                    court: court,
                    timeSlots: _timeSlots,
                    bookedSlots: state.bookedSlots,
                    selectedTime: state.selectedTime,
                    loading: state.slotsLoading,
                    onSelect: cubit.selectTime,
                  ),
                ],
                if (state.allSelected) ...[
                  const SizedBox(height: AppSizes.xl),
                  BookingSummaryCard(
                    court: court,
                    date: state.selectedDate!,
                    courtNumber: state.selectedCourtNumber!,
                    time: state.selectedTime!,
                    durationMinutes: state.selectedDuration!,
                  ),
                ],
                const SizedBox(height: AppSizes.xxxl),
                BookingActionButtons(
                  canConfirm: state.allSelected,
                  submitting: state.isSubmitting,
                  onCancel: widget.onBack,
                  onConfirm: () => _confirm(context, state),
                ),
                const SizedBox(height: AppSizes.xl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Asks for confirmation, then delegates the booking to the cubit.
  void _confirm(BuildContext context, BookCourtState state) {
    final cubit = context.read<BookCourtCubit>();
    final message =
        'هل تريد تأكيد حجز ملعب ${state.selectedCourtNumber} بتاريخ '
        '${BookingDateUtils.shortDate(state.selectedDate!)} '
        'الساعة ${state.selectedTime}؟';

    showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          ),
          title: const Text('تأكيد الحجز'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                cubit.submitBooking();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
              ),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.success : AppColors.destructive,
      ),
    );
  }
}
