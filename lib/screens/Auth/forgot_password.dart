import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:upgrade/api.dart';
import 'package:upgrade/app_validation.dart';
import 'package:upgrade/controllers/api_controller.dart';
import 'package:upgrade/controllers/error_handler.dart';
import 'package:upgrade/main.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/widgets/app_snack_bar.dart';

/// Two steps on one screen:
///  1. type your email and press "send code" (the screen STAYS open),
///  2. type the code from the email + a new password.
class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool codeSent = false;
  bool sending = false;
  bool resetting = false;
  bool hidePassword = true;

  /// Seconds left before "send again" is allowed.
  int cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    emailController.dispose();
    codeController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => cooldown--);
      if (cooldown <= 0) t.cancel();
    });
  }

  /// Turns a server reply into text for the user.
  String _messageOf(Response r) {
    final data = r.data;
    if (data is Map) {
      final m = data['message'];
      if (m is List) return m.join('\n');
      if (m != null) return m.toString();
    }
    return 'حدث خطأ، حاول مرة أخرى';
  }

  void _showError(Object e) {
    final failure = ErrorHandler.handle(e).failure;
    if (failure.code != -6) {
      showSnackBarWidget(message: failure.message ?? "");
    }
  }

  Future<void> _sendCode() async {
    final email = emailController.text.trim();
    if (AppValidation.validateEmail(email) != null) {
      showSnackBarWidget(message: 'أدخل بريداً إلكترونياً صحيحاً');
      return;
    }
    setState(() => sending = true);
    try {
      final response = await ApiController.dio.put(
        Api.requestResetPassword,
        data: {'email': email},
      );
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => codeSent = true);
        _startCooldown();
        showSnackBarWidget(
            message: 'تم إرسال الرمز إلى بريدك. تحقق أيضاً من الرسائل غير المرغوبة');
      } else {
        showSnackBarWidget(message: _messageOf(response));
      }
    } catch (e) {
      _showError(e);
    }
    if (mounted) setState(() => sending = false);
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => resetting = true);
    try {
      final response = await ApiController.dio.put(
        Api.resetPassword,
        data: {
          'email': emailController.text.trim(),
          'code': codeController.text.trim(),
          'password': passwordController.text,
        },
      );
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        showSnackBarWidget(message: 'تم تغيير كلمة المرور، سجّل الدخول الآن');
        Get.offAllNamed(AppRoutes.loginRoute);
        return;
      }
      // Wrong code / wrong email: stay here so it can be corrected.
      showSnackBarWidget(message: _messageOf(response));
    } catch (e) {
      _showError(e);
    }
    if (mounted) setState(() => resetting = false);
  }

  InputDecoration _fieldDecoration(IconData icon, String hint,
      {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffix,
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

  Widget _primaryButton({
    required String label,
    required bool busy,
    required VoidCallback? onPressed,
    bool filled = true,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              filled ? AppColor.darkGreenColor : Colors.transparent,
          foregroundColor: filled ? Colors.white : AppColor.darkGreenColor,
          disabledBackgroundColor:
              filled ? AppColor.disabledColor : Colors.transparent,
          elevation: 0,
          side: filled
              ? null
              : const BorderSide(color: AppColor.greenColor, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        onPressed: busy ? null : onPressed,
        child: busy
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: filled ? Colors.white : AppColor.greenColor,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
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
            iconTheme: const IconThemeData(color: AppColor.textPrimary),
          ),
          body: Form(
            key: _formKey,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Center(
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
                              'استعادة كلمة المرور',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColor.darkGreenColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              codeSent
                                  ? 'أدخل الرمز الذي وصلك وكلمة المرور الجديدة'
                                  : 'أدخل بريدك الإلكتروني وسنرسل لك رمزاً',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColor.textSecondary.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 22),
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
                                    controller: emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    cursorColor: AppColor.greenColor,
                                    textAlign: TextAlign.right,
                                    readOnly: codeSent && resetting,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: AppColor.textPrimary,
                                    ),
                                    validator: AppValidation.validateEmail,
                                    decoration: _fieldDecoration(
                                        Icons.mail_outline_rounded,
                                        'البريد الإلكتروني'),
                                  ),
                                  const SizedBox(height: 14),
                                  _primaryButton(
                                    label: !codeSent
                                        ? 'إرسال الرمز'
                                        : (cooldown > 0
                                            ? 'إعادة الإرسال بعد $cooldown ث'
                                            : 'إعادة إرسال الرمز'),
                                    busy: sending,
                                    filled: !codeSent,
                                    onPressed: (codeSent && cooldown > 0)
                                        ? null
                                        : _sendCode,
                                  ),
                                  if (codeSent) ...[
                                    const SizedBox(height: 22),
                                    TextFormField(
                                      controller: codeController,
                                      cursorColor: AppColor.greenColor,
                                      textAlign: TextAlign.center,
                                      textDirection: TextDirection.ltr,
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        letterSpacing: 4,
                                        fontWeight: FontWeight.w700,
                                        color: AppColor.textPrimary,
                                      ),
                                      validator: AppValidation.validateEmpty,
                                      decoration: _fieldDecoration(
                                          Icons.pin_outlined, 'الرمز'),
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: passwordController,
                                      obscureText: hidePassword,
                                      cursorColor: AppColor.greenColor,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: AppColor.textPrimary,
                                      ),
                                      validator:
                                          AppValidation.validatePassword,
                                      decoration: _fieldDecoration(
                                        Icons.lock_outline_rounded,
                                        'كلمة المرور الجديدة',
                                        suffix: IconButton(
                                          splashRadius: 20,
                                          icon: Icon(
                                            hidePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 20,
                                            color: AppColor.textSecondary,
                                          ),
                                          onPressed: () => setState(() =>
                                              hidePassword = !hidePassword),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _primaryButton(
                                      label: 'تعيين كلمة المرور',
                                      busy: resetting,
                                      onPressed: _resetPassword,
                                    ),
                                  ],
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
