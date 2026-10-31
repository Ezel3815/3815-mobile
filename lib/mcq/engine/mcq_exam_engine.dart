import 'package:upgrade/mcq/engine/mcq_engine.dart';
import 'package:upgrade/mcq/models/mcq_models.dart';

/// Exam settings chosen on the setup screen.
class McqExamConfig {
  final int count;
  final int timeLimitMinutes; // 0 = untimed
  final bool randomize;
  const McqExamConfig({
    required this.count,
    this.timeLimitMinutes = 0,
    this.randomize = true,
  });
  bool get timed => timeLimitMinutes > 0;
}

/// Pure-Dart exam session. Unlike practice, nothing is graded or revealed
/// until [finalize]; answers can be changed freely until then.
class McqExamSession {
  McqExamSession(List<McqQuestion> questions,
      {Map<String, Set<String>>? answers, int index = 0})
      : assert(questions.isNotEmpty, "an exam needs at least one question"),
        questions = List.unmodifiable(questions),
        _answers = {
          for (final e in (answers ?? const <String, Set<String>>{}).entries)
            if (e.value.isNotEmpty) e.key: Set<String>.of(e.value)
        },
        index = index.clamp(0, questions.length - 1).toInt();

  final List<McqQuestion> questions;
  final Map<String, Set<String>> _answers;
  int index;
  bool _finalized = false;
  McqScore? _finalScore;

  McqQuestion get current => questions[index];
  bool get isFinalized => _finalized;
  Set<String> get selected => _answers[current.id] ?? const <String>{};
  bool isAnswered(int i) => _answers.containsKey(questions[i].id);
  int get answeredCount => _answers.length;
  int get unansweredCount => questions.length - _answers.length;
  bool get isLast => index == questions.length - 1;
  bool get isFirst => index == 0;
  Map<String, Set<String>> get answers => Map.unmodifiable(_answers);

  /// Single answer: tap selects, tapping the same option clears it.
  /// Multiple answer: toggles. Ignored after finalization.
  void toggle(String optionId) {
    if (_finalized || !current.options.any((o) => o.id == optionId)) return;
    final cur = Set<String>.of(selected);
    if (current.type == McqQuestionType.single) {
      if (cur.contains(optionId)) {
        _answers.remove(current.id);
      } else {
        _answers[current.id] = {optionId};
      }
      return;
    }
    if (!cur.remove(optionId)) cur.add(optionId);
    if (cur.isEmpty) {
      _answers.remove(current.id);
    } else {
      _answers[current.id] = cur;
    }
  }

  void goTo(int i) {
    if (i >= 0 && i < questions.length) index = i;
  }

  void next() => goTo(index + 1);
  void prev() => goTo(index - 1);

  McqScore _compute() {
    var ok = 0, bad = 0;
    for (final q in questions) {
      final a = _answers[q.id];
      if (a == null) continue;
      McqGrader.isCorrect(q, a) ? ok++ : bad++;
    }
    return McqScore(questions.length, ok, bad);
  }

  /// Locks the exam and grades it. Idempotent: calling it again (double tap,
  /// timer firing while the confirm dialog is open) returns the same score
  /// and changes nothing, so an exam can never be finalized twice.
  McqScore finalize() {
    if (_finalized) return _finalScore!;
    _finalized = true;
    return _finalScore = _compute();
  }

  List<McqReviewItem> get reviewItems => [
        for (final q in questions)
          McqReviewItem(
            q,
            _answers[q.id] ?? const <String>{},
            _answers[q.id] == null
                ? McqAnswerStatus.unanswered
                : (McqGrader.isCorrect(q, _answers[q.id]!)
                    ? McqAnswerStatus.correct
                    : McqAnswerStatus.incorrect),
          )
      ];

  /// Picks the exam question set from [pool].
  static List<McqQuestion> pick(
    List<McqQuestion> pool,
    McqExamConfig config, {
    List<McqQuestion> Function(List<McqQuestion>)? shuffler,
  }) {
    final list = [...pool];
    if (config.randomize) {
      if (shuffler != null) {
        return shuffler(list).take(config.count).toList();
      }
      list.shuffle();
    }
    return list.take(config.count).toList();
  }

  /// Offered question-count options, never more than available.
  static List<int> countOptions(int available) {
    if (available <= 0) return const [];
    return [
      for (final n in const [10, 20, 50])
        if (n < available) n,
      available,
    ];
  }
}
