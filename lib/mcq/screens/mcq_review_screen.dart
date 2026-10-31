import 'package:flutter/material.dart';
import 'package:upgrade/mcq/controllers/mcq_controllers.dart';
import 'package:upgrade/mcq/engine/mcq_engine.dart';
import 'package:upgrade/mcq/mcq_strings.dart';
import 'package:upgrade/mcq/models/mcq_models.dart';
import 'package:upgrade/mcq/widgets/mcq_page.dart';
import 'package:upgrade/mcq/widgets/mcq_widgets.dart';
import 'package:upgrade/resources.dart';
import 'package:get/get.dart';

class _TabSpec {
  final String label;
  final List<McqReviewItem> Function(McqBankController bank) items;
  const _TabSpec(this.label, this.items);
}

/// Mockup frame 8: Review Mistakes. One screen, two uses:
///  * [McqReviewScreen.global]  - all questions the student still gets wrong
///    (unique questions, latest attempt) plus bookmarks;
///  * [McqReviewScreen.forItems] - the exact set of a finished session.
class McqReviewScreen extends StatefulWidget {
  final String title;
  final List<_TabSpec> _tabs;

  const McqReviewScreen._(this.title, this._tabs, {super.key});

  factory McqReviewScreen.global({Key? key}) => McqReviewScreen._(
        McqStrings.reviewTitle,
        [
          _TabSpec(McqStrings.incorrectTab, (b) => b.incorrectItems()),
          _TabSpec(McqStrings.bookmarkedTab, (b) => b.bookmarkedItems()),
          _TabSpec(McqStrings.all, (b) {
            final out = <McqReviewItem>[...b.incorrectItems()];
            final seen = {for (final i in out) i.question.id};
            for (final i in b.bookmarkedItems()) {
              if (seen.add(i.question.id)) out.add(i);
            }
            return out;
          }),
        ],
        key: key,
      );

  factory McqReviewScreen.forItems({
    Key? key,
    required String title,
    required List<McqReviewItem> items,
  }) {
    List<McqReviewItem> only(McqAnswerStatus s) =>
        [for (final i in items) if (i.status == s) i];
    return McqReviewScreen._(
      title,
      [
        _TabSpec(McqStrings.all, (_) => items),
        _TabSpec(McqStrings.incorrectTab, (_) => only(McqAnswerStatus.incorrect)),
        _TabSpec(McqStrings.correctTab, (_) => only(McqAnswerStatus.correct)),
        if (items.any((i) => i.status == McqAnswerStatus.unanswered))
          _TabSpec(McqStrings.unansweredTab,
              (_) => only(McqAnswerStatus.unanswered)),
      ],
      key: key,
    );
  }

  @override
  State<McqReviewScreen> createState() => _McqReviewScreenState();
}

class _McqReviewScreenState extends State<McqReviewScreen> {
  final bank = McqBankController.ensure();
  int _tab = 0;
  final Set<String> _open = {};

  @override
  Widget build(BuildContext context) {
    return McqPage(
      child: Obx(() {
        bank.tick();
        final tabs = widget._tabs;
        final lists = [for (final t in tabs) t.items(bank)];
        final items = lists[_tab.clamp(0, lists.length - 1).toInt()];
        return Column(
          children: [
            McqTopBar(title: widget.title),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColor.surface2Color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColor.borderColor),
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < tabs.length; i++)
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: i == _tab,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => setState(() => _tab = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: i == _tab
                                    ? McqTheme.accent
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${tabs[i].label} (${lists[i].length})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: i == _tab
                                      ? Colors.white
                                      : AppColor.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? McqEmptyState(
                      icon: Icons.fact_check_outlined,
                      title: McqStrings.emptyReview)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _ReviewCard(
                        number: i + 1,
                        item: items[i],
                        bank: bank,
                        expanded: _open.contains(items[i].question.id),
                        onToggle: () => setState(() {
                          final id = items[i].question.id;
                          if (!_open.remove(id)) _open.add(id);
                        }),
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final int number;
  final McqReviewItem item;
  final McqBankController bank;
  final bool expanded;
  final VoidCallback onToggle;
  const _ReviewCard({
    required this.number,
    required this.item,
    required this.bank,
    required this.expanded,
    required this.onToggle,
  });

  String _letters(McqQuestion q, Set<String> ids) => [
        for (final o in q.options)
          if (ids.contains(o.id)) q.letterFor(o.id)
      ].join(', ');

  @override
  Widget build(BuildContext context) {
    final q = item.question;
    final subject = bank.cat?.subjectById(q.subjectId);
    final marked = bank.isBookmarked(q.id);
    final answered = item.status != McqAnswerStatus.unanswered;
    final ok = item.status == McqAnswerStatus.correct;
    return McqSurface(
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: McqTheme.accent.withOpacity(.16),
                  shape: BoxShape.circle,
                ),
                child: Text('$number',
                    style: TextStyle(
                        color: McqTheme.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: McqText(q.text,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppColor.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.5)),
                ),
              ),
              IconButton(
                tooltip: marked
                    ? McqStrings.removeBookmark
                    : McqStrings.addBookmark,
                onPressed: () => bank.toggleBookmark(q.id),
                icon: Icon(
                  marked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: marked ? McqTheme.accent : AppColor.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (answered)
                  McqChip(
                    label:
                        '${McqStrings.yourAnswer}: ${_letters(q, item.selected)}',
                    icon: ok ? Icons.check_rounded : Icons.close_rounded,
                    color: ok ? McqTheme.success : McqTheme.danger,
                  ),
                McqChip(
                  label:
                      '${McqStrings.correctShort}: ${q.correctLetters.join(', ')}',
                  icon: Icons.check_circle_outline_rounded,
                  color: McqTheme.success,
                ),
                if (subject != null)
                  McqChip(
                      label: subject.displayName,
                      color: AppColor.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: McqSecondaryButton(
              label: expanded
                  ? McqStrings.hideExplanation
                  : McqStrings.viewExplanation,
              onTap: onToggle,
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0, 12, 8, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final o in q.options)
                    if (q.correctOptionIds.contains(o.id))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: McqText('${q.letterFor(o.id)}. ${o.text}',
                            style: TextStyle(
                                color: McqTheme.success,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                height: 1.5)),
                      ),
                  const SizedBox(height: 4),
                  if (q.explanation != null)
                    McqText(q.explanation!,
                        style: TextStyle(
                            color: AppColor.textPrimary,
                            fontSize: 14.5,
                            height: 1.65))
                  else
                    Text(McqStrings.noExplanation,
                        style: TextStyle(
                            color: AppColor.textSecondary, fontSize: 13.5)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
