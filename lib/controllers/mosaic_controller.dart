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

  bool _refreshing = false;
  bool _refreshQueued = false;

  /// Piece ids already put in rewardQueue during this app run. A batch is
  /// removed from rewardQueue the moment its ceremony starts, so without this
  /// a refresh mid-animation would see the piece as "orphaned" and queue it
  /// a second time.
  final Set<int> _queuedPieceIds = <int>{};

  /// Secondary/background: never throws, never clears good state. A failed
  /// request keeps whatever state we already had. Overlapping calls don't run
  /// in parallel; one follow-up pass is queued so a call made right after a
  /// reward/chest change is not lost.
  Future<void>? _current;

  /// Awaiting this always means "a refresh that started after this call has
  /// finished" (an in-flight one is joined, with one follow-up pass queued).
  Future<void> refresh() {
    final running = _current;
    if (running != null) {
      _refreshQueued = true;
      return running;
    }
    final f = _runRefresh().whenComplete(() => _current = null);
    _current = f;
    return f;
  }

  Future<void> _runRefresh() async {
    _refreshing = true;
    try {
      do {
        _refreshQueued = false;
        if (state.value == null) loading.value = true;
        try {
          final s = await ApiController.getMosaic();
          if (s != null) {
            state.value = s;
            _recoverUnrevealedPieces();
          }
        } catch (_) {
          // Keep existing state; retry on the next refresh.
        }
      } while (_refreshQueued);
    } finally {
      _refreshing = false;
      loading.value = false;
    }
  }

  /// Picks up any server-owned piece that is unrevealed AND not already
  /// sitting in rewardQueue, and queues it — grouped by source, so a
  /// leftover chest piece can never surface as a daily reward. This is what
  /// makes a piece recoverable after the app was closed mid-ceremony, an
  /// old build missed it, or anything else left it unrevealed, without ever
  /// re-queuing a piece that's already queued or mid-animation.
  void _recoverUnrevealedPieces() {
    final s = state.value;
    if (s == null) return;
    final alreadyQueued = <int>{
      ...rewardQueue.expand((b) => b.pieces).map((p) => p.pieceId),
      ..._queuedPieceIds,
    };
    final orphaned = s.pieces.where((p) => !p.revealed && !alreadyQueued.contains(p.pieceId));

    final daily = <MosaicAwardedPiece>[];
    final chest = <MosaicAwardedPiece>[];
    for (final p in orphaned) {
      final piece = MosaicAwardedPiece(pieceId: p.pieceId, slot: p.slot, kind: p.kind);
      (p.kind == 'CHEST' ? chest : daily).add(piece);
    }
    if (daily.isNotEmpty) {
      _queuedPieceIds.addAll(daily.map((p) => p.pieceId));
      rewardQueue.add(PendingRewardBatch(source: RewardSource.daily, pieces: daily));
    }
    if (chest.isNotEmpty) {
      _queuedPieceIds.addAll(chest.map((p) => p.pieceId));
      rewardQueue.add(PendingRewardBatch(source: RewardSource.chest, pieces: chest));
    }
  }

  /// Called once, when a study session actually ends, with every mosaic
  /// piece earned across the whole session (however many separate
  /// answerCard() responses they arrived in). This is the single "Daily
  /// Complete" moment — it must never be called mid-session per answer.
  void queueDailyReward(List<MosaicAwardedPiece> pieces, {int? cardsStudied, int? accuracyPercent}) {
    if (pieces.isEmpty) return;
    _queuedPieceIds.addAll(pieces.map((p) => p.pieceId));
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
      _queuedPieceIds.addAll(award.newPieces.map((p) => p.pieceId));
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
