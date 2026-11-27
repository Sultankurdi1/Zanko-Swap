import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/data/removed_rows.dart';
import '../../core/data/supabase_storage_service.dart';
import '../../core/data/verification_repository.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../listings/data/featured_repository.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final palette = AppThemeScope.of(context);
    String t(String ku, String ar, String en) =>
        s.isKurdish ? ku : (s.isArabic ? ar : en);

    return DefaultTabController(
      length: 7,
      child: Scaffold(
        backgroundColor: palette.bg,
        appBar: AppBar(
          backgroundColor: palette.bg,
          foregroundColor: palette.textPrimary,
          title: Text(s.adminPanel),
          bottom: TabBar(
            isScrollable: true,
            labelColor: palette.accent,
            unselectedLabelColor: palette.textSecondary,
            indicatorColor: palette.accent,
            tabs: [
              Tab(text: t('ئامار', 'الإحصائيات', 'Statistics')),
              Tab(text: t('پشتڕاستکردنەوە', 'التوثيق', 'Verification')),
              Tab(text: t('کاڵای تایبەت', 'إعلانات مميزة', 'Featured')),
              Tab(text: t('ڕاپۆرتەکان', 'البلاغات', 'Reports')),
              Tab(text: t('دامەزراوەکان', 'المؤسسات', 'Institutions')),
              Tab(text: t('شاردراوەکان', 'المخفية', 'Hidden')),
              Tab(text: t('هەڵەکانی ئەپ', 'أخطاء التطبيق', 'App errors')),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _StatsTab(),
            _VerificationTab(),
            _FeaturedTab(),
            _ReportsTab(),
            _InstitutionsTab(),
            _HiddenTab(),
            _ErrorsTab(),
          ],
        ),
      ),
    );
  }
}

SupabaseClient get _db => Supabase.instance.client;

String _t(BuildContext context, String ku, String ar, String en) {
  final s = AppStrings.of(context);
  return s.isKurdish ? ku : (s.isArabic ? ar : en);
}

String _date(dynamic value) {
  final d = DateTime.tryParse('${value ?? ''}')?.toLocal();
  if (d == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
}

String _reason(BuildContext context, String reason) {
  final s = AppStrings.of(context);
  switch (reason) {
    case 'sexual':
    case 'inappropriate':
      return s.reportSexual;
    case 'harassment':
      return s.reportHarassment;
    case 'spam':
      return s.reportSpam;
    default:
      return s.reportOther;
  }
}

Future<void> _run(BuildContext context, Future<void> Function() action) async {
  final messenger = ScaffoldMessenger.of(context);
  final s = AppStrings.of(context);
  try {
    await action();
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(s.errorFor(e))));
  }
}

Future<bool> _confirm(BuildContext context, String message) async {
  final s = AppStrings.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(s.cancel),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(s.delete),
        ),
      ],
    ),
  );
  return ok == true;
}

class _AsyncList extends StatefulWidget {
  final Future<List<Widget>> Function(BuildContext context, VoidCallback reload)
  load;
  final String emptyText;
  const _AsyncList({required this.load, required this.emptyText});

  @override
  State<_AsyncList> createState() => _AsyncListState();
}

