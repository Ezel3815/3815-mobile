import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/main.dart' show AppRoutes;
import 'package:upgrade/mcq/controllers/mcq_exam_controller.dart';
import 'package:upgrade/mcq/mcq_strings.dart';
import 'package:upgrade/mcq/screens/mcq_review_screen.dart';
import 'package:upgrade/mcq/widgets/mcq_page.dart';
import 'package:upgrade/mcq/widgets/mcq_widgets.dart';
import 'package:upgrade/resources.dart';

/// Mockup frame 11: Exam Completed. Shown only for a really submitted exam,
/// and the review button opens THIS exam's answers, not a new question set.
class McqExamResultScreen extends StatelessWidget {
  final McqExamOutcome outcome;
  final McqExamController controller;
  const McqExamResultScreen(
      {super.key, required this.outcome, required this.controller});

  @override
  Widget build(BuildContext context) {
    final s = outcome.score;
    final avgMs = s.total == 0 ? 0 : (outcome.elapsedMs / s.total).round();
    return McqPage(
      child: Column(
        children: [
          McqTopBar(title: McqStrings.examCompleted),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                if (outcome.expired) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: McqTheme.warning.withOpacity(.14),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: McqTheme.warning.withOpacity(.6)),
                    ),
                    child: Row(children: [
                      Icon(Icons.hourglass_bottom_rounded,
                          color: McqTheme.warning),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(McqStrings.timeExpired,
                            style: TextStyle(
                                color: AppColor.textPrimary,
                                fontSize: 13.5,
                                height: 1.45)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                ],
                McqSurface(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                      child: McqScoreRing(correct: s.correct, total: s.total)),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                      child: _Stat(s.correct, McqStrings.correctLabel,
                          McqTheme.success)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _Stat(s.incorrect, McqStrings.incorrectLabel,
                          McqTheme.danger)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _Stat(s.unanswered, McqStrings.unanswered,
                          AppColor.textSecondary)),
                ]),
                const SizedBox(height: 14),
                McqSurface(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    _Row(Icons.timer_outlined, McqStrings.timeSpent,
                        mcqFormatDuration(outcome.elapsedMs)),
                    Divider(height: 24, color: AppColor.borderColor),
                    _Row(Icons.speed_rounded, McqStrings.avgPerQuestion,
                        mcqFormatDuration(avgMs)),
                  ]),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: Column(children: [
              McqPrimaryButton(
                label: McqStrings.reviewAnswers,
                onTap: () => Get.to(() => McqReviewScreen.forItems(
                    title: McqStrings.examReviewTitle, items: outcome.items)),
              ),
              const SizedBox(height: 10),
              McqSecondaryButton(
                label: McqStrings.backToMcq,
                onTap: () => Get.until((r) =>
                    r.settings.name == AppRoutes.mainRoute || r.isFirst),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _Stat(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => McqSurface(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        radius: 18,
        child: Column(children: [
          Text('$value',
              style: TextStyle(
                  color: color, fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: AppColor.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600)),
        ]),
      );
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: AppColor.textSecondary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: TextStyle(
                  color: AppColor.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ),
        Text(value,
            textDirection: TextDirection.ltr,
            style: TextStyle(
                color: AppColor.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800)),
      ]);
}
