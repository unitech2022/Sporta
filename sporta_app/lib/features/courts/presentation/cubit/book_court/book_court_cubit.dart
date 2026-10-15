import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../auth/data/models/api_exception.dart';
import '../../../data/court_repository.dart';
import '../../../data/models/booking_quote.dart';
import '../../../data/models/booking_result.dart';
import '../../../data/models/court_slot.dart';
import '../../../domain/entities/court_entity.dart';
import '../../courts_helpers.dart';

part 'book_court_state.dart';

/// Drives the court booking screen: loading the court, fetching per-date
/// availability, tracking the user's selections and submitting the booking.
/// All HTTP work is delegated to [CourtRepository].
class BookCourtCubit extends Cubit<BookCourtState> {
  BookCourtCubit(this._repository) : super(const BookCourtState());

  final CourtRepository _repository;

  /// Loads the court identified by [courtId] (the string id used in navigation).
  ///
  /// [initialDate]/[initialTime]/[initialDuration]: موعد اختاره اللاعب من بطاقة
  /// البحث بالوقت — تُملأ الخطوات به، والوقت لا يُختار إلا إن بقي فارغاً.
  Future<void> loadCourt(
    String? courtId, {
    bool isArabic = true,
    DateTime? initialDate,
    String? initialTime,
    int? initialDuration,
  }) async {
    final id = int.tryParse(courtId ?? '');
    if (id == null) {
      emit(state.copyWith(
        status: BookCourtStatus.failure,
        error: isArabic ? 'الملعب غير موجود' : 'Court not found',
      ));
      return;
    }

    emit(state.copyWith(status: BookCourtStatus.loading, error: null));
    try {
      final court = await _repository.fetchCourtById(id);
      emit(state.copyWith(status: BookCourtStatus.ready, court: court));
      if (initialDate != null) {
        await _applyPreset(court, initialDate, initialTime, initialDuration);
      }
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: BookCourtStatus.failure,
        error: e.display,
      ));
    }
  }

  /// يملأ اليوم ورقم الملعب (الأول — الرقم للعرض ولا يغيّر التوفر) والمدة
  /// إن كان الملعب يقبلها، ثم الوقت إن ظهر فارغاً في المواعيد الحديثة.
  Future<void> _applyPreset(
    CourtEntity court,
    DateTime date,
    String? time,
    int? duration,
  ) async {
    selectDate(DateTime(date.year, date.month, date.day));
    selectCourtNumber(1);
    if (duration == null || !court.availableDurations.contains(duration)) {
      return;
    }
    await selectDuration(duration);
    if (isClosed || time == null) return;
    final free = state.availableSlots.any((s) => s.time == time && !s.isBooked);
    if (free) await selectTime(time);
  }

  /// Selects a date. Downstream choices (court number, duration, time) are
  /// reset; availability is only fetched once a duration is chosen, since the
  /// slot times themselves depend on it.
  void selectDate(DateTime date) => emit(state.copyWith(
        selectedDate: date,
        clearCourtNumber: true,
        clearDuration: true,
        clearTime: true,
        availableSlots: const [],
      ));

  void selectCourtNumber(int number) => emit(state.copyWith(
        selectedCourtNumber: number,
        clearDuration: true,
        clearTime: true,
        availableSlots: const [],
      ));

  /// Selects a session duration and refreshes availability stepped to match
  /// it (e.g. every 120 minutes for a 120-minute session).
  Future<void> selectDuration(int minutes) async {
    emit(state.copyWith(selectedDuration: minutes, clearTime: true));
    if (state.selectedDate != null) {
      await _loadAvailability(state.selectedDate!, minutes);
    }
  }

  /// اختيار الوقت يجلب تسعير الخادم فوراً حتى يرى اللاعب السعر الحقيقي
  /// (قواعد تسعير المالك + خصم باقته) قبل التأكيد لا بعد الخصم.
  Future<void> selectTime(String time) async {
    emit(state.copyWith(selectedTime: time, quoteLoading: true, clearQuote: true));
    await _loadQuote();
  }

  Future<void> _loadQuote() async {
    final court = state.court;
    if (court == null ||
        state.selectedDate == null ||
        state.selectedTime == null ||
        state.selectedDuration == null) {
      emit(state.copyWith(quoteLoading: false));
      return;
    }
    try {
      final quote = await _repository.quoteBooking(
        courtId: court.numericId,
        startTime: _startDateTime(),
        durationMinutes: state.selectedDuration!,
      );
      emit(state.copyWith(quote: quote, quoteLoading: false));
    } on ApiException {
      // التسعير معلومة عرض فقط — الفشل يعيدنا للتقدير المحلي بلا رسالة خطأ.
      emit(state.copyWith(quoteLoading: false));
    }
  }

  /// يحوّل التاريخ والوقت المختارين إلى DateTime واحد.
  DateTime _startDateTime() {
    final parts = state.selectedTime!.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(
      state.selectedDate!.year,
      state.selectedDate!.month,
      state.selectedDate!.day,
      hour,
      minute,
    );
  }

  /// Submits the booking using the current selections.
  Future<void> submitBooking({bool isArabic = true}) async {
    final court = state.court;
    if (court == null || !state.allSelected) return;

    // تسعير الخادم هو المرجع؛ التقدير المحلي احتياط حين تعذّر جلبه.
    final totalPrice = state.quote?.total ??
        sessionTotalPrice(
          court,
          state.selectedTime!,
          state.selectedDuration!,
        ).toDouble();

    emit(state.copyWith(
      submission: BookingSubmission.submitting,
      bookingTotalPrice: totalPrice,
    ));

    final start = _startDateTime();

    try {
      final result = await _repository.createBooking(
        courtId: court.numericId,
        startTime: start,
        durationMinutes: state.selectedDuration!,
      );
      emit(state.copyWith(
        submission: BookingSubmission.success,
        bookingResult: result,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        submission: BookingSubmission.failure,
        bookingError: e.display,
        bookingErrorCode: e.code,
      ));
      // The slot may have just been taken — refresh availability.
      await _loadAvailability(state.selectedDate!, state.selectedDuration!);
    }
  }

  Future<void> _loadAvailability(DateTime date, int durationMinutes) async {
    final court = state.court;
    if (court == null) return;

    emit(state.copyWith(
        slotsLoading: true, availableSlots: const [], dayClosed: false));
    try {
      final day = await _repository.fetchAvailability(
        court.numericId,
        date,
        durationMinutes: durationMinutes,
      );
      emit(state.copyWith(
        slotsLoading: false,
        availableSlots: day.slots,
        // اليوم المغلق في دوام الملعب يُشرح للاعب بدل قائمة فارغة بلا سبب.
        dayClosed: day.isClosed,
        dayRangeLabel: day.rangeLabel,
      ));
    } on ApiException {
      // Treat all slots as available if availability can't be loaded.
      emit(state.copyWith(slotsLoading: false));
    }
  }
}
