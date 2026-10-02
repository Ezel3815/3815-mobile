import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/main.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/services/streak_widget_service.dart';

/// One-time sheet shown the first time a user reaches Home (i.e. right after
/// registering), asking them to add the streak widget to the home screen.
class StreakWidgetPrompt {
  static const _shownKey = 'streak_widget_prompt_shown';

  static Future<void> maybeShow() async {
    final svc = StreakWidgetService.instance;
    if (!svc.supported || sharedPref.getBool(_shownKey) == true) return;
    await Future.delayed(const Duration(milliseconds: 700));
    if (Get.context == null) return;
    await sharedPref.setBool(_shownKey, true);
    if (await svc.isInstalled) return;
    await Get.bottomSheet(
      const _PromptSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _PromptSheet extends StatelessWidget {
  const _PromptSheet();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        decoration: BoxDecoration(
          color: AppColor.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('lib/assests/brand/mozaik_emblem.png', height: 96),
              const SizedBox(height: 16),
              const Text('لا تفقد سلسلة إنجازاتك!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColor.darkGreenColor)),
              const SizedBox(height: 10),
              Text(
                  'أضف ودجت Mozaik إلى شاشتك الرئيسية لتتابع سلسلتك وتتذكر المذاكرة كل يوم.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: AppColor.textSecondary.withOpacity(0.95))),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.darkGreenColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: () async {
                    final ok = await StreakWidgetService.instance.requestPin();
                    Get.back();
                    if (!ok) {
                      Get.snackbar('أضف الودجت يدويًا',
                          'اضغط مطولًا على الشاشة الرئيسية ← الودجتات ← Mozaik',
                          duration: const Duration(seconds: 6));
                    }
                  },
                  child: const Text('أضف الودجت',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ),
              ),
              TextButton(
                onPressed: Get.back,
                child: Text('ليس الآن',
                    style: TextStyle(
                        fontSize: 15,
                        color: AppColor.textSecondary.withOpacity(0.9))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
