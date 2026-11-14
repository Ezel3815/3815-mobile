import 'dart:convert';
import 'package:upgrade/entity/card_entity.dart';

/// Optional 3D model stored inside a card's existing `data` JSON:
///   { "model": { "side": "front" | "back", "url": "https://.../muscle.glb" } }
/// "front": shown with the question and stays visible after the answer is revealed.
/// "back":  shown only once the answer is revealed.
/// Any card type except OCCLUSION can carry it; other cards behave exactly as before.
extension CardModel3D on CardEntity {
  String? _modelUrl({required bool back}) {
    if (type == 'OCCLUSION') return null;
    try {
      final d = data is String ? jsonDecode(data as String) : data;
      final m = d is Map ? d['model'] : null;
      if (m is! Map) return null;
      final url = (m['url'] ?? '').toString();
      if (url.isEmpty) return null;
      final isBack = (m['side'] ?? 'front').toString() == 'back';
      return isBack == back ? url : null;
    } catch (_) {
      return null;
    }
  }

  String? modelUrlFront() => _modelUrl(back: false);
  String? modelUrlBack() => _modelUrl(back: true);
  String? anyModelUrl() => modelUrlFront() ?? modelUrlBack();
}
