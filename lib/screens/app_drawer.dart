import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:upgrade/resources.dart';

/// Palette from the approved design pack, with its night (Nocturne) twin.
/// Getters, not constants: they follow [AppColor.night] so the AI screens flip with the rest of the app.
class AiC {
  static Color _p(int light, int dark) => Color(AppColor.night ? dark : light);
  static Color get ivory => _p(0xFFF8F6E9, 0xFF070811); // page background
  static Color get forest => _p(0xFF174F41, 0xFFF4F2FF); // headings / strong text / icons
  static Color get primary => _p(0xFF286A54, 0xFF7358FF);
  static Color get sage => _p(0xFF638A76, 0xFFB9B6D5); // secondary text
  static Color get paleSage => _p(0xFFDDE7D4, 0xFF211A4D);
  static Color get gold => _p(0xFFC5A34A, 0xFFFFD56A);
  static Color get card => _p(0xFFFCFBF3, 0xFF11152A);
  static Color get line => _p(0xFFE3E6D6, 0xFF252A58);
  static Color get accent => _p(0xFF174F41, 0xFF7358FF); // filled buttons / selected pills
  static Color get deep => _p(0xFF174F41, 0xFF0D1020); // dark surfaces (window 10, scrims)
  static Color get shadow => _p(0xFF174F41, 0xFF000000).withOpacity(AppColor.night ? .35 : .08);
}

// single-colour icons that must follow the text colour in night mode
const _tintable = {
  'w02_back_button.svg', 'w02_chevron_right.svg', 'w02_info_circle.svg', 'w02_camera_outline.svg',
  'w02_photo_gallery.svg', 'w03_gallery_upload_arrow.svg', 'w78_close.svg',
};

Widget aiSvg(String name, {double? w, double? h, BoxFit fit = BoxFit.contain}) {
  final svg = SvgPicture.asset('lib/assests/ai_scan/$name', width: w, height: h, fit: fit);
  if (AppColor.night && _tintable.contains(name)) {
    return ColorFiltered(colorFilter: const ColorFilter.mode(Color(0xFFF4F2FF), BlendMode.srcIn), child: svg);
  }
  return svg;
}

bool aiRtl(BuildContext c) => Directionality.of(c) == TextDirection.rtl;

TextStyle get aiTitle => TextStyle(fontFamily: 'ELMESSIRI', fontSize: 24, fontWeight: FontWeight.w700, color: AiC.forest, height: 1.3);
TextStyle get aiBody => TextStyle(fontFamily: 'ELMESSIRI', fontSize: 13, color: AiC.sage, height: 1.6);
TextStyle get aiCardTitle => TextStyle(fontFamily: 'ELMESSIRI', fontSize: 16, fontWeight: FontWeight.w700, color: AiC.forest);

/// Soft ivory page with the pale geometric mountains at the bottom (windows 2-6).
class AiPage extends StatelessWidget {
  final Widget child;
  final bool mountains;
  const AiPage({super.key, required this.child, this.mountains = true});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AiC.ivory,
        body: Stack(children: [
          if (mountains && !AppColor.night) Positioned(left: 0, right: 0, bottom: 0, child: Opacity(opacity: .5, child: aiSvg('w78_mountain-landscape.svg', fit: BoxFit.fitWidth))),
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
            backgroundColor: light ? AiC.ivory : AiC.accent,
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
            Text(title, style: TextStyle(fontFamily: 'ELMESSIRI', fontSize: 15, fontWeight: FontWeight.w600, color: AiC.forest)),
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(onTap: onBack ?? () => Navigator.of(context).maybePop(), child: aiSvg('w02_back_button.svg', w: 24, h: 24)),
            ),
          ]),
        ),
      );
}
