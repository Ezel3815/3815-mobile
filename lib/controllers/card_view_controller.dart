import 'package:upgrade/controllers/progress_controller.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/controllers/api_controller.dart';
import 'package:upgrade/controllers/card_controller.dart';
import 'package:upgrade/controllers/years_controller.dart';
import 'package:upgrade/controllers/mosaic_controller.dart';
import 'package:upgrade/entity/card_entity.dart';
import 'package:upgrade/entity/shape_creator_entity.dart';
import 'package:upgrade/extension.dart';
import 'package:upgrade/main.dart';
import 'package:upgrade/mapper/app_mapper.dart';
import 'package:upgrade/models/shape_creator_model.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/widgets/celebration.dart';
import 'package:upgrade/services/notification_service.dart';

class CardViewController extends GetxController {
  late bool isView;

  // Session tracking — additive only, does not change the existing
  // grading buttons, the answerCard API call, or OCCLUSION logic.
  DateTime _sessionStart = DateTime.now();
  int sessionCorrect = 0;
  int sessionWrong = 0;
  final List<CardEntity> sessionMistakes = [];

  void _recordAnswer(String answer, CardEntity card) {
    if (answer == "GOOD" || answer == "EASY") {
      sessionCorrect += 1;
    } else if (answer == "AGAIN" || answer == "HARD") {
      sessionWrong += 1;
      if (!sessionMistakes.any((c) => c.id == card.id)) {
        sessionMistakes.add(card);
      }
    }
  }

  void _goToSessionResult() {
    NotificationService.instance.markStudiedToday();
    Get.offNamed(
      AppRoutes.sessionResultRoute,
      arguments: {
        'correct': sessionCorrect,
        'wrong': sessionWrong,
        'minutes': DateTime.now().difference(_sessionStart).inMinutes,
        'mistakes': sessionMistakes,
        'isView': isView,
      },
    );
  }
  final Rx<ShapeCreatorEntity> _data = ShapeCreatorModel().toDomain().obs;
  late PageController pageController;

  final RxBool _showAnswer = false.obs;
  final RxBool _toggleMask = false.obs;
  final RxInt _currentIndex = 0.obs;
  final RxInt _pageViewIndex = 0.obs;
  final RxList<CardEntity> _cards = <CardEntity>[].obs;

  bool get showAnswer => _showAnswer.value;

  bool get toggleMask => _toggleMask.value;

  int get currentIndex => _currentIndex.value;

  int get pageViewIndex => _pageViewIndex.value;

  List<CardEntity> get cards => _cards;

  ShapeCreatorEntity get data => _data.value;

  set showAnswer(value) => _showAnswer.value = value;

  set toggleMask(value) => _toggleMask.value = value;

  set currentIndex(value) => _currentIndex.value = value;

  set data(ShapeCreatorEntity value) => _data.value = value;

  set cards(List<CardEntity> value) => _cards.value = value;

  set pageViewIndex(value) => _pageViewIndex.value = value;

  toggleAnswer() {
    showAnswer = !showAnswer;
    if (cards[pageViewIndex].type == "OCCLUSION" && isView) {
      changeToggleMask();
    }
    if (cards[pageViewIndex].type == "OCCLUSION") {
      onTapOnShowAnswer();
    }
  }

  changeToggleMask() {
    toggleMask = !toggleMask;

    if (cards[pageViewIndex].type == "OCCLUSION") {
      for (var element in data.shapes) {
        element.isShow = !toggleMask;
      }

      _data.refresh();
    }
  }

  getData() {
    try {
      return jsonDecode(cards[pageViewIndex].data);
    } catch (_) {
      // Corrupt/legacy data must not crash the card (same fix as getOCCData).
      return {};
    }
  }

  String getFrontText() {
    if (getData()['front'] != null && getData()['front']['text'] != null) {
      String text = getData()['front']['text'].toString();

      if (cards[pageViewIndex].type == "BASIC" ||
          cards[pageViewIndex].type == "OCCLUSION") {
        return text;
      }

      RegExp regex = RegExp(r"\{(.*?)\}");
      return text.replaceAllMapped(regex, (match) {
        String insideText = match.group(1) ?? "";

        if (showAnswer) {
          String color =
              AppColor.greenColor.value.toRadixString(16).substring(2);
          return '<span style="color: #$color;">$insideText</span>';
        } else {
          return "{....}";
        }
      });
    }
    return '';
  }

  double getFrontSize() {
    if (getData()['front'] != null && getData()['front']['size'] != null) {
      return (getData()['front']['size'] as num).toDouble();
    }
    return 14.0;
  }

  String getFrontAlign() {
    if (getData()['front'] != null && getData()['front']['align'] != null) {
      return getData()['front']['align'] == "center"
          ? 'center'
          : getData()['front']['align'] == "start"
              ? 'left'
              : 'right';
    }
    return 'center';
  }

  String getBackText() {
    if (getData()['back'] != null && getData()['back']['text'] != null) {
      return getData()['back']['text'];
    }
    return '';
  }

