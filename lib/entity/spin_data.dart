import 'dart:convert';
import 'package:upgrade/entity/card_entity.dart';

/// Optional 360° photo set stored inside a card's existing `data` JSON:
/// { "spin": { "side": "front"|"back", "frames": [url, ...],
///             "labels": [ {"frame": 0, "text": "Anterior"} ] } }
/// Any card type can carry it; cards without it behave exactly as before.
class SpinData {
  final List<String> frames;
  final Map<int, String> labels;
  const SpinData(this.frames, this.labels);
}

extension CardSpin on CardEntity {
  SpinData? spinFor({required bool back}) {
    if (type == 'OCCLUSION') return null;
    try {
      final d = data is String ? jsonDecode(data as String) : data;
      final s = d is Map ? d['spin'] : null;
      if (s is! Map) return null;
      final side = (s['side'] ?? 'front').toString();
      if ((side == 'back') != back) return null;
      final frames = (s['frames'] is List)
          ? (s['frames'] as List).map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : <String>[];
      if (frames.length < 2) return null;
      final labels = <int, String>{};
      if (s['labels'] is List) {
        for (final l in s['labels']) {
          if (l is Map && l['frame'] is num) labels[(l['frame'] as num).toInt()] = '${l['text']}';
        }
      }
      return SpinData(frames, labels);
    } catch (_) {
      return null;
    }
  }

  /// Every frame URL (both sides), for offline download.
  List<String> allSpinFrames() => [
        ...?spinFor(back: false)?.frames,
        ...?spinFor(back: true)?.frames,
      ];
}
