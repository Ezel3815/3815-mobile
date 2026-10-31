import 'package:get/get.dart';

/// Bilingual MCQ text. Same pattern as AppStrings, so the drawer language
/// toggle applies to the whole MCQ section automatically.
class McqStrings {
  McqStrings._();

  static bool get isEnglish => Get.locale?.languageCode == 'en';
  static String _t(String ar, String en) => isEnglish ? en : ar;

  /// Arabic counted nouns: 1 / 2 / 3-10 / 11+.
  static String _ar(int n, String one, String two, String few, String many) {
    if (n == 1) return one;
    if (n == 2) return two;
    if (n >= 3 && n <= 10) return '$n $few';
    return '$n $many';
  }

  // ===== Tab / home =====
  static String get tab => 'MCQ';
  static String get title => 'MCQ';
  static String get heroTitle => _t('اختبر معلوماتك', 'Sharpen your knowledge');
  static String get heroSubtitle =>
      _t('تدرّب · تحسّن · تفوّق', 'Practice · Improve · Succeed');
  static String get startPractice => _t('ابدأ التدريب', 'Start Practice');
  static String get questionBank => _t('بنك الأسئلة', 'Question Bank');
  static String get browseBySubject =>
      _t('تصفّح حسب المادة', 'Browse by subject');
  static String get examMode => _t('وضع الاختبار', 'Exam Mode');
  static String get timedPractice => _t('تدريب مؤقّت', 'Timed practice');
  static String get review => _t('المراجعة', 'Review');
  static String get mistakesAndBookmarks =>
      _t('الأخطاء والمحفوظات', 'Mistakes & bookmarks');
  static String get myProgress => _t('تقدّمي', 'My Progress');
  static String get viewStats => _t('إحصاءاتك', 'View your stats');
  static String get soon => _t('قريباً', 'Soon');
  static String get continueWhere =>
      _t('تابع من حيث توقفت', 'Continue where you left off');
  static String toReview(int n) =>
      isEnglish ? '$n to review' : '$n للمراجعة';

  // ===== Counts =====
  static String questionsCount(int n) => isEnglish
      ? (n == 1 ? '1 question' : '$n questions')
      : _ar(n, 'سؤال واحد', 'سؤالان', 'أسئلة', 'سؤالاً');
  static String collectionsCount(int n) => isEnglish
      ? (n == 1 ? '1 collection' : '$n collections')
      : _ar(n, 'مجموعة واحدة', 'مجموعتان', 'مجموعات', 'مجموعة');
  static String progressOf(int done, int total) =>
      isEnglish ? '$done/$total questions' : '$done/$total سؤال';

  // ===== Subjects / collections =====
  static String get searchSubjects =>
      _t('ابحث عن مادة...', 'Search subjects...');
  static String get noSearchResults =>
      _t('لا توجد نتائج مطابقة', 'No matching results');
  static String get collections => _t('المجموعات', 'Collections');
  static String get examSessions => _t('الدورات', 'Exam sessions');
  static String get reviewMistakesCount => _t('راجع الأخطاء', 'Review mistakes');

  // ===== Empty / error =====
  static String get noQuestionsTitle =>
      _t('لا توجد أسئلة بعد', 'No questions yet');
  static String get noQuestionsBody => _t(
      'ستظهر المواد والأسئلة هنا فور إضافتها.',
      'Subjects and questions will appear here as soon as they are added.');
  static String get loadFailed =>
      _t('تعذّر تحميل الأسئلة', "Couldn't load the questions");
  static String get retry => _t('إعادة المحاولة', 'Try again');

  // ===== Practice =====
  static String qOf(int i, int n) => isEnglish ? '$i of $n' : '$i من $n';
  static String get singleAnswer => _t('إجابة واحدة', 'Single Answer');
  static String get multiAnswer => _t('عدة إجابات', 'Multiple Answers');
  static String get selectAll => _t('اختر كل ما ينطبق', 'Select all that apply');
  static String get checkAnswer => _t('تحقّق من الإجابة', 'Check Answer');
  static String get next => _t('التالي', 'Next');
  static String get finish => _t('إنهاء', 'Finish');
  static String get correct => _t('إجابة صحيحة!', 'Correct!');
  static String get incorrect => _t('إجابة خاطئة', 'Incorrect');
  static String get wellDone =>
      _t('أحسنت، إجابتك صحيحة.', 'Well done, you got it right.');
  static String correctAnswerIs(String letters) => isEnglish
      ? 'The correct answer: $letters'
      : 'الإجابة الصحيحة: $letters';
  static String get correctAnswerTag => _t('الإجابة الصحيحة', 'Correct answer');
  static String get yourAnswerTag => _t('إجابتك', 'Your answer');
  static String get explanation => _t('الشرح', 'Explanation');
  static String get noExplanation => _t('لا يوجد شرح لهذا السؤال.',
      'No explanation is available for this question.');
  static String get keyPoints => _t('نقاط أساسية', 'Key Points');
  static String get addBookmark => _t('حفظ السؤال', 'Bookmark question');
  static String get removeBookmark => _t('إزالة من المحفوظات', 'Remove bookmark');

