import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'ai_scan_api.dart';
import 'ai_scan_strings.dart';
import 'ai_scan_theme.dart';
import 'create_type_screen.dart';

/// Opens the AI scan flow. [deckId]: flashcards are saved straight into this deck; [onDeckChanged] refreshes the deck's list afterwards.
class AiScan {
  static Future<void> open(BuildContext context, {int? deckId, VoidCallback? onDeckChanged}) {
    return Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(name: 'ai_scan_root'),
      builder: (_) => CreateTypeScreen(api: AiScanApi(), deckId: deckId, onDeckChanged: onDeckChanged),
    ));
  }

  /// The "+" menu on a deck: add manually (existing screen) or create with AI.
  static void showAddMenu({required VoidCallback onManual, required BuildContext context, int? deckId, VoidCallback? onDeckChanged, String? manualLabel}) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: const BoxDecoration(color: AiC.ivory, borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AiC.line, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            _Tile(icon: Icons.edit_outlined, text: manualLabel ?? AiStr.addManual, onTap: () {
              Get.back();
              onManual();
            }),
            const SizedBox(height: 10),
            _Tile(icon: Icons.auto_awesome_outlined, text: AiStr.addWithAi, onTap: () {
              Get.back();
              open(context, deckId: deckId, onDeckChanged: onDeckChanged);
            }),
          ]),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  const _Tile({required this.icon, required this.text, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: AiC.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AiC.line)),
          child: Row(children: [
            Icon(icon, color: AiC.forest),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: aiCardTitle.copyWith(fontSize: 15))),
          ]),
        ),
      );
}
