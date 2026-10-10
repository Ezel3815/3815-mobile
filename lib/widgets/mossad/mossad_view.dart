import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/controllers/progress_controller.dart';
import 'package:upgrade/entity/leaderboard_entry.dart';
import 'package:upgrade/widgets/app_image.dart';
import 'package:upgrade/widgets/mossad/mossad_logic.dart';
import 'package:upgrade/widgets/study_year_prompt.dart';

/// Palette of the Mossad destination (dark + neon, separate from the app's
/// light theme on purpose so the screen feels like a special place).
class MossadColors {
  static const Color bg = Color(0xFF0B1118);
  static const Color surface = Color(0xFF121B26);
  static const Color surfaceAlt = Color(0xFF1A2633);
  static const Color border = Color(0xFF263647);
  static const Color neon = Color(0xFF52F26B);
  static const Color neonDeep = Color(0xFF2BD46B);
  static const Color neonInk = Color(0xFF08210F);
  static const Color pink = Color(0xFFFF3D9A);
  static const Color gold = Color(0xFFFFC53D);
  static const Color silver = Color(0xFFC5CEDA);
  static const Color bronze = Color(0xFFE08A4B);
  static const Color text = Color(0xFFF2F6FA);
  static const Color muted = Color(0xFF8FA3B5);
  static const Color paper = Color(0xFFF1EBD8);
}

const String _kAssetDir = 'lib/assests/mossad/';
const String _kCohort = 'طلاب السنة التحضيرية';

/// The whole Mossad body: cohort badge, hero banner, the two segments
/// (global / my rank), cohort strip and the leaderboard. It only reads the
/// existing [ProgressController] data (`mossad`, `mossadLoading`).
class MossadView extends StatefulWidget {
  final ProgressController controller;
  const MossadView({super.key, required this.controller});

  @override
  State<MossadView> createState() => _MossadViewState();
}

class _MossadViewState extends State<MossadView> {
  bool _global = true;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: _CohortBadge(),
          ),
          const SizedBox(height: 10),
          const MossadHero(),
          const SizedBox(height: 16),
          _Segments(
            global: _global,
            onChanged: (v) => setState(() => _global = v),
          ),
          const SizedBox(height: 12),
          Obx(_buildContent),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final c = widget.controller;
    final data = c.mossad.value;
    final loading = c.mossadLoading.value;

    if (data == null && loading) return const _LoadingBox();
    if (data == null) {
      return _MessageCard(
        icon: Icons.cloud_off_rounded,
        title: 'تعذّر تحميل الترتيب',
        body: 'تحقّق من الاتصال ثم حاول مرة أخرى.',
        actionLabel: 'إعادة المحاولة',
        onAction: () => c.loadMossad(),
      );
    }
    if (!data.inMossad) {
      return _MessageCard(
        icon: Icons.school_rounded,
        title: 'مسابقة $_kCohort',
        body: data.total > 0
            ? 'اختر سنتك الدراسية لتنافس ${mossadFormatXp(data.total)} طالبًا على الصدارة.'
            : 'اختر سنتك الدراسية لتنضم إلى المسابقة.',
        actionLabel: 'اختيار سنتي الدراسية',
        onAction: () async {
          await StudyYearPrompt.choose();
          c.loadMossad();
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CohortStrip(
          total: data.total,
          loading: loading,
          onRefresh: () => c.loadMossad(),
        ),
        const SizedBox(height: 12),
        if (data.entries.isEmpty)
          const _MessageCard(
            icon: Icons.emoji_events_outlined,
            title: 'لا يوجد متسابقون بعد',
            body: 'كن أول من يجمع النقاط ويتصدّر الترتيب.',
          )
        else if (_global)
          _GlobalList(entries: data.entries)
        else
          _MyRank(data: data),
      ],
    );
  }
}

// ───────────────────────── Hero banner ─────────────────────────

