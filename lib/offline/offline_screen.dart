import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/controllers/years_controller.dart';
import 'package:upgrade/di.dart';
import 'package:upgrade/entity/deck_entity.dart';
import 'package:upgrade/network_info.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/widgets/app_snack_bar.dart';
import 'package:upgrade/widgets/inter_code_dialog.dart';
import 'offline_store.dart';

/// Arabic / English text for the Offline screen.
class OffUi {
  static bool get _en => Get.locale?.languageCode == 'en';
  static String _t(String ar, String en) => _en ? en : ar;
  static String get title => _t('بدون إنترنت', 'Offline');
  static String get heroTitle => _t('ادرس في أي مكان', 'Study anywhere');
  static String get heroSub => _t('حمّل موادك مرة واحدة، ثم ادرس بدون اتصال', 'Download once, then study without a connection');
  static String get subjectsLabel => _t('مواد محمّلة', 'Downloaded');
  static String get sizeLabel => _t('المساحة', 'Storage');
  static String get listTitle => _t('موادك المفتوحة', 'Your unlocked subjects');
  static String get ready => _t('جاهزة للتحميل', 'Ready to download');
  static String get downloading => _t('جارٍ التحميل', 'Downloading');
  static String get calculating => _t('جارٍ حساب الوقت…', 'Estimating time…');
  static String get almost => _t('على وشك الانتهاء', 'Almost done');
  static String left(String t) => _t('المتبقي تقريبًا $t', '$t left');
  static String secs(int s) => _t('$s ثانية', '$s sec');
  static String mins(int m) => _t('$m دقيقة', '$m min');
  static String cardsMb(int c, double mb) => _t('متاحة بدون إنترنت · $c بطاقة · ${mb.toStringAsFixed(1)} ميغابايت', 'Available offline · $c cards · ${mb.toStringAsFixed(1)} MB');
  static String get cancel => _t('إلغاء', 'Cancel');
  static String get update => _t('تحديث', 'Update');
  static String get remove => _t('حذف التحميل', 'Remove download');
  static String get noNet => _t('تحتاج إلى اتصال بالإنترنت للتحميل', 'You need an internet connection to download');
  static String get done => _t('تم التحميل. يمكنك الدراسة بدون إنترنت', 'Downloaded. You can study offline');
  static String partial(int n) => _t('تم التحميل، لكن تعذّر تحميل $n ملف. حاول التحديث لاحقًا', 'Downloaded, but $n files failed. Try Update later');
  static String get failed => _t('تعذّر التحميل، حاول مرة أخرى', 'Download failed, please try again');
  static String get busy => _t('انتظر انتهاء التحميل الحالي', 'Wait for the current download to finish');
  static String get emptyTitle => _t('لا توجد مواد للتحميل بعد', 'Nothing to download yet');
  static String get lockedNote => _t('المواد المقفلة لا يمكن تحميلها. أدخل الكود لفتحها أولًا.', 'Locked subjects can\'t be downloaded. Enter your code to unlock them first.');
  static String get enterCode => _t('إدخال الكود', 'Enter code');
}

/// The one download that is running right now. It lives outside the screen,
/// so leaving the screen does not stop it.
class _Job {
  final DeckEntity subject;
  final ValueNotifier<double> progress = ValueNotifier(0);
  final CancelToken cancel = CancelToken();
  final DateTime started = DateTime.now();
  _Job(this.subject);
}

class OfflineJobs {
  static _Job? current;
  static final ValueNotifier<int> tick = ValueNotifier(0);

  static Future<void> start(DeckEntity subject) async {
    if (current != null) {
      showSnackBarWidget(message: OffUi.busy);
      return;
    }
    if (!await instance<NetworkInfo>().isConnected) {
      showSnackBarWidget(message: OffUi.noNet);
      return;
    }
    final job = _Job(subject);
    current = job;
    tick.value++;
    String? msg;
    try {
      final failed = await OfflineStore.download(subject, onProgress: (p) => job.progress.value = p, cancel: job.cancel);
      msg = failed == 0 ? OffUi.done : OffUi.partial(failed);
    } catch (e) {
      msg = job.cancel.isCancelled ? null : OffUi.failed;
    }
    current = null;
    tick.value++;
    if (msg != null) showSnackBarWidget(message: msg);
  }
}

