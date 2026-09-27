import 'package:upgrade/entity/mosaic_entity.dart';

/// Where a batch of newly-earned pieces came from. The daily allowance and
/// the weekly chest are separate reward sources per the approved economy —
/// they are never merged into one presentation, even on a day both fire.
enum RewardSource { daily, chest }

/// One reveal "run": all the pieces earned from a single event (one
/// answerCard() response, or one chest claim), shown as one sequential flow.
/// Two batches from different sources are always presented as two separate
/// flows, never combined into a single reward window.
class PendingRewardBatch {
  final RewardSource source;
  final List<MosaicAwardedPiece> pieces;

  /// Daily-only context for the "Study Complete!" intro card.
  final int? cardsStudied;
  final int? accuracyPercent;

  PendingRewardBatch({
    required this.source,
    required this.pieces,
    this.cardsStudied,
    this.accuracyPercent,
  });
}
