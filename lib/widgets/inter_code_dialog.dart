import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/controllers/inter_code_controller.dart';
import 'package:upgrade/resources.dart';

class InterCodeDialog extends GetView<InterCodeController> {
  const InterCodeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => InterCodeController());
    return Obx(() => controller.success.value ? _successView() : _form());
  }

  Widget _successView() {
    return Dialog(
      backgroundColor: AppColor.surfaceColor,
      surfaceTintColor: AppColor.surfaceColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, 32, 22, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded,
                color: AppColor.greenColor, size: 84),
            SizedBox(height: 14),
            Text(
              "Code activated!",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColor.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form() {
    return Dialog(
      backgroundColor: AppColor.surfaceColor,
      surfaceTintColor: AppColor.surfaceColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Form(
        key: controller.formKey,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColor.lightGreenColor.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_open_rounded,
                  color: AppColor.darkGreenColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Enter your activation code",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Unlocks the decks tied to this code",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColor.textSecondary.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: controller.codeController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.text,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                  color: AppColor.textPrimary,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "This field is required.";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColor.scaffoldBackgroundColor,
                  hintText: "••••••",
                  hintStyle: TextStyle(
                    color: AppColor.textSecondary.withOpacity(0.5),
                    letterSpacing: 3,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        BorderSide(color: AppColor.greenColor, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Colors.redAccent, width: 1.2),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: controller.loading ? null : controller.enterCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.greenColor,
                      disabledBackgroundColor:
                          AppColor.greenColor.withOpacity(0.6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: controller.loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Activate",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  "Cancel",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColor.textSecondary.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
