import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/search_text.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/models/listing.dart';
import '../../../core/theme/app_theme.dart';
import '../data/listing_repository.dart';
import 'item_details_screen.dart';

class WantedScreen extends StatefulWidget {
  const WantedScreen({super.key, this.initialTitle});

  final String? initialTitle;

  @override
  State<WantedScreen> createState() => _WantedScreenState();
}

class _WantedScreenState extends State<WantedScreen> {
  static const _seenKey = 'wanted_last_seen';
  final _db = Supabase.instance.client;
  late final TextEditingController _title = TextEditingController(
    text: widget.initialTitle ?? '',
  );
  late final Stream<List<Listing>> _listings = ListingRepository()
      .streamListings();
  late Future<List<Map<String, dynamic>>> _requests;
  DateTime? _lastSeen;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _requests = _loadRequests();
    _loadLastSeen();
  }

  @override
  void dispose() {
    _title.dispose();
    _markSeen();
    super.dispose();
  }

  Future<void> _loadLastSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = DateTime.tryParse(prefs.getString(_seenKey) ?? '');
      if (mounted) setState(() => _lastSeen = value);
    } catch (_) {}
  }

  Future<void> _markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_seenKey, DateTime.now().toIso8601String());
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> _loadRequests() async {
    final me = _db.auth.currentUser?.id;
    if (me == null) return const [];
    return List<Map<String, dynamic>>.from(
      await _db
          .from('book_requests')
          .select()
          .eq('user_id', me)
          .order('created_at', ascending: false),
    );
  }

  String _t(String ku, String ar, String en) {
    final s = AppStrings.of(context);
    return s.isKurdish ? ku : (s.isArabic ? ar : en);
  }

  Future<void> _add() async {
    final title = _title.text.trim();
    if (title.length < 2) return;
    final s = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await _db.from('book_requests').insert({'title': title});
      _title.clear();
      setState(() => _requests = _loadRequests());
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(s.errorFor(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(Object id) async {
    await _db.from('book_requests').delete().eq('id', id);
    if (mounted) setState(() => _requests = _loadRequests());
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeScope.of(context);
    final signedIn = _db.auth.currentUser != null;
    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.bg,
        foregroundColor: palette.textPrimary,
        title: Text(_t('کتێبە داواکراوەکانم', 'كتب أبحث عنها', 'Books I want')),
      ),
      body: !signedIn
          ? Center(child: Text(AppStrings.of(context).signInFirst))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  _t(
                    'ناوی ئەو کتێبانە بنووسە کە بەدوایاندا دەگەڕێیت. هەر کاتێک کەسێک دایبنێت، لێرە دەردەکەوێت.',
                    'اكتب أسماء الكتب التي تبحث عنها، وستظهر هنا عندما يعرضها أحد.',
                    'Write the books you are looking for. When someone lists one, it shows up here.',
                  ),
                  style: TextStyle(color: palette.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _title,
                        maxLength: 120,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _add(),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: _t(
                            'بۆ نموونە: بیرکاری قۆناغی ٢',
                            'مثال: رياضيات المرحلة الثانية',
                            'e.g. Calculus stage 2',
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      onPressed: _busy ? null : _add,
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _requests,
                  builder: (context, reqSnap) {
                    final requests = reqSnap.data ?? const [];
                    if (reqSnap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (requests.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _t(
                            'هێشتا هیچ کتێبێکت زیاد نەکردووە.',
                            'لم تضف أي كتاب بعد.',
                            'No books added yet.',
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: palette.textSecondary),
                        ),
                      );
                    }
                    return StreamBuilder<List<Listing>>(
                      stream: _listings,
                      builder: (context, listSnap) {
                        final listings = listSnap.data ?? const <Listing>[];
                        return Column(
                          children: [
                            for (final r in requests)
                              _requestCard(palette, r, listings),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
    );
  }

  Widget _requestCard(
    AppPalette palette,
    Map<String, dynamic> request,
    List<Listing> listings,
  ) {
    final title = '${request['title'] ?? ''}';
    final me = _db.auth.currentUser?.id;
    final matches = listings
        .where(
          (l) =>
              l.status == 'active' &&
              l.sellerId != me &&
              SearchText.matches(title, [l.title, l.description, l.subject]),
        )
        .toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: ExpansionTile(
        shape: const Border(),
        title: Text(
          title,
          style: TextStyle(
            color: palette.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          matches.isEmpty
              ? _t('هێشتا نەدۆزراوەتەوە', 'لم يُعثر عليه بعد', 'Not found yet')
              : _t(
                  '${matches.length} کاڵا دۆزرایەوە',
                  'وُجد ${matches.length} إعلان',
                  '${matches.length} found',
                ),
          style: TextStyle(
            color: matches.isEmpty ? palette.textSecondary : palette.accent,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: palette.textSecondary),
          onPressed: () => _remove(request['id'] as Object),
        ),
        children: [
          for (final l in matches)
            ListTile(
              title: Text(
                l.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                l.priceIQD > 0 ? '${l.priceIQD} IQD' : l.universityName,
              ),
              trailing: _lastSeen != null && l.createdAt.isAfter(_lastSeen!)
                  ? Chip(label: Text(_t('نوێ', 'جديد', 'New')))
                  : const Icon(Icons.chevron_left),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ItemDetailsScreen(listing: l),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
