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

  bool _fetching = false;
  bool _fetchQueued = false;

  Future<void> getCard() async {
    if (_fetching) {
      _fetchQueued = true;
      return;
    }
    _fetching = true;
    try {
      do {
        _fetchQueued = false;
        await _loadCards();
      } while (_fetchQueued);
    } finally {
      _fetching = false;
    }
  }

  Future<void> _loadCards() async {
    final hadCards = cards.isNotEmpty;
    if (!hadCards) loading = true;
    // null = the request FAILED (not "deck has no cards").
    final data = await ApiController.fetchCards(deck.id);
    final error = ApiController.lastCardsError;
    if (error != null && !hadCards) showSnackBarWidget(message: error);
    // Failed request (or failed-with-nothing-cached): never turn it into an
    // empty list, and never wipe cards that are already showing.
    if (data == null || (error != null && hadCards)) {
      loading = false;
      return;
    }
    cards.clear();
    final easyCard = data.where((element) {
      final answer = element.answers?.map((e) => e.toDomain()).toList() ?? [];
      if (answer.isNotEmpty) {
        if (answer.first.answer == "EASY" || answer.first.answer == "GOOD") {
          return true;
        }
      }
      return false;
    }).toList();
    final againCard = data.where((element) {
      final answer = element.answers?.map((e) => e.toDomain()).toList() ?? [];
      if (answer.isNotEmpty) {
        if (answer.first.answer == "AGAIN") {
          return true;
        }
      }
      return false;
    }).toList();
    final hardCard = data.where((element) {
      final answer = element.answers?.map((e) => e.toDomain()).toList() ?? [];
      if (answer.isNotEmpty) {
        if (answer.first.answer == "HARD") {
          return true;
        }
      }
      return false;
    }).toList();
    final emptyCard = data.where((element) {
      final answer = element.answers?.map((e) => e.toDomain()).toList() ?? [];
      if (answer.isNotEmpty) {
        if (answer.first.answer == "NONE") {
          return true;
        }
      } else {
        return true;
      }
      return false;
    }).toList();
    cards.addAll(emptyCard);
    cards.addAll(hardCard);
    cards.addAll(againCard);
    cards.addAll(easyCard);
    loading = false;
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
