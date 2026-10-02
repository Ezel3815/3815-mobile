import 'dart:io';
import 'package:home_widget/home_widget.dart';
import 'package:upgrade/main.dart';

/// Feeds the Android home-screen streak widget. Streak stays server-authoritative:
/// the widget only ever shows the last value the app received, and a failed or
/// empty refresh never lowers it.
class StreakWidgetService {
  StreakWidgetService._();
  static final StreakWidgetService instance = StreakWidgetService._();

  static const _provider = 'StreakWidgetProvider';
  static const _qualified = 'com.example.upgrade.StreakWidgetProvider';
  static const _keyCount = 'streak_count';
  static const _keyStudied = 'streak_studied_date';
  // Written by NotificationService.markStudiedToday (same "y-m-d" format).
  static const _appStudiedKey = 'notif_last_study_date';

  bool get supported => Platform.isAndroid;

  Future<void> sync({int? streak, bool? studiedToday}) async {
    if (!supported) return;
    try {
      if (streak != null && streak >= 0) {
        await HomeWidget.saveWidgetData<int>(_keyCount, streak);
      }
      final studied = studiedToday == true
          ? _todayString()
          : sharedPref.getString(_appStudiedKey);
      if (studied != null) {
        await HomeWidget.saveWidgetData<String>(_keyStudied, studied);
      }
      await HomeWidget.updateWidget(
          name: _provider, qualifiedAndroidName: _qualified);
    } catch (_) {
      // Widget is a nice-to-have; never break the app for it.
    }
  }

  Future<bool> get isInstalled async {
    if (!supported) return false;
    try {
      final w = await HomeWidget.getInstalledWidgets();
      return w.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Asks the launcher to pin the widget (system confirmation dialog).
  /// Returns false when the launcher doesn't support it.
  Future<bool> requestPin() async {
    if (!supported) return false;
    try {
      await sync(); // so it is never empty on first appearance
      final ok = await HomeWidget.isRequestPinWidgetSupported();
      if (ok != true) return false;
      await HomeWidget.requestPinWidget(
          name: _provider, qualifiedAndroidName: _qualified);
      return true;
    } catch (_) {
      return false;
    }
  }

  String _todayString() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }
}
