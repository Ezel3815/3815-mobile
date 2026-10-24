import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/entity/deck_entity.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/strings.dart';
import 'package:upgrade/utils/chapter_navigation.dart';
import 'package:upgrade/widgets/mozaik_mark_icon.dart';

/// Renders a list of chapter decks as a guided lesson path.
/// Every node is open — there is no progression lock. Progress
/// (not-started / in-progress / completed) is derived from each
/// card's existing `answer` field, no new backend data required.
class LessonPathWidget extends StatelessWidget {
  final List<DeckEntity> chapters;

  /// When true the list sizes itself to its content and leaves scrolling
  /// to the parent (used on Home, inside the page's own ListView).
  final bool embedded;
  const LessonPathWidget(
      {super.key, required this.chapters, this.embedded = false});

  _ChapterStatus _statusFor(DeckEntity chapter) {
    final total = chapter.cards.length;
    if (total == 0) return _ChapterStatus.notStarted;
    final answered = chapter.cards
        .where((c) => c.answer.isNotEmpty && c.answer != "NONE")
        .length;
    if (answered == 0) return _ChapterStatus.notStarted;
    if (answered >= total) return _ChapterStatus.completed;
    return _ChapterStatus.inProgress;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: embedded,
      physics: embedded ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        final status = _statusFor(chapter);
        final isLast = index == chapters.length - 1;
        return _LessonNode(
          index: index + 1,
          chapter: chapter,
          status: status,
          showConnector: !isLast,
        );
      },
    );
  }
}

enum _ChapterStatus { notStarted, inProgress, completed }

class _LessonNode extends StatelessWidget {
  final int index;
  final DeckEntity chapter;
  final _ChapterStatus status;
  final bool showConnector;

  const _LessonNode({
    required this.index,
    required this.chapter,
    required this.status,
    required this.showConnector,
  });

  Color get _nodeColor {
    switch (status) {
      case _ChapterStatus.completed:
        return AppColor.greenColor;
      case _ChapterStatus.inProgress:
        return AppColor.darkGreenColor;
      case _ChapterStatus.notStarted:
        return AppColor.disabledColor;
    }
  }

  /// Small badge shown centered on top of the mark — a check for
  /// completed chapters, otherwise the lesson number.
  Widget get _nodeBadge {
    switch (status) {
      case _ChapterStatus.completed:
        return const Icon(Icons.check_rounded, color: Colors.white, size: 16);
      case _ChapterStatus.inProgress:
      case _ChapterStatus.notStarted:
        return Text(
          "$index",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            shadows: [Shadow(color: Colors.black26, blurRadius: 3)],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // No lock check — every chapter is open, user can skip freely.
      onTap: () => openChapter(chapter),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      MozaikMarkIcon(color: _nodeColor, size: 36),
                      _nodeBadge,
                    ],
                  ),
                ),
                if (showConnector)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: status == _ChapterStatus.completed
                          ? AppColor.greenColor
                          : AppColor.lightGreenColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColor.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: status == _ChapterStatus.inProgress
                        ? Border.all(color: AppColor.greenColor, width: 1.5)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${AppStrings.lesson} $index",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                                color: AppColor.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              chapter.title,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColor.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (status == _ChapterStatus.completed)
                        Text("✓ ${AppStrings.completed}",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColor.greenColor,
                            ))
                      else if (status == _ChapterStatus.inProgress)
                        Text(AppStrings.inProgress,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColor.darkGreenColor,
                            ))
                      else
                        Text(AppStrings.pending,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColor.textSecondary.withOpacity(0.7),
                            )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
