import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/mcq/controllers/mcq_controllers.dart';
import 'package:upgrade/mcq/mcq_strings.dart';
import 'package:upgrade/mcq/models/mcq_models.dart';
import 'package:upgrade/mcq/screens/mcq_exam_setup_screen.dart';
import 'package:upgrade/mcq/screens/mcq_practice_screen.dart';
import 'package:upgrade/mcq/screens/mcq_review_screen.dart';
import 'package:upgrade/mcq/widgets/mcq_page.dart';
import 'package:upgrade/mcq/widgets/mcq_widgets.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/utils/subject_icon.dart';

Widget _subjectIcon(String name, double size) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(size * .28),
    child: Image.asset(
      subjectIconAsset(name),
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        color: McqTheme.accent.withOpacity(.16),
        child: Icon(Icons.menu_book_rounded, color: McqTheme.accent),
      ),
    ),
  );
}

/// Mockup frame 3: Browse Subjects. Only subjects that really contain
/// questions are listed; counts come from the validated catalog.
class McqSubjectsScreen extends StatefulWidget {
  const McqSubjectsScreen({super.key});

  @override
  State<McqSubjectsScreen> createState() => _McqSubjectsScreenState();
}

class _McqSubjectsScreenState extends State<McqSubjectsScreen> {
  final bank = McqBankController.ensure();

  @override
  void initState() {
    super.initState();
    bank.query.value = '';
  }

