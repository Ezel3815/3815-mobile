import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:upgrade/controllers/api_controller.dart';
import 'package:upgrade/main.dart';
import 'package:upgrade/services/notification_engine.dart';
import 'package:upgrade/services/notification_router.dart';

class PrefsNeStore implements NeStore {
  static const _key = 'ne_engine_v1';
  @override
  String? read() => sharedPref.getString(_key);
  @override
  Future<void> write(String json) => sharedPref.setString(_key, json);
}

/// Study reminders. WHAT is sent is decided by [NotificationEngine]
/// (study state → time slot → pool → random message inside that pool);
/// this class only talks to the OS: it schedules the engine's plan as local
/// notifications, cancels it the moment the user really studies, keeps the
/// state in sync with the server, and uploads the analytics.
///
/// Reminders are pre-scheduled for the next 7 days (so they still arrive if
/// the app isn't opened for a few days) and re-planned every time the app is
/// opened or the user studies.
class NotificationService with WidgetsBindingObserver {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const int _baseId = 3000; // 3000..3099 = engine plan
  static const int _legacyStudyId = 1001;
  static const int _legacyStreakId = 1002;
  static const String _channelId = 'mozaik_reminders_v2';
  static const String smallIcon = 'ic_stat_mozaik';

  static const _keyStudyEnabled = "notif_study_reminder_enabled";
  static const _keyStreakEnabled = "notif_streak_reminder_enabled";
  static const _keyStudyHour = "notif_study_hour";
  static const _keyStudyMinute = "notif_study_minute";
  static const _keyStreakHour = "notif_streak_hour";
  static const _keyStreakMinute = "notif_streak_minute";
  static const _keyDue = "ne_due_reviews";
  static const _keyStreak = "ne_streak";

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  DateTime _lastOpenSync = DateTime.fromMillisecondsSinceEpoch(0);
  NotificationEngine? _engine;

  NotificationEngine get engine => _engine ??= NotificationEngine(PrefsNeStore());
  FlutterLocalNotificationsPlugin get plugin => _plugin;

  // ───────────── settings (unchanged API) ─────────────
  bool get studyReminderEnabled => sharedPref.getBool(_keyStudyEnabled) ?? true;
  bool get streakReminderEnabled => sharedPref.getBool(_keyStreakEnabled) ?? true;
  int get studyHour => sharedPref.getInt(_keyStudyHour) ?? 14;
  int get studyMinute => sharedPref.getInt(_keyStudyMinute) ?? 0;
  int get streakHour => sharedPref.getInt(_keyStreakHour) ?? 21;
  int get streakMinute => sharedPref.getInt(_keyStreakMinute) ?? 30;
  int get dueReviews => sharedPref.getInt(_keyDue) ?? 0;
  int get streak => sharedPref.getInt(_keyStreak) ?? 0;

  EngineConfig get config => EngineConfig(
        remindersEnabled: studyReminderEnabled,
        lateEnabled: streakReminderEnabled,
        dailyMinutes: studyHour * 60 + studyMinute,
        lateMinutes: streakHour * 60 + streakMinute,
      );

  Future<void> setStudyReminderEnabled(bool v) async {
    await sharedPref.setBool(_keyStudyEnabled, v);
    await replan();
  }

  Future<void> setStreakReminderEnabled(bool v) async {
    await sharedPref.setBool(_keyStreakEnabled, v);
    await replan();
  }

  Future<void> setStudyTime(int h, int m) async {
    await sharedPref.setInt(_keyStudyHour, h);
    await sharedPref.setInt(_keyStudyMinute, m);
    await replan();
  }

  Future<void> setStreakTime(int h, int m) async {
    await sharedPref.setInt(_keyStreakHour, h);
    await sharedPref.setInt(_keyStreakMinute, m);
    await replan();
  }