class MossadHero extends StatelessWidget {
  const MossadHero({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = (w * 0.68).clamp(220.0, 270.0).toDouble();
        final titleSize = (w * 0.15).clamp(40.0, 60.0).toDouble();
        return Directionality(
          // Positions are physical (mascot left, props right) in every locale.
          textDirection: TextDirection.ltr,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              height: h,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  const Positioned.fill(
                    child: CustomPaint(painter: _BackdropPainter()),
                  ),
                  Positioned(
                    right: w * 0.02,
                    top: h * 0.03,
                    width: w * 0.24,
                    child: const _Art('mossad_brain.png'),
                  ),
                  Positioned(
                    right: w * 0.03,
                    top: h * 0.27,
                    width: w * 0.15,
                    child: const _Art('mossad_microscope.png'),
                  ),
                  Positioned(
                    right: w * 0.02,
                    bottom: h * 0.03,
                    width: w * 0.2,
                    child: const _Art('mossad_cards.png'),
                  ),
                  Positioned(
                    left: -w * 0.01,
                    bottom: 0,
                    width: w * 0.4,
                    child: const _Art('mossad_axolotl.png'),
                  ),
                  Positioned(
                    left: w * 0.33,
                    top: 4,
                    width: 34,
                    height: 26,
                    child: const ExcludeSemantics(
                      child: CustomPaint(
                        painter: _CrownPainter(
                          color: MossadColors.neon,
                          fill: false,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    top: h * 0.2,
                    child: Transform.rotate(
                      angle: -0.2,
                      child: const ExcludeSemantics(
                        child: Text(
                          'STUDY\nLEARN\nGROW',
                          style: TextStyle(
                            color: MossadColors.neon,
                            fontSize: 11,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: w * 0.085,
                    top: h * 0.34,
                    width: 28,
                    height: 28,
                    child: const ExcludeSemantics(
                      child: CustomPaint(painter: _PlusPainter()),
                    ),
                  ),
                  Positioned(
                    left: w * 0.15,
                    top: h * 0.1,
                    width: w * 0.64,
                    child: _TitleBlock(titleSize: titleSize),
                  ),
                  Positioned(
                    right: w * 0.17,
                    bottom: h * 0.1,
                    child: Transform.rotate(
                      angle: -0.08,
                      child: const _Sticker(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Art extends StatelessWidget {
  final String file;
  const _Art(this.file);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      '$_kAssetDir$file',
      fit: BoxFit.contain,
      cacheWidth: 420,
      excludeFromSemantics: true,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  final double titleSize;
  const _TitleBlock({required this.titleSize});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'Mossad، تحدّي السنة التحضيرية',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.rotate(
            angle: -0.04,
            child: CustomPaint(
              painter: const _TornPainter(
                color: MossadColors.neon,
                shadow: MossadColors.pink,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Stack(
                    children: [
                      Transform.translate(
                        offset: const Offset(3, 3),
                        child: Text(
                          'Mossad',
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                            color: MossadColors.pink,
                          ),
                        ),
                      ),
                      Text(
                        'Mossad',
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                          color: const Color(0xFF0B0B0B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -6),
            child: Transform.rotate(
              angle: -0.03,
              child: CustomPaint(
                painter: const _TornPainter(color: MossadColors.paper),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'تحدّي السنة التحضيرية',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sticker extends StatelessWidget {
  const _Sticker();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _TornPainter(color: MossadColors.neon),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          'أعلى درجات\nأكبر أحلام',
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.25,
            fontWeight: FontWeight.w800,
            color: MossadColors.neonInk,
          ),
        ),
      ),
    );
  }
}

/// Deterministic jagged rectangle: reads as torn paper without any raster.
Path _tornRect(Size s, {double jag = 3.5, int seed = 7}) {
  final r = math.Random(seed);
  double j() => r.nextDouble() * jag;
  final sx = math.max(8, (s.width / 12).round());
  final sy = math.max(3, (s.height / 12).round());
  final p = Path()..moveTo(j(), j());
  for (var i = 1; i <= sx; i++) {
    p.lineTo(s.width * i / sx, j());
  }
  for (var i = 1; i <= sy; i++) {
    p.lineTo(s.width - j(), s.height * i / sy);
  }
  for (var i = 1; i <= sx; i++) {
    p.lineTo(s.width * (1 - i / sx), s.height - j());
  }
  for (var i = 1; i < sy; i++) {
    p.lineTo(j(), s.height * (1 - i / sy));
  }
  p.close();
  return p;
}

class _TornPainter extends CustomPainter {
  final Color color;
  final Color? shadow;
  const _TornPainter({required this.color, this.shadow});

  @override
  void paint(Canvas canvas, Size size) {
    final path = _tornRect(size);
    canvas.drawPath(
      path.shift(const Offset(4, 4)),
      Paint()..color = shadow ?? const Color(0xFF000000).withOpacity(0.45),
    );
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TornPainter old) =>
      old.color != color || old.shadow != shadow;
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10201A), Color(0xFF0B1118)],
        ).createShader(rect),
    );
    Paint stroke(Color c, double w) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    final w = size.width;
    final h = size.height;
    // Neon brush strokes behind the mascot and the title.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.02, h * 0.92)
        ..quadraticBezierTo(w * 0.2, h * 0.72, w * 0.46, h * 0.9),
      stroke(MossadColors.neon.withOpacity(0.9), 10),
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.0, h * 0.14)
        ..lineTo(w * 0.1, h * 0.08),
      stroke(MossadColors.neon.withOpacity(0.85), 6),
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.04, h * 0.66)
        ..lineTo(w * 0.14, h * 0.6),
      stroke(MossadColors.pink, 5),
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.52, h * 0.94)
        ..quadraticBezierTo(w * 0.62, h * 0.86, w * 0.7, h * 0.95),
      stroke(MossadColors.pink.withOpacity(0.9), 4),
    );
    final dot = Paint()..color = MossadColors.neon.withOpacity(0.7);
    canvas.drawCircle(Offset(w * 0.58, h * 0.07), 3, dot);
    canvas.drawCircle(Offset(w * 0.8, h * 0.62), 2.5, dot);
    canvas.drawCircle(
      Offset(w * 0.48, h * 0.62),
      2.5,
      Paint()..color = MossadColors.pink.withOpacity(0.85),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _PlusPainter extends CustomPainter {
  const _PlusPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final t = size.width * 0.34;
    final path = Path()
      ..addRect(Rect.fromLTWH((size.width - t) / 2, 0, t, size.height))
      ..addRect(Rect.fromLTWH(0, (size.height - t) / 2, size.width, t));
    canvas.drawPath(
      path.shift(const Offset(2, 2)),
      Paint()..color = const Color(0xFF000000),
    );
    canvas.drawPath(path, Paint()..color = MossadColors.pink);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _CrownPainter extends CustomPainter {
  final Color color;
  final bool fill;
  const _CrownPainter({required this.color, required this.fill});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.1, h * 0.92)
      ..lineTo(w * 0.04, h * 0.22)
      ..lineTo(w * 0.3, h * 0.55)
      ..lineTo(w * 0.5, h * 0.06)
      ..lineTo(w * 0.7, h * 0.55)
      ..lineTo(w * 0.96, h * 0.22)
      ..lineTo(w * 0.9, h * 0.92)
      ..close();
    if (fill) {
      canvas.drawPath(path, Paint()..color = color);
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF000000).withOpacity(0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    } else {
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CrownPainter old) =>
      old.color != color || old.fill != fill;
}

// ───────────────────────── Badge, segments, strip ─────────────────────────

class _CohortBadge extends StatelessWidget {
  const _CohortBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: MossadColors.neon.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MossadColors.neon.withOpacity(0.55)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school_rounded, size: 18, color: MossadColors.neon),
          SizedBox(width: 6),
          Text(
            _kCohort,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: MossadColors.neon,
            ),
          ),
        ],
      ),
    );
  }
}

class _Segments extends StatelessWidget {
  final bool global;
  final ValueChanged<bool> onChanged;
  const _Segments({required this.global, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: MossadColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: MossadColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: 'الترتيب العام',
              icon: Icons.emoji_events_rounded,
              selected: global,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _Segment(
              label: 'ترتيبي',
              icon: Icons.person_rounded,
              selected: !global,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _Segment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? MossadColors.neonInk : MossadColors.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? MossadColors.neon : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CohortStrip extends StatelessWidget {
  final int total;
  final bool loading;
  final VoidCallback onRefresh;
  const _CohortStrip({
    required this.total,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.only(start: 14, end: 4),
      constraints: const BoxConstraints(minHeight: 52),
      decoration: BoxDecoration(
        color: MossadColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MossadColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.school_rounded, size: 20, color: MossadColors.muted),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              _kCohort,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: MossadColors.muted,
              ),
            ),
          ),
          const Icon(Icons.groups_rounded, size: 20, color: MossadColors.muted),
          const SizedBox(width: 6),
          Text(
            total > 0 ? '${mossadFormatXp(total)} طالب' : '—',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: MossadColors.text,
            ),
          ),
          IconButton(
            tooltip: 'تحديث',
            onPressed: loading ? null : onRefresh,
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: MossadColors.neon,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, color: MossadColors.neon),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Leaderboard ─────────────────────────

class _GlobalList extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  const _GlobalList({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 4),
      decoration: BoxDecoration(
        color: MossadColors.surface.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MossadColors.border),
      ),
      child: Column(
        children: [
          const _ListHeader(),
          for (var i = 0; i < entries.length; i++) ...[
            if (mossadHasGapBefore(entries, i)) const _GapDots(),
            _RankRow(entry: entries[i], rank: mossadRankOf(entries[i], i)),
          ],
        ],
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: MossadColors.muted,
    );
    return const Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text('الترتيب', style: style),
            ),
          ),
          Expanded(child: Text('الطالب', style: style)),
          Text('XP', style: style),
        ],
      ),
    );
  }
}

class _GapDots extends StatelessWidget {
  const _GapDots();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Text(
        '•  •  •',
        style: TextStyle(
          color: MossadColors.muted,
          fontSize: 12,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

Color? _medalColor(int rank) {
  if (rank == 1) return MossadColors.gold;
  if (rank == 2) return MossadColors.silver;
  if (rank == 3) return MossadColors.bronze;
  return null;
}

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final medal = _medalColor(rank);
    if (medal == null) {
      return SizedBox(
        width: 40,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$rank',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: MossadColors.muted,
            ),
          ),
        ),
      );
    }
    return SizedBox(
      width: 40,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 18,
            child: CustomPaint(painter: _CrownPainter(color: medal, fill: true)),
          ),
          const SizedBox(height: 2),
          Container(
            width: 30,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: medal.withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: medal.withOpacity(0.7)),
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: medal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final LeaderboardEntry entry;
  final Color ring;
  const _Avatar({required this.entry, required this.ring});

