import 'package:flutter/material.dart';
import '../../../core/data/institution_repository.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/models/institution.dart';

class InstitutionFormScreen extends StatefulWidget {
  final InstitutionType initialType;
  final Institution? editing;
  const InstitutionFormScreen({
    super.key,
    required this.initialType,
    this.editing,
  });

  @override
  State<InstitutionFormScreen> createState() => _InstitutionFormScreenState();
}

class _InstitutionFormScreenState extends State<InstitutionFormScreen> {
  final repo = InstitutionRepository();
  late InstitutionType type;
  final ku = TextEditingController();
  final en = TextEditingController();
  final province = TextEditingController();
  final city = TextEditingController();
  String sector = 'government';
  final duration = TextEditingController();
  final descKu = TextEditingController();
  final descEn = TextEditingController();
  final website = TextEditingController();
  final instagram = TextEditingController();
  final facebook = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  bool saving = false;

  @override
  void initState() {
    super.initState();
    type = widget.editing?.type ?? widget.initialType;
    final x = widget.editing;
    if (x != null) {
      ku.text = x.nameKu;
      en.text = x.nameEn;
      province.text = x.province;
      city.text = x.city;
      sector = x.sector;
      duration.text = x.durationYears == 0 ? '' : '${x.durationYears}';
      descKu.text = x.descriptionKu;
      descEn.text = x.descriptionEn;
      website.text = x.websiteUrl;
      instagram.text = x.instagramUrl;
      facebook.text = x.facebookUrl;
      phone.text = x.phone;
      address.text = x.address;
    }
  }

  @override
  void dispose() {
    for (final c in [
      ku,
      en,
      province,
      city,
      duration,
      descKu,
      descEn,
      website,
      instagram,
      facebook,
      phone,
      address,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (ku.text.trim().isEmpty && en.text.trim().isEmpty) return;
    setState(() => saving = true);
    final item = Institution(
      id: widget.editing?.id ?? '',
      type: type,
      nameKu: ku.text.trim(),
      nameEn: en.text.trim(),
      province: province.text.trim(),
      city: city.text.trim(),
      sector: sector,
      durationYears: int.tryParse(duration.text.trim()) ?? 0,
      descriptionKu: descKu.text.trim(),
      descriptionEn: descEn.text.trim(),
      websiteUrl: website.text.trim(),
      instagramUrl: instagram.text.trim(),
      facebookUrl: facebook.text.trim(),
      phone: phone.text.trim(),
      address: address.text.trim(),
    );
    try {
      if (widget.editing == null) {
        await repo.create(item);
      } else {
        await repo.update(item);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.isKurdish
              ? 'زانیاری دامەزراوە'
              : s.isArabic
              ? 'بيانات المؤسسة'
              : 'Institution details',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<InstitutionType>(
            initialValue: type,
            decoration: InputDecoration(
              labelText: s.isKurdish
                  ? 'جۆر'
                  : s.isArabic
                  ? 'النوع'
                  : 'Type',
            ),
            items: InstitutionType.values
                .map(
                  (x) => DropdownMenuItem(
                    value: x,
                    child: Text(s.institutionType(x.name)),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => type = v ?? type),
          ),
          const SizedBox(height: 12),
          _field(
            ku,
            s.isKurdish
                ? 'ناو بە کوردی'
                : s.isArabic
                ? 'الاسم بالكردية'
                : 'Kurdish name',
          ),
          _field(en, 'English name'),
          _field(
            province,
            s.isKurdish
                ? 'پارێزگا'
                : s.isArabic
                ? 'المحافظة'
                : 'Province',
          ),
          _field(city, s.city),
          DropdownButtonFormField<String>(
            initialValue: sector,
            decoration: InputDecoration(
              labelText: s.isKurdish
                  ? 'جۆری دامەزراوە'
                  : s.isArabic
                  ? 'القطاع'
                  : 'Sector',
            ),
            items: const [
              DropdownMenuItem(
                value: 'government',
                child: Text('حکومی / Government'),
              ),
              DropdownMenuItem(
                value: 'private',
                child: Text('ئەهلی / Private'),
              ),
            ],
            onChanged: (v) => setState(() => sector = v ?? sector),
          ),
          const SizedBox(height: 12),
          _field(
            duration,
            s.isKurdish
                ? 'ماوەی خوێندن بە ساڵ (بۆ پەیمانگای ٥ ساڵی)'
                : 'Duration in years (for 5-year vocational institutes)',
          ),
          _field(
            descKu,
            s.isKurdish
                ? 'وەسف بە کوردی'
                : s.isArabic
                ? 'الوصف بالكردية'
                : 'Kurdish description',
            maxLines: 3,
          ),
          _field(descEn, 'English description', maxLines: 3),
          const SizedBox(height: 6),
          Text(
            s.isKurdish
                ? 'بەستەرەکان'
                : s.isArabic
                ? 'الروابط'
                : 'Links',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _field(website, 'Website URL'),
          _field(instagram, 'Instagram URL'),
          _field(facebook, 'Facebook URL'),
          _field(
            phone,
            s.isKurdish
                ? 'ژمارەی پەیوەندی'
                : s.isArabic
                ? 'رقم الهاتف'
                : 'Phone',
          ),
          _field(
            address,
            s.isKurdish
                ? 'ناونیشان'
                : s.isArabic
                ? 'العنوان'
                : 'Address',
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: saving ? null : save,
            icon: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(
              s.isKurdish
                  ? 'پاشەکەوتکردن'
                  : s.isArabic
                  ? 'حفظ'
                  : 'Save',
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