  // ───────────── setup ─────────────
  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Mozaik reminders',
          channelDescription: 'Study reminders and friend challenges',
          importance: Importance.high,
          priority: Priority.high,
          icon: smallIcon,
        ),
        iOS: DarwinNotificationDetails(),
      );

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final localZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localZone));
    } catch (_) {}

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings(smallIcon),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: _onTap,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          'Mozaik reminders',
          description: 'Study reminders and friend challenges',
          importance: Importance.high,
        ));
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);

    // App launched by tapping a notification (cold start).
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      final r = launch!.notificationResponse;
      if (r != null) _onTap(r);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onAppOpened();
  }

  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<bool> notificationsAllowed() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.areNotificationsEnabled() ?? true;
    return true;
  }

  // ───────────── tap handling ─────────────
  void _onTap(NotificationResponse r) {
    try {
      final payload = r.payload;
      if (payload == null || payload.isEmpty) return;
      final j = jsonDecode(payload) as Map<String, dynamic>;
      final cid = j['cid'] as String?;
      if (cid != null) {
        engine.recordOpened(cid, DateTime.now()).then((_) => flushAnalytics());
      }
      final route = j['route'] as String?;
      if (route != null) NotificationRouter.open(route);
    } catch (_) {}
  }

  // ───────────── lifecycle events (called by the app) ─────────────

  /// App opened / foregrounded: counts as ENTERED_APP (reminders continue),
  /// then re-syncs with the server and re-plans.
  Future<void> onAppOpened() async {
    if (!_initialized) return;
    final now = DateTime.now();
    if (now.difference(_lastOpenSync).inSeconds < 20) return;
    _lastOpenSync = now;
    await engine.markEntered(now);
    await syncWithServer();
    await replan();
    await flushAnalytics();
  }

  /// A study session started → STUDYING (reminders still allowed until a card
  /// is actually answered).
  Future<void> onSessionStarted() => engine.markStudying(DateTime.now());

  /// Called after every server-confirmed answer. The first one of the day
  /// marks STUDIED_TODAY and cancels all remaining reminders for today.
  Future<void> onCardAnswered() async {
    final now = DateTime.now();
    final first = !engine.studiedToday(now);
    await engine.markStudied(now);
    if (first) await replan();
  }

  Future<void> onSessionFinished() => flushAnalytics();

  /// Back-compat name used by older call sites.
  Future<void> markStudiedToday() => onCardAnswered();
  Future<void> scheduleNextReminders() => onAppOpened();

  // ───────────── server sync / analytics ─────────────
  Future<void> syncWithServer() async {
    final s = await ApiController.getNotificationState();
    if (s == null) return; // offline: keep local state
    await sharedPref.setInt(_keyDue, (s['due_reviews'] as num?)?.toInt() ?? 0);
    await sharedPref.setInt(_keyStreak, (s['streak'] as num?)?.toInt() ?? 0);
    final now = DateTime.now();
    // Server day is UTC; only trust it after the UTC/local day roll-over
    // window, so a late-night session never silences tomorrow morning.
    if (s['studied_today'] == true && now.hour >= 5) {
      await engine.applyServerStudied(now);
    }
  }

  Future<void> flushAnalytics() async {
    final dirty = engine.dirtyRecords();
    if (dirty.isEmpty) return;
    final ok = await ApiController.postNotificationEvents(
        dirty.map((r) => r.toApi()).toList());
    if (ok) await engine.markUploaded(dirty.map((r) => r.clientId));
  }

  // ───────────── scheduling ─────────────
  Future<void> _cancelPlanned() async {
    await _plugin.cancel(_legacyStudyId);
    await _plugin.cancel(_legacyStreakId);
    for (var i = 0; i < 100; i++) {
      await _plugin.cancel(_baseId + i);
    }
  }

  /// Rebuilds the whole schedule from the engine's current decision.
  Future<List<PlannedNotification>> replan({int days = 7}) async {
    if (!_initialized) return const [];
    await _cancelPlanned();
    if (!await notificationsAllowed()) return const [];
    final now = DateTime.now();
    final plan = await engine.planAndStore(
      now: now,
      cfg: config,
      days: days,
      dueCount: dueReviews,
      streak: streak,
    );
    for (var i = 0; i < plan.length && i < 100; i++) {
      await _schedule(_baseId + i, plan[i]);
    }
    return plan;
  }

  Future<void> _schedule(int id, PlannedNotification p, {DateTime? at}) async {
    await _plugin.zonedSchedule(
      id,
      'MOZAIK',
      p.message,
      tz.TZDateTime.from(at ?? p.at, tz.local),
      _details,
      payload: jsonEncode({'cid': p.clientId, 'type': p.slot.name}),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Logout: this device must stop reminding the previous account.
  Future<void> clearForLogout() async {
    if (!_initialized) return;
    await _cancelPlanned();
    await cancelTests();
    await engine.reset();
  }

  // ───────────── testing helpers (used by the Notification Lab) ─────────────

  /// Shows a notification right now (same channel/icon as real ones).
  Future<void> showNow(String title, String body, {String? payload, int id = 9998}) =>
      _plugin.show(id, title, body, _details, payload: payload);

  /// Schedules [p] to fire at [at] (test only; uses a high id range so it
  /// never collides with the real plan).
  Future<void> scheduleTest(int slotIndex, PlannedNotification p, DateTime at) =>
      _schedule(8000 + slotIndex, p, at: at);

  /// Cancels the remaining test notifications (ids 8000..8009).
  Future<void> cancelTests() async {
    for (var i = 0; i < 10; i++) {
      await _plugin.cancel(8000 + i);
    }
  }

  Future<void> showTestNotification() => showNow(
        '✅ MOZAIK',
        'If you can see this, notifications are working.',
        id: 9999,
      );

  Future<List<PendingNotificationRequest>> pendingNotifications() =>
      _plugin.pendingNotificationRequests();
}
