import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/success_dialog.dart';
import '../../data/court_repository.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/court_entity.dart';
import 'booking_detail_page.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/gradient_page_header.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../payment/data/wallet_repository.dart';
import '../../../payment/presentation/pages/top_up_wallet_page.dart';
import '../../../payment/presentation/widgets/insufficient_balance_dialog.dart';
import '../../../payment/presentation/widgets/payment_confirm_dialog.dart';
import '../courts_helpers.dart';
import '../cubit/book_court/book_court_cubit.dart';
import '../widgets/book_court/booking_action_buttons.dart';
import '../widgets/book_court/booking_date_picker.dart';
import '../widgets/book_court/booking_date_utils.dart';
import '../widgets/book_court/booking_summary_card.dart';
import '../widgets/book_court/court_info_card.dart';
import '../widgets/book_court/court_number_picker.dart';
import '../widgets/book_court/duration_picker.dart';
import '../widgets/book_court/time_slots_grid.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/utils/system_insets.dart';
import 'package:sporta_app/core/utils/server_time.dart';

/// Court booking screen. Provides a [BookCourtCubit] and renders the booking
/// flow (date → court → duration → time → confirm) from its state.
class BookCourtPage extends StatelessWidget {
  const BookCourtPage({
    super.key,
    required this.onBack,
    this.courtId,
    this.onComplete,
    this.initialDate,
    this.initialTime,
    this.initialDuration,
  });

  final VoidCallback onBack;
  final String? courtId;
  final VoidCallback? onComplete;

