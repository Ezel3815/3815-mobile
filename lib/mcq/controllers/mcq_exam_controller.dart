import 'dart:async';
import 'package:get/get.dart';
import 'package:upgrade/mcq/controllers/mcq_controllers.dart';
import 'package:upgrade/mcq/data/mcq_progress_store.dart';
import 'package:upgrade/mcq/engine/mcq_engine.dart';
import 'package:upgrade/mcq/engine/mcq_exam_engine.dart';

class McqExamOutcome {
  final McqScore score;
  final bool expired;
  final int elapsedMs;
  final List<McqReviewItem> items;
  const McqExamOutcome(this.score, this.expired, this.elapsedMs, this.items);
}

/// Runs one exam: clock, persistence and submission. Rules live in
/// [McqExamSession]; this class only coordinates them with time and storage.
class McqExamController extends GetxController {
  McqExamController({
    required this.bank,
    required this.session,
    required this.title,
    required this.examId,
    required this.limitMinutes,
    this.endAtMs,
    int priorElapsedMs = 0,
  }) : _priorMs = priorElapsedMs;

  final McqBankController bank;
  final McqExamSession session;
  final String title;
  final String examId;
  final int limitMinutes;
  final int? endAtMs;
  final int _priorMs;
  final Stopwatch _watch = Stopwatch()..start();

  final tick = 0.obs;
  final remainingMs = 0.obs;
  final outcome = Rxn<McqExamOutcome>();

  Timer? _timer;
  bool _submitting = false;

  bool get timed => endAtMs != null;
  int get elapsedMs => _priorMs + _watch.elapsedMilliseconds;
  void _bump() => tick.value++;

  bool _started = false;

  /// Starts the clock. Called by the exam screen (this controller is created
  /// by hand, not via Get.put, so GetX lifecycle hooks are not used).
  void start() {
    if (_started) return;
    _started = true;
    if (timed) {
      checkClock();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => checkClock());
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Recomputes time left from the wall clock (also called when the app
  /// returns to the foreground) and auto-submits at zero.
  void checkClock() {
    if (!timed || session.isFinalized) return;
    final rem = endAtMs! - DateTime.now().millisecondsSinceEpoch;
    remainingMs.value = rem < 0 ? 0 : rem;
    if (rem <= 0) submit(expired: true);
  }

  void toggle(String optionId) {
    if (session.isFinalized) return;
    session.toggle(optionId);
    persist();
    _bump();
  }

  void goTo(int i) {
    if (session.isFinalized) return;
    session.goTo(i);
    persist();
    _bump();
  }

  void next() => goTo(session.index + 1);
  void prev() => goTo(session.index - 1);

  bool get isBookmarked => bank.isBookmarked(session.current.id);
  Future<void> toggleBookmark() async {
    await bank.toggleBookmark(session.current.id);
    _bump();
  }

  void persist() {
    if (session.isFinalized || _submitting) return;
    bank.store.saveExam(McqExamSnapshot(
      id: examId,
      title: title,
      questionIds: [for (final q in session.questions) q.id],
      answers: {
        for (final e in session.answers.entries) e.key: e.value.toList()
      },
      index: session.index,
      endAtMs: endAtMs,
      limitMinutes: limitMinutes,
      elapsedMs: elapsedMs,
    ));
  }

  /// Finalizes exactly once, no matter how many times it is called
  /// (button double-tap, timer firing under the confirm dialog, ...).
  Future<void> submit({bool expired = false}) async {
    if (_submitting || session.isFinalized) return;
    _submitting = true;
    _timer?.cancel();
    final score = session.finalize();
    final items = session.reviewItems;
    final now = DateTime.now().millisecondsSinceEpoch;
    final limitMs = limitMinutes * 60000;
    final spent = (expired && timed) ? limitMs : elapsedMs;

    await bank.store.addAttempts([
      for (final i in items)
        if (i.status != McqAnswerStatus.unanswered)
          McqAttempt(i.question.id, i.selected.toList(),
              i.status == McqAnswerStatus.correct, now, examId)
    ]);
    await bank.store.addSession(McqSessionRecord(
      id: examId,
      mode: 'exam',
      title: title,
      total: score.total,
      correct: score.correct,
      incorrect: score.incorrect,
      elapsedMs: spent,
      atMs: now,
    ));
    await bank.store.clearExam();
    bank.notifyProgress();
    outcome.value = McqExamOutcome(score, expired, spent, items);
  }
}
