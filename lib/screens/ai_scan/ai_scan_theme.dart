import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Palette from the approved design pack.
class AiC {
  static const ivory = Color(0xFFF8F6E9);
  static const forest = Color(0xFF174F41);
  static const primary = Color(0xFF286A54);
  static const sage = Color(0xFF638A76);
  static const paleSage = Color(0xFFDDE7D4);
  static const gold = Color(0xFFC5A34A);
  static const card = Color(0xFFFCFBF3);
  static const line = Color(0xFFE3E6D6);
}

Widget aiSvg(String name, {double? w, double? h, BoxFit fit = BoxFit.contain}) =>
    SvgPicture.asset('lib/assests/ai_scan/$name', width: w, height: h, fit: fit);

bool aiRtl(BuildContext c) => Directionality.of(c) == TextDirection.rtl;

const aiTitle = TextStyle(fontFamily: 'ELMESSIRI', fontSize: 24, fontWeight: FontWeight.w700, color: AiC.forest, height: 1.3);
const aiBody = TextStyle(fontFamily: 'ELMESSIRI', fontSize: 13, color: AiC.sage, height: 1.6);
const aiCardTitle = TextStyle(fontFamily: 'ELMESSIRI', fontSize: 16, fontWeight: FontWeight.w700, color: AiC.forest);

/// Soft ivory page with the pale geometric mountains at the bottom (windows 2-6).
class AiPage extends StatelessWidget {
  final Widget child;
  final bool mountains;
  const AiPage({super.key, required this.child, this.mountains = true});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AiC.ivory,
        body: Stack(children: [
          if (mountains) Positioned(left: 0, right: 0, bottom: 0, child: Opacity(opacity: .5, child: aiSvg('w78_mountain-landscape.svg', fit: BoxFit.fitWidth))),
          SafeArea(child: child),
        ]),
      );
}

class AiButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool light;
  const AiButton(this.text, {super.key, this.onTap, this.light = false});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: light ? AiC.ivory : AiC.forest,
            foregroundColor: light ? AiC.forest : Colors.white,
            disabledBackgroundColor: AiC.paleSage,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            textStyle: const TextStyle(fontFamily: 'ELMESSIRI', fontSize: 16, fontWeight: FontWeight.w700),
          ),
          child: Text(text),
        ),
      );
}

/// Back arrow on the left edge (as in the design), centered title.
class AiTopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  const AiTopBar(this.title, {super.key, this.onBack});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: SizedBox(
          height: 44,
          child: Stack(alignment: Alignment.center, children: [
            Text(title, style: const TextStyle(fontFamily: 'ELMESSIRI', fontSize: 15, fontWeight: FontWeight.w600, color: AiC.forest)),
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(onTap: onBack ?? () => Navigator.of(context).maybePop(), child: aiSvg('w02_back_button.svg', w: 24, h: 24)),
            ),
          ]),
        ),
      );
}
