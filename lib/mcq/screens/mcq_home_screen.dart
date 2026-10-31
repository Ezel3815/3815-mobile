import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/mcq/controllers/mcq_controllers.dart';
import 'package:upgrade/mcq/mcq_strings.dart';
import 'package:upgrade/mcq/screens/mcq_exam_screen.dart';
import 'package:upgrade/mcq/screens/mcq_exam_setup_screen.dart';
import 'package:upgrade/mcq/screens/mcq_practice_screen.dart';
import 'package:upgrade/mcq/screens/mcq_progress_screen.dart';
import 'package:upgrade/mcq/screens/mcq_review_screen.dart';
import 'package:upgrade/mcq/screens/mcq_subjects_screen.dart';
import 'package:upgrade/mcq/widgets/mcq_widgets.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/widgets/tablet_bounded.dart';

/// The MCQ tab (mockup frame 2: "MCQ Home").
class McqHomeScreen extends StatefulWidget {
  const McqHomeScreen({super.key});

  @override
  State<McqHomeScreen> createState() => _McqHomeScreenState();
}

class _McqHomeScreenState extends State<McqHomeScreen> {
  late final McqBankController bank = McqBankController.ensure();

  @override
  Widget build(BuildContext context) {
    return McqBackdrop(
      child: SafeArea(
        bottom: false,
        child: TabletBounded(
          child: Obx(() {
            if (bank.loading.value) {
              return Center(
                  child: CircularProgressIndicator(color: McqTheme.accent));
            }
            if (bank.loadFailed.value) {
              return McqEmptyState(
                icon: Icons.cloud_off_rounded,
                title: McqStrings.loadFailed,
                actionLabel: McqStrings.retry,
                onAction: bank.load,
              );
            }
            bank.tick(); // rebuild when progress changes
            if (!bank.hasQuestions) {
              return Column(
                children: [
                  McqTopBar(title: McqStrings.title, showBack: false),
                  Expanded(
                    child: McqEmptyState(
                      icon: Icons.quiz_rounded,
                      title: McqStrings.noQuestionsTitle,
                      body: McqStrings.noQuestionsBody,
                      actionLabel: McqStrings.retry,
                      onAction: bank.load,
                    ),
                  ),
                ],
              );
            }
            return RefreshIndicator(
              color: McqTheme.accent,
              onRefresh: bank.refresh,
              child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              children: [
                McqTopBar(title: McqStrings.title, showBack: false),
                const SizedBox(height: 10),
                _Hero(onStart: _startQuick),
                const SizedBox(height: 14),
                _tilesRow(
                  _McqTile(
                    icon: Icons.library_books_rounded,
                    title: McqStrings.questionBank,
                    subtitle: McqStrings.browseBySubject,
                    onTap: () => Get.to(() => const McqSubjectsScreen()),
                  ),
                  _McqTile(
                    icon: Icons.timer_rounded,
                    title: McqStrings.examMode,
                    subtitle: McqStrings.timedPractice,
                    onTap: _openExam,
                  ),
                ),
                const SizedBox(height: 12),
                _tilesRow(
                  _McqTile(
                    icon: Icons.fact_check_rounded,
                    title: McqStrings.review,
                    subtitle: bank.needsReviewCount > 0
                        ? McqStrings.toReview(bank.needsReviewCount)
                        : McqStrings.mistakesAndBookmarks,
                    onTap: () => Get.to(() => McqReviewScreen.global()),
                  ),
                  _McqTile(
                    icon: Icons.insights_rounded,
                    title: McqStrings.myProgress,
                    subtitle: McqStrings.viewStats,
                    onTap: () => Get.to(() => const McqProgressScreen()),
                  ),
                ),
                if (bank.resume != null || bank.examSnapshot != null) ...[
                  const SizedBox(height: 26),
                  Text(McqStrings.continueWhere,
                      style: TextStyle(
                          color: AppColor.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  if (bank.examSnapshot != null) ...[
                    _ContinueCard(
                      icon: Icons.timer_rounded,
                      badge: McqStrings.examInProgress,
                      title: bank.examSnapshot!.title,
                      progress: McqStrings.progressOf(
                          bank.examSnapshot!.answers.length,
                          bank.examSnapshot!.questionIds.length),
                      onTap: _resumeExam,
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (bank.resume != null)
                    _ContinueCard(
                      icon: Icons.description_rounded,
                      title: bank.resume!.title,
                      progress: McqStrings.progressOf(
                          bank.resume!.submitted.length,
                          bank.resume!.questionIds.length),
                      onTap: _resume,
                    ),
                ],
              ],
            ));
          }),
        ),
      ),
    );
  }

  Widget _tilesRow(Widget a, Widget b) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: a),
            const SizedBox(width: 12),
            Expanded(child: b),
          ],
        ),
      );

  void _startQuick() {
    final qs = bank.quickPracticeQuestions();
    if (qs.isEmpty) return;
    McqPracticeScreen.open(
        bank.startSession(title: McqStrings.title, questions: qs));
  }

  void _resume() {
    final c = bank.resumeSession();
    if (c != null) McqPracticeScreen.open(c);
  }

  void _resumeExam() {
    final c = bank.resumeExam();
    if (c != null) McqExamScreen.open(c);
  }

  /// Opens exam setup; if an unsubmitted exam exists, asks what to do first
  /// so it is never discarded by accident.
  Future<void> _openExam() async {
    if (bank.examSnapshot == null) {
      Get.to(() => const McqExamSetupScreen());
      return;
    }
    final cont = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColor.card,
        title: Text(McqStrings.examInProgress,
            style: TextStyle(color: AppColor.textPrimary)),
        content: Text(McqStrings.examPendingBody,
            style: TextStyle(color: AppColor.textSecondary, height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(McqStrings.startNewExam,
                  style: TextStyle(color: McqTheme.danger))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(McqStrings.continueExam)),
        ],
      ),
    );
    if (cont == null) return; // dismissed
    if (cont) {
      _resumeExam();
    } else {
      await bank.discardExam();
      Get.to(() => const McqExamSetupScreen());
    }
  }
}

