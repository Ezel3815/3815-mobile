import 'dart:convert';
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:upgrade/resources.dart';
import 'package:upgrade/services/notification_engine.dart';
import 'package:upgrade/services/notification_pools.dart';
import 'package:upgrade/services/notification_selftest.dart';
import 'package:upgrade/services/notification_service.dart';

/// Test bench for notifications: check the phone setup, fire any pool right
/// now, run a whole "day" in ~1 minute, and verify that studying stops the
/// rest. Nothing here needs waiting for real clock times.
class NotificationLabScreen extends StatefulWidget {
  const NotificationLabScreen({super.key});

  @override
  State<NotificationLabScreen> createState() => _NotificationLabScreenState();
}

class _NotificationLabScreenState extends State<NotificationLabScreen> {
  final _svc = NotificationService.instance;
  bool _weekend = false;
  bool _due = false;
  List<SelfTestResult>? _selfTest;
  List<PlannedNotification> _fastDay = [];
  NotificationEngine _testEngine = NotificationEngine(MemoryNeStore());
  String _log = '';
  late Future<List<String>> _diag = _runDiagnostics();

  void _say(String s) => setState(() => _log = '$s\n$_log');

  Future<List<String>> _runDiagnostics() async {
    final out = <String>[];
    final android = _svc.plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final allowed = await _svc.notificationsAllowed();
    out.add('${allowed ? '✅' : '❌'} إذن الإشعارات في النظام');
    if (android != null) {
      final exact = await android.canScheduleExactNotifications() ?? false;
      out.add('${exact ? '✅' : 'ℹ️'} المنبّه الدقيق ${exact ? 'مسموح' : 'غير مفعّل (التذكيرات تعمل بدقة تقريبية ±15 دقيقة، وهذا طبيعي)'}');
    }
    final pending = await _svc.pendingNotifications();
    out.add('${pending.isNotEmpty ? '✅' : '⚠️'} مجدول الآن: ${pending.length} إشعار');
    out.add('🕒 المنطقة الزمنية: ${tz.local.name}');
    try {
      final t = await FirebaseMessaging.instance.getToken();
      out.add('${t != null ? '✅' : '❌'} رمز الإشعارات الفورية (للتحديات): ${t != null ? 'موجود' : 'غير موجود'}');
    } catch (_) {
      out.add('❌ Firebase غير متاح على هذا الجهاز');
    }
    final now = DateTime.now();
    out.add('📅 الحالة اليوم: ${_svc.engine.stateAt(now).name}   •   مراجعات مستحقة (من الخادم): ${_svc.dueReviews}   •   السلسلة: ${_svc.streak}');
    out.add('🔋 إن لم تصل الإشعارات أبدًا: عطّل «توفير البطارية» لتطبيق MOZAIK من إعدادات الهاتف (شاومي/هواوي/سامسونج توقف الإشعارات المجدولة).');
    return out;
  }

  PlannedNotification _fake(NotifPool pool, Slot slot, DateTime at, [int i = 0]) {
    final list = NotificationPools.list(pool, weekend: _weekend);
    final idx = Random().nextInt(list.length);
    return PlannedNotification(
      clientId: 'lab-$i-${at.millisecondsSinceEpoch}',
      slot: slot,
      pool: pool,
      weekend: _weekend,
      messageIndex: idx,
      message: list[idx],
      at: at,
      dayOffset: 0,
    );
  }

  Future<void> _fireNow(NotifPool pool) async {
    final p = _fake(pool, Slot.daily, DateTime.now());
    await _svc.showNow('MOZAIK', p.message);
    _say('أُرسل الآن [${pool.name} • ${_weekend ? 'عطلة' : 'أيام عادية'}]: ${p.message}');
  }

