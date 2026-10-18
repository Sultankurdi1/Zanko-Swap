import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final palette = AppThemeScope.of(context);

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
          s.isKurdish
              ? 'ئاگادارکردنەوەکان'
              : s.isArabic
              ? 'الإشعارات'
              : 'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: palette.accent,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 60,
                  color: palette.accent,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                s.isKurdish
                    ? 'هێشتا هیچ ئاگادارکردنەوەیەکت نییە'
                    : 'You have no notifications yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.isKurdish
                    ? 'کاتێک کەسێک وەڵامی نامەکەت بداتەوە یان کارلێک لەگەڵ بابەتەکانت بکات لێرە پیشان دەدرێت'
                    : "You'll see replies to your messages and activity on your listings here",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
