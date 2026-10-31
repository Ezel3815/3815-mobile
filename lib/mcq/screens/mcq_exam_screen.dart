import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/mcq/controllers/mcq_exam_controller.dart';
import 'package:upgrade/mcq/mcq_strings.dart';
import 'package:upgrade/mcq/models/mcq_models.dart';
import 'package:upgrade/mcq/screens/mcq_exam_result_screen.dart';
import 'package:upgrade/mcq/widgets/mcq_page.dart';
import 'package:upgrade/mcq/widgets/mcq_widgets.dart';
import 'package:upgrade/resources.dart';

/// Mockup frame 10: Exam in progress. Nothing is graded or revealed until
/// the exam is submitted (or the time runs out).
class McqExamScreen extends StatefulWidget {
  final McqExamController controller;
  const McqExamScreen({super.key, required this.controller});

  static void open(McqExamController c) =>
      Get.to(() => McqExamScreen(controller: c));

  @override
  State<McqExamScreen> createState() => _McqExamScreenState();
}

class _McqExamScreenState extends State<McqExamScreen>
    with WidgetsBindingObserver {
  final _scroll = ScrollController();
  Worker? _worker;
  bool _navigated = false;

  McqExamController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _worker = ever<McqExamOutcome?>(c.outcome, _onOutcome);
    c.start();
    // The exam may already have ended (resumed after the deadline).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onOutcome(c.outcome.value);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) c.checkClock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _worker?.dispose();
    c.persist();
    c.stop();
    _scroll.dispose();
    super.dispose();
  }

  void _onOutcome(McqExamOutcome? o) {
    if (o == null || _navigated || !mounted) return;
    _navigated = true;
    // Close a confirm dialog / question sheet that may be open on top.
    final route = ModalRoute.of(context);
    if (route != null) {
      Navigator.of(context).popUntil((r) => r == route);
    }
    Get.off(() => McqExamResultScreen(outcome: o, controller: c));
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColor.card,
        title: Text(McqStrings.leaveExamTitle,
            style: TextStyle(color: AppColor.textPrimary)),
        content: Text(
            c.timed ? McqStrings.leaveExamTimedBody : McqStrings.leaveExamBody,
            style: TextStyle(color: AppColor.textSecondary, height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(McqStrings.stay)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(McqStrings.leave,
                  style: TextStyle(color: McqTheme.danger))),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmSubmit() async {
    final left = c.session.unansweredCount;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColor.card,
        title: Text(McqStrings.submitConfirmTitle,
            style: TextStyle(color: AppColor.textPrimary)),
        content: Text(
          '${left > 0 ? McqStrings.unansweredWarning(left) : McqStrings.allAnsweredNote}\n${McqStrings.cannotUndo}',
          style: TextStyle(color: AppColor.textSecondary, height: 1.6),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(McqStrings.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(McqStrings.submit,
                  style: TextStyle(
                      color: McqTheme.accent, fontWeight: FontWeight.w800))),
        ],
      ),
    );
    if (ok == true) c.submit();
  }

  void _openList() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColor.scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(McqStrings.questionList,
                  style: TextStyle(
                      color: AppColor.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(McqStrings.answeredOf(
                      c.session.answeredCount, c.session.questions.length),
                  style: TextStyle(color: AppColor.textSecondary, fontSize: 13)),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (var i = 0; i < c.session.questions.length; i++)
                        _NumberCell(
                          number: i + 1,
                          answered: c.session.isAnswered(i),
                          current: i == c.session.index,
                          onTap: () {
                            Navigator.pop(ctx);
                            c.goTo(i);
                            if (_scroll.hasClients) _scroll.jumpTo(0);
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 14, runSpacing: 6, children: [
                _Legend(McqStrings.legendAnswered, McqTheme.accent, true),
                _Legend(McqStrings.legendUnanswered, AppColor.borderColor, false),
                _Legend(McqStrings.legendCurrent, AppColor.textPrimary, false),
              ]),
              const SizedBox(height: 16),
              McqPrimaryButton(
                label: McqStrings.submitExam,
                trailingIcon: Icons.flag_rounded,
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmSubmit();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _go(int delta) {
    delta > 0 ? c.next() : c.prev();
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: McqPage(
        child: Obx(() {
          c.tick();
          final s = c.session;
          final q = s.current;
          final multi = q.type == McqQuestionType.multiple;
          final subject = c.bank.cat?.subjectById(q.subjectId);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 4, 0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip:
                          MaterialLocalizations.of(context).backButtonTooltip,
                      onPressed: _confirmLeave,
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20, color: AppColor.textPrimary),
                    ),
                    if (c.timed) _TimerLabel(c: c),
                    const Spacer(),
                    Text(McqStrings.qOf(s.index + 1, s.questions.length),
                        style: TextStyle(
                            color: AppColor.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
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
                child: McqProgressBar(
                    value: s.answeredCount / s.questions.length),
              ),
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  children: [
                    Wrap(spacing: 8, runSpacing: 8, children: [
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
                    ]),
                    const SizedBox(height: 16),
                    McqText(q.text,
                        style: TextStyle(
                            color: AppColor.textPrimary,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            height: 1.55)),
                    if (multi) ...[
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
                        state: s.selected.contains(o.id)
                            ? McqOptionState.selected
                            : McqOptionState.idle,
                        onTap: () => c.toggle(o.id),
                      ),
                      const SizedBox(height: 10),
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
                child: Row(
                  children: [
                    _SquareButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: McqStrings.previous,
                      onTap: s.isFirst ? null : () => _go(-1),
                    ),
                    const SizedBox(width: 10),
                    _SquareButton(
                      icon: Icons.grid_view_rounded,
                      tooltip: McqStrings.questionList,
                      onTap: _openList,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: s.isLast
                          ? McqPrimaryButton(
                              label: McqStrings.submitExam,
                              trailingIcon: Icons.flag_rounded,
                              onTap: _confirmSubmit,
                            )
                          : McqPrimaryButton(
                              label: McqStrings.next,
                              trailingIcon: Icons.arrow_forward_rounded,
                              onTap: () => _go(1),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _TimerLabel extends StatelessWidget {
  final McqExamController c;
  const _TimerLabel({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ms = c.remainingMs.value;
      final low = ms <= 5 * 60 * 1000;
      final color = low ? McqTheme.warning : AppColor.textPrimary;
      final time = mcqFormatDuration(ms);
      return Semantics(
        label: '${McqStrings.timeLeft} $time',
        liveRegion: false,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(low ? Icons.hourglass_bottom_rounded : Icons.timer_outlined,
                color: color, size: 20),
            const SizedBox(width: 6),
            Text(time,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                    color: color, fontSize: 19, fontWeight: FontWeight.w800)),
            if (low) ...[
              const SizedBox(width: 8),
              Text(McqStrings.lowTime,
                  style: TextStyle(
                      color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
            ],
          ],
        ),
      );
    });
  }
}

class _SquareButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  const _SquareButton(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: onTap == null ? .4 : 1,
        child: McqSurface(
          onTap: onTap,
          padding: EdgeInsets.zero,
          radius: 16,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(icon, color: AppColor.textPrimary, size: 22),
          ),
        ),
      ),
    );
  }
}

class _NumberCell extends StatelessWidget {
  final int number;
  final bool answered;
  final bool current;
  final VoidCallback onTap;
  const _NumberCell(
      {required this.number,
      required this.answered,
      required this.current,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$number, ${answered ? McqStrings.legendAnswered : McqStrings.legendUnanswered}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: answered ? McqTheme.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: current
                  ? AppColor.textPrimary
                  : (answered ? McqTheme.accent : AppColor.borderColor),
              width: current ? 2.2 : 1.2,
            ),
          ),
          child: Text('$number',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                  color: answered ? Colors.white : AppColor.textPrimary,
                  fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  const _Legend(this.label, this.color, this.filled);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color, width: 1.5),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(color: AppColor.textSecondary, fontSize: 12)),
    ]);
  }
}
