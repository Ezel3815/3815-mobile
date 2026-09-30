import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/entity/card_entity.dart';
import 'package:upgrade/main.dart';
import 'package:upgrade/controllers/api_controller.dart';
import 'package:upgrade/models/user_model.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/widgets/tablet_bounded.dart';
import 'package:upgrade/controllers/mosaic_controller.dart';
import 'package:upgrade/controllers/session_rewards.dart';
import 'package:upgrade/widgets/mosaic/reward_flow_models.dart';
import 'package:upgrade/widgets/mosaic/reward_flow_screen.dart';
import 'package:upgrade/widgets/streak/streak_reward_screen.dart';

/// Shown after finishing every card in a study session. Reads its data
/// straight from the arguments CardViewController passes when the last
/// card is answered — no new backend endpoint, purely a summary of
/// what already happened client-side during the session.
class SessionResultScreen extends StatefulWidget {
  const SessionResultScreen({super.key});

  @override
  State<SessionResultScreen> createState() => _SessionResultScreenState();
}

class _SessionResultScreenState extends State<SessionResultScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _badgeScale;
  late final Animation<double> _contentFade;
  late final AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..forward();
    _badgeScale = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
    );
    _contentFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    )..forward();

    // _finishSession() in CardViewController flushes the whole session's
    // accumulated mosaic pieces into the queue SYNCHRONOUSLY, before it
    // navigates here — so by the time this screen exists, the batch (if
    // any) is already present. No polling needed; the short delay below is
    // purely cosmetic pacing, letting the confetti/entrance play first.
    _runRewardSequence();
  }

  /// 1) mosaic ceremony (unchanged: same queue, same batch removal), THEN
  /// 2) the standalone streak window, only if this session saved the streak.
  Future<void> _runRewardSequence() async {
    final args = Get.arguments;
    final SessionRewards? rewards =
        (args is Map && args['rewards'] is SessionRewards)
            ? args['rewards'] as SessionRewards
            : null;
    final int correct = (args is Map ? args['correct'] : null) ?? 0;
    final int wrong = (args is Map ? args['wrong'] : null) ?? 0;

    // The window is already on screen; wait (in the background) for the last
    // answer so a slow server can never lose the streak or the mosaic pieces.
    if (rewards != null) {
      await rewards.settled.timeout(const Duration(seconds: 30), onTimeout: () {});
      if (!mounted) return;
    }

    final mosaic = Get.isRegistered<MosaicController>()
        ? Get.find<MosaicController>()
        : Get.put(MosaicController());
    if (rewards != null && rewards.pieces.isNotEmpty) {
      final total = correct + wrong;
      mosaic.queueDailyReward(
        List.of(rewards.pieces),
        cardsStudied: total,
        accuracyPercent: total == 0 ? 0 : ((correct / total) * 100).round(),
      );
      rewards.pieces.clear();
    }
    final streak = await _streakToShow(rewards?.streak);
    final index = mosaic.rewardQueue.indexWhere((b) => b.source == RewardSource.daily);
    if (index != -1) {
      final batch = mosaic.rewardQueue.removeAt(index);
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RewardFlowScreen.daily(batch: batch)),
      );
    }

    if (streak != null && streak > 0) {
      if (index == -1) await Future.delayed(const Duration(milliseconds: 1100));
      if (!mounted) return;
      await StreakRewardScreen.show(context, streak: streak);
    }
  }

  /// Set to true to force the streak window after EVERY session (testing).
  static const bool _alwaysShowStreakWindow = false;

  /// Decides the streak number to show, or null for no window.
  /// 1) The server says it saved today's streak -> trust it.
  /// 2) Otherwise (already saved earlier today, or the flag was missed) show
  ///    the window ONCE per day using the profile's current streak, so the
  ///    first finished session of the day always gets its window.
  Future<int?> _streakToShow(int? serverStreak) async {
    const key = 'streak_window_shown_day';
    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    debugPrint('STREAK server=$serverStreak shownDay=${sharedPref.getString(key)}');
    if (serverStreak != null && serverStreak > 0) {
      await sharedPref.setString(key, today);
      return serverStreak;
    }
    if (!_alwaysShowStreakWindow && sharedPref.getString(key) == today) {
      return null;
    }
    try {
      final userJson = sharedPref.getString('user');
      if (userJson == null) return null;
      final id = UserModel.fromJson(jsonDecode(userJson)).id;
      if (id == null) return null;
      final p = await ApiController.getProfile(id);
      final s = p?.currentStreak ?? 0;
      debugPrint('STREAK fallback profile=$s');
      await sharedPref.setString(key, today);
      // The user just finished a session, so the streak is at least 1.
      return s > 0 ? s : 1;
    } catch (e) {
      debugPrint('STREAK fallback error: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map;
    final int correct = args['correct'] ?? 0;
    final int wrong = args['wrong'] ?? 0;
    final int minutes = args['minutes'] ?? 0;
    final List<CardEntity> mistakes =
        List<CardEntity>.from(args['mistakes'] ?? []);
    final bool isView = args['isView'] ?? false;
    final total = correct + wrong;
    final accuracy = total == 0 ? 0 : ((correct / total) * 100).round();
    final bool celebrate = total > 0 && accuracy >= 60;

    return Scaffold(
      backgroundColor: AppColor.scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: TabletBounded(
              maxWidth: 460,
              child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(),
                  ScaleTransition(
                    scale: _badgeScale,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColor.lightGreenColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColor.darkGreenColor,
                        size: 46,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeTransition(
                    opacity: _contentFade,
                    child: Column(
                      children: [
                        const Text(
                          "أحسنت!",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColor.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "لقد أكملت هذه الجلسة",
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColor.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: accuracy / 100),
                                duration: const Duration(milliseconds: 900),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, _) =>
                                    CircularProgressIndicator(
                                  value: value,
                                  strokeWidth: 9,
                                  backgroundColor: AppColor.lightGreenColor,
                                  valueColor: const AlwaysStoppedAnimation(
                                      AppColor.greenColor),
                                ),
                              ),
                            ),
                            Text(
                              "$accuracy%",
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: AppColor.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "الدقة",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColor.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatChip(
                              icon: Icons.star_rounded,
                              color: AppColor.warningColor,
                              value: "$correct",
                              label: "صحيح",
                            ),
                            _StatChip(
                              icon: Icons.close_rounded,
                              color: AppColor.errorColor,
                              value: "$wrong",
                              label: "خاطئ",
                            ),
                            _StatChip(
                              icon: Icons.schedule_rounded,
                              color: AppColor.infoColor,
                              value: "$minutes",
                              label: "دقيقة",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  FadeTransition(
                    opacity: _contentFade,
                    child: Column(
                      children: [
                        if (mistakes.isNotEmpty) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () {
                                Get.offNamed(
                                  AppRoutes.cardViewRoute,
                                  arguments: {
                                    'cards': mistakes,
                                    'isView': isView,
                                    'initalIndex': 0,
                                  },
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side:
                                    const BorderSide(color: AppColor.greenColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                "مراجعة ${mistakes.length} بطاقة فائتة",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColor.greenColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            // Pop only this screen (and any celebration dialog):
                            // back to the deck list for owners, or to wherever
                            // the study started for regular users. The old
                            // "until cardRoute" popped everything (black screen)
                            // when no card list was in the stack.
                            onPressed: () => Get.until((route) =>
                                route is! PopupRoute &&
                                route.settings.name !=
                                    AppRoutes.sessionResultRoute),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.greenColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              "متابعة",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
              ),
            ),
          ),
          if (celebrate)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (context, _) => CustomPaint(
                  size: Size.infinite,
                  painter: _ConfettiPainter(_confettiController.value),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ConfettiParticle {
  final double startX;
  final double delay;
  final double speed;
  final double drift;
  final double size;
  final double rotationSpeed;
  final Color color;
  final bool isCircle;

  _ConfettiParticle({
    required this.startX,
    required this.delay,
    required this.speed,
    required this.drift,
    required this.size,
    required this.rotationSpeed,
    required this.color,
    required this.isCircle,
  });
}

/// Lightweight confetti burst — no external package. ~36 small shapes
/// fall from just above the top edge, drifting sideways and rotating,
/// fading out over the last quarter of the animation.
class _ConfettiPainter extends CustomPainter {
  final double progress;
  static final List<_ConfettiParticle> _particles = _generateParticles();

  _ConfettiPainter(this.progress);

  static List<_ConfettiParticle> _generateParticles() {
    final random = Random(7);
    const colors = [
      AppColor.greenColor,
      AppColor.freshGreenColor,
      AppColor.darkGreenColor,
      AppColor.warningColor,
      AppColor.infoColor,
      Color(0xFF7C6FA8),
    ];
    return List.generate(36, (i) {
      return _ConfettiParticle(
        startX: random.nextDouble(),
        delay: random.nextDouble() * 0.35,
        speed: 0.7 + random.nextDouble() * 0.5,
        drift: (random.nextDouble() - 0.5) * 0.4,
        size: 5 + random.nextDouble() * 5,
        rotationSpeed: (random.nextDouble() - 0.5) * 10,
        color: colors[i % colors.length],
        isCircle: i.isEven,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final localT = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (localT <= 0) continue;

      final fallY = -20 + localT * p.speed * (size.height + 40);
      if (fallY > size.height) continue;

      final x = (p.startX * size.width) + (p.drift * size.height * localT);
      final opacity = localT > 0.75 ? (1 - (localT - 0.75) / 0.25) : 1.0;

      final paint = Paint()..color = p.color.withOpacity(opacity.clamp(0, 1));

      canvas.save();
      canvas.translate(x, fallY);
      canvas.rotate(localT * p.rotationSpeed);
      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _StatChip({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColor.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColor.textSecondary,
          ),
        ),
      ],
    );
  }
}
