import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'ai_scan_api.dart';
import 'ai_scan_strings.dart';
import 'ai_scan_theme.dart';

/// Shown whenever the free tries are used up.
/// 7 (offer): subscribe -> 9 -> payment  |  maybe later -> 8 (countdown)  ·  9 -> back to app -> 10
Future<void> showAiPremiumFlow(BuildContext context, AiScanApi api, {DateTime? nextAt}) async {
  final go = await showDialog<bool>(context: context, barrierColor: AiC.deep.withOpacity(.82), builder: (_) => _OfferDialog(api: api));
  if (!context.mounted) return;
  if (go == true) {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PremiumPage(api: api)));
  } else {
    var t = nextAt;
    if (t == null) {
      try {
        t = (await api.status()).nextAvailableAt;
      } catch (_) {}
    }
    if (context.mounted) await showDialog(context: context, barrierColor: AiC.deep.withOpacity(.82), builder: (_) => _SeeYouDialog(until: t));
  }
}

Widget _sheet({required Widget child}) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Container(decoration: BoxDecoration(color: AiC.ivory, borderRadius: BorderRadius.circular(28)), child: child),
    );

class _Feature extends StatelessWidget {
  final String text;
  final double size;
  const _Feature(this.text, {this.size = 13});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          aiSvg('w78_check-circle.svg', w: 20, h: 20),
          const SizedBox(width: 10),
          Flexible(child: Text(text, style: TextStyle(fontFamily: 'ELMESSIRI', fontSize: size, color: AiC.forest, fontWeight: FontWeight.w600))),
        ]),
      );
}

class _PlanBox extends StatelessWidget {
  final String label, price;
  final bool yearly, selected;
  final int saving;
  final VoidCallback? onTap;
  const _PlanBox({required this.label, required this.price, this.yearly = false, this.selected = false, this.saving = 0, this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 92,
            decoration: BoxDecoration(
              color: AiC.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: selected ? AiC.primary : AiC.line, width: selected ? 1.6 : 1),
            ),
            child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(label, style: TextStyle(fontFamily: 'ELMESSIRI', fontSize: 12.5, color: AiC.forest, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(price, style: TextStyle(fontFamily: 'ELMESSIRI', fontSize: 19, color: AiC.forest, fontWeight: FontWeight.w700)),
                if (yearly && saving > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                    decoration: BoxDecoration(color: AiC.paleSage, borderRadius: BorderRadius.circular(10)),
                    child: Text(AiStr.save(saving), style: TextStyle(fontFamily: 'ELMESSIRI', fontSize: 10.5, color: AiC.primary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ]),
              if (yearly) Positioned(top: -12, left: 12, child: aiSvg('w78_pricing-crown.svg', w: 26, h: 26)),
            ]),
          ),
        ),
      );
}

/// Yearly on the left, monthly on the right (as in the design), in both languages.
Widget _plansRow(Plans? p, bool yearlySelected, void Function(bool yearly)? onPick) => Directionality(
      textDirection: TextDirection.ltr,
      child: Row(children: [
        _PlanBox(label: AiStr.yearly, price: '\$${(p?.yearly ?? 49.99).toStringAsFixed(2)}', yearly: true, saving: p?.savingPercent ?? 30, selected: yearlySelected, onTap: onPick == null ? null : () => onPick(true)),
        const SizedBox(width: 12),
        _PlanBox(label: AiStr.monthly, price: '\$${(p?.monthly ?? 5.99).toStringAsFixed(2)}', selected: !yearlySelected, onTap: onPick == null ? null : () => onPick(false)),
      ]),
    );

/// Window 7 — premium offer.
class _OfferDialog extends StatefulWidget {
  final AiScanApi api;
  const _OfferDialog({required this.api});
  @override
  State<_OfferDialog> createState() => _OfferDialogState();
}

class _OfferDialogState extends State<_OfferDialog> {
  Plans? _plans;
  @override
  void initState() {
    super.initState();
    widget.api.plans().then((p) {
      if (mounted) setState(() => _plans = p);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) => _sheet(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Align(alignment: Alignment.centerRight, child: InkWell(onTap: () => Navigator.pop(context, false), child: aiSvg('w78_close.svg', w: 24, h: 24))),
            aiSvg('w06_premium_crown.svg', w: 76, h: 76),
            const SizedBox(height: 8),
            Text(AiStr.discoverPremium, textAlign: TextAlign.center, style: aiTitle.copyWith(fontSize: 21)),
            const SizedBox(height: 10),
            Text(AiStr.usedFree, textAlign: TextAlign.center, style: aiBody),
            const SizedBox(height: 12),
            Align(alignment: AlignmentDirectional.centerStart, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_Feature(AiStr.fUnlimited), _Feature(AiStr.fFaster), _Feature(AiStr.fPriority)])),
            const SizedBox(height: 18),
            _plansRow(_plans, true, null),
            const SizedBox(height: 18),
            AiButton(AiStr.subscribe, onTap: () => Navigator.pop(context, true)),
            const SizedBox(height: 10),
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AiStr.maybeLater, style: TextStyle(color: AiC.forest, fontSize: 13, fontFamily: 'ELMESSIRI'))),
          ]),
        ),
      );
}

