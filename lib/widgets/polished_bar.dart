import 'package:flutter/material.dart';

/// Thin progress bar with fully rounded ends, a clear track and a soft highlight
/// on the filled part. Same value/colour contract as a LinearProgressIndicator.
class PolishedBar extends StatelessWidget {
  final double value;
  final Color color;
  final Color track;
  final double height;
  const PolishedBar({super.key, required this.value, required this.color, required this.track, this.height = 8});

  @override
  Widget build(BuildContext context) {
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0).toDouble();
    final r = BorderRadius.circular(height);
    return ClipRRect(
      borderRadius: r,
      child: Container(
        height: height,
        color: track,
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: v,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: r,
              gradient: LinearGradient(colors: [color, Color.lerp(color, Colors.white, .22)!]),
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: height * .28,
                margin: EdgeInsets.symmetric(horizontal: height * .5, vertical: height * .14),
                decoration: BoxDecoration(color: Colors.white.withOpacity(.28), borderRadius: BorderRadius.circular(height)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
