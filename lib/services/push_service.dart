import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:upgrade/controllers/api_controller.dart';
import 'package:upgrade/main.dart';
import 'package:upgrade/services/notification_router.dart';
import 'package:upgrade/services/notification_service.dart';

/// Must be a top-level (or static) function — the platform calls this
/// in a separate isolate when a data message arrives while the app is
/// fully closed. Kept minimal on purpose: no navigation, no
/// controllers, nothing that assumes the app's widget tree exists.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // Nothing to do here — a notification-type FCM message (which is
  // what the backend sends) is already shown by the OS itself when
  // the app isn't in the foreground. This handler exists so
  // firebase_messaging doesn't warn about a missing one.
}

/// Push notifications for events that should reach the user OUTSIDE
/// the app — a friend followed someone, a friend unlocked an
/// achievement (see push.utils.ts on the backend for the sending
/// side). Separate from NotificationService, which handles the
/// purely-local, on-device study reminders.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Call once at startup, after Firebase.initializeApp(). Safe to call
  /// even if the user isn't logged in yet — it only starts listening;
  /// the token is sent to the backend separately by [syncToken], which
  /// is called after login/register and here (for an already-logged-in
  /// user reopening the app).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground messages don't show a system notification on their
    // own (that's the OS's job when the app is backgrounded/closed) —
    // so show one manually here using the same local-notifications
    // plugin/channel NotificationService already set up.
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // Tapping a push (app in background / closed) → open the right screen.
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _handleTap(m));
    FirebaseMessaging.instance.getInitialMessage().then((m) {
      if (m != null) _handleTap(m);
    });

    // A token can change (app reinstalled, Firebase rotates it) at any
    // time, not just at startup.
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      ApiController.registerFcmToken(token);
    });

    await syncToken();
  }

  /// Records the push for analytics and routes challenge invites to the
  /// Quests tab (where the friends challenge lives).
  Future<void> _handleTap(RemoteMessage message) async {
    final data = message.data;
    if (data['type'] == 'challenge_invite') {
      await _recordChallenge(message, opened: true);
      NotificationRouter.open(data['route'] ?? 'quests');
    }
  }

  Future<void> _recordChallenge(RemoteMessage message, {required bool opened}) async {
    final data = message.data;
    final challengeId = int.tryParse(data['challenge_id'] ?? '');
    await NotificationService.instance.engine.recordExternal(
      // one record per invitation (each challenge has its own event id)
      clientId: 'challenge-${challengeId ?? message.messageId ?? DateTime.now().millisecondsSinceEpoch}',
      type: 'challenge_invite',
      message: message.notification?.body ?? '',
      sentAt: message.sentTime ?? DateTime.now(),
      opened: opened,
      challengeId: challengeId,
      friendId: int.tryParse(data['friend_id'] ?? ''),
    );
    NotificationService.instance.flushAnalytics();
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    if (message.data['type'] == 'challenge_invite') {
      _recordChallenge(message, opened: false);
    }
    await _plugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'social_notifications',
          'Friend activity',
          channelDescription: 'Follows, achievements and friend challenges',
          importance: Importance.high,
          priority: Priority.high,
          icon: NotificationService.smallIcon,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data['type'] == 'challenge_invite'
          ? '{"route":"${message.data['route'] ?? 'quests'}","cid":"challenge-${message.data['challenge_id'] ?? ''}"}'
          : null,
    );
  }

  /// Sends whatever token Firebase currently has to the backend — but
  /// only if the person is actually logged in, since the endpoint is
  /// authenticated. Safe to call repeatedly (login, register, app
  /// resume); it's a no-op with no session.
  Future<void> syncToken() async {
    final session = sharedPref.getString("token");
    if (session == null || session.isEmpty) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await ApiController.registerFcmToken(token);
      }
    } catch (e) {
      // No Google Play services (some tablets/emulators), or Firebase
      // not reachable — push notifications just won't work on this
      // device; everything else about the app keeps functioning.
      log('Could not fetch FCM token: $e');
    }
  }
}
