import 'package:get/get.dart';
import 'package:upgrade/api.dart';

/// Centralized, bilingual app text. Every screen that reads from here
/// automatically follows the language switch in the drawer — no
/// per-screen work needed. Screens that still hardcode Arabic text
/// inline (most of the app, as of now) aren't affected yet; moving a
/// screen's strings in here is what makes it respond to the language
/// toggle. Built out incrementally — see section markers.
class AppStrings {
  static bool get _isEnglish => Get.locale?.languageCode == 'en';

  static String _t(String ar, String en) => _isEnglish ? en : ar;

  // ===== Home =====
  static String get welcomeBack => _t("مرحباً بعودتك", "Welcome back");
  static String get continueJourney =>
      _t("لنكمل رحلتك التعليمية", "Let's continue your learning journey");
  static String get currentPath => _t("رحلتك الحالية", "Current Path");
  static String get yourLearningPath =>
      _t("مسارك التعليمي", "Learning Path");
  static String get todaysMissions => _t("مهام اليوم", "Today's Missions");
  static String get completedCount => _t("مكتمل", "completed");
  static String get friendsActivity => _t("نشاط الأصدقاء", "Friends Activity");
  static String get noSubjectsYet =>
      _t("لا توجد مواد دراسية بعد", "No subjects yet");

  // ===== Lesson path (shared widget: Home + subject drill-down) =====
  static String get lesson => _t("الدرس", "Lesson");
  static String get completed => _t("مكتمل", "Completed");
  static String get inProgress => _t("قيد التقدم", "In Progress");
  static String get pending => _t("قيد الانتظار", "Pending");
  static String get notStarted => _t("لم يبدأ", "Not Started");

  // ===== Bottom navigation =====
  static String get navHome => _t("تعلم", "Learn");
  static String get navLibrary => _t("البطاقات", "Cards");
  static String get navProgress => _t("التقدم", "Progress");
  static String get navProfile => _t("الملف الشخصي", "Profile");
  static String get navMore => _t("الإشعارات", "Alerts");

  // ===== Streak / activity verbs (used in the friends feed) =====
  static String get unlocked => _t("فتح", "unlocked");
  static String get reachedLevel => _t("وصل إلى المستوى", "reached level");
  static String get dayStreak => _t("يوم متتالي", "day streak");

  // ===== Create deck =====
  static String get createDeck => _t("إنشاء مجموعة", "Create Deck");
  static String get startNewDeck => _t("ابدأ مجموعة جديدة", "Start a new deck");
  static String get startNewDeckHint => _t(
      "نظّم بطاقاتك في مجموعة لتبدأ الدراسة",
      "Organize your flashcards into a deck to start studying");
  static String get newDeck => _t("مجموعة جديدة", "New Deck");
  static String get deckName => _t("اسم المجموعة", "Deck name");
  static String get fieldRequired => _t("هذا الحقل مطلوب.", "This field is required.");
  static String get cancel => _t("إلغاء", "Cancel");
  static String get create => _t("إنشاء", "Create");

  // ===== Language toggle (drawer) =====
  static String get language => _t("اللغة", "Language");
  // ===== Night mode (Nocturne) =====
  static String get nightMode => _t("الوضع الليلي", "Night mode");
  static String get enteringNocturne => _t("ندخل الوضع الليلي", "Entering Nocturne");
  static String get studyAfterDark => _t("ادرس بهدوء بعد حلول الظلام", "Study calmly after dark");

  static String get arabic => _t("العربية", "Arabic");
  static String get english => _t("الإنجليزية", "English");

  // ===== Library / Cards screen =====
  static String get searchSubjectHint =>
      _t("ابحث عن مادة", "Search for a subject");
  static String get allYears => _t("كل السنوات", "All years");
  static String get all => _t("الكل", "All");
  static String get myCards => _t("بطاقاتي", "My Cards");
  static String get createdByMe => _t("أنشأتها", "Created by me");
  static String get noSubjects => _t("لا توجد مواد", "No subjects");
  static String get subjectLockedHint => _t(
      "هذه المادة مقفلة، أدخل الكود لفتحها من القائمة",
      "This subject is locked - enter the code to unlock it from the menu");
  static String get locked => _t("مقفل", "Locked");
  static String cardsCount(int total) => _t("$total بطاقة", "$total cards");

