import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:upgrade/entity/spin_data.dart';
import 'package:upgrade/widgets/app_image.dart';

/// Drag left/right to rotate through photos of the same subject; pinch to zoom,
/// double-tap to reset. One finger rotates, two fingers zoom/pan.
class SpinViewer extends StatefulWidget {
  final SpinData spin;
  final double aspectRatio;
  final double radius;
  const SpinViewer({super.key, required this.spin, this.aspectRatio = 4 / 3, this.radius = 16});

  @override
  State<SpinViewer> createState() => _SpinViewerState();
}

class _SpinViewerState extends State<SpinViewer> with SingleTickerProviderStateMixin {
  late final AnimationController _inertia = AnimationController.unbounded(vsync: this)
    ..addListener(() => setState(() => _pos = _inertia.value));
  late final List<ImageProvider> _providers =
      widget.spin.frames.map(AppImage.providerFor).toList();
  double _pos = 0; // fractional frame position
  double _zoom = 1, _baseZoom = 1;
  Offset _pan = Offset.zero;
  bool _touched = false;
  int _loaded = 0;
  double _w = 300;

  int get _n => _providers.length;
  int get _index => ((_pos.round() % _n) + _n) % _n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded == 0) {
      for (final p in _providers) {
        precacheImage(p, context, onError: (_, __) {}).whenComplete(() {
          if (mounted) setState(() => _loaded++);
        });
      }
    }
  }

  @override
  void dispose() {
    _inertia.dispose();
    super.dispose();
  }

  void _clampPan() {
    final maxX = _w * (_zoom - 1) / 2;
    final maxY = _w / widget.aspectRatio * (_zoom - 1) / 2;
    _pan = Offset(_pan.dx.clamp(-maxX, maxX), _pan.dy.clamp(-maxY, maxY));
  }

  @override
  Widget build(BuildContext context) {
    final label = _labelFor(_index);
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: LayoutBuilder(builder: (context, c) {
        _w = c.maxWidth;
        final perFrame = _w / _n; // one full width = one full turn
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.radius),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTap: () => setState(() {
              _zoom = 1;
              _pan = Offset.zero;
            }),
            onScaleStart: (_) {
              _inertia.stop();
              _baseZoom = _zoom;
              _touched = true;
            },
            onScaleUpdate: (d) => setState(() {
              if (d.pointerCount >= 2) {
                _zoom = (_baseZoom * d.scale).clamp(1.0, 4.0);
                _pan += d.focalPointDelta;
                _clampPan();
              } else if (_zoom > 1.01) {
                _pan += d.focalPointDelta;
                _clampPan();
              } else {
                _pos -= d.focalPointDelta.dx / perFrame;
              }
            }),
            onScaleEnd: (d) {
              if (_zoom > 1.01) return;
              final v = -d.velocity.pixelsPerSecond.dx / perFrame;
              if (v.abs() < 1) return;
              _inertia.value = _pos;
              _inertia.animateWith(FrictionSimulation(0.12, _pos, v));
            },
            child: Stack(fit: StackFit.expand, children: [
              Transform.translate(
                offset: _pan,
                child: Transform.scale(
                  scale: _zoom,
                  child: Image(
                    image: _providers[_index],
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.info_outline)),
                  ),
                ),
              ),
              if (label != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: _chip(Text(label, style: const TextStyle(color: Colors.white, fontSize: 12))),
                ),
              if (!_touched)
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: _chip(const Icon(Icons.threesixty, color: Colors.white, size: 20)),
                ),
              if (_loaded < _n)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LinearProgressIndicator(value: _loaded / _n, minHeight: 3),
                )
              else
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: Container(
                    height: 3,
                    width: _w * (_index + 1) / _n,
                    color: Colors.black26,
                  ),
                ),
            ]),
          ),
        );
      }),
    );
  }

  String? _labelFor(int i) {
    final l = widget.spin.labels;
    if (l.isEmpty) return null;
    final keys = l.keys.where((k) => k <= i).toList();
    return keys.isEmpty ? null : l[keys.reduce(math.max)];
  }

  Widget _chip(Widget child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
        child: child,
      );
}
