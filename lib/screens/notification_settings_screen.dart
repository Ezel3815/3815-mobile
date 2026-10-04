import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:upgrade/main.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final _service = NotificationService.instance;
  late bool _studyOn = _service.studyReminderEnabled;
  late bool _streakOn = _service.streakReminderEnabled;
  late TimeOfDay _studyTime =
      TimeOfDay(hour: _service.studyHour, minute: _service.studyMinute);
  late TimeOfDay _streakTime =
      TimeOfDay(hour: _service.streakHour, minute: _service.streakMinute);

  Future<void> _pickTime({required bool isStudy}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStudy ? _studyTime : _streakTime,
    );
    if (picked == null) return;
    setState(() {
      if (isStudy) {
        _studyTime = picked;
      } else {
        _streakTime = picked;
      }
    });
    if (isStudy) {
      await _service.setStudyTime(picked.hour, picked.minute);
    } else {
      await _service.setStreakTime(picked.hour, picked.minute);
    }
  }

  String _fmt(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return "$h:$m ${t.period == DayPeriod.am ? 'AM' : 'PM'}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColor.scaffoldBackgroundColor,
        elevation: 0,
        title: const Text(
          "الإشعارات",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColor.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ReminderCard(
            icon: Icons.schedule_rounded,
            iconColor: AppColor.greenColor,
            title: "تذكير وقت المراجعة",
            subtitle: "تذكير لطيف في وقت مراجعتك المعتاد.",
            enabled: _studyOn,
            time: _fmt(_studyTime),
            onToggle: (v) async {
              setState(() => _studyOn = v);
              await _service.setStudyReminderEnabled(v);
            },
            onTapTime: () => _pickTime(isStudy: true),
          ),
          const SizedBox(height: 14),
          _ReminderCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColor.warningColor,
            title: "حماية السلسلة",
            subtitle: "ينبّهك لاحقاً في اليوم إذا لم تكن قد راجعت بعد.",
            enabled: _streakOn,
            time: _fmt(_streakTime),
            onToggle: (v) async {
              setState(() => _streakOn = v);
              await _service.setStreakReminderEnabled(v);
            },
            onTapTime: () => _pickTime(isStudy: false),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              "يتم إلغاء التذكيرات تلقائياً في أي يوم تكون قد راجعت فيه بالفعل.",
              style: TextStyle(
                fontSize: 12,
                color: AppColor.textSecondary.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            "اختبار",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColor.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              await _service.showTestNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("تم إرسال إشعار تجريبي — تحقق من الإشعارات."),
                ));
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColor.greenColor,
              side: const BorderSide(color: AppColor.greenColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.notifications_active_outlined, size: 18),
            label: const Text("إرسال إشعار تجريبي الآن"),
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<PendingNotificationRequest>>(
            future: _service.pendingNotifications(),
            builder: (context, snapshot) {
              final pending = snapshot.data ?? [];
              if (pending.isEmpty) {
                return const Text(
                  "لا يوجد شيء مجدول حالياً.",
                  style: TextStyle(fontSize: 12, color: AppColor.textSecondary),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: pending
                    .map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            "• ${p.title} (id ${p.id})",
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColor.textSecondary,
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool enabled;
  final String time;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTapTime;

  const _ReminderCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.time,
    required this.onToggle,
    required this.onTapTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColor.textSecondary.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                activeColor: AppColor.greenColor,
                onChanged: onToggle,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 4),
            Divider(color: Colors.black.withOpacity(0.06), height: 1),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTapTime,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 16, color: AppColor.textSecondary),
                    const SizedBox(width: 8),
                    const Text(
                      "وقت التذكير",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColor.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColor.greenColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded,
                        size: 18, color: AppColor.textSecondary),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
