import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'ai_scan_api.dart';
import 'ai_scan_strings.dart';
import 'ai_scan_theme.dart';

/// Window 5 — flip cards (also reached after saving into a deck).
class FlashcardsResultScreen extends StatefulWidget {
  final List<FlashItem> cards;
  final bool savedToDeck;
  const FlashcardsResultScreen({super.key, required this.cards, this.savedToDeck = false});
  @override
  State<FlashcardsResultScreen> createState() => _FlashcardsResultScreenState();
}

class _FlashcardsResultScreenState extends State<FlashcardsResultScreen> with SingleTickerProviderStateMixin {
  int _i = 0;
  bool _back = false;
  late final AnimationController _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));

  @override
  void initState() {
    super.initState();
    if (widget.savedToDeck) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AiStr.savedToDeck(widget.cards.length), style: const TextStyle(fontFamily: 'ELMESSIRI')), backgroundColor: AiC.forest));
      });
    }
  }

  void _go(int d) {
    final n = _i + d;
    if (n < 0 || n >= widget.cards.length) return;
    _flip.value = 0;
    setState(() {
      _i = n;
      _back = false;
    });
  }

  void _toggle() {
    _back ? _flip.reverse() : _flip.forward();
    setState(() => _back = !_back);
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  Widget _arrow(BuildContext context, bool next) {
    final rtl = aiRtl(context);
    // "next" points to the end of the reading direction
    final pointsLeft = next ? rtl : !rtl;
    return IconButton(
      onPressed: () => _go(next ? 1 : -1),
      icon: Icon(pointsLeft ? Icons.chevron_left : Icons.chevron_right, color: AiC.forest, size: 30),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cards[_i];
    return AiPage(
      child: Column(children: [
        AiTopBar(AiStr.flashcards),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(color: AiC.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AiC.line)),
          child: Text('${_i + 1}/${widget.cards.length}', style: const TextStyle(fontFamily: 'ELMESSIRI', fontSize: 12, color: AiC.sage)),
        ),
        Expanded(
          child: GestureDetector(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 16, 26, 10),
              child: AnimatedBuilder(
                animation: _flip,
                builder: (_, __) {
                  final a = _flip.value * math.pi;
                  final showBack = a > math.pi / 2;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, .001)
                      ..rotateY(a),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        color: AiC.card,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AiC.line),
                        boxShadow: [BoxShadow(color: AiC.forest.withOpacity(.08), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(showBack ? math.pi : 0),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Flexible(
                            child: SingleChildScrollView(
                              child: Text(showBack ? c.answer : c.question,
                                  textAlign: TextAlign.center,
                                  style: showBack ? const TextStyle(fontFamily: 'ELMESSIRI', fontSize: 16, color: AiC.forest, height: 1.8) : aiTitle.copyWith(fontSize: 22)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Icon(Icons.keyboard_arrow_down, color: AiC.sage),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        Column(children: [
          InkWell(
            customBorder: const CircleBorder(),
            onTap: _toggle,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AiC.card, border: Border.all(color: AiC.line)),
              child: const Icon(Icons.refresh, color: AiC.forest),
            ),
          ),
          const SizedBox(height: 6),
          Text(AiStr.flipCard, style: const TextStyle(fontFamily: 'ELMESSIRI', fontSize: 11.5, color: AiC.sage)),
        ]),
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 10, 40, 22),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _arrow(context, false),
            _arrow(context, true),
          ]),
        ),
      ]),
    );
  }
}

/// Window 6 — multiple-choice quiz, one question at a time.
class McqResultScreen extends StatefulWidget {
  final AiScanApi api;
  final ScanResult result;
  const McqResultScreen({super.key, required this.api, required this.result});
  @override
  State<McqResultScreen> createState() => _McqResultScreenState();
}

class _McqResultScreenState extends State<McqResultScreen> {
  int _i = 0;
  int? _sel;
  late final List<int?> _answers = List.filled(widget.result.questions.length, null);

  String _letter(int k) {
    const ar = ['أ', 'ب', 'ج', 'د', 'هـ', 'و'];
    const en = ['A', 'B', 'C', 'D', 'E', 'F'];
    return (aiRtl(context) ? ar : en)[k % 6];
  }

  Future<void> _next() async {
    _answers[_i] = _sel;
    final qs = widget.result.questions;
    if (_i + 1 < qs.length) {
      setState(() {
        _i++;
        _sel = _answers[_i];
      });
      return;
    }
    int score = 0;
    for (var k = 0; k < qs.length; k++) {
      if (_answers[k] == qs[k].correct) score++;
    }
    if (widget.result.quizId != null) widget.api.submitQuiz(widget.result.quizId!, _answers).catchError((_) {});
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AiC.ivory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(AiStr.quizDone, style: aiCardTitle),
        content: Text(AiStr.score(score, qs.length), style: aiBody.copyWith(fontSize: 16, color: AiC.forest)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(AiStr.ok, style: const TextStyle(color: AiC.forest, fontFamily: 'ELMESSIRI')))],
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final qs = widget.result.questions;
    final q = qs[_i];
    return AiPage(
      child: Column(children: [
        AiTopBar(AiStr.mcq),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
          child: Column(children: [
            Align(alignment: AlignmentDirectional.centerEnd, child: Text('${_i + 1}/${qs.length}', style: const TextStyle(fontFamily: 'ELMESSIRI', fontSize: 12, color: AiC.sage))),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: (_i + 1) / qs.length, minHeight: 4, backgroundColor: AiC.paleSage, color: AiC.primary),
            ),
          ]),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(22, 24, 22, 16), children: [
            Text(q.question, style: aiCardTitle.copyWith(fontSize: 17, height: 1.6)),
            const SizedBox(height: 18),
            for (var k = 0; k < q.options.length; k++)
              _Option(letter: _letter(k), text: q.options[k], selected: _sel == k, onTap: () => setState(() => _sel = k)),
          ]),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(22, 0, 22, 26), child: AiButton(_i + 1 < qs.length ? AiStr.next : AiStr.finish, onTap: _sel == null ? null : _next)),
      ]),
    );
  }
}

class _Option extends StatelessWidget {
  final String letter, text;
  final bool selected;
  final VoidCallback onTap;
  const _Option({required this.letter, required this.text, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AiC.paleSage : AiC.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? AiC.sage : AiC.line, width: selected ? 1.4 : 1),
            ),
            child: Row(children: [
              Text('$letter.', style: const TextStyle(fontFamily: 'ELMESSIRI', fontSize: 14, color: AiC.forest, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Expanded(child: Text(text, style: const TextStyle(fontFamily: 'ELMESSIRI', fontSize: 14, color: AiC.forest))),
              if (selected) const Icon(Icons.check_circle, color: AiC.primary, size: 22),
            ]),
          ),
        ),
      );
}
