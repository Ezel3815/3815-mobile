import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:upgrade/main.dart';
import 'package:upgrade/resources.dart';

/// MOZAIK // NOCTURNE (night mode). Persisted; light mode is untouched.
/// [AppColor.night] flips the palette, [Get.forceAppUpdate] repaints every
/// screen, and the overlay in nocturne_overlay.dart covers the swap.
class NocturneController extends GetxController {
  static const _key = "night_mode";

  final RxBool isNight = false.obs;

  /// 0 = idle, 1 = entering Nocturne (full sequence), 2 = back to light.
  final RxInt transition = 0.obs;

  @override
  void onInit() {
    isNight.value = sharedPref.getBool(_key) ?? false;
    AppColor.night = isNight.value;
    super.onInit();
  }

  static void syncSystemUi() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: AppColor.scaffoldBackgroundColor,
      systemNavigationBarIconBrightness:
          AppColor.night ? Brightness.light : Brightness.dark,
      statusBarIconBrightness:
          AppColor.night ? Brightness.light : Brightness.dark,
    ));
  }

  void toggle() => setNight(!isNight.value);

  void setNight(bool v) {
    if (v == isNight.value || transition.value != 0) return;
    transition.value = v ? 1 : 2;
    // Failsafe: the overlay can never trap the user or skip the switch.
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (transition.value != 0) {
        if (isNight.value != v) apply(v);
        done();
      }
    });
  }

  /// Called by the overlay while the screen is fully covered.
  void apply(bool v) {
    AppColor.night = v;
    isNight.value = v;
    sharedPref.setBool(_key, v);
    syncSystemUi();
    Get.forceAppUpdate();
  }

  void done() => transition.value = 0;
}
