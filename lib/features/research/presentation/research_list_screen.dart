import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/data/auth_permissions.dart';
import '../../../core/data/favorites_store.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/models/academic_path.dart';
import '../../../core/models/research_paper.dart';
import '../../../core/theme/app_theme.dart';
import '../data/research_repository.dart';
import 'add_research_screen.dart';
import 'pdf_viewer_screen.dart';

class ResearchListScreen extends StatefulWidget {
  final AcademicPath? filterPath;
  const ResearchListScreen({super.key, this.filterPath});
  @override
  State<ResearchListScreen> createState() => _ResearchListScreenState();
}

class _ResearchListScreenState extends State<ResearchListScreen> {
  final repo = ResearchRepository();
  final search = TextEditingController();
  String query = '';

  @override
  void initState() {
    super.initState();
    search.addListener(
      () => setState(() => query = search.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> _deleteResearch(
    BuildContext context,
    ResearchPaper paper,
    AppPalette palette,
  ) async {
    final s = AppStrings.of(context);
    if (!AuthPermissions().canManage(paper.authorId)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          s.isArabic
              ? 'حذف البحث؟'
              : s.isKurdish
              ? 'دەتەوێ توێژینەوەکە بسڕیتەوە؟'
              : 'Delete this research?',
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
      await repo.delete(paper.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
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
          s.researchPapers,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: palette.accent,
            letterSpacing: -0.5,
          ),
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
                  'https://images.unsplash.com/photo-1532094349884-543bc11b234d?auto=format&fit=crop&w=1200&q=80',
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
                s.researchPapers,
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
            child: Container(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.border),
              ),
              child: TextField(
                controller: search,
                style: TextStyle(color: palette.textPrimary, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: s.isKurdish
                      ? 'گەڕان بۆ ناونیشانی توێژینەوە، زانکۆ یان نووسەر...'
                      : s.search,
                  hintStyle: TextStyle(
                    color: palette.textSecondary.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(Icons.search_rounded, color: palette.accent),
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
            child: StreamBuilder<List<ResearchPaper>>(
              stream: repo.stream(
                departmentId: widget.filterPath?.departmentName,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _ResearchSkeleton(palette: palette);
                }
                if (snapshot.hasError) {
                  return _ErrorRetry(
                    palette: palette,
                    message: '${snapshot.error}',
                    onRetry: () => setState(() {}),
                  );
                }
                final items = (snapshot.data ?? const <ResearchPaper>[]).where((
                  r,
                ) {
                  if (query.isEmpty) return true;
                  final text =
                      '${r.title} ${r.description} ${r.authorName} ${r.path.summary}'
                          .toLowerCase();
                  return text.contains(query);
                }).toList();
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      s.noResearchYet,
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
                      final r = items[i];
                      final saved = FavoritesStore.instance.containsResearch(
                        r.id,
                      );
                      final isPdf =
                          r.linkOrContent.startsWith('http') &&
                          r.linkOrContent.toLowerCase().contains('.pdf');
                      return Container(
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: palette.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      r.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        color: palette.textPrimary,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => FavoritesStore.instance
                                        .toggleResearch(r.id),
                                    icon: Icon(
                                      saved
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      color: saved
                                          ? const Color(0xFFF87171)
                                          : palette.textSecondary,
                                    ),
                                  ),
                                  if (permissions.canManage(r.authorId)) ...[
                                    IconButton(
                                      tooltip: s.isKurdish
                                          ? 'دەستکاری'
                                          : 'Edit',
                                      icon: Icon(
                                        Icons.edit_rounded,
                                        color: palette.accent,
                                      ),
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              AddResearchScreen(existing: r),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: s.delete,
                                      icon: const Icon(
                                        Icons.delete_rounded,
                                        color: Color(0xFFF87171),
                                      ),
                                      onPressed: () =>
                                          _deleteResearch(context, r, palette),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                r.path.summary,
                                style: TextStyle(
                                  color: palette.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              if (r.description.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  r.description,
                                  style: TextStyle(
                                    color: palette.textPrimary,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                              if (r.linkOrContent.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                if (isPdf)
                                  InkWell(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PdfViewerScreen(
                                          url: r.linkOrContent,
                                          title: r.title,
                                        ),
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: palette.primary.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.picture_as_pdf_rounded,
                                            size: 16,
                                            color: palette.accent,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            s.isKurdish
                                                ? 'کردنەوەی PDF'
                                                : 'Open PDF',
                                            style: TextStyle(
                                              color: palette.accent,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  Text(
                                    r.linkOrContent,
                                    style: TextStyle(
                                      color: palette.accent,
                                      fontSize: 12.5,
                                    ),
                                  ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                '${s.by} ${r.authorName}',
                                style: TextStyle(
                                  color: palette.textSecondary,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
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
          onPressed: () {
            if (Supabase.instance.client.auth.currentUser == null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(s.signIn)));
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddResearchScreen(
                  initialPath: widget.filterPath ?? const AcademicPath(),
                ),
              ),
            );
          },
          icon: const Icon(Icons.add_rounded),
          label: Text(
            s.addResearch,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _ResearchSkeleton extends StatelessWidget {
  final AppPalette palette;
  const _ResearchSkeleton({required this.palette});

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: 6,
    itemBuilder: (_, __) => Container(
      height: 128,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: palette.surfaceHighlight,
        borderRadius: BorderRadius.circular(18),
      ),
    ),
  );
}

class _ErrorRetry extends StatelessWidget {
  final AppPalette palette;
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({
    required this.palette,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: palette.primary),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}
