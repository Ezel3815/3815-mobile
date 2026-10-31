import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/mcq/controllers/mcq_controllers.dart';
import 'package:upgrade/mcq/data/mcq_progress_store.dart';
import 'package:upgrade/mcq/engine/mcq_stats.dart';
import 'package:upgrade/mcq/mcq_strings.dart';
import 'package:upgrade/mcq/widgets/mcq_page.dart';
import 'package:upgrade/mcq/widgets/mcq_widgets.dart';
import 'package:upgrade/resources.dart';

/// Mockup frame 14: My Progress. Everything shown is computed from real
/// stored attempts and sessions (see McqStats for each definition); nothing
/// appears until there is data.
class McqProgressScreen extends StatefulWidget {
  const McqProgressScreen({super.key});

  @override
  State<McqProgressScreen> createState() => _McqProgressScreenState();
}

class _McqProgressScreenState extends State<McqProgressScreen> {
  final bank = McqBankController.ensure();
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return McqPage(
      child: Obx(() {
        bank.tick();
        final st = bank.stats;
        return Column(
          children: [
            McqTopBar(title: McqStrings.progressTitle),
            if (!st.hasData)
              Expanded(
                child: McqEmptyState(
                  icon: Icons.insights_rounded,
                  title: McqStrings.noProgressTitle,
                  body: McqStrings.noProgressBody,
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                child: _Segmented(
                  labels: [McqStrings.overview, McqStrings.bySubject],
                  index: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: _tab == 0 ? _overview(st) : _subjects(st),
                ),
              ),
            ],
          ],
        );
      }),
    );
  }

  List<Widget> _overview(McqStats st) {
    return [
      if (st.attempts > 0)
        McqSurface(
          padding: const EdgeInsets.symmetric(vertical: 22),
          child: Column(
            children: [
              McqScoreRing(correct: st.correctAttempts, total: st.attempts),
              const SizedBox(height: 12),
              Text(McqStrings.overallAccuracy,
                  style: TextStyle(
                      color: AppColor.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(McqStrings.attemptsHint(st.attempts),
                  style: TextStyle(color: AppColor.textSecondary, fontSize: 12.5)),
            ],
          ),
        ),
      if (st.attempts > 0 && st.isEarly) ...[
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded,
                size: 18, color: AppColor.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(McqStrings.earlyNote,
                  style: TextStyle(
                      color: AppColor.textSecondary, fontSize: 12.5, height: 1.45)),
            ),
          ],
        ),
      ],
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: _Box(
              value: '${st.completedSessions}',
              label: McqStrings.completedSessions,
              sub: '${McqStrings.completedExams}: ${st.completedExams}',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Box(
              value: McqStrings.hoursMinutes(st.studyMs),
              label: McqStrings.studyTime,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      McqSurface(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.task_alt_rounded, color: McqTheme.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(McqStrings.questionsAnswered,
                  style: TextStyle(
                      color: AppColor.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700)),
            ),
            Text('${st.uniqueAnswered}',
                style: TextStyle(
                    color: AppColor.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
      if (st.recent.isNotEmpty) ...[
        const SizedBox(height: 24),
        Text(McqStrings.recentSessions,
            style: TextStyle(
                color: AppColor.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        for (final r in st.recent) ...[
          _SessionRow(r),
          const SizedBox(height: 10),
        ],
      ],
    ];
  }

  List<Widget> _subjects(McqStats st) {
    final cat = bank.cat;
    if (st.bySubject.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Center(
            child: Text(McqStrings.noSubjectData,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColor.textSecondary, fontSize: 14)),
          ),
        ),
      ];
    }
    return [
      Text(McqStrings.subjectAccuracyHint,
          style: TextStyle(color: AppColor.textSecondary, fontSize: 12.5)),
      const SizedBox(height: 12),
      for (final s in st.bySubject) ...[
        McqSurface(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: McqText(
                        cat?.subjectById(s.subjectId)?.displayName ?? s.subjectId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: AppColor.textPrimary,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800)),
                  ),
                  Text('${((s.accuracy ?? 0) * 100).round()}%',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                          color: AppColor.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 4),
              Text(McqStrings.subjectAnswered(s.answered),
                  style: TextStyle(color: AppColor.textSecondary, fontSize: 12.5)),
              const SizedBox(height: 10),
              McqProgressBar(value: s.accuracy ?? 0),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    ];
  }
}

class _Segmented extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const _Segmented(
      {required this.labels, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColor.surface2Color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.borderColor),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == index,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: i == index ? McqTheme.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(labels[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: i == index
                                ? Colors.white
                                : AppColor.textSecondary)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  final String value;
  final String label;
  final String? sub;
  const _Box({required this.value, required this.label, this.sub});

  @override
  Widget build(BuildContext context) => McqSurface(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    color: AppColor.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(color: AppColor.textSecondary, fontSize: 12.5)),
            if (sub != null) ...[
              const SizedBox(height: 4),
              Text(sub!,
                  style: TextStyle(color: AppColor.textSecondary, fontSize: 11.5)),
            ],
          ],
        ),
      );
}

class _SessionRow extends StatelessWidget {
  final McqSessionRecord r;
  const _SessionRow(this.r);

  @override
  Widget build(BuildContext context) {
    final d = DateTime.fromMillisecondsSinceEpoch(r.atMs);
    final date =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    return McqSurface(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: McqTheme.accent.withOpacity(.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(r.isExam ? Icons.timer_rounded : Icons.edit_note_rounded,
                color: McqTheme.accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                McqText(r.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppColor.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                    '${r.isExam ? McqStrings.modeExam : McqStrings.modePractice} · $date',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                        color: AppColor.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text('${r.correct}/${r.total}',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                  color: AppColor.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
