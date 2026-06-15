import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/data/models/api_exception.dart';
import '../../data/level_repository.dart';

part 'level_state.dart';

/// Drives the level self-assessment: question navigation, answer tracking and
/// submitting to the backend. Networking is delegated to [LevelRepository].
class LevelCubit extends Cubit<LevelState> {
  LevelCubit(this._repository) : super(const LevelState());

  final LevelRepository _repository;

  /// Initialises the answers list for [questionCount] questions.
  void init(int questionCount) =>
      emit(state.copyWith(answers: List<int?>.filled(questionCount, null)));

  /// Records the chosen option [score] for the current question.
  void selectAnswer(int score) {
    final answers = List<int?>.from(state.answers);
    answers[state.index] = score;
    emit(state.copyWith(answers: answers, error: null));
  }

  /// Moves to the previous question (no-op on the first question).
  void previous() {
    if (state.index > 0) {
      emit(state.copyWith(index: state.index - 1, error: null));
    }
  }

  /// Advances to the next question, or submits when on the last one.
  Future<void> submitOrNext({
    required String sport,
    required bool isArabic,
  }) async {
    if (!state.isLast) {
      emit(state.copyWith(index: state.index + 1, error: null));
      return;
    }
    await _submit(sport: sport, isArabic: isArabic);
  }

  Future<void> _submit({required String sport, required bool isArabic}) async {
    emit(state.copyWith(status: LevelStatus.submitting, error: null));
    try {
      final result = await _repository.submitAssessment(
        sport: sport,
        answers: state.answers.cast<int>(),
      );
      emit(state.copyWith(status: LevelStatus.success, result: result));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: LevelStatus.answering,
        error: e.localized(isArabic),
      ));
    }
  }
}
