import 'package:upgrade/screens/follow_list_screen.dart';
import 'package:upgrade/screens/locale_controller.dart';
import 'package:upgrade/utils/deep_link_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrade/controllers/add_card_controller.dart';
import 'package:upgrade/controllers/card_view_controller.dart';
import 'package:upgrade/controllers/create_deck_controller.dart';
import 'package:upgrade/controllers/document_controller.dart';
import 'package:upgrade/controllers/main_controller.dart';
import 'package:upgrade/controllers/preparatory_year_controller.dart';
import 'package:upgrade/controllers/card_controller.dart';
import 'package:upgrade/controllers/shape_creator_controller.dart';
import 'package:upgrade/controllers/years_controller.dart';
import 'package:upgrade/di.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/screens/Auth/activate_code.dart';
import 'package:upgrade/controllers/api_controller.dart';
import 'package:upgrade/screens/Auth/forgot_password.dart';
import 'package:upgrade/screens/Auth/login.dart';
import 'package:upgrade/screens/Auth/register.dart';
import 'package:upgrade/screens/Preparatory%20Year/preparatory_year_screen.dart';
import 'package:upgrade/screens/card_view_screen.dart';
import 'package:upgrade/screens/creat_deck/add_card_screen.dart';
import 'package:upgrade/screens/creat_deck/create_deck_screen.dart';
import 'package:upgrade/screens/creat_deck/shape_creator.dart';
import 'package:upgrade/screens/creat_deck/card_screen.dart';
import 'package:upgrade/screens/intro/onbording_screen.dart';
import 'package:upgrade/screens/main_screen.dart';
import 'package:upgrade/screens/profile_screen.dart';
import 'package:upgrade/screens/search_users_screen.dart';
import 'package:upgrade/screens/session_result_screen.dart';
import 'package:upgrade/screens/notification_settings_screen.dart';
import 'package:upgrade/screens/mosaic_screen.dart';
import 'package:upgrade/services/notification_service.dart';
import 'package:upgrade/services/push_service.dart';
import 'package:firebase_core/firebase_core.dart';

