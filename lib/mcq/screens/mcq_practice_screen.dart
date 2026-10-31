import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/mcq/controllers/mcq_controllers.dart';
import 'package:upgrade/mcq/mcq_strings.dart';
import 'package:upgrade/mcq/models/mcq_models.dart';
import 'package:upgrade/mcq/screens/mcq_result_screen.dart';
import 'package:upgrade/mcq/widgets/mcq_page.dart';
import 'package:upgrade/mcq/widgets/mcq_widgets.dart';
import 'package:upgrade/resources.dart';

/// Mockup frames 6 + 7: the question, then feedback and explanation on the
/// same screen so the question never disappears while the student reads.
class McqPracticeScreen extends StatefulWidget {
  final McqSessionController controller;
  const McqPracticeScreen({super.key, required this.controller});

  static void open(McqSessionController c) =>
      Get.to(() => McqPracticeScreen(controller: c));

  @override
  State<McqPracticeScreen> createState() => _McqPracticeScreenState();
}

class _McqPracticeScreenState extends State<McqPracticeScreen> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    widget.controller.persist(); // keeps the session resumable
    _scroll.dispose();
    super.dispose();
  }

  McqOptionState _stateFor(McqSessionController c, McqOption o) {
    final s = c.session;
    final q = s.current;
    final chosen = s.selected.contains(o.id);
    if (!s.isSubmitted) {
      return chosen ? McqOptionState.selected : McqOptionState.idle;
    }
    if (q.correctOptionIds.contains(o.id)) {
      return chosen ? McqOptionState.correct : McqOptionState.missed;
    }
    return chosen ? McqOptionState.wrong : McqOptionState.idle;
  }

  Future<void> _finish() async {
    final c = widget.controller;
    final score = await c.finish();
    Get.off(() => McqResultScreen(score: score, controller: c));
  }

  void _next() {
    widget.controller.next();
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return McqPage(
      child: Obx(() {
        c.tick();
        final s = c.session;
        final q = s.current;
        final submitted = s.isSubmitted;
        final multi = q.type == McqQuestionType.multiple;
        final subject = c.bank.cat?.subjectById(q.subjectId);
        final progress =
            (s.index + (submitted ? 1 : 0)) / s.questions.length;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 4, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 20, color: AppColor.textPrimary),
                  ),
                  Expanded(
                    child: Text(
                      McqStrings.qOf(s.index + 1, s.questions.length),
                      style: TextStyle(
                          color: AppColor.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    tooltip: c.isBookmarked
                        ? McqStrings.removeBookmark
                        : McqStrings.addBookmark,
                    onPressed: c.toggleBookmark,
                    icon: Icon(
                      c.isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: c.isBookmarked
                          ? McqTheme.accent
                          : AppColor.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
              child: McqProgressBar(value: progress),
            ),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (subject != null)
                        McqChip(
                            label: subject.displayName,
                            icon: Icons.medical_services_rounded),
                      McqChip(
                        label: multi
                            ? McqStrings.multiAnswer
                            : McqStrings.singleAnswer,
                        icon: multi
                            ? Icons.checklist_rounded
                            : Icons.radio_button_checked_rounded,
                        color: AppColor.textSecondary,
                      ),
                      if (q.examLabel != null)
                        McqChip(
                            label: q.examLabel!,
                            icon: Icons.event_note_rounded,
                            color: AppColor.textSecondary),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (submitted) ...[
                    _FeedbackBanner(correct: s.currentIsCorrect, q: q),
                    const SizedBox(height: 16),
                  ],
                  McqText(q.text,
                      style: TextStyle(
                          color: AppColor.textPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          height: 1.55)),
                  if (multi && !submitted) ...[
                    const SizedBox(height: 8),
                    Text(McqStrings.selectAll,
                        style: TextStyle(
                            color: McqTheme.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ],
                  const SizedBox(height: 16),
                  for (final o in q.options) ...[
                    McqOptionTile(
                      letter: q.letterFor(o.id),
                      text: o.text,
                      multi: multi,
                      state: _stateFor(c, o),
                      onTap: submitted ? null : () => c.toggle(o.id),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (submitted) ...[
                    const SizedBox(height: 6),
                    _ExplanationCard(q: q),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              decoration: BoxDecoration(
                color: AppColor.scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: AppColor.borderColor)),
              ),
              child: !submitted
                  ? McqPrimaryButton(
                      label: McqStrings.checkAnswer,
                      onTap: s.canSubmit ? c.submit : null,
                    )
                  : McqPrimaryButton(
                      label: s.isLast ? McqStrings.finish : McqStrings.next,
                      trailingIcon:
                          s.isLast ? Icons.flag_rounded : Icons.arrow_forward_rounded,
                      onTap: s.isLast ? _finish : _next,
                    ),
            ),
          ],
        );
      }),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  final bool correct;
  final McqQuestion q;
  const _FeedbackBanner({required this.correct, required this.q});

  @override
  Widget build(BuildContext context) {
    final color = correct ? McqTheme.success : McqTheme.danger;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(.6)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(
                correct ? Icons.check_rounded : Icons.close_rounded,
                color: correct ? Colors.black87 : Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(correct ? McqStrings.correct : McqStrings.incorrect,
                      style: TextStyle(
                          color: AppColor.textPrimary,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    correct
                        ? McqStrings.wellDone
                        : McqStrings.correctAnswerIs(q.correctLetters.join(', ')),
                    style: TextStyle(
                        color: AppColor.textSecondary, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  final McqQuestion q;
  const _ExplanationCard({required this.q});

  @override
  Widget build(BuildContext context) {
    final has = q.explanation != null;
    return McqSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_rounded, size: 20, color: McqTheme.warning),
              const SizedBox(width: 8),
              Text(McqStrings.explanation,
                  style: TextStyle(
                      color: AppColor.textPrimary,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          if (has)
            McqText(q.explanation!,
                style: TextStyle(
                    color: AppColor.textPrimary, fontSize: 15, height: 1.65))
          else
            Text(McqStrings.noExplanation,
                style: TextStyle(color: AppColor.textSecondary, fontSize: 14)),
          if (q.keyPoints.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(McqStrings.keyPoints,
                style: TextStyle(
                    color: AppColor.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            for (final k in q.keyPoints)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 2, right: 8),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                            color: McqTheme.accent, shape: BoxShape.circle),
                      ),
                    ),
                    Expanded(
                      child: McqText(k,
                          style: TextStyle(
                              color: AppColor.textPrimary,
                              fontSize: 14.5,
                              height: 1.5)),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
