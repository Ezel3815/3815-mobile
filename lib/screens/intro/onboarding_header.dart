import 'package:flutter/material.dart';
import 'package:upgrade/resources.dart';

class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // New Mozaik hexagon identity (raster brand assets; aspect ratio kept).
        Image.asset(
          'lib/assests/brand/mozaik_hexagon.png',
          height: 76,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 10),
        Image.asset(
          'lib/assests/brand/mozaik_wordmark.png',
          height: 22,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 8),
        Text(
          "قطعة تلو الأخرى، تتكامل الصورة.",
          style: TextStyle(
            fontSize: 12,
            color: AppColor.textSecondary.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}
