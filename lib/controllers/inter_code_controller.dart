import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:upgrade/controllers/api_controller.dart';
import 'package:upgrade/controllers/years_controller.dart';

class InterCodeController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final codeController = TextEditingController();
  final yearsController = Get.find<YearsController>();

  final RxBool _loading = false.obs;
  final RxBool success = false.obs;

  bool get loading => _loading.value;

  set loading(value) => _loading.value = value;

  /// Resets the dialog so it opens clean every time.
  void reset() {
    success.value = false;
    loading = false;
    codeController.clear();
  }

  enterCode() async {
    if (formKey.currentState!.validate()) {
      loading = true;
      final ok = await ApiController.enterCode(codeController.text.trim());
      if (ok) {
        // Reload the decks BEFORE closing so the new subject is already
        // there when the user lands back on the app (no restart needed).
        // Always refresh, whether or not the dialog is still open.
        try {
          await yearsController.getAllDeck();
        } catch (_) {}
        success.value = true; // show the tick
        await Future.delayed(const Duration(milliseconds: 1200));
        if (Get.isDialogOpen == true) Get.back();
        reset();
      }
      loading = false;
    }
  }
}