  double getBackSize() {
    if (getData()['back'] != null && getData()['back']['size'] != null) {
      return (getData()['back']['size'] as num).toDouble();
    }
    return 14.0;
  }

  String getBackAlign() {
    if (getData()['back'] != null && getData()['back']['align'] != null) {
      return getData()['back']['align'] == "center"
          ? "center"
          : getData()['back']['align'] == "start"
              ? "left"
              : "right";
    }
    return "center";
  }

  String getCommentText() {
    if (getData()['comment'] != null && getData()['comment']['text'] != null) {
      return getData()['comment']['text'];
    }
    return '';
  }

  double getCommentSize() {
    if (getData()['comment'] != null && getData()['comment']['size'] != null) {
      return (getData()['comment']['size'] as num).toDouble();
    }
    return 14.0;
  }

  String getCommentAlign() {
    if (getData()['comment'] != null && getData()['comment']['align'] != null) {
      return getData()['comment']['align'] == "center"
          ? "center"
          : getData()['comment']['align'] == "start"
              ? "left"
              : "right";
    }
    return "center";
  }

  getOCCData({bool resetIndex = true}) {
    if (resetIndex) currentIndex = 0;
    try {
      final shapes = getData()['shapes'];
      if (shapes != null) {
        data = ShapeCreatorModel.fromJson(jsonDecode(shapes)).toDomain();
      } else {
        data = ShapeCreatorModel().toDomain();
      }
    } catch (_) {
      // Corrupt/legacy data (e.g. missing image) must not freeze the card.
      data = ShapeCreatorModel().toDomain();
    }
  }

  onTapOnStatusButton(String answer) async {
    _recordAnswer(answer, cards[pageViewIndex]);
    Get.find<YearsController>().rememberSubjectForDeck(cards[pageViewIndex].deckId);

    if (cards[pageViewIndex].type == "OCCLUSION") {
      if(answer == "AGAIN") {
        showAnswer = false;
        getOCCData(resetIndex: false);
        return;
      }
      for (var element in data.shapes) {
        element.isShow = true;
      }
      if (currentIndex < data.shapes.length - 1) {
        showAnswer = false;
        currentIndex += 1;
      } else {
        if (pageViewIndex < cards.length - 1) {
          showAnswer = false;
          await pageController.animateToPage(
            pageViewIndex + 1,
            curve: Curves.linear,
            duration: const Duration(milliseconds: 300),
          );
          getOCCData();

          _cards.refresh();
        } else {
          _goToSessionResult();
        }
      }
    } else {
      if(answer == "AGAIN") {
        showAnswer = false;
        return;
      }
      if (pageViewIndex < cards.length - 1) {
        showAnswer = false;
        await pageController.animateToPage(
          pageViewIndex + 1,
          curve: Curves.linear,
          duration: const Duration(milliseconds: 300),
        );
        if (cards[pageViewIndex].type == "OCCLUSION") {
          getOCCData();
        }
      } else {
        _goToSessionResult();
      }
    }
    final result = await ApiController.answerCard(
        cardID: cards[pageViewIndex].id, answer: answer);
    if (result != null) showCelebration(result);
    // Queued (not shown inline here) because the LAST card's answer resolves
    // AFTER _goToSessionResult() has already navigated away. The mosaic
    // screen/result screen read this reactively, so the piece is never lost
    // regardless of that ordering, and it's already persisted server-side
    // either way.
    if (result?.mosaic != null) {
      final total = sessionCorrect + sessionWrong;
      final accuracy = total == 0 ? 0 : ((sessionCorrect / total) * 100).round();
      (Get.isRegistered<MosaicController>()
              ? Get.find<MosaicController>()
              : Get.put(MosaicController()))
          .queueDailyReward(result!.mosaic, cardsStudied: total, accuracyPercent: accuracy);
    }
    if (Get.isRegistered<CardController>()) {
      Get.find<CardController>().getCard();
    }
    Get.find<YearsController>().getAllDeck();
    if (Get.isRegistered<ProgressController>()) {
      Get.find<ProgressController>().loadQuests();
    }
  }

  bool isArabic(String text) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(text);
  }

  onTapOnShape(index) {
    data.shapes[index].isShow = !data.shapes[index].isShow;
    _data.refresh();
  }

  onTapOnShowAnswer() {
    if (currentIndex < 0 || currentIndex >= data.shapes.length) return;
    data.shapes[currentIndex].isShow = false;
    _data.refresh();
  }

  onChangePageViewIndex(value) {
    pageViewIndex = value;
  }

  @override
  void onInit() {
    final List<CardEntity> arg = Get.arguments['cards'];
    for (var element in arg) {
      cards.add(element);
    }
    isView = Get.arguments['isView'];
    pageViewIndex = Get.arguments['initalIndex'];
    pageController = PageController(initialPage: pageViewIndex);
    if (cards[pageViewIndex].type == "OCCLUSION") {
      getOCCData();
    }

    super.onInit();
  }
}
