import 'dart:async';
import 'dart:io';
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

class _ProcessingScreenState extends State<ProcessingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
  Timer? _t;
  int _stage = 0; // 0 analyse, 1 understand, 2 create
  String? _error;

  @override
  void initState() {
    super.initState();
    // visual progress only; the real work is the single request in _run()
    _t = Timer.periodic(const Duration(seconds: 4), (_) {
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
      final r = await widget.api.scan(widget.images, mcq: widget.mcq, deckId: widget.deckId, title: widget.mcq ? title : null);
      if (!mounted) return;
      if (!r.mcq && widget.deckId != null) widget.onDeckChanged?.call();
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => r.mcq ? McqResultScreen(api: widget.api, result: r) : FlashcardsResultScreen(cards: r.cards, savedToDeck: widget.deckId != null)));
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
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AiPage(
        child: Column(children: [
          const SizedBox(height: 70),
          SizedBox(
            height: 190,
            child: Stack(alignment: Alignment.center, children: [
              RotationTransition(turns: _spin, child: aiSvg('w04_processing_orbit.svg', w: 230, h: 190)),
              aiSvg('w04_processing_gem_premium.svg', w: 110, h: 110),
            ]),
          ),
          const SizedBox(height: 34),
          Text(AiStr.preparing, style: aiTitle),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(_error ?? AiStr.preparingSub, textAlign: TextAlign.center, style: aiBody.copyWith(color: _error == null ? AiC.sage : Colors.red.shade700)),
          ),
          if (_error != null) ...[
            const SizedBox(height: 18),
            SizedBox(width: 200, child: AiButton(AiStr.retry, onTap: _run)),
          ],
          const SizedBox(height: 44),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _Stage(AiStr.stageAnalyze, 'w04_stage_analyze.svg', _stage >= 0),
              _Stage(AiStr.stageUnderstand, 'w04_stage_image.svg', _stage >= 1),
              _Stage(AiStr.stageCreate, 'w04_stage_generate.svg', _stage >= 2),
            ]),
          ),
        ]),
      );
}

class _Stage extends StatelessWidget {
  final String label, icon;
  final bool on;
  const _Stage(this.label, this.icon, this.on);
  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: on ? 1 : .45,
        child: Column(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: on ? AiC.primary : AiC.sage.withOpacity(.4), shape: BoxShape.circle)),
          const SizedBox(height: 10),
          aiSvg(icon, w: 28, h: 28),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontFamily: 'ELMESSIRI', fontSize: 11.5, color: AiC.sage)),
        ]),
      );
}
