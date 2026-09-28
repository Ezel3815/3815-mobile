import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/controllers/api_controller.dart';
import 'package:upgrade/controllers/progress_controller.dart';
import 'package:upgrade/entity/quests_entity.dart';
import 'package:upgrade/main.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/widgets/app_image.dart';
import 'package:upgrade/widgets/app_snack_bar.dart';

const Color _trackLight = Color(0xFFE6EBD8);
const Color _cardBorder = Color(0xFFDDE4CC);

String _timeLabel(int hours) =>
    hours >= 48 ? '${(hours / 24).ceil()} أيام' : '$hours ساعة';

String _dailyTitle(DailyQuest q) {
  switch (q.id) {
    case 'daily_reviews':
      return 'راجع ${q.target} بطاقات';
    case 'daily_mastery':
      return 'أتقن ${q.target} بطاقات (سهل أو جيد)';
    case 'daily_chapter':
      return 'أنهِ فصلاً كاملاً';
    default:
      return q.id;
  }
}

Future<void> _claim(ProgressController c, String id) async {
  final xp = await c.claimChest(id);
  if (xp != null) {
    Get.snackbar(
      'فتحت الصندوق! 🎉',
      '+$xp نقطة خبرة',
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColor.greenColor,
      colorText: Colors.white,
      margin: const EdgeInsets.all(14),
      borderRadius: 16,
    );
  }
}

/// Duolingo-style "Quests" page: friends quest, daily quests.
/// (The monthly quest card was replaced by the Garden by the Sea mosaic hero
/// at the top of the Progress screen.)
class QuestsBody extends StatelessWidget {
  final ProgressController controller;
  const QuestsBody({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final q = controller.quests.value;
      if (q == null) {
        if (controller.questsLoading.value) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: CircularProgressIndicator(color: AppColor.greenColor),
            ),
          );
        }
        return _QuestsError(onRetry: controller.loadQuests);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'تحدي الأصدقاء', hours: q.friendsHoursLeft),
          const SizedBox(height: 12),
          _FriendsCard(q: q, controller: controller),
          const SizedBox(height: 26),
          _SectionHeader(title: 'المهام اليومية', hours: q.dailyHoursLeft),
          const SizedBox(height: 12),
          _DailyCard(q: q, controller: controller),
        ],
      );
    });
  }
}