late SharedPreferences sharedPref;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TEMPORARY DIAGNOSTIC: release builds normally hide widget-build
  // errors behind a blank grey box. This makes the real error message
  // visible on screen instead, so it can be screenshotted and fixed —
  // safe to leave in, it only ever shows up when something is already
  // broken. Remove once the grey-box bug is found and fixed.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Container(
      color: const Color(0xFF7A1F1F),
      padding: const EdgeInsets.all(10),
      alignment: Alignment.center,
      child: Text(
        details.exceptionAsString(),
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  };
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Make the system navigation bar match the app instead of a black strip.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: AppColor.scaffoldBackgroundColor,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  sharedPref = await SharedPreferences.getInstance();
  // Loads the saved language (defaults to Arabic) before the first frame,
  // so GetMaterialApp picks the right locale/direction on the very first
  // build instead of flashing Arabic then flipping.
  Get.put(LocaleController(), permanent: true);
  await initAppModule();
  await ApiController.initDio();
  await NotificationService.instance.init();
  try {
    await Firebase.initializeApp();
    await PushService.instance.init();
  } catch (e) {
    // Missing google-services.json / no Play services on this device —
    // push notifications are unavailable, everything else still runs.
  }
  DeepLinkService.init();
  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeController = Get.find<LocaleController>();
    return Obx(() => GetMaterialApp(
      title: "MOZAIK",
      debugShowCheckedModeBanner: false,
      getPages: AppRoutes.pages,
      // Reactive: follows LocaleController, which defaults to Arabic and
      // persists whatever the user picks in the drawer. Registering both
      // locales (rather than just "ar") is what lets Get.updateLocale("en")
      // actually take, and also what makes Flutter auto-flip text
      // direction (RTL for ar, LTR for en) via GlobalWidgetsLocalizations.
      locale: Locale(localeController.languageCode.value),
      supportedLocales: const [Locale("ar"), Locale("en")],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Keep every screen above the system navigation bar (gesture pill or
      // 3-button bar). Android draws apps edge-to-edge on newer phones, which
      // slid content underneath it. Screens that already use a SafeArea are
      // unaffected: nested SafeAreas don't add up.
      builder: (context, child) => ColoredBox(
        color: AppColor.scaffoldBackgroundColor,
        child: SafeArea(
          top: false,
          left: false,
          right: false,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      theme: ThemeData(
        fontFamily: "ELMESSIRI",
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.transparent,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
      ),
    ));
  }
}

class AnimatedLogos extends StatefulWidget {
  const AnimatedLogos({super.key});

  @override
  AnimatedLogosState createState() => AnimatedLogosState();
}

class AnimatedLogosState extends State<AnimatedLogos>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _markScale;
  late Animation<double> _markOpacity;
  late Animation<double> _wordmarkOpacity;
  late Animation<Offset> _wordmarkSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    // Mark scales in with a slight overshoot ("pop"), fading in over the
    // first half of the animation.
    _markScale = Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
    ));
    _markOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    ));

    // Wordmark fades and slides up slightly, starting once the mark has
    // mostly settled.
    _wordmarkOpacity =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    ));
    _wordmarkSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic),
    ));

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (sharedPref.getString("token") != null) {
        Get.offNamed(AppRoutes.mainRoute);
      } else {
        if (sharedPref.get("onBoarding") != null) {
          Get.offNamed(AppRoutes.loginRoute);
        } else {
          Get.offNamed(AppRoutes.onboardingRoute);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _markScale,
              child: FadeTransition(
                opacity: _markOpacity,
                child: Image.asset(
                  "lib/assests/brand/mozaik_emblem.png",
                  height: 104,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SlideTransition(
              position: _wordmarkSlide,
              child: FadeTransition(
                opacity: _wordmarkOpacity,
                child: Image.asset(
                  "lib/assests/images/splash_wordmark.png",
                  height: 34,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppRoutes {
  static const String searchUsersRoute = "/searchUsersRoute";
  static const String viewProfileRoute = "/viewProfileRoute";
  static const String followListRoute = "/followListRoute";
  static const String splashRoute = "/";
  static const String onboardingRoute = "/onbordingRoute";
  static const String cardRoute = "/cardRoute";
  static const String activateCodeRoute = "/activateCodeRoute";
  static const String loginRoute = "/loginRoute";
  static const String registerRoute = "/registerRoute";
  static const String forgetPassowrdRoute = "/forgetPassowrdRoute";
  static const String addCardRoute = "/addCardRoute";
  static const String shapeCreatorRoute = "/shapeCreatorRoute";
  static const String preparatoryYearRoute = "/preparatoryYearRoute";
  static const String cardViewRoute = "/cardViewRoute";
  static const String mainRoute = "/mainRoute";
  static const String createDeckRoute = "/createDeckRoute";
  static const String sessionResultRoute = "/sessionResultRoute";
  static const String notificationSettingsRoute = "/notificationSettingsRoute";
  static const String mosaicRoute = "/mosaicRoute";

  static final List<GetPage> pages = [
    GetPage(name: searchUsersRoute, page: () => const SearchUsersScreen()),
    GetPage(name: viewProfileRoute, page: () => ProfileScreen(userId: Get.arguments)),
    GetPage(name: followListRoute, page: () => const FollowListScreen()),
    GetPage(
      name: splashRoute,
      page: () => const AnimatedLogos(),
    ),
    GetPage(
      name: onboardingRoute,
      page: () => const OnBording(),
    ),
    GetPage(
      name: cardRoute,
      page: () => const CardScreen(),
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => CardController(),
        ),
      ),
    ),
    GetPage(
      name: activateCodeRoute,
      page: () => const ActivateCode(),
    ),
    GetPage(
      name: loginRoute,
      page: () => const Login(),
    ),
    GetPage(
      name: registerRoute,
      page: () => const Register(),
    ),
    GetPage(
      name: forgetPassowrdRoute,
      page: () => const ForgotPassword(),
    ),
    GetPage(
      name: addCardRoute,
      page: () => const AddCardScreen(),
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => AddCardController(),
        ),
      ),
    ),
    GetPage(
      name: shapeCreatorRoute,
      page: () => const ShapeCreator(),
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => ShapeCreatorController(),
        ),
      ),
    ),
   GetPage(
  name: preparatoryYearRoute,
  page: () => PreparatoryYear(id: (Get.arguments['id']).toString()), // was: () => const PreparatoryYear()
  binding: BindingsBuilder(
    () => Get.lazyPut(
      () => PreparatoryYearController(),
      tag: Get.arguments['id'].toString(),
      fenix: true,
    ),
  ),
),
    GetPage(
      name: cardViewRoute,
      page: () => const CardViewScreen(),
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => CardViewController(),
        ),
      ),
    ),
    GetPage(
      // CreateDeckScreen used to be a bottom-nav tab; it's now reached
      // from a "+" button inside the Library screen instead, so it
      // needs a real named route. CreateDeckController is already
      // registered (lazyPut) via mainRoute's bindings below, and
      // stays alive for the lifetime of the main tab shell, so no
      // extra binding is needed here.
      name: createDeckRoute,
      page: () => const CreateDeckScreen(),
      binding: BindingsBuilder(() {
        // Safe no-ops if already registered by mainRoute; recreates
        // them if the main shell was disposed (fixes "not found" crash).
        Get.lazyPut(() => YearsController(), fenix: true);
        Get.lazyPut(() => CreateDeckController(), fenix: true);
      }),
    ),
    GetPage(
      name: sessionResultRoute,
      page: () => const SessionResultScreen(),
    ),
    GetPage(
      name: notificationSettingsRoute,
      page: () => const NotificationSettingsScreen(),
    ),
    GetPage(
      name: mosaicRoute,
      page: () => const MosaicScreen(),
    ),
    GetPage(
      name: mainRoute,
      page: () => const MainScreen(),
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => MainController(),
        ),
      ),
      bindings: [
        BindingsBuilder(
          () => Get.lazyPut(
            () => YearsController(),
          ),
        ),
        BindingsBuilder(
          () => Get.lazyPut(
            () => CreateDeckController(),
          ),
        ),
        BindingsBuilder(
          () => Get.lazyPut(
            () => DocumentController(),
          ),
        ),
      ],
    ),
  ];
}
