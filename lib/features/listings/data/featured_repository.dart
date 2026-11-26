import 'package:supabase_flutter/supabase_flutter.dart';

/// A request to show a listing first on the home screen (paid).
class FeaturedRequest {
  final int id;
  final String userId;
  final String listingId;
  final int days;
  final int priceIqd;
  final String receipt; // "ad-receipts/<path>" or a transaction code
  final String status; // pending, approved, rejected
  final DateTime? createdAt;

  const FeaturedRequest({
    required this.id,
    required this.userId,
    required this.listingId,
    required this.days,
    required this.priceIqd,
    required this.receipt,
    required this.status,
    this.createdAt,
  });

  factory FeaturedRequest.fromMap(Map<String, dynamic> m) => FeaturedRequest(
    id: (m['id'] as num).toInt(),
    userId: '${m['user_id'] ?? ''}',
    listingId: '${m['listing_id'] ?? ''}',
    days: (m['days'] as num?)?.toInt() ?? 7,
    priceIqd: (m['price_iqd'] as num?)?.toInt() ?? 0,
    receipt: '${m['receipt'] ?? ''}',
    status: '${m['status'] ?? 'pending'}',
    createdAt: DateTime.tryParse('${m['created_at'] ?? ''}'),
  );
}

class FeaturedRepository {
  FeaturedRepository({SupabaseClient? client})
    : db = client ?? Supabase.instance.client;
  final SupabaseClient db;

  /// The newest request for one of my listings, or null.
  Future<FeaturedRequest?> latestFor(String listingId) async {
    final row = await db
        .from('featured_requests')
        .select()
        .eq('listing_id', listingId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : FeaturedRequest.fromMap(row);
  }

  Future<void> submit({
    required String listingId,
    required int days,
    required String receipt,
  }) async {
    await db.from('featured_requests').insert({
      'listing_id': listingId,
      'days': days,
      'receipt': receipt,
    });
  }

  Future<void> cancel(FeaturedRequest request) =>
      db.from('featured_requests').delete().eq('id', request.id);

  // ---- Admin ----

  Future<List<FeaturedRequest>> pending() async {
    final rows = await db
        .from('featured_requests')
        .select()
        .eq('status', 'pending')
        .order('created_at');
    return rows.map(FeaturedRequest.fromMap).toList();
  }

  Future<void> review(FeaturedRequest request, {required bool approve}) =>
      db.rpc(
        'review_featured',
        params: {'request_id': request.id, 'approve': approve},
      );
}