class _Hero extends StatelessWidget {
  final VoidCallback onStart;
  const _Hero({required this.onStart});

  @override
  Widget build(BuildContext context) {
    final night = AppColor.night;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: McqTheme.heroGradient,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(night ? .10 : .0)),
        boxShadow: [
          BoxShadow(
            color: McqTheme.accent.withOpacity(.22),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            end: -4,
            top: -4,
            child: Image.asset(
              'lib/assests/nocturne/medical/icon-stethoscope-3.png',
              width: 104,
              height: 104,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(McqStrings.heroTitle,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.25)),
                    const SizedBox(height: 6),
                    Text(McqStrings.heroSubtitle,
                        style: TextStyle(
                            color: Colors.white.withOpacity(.78),
                            fontSize: 13.5)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onStart,
                  borderRadius: BorderRadius.circular(15),
                  child: Ink(
                    height: 50,
                    decoration: BoxDecoration(
                      color: night ? const Color(0xFF8B6CFF) : Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(McqStrings.startPractice,
                          style: TextStyle(
                              color: night
                                  ? Colors.white
                                  : AppColor.darkGreenColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _McqTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool soon;
  const _McqTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.soon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: soon ? .55 : 1,
      child: McqSurface(
        onTap: soon ? null : onTap,
        padding: const EdgeInsets.all(14),
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: McqTheme.accent.withOpacity(.16),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, size: 23, color: McqTheme.accent),
                ),
                if (soon)
                  McqChip(label: McqStrings.soon, color: AppColor.textSecondary),
              ],
            ),
            const SizedBox(height: 14),
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: AppColor.textPrimary,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: AppColor.textSecondary, fontSize: 12.5, height: 1.3)),
          ],
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final IconData icon;
  final String? badge;
  final String title;
  final String progress;
  final VoidCallback onTap;
  const _ContinueCard({
    required this.icon,
    this.badge,
    required this.title,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return McqSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: McqTheme.accent.withOpacity(.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: McqTheme.accent, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badge != null)
                  Text(badge!,
                      style: TextStyle(
                          color: McqTheme.warning,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800)),
                McqText(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppColor.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(progress,
                    style: TextStyle(
                        color: AppColor.textSecondary, fontSize: 12.5)),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: McqTheme.ctaGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }
}
