import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import 'privacy_policy_content.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  final Locale locale;
  final ValueChanged<Locale>? onLocaleChanged;
  final VoidCallback? onAccepted;

  const PrivacyPolicyScreen({
    super.key,
    required this.locale,
    this.onLocaleChanged,
    this.onAccepted,
  });

  static const _acceptedKey = 'privacy_policy_accepted';

  static Future<bool> isAccepted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_acceptedKey) == PrivacyPolicyText.version;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_acceptedKey, PrivacyPolicyText.version);
  }

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  late String _language = widget.locale.languageCode;
  bool _saving = false;

  bool get _requiresAcceptance => widget.onAccepted != null;

  void _setLanguage(String code) {
    setState(() => _language = code);
    widget.onLocaleChanged?.call(Locale(code));
  }

  Future<void> _accept() async {
    setState(() => _saving = true);
    try {
      await PrivacyPolicyScreen.markAccepted();
    } catch (_) {}
    widget.onAccepted?.call();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeScope.of(context);
    final text = PrivacyPolicyText.of(_language);
    final isRtl = _language != 'en';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: palette.bg,
        appBar: AppBar(
          backgroundColor: palette.bg,
          foregroundColor: palette.textPrimary,
          automaticallyImplyLeading: !_requiresAcceptance,
          title: Text(
            text.title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'ku', label: Text('کوردی')),
                  ButtonSegment(value: 'ar', label: Text('العربية')),
                  ButtonSegment(value: 'en', label: Text('English')),
                ],
                selected: {_language},
                onSelectionChanged: (value) => _setLanguage(value.first),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Text(
                    text.effective,
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  for (final section in text.sections) ...[
                    const SizedBox(height: 20),
                    Text(
                      section.title,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      section.body,
                      style: TextStyle(
                        color: palette.textPrimary.withValues(alpha: 0.85),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_requiresAcceptance)
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    border: Border(top: BorderSide(color: palette.border)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        text.agreeNote,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: palette.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _saving ? null : _accept,
                          child: Text(
                            text.agree,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
