import 'package:flutter/material.dart';
import '../../../core/data/favorites_store.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/exam_paper.dart';
import '../../../core/models/listing.dart';
import '../../../core/models/research_paper.dart';
import '../../exams/data/exam_repository.dart';
import '../../exams/presentation/exam_gallery_screen.dart';
import '../../listings/presentation/item_details_screen.dart';
import '../../listings/data/listing_repository.dart';
import '../../research/data/research_repository.dart';
import '../../research/presentation/pdf_viewer_screen.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final palette = AppThemeScope.of(context);

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: palette.bg,
        title: Text(
          s.saved,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: palette.accent,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: FavoritesStore.instance,
        builder: (context, _) {
          return StreamBuilder<List<Listing>>(
            stream: ListingRepository().streamListings(),
            builder: (context, listingSnap) {
              return StreamBuilder<List<ExamPaper>>(
                stream: ExamRepository().stream(),
                builder: (context, examSnap) {
                  return StreamBuilder<List<ResearchPaper>>(
                    stream: ResearchRepository().stream(),
                    builder: (context, researchSnap) {
                      if (listingSnap.connectionState ==
                              ConnectionState.waiting &&
                          examSnap.connectionState == ConnectionState.waiting &&
                          researchSnap.connectionState ==
                              ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: palette.primary,
                          ),
                        );
                      }

                      final listings = (listingSnap.data ?? const <Listing>[])
                          .where(
                            (item) => FavoritesStore.instance.containsListing(
                              item.id,
                            ),
                          )
                          .toList();

                      final exams = (examSnap.data ?? const <ExamPaper>[])
                          .where(
                            (exam) =>
                                FavoritesStore.instance.containsExam(exam.id),
                          )
                          .toList();

                      final researches =
                          (researchSnap.data ?? const <ResearchPaper>[])
                              .where(
                                (res) => FavoritesStore.instance
                                    .containsResearch(res.id),
                              )
                              .toList();

                      final isEmpty =
                          listings.isEmpty &&
                          exams.isEmpty &&
                          researches.isEmpty;

                      if (isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  color: palette.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.bookmark_border_rounded,
                                  size: 64,
                                  color: palette.accent,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                s.isKurdish
                                    ? 'هیچ شتێک لە دڵخوازەکان نییە'
                                    : 'No saved items',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: palette.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                s.isKurdish
                                    ? 'ئەو شتانەی پاشەکەوتیان دەکەیت لێرەدا دەردەکەون'
                                    : 'Items you bookmark will show up here',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: palette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        children: [
                          if (listings.isNotEmpty) ...[
                            _buildTitle(s.books, palette),
                            ...listings.map(
                              (item) => Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: palette.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: palette.border),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ItemDetailsScreen(listing: item),
                                    ),
                                  ),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 52,
                                      height: 52,
                                      child: item.images.isEmpty
                                          ? Container(
                                              color: palette.surfaceHighlight,
                                              child: Icon(
                                                Icons.inventory_2_outlined,
                                                color: palette.textSecondary,
                                              ),
                                            )
                                          : Image.network(
                                              item.images.first,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                    color: palette
                                                        .surfaceHighlight,
                                                    child: Icon(
                                                      Icons
                                                          .broken_image_rounded,
                                                      color:
                                                          palette.textSecondary,
                                                    ),
                                                  ),
                                            ),
                                    ),
                                  ),
                                  title: Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: palette.textPrimary,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                  subtitle: Text(
                                    item.sellerName,
                                    style: TextStyle(
                                      color: palette.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    onPressed: () => FavoritesStore.instance
                                        .toggleListing(item.id),
                                    icon: const Icon(
                                      Icons.favorite_rounded,
                                      color: Color(0xFFF87171),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (exams.isNotEmpty) ...[
                            _buildTitle(s.examsLabel, palette),
                            ...exams.map(
                              (item) => Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: palette.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: palette.border),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  onTap: item.images.isEmpty
                                      ? null
                                      : () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ExamGalleryScreen(
                                              images: item.images,
                                            ),
                                          ),
                                        ),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: palette.primary.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.assignment_rounded,
                                      color: palette.accent,
                                    ),
                                  ),
                                  title: Text(
                                    item.subject,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: palette.textPrimary,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${item.year} • ${item.track}',
                                    style: TextStyle(
                                      color: palette.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    onPressed: () => FavoritesStore.instance
                                        .toggleExam(item.id),
                                    icon: const Icon(
                                      Icons.favorite_rounded,
                                      color: Color(0xFFF87171),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (researches.isNotEmpty) ...[
                            _buildTitle(s.researchesLabel, palette),
                            ...researches.map(
                              (item) => Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: palette.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: palette.border),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  onTap: item.linkOrContent.startsWith('http')
                                      ? () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PdfViewerScreen(
                                              url: item.linkOrContent,
                                              title: item.title,
                                            ),
                                          ),
                                        )
                                      : null,
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF06B6D4,
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.science_rounded,
                                      color: Color(0xFF06B6D4),
                                    ),
                                  ),
                                  title: Text(
                                    item.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: palette.textPrimary,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                  subtitle: Text(
                                    item.path.summary,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: palette.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    onPressed: () => FavoritesStore.instance
                                        .toggleResearch(item.id),
                                    icon: const Icon(
                                      Icons.favorite_rounded,
                                      color: Color(0xFFF87171),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  static Widget _buildTitle(String title, AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 15,
          color: palette.accent,
        ),
      ),
    );
  }
}
