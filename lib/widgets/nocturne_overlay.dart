import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/controllers/theme_controller.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/strings.dart';

/// Temporary "Entering Nocturne" state (not a screen). Never blocks input.
/// Sequence: dark fade -> Nox + halo -> stars -> message -> reveal.
/// Reduced motion / leaving night: a short plain crossfade.
class NocturneOverlay extends StatelessWidget {
  const NocturneOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<NocturneController>();
    return Obx(() {
      final t = c.transition.value;
      if (t == 0) return const SizedBox.shrink();
      return IgnorePointer(
        child: _Run(
          key: ValueKey(t),
          entering: t == 1,
          full: t == 1 && !MediaQuery.disableAnimationsOf(context),
          c: c,
        ),
      );
    });
  }
}

class _Run extends StatefulWidget {
  final bool entering, full;
  final NocturneController c;
  const _Run({super.key, required this.entering, required this.full, required this.c});

  @override
  State<_Run> createState() => _RunState();
}

class _RunState extends State<_Run> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.full ? 1900 : 420),
  );
  bool _applied = false;

  double _iv(double a, double b) =>
      Curves.easeInOutCubic.transform(((_a.value - a) / (b - a)).clamp(0.0, 1.0));

  @override
  void initState() {
    super.initState();
    _a.addListener(() {
      // Switch palette once fully covered (or at the midpoint of a fade).
      if (!_applied && _a.value >= (widget.full ? 0.2 : 0.5)) {
        _applied = true;
        widget.c.apply(widget.entering);
      }
    });
  }

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _begin();
  }

  /// Decode the artwork first so the cat and logo never pop in half-drawn
  /// (capped at 450 ms so the 2.6 s failsafe can never be hit).
  Future<void> _begin() async {
    if (widget.full) {
      try {
        await Future.wait([
          precacheImage(
              const AssetImage(
                  'lib/assests/nocturne/mascot/mozaik-cat-orbiting.png'),
              context),
          precacheImage(
              const AssetImage('lib/assests/brand/mozaik_wordmark.png'),
              context),
        ]).timeout(const Duration(milliseconds: 450));
      } catch (_) {}
    }
    if (!mounted) return;
    _a.forward().whenComplete(() {
      if (!_applied) widget.c.apply(widget.entering);
      widget.c.done();
    });
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) {
        final v = _a.value;
        // cover: in, hold, out
        final cover = widget.full
            ? (_iv(0, .2) * (1 - _iv(.82, 1))).clamp(0.0, 1.0)
            : (1 - (v - .5).abs() * 2).clamp(0.0, 1.0);
        final bg = widget.entering ? const Color(0xFF070811) : const Color(0xFFF2F4E7);
        return Stack(fit: StackFit.expand, children: [
          ColoredBox(color: bg.withOpacity(cover)),
          if (widget.full) ..._scene(context, v),
        ]);
      },
    );
  }

  List<Widget> _scene(BuildContext context, double v) {
    final nox = _iv(.22, .5) * (1 - _iv(.84, 1));
    final stars = _iv(.4, .6) * (1 - _iv(.84, 1));
    final msg1 = _iv(.55, .7) * (1 - _iv(.72, .8));
    final msg2 = _iv(.72, .84) * (1 - _iv(.88, 1));
    final size = MediaQuery.sizeOf(context);
    final s = size.shortestSide * .46;
    return [
      Center(
        child: Transform.translate(
          offset: Offset(0, -size.height * .06),
          child: Opacity(
            opacity: nox,
            child: Transform.scale(
              scale: .9 + .1 * nox + .06 * _iv(.5, .85),
              child: SizedBox(
                width: s * 1.5,
                height: s * 1.5,
                child: Stack(alignment: Alignment.center, children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        const Color(0xFF7358FF).withOpacity(.34),
                        const Color(0xFF54E7FF).withOpacity(.08),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                  Opacity(
                    opacity: (stars * (.75 + .25 * math.sin(v * math.pi * 8))).clamp(0.0, 1.0),
                    child: CustomPaint(size: Size.square(s * 1.5), painter: _Stars()),
                  ),
                  Align(
                    alignment: const Alignment(0, .86),
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                          Color(0xFFF4F2FF), BlendMode.srcIn),
                      child: Image.asset(
                          'lib/assests/brand/mozaik_wordmark.png',
                          width: s * .85,
                          filterQuality: FilterQuality.medium),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, math.sin(v * math.pi * 3) * s * .035),
                    child: Transform.rotate(
                      angle: math.sin(v * math.pi * 2) * .035,
                      child: Image.asset(
                          'lib/assests/nocturne/mascot/mozaik-cat-orbiting.png',
                          width: s,
                          filterQuality: FilterQuality.medium),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        left: 24,
        right: 24,
        top: size.height * .5 + s * .78,
        child: Stack(alignment: Alignment.topCenter, children: [
          Opacity(opacity: msg1, child: _txt(AppStrings.enteringNocturne, 22, FontWeight.w700, const Color(0xFFF4F2FF))),
          Opacity(opacity: msg2, child: _txt(AppStrings.studyAfterDark, 17, FontWeight.w500, const Color(0xFFB9B6D5))),
        ]),
      ),
    ];
  }

  Widget _txt(String s, double sz, FontWeight w, Color c) => Text(s,
      textAlign: TextAlign.center,
      style: TextStyle(
          fontSize: sz, fontWeight: w, color: c, decoration: TextDecoration.none));
}

class _Stars extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(11);
    final p = Paint();
    for (var i = 0; i < 9; i++) {
      final a = r.nextDouble() * math.pi * 2;
      final d = size.width * (.3 + r.nextDouble() * .2);
      final o = size.center(Offset.zero) + Offset(math.cos(a), math.sin(a)) * d;
      p.color = (i.isEven ? const Color(0xFF54E7FF) : const Color(0xFFA98CFF))
          .withOpacity(.55 + r.nextDouble() * .35);
      canvas.drawCircle(o, 1.2 + r.nextDouble() * 1.4, p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
