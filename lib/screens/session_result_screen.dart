import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/entity/card_entity.dart';
import 'package:upgrade/main.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/widgets/tablet_bounded.dart';
import 'package:upgrade/controllers/mosaic_controller.dart';
import 'package:upgrade/controllers/session_rewards.dart';
import 'package:upgrade/controllers/years_controller.dart';
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
    // After the first frame: the route (and its arguments) is fully attached,
    // which is not guaranteed while initState is still running.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _runRewardSequence();
    });
  }

  /// 1) mosaic ceremony (unchanged: same queue, same batch removal), THEN
  /// 2) the standalone streak window, only if this session saved the streak.
  Future<void> _runRewardSequence() async {
    try {
      await _runRewardSequenceInner();
    } catch (_) {
      // Rewards are secondary: never let them break the result screen.
    }
  }

  Future<void> _runRewardSequenceInner() async {
    final args = ModalRoute.of(context)?.settings.arguments ?? Get.arguments;
    final SessionRewards? rewards =
        (args is Map && args['rewards'] is SessionRewards)
            ? args['rewards'] as SessionRewards
            : null;
    final int correct = (args is Map ? args['correct'] : null) ?? 0;
    final int wrong = (args is Map ? args['wrong'] : null) ?? 0;

    // The window is already on screen and its numbers are counting up; that
    // time is used to let the last answer settle and the server catch up, so a
    // slow server can never lose the streak or the mosaic pieces.
    final countUp = Future.delayed(_countUpDuration + const Duration(milliseconds: 300));
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
    // Re-read the mosaic from the server (one request): any piece the server
    // granted that the answer response did not carry (slow/failed response)
    // is recovered and queued HERE, instead of waiting for an app restart.
    try {
      await mosaic.refresh(sync: true).timeout(const Duration(seconds: 15));
    } catch (_) {}
    final streak = await _streakToShow(rewards, correct + wrong);
    await countUp; // never open a reward window over a half-counted result
    if (!mounted) return;
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

  /// The streak window is a once-per-day moment. The server only *reports* the
  /// streak on the first answer of the day, so relying on that alone loses the
  /// window whenever that answer came from an earlier/aborted session. Instead:
  /// show it at most once per UTC day, after a session that reached the server,
  /// using the reported streak or, failing that, the current streak (profile).
  Future<int?> _streakToShow(SessionRewards? rewards, int cardsAnswered) async {
    final answered = rewards?.answered ?? cardsAnswered > 0;
    if (!answered) return null;
    final todayKey = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    if (sharedPref.getString(_streakShownKey) == todayKey) return null;

    // The server is the source of truth, and it can lag a moment behind the
    // last answer: read the profile fresh (one retry), fall back to the value
    // the answer response reported.
    int? streak;
    for (var attempt = 0; attempt < 2 && (streak == null || streak <= 0); attempt++) {
      if (attempt > 0) await Future.delayed(const Duration(milliseconds: 1500));
      try {
        final years = Get.find<YearsController>();
        final before = years.profile.value;
        await years.getMyProfile().timeout(const Duration(seconds: 10));
        if (years.profile.value == null) years.profile.value = before;
        streak = years.profile.value?.currentStreak;
      } catch (_) {}
    }
    if (streak == null || streak <= 0) streak = rewards?.streak;
    if (streak == null || streak <= 0) return null;
    await sharedPref.setString(_streakShownKey, todayKey);
    return streak;
  }

  static const String _streakShownKey = 'streak_window_shown_date';
  static const Duration _countUpDuration = Duration(milliseconds: 2200);

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
                                duration: _countUpDuration,
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
                              value: correct,
                              label: "صحيح",
                            ),
                            _StatChip(
                              icon: Icons.close_rounded,
                              color: AppColor.errorColor,
                              value: wrong,
                              label: "خاطئ",
                            ),
                            _StatChip(
                              icon: Icons.schedule_rounded,
                              color: AppColor.infoColor,
                              value: minutes,
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
  final int value;
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
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: value),
          duration: _SessionResultScreenState._countUpDuration,
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => Text(
            '$v',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColor.textPrimary,
            ),
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
