import 'package:upgrade/controllers/feed_controller.dart';
import 'package:upgrade/services/notification_router.dart';
import 'package:upgrade/widgets/streak_widget_prompt.dart';
import 'package:upgrade/screens/feed_screen.dart';
import 'package:upgrade/utils/deep_link_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/screens/library_screen.dart';
import 'package:upgrade/screens/profile_screen.dart';
import 'package:upgrade/screens/progress_screen.dart';
import 'package:upgrade/screens/years_screen.dart';

class MainController extends GetxController {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final RxInt _page = 0.obs;
  int get page => _page.value;
  set page(value) => _page.value = value;

  @override
  void onReady() {
    DeepLinkService.markReady();
    // Loaded here (not lazily inside FeedScreen) so the unread red dot
    // on the bottom nav can be correct even before the feed tab is
    // ever opened.
    Get.put(FeedController(), permanent: true).load();
    StreakWidgetPrompt.maybeShow();
    NotificationRouter.consumePending();
    super.onReady();
  }

  @override
  void onClose() {
    DeepLinkService.markNotReady();
    super.onClose();
  }

  onChangePage(index) async {
    page = index;
  }

  final pages = const [
    YearsScreen(),
    LibraryScreen(),
    ProgressScreen(),
    ProfileScreen(),
    FeedScreen(),
  ];
}
