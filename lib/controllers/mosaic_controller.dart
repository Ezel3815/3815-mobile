import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:upgrade/controllers/api_controller.dart';
import 'package:upgrade/entity/mosaic_entity.dart';
import 'package:upgrade/widgets/mosaic/mosaic_geometry.dart';
import 'package:upgrade/widgets/mosaic/reward_flow_models.dart';

/// Owns the mosaic's read model. State always comes from GET /users/me/mosaic
/// (the server ledger), never invented client-side — that's what keeps a
/// second device or a reinstalled app showing the same painting.
class MosaicController extends GetxController {
  /// TEMPORARY: last session-end diagnostic, shown as a snackbar on the result screen.
  static String diag = 'finishSession never ran';

  final state = Rxn<MosaicState>();
  final geometry = Rxn<MosaicArtworkGeometry>();
  final loading = true.obs;

  /// Reward batches waiting to be shown by RewardFlowScreen, in the order
  /// they were earned. Daily and chest batches are always separate entries
  /// here — a chest-day never merges its 5 pieces into the daily 3.
  final rewardQueue = <PendingRewardBatch>[].obs;

  /// Only pieces the reveal animation has actually played for count as
  /// "owned" for display purposes. This is what keeps the artwork from
  /// spoiling a piece's colour before its flight animation has run — a
  /// piece can be persisted server-side (survives app close) while still
  /// visually "unrevealed" until RewardFlowScreen finishes with it.
  Set<int> get ownedPieceIds => state.value?.pieces
          .where((p) => p.revealed)
          .map((p) => p.pieceId)
          .toSet() ??
      <int>{};

  @override
  void onInit() {
    super.onInit();
    _syncTimezoneThenRefresh();
    MosaicArtworkGeometry.load().then((g) => geometry.value = g);
  }

  /// The mosaic season needs the device's real IANA timezone before the
  /// server will start it (see mosaic.time.ts — it never guesses). Sending
  /// this is safe to repeat on every app open: the backend only uses it to
  /// set User.timezone, and a season's own timezone is frozen at creation
  /// regardless of later calls here.
  Future<void> _syncTimezoneThenRefresh() async {
    try {
      final tz = await FlutterTimezone.getLocalTimezone();
      await ApiController.updateTimezone(tz);
    } catch (_) {
      // Best-effort — if this fails, getMosaic() below will just report
      // status "timezone_required" and the UI hides itself, same as today.
    }
    await refresh();
  }

  Future<void> refresh() async {
    loading.value = true;
    state.value = await ApiController.getMosaic();
    loading.value = false;
  }

  /// Called once, when a study session actually ends, with every mosaic
  /// piece earned across the whole session (however many separate
  /// answerCard() responses they arrived in). This is the single "Daily
  /// Complete" moment — it must never be called mid-session per answer.
  void queueDailyReward(List<MosaicAwardedPiece> pieces, {int? cardsStudied, int? accuracyPercent}) {
    if (pieces.isEmpty) return;
    rewardQueue.add(PendingRewardBatch(
      source: RewardSource.daily,
      pieces: pieces,
      cardsStudied: cardsStudied,
      accuracyPercent: accuracyPercent,
    ));
    refresh();
  }

  /// Actually opens the chest server-side. Only ever called from an explicit
  /// user tap (the chest gate screen's "Open Chest" button) — reaching the
  /// unlock day never calls this on its own.
  Future<void> openChest(String id) async {
    final award = await ApiController.claimMosaicChest(id);
    if (award != null && award.newPieces.isNotEmpty) {
      rewardQueue.add(PendingRewardBatch(source: RewardSource.chest, pieces: award.newPieces));
    }
    refresh();
  }

  /// True once `refresh()` has actual chest data to check readiness against.
  bool chestIsReady(String id) {
    final chests = state.value?.chests ?? const [];
    for (final c in chests) {
      if (c.id == id) return c.ready;
    }
    return false;
  }

  /// Called once a piece's flight-and-landing animation has actually played.
  void markRevealed(MosaicAwardedPiece piece) {
    ApiController.ackMosaicReveal([piece.pieceId]);
    // Optimistic local update so the artwork reflects it immediately,
    // without waiting for the next refresh() round-trip.
    final s = state.value;
    if (s == null) return;
    state.value = MosaicState(
      status: s.status,
      artworkId: s.artworkId,
      totalPieces: s.totalPieces,
      seasonDays: s.seasonDays,
      seasonDay: s.seasonDay,
      piecesEarned: s.piecesEarned,
      piecesRemaining: s.piecesRemaining,
      pieces: s.pieces
          .map((p) => p.pieceId == piece.pieceId
              ? MosaicPieceOwned(pieceId: p.pieceId, slot: p.slot, kind: p.kind, revealed: true)
              : p)
          .toList(),
      today: s.today,
      chests: s.chests,
    );
  }
}
