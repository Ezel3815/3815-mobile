import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/controllers/add_card_controller.dart';
import 'package:upgrade/resources.dart';

class ToolsStatusBar extends GetView<AddCardController> {
  final CardTypes type;
  final FrontBackType type2;

  const ToolsStatusBar(this.type, this.type2, {super.key});

  Widget _toolButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool active = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onPressed,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? AppColor.greenColor.withOpacity(0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? AppColor.greenColor : AppColor.textSecondary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColor.surfaceColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _toolButton(
                  icon: Icons.format_bold_rounded,
                  onPressed: () => controller.toggleBold(type2),
                ),
                _toolButton(
                  icon: Icons.format_italic_rounded,
                  onPressed: () => controller.toggleItalic(type2),
                ),
                _toolButton(
                  icon: Icons.format_underline_rounded,
                  onPressed: () => controller.toggleUnderline(type2),
                ),
                _toolButton(
                  icon: Icons.format_strikethrough_rounded,
                  onPressed: () => controller.toggleStrikethrough(type2),
                ),
                _toolButton(
                  icon: Icons.palette_outlined,
                  onPressed: () => controller.pickColor(type2),
                ),
                _toolButton(
                  icon: Icons.format_size_rounded,
                  onPressed: () => controller.toggleFontSize(type2),
                ),
                if (type == CardTypes.cloze && type2 == FrontBackType.front)
                  _toolButton(
                    icon: Icons.tag_rounded,
                    onPressed: controller.addBraces,
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Divider(height: 1, color: AppColor.ink.withOpacity(0.06)),
            ),
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _toolButton(
                    icon: Icons.align_horizontal_left_rounded,
                    onPressed: () =>
                        controller.addAlignToText(type2, TextAlign.start),
                    active: (controller.selectedAlignFront == TextAlign.start &&
                            type2 == FrontBackType.front) ||
                        (controller.selectedAlignBack == TextAlign.start &&
                            type2 == FrontBackType.back) ||
                        (controller.selectedAlignComment == TextAlign.start &&
                            type2 == FrontBackType.comments),
                  ),
                  _toolButton(
                    icon: Icons.align_horizontal_center_rounded,
                    onPressed: () =>
                        controller.addAlignToText(type2, TextAlign.center),
                    active: (controller.selectedAlignFront == TextAlign.center &&
                            type2 == FrontBackType.front) ||
                        (controller.selectedAlignBack == TextAlign.center &&
                            type2 == FrontBackType.back) ||
                        (controller.selectedAlignComment == TextAlign.center &&
                            type2 == FrontBackType.comments),
                  ),
                  _toolButton(
                    icon: Icons.align_horizontal_right_rounded,
                    onPressed: () =>
                        controller.addAlignToText(type2, TextAlign.end),
                    active: (controller.selectedAlignFront == TextAlign.end &&
                            type2 == FrontBackType.front) ||
                        (controller.selectedAlignBack == TextAlign.end &&
                            type2 == FrontBackType.back) ||
                        (controller.selectedAlignComment == TextAlign.end &&
                            type2 == FrontBackType.comments),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
