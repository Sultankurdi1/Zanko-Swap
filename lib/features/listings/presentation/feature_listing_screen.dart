import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/supabase_storage_service.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/models/listing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/picked_image.dart';
import '../../ads/data/ad_prices.dart';
import '../data/featured_repository.dart';

/// Seller pays a small amount so their listing is shown first (with a ⭐)
/// on the home screen. The admin checks the payment and turns it on.
class FeatureListingScreen extends StatefulWidget {
  const FeatureListingScreen({super.key, required this.listing});
  final Listing listing;

  @override
  State<FeatureListingScreen> createState() => _FeatureListingScreenState();
}

class _FeatureListingScreenState extends State<FeatureListingScreen> {
  final _repo = FeaturedRepository();
  final _code = TextEditingController();
  late Future<(int, FeaturedRequest?)> _future;
  int _days = 7;
  XFile? _receipt;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<(int, FeaturedRequest?)> _load() async {
    final prices = await AdPrices.load();
    final request = await _repo.latestFor(widget.listing.id);
    return (prices['featured'] ?? AdPrices.defaults['featured']!, request);
  }

  String _t(String ku, String ar, String en) {
    final s = AppStrings.of(context);
    return s.isKurdish ? ku : (s.isArabic ? ar : en);
  }

  Future<void> _submit() async {
    final s = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    if (_receipt == null && _code.text.trim().length < 3) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'وێنەی پسوولە یان ژمارەی مامەڵە دابنێ.',
              'أرفق صورة الإيصال أو رقم العملية.',
              'Add a receipt photo or the transaction number.',
            ),
          ),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final receipt = _receipt != null
          ? await SupabaseStorageService.uploadReceipt(
              ownerId: user.id,
              file: _receipt!,
            )
          : _code.text.trim();
      await _repo.submit(
        listingId: widget.listing.id,
        days: _days,
        receipt: receipt,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'داواکارییەکەت نێردرا. دوای پشکنینی پارەدان چالاک دەکرێت.',
              'تم إرسال طلبك. سيُفعّل بعد التحقق من الدفع.',
              'Request sent. It starts after the payment is checked.',
            ),
          ),
        ),
      );
      setState(() => _future = _load());
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
        title: Text(_t('کاڵای تایبەت ⭐', 'إعلان مميز ⭐', 'Featured ⭐')),
      ),
      body: FutureBuilder<(int, FeaturedRequest?)>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Center(
              child: CircularProgressIndicator(color: palette.primary),
            );
          }
          if (snap.hasError) {
            return Center(
              child: Text(AppStrings.of(context).errorFor(snap.error!)),
            );
          }
          final (weekly, request) = snap.data!;
          final total = weekly * (_days ~/ 7);
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text(
                widget.listing.title,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              if (widget.listing.isFeatured)
                _note(
                  palette,
                  _t(
                    '⭐ ئێستا تایبەتە تا ${_date(widget.listing.featuredUntil!)}. دەتوانیت درێژی بکەیتەوە.',
                    '⭐ مميز الآن حتى ${_date(widget.listing.featuredUntil!)}. يمكنك التمديد.',
                    '⭐ Featured until ${_date(widget.listing.featuredUntil!)}. You can extend it.',
                  ),
                ),
              _note(
                palette,
                _t(
                  'کاڵا تایبەتەکان لە سەرەوەی پەڕەی سەرەکی و بە نیشانەی ⭐ پیشان دەدرێن.',
                  'تظهر الإعلانات المميزة أولاً في الصفحة الرئيسية مع علامة ⭐.',
                  'Featured listings are shown first on the home screen with a ⭐.',
                ),
              ),
              const SizedBox(height: 12),
              if (request?.status == 'pending')
                ..._pending(palette, request!)
              else ...[
                if (request?.status == 'rejected')
                  _note(
                    palette,
                    _t(
                      'داواکاریی پێشوو قبوڵ نەکرا. ئەگەر پارەت داوە، پەیوەندیمان پێوە بکە.',
                      'لم يُقبل الطلب السابق. إذا دفعت، تواصل معنا.',
                      'The previous request was not accepted. If you paid, contact us.',
                    ),
                  ),
                SegmentedButton<int>(
                  segments: [
                    ButtonSegment(
                      value: 7,
                      label: Text(_t('١ هەفتە', 'أسبوع', '1 week')),
                    ),
                    ButtonSegment(
                      value: 14,
                      label: Text(_t('٢ هەفتە', 'أسبوعان', '2 weeks')),
                    ),
                  ],
                  selected: {_days},
                  onSelectionChanged: (v) => setState(() => _days = v.first),
                ),
                const SizedBox(height: 14),
                _payment(palette, total),
                const SizedBox(height: 14),
                if (_receipt != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: PickedImage(
                      _receipt!,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () async {
                          final picked = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80,
                          );
                          if (picked != null) setState(() => _receipt = picked);
                        },
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: Text(
                    _t('وێنەی پسوولە', 'صورة الإيصال', 'Receipt photo'),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _code,
                  decoration: InputDecoration(
                    labelText: _t(
                      'یان ژمارەی مامەڵە',
                      'أو رقم العملية',
                      'Or transaction number',
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _busy ? null : _submit,
                  child: Text(_t('ناردن', 'إرسال', 'Send')),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _date(DateTime d) {
    final l = d.toLocal();
    return '${l.year}/${l.month}/${l.day}';
  }

  Widget _note(AppPalette palette, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(color: palette.textSecondary, height: 1.5),
    ),
  );

  List<Widget> _pending(AppPalette palette, FeaturedRequest request) => [
    _note(
      palette,
      _t(
        'داواکارییەکەت (${request.days} ڕۆژ، ${request.priceIqd} دینار) چاوەڕێی پشکنینە.',
        'طلبك (${request.days} يوم، ${request.priceIqd} دينار) قيد المراجعة.',
        'Your request (${request.days} days, ${request.priceIqd} IQD) is waiting for review.',
      ),
    ),
    OutlinedButton(
      onPressed: _busy
          ? null
          : () async {
              await _repo.cancel(request);
              if (mounted) setState(() => _future = _load());
            },
      child: Text(_t('هەڵوەشاندنەوە', 'إلغاء', 'Cancel')),
    ),
  ];

  Widget _payment(AppPalette palette, int total) {
    Widget account(String name, String number, String qr) => ListTile(
      tileColor: palette.surfaceHighlight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(Icons.qr_code_2_rounded, color: palette.accent, size: 30),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(number),
      trailing: IconButton(
        icon: const Icon(Icons.copy_rounded, size: 18),
        onPressed: () {
          Clipboard.setData(ClipboardData(text: number));
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$name: $number')));
        },
      ),
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Image.asset(qr),
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_t('بڕی پارە', 'المبلغ', 'Amount')}: $total IQD',
            style: TextStyle(
              color: palette.accent,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _t(
              'پارەکە بنێرە بۆ یەکێک لەم هەژمارانە (Taha sulaiman Azeez)، پاشان وێنەی پسوولەکە یان ژمارەی مامەڵەکە دابنێ.',
              'أرسل المبلغ إلى أحد هذه الحسابات (Taha sulaiman Azeez)، ثم أرفق الإيصال أو رقم العملية.',
              'Send the amount to one of these accounts (Taha sulaiman Azeez), then add the receipt or transaction number.',
            ),
            style: TextStyle(color: palette.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 10),
          account('FastPay', '07504359605', 'assets/fastpay_qr.jpg'),
          const SizedBox(height: 8),
          account('FIB', '07734059605', 'assets/fib_qr.jpg'),
        ],
      ),
    );
  }
}
