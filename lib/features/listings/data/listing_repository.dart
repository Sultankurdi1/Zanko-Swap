import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/listing.dart';

class ListingRepository {
  final SupabaseClient db;
  ListingRepository({SupabaseClient? client})
    : db = client ?? Supabase.instance.client;

  Stream<List<Listing>> streamListings({
    String? cityId,
    String? universityId,
    String? collegeId,
    String? departmentId,
    int? stage,
  }) {
    var stream = db
        .from('listings')
        .stream(primaryKey: ['id'])
        .eq('status', 'active');
    if (cityId?.isNotEmpty == true) {
      stream = stream.eq('cityId', cityId!);
    }
    if (universityId?.isNotEmpty == true) {
      stream = stream.eq('universityId', universityId!);
    }
    if (collegeId?.isNotEmpty == true) {
      stream = stream.eq('collegeId', collegeId!);
    }
    if (departmentId?.isNotEmpty == true) {
      stream = stream.eq('departmentId', departmentId!);
    }
    if (stage != null) stream = stream.eq('stage', stage);
    return stream
        .order('createdAt', ascending: false)
        .map((rows) => rows.map(Listing.fromMap).toList());
  }

  Future<String> createListing(Map<String, dynamic> data) async {
    final row = await db
        .from('listings')
        .insert({
          ...data,
          'status': 'active',
          'viewCount': 0,
          'favoriteCount': 0,
        })
        .select('id')
        .single();
    return '${row['id']}';
  }

  Stream<List<Listing>> streamMyListings(String sellerId) => db
      .from('listings')
      .stream(primaryKey: ['id'])
      .eq('sellerId', sellerId)
      .order('createdAt', ascending: false)
      .map((r) => r.map(Listing.fromMap).toList());

  Future<void> updateStatus(String id, String status) => db
      .from('listings')
      .update({'status': status, 'updatedAt': DateTime.now().toIso8601String()})
      .eq('id', id);

  Future<void> deleteListing(String id, String sellerId) async {
    final user = db.auth.currentUser;
    final isAdmin =
        user?.appMetadata['role'] == 'admin' ||
        user?.appMetadata['is_admin'] == true;
    if (isAdmin) {
      await db.from('listings').delete().eq('id', id);
    } else {
      await db.from('listings').delete().eq('id', id).eq('sellerId', sellerId);
    }
  }
}
