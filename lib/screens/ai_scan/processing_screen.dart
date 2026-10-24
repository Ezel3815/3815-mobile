import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'ai_scan_api.dart';
import 'ai_scan_strings.dart';
import 'ai_scan_theme.dart';
import 'premium_screens.dart';
import 'result_screens.dart';

/// Window 4 — runs the scan on the server, then opens window 5 or 6.
class ProcessingScreen extends StatefulWidget {
  final AiScanApi api;
  final List<File> images;
  final bool mcq;
  final int? deckId;
  final VoidCallback? onDeckChanged;
  const ProcessingScreen({super.key, required this.api, required this.images, required this.mcq, this.deckId, this.onDeckChanged});
  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> with TickerProviderStateMixin {
  late final AnimationController _ripple = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600))..repeat();
  late final AnimationController _orbit = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat();
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);
  Timer? _t;
  int _stage = 0; // 0 analyse, 1 understand, 2 create
  String? _error;

  @override
  void initState() {
    super.initState();
    // visual progress only; the real work is the single request in _run()
    _t = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_stage < 2 && mounted) setState(() => _stage++);
    });
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _error = null;
      _stage = 0;
    });
    try {
      final title = (widget.mcq ? AiStr.mcq : AiStr.flashcards) + ' ' + DateTime.now().toString().substring(0, 10);
      final r = await widget.api.scan(widget.images, mcq: widget.mcq, deckId: widget.deckId, title: widget.mcq ? title : null, deckTitle: title);
      if (!mounted) return;
      if (!r.mcq && r.savedDeckId != null) widget.onDeckChanged?.call();
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => r.mcq ? McqResultScreen(api: widget.api, result: r) : FlashcardsResultScreen(cards: r.cards, savedToDeck: r.savedDeckId != null)));
    } on QuotaExceeded catch (e) {
      if (!mounted) return;
      final nav = Navigator.of(context);
      nav.popUntil((r) => r.isFirst || r.settings.name == 'ai_scan_root');
      await showAiPremiumFlow(nav.context, widget.api, nextAt: e.nextAvailableAt);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    _ripple.dispose();
    _orbit.dispose();
    _float.dispose();
    super.dispose();
  }

  /// Gem floating in the middle, soft rings spreading out from it, two tiny sparks circling it.
  Widget _hero() => SizedBox(
        height: 250,
        width: 250,
        child: AnimatedBuilder(
          animation: Listenable.merge([_ripple, _orbit, _float]),
          builder: (_, __) {
            final kids = <Widget>[];
            for (var i = 0; i < 3; i++) {
              final ph = (_ripple.value + i / 3) % 1.0;
              kids.add(Opacity(
                opacity: (1 - ph) * .38,
                child: Container(
                  width: 120 + ph * 130,
                  height: 120 + ph * 130,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AiC.sage, width: 1.2)),
                ),
              ));
            }
            // warm glow behind the gem
            kids.add(Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AiC.gold.withOpacity(.22), AiC.gold.withOpacity(0)])),
            ));
            kids.add(Transform.translate(offset: Offset(0, math.sin(_float.value * math.pi) * -8 + 4), child: aiSvg('w04_processing_gem_premium.svg', w: 118, h: 118)));
            for (var k = 0; k < 2; k++) {
              final a = _orbit.value * 2 * math.pi + k * math.pi;
              final r = k == 0 ? 100.0 : 82.0;
              kids.add(Transform.translate(
                offset: Offset(math.cos(a) * r, math.sin(a) * r * .42),
                child: Container(
                  width: k == 0 ? 8 : 5,
                  height: k == 0 ? 8 : 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: k == 0 ? AiC.gold : AiC.sage,
                    boxShadow: [BoxShadow(color: (k == 0 ? AiC.gold : AiC.sage).withOpacity(.55), blurRadius: 8, spreadRadius: 1)],
                  ),
                ),
              ));
            }
            return Stack(alignment: Alignment.center, children: kids);
          },
        ),
      );

  Widget _stage3(String label, int index) {
    final done = _stage > index;
    final current = _stage == index;
    final first = index == 0, last = index == 2;
    Widget line(bool filled, bool show) => Expanded(
          child: show
              ? Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: filled ? 1 : 0),
                      duration: const Duration(milliseconds: 600),
                      builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 2, backgroundColor: AiC.line, color: AiC.primary),
                    ),
                  ),
                )
              : const SizedBox(),
        );
    return Expanded(
      child: Column(children: [
        Row(children: [
          line(_stage >= index, !first),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? AiC.primary : AiC.card,
              border: Border.all(color: done || current ? AiC.primary : AiC.line, width: 1.6),
            ),
            child: done
                ? const Icon(Icons.check_rounded, size: 17, color: Colors.white)
                : current
                    ? Center(
                        child: AnimatedBuilder(
                          animation: _ripple,
                          builder: (_, __) => Container(
                            width: 8 + 4 * math.sin(_ripple.value * 2 * math.pi).abs(),
                            height: 8 + 4 * math.sin(_ripple.value * 2 * math.pi).abs(),
                            decoration: BoxDecoration(shape: BoxShape.circle, color: AiC.primary),
                          ),
                        ),
                      )
                    : null,
          ),
          line(_stage > index, !last),
        ]),
        const SizedBox(height: 10),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(fontFamily: 'ELMESSIRI', fontSize: 12, fontWeight: current ? FontWeight.w700 : FontWeight.w500, color: done || current ? AiC.forest : AiC.sage.withOpacity(.7)),
          child: Text(label, textAlign: TextAlign.center),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => AiPage(
        child: Column(children: [
          const SizedBox(height: 40),
          _hero(),
          const SizedBox(height: 18),
          Text(AiStr.preparing, style: aiTitle),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(_error ?? AiStr.preparingSub, key: ValueKey(_error), textAlign: TextAlign.center, style: aiBody.copyWith(color: _error == null ? AiC.sage : Colors.red.shade700)),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 18),
            SizedBox(width: 200, child: AiButton(AiStr.retry, onTap: _run)),
          ],
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _stage3(AiStr.stageAnalyze, 0),
              _stage3(AiStr.stageUnderstand, 1),
              _stage3(AiStr.stageCreate, 2),
            ]),
          ),
        ]),
      );
}
