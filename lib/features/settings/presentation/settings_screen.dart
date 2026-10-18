import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDark;
  final ValueChanged<bool> onDarkChanged;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;
  final Color themeSeed;
  final ValueChanged<Color> onThemeSeedChanged;

  const SettingsScreen({
    super.key,
    required this.isDark,
    required this.onDarkChanged,
    required this.locale,
    required this.onLocaleChanged,
    required this.themeSeed,
    required this.onThemeSeedChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool locationEnabled = true;
  String selectedPreset = 'emerald';

  @override
  void initState() {
    super.initState();
    _loadSelectedPreset();
  }

  Future<void> _loadSelectedPreset() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedPreset = prefs.getString('app_theme_preset') ?? 'emerald';
    });
  }

  Future<void> _selectPreset(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme_preset', id);
    setState(() {
      selectedPreset = id;
    });

    final palette = AppPalette.fromId(id);
    widget.onDarkChanged(palette.isDark);
    widget.onThemeSeedChanged(palette.primary);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final palette = AppThemeScope.of(context);
    final locale = widget.locale;
    final onLocaleChanged = widget.onLocaleChanged;

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
          s.settings,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: palette.accent,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          Text(
            s.isKurdish
                ? 'مۆدێل و ڕووکاری بەرنامە (Themes)'
                : s.isArabic
                ? 'مظهر التطبيق'
                : 'App Theme Preset',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          ...AppPalette.presets.map((preset) {
            final isSelected = selectedPreset == preset.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? palette.primary : palette.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                onTap: () => _selectPreset(preset.id),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: preset.buttonGradient,
                    boxShadow: [
                      BoxShadow(
                        color: preset.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 24,
                        )
                      : null,
                ),
                title: Text(
                  s.isKurdish
                      ? preset.nameKu
                      : s.isArabic
                      ? switch (preset.id) {
                          'emerald' => 'الزمردي العصري',
                          'purple_sunset' => 'غروب بنفسجي',
                          'coral_creative' => 'مرجاني إبداعي',
                          'ocean_blue' => 'أزرق المحيط',
                          'arctic_light' => 'ضوء قطبي',
                          'lavender_night' => 'ليلة الخزامى',
                          'golden_hour' => 'الساعة الذهبية',
                          _ => preset.nameEn,
                        }
                      : preset.nameEn,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                    fontSize: 14.5,
                  ),
                ),
                subtitle: Text(
                  preset.isDark
                      ? (s.isKurdish
                            ? 'تاریک (Dark)'
                            : s.isArabic
                            ? 'المظهر الداكن'
                            : 'Dark theme')
                      : (s.isKurdish
                            ? 'ڕۆشن (Light)'
                            : s.isArabic
                            ? 'المظهر الفاتح'
                            : 'Light theme'),
                  style: TextStyle(color: palette.textSecondary, fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: preset.bg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: palette.textSecondary.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: preset.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 18),
          Text(
            s.isKurdish
                ? 'زمان و شوێن'
                : s.isArabic
                ? 'اللغة والموقع'
                : 'Language & Location',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.border),
            ),
            child: ListTile(
              leading: Icon(Icons.language_rounded, color: palette.accent),
              title: Text(
                s.language,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                locale.languageCode == 'ku'
                    ? 'کوردی (سۆرانی)'
                    : locale.languageCode == 'ar'
                    ? 'العربية'
                    : 'English',
                style: TextStyle(color: palette.textSecondary),
              ),
              trailing: PopupMenuButton<String>(
                color: palette.surface,
                initialValue: locale.languageCode,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceHighlight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: palette.border),
                  ),
                  child: Text(
                    locale.languageCode.toUpperCase(),
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'ku',
                    child: Text(
                      'کوردی',
                      style: TextStyle(color: palette.textPrimary),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'ar',
                    child: Text(
                      'العربية',
                      style: TextStyle(color: palette.textPrimary),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'en',
                    child: Text(
                      'English',
                      style: TextStyle(color: palette.textPrimary),
                    ),
                  ),
                ],
                onSelected: (v) => onLocaleChanged(Locale(v)),
              ),
            ),
          ),

          const SizedBox(height: 20),
          Text(
            s.isKurdish
                ? 'ڕێکخستنە خزمەتگوزارییەکان'
                : s.isArabic
                ? 'التفضيلات'
                : 'Preferences',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  activeTrackColor: palette.primary,
                  activeThumbColor: Colors.white,
                  value: notificationsEnabled,
                  onChanged: (v) => setState(() => notificationsEnabled = v),
                  secondary: Icon(
                    Icons.notifications_active_outlined,
                    color: palette.accent,
                  ),
                  title: Text(
                    s.isKurdish
                        ? 'ئاگادارکردنەوەکان'
                        : s.isArabic
                        ? 'الإشعارات'
                        : 'Notifications',
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Divider(height: 1, color: palette.border),
                SwitchListTile(
                  activeTrackColor: palette.primary,
                  activeThumbColor: Colors.white,
                  value: locationEnabled,
                  onChanged: (v) => setState(() => locationEnabled = v),
                  secondary: Icon(
                    Icons.location_on_outlined,
                    color: palette.accent,
                  ),
                  title: Text(
                    s.isKurdish
                        ? 'شوێن'
                        : s.isArabic
                        ? 'الموقع'
                        : 'Location',
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
