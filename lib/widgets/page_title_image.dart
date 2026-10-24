import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/controllers/add_card_controller.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/widgets/app_image.dart';

class PageTitleImage extends GetView<AddCardController> {
  final CardTypes type;
  final FrontBackType type2;

  const PageTitleImage(this.type, this.type2, {super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Row(
          children: [
            Text(
              controller.getTitle(type, type2),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColor.textPrimary,
              ),
            ),
            if (controller.commentImage.isEmpty &&
                type != CardTypes.occlusion) ...[
              const Spacer(),
              if (controller.getImage(type2).isNotEmpty)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AppImage(
                          image: controller.getImage(type2),
                          fit: BoxFit.cover,
                          radius: 10,
                        ),
                      ),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: InkWell(
                          onTap: () => controller.onTapClearImage(type2),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => controller.pickImage(type2),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColor.lightGreenColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.attachment_rounded,
                      color: AppColor.darkGreenColor,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
