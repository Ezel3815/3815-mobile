import 'dart:ui';
import 'package:flutter/painting.dart';

/// App palette. Values are theme-aware getters: [night] flips the whole
/// palette to MOZAIK // NOCTURNE (see NocturneController). Names are kept
/// so existing screens need no per-widget changes.
class AppColor {
  static bool night = false;
  static Color _p(int light, int dark) => Color(night ? dark : light);
  static Color pick(int light, int dark) => _p(light, dark);
  /// Hairline/shadow tint that stays visible in both modes (black in light, white in night).
  static Color edge(double opacity) => Color(night ? 0xFFFFFFFF : 0xFF000000).withOpacity(opacity);
  static Color get ink => _p(0xFF000000, 0xFFF4F2FF); // was Colors.black text
  static Color get card => _p(0xFFFFFFFF, 0xFF11152A); // was Colors.white fill
  static Color get line => _p(0xFFFFFFFF, 0xFF252A58); // was white border

  // Backgrounds
  static Color get scaffoldBackgroundColor => _p(0xFFF2F4E7, 0xFF070811);
  static Color get surfaceColor => _p(0xFFFAFBF6, 0xFF11152A);
  static Color get elevatedColor => _p(0xFFF2F4E7, 0xFF0D1020);
  static Color get surface2Color => _p(0xFFFAFBF6, 0xFF171B35);
  static Color get borderColor => _p(0xFFDDE4CC, 0xFF252A58);

  // Brand (green in light, violet in Nocturne)
  static Color get greenColor => _p(0xFF4F9B69, 0xFF7358FF);
  static Color get darkGreenColor => _p(0xFF174A40, 0xFF8B6CFF);
  static Color get forestGreenColor => _p(0xFF2A4E42, 0xFF171B35);
  static Color get freshGreenColor => _p(0xFF6DBA78, 0xFF6FE7C8);
  static Color get lightGreenColor => _p(0xFFDDF1D8, 0xFF211A4D);
  static Color get disabledColor => _p(0xFF8A968F, 0xFF777594);

  // Text
  static Color get textPrimary => _p(0xFF1D2924, 0xFFF4F2FF);
  static Color get textSecondary => _p(0xFF49665D, 0xFFB9B6D5);

  // Utility / status
  static Color get warningColor => _p(0xFFD69E45, 0xFFFFD56A);
  static Color get errorColor => _p(0xFFC95C5C, 0xFFFF7A8A);
  static Color get infoColor => _p(0xFF5D8FA3, 0xFF4E9CFF);
  static Color get accentColor => _p(0xFF5D8FA3, 0xFF54E7FF); // cyan

  // Legacy aliases
  static Color get lightRedColor => _p(0xFFF7DCD0, 0xFF3A1B2A);
  static Color get greyColor => _p(0xFFCFCFCF, 0xFF252A58);

  // Nocturne neon glow (matches the design board): violet outline + soft halo.
  static Color get glowBorder => _p(0xFFDDE4CC, 0xFF252A58);
  static List<BoxShadow> get glowShadow => night
      ? const [BoxShadow(color: Color(0x147358FF), blurRadius: 12, offset: Offset(0, 4))]
      : const [BoxShadow(color: Color(0x14243D2E), blurRadius: 22, offset: Offset(0, 8))];

  // Nocturne gradient (primary CTA)
  static const List<Color> nocturneGradient = [
    Color(0xFF7358FF),
    Color(0xFFA56BFF),
    Color(0xFF54E7FF),
  ];
}
