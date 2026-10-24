import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/controllers/profile_controller.dart';
import 'package:upgrade/resources.dart';

class EditProfileDialog extends StatelessWidget {
  final ProfileController controller;
  const EditProfileDialog({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final usernameController = TextEditingController(
      text: controller.profile.value?.username ?? '',
    );
    final formKey = GlobalKey<FormState>();

    return Dialog(
      backgroundColor: AppColor.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: usernameController,
                  validator: (value) {
                    if (value == null || value.trim().length < 3) {
                      return "Must be at least 3 characters";
                    }
                    return null;
                  },
                  cursorColor: AppColor.greenColor,
                  decoration: InputDecoration(
                    hintText: "Username",
                    hintStyle: TextStyle(
                      color: AppColor.textSecondary,
                      fontSize: 15,
                    ),
                    filled: true,
                    fillColor: AppColor.surfaceColor,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
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
                      borderSide: BorderSide(
                          color: AppColor.greenColor, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.redAccent),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: Colors.redAccent, width: 1.5),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColor.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          Get.back();
                          await controller.updateUsername(
                              usernameController.text.trim());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.greenColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 15,
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
      ),
    );
  }
}
