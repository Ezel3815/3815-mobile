import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:upgrade/resources.dart';

import 'app_button.dart';

class SuccessDownloadDialog extends StatelessWidget {
  const SuccessDownloadDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Dialog(
      backgroundColor: AppColor.card,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Downloaded successfully",
              style: Get.textTheme.labelLarge!.copyWith(
                color: AppColor.greenColor,
                fontSize: 22,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Icon(
              Icons.check_circle,
              color: AppColor.greenColor,
              size: 100,
            ),
            const SizedBox(
              height: 10,
            ),
            AppButton(
              title: "Back",
              style: Get.textTheme.labelLarge!.copyWith(
                fontSize: 18,
              ),
              onTap: () => Get.back(),
              width: width,
              backgroundColor: Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }
}
