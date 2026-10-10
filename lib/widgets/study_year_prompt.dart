import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/controllers/api_controller.dart';
import 'package:upgrade/main.dart';
import 'package:upgrade/resources.dart';

/// Accounts created before the year option existed have no study year, so they
/// can't join Mossad. Ask once (until they answer): one tap, nothing is deleted
/// or reset. "Later" only hides it for this launch.
class StudyYearPrompt {
  static const _knownKey = 'study_year_known';
  static bool _askedThisLaunch = false;

  /// Opens the picker on demand (e.g. from the Mossad tab).
  static Future<void> choose() async {
    await Get.dialog(const _YearDialog(), barrierDismissible: true);
  }

  static Future<void> maybeShow() async {
    if (_askedThisLaunch || sharedPref.getString(_knownKey) != null) return;
    _askedThisLaunch = true;
    final year = await ApiController.getStudyYear();
    if (year == null) return; // offline: try again next launch
    if (year.isNotEmpty) {
      await sharedPref.setString(_knownKey, year);
      return;
    }
    await Future.delayed(const Duration(milliseconds: 900));
    if (Get.context == null) return;
    await Get.dialog(const _YearDialog(), barrierDismissible: false);
  }
}

class _YearDialog extends StatefulWidget {
  const _YearDialog();

  @override
  State<_YearDialog> createState() => _YearDialogState();
}

class _YearDialogState extends State<_YearDialog> {
  bool _busy = false;

  Future<void> _choose(String year) async {
    setState(() => _busy = true);
    final ok = await ApiController.setStudyYear(year);
    if (ok) {
      await sharedPref.setString(StudyYearPrompt._knownKey, year);
      if (mounted) Get.back();
    } else if (mounted) {
      setState(() => _busy = false);
      Get.snackbar("تعذّر الحفظ", "تحقق من الاتصال وحاول مرة أخرى");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: AppColor.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text("ما سنتك الدراسية؟",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: const Text(
          "اختر سنتك لتظهر في الترتيب المناسب. طلاب السنة التحضيرية يدخلون مسابقة Mossad.",
          style: TextStyle(height: 1.5, fontSize: 13.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsOverflowDirection: VerticalDirection.down,
        actions: _busy
            ? [const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator())]
            : [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _choose('PREPARATORY'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.darkGreenColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text("السنة التحضيرية"),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _choose('OTHER'),
                    child: const Text("سنة أخرى"),
                  ),
                ),
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text("لاحقًا"),
                ),
              ],
      ),
    );
  }
}
