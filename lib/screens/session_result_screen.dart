import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/entity/card_entity.dart';
import 'package:upgrade/main.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/widgets/tablet_bounded.dart';
import 'package:upgrade/controllers/mosaic_controller.dart';
import 'package:upgrade/widgets/mosaic/reward_flow_models.dart';
import 'package:upgrade/widgets/mosaic/reward_flow_screen.dart';

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

    // The daily piece(s) earned by THIS session may still be in flight from
    // the server (the last card's answer resolves after this screen has
    // already opened — see card_view_controller.dart). Poll briefly rather
    // than fire once, so the reward ceremony still appears even when it
    // lands a beat late; it's a no-op once the batch has already shown.
    _watchForDailyReward();
  }

  void _watchForDailyReward() {
    var attempts = 0;
    void tick() {
      if (!mounted) return;
      final mosaic = Get.isRegistered<MosaicController>()
          ? Get.find<MosaicController>()
          : Get.put(MosaicController());
      final index = mosaic.rewardQueue.indexWhere((b) => b.source == RewardSource.daily);
      if (index != -1) {
        final batch = mosaic.rewardQueue.removeAt(index);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RewardFlowScreen.daily(batch: batch)),
        );
        return;
      }
      attempts += 1;
      if (attempts < 20) Future.delayed(const Duration(milliseconds: 300), tick);
    }

    Future.delayed(const Duration(milliseconds: 900), tick);
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
