import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/controllers/mosaic_controller.dart';
import 'package:upgrade/entity/mosaic_entity.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/widgets/mosaic/mosaic_artwork.dart';
import 'package:upgrade/widgets/mosaic/mosaic_geometry.dart';
import 'package:upgrade/widgets/mosaic/mosaic_reveal_overlay.dart';
import 'package:upgrade/widgets/mosaic/reward_flow_models.dart';

const _gold = Color(0xFFD8B65A);
const _cream = Color(0xFFF6F5EA);
const _forest = Color(0xFF0F3D2E);
const _serif = 'ELMESSIRI';

/// The premium reward ceremony: Study Complete / Weekly Chest intro →
/// "New Piece Unlocked" / "Chest Reward" for each earned piece, one at a
/// time → real flight into the real Garden by the Sea artwork at its exact
/// bbox position (reusing showMosaicPieceReveal — no second geometry system)
/// → updated N/100 counter → next piece, until the batch is done.
///
/// Two ways to open this screen:
///  - RewardFlowScreen.daily(...): batch is already earned server-side;
///    shown automatically right after a study session.
///  - RewardFlowScreen.chestGate(...): the chest has NOT been opened yet —
///    this shows the closed "Weekly Chest" card first, and only calls the
///    real claim endpoint when the user explicitly taps "Open Chest".
class RewardFlowScreen extends StatefulWidget {
  final RewardSource source;
  final PendingRewardBatch? batch; // null only for chestGate, before opening
  final String? chestId; // set only for chestGate mode
  final int? chestPieceCount; // for the closed-chest card's "+N" label

  const RewardFlowScreen.daily({super.key, required PendingRewardBatch batch})
      : source = RewardSource.daily,
        batch = batch,
        chestId = null,
        chestPieceCount = null;

  const RewardFlowScreen.chest({super.key, required PendingRewardBatch batch})
      : source = RewardSource.chest,
        batch = batch,
        chestId = null,
        chestPieceCount = null;

  const RewardFlowScreen.chestGate({
    super.key,
    required String chestId,
    required int pieceCount,
  })  : source = RewardSource.chest,
        batch = null,
        chestId = chestId,
        chestPieceCount = pieceCount;

  @override
  State<RewardFlowScreen> createState() => _RewardFlowScreenState();
}

enum _Step { chestClosed, opening, intro, revealing, finished }

/// Per-piece UI phase: the piece hovers (tap Continue to send it), then it has
/// landed in the artwork (tap Continue for the next piece / the end state).
enum _Phase { hover, landed }

class _RewardFlowScreenState extends State<RewardFlowScreen> {
  late _Step _step = widget.batch == null ? _Step.chestClosed : _Step.intro;
  PendingRewardBatch? _batch;
  int _pieceIndex = 0;
  final _artworkKey = GlobalKey();
  final _pieceKey = GlobalKey();
  late final MosaicController _mosaic;
  final Set<int> _justLanded = {};
  _Phase _phase = _Phase.hover;
  Completer<void>? _tap;

  Future<void> _waitForTap() {
    _tap = Completer<void>();
    return _tap!.future;
  }

  void _onTap() {
    final c = _tap;
    if (c != null && !c.isCompleted) c.complete();
  }

  @override
  void initState() {
    super.initState();
    _batch = widget.batch;
    _mosaic = Get.isRegistered<MosaicController>()
        ? Get.find<MosaicController>()
        : Get.put(MosaicController());
  }

