import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/localization/app_strings.dart';
import '../core/models/ad_campaign.dart';
import '../core/theme/app_theme.dart';
import 'ads/data/ad_repository.dart';
import 'ads/presentation/create_ad_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final adRepo = AdRepository();
  Key refreshKey = UniqueKey();

  Future<void> _openAdLink(AdCampaign ad) async {
    if (ad.id.isNotEmpty) {
      adRepo.logClick(ad.id);
    }
    final rawUrl = ad.targetUrl.trim();
    if (rawUrl.isNotEmpty) {
      final fullUrl =
          (rawUrl.startsWith('http://') || rawUrl.startsWith('https://'))
          ? rawUrl
          : 'https://$rawUrl';
      final uri = Uri.tryParse(fullUrl);
      if (uri != null) {
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {}
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
          s.courses,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: palette.accent,
            letterSpacing: -0.5,
          ),
        ),
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
          focusElevation: 0,
          hoverElevation: 0,
          highlightElevation: 0,
          foregroundColor: Colors.white,
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const CreateAdScreen(defaultPlacement: 'course'),
              ),
            );
            setState(() {
              refreshKey = UniqueKey();
            });
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'زیادکردنی کۆرس',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: palette.primary,
        backgroundColor: palette.surfaceHighlight,
        onRefresh: () async {
          setState(() {
            refreshKey = UniqueKey();
          });
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: palette.headerGradient ?? palette.buttonGradient,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: palette.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: palette.isDark ? 0.25 : 0.08,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎓 کۆرس و پەیمانگاکان',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'کۆرس و خولە ڕاستەقینەکانی پەیمانگاکانی کوردستان لێرەدا بدۆزەوە و ڕاستەوخۆ پەیوەندییان پێوە بکە.',
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            FutureBuilder<List<AdCampaign>>(
              key: refreshKey,
              future: adRepo.fetchAdsByPlacement('course'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: palette.primary),
                    ),
                  );
                }

                final ads = snapshot.data ?? [];

                if (ads.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 70,
                          color: palette.textSecondary.withValues(alpha: 0.35),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'هێشتا هیچ کۆرسێک بڵاونەکراوەتەوە',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'پەیمانگا و ڕاهێنەرەکان دەتوانن لە ڕێگەی دوگمەی خوارەوە کۆرسەکانیان زیاد بکەن.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: palette.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ads.length} کۆرسی بەردەست',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...ads.map(
                      (ad) => _RealCourseCard(
                        ad: ad,
                        palette: palette,
                        onTap: () => _openAdLink(ad),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RealCourseCard extends StatelessWidget {
  final AdCampaign ad;
  final AppPalette palette;
  final VoidCallback onTap;

  const _RealCourseCard({
    required this.ad,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = ad.imageUrl.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: hasImage
                        ? Image.network(
                            ad.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: palette.surfaceHighlight,
                              child: Icon(
                                Icons.school_rounded,
                                color: palette.textSecondary,
                              ),
                            ),
                          )
                        : Container(
                            color: palette.surfaceHighlight,
                            child: Icon(
                              Icons.school_rounded,
                              color: palette.textSecondary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ad.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: palette.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: palette.buttonGradient,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ڕیکلام',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        ad.advertiser,
                        style: TextStyle(
                          color: palette.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                      if (ad.subtitle.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          ad.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: onTap,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: palette.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'پەیوەندی و بینین',
                                style: TextStyle(
                                  color: palette.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: palette.accent,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
