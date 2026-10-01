import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/app_validation.dart';
import 'package:upgrade/controllers/api_controller.dart';
import 'package:upgrade/resources.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  TextEditingController nameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController confirmEmailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey1 = GlobalKey<FormState>();
  bool isPasswordValid = false;
  bool isLoading = false;
  bool hidePassword = true;
  Timer? _usernameDebounce;
  bool? usernameAvailable; // null = unknown
  bool checkingUsername = false;
  bool serverRejected = false;

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    confirmEmailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String v) {
    _usernameDebounce?.cancel();
    final t = v.trim();
    final valid = RegExp(r'^[a-zA-Z0-9_.]{3,20}$').hasMatch(t);
    setState(() {
      usernameAvailable = null;
      serverRejected = false;
      checkingUsername = valid;
    });
    if (!valid) return;
    // Debounced availability check; stale answers are ignored.
    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      final ok = await ApiController.isUsernameAvailable(t);
      if (!mounted || usernameController.text.trim() != t) return;
      setState(() {
        usernameAvailable = ok;
        checkingUsername = false;
      });
      _formKey1.currentState?.validate();
    });
  }

  Widget? _usernameSuffix() {
    if (checkingUsername) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColor.greenColor),
        ),
      );
    }
    if (usernameAvailable == true) {
      return const Icon(Icons.check_circle_rounded,
          size: 20, color: AppColor.greenColor);
    }
    if (usernameAvailable == false) {
      return const Icon(Icons.error_rounded,
          size: 20, color: Colors.redAccent);
    }
    return null;
  }

  /// The eye button inside the password field.
  Widget _eyeButton() {
    return IconButton(
      splashRadius: 20,
      icon: Icon(
        hidePassword
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined,
        size: 20,
        color: AppColor.textSecondary,
      ),
      onPressed: () => setState(() => hidePassword = !hidePassword),
    );
  }

  InputDecoration _fieldDecoration(IconData icon, String hint,
      {Widget? suffix, String? helper}) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffix,
      helperText: helper,
      helperStyle: const TextStyle(fontSize: 11.5, color: AppColor.greenColor),
      errorStyle: const TextStyle(fontSize: 11.5, color: Colors.redAccent),
      hintStyle: TextStyle(
        fontSize: 14,
        color: AppColor.textSecondary.withOpacity(0.8),
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(icon, size: 19, color: AppColor.greenColor),
      filled: true,
      fillColor: Colors.white.withOpacity(0.55),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColor.greenColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: screenHeight,
          color: AppColor.scaffoldBackgroundColor,
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Form(
            key: _formKey1,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Center(
                      // On tablets the form stays a comfortable column.
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Image.asset(
                                'lib/assests/brand/mozaik_emblem.png',
                                height: 78,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              "MOZAIK",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 5,
                                color: AppColor.darkGreenColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "أنشئ حسابك وابدأ رحلتك",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColor.textSecondary.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.6),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextFormField(
                                    controller: nameController,
                                    cursorColor: AppColor.greenColor,
                                    keyboardType: TextInputType.name,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: AppColor.textPrimary,
                                    ),
                                    validator: AppValidation.validateEmpty,
                                    decoration: _fieldDecoration(
                                        Icons.person_outline_rounded, 'الاسم'),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: usernameController,
                                    onChanged: _onUsernameChanged,
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    cursorColor: AppColor.greenColor,
                                    keyboardType: TextInputType.text,
                                    textDirection: TextDirection.ltr,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: AppColor.textPrimary,
                                    ),
                                    validator: (v) {
                                      final t = (v ?? '').trim();
                                      if (t.length < 3 || t.length > 20) {
                                        return 'من 3 إلى 20 حرفاً';
                                      }
                                      if (!RegExp(r'^[a-zA-Z0-9_.]+$')
                                          .hasMatch(t)) {
                                        return 'أحرف إنجليزية وأرقام و _ . فقط';
                                      }
                                      if (usernameAvailable == false) {
                                        return 'اسم المستخدم مستخدم بالفعل، جرّب اسماً آخر';
                                      }
                                      if (serverRejected) {
                                        return 'تعذّر التسجيل، ربما اسم المستخدم مستخدم. جرّب اسماً آخر';
                                      }
                                      return null;
                                    },
                                    decoration: _fieldDecoration(
                                        Icons.alternate_email_rounded,
                                        'معرّف المستخدم (فريد)',
                                        suffix: _usernameSuffix(),
                                        helper: usernameAvailable == true
                                            ? 'اسم المستخدم متاح'
                                            : null),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    keyboardType: TextInputType.emailAddress,
                                    cursorColor: AppColor.greenColor,
                                    controller: emailController,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: AppColor.textPrimary,
                                    ),
                                    validator: AppValidation.validateEmail,
                                    decoration: _fieldDecoration(
                                        Icons.mail_outline_rounded,
                                        'البريد الإلكتروني'),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    keyboardType: TextInputType.emailAddress,
                                    cursorColor: AppColor.greenColor,
                                    controller: confirmEmailController,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: AppColor.textPrimary,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Filed Required";
                                      }
                                      if (value.trim().toLowerCase() !=
                                          emailController.text
                                              .trim()
                                              .toLowerCase()) {
                                        return "Emails do not match";
                                      }
                                      return null;
                                    },
                                    decoration: _fieldDecoration(
                                        Icons.mail_outline_rounded,
                                        'تأكيد البريد الإلكتروني'),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    obscureText: hidePassword,
                                    controller: passwordController,
                                    cursorColor: AppColor.greenColor,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: AppColor.textPrimary,
                                    ),
                                    validator: AppValidation.validatePassword,
                                    onChanged: (value) {
                                      isPasswordValid =
                                          AppValidation.validatePassword(
                                                  value) ==
                                              null;
                                      setState(() {});
                                    },
                                    decoration: _fieldDecoration(
                                      Icons.lock_outline_rounded,
                                      'كلمة المرور',
                                      suffix: _eyeButton(),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    height: 54,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isPasswordValid
                                            ? AppColor.darkGreenColor
                                            : AppColor.disabledColor,
                                        foregroundColor: Colors.white,
                                        elevation: isPasswordValid ? 3 : 0,
                                        shadowColor: AppColor.darkGreenColor
                                            .withOpacity(0.4),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(28),
                                        ),
                                      ),
                                      onPressed: isLoading
                                          ? null
                                          : () async {
                                              if (_formKey1.currentState!
                                                  .validate()) {
                                                setState(() {
                                                  isLoading = true;
                                                });
                                                // Final check if the live one hasn't answered yet.
                                                if (usernameAvailable == null &&
                                                    await ApiController
                                                            .isUsernameAvailable(
                                                                usernameController
                                                                    .text
                                                                    .trim()) ==
                                                        false) {
                                                  if (mounted) {
                                                    setState(() {
                                                      usernameAvailable = false;
                                                      isLoading = false;
                                                    });
                                                    _formKey1.currentState
                                                        ?.validate();
                                                  }
                                                  return;
                                                }
                                                final error =
                                                    await ApiController
                                                        .register(
                                                            nameController.text,
                                                            usernameController
                                                                .text,
                                                            emailController
                                                                .text,
                                                            passwordController
                                                                .text,
                                                            context);
                                                if (mounted) {
                                                  setState(() {
                                                    isLoading = false;
                                                    if (error ==
                                                        'username_taken') {
                                                      usernameAvailable = false;
                                                    }
                                                    if (error ==
                                                        'server_error') {
                                                      serverRejected = true;
                                                    }
                                                  });
                                                  if (error != null) {
                                                    _formKey1.currentState
                                                        ?.validate();
                                                  }
                                                }
                                              }
                                            },
                                      child: isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'إنشاء حساب',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Icon(Icons.arrow_back_rounded,
                                                    size: 18,
                                                    color: Colors.white),
                                              ],
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    children: [
                                      Expanded(
                                          child: Divider(
                                              color: AppColor.textSecondary
                                                  .withOpacity(0.3))),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                        child: Text(
                                          "أو",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColor.textSecondary
                                                .withOpacity(0.8),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                          child: Divider(
                                              color: AppColor.textSecondary
                                                  .withOpacity(0.3))),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 52,
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColor.darkGreenColor,
                                        side: const BorderSide(
                                            color: AppColor.greenColor,
                                            width: 1.2),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(28),
                                        ),
                                      ),
                                      onPressed: () => Get.back(),
                                      child: const Text(
                                        'تسجيل الدخول',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
