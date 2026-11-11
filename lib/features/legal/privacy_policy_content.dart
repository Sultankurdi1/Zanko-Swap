class PolicySection {
  final String title;
  final String body;
  const PolicySection(this.title, this.body);
}

class PrivacyPolicyText {
  final String title;
  final String effective;
  final String agree;
  final String agreeNote;
  final List<PolicySection> sections;
  const PrivacyPolicyText({
    required this.title,
    required this.effective,
    required this.agree,
    required this.agreeNote,
    required this.sections,
  });

  static const version = '2026-11-12';

  static PrivacyPolicyText of(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return arabic;
      case 'en':
        return english;
      default:
        return kurdish;
    }
  }

  static const kurdish = PrivacyPolicyText(
    title: 'سیاسەتی تایبەتمەندی و مەرجەکان',
    effective: 'بەرواری کارپێکردن: ٩ی تشرینی دووەمی ٢٠٢٦',
    agree: 'خوێندمەوە و ڕازیم',
    agreeNote:
        'بە دانانی "ڕازیم"، ڕازی دەبیت بە سیاسەتی تایبەتمەندی و مەرجەکانی بەکارهێنان.',
    sections: [
      PolicySection(
        '١. پێشەکی',
        'ئەم سیاسەتە ڕووندەکاتەوە کە ئەپی ZankoSwap چ زانیارییەک کۆدەکاتەوە، بۆچی، کێ دەیبینێت، و چۆن دەتوانیت بیسڕیتەوە.\n\n'
            'ZankoSwap بازاڕ و ئاڵوگۆڕی ئەکادیمییە بۆ قوتابیانی کوردستان و عێراق. ڕێگە دەدات کتێب و پێداویستی خوێندن بڵاو بکەیتەوە، توێژینەوە و پرسیارەکانی تاقیکردنەوە هاوبەش بکەیت، داشکاندنی قوتابیان لە شوێنەکانی نزیکت بدۆزیتەوە، قوتابخانە و زانکۆکان ببینیت، و لەگەڵ قوتابیانی تر چات بکەیت. بە بەکارهێنانی ئەپەکە، ڕازی دەبیت بەم سیاسەتە.',
      ),
      PolicySection(
        '٢. ئەو زانیارییانەی کۆیان دەکەینەوە',
        'تەنها ئەوە کۆدەکەینەوە کە خۆت دەیدەیت و ئەپەکە بۆ کارکردن پێویستی پێیەتی. ناوی پەیوەندییەکانت، تۆماری پەیوەندییەکان، یان شوێنی تۆ لە پشتەوە کۆناکەینەوە.\n\n'
            '• هەژمار: ئیمەیڵ یان ژمارەی تەلەفۆن، و وشەی نهێنی بە شێوەی شاردراوە.\n'
            '• چوونەژوورەوە بە Google: ناو، ئیمەیڵ و وێنەی هەژماری Google (لە Android).\n'
            '• پرۆفایل: ناو، وێنە، و ژمارەی تەلەفۆن ئەگەر بتەوێت.\n'
            '• ڕێکەوتی لەدایکبوون: تەنها بۆ دڵنیابوون لەوەی تەمەنت ١٣ ساڵ یان زیاترە. بە کەس پیشان نادرێت.\n'
            '• بابەتەکان: ناونیشان، وەسف، نرخ، باری بابەت، وێنە، زانکۆ، کۆلێژ، بەش و قۆناغ.\n'
            '• شوێنەکان: ناو، جۆر، ناونیشان، تەلەفۆن، داشکاندن، لینکی مینیو، وێنە، و ئەو شوێنەی لەسەر نەخشە دیاری دەکەیت. شوێنی مۆبایلەکەت تەنها ئەو کاتە بەکاردێت کە خۆت کلیک لە "شوێنی ئێستام" دەکەیت، و جیا هەڵناگیرێت. نەخشەکە لە OpenStreetMap ـەوە باردەکرێت.\n'
            '• توێژینەوە و پرسیارەکانی تاقیکردنەوە: ناونیشان، وەسف، لینک، فایل و وێنە.\n'
            '• چات: نامەکانت، ئەو کەسانەی چاتیان لەگەڵ دەکەیت، خوێندرانەوەی نامە، بلۆک و ڕاپۆرتەکان.\n'
            '• ڕیکلام: دەق، وێنە، لینک، بودجە، و وێنەی وەسڵی پارەدان (FastPay یان FIB).\n'
            '• هەڵسەنگاندن: ئەو ئەستێرانەی بە کەسانێک دەدەیت کە چاتت لەگەڵیان کردووە.\n'
            '• ڕاپۆرتی هەڵە: کاتێک ئەپەکە تووشی هەڵە دەبێت، پەیامی هەڵەکە، زانیاری تەکنیکی، جۆری مۆبایل (Android یان iOS)، وەشانی ئەپ و ناسنامەی هەژمارەکەت.\n'
            '• ئامێر: تۆکنی ئاگادارکردنەوە (notification) بۆ ئامێرەکەت (لە Android).\n'
            '• دڵخوازەکان و ڕێکخستنەکان: لەسەر ئامێرەکەی خۆت هەڵدەگیرێن.\n\n'
            'وێنە و کامێرا تەنها کاتێک بەکاردێن کە خۆت وێنەیەک هەڵدەبژێریت یان دەیگریت.',
      ),
      PolicySection(
        '٣. چۆن زانیارییەکانت بەکاردەهێنین',
        'تەنها بۆ کارپێکردنی ZankoSwap بەکاریان دەهێنین. نایانفرۆشین و بۆ ڕیکلامی لایەنی سێیەم بەکاریان ناهێنین.\n\n'
            '• دروستکردن و پاراستنی هەژمارەکەت.\n'
            '• نیشاندانی بابەت، شوێن، توێژینەوە و پرسیارەکانت بە قوتابیانی تر.\n'
            '• گەیاندنی نامەکان و ناردنی ئاگادارکردنەوە بۆ نامەی نوێ و شوێنی نوێ.\n'
            '• پشکنینی ڕیکلام و وەسڵی پارەدان پێش بڵاوکردنەوە.\n'
            '• پشکنینی ئەو دامەزراوانەی بەکارهێنەران پێشنیاری دەکەن.\n'
            '• پشکنینی خۆکاری دەقی نامە، ناو، بابەت و شوێنەکان بۆ ڕێگریکردن لە وشەی سێکسی، بێڕێزی و هەڕەشە. ئەم پشکنینە لە سێرڤەر و بێ دەستی مرۆڤ دەکرێت.\n'
            '• مامەڵەکردن لەگەڵ ڕاپۆرت، بلۆککردنی بەکارهێنەری خراپ، و لابردنی ناوەڕۆکی زیانبەخش.\n'
            '• چاککردنی کێشەکان.',
      ),
      PolicySection(
        '٤. بەکارهێنەرانی تر چی دەبینن',
        'بەکارهێنەرانی تر ناو و وێنەی پرۆفایلت و ئەوەی بڵاوی دەکەیتەوە دەبینن. ئیمەیڵ و ژمارەی تەلەفۆنی پرۆفایلت هەرگیز بۆ کەس نیشان نادرێت.\n\n'
            '• بۆ هەمووان، میوانانیش: بابەتە چالاکەکانت، شوێنەکان (بە تەلەفۆن و شوێنی سەر نەخشەوە)، توێژینەوە، پرسیارەکانی تاقیکردنەوە، و ڕیکلامە پەسەندکراوەکان.\n'
            '• تەنها تۆ و کەسەکەی تر: نامەکانی چات.\n'
            '• تەنها تۆ و ئەدمینەکانمان: وەسڵی پارەدانی ڕیکلام.\n'
            '• تەنها تۆ: دڵخوازەکان، بلۆکەکان و ڕاپۆرتەکانت.\n'
            '• هەڵسەنگاندن: تەنها تێکڕای ئەستێرەکان و ژمارەیان پیشان دەدرێت، نەک ئەوەی کێ چ ئەستێرەیەکی داوە.\n\n'
            'ئەگەر ژمارەی تەلەفۆن لە بابەت یان شوێنێکدا دابنێیت، بۆ هەمووان دیارە.',
      ),
      PolicySection(
        '٥. ئەو کۆمپانیایانەی خزمەتگوزاریمان پێدەدەن',
        'تەنها لەگەڵ ئەو کۆمپانیایانە هاوبەشی دەکەین کە بەشێک لە ئەپەکە بەڕێوەدەبەن. لەوانەیە زانیارییەکان لە سێرڤەری دەرەوەی عێراق هەڵبگیرێن.\n\n'
            '• Supabase: هەژمار، داتابەیس و هەڵگرتنی فایل.\n'
            '• Google Firebase Cloud Messaging: ناردنی ئاگادارکردنەوە.\n'
            '• Google Sign-In: چوونەژوورەوە بە Google ئەگەر هەڵیبژێریت.\n'
            '• Sightengine: پشکنینی خۆکاری ئەو وێنانەی بەرزیان دەکەیتەوە بۆ ڕووتی، پێش بڵاوکردنەوە.\n\n'
            'لەوانەیە زانیاری هاوبەش بکەین ئەگەر یاسا داوای بکات، یان بۆ پاراستنی بەکارهێنەران لە فێڵ و زیان.',
      ),
      PolicySection(
        '٦. ماوەی هەڵگرتن و سڕینەوەی هەژمار',
        'هەر کاتێک بتەوێت دەتوانیت هەژمارەکەت لە ناو ئەپەکە بسڕیتەوە: بچۆ بۆ پرۆفایل، کلیک لە "سڕینەوەی هەژمار" بکە و دڵنیای بکەرەوە. ئەمە هەژمار، پرۆفایل، بابەت، شوێن، توێژینەوە، پرسیار، چات، نامە، دڵخوازەکان، تۆکنی ئامێر، و وێنە و وەسڵەکانت بە یەکجاری دەسڕێتەوە.\n\n'
            '• چاتەکان دوای ٢٤ کاتژمێر بێ نامەی نوێ خۆکار دەسڕدرێنەوە.\n'
            '• ئەوەی خۆت دەیسڕیتەوە یەکسەر لادەبرێت.\n'
            '• ڕاپۆرتەکانت لەگەڵ هەژمارەکەت دەسڕدرێنەوە.\n'
            '• کۆپییە یەدەکەکانی کۆمپانیاکان بەپێی خشتەی ئاسایی خۆیان دەسڕدرێنەوە.\n\n'
            'ئەگەر نەتوانیت ئەپەکە بکەیتەوە، لە ئیمەیڵی هەژمارەکەتەوە نامەمان بۆ بنێرە و بۆت دەسڕینەوە.',
      ),
      PolicySection(
        '٧. ئاسایش',
        'هەموو زانیارییەکان بە پەیوەندی شفرەکراو (HTTPS) دەگوازرێنەوە، و وشەی نهێنی تەنها بە شێوەی شاردراوە هەڵدەگیرێت. یاساکانی داتابەیس وا دەکەن هەر بەکارهێنەرێک تەنها بتوانێت ناوەڕۆکی خۆی بگۆڕێت و تەنها چاتەکانی خۆی بخوێنێتەوە.\n\n'
            'وەسڵی پارەدان لە شوێنێکی تایبەت هەڵدەگیرێت کە تەنها تۆ و ئەدمینەکانمان دەتوانن بیکەنەوە. هیچ سیستەمێک بە تەواوی پارێزراو نییە، بۆیە وشەی نهێنی بەهێز بەکاربهێنە و بە کەسی مەدە.',
      ),
      PolicySection(
        '٨. مافەکانت',
        '• بینین و دەستکاریکردنی پرۆفایل، بابەت، شوێن، توێژینەوە و پرسیارەکانت.\n'
            '• سڕینەوەی هەر شتێک کە بڵاوت کردۆتەوە، هەر نامەیەک، یان هەموو هەژمارەکەت.\n'
            '• شاردنەوەی چاتێک، یان بلۆک و ڕاپۆرتکردنی بەکارهێنەرێک.\n'
            '• کوژاندنەوەی ئاگادارکردنەوەکان لە ڕێکخستنەکانی مۆبایلەکەت.\n'
            '• بینینی ئەپەکە وەک میوان بەبێ هەژمار. هەژمار تەنها بۆ بڵاوکردنەوە و چات پێویستە.\n'
            '• داواکردنی کۆپییەک لە زانیارییەکانت یان چاککردنیان بە ئیمەیڵ.',
      ),
      PolicySection(
        '٩. منداڵان',
        'ZankoSwap بۆ قوتابیانی ١٣ ساڵ و سەرووترە. لە کاتی دروستکردنی هەژماردا ڕێکەوتی لەدایکبوون دەپرسین، و ئەگەر تەمەن لە ١٣ ساڵ کەمتر بێت هەژمارەکە دەسڕدرێتەوە. بە ئاگاداری زانیاری لە منداڵانی خوار ١٣ ساڵ کۆناکەینەوە. ئەگەر پێتوایە منداڵێکی خوار ١٣ ساڵ هەژماری دروست کردووە، ئیمەیڵمان بۆ بنێرە و دەیسڕینەوە.',
      ),
      PolicySection(
        '١٠. گۆڕانکاری و پەیوەندی',
        'ئەگەر ئەم سیاسەتە بگۆڕین، بەرواری سەرەوە نوێ دەکەینەوە، و بۆ گۆڕانکاری گرنگ لە ناو ئەپەکە ئاگادارت دەکەینەوە.\n\n'
            'ئیمەیڵ: tahasulaiman135@gmail.com\n'
            'واتسئاپ: ‎+964 750 435 9605\n'
            'تەلەفۆن: ‎+964 750 435 9605 یان ‎+964 773 405 9605',
      ),
      PolicySection(
        '١١. مەرجەکانی بەکارهێنان',
        'بە بەکارهێنانی ZankoSwap ڕازی دەبیت بەم مەرجانە. هیچ لێبوردنێک بۆ ناوەڕۆکی نەشیاو یان بەکارهێنەری خراپ نییە.\n\n'
            '• قسە، وێنە یان ناوەڕۆکی سێکسی، ڕووتی، هەڕەشە، جنێو، ڕەگەزپەرستی، ئازاردان یان فێڵ قەدەغەیە.\n'
            '• تەنها ئەو شتانە بڵاو بکەرەوە کە مافی خۆتە و ڕاستن.\n'
            '• هەر ناوەڕۆکێکی ڕاپۆرتکراو لە ماوەی ٢٤ کاتژمێردا دەپشکنین و ئەگەر یاسا شکێن بوو لایدەبەین.\n'
            '• ئەو کەسانەی ئەم مەرجانە دەشکێنن، هەژمارەکەیان ڕادەگیرێت یان دەسڕدرێتەوە.\n'
            '• دەتوانیت هەر بەکارهێنەرێک بلۆک بکەیت و هەر نامە، بابەت یان شوێنێک ڕاپۆرت بکەیت.',
      ),
    ],
  );

  static const arabic = PrivacyPolicyText(
    title: 'سياسة الخصوصية والشروط',
    effective: 'تاريخ السريان: ٩ تشرين الثاني ٢٠٢٦',
    agree: 'قرأتها وأوافق',
    agreeNote:
        'بالضغط على "أوافق"، فإنك توافق على سياسة الخصوصية وشروط الاستخدام.',
    sections: [
      PolicySection(
        '١. مقدمة',
        'توضح هذه السياسة المعلومات التي يجمعها تطبيق ZankoSwap، ولماذا، ومن يمكنه رؤيتها، وكيف يمكنك حذفها.\n\n'
            'ZankoSwap سوق وتبادل أكاديمي لطلاب كردستان والعراق. يتيح لك نشر الكتب ومستلزمات الدراسة، ومشاركة الأبحاث وأسئلة الامتحانات السابقة، والعثور على خصومات الطلاب في الأماكن القريبة، وتصفح المدارس والجامعات، والدردشة مع الطلاب الآخرين. باستخدامك للتطبيق، فإنك توافق على هذه السياسة.',
      ),
      PolicySection(
        '٢. المعلومات التي نجمعها',
        'نجمع فقط ما تقدمه لنا وما يحتاجه التطبيق ليعمل. لا نجمع جهات اتصالك أو سجل مكالماتك أو موقعك في الخلفية.\n\n'
            '• الحساب: البريد الإلكتروني أو رقم الهاتف، وكلمة مرور مشفرة.\n'
            '• تسجيل الدخول عبر Google: الاسم والبريد الإلكتروني وصورة الحساب (على Android).\n'
            '• الملف الشخصي: الاسم والصورة ورقم الهاتف اختياريًا.\n'
            '• تاريخ الميلاد: فقط للتأكد من أن عمرك ١٣ عامًا أو أكثر. لا يُعرض لأي أحد.\n'
            '• الإعلانات المنشورة: العنوان والوصف والسعر والحالة والصور والجامعة والكلية والقسم والمرحلة.\n'
            '• الأماكن: الاسم والنوع والعنوان والهاتف والعرض ورابط القائمة والصورة والموقع الذي تحدده على الخريطة. يُستخدم موقع هاتفك فقط عندما تضغط على "موقعي الحالي" ولا يُحفظ بشكل منفصل. تُحمَّل الخريطة من OpenStreetMap.\n'
            '• الأبحاث وأسئلة الامتحانات: العناوين والأوصاف والروابط والملفات والصور.\n'
            '• الدردشة: رسائلك، والأشخاص الذين تتحدث معهم، وحالة القراءة، والحظر والبلاغات.\n'
            '• الإعلانات المدفوعة: النص والصورة والرابط والميزانية وصورة إيصال الدفع (FastPay أو FIB).\n'
            '• التقييمات: النجوم التي تمنحها لأشخاص تحدثت معهم.\n'
            '• تقارير الأخطاء: عند حدوث خطأ في التطبيق، رسالة الخطأ والتفاصيل التقنية ونوع الهاتف (Android أو iOS) وإصدار التطبيق ومعرّف حسابك.\n'
            '• الجهاز: رمز الإشعارات لجهازك (على Android).\n'
            '• المفضلة والإعدادات: تُحفظ على جهازك.\n\n'
            'تُستخدم الصور والكاميرا فقط عندما تختار صورة أو تلتقطها بنفسك.',
      ),
      PolicySection(
        '٣. كيف نستخدم معلوماتك',
        'نستخدمها فقط لتشغيل ZankoSwap. لا نبيعها ولا نستخدمها لإعلانات جهات خارجية.\n\n'
            '• إنشاء حسابك وحمايته.\n'
            '• عرض إعلاناتك وأماكنك وأبحاثك وأسئلتك للطلاب الآخرين.\n'
            '• توصيل الرسائل وإرسال إشعارات الرسائل الجديدة والأماكن الجديدة.\n'
            '• مراجعة الإعلانات وإيصالات الدفع قبل النشر.\n'
            '• مراجعة المؤسسات التي يقترحها المستخدمون.\n'
            '• فحص تلقائي لنصوص الرسائل والأسماء والإعلانات والأماكن لمنع الكلمات الجنسية والمسيئة والتهديدية. يتم هذا الفحص على الخادم دون تدخل بشري.\n'
            '• معالجة البلاغات وحظر المستخدمين المسيئين وإزالة المحتوى الضار.\n'
            '• إصلاح المشكلات.',
      ),
      PolicySection(
        '٤. ما يراه المستخدمون الآخرون',
        'يرى المستخدمون الآخرون اسمك وصورتك وما تنشره. لا يظهر بريدك الإلكتروني ورقم هاتف ملفك الشخصي لأي أحد.\n\n'
            '• للجميع، بمن فيهم الزوار: إعلاناتك النشطة، والأماكن (مع الهاتف والموقع)، والأبحاث، وأسئلة الامتحانات، والإعلانات المعتمدة.\n'
            '• أنت والطرف الآخر فقط: رسائل الدردشة.\n'
            '• أنت ومشرفونا فقط: إيصالات دفع الإعلانات.\n'
            '• أنت فقط: المفضلة والحظر والبلاغات.\n'
            '• التقييمات: يظهر متوسط النجوم وعددها فقط، وليس من أعطى كل تقييم.\n\n'
            'إذا وضعت رقم هاتف في إعلان أو مكان، فسيكون مرئيًا للجميع.',
      ),
      PolicySection(
        '٥. مزودو الخدمة',
        'نشارك البيانات فقط مع الشركات التي تشغّل أجزاء من التطبيق لصالحنا. قد تُخزَّن البيانات على خوادم خارج العراق.\n\n'
            '• Supabase: الحسابات وقاعدة البيانات وتخزين الملفات.\n'
            '• Google Firebase Cloud Messaging: الإشعارات.\n'
            '• Google Sign-In: تسجيل الدخول عبر Google إذا اخترته.\n'
            '• Sightengine: فحص تلقائي للصور التي ترفعها بحثًا عن العري قبل نشرها.\n\n'
            'قد نشارك المعلومات إذا طلب القانون ذلك، أو لحماية المستخدمين من الاحتيال والضرر.',
      ),
      PolicySection(
        '٦. مدة الاحتفاظ وحذف الحساب',
        'يمكنك حذف حسابك في أي وقت من داخل التطبيق: افتح الملف الشخصي، واضغط "حذف الحساب" ثم أكّد. يحذف هذا نهائيًا حسابك وملفك وإعلاناتك وأماكنك وأبحاثك وأسئلتك ودردشاتك ورسائلك والمفضلة ورموز الجهاز والصور والإيصالات.\n\n'
            '• تُحذف المحادثات تلقائيًا بعد ٢٤ ساعة دون رسائل جديدة.\n'
            '• ما تحذفه بنفسك يُزال فورًا.\n'
            '• تُحذف بلاغاتك مع حسابك.\n'
            '• تُستبدل النسخ الاحتياطية لدى المزودين وفق جدولها المعتاد.\n\n'
            'إذا لم تتمكن من فتح التطبيق، راسلنا من بريد حسابك وسنحذفه لك.',
      ),
      PolicySection(
        '٧. الأمان',
        'تنتقل جميع البيانات عبر اتصالات مشفرة (HTTPS)، وتُخزن كلمات المرور بشكل مشفر فقط. تضمن قواعد قاعدة البيانات أن كل مستخدم يمكنه تعديل محتواه فقط وقراءة دردشاته فقط.\n\n'
            'تُحفظ إيصالات الدفع في تخزين خاص لا يفتحه إلا أنت ومشرفونا. لا يوجد نظام آمن تمامًا، لذا استخدم كلمة مرور قوية ولا تشاركها.',
      ),
      PolicySection(
        '٨. حقوقك',
        '• عرض وتعديل ملفك وإعلاناتك وأماكنك وأبحاثك وأسئلتك.\n'
            '• حذف أي شيء نشرته، أو أي رسالة، أو حسابك بالكامل.\n'
            '• إخفاء محادثة، أو حظر مستخدم والإبلاغ عنه.\n'
            '• إيقاف الإشعارات من إعدادات هاتفك.\n'
            '• تصفح التطبيق كزائر دون حساب. الحساب مطلوب فقط للنشر والدردشة.\n'
            '• طلب نسخة من بياناتك أو تصحيحها عبر البريد الإلكتروني.',
      ),
      PolicySection(
        '٩. الأطفال',
        'ZankoSwap مخصص للطلاب من عمر ١٣ عامًا فأكثر. نسأل عن تاريخ الميلاد عند إنشاء الحساب، ويُحذف الحساب إذا كان العمر أقل من ١٣ عامًا. لا نجمع عن علم معلومات من أطفال دون ١٣ عامًا. إذا كنت تعتقد أن طفلًا دون ١٣ عامًا أنشأ حسابًا، راسلنا وسنحذفه.',
      ),
      PolicySection(
        '١٠. التغييرات والتواصل',
        'إذا غيّرنا هذه السياسة، سنحدّث التاريخ في الأعلى، وسنبلغك داخل التطبيق بالتغييرات المهمة.\n\n'
            'البريد الإلكتروني: tahasulaiman135@gmail.com\n'
            'واتساب: ‎+964 750 435 9605\n'
            'الهاتف: ‎+964 750 435 9605 أو ‎+964 773 405 9605',
      ),
      PolicySection(
        '١١. شروط الاستخدام',
        'باستخدامك ZankoSwap فإنك توافق على هذه الشروط. لا تسامح إطلاقًا مع المحتوى غير اللائق أو المستخدمين المسيئين.\n\n'
            '• يُمنع الكلام أو الصور أو المحتوى الجنسي أو العاري، والتهديد، والشتائم، والعنصرية، والتحرش، والاحتيال.\n'
            '• انشر فقط ما تملك حقه وما هو صحيح.\n'
            '• نراجع أي محتوى مُبلغ عنه خلال ٢٤ ساعة ونزيله إذا خالف الشروط.\n'
            '• يتم إيقاف أو حذف حسابات من يخالفون هذه الشروط.\n'
            '• يمكنك حظر أي مستخدم والإبلاغ عن أي رسالة أو إعلان أو مكان.',
      ),
    ],
  );

  static const english = PrivacyPolicyText(
    title: 'Privacy Policy & Terms',
    effective: 'Effective date: November 9, 2026',
    agree: 'I have read it and agree',
    agreeNote:
        'By tapping "I agree", you accept the Privacy Policy and Terms of Use.',
    sections: [
      PolicySection(
        '1. Introduction',
        'This policy explains what information the ZankoSwap app collects, why, who can see it, and how you can delete it.\n\n'
            'ZankoSwap is a student marketplace and academic exchange for Kurdistan and Iraq. It lets students list books and study items, share research and past exam papers, find student discounts at nearby places, browse schools and universities, and chat with each other. By using the app, you agree to this policy.',
      ),
      PolicySection(
        '2. Information we collect',
        'We collect only what you give us and what the app needs to work. We do not collect your contacts, call logs, or background location.\n\n'
            '• Account: email address or phone number, and an encrypted password.\n'
            '• Google sign-in: name, email address, and profile photo from your Google account (Android).\n'
            '• Profile: display name, profile photo, and optional phone number.\n'
            '• Date of birth: only to confirm you are 13 or older. It is never shown to anyone.\n'
            '• Listings: title, description, price, condition, photos, university, college, department, and stage.\n'
            '• Places: name, type, address, phone, offer, menu link, photo, and the map location you choose. Your phone\'s location is used only when you tap "My location" and is not stored separately. Map tiles load from OpenStreetMap.\n'
            '• Research and exam papers: titles, descriptions, links, files, and photos.\n'
            '• Chat: messages you send, the people you chat with, read status, blocks, and reports.\n'
            '• Ads: ad text, image, link, budget, and a photo of your payment receipt (FastPay or FIB).\n'
            '• Ratings: the stars you give to people you have chatted with.\n'
            '• Error reports: when the app hits an error, the error message, technical details, phone platform (Android or iOS), app version, and your account ID.\n'
            '• Device: a push notification token for your device (Android).\n'
            '• Saved items and settings: stored on your device.\n\n'
            'Photos and the camera are used only when you pick or take a photo.',
      ),
      PolicySection(
        '3. How we use your information',
        'We use your information only to run ZankoSwap. We do not sell it, and we do not use it for third-party advertising.\n\n'
            '• Create and secure your account.\n'
            '• Show your listings, places, research, and exam papers to other students.\n'
            '• Deliver chat messages and send notifications about new messages and new places.\n'
            '• Review ads and payment receipts before an ad goes live.\n'
            '• Review suggested schools and institutions before they are published.\n'
            '• Automatically check the text of messages, names, listings, and places to block sexual, abusive, and threatening words. This check runs on our server without a person reading your messages.\n'
            '• Handle reports, block abusive users, and remove harmful content.\n'
            '• Fix problems and keep the app working.',
      ),
      PolicySection(
        '4. What other users can see',
        'Other users see your display name and profile photo, plus anything you publish. Your email address and the phone number on your profile are never shown to other users.\n\n'
            '• Everyone, including guests: your active listings, places (including their phone and location), research, exam papers, and approved ads.\n'
            '• Only you and the other person: your chat messages.\n'
            '• Only you and our admins: your ad payment receipts.\n'
            '• Only you: your favorites, blocks, and reports.\n'
            '• Ratings: only the average and number of stars are shown, never who gave which rating.\n\n'
            'If you put a phone number in a listing or a place, it is public.',
      ),
      PolicySection(
        '5. Service providers',
        'We share data only with the providers that run parts of the app for us. Data may be stored on servers outside Iraq.\n\n'
            '• Supabase: accounts, database, and file storage.\n'
            '• Google Firebase Cloud Messaging: push notifications.\n'
            '• Google Sign-In: optional sign-in with Google.\n'
            '• Sightengine: automatic nudity check of photos you upload, before they are published.\n\n'
            'We may also share information when the law requires it, or to protect users from fraud, abuse, or harm.',
      ),
      PolicySection(
        '6. Data retention and account deletion',
        'You can delete your account at any time inside the app: open Profile, tap "Delete account", and confirm. This permanently deletes your account, profile, listings, places, research, exam papers, chats, messages, favorites, device tokens, and uploaded photos and receipts.\n\n'
            '• Conversations are deleted automatically after 24 hours with no new messages.\n'
            '• Content you delete yourself is removed right away.\n'
            '• Reports you sent are deleted with your account.\n'
            '• Backups held by our providers are overwritten on their normal schedule.\n\n'
            'If you cannot open the app, email us from the address on your account and we will delete it for you.',
      ),
      PolicySection(
        '7. Security',
        'All data travels over encrypted connections (HTTPS), and passwords are stored only in hashed form. Database rules make sure each user can change only their own content and read only their own chats.\n\n'
            'Payment receipts are kept in private storage that only you and our admins can open. No system is perfectly secure, so please use a strong password and do not share it.',
      ),
      PolicySection(
        '8. Your rights and choices',
        '• See and edit your profile, listings, places, research, and exam papers.\n'
            '• Delete anything you posted, any message you sent, or your whole account.\n'
            '• Hide a conversation, or block and report a user.\n'
            '• Turn off notifications in your phone\'s settings.\n'
            '• Browse as a guest without an account. You need an account only to post or chat.\n'
            '• Ask us by email for a copy of your data, or to correct it.',
      ),
      PolicySection(
        '9. Children',
        'ZankoSwap is for students aged 13 and older. We ask for your date of birth when you create an account, and accounts under 13 are deleted. We do not knowingly collect information from children under 13. If you believe a child under 13 has created an account, email us and we will delete it.',
      ),
      PolicySection(
        '10. Changes and contact',
        'If we change this policy, we will update the effective date at the top and, for important changes, tell you in the app.\n\n'
            'Email: tahasulaiman135@gmail.com\n'
            'WhatsApp: +964 750 435 9605\n'
            'Phone: +964 750 435 9605 or +964 773 405 9605',
      ),
      PolicySection(
        '11. Terms of use',
        'By using ZankoSwap you agree to these terms. There is zero tolerance for objectionable content or abusive users.\n\n'
            '• Sexual or nude content, threats, insults, racism, harassment, and scams are not allowed, in words or images.\n'
            '• Post only what you have the right to share and what is true.\n'
            '• We review reported content within 24 hours and remove it if it breaks these terms.\n'
            '• Accounts that break these terms are suspended or deleted.\n'
            '• You can block any user and report any message, listing, or place.',
      ),
    ],
  );
}
