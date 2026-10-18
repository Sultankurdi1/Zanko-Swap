import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/data/institution_repository.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/models/institution.dart';
import '../../../core/theme/app_theme.dart';
import 'institution_form_screen.dart';

class InstitutionDirectoryScreen extends StatefulWidget {
  final int initialTab;
  const InstitutionDirectoryScreen({super.key, this.initialTab = 0});
  @override
  State<InstitutionDirectoryScreen> createState() =>
      _InstitutionDirectoryScreenState();
}

class _InstitutionDirectoryScreenState extends State<InstitutionDirectoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;
  final repo = InstitutionRepository();
  String query = '';

  @override
  void initState() {
    super.initState();
    tabs = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  Stream<List<Institution>> stream(int i) =>
      repo.streamByType(InstitutionType.values[i]);

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
          s.institutions,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: palette.accent,
            letterSpacing: -0.5,
          ),
        ),
        bottom: TabBar(
          controller: tabs,
          indicatorColor: palette.primary,
          indicatorWeight: 3,
          labelColor: palette.accent,
          unselectedLabelColor: palette.textSecondary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
          tabs: [
            Tab(text: s.schools, icon: const Icon(Icons.school_outlined)),
            Tab(text: s.institutes, icon: const Icon(Icons.apartment_outlined)),
            Tab(
              text: s.vocationalFiveYear,
              icon: const Icon(Icons.construction_outlined),
            ),
            Tab(
              text: s.colleges,
              icon: const Icon(Icons.account_balance_outlined),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: palette.border),
              ),
              child: TextField(
                style: TextStyle(color: palette.textPrimary, fontSize: 13.5),
                onChanged: (v) =>
                    setState(() => query = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded, color: palette.accent),
                  hintText: s.isKurdish
                      ? 'گەڕان لە ناوی دامەزراوە...'
                      : 'Search institution...',
                  hintStyle: TextStyle(
                    color: palette.textSecondary.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: tabs,
              children: List.generate(4, (i) {
                return StreamBuilder<List<Institution>>(
                  stream: stream(i),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: palette.primary,
                        ),
                      );
                    }
                    if (snap.hasError) {
                      return Center(
                        child: Text(
                          '${snap.error}',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      );
                    }
                    final items = (snap.data ?? [])
                        .where(
                          (x) =>
                              query.isEmpty ||
                              x.name(true).toLowerCase().contains(query) ||
                              x.name(false).toLowerCase().contains(query) ||
                              x.city.toLowerCase().contains(query),
                        )
                        .toList();
                    if (items.isEmpty) {
                      return Center(
                        child: Text(
                          s.isKurdish
                              ? 'هیچ دامەزراوەیەک نییە'
                              : 'No institutions yet',
                          style: TextStyle(color: palette.textSecondary),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, j) =>
                          _InstitutionCard(item: items[j], palette: palette),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: palette.buttonGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InstitutionFormScreen(
                initialType: InstitutionType.values[tabs.index],
              ),
            ),
          ),
          icon: const Icon(Icons.add_rounded),
          label: Text(
            s.isKurdish
                ? 'زیادکردنی دامەزراوە'
                : s.isArabic
                ? 'إضافة مؤسسة'
                : 'Add institution',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _InstitutionCard extends StatelessWidget {
  final Institution item;
  final AppPalette palette;

  const _InstitutionCard({required this.item, required this.palette});

  Future<void> _open(String value) async {
    final uri = Uri.tryParse(value);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: palette.primary.withValues(alpha: 0.15),
                  child: Icon(item.icon, color: palette.accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name(s.isKurdish),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16.5,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          item.province,
                          item.city,
                          item.sector == 'private'
                              ? (s.isKurdish
                                    ? 'ئەهلی'
                                    : s.isArabic
                                    ? 'أهلي'
                                    : 'Private')
                              : (s.isKurdish
                                    ? 'حکومی'
                                    : s.isArabic
                                    ? 'حكومي'
                                    : 'Government'),
                        ].where((x) => x.trim().isNotEmpty).join(' • '),
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (item.admissionAfterGrade9 ||
                          item.durationYears > 0) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (item.admissionAfterGrade9)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.surfaceHighlight,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: palette.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.school_rounded,
                                      size: 14,
                                      color: palette.accent,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      s.isKurdish
                                          ? 'دوای پۆلی ٩'
                                          : 'After grade 9',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: palette.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (item.durationYears > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.surfaceHighlight,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: palette.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.schedule_rounded,
                                      size: 14,
                                      color: palette.accent,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${item.durationYears} ${s.isKurdish
                                          ? 'ساڵ'
                                          : s.isArabic
                                          ? 'سنوات'
                                          : 'years'}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: palette.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  color: palette.surface,
                  iconColor: palette.textSecondary,
                  onSelected: (v) => _open(v),
                  itemBuilder: (_) => [
                    if (item.websiteUrl.isNotEmpty)
                      PopupMenuItem(
                        value: item.websiteUrl,
                        child: Text(
                          s.website,
                          style: TextStyle(color: palette.textPrimary),
                        ),
                      ),
                    if (item.instagramUrl.isNotEmpty)
                      PopupMenuItem(
                        value: item.instagramUrl,
                        child: Text(
                          'Instagram',
                          style: TextStyle(color: palette.textPrimary),
                        ),
                      ),
                    if (item.facebookUrl.isNotEmpty)
                      PopupMenuItem(
                        value: item.facebookUrl,
                        child: Text(
                          'Facebook',
                          style: TextStyle(color: palette.textPrimary),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (item.studyLanguage.isNotEmpty ||
                item.specialties.isNotEmpty) ...[
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  [
                    if (item.studyLanguage.isNotEmpty)
                      '${s.isKurdish
                          ? 'زمانی خوێندن'
                          : s.isArabic
                          ? 'لغة الدراسة'
                          : 'Study language'}: ${item.studyLanguage}',
                    if (item.specialties.isNotEmpty)
                      '${s.isKurdish
                          ? 'بەشەکان'
                          : s.isArabic
                          ? 'الفروع'
                          : 'Tracks'}: ${item.specialties}',
                  ].join(' • '),
                  style: TextStyle(fontSize: 12, color: palette.textSecondary),
                ),
              ),
            ],
            if (item.description(s.isKurdish).isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  item.description(s.isKurdish),
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            if (item.address.isNotEmpty || item.phone.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (item.address.isNotEmpty)
                    Expanded(
                      child: Text(
                        '📍 ${item.address}',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (item.phone.isNotEmpty)
                    Expanded(
                      child: Text(
                        '☎ ${item.phone}',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (item.websiteUrl.isNotEmpty ||
                item.instagramUrl.isNotEmpty ||
                item.facebookUrl.isNotEmpty)
              Divider(height: 22, color: palette.border),
            Wrap(
              spacing: 8,
              children: [
                if (item.websiteUrl.isNotEmpty)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.accent,
                      side: BorderSide(color: palette.border),
                    ),
                    onPressed: () => _open(item.websiteUrl),
                    icon: const Icon(Icons.language_rounded, size: 18),
                    label: Text(s.website),
                  ),
                if (item.instagramUrl.isNotEmpty)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.accent,
                      side: BorderSide(color: palette.border),
                    ),
                    onPressed: () => _open(item.instagramUrl),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Instagram'),
                  ),
                if (item.facebookUrl.isNotEmpty)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.accent,
                      side: BorderSide(color: palette.border),
                    ),
                    onPressed: () => _open(item.facebookUrl),
                    icon: const Icon(Icons.facebook_rounded, size: 18),
                    label: const Text('Facebook'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
