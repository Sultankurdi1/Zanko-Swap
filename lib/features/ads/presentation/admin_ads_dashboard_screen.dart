import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/ad_campaign.dart';

class AdminAdsDashboardScreen extends StatefulWidget {
  const AdminAdsDashboardScreen({super.key});

  @override
  State<AdminAdsDashboardScreen> createState() =>
      _AdminAdsDashboardScreenState();
}

class _AdminAdsDashboardScreenState extends State<AdminAdsDashboardScreen> {
  final _client = Supabase.instance.client;
  bool _isLoading = true;
  List<AdCampaign> _ads = [];

  @override
  void initState() {
    super.initState();
    _fetchAds();
  }

  Future<void> _fetchAds() async {
    setState(() => _isLoading = true);
    try {
      final res = await _client
          .from('ad_campaigns')
          .select()
          .order('created_at', ascending: false);

      final list = (res as List).map((map) => AdCampaign.fromMap(map)).toList();
      if (!mounted) return;
      setState(() {
        _ads = list;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('هەڵە لە بارکردنی ڕیکلامەکان: $e')),
        );
      }
    }
  }

  Future<void> _toggleAdStatus(AdCampaign ad) async {
    final nextActive = !ad.isActive;
    try {
      final updateData = <String, dynamic>{
        'is_active': nextActive,
        'status': nextActive ? 'approved' : 'paused',
      };

      if (nextActive && ad.endDate.isBefore(DateTime.now())) {
        updateData['end_date'] = DateTime.now()
            .add(Duration(days: ad.days > 0 ? ad.days : 30))
            .toIso8601String();
      }

      await _client.from('ad_campaigns').update(updateData).eq('id', ad.id);
      await _fetchAds();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('کردارەکە سەرکەوتوو نەبوو: $e')));
      }
    }
  }

  Future<void> _deleteAd(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('سڕینەوەی ڕیکلام'),
        content: const Text('ئایا دڵنیایت لە سڕینەوەی ئەم کەمپەینە؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('پاشگەزبوونەوە'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('بیسڕەوە'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _client.from('ad_campaigns').delete().eq('id', id);
        await _fetchAds();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('سڕینەوە سەرکەوتوو نەبوو: $e')),
          );
        }
      }
    }
  }

  void _showSingleAdStats(AdCampaign ad) {
    final ctr = ad.viewsCount > 0
        ? ((ad.clicksCount / ad.viewsCount) * 100).toStringAsFixed(1)
        : '0.0';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('ئاماری ڕیکلام: ${ad.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ڕیکلامکار: ${ad.advertiser}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.visibility_rounded,
                          color: Colors.green,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${ad.viewsCount}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.green,
                          ),
                        ),
                        const Text(
                          'بینەر',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blueAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.touch_app_rounded,
                          color: Colors.blueAccent,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${ad.clicksCount}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const Text(
                          'کلیک',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'ڕێژەی کارلێک (CTR): %$ctr',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'شوێنی نیشاندان: ${ad.placement}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('داخستن'),
          ),
        ],
      ),
    );
  }

  void _showReceiptDialog(AdCampaign ad) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('پسوولەی: ${ad.advertiser}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'بڕی بودجە: ${ad.budgetIQD} IQD',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'زانیاری پسوولە / بەستەر:\n${ad.receiptUrl.isEmpty ? 'هیچ پسوولەیەک دانەنراوە' : ad.receiptUrl}',
            ),
            if (ad.receiptUrl.startsWith('http://') ||
                ad.receiptUrl.startsWith('https://')) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  ad.receiptUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Text('وێنەکە بارنەکرا.'),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('داخستن'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'بەڕێوەبردنی ڕیکلامەکان',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchAds,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAds,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'کەمپەینە چالاک و تۆمارکراوەکان',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_ads.length} ڕیکلام',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_ads.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: Text('هیچ ڕیکلامێک بەردەست نییە.')),
                    ),
                  ..._ads.map(
                    (ad) => _AdItemCard(
                      ad: ad,
                      onToggle: () => _toggleAdStatus(ad),
                      onDelete: () => _deleteAd(ad.id),
                      onViewReceipt: () => _showReceiptDialog(ad),
                      onTapDetails: () => _showSingleAdStats(ad),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _AdItemCard extends StatelessWidget {
  final AdCampaign ad;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onViewReceipt;
  final VoidCallback onTapDetails;

  const _AdItemCard({
    required this.ad,
    required this.onToggle,
    required this.onDelete,
    required this.onViewReceipt,
    required this.onTapDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = ad.endDate.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTapDetails,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ad.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ڕیکلامکار: ${ad.advertiser}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isExpired
                          ? Colors.red.withValues(alpha: 0.15)
                          : (ad.isActive
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.orange.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isExpired
                          ? 'بەسەرچووە'
                          : (ad.isActive ? 'چالاکە' : 'وەستێنراوە'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isExpired
                            ? Colors.red
                            : (ad.isActive ? Colors.green : Colors.orange),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.visibility_rounded,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${ad.viewsCount} بینین',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.touch_app_rounded,
                      size: 16,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${ad.clicksCount} کلیک',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'شوێن: ${ad.placement}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.receipt_rounded, size: 16),
                    label: const Text('پسوولە', style: TextStyle(fontSize: 12)),
                    onPressed: onViewReceipt,
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          ad.isActive
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                          color: ad.isActive ? Colors.orange : Colors.green,
                        ),
                        tooltip: ad.isActive ? 'ڕاگرتن' : 'چالاککردنەوە',
                        onPressed: onToggle,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                        ),
                        tooltip: 'سڕینەوە',
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
