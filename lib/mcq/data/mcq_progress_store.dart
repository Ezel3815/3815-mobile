import "dart:convert";
import "package:flutter/foundation.dart";
import "package:upgrade/main.dart" show sharedPref;

class McqAttempt {
  final String questionId;
  final List<String> selected;
  final bool correct;
  final int atMs;
  final String sessionId;
  const McqAttempt(
      this.questionId, this.selected, this.correct, this.atMs, this.sessionId);

  Map<String, dynamic> toJson() =>
      {"q": questionId, "s": selected, "ok": correct, "t": atMs, "sid": sessionId};

  factory McqAttempt.fromJson(Map<String, dynamic> j) => McqAttempt(
        j["q"] as String,
        List<String>.from(j["s"] as List),
        j["ok"] as bool,
        j["t"] as int,
        (j["sid"] ?? "") as String,
      );
}

/// Snapshot of an unfinished practice session.
class McqResume {
  final String sessionId;
  final String title;
  final List<String> questionIds;
  final int index;
  final Map<String, List<String>> submitted;
  final int elapsedMs;
  const McqResume({
    required this.sessionId,
    required this.title,
    required this.questionIds,
    required this.index,
    required this.submitted,
    required this.elapsedMs,
  });

  Map<String, dynamic> toJson() => {
        "sid": sessionId,
        "title": title,
        "ids": questionIds,
        "i": index,
        "sub": submitted,
        "ms": elapsedMs,
      };

  factory McqResume.fromJson(Map<String, dynamic> j) => McqResume(
        sessionId: j["sid"] as String,
        title: j["title"] as String,
        questionIds: List<String>.from(j["ids"] as List),
        index: j["i"] as int,
        submitted: {
          for (final e in (j["sub"] as Map).entries)
            e.key as String: List<String>.from(e.value as List)
        },
        elapsedMs: j["ms"] as int,
      );
}

/// A finished practice session or exam (feeds the Progress screen).
class McqSessionRecord {
  final String id;
  final String mode; // "practice" | "exam"
  final String title;
  final int total;
  final int correct;
  final int incorrect;
  final int elapsedMs;
  final int atMs;
  const McqSessionRecord({
    required this.id,
    required this.mode,
    required this.title,
    required this.total,
    required this.correct,
    required this.incorrect,
    required this.elapsedMs,
    required this.atMs,
  });

  int get unanswered => total - correct - incorrect;
  bool get isExam => mode == "exam";

  Map<String, dynamic> toJson() => {
        "id": id,
        "m": mode,
        "title": title,
        "n": total,
        "ok": correct,
        "bad": incorrect,
        "ms": elapsedMs,
        "t": atMs,
      };

  factory McqSessionRecord.fromJson(Map<String, dynamic> j) => McqSessionRecord(
        id: j["id"] as String,
        mode: j["m"] as String,
        title: j["title"] as String,
        total: j["n"] as int,
        correct: j["ok"] as int,
        incorrect: j["bad"] as int,
        elapsedMs: j["ms"] as int,
        atMs: j["t"] as int,
      );
}

/// Snapshot of an exam in progress. [endAtMs] is an absolute wall-clock
/// deadline (null = untimed), so the clock keeps running if the app is closed.
class McqExamSnapshot {
  final String id;
  final String title;
  final List<String> questionIds;
  final Map<String, List<String>> answers;
  final int index;
  final int? endAtMs;
  final int limitMinutes; // 0 = untimed
  final int elapsedMs;
  const McqExamSnapshot({
    required this.id,
    required this.title,
    required this.questionIds,
    required this.answers,
    required this.index,
    required this.endAtMs,
    required this.limitMinutes,
    required this.elapsedMs,
  });

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "ids": questionIds,
        "a": answers,
        "i": index,
        "end": endAtMs,
        "lim": limitMinutes,
        "ms": elapsedMs,
      };

  factory McqExamSnapshot.fromJson(Map<String, dynamic> j) => McqExamSnapshot(
        id: j["id"] as String,
        title: j["title"] as String,
        questionIds: List<String>.from(j["ids"] as List),
        answers: {
          for (final e in (j["a"] as Map).entries)
            e.key as String: List<String>.from(e.value as List)
        },
        index: j["i"] as int,
        endAtMs: j["end"] as int?,
        limitMinutes: j["lim"] as int,
        elapsedMs: j["ms"] as int,
      );
}

