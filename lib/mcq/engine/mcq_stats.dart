import 'package:upgrade/mcq/data/mcq_progress_store.dart';

class McqSubjectStat {
  final String subjectId;
  final int answered; // unique questions answered at least once
  final int correctNow; // of those, latest attempt correct
  const McqSubjectStat(this.subjectId, this.answered, this.correctNow);
  double? get accuracy => answered == 0 ? null : correctNow / answered;
}

/// Progress numbers, each with ONE clear definition:
///  * attempts            - every submitted answer (a question can count many times)
///  * uniqueAnswered      - distinct questions answered at least once
///  * completedSessions   - finished practice runs + finished exams
///  * completedExams      - finished exams only
///  * attemptAccuracy     - correct attempts / attempts
///  * subject accuracy    - unique questions whose LATEST attempt is correct /
///                          unique questions answered in that subject
class McqStats {
  final int attempts;
  final int correctAttempts;
  final int uniqueAnswered;
  final int completedSessions;
  final int completedExams;
  final int studyMs;
  final List<McqSubjectStat> bySubject;
  final List<McqSessionRecord> recent;

  const McqStats({
    required this.attempts,
    required this.correctAttempts,
    required this.uniqueAnswered,
    required this.completedSessions,
    required this.completedExams,
    required this.studyMs,
    required this.bySubject,
    required this.recent,
  });

  bool get hasData => attempts > 0 || completedSessions > 0;
  double? get attemptAccuracy => attempts == 0 ? null : correctAttempts / attempts;

  /// Below this many attempts the numbers are shown with a caution note and
  /// never described as mastery.
  static const fewAttempts = 20;
  bool get isEarly => attempts < fewAttempts;

  static McqStats compute({
    required List<McqAttempt> attempts,
    required List<McqSessionRecord> sessions,
    required Map<String, String> subjectOfQuestion,
  }) {
    final latest = <String, McqAttempt>{};
    var ok = 0;
    for (final a in attempts) {
      latest[a.questionId] = a;
      if (a.correct) ok++;
    }
    final perSubject = <String, List<int>>{}; // [answered, correctNow]
    for (final e in latest.entries) {
      final sid = subjectOfQuestion[e.key];
      if (sid == null) continue;
      final v = perSubject.putIfAbsent(sid, () => [0, 0]);
      v[0]++;
      if (e.value.correct) v[1]++;
    }
    final recent = [...sessions]..sort((a, b) => b.atMs.compareTo(a.atMs));
    return McqStats(
      attempts: attempts.length,
      correctAttempts: ok,
      uniqueAnswered: latest.length,
      completedSessions: sessions.length,
      completedExams: sessions.where((s) => s.isExam).length,
      studyMs: sessions.fold<int>(0, (t, s) => t + s.elapsedMs),
      bySubject: [
        for (final e in perSubject.entries)
          McqSubjectStat(e.key, e.value[0], e.value[1])
      ]..sort((a, b) => b.answered.compareTo(a.answered)),
      recent: recent.take(5).toList(),
    );
  }
}
