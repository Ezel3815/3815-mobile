import 'package:upgrade/widgets/nocturne_mascot.dart';
import 'package:upgrade/widgets/edit_profile_dialog.dart';
import 'package:upgrade/strings.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:upgrade/api.dart';
import 'package:upgrade/controllers/profile_controller.dart';
import 'package:upgrade/entity/profile_entity.dart';
import 'package:upgrade/main.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/screens/app_drawer.dart';
import 'package:upgrade/widgets/app_image.dart';

class ProfileScreen extends StatefulWidget {
  final int? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late final controller = Get.put(
    ProfileController(targetUserId: widget.userId),
    tag: widget.userId?.toString() ?? "me",
  );

  Future<void> _openFollowList(ProfileEntity p, String kind) async {
    await Get.toNamed(AppRoutes.followListRoute,
        arguments: {'userId': p.id, 'kind': kind, 'name': p.name});
    controller.load(); // counts may have changed (follow / unfollow)
  }

  String _formatJoined(DateTime? date) {
    if (date == null) return "";
    final months = [
      AppStrings.monthJanuary, AppStrings.monthFebruary, AppStrings.monthMarch,
      AppStrings.monthApril, AppStrings.monthMay, AppStrings.monthJune,
      AppStrings.monthJuly, AppStrings.monthAugust, AppStrings.monthSeptember,
      AppStrings.monthOctober, AppStrings.monthNovember, AppStrings.monthDecember
    ];
    return AppStrings.joinedOn(months[date.month - 1], date.year);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AppColor.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      drawerEnableOpenDragGesture: false,
      body: Obx(
        () {
          if (controller.loading.value) {
            return Center(
              child: CircularProgressIndicator(color: AppColor.greenColor),
            );
          }
          final profile = controller.profile.value;
          if (profile == null) {
            return Center(
              child: Text(
                "Couldn't load profile",
                style: TextStyle(color: AppColor.textSecondary),
              ),
            );
          }
          // Pull down to refresh (works whether load() returns a Future
          // or not).
          return RefreshIndicator(
            color: AppColor.greenColor,
            onRefresh: () => Future<void>.sync(() => controller.load()),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 260,
                        decoration: BoxDecoration(
                          color: AppColor.lightGreenColor,
                        ),
                        child: SafeArea(
                          child: Stack(
                            children: [
                              const Align(
                                alignment: Alignment.bottomLeft,
                                child: Padding(
                                  padding: EdgeInsets.only(left: 6, bottom: 14),
                                  child: NocturneMascot(
                                      pose: 'star-hug', height: 56),
                                ),
                              ),
                              Align(
                                alignment: Alignment.topLeft,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: InkWell(
                                    onTap: () => Get.toNamed(
                                        AppRoutes.searchUsersRoute),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColor.card.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        PhosphorIcons.magnifyingGlass(
                                            PhosphorIconsStyle.bold),
                                        size: 22,
                                        color: AppColor.darkGreenColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: InkWell(
                                    onTap: () =>
                                        scaffoldKey.currentState?.openDrawer(),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColor.card.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        PhosphorIcons.gearSix(
                                            PhosphorIconsStyle.bold),
                                        size: 22,
                                        color: AppColor.darkGreenColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Center(
                                child: Container(
                                  width: 152,
                                  height: 152,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColor.card,
                                    border: Border.all(
                                      color: AppColor.greenColor,
                                      width: 3,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: ClipOval(
                                      child: (profile.avatarPhotoName != null &&
                                              profile.avatarPhotoName!
                                                  .isNotEmpty)
                                          ? AppImage(
                                              image: profile.avatarPhotoName!,
                                              width: 144,
                                              height: 144,
                                              fit: BoxFit.cover,
                                            )
                                          : Icon(
                                              PhosphorIcons.userCircle(
                                                  PhosphorIconsStyle.light),
                                              size: 96,
                                              color: AppColor.greenColor,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // "Change Photo" only exists on your own profile.
                      if (controller.isOwnProfile)
                        Positioned(
                          bottom: -18,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: InkWell(
                              onTap: controller.uploadingPhoto.value
                                  ? null
                                  : controller.pickAndUploadAvatar,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColor.darkGreenColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    controller.uploadingPhoto.value
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(
                                            PhosphorIcons.camera(
                                                PhosphorIconsStyle.bold),
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                    const SizedBox(width: 6),
                                    Text(
                                      AppStrings.changePhoto,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: controller.isOwnProfile ? 30 : 20),
                  // On tablets the details stay a centred column instead of
                  // stretching across the whole screen.
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColor.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.username != null
                                ? "@${profile.username} · ${_formatJoined(profile.createdAt)}"
                                : _formatJoined(profile.createdAt),
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColor.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColor.surfaceColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _StatItem(
                                  icon: PhosphorIcons.flame(
                                      PhosphorIconsStyle.fill),
                                  iconColor: AppColor.warningColor,
                                  value: "${profile.currentStreak}",
                                  label: AppStrings.dayStreak,
                                ),
                                Container(
                                    width: 1,
                                    height: 32,
                                    color: AppColor.ink.withOpacity(0.06)),
                                InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () =>
                                      _openFollowList(profile, 'following'),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    child: _StatItem(
                                      value: "${profile.followingCount}",
                                      label: AppStrings.following,
                                    ),
                                  ),
                                ),
                                Container(
                                    width: 1,
                                    height: 32,
                                    color: AppColor.ink.withOpacity(0.06)),
                                InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () =>
                                      _openFollowList(profile, 'followers'),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    child: _StatItem(
                                      value: "${profile.followersCount}",
                                      label: AppStrings.followers,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: controller.isOwnProfile
                                      ? OutlinedButton(
                                          onPressed: () => Get.dialog(
                                              EditProfileDialog(
                                                  controller: controller)),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                                color: AppColor.greenColor),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: Text(
                                            AppStrings.editProfile,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColor.greenColor,
                                            ),
                                          ),
                                        )
                                      : ElevatedButton(
                                          onPressed: controller.followBusy.value
                                              ? null
                                              : controller.toggleFollow,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                profile.isFollowing
                                                    ? Colors.white
                                                    : AppColor.greenColor,
                                            elevation: 0,
                                            side: BorderSide(
                                                color: AppColor.greenColor),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              if (profile.isFriend) ...[
                                                Icon(
                                                  PhosphorIcons.usersThree(
                                                      PhosphorIconsStyle
                                                          .fill),
                                                  size: 15,
                                                  color: profile.isFollowing
                                                      ? AppColor.greenColor
                                                      : Colors.white,
                                                ),
                                                const SizedBox(width: 6),
                                              ],
                                              Text(
                                                profile.isFriend
                                                    ? "FRIENDS"
                                                    : profile.isFollowing
                                                        ? "FOLLOWING"
                                                        : "FOLLOW",
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: profile.isFollowing
                                                      ? AppColor.greenColor
                                                      : Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  final u = profile.username;
                                  if (u == null || u.isEmpty) {
                                    // No username yet: let the owner pick one first.
                                    if (controller.isOwnProfile) {
                                      Get.dialog(EditProfileDialog(
                                          controller: controller));
                                    }
                                    return;
                                  }
                                  Share.share(AppStrings.shareMe(u));
                                },
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: AppColor.greenColor
                                            .withOpacity(0.4)),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    PhosphorIcons.shareNetwork(
                                        PhosphorIconsStyle.bold),
                                    size: 18,
                                    color: AppColor.greenColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _LevelCard(profile: profile),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final ProfileEntity profile;
  const _LevelCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final progress = profile.xpForNextLevel == 0
        ? 0.0
        : profile.xpIntoLevel / profile.xpForNextLevel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColor.lightGreenColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "${profile.level}",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColor.darkGreenColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Level ${profile.level}",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    Text(
                      "${profile.xpIntoLevel}/${profile.xpForNextLevel} XP",
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColor.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 7,
                    backgroundColor: AppColor.scaffoldBackgroundColor,
                    valueColor:
                        AlwaysStoppedAnimation(AppColor.greenColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final Color? iconColor;
  const _StatItem({
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: iconColor ?? AppColor.textPrimary),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColor.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColor.textSecondary,
          ),
        ),
      ],
    );
  }
}
