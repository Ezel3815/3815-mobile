import 'package:upgrade/entity/mosaic_entity.dart';

/// Rewards collected from the server during ONE study session. The session
/// result screen reads it after [settled], so a slow final answer can never
/// lose the streak or the mosaic pieces (they are read when they arrive, not
/// when the screen opens).
class SessionRewards {
  /// Set only by the answer that actually saved today's streak.
  int? streak;

  /// Mosaic pieces earned this session (mosaic side only; never the streak).
  final List<MosaicAwardedPiece> pieces = [];

  /// Completes when every answer request of the session has finished.
  Future<void> settled = Future<void>.value();
}
