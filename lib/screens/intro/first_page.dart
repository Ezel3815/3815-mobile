import 'package:flutter/material.dart';
import 'package:upgrade/screens/intro/onboarding_widgets.dart';

class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const SizedBox(height: 56),
            const ObTitle("تعلّم قطعة،\nوابنِ الصورة."),
            const SizedBox(height: 14),
            const ObBody("حوّل المعلومات المتفرقة إلى\nمعرفة راسخة."),
            Expanded(
              child: Center(
                child: Image.asset(
                  'lib/assests/onboarding/piece_assembly.png',
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
