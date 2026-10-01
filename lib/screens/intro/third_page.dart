import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/screens/intro/onboarding_widgets.dart';

class ThirdPage extends StatelessWidget {
  const ThirdPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const SizedBox(height: 56),
            const ObTitle("في يوم ما،\nستكتمل الصورة."),
            const SizedBox(height: 14),
            const ObBody("كل بطاقة هي قطعة.\nوكل مراجعة تزيد قطعة أخرى."),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: 330,
                    height: 310,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 0,
                          top: 50,
                          width: 330,
                          height: 220,
                          child: Image.asset(
                              "lib/assests/onboarding/orbit.png",
                              fit: BoxFit.contain),
                        ),
                        // Soft ground shadow under the emblem.
                        Positioned(
                          left: 105,
                          top: 238,
                          width: 120,
                          height: 14,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(60),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColor.forestGreenColor
                                      .withOpacity(0.22),
                                  blurRadius: 14,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 75,
                          top: 70,
                          width: 180,
                          height: 162,
                          child: Image.asset(
                              "lib/assests/brand/mozaik_emblem.png",
                              fit: BoxFit.contain),
                        ),
                        Positioned(
                          right: -6,
                          top: 22,
                          width: 56,
                          child: Transform.rotate(
                            angle: -0.35,
                            child: Image.asset(
                                "lib/assests/onboarding/leaf.png",
                                fit: BoxFit.contain),
                          ),
                        ),
                        Positioned(
                          right: 14,
                          top: 252,
                          width: 30,
                          child: Transform.rotate(
                            angle: math.pi / 3,
                            child: Image.asset(
                                "lib/assests/onboarding/leaf.png",
                                fit: BoxFit.contain),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 130),
          ],
        ),
      ),
    );
  }
}
