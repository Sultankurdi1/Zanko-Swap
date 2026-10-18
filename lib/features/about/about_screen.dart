import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final palette = AppThemeScope.of(context);
    final isKu = strings.isKurdish;
    final isAr = strings.isArabic;
    final title = isKu
        ? 'دەربارەی ZankoSwap'
        : isAr
        ? 'عن ZankoSwap'
        : 'About ZankoSwap';

    final sections = isKu
        ? const [
            _AboutSectionData(
              icon: Icons.lightbulb_outline_rounded,
              title: 'بۆچی دروستکراوە؟',
              body:
                  'ZankoSwap بۆ ئەوە دروستکراوە کە خوێندکاران بە ئاسانی پێکەوە ببەستێتەوە و دەستگەیشتن بە کەرەستە و زانیاریی خوێندن ئاسانتر بکات. دەتوانرێت کتێب و کەرەستەی بەکارهاتوو بفرۆشرێت، بگۆڕدرێت یان بەخۆڕایی بدرێت؛ بەمەش سوود بە خوێندکاران دەگات و کەرەستەکان دووبارە بەکاردەهێنرێنەوە.',
            ),
            _AboutSectionData(
              icon: Icons.alt_route_rounded,
              title: 'چۆن کار دەکات؟',
              body:
                  'ئەپەکە وەک بازاڕ و شوێنێکی هاوبەشی دیجیتاڵی بۆ کۆمەڵگەی خوێندکاران کار دەکات. بەکارهێنەر دەتوانێت بابەتێک زیاد بکات، بە زانکۆ و جۆری پێویستی بگەڕێت، بابەتەکانی پاشەکەوت بکات و لە ڕێگەی نامەی تایبەتەوە لەگەڵ خاوەن بابەتەکە پەیوەندی بکات.',
            ),
            _AboutSectionData(
              icon: Icons.grid_view_rounded,
              title: 'چ خزمەتگوزارییەکانی هەیە؟',
              body:
                  'ZankoSwap کتێب و کەرەستەی خوێندن، تێبینی و ئەزمونەکانی پێشوو، توێژینەوە و زانیاریی دامەزراوە خوێندنییەکان لە یەک شوێن کۆدەکاتەوە. هەروەها ڕێگەت پێدەدات بابەت زیاد بکەیت و بفرۆشیت یان بگۆڕیت، لەگەڵ خوێندکارانی تر گفتوگۆ بکەیت و خزمەتگوزاریی نزیک وەک خواردنگە، کافێ و فەنتۆکەپی بدۆزیتەوە.',
            ),
          ]
        : isAr
        ? const [
            _AboutSectionData(
              icon: Icons.lightbulb_outline_rounded,
              title: 'لماذا أُنشئ التطبيق؟',
              body:
                  'أُنشئ ZankoSwap لتسهيل تواصل الطلبة ومساعدتهم في الوصول إلى المواد والمعلومات الدراسية. يمكن للطلبة بيع الكتب والمستلزمات المستعملة أو مبادلتها أو تقديمها مجاناً، ليستفيد منها الآخرون وتُستخدم من جديد.',
            ),
            _AboutSectionData(
              icon: Icons.alt_route_rounded,
              title: 'كيف يعمل؟',
              body:
                  'يعمل التطبيق كسوق ومساحة رقمية مشتركة للطلبة. يمكن للمستخدم إضافة إعلان، والبحث حسب الجامعة ونوع الحاجة، وحفظ الإعلانات، والتواصل مع صاحب الإعلان عبر الرسائل الخاصة.',
            ),
            _AboutSectionData(
              icon: Icons.grid_view_rounded,
              title: 'ما الخدمات التي يقدمها؟',
              body:
                  'يجمع ZankoSwap الكتب والمواد الدراسية والملاحظات وأسئلة الامتحانات السابقة والأبحاث ومعلومات المؤسسات التعليمية في مكان واحد. كما يتيح إضافة الإعلانات وبيعها أو مبادلتها، والتواصل مع الطلبة، والعثور على خدمات قريبة مثل المطاعم والمقاهي ومراكز القرطاسية والنسخ.',
            ),
          ]
        : const [
            _AboutSectionData(
              icon: Icons.lightbulb_outline_rounded,
              title: 'Why we created it',
              body:
                  'ZankoSwap was created to help students connect and make study resources easier to find. Students can sell, exchange, or give away used books and supplies, helping others save money and giving useful items a second life.',
            ),
            _AboutSectionData(
              icon: Icons.alt_route_rounded,
              title: 'How it works',
              body:
                  'The app works as a shared digital marketplace for students. Users can post a listing, browse by university and category, save items, and contact a listing owner through private messages.',
            ),
            _AboutSectionData(
              icon: Icons.grid_view_rounded,
              title: 'What it offers',
              body:
                  'ZankoSwap brings together books and study materials, past exam papers, research, and educational institution information. Students can post items to sell or exchange, message each other, and find nearby services such as restaurants, cafes, and stationery or copy shops.',
            ),
          ];

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: palette.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: palette.accent,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: palette.buttonGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.school_rounded, color: Colors.white, size: 30),
                const SizedBox(height: 12),
                const Text(
                  'ZankoSwap',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isKu
                      ? 'بازاڕێکی خوێندکاری بۆ هاوبەشکردنی کەرەستە و دەرفەت.'
                      : isAr
                      ? 'سوق طلابي لمشاركة المواد والفرص.'
                      : 'A student marketplace for sharing resources and opportunities.',
                  style: const TextStyle(
                    color: Colors.white,
                    height: 1.5,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final section in sections) ...[
            _AboutSection(section: section, palette: palette),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _AboutSectionData {
  final IconData icon;
  final String title;
  final String body;

  const _AboutSectionData({
    required this.icon,
    required this.title,
    required this.body,
  });
}

class _AboutSection extends StatelessWidget {
  final _AboutSectionData section;
  final AppPalette palette;

  const _AboutSection({required this.section, required this.palette});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: palette.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: palette.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(section.icon, color: palette.accent, size: 21),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                section.title,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          section.body,
          textDirection: Directionality.of(context),
          style: TextStyle(
            color: palette.textSecondary,
            height: 1.65,
            fontSize: 13.5,
          ),
        ),
      ],
    ),
  );
}
