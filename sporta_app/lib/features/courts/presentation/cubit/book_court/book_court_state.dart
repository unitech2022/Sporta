part of 'book_court_cubit.dart';

/// Lifecycle of the court fetch that backs the booking screen.
enum BookCourtStatus { loading, ready, failure }

/// Lifecycle of the booking submission.
enum BookingSubmission { idle, submitting, success, failure }

class BookCourtState extends Equatable {
  const BookCourtState({
    this.status = BookCourtStatus.loading,
    this.court,
    this.error,
    this.selectedDate,
    this.selectedCourtNumber,
    this.selectedDuration,
    this.selectedTime,
    this.bookedSlots = const {},
    this.slotsLoading = false,
    this.submission = BookingSubmission.idle,
    this.bookingError,
    this.bookingResult,
  });

  final BookCourtStatus status;
  final CourtEntity? court;
  final String? error;

  // User selections.
  final DateTime? selectedDate;
  final int? selectedCourtNumber;
  final int? selectedDuration;
  final String? selectedTime;

  // Availability for the selected date.
  final Set<String> bookedSlots;
  final bool slotsLoading;

  // Submission feedback.
  final BookingSubmission submission;
  final String? bookingError;
  final BookingResult? bookingResult;

  bool get allSelected =>
      selectedDate != null &&
      selectedCourtNumber != null &&
      selectedDuration != null &&
      selectedTime != null;

  bool get isSubmitting => submission == BookingSubmission.submitting;

  BookCourtState copyWith({
    BookCourtStatus? status,
    CourtEntity? court,
    String? error,
    DateTime? selectedDate,
    int? selectedCourtNumber,
    int? selectedDuration,
    String? selectedTime,
    Set<String>? bookedSlots,
    bool? slotsLoading,
    BookingSubmission? submission,
    String? bookingError,
    BookingResult? bookingResult,
    bool clearCourtNumber = false,
    bool clearDuration = false,
    bool clearTime = false,
  }) {
    return BookCourtState(
      status: status ?? this.status,
      court: court ?? this.court,
      error: error,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedCourtNumber:
          clearCourtNumber ? null : (selectedCourtNumber ?? this.selectedCourtNumber),
      selectedDuration:
          clearDuration ? null : (selectedDuration ?? this.selectedDuration),
      selectedTime: clearTime ? null : (selectedTime ?? this.selectedTime),
      bookedSlots: bookedSlots ?? this.bookedSlots,
      slotsLoading: slotsLoading ?? this.slotsLoading,
      submission: submission ?? this.submission,
      bookingError: bookingError,
      bookingResult: bookingResult ?? this.bookingResult,
    );
  }

  @override
  List<Object?> get props => [
        status,
        court,
        error,
        selectedDate,
        selectedCourtNumber,
        selectedDuration,
        selectedTime,
        bookedSlots,
        slotsLoading,
        submission,
        bookingError,
        bookingResult,
      ];
}
