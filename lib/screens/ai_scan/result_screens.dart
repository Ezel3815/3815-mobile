import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/strings.dart';
import 'ai_scan_api.dart';
import 'ai_scan_strings.dart';
import 'ai_scan_theme.dart';

bool _isArabic(String t) => RegExp(r'[؀-ۿ]').hasMatch(t);

/// Text for an HtmlWidget, exactly like the app's own card view does it (same markup, alignment, direction).
String _html(String text) {
  final safe = const HtmlEscape().convert(text).replaceAll('\n', '<br>');
  return '<div style="text-align:center;" dir="${_isArabic(text) ? 'rtl' : 'ltr'}">$safe</div>';
}

/// The "Keep or Delete" page shown after the last card / question. Nothing is saved until the student taps Keep.
class _KeepPage extends StatefulWidget {
  final String title;
  final Future<void> Function() onKeep;
  final VoidCallback onDelete;
  final Widget? top;
  const _KeepPage({required this.title, required this.onKeep, required this.onDelete, this.top});
  @override
  State<_KeepPage> createState() => _KeepPageState();
}

class _KeepPageState extends State<_KeepPage> {
  bool _busy = false;
  String? _err;

  Future<void> _keep() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      await widget.onKeep();
    } catch (e) {
      if (mounted) setState(() {
        _busy = false;
        _err = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) => AiPage(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (widget.top != null) ...[widget.top!, const SizedBox(height: 18)],
              Text(widget.title, textAlign: TextAlign.center, style: aiTitle.copyWith(fontSize: 21)),
              const SizedBox(height: 10),
              Text(AiStr.keepSub, textAlign: TextAlign.center, style: aiBody),
              if (_err != null) ...[const SizedBox(height: 12), Text(_err!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontFamily: 'ELMESSIRI', fontSize: 12.5))],
              const SizedBox(height: 28),
              AiButton(_busy ? AiStr.saving : AiStr.keep, onTap: _busy ? null : _keep),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _busy ? null : widget.onDelete,
                child: Text(AiStr.delete, style: const TextStyle(color: Colors.redAccent, fontSize: 15, fontFamily: 'ELMESSIRI', fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ),
      );
}

void _leave(BuildContext context, String message) {
  final nav = Navigator.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  nav.popUntil((r) => r.isFirst || r.settings.name == 'ai_scan_root');
  if (nav.canPop()) nav.pop(); // also close the AI entry screen
  messenger?.showSnackBar(SnackBar(content: Text(message, style: const TextStyle(fontFamily: 'ELMESSIRI'))));
}

/// Review of the generated flashcards, laid out like the app's own card view
/// (front, divider, back; the green "Show answer" bar). At the end: Keep or Delete.
class FlashcardsResultScreen extends StatefulWidget {
  final AiScanApi api;
  final List<FlashItem> cards;
  final int? deckId;
  final String deckTitle;
  final VoidCallback? onDeckChanged;
  const FlashcardsResultScreen({super.key, required this.api, required this.cards, this.deckId, required this.deckTitle, this.onDeckChanged});
  @override
  State<FlashcardsResultScreen> createState() => _FlashcardsResultScreenState();
}

class _FlashcardsResultScreenState extends State<FlashcardsResultScreen> {
  final PageController _pc = PageController();
  int _i = 0;
  bool _show = false;

  void _go(int d) {
    final n = _i + d;
    if (n < 0) return;
    if (n >= widget.cards.length) {
      _keepPage();
      return;
    }
    setState(() => _show = false);
    _pc.animateToPage(n, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _keepPage() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _KeepPage(
        title: AiStr.keepAsk(widget.cards.length),
        onKeep: () async {
          await widget.api.keepCards(widget.cards, deckId: widget.deckId, deckTitle: widget.deckTitle);
          widget.onDeckChanged?.call();
          if (mounted) _leave(context, AiStr.kept);
        },
        onDelete: () => _leave(context, AiStr.discarded),
      ),
    ));
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _i == widget.cards.length - 1;
    return Scaffold(
      backgroundColor: AppColor.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColor.textPrimary),
        centerTitle: true,
        title: Text('${_i + 1}/${widget.cards.length}', style: TextStyle(fontSize: 14, color: AppColor.textPrimary)),
      ),
      body: SafeArea(
        child: PageView.builder(
          controller: _pc,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.cards.length,
          onPageChanged: (v) => setState(() => _i = v),
          itemBuilder: (_, index) {
            final c = widget.cards[index];
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(children: [
                HtmlWidget(_html(c.question), textStyle: TextStyle(fontSize: 14, color: AppColor.textPrimary)),
                if (_show && index == _i) ...[
                  const SizedBox(height: 14),
                  Divider(height: 0, thickness: 1, color: AppColor.ink.withOpacity(0.08)),
                  const SizedBox(height: 14),
                  HtmlWidget(_html(c.answer), textStyle: TextStyle(fontSize: 14, color: AppColor.textPrimary)),
                  const SizedBox(height: 14),
                ],
              ]),
            );
          },
        ),
      ),
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
        InkWell(
          onTap: () => setState(() => _show = !_show),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColor.greenColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
            child: Text(_show ? AppStrings.hideAnswer : AppStrings.showAnswer,
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
        Container(
          color: AppColor.greenColor,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: SafeArea(
            top: false,
            child: Row(children: [
              Expanded(child: TextButton(onPressed: _i == 0 ? null : () => _go(-1), child: Text(AiStr.previous, style: TextStyle(color: Colors.white.withOpacity(_i == 0 ? .4 : 1), fontSize: 15)))),
              Expanded(child: TextButton(onPressed: () => _go(1), child: Text(last ? AiStr.finish : AiStr.next, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)))),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// Multiple-choice quiz: every pick is marked right or wrong straight away. At the end: score, then Keep or Delete.
class McqResultScreen extends StatefulWidget {
  final AiScanApi api;
  final ScanResult result;
  final String title;
  const McqResultScreen({super.key, required this.api, required this.result, required this.title});
  @override
  State<McqResultScreen> createState() => _McqResultScreenState();
}

class _McqResultScreenState extends State<McqResultScreen> {
  int _i = 0;
  int? _sel; // locked in as soon as it is picked
  int _score = 0;

  static const _ok = Color(0xFF2E9E5B);
  static const _bad = Color(0xFFD64545);

  String _letter(int k) {
    const ar = ['أ', 'ب', 'ج', 'د', 'هـ', 'و'];
    const en = ['A', 'B', 'C', 'D', 'E', 'F'];
    return (aiRtl(context) ? ar : en)[k % 6];
  }

  void _pick(int k) {
    if (_sel != null) return;
    final q = widget.result.questions[_i];
    setState(() {
      _sel = k;
      if (k == q.correct) _score++;
    });
  }

  void _next() {
    final qs = widget.result.questions;
    if (_i + 1 < qs.length) {
      setState(() {
        _i++;
        _sel = null;
      });
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _KeepPage(
        title: AiStr.keepAskQuiz,
        top: Column(children: [
          Text(AiStr.quizDone, style: aiCardTitle.copyWith(fontSize: 18)),
          const SizedBox(height: 6),
          Text(AiStr.score(_score, qs.length), style: aiBody.copyWith(fontSize: 17, color: AiC.forest)),
        ]),
        onKeep: () async {
          await widget.api.keepQuiz(qs, widget.title);
          if (mounted) _leave(context, AiStr.kept);
        },
        onDelete: () => _leave(context, AiStr.discarded),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final qs = widget.result.questions;
    final q = qs[_i];
    final answered = _sel != null;
    final right = answered && _sel == q.correct;
    return AiPage(
      child: Column(children: [
        AiTopBar(AiStr.mcq),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
          child: Column(children: [
            Align(alignment: AlignmentDirectional.centerEnd, child: Text('${_i + 1}/${qs.length}', style: TextStyle(fontFamily: 'ELMESSIRI', fontSize: 12, color: AiC.sage))),
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
              _Option(
                letter: _letter(k),
                text: q.options[k],
                state: !answered ? 0 : (k == q.correct ? 1 : (k == _sel ? 2 : 0)),
                onTap: () => _pick(k),
              ),
            if (answered) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: (right ? _ok : _bad).withOpacity(.10), borderRadius: BorderRadius.circular(14), border: Border.all(color: (right ? _ok : _bad).withOpacity(.5))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(right ? Icons.check_circle : Icons.cancel, color: right ? _ok : _bad, size: 22),
                    const SizedBox(width: 8),
                    Text(right ? AiStr.correct : AiStr.wrong, style: TextStyle(fontFamily: 'ELMESSIRI', fontSize: 15, fontWeight: FontWeight.w700, color: right ? _ok : _bad)),
                  ]),
                  if (!right) ...[
                    const SizedBox(height: 6),
                    Text('${AiStr.rightWas} ${_letter(q.correct)}. ${q.options[q.correct]}', style: TextStyle(fontFamily: 'ELMESSIRI', fontSize: 13.5, color: AiC.forest, height: 1.5)),
                  ],
                  if (q.explanation.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(q.explanation, style: TextStyle(fontFamily: 'ELMESSIRI', fontSize: 13, color: AiC.sage, height: 1.6)),
                  ],
                ]),
              ),
            ],
          ]),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(22, 0, 22, 26), child: AiButton(_i + 1 < qs.length ? AiStr.next : AiStr.seeResult, onTap: answered ? _next : null)),
      ]),
    );
  }
}

class _Option extends StatelessWidget {
  final String letter, text;
  final int state; // 0 neutral, 1 correct, 2 wrong pick
  final VoidCallback onTap;
  const _Option({required this.letter, required this.text, required this.state, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final col = state == 1 ? _McqResultScreenState._ok : _McqResultScreenState._bad;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: state == 0 ? AiC.card : col.withOpacity(.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: state == 0 ? AiC.line : col, width: state == 0 ? 1 : 1.6),
          ),
          child: Row(children: [
            Text('$letter.', style: TextStyle(fontFamily: 'ELMESSIRI', fontSize: 14, color: AiC.forest, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: TextStyle(fontFamily: 'ELMESSIRI', fontSize: 14, color: AiC.forest))),
            if (state == 1) Icon(Icons.check_circle, color: col, size: 22),
            if (state == 2) Icon(Icons.cancel, color: col, size: 22),
          ]),
        ),
      ),
    );
  }
}
