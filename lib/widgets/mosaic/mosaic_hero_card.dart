import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/controllers/mosaic_controller.dart';
import 'package:upgrade/main.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/widgets/mosaic/mosaic_artwork.dart';
import 'package:upgrade/widgets/polished_bar.dart';

const Color _mosaicGold = Color(0xFFD8B65A);

/// Garden by the Sea hero — the user's 30-day mosaic season, front and centre
/// on the Progress screen. It replaces both the old small teaser and the
/// separate Monthly Challenge card: the painting IS the monthly challenge.
///
/// Nothing here is a second mosaic implementation. Count, day and artwork all
/// come from the existing MosaicController (server-driven state), the artwork
/// is the existing MosaicArtwork, and tapping opens the existing MosaicScreen.
class MosaicHeroCard extends StatefulWidget {
  const MosaicHeroCard();

  @override
  State<MosaicHeroCard> createState() => _MosaicHeroCardState();
}

class _MosaicHeroCardState extends State<MosaicHeroCard> {
  late final MosaicController _c;

  @override
  void initState() {
    super.initState();
    _c = Get.isRegistered<MosaicController>()
        ? Get.find<MosaicController>()
        : Get.put(MosaicController());
    _c.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _c.state.value;
      final geometry = _c.geometry.value;
      if (state?.status == 'timezone_required') return const SizedBox.shrink();
      if (state == null) {
        // First load: hold the hero's space so the screen doesn't jump.
        // A failed load hides the hero, exactly as the old teaser did.
        return _c.loading.value
            ? const MosaicHeroPlaceholder()
            : const SizedBox.shrink();
      }
      if (geometry == null) return const MosaicHeroPlaceholder();

      final earned = state.piecesEarned;
      final total = state.totalPieces;
      final fraction = total <= 0 ? 0.0 : (earned / total).clamp(0.0, 1.0).toDouble();
      final seasonDays = state.seasonDays < 1 ? 30 : state.seasonDays;
      final dayLine = state.seasonDay > 0
          ? 'اليوم ${state.seasonDay.clamp(1, seasonDays).toInt()} من $seasonDays'
          : '$seasonDays يوماً';

      return Semantics(
        button: true,
        label: 'Garden by the Sea, $earned / $total',
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  // no cream wash on the dark theme
                  AppColor.night ? AppColor.surface2Color : const Color(0xFFFFFDF6),
                  AppColor.surfaceColor,
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _mosaicGold.withOpacity(0.55)),
              boxShadow: [
                BoxShadow(
                  color: AppColor.night
                      ? Colors.black.withOpacity(0.35)
                      : AppColor.darkGreenColor.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => Get.toNamed(AppRoutes.mosaicRoute),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(builder: (context, c) {
                  final art = (c.maxWidth * 0.52).clamp(128.0, 280.0).toDouble();
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // The real, live mosaic: earned pieces in colour, the
                      // rest dimmed, real piece structure visible.
                      SizedBox(
                        width: art,
                        height: art,
                        child: Container(
                          // thin gold edge so the painting sits inside the card
                          foregroundDecoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: _mosaicGold.withOpacity(0.35)),
                          ),
                          child: MosaicArtwork(
                            geometry: geometry,
                            ownedPieceIds: _c.ownedPieceIds,
                            radius: 16, // 28 (card) - 12 (padding): corners line up
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Garden by the Sea',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                                color: AppColor.darkGreenColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'لوحتك الفسيفسائية',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColor.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'lib/assests/brand/mozaik_emblem.png',
                                    height: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  // Forced LTR so "17 / 100" never renders
                                  // as "100 / 17" inside an RTL layout.
                                  Text(
                                    '$earned / $total',
                                    textDirection: TextDirection.ltr,
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: AppColor.darkGreenColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: fraction),
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeOutCubic,
                              builder: (context, v, _) => PolishedBar(
                                value: v,
                                color: AppColor.greenColor,
                                track: AppColor.lightGreenColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_month_rounded,
                                  size: 18,
                                  color: AppColor.darkGreenColor,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    dayLine,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColor.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 16,
                                  height: 2,
                                  margin: const EdgeInsets.only(top: 8),
                                  color: _mosaicGold,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Piece by piece, it clicks.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                      color: AppColor.darkGreenColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class MosaicHeroPlaceholder extends StatelessWidget {
  const MosaicHeroPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColor.surfaceColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _mosaicGold.withOpacity(0.35)),
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColor.greenColor,
        ),
      ),
    );
  }
}
