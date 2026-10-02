import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:upgrade/strings.dart';
import 'package:upgrade/widgets/app_image.dart';
import 'package:upgrade/widgets/lesson_path_widget.dart';
import 'package:upgrade/controllers/main_controller.dart';
import 'package:upgrade/controllers/years_controller.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/screens/app_drawer.dart';
import 'package:upgrade/widgets/tablet_bounded.dart';
import 'package:upgrade/widgets/mosaic/mosaic_hero_card.dart';

class YearsScreen extends StatefulWidget {
  const YearsScreen({super.key});
  @override
  State<YearsScreen> createState() => _YearsScreenState();
}

class _YearsScreenState extends State<YearsScreen> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final controller = Get.find<YearsController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColor.scaffoldBackgroundColor,
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Obx(
            () => controller.loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColor.greenColor,
                    ),
                  )
                : RefreshIndicator(
                    color: AppColor.greenColor,
                    onRefresh: () => Future.wait([
                      controller.getAllDeck(),
                      controller.getMyProfile(),
                      controller.getActivityFeed(),
                    ]),
                    child: TabletBounded(
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 20),
                        children: [
                          const SizedBox(height: 4),
                          _Header(scaffoldKey: scaffoldKey),
                          const SizedBox(height: 20),
                          _GreetingBlock(),
                          const SizedBox(height: 18),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: MosaicHeroCard(),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              AppStrings.yourLearningPath,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColor.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _CurrentSubjectLessons(),
                          const SizedBox(height: 24),
                          _FriendsActivity(),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
        drawerEnableOpenDragGesture: false,
        drawer: const AppDrawer(),
      ),
    );
  }
}

/// Top bar: menu, logo, streak pill, avatar.
class _Header extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const _Header({required this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<YearsController>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
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
          Image.asset(
            height: 26,
            width: 90,
            fit: BoxFit.contain,
            'lib/assests/images/logodeck.png',
          ),
          const Spacer(),
          Obx(() {
            final streak = controller.profile.value?.currentStreak ?? 0;
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColor.lightGreenColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.flame(PhosphorIconsStyle.fill),
                    size: 15,
                    color: AppColor.warningColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "$streak",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColor.darkGreenColor,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(width: 10),
          InkWell(
            onTap: () => Get.find<MainController>().onChangePage(3),
            child: Obx(() {
              final me = controller.profile.value;
              final name = me?.name ?? "";
              final initial = name.isNotEmpty ? name[0].toUpperCase() : "?";
              final photo = me?.avatarHair;
              // The same picture as on the profile; the initial is only a
              // fallback for people who haven't set a photo.
              return Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColor.greenColor,
                ),
                child: ClipOval(
                  child: (photo != null && photo.isNotEmpty)
                      ? AppImage(
                          image: photo,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _GreetingBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<YearsController>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Obx(() {
        final name = controller.profile.value?.name ?? "";
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name.isNotEmpty
                  ? "${AppStrings.welcomeBack}، $name"
                  : AppStrings.welcomeBack,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColor.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.continueJourney,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColor.textSecondary,
              ),
            ),
          ],
        );
      }),
    );
  }
}

String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return "الآن";
  if (diff.inMinutes < 60) return "قبل ${diff.inMinutes} د";
  if (diff.inHours < 24) return "قبل ${diff.inHours} س";
  return "قبل ${diff.inDays} ي";
}

/// The "I'm not studying alone" feed — recent real milestones from
/// people you follow (chapter completions, level-ups, achievement
/// unlocks). Nothing here is simulated; it's a direct read of the same
/// events that trigger celebration popups on each person's own device.
class _FriendsActivity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<YearsController>();
    return Obx(() {
      final feed = controller.activityFeed;
      if (feed.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.friendsActivity,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColor.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...feed.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColor.surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipOval(
                        child: (item.userAvatar != null &&
                                item.userAvatar!.isNotEmpty)
                            ? AppImage(
                                image: item.userAvatar!,
                                width: 34,
                                height: 34,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 34,
                                height: 34,
                                color: AppColor.lightGreenColor,
                                child: Center(
                                  child: Text(
                                    item.userName.isNotEmpty
                                        ? item.userName[0].toUpperCase()
                                        : "?",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColor.darkGreenColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColor.textPrimary,
                            ),
                            children: [
                              TextSpan(
                                text: item.userName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              TextSpan(text: " ${item.verbPhrase}"),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        _relativeTime(item.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      );
    });
  }
}

/// Shows the current subject's chapters as a guided lesson path —
/// reuses the exact same widget used when drilling into a subject from
/// Library, so Home and Library behave identically once you're looking
/// at a subject's lessons. No locking: every chapter is tappable.
class _CurrentSubjectLessons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<YearsController>();
    return Obx(() {
      final subject = controller.currentSubject;
      if (subject == null) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Text(
            AppStrings.noSubjectsYet,
            style: const TextStyle(color: AppColor.textSecondary),
          ),
        );
      }
      // Embedded: sizes to its content, the page's outer ListView scrolls.
      return LessonPathWidget(chapters: subject.children, embedded: true);
    });
  }
}
