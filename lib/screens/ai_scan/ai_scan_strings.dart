import 'package:get/get.dart';

/// Arabic / English text for the AI scan feature (follows the app's language switch).
class AiStr {
  static bool get _en => Get.locale?.languageCode == 'en';
  static String _t(String ar, String en) => _en ? en : ar;

  // entry sheet on the deck's "+" button
  static String get addManual => _t('إضافة بطاقة يدويًا', 'Add a card manually');
  static String get newDeck => _t('إنشاء مجموعة جديدة', 'Create a new deck');
  static String get addWithAi => _t('إنشاء بطاقات بالذكاء الاصطناعي من صورة', 'Create cards from a photo with AI');

  // window 2
  static String get createTitle => _t('إنشاء بالذكاء الاصطناعي', 'Create with AI');
  static String get whatCreate => _t('ما الذي تريد إنشاءه؟', 'What do you want to create?');
  static String get whatCreateSub => _t('حوّل صورك إلى بطاقات دراسية أو اختبارات متعددة الخيارات باستخدام الذكاء الاصطناعي',
      'Turn your photos into flashcards or multiple-choice quizzes with AI');
  static String get flashcards => _t('بطاقات دراسية', 'Flashcards');
  static String get flashcardsSub => _t('تحويل الصورة إلى بطاقات لتسهيل المراجعة', 'Turn the photo into cards for easy review');
  static String get mcq => _t('اختبار متعدد الخيارات', 'Multiple-choice quiz');
  static String get mcqSub => _t('إنشاء أسئلة موضوعية من صورتك', 'Create objective questions from your photo');
  static String get clearPhotoTip => _t('استخدم صورة واضحة للحصول على أفضل النتائج', 'Use a clear photo for the best results');

  // window 3
  static String get takePhoto => _t('التقط الصورة', 'Take a photo');
  static String get camera => _t('الكاميرا', 'Camera');
  static String get gallery => _t('المعرض', 'Gallery');
  static String get photoHint => _t('تأكد من وضوح النص ووقوعه داخل الإطار', 'Make sure the text is clear and inside the frame');

  // window 4
  static String get preparing => _t('جارٍ إعداد دراستك', 'Preparing your study material');
  static String get preparingSub => _t('نستخدم الذكاء الاصطناعي لتحويل صورتك إلى بطاقات أو اختبار', 'We use AI to turn your photo into cards or a quiz');
  static String get stageAnalyze => _t('تحليل الصورة', 'Analyzing photo');
  static String get stageUnderstand => _t('فهم المحتوى', 'Understanding');
  static String get stageCreate => _t('إنشاء النتيجة', 'Creating result');
  static String get retry => _t('حاول مرة أخرى', 'Try again');
  static String get genericError => _t('حدث خطأ، حاول مرة أخرى', 'Something went wrong, please try again');

  // windows 5-6
  static String get flipCard => _t('قلب البطاقة', 'Flip card');
  static String get next => _t('التالي', 'Next');
  static String get finish => _t('إنهاء', 'Finish');
  static String get quizDone => _t('انتهى الاختبار', 'Quiz finished');
  static String score(int s, int t) => _t('نتيجتك: $s من $t', 'Your score: $s of $t');
  static String get ok => _t('حسنًا', 'OK');
  static String savedToDeck(int n) => _t('تمت إضافة $n بطاقة إلى المجموعة', '$n cards added to the deck');

  // review + keep / delete
  static String keepAsk(int n) => _t('هل تريد الاحتفاظ بهذه البطاقات ($n)؟', 'Keep these $n cards?');
  static String get keepAskQuiz => _t('هل تريد الاحتفاظ بهذا الاختبار؟', 'Keep this quiz?');
  static String get keepSub => _t('إذا اخترت الحذف فلن يتم حفظ أي شيء.', 'If you choose Delete, nothing will be saved.');
  static String get keep => _t('احتفاظ', 'Keep');
  static String get delete => _t('حذف', 'Delete');
  static String get saving => _t('جارٍ الحفظ...', 'Saving...');
  static String get kept => _t('تم الحفظ', 'Saved');
  static String get discarded => _t('تم الحذف', 'Deleted');
  static String get correct => _t('إجابة صحيحة', 'Correct!');
  static String get wrong => _t('إجابة خاطئة', 'Wrong answer');
  static String get rightWas => _t('الإجابة الصحيحة:', 'The correct answer:');
  static String get seeResult => _t('عرض النتيجة', 'See result');
  static String get previous => _t('السابق', 'Previous');

