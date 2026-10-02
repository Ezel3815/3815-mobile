import 'package:upgrade/widgets/mosaic/mosaic_hero_card.dart';
import 'package:upgrade/widgets/quests_view.dart';
import 'package:upgrade/strings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/controllers/progress_controller.dart';
import 'package:upgrade/entity/leaderboard_entry.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/screens/app_drawer.dart';
import 'package:upgrade/widgets/app_image.dart';
import 'package:upgrade/widgets/mozaik_mark_icon.dart';
import 'package:upgrade/widgets/tablet_bounded.dart';
import 'package:upgrade/controllers/mosaic_controller.dart';
import 'package:upgrade/widgets/mosaic/mosaic_artwork.dart';
import 'package:upgrade/main.dart' show AppRoutes;

const List<Color> _subjectAccentColors = [
  AppColor.greenColor,
  AppColor.infoColor,
  AppColor.warningColor,
  Color(0xFF7C6FA8),
  AppColor.freshGreenColor,
];

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProgressController());
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AppColor.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      drawerEnableOpenDragGesture: false,
      body: SafeArea(
        child: TabletBounded(
          child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () => scaffoldKey.currentState?.openDrawer(),
                  child: const Icon(
                    Icons.dehaze,
                    size: 26,
                    color: AppColor.textPrimary,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  AppStrings.navProgress,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const MosaicHeroCard(),
            const SizedBox(height: 18),
            Obx(
              () => Row(
                children: [
                  Expanded(
                    child: _TabPill(
                      label: AppStrings.tasks,
                      selected:
                          controller.tab.value == ProgressTab.achievements,
                      onTap: () =>
                          controller.tab.value = ProgressTab.achievements,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TabPill(
                      label: AppStrings.statistics,
                      selected: controller.tab.value == ProgressTab.statistics,
                      onTap: () =>
                          controller.tab.value = ProgressTab.statistics,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TabPill(
                      label: AppStrings.leaderboard,
                      selected: controller.tab.value == ProgressTab.leaderboard,
                      onTap: () =>
                          controller.tab.value = ProgressTab.leaderboard,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Obx(() {
              if (controller.tab.value == ProgressTab.achievements) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    QuestsBody(controller: controller),
                    const SizedBox(height: 28),
                    Text(
                      AppStrings.achievements,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _AchievementsBody(controller: controller),
                  ],
                );
              }
              if (controller.tab.value == ProgressTab.leaderboard) {
                return _LeaderboardBody(controller: controller);
              }
              return _StatisticsBody(controller: controller);
            }),
          ],
          ),
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColor.greenColor : AppColor.surfaceColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColor.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _AchievementsBody extends StatelessWidget {
  final ProgressController controller;
  const _AchievementsBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.achievementsLoading.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Center(
            child: CircularProgressIndicator(color: AppColor.greenColor),
          ),
        );
      }
      final achievements = controller.achievements;
      final unlockedCount = achievements.where((a) => a.unlocked).length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.unlockedOf(unlockedCount, achievements.length),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColor.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isTabletWidth(context) ? 5 : 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final a = achievements[index];
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColor.surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: a.unlocked
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: a.unlocked
                            ? AppColor.lightGreenColor
                            : AppColor.scaffoldBackgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        a.unlocked
                            ? Icons.emoji_events_rounded
                            : Icons.lock_outline_rounded,
                        color: a.unlocked
                            ? AppColor.darkGreenColor
                            : AppColor.textSecondary.withOpacity(0.4),
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: a.unlocked
                            ? AppColor.textPrimary
                            : AppColor.textSecondary.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      );
    });
  }
}

class _LeaderboardBody extends StatelessWidget {
  final ProgressController controller;
  const _LeaderboardBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.leaderboardLoading.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Center(
            child: CircularProgressIndicator(color: AppColor.greenColor),
          ),
        );
      }
      final entries = controller.leaderboard;
      if (entries.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text(
              AppStrings.followFriendsForRank,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColor.textSecondary),
            ),
          ),
        );
      }
      return Column(
        children: List.generate(entries.length, (index) {
          final entry = entries[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: entry.isMe
                  ? AppColor.lightGreenColor.withOpacity(0.5)
                  : AppColor.surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: entry.isMe
                  ? Border.all(color: AppColor.greenColor, width: 1.2)
                  : null,
              boxShadow: entry.isMe
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    "${index + 1}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ClipOval(
                  child: (entry.avatarPhotoName != null &&
                          entry.avatarPhotoName!.isNotEmpty)
                      ? AppImage(
                          image: entry.avatarPhotoName!,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 36,
                          height: 36,
                          color: AppColor.lightGreenColor,
                          child: Center(
                            child: Text(
                              entry.name.isNotEmpty
                                  ? entry.name[0].toUpperCase()
                                  : "?",
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColor.darkGreenColor,
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.isMe ? "${entry.name} (You)" : entry.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      Text(
                        "Level ${entry.level}",
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "${entry.xp} XP",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColor.greenColor,
                  ),
                ),
              ],
            ),
          );
        }),
      );
    });
  }
}

class _StatisticsBody extends StatelessWidget {
  final ProgressController controller;
  const _StatisticsBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final subjects = controller.subjectBreakdown;
      return Column(
        children: [
          // Total learning summary
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColor.surfaceColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryStat(
                    icon: Icons.local_fire_department_rounded,
                    color: AppColor.warningColor,
                    value: "${controller.streak}",
                    label: AppStrings.dayStreak,
                  ),
                ),
                Container(
                    width: 1,
                    height: 40,
                    color: Colors.black.withOpacity(0.06)),
                Expanded(
                  child: _SummaryStat(
                    icon: Icons.menu_book_rounded,
                    color: AppColor.greenColor,
                    value: "${controller.totalCardsReviewed}",
                    label: AppStrings.cardsReviewed,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Mastery rate
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColor.surfaceColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppStrings.masteryRate,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: CircularProgressIndicator(
                        value: controller.masteryPercent / 100,
                        strokeWidth: 8,
                        backgroundColor: AppColor.lightGreenColor,
                        valueColor: const AlwaysStoppedAnimation(
                            AppColor.greenColor),
                      ),
                    ),
                    Text(
                      "${controller.masteryPercent}%",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColor.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppStrings.performanceBySubject,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColor.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (subjects.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                AppStrings.noDataYet,
                style: TextStyle(color: AppColor.textSecondary),
              ),
            )
          else
            ...subjects.asMap().entries.map((entry) {
              final s = entry.value;
              final accentColor = _subjectAccentColors[
                  entry.key % _subjectAccentColors.length];
              return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColor.surfaceColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Center(
                            child: MozaikMarkIcon(color: accentColor, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.title,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColor.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: LinearProgressIndicator(
                                  value: s.mastery,
                                  minHeight: 5,
                                  backgroundColor:
                                      AppColor.scaffoldBackgroundColor,
                                  valueColor: const AlwaysStoppedAnimation(
                                      AppColor.greenColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "${(s.mastery * 100).round()}%",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColor.greenColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
            }),
        ],
      );
    });
  }
}

class _SummaryStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _SummaryStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColor.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColor.textSecondary,
          ),
        ),
      ],
    );
  }
}

const Color _mosaicGold = Color(0xFFD8B65A);
