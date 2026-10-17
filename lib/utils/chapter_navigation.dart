import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/controllers/api_controller.dart';
import 'package:upgrade/entity/card_entity.dart';
import 'package:upgrade/entity/deck_entity.dart';
import 'package:upgrade/main.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/widgets/app_snack_bar.dart';

/// Regular users tapping a chapter land directly in study mode. The deck
/// tree only carries slim card info (for progress), so the full cards are
/// fetched here, with a small loader so the app never looks frozen.
/// Owners of an editable deck go through the management list.
Future<void> openChapter(DeckEntity chapter) async {
  if (chapter.editable) {
    Get.toNamed(AppRoutes.cardRoute, arguments: chapter);
    return;
  }
  Get.dialog(
    const _OpeningDeckLoader(),
    barrierDismissible: false,
    barrierColor: Colors.black12,
  );
  List<CardEntity>? fetched;
  try {
    fetched = await ApiController.fetchCards(chapter.id);
  } finally {
    if (Get.isDialogOpen == true) Get.back();
  }
  if (fetched == null) {
    // Request failed: report the real reason, not "no cards in this lesson".
    showSnackBarWidget(message: ApiController.lastCardsError ?? 'خطأ في الاتصال');
    return;
  }
  final cards = fetched;
  if (cards.isEmpty) {
    showSnackBarWidget(message: "لا توجد بطاقات في هذا الدرس");
    return;
  }
  Get.toNamed(
    AppRoutes.cardViewRoute,
    arguments: {
      "cards": cards,
      "isView": false,
      "initalIndex": 0,
    },
  );
}

class _OpeningDeckLoader extends StatelessWidget {
  const _OpeningDeckLoader();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Center(
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.96),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColor.greenColor.withOpacity(0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 2.6,
              strokeCap: StrokeCap.round,
              color: AppColor.greenColor,
            ),
          ),
        ),
      ),
    );
  }
}