  /// A whole day compressed: 4 real scheduled notifications 12 s apart.
  Future<void> _startFastDay() async {
    await _svc.cancelTests();
    _testEngine = NotificationEngine(MemoryNeStore());
    final base = DateTime(2026, 10, _weekend ? 10 : 7, 6); // Sat / Wed 06:00
    final plan = _testEngine.planAhead(
      now: base,
      days: 1,
      dueCount: _due ? 6 : 0,
      streak: 5,
      weekendOverride: _weekend,
      ignoreCooldown: true,
    );
    final start = DateTime.now().add(const Duration(seconds: 10));
    for (var i = 0; i < plan.length; i++) {
      await _svc.scheduleTest(i, plan[i], start.add(Duration(seconds: 12 * i)));
    }
    setState(() => _fastDay = plan);
    _say('بدأ يوم تجريبي: ${plan.length} إشعارات خلال ~${12 * plan.length} ثانية. أغلق التطبيق أو اتركه مفتوحًا.');
  }

  Future<void> _studied() async {
    await _testEngine.markStudied(DateTime(2026, 10, 7, 12));
    await _svc.cancelTests();
    final left = await _svc.pendingNotifications();
    _say('✅ درس المستخدم → أُلغيت الإشعارات المتبقية (متبقي في الطابور: ${left.where((p) => p.id >= 8000 && p.id < 8010).length}). يجب ألا يصلك شيء بعد الآن.');
  }