  // ===== Result =====
  static String get practiceComplete => _t('اكتمل التدريب', 'Practice Complete');
  static String get correctLabel => _t('صحيحة', 'Correct');
  static String get incorrectLabel => _t('خاطئة', 'Incorrect');
  static String get unanswered => _t('بلا إجابة', 'Unanswered');
  static String get timeSpent => _t('الوقت المستغرق', 'Time Spent');
  static String get accuracy => _t('الدقة', 'Accuracy');
  static String get accuracyHint =>
      _t('صحيحة ÷ المُجاب عنها', 'correct ÷ answered');
  static String get reviewMistakes => _t('راجع الأخطاء', 'Review Mistakes');
  static String get tryAgain => _t('حاول مجدداً', 'Try Again');
  static String get backToMcq => _t('العودة إلى MCQ', 'Back to MCQ');

  // ===== Review =====
  static String get all => _t('الكل', 'All');
  static String get incorrectTab => _t('خاطئة', 'Incorrect');
  static String get correctTab => _t('صحيحة', 'Correct');
  static String get bookmarkedTab => _t('محفوظة', 'Bookmarked');
  static String get unansweredTab => _t('بلا إجابة', 'Unanswered');
  static String get yourAnswer => _t('إجابتك', 'Your answer');
  static String get correctShort => _t('الصحيحة', 'Correct');
  static String get viewExplanation => _t('عرض الشرح', 'View Explanation');
  static String get hideExplanation => _t('إخفاء الشرح', 'Hide Explanation');
  static String get emptyReview =>
      _t('لا توجد أسئلة هنا بعد.', 'Nothing to show here yet.');
  static String get reviewTitle => _t('مراجعة الأخطاء', 'Review Mistakes');

