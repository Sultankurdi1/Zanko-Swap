import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../data/listing_repository.dart';
import '../../../core/models/listing.dart';
import 'item_details_screen.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final palette = AppThemeScope.of(context);
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
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
            s.activeListings,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
        ),
        body: Center(
          child: Text(s.signIn, style: TextStyle(color: palette.textSecondary)),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: palette.bg,
        appBar: AppBar(
          backgroundColor: palette.bg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: palette.textSecondary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            s.isKurdish
                ? 'بابەتەکانی من'
                : s.isArabic
                ? 'إعلاناتي'
                : 'My listings',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: palette.accent,
              letterSpacing: -0.5,
            ),
          ),
          bottom: TabBar(
            indicatorColor: palette.primary,
            indicatorWeight: 3,
            labelColor: palette.accent,
            unselectedLabelColor: palette.textSecondary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
            tabs: [
              Tab(
                text: s.isKurdish
                    ? 'چالاکەکان'
                    : s.isArabic
                    ? 'النشطة'
                    : 'Active',
              ),
              Tab(
                text: s.isKurdish
                    ? 'فرۆشراوەکان'
                    : s.isArabic
                    ? 'المباعة'
                    : 'Sold',
              ),
            ],
          ),
        ),
        body: StreamBuilder<List<Listing>>(
          stream: ListingRepository().streamMyListings(user.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: palette.primary),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }
            final items = snapshot.data ?? const <Listing>[];
            return TabBarView(
              children: [
                _ListingStatusList(
                  items: items.where((x) => x.status == 'active').toList(),
                  status: 'active',
                  palette: palette,
                ),
                _ListingStatusList(
                  items: items.where((x) => x.status == 'sold').toList(),
                  status: 'sold',
                  palette: palette,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ListingStatusList extends StatelessWidget {
  final List<Listing> items;
  final String status;
  final AppPalette palette;

  const _ListingStatusList({
    required this.items,
    required this.status,
    required this.palette,
  });

  Future<void> _deleteListing(BuildContext context, Listing listing) async {
    final s = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          s.isArabic
              ? 'حذف الإعلان؟'
              : s.isKurdish
              ? 'بابەتەکە بسڕدرێتەوە؟'
              : 'Delete listing?',
          style: TextStyle(
            color: palette.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          s.isArabic
              ? 'لا يمكن التراجع عن هذا الإجراء.'
              : s.isKurdish
              ? 'ئەم کردارە ناگەڕێتەوە.'
              : 'This action cannot be undone.',
          style: TextStyle(color: palette.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              s.isArabic
                  ? 'إلغاء'
                  : s.isKurdish
                  ? 'پاشگەزبوونەوە'
                  : 'Cancel',
              style: TextStyle(color: palette.textSecondary),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF87171),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              s.isArabic
                  ? 'حذف'
                  : s.isKurdish
                  ? 'سڕینەوە'
                  : 'Delete',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await ListingRepository().deleteListing(listing.id, user.id);
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

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'sold'
                  ? Icons.check_circle_outline_rounded
                  : Icons.inventory_2_outlined,
              size: 56,
              color: palette.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              status == 'sold'
                  ? (s.isKurdish
                        ? 'هیچ بابەتێکی فرۆشراو نییە'
                        : 'No sold listings')
                  : (s.isKurdish
                        ? 'هیچ بابەتێکی چالاک نییە'
                        : 'No active listings'),
              style: TextStyle(color: palette.textSecondary, fontSize: 13.5),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final listing = items[index];
        final price = listing.transactionType == 'free'
            ? (s.isKurdish
                  ? 'بەخۆڕایی'
                  : s.isArabic
                  ? 'مجاناً'
                  : 'Free')
            : '${listing.priceIQD} IQD';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ItemDetailsScreen(listing: listing),
              ),
            ),
            leading: SizedBox(
              width: 56,
              height: 56,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: listing.images.isEmpty
                    ? Container(
                        color: palette.surfaceHighlight,
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: palette.textSecondary,
                        ),
                      )
                    : Image.network(
                        listing.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: palette.surfaceHighlight,
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: palette.textSecondary,
                          ),
                        ),
                      ),
              ),
            ),
            title: Text(
              listing.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
                fontSize: 14.5,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                price,
                style: TextStyle(
                  color: palette.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: s.isArabic ? 'حذف' : 'Delete',
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFF87171),
                    size: 22,
                  ),
                  onPressed: () => _deleteListing(context, listing),
                ),
                status == 'sold'
                    ? Container(
                        decoration: BoxDecoration(
                          color: palette.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextButton(
                          onPressed: () async {
                            await ListingRepository().updateStatus(
                              listing.id,
                              'active',
                            );
                          },
                          child: Text(
                            s.isKurdish
                                ? 'بڵاوکردنەوە'
                                : s.isArabic
                                ? 'إعادة النشر'
                                : 'Relist',
                            style: TextStyle(
                              color: palette.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: palette.border,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextButton(
                          onPressed: () async {
                            await ListingRepository().updateStatus(
                              listing.id,
                              'sold',
                            );
                          },
                          child: Text(
                            s.isKurdish
                                ? 'فرۆشراو'
                                : s.isArabic
                                ? 'تحديد كمباع'
                                : 'Mark sold',
                            style: TextStyle(
                              color: palette.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }
}
