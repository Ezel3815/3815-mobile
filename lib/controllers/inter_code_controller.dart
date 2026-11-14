import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:upgrade/controllers/api_controller.dart';
import 'package:upgrade/controllers/years_controller.dart';
import 'package:upgrade/entity/deck_entity.dart';
import 'package:upgrade/main.dart' show sharedPref;
import 'package:upgrade/strings.dart';

class InterCodeController extends GetxController {
  static const _redeemedKey = 'redeemed_codes';

  final formKey = GlobalKey<FormState>();
  final codeController = TextEditingController();
  final yearsController = Get.find<YearsController>();

  final RxBool _loading = false.obs;
  final RxBool success = false.obs;

  /// Why the last attempt failed (shown inside the dialog). Empty = no error.
  final RxString errorText = ''.obs;

  bool get loading => _loading.value;

  set loading(value) => _loading.value = value;

  /// Resets the dialog so it opens clean every time.
  void reset() {
    success.value = false;
    loading = false;
    errorText.value = '';
    codeController.clear();
  }

  Set<String> _redeemed() => (sharedPref.getStringList(_redeemedKey) ?? <String>[]).toSet();

  void _remember(String code) {
    final all = _redeemed()..add(code);
    sharedPref.setStringList(_redeemedKey, all.toList());
  }

  int _countDecks(List<DeckEntity> nodes) =>
      nodes.fold(0, (a, d) => a + 1 + _countDecks(d.children));

  /// Waits until the app really has the newly unlocked subjects: reloads the decks
  /// (retrying when the connection fails or nothing new shows up yet), then the rest of the data.
  Future<void> _refreshApp() async {
    final before = _countDecks(yearsController.decks);
    for (var attempt = 0; attempt < 3; attempt++) {
      await yearsController.getAllDeck(silent: true);
      final failed = ApiController.lastDecksFailed || ApiController.lastMyDecksFailed;
      final changed = _countDecks(yearsController.decks) != before;
      if (!failed && changed) break;
      if (attempt < 2) await Future.delayed(const Duration(milliseconds: 1200));
    }
    await Future.wait<void>([
      yearsController.getMyProfile().catchError((_) {}),
      yearsController.getDailyMissions().catchError((_) {}),
      yearsController.getActivityFeed().catchError((_) {}),
    ]);
    // Poor connection: the code IS activated, so keep trying quietly in the background.
    if (ApiController.lastDecksFailed || ApiController.lastMyDecksFailed) {
      Future.delayed(const Duration(seconds: 6),
          () => yearsController.getAllDeck(silent: true).catchError((_) {}));
    }
  }

  enterCode() async {
    if (loading) return;
    if (!formKey.currentState!.validate()) return;
    final code = codeController.text.trim();
    errorText.value = '';

    // Same code typed again on this phone: no need to ask the server.
    if (_redeemed().contains(code)) {
      errorText.value = AppStrings.codeAlreadyEntered;
      return;
    }

    loading = true; // the dialog shows a spinner until everything is really ready
    try {
      final error = await ApiController.enterCode(code);
      if (error != null) {
        if (error == AppStrings.codeAlreadyEntered) _remember(code);
        errorText.value = error;
        return;
      }
      _remember(code);
      await _refreshApp();
      success.value = true; // tick only now: the subject is already on screen
      await Future.delayed(const Duration(milliseconds: 900));
      if (Get.isDialogOpen == true) Get.back();
      reset();
    } finally {
      loading = false;
    }
  }
}
