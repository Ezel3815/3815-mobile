import 'package:flutter/material.dart';
import 'package:upgrade/screens/intro/onboarding_widgets.dart';

class ThirdPage extends StatelessWidget {
  const ThirdPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 56),
            const ObTitle("في يوم ما،\nستكتمل الصورة."),
            const SizedBox(height: 14),
            const ObBody("كل بطاقة هي قطعة.\nوكل مراجعة تزيد قطعة أخرى."),
            Expanded(
              child: Center(
                child: Image.asset(
                  'lib/assests/onboarding/hex_hero.png',
                  fit: BoxFit.contain,
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