/// Bookmarks, attempts and the resumable session, kept on-device in the
/// app's existing SharedPreferences and scoped per signed-in user.
/// (Server-side sync can replace this later without touching the UI.)
class McqProgressStore {
  McqProgressStore._() {
    _load();
  }

  static const _maxAttempts = 3000;

  final Set<String> bookmarks = {};
  final List<McqAttempt> attempts = [];
  McqResume? resume;
  final List<McqSessionRecord> sessions = [];
  McqExamSnapshot? exam;

  static Future<McqProgressStore> open() async => McqProgressStore._();

  String get _scope {
    try {
      final raw = sharedPref.getString("user");
      if (raw != null) {
        final id = (jsonDecode(raw) as Map)["id"];
        if (id != null) return "u$id";
      }
    } catch (e) {
      debugPrint("MCQ store: could not read user id ($e)");
    }
    return "anon";
  }

  String _k(String name) => "mcq.$_scope.$name";

  void _load() {
    bookmarks.addAll(sharedPref.getStringList(_k("bookmarks")) ?? const []);
    try {
      for (final s in sharedPref.getStringList(_k("attempts")) ?? const []) {
        attempts.add(McqAttempt.fromJson(jsonDecode(s) as Map<String, dynamic>));
      }
      final r = sharedPref.getString(_k("resume"));
      if (r != null) resume = McqResume.fromJson(jsonDecode(r) as Map<String, dynamic>);
      for (final x in sharedPref.getStringList(_k("sessions")) ?? const []) {
        sessions.add(McqSessionRecord.fromJson(jsonDecode(x) as Map<String, dynamic>));
      }
      final e = sharedPref.getString(_k("exam"));
      if (e != null) exam = McqExamSnapshot.fromJson(jsonDecode(e) as Map<String, dynamic>);
    } catch (e) {
      debugPrint("MCQ store: stored progress was unreadable and was reset ($e)");
      attempts.clear();
      sessions.clear();
      resume = null;
      exam = null;
    }
  }

  Future<void> toggleBookmark(String questionId) async {
    if (!bookmarks.remove(questionId)) bookmarks.add(questionId);
    await sharedPref.setStringList(_k("bookmarks"), bookmarks.toList());
  }

  Future<void> addAttempt(McqAttempt a) async {
    attempts.add(a);
    if (attempts.length > _maxAttempts) {
      attempts.removeRange(0, attempts.length - _maxAttempts);
    }
    await sharedPref.setStringList(
        _k("attempts"), [for (final x in attempts) jsonEncode(x.toJson())]);
  }

  Future<void> addAttempts(List<McqAttempt> list) async {
    if (list.isEmpty) return;
    attempts.addAll(list);
    if (attempts.length > _maxAttempts) {
      attempts.removeRange(0, attempts.length - _maxAttempts);
    }
    await sharedPref.setStringList(
        _k("attempts"), [for (final x in attempts) jsonEncode(x.toJson())]);
  }

  Future<void> saveResume(McqResume r) async {
    resume = r;
    await sharedPref.setString(_k("resume"), jsonEncode(r.toJson()));
  }

  Future<void> clearResume() async {
    resume = null;
    await sharedPref.remove(_k("resume"));
  }

  Future<void> addSession(McqSessionRecord r) async {
    sessions.add(r);
    if (sessions.length > 300) sessions.removeRange(0, sessions.length - 300);
    await sharedPref.setStringList(
        _k("sessions"), [for (final x in sessions) jsonEncode(x.toJson())]);
  }

  Future<void> saveExam(McqExamSnapshot e) async {
    exam = e;
    await sharedPref.setString(_k("exam"), jsonEncode(e.toJson()));
  }

  Future<void> clearExam() async {
    exam = null;
    await sharedPref.remove(_k("exam"));
  }

  /// Most recent attempt per question.
  Map<String, McqAttempt> get latestByQuestion {
    final m = <String, McqAttempt>{};
    for (final a in attempts) {
      m[a.questionId] = a;
    }
    return m;
  }

  /// UNIQUE questions whose latest attempt was wrong (not an attempt count).
  Set<String> get needsReviewIds => {
        for (final e in latestByQuestion.entries)
          if (!e.value.correct) e.key
      };
}
