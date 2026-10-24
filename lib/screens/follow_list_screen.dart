import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/controllers/api_controller.dart';
import 'package:upgrade/entity/follow_person.dart';
import 'package:upgrade/main.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/widgets/app_image.dart';
import 'package:upgrade/widgets/tablet_bounded.dart';

/// Who follows a user ("followers") or whom they follow ("following").
/// Opened by tapping the counts on a profile. Arguments:
/// {'userId': int, 'kind': 'followers' | 'following', 'name': String}
class FollowListScreen extends StatefulWidget {
  const FollowListScreen({super.key});

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  late final int userId;
  late final String kind;
  late final String ownerName;
  List<FollowPerson>? people;
  bool failed = false;
  final Set<int> busy = {};

  bool get isFollowers => kind == 'followers';

  @override
  void initState() {
    super.initState();
    final args = (Get.arguments as Map?) ?? {};
    userId = (args['userId'] as int?) ?? 0;
    kind = (args['kind'] as String?) ?? 'followers';
    ownerName = (args['name'] as String?) ?? '';
    _load();
  }

  Future<void> _load() async {
    final data = await ApiController.getFollowList(userId, kind);
    if (!mounted) return;
    setState(() {
      if (data != null) {
        people = data;
        failed = false;
      } else if (people == null) {
        failed = true; // keep an already-loaded list if a refresh fails
      }
    });
  }

  Future<void> _toggle(FollowPerson p) async {
    if (busy.contains(p.id)) return;
    setState(() => busy.add(p.id));
    final ok = p.isFollowing
        ? await ApiController.unfollowUser(p.id)
        : await ApiController.followUser(p.id);
    if (!mounted) return;
    setState(() {
      busy.remove(p.id);
      if (ok) p.isFollowing = !p.isFollowing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffoldBackgroundColor,
      body: SafeArea(
        child: TabletBounded(
          child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: Get.back,
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: AppColor.textPrimary),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFollowers ? 'المتابعون' : 'يتابع',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColor.textPrimary,
                          ),
                        ),
                        if (ownerName.isNotEmpty)
                          Text(
                            ownerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 13, color: AppColor.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _body()),
          ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    final list = people;
    if (list == null) {
      if (failed) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 44, color: AppColor.disabledColor),
              const SizedBox(height: 12),
              Text('تعذّر تحميل القائمة',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textPrimary)),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  setState(() => failed = false);
                  _load();
                },
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        );
      }
      return Center(
        child: CircularProgressIndicator(color: AppColor.greenColor),
      );
    }
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            isFollowers ? 'لا يوجد متابعون بعد' : 'لا يتابع أحداً بعد',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 15, color: AppColor.textSecondary, height: 1.4),
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColor.greenColor,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _row(list[i]),
      ),
    );
  }

  Widget _row(FollowPerson p) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Get.toNamed(AppRoutes.viewProfileRoute, arguments: p.id),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColor.surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColor.pick(0xFFDDE4CC, 0xFF252A58), width: 1),
        ),
        child: Row(
          children: [
            _avatar(p),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  if (p.username != null && p.username!.isNotEmpty)
                    Text(
                      '@${p.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12.5, color: AppColor.textSecondary),
                    ),
                ],
              ),
            ),
            if (!p.isMe) _followButton(p),
          ],
        ),
      ),
    );
  }

  Widget _followButton(FollowPerson p) {
    final busyNow = busy.contains(p.id);
    final following = p.isFollowing;
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: busyNow ? null : () => _toggle(p),
        style: OutlinedButton.styleFrom(
          foregroundColor: following ? AppColor.textPrimary : Colors.white,
          backgroundColor:
              following ? Colors.transparent : AppColor.greenColor,
          side: BorderSide(
            color: following ? const Color(0xFFDDE4CC) : AppColor.greenColor,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: busyNow
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColor.greenColor),
              )
            : Text(
                following ? 'أتابعه' : (isFollowers ? 'متابعة بالمثل' : 'متابعة'),
                style:
                    const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }

  Widget _avatar(FollowPerson p) {
    final photo = p.photo;
    return Container(
      width: 46,
      height: 46,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColor.lightGreenColor,
      ),
      child: ClipOval(
        child: (photo != null && photo.isNotEmpty)
            ? AppImage(image: photo, width: 46, height: 46, fit: BoxFit.cover)
            : Center(
                child: Text(
                  p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColor.darkGreenColor,
                  ),
                ),
              ),
      ),
    );
  }
}