class _QuestsError extends StatelessWidget {
  final VoidCallback onRetry;
  const _QuestsError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 44, color: AppColor.disabledColor),
          const SizedBox(height: 12),
          const Text(
            'تعذّر تحميل المهام',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColor.textPrimary),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColor.greenColor,
              side: const BorderSide(color: AppColor.greenColor),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int hours;
  const _SectionHeader({required this.title, required this.hours});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColor.textPrimary,
            ),
          ),
        ),
        const Icon(Icons.schedule_rounded,
            size: 18, color: AppColor.warningColor),
        const SizedBox(width: 4),
        Text(
          _timeLabel(hours),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColor.warningColor,
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Friends quest ─────────────────────────

class _FriendsCard extends StatelessWidget {
  final QuestsData q;
  final ProgressController controller;
  const _FriendsCard({required this.q, required this.controller});

  @override
  Widget build(BuildContext context) {
    final hasPartner = q.partner != null;
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أجيبا معاً على ${q.friendsTarget} بطاقة هذا الأسبوع',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColor.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _TwoToneBar(q: q)),
                    const SizedBox(width: 10),
                    _ChestButton(
                      controller: controller,
                      id: q.friendsChest.id,
                      tier: 'purple',
                      claimable: q.friendsChest.claimable,
                      claimed: q.friendsChest.claimed,
                      size: 44,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${(q.myCount + q.partnerCount).clamp(0, q.friendsTarget).toInt()} / ${q.friendsTarget}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColor.disabledColor,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 2, thickness: 2, color: _cardBorder),
          if (hasPartner) _partnerSection(context) else _emptySection(),
        ],
      ),
    );
  }

  Widget _partnerSection(BuildContext context) {
    final me = q.me;
    final partner = q.partner!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _PersonColumn(
                    person: me,
                    label: 'أنت',
                    count: q.myCount,
                    color: AppColor.greenColor,
                    studied: me?.studiedToday,
                  ),
                ),
                const VerticalDivider(
                    width: 2, thickness: 2, color: _cardBorder),
                Expanded(
                  child: _PersonColumn(
                    person: partner,
                    label: partner.name,
                    count: q.partnerCount,
                    color: AppColor.warningColor,
                    studied: partner.studiedToday,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _NudgeButton(partner: partner, controller: controller),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => _showFriendPicker(controller),
            child: const Text(
              'تغيير الشريك',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColor.greenColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptySection() {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          const Text(
            'اختر صديقاً للتحدي',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColor.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'اختر من أصدقائك (تتابعان بعضكما) من تريد أن تنجز معه التحدي الأسبوعي',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12.5, color: AppColor.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => _showFriendPicker(controller),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.greenColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'اختيار صديق',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TwoToneBar extends StatelessWidget {
  final QuestsData q;
  const _TwoToneBar({required this.q});

  @override
  Widget build(BuildContext context) {
    final t = q.friendsTarget;
    final mine = (q.myCount / t).clamp(0.0, 1.0).toDouble();
    final theirs = (q.partnerCount / t).clamp(0.0, 1.0 - mine).toDouble();
    final rest = (1.0 - mine - theirs).clamp(0.0, 1.0).toDouble();
    final a = (mine * 1000).round();
    final b = (theirs * 1000).round();
    final r = (rest * 1000).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 24,
        color: _trackLight,
        child: Row(
          children: [
            if (a > 0)
              Expanded(
                flex: a,
                child: const _BarFill(color: AppColor.greenColor, radius: 0),
              ),
            if (b > 0)
              Expanded(
                flex: b,
                child:
                    const _BarFill(color: AppColor.warningColor, radius: 0),
              ),
            if (r > 0) Expanded(flex: r, child: const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

class _PersonColumn extends StatelessWidget {
  final QuestPerson? person;
  final String label;
  final int count;
  final Color color;

  /// null = unknown (no status shown)
  final bool? studied;
  const _PersonColumn({
    required this.person,
    required this.label,
    required this.count,
    required this.color,
    this.studied,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _QuestAvatar(person: person, size: 62),
        const SizedBox(height: 8),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColor.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$count بطاقة',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        if (studied != null) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                studied! ? Icons.check_circle_rounded : Icons.schedule_rounded,
                size: 14,
                color: studied! ? AppColor.greenColor : AppColor.disabledColor,
              ),
              const SizedBox(width: 4),
              Text(
                studied! ? 'درس اليوم' : 'لم يدرس بعد',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: studied! ? AppColor.greenColor : AppColor.disabledColor,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _QuestAvatar extends StatelessWidget {
  final QuestPerson? person;
  final double size;
  const _QuestAvatar({required this.person, required this.size});

  @override
  Widget build(BuildContext context) {
    final photo = person?.photo;
    final name = person?.name ?? '';
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColor.lightGreenColor,
      ),
      child: ClipOval(
        child: (photo != null && photo.isNotEmpty)
            ? AppImage(
                image: photo,
                width: size,
                height: size,
                fit: BoxFit.cover,
              )
            : Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.w800,
                    color: AppColor.darkGreenColor,
                  ),
                ),
              ),
      ),
    );
  }
}

// ───────────────────────── Daily quests ─────────────────────────

class _DailyCard extends StatelessWidget {
  final QuestsData q;
  final ProgressController controller;
  const _DailyCard({required this.q, required this.controller});

  @override
  Widget build(BuildContext context) {
    final items = q.daily;
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 2, thickness: 2, color: _cardBorder),
            _DailyRow(quest: items[i], controller: controller),
          ],
        ],
      ),
    );
  }
}

class _DailyRow extends StatelessWidget {
  final DailyQuest quest;
  final ProgressController controller;
  const _DailyRow({required this.quest, required this.controller});

  @override
  Widget build(BuildContext context) {
    final frac = (quest.progress / quest.target).clamp(0.0, 1.0).toDouble();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dailyTitle(quest),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColor.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 24,
                    color: _trackLight,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (frac > 0)
                          FractionallySizedBox(
                            alignment: AlignmentDirectional.centerStart,
                            widthFactor: frac,
                            child: const SizedBox(
                              height: 24,
                              child: _BarFill(
                                  color: AppColor.greenColor, radius: 0),
                            ),
                          ),
                        Text(
                          '${quest.progress} / ${quest.target}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: frac >= 0.5
                                ? Colors.white
                                : AppColor.disabledColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          _ChestButton(
            controller: controller,
            id: quest.id,
            tier: quest.tier,
            claimable: quest.claimable,
            claimed: quest.claimed,
            size: 48,
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Shared pieces ─────────────────────────

BoxDecoration _cardDecoration() => BoxDecoration(
      color: AppColor.surfaceColor,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _cardBorder, width: 2),
    );

/// Progress fill with a soft glossy highlight (the "thick bar" look).
class _BarFill extends StatelessWidget {
  final Color color;
  final double radius;
  const _BarFill({required this.color, this.radius = 10});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.28),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _ChestButton extends StatelessWidget {
  final ProgressController controller;
  final String id;
  final String tier;
  final bool claimable;
  final bool claimed;
  final double size;
  const _ChestButton({
    required this.controller,
    required this.id,
    required this.tier,
    required this.claimable,
    required this.claimed,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = controller.claimingId.value == id;
      return GestureDetector(
        onTap: claimable && !busy ? () => _claim(controller, id) : null,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: claimable
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD25A).withOpacity(0.55),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      )
                    : null,
                child: Opacity(
                  opacity: (claimable || claimed) ? 1 : 0.45,
                  child: _Chest(tier: tier, size: size * 0.86),
                ),
              ),
              if (claimed)
                PositionedDirectional(
                  end: 0,
                  bottom: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColor.greenColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.check_rounded,
                        size: 11, color: Colors.white),
                  ),
                ),
              if (busy)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: AppColor.greenColor),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _Chest extends StatelessWidget {
  final String tier;
  final double size;
  const _Chest({required this.tier, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.82),
      painter: _ChestPainter(tier),
    );
  }
}

class _ChestPainter extends CustomPainter {
  final String tier;
  _ChestPainter(this.tier);

  @override
  void paint(Canvas canvas, Size s) {
    late Color body, lid, accent;
    switch (tier) {
      case 'gold':
        body = const Color(0xFFE0A21B);
        lid = const Color(0xFFF6C744);
        accent = const Color(0xFF8B5E0B);
        break;
      case 'silver':
        body = const Color(0xFF8E9BA5);
        lid = const Color(0xFFC5CED6);
        accent = const Color(0xFF56626B);
        break;
      case 'purple':
        body = const Color(0xFF7C6FA8);
        lid = const Color(0xFFA89BD1);
        accent = const Color(0xFF4A3F73);
        break;
      default: // bronze
        body = const Color(0xFFB8703B);
        lid = const Color(0xFFD8925A);
        accent = const Color(0xFF7A4520);
    }
    final w = s.width, h = s.height;

    final bodyRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, h * 0.42, w, h * 0.58), const Radius.circular(6));
    canvas.drawRRect(bodyRect, Paint()..color = body);

    final lidRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, w, h * 0.5),
      topLeft: Radius.circular(w * 0.32),
      topRight: Radius.circular(w * 0.32),
      bottomLeft: const Radius.circular(3),
      bottomRight: const Radius.circular(3),
    );
    canvas.drawRRect(lidRect, Paint()..color = lid);

    // vertical straps
    final strap = Paint()..color = accent.withOpacity(0.55);
    canvas.drawRect(Rect.fromLTWH(w * 0.16, 0, w * 0.1, h), strap);
    canvas.drawRect(Rect.fromLTWH(w * 0.74, 0, w * 0.1, h), strap);

    // lock plate
    final plate = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.4, h * 0.36, w * 0.2, h * 0.24),
      const Radius.circular(3),
    );
    canvas.drawRRect(plate, Paint()..color = accent);
    canvas.drawCircle(Offset(w * 0.5, h * 0.46), w * 0.028,
        Paint()..color = Colors.white.withOpacity(0.85));
  }

  @override
  bool shouldRepaint(covariant _ChestPainter old) => old.tier != tier;
}