  // ===== Misc =====
  static String get exam => _t('الدورة', 'Exam');
  static String get notAnswered => _t('—', '—');
  // ===== Exam =====
  static String get examSetupTitle => _t('بدء الاختبار', 'Start Exam');
  static String get scope => _t('النطاق', 'Scope');
  static String get allSubjects => _t('كل المواد', 'All subjects');
  static String get numberOfQuestions =>
      _t('عدد الأسئلة', 'Number of Questions');
  static String get allLabel => _t('الكل', 'All');
  static String get timeLimit => _t('الوقت المحدد', 'Time Limit');
  static String minutes(int n) => isEnglish ? '$n min' : '$n د';
  static String get noTimeLimit => _t('بلا وقت محدد', 'No time limit');
  static String get randomizeQuestions =>
      _t('ترتيب عشوائي للأسئلة', 'Randomize Questions');
  static String get startExam => _t('ابدأ الاختبار', 'Start Exam');
  static String get examInProgress => _t('اختبار قيد التنفيذ', 'Exam in progress');
  static String get continueExam => _t('تابع الاختبار', 'Continue exam');
  static String get startNewExam => _t('ابدأ اختباراً جديداً', 'Start a new exam');
  static String get examPendingBody => _t(
      'لديك اختبار لم يُسلَّم بعد. المتابعة أو إلغاؤه وبدء اختبار جديد؟',
      'You have an exam that has not been submitted. Continue it, or discard it and start a new one?');
  static String get leaveExamTitle => _t('مغادرة الاختبار؟', 'Leave the exam?');
  static String get leaveExamTimedBody => _t(
      'إجاباتك محفوظة، لكن الوقت يستمر بالجريان.',
      'Your answers are saved, but the timer keeps running.');
  static String get leaveExamBody =>
      _t('إجاباتك محفوظة ويمكنك المتابعة لاحقاً.',
          'Your answers are saved and you can continue later.');
  static String get leave => _t('مغادرة', 'Leave');
  static String get stay => _t('البقاء', 'Stay');
  static String get previous => _t('السابق', 'Previous');
  static String get questionList => _t('قائمة الأسئلة', 'Question list');
  static String get submitExam => _t('تسليم الاختبار', 'Submit Exam');
  static String get submitConfirmTitle => _t('تسليم الاختبار؟', 'Submit the exam?');
  static String unansweredWarning(int n) => isEnglish
      ? (n == 1
          ? '1 question is still unanswered.'
          : '$n questions are still unanswered.')
      : (n == 1 ? 'سؤال واحد بلا إجابة.' : '$n أسئلة بلا إجابة.');
  static String get allAnsweredNote =>
      _t('أجبت عن جميع الأسئلة.', 'You answered every question.');
  static String get cannotUndo =>
      _t('لا يمكن تعديل الإجابات بعد التسليم.',
          'Answers cannot be changed after submitting.');
  static String get cancel => _t('إلغاء', 'Cancel');
  static String get submit => _t('تسليم', 'Submit');
  static String get timeLeft => _t('الوقت المتبقي', 'Time left');
  static String get lowTime => _t('الوقت ينفد', 'Time running out');
  static String get legendAnswered => _t('مُجاب', 'Answered');
  static String get legendUnanswered => _t('بلا إجابة', 'Unanswered');
  static String get legendCurrent => _t('الحالي', 'Current');
  static String answeredOf(int a, int n) =>
      isEnglish ? 'Answered $a of $n' : 'أُجيب عن $a من $n';
  static String get examCompleted => _t('اكتمل الاختبار', 'Exam Completed');
  static String get timeExpired => _t(
      'انتهى الوقت وتم تسليم إجاباتك تلقائياً.',
      'Time ran out and your answers were submitted automatically.');
  static String get avgPerQuestion =>
      _t('متوسط الوقت لكل سؤال', 'Avg. time per question');
  static String get reviewAnswers => _t('راجع الإجابات', 'Review Answers');
  static String get examReviewTitle => _t('مراجعة الاختبار', 'Exam Review');

  // ===== Progress =====
  static String get progressTitle => _t('تقدّمي', 'My Progress');
  static String get overview => _t('نظرة عامة', 'Overview');
  static String get bySubject => _t('حسب المادة', 'By Subject');
  static String get overallAccuracy => _t('الدقة العامة', 'Overall Accuracy');
  static String attemptsHint(int n) => isEnglish
      ? 'correct ÷ all $n attempts'
      : 'صحيحة ÷ كل المحاولات ($n)';
  static String get completedSessions =>
      _t('جلسات مكتملة', 'Completed Sessions');
  static String get completedExams => _t('اختبارات مكتملة', 'Completed Exams');
  static String get questionsAnswered =>
      _t('أسئلة مختلفة أُجيب عنها', 'Unique questions answered');
  static String get studyTime => _t('إجمالي وقت الدراسة', 'Total Study Time');
  static String get recentSessions => _t('آخر الجلسات', 'Recent Sessions');
  static String get modeExam => _t('اختبار', 'Exam');
  static String get modePractice => _t('تدريب', 'Practice');
  static String get noProgressTitle => _t('لا توجد بيانات بعد', 'No progress yet');
  static String get noProgressBody => _t(
      'أكمل جلسة تدريب أو اختباراً لتظهر إحصاءاتك هنا.',
      'Finish a practice session or an exam and your stats will appear here.');
  static String get earlyNote => _t(
      'عدد المحاولات قليل حتى الآن، ستصبح الأرقام أدق مع المزيد من التدريب.',
      'Only a few attempts so far; the numbers become more meaningful as you practice.');
  static String subjectAnswered(int n) =>
      isEnglish ? '$n answered' : '$n مُجاب';
  static String get subjectAccuracyHint => _t(
      'نسبة الأسئلة التي كانت إجابتها الأخيرة صحيحة',
      'share of questions whose latest answer was correct');
  static String get noSubjectData =>
      _t('لا توجد إجابات مسجّلة حسب المادة بعد.',
          'No answers recorded per subject yet.');
  static String hoursMinutes(int ms) {
    final m = (ms / 60000).round();
    final h = m ~/ 60;
    final r = m % 60;
    if (h == 0) return isEnglish ? '${r}m' : '$r د';
    return isEnglish ? '${h}h ${r}m' : '$h س $r د';
  }
}