  Future<void> _challengeTest() async {
    final msg = NotificationPools.challengeVariants[Random().nextInt(NotificationPools.challengeVariants.length)]
        .replaceAll('{friendName}', 'أحمد');
    await _svc.showNow('تحدٍّ جديد 🔥', msg, payload: jsonEncode({'route': 'quests', 'cid': 'lab-challenge'}));
    _say('أُرسل إشعار تحدٍّ تجريبي. اضغط عليه: يجب أن يفتح تبويب التحديات.');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColor.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('مختبر الإشعارات')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _card('1) فحص الجهاز', [
              FutureBuilder<List<String>>(
                future: _diag,
                builder: (_, s) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: (s.data ?? ['...'])
                      .map((l) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(l, style: const TextStyle(fontSize: 12.5, height: 1.4)),
                          ))
                      .toList(),
                ),
              ),
              _btn('إعادة الفحص', () => setState(() => _diag = _runDiagnostics())),
              _btn('إرسال إشعار تجريبي الآن', () async {
                await _svc.showTestNotification();
                _say('أُرسل إشعار تجريبي — هل ظهر في شريط الإشعارات؟');
              }),
            ]),
            _card('2) خيارات المحاكاة', [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('محاكاة يوم عطلة (السبت/الأحد)'),
                value: _weekend,
                onChanged: (v) => setState(() => _weekend = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('افتراض وجود مراجعات مستحقة'),
                value: _due,
                onChanged: (v) => setState(() => _due = v),
              ),
            ]),
            _card('3) أرسل أي مجموعة الآن', [
              Wrap(spacing: 8, runSpacing: 8, children: [
                _chip('☀️ الصباح', () => _fireNow(NotifPool.morning)),
                _chip('📚 التذكير اليومي', () => _fireNow(NotifPool.daily)),
                _chip('😈 الساخرة', () => _fireNow(NotifPool.passive)),
                _chip('🧠 المراجعة', () => _fireNow(NotifPool.review)),
                _chip('🔥 إضافية للعطلة', () => _fireNow(NotifPool.weekendExtra)),
                _chip('🏆 تحدٍّ من صديق', _challengeTest),
              ]),
            ]),
            _card('4) يوم كامل في دقيقة', [
              const Text(
                'يجدول 4 إشعارات حقيقية (صباح ← يومي ← ساخر ← متأخر) بفارق 12 ثانية. لاختبار التوقف: اضغط «درست الآن» بعد وصول أول إشعار — لن يصلك ما بعده.',
                style: TextStyle(fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _btn('ابدأ اليوم التجريبي', _startFastDay)),
                const SizedBox(width: 8),
                Expanded(child: _btn('درست الآن ✅', _studied)),
              ]),
              _btn('فتحت التطبيق بدون دراسة', () async {
                await _testEngine.markEntered(DateTime(2026, 10, 7, 12));
                _say('فتح التطبيق دون دراسة → الحالة: ${_testEngine.stateAt(DateTime(2026, 10, 7, 12)).name} (التذكيرات تستمر).');
              }),
              ..._fastDay.map((p) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('• ${p.slot.name} / ${p.pool.name}: ${p.message}',
                        style: const TextStyle(fontSize: 12)),
                  )),
            ]),
            _card('5) ما الذي سيُجدول فعليًا (حقيقي)', [
              _btn('عرض خطة الأيام السبعة القادمة', () {
                final plan = _svc.engine.planAhead(
                  now: DateTime.now(),
                  cfg: _svc.config,
                  dueCount: _due ? 6 : _svc.dueReviews,
                  streak: _svc.streak,
                );
                _say(plan.isEmpty
                    ? 'لا شيء مجدول (درست اليوم أو الإشعارات معطّلة).'
                    : plan
                        .take(12)
                        .map((p) =>
                            '${p.at.month}/${p.at.day} ${p.at.hour.toString().padLeft(2, '0')}:${p.at.minute.toString().padLeft(2, '0')}  ${p.slot.name}/${p.pool.name}  ${p.message}')
                        .join('\n'));
              }),
              _btn('تطبيق الجدولة الآن', () async {
                final p = await _svc.replan();
                setState(() => _diag = _runDiagnostics());
                _say('جُدول ${p.length} إشعارًا.');
              }),
            ]),
            _card('6) اختبار آلي (16 خطوة)', [
              _btn('تشغيل الاختبار الكامل', () async {
                final r = await runNotificationSelfTest();
                setState(() => _selfTest = r);
              }),
              if (_selfTest != null) ...[
                Text(
                  '${_selfTest!.where((r) => r.ok).length} / ${_selfTest!.length} نجح',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                ..._selfTest!.map((r) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('${r.ok ? '✅' : '❌'} ${r.label}${r.ok || r.detail.isEmpty ? '' : '  → ${r.detail}'}',
                          style: const TextStyle(fontSize: 12)),
                    )),
              ],
            ]),
            _card('7) سجل الإشعارات (آخر 12)', [
              ...(_svc.engine.records.where((r) => r.status != 'planned').toList()
                    ..sort((a, b) => b.at.compareTo(a.at)))
                  .take(12)
                  .map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '${r.at.month}/${r.at.day} ${r.at.hour}:${r.at.minute.toString().padLeft(2, '0')} • ${r.pool} • '
                          '${r.status == 'cancelled' ? 'أُلغي' : r.openedAt != null ? 'فُتح' : r.appOpened ? 'فُتح التطبيق' : 'لم يُفتح'}'
                          '${r.converted ? ' • أدّى للدراسة ✅' : ''}\n${r.message}',
                          style: const TextStyle(fontSize: 11.5, height: 1.4),
                        ),
                      )),
              _btn('رفع التحليلات إلى الخادم الآن', () async {
                await _svc.flushAnalytics();
                _say('تم طلب رفع التحليلات.');
              }),
              _btn('مسح بيانات النظام وإعادة البدء', () async {
                await _svc.engine.reset();
                await _svc.replan();
                setState(() {});
                _say('تم المسح.');
              }),
            ]),
            if (_log.isNotEmpty)
              _card('الناتج', [Text(_log, style: const TextStyle(fontSize: 12, height: 1.5))]),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, List<Widget> children) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColor.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      );

  Widget _btn(String label, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(foregroundColor: AppColor.greenColor),
            child: Text(label),
          ),
        ),
      );

  Widget _chip(String label, VoidCallback onTap) =>
      ActionChip(label: Text(label), onPressed: onTap);
}