  @override
  Widget build(BuildContext context) {
    return McqPage(
      child: Column(
        children: [
          McqTopBar(title: McqStrings.questionBank),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
            child: TextField(
              onChanged: (v) => bank.query.value = v,
              style: TextStyle(color: AppColor.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: McqStrings.searchSubjects,
                hintStyle: TextStyle(color: AppColor.disabledColor),
                prefixIcon:
                    Icon(Icons.search_rounded, color: AppColor.textSecondary),
                filled: true,
                fillColor: AppColor.card,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColor.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: McqTheme.accent, width: 1.4),
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              bank.tick();
              final cat = bank.cat;
              final q = bank.query.value.trim().toLowerCase();
              final all = cat?.subjects ?? const <McqSubject>[];
              final list = q.isEmpty
                  ? all
                  : all
                      .where((s) =>
                          s.name.toLowerCase().contains(q) ||
                          (s.nameEn ?? '').toLowerCase().contains(q))
                      .toList();
              if (list.isEmpty) {
                return McqEmptyState(
                  icon: Icons.search_off_rounded,
                  title: all.isEmpty
                      ? McqStrings.noQuestionsTitle
                      : McqStrings.noSearchResults,
                  body: all.isEmpty ? McqStrings.noQuestionsBody : null,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final s = list[i];
                  final qn = cat!.questionsOfSubject(s.id).length;
                  final cn = cat.collectionsOfSubject(s.id).length;
                  return McqSurface(
                    onTap: () => Get.to(() => McqSubjectScreen(subjectId: s.id)),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        _subjectIcon(s.displayName, 52),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              McqText(s.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: AppColor.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 3),
                              Text(
                                  '${McqStrings.collectionsCount(cn)} · ${McqStrings.questionsCount(qn)}',
                                  style: TextStyle(
                                      color: AppColor.textSecondary,
                                      fontSize: 12.5)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: AppColor.textSecondary),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Mockup frame 4: a subject and its collections.
class McqSubjectScreen extends StatelessWidget {
  final String subjectId;
  const McqSubjectScreen({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context) {
    final bank = McqBankController.ensure();
    return McqPage(
      child: Obx(() {
        bank.tick();
        final cat = bank.cat;
        final subject = cat?.subjectById(subjectId);
        if (cat == null || subject == null) {
          return Column(children: [
            McqTopBar(title: McqStrings.questionBank),
            Expanded(
                child: McqEmptyState(
                    icon: Icons.search_off_rounded,
                    title: McqStrings.noQuestionsTitle)),
          ]);
        }
        final qs = cat.questionsOfSubject(subjectId);
        final cols = cat.collectionsOfSubject(subjectId);
        return Column(
          children: [
            McqTopBar(title: subject.displayName),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  McqSurface(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _subjectIcon(subject.displayName, 60),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              McqChip(
                                  label: McqStrings.collectionsCount(cols.length),
                                  icon: Icons.folder_rounded),
                              McqChip(
                                  label: McqStrings.questionsCount(qs.length),
                                  icon: Icons.quiz_rounded),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  McqPrimaryButton(
                    label: McqStrings.startPractice,
                    trailingIcon: Icons.play_arrow_rounded,
                    onTap: () => McqPracticeScreen.open(bank.startSession(
                        title: subject.displayName, questions: qs, shuffle: true)),
                  ),
                  const SizedBox(height: 10),
                  McqSecondaryButton(
                    icon: Icons.timer_rounded,
                    label: McqStrings.examMode,
                    onTap: () => Get.to(() => McqExamSetupScreen(
                        fixedTitle: subject.displayName, fixedPool: qs)),
                  ),
                  const SizedBox(height: 24),
                  Text(McqStrings.collections,
                      style: TextStyle(
                          color: AppColor.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  for (final c in cols) ...[
                    McqSurface(
                      onTap: () => Get.to(() => McqCollectionScreen(collectionId: c.id)),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: McqTheme.accent.withOpacity(.16),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(Icons.layers_rounded,
                                color: McqTheme.accent, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                McqText(c.displayTitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: AppColor.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        height: 1.3)),
                                const SizedBox(height: 3),
                                Text(
                                    McqStrings.questionsCount(
                                        cat.questionsOfCollection(c.id).length),
                                    style: TextStyle(
                                        color: AppColor.textSecondary,
                                        fontSize: 12.5)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: AppColor.textSecondary),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// Mockup frame 5: a collection, with a direct route to start.
class McqCollectionScreen extends StatelessWidget {
  final String collectionId;
  const McqCollectionScreen({super.key, required this.collectionId});

  @override
  Widget build(BuildContext context) {
    final bank = McqBankController.ensure();
    return McqPage(
      child: Obx(() {
        bank.tick();
        final cat = bank.cat;
        final col = cat?.collectionById(collectionId);
        if (cat == null || col == null) {
          return Column(children: [
            McqTopBar(title: McqStrings.questionBank),
            Expanded(
                child: McqEmptyState(
                    icon: Icons.search_off_rounded,
                    title: McqStrings.noQuestionsTitle)),
          ]);
        }
        final qs = cat.questionsOfCollection(collectionId);
        final subject = cat.subjectById(col.subjectId);
        final labels = <String>[];
        for (final q in qs) {
          if (q.examLabel != null && !labels.contains(q.examLabel)) {
            labels.add(q.examLabel!);
          }
        }
        final wrong = bank.incorrectCountIn(qs);
        return Column(
          children: [
            McqTopBar(title: subject?.displayName ?? McqStrings.questionBank),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  McqSurface(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        McqText(col.displayTitle,
                            style: TextStyle(
                                color: AppColor.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                height: 1.35)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            McqChip(
                                label: McqStrings.questionsCount(qs.length),
                                icon: Icons.quiz_rounded),
                            for (final l in labels)
                              McqChip(
                                  label: l,
                                  icon: Icons.event_note_rounded,
                                  color: AppColor.textSecondary),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  McqPrimaryButton(
                    label: McqStrings.startPractice,
                    trailingIcon: Icons.play_arrow_rounded,
                    onTap: () => McqPracticeScreen.open(
                        bank.startSession(title: col.displayTitle, questions: qs)),
                  ),
                  const SizedBox(height: 10),
                  McqSecondaryButton(
                    icon: Icons.timer_rounded,
                    label: McqStrings.examMode,
                    onTap: () => Get.to(() => McqExamSetupScreen(
                        fixedTitle: col.displayTitle, fixedPool: qs)),
                  ),
                  if (wrong > 0) ...[
                    const SizedBox(height: 12),
                    McqSecondaryButton(
                      icon: Icons.fact_check_rounded,
                      label: '${McqStrings.reviewMistakesCount} ($wrong)',
                      onTap: () {
                        final ids = {for (final q in qs) q.id};
                        Get.to(() => McqReviewScreen.forItems(
                              title: McqStrings.reviewTitle,
                              items: [
                                for (final i in bank.incorrectItems())
                                  if (ids.contains(i.question.id)) i
                              ],
                            ));
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
