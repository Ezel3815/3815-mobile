import 'package:upgrade/services/notification_engine.dart';
import 'package:upgrade/services/notification_pools.dart';

class SelfTestResult {
  final String label;
  final bool ok;
  final String detail;
  const SelfTestResult(this.label, this.ok, [this.detail = '']);
}

/// Runs the whole notification flow against a FAKE clock and an in-memory
/// store (never touches real data), so a week of behaviour is checked in a
/// blink. Mirrors the 16-step flow from the spec.
Future<List<SelfTestResult>> runNotificationSelfTest() async {
  final out = <SelfTestResult>[];
  void check(String label, bool ok, [String detail = '']) =>
      out.add(SelfTestResult(label, ok, detail));

  const cfg = EngineConfig();
  final wed = DateTime(2026, 10, 7); // Wednesday
  final sat = DateTime(2026, 10, 10); // Saturday
  DateTime at(DateTime d, int h, [int m = 0]) => DateTime(d.year, d.month, d.day, h, m);

  var e = NotificationEngine(MemoryNeStore());

  // 1-2 Not studied → morning pool.
  var n = e.getNextNotification(now: at(wed, 6), cfg: cfg);
  check('1-2  لم يدرس → إشعار الصباح من مجموعة الصباح',
      n != null && n.pool == NotifPool.morning && !n.weekend && n.slot == Slot.morning,
      n?.message ?? 'null');

  // 3-4 Ignored → daily pool, then passive.
  n = e.getNextNotification(now: at(wed, 12), cfg: cfg);
  check('3-4  تجاهل الصباح → تذكير يومي', n?.pool == NotifPool.daily, '${n?.pool}');
  n = e.getNextNotification(now: at(wed, 15), cfg: cfg);
  check('5-6  تجاهل اليومي → المجموعة الساخرة', n?.pool == NotifPool.passive, '${n?.pool}');

  // 7-8 Opens the app but doesn't study → reminders continue.
  await e.markEntered(at(wed, 16));
  n = e.getNextNotification(now: at(wed, 16, 5), cfg: cfg);
  check('7-8  فتح التطبيق دون دراسة → التذكيرات مستمرة',
      e.stateAt(at(wed, 16, 5)) == StudyState.enteredApp && n != null && n.dayOffset == 0,
      '${e.stateAt(at(wed, 16, 5))}');

  // Whole day plan: spacing + no duplicates.
  final plan = await e.planAndStore(now: at(wed, 6), cfg: cfg, days: 1);
  var gapsOk = true;
  for (var i = 1; i < plan.length; i++) {
    if (plan[i].at.difference(plan[i - 1].at) < cfg.cooldown) gapsOk = false;
  }
  check('فترة تهدئة ≥ ساعتين بين الإشعارات', gapsOk && plan.length >= 3, '${plan.length} إشعارات');
  check('لا تتكرر الرسالة نفسها في اليوم',
      plan.map((p) => p.message).toSet().length == plan.length);

  // 9-12 Studies → STUDIED_TODAY → rest of the day cancelled.
  await e.markStudying(at(wed, 17));
  check('9  بدأ الجلسة → STUDYING', e.stateAt(at(wed, 17)) == StudyState.studying);
  e.reconcile(at(wed, 17)); // morning/daily were "sent" by now
  await e.markStudied(at(wed, 17, 30));
  check('10-11  أكمل الدراسة → STUDIED_TODAY', e.studiedToday(at(wed, 17, 30)));
  final left = e.planAhead(now: at(wed, 17, 31), cfg: cfg, days: 1);
  check('12  لا إشعارات دراسة متبقية اليوم', left.isEmpty, '${left.length} متبقي');
  final cancelled = e.records.where((r) => r.status == 'planned' && EngineKey.today(r, wed)).isEmpty;
  check('12  الإشعارات المجدولة لباقي اليوم أُلغيت', cancelled);

  // 13 Next day resets.
  final thu = wed.add(const Duration(days: 1));
  n = e.getNextNotification(now: at(thu, 6), cfg: cfg);
  check('13  اليوم التالي: يعود النظام من الصفر',
      e.stateAt(at(thu, 6)) == StudyState.notStudied && n?.pool == NotifPool.morning);

  // Studied before first notification → none.
  e = NotificationEngine(MemoryNeStore());
  await e.markStudied(at(wed, 6, 30));
  check('درس قبل أول إشعار → لا إشعار اليوم',
      e.planAhead(now: at(wed, 6, 31), cfg: cfg, days: 1).isEmpty);

  // Review pool only with due cards.
  e = NotificationEngine(MemoryNeStore());
  var p0 = e.planAhead(now: at(wed, 6), cfg: cfg, days: 1, dueCount: 0);
  var p1 = e.planAhead(now: at(wed, 6), cfg: cfg, days: 1, dueCount: 7);
  check('لا مراجعات مستحقة → بلا مجموعة المراجعة',
      !p0.any((p) => p.pool == NotifPool.review));
  check('مراجعات مستحقة → مجموعة المراجعة', p1.any((p) => p.pool == NotifPool.review));

  // Weekend pools.
  p1 = e.planAhead(now: at(sat, 6), cfg: cfg, days: 1, dueCount: 0);
  final m = p1.firstWhere((p) => p.slot == Slot.morning);
  check('السبت: صباح العطلة',
      m.weekend && NotificationPools.morningWeekend.contains(m.message), m.message);
  p1 = e.planAhead(now: at(sat, 6), cfg: cfg, days: 1, dueCount: 4);
  final r = p1.firstWhere((p) => p.slot == Slot.daily);
  check('السبت + مراجعات: مراجعة العطلة',
      NotificationPools.reviewWeekend.contains(r.message), r.message);

  // No repeats across a week (same pool+type).
  e = NotificationEngine(MemoryNeStore());
  final week = await e.planAndStore(now: at(wed, 6), cfg: cfg, days: 7);
  final mornings = week.where((p) => p.slot == Slot.morning).map((p) => p.message).toList();
  check('أسبوع كامل بلا تكرار لرسائل الصباح', mornings.toSet().length == mornings.length,
      '${mornings.length} رسائل');

  // Cooldown after a recent notification.
  e = NotificationEngine(MemoryNeStore());
  await e.planAndStore(now: at(wed, 6), cfg: cfg, days: 1);
  e.reconcile(at(wed, 14, 10)); // daily (14:00) now "sent"
  final after = e.planAhead(now: at(wed, 14, 10), cfg: cfg, days: 1);
  check('تهدئة: لا إشعار خلال ساعتين من آخر إرسال',
      after.every((p) => p.at.difference(at(wed, 14)) >= cfg.cooldown));

  // Opened ≠ studied.
  e = NotificationEngine(MemoryNeStore());
  final pl = await e.planAndStore(now: at(wed, 6), cfg: cfg, days: 1);
  e.reconcile(at(wed, 22));
  await e.recordOpened(pl.first.clientId, at(wed, 9, 35));
  var rec = e.records.firstWhere((x) => x.clientId == pl.first.clientId);
  check('NOTIFICATION_OPENED ≠ STUDY_COMPLETED',
      rec.openedAt != null && !rec.studied && !rec.converted);
  await e.markStudied(at(wed, 22, 1));
  rec = e.records.where((x) => x.status == 'sent').reduce((a, b) => a.at.isAfter(b.at) ? a : b);
  check('الدراسة بعد إشعار تُسجَّل كتحويل', rec.studied && rec.converted && rec.cards >= 1);

  // Challenge text.
  final c = NotificationPools.challengeVariants.first.replaceAll('{friendName}', 'أحمد');
  check('رسالة التحدي تحمل اسم الصديق', c == 'أحمد تحداك! يلا نحرق هالتحدي 🔥', c);

  return out;
}

class EngineKey {
  static bool today(NotifRecord r, DateTime day) =>
      r.at.year == day.year && r.at.month == day.month && r.at.day == day.day;
}
