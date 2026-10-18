import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/localization/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../core/notifications/push_notification_service.dart';
import '../features/splash/animated_splash_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/listings/presentation/add_listing_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/institutions/presentation/institution_directory_screen.dart';
import '../features/research/presentation/research_list_screen.dart';
import '../features/exams/presentation/exam_papers_screen.dart';
import '../features/courses_screen.dart';
import '../features/services_screen.dart';
import '../features/ads/presentation/create_ad_screen.dart';
import '../features/saved/presentation/saved_screen.dart';
import '../features/listings/presentation/my_listings_screen.dart';
import '../features/contact_us_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/chat/presentation/inbox_screen.dart';

class ZankoSwapApp extends StatefulWidget {
  const ZankoSwapApp({super.key});
  @override
  State<ZankoSwapApp> createState() => _ZankoSwapAppState();
}

class _ZankoSwapAppState extends State<ZankoSwapApp> {
  Locale locale = const Locale('ku');
  ThemeMode themeMode = ThemeMode.dark;
  Color themeSeed = const Color(0xFF10B981);
  AppPalette currentPalette = AppPalette.emerald;
  int index = 0;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    final presetId = p.getString('app_theme_preset') ?? 'emerald';
    final palette = AppPalette.fromId(presetId);
    setState(() {
      currentPalette = palette;
      themeMode = palette.isDark ? ThemeMode.dark : ThemeMode.light;
      themeSeed = palette.primary;
    });
  }

  void setLocale(Locale value) => setState(() => locale = value);

  void setTheme(bool dark) {
    setState(() => themeMode = dark ? ThemeMode.dark : ThemeMode.light);
    SharedPreferences.getInstance().then((p) => p.setBool('darkMode', dark));
  }

  void setThemeSeed(Color color) {
    setState(() => themeSeed = color);
    SharedPreferences.getInstance().then(
      (p) => p.setInt('themeSeed', color.toARGB32()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeScope(
      palette: currentPalette,
      child: MaterialApp(
        navigatorKey: PushNotificationService.navigatorKey,
        title: 'ZankoSwap',
        debugShowCheckedModeBanner: false,
        locale: locale,
        theme: ZankoTheme.buildFromPalette(currentPalette),
        darkTheme: ZankoTheme.buildFromPalette(currentPalette),
        themeMode: themeMode,
        supportedLocales: const [Locale('ku'), Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          AppStrings.delegate,
          _KurdishMaterialLocalizationsDelegate(),
          _KurdishWidgetsLocalizationsDelegate(),
          _KurdishCupertinoLocalizationsDelegate(),
        ],
        home: _showSplash
            ? AnimatedSplashScreen(
                onLanguageChanged: setLocale,
                onOpenSettings: () {},
                onNavigateToTab: (i) {},
                onFinished: () {
                  if (mounted) {
                    setState(() => _showSplash = false);
                  }
                },
              )
            : Builder(
                builder: (context) {
                  final s = AppStrings.of(context);
                  final palette = AppThemeScope.of(context);
                  final myId = Supabase.instance.client.auth.currentUser?.id;

                  final pages = [
                    HomeScreen(
                      onLanguageChanged: setLocale,
                      onNavigateToTab: (i) => setState(() => index = i),
                      onOpenSettings: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SettingsScreen(
                            isDark: themeMode == ThemeMode.dark,
                            onDarkChanged: setTheme,
                            locale: locale,
                            onLocaleChanged: setLocale,
                            themeSeed: themeSeed,
                            onThemeSeedChanged: (col) {
                              _loadPrefs();
                            },
                          ),
                        ),
                      ).then((_) => _loadPrefs()),
                    ),
                    const SavedScreen(),
                    const InboxScreen(),
                    ProfileScreen(
                      onOpenSettings: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SettingsScreen(
                            isDark: themeMode == ThemeMode.dark,
                            onDarkChanged: setTheme,
                            locale: locale,
                            onLocaleChanged: setLocale,
                            themeSeed: themeSeed,
                            onThemeSeedChanged: (col) {
                              _loadPrefs();
                            },
                          ),
                        ),
                      ).then((_) => _loadPrefs()),
                    ),
                  ];

                  return PopScope(
                    canPop: index == 0,
                    onPopInvokedWithResult: (didPop, result) {
                      if (didPop) return;
                      setState(() => index = 0);
                    },
                    child: Directionality(
                      textDirection:
                          (locale.languageCode == 'ku' ||
                              locale.languageCode == 'ar')
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      child: Scaffold(
                        backgroundColor: palette.bg,
                        body: IndexedStack(index: index, children: pages),
                        bottomNavigationBar: Container(
                          decoration: BoxDecoration(
                            color: palette.surface,
                            border: Border(
                              top: BorderSide(color: palette.border, width: 1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: palette.isDark ? 0.35 : 0.08,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, -4),
                              ),
                            ],
                          ),
                          child: SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildNavItem(
                                    palette: palette,
                                    icon: Icons.home_rounded,
                                    outlinedIcon: Icons.home_outlined,
                                    label: s.home,
                                    isSelected: index == 0,
                                    onTap: () => setState(() => index = 0),
                                  ),
                                  _buildNavItem(
                                    palette: palette,
                                    icon: Icons.bookmark_rounded,
                                    outlinedIcon: Icons.bookmark_border_rounded,
                                    label: s.saved,
                                    isSelected: index == 1,
                                    onTap: () => setState(() => index = 1),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const AddListingScreen(),
                                      ),
                                    ).then((_) => _loadPrefs()),
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: palette.buttonGradient,
                                        boxShadow: [
                                          BoxShadow(
                                            color: palette.primary.withValues(
                                              alpha: 0.45,
                                            ),
                                            blurRadius: 12,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.add_rounded,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                  ),

                                  StreamBuilder<List<Map<String, dynamic>>>(
                                    stream: Supabase.instance.client
                                        .from('chats')
                                        .stream(primaryKey: ['id']),
                                    builder: (context, chatSnapshot) {
                                      final chatRows = chatSnapshot.data ?? [];
                                      final chatIds = chatRows
                                          .where((c) {
                                            return c['buyerId'] == myId ||
                                                c['sellerId'] == myId;
                                          })
                                          .map((c) => c['id'].toString())
                                          .toSet();
                                      return StreamBuilder<
                                        List<Map<String, dynamic>>
                                      >(
                                        stream: Supabase.instance.client
                                            .from('messages')
                                            .stream(primaryKey: ['id']),
                                        builder: (context, messageSnapshot) {
                                          final unreadCount =
                                              (messageSnapshot.data ?? [])
                                                  .where((m) {
                                                    return chatIds.contains(
                                                          m['chatId']
                                                              ?.toString(),
                                                        ) &&
                                                        m['senderId']
                                                                ?.toString() !=
                                                            myId &&
                                                        m['isRead'] != true &&
                                                        m['is_read'] != true;
                                                  })
                                                  .length;
                                          return _buildNavItem(
                                            palette: palette,
                                            icon: Icons.chat_bubble_rounded,
                                            outlinedIcon: Icons
                                                .chat_bubble_outline_rounded,
                                            label: s.messages,
                                            isSelected: index == 2,
                                            badgeCount: unreadCount,
                                            onTap: () =>
                                                setState(() => index = 2),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  _buildNavItem(
                                    palette: palette,
                                    icon: Icons.person_rounded,
                                    outlinedIcon: Icons.person_outline_rounded,
                                    label: s.profile,
                                    isSelected: index == 3,
                                    onTap: () => setState(() => index = 3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
        routes: {
          '/add': (_) => const AddListingScreen(),
          '/add-study': (_) => const AddListingScreen(initialType: 'handout'),
          '/institutions': (_) => const InstitutionDirectoryScreen(),
          '/research': (_) => const ResearchListScreen(),
          '/exams': (_) => const ExamPapersScreen(),
          '/courses': (_) => const CoursesScreen(),
          '/services': (_) => const ServicesScreen(),
          '/restaurants': (_) =>
              const ServicesScreen(initialCategory: 'restaurant'),
          '/cafes': (_) => const ServicesScreen(initialCategory: 'cafe'),
          '/stationery': (_) => const ServicesScreen(initialCategory: 'copy'),
          '/advertise': (_) => const CreateAdScreen(),
          '/my-listings': (_) => const MyListingsScreen(),
          '/contact': (_) => const ContactUsScreen(),
          '/saved': (_) => const SavedScreen(),
          '/sign-in': (_) => const SignInScreen(),
        },
      ),
    );
  }

  Widget _buildNavItem({
    required AppPalette palette,
    required IconData icon,
    required IconData outlinedIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    final activeColor = palette.accent;
    final inactiveColor = palette.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: badgeCount > 0,
              backgroundColor: const Color(0xFFEF4444),
              label: Text(
                badgeCount > 9 ? '9+' : '$badgeCount',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              child: Icon(
                isSelected ? icon : outlinedIcon,
                color: isSelected ? activeColor : inactiveColor,
                size: 23,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KurdishMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _KurdishMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'ku' ||
      locale.languageCode == 'en' ||
      locale.languageCode == 'ar';

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return GlobalMaterialLocalizations.delegate.load(
      (locale.languageCode == 'ku' || locale.languageCode == 'ar')
          ? const Locale('en')
          : locale,
    );
  }

  @override
  bool shouldReload(_KurdishMaterialLocalizationsDelegate old) => false;
}

class _KurdishWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _KurdishWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'ku' ||
      locale.languageCode == 'en' ||
      locale.languageCode == 'ar';

  @override
  Future<WidgetsLocalizations> load(Locale locale) {
    return GlobalWidgetsLocalizations.delegate.load(
      (locale.languageCode == 'ku' || locale.languageCode == 'ar')
          ? const Locale('en')
          : locale,
    );
  }

  @override
  bool shouldReload(_KurdishWidgetsLocalizationsDelegate old) => false;
}

class _KurdishCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _KurdishCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'ku' ||
      locale.languageCode == 'en' ||
      locale.languageCode == 'ar';

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    return GlobalCupertinoLocalizations.delegate.load(
      (locale.languageCode == 'ku' || locale.languageCode == 'ar')
          ? const Locale('en')
          : locale,
    );
  }

  @override
  bool shouldReload(_KurdishCupertinoLocalizationsDelegate old) => false;
}
