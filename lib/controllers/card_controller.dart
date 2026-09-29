import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/controllers/add_card_controller.dart';
import 'package:upgrade/controllers/api_controller.dart';
import 'package:upgrade/controllers/years_controller.dart';
import 'package:upgrade/entity/card_entity.dart';
import 'package:upgrade/entity/deck_entity.dart';
import 'package:upgrade/main.dart';
import 'package:upgrade/mapper/app_mapper.dart';
import 'package:upgrade/widgets/app_snack_bar.dart';

class CardController extends GetxController {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final formKey = GlobalKey<FormState>();
  final editDeckController = TextEditingController();

  late DeckEntity deck;
  final RxList<CardEntity> _cards = <CardEntity>[].obs;
  final RxBool _loading = false.obs;
  final RxBool _loadingEdit = false.obs;

  bool get loading => _loading.value;

  bool get loadingEdit => _loadingEdit.value;

  List<CardEntity> get cards => _cards;

  set loading(value) => _loading.value = value;

  set loadingEdit(value) => _loadingEdit.value = value;
  set cards(List<CardEntity> value) => _cards.value = value;

  int _loadSeq = 0;

  /// Loads this deck's cards. A successful response with zero cards is a
  /// legitimate empty state; a FAILED request (timeout etc.) is not — it
  /// leaves the existing cards untouched instead of wiping them.
  /// [background] refreshes (after a study answer) never show a spinner or
  /// an error snackbar.
  Future<void> getCard({bool background = false}) async {
    final seq = ++_loadSeq;
    if (!background && cards.isEmpty) loading = true;
    try {
      final data = await ApiController.fetchCards(deck.id);
      // A newer load started meanwhile — let it win.
      if (seq != _loadSeq) return;
      // fetchCards() falls back to the local cache on failure and records
      // the reason in lastCardsError. A failed request must never replace
      // cards we already have.
      final failed = data == null || ApiController.lastCardsError != null;
      if (failed && cards.isNotEmpty) return;
      if (data == null) {
        if (!background) {
          showSnackBarWidget(
              message: ApiController.lastCardsError ?? 'خطأ في الاتصال');
        }
        return;
      }
      List<CardEntity> pick(bool Function(String? first) test) =>
          data.where((element) {
            final answer =
                element.answers?.map((e) => e.toDomain()).toList() ?? [];
            return test(answer.isEmpty ? null : answer.first.answer);
          }).toList();

      final easyCard = pick((a) => a == "EASY" || a == "GOOD");
      final againCard = pick((a) => a == "AGAIN");
      final hardCard = pick((a) => a == "HARD");
      final emptyCard = pick((a) => a == null || a == "NONE");
      // Build the full list first, then swap it in once — never clear first.
      cards = [...emptyCard, ...hardCard, ...againCard, ...easyCard];
    } finally {
      if (seq == _loadSeq) loading = false;
    }
  }

  editDeck() async {
    if (formKey.currentState!.validate()) {
      loadingEdit = true;
      final response =
          await ApiController.editDeck(editDeckController.text, deck.id);
      if (response != null) {
        if (Get.isDialogOpen == true) {
          Get.back();
        }
        deck = response;
        Get.find<YearsController>().getAllDeck();
      }
      loadingEdit = false;
    }
  }

  deleteDeck() async {
    Get.back();
    await ApiController.deleteDeck(deck.id);
    Get.until(
      (route) {
        return Get.currentRoute == AppRoutes.mainRoute;
      },
    );
    Get.find<YearsController>().getAllDeck();
  }

  @override
  void onInit() async {
    deck = Get.arguments;
    await getCard();
    super.onInit();
  }
}