/// Drawer → Offline: every unlocked subject, with a download button and a live progress ring.
class OfflineScreen extends StatefulWidget {
  const OfflineScreen({super.key});
  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  List<DeckEntity> _subjects() {
    final yc = Get.find<YearsController>();
    final out = <DeckEntity>[];
    final seen = <int>{};
    void add(DeckEntity d) {
      if (d.locked) return;
      if (seen.add(d.id)) out.add(d);
    }

    for (final year in yc.decks) {
      if (year.type != 'PACKAGE_DECK') {
        if (year.type == 'CARDS_DECK') add(year);
        continue;
      }
      final hasSub = year.children.any((c) => c.type == 'PACKAGE_DECK');
      final hasChapters = year.children.any((c) => c.type == 'CARDS_DECK');
      if (!hasSub && hasChapters) {
        add(year);
        continue;
      }
      for (final c in year.children) {
        if (c.type == 'CARDS_DECK' || c.children.isNotEmpty) add(c);
      }
    }
    return out;
  }

  List<Color> _accents() => [AppColor.greenColor, AppColor.infoColor, AppColor.warningColor, const Color(0xFF7C6FA8), AppColor.freshGreenColor];

  void _manage(DeckEntity s, Color color) {
    final info = OfflineStore.info(s.id);
    final mb = ((info?['bytes'] ?? 0) as int) / (1024 * 1024);
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
        decoration: BoxDecoration(color: AppColor.surfaceColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColor.borderColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 18),
            Row(children: [
              Icon(Icons.offline_pin_rounded, color: color, size: 26),
              const SizedBox(width: 10),
              Expanded(child: Text(s.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColor.textPrimary))),
            ]),
            const SizedBox(height: 6),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(OffUi.cardsMb((info?['cards'] ?? 0) as int, mb), style: TextStyle(fontSize: 12.5, color: AppColor.textSecondary)),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), side: BorderSide(color: AppColor.errorColor)),
                  onPressed: () async {
                    Get.back();
                    await OfflineStore.remove(s.id);
                  },
                  child: Text(OffUi.remove, style: TextStyle(color: AppColor.errorColor, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: () {
                    Get.back();
                    OfflineJobs.start(s);
                  },
                  child: Text(OffUi.update, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColor.textPrimary),
        title: Text(OffUi.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColor.textPrimary)),
      ),
      body: SafeArea(
        child: Obx(() {
          Get.find<YearsController>().decks.length; // rebuild when the subjects load
          return ValueListenableBuilder<int>(
            valueListenable: OfflineStore.changes,
            builder: (_, __, ___) => ValueListenableBuilder<int>(
              valueListenable: OfflineJobs.tick,
              builder: (_, __, ___) => _content(),
            ),
          );
        }),
      ),
    );
  }

  Widget _content() {
    final subjects = _subjects();
    final accents = _accents();
    var downloaded = 0;
    var bytes = 0;
    for (final s in subjects) {
      final info = OfflineStore.info(s.id);
      if (info != null) {
        downloaded++;
        bytes += (info['bytes'] ?? 0) as int;
      }
    }
    final job = OfflineJobs.current;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 40),
      children: [
        _Hero(anim: _anim, downloaded: downloaded, bytes: bytes),
        const SizedBox(height: 22),
        Text(OffUi.listTitle, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColor.textPrimary)),
        const SizedBox(height: 12),
        if (subjects.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(children: [
              Icon(Icons.cloud_off_rounded, size: 54, color: AppColor.disabledColor),
              const SizedBox(height: 12),
              Text(OffUi.emptyTitle, style: TextStyle(fontSize: 14, color: AppColor.textSecondary)),
            ]),
          ),
        for (var i = 0; i < subjects.length; i++)
          _Entrance(
            index: i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SubjectRow(
                subject: subjects[i],
                color: accents[i % accents.length],
                anim: _anim,
                job: job != null && job.subject.id == subjects[i].id ? job : null,
                info: OfflineStore.info(subjects[i].id),
                onTap: () {
                  final s = subjects[i];
                  if (OfflineStore.isDownloaded(s.id)) {
                    _manage(s, accents[i % accents.length]);
                  } else {
                    OfflineJobs.start(s);
                  }
                },
              ),
            ),
          ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColor.lightGreenColor.withOpacity(.6), borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Icon(Icons.lock_outline_rounded, size: 20, color: AppColor.darkGreenColor),
            const SizedBox(width: 10),
            Expanded(child: Text(OffUi.lockedNote, style: TextStyle(fontSize: 12.5, height: 1.5, color: AppColor.textPrimary))),
            const SizedBox(width: 8),
            TextButton(onPressed: () => Get.dialog(const InterCodeDialog()), child: Text(OffUi.enterCode, style: TextStyle(fontWeight: FontWeight.w800, color: AppColor.darkGreenColor))),
          ]),
        ),
      ],
    );
  }
}

