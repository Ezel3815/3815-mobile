import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/main.dart' show AppRoutes;
import 'package:upgrade/mcq/controllers/mcq_controllers.dart';
import 'package:upgrade/mcq/engine/mcq_engine.dart';
import 'package:upgrade/mcq/mcq_strings.dart';
import 'package:upgrade/mcq/screens/mcq_practice_screen.dart';
import 'package:upgrade/mcq/screens/mcq_review_screen.dart';
import 'package:upgrade/mcq/widgets/mcq_page.dart';
import 'package:upgrade/mcq/widgets/mcq_widgets.dart';
import 'package:upgrade/resources.dart';

/// Mockup frame 12: Practice Complete.
class McqResultScreen extends StatelessWidget {
  final McqScore score;
  final McqSessionController controller;
  const McqResultScreen(
      {super.key, required this.score, required this.controller});

  @override
  Widget build(BuildContext context) {
    final acc = score.accuracyOfAnswered;
    final hasWrong = score.incorrect > 0;
    return McqPage(
      child: Column(
        children: [
          McqTopBar(title: McqStrings.practiceComplete),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                McqSurface(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: McqScoreRing(
                        correct: score.correct, total: score.total),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                        child: _Stat(
                            value: score.correct,
                            label: McqStrings.correctLabel,
                            color: McqTheme.success)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _Stat(
                            value: score.incorrect,
                            label: McqStrings.incorrectLabel,
                            color: McqTheme.danger)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _Stat(
                            value: score.unanswered,
                            label: McqStrings.unanswered,
                            color: AppColor.textSecondary)),
                  ],
                ),
                const SizedBox(height: 14),
                McqSurface(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.timer_outlined,
                        label: McqStrings.timeSpent,
                        value: mcqFormatDuration(controller.elapsedMs),
                      ),
                      if (acc != null) ...[
                        Divider(height: 24, color: AppColor.borderColor),
                        _InfoRow(
                          icon: Icons.percent_rounded,
                          label: McqStrings.accuracy,
                          hint: McqStrings.accuracyHint,
                          value: '${(acc * 100).round()}%',
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: Column(
              children: [
                if (hasWrong) ...[
                  McqPrimaryButton(
                    label: McqStrings.reviewMistakes,
                    onTap: () => Get.to(() => McqReviewScreen.forItems(
                          title: McqStrings.reviewTitle,
                          items: controller.session.reviewItems,
                        )),
                  ),
                  const SizedBox(height: 10),
                  McqSecondaryButton(
                      label: McqStrings.tryAgain,
                      icon: Icons.refresh_rounded,
                      onTap: _tryAgain),
                ] else
                  McqPrimaryButton(
                      label: McqStrings.tryAgain,
                      trailingIcon: Icons.refresh_rounded,
                      onTap: _tryAgain),
                const SizedBox(height: 10),
                McqSecondaryButton(
                  label: McqStrings.backToMcq,
                  onTap: () => Get.until((r) =>
                      r.settings.name == AppRoutes.mainRoute || r.isFirst),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _tryAgain() {
    final next = controller.bank.startSession(
      title: controller.title,
      questions: controller.session.questions,
    );
    Get.off(() => McqPracticeScreen(controller: next));
  }
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _Stat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return McqSurface(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      radius: 18,
      child: Column(
        children: [
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
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? hint;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value, this.hint});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColor.textSecondary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: AppColor.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              if (hint != null)
                Text(hint!,
                    style: TextStyle(
                        color: AppColor.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        Text(value,
            textDirection: TextDirection.ltr,
            style: TextStyle(
                color: AppColor.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800)),
      ],
    );
  }
}
