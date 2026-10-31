import "package:upgrade/mcq/models/mcq_models.dart";

/// Where MCQ content comes from. The backend/dashboard implementation will
/// return the same JSON shape (MCQ_DATA_FORMAT.md) and go through the same
/// [McqCatalog.build] validation, so nothing else in the UI changes.
abstract class McqRepository {
  Future<McqCatalog> load();
}

/// Placeholder content, NOT used by the app any more (the app now reads the
/// backend through ApiMcqRepository). Kept only for tests / offline demos.
/// ONE question, copied verbatim (including its answer key and explanation)
/// from the supplied General Surgery file, so the screens can be reviewed
/// with real Arabic medical text. Delete this class once the API repository
/// is wired in.
class SampleMcqRepository implements McqRepository {
  @override
  Future<McqCatalog> load() async {
    return McqCatalog.build(
      subjects: const [
        McqSubject(
            id: "general-surgery",
            name: "الجراحة العامة",
            nameEn: "General Surgery"),
      ],
      collections: const [
        McqCollection(
          id: "gs-liver-intro",
          subjectId: "general-surgery",
          title: "مقدمة تشريحية في الكبد وآفاته",
          order: 1,
        ),
      ],
      rawQuestions: const [
        {
          "id": "sample-gs-liver-2023-q1",
          "subject_id": "general-surgery",
          "collection_id": "gs-liver-intro",
          "exam_label": "دورة 2023",
          "source": "General Surgery - Dr. Mohammad Al-Ahmad courses (EX09), p.2",
          "text": "في كيسات الكبد البسيطة كل مما يلي صح ما عدا: (مكرر)",
          "options": [
            {"id": "a", "text": "من أشيع آفات الكبد السليمة."},
            {"id": "b", "text": "لها جدار رقيق عديم التنبتات."},
            {
              "id": "c",
              "text": "تفرز ظهارة الكيسة سائلاً رائقاً لا يحتوي على صفراء."
            },
            {
              "id": "d",
              "text": "معدل النكس بعد البزل البسيط عبر الجلد منخفض للغاية."
            },
            {
              "id": "e",
              "text": "لا تتصل مع الأقنية الصفراوية في الحالات النموذجية."
            },
          ],
          "correct": ["d"],
          "explanation": "معدل النكس بعد البزل البسيط مرتفع.",
        },
      ],
    );
  }
}
