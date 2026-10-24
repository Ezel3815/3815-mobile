import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'ai_scan_api.dart';
import 'ai_scan_strings.dart';
import 'ai_scan_theme.dart';
import 'processing_screen.dart';

/// Window 3 — take or pick the photo.
class PhotoCaptureScreen extends StatefulWidget {
  final AiScanApi api;
  final bool mcq;
  final int? deckId;
  final VoidCallback? onDeckChanged;
  const PhotoCaptureScreen({super.key, required this.api, required this.mcq, this.deckId, this.onDeckChanged});
  @override
  State<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends State<PhotoCaptureScreen> {
  CameraController? _cam;
  bool _denied = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final cams = await availableCameras();
      final c = CameraController(
        cams.firstWhere((x) => x.lensDirection == CameraLensDirection.back, orElse: () => cams.first),
        ResolutionPreset.high,
        enableAudio: false,
      );
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() => _cam = c);
    } catch (_) {
      if (mounted) setState(() => _denied = true);
    }
  }

  @override
  void dispose() {
    _cam?.dispose();
    super.dispose();
  }

  void _go(File f) => Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProcessingScreen(api: widget.api, images: [f], mcq: widget.mcq, deckId: widget.deckId, onDeckChanged: widget.onDeckChanged)));

  Future<void> _shoot() async {
    final c = _cam;
    if (c == null || !c.value.isInitialized || c.value.isTakingPicture) return;
    try {
      _go(File((await c.takePicture()).path));
    } catch (_) {}
  }

  Future<void> _gallery() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 2200, imageQuality: 88);
    if (x != null && mounted) _go(File(x.path));
  }

  @override
  Widget build(BuildContext context) {
    final ready = _cam != null && _cam!.value.isInitialized;
    return AiPage(
      mountains: false,
      child: Column(children: [
        AiTopBar(AiStr.takePhoto),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: AspectRatio(
            aspectRatio: 4 / 4.6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(fit: StackFit.expand, children: [
                if (ready)
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(width: _cam!.value.previewSize!.height, height: _cam!.value.previewSize!.width, child: CameraPreview(_cam!)),
                  )
                else
                  Container(color: AiC.paleSage, child: Center(child: _denied ? aiSvg('w03_camera_permission.svg', w: 80) : CircularProgressIndicator(color: AiC.primary))),
                Padding(padding: const EdgeInsets.all(10), child: aiSvg('w03_scan_frame_corners.svg', fit: BoxFit.fill)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: AiC.card, borderRadius: BorderRadius.circular(26), border: Border.all(color: AiC.line)),
          child: Row(children: [
            Expanded(child: _Seg(text: AiStr.camera, icon: 'w02_camera_outline.svg', active: true, onTap: () {})),
            Expanded(child: _Seg(text: AiStr.gallery, icon: 'w02_photo_gallery.svg', active: false, onTap: _gallery)),
          ]),
        ),
        const Spacer(),
        InkWell(customBorder: const CircleBorder(), onTap: _shoot, child: aiSvg('w03_capture_shutter.svg', w: 84, h: 84)),
        const SizedBox(height: 10),
        Text(AiStr.photoHint, style: TextStyle(fontFamily: 'ELMESSIRI', fontSize: 12, color: AiC.sage)),
        const SizedBox(height: 22),
      ]),
    );
  }
}

class _Seg extends StatelessWidget {
  final String text, icon;
  final bool active;
  final VoidCallback onTap;
  const _Seg({required this.text, required this.icon, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          height: 42,
          decoration: BoxDecoration(color: active ? AiC.accent : Colors.transparent, borderRadius: BorderRadius.circular(22)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ColorFiltered(colorFilter: ColorFilter.mode(active ? Colors.white : AiC.forest, BlendMode.srcIn), child: aiSvg(icon, w: 20, h: 20)),
            const SizedBox(width: 8),
            Text(text, style: TextStyle(fontFamily: 'ELMESSIRI', fontSize: 13.5, fontWeight: FontWeight.w600, color: active ? Colors.white : AiC.forest)),
          ]),
        ),
      );
}
