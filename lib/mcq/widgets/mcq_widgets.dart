import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:upgrade/mcq/mcq_strings.dart';
import 'package:upgrade/resources.dart';

/// MCQ-specific colour roles, all derived from the app's own AppColor so the
/// light (cream/green) and Nocturne (navy/violet) themes both stay correct.
class McqTheme {
  McqTheme._();

  static Color get accent => AppColor.greenColor;
  static Color get success => AppColor.freshGreenColor;
  static Color get danger => AppColor.errorColor;
  static Color get warning => AppColor.warningColor;

  static LinearGradient get heroGradient => AppColor.night
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A2E8C), Color(0xFF191848)],
        )
      : LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColor.darkGreenColor, AppColor.greenColor],
        );

  static LinearGradient get ctaGradient => AppColor.night
      ? const LinearGradient(colors: [Color(0xFF7358FF), Color(0xFF9B6BFF)])
      : LinearGradient(colors: [AppColor.greenColor, const Color(0xFF5BAE76)]);
}

/// Picks the text direction from the text itself (first strong character),
/// so an English term-heavy question is not forced RTL inside an Arabic UI
/// and Arabic content is never forced LTR.
TextDirection mcqDirFor(String s, TextDirection fallback) {
  for (final r in s.runes) {
    if ((r >= 0x0590 && r <= 0x08FF) ||
        (r >= 0xFB1D && r <= 0xFDFF) ||
        (r >= 0xFE70 && r <= 0xFEFF)) {
      return TextDirection.rtl;
    }
    if ((r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A)) {
      return TextDirection.ltr;
    }
  }
  return fallback;
}

/// Text that follows its own content direction.
class McqText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final int? maxLines;
  final TextOverflow? overflow;
  const McqText(this.text,
      {super.key, required this.style, this.maxLines, this.overflow});

  @override
  Widget build(BuildContext context) {
    final dir = mcqDirFor(text, Directionality.of(context));
    return Directionality(
      textDirection: dir,
      child: Text(text,
          style: style,
          maxLines: maxLines,
          overflow: overflow,
          textAlign: TextAlign.start),
    );
  }
}

/// Page background: plain scaffold colour, plus a faint violet glow at the
/// top in Nocturne only.
class McqBackdrop extends StatelessWidget {
  final Widget child;
  const McqBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColor.scaffoldBackgroundColor,
      child: Stack(
        children: [
          if (AppColor.night)
            const Positioned(
              top: -140,
              left: -80,
              right: -80,
              height: 380,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.75,
                    colors: [Color(0x307358FF), Color(0x007358FF)],
                  ),
                ),
              ),
            ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class McqSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;
  final double radius;
  final List<BoxShadow>? shadow;

  const McqSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.border,
    this.radius = 20,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? AppColor.card,
            borderRadius: BorderRadius.circular(radius),
            border: border ?? Border.all(color: AppColor.borderColor),
            boxShadow: shadow ?? AppColor.glowShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}

class McqPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? trailingIcon;
  final double height;

  const McqPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.trailingIcon,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : .45,
        duration: const Duration(milliseconds: 150),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              height: height,
              decoration: BoxDecoration(
                gradient: McqTheme.ctaGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: McqTheme.accent.withOpacity(.28),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 8),
                      Icon(trailingIcon, color: Colors.white, size: 20),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class McqSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  const McqSecondaryButton(
      {super.key, required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: McqTheme.accent.withOpacity(.55)),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 19, color: AppColor.textPrimary),
                    const SizedBox(width: 8),
                  ],
                  Text(label,
                      style: TextStyle(
                          color: AppColor.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class McqChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  const McqChip({super.key, required this.label, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColor.textSecondary;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(10, 5, 10, 5),
      decoration: BoxDecoration(
        color: (color ?? McqTheme.accent).withOpacity(.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: (color ?? McqTheme.accent).withOpacity(.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: c),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: McqText(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: c, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class McqProgressBar extends StatelessWidget {
  final double value;
  const McqProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        builder: (_, v, __) => LinearProgressIndicator(
          value: v,
          minHeight: 6,
          backgroundColor: AppColor.borderColor,
          valueColor: AlwaysStoppedAnimation(McqTheme.accent),
        ),
      ),
    );
  }
}

class McqTopBar extends StatelessWidget {
  final String title;
  final bool showBack;
  final Widget? trailing;
  const McqTopBar(
      {super.key, required this.title, this.showBack = true, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 4),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20, color: AppColor.textPrimary),
            )
          else
            const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: AppColor.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w800)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class McqEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  const McqEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: McqTheme.accent.withOpacity(.12),
              ),
              child: Icon(icon, size: 32, color: McqTheme.accent),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColor.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(body!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColor.textSecondary, fontSize: 14, height: 1.5)),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: McqPrimaryButton(
                    label: actionLabel!, onTap: onAction, height: 48),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum McqOptionState { idle, selected, correct, wrong, missed }

/// One answer choice. Correctness is never conveyed by colour alone: the
/// badge icon and a text tag change too.
class McqOptionTile extends StatelessWidget {
  final String letter;
  final String text;
  final McqOptionState state;
  final bool multi;
  final VoidCallback? onTap;

  const McqOptionTile({
    super.key,
    required this.letter,
    required this.text,
    required this.state,
    this.multi = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = McqTheme.accent;
    Color border = AppColor.borderColor;
    Color fill = AppColor.card;
    Color badgeFill = AppColor.surface2Color;
    Color badgeText = AppColor.textSecondary;
    Widget? badgeIcon;
    String? tag;
    Color? tagColor;
    double borderWidth = 1;

    switch (state) {
      case McqOptionState.idle:
        break;
      case McqOptionState.selected:
        border = accent;
        borderWidth = 1.6;
        fill = accent.withOpacity(.10);
        badgeFill = accent;
        badgeText = Colors.white;
        break;
      case McqOptionState.correct:
        border = McqTheme.success;
        borderWidth = 1.6;
        fill = McqTheme.success.withOpacity(.13);
        badgeFill = McqTheme.success;
        badgeIcon = const Icon(Icons.check_rounded, size: 20, color: Colors.black87);
        tag = McqStrings.correctAnswerTag;
        tagColor = McqTheme.success;
        break;
      case McqOptionState.wrong:
        border = McqTheme.danger;
        borderWidth = 1.6;
        fill = McqTheme.danger.withOpacity(.12);
        badgeFill = McqTheme.danger;
        badgeIcon = const Icon(Icons.close_rounded, size: 20, color: Colors.white);
        tag = McqStrings.yourAnswerTag;
        tagColor = McqTheme.danger;
        break;
      case McqOptionState.missed:
        border = McqTheme.success.withOpacity(.75);
        fill = McqTheme.success.withOpacity(.06);
        badgeFill = McqTheme.success.withOpacity(.25);
        badgeIcon = Icon(Icons.check_rounded, size: 20, color: McqTheme.success);
        tag = McqStrings.correctAnswerTag;
        tagColor = McqTheme.success;
        break;
    }

    final radius = multi ? 10.0 : 17.0;
    return Semantics(
      button: onTap != null,
      selected: state == McqOptionState.selected,
      label: '$letter. $text',
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 170),
              constraints: const BoxConstraints(minHeight: 58),
              padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 14, 10),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border, width: borderWidth),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 170),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: badgeFill,
                      borderRadius: BorderRadius.circular(radius),
                    ),
                    alignment: Alignment.center,
                    child: badgeIcon ??
                        Text(letter,
                            style: TextStyle(
                                color: badgeText,
                                fontSize: 14,
                                fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        McqText(text,
                            style: TextStyle(
                                color: AppColor.textPrimary,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                                height: 1.45)),
                        if (tag != null) ...[
                          const SizedBox(height: 3),
                          Text(tag,
                              style: TextStyle(
                                  color: tagColor,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular score: correct / total in the middle, percentage under it.
class McqScoreRing extends StatelessWidget {
  final int correct;
  final int total;
  final double size;
  const McqScoreRing(
      {super.key, required this.correct, required this.total, this.size = 170});

  @override
  Widget build(BuildContext context) {
    final v = total == 0 ? 0.0 : correct / total;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: v),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) => CustomPaint(
              size: Size.square(size),
              painter: _RingPainter(value, AppColor.borderColor, McqTheme.accent),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$correct/$total',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                      color: AppColor.textPrimary,
                      fontSize: 34,
                      fontWeight: FontWeight.w800)),
              Text('${(v * 100).round()}%',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                      color: AppColor.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color track;
  final Color color;
  _RingPainter(this.value, this.track, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = (size.shortestSide - 16) / 2;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawCircle(c, r, p);
    if (value <= 0) return;
    p.color = color;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2,
        2 * math.pi * value.clamp(0.0, 1.0), false, p);
  }

  @override
  bool shouldRepaint(_RingPainter o) =>
      o.value != value || o.track != track || o.color != color;
}

String mcqFormatDuration(int ms) {
  final s = (ms / 1000).round();
  final m = s ~/ 60;
  final r = s % 60;
  return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
}
