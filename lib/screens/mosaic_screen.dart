import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/controllers/mosaic_controller.dart';
import 'package:upgrade/entity/mosaic_entity.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/widgets/mosaic/mosaic_artwork.dart';
import 'package:upgrade/widgets/mosaic/reward_flow_models.dart';
import 'package:upgrade/widgets/mosaic/reward_flow_screen.dart';
import 'package:upgrade/widgets/tablet_bounded.dart';

/// The premium mosaic hero screen: "I'm building this." The artwork stays
/// the visual focus — no dashboard chrome, no confetti, nothing gamified.
///
/// Reward reveals themselves (daily or chest) always happen in
/// RewardFlowScreen, not here — this screen only ever shows the artwork as
/// it currently stands. If the app was closed mid-animation and a batch is
/// still queued, this screen picks it up and launches that same flow so
/// nothing is silently lost.
class MosaicScreen extends StatefulWidget {
  const MosaicScreen({super.key});

  @override
  State<MosaicScreen> createState() => _MosaicScreenState();
}

class _MosaicScreenState extends State<MosaicScreen> {
  late final MosaicController _c;
  bool _checkedQueue = false;

  @override
  void initState() {
    super.initState();
    _c = Get.isRegistered<MosaicController>()
        ? Get.find<MosaicController>()
        : Get.put(MosaicController());
    _c.refresh();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resumeAnyPendingBatch());
  }

  /// Resumes a batch left over from before the app was closed (or from a
  /// chest claim response that arrived while this screen was already open).
  /// Runs once per screen visit; RewardFlowScreen itself removes the batch
  /// from the queue the moment it starts showing it.
  void _resumeAnyPendingBatch() {
    if (_checkedQueue || !mounted) return;
    if (_c.rewardQueue.isEmpty) return;
    _checkedQueue = true;
    final batch = _c.rewardQueue.removeAt(0);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => batch.source == RewardSource.daily
            ? RewardFlowScreen.daily(batch: batch)
            : RewardFlowScreen.chest(batch: batch),
      ),
    );
  }

  Future<void> _openChest(MosaicChest chest) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RewardFlowScreen.chestGate(chestId: chest.id, pieceCount: chest.pieces),
      ),
    );
    _c.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColor.scaffoldBackgroundColor,
        elevation: 0,
        title: const Text(
          "لوحتك الفسيفسائية",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColor.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: TabletBounded(
          child: Obx(() {
            final state = _c.state.value;
            final geometry = _c.geometry.value;
            if (_c.loading.value && state == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state == null || geometry == null) {
              return const Center(child: Text("تعذر تحميل اللوحة"));
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
              children: [
                const Text(
                  "Garden by the Sea",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${state.piecesEarned} / ${state.totalPieces}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColor.greenColor,
                  ),
                ),
                const SizedBox(height: 18),
                MosaicArtwork(geometry: geometry, ownedPieceIds: _c.ownedPieceIds),
                const SizedBox(height: 24),
                if (state.today != null) _TodayProgress(today: state.today!),
                const SizedBox(height: 20),
                ...state.chests.map(
                  (chest) => _ChestRow(chest: chest, onOpen: () => _openChest(chest)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _TodayProgress extends StatelessWidget {
  final MosaicToday today;
  const _TodayProgress({required this.today});

  @override
  Widget build(BuildContext context) {
    // Each task says exactly what to do and shows live progress (server data).
    Widget step(String label, String hint, MosaicStep st) {
      final done = st.done;
      final showCount = st.target > 0;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              done ? Icons.check_circle : Icons.circle_outlined,
              size: 18,
              color: done ? AppColor.greenColor : AppColor.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: done ? AppColor.textPrimary : AppColor.textSecondary,
                    fontWeight: done ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColor.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (showCount)
            Text(
              '${st.progress.clamp(0, st.target)} / ${st.target}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: done ? AppColor.greenColor : AppColor.textSecondary,
              ),
            ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE6D6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "تقدم اليوم",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColor.textPrimary),
              ),
              Text(
                "${today.stepsDone} / 3",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColor.greenColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          step(
            "دراسة",
            "أجب عن ${today.study.target} بطاقات مختلفة اليوم (بأي تقييم).",
            today.study,
          ),
          const SizedBox(height: 12),
          step(
            "إتقان",
            "قيّم ${today.mastery.target} بطاقات بـ«جيد» أو «سهل» اليوم.",
            today.mastery,
          ),
          const SizedBox(height: 12),
          step(
            "تحدي",
            "أجب عن ${today.challenge.target} بطاقة اليوم، أو أنهِ فصلًا كاملًا.",
            today.challenge,
          ),
          const SizedBox(height: 12),
          const Text(
            "أكمل المهام الثلاث لتفتح قطعة جديدة من اللوحة.",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColor.greenColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Only ever offers to OPEN the reward gate screen — never calls the claim
/// endpoint itself. The actual server claim happens only after the user
/// explicitly taps "Open Chest" inside RewardFlowScreen.chestGate.
class _ChestRow extends StatelessWidget {
  final MosaicChest chest;
  final VoidCallback onOpen;
  const _ChestRow({required this.chest, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: chest.claimed ? const Color(0xFFF6F1E7) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEDE6D6)),
        ),
        child: Row(
          children: [
            Icon(
              chest.claimed ? Icons.lock_open : Icons.card_giftcard,
              color: chest.ready ? const Color(0xFFD8B65A) : AppColor.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "صندوق الأسبوع ${chest.index} — يوم ${chest.unlockDay}",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
              ),
            ),
            if (chest.claimed)
              const Text("تم الفتح", style: TextStyle(fontSize: 13, color: AppColor.textSecondary))
            else if (chest.ready)
              TextButton(
                onPressed: onOpen,
                child: const Text("افتح", style: TextStyle(fontWeight: FontWeight.w700)),
              )
            else
              Text("${chest.pieces} قطع", style: const TextStyle(fontSize: 13, color: AppColor.textSecondary)),
          ],
        ),
      ),
    );
  }
}