  @override
  Widget build(BuildContext context) {
    final photo = entry.avatarPhotoName;
    final initial =
        entry.name.isNotEmpty ? entry.name.substring(0, 1).toUpperCase() : '?';
    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: 2),
      ),
      child: ClipOval(
        child: (photo != null && photo.isNotEmpty)
            ? AppImage(image: photo, width: 40, height: 40, fit: BoxFit.cover)
            : Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                color: MossadColors.surfaceAlt,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: MossadColors.neon,
                  ),
                ),
              ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  const _RankRow({required this.entry, required this.rank});

  @override
  Widget build(BuildContext context) {
    final medal = _medalColor(rank);
    final me = entry.isMe;
    final ring = me ? MossadColors.neon : (medal ?? MossadColors.border);
    final handle = (entry.username != null && entry.username!.isNotEmpty)
        ? '@${entry.username}'
        : 'المستوى ${entry.level}';

    return Semantics(
      label:
          'المركز $rank، ${entry.name}، ${entry.xp} نقطة${me ? '، هذا أنت' : ''}',
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: me
              ? MossadColors.neon.withOpacity(0.1)
              : MossadColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: me
                ? MossadColors.neon
                : (medal != null
                    ? medal.withOpacity(0.55)
                    : MossadColors.border),
            width: me ? 1.5 : 1,
          ),
          boxShadow: me
              ? [
                  BoxShadow(
                    color: MossadColors.neon.withOpacity(0.22),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            _RankBadge(rank: rank),
            const SizedBox(width: 6),
            _Avatar(entry: entry, ring: ring),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: MossadColors.text,
                          ),
                        ),
                      ),
                      if (me) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 1),
                          decoration: BoxDecoration(
                            color: MossadColors.neon,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'أنت',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: MossadColors.neonInk,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    handle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: MossadColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 96),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      textDirection: TextDirection.ltr,
                      children: [
                        Text(
                          mossadFormatXp(entry.xp),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: MossadColors.text,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'XP',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: MossadColors.neon,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: MossadColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 13, color: MossadColors.gold),
                        const SizedBox(width: 3),
                        Text(
                          'مستوى ${entry.level}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: MossadColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── "ترتيبي" segment ─────────────────────────

class _MyRank extends StatelessWidget {
  final MossadData data;
  const _MyRank({required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries;
    final me = mossadMyEntry(entries);
    if (me == null) {
      return const _MessageCard(
        icon: Icons.person_search_rounded,
        title: 'ترتيبك غير متاح الآن',
        body: 'حدّث الصفحة بعد قليل لعرض مركزك بين الطلاب.',
      );
    }
    final rank = mossadRankOf(me, entries.indexOf(me));
    final medal = _medalColor(rank);
    final gap = mossadXpGapToNext(entries);
    final neighbors = mossadNeighbors(entries);

    String? hint;
    if (rank == 1) {
      hint = 'أنت في الصدارة! حافظ على مركزك.';
    } else if (gap != null) {
      hint = gap == 0
          ? 'متعادل في النقاط مع المركز ${rank - 1}.'
          : 'يفصلك ${mossadFormatXp(gap)} XP عن المركز ${rank - 1}.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                MossadColors.neon.withOpacity(0.16),
                MossadColors.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: MossadColors.neon.withOpacity(0.7)),
          ),
          child: Column(
            children: [
              const Text(
                'ترتيبك الحالي',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: MossadColors.muted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '#$rank',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 56,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  color: medal ?? MossadColors.neon,
                ),
              ),
              if (data.total > 0)
                Text(
                  'من أصل ${mossadFormatXp(data.total)} طالب',
                  style: const TextStyle(
                    fontSize: 14,
                    color: MossadColors.muted,
                  ),
                ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'مجموع النقاط',
                      value: '${mossadFormatXp(me.xp)} XP',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      label: 'المستوى',
                      value: '${me.level}',
                    ),
                  ),
                ],
              ),
              if (hint != null) ...[
                const SizedBox(height: 12),
                Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: MossadColors.neon,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (neighbors.length > 1) ...[
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.only(bottom: 8, right: 4),
            child: Text(
              'من حولك',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: MossadColors.text,
              ),
            ),
          ),
          for (final e in neighbors)
            _RankRow(entry: e, rank: mossadRankOf(e, entries.indexOf(e))),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: MossadColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: MossadColors.muted),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: MossadColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── States ─────────────────────────

class _LoadingBox extends StatelessWidget {
  const _LoadingBox();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: CircularProgressIndicator(color: MossadColors.neon),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: MossadColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MossadColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 38, color: MossadColors.neon),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: MossadColors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: MossadColors.muted,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: MossadColors.neon,
                foregroundColor: MossadColors.neonInk,
                minimumSize: const Size(180, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
