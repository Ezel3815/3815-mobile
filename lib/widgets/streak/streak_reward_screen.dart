import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/widgets/streak/streak_week.dart';

const Color _gold = Color(0xFFF5B92E);
const Color _goldDeep = Color(0xFFE39A12);
const Color _muted = Color(0xFFC3CBBF);

const String _flameAsset = 'lib/assests/streak/streak_flame.svg';
const String _haloAsset = 'lib/assests/streak/streak_halo.svg';
const String _coinAsset = 'lib/assests/streak/streak_coin.svg';
const String _coinFaceAsset = 'lib/assests/streak/streak_coin_face.svg';

/// Standalone Streak Reward window. Completely separate from the mosaic
/// reward ceremony: it takes only the authoritative streak number, reads no
/// mosaic state and touches no reward queue.
class StreakRewardScreen extends StatefulWidget {
  final int streak;

  /// Injectable clock (UTC) so tests are deterministic.
  final DateTime? nowUtc;

  const StreakRewardScreen({super.key, required this.streak, this.nowUtc});

  static Future<void> show(BuildContext context, {required int streak}) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => StreakRewardScreen(streak: streak),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  State<StreakRewardScreen> createState() => _StreakRewardScreenState();
}

class _StreakRewardScreenState extends State<StreakRewardScreen>
    with TickerProviderStateMixin {
  // One master timeline drives every phase; a second loop drives idle motion.
  late final AnimationController _master;
  late final AnimationController _idle;
  bool _motionChecked = false;

  late final List<bool> _done;
  late final int _todayIndex;

  @override
  void initState() {
    super.initState();
    final now = (widget.nowUtc ?? DateTime.now()).toUtc();
    _done = completedWeekDays(streak: widget.streak, nowUtc: now);
    _todayIndex = todayWeekIndex(now);
    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4600),
    )..forward();
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionChecked) return;
    _motionChecked = true;
    if (MediaQuery.of(context).disableAnimations) {
      _master.value = 1;
      _idle.stop();
    }
  }

  @override
  void dispose() {
    _master.dispose();
    _idle.dispose();
    super.dispose();
  }

  /// Normalised progress of [_master] between [a] and [b] (fractions 0..1).
  double _seg(double a, double b, [Curve curve = Curves.linear]) {
    final t = ((_master.value - a) / (b - a)).clamp(0.0, 1.0).toDouble();
    return curve.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.streak;
    final size = MediaQuery.of(context).size;
    final flameSize = math.min(size.height * 0.2, 176.0);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColor.scaffoldBackgroundColor,
        body: AnimatedBuilder(
          animation: Listenable.merge([_master, _idle]),
          builder: (context, _) {
            final ctaT = _seg(0.85, 1.0, Curves.easeOut);
            return Stack(
              children: [
                // Soft warm glow + leaves, painted (no full-screen image).
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _BackdropPainter()),
                  ),
                ),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, c) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: c.maxHeight),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 440),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 12),
                                  _buildFlame(flameSize),
                                  const SizedBox(height: 8),
                                  _buildTitle(n),
                                  const SizedBox(height: 14),
                                  _buildNumber(n),
                                  const SizedBox(height: 22),
                                  _buildWeek(),
                                  const SizedBox(height: 22),
                                  _buildCoinCard(n),
                                  const SizedBox(height: 22),
                                  _buildCta(ctaT),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- flame
  Widget _buildFlame(double s) {
    // Phase 1: scale up + fade in while spinning around the vertical axis.
    final enter = _seg(0.0, 0.12, Curves.easeOutBack);
    final fade = _seg(0.0, 0.12, Curves.easeOut);
    final scale = 0.7 + 0.3 * enter;
    final opacity = 0.35 + 0.65 * fade;

    // Phase 2: the spin decelerates (1.5 turns -> 0) and lands with a small,
    // restrained bounce.
    final spin = _seg(0.0, 0.30, Curves.easeOutCubic);
    final angle = (1 - spin) * 3 * math.pi;
    final landB = _seg(0.30, 0.40);
    final landDy = -5 * math.sin(math.pi * landB);

    // Phase 3: calm idle float + glow pulse, eased in once landed.
    final idleAmt = _seg(0.38, 0.5);
    final wave = math.sin(_idle.value * 2 * math.pi);
    final idleDy = wave * 4 * idleAmt;
    final pulse = 0.85 + 0.15 * (0.5 + 0.5 * wave);

    final box = s * 1.7;
    return SizedBox(
      width: box,
      height: s * 1.35,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Opacity(
            opacity: (0.9 * _seg(0.0, 0.2, Curves.easeOut) * pulse).clamp(0.0, 1.0).toDouble(),
            child: Transform.scale(
              scale: 1.0 + 0.04 * wave * idleAmt,
              child: SvgPicture.asset(_haloAsset, width: box, height: box),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SparklePainter(
                  t: _idle.value,
                  visibility: _seg(0.05, 0.2) * (_master.value > 0.6 ? 0.55 : 1.0),
                ),
              ),
            ),
          ),
          Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, landDy + idleDy),
              child: Transform.scale(
                scale: scale,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: 0.55 * fade,
                      child: CustomPaint(
                        size: Size(s * 1.25, s * 0.3),
                        painter: _OrbitPainter(),
                      ),
                    ),
                    Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0012)
                        ..rotateY(angle),
                      child: SvgPicture.asset(_flameAsset, width: s, height: s),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- texts
  Widget _buildTitle(int n) {
    final t = _seg(0.30, 0.42, Curves.easeOut);
    final fresh = n <= 1;
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, 8 * (1 - t)),
        child: Column(
          children: [
            Text(
              fresh ? 'بداية جديدة!' : 'أنت مشتعل!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColor.darkGreenColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              fresh
                  ? 'كل سلسلة عظيمة تبدأ بيوم واحد'
                  : 'حافظ على سلسلتك، أنت تبلي بلاءً حسنًا!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColor.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Phase 4: the number fades and scales in. Always the real streak value.
  Widget _buildNumber(int n) {
    final t = _seg(0.36, 0.50, Curves.easeOutCubic);
    return Opacity(
      opacity: t,
      child: Transform.scale(
        scale: 0.82 + 0.18 * t,
        child: Column(
          children: [
            Text(
              '$n',
              style: const TextStyle(
                fontSize: 76,
                height: 1.0,
                fontWeight: FontWeight.w800,
                color: AppColor.darkGreenColor,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'يوم متتالٍ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColor.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- week
  Widget _buildWeek() {
    final t = _seg(0.50, 0.62, Curves.easeOut);
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, 12 * (1 - t)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            // Phase 5: completed days pop into gold checks, staggered.
            final start = 0.52 + i * 0.025;
            final pop = _done[i] ? _seg(start, start + 0.08, Curves.easeOutBack) : 0.0;
            final isToday = i == _todayIndex;
            return Column(
              children: [
                Text(
                  weekDayLabelsAr[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                    color: isToday
                        ? AppColor.darkGreenColor
                        : AppColor.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.lerp(_muted, _gold, pop.clamp(0.0, 1.0).toDouble()),
                    border: isToday
                        ? Border.all(color: AppColor.darkGreenColor, width: 2)
                        : null,
                  ),
                  child: _done[i]
                      ? Transform.scale(
                          scale: pop.clamp(0.0, 1.3).toDouble(),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 20,
                            color: AppColor.darkGreenColor,
                          ),
                        )
                      : null,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- coin
  Widget _buildCoinCard(int n) {
    final t = _seg(0.66, 0.78, Curves.easeOut);
    // Phase 6: two vertical-axis flips, then a tiny landing bounce.
    final flip = _seg(0.72, 0.95, Curves.easeInOutCubic);
    final angle = flip * 4 * math.pi;
    final landB = _seg(0.95, 1.0);
    final landScale = 1.0 + 0.08 * math.sin(math.pi * landB);
    final showBack = () {
      final a = angle % (2 * math.pi);
      return a > math.pi / 2 && a < 3 * math.pi / 2;
    }();

    Widget front = SvgPicture.asset(_coinAsset, width: 58, height: 58);
    Widget back = Stack(
      alignment: Alignment.center,
      children: [
        SvgPicture.asset(_coinFaceAsset, width: 58, height: 58),
        // flutter_svg does not render <text>, so the star is a real icon.
        const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Icon(Icons.star_rounded, size: 28, color: Color(0xFFFFF8D4)),
        ),
      ],
    );

    final coin = Transform.scale(
      scale: landScale,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.002)
          ..rotateY(angle),
        child: showBack
            ? Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(math.pi),
                child: back,
              )
            : front,
      ),
    );

    final fresh = n <= 1;
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, 12 * (1 - t)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColor.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(width: 64, height: 64, child: Center(child: coin)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fresh ? 'أول يوم في سلسلتك' : 'سلسلة مثالية!',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColor.darkGreenColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      fresh
                          ? 'عد غدًا لتواصل السلسلة.'
                          : 'حافظت على سلسلتك ${arabicDays(n)}. عمل رائع!',
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: AppColor.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- CTA
  Widget _buildCta(double t) {
    return IgnorePointer(
      ignoring: t < 0.99,
      child: Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - t)),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.forestGreenColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'يمكنني فعلها!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ painters

/// Soft warm glow at the top + two quiet leaf clusters at the bottom corners.
class _BackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [_gold.withOpacity(0.16), _gold.withOpacity(0)],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, size.height * 0.18),
        radius: size.width * 0.75,
      ));
    canvas.drawRect(Offset.zero & size, glow);

    final leaf = Paint()..color = AppColor.greenColor.withOpacity(0.16);
    void cluster(Offset base, double dir) {
      for (var i = 0; i < 5; i++) {
        canvas.save();
        canvas.translate(base.dx, base.dy);
        canvas.rotate(dir * (-0.35 - i * 0.28));
        final p = Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(22, -38, 0, -84 - i * 6)
          ..quadraticBezierTo(-22, -38, 0, 0);
        canvas.drawPath(p, leaf);
        canvas.restore();
      }
    }

    cluster(Offset(0, size.height), 1);
    cluster(Offset(size.width, size.height), -1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// A few slow, twinkling 4-point gold sparkles around the flame.
class _SparklePainter extends CustomPainter {
  final double t;
  final double visibility;
  _SparklePainter({required this.t, required this.visibility});

  static final List<_Spark> _sparks = () {
    final r = math.Random(7);
    return List.generate(
      12,
      (_) => _Spark(
        dx: r.nextDouble() * 2 - 1,
        dy: r.nextDouble() * 1.6 - 1.0,
        phase: r.nextDouble(),
        size: 3 + r.nextDouble() * 4,
      ),
    );
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _gold;
    for (final s in _sparks) {
      final p = (t + s.phase) % 1.0;
      final a = math.sin(math.pi * p) * visibility;
      if (a <= 0.02) continue;
      paint.color = _goldDeep.withOpacity((a * 0.85).clamp(0.0, 1.0).toDouble());
      final c = Offset(
        size.width / 2 + s.dx * size.width * 0.42,
        size.height / 2 + s.dy * size.height * 0.42 - 14 * p,
      );
      final r = s.size * (0.6 + 0.4 * a);
      final path = Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) =>
      old.t != t || old.visibility != visibility;
}

class _Spark {
  final double dx, dy, phase, size;
  const _Spark(
      {required this.dx,
      required this.dy,
      required this.phase,
      required this.size});
}

/// Thin tilted golden ring orbiting the flame (matches the reference).
class _OrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..shader = SweepGradient(
        colors: [
          _gold.withOpacity(0),
          _gold,
          const Color(0xFFFFF3A8),
          _gold.withOpacity(0),
        ],
        stops: const [0.0, 0.35, 0.6, 1.0],
      ).createShader(rect);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-0.21);
    canvas.translate(-size.width / 2, -size.height / 2);
    canvas.drawOval(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
