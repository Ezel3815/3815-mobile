import "package:flutter/foundation.dart";
import "package:get/get.dart";

bool get _en => Get.locale?.languageCode == "en";

/// One validation problem found while loading content. Content is never
/// dropped silently: every skipped record ends up in [McqValidationReport].
class McqIssue {
  final String recordId;
  final String message;
  const McqIssue(this.recordId, this.message);
  @override
  String toString() => "[$recordId] $message";
}

class McqValidationReport {
  final int received;
  final List<McqIssue> issues;
  const McqValidationReport(this.received, this.issues);
  int get skipped => issues.length;
  bool get isClean => issues.isEmpty;
}

enum McqQuestionType { single, multiple }

class McqOption {
  final String id;
  final String text;
  const McqOption(this.id, this.text);
}

class McqSubject {
  final String id;
  final String name;
  final String? nameEn;
  const McqSubject({required this.id, required this.name, this.nameEn});

  String get displayName =>
      (_en && nameEn != null && nameEn!.isNotEmpty) ? nameEn! : name;
}

class McqCollection {
  final String id;
  final String subjectId;
  final String title;
  final String? titleEn;
  final int order;
  const McqCollection({
    required this.id,
    required this.subjectId,
    required this.title,
    this.titleEn,
    this.order = 0,
  });

  String get displayTitle =>
      (_en && titleEn != null && titleEn!.isNotEmpty) ? titleEn! : title;
}

class McqQuestion {
  final String id;
  final String text;
  final String subjectId;
  final String collectionId;
  final List<McqOption> options;
  final Set<String> correctOptionIds;
  final String? explanation;
  final List<String> keyPoints;
  final String? examLabel;
  final String? source;

  const McqQuestion({
    required this.id,
    required this.text,
    required this.subjectId,
    required this.collectionId,
    required this.options,
    required this.correctOptionIds,
    this.explanation,
    this.keyPoints = const [],
    this.examLabel,
    this.source,
  });

  /// More than one correct option => multiple-answer question.
  McqQuestionType get type => correctOptionIds.length > 1
      ? McqQuestionType.multiple
      : McqQuestionType.single;

  /// Display letter for an option (A, B, C ...), by position.
  String letterFor(String optionId) {
    final i = options.indexWhere((o) => o.id == optionId);
    return i < 0 ? "?" : String.fromCharCode(0x41 + i);
  }

  /// Letters of all correct options, in display order.
  List<String> get correctLetters => [
        for (final o in options)
          if (correctOptionIds.contains(o.id)) letterFor(o.id)
      ];

  /// Backend/dashboard JSON shape (see MCQ_DATA_FORMAT.md).
  /// Returns null and records an [McqIssue] when the record is unusable.
  static McqQuestion? tryParse(Map<String, dynamic> j, List<McqIssue> issues) {
    final id = (j["id"] ?? "").toString().trim();
    void bad(String m) => issues.add(McqIssue(id.isEmpty ? "(no id)" : id, m));

    if (id.isEmpty) {
      bad("missing id");
      return null;
    }
    final text = (j["text"] ?? "").toString().trim();
    if (text.isEmpty) {
      bad("empty question text");
      return null;
    }
    final subjectId = (j["subject_id"] ?? "").toString().trim();
    final collectionId = (j["collection_id"] ?? "").toString().trim();
    if (subjectId.isEmpty || collectionId.isEmpty) {
      bad("missing subject_id or collection_id");
      return null;
    }
    final rawOptions = j["options"];
    if (rawOptions is! List || rawOptions.length < 2) {
      bad("needs at least 2 options");
      return null;
    }
    final options = <McqOption>[];
    final seen = <String>{};
    for (final o in rawOptions) {
      if (o is! Map) {
        bad("option is not an object");
        return null;
      }
      final oid = (o["id"] ?? "").toString().trim();
      final ot = (o["text"] ?? "").toString().trim();
      if (oid.isEmpty || ot.isEmpty) {
        bad("option with empty id or text");
        return null;
      }
      if (!seen.add(oid)) {
        bad("duplicate option id \"$oid\"");
        return null;
      }
      options.add(McqOption(oid, ot));
    }
    final rawCorrect = j["correct"];
    final correct = <String>{
      if (rawCorrect is List)
        ...rawCorrect.map((e) => e.toString())
      else if (rawCorrect != null)
        rawCorrect.toString(),
    };
    if (correct.isEmpty) {
      bad("no correct answer given");
      return null;
    }
    if (!correct.every(seen.contains)) {
      bad("correct answer refers to an unknown option");
      return null;
    }
    final explanation = (j["explanation"] ?? "").toString().trim();
    final examLabel = (j["exam_label"] ?? "").toString().trim();
    final source = (j["source"] ?? "").toString().trim();
    final kp = j["key_points"];
    return McqQuestion(
      id: id,
      text: text,
      subjectId: subjectId,
      collectionId: collectionId,
      options: options,
      correctOptionIds: correct,
      explanation: explanation.isEmpty ? null : explanation,
      keyPoints: kp is List
          ? [
              for (final k in kp)
                if (k.toString().trim().isNotEmpty) k.toString().trim()
            ]
          : const [],
      examLabel: examLabel.isEmpty ? null : examLabel,
      source: source.isEmpty ? null : source,
    );
  }
}

