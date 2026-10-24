import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/controllers/add_card_controller.dart';
import 'package:upgrade/entity/card_entity.dart';
import 'package:upgrade/main.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/widgets/delete_dialog.dart';
import 'package:upgrade/widgets/page_form_filed.dart';
import 'package:upgrade/widgets/page_title_image.dart';
import 'package:upgrade/widgets/tools_status_bar.dart';

class AddCardScreen extends GetView<AddCardController> {
  const AddCardScreen({super.key});

  Widget _appBarIcon({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColor.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 19, color: color ?? AppColor.textPrimary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;

    return Scaffold(
      backgroundColor: AppColor.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColor.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'إضافة بطاقة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColor.textPrimary,
          ),
        ),
        actions: [
          _appBarIcon(
            icon: Icons.visibility_outlined,
            onPressed: () {
              final CardEntity card = CardEntity(
                type: controller.selectedTypes,
                data: jsonEncode(controller.getCardData()),
                answer: "answer",
                id: 0,
                backImageUrl: controller.backImage,
                createdAt: "createdAt",
                deckId: 0,
                documentTitle: "",
                documentUrl: "",
                frontImageUrl: controller.frontImage,
                order: 0,
                answers: [],
              );

              Get.toNamed(
                AppRoutes.cardViewRoute,
                arguments: {
                  "cards": [card],
                  "isView": true,
                  'initalIndex': 0,
                },
              );
            },
          ),
          if (controller.isEdit)
            _appBarIcon(
              icon: Icons.delete_outline_rounded,
              color: Colors.redAccent,
              onPressed: () {
                Get.dialog(
                  DeleteDialog(
                    title: "هل أنت متأكد من حذف هذه البطاقة؟",
                    onTapDelete: controller.deleteCard,
                  ),
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: controller.addCard,
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColor.greenColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_rounded,
                    size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: Obx(
        () => Container(
          width: double.infinity,
          height: screenHeight,
          color: AppColor.scaffoldBackgroundColor,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        'النوع',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColor.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColor.surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButtonFormField<String>(
                              decoration:
                                  const InputDecoration.collapsed(hintText: ''),
                              icon: Icon(Icons.keyboard_arrow_down_rounded,
                                  color: AppColor.textSecondary),
                              value: controller.selectedTypes,
                              items: controller.types
                                  .map<DropdownMenuItem<String>>(
                                    (String level) => DropdownMenuItem<String>(
                                      value: level,
                                      child: Text(
                                        level,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColor.textPrimary,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: controller.onChangeTypeValue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (controller.selectedTypes == "BASIC")
                  const Column(
                    children: [
                      PageTitleImage(CardTypes.basic, FrontBackType.front),
                      PageFormFiled(FrontBackType.front),
                      ToolsStatusBar(CardTypes.basic, FrontBackType.front),
                      PageTitleImage(CardTypes.basic, FrontBackType.back),
                      PageFormFiled(FrontBackType.back),
                      ToolsStatusBar(CardTypes.basic, FrontBackType.back),
                    ],
                  )
                else if (controller.selectedTypes == "CLOZE")
                  const Column(
                    children: [
                      PageTitleImage(CardTypes.cloze, FrontBackType.front),
                      PageFormFiled(FrontBackType.front),
                      ToolsStatusBar(CardTypes.cloze, FrontBackType.front),
                      PageTitleImage(CardTypes.cloze, FrontBackType.back),
                      PageFormFiled(FrontBackType.back),
                      ToolsStatusBar(CardTypes.cloze, FrontBackType.back),
                    ],
                  )
                else if (controller.selectedTypes == "OCCLUSION")
                  Column(
                    children: [
                      const PageTitleImage(
                          CardTypes.occlusion, FrontBackType.front),
                      const PageFormFiled(FrontBackType.front),
                      const ToolsStatusBar(
                          CardTypes.occlusion, FrontBackType.front),
                      const PageTitleImage(
                          CardTypes.occlusion, FrontBackType.back),
                      const PageFormFiled(FrontBackType.back),
                      const ToolsStatusBar(
                          CardTypes.occlusion, FrontBackType.back),
                      const PageTitleImage(
                          CardTypes.occlusion, FrontBackType.comments),
                      const PageFormFiled(FrontBackType.comments),
                      const ToolsStatusBar(
                          CardTypes.occlusion, FrontBackType.comments),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: controller.goToShapeCreator,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColor.greenColor,
                              side: BorderSide(
                                  color: AppColor.greenColor, width: 1.2),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.image_outlined, size: 18),
                            label: const Text(
                              'اختيار صورة',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                if (controller.user.role == 'ADMIN') ...[
                  if (controller.file.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColor.surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.picture_as_pdf_outlined,
                                size: 18, color: AppColor.greenColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                controller.fileName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColor.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              onTap: controller.clearFile,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: controller.pickFile,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColor.greenColor,
                            side: BorderSide(
                                color: AppColor.greenColor, width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.attach_file_rounded, size: 18),
                          label: const Text(
                            'إضافة ملف PDF',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