// ───────────────────────── Nudge + partner picker ─────────────────────────

/// Real nudge: a feed post + push notification for the friend — or, if the
/// friend already studied today, a "they studied" badge instead.
class _NudgeButton extends StatelessWidget {
  final QuestPerson partner;
  final ProgressController controller;
  const _NudgeButton({required this.partner, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = controller.remindBusy.value; // read first: Obx needs an observable touched on every branch
      if (partner.studiedToday) {
        return Container(
          width: double.infinity,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColor.greenColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColor.greenColor.withOpacity(0.35), width: 2),
          ),
          child: Text(
            '${partner.name} درس اليوم 🎉',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColor.greenColor,
            ),
          ),
        );
      }
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton(
          onPressed: busy ? null : () => controller.remindPartner(partner),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColor.textPrimary,
            side: const BorderSide(color: _cardBorder, width: 2),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.2, color: AppColor.greenColor),
                )
              : Text(
                  '👋  ذكّر ${partner.name}',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800),
                ),
        ),
      );
    });
  }
}

Future<void> _showFriendPicker(ProgressController controller) async {
  await Get.bottomSheet(
    _FriendPickerSheet(controller: controller),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class _FriendPickerSheet extends StatefulWidget {
  final ProgressController controller;
  const _FriendPickerSheet({required this.controller});

  @override
  State<_FriendPickerSheet> createState() => _FriendPickerSheetState();
}

class _FriendPickerSheetState extends State<_FriendPickerSheet> {
  List<QuestFriend>? friends;
  bool failed = false;
  int? busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await ApiController.getQuestFriends();
    if (!mounted) return;
    setState(() {
      friends = data;
      failed = data == null;
    });
  }

  Future<void> _choose(QuestFriend f) async {
    if (busyId != null) return;
    setState(() => busyId = f.id);
    final ok = await widget.controller.choosePartner(f.id);
    if (!mounted) return;
    setState(() => busyId = null);
    if (ok) {
      Get.back();
      showSnackBarWidget(message: 'تم اختيار ${f.name} — أرسلنا له دعوة 🏆');
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.62),
        decoration: const BoxDecoration(
          color: AppColor.scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: _cardBorder,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Text(
                'اختر شريك التحدي',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColor.textPrimary,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'تظهر هنا فقط الأصدقاء الذين تتابعهم ويتابعونك',
                style: TextStyle(fontSize: 12.5, color: AppColor.textSecondary),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: _cardBorder),
            Flexible(child: _content()),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    final list = friends;
    if (failed) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: TextButton(
          onPressed: () {
            setState(() => failed = false);
            _load();
          },
          child: const Text('تعذّر تحميل الأصدقاء، إعادة المحاولة'),
        ),
      );
    }
    if (list == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(color: AppColor.greenColor),
      );
    }
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'لا يوجد أصدقاء متبادلون بعد. تابع صديقاً واطلب منه أن يتابعك.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: AppColor.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () {
                Get.back();
                Get.toNamed(AppRoutes.searchUsersRoute);
              },
              child: const Text('ابحث عن أصدقاء'),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final f = list[i];
        final busy = busyId == f.id;
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _choose(f),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColor.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: f.isPartner ? AppColor.greenColor : _cardBorder,
                width: f.isPartner ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                _QuestAvatar(
                  person: QuestPerson(id: f.id, name: f.name, photo: f.photo),
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      if (f.username != null && f.username!.isNotEmpty)
                        Text(
                          '@${f.username}',
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColor.textSecondary),
                        ),
                    ],
                  ),
                ),
                if (busy)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2, color: AppColor.greenColor),
                  )
                else if (f.isPartner)
                  const Icon(Icons.check_circle_rounded,
                      color: AppColor.greenColor)
                else
                  const Text(
                    'اختيار',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColor.greenColor,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
