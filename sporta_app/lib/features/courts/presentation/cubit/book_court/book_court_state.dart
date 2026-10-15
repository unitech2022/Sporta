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
    this.availableSlots = const [],
    this.slotsLoading = false,
    this.dayClosed = false,
    this.dayRangeLabel = '',
    this.quote,
    this.quoteLoading = false,
    this.submission = BookingSubmission.idle,
    this.bookingError,
    this.bookingErrorCode,
    this.bookingTotalPrice,
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

  // Availability for the selected date + duration. Slot times/prices are
  // stepped by the chosen duration (e.g. every 120 min for a 120-min session).
  final List<CourtSlot> availableSlots;
  final bool slotsLoading;

  /// الملعب مغلق في اليوم المختار حسب دوام أسبوعه (لا مواعيد إطلاقاً).
  final bool dayClosed;

  /// دوام اليوم المختار للعرض، مثل "06:00 - 24:00".
  final String dayRangeLabel;

  /// تسعير الخادم للموعد المختار (السعر بعد قواعد المالك وخصم الباقة).
  final BookingQuote? quote;
  final bool quoteLoading;

  // Submission feedback.
  final BookingSubmission submission;
  final String? bookingError;
  final String? bookingErrorCode;
  final double? bookingTotalPrice;
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
    List<CourtSlot>? availableSlots,
    bool? slotsLoading,
    bool? dayClosed,
    String? dayRangeLabel,
    BookingQuote? quote,
    bool? quoteLoading,
    BookingSubmission? submission,
    String? bookingError,
    String? bookingErrorCode,
    double? bookingTotalPrice,
    BookingResult? bookingResult,
    bool clearCourtNumber = false,
    bool clearDuration = false,
    bool clearTime = false,
    bool clearQuote = false,
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
      availableSlots: availableSlots ?? this.availableSlots,
      slotsLoading: slotsLoading ?? this.slotsLoading,
      dayClosed: dayClosed ?? this.dayClosed,
      dayRangeLabel: dayRangeLabel ?? this.dayRangeLabel,
      quote: clearQuote || clearTime ? quote : (quote ?? this.quote),
      quoteLoading: quoteLoading ?? this.quoteLoading,
      submission: submission ?? this.submission,
      bookingError: bookingError,
      bookingErrorCode: bookingErrorCode,
      bookingTotalPrice: bookingTotalPrice ?? this.bookingTotalPrice,
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
        availableSlots,
        slotsLoading,
        dayClosed,
        dayRangeLabel,
        quote,
        quoteLoading,
        submission,
        bookingError,
        bookingErrorCode,
        bookingTotalPrice,
        bookingResult,
      ];
}
