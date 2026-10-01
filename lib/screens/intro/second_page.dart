import 'package:flutter/material.dart';
import 'package:upgrade/screens/intro/onboarding_widgets.dart';

class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  Widget _piece(String n, double left, double top, double size) => Positioned(
        left: left,
        top: top,
        width: size,
        height: size,
        child: Image.asset('lib/assests/onboarding/piece_$n.png',
            fit: BoxFit.contain),
      );

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
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: 330,
                    height: 240,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _piece('01', 0, 0, 112),
                        _piece('02', 118, -4, 112),
                        _piece('03', 0, 112, 112),
                        const Positioned(
                            left: 124,
                            top: 118,
                            width: 94,
                            height: 94,
                            child: DashedSlot()),
                        _piece('04', 216, 112, 108),
                        const Positioned.fill(child: CurvedArrow()),
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
