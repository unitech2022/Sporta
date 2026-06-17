part of 'level_cubit.dart';

enum LevelStatus { answering, submitting, success, failure }

class LevelState extends Equatable {
  const LevelState({
    this.index = 0,
    this.answers = const [],
    this.status = LevelStatus.answering,
    this.error,
    this.result,
  });

  /// Index of the question currently shown.
  final int index;

  /// Chosen option score per question (null until answered).
  final List<int?> answers;

  final LevelStatus status;
  final String? error;
  final LevelAssessmentResult? result;

  bool get isSubmitting => status == LevelStatus.submitting;

  /// Whether the current question has been answered.
  bool get currentAnswered =>
      index < answers.length && answers[index] != null;

  /// Whether the current question is the last one.
  bool get isLast => index == answers.length - 1;

  bool get atFirstQuestion => index == 0;

  LevelState copyWith({
    int? index,
    List<int?>? answers,
    LevelStatus? status,
    String? error,
    LevelAssessmentResult? result,
  }) {
    return LevelState(
      index: index ?? this.index,
      answers: answers ?? this.answers,
      status: status ?? this.status,
      error: error,
      result: result ?? this.result,
    );
  }

  @override
  List<Object?> get props => [index, answers, status, error, result];
}
