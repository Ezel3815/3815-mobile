import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/resources.dart';

class FontSizeDialog extends StatelessWidget {
  const FontSizeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColor.scaffoldBackgroundColor,
      surfaceTintColor: AppColor.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Font Size",
              style: TextStyle(
                fontSize: 24,
                color: AppColor.ink,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              onTap: () {
                Get.back(result: 10.0);
              },
              title: Text(
                "xx-small",
                style: TextStyle(
                  fontSize: 18,
                  color: AppColor.ink,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            ListTile(
              onTap: () {
                Get.back(result: 12.0);
              },
              title: Text(
                "x-small",
                style: TextStyle(
                  fontSize: 18,
                  color: AppColor.ink,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            ListTile(
              onTap: () {
                Get.back(result: 14.0);
              },
              title: Text(
                "small",
                style: TextStyle(
                  fontSize: 18,
                  color: AppColor.ink,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            ListTile(
              onTap: () {
                Get.back(result: 16.0);
              },
              title: Text(
                "medium",
                style: TextStyle(
                  fontSize: 18,
                  color: AppColor.ink,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            ListTile(
              onTap: () {
                Get.back(result: 18.0);
              },
              title: Text(
                "large",
                style: TextStyle(
                  fontSize: 18,
                  color: AppColor.ink,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            ListTile(
              onTap: () {
                Get.back(result: 20.0);
              },
              title: Text(
                "x-large",
                style: TextStyle(
                  fontSize: 18,
                  color: AppColor.ink,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            ListTile(
              onTap: () {
                Get.back(result: 22.0);
              },
              title: Text(
                "xx-large",
                style: TextStyle(
                  fontSize: 18,
                  color: AppColor.ink,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