  Future<void> _openChest() async {
    setState(() => _step = _Step.opening);
    await _mosaic.openChest(widget.chestId!);
    final fresh = _mosaic.rewardQueue
        .where((b) => b.source == RewardSource.chest)
        .toList();
    if (fresh.isEmpty) {
      // Nothing came back (already claimed / not ready any more) — bail out
      // gracefully rather than getting stuck on a spinner.
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final batch = fresh.last;
    _mosaic.rewardQueue.remove(batch);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _batch = batch;
      _step = _Step.intro;
    });
  }

  Future<void> _startReveals() async {
    setState(() => _step = _Step.revealing);
    await _revealCurrent();
  }

  Future<void> _revealCurrent() async {
    if (mounted) setState(() => _phase = _Phase.hover);
    // Let this frame lay out the materialized piece + artwork, then wait for
    // the user's tap (window 2 "Continue") before the piece takes flight.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    await _waitForTap();
    if (!mounted) return;
    final piece = _batch!.pieces[_pieceIndex];
    final geo = _mosaic.geometry.value?.pieces[piece.pieceId];
    final pieceBox = _pieceKey.currentContext?.findRenderObject() as RenderBox?;
    final artBox = _artworkKey.currentContext?.findRenderObject() as RenderBox?;
    if (geo != null && pieceBox != null && artBox != null && pieceBox.hasSize && artBox.hasSize) {
      final sourceCenter = pieceBox.localToGlobal(Offset.zero) + Offset(pieceBox.size.width / 2, pieceBox.size.height / 2);
      final artRect = artBox.localToGlobal(Offset.zero) & artBox.size;
      await showMosaicPieceReveal(
        context,
        piece: geo,
        sourceCenter: sourceCenter,
        artworkRect: artRect,
        canvasWidth: _mosaic.geometry.value!.canvasWidth,
      );
    }
    if (!mounted) return;
    setState(() {
      _justLanded.add(piece.pieceId);
      _phase = _Phase.landed;
    });
    _mosaic.markRevealed(piece);
    // Window 3: "New piece added!" — wait for Continue.
    await _waitForTap();
    if (!mounted) return;
    if (_pieceIndex < _batch!.pieces.length - 1) {
      setState(() => _pieceIndex += 1);
      await _revealCurrent();
    } else {
      setState(() => _step = _Step.finished);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Explicit LTR: the app can run under an RTL locale, which would flip
    // English punctuation ("!") and numbers ("3 / 100") in these windows.
    final light = (_step == _Step.intro && widget.source == RewardSource.daily) || _step == _Step.finished;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: PopScope(
      canPop: _step == _Step.chestClosed || _step == _Step.finished,
      child: Scaffold(
        backgroundColor: light ? _cream : AppColor.darkGreenColor,
        body: SafeArea(
          child: switch (_step) {
            _Step.chestClosed => _closedChest(),
            _Step.opening => _opening(),
            _Step.intro => _intro(),
            _Step.revealing => _revealing(),
            _Step.finished => _finished(),
          },
        ),
      ),
      ),
    );
  }

  // ---------------------------------------------------------------- steps

  Widget _closedChest() => _darkCard(
        icon: Icons.card_giftcard_rounded,
        iconGlow: true,
        title: "Weekly Chest",
        subtitle: "Your weekly mosaic chest is ready.\n+${widget.chestPieceCount} pieces inside.",
        button: _button("Open Chest", _openChest),
        onCloseTap: () => Navigator.of(context).pop(),
      );

  Widget _opening() => Center(
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 0, end: 1),
          builder: (_, t, __) => Opacity(
            opacity: t,
            child: Icon(Icons.card_giftcard_rounded, size: 96 + 12 * t, color: _gold),
          ),
        ),
      );

  Widget _intro() {
    final b = _batch!;
    if (widget.source == RewardSource.daily) {
      final g = _mosaic.geometry.value;
      return _lightCard(
        heroAsset: g?.pieces[b.pieces.first.pieceId]?.assetPath,
        title: "Study Complete!",
        subtitle: "Great job! You've finished your daily study session.",
        stats: [
          if (b.cardsStudied != null) ("${b.cardsStudied}", "Cards Studied"),
          if (b.accuracyPercent != null) ("${b.accuracyPercent}%", "Accuracy"),
          ("+${b.pieces.length}", b.pieces.length == 1 ? "Mosaic Piece" : "Mosaic Pieces"),
        ],
        button: _button("Continue", _startReveals, arrow: true),
      );
    }
    return _darkCard(
      icon: Icons.card_giftcard_rounded,
      iconGlow: true,
      title: "Chest Opened!",
      subtitle: "You found ${b.pieces.length} mosaic piece${b.pieces.length == 1 ? '' : 's'}!",
      button: _button("Continue", _startReveals),
      onCloseTap: null,
    );
  }

  Widget _revealing() {
    final piece = _batch!.pieces[_pieceIndex];
    final geometry = _mosaic.geometry.value;
    final owned = _mosaic.ownedPieceIds.union(_justLanded);
    final total = _mosaic.state.value?.totalPieces ?? 100;
    final earnedSoFar = (_mosaic.state.value?.piecesEarned ?? 0);
    final counter = "$earnedSoFar / $total";

    if (_phase == _Phase.landed && geometry != null) {
      return _landed(geometry, owned, piece.pieceId, counter);
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          widget.source == RewardSource.daily ? "New Piece Unlocked!" : "Chest Reward",
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: _serif, color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          "You earned a new piece for\nGarden by the Sea",
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: _serif, color: Colors.white.withOpacity(0.78), fontSize: 14),
        ),
        Expanded(
          child: Center(
            child: FittedBox(
              child: _MaterializingPiece(key: _pieceKey, assetPath: geometry?.pieces[piece.pieceId]?.assetPath),
            ),
          ),
        ),
        Text(
          "$counter pieces discovered",
          textDirection: TextDirection.ltr,
          style: TextStyle(fontFamily: _serif, color: Colors.white.withOpacity(0.85), fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: geometry == null
                ? const SizedBox(height: 150)
                : MosaicArtwork(key: _artworkKey, geometry: geometry, ownedPieceIds: owned),
          ),
        ),
        _button("Continue", _onTap),
      ],
    );
  }

  /// Window 3 — "Piece Lands in Artwork": the artwork is the hero, the counter
  /// sits top-right, the freshly landed piece pulses, and a banner confirms it.
  Widget _landed(MosaicArtworkGeometry geometry, Set<int> owned, int pieceId, String counter) {
    final geo = geometry.pieces[pieceId];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.extension_rounded, size: 14, color: _gold),
                  const SizedBox(width: 6),
                  Text(counter, textDirection: TextDirection.ltr, style: const TextStyle(fontFamily: _serif, color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ]),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LayoutBuilder(builder: (context, c) {
                  final scale = c.maxWidth / geometry.canvasWidth;
                  return Stack(children: [
                    MosaicArtwork(geometry: geometry, ownedPieceIds: owned),
                    if (geo != null)
                      Positioned(
                        left: geo.bbox[0] * scale,
                        top: geo.bbox[1] * scale,
                        width: geo.bbox[2] * scale,
                        height: geo.bbox[3] * scale,
                        child: const _LandingPulse(),
                      ),
                  ]);
                }),
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.10), borderRadius: BorderRadius.circular(20), border: Border.all(color: _gold.withOpacity(0.3))),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: geo == null ? const Icon(Icons.eco_rounded, color: AppColor.greenColor) : Image.asset(geo.assetPath, fit: BoxFit.contain),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("New piece added!", style: TextStyle(fontFamily: _serif, color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text("Keep going \u2014 you\u2019re doing great!", style: TextStyle(fontFamily: _serif, color: Colors.white70, fontSize: 13)),
              ]),
            ),
          ]),
        ),
        _button("Continue", _onTap),
      ],
    );
  }

  Widget _finished() {
    final geometry = _mosaic.geometry.value;
    final total = _mosaic.state.value?.totalPieces ?? 100;
    final earned = _mosaic.state.value?.piecesEarned ?? _mosaic.ownedPieceIds.length;
    final lastAsset = (_batch != null && _batch!.pieces.isNotEmpty) ? geometry?.pieces[_batch!.pieces.last.pieceId]?.assetPath : null;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Sea/garden atmosphere from the real artwork, fading into cream.
        if (geometry != null)
          Positioned.fill(
            child: Image.asset(geometry.masterAssetPath, fit: BoxFit.cover, alignment: Alignment.bottomCenter),
          ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_cream, _cream.withOpacity(0.92), _cream.withOpacity(0.0), Colors.transparent],
                stops: const [0.0, 0.32, 0.6, 1.0],
              ),
            ),
          ),
        ),
        Column(
          children: [
            const SizedBox(height: 56),
            Container(
              width: 88,
              height: 88,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _forest.withOpacity(0.12), blurRadius: 18, offset: const Offset(0, 6))],
              ),
              child: lastAsset == null ? const Icon(Icons.eco_rounded, color: AppColor.greenColor, size: 40) : Image.asset(lastAsset, fit: BoxFit.contain),
            ),
            const SizedBox(height: 20),
            const Text("Keep going!", style: TextStyle(fontFamily: _serif, fontSize: 34, fontWeight: FontWeight.w700, color: _forest)),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 44),
              child: Text("Each day brings you closer to completing your masterpiece.", textAlign: TextAlign.center, style: TextStyle(fontFamily: _serif, fontSize: 16, color: AppColor.textSecondary)),
            ),
            const SizedBox(height: 14),
            Text("$earned / $total", textDirection: TextDirection.ltr, style: const TextStyle(fontFamily: _serif, fontSize: 18, fontWeight: FontWeight.w600, color: AppColor.greenColor)),
            const Spacer(),
            _button("Back to Home", () => Navigator.of(context).pop()),
            const SizedBox(height: 8),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- shared UI

  Widget _button(String label, VoidCallback onTap, {bool arrow = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(colors: [Color(0xFF3C8F66), Color(0xFF1F6B47)]),
            boxShadow: [BoxShadow(color: _forest.withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: onTap,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(label, style: const TextStyle(fontFamily: _serif, color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                if (arrow) ...[const SizedBox(width: 10), const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20)],
              ]),
            ),
          ),
        ),
      );

  Widget _lightCard({
    required String? heroAsset,
    required String title,
    required String subtitle,
    required List<(String, String)> stats,
    required Widget button,
  }) =>
      Stack(children: [
        Positioned(top: -30, left: -30, child: _leaf(150, -0.5)),
        Positioned(bottom: 60, left: -30, child: _leaf(120, 0.6)),
        Positioned(top: 220, right: -30, child: _leaf(110, 2.6)),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _MaterializingPiece(assetPath: heroAsset, light: true),
            const SizedBox(height: 4),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontFamily: _serif, fontSize: 34, fontWeight: FontWeight.w700, color: _forest)),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontFamily: _serif, fontSize: 16, color: AppColor.greenColor)),
            ),
            const SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  for (final s in stats)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _gold.withOpacity(0.35)),
                            boxShadow: [BoxShadow(color: _forest.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6))],
                          ),
                          child: Column(children: [
                            Text(s.$1, textDirection: TextDirection.ltr, style: const TextStyle(fontFamily: _serif, fontSize: 26, fontWeight: FontWeight.w700, color: _forest)),
                            const SizedBox(height: 2),
                            Text(s.$2, textAlign: TextAlign.center, style: const TextStyle(fontFamily: _serif, fontSize: 12.5, color: AppColor.greenColor)),
                          ]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            button,
          ],
        ),
      ]);

  Widget _leaf(double size, double angle) => IgnorePointer(
        child: Transform.rotate(angle: angle, child: Icon(Icons.eco_rounded, size: size, color: AppColor.greenColor.withOpacity(0.14))),
      );

  Widget _darkCard({
    required IconData icon,
    required bool iconGlow,
    required String title,
    required String subtitle,
    required Widget button,
    VoidCallback? onCloseTap,
  }) =>
      Stack(children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GlowIcon(icon: icon, glow: iconGlow),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontFamily: _serif, fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
            ),
            button,
          ],
        ),
        if (onCloseTap != null)
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: onCloseTap),
          ),
      ]);
}

