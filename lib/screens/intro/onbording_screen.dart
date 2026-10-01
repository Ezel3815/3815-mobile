import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:upgrade/main.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/strings.dart';
import 'package:upgrade/screens/intro/second_page.dart';
import 'package:upgrade/screens/intro/third_page.dart';

import 'first_page.dart';

class OnBording extends StatefulWidget {
  const OnBording({super.key});

  @override
  OutBoordinagState createState() => OutBoordinagState();
}

class OutBoordinagState extends State<OnBording> {
  final controller = PageController();
  bool islastpage = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _finish() {
    Get.offAllNamed(AppRoutes.loginRoute);
    sharedPref.setBool("onBoarding", true);
  }

  Widget _bar() {
    return Row(
      key: const ValueKey('bar'),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () => controller.nextPage(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut),
          child: Text(AppStrings.next,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textPrimary)),
        ),
        SmoothPageIndicator(
          controller: controller,
          count: 3,
          effect: const WormEffect(
            dotWidth: 9,
            dotHeight: 9,
            spacing: 12,
            dotColor: Color(0xFFCBD3C4),
            activeDotColor: AppColor.darkGreenColor,
          ),
          onDotClicked: (i) => controller.animateToPage(i,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut),
        ),
        TextButton(
          onPressed: _finish,
          child: Text(AppStrings.skip,
              style: TextStyle(
                  fontSize: 17,
                  color: AppColor.textSecondary.withOpacity(0.85))),
        ),
      ],
    );
  }

  Widget _startButton() {
    return SizedBox(
      key: const ValueKey('start'),
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.darkGreenColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: _finish,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('ابدأ الآن',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            SizedBox(width: 8),
            Icon(Icons.arrow_back_rounded, size: 20, color: Colors.white),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Static mountain footer behind every page.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Image.asset(
                'lib/assests/onboarding/mountain.png',
                width: double.infinity,
                fit: BoxFit.fitWidth,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ),
          PageView(
            // Arabic UI: swiping should feel right-to-left.
            reverse: true,
            controller: controller,
            onPageChanged: (i) => setState(() => islastpage = i == 2),
            children: const [FirstPage(), SecondPage(), ThirdPage()],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 20),
                child: SizedBox(
                  height: 56,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: islastpage ? _startButton() : _bar(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
