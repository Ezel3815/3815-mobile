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
        // Show the tick immediately, refresh the decks in the background.
        success.value = true;
        yearsController.getAllDeck().catchError((_) {});
        await Future.delayed(const Duration(milliseconds: 700));
        if (Get.isDialogOpen == true) Get.back();
        reset();
      }
      loading = false;
    }
  }
}
