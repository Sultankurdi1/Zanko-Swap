import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/listing.dart';
import '../../../core/data/favorites_store.dart';
import '../../../core/data/kurdistan_institutions.dart';
import '../../listings/data/listing_repository.dart';
import '../../listings/presentation/item_details_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../ads/presentation/admin_ads_dashboard_screen.dart';
import '../../about/about_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<Locale> onLanguageChanged;
  final VoidCallback onOpenSettings;
  final ValueChanged<int> onNavigateToTab;

  const HomeScreen({
    super.key,
    required this.onLanguageChanged,
    required this.onOpenSettings,
    required this.onNavigateToTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final repository = ListingRepository();
  final searchController = TextEditingController();
  final scrollController = ScrollController();
  final db = Supabase.instance.client;
  final PageController _adPageController = PageController();
  late Future<List<Map<String, dynamic>>> _adsFuture;
  Timer? _adRotationTimer;
  int _adItemCount = 0;

  String search = '';
  String contentFilter = 'all';
  String selectedUniversityId = '';
  int _adPageIndex = 0;
  bool _isSearchOpen = false;
  Key _refreshKey = UniqueKey();

  List<Listing> _lastKnownListings = [];

  @override
  void initState() {
    super.initState();
    _adsFuture = _fetchAds();
    _adRotationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _adItemCount < 2 || !_adPageController.hasClients) return;
      final nextPage = (_adPageIndex + 1) % _adItemCount;
      _adPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _adRotationTimer?.cancel();
    _adPageController.dispose();
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _refreshKey = UniqueKey();
      _adsFuture = _fetchAds();
      _adPageIndex = 0;
      _adItemCount = 0;
    });
    if (_adPageController.hasClients) _adPageController.jumpToPage(0);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  List<Listing> _filterItems(List<Listing> source) {
    return source.where((x) {
      final typeMatch =
          contentFilter == 'all' ||
          (contentFilter == 'medical' && x.type == 'medical') ||
          (contentFilter == 'postgraduate' && x.type == 'postgraduate') ||
          (contentFilter == 'electronics' && x.type == 'device') ||
          (contentFilter == 'book' &&
              (x.type == 'book' || x.type == 'study_material')) ||
          (contentFilter == 'handout' && x.type == 'handout');

      final searchMatch =
          search.isEmpty ||
          x.title.toLowerCase().contains(search) ||
          x.description.toLowerCase().contains(search) ||
          x.universityName.toLowerCase().contains(search);
      final universityMatch =
          selectedUniversityId.isEmpty ||
          x.universityId == selectedUniversityId;
      return typeMatch && searchMatch && universityMatch;
    }).toList();
  }

  Future<void> _launchUrlStr(String? urlStr) async {
    if (urlStr == null || urlStr.trim().isEmpty) return;
    final clean = urlStr.trim();
    final uri = Uri.tryParse(
      clean.startsWith('http') ? clean : 'https://$clean',
    );
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAds() async {
    try {
      final res = await db
          .from('ad_campaigns')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      final List<Map<String, dynamic>> ads = List<Map<String, dynamic>>.from(
        res,
      );

      final filtered = ads.where((ad) {
        final placement = (ad['placement'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        final status = (ad['status'] ?? '').toString().trim().toLowerCase();

        final isActive = ad['is_active'] == true;
        final endDate = DateTime.tryParse(
          (ad['end_date'] ?? ad['endDate'] ?? '').toString(),
        );
        final isNotExpired = endDate == null || endDate.isAfter(DateTime.now());
        final hasHomePlacement =
            placement == 'home' ||
            placement == 'home_banner' ||
            placement == 'all' ||
            placement.isEmpty;

        return (status == 'approved' || status == 'active') &&
            isActive &&
            isNotExpired &&
            hasHomePlacement;
      }).toList();

      return filtered;
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final palette = AppThemeScope.of(context);

    return Scaffold(
      backgroundColor: palette.bg,
      drawer: _EmeraldDrawer(
        palette: palette,
        onLanguageChanged: widget.onLanguageChanged,
        onOpenSettings: widget.onOpenSettings,
        onNavigateToTab: widget.onNavigateToTab,
      ),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: palette.bg,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu_rounded, color: palette.textSecondary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: _isSearchOpen
            ? Container(
                height: 38,
                decoration: BoxDecoration(
                  color: palette.surfaceHighlight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: palette.border),
                ),
                child: TextField(
                  controller: searchController,
                  autofocus: true,
                  style: TextStyle(color: palette.textPrimary, fontSize: 13),
                  onChanged: (v) =>
                      setState(() => search = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: _homeText(s, 'گەڕان...', 'بحث...', 'Search...'),
                    hintStyle: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 12,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: palette.textSecondary,
                      size: 18,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ZankoSwap',
                    style: TextStyle(
                      color: palette.accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 21,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    s.isKurdish
                        ? 'کڕین، فرۆشتن و ئاڵوگۆڕ لەگەڵ خوێندکاران'
                        : 'Buy, Sell & Swap with Students',
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _isSearchOpen
                    ? palette.primary
                    : palette.surfaceHighlight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.border),
              ),
              child: Icon(
                _isSearchOpen ? Icons.close_rounded : Icons.search_rounded,
                color: _isSearchOpen ? Colors.white : palette.textSecondary,
                size: 20,
              ),
            ),
            onPressed: () {
              setState(() {
                _isSearchOpen = !_isSearchOpen;
                if (!_isSearchOpen) {
                  searchController.clear();
                  search = '';
                }
              });
            },
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: palette.surfaceHighlight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.border),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                color: palette.textSecondary,
                size: 20,
              ),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: palette.primary,
        backgroundColor: palette.surfaceHighlight,
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          key: _refreshKey,
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _adsFuture,
                builder: (context, snap) {
                  final dbAds = snap.data ?? [];
                  final List<Map<String, String>> bannerItems = dbAds.isNotEmpty
                      ? dbAds
                            .map(
                              (a) => {
                                'title': '${a['title'] ?? ''}',
                                'image':
                                    '${a['imageUrl'] ?? a['image_url'] ?? a['image'] ?? ''}',
                                'tag':
                                    '${a['advertiser'] ?? _homeText(s, 'سپۆنسەر', 'إعلان ممول', 'Sponsored')}',
                                'url':
                                    '${a['targetUrl'] ?? a['target_url'] ?? a['url'] ?? ''}',
                              },
                            )
                            .toList()
                      : [
                          {
                            'title': s.isKurdish
                                ? 'گەورەترین بازاڕی خوێندکارانی زانکۆ لە کوردستان'
                                : 'The Leading Academic Marketplace in Kurdistan',
                            'image':
                                'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=800&auto=format&fit=crop&q=80',
                            'tag': 'ZankoSwap',
                            'url': '',
                          },
                        ];
                  _adItemCount = bannerItems.length;
                  if (_adPageIndex >= _adItemCount) _adPageIndex = 0;

                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    height: 115,
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _adPageController,
                          itemCount: bannerItems.length,
                          onPageChanged: (i) {
                            _adItemCount = bannerItems.length;
                            if (_adPageIndex != i) {
                              setState(() => _adPageIndex = i);
                            }
                          },
                          itemBuilder: (context, i) {
                            final item = bannerItems[i];
                            return GestureDetector(
                              onTap: () => _launchUrlStr(item['url']),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (item['image']!.isNotEmpty)
                                      Image.network(
                                        item['image']!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: palette.surfaceHighlight,
                                        ),
                                      )
                                    else
                                      Container(
                                        color: palette.surfaceHighlight,
                                      ),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            palette.bg.withValues(alpha: 0.9),
                                            Colors.transparent,
                                          ],
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 10,
                                      left: 12,
                                      right: 12,
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: palette.buttonGradient,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item['tag']!,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              item['title']!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: palette.textPrimary,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        if (bannerItems.length > 1)
                          Positioned(
                            bottom: 8,
                            right: 12,
                            child: Row(
                              children: List.generate(
                                bannerItems.length,
                                (idx) => Container(
                                  margin: const EdgeInsets.only(left: 3),
                                  width: _adPageIndex == idx ? 8 : 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: _adPageIndex == idx
                                        ? palette.accent
                                        : Colors.white24,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.isKurdish
                          ? 'بەشەکان و خزمەتگوزارییەکان'
                          : 'Categories & Services',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: palette.textPrimary,
                      ),
                    ),
                    if (contentFilter != 'all')
                      GestureDetector(
                        onTap: () => setState(() => contentFilter = 'all'),
                        child: Text(
                          _homeText(s, 'هەمووی', 'الكل', 'All'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: palette.accent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _UnifiedImageCategoryCard(
                      palette: palette,
                      title: _homeText(s, 'پزیشکی', 'طبي', 'Medical'),
                      imageUrl:
                          'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=400&auto=format&fit=crop&q=60',
                      isSelected: contentFilter == 'medical',
                      onTap: () => setState(
                        () => contentFilter = contentFilter == 'medical'
                            ? 'all'
                            : 'medical',
                      ),
                    ),
                    _UnifiedImageCategoryCard(
                      palette: palette,
                      title: _homeText(s, 'کتێب', 'كتب', 'Books'),
                      imageUrl:
                          'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=400&auto=format&fit=crop&q=60',
                      isSelected: contentFilter == 'book',
                      onTap: () => setState(
                        () => contentFilter = contentFilter == 'book'
                            ? 'all'
                            : 'book',
                      ),
                    ),
                    _UnifiedImageCategoryCard(
                      palette: palette,
                      title: _homeText(
                        s,
                        'ملزەمە',
                        'ملازم ومواد دراسية',
                        'Handouts',
                      ),
                      imageUrl:
                          'https://images.unsplash.com/photo-1506784983877-45594efa4cbe?w=400&auto=format&fit=crop&q=60',
                      isSelected: contentFilter == 'handout',
                      onTap: () => setState(
                        () => contentFilter = contentFilter == 'handout'
                            ? 'all'
                            : 'handout',
                      ),
                    ),
                    _UnifiedImageCategoryCard(
                      palette: palette,
                      title: _homeText(
                        s,
                        'خوێندنی باڵا',
                        'دراسات عليا',
                        'Postgrad',
                      ),
                      imageUrl:
                          'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=800&auto=format&fit=crop&q=80',
                      isSelected: contentFilter == 'postgraduate',
                      onTap: () => setState(
                        () => contentFilter = contentFilter == 'postgraduate'
                            ? 'all'
                            : 'postgraduate',
                      ),
                    ),
                    _UnifiedImageCategoryCard(
                      palette: palette,
                      title: _homeText(
                        s,
                        'ئەلیکترۆنیات',
                        'أجهزة إلكترونية',
                        'Devices',
                      ),
                      imageUrl:
                          'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=400&auto=format&fit=crop&q=60',
                      isSelected: contentFilter == 'electronics',
                      onTap: () => setState(
                        () => contentFilter = contentFilter == 'electronics'
                            ? 'all'
                            : 'electronics',
                      ),
                    ),
                    _UnifiedImageCategoryCard(
                      palette: palette,
                      title: _homeText(
                        s,
                        'چێشتخانەکان',
                        'مطاعم',
                        'Restaurants',
                      ),
                      imageUrl:
                          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400&auto=format&fit=crop&q=60',
                      onTap: () => Navigator.pushNamed(context, '/restaurants'),
                    ),
                    _UnifiedImageCategoryCard(
                      palette: palette,
                      title: _homeText(s, 'کافێیەکان', 'مقاهٍ', 'Cafes'),
                      imageUrl:
                          'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=400&auto=format&fit=crop&q=60',
                      onTap: () => Navigator.pushNamed(context, '/cafes'),
                    ),
                    _UnifiedImageCategoryCard(
                      palette: palette,
                      title: _homeText(s, 'خول و کۆرس', 'دورات', 'Courses'),
                      imageUrl:
                          'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=400&auto=format&fit=crop&q=60',
                      onTap: () => Navigator.pushNamed(context, '/courses'),
                    ),
                    _UnifiedImageCategoryCard(
                      palette: palette,
                      title: _homeText(
                        s,
                        'فۆتۆکۆپی',
                        'قرطاسية ونسخ',
                        'Stationery',
                      ),
                      imageUrl:
                          'https://images.unsplash.com/photo-1589829085413-56de8ae18c73?w=400&auto=format&fit=crop&q=60',
                      onTap: () => Navigator.pushNamed(context, '/stationery'),
                    ),
                    _UnifiedImageCategoryCard(
                      palette: palette,
                      title: _homeText(s, 'توێژینەوە', 'أبحاث', 'Research'),
                      imageUrl:
                          'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=400&auto=format&fit=crop&q=60',
                      onTap: () => Navigator.pushNamed(context, '/research'),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: DropdownButtonFormField<String>(
                  initialValue: selectedUniversityId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: _homeText(
                      s,
                      'فلتەر بە زانکۆ یان پەیمانگا',
                      'تصفية حسب الجامعة أو المعهد',
                      'Filter by university or institute',
                    ),
                    prefixIcon: const Icon(Icons.account_balance_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: '',
                      child: Text(
                        _homeText(
                          s,
                          'هەموو زانکۆکان',
                          'جميع الجامعات',
                          'All universities',
                        ),
                      ),
                    ),
                    ...kurdistanInstitutions.map(
                      (x) => DropdownMenuItem(
                        value: x.id,
                        child: Text(
                          x.name(s.isKurdish),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => selectedUniversityId = value ?? ''),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('🔥 ', style: TextStyle(fontSize: 14)),
                        Text(
                          contentFilter == 'all'
                              ? (s.isKurdish
                                    ? 'بابەتە باوەکان'
                                    : 'Popular Listings')
                              : _homeText(
                                  s,
                                  'ئەنجامەکان',
                                  'النتائج',
                                  'Filtered Items',
                                ),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: palette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (contentFilter != 'all')
                      GestureDetector(
                        onTap: () => setState(() => contentFilter = 'all'),
                        child: Text(
                          _homeText(s, 'هەمووی ببینە', 'عرض الكل', 'See all'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: palette.accent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            StreamBuilder<List<Listing>>(
              stream: repository.streamListings(),
              builder: (context, snapshot) {
                if (snapshot.hasData &&
                    snapshot.data != null &&
                    snapshot.data!.isNotEmpty) {
                  _lastKnownListings = snapshot.data!;
                }

                final currentData = (snapshot.hasData && snapshot.data != null)
                    ? snapshot.data!
                    : _lastKnownListings;

                if (snapshot.connectionState == ConnectionState.waiting &&
                    _lastKnownListings.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: palette.primary),
                    ),
                  );
                }

                final items = _filterItems(currentData);

                if (items.isEmpty && _lastKnownListings.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        s.isKurdish
                            ? 'هیچ بابەتێک نەدۆزرایەوە'
                            : 'No listings found',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.68,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _EmeraldFeedCard(
                        listing: items[index],
                        palette: palette,
                      ),
                      childCount: items.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _UnifiedImageCategoryCard extends StatelessWidget {
  final AppPalette palette;
  final String title;
  final String imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const _UnifiedImageCategoryCard({
    required this.palette,
    required this.title,
    required this.imageUrl,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 86,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: palette.primary, width: 2)
              : Border.all(color: palette.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: palette.isDark ? 0.2 : 0.06,
              ),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: palette.surfaceHighlight),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Positioned(
                bottom: 6,
                left: 4,
                right: 4,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmeraldFeedCard extends StatelessWidget {
  final Listing listing;
  final AppPalette palette;
  const _EmeraldFeedCard({required this.listing, required this.palette});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final price = listing.transactionType == 'free'
        ? _homeText(s, 'بەخۆڕایی', 'مجاناً', 'Free')
        : listing.transactionType == 'exchange'
        ? _homeText(s, 'گۆڕینەوە', 'مبادلة', 'Exchange')
        : '${listing.priceIQD} IQD';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ItemDetailsScreen(listing: listing)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: listing.images.isEmpty
                        ? Container(
                            color: palette.surfaceHighlight,
                            child: Icon(
                              Icons.inventory_2_outlined,
                              size: 22,
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
                                size: 20,
                                color: palette.textSecondary,
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: CircleAvatar(
                      radius: 11,
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                      child: AnimatedBuilder(
                        animation: FavoritesStore.instance,
                        builder: (_, __) {
                          final saved = FavoritesStore.instance.containsListing(
                            listing.id,
                          );
                          return IconButton(
                            padding: EdgeInsets.zero,
                            iconSize: 13,
                            onPressed: () => FavoritesStore.instance
                                .toggleListing(listing.id),
                            icon: Icon(
                              saved
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: saved
                                  ? const Color(0xFFF87171)
                                  : Colors.white70,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 5, 6, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    price,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      color: palette.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmeraldDrawer extends StatelessWidget {
  final AppPalette palette;
  final ValueChanged<Locale> onLanguageChanged;
  final VoidCallback onOpenSettings;
  final ValueChanged<int> onNavigateToTab;

  const _EmeraldDrawer({
    required this.palette,
    required this.onLanguageChanged,
    required this.onOpenSettings,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final currentUserEmail = Supabase.instance.client.auth.currentUser?.email
        ?.toLowerCase()
        .trim();

    return Drawer(
      backgroundColor: palette.bg,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: palette.surfaceHighlight,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: palette.primary,
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ZankoSwap',
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        s.studentHome,
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 6),
                children: [
                  _drawerItem(
                    Icons.campaign_rounded,
                    s.promoteBusiness,
                    () => Navigator.pushNamed(context, '/advertise'),
                  ),
                  if (currentUserEmail == 'tahasulaiman135@gmail.com')
                    _drawerItem(
                      Icons.admin_panel_settings_rounded,
                      _homeText(
                        s,
                        'بەڕێوەبردنی ڕیکلامەکان',
                        'لوحة الإعلانات',
                        'Ads Dashboard',
                      ),
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminAdsDashboardScreen(),
                          ),
                        );
                      },
                    ),
                  Divider(color: palette.border),
                  _drawerItem(Icons.settings_rounded, s.settings, () {
                    Navigator.pop(context);
                    onOpenSettings();
                  }),
                  _drawerItem(
                    Icons.contact_support_outlined,
                    s.contactUs,
                    () => Navigator.pushNamed(context, '/contact'),
                  ),
                  _drawerItem(Icons.info_outline_rounded, s.about, () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const AboutScreen(),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'ZankoSwap v1.2.0',
                style: TextStyle(color: palette.textSecondary, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) =>
      ListTile(
        dense: true,
        leading: Icon(icon, color: palette.accent, size: 20),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: palette.textSecondary,
        ),
        onTap: onTap,
      );
}

String _homeText(
  AppStrings strings,
  String kurdish,
  String arabic,
  String english,
) => strings.isKurdish
    ? kurdish
    : strings.isArabic
    ? arabic
    : english;
