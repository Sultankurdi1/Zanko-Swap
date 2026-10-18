import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/auth_permissions.dart';
import '../../../core/data/favorites_store.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/models/exam_paper.dart';
import '../../../core/theme/app_theme.dart';
import '../data/exam_repository.dart';
import 'add_exam_paper_screen.dart';
import 'exam_gallery_screen.dart';

class ExamPapersScreen extends StatefulWidget {
  const ExamPapersScreen({super.key});
  @override
  State<ExamPapersScreen> createState() => _ExamPapersScreenState();
}

class _ExamPapersScreenState extends State<ExamPapersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs = TabController(length: 2, vsync: this);
  final repo = ExamRepository();
  final search = TextEditingController();
  String query = '';
  String year = '';

  @override
  void initState() {
    super.initState();
    search.addListener(() => setState(() => query = search.text.trim()));
  }

  @override
  void dispose() {
    tabs.dispose();
    search.dispose();
    super.dispose();
  }

  Future<void> _openAdd() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.of(context).signIn)));
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddExamPaperScreen()),
    );
  }

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
          s.examPapers,
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
            fontWeight: FontWeight.w900,
            fontSize: 13.5,
          ),
          tabs: [
            Tab(text: s.scientificTrack),
            Tab(text: s.literaryTrack),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 125,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?auto=format&fit=crop&w=1200&q=80',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.25),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              padding: const EdgeInsets.all(16),
              alignment: Alignment.bottomRight,
              child: Text(
                s.examPapers,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: palette.border),
                    ),
                    child: TextField(
                      controller: search,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 13.5,
                      ),
                      decoration: InputDecoration(
                        hintText: s.isKurdish
                            ? 'گەڕان بۆ وانە (بیرکاری، فیزیا...)'
                            : s.search,
                        hintStyle: TextStyle(
                          color: palette.textSecondary.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: palette.accent,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 95,
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: palette.border),
                  ),
                  child: TextField(
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() => year = v.trim()),
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 13.5,
                    ),
                    decoration: InputDecoration(
                      labelText: s.year,
                      labelStyle: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 12,
                      ),
                      hintText: '2024',
                      hintStyle: TextStyle(
                        color: palette.textSecondary.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: tabs,
              children: [
                _ExamList(
                  track: 'scientific',
                  year: year,
                  subject: query,
                  repo: repo,
                  palette: palette,
                ),
                _ExamList(
                  track: 'literary',
                  year: year,
                  subject: query,
                  repo: repo,
                  palette: palette,
                ),
              ],
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
          onPressed: _openAdd,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            s.addExamPaper,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _ExamList extends StatelessWidget {
  final String track;
  final String year;
  final String subject;
  final ExamRepository repo;
  final AppPalette palette;

  const _ExamList({
    required this.track,
    required this.year,
    required this.subject,
    required this.repo,
    required this.palette,
  });

  Future<List<ExamPaper>> _fetchFallback() async {
    var queryBuilder = Supabase.instance.client
        .from('exam_papers')
        .select()
        .eq('track', track);

    if (year.isNotEmpty) {
      queryBuilder = queryBuilder.eq('year', year);
    }
    if (subject.isNotEmpty) {
      queryBuilder = queryBuilder.ilike('subject', '%$subject%');
    }

    final rows = await queryBuilder.order('createdAt', ascending: false);
    return (rows as List).map((map) => ExamPaper.fromMap(map)).toList();
  }

  Future<void> _deleteExam(BuildContext context, ExamPaper exam) async {
    final s = AppStrings.of(context);
    final permissions = AuthPermissions();
    if (!permissions.canManage(exam.authorId)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          s.isArabic
              ? 'حذف ورقة الامتحان؟'
              : s.isKurdish
              ? 'دەتەوێ ئەسیلەکە بسڕیتەوە؟'
              : 'Delete this exam paper?',
          style: TextStyle(color: palette.textPrimary),
        ),
        content: Text(
          s.isKurdish
              ? 'ئەم کردارە ناگەڕێتەوە.'
              : s.isArabic
              ? 'لا يمكن التراجع عن هذا الإجراء.'
              : 'This action cannot be undone.',
          style: TextStyle(color: palette.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              s.cancel,
              style: TextStyle(color: palette.textSecondary),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF87171),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ExamRepository().delete(exam.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Widget _buildList(BuildContext context, List<ExamPaper> items, AppStrings s) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          s.noExamPapersYet,
          style: TextStyle(color: palette.textSecondary),
        ),
      );
    }
    final permissions = AuthPermissions();
    return AnimatedBuilder(
      animation: FavoritesStore.instance,
      builder: (context, _) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final e = items[i];
          final saved = FavoritesStore.instance.containsExam(e.id);
          return Container(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.border),
            ),
            child: ExpansionTile(
              shape: const Border(),
              iconColor: palette.accent,
              collapsedIconColor: palette.textSecondary,
              title: Text(
                '${e.subject} ${e.year.isNotEmpty ? "(${e.year})" : ""}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
              subtitle: Text(
                '${s.by} ${e.authorName} • ${e.track}',
                style: TextStyle(color: palette.textSecondary, fontSize: 12),
              ),
              trailing: Wrap(
                children: [
                  IconButton(
                    onPressed: () => FavoritesStore.instance.toggleExam(e.id),
                    icon: Icon(
                      saved
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: saved
                          ? const Color(0xFFF87171)
                          : palette.textSecondary,
                    ),
                  ),
                  if (permissions.canManage(e.authorId)) ...[
                    IconButton(
                      tooltip: s.isKurdish
                          ? 'دەستکاری'
                          : s.isArabic
                          ? 'تعديل'
                          : 'Edit',
                      icon: Icon(Icons.edit_rounded, color: palette.accent),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddExamPaperScreen(existing: e),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: s.delete,
                      icon: const Icon(
                        Icons.delete_rounded,
                        color: Color(0xFFF87171),
                      ),
                      onPressed: () => _deleteExam(context, e),
                    ),
                  ],
                ],
              ),
              children: [
                if (e.images.isNotEmpty)
                  SizedBox(
                    height: 116,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                      scrollDirection: Axis.horizontal,
                      itemCount: e.images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, index) => GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExamGalleryScreen(
                              images: e.images,
                              initialIndex: index,
                            ),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            e.images[index],
                            width: 102,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 102,
                              height: 100,
                              color: palette.surfaceHighlight,
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: palette.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (e.content.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        e.content,
                        style: TextStyle(
                          color: palette.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return StreamBuilder<List<ExamPaper>>(
      stream: repo.stream(track: track, year: year, subject: subject),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _ExamSkeleton(palette: palette);
        }

        if (snapshot.hasError) {
          return FutureBuilder<List<ExamPaper>>(
            future: _fetchFallback(),
            builder: (context, fallbackSnap) {
              if (fallbackSnap.connectionState == ConnectionState.waiting &&
                  !fallbackSnap.hasData) {
                return _ExamSkeleton(palette: palette);
              }
              final items = fallbackSnap.data ?? const <ExamPaper>[];
              return _buildList(context, items, s);
            },
          );
        }

        final items = snapshot.data ?? const <ExamPaper>[];
        return _buildList(context, items, s);
      },
    );
  }
}

class _ExamSkeleton extends StatelessWidget {
  final AppPalette palette;
  const _ExamSkeleton({required this.palette});

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: 6,
    itemBuilder: (_, __) => Container(
      height: 82,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: palette.surfaceHighlight,
        borderRadius: BorderRadius.circular(18),
      ),
    ),
  );
}
