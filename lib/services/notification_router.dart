import 'package:get/get.dart';
import 'package:upgrade/controllers/main_controller.dart';
import 'package:upgrade/main.dart';

/// Opens the right screen when a notification (local or push) is tapped.
/// If the app isn't ready yet (cold start / not logged in) the destination is
/// remembered and applied as soon as the main screen is up.
class NotificationRouter {
  NotificationRouter._();
  static const _pendingKey = 'pending_notification_route';

  /// [route]: 'quests' (friend challenge) or 'home' (study reminder).
  static void open(String route) {
    final hasSession = (sharedPref.getString('token') ?? '').isNotEmpty;
    if (hasSession && Get.isRegistered<MainController>()) {
      _go(route);
    } else {
      sharedPref.setString(_pendingKey, route);
    }
  }

  /// Called by MainController.onReady.
  static void consumePending() {
    final route = sharedPref.getString(_pendingKey);
    if (route == null) return;
    sharedPref.remove(_pendingKey);
    _go(route);
  }

  static void _go(String route) {
    try {
      Get.until((r) => r.settings.name == AppRoutes.mainRoute || r.isFirst);
      Get.find<MainController>().onChangePage(route == 'quests' ? 2 : 0);
    } catch (_) {}
  }
}
