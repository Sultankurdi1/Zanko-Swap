import 'package:supabase_flutter/supabase_flutter.dart';

class RatingSummary {
  final double average;
  final int total;
  const RatingSummary(this.average, this.total);
  static const empty = RatingSummary(0, 0);
}

class RatingRepository {
  RatingRepository({SupabaseClient? client})
    : db = client ?? Supabase.instance.client;
  final SupabaseClient db;

  Future<RatingSummary> summary(String sellerId) async {
    if (sellerId.isEmpty) return RatingSummary.empty;
    try {
      final rows = await db.rpc(
        'seller_rating_summary',
        params: {'seller': sellerId},
      );
      final row = rows is List && rows.isNotEmpty ? rows.first : null;
      if (row is! Map) return RatingSummary.empty;
      final total = (row['total'] as num?)?.toInt() ?? 0;
      final average = (row['average'] as num?)?.toDouble() ?? 0;
      return RatingSummary(average, total);
    } catch (_) {
      return RatingSummary.empty;
    }
  }

  Future<int?> myRating(String sellerId) async {
    final me = db.auth.currentUser?.id;
    if (me == null || sellerId.isEmpty) return null;
    try {
      final row = await db
          .from('seller_ratings')
          .select('stars')
          .eq('rater_id', me)
          .eq('seller_id', sellerId)
          .maybeSingle();
      return (row?['stars'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  Future<void> rate(String sellerId, int stars) async {
    final me = db.auth.currentUser?.id;
    if (me == null) throw StateError('not signed in');
    await db.from('seller_ratings').upsert({
      'rater_id': me,
      'seller_id': sellerId,
      'stars': stars.clamp(1, 5),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'rater_id,seller_id');
  }
}