/// Soft fade + slide-up when a row first appears, one after another.
class _Entrance extends StatelessWidget {
  final int index;
  final Widget child;
  const _Entrance({required this.index, required this.child});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 380 + math.min(index, 8) * 70),
        curve: Curves.easeOutCubic,
        builder: (_, v, c) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 22), child: c)),
        child: child,
      );
}

/// Gradient header: floating rings around a cloud, plus the two numbers that matter.
class _Hero extends StatelessWidget {
  final AnimationController anim;
  final int downloaded, bytes;
  const _Hero({required this.anim, required this.downloaded, required this.bytes});

  @override
  Widget build(BuildContext context) {
    final mb = bytes / (1024 * 1024);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColor.greenColor, AppColor.darkGreenColor]),
        boxShadow: [BoxShadow(color: AppColor.greenColor.withOpacity(.35), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(OffUi.heroTitle, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 6),
              Text(OffUi.heroSub, style: TextStyle(fontSize: 12.5, height: 1.5, color: Colors.white.withOpacity(.85))),
            ]),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 78,
            height: 78,
            child: AnimatedBuilder(
              animation: anim,
              builder: (_, __) => CustomPaint(painter: _HeroPainter(anim.value), child: const Center(child: Icon(Icons.cloud_download_rounded, color: Colors.white, size: 30))),
            ),
          ),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: _Stat(value: '$downloaded', label: OffUi.subjectsLabel)),
          const SizedBox(width: 12),
          Expanded(child: _Stat(value: mb < 1 && bytes > 0 ? '<1 MB' : '${mb.toStringAsFixed(mb >= 10 ? 0 : 1)} MB', label: OffUi.sizeLabel)),
        ]),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  const _Stat({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
        decoration: BoxDecoration(color: Colors.white.withOpacity(.16), borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(.82))),
        ]),
      );
}

class _HeroPainter extends CustomPainter {
  final double t;
  _HeroPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1.0;
      ring.color = Colors.white.withOpacity((1 - p) * .55);
      canvas.drawCircle(c, r * (.45 + .55 * p), ring);
    }
    final dot = Paint()..color = Colors.white;
    final a = t * 2 * math.pi;
    canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * (r * .86), 3, dot);
    canvas.drawCircle(c + Offset(math.cos(-a * 1.4 + 2), math.sin(-a * 1.4 + 2)) * (r * .66), 2.2, dot..color = Colors.white.withOpacity(.8));
  }

  @override
  bool shouldRepaint(_HeroPainter old) => old.t != t;
}

/// One subject: idle → download button, done → "available offline", running → orbit loader + liquid bar + time left.
class _SubjectRow extends StatelessWidget {
  final DeckEntity subject;
  final Color color;
  final AnimationController anim;
  final _Job? job;
  final Map<String, dynamic>? info;
  final VoidCallback onTap;
  const _SubjectRow({required this.subject, required this.color, required this.anim, required this.job, required this.info, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final running = job != null;
    final done = info != null;
    final mb = ((info?['bytes'] ?? 0) as int) / (1024 * 1024);
    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.surfaceColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: running ? color.withOpacity(.7) : AppColor.borderColor, width: running ? 1.4 : 1),
          boxShadow: [BoxShadow(color: color.withOpacity(running ? .22 : .06), blurRadius: running ? 22 : 12, offset: const Offset(0, 6))],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: running ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: running ? _running(context) : _idle(done, mb),
            ),
          ),
        ),
      ),
    );
  }

  Widget _idle(bool done, double mb) => Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withOpacity(.95), color.withOpacity(.6)]),
          ),
          child: Icon(done ? Icons.offline_pin_rounded : Icons.cloud_download_outlined, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(subject.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColor.textPrimary)),
            const SizedBox(height: 4),
            Text(done ? OffUi.cardsMb((info?['cards'] ?? 0) as int, mb) : OffUi.ready, style: TextStyle(fontSize: 12, color: done ? color : AppColor.textSecondary, fontWeight: done ? FontWeight.w700 : FontWeight.w500)),
          ]),
        ),
        const SizedBox(width: 8),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(.14)),
          child: Icon(done ? Icons.more_horiz_rounded : Icons.arrow_downward_rounded, color: color, size: 22),
        ),
      ]);

  Widget _running(BuildContext context) {
    final j = job!;
    return ValueListenableBuilder<double>(
      valueListenable: j.progress,
      builder: (_, p, __) {
        final secs = DateTime.now().difference(j.started).inMilliseconds / 1000.0;
        String eta;
        if (p < .04) {
          eta = OffUi.calculating;
        } else if (p > .97) {
          eta = OffUi.almost;
        } else {
          final left = (secs * (1 - p) / p).round();
          eta = OffUi.left(left < 60 ? OffUi.secs(math.max(5, (left / 5).ceil() * 5)) : OffUi.mins((left / 60).ceil()));
        }
        return Row(children: [
          _OrbitLoader(anim: anim, progress: p, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(subject.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColor.textPrimary)),
              const SizedBox(height: 3),
              Text('${OffUi.downloading} · ${(p * 100).round()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(height: 9),
              _LiquidBar(anim: anim, progress: p, color: color),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Text(eta, style: TextStyle(fontSize: 11.5, color: AppColor.textSecondary))),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => j.cancel.cancel(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(OffUi.cancel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColor.errorColor)),
                  ),
                ),
              ]),
            ]),
          ),
        ]);
      },
    );
  }
}