class _AsyncListState extends State<_AsyncList> {
  late Future<List<Widget>> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future = widget.load(context, _reload);
  }

  void _reload() {
    if (!mounted) return;
    setState(() => _future = widget.load(context, _reload));
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeScope.of(context);
    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: FutureBuilder<List<Widget>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Center(
              child: CircularProgressIndicator(color: palette.primary),
            );
          }
          if (snap.hasError) {
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    AppStrings.of(context).errorFor(snap.error!),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: palette.textSecondary),
                  ),
                ),
              ],
            );
          }
          final items = snap.data ?? const <Widget>[];
          if (items.isEmpty) {
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    widget.emptyText,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: palette.textSecondary),
                  ),
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) => items[i],
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final VoidCallback? onTap;
  const _Card({
    required this.title,
    required this.subtitle,
    this.actions = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeScope.of(context);
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: palette.textSecondary, fontSize: 12.5),
              ),
              if (actions.isNotEmpty)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Wrap(spacing: 4, children: actions),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  static Future<List<Widget>> _load(
    BuildContext context,
    VoidCallback reload,
  ) async {
    final contentRows = List<Map<String, dynamic>>.from(
      await _db
          .from('content_reports')
          .select()
          .order('created_at', ascending: false)
          .limit(200),
    );
    final userRows = List<Map<String, dynamic>>.from(
      await _db
          .from('user_reports')
          .select()
          .order('created_at', ascending: false)
          .limit(200),
    );

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final row in contentRows) {
      grouped
          .putIfAbsent('${row['content_type']}:${row['content_id']}', () => [])
          .add(row);
    }

    final listingIds = <String>{};
    final serviceIds = <String>{};
    for (final rows in grouped.values) {
      final type = '${rows.first['content_type']}';
      final id = '${rows.first['content_id']}';
      if (type == 'listing') listingIds.add(id);
      if (type == 'service') serviceIds.add(id);
    }
    final titles = <String, String>{};
    if (listingIds.isNotEmpty) {
      for (final r
          in await _db
              .from('listings')
              .select('id, title')
              .inFilter('id', listingIds.toList())) {
        titles['listing:${r['id']}'] = '${r['title'] ?? ''}';
      }
    }
    if (serviceIds.isNotEmpty) {
      for (final r
          in await _db
              .from('services')
              .select('id, name')
              .inFilter('id', serviceIds.toList())) {
        titles['service:${r['id']}'] = '${r['name'] ?? ''}';
      }
    }

    final userIds = {for (final r in userRows) '${r['reported_user_id']}'};
    final names = <String, String>{};
    if (userIds.isNotEmpty) {
      for (final r
          in await _db
              .from('profiles')
              .select('id, displayName')
              .inFilter('id', userIds.toList())) {
        names['${r['id']}'] = '${r['displayName'] ?? ''}';
      }
    }
    if (!context.mounted) return const [];

    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      final rows = entry.value;
      final type = '${rows.first['content_type']}';
      final id = '${rows.first['content_id']}';
      final kind = switch (type) {
        'listing' => _t(context, 'بابەت', 'إعلان', 'Listing'),
        'service' => _t(context, 'شوێن', 'مكان', 'Place'),
        _ => _t(context, 'پۆستی شوێن', 'منشور مكان', 'Place update'),
      };
      final reasons = rows
          .map((r) => _reason(context, '${r['reason']}'))
          .toSet()
          .join('، ');
      widgets.add(
        _Card(
          title: '$kind: ${titles[entry.key] ?? '#$id'}',
          subtitle:
              '${rows.length} ${_t(context, 'ڕاپۆرت', 'بلاغ', 'reports')} · $reasons · ${_date(rows.first['created_at'])}',
          actions: [
            if (type != 'service_update')
              TextButton(
                onPressed: () => _run(context, () async {
                  final table = type == 'listing' ? 'listings' : 'services';
                  await _db
                      .from(table)
                      .update({'moderation_hidden': true})
                      .eq('id', id);
                  reload();
                }),
                child: Text(_t(context, 'شاردنەوە', 'إخفاء', 'Hide')),
              ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                if (!await _confirm(
                  context,
                  _t(
                    context,
                    'ئەم ناوەڕۆکە بە یەکجاری بسڕدرێتەوە؟',
                    'حذف هذا المحتوى نهائيًا؟',
                    'Delete this content permanently?',
                  ),
                )) {
                  return;
                }
                if (!context.mounted) return;
                await _run(context, () async {
                  final table = switch (type) {
                    'listing' => 'listings',
                    'service' => 'services',
                    _ => 'service_updates',
                  };
                  await _db.from(table).delete().eq('id', id);
                  RemovedRows.mark(table, id);
                  RemovedRows.mark('$table:active', id);
                  await _db
                      .from('content_reports')
                      .delete()
                      .eq('content_type', type)
                      .eq('content_id', id);
                  reload();
                });
              },
              child: Text(AppStrings.of(context).delete),
            ),
            TextButton(
              onPressed: () => _run(context, () async {
                await _db
                    .from('content_reports')
                    .delete()
                    .eq('content_type', type)
                    .eq('content_id', id);
                reload();
              }),
              child: Text(_t(context, 'پشتگوێخستن', 'تجاهل', 'Dismiss')),
            ),
          ],
        ),
      );
    }

    for (final row in userRows) {
      final name = names['${row['reported_user_id']}'];
      widgets.add(
        _Card(
          title:
              '${_t(context, 'بەکارهێنەر', 'مستخدم', 'User')}: ${name == null || name.isEmpty ? row['reported_user_id'] : name}',
          subtitle:
              '${_reason(context, '${row['reason']}')} · ${_date(row['created_at'])}${'${row['details'] ?? ''}'.isEmpty ? '' : '\n${row['details']}'}',
          actions: [
            TextButton(
              onPressed: () => _run(context, () async {
                await _db.from('user_reports').delete().eq('id', row['id']);
                reload();
              }),
              child: Text(_t(context, 'پشتگوێخستن', 'تجاهل', 'Dismiss')),
            ),
          ],
        ),
      );
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) => _AsyncList(
    load: _load,
    emptyText: _t(
      context,
      'هیچ ڕاپۆرتێک نییە.',
      'لا توجد بلاغات.',
      'No reports.',
    ),
  );
}

