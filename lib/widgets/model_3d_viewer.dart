import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/strings.dart';
import 'package:upgrade/utils/model_cache.dart';

/// A 3D model the student can turn with one finger and zoom with two.
/// [onTouching] tells the card screen to stop scrolling while a finger is on the model,
/// otherwise the page would scroll instead of the model turning.
class Model3DViewer extends StatefulWidget {
  final String url;
  final ValueChanged<bool>? onTouching;
  final double aspectRatio;
  final double radius;
  const Model3DViewer({
    super.key,
    required this.url,
    this.onTouching,
    this.aspectRatio = 1,
    this.radius = 16,
  });

  @override
  State<Model3DViewer> createState() => _Model3DViewerState();
}

class _Model3DViewerState extends State<Model3DViewer> {
  late Future<String> _file = ModelCache.file(widget.url);
  int _touches = 0;

  void _down() {
    if (_touches++ == 0) widget.onTouching?.call(true);
  }

  void _up() {
    if (_touches > 0 && --_touches == 0) widget.onTouching?.call(false);
  }

  @override
  void dispose() {
    if (_touches > 0) widget.onTouching?.call(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: ColoredBox(
          color: AppColor.surfaceColor,
          child: FutureBuilder<String>(
            future: _file,
            builder: (context, snap) {
              if (snap.hasError) return _error();
              if (!snap.hasData) return _loading();
              return Listener(
                onPointerDown: (_) => _down(),
                onPointerUp: (_) => _up(),
                onPointerCancel: (_) => _up(),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ModelViewer(
                      key: ValueKey(snap.data),
                      src: 'file://${snap.data}',
                      alt: '3D model',
                      cameraControls: true,
                      autoRotate: false,
                      ar: false,
                      disableZoom: false,
                      backgroundColor: AppColor.surfaceColor,
                    ),
                    IgnorePointer(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            AppStrings.model3dHint,
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _loading() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColor.greenColor),
            const SizedBox(height: 12),
            Text(AppStrings.model3dLoading, style: TextStyle(color: AppColor.textSecondary)),
          ],
        ),
      );

  Widget _error() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, color: AppColor.textSecondary, size: 36),
            const SizedBox(height: 8),
            Text(AppStrings.model3dError, style: TextStyle(color: AppColor.textSecondary)),
            TextButton(
              onPressed: () => setState(() => _file = ModelCache.file(widget.url)),
              child: Text(AppStrings.model3dRetry),
            ),
          ],
        ),
      );
}
