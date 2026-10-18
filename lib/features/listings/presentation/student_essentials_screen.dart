import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/models/listing.dart';
import '../data/listing_repository.dart';
import 'add_listing_screen.dart';
import 'item_details_screen.dart';

class StudentEssentialsScreen extends StatefulWidget {
  const StudentEssentialsScreen({super.key});

  @override
  State<StudentEssentialsScreen> createState() =>
      _StudentEssentialsScreenState();
}

class _StudentEssentialsScreenState extends State<StudentEssentialsScreen> {
  final repository = ListingRepository();
  final searchController = TextEditingController();
  String search = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isKurdish = s.isKurdish;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isKurdish
              ? 'پێداویستی و ئامێرەکان'
              : s.isArabic
              ? 'مستلزمات الطالب'
              : 'Student Essentials',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 135,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1519389950473-47ba0277781c?auto=format&fit=crop&w=1200&q=80',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.78),
                    Colors.black.withValues(alpha: 0.25),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              padding: const EdgeInsets.all(16),
              alignment: Alignment.bottomRight,
              child: Text(
                isKurdish
                    ? 'ئامێر، لاپتۆپ و پێداویستییەکانی خوێندن'
                    : 'Laptops, Devices & Tools',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: searchController,
              onChanged: (v) => setState(() => search = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: isKurdish
                    ? 'گەڕان بۆ لاپتۆپ، ئایپاد، حاسیبە...'
                    : 'Search devices...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: search.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          searchController.clear();
                          setState(() => search = '');
                        },
                      ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Listing>>(
              stream: repository.streamListings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final items = (snapshot.data ?? []).where((x) {
                  final isDevice = x.type == 'device';
                  final matchesSearch =
                      search.isEmpty ||
                      x.title.toLowerCase().contains(search) ||
                      x.description.toLowerCase().contains(search);
                  return isDevice && matchesSearch;
                }).toList();

                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      isKurdish
                          ? 'هیچ ئامێر یان پێداویستییەک نەدۆزرایەوە'
                          : 'No devices found',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.74,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final priceText = item.transactionType == 'free'
                        ? (isKurdish
                              ? 'خۆڕایی'
                              : s.isArabic
                              ? 'مجاناً'
                              : 'Free')
                        : item.transactionType == 'exchange'
                        ? (isKurdish
                              ? 'ئاڵوگۆڕ'
                              : s.isArabic
                              ? 'مبادلة'
                              : 'Exchange')
                        : '${item.priceIQD} IQD';

                    return Card(
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ItemDetailsScreen(listing: item),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Flexible(
                              flex: 3,
                              child: item.images.isNotEmpty
                                  ? Image.network(
                                      item.images.first,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.black12,
                                        child: const Center(
                                          child: Icon(
                                            Icons.devices_other_rounded,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.black12,
                                      child: const Center(
                                        child: Icon(
                                          Icons.devices_other_rounded,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                            ),
                            Flexible(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      priceText,
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AddListingScreen(initialType: 'device'),
          ),
        ),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          isKurdish
              ? 'زیادکردنی ئامێر'
              : s.isArabic
              ? 'إضافة جهاز'
              : 'Add Device',
        ),
      ),
    );
  }
}
