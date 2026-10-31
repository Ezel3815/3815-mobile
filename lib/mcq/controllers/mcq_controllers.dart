import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:upgrade/mcq/data/mcq_api_repository.dart';
import 'package:upgrade/mcq/data/mcq_progress_store.dart';
import 'package:upgrade/mcq/data/mcq_repository.dart';
import 'package:upgrade/mcq/controllers/mcq_exam_controller.dart';
import 'package:upgrade/mcq/engine/mcq_engine.dart';
import 'package:upgrade/mcq/engine/mcq_exam_engine.dart';
import 'package:upgrade/mcq/engine/mcq_stats.dart';
import 'package:upgrade/mcq/models/mcq_models.dart';

/// Catalog + study progress for the whole MCQ section.
/// Registered without `permanent`, so it is disposed with the main route
/// (e.g. on logout) and the next user gets a fresh, correctly scoped store.
class McqBankController extends GetxController {
  McqBankController({McqRepository? repository})
      : _repo = repository ?? ApiMcqRepository();

  static McqBankController ensure() => Get.isRegistered<McqBankController>()
      ? Get.find<McqBankController>()
      : Get.put(McqBankController());

  final McqRepository _repo;
  final loading = true.obs;
  final loadFailed = false.obs;
  final catalog = Rxn<McqCatalog>();

  /// Bumped after any change to bookmarks / attempts / resume so that
  /// screens wrapped in Obx (and reading [tick]) rebuild.
  final tick = 0.obs;
  final query = ''.obs;

  McqProgressStore? _store;
  McqProgressStore get store => _store!;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void notifyProgress() => tick.value++;

  Future<void> load() async {
    loading.value = true;
    loadFailed.value = false;
    try {
      _store ??= await McqProgressStore.open();
      catalog.value = await _repo.load();
    } catch (e, st) {
      debugPrint('MCQ load failed: $e\n$st');
      loadFailed.value = true;
    } finally {
      loading.value = false;
      notifyProgress();
    }
  }

  /// Re-reads the catalog without showing the full-screen spinner
  /// (pull-to-refresh). On failure the current content stays on screen.
  Future<void> refresh() async {
    try {
      catalog.value = await _repo.load();
    } catch (e) {
      debugPrint('MCQ refresh failed: $e');
    } finally {
      notifyProgress();
    }
  }

  McqCatalog? get cat => catalog.value;
  bool get hasQuestions => cat != null && !cat!.isEmpty;

  // ---- bookmarks ----
  bool isBookmarked(String id) => _store?.bookmarks.contains(id) ?? false;
  Future<void> toggleBookmark(String id) async {
    await _store?.toggleBookmark(id);
    notifyProgress();
  }

  // ---- review ----
  int get needsReviewCount {
    final c = cat;
    if (c == null || _store == null) return 0;
    return _store!.needsReviewIds.where((id) => c.questionById(id) != null).length;
  }

  List<McqReviewItem> incorrectItems() {
    final c = cat;
    if (c == null || _store == null) return const [];
    final latest = _store!.latestByQuestion;
    return [
      for (final id in _store!.needsReviewIds)
        if (c.questionById(id) != null)
          McqReviewItem(c.questionById(id)!, latest[id]!.selected.toSet(),
              McqAnswerStatus.incorrect)
    ];
  }

  List<McqReviewItem> bookmarkedItems() {
    final c = cat;
    if (c == null || _store == null) return const [];
    final latest = _store!.latestByQuestion;
    final out = <McqReviewItem>[];
    for (final id in _store!.bookmarks) {
      final q = c.questionById(id);
      if (q == null) continue;
      final a = latest[id];
      out.add(McqReviewItem(
        q,
        a == null ? const {} : a.selected.toSet(),
        a == null
            ? McqAnswerStatus.unanswered
            : (a.correct ? McqAnswerStatus.correct : McqAnswerStatus.incorrect),
      ));
    }
    return out;
  }

  int incorrectCountIn(List<McqQuestion> qs) {
    final need = _store?.needsReviewIds ?? const <String>{};
    return qs.where((q) => need.contains(q.id)).length;
  }

  // ---- exams ----
  McqExamController startExam({
    required String title,
    required List<McqQuestion> pool,
    required McqExamConfig config,
  }) {
    final qs = McqExamSession.pick(pool, config);
    final now = DateTime.now().millisecondsSinceEpoch;
    final c = McqExamController(
      bank: this,
      session: McqExamSession(qs),
      title: title,
      examId: '$now',
      limitMinutes: config.timeLimitMinutes,
      endAtMs: config.timed ? now + config.timeLimitMinutes * 60000 : null,
    );
    c.persist(); // resumable from the very first second
    return c;
  }

  /// The unfinished exam, if any of its questions still exist.
  McqExamSnapshot? get examSnapshot {
    final e = _store?.exam;
    final c = cat;
    if (e == null || c == null) return null;
    return e.questionIds.any((id) => c.questionById(id) != null) ? e : null;
  }

  Future<void> discardExam() async {
    await _store?.clearExam();
    notifyProgress();
  }

