import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/verification_repository.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/picked_image.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _repo = VerificationRepository();
  late Future<(bool, VerificationRequest?)> _future;
  XFile? _photo;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(bool, VerificationRequest?)> _load() async {
    final me = Supabase.instance.client.auth.currentUser?.id ?? '';
    final verified = await _repo.isVerified(me, fresh: true);
    final request = await _repo.myLatestRequest();
    return (verified, request);
  }

  void _reload() => setState(() => _future = _load());

  String _t(String ku, String ar, String en) {
    final s = AppStrings.of(context);
    return s.isKurdish ? ku : (s.isArabic ? ar : en);
  }

  Future<void> _pick() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1800,
    );
    if (photo != null) setState(() => _photo = photo);
  }

  Future<void> _submit() async {
    final photo = _photo;
    if (photo == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final s = AppStrings.of(context);
    setState(() => _busy = true);
    try {
      await _repo.submit(photo);
      _photo = null;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'داواکارییەکەت نێردرا. دوای پشکنین ئاگادار دەکرێیتەوە.',
              'تم إرسال طلبك. ستتم مراجعته قريبًا.',
              'Request sent. The admin will review it soon.',
            ),
          ),
        ),
      );
      _reload();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(s.errorFor(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(VerificationRequest request) async {
    final messenger = ScaffoldMessenger.of(context);
    final s = AppStrings.of(context);
    setState(() => _busy = true);
    try {
      await _repo.cancel(request);
      _reload();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(s.errorFor(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeScope.of(context);
    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.bg,
        foregroundColor: palette.textPrimary,
        title: Text(_t('قوتابی پشتڕاستکراو', 'طالب موثّق', 'Verified student')),
      ),
      body: FutureBuilder<(bool, VerificationRequest?)>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Center(
              child: CircularProgressIndicator(color: palette.primary),
            );
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  AppStrings.of(context).errorFor(snap.error!),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final (verified, request) = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Icon(
                Icons.verified_rounded,
                size: 64,
                color: verified ? const Color(0xFF38BDF8) : palette.border,
              ),
              const SizedBox(height: 12),
              if (verified)
                _message(
                  palette,
                  _t(
                    'پیرۆزە! تۆ قوتابیی پشتڕاستکراویت. نیشانەی ✓ لە تەنیشت ناوەکەت دەردەکەوێت.',
                    'مبروك! أنت طالب موثّق. تظهر علامة ✓ بجانب اسمك.',
                    'You are a verified student. A ✓ appears next to your name.',
                  ),
                )
              else if (request?.status == 'pending')
                ..._pending(palette, request!)
              else
                ..._form(palette, rejected: request?.status == 'rejected'),
            ],
          );
        },
      ),
    );
  }

  Widget _message(AppPalette palette, String text) => Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(color: palette.textPrimary, fontSize: 15, height: 1.6),
  );

  List<Widget> _pending(AppPalette palette, VerificationRequest request) => [
    _message(
      palette,
      _t(
        'داواکارییەکەت چاوەڕێی پشکنینە. دوای بڕیاردان، وێنەکە دەسڕدرێتەوە.',
        'طلبك قيد المراجعة. تُحذف الصورة بعد القرار.',
        'Your request is waiting for review. The photo is deleted after the decision.',
      ),
    ),
    const SizedBox(height: 20),
    OutlinedButton(
      onPressed: _busy ? null : () => _cancel(request),
      child: Text(
        _t('هەڵوەشاندنەوەی داواکاری', 'إلغاء الطلب', 'Cancel request'),
      ),
    ),
  ];

  List<Widget> _form(AppPalette palette, {required bool rejected}) => [
    if (rejected) ...[
      _message(
        palette,
        _t(
          'داواکارییەکەی پێشووت قبوڵ نەکرا. تکایە وێنەیەکی ڕوونتر بنێرە.',
          'لم يُقبل طلبك السابق. أرسل صورة أوضح من فضلك.',
          'Your previous request was not accepted. Please send a clearer photo.',
        ),
      ),
      const SizedBox(height: 12),
    ],
    _message(
      palette,
      _t(
        'وێنەیەکی ڕوونی ناسنامەی قوتابییەکەت بنێرە. تەنها ئەدمین دەیبینێت، و دوای بڕیاردان یەکسەر دەسڕدرێتەوە.',
        'أرسل صورة واضحة لهوية الطالب. يراها المشرف فقط، وتُحذف فور القرار.',
        'Send a clear photo of your student ID. Only the admin sees it, and it is deleted right after the decision.',
      ),
    ),
    const SizedBox(height: 20),
    if (_photo != null)
      ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: PickedImage(_photo!, height: 200, fit: BoxFit.cover),
      ),
    const SizedBox(height: 12),
    OutlinedButton.icon(
      onPressed: _busy ? null : _pick,
      icon: const Icon(Icons.badge_outlined),
      label: Text(
        _photo == null
            ? _t(
                'هەڵبژاردنی وێنەی ناسنامە',
                'اختيار صورة الهوية',
                'Choose ID photo',
              )
            : _t('گۆڕینی وێنە', 'تغيير الصورة', 'Change photo'),
      ),
    ),
    const SizedBox(height: 12),
    FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: palette.primary,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onPressed: _busy || _photo == null ? null : _submit,
      child: _busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(_t('ناردن', 'إرسال', 'Send')),
    ),
  ];
}