/// The loading spinner: a progress ring whose head glows, three comets on different orbits,
/// a breathing core and a slowly turning dashed ring, with the percentage in the middle.
class _OrbitLoader extends StatelessWidget {
  final AnimationController anim;
  final double progress;
  final Color color;
  const _OrbitLoader({required this.anim, required this.progress, required this.color});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 84,
        height: 84,
        child: AnimatedBuilder(
          animation: anim,
          builder: (_, __) => CustomPaint(
            painter: _OrbitPainter(anim.value, progress, color, AppColor.borderColor),
            child: Center(child: Text('${(progress * 100).round()}', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColor.textPrimary))),
          ),
        ),
      );
}

class _OrbitPainter extends CustomPainter {
  final double t, p;
  final Color color, track;
  _OrbitPainter(this.t, this.p, this.color, this.track);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 6;
    final rect = Rect.fromCircle(center: c, radius: r);

    // track + progress arc
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = track.withOpacity(.55));
    final sweep = 2 * math.pi * p.clamp(0.0, 1.0);
    if (sweep > 0.01) {
      canvas.drawArc(
          rect,
          -math.pi / 2,
          sweep,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round
            ..shader = SweepGradient(startAngle: -math.pi / 2, endAngle: -math.pi / 2 + sweep, colors: [color.withOpacity(.35), color], transform: const GradientRotation(0)).createShader(rect));
      final head = c + Offset(math.cos(-math.pi / 2 + sweep), math.sin(-math.pi / 2 + sweep)) * r;
      canvas.drawCircle(head, 7, Paint()..color = color.withOpacity(.45)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      canvas.drawCircle(head, 3.4, Paint()..color = Colors.white);
    }

    // slowly turning dashed ring
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = color.withOpacity(.45);
    final dr = r - 10;
    for (var i = 0; i < 14; i++) {
      final a = t * 2 * math.pi * -.5 + i * (2 * math.pi / 14);
      canvas.drawArc(Rect.fromCircle(center: c, radius: dr), a, .16, false, dash);
    }

    // three comets, each with a fading tail
    void comet(double radius, double speed, double phase, double size) {
      final base = t * 2 * math.pi * speed + phase;
      for (var k = 7; k >= 0; k--) {
        final a = base - k * .11 * (speed < 0 ? -1 : 1);
        final o = c + Offset(math.cos(a), math.sin(a)) * radius;
        canvas.drawCircle(o, size * (1 - k * .09), Paint()..color = color.withOpacity((1 - k / 8) * (k == 0 ? 1 : .55)));
      }
    }

    comet(r - 18, 2, 0, 2.8);
    comet(r - 24, -3, 2.1, 2.2);
    comet(r - 13, 1, 4.2, 2.5);

    // breathing core glow behind the number
    final pulse = 1 + .1 * math.sin(t * 2 * math.pi * 2);
    canvas.drawCircle(c, (r - 28) * pulse, Paint()..shader = RadialGradient(colors: [color.withOpacity(.22), color.withOpacity(0)]).createShader(Rect.fromCircle(center: c, radius: (r - 18) * pulse)));
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.t != t || old.p != p || old.color != color;
}

/// Progress bar that looks like liquid: gradient fill with a sheen that keeps sliding through it.
class _LiquidBar extends StatelessWidget {
  final AnimationController anim;
  final double progress;
  final Color color;
  const _LiquidBar({required this.anim, required this.progress, required this.color});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 10,
          color: AppColor.borderColor.withOpacity(.6),
          alignment: AlignmentDirectional.centerStart,
          child: AnimatedBuilder(
            animation: anim,
            builder: (_, __) => FractionallySizedBox(
              widthFactor: progress.clamp(0.02, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment(-1 + anim.value * 3, 0),
                    end: Alignment(0 + anim.value * 3, 0),
                    colors: [color.withOpacity(.8), Colors.white.withOpacity(.85), color],
                    stops: const [0, .5, 1],
                    tileMode: TileMode.repeated,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
