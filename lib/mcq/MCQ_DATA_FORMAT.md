# MCQ data format (what the backend / dashboard should send)

The app validates every record in `McqCatalog.build` (lib/mcq/models/mcq_models.dart).
Bad records are skipped **and reported** (debug log + `catalog.report`), never silently.

## Subject
```json
{ "id": "general-surgery", "name": "الجراحة العامة", "name_en": "General Surgery" }
```
## Collection (a lecture / course inside a subject)
```json
{ "id": "gs-liver-intro", "subject_id": "general-surgery",
  "title": "مقدمة تشريحية في الكبد وآفاته", "title_en": null, "order": 1 }
```
## Question
```json
{
  "id": "unique-and-stable",          // required, never reused
  "subject_id": "general-surgery",    // required, must exist
  "collection_id": "gs-liver-intro",  // required, must belong to that subject
  "text": "…",                        // required
  "options": [                        // required, >= 2, any number
    { "id": "a", "text": "…" },
    { "id": "b", "text": "…" }
  ],
  "correct": ["b"],                   // required; 1 id = single answer, 2+ = multiple answer
  "explanation": "…",                 // optional (missing => "no explanation" is shown)
  "key_points": ["…"],                // optional
  "exam_label": "دورة 2023",          // optional (shown as a chip)
  "source": "file / page"             // optional provenance
}
```
Rules: option ids unique inside a question; every id in `correct` must be an option id;
option order is kept as sent (letters A, B, C… are assigned by position).
Grading: exact set match, no partial credit, no negative marking.

## Hooking up the backend
Implement `McqRepository.load()` (lib/mcq/data/mcq_repository.dart) to fetch these three
lists and return `McqCatalog.build(...)`; then pass it in `McqBankController(repository: ...)`
(or change the default in `mcq_controllers.dart`) and delete `SampleMcqRepository`.
