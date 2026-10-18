import 'package:flutter/material.dart';

enum AppThemeMode {
  emerald,
  purpleSunset,
  coralCreative,
  oceanBlue,
  arcticLight,
  lavenderNight,
  goldenHour,
}

class AppPalette {
  final String id;
  final String nameKu;
  final String nameEn;
  final bool isDark;
  final Color bg;
  final Color surface;
  final Color surfaceHighlight;
  final Color primary;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final LinearGradient buttonGradient;
  final LinearGradient? headerGradient;

  const AppPalette({
    required this.id,
    required this.nameKu,
    required this.nameEn,
    required this.isDark,
    required this.bg,
    required this.surface,
    required this.surfaceHighlight,
    required this.primary,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.buttonGradient,
    this.headerGradient,
  });

  static const emerald = AppPalette(
    id: 'emerald',
    nameKu: 'سەوزی زەمرووتی (Emerald)',
    nameEn: 'Emerald Modern',
    isDark: true,
    bg: Color(0xFF071D16),
    surface: Color(0xFF0C271E),
    surfaceHighlight: Color(0xFF0E2E23),
    primary: Color(0xFF10B981),
    accent: Color(0xFF34D399),
    textPrimary: Colors.white,
    textSecondary: Colors.white54,
    border: Color(0x1AFFFFFF),
    buttonGradient: LinearGradient(
      colors: [Color(0xFF10B981), Color(0xFF059669)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF0F4A38), Color(0xFF0A2E22)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const purpleSunset = AppPalette(
    id: 'purple_sunset',
    nameKu: 'مۆری پاشایانە (Purple Sunset)',
    nameEn: 'Purple Sunset',
    isDark: true,
    bg: Color(0xFF150A26),
    surface: Color(0xFF22123B),
    surfaceHighlight: Color(0xFF2E1950),
    primary: Color(0xFFFF5277),
    accent: Color(0xFFFF8A48),
    textPrimary: Colors.white,
    textSecondary: Color(0xFFB3A1CF),
    border: Color(0x26FFFFFF),
    buttonGradient: LinearGradient(
      colors: [Color(0xFFFF3E6C), Color(0xFFFF8C38)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF4A154B), Color(0xFF250D44)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const coralCreative = AppPalette(
    id: 'coral_creative',
    nameKu: 'مەرجانی ڕۆشن (Coral Creative)',
    nameEn: 'Coral Creative',
    isDark: false,
    bg: Color(0xFFF8F9FA),
    surface: Colors.white,
    surfaceHighlight: Color(0xFFF1F3F5),
    primary: Color(0xFFFF5E57),
    accent: Color(0xFFFF9F43),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF6E7881),
    border: Color(0x14000000),
    buttonGradient: LinearGradient(
      colors: [Color(0xFFFF5E57), Color(0xFFFF9F43)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFFFF7675), Color(0xFFFAB1A0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const oceanBlue = AppPalette(
    id: 'ocean_blue',
    nameKu: 'شینی ئۆقیانوس',
    nameEn: 'Ocean Blue',
    isDark: true,
    bg: Color(0xFF071827),
    surface: Color(0xFF0C2437),
    surfaceHighlight: Color(0xFF12334A),
    primary: Color(0xFF38BDF8),
    accent: Color(0xFF67E8F9),
    textPrimary: Colors.white,
    textSecondary: Color(0xFF9BB8C9),
    border: Color(0x24FFFFFF),
    buttonGradient: LinearGradient(
      colors: [Color(0xFF0284C7), Color(0xFF22D3EE)],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF0C4563), Color(0xFF0B263A)],
    ),
  );

  static const arcticLight = AppPalette(
    id: 'arctic_light',
    nameKu: 'سەهۆڵی ڕووناک',
    nameEn: 'Arctic Light',
    isDark: false,
    bg: Color(0xFFF1F8FC),
    surface: Colors.white,
    surfaceHighlight: Color(0xFFE5F1F7),
    primary: Color(0xFF2878B8),
    accent: Color(0xFF19A7A1),
    textPrimary: Color(0xFF132C3D),
    textSecondary: Color(0xFF607888),
    border: Color(0x182878B8),
    buttonGradient: LinearGradient(
      colors: [Color(0xFF2878B8), Color(0xFF19A7A1)],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFFD9F0FA), Color(0xFFE5F5F0)],
    ),
  );

  static const lavenderNight = AppPalette(
    id: 'lavender_night',
    nameKu: 'شەوی لاڤەندەر',
    nameEn: 'Lavender Night',
    isDark: true,
    bg: Color(0xFF171426),
    surface: Color(0xFF242039),
    surfaceHighlight: Color(0xFF302A49),
    primary: Color(0xFFA78BFA),
    accent: Color(0xFFF0ABFC),
    textPrimary: Colors.white,
    textSecondary: Color(0xFFB8B1CC),
    border: Color(0x27FFFFFF),
    buttonGradient: LinearGradient(
      colors: [Color(0xFF7C3AED), Color(0xFFDB69C6)],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF443267), Color(0xFF211D36)],
    ),
  );

  static const goldenHour = AppPalette(
    id: 'golden_hour',
    nameKu: 'کاتی زێڕین',
    nameEn: 'Golden Hour',
    isDark: false,
    bg: Color(0xFFFFF8EE),
    surface: Colors.white,
    surfaceHighlight: Color(0xFFFFF0D9),
    primary: Color(0xFFD97706),
    accent: Color(0xFFEA580C),
    textPrimary: Color(0xFF382719),
    textSecondary: Color(0xFF806B56),
    border: Color(0x1AD97706),
    buttonGradient: LinearGradient(
      colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFFFFE5B4), Color(0xFFFFF1DC)],
    ),
  );

  static const List<AppPalette> presets = [
    emerald,
    purpleSunset,
    coralCreative,
    oceanBlue,
    arcticLight,
    lavenderNight,
    goldenHour,
  ];

  static AppPalette fromId(String id) =>
      presets.firstWhere((palette) => palette.id == id, orElse: () => emerald);
}

class AppThemeScope extends InheritedWidget {
  final AppPalette palette;

  const AppThemeScope({super.key, required this.palette, required super.child});

  static AppPalette of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppThemeScope>();
    return scope?.palette ?? AppPalette.emerald;
  }

  @override
  bool updateShouldNotify(AppThemeScope oldWidget) {
    return oldWidget.palette.id != palette.id;
  }
}

class ZankoTheme {
  static AppPalette of(BuildContext context) => AppThemeScope.of(context);

  static ThemeData buildFromPalette(AppPalette palette) {
    return ThemeData(
      useMaterial3: true,
      brightness: palette.isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: palette.bg,
      colorScheme: ColorScheme(
        brightness: palette.isDark ? Brightness.dark : Brightness.light,
        primary: palette.primary,
        onPrimary: Colors.white,
        secondary: palette.accent,
        onSecondary: Colors.white,
        error: Colors.redAccent,
        onError: Colors.white,
        surface: palette.surface,
        onSurface: palette.textPrimary,
      ),
      fontFamily: 'Arial',
      appBarTheme: AppBarTheme(
        backgroundColor: palette.bg,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: palette.accent,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: palette.border),
        ),
      ),
    );
  }

  static ThemeData light({Color seed = Colors.green}) =>
      buildFromPalette(AppPalette.coralCreative);
  static ThemeData dark({Color seed = Colors.green}) =>
      buildFromPalette(AppPalette.emerald);
}