  // ===== Progress screen =====
  static String get tasks => _t("المهام", "Tasks");
  static String get statistics => _t("الإحصائيات", "Statistics");
  static String get leaderboard => _t("المتصدرون", "Leaderboard");
  static String get achievements => _t("الإنجازات", "Achievements");
  static String unlockedOf(int unlocked, int total) =>
      _t("$unlocked/$total مفتوح", "$unlocked/$total unlocked");
  static String get followFriendsForRank => _t(
      "تابع بعض الأصدقاء لمعرفة ترتيبك بينهم",
      "Follow some friends to see your rank among them");
  static String get cardsReviewed =>
      _t("بطاقات تمت مراجعتها", "Cards reviewed");
  static String get masteryRate => _t("نسبة الإتقان", "Mastery rate");
  static String get performanceBySubject =>
      _t("الأداء حسب المادة", "Performance by subject");
  static String get noDataYet => _t("لا توجد بيانات بعد", "No data yet");

  // ===== Profile screen =====
  static String get following => _t("المتابَعون", "Following");
  static String get followers => _t("المتابِعون", "Followers");
  static String shareMe(String username) => _t(
      "تابعني على MOZAIK: @$username\n${Api.baseUrl}/users/share/$username",
      "Follow me on MOZAIK: @$username\n${Api.baseUrl}/users/share/$username");

  // ===== Card study screen =====
  static String get showAnswer => _t("إظهار الإجابة", "Show Answer");
  static String get hideAnswer => _t("إخفاء الإجابة", "Hide Answer");
  static String get toggleMask => _t("إظهار/إخفاء التظليل", "Toggle Mask");
  static String get attachedFile => _t("ملف مرفق: \n", "Attached file: \n");
  static String get again => _t("مرة أخرى", "Again");
  static String get hard => _t("صعب", "Hard");
  static String get good => _t("جيد", "Good");
  static String get easy => _t("سهل", "Easy");
  static String get lastCard => _t("الأخيرة", "Last");
  static String remaining(int left) => _t("متبقي $left", "$left left");

  // ===== Onboarding =====
  static String get skip => _t("تخطي", "Skip");
  static String get next => _t("التالي", "Next");

  // ===== Color picker =====
  static String get chooseColor => _t("اختر اللون", "Choose Color");
  static String get selectColor => _t("اختر اللون", "Select color");
  static String get selectColorShade => _t("اختر درجة اللون", "Select color shade");
  static String get primaryColorLabel => _t("أساسي", "Primary");
  static String get accentColorLabel => _t("مميز", "Accent");
  static String get ok => _t("موافق", "ok");

  // ===== Document screen =====
  static String get pdfFiles => _t("ملفات PDF", "PDF Files");

  // ===== Drawer =====
  static String get drawerHome => _t("الرئيسية", "Home");
  static String get drawerFlashcards => _t("البطاقات", "Flashcards");
  static String get drawerProgress => _t("التقدم", "Progress");
  static String get drawerProfile => _t("الملف الشخصي", "Profile");
  static String get enterCode => _t("إدخال الكود", "Enter Code");
  static String get shareThisApp => _t("شارك التطبيق", "Share This App");
  static String get helpFeedback => _t("المساعدة والملاحظات", "Help & Feedback");
  static String get logOut => _t("تسجيل الخروج", "Log Out");

  // ===== Profile screen (misc) =====
  static String get changePhoto => _t("تغيير الصورة", "Change Photo");
  static String get editProfile => _t("تعديل الملف الشخصي", "EDIT PROFILE");
  static String joinedOn(String month, int year) =>
      _t("انضم في $month $year", "Joined $month $year");
  static String get monthJanuary => _t("يناير", "January");
  static String get monthFebruary => _t("فبراير", "February");
  static String get monthMarch => _t("مارس", "March");
  static String get monthApril => _t("أبريل", "April");
  static String get monthMay => _t("مايو", "May");
  static String get monthJune => _t("يونيو", "June");
  static String get monthJuly => _t("يوليو", "July");
  static String get monthAugust => _t("أغسطس", "August");
  static String get monthSeptember => _t("سبتمبر", "September");
  static String get monthOctober => _t("أكتوبر", "October");
  static String get monthNovember => _t("نوفمبر", "November");
  static String get monthDecember => _t("ديسمبر", "December");
}