class _InstitutionsTab extends StatelessWidget {
  const _InstitutionsTab();

  static Future<List<Widget>> _load(
    BuildContext context,
    VoidCallback reload,
  ) async {
    final rows = List<Map<String, dynamic>>.from(
      await _db
          .from('institutions')
          .select()
          .eq('active', false)
          .order('createdAt', ascending: false),
    );
    if (!context.mounted) return const [];
    return [
      for (final row in rows)
        _Card(
          title: [
            '${row['nameKu'] ?? ''}',
            '${row['nameEn'] ?? ''}',
          ].where((v) => v.isNotEmpty).join(' · '),
          subtitle: [
            '${row['city'] ?? ''}',
            '${row['websiteUrl'] ?? ''}',
            '${row['phone'] ?? ''}',
          ].where((v) => v.isNotEmpty).join('\n'),
          actions: [
            TextButton(
              onPressed: () => _run(context, () async {
                await _db
                    .from('institutions')
                    .update({'active': true})
                    .eq('id', row['id']);
                reload();
              }),
              child: Text(_t(context, 'پەسەندکردن', 'موافقة', 'Approve')),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => _run(context, () async {
                await _db.from('institutions').delete().eq('id', row['id']);
                reload();
              }),
              child: Text(AppStrings.of(context).delete),
            ),
          ],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) => _AsyncList(
    load: _load,
    emptyText: _t(
      context,
      'هیچ دامەزراوەیەک چاوەڕێی پەسەندکردن نییە.',
      'لا توجد مؤسسات بانتظار الموافقة.',
      'No institutions waiting for review.',
    ),
  );
}

class _HiddenTab extends StatelessWidget {
  const _HiddenTab();

  static Future<List<Widget>> _load(
    BuildContext context,
    VoidCallback reload,
  ) async {
    final listings = List<Map<String, dynamic>>.from(
      await _db
          .from('listings')
          .select('id, title, sellerName')
          .eq('moderation_hidden', true),
    );
    final services = List<Map<String, dynamic>>.from(
      await _db
          .from('services')
          .select('id, name, address')
          .eq('moderation_hidden', true),
    );
    if (!context.mounted) return const [];

    Widget card(
      String table,
      Map<String, dynamic> row,
      String title,
      String sub,
    ) => _Card(
      title: title,
      subtitle: sub,
      actions: [
        TextButton(
          onPressed: () => _run(context, () async {
            await _db
                .from(table)
                .update({'moderation_hidden': false})
                .eq('id', row['id']);
            reload();
          }),
          child: Text(_t(context, 'گەڕاندنەوە', 'استعادة', 'Restore')),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: () => _run(context, () async {
            await _db.from(table).delete().eq('id', row['id']);
            RemovedRows.mark(table, row['id']);
            RemovedRows.mark('$table:active', row['id']);
            reload();
          }),
          child: Text(AppStrings.of(context).delete),
        ),
      ],
    );

    return [
      for (final r in listings)
        card(
          'listings',
          r,
          '${_t(context, 'بابەت', 'إعلان', 'Listing')}: ${r['title'] ?? ''}',
          '${r['sellerName'] ?? ''}',
        ),
      for (final r in services)
        card(
          'services',
          r,
          '${_t(context, 'شوێن', 'مكان', 'Place')}: ${r['name'] ?? ''}',
          '${r['address'] ?? ''}',
        ),
    ];
  }

  @override
  Widget build(BuildContext context) => _AsyncList(
    load: _load,
    emptyText: _t(
      context,
      'هیچ ناوەڕۆکێکی شاردراوە نییە.',
      'لا يوجد محتوى مخفي.',
      'No hidden content.',
    ),
  );
}

class _ErrorsTab extends StatelessWidget {
  const _ErrorsTab();

  static Future<List<Widget>> _load(
    BuildContext context,
    VoidCallback reload,
  ) async {
    final rows = List<Map<String, dynamic>>.from(
      await _db
          .from('app_errors')
          .select()
          .order('created_at', ascending: false)
          .limit(100),
    );
    if (!context.mounted) return const [];
    return [
      if (rows.isNotEmpty)
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => _run(context, () async {
              await _db.from('app_errors').delete().gte('id', 0);
              reload();
            }),
            icon: const Icon(Icons.delete_sweep_outlined),
            label: Text(
              _t(context, 'سڕینەوەی هەمووی', 'حذف الكل', 'Clear all'),
            ),
          ),
        ),
      for (final row in rows)
        _Card(
          title: '${row['message'] ?? ''}',
          subtitle:
              '${row['platform'] ?? ''} · ${row['app_version'] ?? ''} · ${_date(row['created_at'])}',
          onTap: () => showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text('${row['message'] ?? ''}', maxLines: 3),
              content: SingleChildScrollView(
                child: SelectableText(
                  '${row['stack'] ?? ''}',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) => _AsyncList(
    load: _load,
    emptyText: _t(
      context,
      'هیچ هەڵەیەک تۆمار نەکراوە.',
      'لم تُسجل أي أخطاء.',
      'No errors recorded.',
    ),
  );
}

class _StatsTab extends StatelessWidget {
  const _StatsTab();

  static Future<List<Widget>> _load(
    BuildContext context,
    VoidCallback reload,
  ) async {
    final data = Map<String, dynamic>.from(await _db.rpc('admin_stats') as Map);
    if (!context.mounted) return const [];
    String n(String key) => '${data[key] ?? 0}';
    List<Map<String, dynamic>> list(String key) =>
        List<Map<String, dynamic>>.from(data[key] as List? ?? const []);

    Widget tile(IconData icon, String label, String value, {String? extra}) =>
        _StatTile(icon: icon, label: label, value: value, extra: extra);

    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          tile(
            Icons.people_alt_outlined,
            _t(context, 'بەکارهێنەران', 'المستخدمون', 'Users'),
            n('users_total'),
            extra: _t(
              context,
              '+${n('users_7d')} لە ٧ ڕۆژدا',
              '+${n('users_7d')} خلال ٧ أيام',
              '+${n('users_7d')} in 7 days',
            ),
          ),
          tile(
            Icons.menu_book_outlined,
            _t(context, 'کاڵای چالاک', 'إعلانات نشطة', 'Active listings'),
            n('listings_active'),
            extra: _t(
              context,
              '+${n('listings_7d')} لە ٧ ڕۆژدا',
              '+${n('listings_7d')} خلال ٧ أيام',
              '+${n('listings_7d')} in 7 days',
            ),
          ),
          tile(
            Icons.chat_bubble_outline,
            _t(
              context,
              'نامە لە ٧ ڕۆژدا',
              'رسائل خلال ٧ أيام',
              'Messages (7 days)',
            ),
            n('messages_7d'),
            extra: _t(
              context,
              '${n('chats_7d')} چاتی چالاک',
              '${n('chats_7d')} محادثة نشطة',
              '${n('chats_7d')} active chats',
            ),
          ),
          tile(
            Icons.visibility_outlined,
            _t(context, 'بینینی کاڵاکان', 'مشاهدات الإعلانات', 'Listing views'),
            n('views_total'),
          ),
          tile(
            Icons.verified_outlined,
            _t(
              context,
              'قوتابی پشتڕاستکراو',
              'طلاب موثّقون',
              'Verified students',
            ),
            n('verified_users'),
            extra: _t(
              context,
              '${n('pending_verifications')} چاوەڕێ دەکەن',
              '${n('pending_verifications')} قيد الانتظار',
              '${n('pending_verifications')} waiting',
            ),
          ),
          tile(
            Icons.place_outlined,
            _t(context, 'شوێنەکان', 'الأماكن', 'Places'),
            n('places_total'),
          ),
          tile(
            Icons.star_outline_rounded,
            _t(context, 'کاڵای تایبەت', 'إعلانات مميزة', 'Featured'),
            n('featured_active'),
            extra: _t(
              context,
              '${n('pending_featured')} چاوەڕێ دەکەن',
              '${n('pending_featured')} قيد الانتظار',
              '${n('pending_featured')} waiting',
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      _RankCard(
        title: _t(
          context,
          'چالاکترین زانکۆکان',
          'أكثر الجامعات نشاطًا',
          'Most active universities',
        ),
        rows: list('top_universities'),
      ),
      _RankCard(
        title: _t(
          context,
          'زۆرترین بینراوی کاڵاکان',
          'الإعلانات الأكثر مشاهدة',
          'Most viewed listings',
        ),
        rows: list('top_listings'),
      ),
      _RankCard(
        title: _t(
          context,
          'زۆرترین کتێبی داواکراو',
          'أكثر الكتب طلبًا',
          'Most wanted books',
        ),
        rows: list('top_wanted'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) => _AsyncList(
    load: _load,
    emptyText: _t(
      context,
      'هیچ ئامارێک نییە.',
      'لا توجد إحصائيات.',
      'No data.',
    ),
  );
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? extra;
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeScope.of(context);
    final width = (MediaQuery.of(context).size.width - 32) / 2;
    return Container(
      width: width.clamp(140.0, 260.0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: palette.accent, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: palette.textSecondary, fontSize: 12.5),
          ),
          if (extra != null) ...[
            const SizedBox(height: 4),
            Text(extra!, style: TextStyle(color: palette.accent, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> rows;
  const _RankCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeScope.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Text('—', style: TextStyle(color: palette.textSecondary)),
          for (var i = 0; i < rows.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${i + 1}.',
                    style: TextStyle(color: palette.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${rows[i]['name'] ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: palette.textPrimary),
                    ),
                  ),
                  Text(
                    '${rows[i]['total'] ?? 0}',
                    style: TextStyle(
                      color: palette.accent,
                      fontWeight: FontWeight.w800,
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

class _VerificationTab extends StatelessWidget {
  const _VerificationTab();

  static Future<List<Widget>> _load(
    BuildContext context,
    VoidCallback reload,
  ) async {
    final repo = VerificationRepository();
    final requests = await repo.pending();
    final names = <String, String>{};
    if (requests.isNotEmpty) {
      for (final r
          in await _db
              .from('profiles')
              .select('id, displayName')
              .inFilter('id', requests.map((e) => e.userId).toSet().toList())) {
        names['${r['id']}'] = '${r['displayName'] ?? ''}';
      }
    }
    final verified = List<Map<String, dynamic>>.from(
      await _db
          .from('profiles')
          .select('id, displayName')
          .eq('is_verified', true)
          .order('displayName'),
    );
    if (!context.mounted) return const [];
    if (requests.isEmpty && verified.isEmpty) return const [];
    return [
      for (final request in requests)
        _VerificationCard(
          request: request,
          name: names[request.userId] ?? '',
          onDone: reload,
        ),
      if (verified.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
          child: Text(
            _t(
              context,
              'قوتابیانی پشتڕاستکراو (${verified.length})',
              'الطلاب الموثّقون (${verified.length})',
              'Verified students (${verified.length})',
            ),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      for (final row in verified)
        _Card(
          title: '${row['displayName'] ?? ''}'.trim().isEmpty
              ? '${row['id']}'
              : '${row['displayName']}',
          subtitle: _t(
            context,
            'نیشانەی ✓ ی هەیە',
            'لديه علامة ✓',
            'Has the ✓ badge',
          ),
          actions: [
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                final ok = await _confirm(
                  context,
                  _t(
                    context,
                    'نیشانەی ✓ لەم کەسە لابدرێت؟',
                    'إزالة علامة ✓ من هذا الشخص؟',
                    'Remove the ✓ badge from this person?',
                  ),
                );
                if (!ok || !context.mounted) return;
                await _run(context, () async {
                  await _db.rpc(
                    'admin_set_verified',
                    params: {'uid': row['id'], 'verified': false},
                  );
                  reload();
                });
              },
              icon: const Icon(Icons.remove_moderator_outlined),
              label: Text(_t(context, 'لابردنی ✓', 'إزالة ✓', 'Remove ✓')),
            ),
          ],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) => _AsyncList(
    load: _load,
    emptyText: _t(
      context,
      'هیچ داواکارییەک چاوەڕێ ناکات.',
      'لا توجد طلبات بانتظار المراجعة.',
      'No requests waiting.',
    ),
  );
}

class _VerificationCard extends StatefulWidget {
  final VerificationRequest request;
  final String name;
  final VoidCallback onDone;
  const _VerificationCard({
    required this.request,
    required this.name,
    required this.onDone,
  });

  @override
  State<_VerificationCard> createState() => _VerificationCardState();
}

class _VerificationCardState extends State<_VerificationCard> {
  late final Future<String> _url = VerificationRepository().photoUrl(
    widget.request.imagePath,
  );
  bool _busy = false;

  Future<void> _decide(bool approve) async {
    setState(() => _busy = true);
    await _run(context, () async {
      await VerificationRepository().review(widget.request, approve: approve);
      widget.onDone();
    });
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeScope.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.name.isEmpty ? widget.request.userId : widget.name,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            _date(widget.request.createdAt?.toIso8601String()),
            style: TextStyle(color: palette.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          FutureBuilder<String>(
            future: _url,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(snap.data!, fit: BoxFit.contain),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: _busy ? null : () => _decide(false),
                  child: Text(_t(context, 'ڕەتکردنەوە', 'رفض', 'Reject')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.primary,
                  ),
                  onPressed: _busy ? null : () => _decide(true),
                  child: Text(
                    _t(context, 'پەسەندکردن ✓', 'قبول ✓', 'Approve ✓'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _t(
              context,
              'دوای بڕیاردان وێنەکە دەسڕدرێتەوە.',
              'تُحذف الصورة بعد القرار.',
              'The photo is deleted after the decision.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textSecondary, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _FeaturedTab extends StatelessWidget {
  const _FeaturedTab();

  static Future<List<Widget>> _load(
    BuildContext context,
    VoidCallback reload,
  ) async {
    final requests = await FeaturedRepository().pending();
    final titles = <String, String>{};
    final names = <String, String>{};
    if (requests.isNotEmpty) {
      for (final r
          in await _db
              .from('listings')
              .select('id, title')
              .inFilter(
                'id',
                requests.map((e) => e.listingId).toSet().toList(),
              )) {
        titles['${r['id']}'] = '${r['title'] ?? ''}';
      }
      for (final r
          in await _db
              .from('profiles')
              .select('id, displayName')
              .inFilter('id', requests.map((e) => e.userId).toSet().toList())) {
        names['${r['id']}'] = '${r['displayName'] ?? ''}';
      }
    }
    if (!context.mounted) return const [];
    return [
      for (final request in requests)
        _FeaturedCard(
          request: request,
          title: titles[request.listingId] ?? request.listingId,
          name: names[request.userId] ?? '',
          onDone: reload,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) => _AsyncList(
    load: _load,
    emptyText: _t(
      context,
      'هیچ داواکارییەک چاوەڕێ ناکات.',
      'لا توجد طلبات بانتظار المراجعة.',
      'No requests waiting.',
    ),
  );
}

class _FeaturedCard extends StatefulWidget {
  final FeaturedRequest request;
  final String title;
  final String name;
  final VoidCallback onDone;
  const _FeaturedCard({
    required this.request,
    required this.title,
    required this.name,
    required this.onDone,
  });

  @override
  State<_FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<_FeaturedCard> {
  // Only photos in our private receipts bucket are shown as images; any
  // other text (even a web link) is shown as plain text, never loaded.
  late final Future<String?> _receiptUrl =
      widget.request.receipt.startsWith(
        '${SupabaseStorageService.receiptBucket}/',
      )
      ? SupabaseStorageService.receiptViewUrl(widget.request.receipt)
      : Future<String?>.value(null);
  bool _busy = false;

  Future<void> _decide(bool approve) async {
    setState(() => _busy = true);
    await _run(context, () async {
      await FeaturedRepository().review(widget.request, approve: approve);
      widget.onDone();
    });
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeScope.of(context);
    final r = widget.request;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            '${widget.name} · ${r.days} ${_t(context, 'ڕۆژ', 'يوم', 'days')} · ${r.priceIqd} IQD · ${_date(r.createdAt?.toIso8601String())}',
            style: TextStyle(color: palette.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          FutureBuilder<String?>(
            future: _receiptUrl,
            builder: (context, snap) {
              final url = snap.data;
              if (url == null) {
                return SelectableText(
                  '${_t(context, 'ژمارەی مامەڵە', 'رقم العملية', 'Transaction')}: ${r.receipt}',
                  style: TextStyle(color: palette.textPrimary),
                );
              }
              return InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(url, fit: BoxFit.contain),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: _busy ? null : () => _decide(false),
                  child: Text(_t(context, 'ڕەتکردنەوە', 'رفض', 'Reject')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.primary,
                  ),
                  onPressed: _busy ? null : () => _decide(true),
                  child: Text(
                    _t(context, 'چالاککردن ⭐', 'تفعيل ⭐', 'Activate ⭐'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
