import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/resources.dart';

class DeleteDialog extends StatelessWidget {
  final String title;
  final void Function()? onTapDelete;

  const DeleteDialog({
    super.key,
    required this.title,
    this.onTapDelete,
  });

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
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                color: AppColor.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onTapDelete,
                    style: const ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        Colors.red,
                      ),
                      elevation: WidgetStatePropertyAll(0),
                    ),
                    child: const Text(
                      "Delete",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                    },
                    style: ButtonStyle(
                      backgroundColor: const WidgetStatePropertyAll(
                        Colors.transparent,
                      ),
                      elevation: const WidgetStatePropertyAll(0),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
