import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../data/ad_repository.dart';
import '../../../core/models/ad_campaign.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/data/supabase_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateAdScreen extends StatefulWidget {
  final String defaultPlacement;
  const CreateAdScreen({super.key, this.defaultPlacement = 'home'});

  @override
  State<CreateAdScreen> createState() => _CreateAdScreenState();
}

class _CreateAdScreenState extends State<CreateAdScreen> {
  final title = TextEditingController();
  final subtitle = TextEditingController();
  final advertiser = TextEditingController();
  final targetUrl = TextEditingController();
  final receiptCode = TextEditingController();

  File? _adImageFile;
  File? _receiptImageFile;

  late String placement;
  int days = 7;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    placement = widget.defaultPlacement;
  }

  @override
  void dispose() {
    title.dispose();
    subtitle.dispose();
    advertiser.dispose();
    targetUrl.dispose();
    receiptCode.dispose();
    super.dispose();
  }

  int get budget => (placement == 'home' ? 15000 : 5000) * (days ~/ 7);

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('ژمارەی $label کۆپی کرا: $text')));
  }

  Future<void> _pickImage(bool isReceipt) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        if (isReceipt) {
          _receiptImageFile = File(picked.path);
        } else {
          _adImageFile = File(picked.path);
        }
      });
    }
  }

  void _showQrDialog(String title, String imagePath, AppPalette palette) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: palette.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    icon: Icon(
                      Icons.close_rounded,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  imagePath,
                  width: 240,
                  height: 240,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 240,
                    height: 240,
                    color: palette.surfaceHighlight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_2_rounded,
                          size: 64,
                          color: palette.textSecondary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'وێنەی QR لە assets نەدۆزرایەوە',
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> submit() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in before submitting an ad.'),
        ),
      );
      return;
    }

    final t = title.text.trim();
    final a = advertiser.text.trim();
    final rawLink = targetUrl.text.trim();

    if (t.isEmpty || a.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تکایە ناونیشان و ناوی کاروبار پڕبکەرەوە.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (rawLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تکایە بەستەری پەیوەندی دابنێ.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_adImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('دانانی وێنەی پۆستەری ڕیکلام مەرجە!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_receiptImageFile == null && receiptCode.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تکایە وێنەی پسوولە یان ژمارەی ترانزاکشن دابنێ!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => sending = true);

    try {
      final myId = currentUser.id;

      final adImageUrl = await SupabaseStorageService.uploadListingImage(
        ownerId: myId,
        file: _adImageFile!,
        fileName: 'ad_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      String receiptResult = receiptCode.text.trim();
      if (_receiptImageFile != null) {
        final receiptUrl = await SupabaseStorageService.uploadListingImage(
          ownerId: myId,
          file: _receiptImageFile!,
          fileName: 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        receiptResult = receiptUrl;
      }

      final formattedUrl =
          (rawLink.startsWith('http://') || rawLink.startsWith('https://'))
          ? rawLink
          : 'https://$rawLink';

      await AdRepository().submit(
        AdCampaign(
          id: '',
          title: t,
          subtitle: subtitle.text.trim(),
          advertiser: a,
          imageUrl: adImageUrl,
          receiptUrl: receiptResult,
          targetUrl: formattedUrl,
          targetRoute: '',
          placement: placement,
          status: 'pending',
          budgetIQD: budget,
          days: days,
          createdAt: DateTime.now(),
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('داواکاریی ڕیکلامەکە بە سەرکەوتوویی نێردرا.'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('هەڵە لە ناردنی ڕیکلام: $e')));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  InputDecoration _inputDecor({
    required AppPalette palette,
    required String label,
    String? hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: palette.textSecondary, fontSize: 13),
      hintStyle: TextStyle(
        color: palette.textSecondary.withValues(alpha: 0.6),
        fontSize: 12,
      ),
      prefixIcon: Icon(icon, color: palette.accent, size: 20),
      filled: true,
      fillColor: palette.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'ڕیکلامی نوێ زیاد بکە',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: palette.accent,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          TextField(
            controller: advertiser,
            style: TextStyle(color: palette.textPrimary, fontSize: 13.5),
            decoration: _inputDecor(
              palette: palette,
              label: 'ناوی کاروبار یان پەیمانگا *',
              icon: Icons.business_rounded,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: title,
            style: TextStyle(color: palette.textPrimary, fontSize: 13.5),
            decoration: _inputDecor(
              palette: palette,
              label: 'ناونیشانی ڕیکلام *',
              icon: Icons.campaign_rounded,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: subtitle,
            maxLines: 2,
            style: TextStyle(color: palette.textPrimary, fontSize: 13.5),
            decoration: _inputDecor(
              palette: palette,
              label: 'پەیامی سەرەکی / کورتە',
              icon: Icons.local_offer_rounded,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: targetUrl,
            keyboardType: TextInputType.url,
            style: TextStyle(color: palette.textPrimary, fontSize: 13.5),
            decoration: _inputDecor(
              palette: palette,
              label: 'بەستەری پەیوەندی (واتسئاپ یان ئینستاگرام) *',
              hint: 'wa.me/964750... یان instagram.com/...',
              icon: Icons.link_rounded,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                _adImageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _adImageFile!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: palette.surfaceHighlight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.image_outlined,
                          color: palette.textSecondary,
                        ),
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'وێنەی ڕیکلام (پۆستەر) *',
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _adImageFile != null
                            ? 'وێنەکە دیاریکراوە'
                            : 'دانانی وێنە پێویستە',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.primary,
                  ),
                  onPressed: () => _pickImage(false),
                  child: const Text(
                    'هەڵبژاردن',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          Text(
            'شوێنی نیشاندان',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: placement,
            dropdownColor: palette.surface,
            style: TextStyle(color: palette.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: palette.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: palette.border),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'home', child: Text('شاشەی سەرەکی')),
              DropdownMenuItem(value: 'course', child: Text('بەشی کۆرسەکان')),
            ],
            onChanged: (v) => setState(() => placement = v!),
          ),

          const SizedBox(height: 18),

          Text(
            'ماوەی مانەوەی ڕیکلام',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [7, 14, 30].map((d) {
              final isSelected = days == d;
              return ChoiceChip(
                label: Text('$d ڕۆژ'),
                selected: isSelected,
                selectedColor: palette.primary,
                backgroundColor: palette.surface,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : palette.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
                side: BorderSide(
                  color: isSelected ? palette.primary : palette.border,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => days = d);
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'بڕی پارەی پێویست:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      '$budget IQD',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: palette.accent,
                      ),
                    ),
                  ],
                ),
                Divider(height: 24, color: palette.border),
                Text(
                  'خاوەن هەژمار: Taha sulaiman Azeez',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: palette.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),

                ListTile(
                  tileColor: palette.surfaceHighlight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: const Icon(
                    Icons.qr_code_2_rounded,
                    color: Colors.orangeAccent,
                    size: 30,
                  ),
                  title: const Text(
                    'FastPay',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('07504359605'),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    onPressed: () => _copyToClipboard('07504359605', 'FastPay'),
                  ),
                  onTap: () => _showQrDialog(
                    'FastPay QR',
                    'assets/fastpay_qr.jpg',
                    palette,
                  ),
                ),
                const SizedBox(height: 8),

                ListTile(
                  tileColor: palette.surfaceHighlight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: Icon(
                    Icons.qr_code_2_rounded,
                    color: palette.accent,
                    size: 30,
                  ),
                  title: const Text(
                    'FIB',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('07734059605'),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    onPressed: () => _copyToClipboard('07734059605', 'FIB'),
                  ),
                  onTap: () =>
                      _showQrDialog('FIB QR', 'assets/fib_qr.jpg', palette),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                _receiptImageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _receiptImageFile!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: palette.surfaceHighlight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.receipt_long_outlined,
                          color: palette.textSecondary,
                        ),
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'وێنەی پسوولە *',
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _receiptImageFile != null
                            ? 'پسوولەکە دیاریکراوە'
                            : 'وێنەی پسوولە دابنێ',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => _pickImage(true),
                  child: const Text(
                    'هەڵبژاردن',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: receiptCode,
            style: TextStyle(color: palette.textPrimary, fontSize: 13),
            decoration: _inputDecor(
              palette: palette,
              label: 'یان ژمارەی ترانزاکشن (ئارەزوومەندانە)',
              icon: Icons.numbers_rounded,
            ),
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primary,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: sending ? null : submit,
            child: sending
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'ناردنی داواکاری و پسوولە',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
