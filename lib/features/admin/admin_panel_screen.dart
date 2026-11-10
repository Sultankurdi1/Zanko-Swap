import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final palette = AppThemeScope.of(context);
    String t(String ku, String ar, String en) =>
        s.isKurdish ? ku : (s.isArabic ? ar : en);

    return DefaultTabController(
      length: 4,
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
              Tab(text: t('ڕاپۆرتەکان', 'البلاغات', 'Reports')),
              Tab(text: t('دامەزراوەکان', 'المؤسسات', 'Institutions')),
              Tab(text: t('شاردراوەکان', 'المخفية', 'Hidden')),
              Tab(text: t('هەڵەکانی ئەپ', 'أخطاء التطبيق', 'App errors')),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
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