  // window 7
  static String get discoverPremium => _t('اكتشف المزيد مع Premium', 'Discover more with Premium');
  static String get usedFree => _t('لقد استخدمتَ جميع المحاولات المجانية. اشترك لمواصلة تحويل صورك إلى بطاقات واختبارات، أو انتظر حتى تتجدد المحاولات.',
      'You have used all your free tries. Subscribe to keep turning photos into cards and quizzes, or wait until your tries renew.');
  static String get fUnlimited => _t('استخدام غير محدود', 'Unlimited use');
  static String get fFaster => _t('معالجة أسرع', 'Faster processing');
  static String get fPriority => _t('دعم الأولوية', 'Priority support');
  static String get fExclusive => _t('ميزات حصرية قادمة', 'Upcoming exclusive features');
  static String get yearly => _t('سنوي', 'Yearly');
  static String get monthly => _t('شهري', 'Monthly');
  static String save(int p) => _t('وفّر $p%', 'Save $p%');
  static String get subscribe => _t('اشترك الآن', 'Subscribe now');
  static String get maybeLater => _t('ربما لاحقًا', 'Maybe later');

  // window 8
  static String get seeYou => _t('إلى اللقاء!', 'See you later!');
  static String get seeYouSub => _t('ستتمكن من استخدام هذه الميزة مجددًا بعد انتهاء فترة الانتظار.', 'You will be able to use this feature again when the waiting period ends.');
  static String get returnsIn => _t('ستعود الميزة بعد', 'The feature returns in');
  static String returnsAt(String t) => _t('تتجدد المحاولات عند الساعة $t', 'Your tries renew at $t');
  static String get gotIt => _t('حسنًا، فهمت', 'Got it');

  // window 9
  static String get upgrade => _t('الترقية إلى Premium', 'Upgrade to Premium');
  static String get upgradeSub => _t('احصل على وصول غير محدود إلى ميزة تحويل الصور إلى بطاقات واختبارات، بالإضافة إلى مزايا أخرى تساعدك في رحلتك التعليمية.',
      'Get unlimited access to turning photos into cards and quizzes, plus other benefits for your learning journey.');
  static String get backToApp => _t('العودة إلى التطبيق', 'Back to the app');

  // window 10
  static String get seeYouLater => _t('سنكمل معك لاحقًا', "We'll continue later");
  static String get laterSub => _t('يمكنك متابعة استخدام باقي ميزات التطبيق أثناء انتظار تجدد المحاولات.', 'You can keep using the rest of the app while your tries renew.');

  // payment (Sham Cash)
  static String get payTitle => _t('الدفع عبر شام كاش', 'Pay with Sham Cash');
  static String get payHeading => _t('حوّل المبلغ ثم أرسل رقم العملية', 'Transfer the amount, then send the transaction number');
  static String get amount => _t('المبلغ', 'Amount');
  static String get wallet => _t('رقم محفظة شام كاش', 'Sham Cash wallet number');
  static String get accountName => _t('اسم الحساب', 'Account name');
  static String get refNote => _t('اكتب هذا الرمز في ملاحظة التحويل', 'Write this code in the transfer note');
  static String get txNumber => _t('رقم العملية في شام كاش', 'Sham Cash transaction number');
  static String get attachProof => _t('إرفاق لقطة شاشة للإيصال (اختياري)', 'Attach a receipt screenshot (optional)');
  static String get proofAttached => _t('تم إرفاق الصورة', 'Image attached');
  static String get send => _t('إرسال', 'Send');
  static String get sentTitle => _t('تم إرسال طلبك', 'Request sent');
  static String get sentSub => _t('سنراجع عملية الدفع ونفعّل اشتراكك قريبًا.', 'We will review the payment and activate your subscription soon.');
}
