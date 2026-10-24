import 'package:flutter/material.dart';
import 'package:upgrade/app_validation.dart';
import 'package:upgrade/resources.dart';

import '../../controllers/api_controller.dart';

class ActivateCode extends StatefulWidget {
  const ActivateCode({super.key});

  @override
  State<ActivateCode> createState() => _ActivateCodeState();
}

class _ActivateCodeState extends State<ActivateCode> {
  TextEditingController emailController = TextEditingController();
  TextEditingController codeController = TextEditingController();
  final GlobalKey<FormState> _formKey1 = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: screenHeight,
          decoration: BoxDecoration(
            color: AppColor.scaffoldBackgroundColor,
            image: DecorationImage(
              image: AssetImage('lib/assests/images/background_5.jpg'),
              fit: BoxFit.fill, // يمكنك تعديل هذا الخيار حسب الحاجة
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
          ),
          body: Form(
            key: _formKey1,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: SingleChildScrollView(
              child: Column(
                // crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,

                children: [
                  const SizedBox(
                    height: 55,
                  ),
                  Image.asset(
                    "lib/assests/images/ddd.png",
                  ),
                  Text(
                    'Forgot Password',
                    style: TextStyle(fontSize: 30, color: AppColor.ink),
                  ),
                  Text(
                    'New Password',
                    style: TextStyle(fontSize: 20, color: AppColor.ink),
                  ),
                  Row(
                    children: [
                      const SizedBox(
                        width: 10,
                      ),
                      IconButton(
                          onPressed: () {},
                          icon: Image.asset(
                            'lib/assests/images/icon_email.png',
                            width: 80,
                            height: 35,
                          )),
                      Container(
                        width: 260,
                        child: TextFormField(
                          keyboardType: TextInputType.emailAddress,
                          controller: emailController,
                          cursorColor: AppColor.ink,
                          textAlign: TextAlign.center,
                          validator: AppValidation.validateEmail,
                          decoration: InputDecoration(
                            hintText: 'Email',
                            hintStyle: TextStyle(
                              fontSize: 18,
                              color: AppColor.ink,
                            ),
                            fillColor: AppColor.greyColor,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            constraints: const BoxConstraints(
                              maxHeight: 60,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 0),
                          ),
                          style: TextStyle(
                            fontSize: 20,
                            color: AppColor.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const SizedBox(
                        width: 10,
                      ),
                      IconButton(
                          onPressed: () {},
                          icon: Image.asset(
                            'lib/assests/images/icon_password.png',
                            width: 80,
                            height: 35,
                          )),
                      Container(
                        width: 260,
                        child: TextFormField(
                          controller: codeController,
                          cursorColor: AppColor.ink,
                          textAlign: TextAlign.center,
                          validator: AppValidation.validateEmpty,
                          decoration: InputDecoration(
                            hintText: 'Code',
                            hintStyle: TextStyle(
                              fontSize: 18,
                              color: AppColor.ink,
                            ),
                            fillColor: AppColor.greyColor,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            constraints: const BoxConstraints(
                              maxHeight: 60,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 0),
                          ),
                          style: TextStyle(
                            fontSize: 20,
                            color: AppColor.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: [
                      const SizedBox(
                        width: 120,
                      ),
                      InkWell(
                        onTap: () async {
                          if (_formKey1.currentState!.validate()) {
                            await ApiController.activate(codeController.text,
                                emailController.text, context);
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            color: AppColor.darkGreenColor,
                          ),
                          width: 220,
                          height: 40,
                          child: Center(
                              child: Text(
                            'Activate',
                            style: TextStyle(
                              fontSize: 20,
                              color: AppColor.ink,
                            ),
                          )),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