/// Window 8 — countdown to the next free try. The server owns the time; it is shown in the device's local time.
class _SeeYouDialog extends StatefulWidget {
  final DateTime? until;
  const _SeeYouDialog({this.until});
  @override
  State<_SeeYouDialog> createState() => _SeeYouDialogState();
}

class _SeeYouDialogState extends State<_SeeYouDialog> {
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  String _p(int n) => n.toString().padLeft(2, '0');
  String get _left {
    final d = (widget.until ?? DateTime.now()).difference(DateTime.now());
    if (d.isNegative) return '00:00';
    return d.inHours > 0 ? '${_p(d.inHours)}:${_p(d.inMinutes % 60)}:${_p(d.inSeconds % 60)}' : '${_p(d.inMinutes)}:${_p(d.inSeconds % 60)}';
  }

  String get _clock {
    final u = widget.until;
    if (u == null) return '';
    final h = u.hour % 12 == 0 ? 12 : u.hour % 12;
    final ar = Directionality.of(context) == TextDirection.rtl;
    return '$h:${_p(u.minute)} ${u.hour < 12 ? (ar ? 'ص' : 'AM') : (ar ? 'م' : 'PM')}';
  }

  @override
  Widget build(BuildContext context) => _sheet(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Align(alignment: Alignment.centerRight, child: InkWell(onTap: () => Navigator.pop(context), child: aiSvg('w78_close.svg', w: 24, h: 24))),
            aiSvg('w06_clock_return.svg', w: 90, h: 90),
            const SizedBox(height: 10),
            Text(AiStr.seeYou, style: aiTitle),
            const SizedBox(height: 10),
            Text(AiStr.seeYouSub, textAlign: TextAlign.center, style: aiBody),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: AiC.paleSage.withOpacity(.55), borderRadius: BorderRadius.circular(16), border: Border.all(color: AiC.line)),
              child: Column(children: [
                Text(AiStr.returnsIn, style: TextStyle(fontFamily: 'ELMESSIRI', fontSize: 12, color: AiC.forest, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Directionality(textDirection: TextDirection.ltr, child: Text(_left, style: TextStyle(fontFamily: 'ELMESSIRI', fontSize: 30, fontWeight: FontWeight.w700, color: AiC.forest))),
                const SizedBox(height: 2),
                if (_clock.isNotEmpty) Text(AiStr.returnsAt(_clock), style: TextStyle(fontFamily: 'ELMESSIRI', fontSize: 11, color: AiC.sage)),
              ]),
            ),
            const SizedBox(height: 18),
            AiButton(AiStr.gotIt, onTap: () => Navigator.pop(context)),
          ]),
        ),
      );
}

/// Window 9 — upgrade page.
class PremiumPage extends StatefulWidget {
  final AiScanApi api;
  const PremiumPage({super.key, required this.api});
  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  bool _yearly = true;
  Plans? _plans;
  @override
  void initState() {
    super.initState();
    widget.api.plans().then((p) {
      if (mounted) setState(() => _plans = p);
    }).catchError((_) {});
  }

  Future<void> _back() async {
    final nav = Navigator.of(context);
    nav.pop();
    await Navigator.of(nav.context).push(PageRouteBuilder(opaque: true, pageBuilder: (_, __, ___) => const _LaterScreen()));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AiC.paleSage,
        body: Stack(children: [
          Positioned(top: 0, left: 0, right: 0, child: SizedBox(height: 260, child: aiSvg('w78_mountain-landscape.svg', fit: BoxFit.cover))),
          Positioned(top: 54, left: 0, right: 0, child: Center(child: aiSvg('w06_premium_crown.svg', w: 78, h: 78))),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * .76,
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 14),
              decoration: BoxDecoration(color: AiC.ivory, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
              child: SafeArea(
                top: false,
                child: Column(children: [
                  Text(AiStr.upgrade, style: aiTitle.copyWith(fontSize: 22)),
                  const SizedBox(height: 10),
                  Text(AiStr.upgradeSub, textAlign: TextAlign.center, style: aiBody),
                  const SizedBox(height: 22),
                  _plansRow(_plans, _yearly, (y) => setState(() => _yearly = y)),
                  const SizedBox(height: 18),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _Feature(AiStr.fUnlimited, size: 12.5),
                      _Feature(AiStr.fFaster, size: 12.5),
                      _Feature(AiStr.fPriority, size: 12.5),
                      _Feature(AiStr.fExclusive, size: 12.5),
                    ]),
                  ),
                  const Spacer(),
                  AiButton(AiStr.subscribe, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PaymentScreen(api: widget.api, plan: _yearly ? 'YEARLY' : 'MONTHLY')))),
                  const SizedBox(height: 10),
                  TextButton(onPressed: _back, child: Text(AiStr.backToApp, style: TextStyle(color: AiC.forest, fontSize: 13, fontFamily: 'ELMESSIRI'))),
                ]),
              ),
            ),
          ),
        ]),
      );
}

