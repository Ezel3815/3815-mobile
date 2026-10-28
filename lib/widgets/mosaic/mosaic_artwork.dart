import 'package:flutter/material.dart';
import 'mosaic_geometry.dart';

/// The premium mosaic "hero": the real master artwork, muted where locked,
/// with each EARNED piece composited on top in full colour at its exact
/// bbox position from pieces.json. Nothing here is decorative placeholder —
/// every visible coloured region corresponds to an owned piece id.
class MosaicArtwork extends StatelessWidget {
  final MosaicArtworkGeometry geometry;
  final Set<int> ownedPieceIds;
  final double radius;

  const MosaicArtwork({
    super.key,
    required this.geometry,
    required this.ownedPieceIds,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final aspect = geometry.canvasWidth / geometry.canvasHeight;
    return AspectRatio(
      aspectRatio: aspect,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = constraints.maxWidth / geometry.canvasWidth;
            return Stack(
              fit: StackFit.expand,
              children: [
                // Locked base: the full artwork, muted so the shape of what's
                // coming is visible without giving away the finished colours.
                ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    0.28, 0.28, 0.28, 0, 0,
                    0.28, 0.28, 0.28, 0, 0,
                    0.28, 0.28, 0.28, 0, 0,
                    0, 0, 0, 0.55, 0,
                  ]),
                  child: Image.asset(geometry.masterAssetPath, fit: BoxFit.cover),
                ),
                // Earned pieces, in full colour, each at its real position.
                for (final id in ownedPieceIds)
                  if (geometry.pieces[id] != null) _piece(geometry.pieces[id]!, scale),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _piece(MosaicPieceGeometry p, double scale) {
    final left = p.bbox[0] * scale;
    final top = p.bbox[1] * scale;
    final w = p.bbox[2] * scale;
    final h = p.bbox[3] * scale;
    return Positioned(
      left: left,
      top: top,
      width: w,
      height: h,
      child: Image.asset(p.assetPath, fit: BoxFit.fill),
    );
  }
}