  /// موعد مختار مسبقاً (من بطاقة البحث بالوقت): اليوم والوقت HH:mm والمدة.
  /// يُطبَّق ما بقي صالحاً منه بعد تحميل الملعب ومواعيده.
  final DateTime? initialDate;
  final String? initialTime;
  final int? initialDuration;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BookCourtCubit>(
      create: (_) => getIt<BookCourtCubit>()
        ..loadCourt(
          courtId,
          initialDate: initialDate,
          initialTime: initialTime,
          initialDuration: initialDuration,
        ),
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
  // Cached once: the next 15 selectable days.
  late final List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    final today = ksaNow();
    _dates = List.generate(15, (i) => today.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocConsumer<BookCourtCubit, BookCourtState>(
          listenWhen: (prev, curr) => prev.submission != curr.submission,
          listener: _onSubmissionChanged,
          builder: (context, state) {
            switch (state.status) {
              case BookCourtStatus.loading:
                return Column(
                  children: [
                    GradientPageHeader(
                      title: context.tr('حجز الملعب'),
                      onBack: widget.onBack,
                    ),
                    const Expanded(child: _BookCourtSkeleton()),
                  ],
                );
              case BookCourtStatus.failure:
                return Center(child: Text(state.error ?? context.tr('الملعب غير موجود')));
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
      // تُغلق صفحة الحجز ثم يظهر حوار النجاح؛ «متابعة» تفتح تفاصيل الحجز
      // والرجوع منها لا يعيد إلى حقول الحجز.
      final result = state.bookingResult;
      final nav = Navigator.of(context);
      final awaitingVenue = result?.status.toLowerCase() == 'pending';
      final title = context.tr('تم الحجز بنجاح');
      final message = awaitingVenue
          ? context.tr('في انتظار موافقة الملعب')
          : context.tr('تم تأكيد حجزك');
      final note =
          awaitingVenue ? context.tr('سيصلك إشعار في حال موافقة الملعب') : null;
      widget.onComplete?.call();
      showSuccessDialog(nav,
          title: title,
          message: message,
          note: note,
          onContinue: () async {
            if (result == null) return;
            final booking = await _findBooking(result.id);
            if (booking != null) {
              nav.push(MaterialPageRoute<void>(
                builder: (_) => BookingDetailPage(booking: booking),
              ));
            }
          });
    } else if (state.submission == BookingSubmission.failure) {
      if (state.bookingErrorCode == 'INSUFFICIENT_BALANCE') {
        _showInsufficientBalance(context);
      } else {
        _showSnack(state.bookingError ?? context.tr('تعذّر تحميل البيانات'),
            success: false);
      }
    }
  }

  /// الحجز الجديد من «حجوزاتي» (لا مسار لجلب حجز برقمه) — يكون في أولها.
  static Future<BookingEntity?> _findBooking(int id) async {
    try {
      final page = await getIt<CourtRepository>().fetchMyBookings(pageSize: 50);
      return page.items.where((b) => b.id == id).firstOrNull;
    } catch (_) {
      return null;
    }
  }

  Future<void> _showInsufficientBalance(BuildContext context) async {
    final requiredAmount =
        context.read<BookCourtCubit>().state.bookingTotalPrice ?? 0;

    final walletRepo = getIt<WalletRepository>();
    double balance = 0;
    try {
      final wallet = await walletRepo.fetchWallet();
      balance = wallet.balance;
    } catch (_) {}
    if (!mounted) return;

    final goTopUp = await showInsufficientBalanceDialog(
      context,
      currentBalance: balance,
      requiredAmount: requiredAmount,
    );

    if (goTopUp == true && mounted) {
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => TopUpWalletPage(
          currentBalance: balance.round(),
          onBack: () => Navigator.of(context).pop(),
          onComplete: () => Navigator.of(context).pop(),
        ),
      ));
    }
  }

  /// أيام الحجز المتاحة: نافذة النادي (مع أيام أولوية العضو) إن وُجدت.
  List<DateTime> _datesFor(CourtEntity court) {
    final window = court.bookingWindowDays;
    if (window == null || window + 1 >= _dates.length) return _dates;
    return _dates.take(window + 1).toList();
  }

  Widget _buildContent(BuildContext context, BookCourtState state) {
    final cubit = context.read<BookCourtCubit>();
    final court = state.court!;
    return Column(
      children: [
        GradientPageHeader(
          title: context.tr('حجز الملعب'),
          subtitle: court.name,
          onBack: widget.onBack,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: context
                .safeBottom(const EdgeInsets.all(AppSizes.pagePadding)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CourtInfoCard(court: court),
                const SizedBox(height: AppSizes.xl),
                BookingDatePicker(
                  dates: _datesFor(court),
                  selectedDate: state.selectedDate,
                  onSelect: cubit.selectDate,
                ),
                if (court.bookingWindowDays != null)
                  BookingWindowNote(
                    days: court.bookingWindowDays!,
                    isMember: court.isMember,
                  ),
                if (state.selectedDate != null) ...[
                  const SizedBox(height: AppSizes.xl),
                  CourtNumberPicker(
                    count: court.courtCount,
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
                    slots: state.availableSlots,
                    selectedTime: state.selectedTime,
                    loading: state.slotsLoading,
                    onSelect: cubit.selectTime,
                    dayClosed: state.dayClosed,
                    dayRangeLabel: state.dayRangeLabel,
                    day: state.selectedDate,
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
                    quote: state.quote,
                    quoteLoading: state.quoteLoading,
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

  /// Asks the user to confirm the wallet debit, then books.
  Future<void> _confirm(BuildContext context, BookCourtState state) async {
    final cubit = context.read<BookCourtCubit>();

    // تسعير الخادم هو ما سيُخصم فعلاً؛ التقدير المحلي احتياط فقط.
    final quote = state.quote;
    final total = quote?.total ??
        sessionTotalPrice(
                state.court!, state.selectedTime!, state.selectedDuration!)
            .toDouble();

    final confirmed = await showPaymentConfirmDialog(
      context,
      title: context.tr('تأكيد الحجز'),
      amount: total,
      details: [
        PaymentDetail(context.tr('الملعب'), '${state.selectedCourtNumber}'),
        PaymentDetail(context.tr('التاريخ'),
            BookingDateUtils.shortDate(state.selectedDate!)),
        PaymentDetail(context.tr('الوقت'), state.selectedTime!),
        // كبطاقة الملخص: خصم العضوية سطر مستقل عن خصم الباقة والعروض.
        if (quote != null && quote.memberDiscountAmount > 0)
          PaymentDetail(context.tr('خصم عضوية النادي'),
              trgArgs('- {p0} ر.س', {'p0': quote.memberDiscountAmount.toStringAsFixed(2)})),
        if (quote != null && quote.packageDiscountAmount >= 0.01)
          PaymentDetail(context.tr('خصم باقتك'),
              trgArgs('- {p0} ر.س', {'p0': quote.packageDiscountAmount.toStringAsFixed(2)})),
      ],
    );

    if (confirmed != true) return;
    cubit.submitBooking();
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

/// هيكل صفحة الحجز: بطاقة الملعب ثم شريط الأيام ثم رقم الملعب.
class _BookCourtSkeleton extends StatelessWidget {
  const _BookCourtSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const SkeletonBox(height: 96, radius: AppSizes.radiusXl),
          const SizedBox(height: AppSizes.xl),
          const SkeletonBox(width: 120, height: 16),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              for (var i = 0; i < 5; i++) ...[
                const Expanded(
                    child: SkeletonBox(height: 72, radius: AppSizes.radiusLg)),
                if (i != 4) const SizedBox(width: AppSizes.sm),
              ],
            ],
          ),
          const SizedBox(height: AppSizes.xl),
          const SkeletonBox(width: 100, height: 16),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                const Expanded(
                    child: SkeletonBox(height: 44, radius: AppSizes.radiusLg)),
                if (i != 2) const SizedBox(width: AppSizes.sm),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
