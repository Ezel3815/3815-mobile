import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/mcq/controllers/mcq_controllers.dart';
import 'package:upgrade/mcq/engine/mcq_exam_engine.dart';
import 'package:upgrade/mcq/mcq_strings.dart';
import 'package:upgrade/mcq/models/mcq_models.dart';
import 'package:upgrade/mcq/screens/mcq_exam_screen.dart';
import 'package:upgrade/mcq/widgets/mcq_page.dart';
import 'package:upgrade/mcq/widgets/mcq_widgets.dart';
import 'package:upgrade/resources.dart';

/// Mockup frame 9: Start Exam. Only offers settings the exam really supports,
/// and never more questions than exist in the chosen scope.
class McqExamSetupScreen extends StatefulWidget {
  /// When both are given the scope is fixed (e.g. launched from a collection).
  final String? fixedTitle;
  final List<McqQuestion>? fixedPool;
  const McqExamSetupScreen({super.key, this.fixedTitle, this.fixedPool});

  @override
  State<McqExamSetupScreen> createState() => _McqExamSetupScreenState();
}

class _McqExamSetupScreenState extends State<McqExamSetupScreen> {
  final bank = McqBankController.ensure();
  String? _subjectId; // null = all subjects
  int _count = 0;
  bool _timed = true;
  int _minutes = 30;
  bool _random = true;

  static const _minuteOptions = [15, 30, 60, 90];

  bool get _fixed => widget.fixedPool != null;

  List<McqQuestion> get _pool {
    if (_fixed) return widget.fixedPool!;
    final c = bank.cat;
    if (c == null) return const [];
    return _subjectId == null ? c.questions : c.questionsOfSubject(_subjectId!);
  }

  String get _title {
    if (_fixed) return widget.fixedTitle ?? McqStrings.examMode;
    if (_subjectId == null) return McqStrings.allSubjects;
    return bank.cat?.subjectById(_subjectId!)?.displayName ?? McqStrings.examMode;
  }

  int _defaultCount(int available) {
    final opts = McqExamSession.countOptions(available);
    if (opts.isEmpty) return 0;
    return opts.contains(10) && available > 10 ? 10 : opts.last;
  }

  @override
  void initState() {
    super.initState();
    _count = _defaultCount(_pool.length);
  }

  void _start() {
    final pool = _pool;
    if (pool.isEmpty || _count <= 0) return;
    final n = _count > pool.length ? pool.length : _count; // never exceed pool
    final c = bank.startExam(
      title: _title,
      pool: pool,
      config: McqExamConfig(
        count: n,
        timeLimitMinutes: _timed ? _minutes : 0,
        randomize: _random,
      ),
    );
    Get.off(() => McqExamScreen(controller: c));
  }

  @override
  Widget build(BuildContext context) {
    final cat = bank.cat;
    final pool = _pool;
    final opts = McqExamSession.countOptions(pool.length);
    return McqPage(
      child: Column(
        children: [
          McqTopBar(title: McqStrings.examSetupTitle),
          Expanded(
            child: cat == null || cat.isEmpty
                ? McqEmptyState(
                    icon: Icons.quiz_rounded,
                    title: McqStrings.noQuestionsTitle,
                    body: McqStrings.noQuestionsBody)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    children: [
                      McqSurface(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            McqText(_title,
                                style: TextStyle(
                                    color: AppColor.textPrimary,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(McqStrings.questionsCount(pool.length),
                                style: TextStyle(
                                    color: AppColor.textSecondary,
                                    fontSize: 13)),
                            if (!_fixed && cat.subjects.length > 1) ...[
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _Pill(
                                    label: McqStrings.allSubjects,
                                    selected: _subjectId == null,
                                    onTap: () => setState(() {
                                      _subjectId = null;
                                      _count = _defaultCount(_pool.length);
                                    }),
                                  ),
                                  for (final s in cat.subjects)
                                    _Pill(
                                      label: s.displayName,
                                      selected: _subjectId == s.id,
                                      onTap: () => setState(() {
                                        _subjectId = s.id;
                                        _count = _defaultCount(_pool.length);
                                      }),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      _Label(McqStrings.numberOfQuestions),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final n in opts)
                            _Pill(
                              label: n == pool.length && opts.length > 1
                                  ? '${McqStrings.allLabel} ($n)'
                                  : (n == pool.length
                                      ? McqStrings.questionsCount(n)
                                      : '$n'),
                              selected: _count == n,
                              onTap: () => setState(() => _count = n),
                            ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      McqSurface(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.timer_rounded,
                                    color: McqTheme.accent, size: 22),
                                const SizedBox(width: 10),
                                Expanded(child: _Label(McqStrings.timeLimit)),
                                Switch.adaptive(
                                  value: _timed,
                                  activeColor: McqTheme.accent,
                                  onChanged: (v) => setState(() => _timed = v),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_timed)
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  for (final m in _minuteOptions)
                                    _Pill(
                                      label: McqStrings.minutes(m),
                                      selected: _minutes == m,
                                      onTap: () => setState(() => _minutes = m),
                                    ),
                                ],
                              )
                            else
                              Text(McqStrings.noTimeLimit,
                                  style: TextStyle(
                                      color: AppColor.textSecondary,
                                      fontSize: 13.5)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      McqSurface(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.shuffle_rounded,
                                color: McqTheme.accent, size: 22),
                            const SizedBox(width: 10),
                            Expanded(child: _Label(McqStrings.randomizeQuestions)),
                            Switch.adaptive(
                              value: _random,
                              activeColor: McqTheme.accent,
                              onChanged: (v) => setState(() => _random = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            decoration: BoxDecoration(
              color: AppColor.scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: AppColor.borderColor)),
            ),
            child: McqPrimaryButton(
              label: McqStrings.startExam,
              trailingIcon: Icons.play_arrow_rounded,
              onTap: (pool.isEmpty || _count <= 0) ? null : _start,
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          color: AppColor.textPrimary, fontSize: 15.5, fontWeight: FontWeight.w800));
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Pill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minWidth: 56, minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? McqTheme.accent : AppColor.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: selected ? McqTheme.accent : AppColor.borderColor),
            ),
            child: McqText(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: selected ? Colors.white : AppColor.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
