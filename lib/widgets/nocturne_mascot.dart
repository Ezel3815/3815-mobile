import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:upgrade/resources.dart';

/// Night-mode mascot (approved Mozaik cat). Renders nothing in light mode.
/// Poses: orbiting, studying, star-hug, jumping, sleeping.
/// Gentle float + soft halo; static when the OS asks for reduced motion.
///
/// [height] is the height of the cat itself. Every pose keeps its true
/// proportions, and the widget adds its own breathing room around the cat
/// (about 14% of [height] on every side) so the halo and the float never
/// touch or clip against neighbouring widgets.
class NocturneMascot extends StatefulWidget {
  final String pose;
  final double height;
  const NocturneMascot({super.key, this.pose = 'orbiting', this.height = 84});

  /// width / height of each pose's artwork.
  static const Map<String, double> _aspect = {
    'orbiting': 390 / 346,
    'studying': 447 / 308,
    'star-hug': 314 / 404,
    'jumping': 356 / 410,
    'sleeping': 350 / 288,
  };

  static double aspectOf(String pose) => _aspect[pose] ?? 1.0;

  @override
  State<NocturneMascot> createState() => _NocturneMascotState();
}

class _NocturneMascotState extends State<NocturneMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
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
    final w = h * NocturneMascot.aspectOf(widget.pose);
    final pad = h * .14; // room for the halo and the float
    final halo = math.max(w, h) * 1.02;
    return SizedBox(
      width: w + pad * 2,
      height: h + pad * 2,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final dy = still ? 0.0 : math.sin(_c.value * 2 * math.pi) * h * .04;
          return Transform.translate(offset: Offset(0, dy), child: child);
        },
        child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
          Container(
            width: halo,
            height: halo,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF7358FF).withOpacity(.22),
                Colors.transparent,
              ]),
            ),
          ),
          SizedBox(
            width: w,
            height: h,
            child: Image.asset(
              'lib/assests/nocturne/mascot/mozaik-cat-${widget.pose}.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ]),
      ),
    );
  }
}