  McqExamController? resumeExam() {
    final e = _store?.exam;
    final c = cat;
    if (e == null || c == null) return null;
    final qs = <McqQuestion>[];
    for (final id in e.questionIds) {
      final q = c.questionById(id);
      if (q != null) qs.add(q);
    }
    if (qs.isEmpty) {
      discardExam();
      return null;
    }
    final known = {for (final q in qs) q.id};
    return McqExamController(
      bank: this,
      session: McqExamSession(
        qs,
        answers: {
          for (final a in e.answers.entries)
            if (known.contains(a.key)) a.key: a.value.toSet()
        },
        index: e.index,
      ),
      title: e.title,
      examId: e.id,
      limitMinutes: e.limitMinutes,
      endAtMs: e.endAtMs,
      priorElapsedMs: e.elapsedMs,
    );
  }

  // ---- stats ----
  McqStats get stats {
    final c = cat;
    return McqStats.compute(
      attempts: _store?.attempts ?? const [],
      sessions: _store?.sessions ?? const [],
      subjectOfQuestion: {
        if (c != null)
          for (final q in c.questions) q.id: q.subjectId
      },
    );
  }

  // ---- sessions ----
  /// Unseen questions first, then ones already seen; capped at [limit].
  List<McqQuestion> quickPracticeQuestions({int limit = 10}) {
    final c = cat;
    if (c == null || c.isEmpty || _store == null) return const [];
    final tried = _store!.latestByQuestion.keys.toSet();
    final fresh = c.questions.where((q) => !tried.contains(q.id)).toList()..shuffle();
    final seen = c.questions.where((q) => tried.contains(q.id)).toList()..shuffle();
    return [...fresh, ...seen].take(limit).toList();
  }

  McqSessionController startSession({
    required String title,
    required List<McqQuestion> questions,
    bool shuffle = false,
  }) {
    final qs = [...questions];
    if (shuffle) qs.shuffle();
    return McqSessionController(
      bank: this,
      session: McqPracticeSession(qs),
      title: title,
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  McqResume? get resume {
    final r = _store?.resume;
    final c = cat;
    if (r == null || c == null) return null;
    return r.questionIds.any((id) => c.questionById(id) != null) ? r : null;
  }

  McqSessionController? resumeSession() {
    final r = _store?.resume;
    final c = cat;
    if (r == null || c == null) return null;
    final qs = <McqQuestion>[];
    for (final id in r.questionIds) {
      final q = c.questionById(id);
      if (q != null) qs.add(q);
    }
    if (qs.isEmpty) {
      _store!.clearResume();
      notifyProgress();
      return null;
    }
    final known = {for (final q in qs) q.id};
    final submitted = <String, Set<String>>{
      for (final e in r.submitted.entries)
        if (known.contains(e.key)) e.key: e.value.toSet()
    };
    return McqSessionController(
      bank: this,
      session: McqPracticeSession(qs, submitted: submitted, index: r.index),
      title: r.title,
      sessionId: r.sessionId,
      priorElapsedMs: r.elapsedMs,
    );
  }
}

/// One practice run. Thin wrapper: all rules live in [McqPracticeSession].
class McqSessionController extends GetxController {
  McqSessionController({
    required this.bank,
    required this.session,
    required this.title,
    required this.sessionId,
    int priorElapsedMs = 0,
  }) : _priorMs = priorElapsedMs;

  final McqBankController bank;
  final McqPracticeSession session;
  final String title;
  final String sessionId;
  final int _priorMs;
  final Stopwatch _watch = Stopwatch()..start();
  bool _done = false;

  /// Bumped on every change; screens read it inside Obx.
  final tick = 0.obs;
  void _bump() => tick.value++;

  McqQuestion get question => session.current;
  int get elapsedMs => _priorMs + _watch.elapsedMilliseconds;
  bool get isBookmarked => bank.isBookmarked(question.id);

  void toggle(String optionId) {
    session.toggle(optionId);
    _bump();
  }

  void submit() {
    final q = session.current;
    if (!session.submit()) return; // nothing selected / already submitted
    bank.store.addAttempt(McqAttempt(
      q.id,
      session.selected.toList(),
      McqGrader.isCorrect(q, session.selected),
      DateTime.now().millisecondsSinceEpoch,
      sessionId,
    ));
    persist();
    bank.notifyProgress();
    _bump();
  }

  void next() {
    session.next();
    persist();
    _bump();
  }

  Future<void> toggleBookmark() async {
    await bank.toggleBookmark(question.id);
    _bump();
  }

  /// Saves where the student is, so the session can be resumed later.
  void persist() {
    if (_done || session.submittedCount == 0) return;
    bank.store.saveResume(McqResume(
      sessionId: sessionId,
      title: title,
      questionIds: [for (final q in session.questions) q.id],
      index: session.index,
      submitted: {
        for (final e in session.submittedAnswers.entries) e.key: e.value.toList()
      },
      elapsedMs: elapsedMs,
    ));
  }

  /// Called once all questions are answered. Clears the resumable snapshot.
  Future<McqScore> finish() async {
    _done = true;
    final score = session.score;
    await bank.store.clearResume();
    await bank.store.addSession(McqSessionRecord(
      id: sessionId,
      mode: "practice",
      title: title,
      total: score.total,
      correct: score.correct,
      incorrect: score.incorrect,
      elapsedMs: elapsedMs,
      atMs: DateTime.now().millisecondsSinceEpoch,
    ));
    bank.notifyProgress();
    return score;
  }
}
