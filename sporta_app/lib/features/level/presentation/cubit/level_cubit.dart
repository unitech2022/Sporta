import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/data/models/api_exception.dart';
import '../../data/level_repository.dart';
import '../../domain/level_question.dart';

part 'level_state.dart';

/// Drives the level self-assessment: question navigation, answer tracking and
/// submitting to the backend. Networking is delegated to [LevelRepository].
class LevelCubit extends Cubit<LevelState> {
  LevelCubit(this._repository) : super(const LevelState());

  final LevelRepository _repository;

  /// Loads the admin-defined questions for [sport] and prepares the answers.
  Future<void> loadQuestions(String sport, {bool isArabic = true}) async {
    emit(state.copyWith(status: LevelStatus.loading, error: null));
    try {
      final questions = await _repository.fetchQuestions(sport);
      emit(state.copyWith(
        status: LevelStatus.answering,
        questions: questions,
        answers: List<int?>.filled(questions.length, null),
        index: 0,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
          status: LevelStatus.failure, error: e.display));
    }
  }

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
        error: e.display,
      ));
    }
  }
}
