import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/di.dart';
import 'package:upgrade/entity/deck_entity.dart';
import 'package:upgrade/network_info.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/widgets/app_snack_bar.dart';
import 'offline_store.dart';

class OfflineStr {
  static bool get _en => Get.locale?.languageCode == 'en';
  static String _t(String ar, String en) => _en ? en : ar;
  static String get download => _t('تحميل للاستخدام بدون إنترنت', 'Download for offline use');
  static String get downloading => _t('جارٍ تحميل المادة…', 'Downloading material…');
  static String get keepOpen => _t('أبقِ التطبيق مفتوحًا حتى ينتهي التحميل', 'Keep the app open until it finishes');
  static String get cancel => _t('إلغاء', 'Cancel');
  static String get noInternet => _t('تحتاج إلى اتصال بالإنترنت للتحميل', 'You need an internet connection to download');
  static String get done => _t('تم التحميل. يمكنك الدراسة بدون إنترنت', 'Downloaded. You can study offline');
  static String partial(int n) => _t('تم التحميل، لكن تعذّر تحميل $n ملف. حاول التحديث لاحقًا', 'Downloaded, but $n files failed. Try Update later');
  static String get failed => _t('تعذّر التحميل، حاول مرة أخرى', 'Download failed, please try again');
  static String get downloaded => _t('تم تحميلها للاستخدام بدون إنترنت', 'Available offline');
  static String cardsMb(int c, double mb) => _t('$c بطاقة · ${mb.toStringAsFixed(1)} ميغابايت', '$c cards · ${mb.toStringAsFixed(1)} MB');
  static String get update => _t('تحديث', 'Update');
  static String get remove => _t('حذف التحميل', 'Remove download');
}

/// Small download / "available offline" icon for a subject card.
class OfflineButton extends StatelessWidget {
  final DeckEntity subject;
  final Color color;
  const OfflineButton({super.key, required this.subject, required this.color});

  Future<void> _start() async {
    if (!await instance<NetworkInfo>().isConnected) {
      showSnackBarWidget(message: OfflineStr.noInternet);
      return;
    }
    final progress = ValueNotifier<double>(0);
    final cancel = CancelToken();
    Get.dialog(_ProgressDialog(progress: progress, cancel: cancel, color: color), barrierDismissible: false);
    String? msg;
    try {
      final failed = await OfflineStore.download(subject, onProgress: (p) => progress.value = p, cancel: cancel);
      msg = failed == 0 ? OfflineStr.done : OfflineStr.partial(failed);
    } catch (e) {
      msg = cancel.isCancelled ? null : OfflineStr.failed;
    }
    if (Get.isDialogOpen == true) Get.back();
    if (msg != null) showSnackBarWidget(message: msg);
  }

  void _manage() {
    final info = OfflineStore.info(subject.id);
    final mb = ((info?['bytes'] ?? 0) as int) / (1024 * 1024);
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(color: AppColor.surfaceColor, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Icon(Icons.offline_pin, color: color),
              const SizedBox(width: 10),
              Expanded(child: Text(OfflineStr.downloaded, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColor.textPrimary))),
            ]),
            const SizedBox(height: 6),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(OfflineStr.cardsMb((info?['cards'] ?? 0) as int, mb), style: const TextStyle(fontSize: 12, color: AppColor.textSecondary)),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    Get.back();
                    await OfflineStore.remove(subject.id);
                  },
                  child: Text(OfflineStr.remove),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
                  onPressed: () {
                    Get.back();
                    _start();
                  },
                  child: Text(OfflineStr.update),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: OfflineStore.changes,
        builder: (_, __, ___) {
          final on = OfflineStore.isDownloaded(subject.id);
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: on ? _manage : _start,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(on ? Icons.offline_pin : Icons.download_for_offline_outlined, size: 22, color: on ? color : AppColor.textSecondary),
            ),
          );
        },
      );
}

class _ProgressDialog extends StatelessWidget {
  final ValueNotifier<double> progress;
  final CancelToken cancel;
  final Color color;
  const _ProgressDialog({required this.progress, required this.cancel, required this.color});
  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: AppColor.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (_, p, __) => Column(mainAxisSize: MainAxisSize.min, children: [
              Text(OfflineStr.downloading, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColor.textPrimary)),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(value: p, minHeight: 7, backgroundColor: AppColor.scaffoldBackgroundColor, valueColor: AlwaysStoppedAnimation(color)),
              ),
              const SizedBox(height: 8),
              Text('${(p * 100).round()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(height: 6),
              Text(OfflineStr.keepOpen, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: AppColor.textSecondary)),
              const SizedBox(height: 10),
              TextButton(onPressed: () => cancel.cancel(), child: Text(OfflineStr.cancel)),
            ]),
          ),
        ),
      );
}
