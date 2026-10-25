import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:upgrade/resources.dart';

/// Night-mode mascot (approved Mozaik cat). Renders nothing in light mode.
/// Poses: orbiting, studying, star-hug, jumping, sleeping.
/// Gentle float + soft halo; static when the OS asks for reduced motion.
class NocturneMascot extends StatefulWidget {
  final String pose;
  final double height;
  const NocturneMascot({super.key, this.pose = 'orbiting', this.height = 84});

  @override
  State<NocturneMascot> createState() => _NocturneMascotState();
}

class _NocturneMascotState extends State<NocturneMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AppColor.night) return const SizedBox.shrink();
    final still = MediaQuery.disableAnimationsOf(context);
    final h = widget.height;
    return SizedBox(
      width: h * 1.15,
      height: h * 1.15,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final dy = still ? 0.0 : math.sin(_c.value * 2 * math.pi) * h * .05;
          return Transform.translate(offset: Offset(0, dy), child: child);
        },
        child: Stack(alignment: Alignment.center, children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF7358FF).withOpacity(.28),
                Colors.transparent,
              ]),
            ),
          ),
          Image.asset(
            'lib/assests/nocturne/mascot/mozaik-cat-${widget.pose}.png',
            height: h,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ]),
      ),
    );
  }
}
