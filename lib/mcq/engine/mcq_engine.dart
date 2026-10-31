import "package:upgrade/mcq/models/mcq_models.dart";

/// The single place where an answer is graded.
/// Rule: a question is correct only when the selected set EXACTLY equals the
/// correct set. No partial credit and no negative marking (none specified).
class McqGrader {
  McqGrader._();
  static bool isCorrect(McqQuestion q, Set<String> selected) =>
      selected.isNotEmpty &&
      selected.length == q.correctOptionIds.length &&
      selected.containsAll(q.correctOptionIds);
}

enum McqAnswerStatus { correct, incorrect, unanswered }

class McqScore {
  final int total;
  final int correct;
  final int incorrect;
  const McqScore(this.total, this.correct, this.incorrect);

  int get answered => correct + incorrect;
  int get unanswered => total - answered;

  /// correct / total questions in the session (the ring on the result screen).
  double? get scoreOfTotal => total == 0 ? null : correct / total;

  /// correct / answered questions (labelled "Accuracy").
  double? get accuracyOfAnswered => answered == 0 ? null : correct / answered;
}

class McqReviewItem {
  final McqQuestion question;
  final Set<String> selected;
  final McqAnswerStatus status;
  const McqReviewItem(this.question, this.selected, this.status);
}

/// Pure-Dart practice session (no Flutter, no storage) so it is unit-testable.
class McqPracticeSession {
  McqPracticeSession(List<McqQuestion> questions,
      {Map<String, Set<String>>? submitted, int index = 0})
      : assert(questions.isNotEmpty, "a session needs at least one question"),
        questions = List.unmodifiable(questions),
        _submitted = {...?submitted},
        index = index.clamp(0, questions.length - 1).toInt();

  final List<McqQuestion> questions;
  final Map<String, Set<String>> _submitted;
  int index;
  Set<String> _draft = {};

  McqQuestion get current => questions[index];
  bool get isSubmitted => _submitted.containsKey(current.id);
  Set<String> get selected => isSubmitted ? _submitted[current.id]! : _draft;
  bool get canSubmit => !isSubmitted && _draft.isNotEmpty;
  bool get isLast => index == questions.length - 1;
  bool get isFinished => questions.every((q) => _submitted.containsKey(q.id));
  bool get currentIsCorrect =>
      isSubmitted && McqGrader.isCorrect(current, _submitted[current.id]!);
  int get submittedCount => _submitted.length;
  Map<String, Set<String>> get submittedAnswers =>
      Map.unmodifiable(_submitted);

  /// Select / deselect. Single-answer replaces; multiple-answer toggles.
  /// Ignored once the question has been submitted.
  void toggle(String optionId) {
    if (isSubmitted || !current.options.any((o) => o.id == optionId)) return;
    if (current.type == McqQuestionType.single) {
      _draft = {optionId};
    } else {
      final next = Set<String>.of(_draft);
      if (!next.remove(optionId)) next.add(optionId);
      _draft = next;
    }
  }

  /// Locks the answer. Returns false (and changes nothing) if there is no
  /// selection or the question was already submitted, so a double tap can
  /// never score twice.
  bool submit() {
    if (!canSubmit) return false;
    _submitted[current.id] = Set<String>.of(_draft);
    return true;
  }

  void next() {
    if (!isSubmitted || isLast) return;
    index++;
    _draft = {};
  }

  McqScore get score {
    var correct = 0, incorrect = 0;
    for (final q in questions) {
      final s = _submitted[q.id];
      if (s == null) continue;
      McqGrader.isCorrect(q, s) ? correct++ : incorrect++;
    }
    return McqScore(questions.length, correct, incorrect);
  }

  List<McqReviewItem> get reviewItems => [
        for (final q in questions)
          McqReviewItem(
            q,
            _submitted[q.id] ?? const {},
            _submitted[q.id] == null
                ? McqAnswerStatus.unanswered
                : (McqGrader.isCorrect(q, _submitted[q.id]!)
                    ? McqAnswerStatus.correct
                    : McqAnswerStatus.incorrect),
          )
      ];
}
