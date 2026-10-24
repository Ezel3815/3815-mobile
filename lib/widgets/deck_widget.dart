import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/entity/deck_entity.dart';
import 'package:upgrade/main.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/utils/chapter_navigation.dart';
import 'package:upgrade/widgets/app_snack_bar.dart';

class DeckWidget extends StatelessWidget {
  final DeckEntity model;
  const DeckWidget({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (model.locked) {
          showSnackBarWidget(
              message: "This deck is locked call support to unlock deck");
          return;
        }
        if (model.type == "PACKAGE_DECK") {
          Get.toNamed(
            AppRoutes.preparatoryYearRoute,
            arguments: {
              "id": model.id,
              "decks": model.children,
            },
            preventDuplicates: false,
          );
        } else {
          /// CARDS_DECK
          openChapter(model);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColor.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 32,
              decoration: BoxDecoration(
                color: AppColor.greenColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                model.title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColor.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            _StatPill(count: getEasyGoodCard(), color: AppColor.greenColor),
            const SizedBox(width: 6),
            _StatPill(count: getAgainCard(), color: Colors.redAccent),
            const SizedBox(width: 6),
            _StatPill(count: getHardCard(), color: const Color(0xFFE8A33D)),
            if (model.locked) ...[
              const SizedBox(width: 10),
              Icon(
                Icons.lock,
                size: 18,
                color: AppColor.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  int getEasyGoodCard() {
    return model.cards
        .where(
            (element) => element.answer == "EASY" || element.answer == "GOOD")
        .toList()
        .length;
  }

  int getAgainCard() {
    return model.cards
        .where((element) => element.answer == "AGAIN")
        .toList()
        .length;
  }

  int getHardCard() {
    return model.cards
        .where((element) => element.answer == "HARD")
        .toList()
        .length;
  }
}

class _StatPill extends StatelessWidget {
  final int count;
  final Color color;
  const _StatPill({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "$count",
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