/// Window 10 — shown after leaving the upgrade page without subscribing.
class _LaterScreen extends StatelessWidget {
  const _LaterScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AiC.deep,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 34),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              aiSvg('w06_friendly_wave.svg', w: 150, h: 150),
              const SizedBox(height: 26),
              Text(AiStr.seeYouLater, style: aiTitle.copyWith(fontSize: 22, color: AiC.ivory)),
              const SizedBox(height: 10),
              Text(AiStr.laterSub, textAlign: TextAlign.center, style: aiBody.copyWith(color: AiC.ivory.withOpacity(.85))),
              const SizedBox(height: 26),
              AiButton(AiStr.ok, light: true, onTap: () => Navigator.pop(context)),
            ]),
          ),
        ),
      );
}

/// Not in the design pack: Sham Cash transfer details + receipt submission, drawn in the same style.
class PaymentScreen extends StatefulWidget {
  final AiScanApi api;
  final String plan;
  const PaymentScreen({super.key, required this.api, required this.plan});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Map? _p;
  String? _err;
  final _tx = TextEditingController();
  File? _proof;
  bool _busy = false, _sent = false;

  @override
  void initState() {
    super.initState();
    widget.api.startPayment(widget.plan).then((p) {
      if (mounted) setState(() => _p = p);
    }).catchError((e) {
      if (mounted) setState(() => _err = e.toString());
    });
  }

  @override
  void dispose() {
    _tx.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      await widget.api.submitPayment(_p!['id'] as int, _tx.text.trim(), proof: _proof);
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Expanded(child: Text(k, style: aiBody)),
          Directionality(textDirection: TextDirection.ltr, child: SelectableText(v, style: TextStyle(fontFamily: 'ELMESSIRI', fontSize: 15, fontWeight: FontWeight.w700, color: AiC.forest))),
        ]),
      );

  @override
  Widget build(BuildContext context) => AiPage(
        child: Column(children: [
          AiTopBar(AiStr.payTitle),
          Expanded(
            child: _sent
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(34),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        aiSvg('w04_success_check.svg', w: 70, h: 70),
                        const SizedBox(height: 18),
                        Text(AiStr.sentTitle, style: aiTitle),
                        const SizedBox(height: 8),
                        Text(AiStr.sentSub, textAlign: TextAlign.center, style: aiBody),
                        const SizedBox(height: 24),
                        AiButton(AiStr.ok, onTap: () => Navigator.of(context).popUntil((r) => r.isFirst || r.settings.name == 'ai_scan_root')),
                      ]),
                    ),
                  )
                : _p == null
                    ? Center(child: _err != null ? Text(_err!, style: aiBody) : CircularProgressIndicator(color: AiC.primary))
                    : ListView(padding: const EdgeInsets.fromLTRB(22, 18, 22, 24), children: [
                        Text(AiStr.payHeading, style: aiTitle.copyWith(fontSize: 20)),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AiC.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: AiC.line)),
                          child: Column(children: [
                            _row(AiStr.amount, '\$${(_p!['amount_usd'] as num).toStringAsFixed(2)}'),
                            _row(AiStr.wallet, '${_p!['wallet'] ?? ''}'),
                            if ('${_p!['account_name'] ?? ''}'.isNotEmpty) _row(AiStr.accountName, '${_p!['account_name']}'),
                            _row(AiStr.refNote, '${_p!['reference']}'),
                          ]),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _tx,
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            labelText: AiStr.txNumber,
                            filled: true,
                            fillColor: AiC.card,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AiC.line)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
                            if (x != null) setState(() => _proof = File(x.path));
                          },
                          icon: aiSvg('w03_gallery_upload_arrow.svg', w: 20, h: 20),
                          label: Text(_proof == null ? AiStr.attachProof : AiStr.proofAttached, style: TextStyle(color: AiC.forest, fontFamily: 'ELMESSIRI')),
                          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), side: BorderSide(color: AiC.line), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        ),
                        if (_err != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_err!, style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
                        const SizedBox(height: 20),
                        AiButton(_busy ? '...' : AiStr.send, onTap: _busy ? null : _submit),
                      ]),
          ),
        ]),
      );
}