/// Everything the student can browse. Counts are always derived from the
/// validated questions, never stored or hardcoded.
class McqCatalog {
  final List<McqSubject> _subjects;
  final List<McqCollection> _collections;
  final List<McqQuestion> questions;
  final McqValidationReport report;
  final Map<String, McqQuestion> _byId;

  McqCatalog._(this._subjects, this._collections, this.questions, this.report)
      : _byId = {for (final q in questions) q.id: q};

  factory McqCatalog.build({
    required List<McqSubject> subjects,
    required List<McqCollection> collections,
    required List<Map<String, dynamic>> rawQuestions,
  }) {
    final issues = <McqIssue>[];
    final subjectIds = {for (final s in subjects) s.id};
    final collectionById = {for (final c in collections) c.id: c};
    final accepted = <McqQuestion>[];
    final seen = <String>{};
    for (final raw in rawQuestions) {
      final q = McqQuestion.tryParse(raw, issues);
      if (q == null) continue;
      if (!seen.add(q.id)) {
        issues.add(McqIssue(q.id, "duplicate question id (first one kept)"));
        continue;
      }
      if (!subjectIds.contains(q.subjectId)) {
        issues.add(McqIssue(q.id, "unknown subject \"${q.subjectId}\""));
        continue;
      }
      final c = collectionById[q.collectionId];
      if (c == null || c.subjectId != q.subjectId) {
        issues.add(McqIssue(q.id,
            "collection \"${q.collectionId}\" missing or in another subject"));
        continue;
      }
      accepted.add(q);
    }
    if (issues.isNotEmpty) {
      debugPrint("MCQ import: ${issues.length} record(s) skipped");
      for (final i in issues) {
        debugPrint("  $i");
      }
    }
    return McqCatalog._(subjects, collections, accepted,
        McqValidationReport(rawQuestions.length, issues));
  }

  bool get isEmpty => questions.isEmpty;

  McqQuestion? questionById(String id) => _byId[id];

  List<McqQuestion> questionsOfSubject(String subjectId) =>
      [for (final q in questions) if (q.subjectId == subjectId) q];

  List<McqQuestion> questionsOfCollection(String collectionId) =>
      [for (final q in questions) if (q.collectionId == collectionId) q];

  /// Subjects that actually contain at least one valid question.
  List<McqSubject> get subjects => [
        for (final s in _subjects)
          if (questions.any((q) => q.subjectId == s.id)) s
      ];

  /// Collections of a subject that contain at least one valid question.
  List<McqCollection> collectionsOfSubject(String subjectId) {
    final list = [
      for (final c in _collections)
        if (c.subjectId == subjectId &&
            questions.any((q) => q.collectionId == c.id))
          c
    ];
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  McqSubject? subjectById(String id) {
    for (final s in _subjects) {
      if (s.id == id) return s;
    }
    return null;
  }

  McqCollection? collectionById(String id) {
    for (final c in _collections) {
      if (c.id == id) return c;
    }
    return null;
  }
}