class _GlowIcon extends StatefulWidget {
  final IconData icon;
  final bool glow;
  const _GlowIcon({required this.icon, required this.glow});
  @override
  State<_GlowIcon> createState() => _GlowIconState();
}

class _GlowIconState extends State<_GlowIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: widget.glow
                ? [BoxShadow(color: _gold.withOpacity(0.35 + 0.25 * _c.value), blurRadius: 30 + 20 * _c.value, spreadRadius: 4)]
                : null,
          ),
          child: Icon(widget.icon, size: 64, color: _gold),
        ),
      );
}

/// The "materialize" step for a single piece: scale/opacity entrance, gentle
/// float + rotation, glow, and a few drifting mosaic-fragment particles —
/// the piece the flight animation will pick up from here by its GlobalKey.
class _MaterializingPiece extends StatefulWidget {
  final String? assetPath;
  final bool light;
  const _MaterializingPiece({super.key, required this.assetPath, this.light = false});
  @override
  State<_MaterializingPiece> createState() => _MaterializingPieceState();
}

class _MaterializingPieceState extends State<_MaterializingPiece> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();
  late final List<Offset> _particleDirs = List.generate(10, (i) {
    final a = (i / 10) * 2 * pi;
    return Offset(cos(a), sin(a));
  });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        final floatY = sin(t * 2 * pi) * 6;
        final rotate = sin(t * 2 * pi) * 0.05;
        return SizedBox(
          width: widget.light ? 230 : 300,
          height: widget.light ? 230 : 300,
          child: Stack(alignment: Alignment.center, children: [
            if (!widget.light)
              Transform.rotate(
                angle: t * 2 * pi * 0.15,
                child: CustomPaint(size: const Size(300, 300), painter: _RaysPainter()),
              ),
            for (var i = 0; i < _particleDirs.length; i++)
              Transform.translate(
                offset: _particleDirs[i] * (95 + 30 * ((t + 0.3 + i * 0.11) % 1.0)),
                child: Opacity(
                  opacity: (1 - ((t + 0.3 + i * 0.11) % 1.0)).clamp(0.0, 1.0) * 0.75,
                  child: Transform.rotate(
                    angle: i * 0.9 + t * 2,
                    child: Container(
                      width: i.isEven ? 6 : 8,
                      height: i.isEven ? 12 : 9,
                      decoration: BoxDecoration(
                        color: const [_gold, Color(0xFF5CC7C9), Color(0xFF6FBF8E)][i % 3],
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ),
                ),
              ),
            Container(
              width: widget.light ? 130 : 180,
              height: widget.light ? 130 : 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _gold.withOpacity(0.35 + 0.15 * sin(t * 2 * pi)), blurRadius: 70, spreadRadius: 18)],
              ),
            ),
            Transform.translate(
              offset: Offset(0, floatY),
              child: Transform.rotate(
                angle: rotate,
                child: widget.assetPath == null
                    ? const SizedBox(width: 96, height: 96)
                    : Image.asset(widget.assetPath!, width: widget.light ? 140 : 210, height: widget.light ? 140 : 210, fit: BoxFit.contain),
              ),
            ),
          ]),
        );
      },
    );
  }
}

/// Soft golden light rays behind the hovering piece (window 2).
class _RaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    const n = 14;
    for (var i = 0; i < n; i++) {
      final a = i * 2 * pi / n;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + cos(a - 0.05) * r, c.dy + sin(a - 0.05) * r)
        ..lineTo(c.dx + cos(a + 0.05) * r, c.dy + sin(a + 0.05) * r)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = RadialGradient(colors: [_gold.withOpacity(0.30), _gold.withOpacity(0.0)]).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// One-shot gold pulse over the piece that just landed (window 3).
class _LandingPulse extends StatelessWidget {
  const _LandingPulse();
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1400),
          tween: Tween(begin: 1, end: 0),
          curve: Curves.easeOut,
          builder: (_, v, __) => DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [BoxShadow(color: _gold.withOpacity(0.7 * v), blurRadius: 24 * v + 1, spreadRadius: 4 * v)],
            ),
          ),
        ),
      );
}
