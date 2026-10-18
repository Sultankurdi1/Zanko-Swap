import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppStrings {
  final Locale locale;
  AppStrings(this.locale);
  static const delegate = _AppStringsDelegate();
  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings)!;

  bool get isKurdish => locale.languageCode == 'ku';
  bool get isArabic => locale.languageCode == 'ar';

  String get appName => 'ZankoSwap';
  String get search => isKurdish
      ? 'گەڕان بۆ کتێب، مالزەمە...'
      : isArabic
      ? 'ابحث عن الكتب والملازم...'
      : 'Search books, notes...';
  String get home => isKurdish
      ? 'سەرەکی'
      : isArabic
      ? 'الرئيسية'
      : 'Home';
  String get saved => isKurdish
      ? 'پاشەکەوتکراوەکان'
      : isArabic
      ? 'المحفوظات'
      : 'Saved';
  String get messages => isKurdish
      ? 'نامەکان'
      : isArabic
      ? 'الرسائل'
      : 'Messages';
  String get profile => isKurdish
      ? 'پرۆفایل'
      : isArabic
      ? 'الملف الشخصي'
      : 'Profile';
  String get addListing => isKurdish
      ? 'زیادکردنی بابەت'
      : isArabic
      ? 'إضافة إعلان'
      : 'Add Listing';
  String get free => isKurdish
      ? 'خۆڕایی'
      : isArabic
      ? 'مجاني'
      : 'Free';
  String get exchange => isKurdish
      ? 'ئاڵوگۆڕ'
      : isArabic
      ? 'مبادلة'
      : 'Exchange';
  String get price => isKurdish
      ? 'نرخ'
      : isArabic
      ? 'السعر'
      : 'Price';
  String get city => isKurdish
      ? 'شار'
      : isArabic
      ? 'المدينة'
      : 'City';
  String get university => isKurdish
      ? 'زانکۆ'
      : isArabic
      ? 'الجامعة'
      : 'University';
  String get college => isKurdish
      ? 'کۆلێژ'
      : isArabic
      ? 'الكلية'
      : 'College';
  String get department => isKurdish
      ? 'بەش'
      : isArabic
      ? 'القسم'
      : 'Department';
  String get stage => isKurdish
      ? 'قۆناغ'
      : isArabic
      ? 'المرحلة'
      : 'Stage';
  String get condition => isKurdish
      ? 'دۆخ'
      : isArabic
      ? 'الحالة'
      : 'Condition';
  String get settings => isKurdish
      ? 'ڕێکخستنەکان'
      : isArabic
      ? 'الإعدادات'
      : 'Settings';
  String get darkMode => isKurdish
      ? 'دۆخی تاریک'
      : isArabic
      ? 'الوضع الداكن'
      : 'Dark mode';
  String get language => isKurdish
      ? 'زمان'
      : isArabic
      ? 'اللغة'
      : 'Language';
  String get institutions => isKurdish
      ? 'دامەزراوە خوێندنییەکان'
      : isArabic
      ? 'المؤسسات التعليمية'
      : 'Institutions';
  String get schools => isKurdish
      ? 'قوتابخانەکان'
      : isArabic
      ? 'المدارس'
      : 'Schools';
  String get institutes => isKurdish
      ? 'پەیمانگاکان'
      : isArabic
      ? 'المعاهد'
      : 'Institutes';
  String get colleges => isKurdish
      ? 'کۆلێژەکان'
      : isArabic
      ? 'الكليات'
      : 'Colleges';
  String get vocationalFiveYear => isKurdish
      ? 'پەیمانگا پیشەییە ٥ ساڵییەکان'
      : isArabic
      ? 'المعاهد المهنية ٥ سنوات'
      : '5-year vocational institutes';
  String get manageInstitutions => isKurdish
      ? 'بەڕێوەبردنی دامەزراوەکان'
      : isArabic
      ? 'إدارة المؤسسات'
      : 'Manage institutions';
  String get website => isKurdish
      ? 'ماڵپەڕ'
      : isArabic
      ? 'الموقع الإلكتروني'
      : 'Website';
  String get socialLinks => isKurdish
      ? 'بەستەرەکان'
      : isArabic
      ? 'الروابط'
      : 'Links';
  String get activeListings => isKurdish
      ? 'بابەتە چالاکەکان'
      : isArabic
      ? 'إعلاناتي'
      : 'Active listings';
  String get sold => isKurdish
      ? 'فرۆشراوەکان'
      : isArabic
      ? 'المباعة'
      : 'Sold';
  String get savedItems => isKurdish
      ? 'پاشەکەوتکراوەکان'
      : isArabic
      ? 'المحفوظات'
      : 'Saved items';
  String get balance => isKurdish
      ? 'باڵانسی من'
      : isArabic
      ? 'رصيدي'
      : 'Balance';
  String get editProfile => isKurdish
      ? 'دەستکاریکردنی پرۆفایل'
      : isArabic
      ? 'تعديل الملف الشخصي'
      : 'Edit profile';
  String get logout => isKurdish
      ? 'چوونەدەرەوە'
      : isArabic
      ? 'تسجيل الخروج'
      : 'Log out';
  String get about => isKurdish
      ? 'دەربارەی ZankoSwap'
      : isArabic
      ? 'عن ZankoSwap'
      : 'About ZankoSwap';
  String get help => isKurdish
      ? 'یارمەتی و پشتیوانی'
      : isArabic
      ? 'المساعدة والدعم'
      : 'Help & support';
  String get courses => isKurdish
      ? 'کۆرس و خولی فێرکاری'
      : isArabic
      ? 'الدورات والتدريب'
      : 'Courses & training';
  String get nearbyServices => isKurdish
      ? 'خزمەتگوزارییە نزیکەکان'
      : isArabic
      ? 'الخدمات القريبة'
      : 'Nearby services';
  String get featured => isKurdish
      ? 'پێشنیارکراو'
      : isArabic
      ? 'مميز'
      : 'Featured';
  String get noListings => isKurdish
      ? 'هیچ بابەتێک نەدۆزرایەوە'
      : isArabic
      ? 'لم يتم العثور على إعلانات'
      : 'No listings found';
  String get student => isKurdish
      ? 'قوتابی'
      : isArabic
      ? 'طالب'
      : 'Student';
  String get guest => isKurdish
      ? 'میوان'
      : isArabic
      ? 'زائر'
      : 'Guest';
  String get signIn => isKurdish
      ? 'چوونەژوورەوە'
      : isArabic
      ? 'تسجيل الدخول'
      : 'Sign in';
  String get createAccount => isKurdish
      ? 'دروستکردنی هەژمار'
      : isArabic
      ? 'إنشاء حساب'
      : 'Create account';
  String get email => isKurdish
      ? 'ئیمەیل'
      : isArabic
      ? 'البريد الإلكتروني'
      : 'Email';
  String get password => isKurdish
      ? 'وشەی نهێنی'
      : isArabic
      ? 'كلمة المرور'
      : 'Password';
  String get fullName => isKurdish
      ? 'ناوی تەواو'
      : isArabic
      ? 'الاسم الكامل'
      : 'Full name';
  String get phone => isKurdish
      ? 'ژمارەی مۆبایل'
      : isArabic
      ? 'رقم الهاتف'
      : 'Phone';
  String get noAccountRegister => isKurdish
      ? 'هەژمارت نییە؟ دروستی بکە'
      : isArabic
      ? 'ليس لديك حساب؟ أنشئ حساباً'
      : "Don't have an account? Register";
  String get haveAccountSignIn => isKurdish
      ? 'هەژمارت هەیە؟ چوونەژوورەوە'
      : isArabic
      ? 'لديك حساب؟ سجل الدخول'
      : 'Already have an account? Sign in';
  String get invalidCredentials => isKurdish
      ? 'ئیمەیل یان وشەی نهێنی هەڵەیە'
      : isArabic
      ? 'البريد الإلكتروني أو كلمة المرور غير صحيحة'
      : 'Invalid email or password';
  String get profileUpdated => isKurdish
      ? 'پرۆفایل نوێکرایەوە'
      : isArabic
      ? 'تم تحديث الملف الشخصي'
      : 'Profile updated';
  String get saveChanges => isKurdish
      ? 'پاشەکەوتکردنی گۆڕانکارییەکان'
      : isArabic
      ? 'حفظ التغييرات'
      : 'Save changes';
  String get privateChat => isKurdish
      ? 'گفتوگۆی تایبەت'
      : isArabic
      ? 'محادثة خاصة'
      : 'Private chat';
  String get contactPrivacy => isKurdish
      ? 'ژمارەی مۆبایل و ئیمەیلی بەکارهێنەران لە چاتدا نیشان نادرێت.'
      : isArabic
      ? 'لن تظهر أرقام الهواتف أو عناوين البريد الإلكتروني في المحادثة.'
      : 'Phone numbers and email addresses are not shown in chat.';
  String get researchHeader => isKurdish
      ? 'توێژینەوە'
      : isArabic
      ? 'الأبحاث'
      : 'Research';
  String get academicPath => isKurdish
      ? 'زانکۆ / کۆلێژ / بەش / قۆناغ'
      : isArabic
      ? 'الجامعة / الكلية / القسم / المرحلة'
      : 'University / College / Department / Stage';
  String get universityOrInstitute => isKurdish
      ? 'زانکۆ یان پەیمانگا'
      : isArabic
      ? 'الجامعة أو المعهد'
      : 'University or Institute';
  String get governmentSection => isKurdish
      ? 'حکومی'
      : isArabic
      ? 'حكومي'
      : 'Government';
  String get privateSection => isKurdish
      ? 'ئەهلی'
      : isArabic
      ? 'أهلي'
      : 'Private';
  String get typeManually => isKurdish
      ? 'بە دەستی بنووسە'
      : isArabic
      ? 'اكتب يدوياً'
      : 'Type manually';
  String get stageLabel => isKurdish
      ? 'قۆناغ'
      : isArabic
      ? 'المرحلة'
      : 'Stage';
  String get researchPapers => isKurdish
      ? 'بابەتی توێژینەوە'
      : isArabic
      ? 'الأبحاث'
      : 'Research papers';
  String get addResearch => isKurdish
      ? 'زیادکردنی بابەتی توێژینەوە'
      : isArabic
      ? 'إضافة بحث'
      : 'Add research paper';
  String get researchTitle => isKurdish
      ? 'ناونیشانی توێژینەوە'
      : isArabic
      ? 'عنوان البحث'
      : 'Research title';
  String get noResearchYet => isKurdish
      ? 'هیچ بابەتێکی توێژینەوە نییە'
      : isArabic
      ? 'لا توجد أبحاث بعد'
      : 'No research papers yet';
  String get examPapers => isKurdish
      ? 'ئەسیلەکانی پۆلی دوازدە'
      : isArabic
      ? 'أسئلة الصف الثاني عشر'
      : 'Grade 12 exam papers';
  String get addExamPaper => isKurdish
      ? 'زیادکردنی ئەسیلە'
      : isArabic
      ? 'إضافة أسئلة امتحان'
      : 'Add exam paper';
  String get subject => isKurdish
      ? 'وانە'
      : isArabic
      ? 'المادة'
      : 'Subject';
  String get track => isKurdish
      ? 'تیپ'
      : isArabic
      ? 'الفرع'
      : 'Track';
  String get scientificTrack => isKurdish
      ? 'زانستی'
      : isArabic
      ? 'علمي'
      : 'Scientific';
  String get literaryTrack => isKurdish
      ? 'ئەدەبی'
      : isArabic
      ? 'أدبي'
      : 'Literary';
  String get year => isKurdish
      ? 'ساڵ'
      : isArabic
      ? 'السنة'
      : 'Year';
  String get noExamPapersYet => isKurdish
      ? 'هیچ ئەسیلەیەک نییە'
      : isArabic
      ? 'لا توجد أسئلة امتحان'
      : 'No exam papers yet';
  String get contentOrLink => isKurdish
      ? 'ناوەڕۆک یان لینکی فایل'
      : isArabic
      ? 'المحتوى أو رابط الملف'
      : 'Content or file link';
  String get all => isKurdish
      ? 'هەمووی'
      : isArabic
      ? 'الكل'
      : 'All';
  String get books => isKurdish
      ? 'کتێبەکان'
      : isArabic
      ? 'الكتب'
      : 'Books';
  String get handouts => isKurdish
      ? 'ملزمە و مادەی خوێندن'
      : isArabic
      ? 'الملازم والمواد الدراسية'
      : 'Study materials / Handouts';
  String get examsLabel => isKurdish
      ? 'ئەسیلەکان'
      : isArabic
      ? 'الامتحانات'
      : 'Exams / Past papers';
  String get researchesLabel => isKurdish
      ? 'توێژینەوەکان'
      : isArabic
      ? 'الأبحاث'
      : 'Researches';
  String get latestListings => isKurdish
      ? 'نوێترین بابەتەکان'
      : isArabic
      ? 'أحدث المنشورات'
      : 'Latest publications';
  String get contentFilter => isKurdish
      ? 'جۆری بابەت'
      : isArabic
      ? 'نوع المحتوى'
      : 'Content filter';
  String get restaurants => isKurdish
      ? 'چێشتخانەکان'
      : isArabic
      ? 'المطاعم'
      : 'Restaurants';
  String get cafes => isKurdish
      ? 'کافێکان'
      : isArabic
      ? 'المقاهي'
      : 'Cafes';
  String get stationery => isKurdish
      ? 'پەراوگە و کۆپی'
      : isArabic
      ? 'المكتبات ومراكز النسخ'
      : 'Stationery / Copy centers';
  String get promoteBusiness => isKurdish
      ? 'ڕیکلامی کاروبارەکەت'
      : isArabic
      ? 'روّج لعملك'
      : 'Promote your business';
  String get contactUs => isKurdish
      ? 'پەیوەندیمان پێوە بکە'
      : isArabic
      ? 'اتصل بنا'
      : 'Contact Us';
  String get studentHome => isKurdish
      ? 'ماڵی خوێندکاران'
      : isArabic
      ? 'الصفحة الرئيسية للطلاب'
      : 'Student Home';
  String get by => isKurdish
      ? 'لەلایەن'
      : isArabic
      ? 'بواسطة'
      : 'By';
  String get delete => isKurdish
      ? 'سڕینەوە'
      : isArabic
      ? 'حذف'
      : 'Delete';
  String get cancel => isKurdish
      ? 'پاشگەزبوونەوە'
      : isArabic
      ? 'إلغاء'
      : 'Cancel';
  String get noPlaces => isKurdish
      ? 'هێشتا هیچ شوێنێک نییە.'
      : isArabic
      ? 'لا توجد أماكن بعد.'
      : 'No places yet.';
  String get placeAdded => isKurdish
      ? 'شوێنەکە زیاد کرا'
      : isArabic
      ? 'تمت إضافة المكان'
      : 'Place added';
  String get addPlace => isKurdish
      ? 'شوێنێک زیاد بکە'
      : isArabic
      ? 'إضافة مكان'
      : 'Add a place';
  String get nearbyPlaces => isKurdish
      ? 'شوێنەکانی نزیک و داشکاندنی قوتابیان'
      : isArabic
      ? 'الأماكن القريبة وخصومات الطلاب'
      : 'Nearby places and student discounts';
  String get copyShops => isKurdish
      ? 'کۆپی و چاپ'
      : isArabic
      ? 'مراكز النسخ والطباعة'
      : 'Copy shops';
  String get placeName => isKurdish
      ? 'ناوی شوێن'
      : isArabic
      ? 'اسم المكان'
      : 'Place name';
  String get type => isKurdish
      ? 'جۆر'
      : isArabic
      ? 'النوع'
      : 'Type';
  String get address => isKurdish
      ? 'ناونیشان'
      : isArabic
      ? 'العنوان'
      : 'Address';
  String get studentDiscount => isKurdish
      ? 'داشکاندنی قوتابیان'
      : isArabic
      ? 'خصم الطلاب / العرض'
      : 'Student discount / offer';
  String get addPhoto => isKurdish
      ? 'وێنە زیاد بکە'
      : isArabic
      ? 'إضافة صورة'
      : 'Add photo';
  String get photoSelected => isKurdish
      ? 'وێنە هەڵبژێردرا'
      : isArabic
      ? 'تم اختيار الصورة'
      : 'Photo selected';
  String get add => isKurdish
      ? 'زیادکردن'
      : isArabic
      ? 'إضافة'
      : 'Add';
  String get maps => isKurdish
      ? 'نەخشە'
      : isArabic
      ? 'الخرائط'
      : 'Google Maps';
  String get whatsapp => 'WhatsApp';
  String get menu => isKurdish
      ? 'مێنیو'
      : isArabic
      ? 'القائمة'
      : 'Menu';
  String get retry => isKurdish
      ? 'دووبارە هەوڵبدەوە'
      : isArabic
      ? 'إعادة المحاولة'
      : 'Retry';
  String get openPdf => isKurdish
      ? 'کردنەوەی PDF'
      : isArabic
      ? 'فتح PDF'
      : 'Open PDF';
  String get download => isKurdish
      ? 'داگرتن'
      : isArabic
      ? 'تنزيل'
      : 'Download';
  String get pdfSaved => isKurdish
      ? 'PDF پاشەکەوت کرا.'
      : isArabic
      ? 'تم حفظ ملف PDF.'
      : 'PDF saved.';
  String get couldNotOpenMaps => isKurdish
      ? 'نەتوانرا نەخشە بکرێتەوە.'
      : isArabic
      ? 'تعذر فتح الخرائط.'
      : 'Could not open Google Maps.';
  String get couldNotOpenWhatsApp => isKurdish
      ? 'نەتوانرا WhatsApp بکرێتەوە.'
      : isArabic
      ? 'تعذر فتح واتساب.'
      : 'Could not open WhatsApp.';
  String get couldNotOpenLink => isKurdish
      ? 'بەستەرەکە نەکرایەوە.'
      : isArabic
      ? 'تعذر فتح الرابط.'
      : 'Could not open the link.';
  String get deleteQuestion => isKurdish
      ? 'دەتەوێ بسڕیتەوە؟'
      : isArabic
      ? 'هل تريد الحذف؟'
      : 'Do you want to delete this?';
  String get cannotUndo => isKurdish
      ? 'ئەم کردارە ناگەڕێتەوە.'
      : isArabic
      ? 'لا يمكن التراجع عن هذا الإجراء.'
      : 'This action cannot be undone.';
  String get chat => isKurdish
      ? 'چات'
      : isArabic
      ? 'محادثة'
      : 'Chat';
  String get nothingSaved => isKurdish
      ? 'هیچ شتێک پاشەکەوت نەکراوە.'
      : isArabic
      ? 'لا توجد عناصر محفوظة.'
      : 'Nothing saved yet.';
  String get retryError => isKurdish
      ? 'هەڵەیەک ڕوویدا.'
      : isArabic
      ? 'حدث خطأ.'
      : 'Something went wrong.';

  String institutionType(String type) {
    if (type == 'school') return schools;
    if (type == 'institute') return institutes;
    if (type == 'vocationalFiveYear') return vocationalFiveYear;
    return colleges;
  }
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();
  @override
  bool isSupported(Locale locale) =>
      ['ku', 'en', 'ar'].contains(locale.languageCode);
  @override
  Future<AppStrings> load(Locale locale) =>
      SynchronousFuture<AppStrings>(AppStrings(locale));
  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}
