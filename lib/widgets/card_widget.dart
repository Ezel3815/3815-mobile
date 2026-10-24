import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/entity/card_entity.dart';
import 'package:upgrade/main.dart';
import 'package:upgrade/resources.dart';

class CardWidget extends StatelessWidget {
  final CardEntity model;
  final bool isEdit;
  const CardWidget({super.key, required this.model, required this.isEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
            height: 24,
            decoration: BoxDecoration(
              color: AppColor.greenColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            model.type,
            style: TextStyle(
              fontSize: 15,
              color: AppColor.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (isEdit)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                Get.toNamed(
                  AppRoutes.addCardRoute,
                  arguments: {
                    "id": model.deckId,
                    "isEdit": true,
                    "cardEntity": model,
                  },
                );
              },
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColor.greenColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColor.greenColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
