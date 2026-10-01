import 'package:flutter/material.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/screens/intro/onboarding_widgets.dart';

class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  static const _timeline = [
    ("اليوم", 1.0),
    ("بعد 4 أيام", 0.6),
    ("بعد أسبوعين", 0.28),
  ];

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final chevron = Icon(
      rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
      size: 20,
      color: AppColor.textSecondary.withOpacity(0.45),
    );
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const SizedBox(height: 48),
            const ObTitle("ما الذي يُسبب\nفرط نشاط الغدة الدرقية؟", size: 25),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Image.asset(
                    "lib/assests/onboarding/flashcard_stack.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _timeline.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: chevron,
                    ),
                  Column(
                    children: [
                      Opacity(
                        opacity: _timeline[i].$2,
                        child: Image.asset(
                          "lib/assests/brand/mozaik_emblem.png",
                          height: 40,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _timeline[i].$1,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColor.textSecondary.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 22),
            const ObTitle("بطاقاتك تتذكّرك معك.", size: 22),
            const SizedBox(height: 10),
            const ObBody(
                "يُعيد MOZAIK عرض القطع المناسبة\nفي الوقت المناسب، عندما تكون أكثر\nاحتمالاً للنسيان."),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}
