import 'package:upgrade/controllers/progress_controller.dart';
import 'package:upgrade/services/streak_widget_service.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/controllers/api_controller.dart';
import 'package:upgrade/controllers/card_controller.dart';
import 'package:upgrade/controllers/years_controller.dart';
import 'package:upgrade/controllers/mosaic_controller.dart';
import 'package:upgrade/entity/card_entity.dart';
import 'package:upgrade/entity/mosaic_entity.dart';
import 'package:upgrade/controllers/session_rewards.dart';
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

  /// Every mosaic piece earned by ANY answer during this session, collected
  /// silently — never shown to the user until the session actually ends.
  /// The backend can release pieces incrementally (one per daily-step
  /// crossed), so a single session's reward can arrive across several
  /// answerCard() responses; the ceremony must represent the whole session
  /// as one moment, not each individual crossing.
  /// Everything the server awarded this session (streak + mosaic pieces),
  /// handed to the result screen, which reads it once the answers settle.
  final SessionRewards _rewards = SessionRewards();

  /// Set the first time _finishSession() runs, so a rapid double-tap on the
  /// last card can't queue the reward or navigate twice. Lives on this
  /// controller instance, so a new study session (a new controller) starts
  /// with it false again.
  bool _sessionFinished = false;

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
    StreakWidgetService.instance.sync(streak: _rewards.streak, studiedToday: true);
    _rewards.settled = _answerChain;
    Get.offNamed(
      AppRoutes.sessionResultRoute,
      arguments: {
        'correct': sessionCorrect,
        'wrong': sessionWrong,
        'minutes': DateTime.now().difference(_sessionStart).inMinutes,
        'mistakes': sessionMistakes,
        'isView': isView,
        'rewards': _rewards,
      },
    );
  }

  /// Submits one card's answer and folds its effects into the running
  /// session state. Never navigates — callers decide when the session ends.
  /// Safe to call without awaiting for any card except the session's last
  /// one, where the caller MUST await this before flushing/navigating so
  /// that card's mosaic pieces (if any) are never lost to the navigation
  /// race described below.
  Future<void> _submitAnswer(String answer, CardEntity card) {
    // One answer request at a time: concurrent answers starve the small DB
    // pool and race the server's once-a-day streak update (which is what
    // produced the "Streak saved!" spam and the slow finish).
    final next = _answerChain.then((_) => _sendAnswer(answer, card));
    _answerChain = next.catchError((_) {});
    return next;
  }

  Future<void> _answerChain = Future<void>.value();

  Future<void> _sendAnswer(String answer, CardEntity card) async {
    try {
      final result =
          await ApiController.answerCard(cardID: card.id, answer: answer);
      if (result != null) showCelebration(result);
      if (result != null) _rewards.answered = true;
      if (result != null && result.streakSaved && result.newStreak != null) {
        _rewards.streak = result.newStreak;
      }
      if (result?.mosaic?.newPieces.isNotEmpty ?? false) {
        _rewards.pieces.addAll(result!.mosaic!.newPieces);
      }
    } catch (_) {
      // Never let an answer failure break the study flow.
    }
  }

  /// Once per session (not once per card): refresh the lists that changed.
  void _refreshAfterSession() {
    if (Get.isRegistered<CardController>()) {
      Get.find<CardController>().getCard().catchError((_) {});
    }
    if (Get.isRegistered<YearsController>()) {
      Get.find<YearsController>().getAllDeck().catchError((_) {});
    }
    if (Get.isRegistered<ProgressController>()) {
      Get.find<ProgressController>().loadQuests().catchError((_) {});
    }
  }

  /// Waits briefly for the last answer, never longer than a few seconds, so
  /// the Session Complete screen opens promptly even on a slow server. Anything
  /// still in flight is picked up by the result screen via SessionRewards.settled.
  Future<void> _awaitFinalAnswer(String answer, CardEntity card) async {
    await _submitAnswer(answer, card)
        .timeout(const Duration(seconds: 3), onTimeout: () {});
  }

  /// Navigates to the session result screen, which builds the ONE daily
  /// reward batch from SessionRewards once the answers have settled.
  /// This is called ONLY after the final card's _submitAnswer has already
  /// been awaited, so it can never fire before that card's pieces (if any)
  /// have been collected — that ordering is what actually prevents the
  /// race, rather than any timing/delay workaround.
  void _finishSession() {
    if (_sessionFinished) return;
    _sessionFinished = true;
    _goToSessionResult();
    _refreshAfterSession();
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
    final answeredCard = cards[pageViewIndex];

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
        unawaited(_submitAnswer(answer, answeredCard));
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
          unawaited(_submitAnswer(answer, answeredCard));
        } else {
          // Last card of the session: this answer's mosaic pieces (if any)
          // must be collected BEFORE we flush and navigate, or they'd be
          // lost to the exact race this restructuring exists to prevent.
          await _awaitFinalAnswer(answer, answeredCard);
          _finishSession();
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
        unawaited(_submitAnswer(answer, answeredCard));
      } else {
        // Same reasoning as above: await the final answer before finishing.
        await _awaitFinalAnswer(answer, answeredCard);
        _finishSession();
      }
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
