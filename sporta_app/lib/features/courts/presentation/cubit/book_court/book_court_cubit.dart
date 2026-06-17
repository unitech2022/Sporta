import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../auth/data/models/api_exception.dart';
import '../../../data/court_repository.dart';
import '../../../data/models/booking_result.dart';
import '../../../domain/entities/court_entity.dart';

part 'book_court_state.dart';

/// Drives the court booking screen: loading the court, fetching per-date
/// availability, tracking the user's selections and submitting the booking.
/// All HTTP work is delegated to [CourtRepository].
class BookCourtCubit extends Cubit<BookCourtState> {
  BookCourtCubit(this._repository) : super(const BookCourtState());

  final CourtRepository _repository;

  /// Loads the court identified by [courtId] (the string id used in navigation).
  Future<void> loadCourt(String? courtId, {bool isArabic = true}) async {
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
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: BookCourtStatus.failure,
        error: e.localized(isArabic),
      ));
    }
  }

  /// Selects a date and refreshes that day's availability. Downstream choices
  /// (court number, duration, time) are reset.
  Future<void> selectDate(DateTime date) async {
    emit(state.copyWith(
      selectedDate: date,
      clearCourtNumber: true,
      clearDuration: true,
      clearTime: true,
    ));
    await _loadAvailability(date);
  }

  void selectCourtNumber(int number) => emit(state.copyWith(
        selectedCourtNumber: number,
        clearDuration: true,
        clearTime: true,
      ));

  void selectDuration(int minutes) =>
      emit(state.copyWith(selectedDuration: minutes, clearTime: true));

  void selectTime(String time) => emit(state.copyWith(selectedTime: time));

  /// Submits the booking using the current selections.
  Future<void> submitBooking({bool isArabic = true}) async {
    final court = state.court;
    if (court == null || !state.allSelected) return;

    emit(state.copyWith(submission: BookingSubmission.submitting));

    final hour = int.tryParse(state.selectedTime!.split(':').first) ?? 0;
    final start = DateTime(
      state.selectedDate!.year,
      state.selectedDate!.month,
      state.selectedDate!.day,
      hour,
    );

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
        bookingError: e.localized(isArabic),
      ));
      // The slot may have just been taken — refresh availability.
      await _loadAvailability(state.selectedDate!);
    }
  }

  Future<void> _loadAvailability(DateTime date) async {
    final court = state.court;
    if (court == null) return;

    emit(state.copyWith(slotsLoading: true, bookedSlots: const {}));
    try {
      final slots = await _repository.fetchAvailability(court.numericId, date);
      emit(state.copyWith(
        slotsLoading: false,
        bookedSlots: slots.where((s) => s.isBooked).map((s) => s.time).toSet(),
      ));
    } on ApiException {
      // Treat all slots as available if availability can't be loaded.
      emit(state.copyWith(slotsLoading: false));
    }
  }
}
