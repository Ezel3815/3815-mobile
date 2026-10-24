import 'package:flutter/material.dart';
import 'ai_scan_api.dart';
import 'ai_scan_strings.dart';
import 'ai_scan_theme.dart';
import 'photo_capture_screen.dart';
import 'premium_screens.dart';

/// Window 2 — what to create.
class CreateTypeScreen extends StatelessWidget {
  final AiScanApi api;
  final int? deckId; // flashcards are saved straight into this deck
  final VoidCallback? onDeckChanged;
  const CreateTypeScreen({super.key, required this.api, this.deckId, this.onDeckChanged});

  Future<void> _pick(BuildContext context, bool mcq) async {
    try {
      final st = await api.status();
      if (!st.canUse) {
        if (context.mounted) await showAiPremiumFlow(context, api, nextAt: st.nextAvailableAt);
        return;
      }
    } catch (_) {/* the server decides again at scan time */}
    if (context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => PhotoCaptureScreen(api: api, mcq: mcq, deckId: deckId, onDeckChanged: onDeckChanged)));
    }
  }

  @override
  Widget build(BuildContext context) => AiPage(
        child: Column(children: [
          AiTopBar(AiStr.createTitle),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(22, 28, 22, 24), children: [
              Text(AiStr.whatCreate, style: aiTitle),
              const SizedBox(height: 10),
              Text(AiStr.whatCreateSub, style: aiBody),
              const SizedBox(height: 26),
              _OptionCard(icon: 'w02_flashcards_option.svg', title: AiStr.flashcards, sub: AiStr.flashcardsSub, onTap: () => _pick(context, false)),
              const SizedBox(height: 16),
              _OptionCard(icon: 'w02_mcq_option.svg', title: AiStr.mcq, sub: AiStr.mcqSub, onTap: () => _pick(context, true)),
              const SizedBox(height: 110),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                aiSvg('w02_info_circle.svg', w: 16, h: 16),
                const SizedBox(width: 6),
                Flexible(child: Text(AiStr.clearPhotoTip, style: TextStyle(fontFamily: 'ELMESSIRI', fontSize: 11.5, color: AiC.sage))),
              ]),
            ]),
          ),
        ]),
      );
}

class _OptionCard extends StatelessWidget {
  final String icon, title, sub;
  final VoidCallback onTap;
  const _OptionCard({required this.icon, required this.title, required this.sub, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
          decoration: BoxDecoration(
            color: AiC.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AiC.line),
            boxShadow: [BoxShadow(color: AiC.shadow, blurRadius: 18, offset: const Offset(0, 6))],
          ),
          child: Row(children: [
            aiSvg(icon, w: 92, h: 70),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: aiCardTitle),
                const SizedBox(height: 4),
                Text(sub, style: TextStyle(fontFamily: 'ELMESSIRI', fontSize: 11.5, color: AiC.sage, height: 1.5)),
              ]),
            ),
            // chevron points to the end of the row: left in Arabic (RTL), right in English
            Transform.flip(flipX: aiRtl(context), child: aiSvg('w02_chevron_right.svg', w: 20, h: 20)),
          ]),
        ),
      );
}
