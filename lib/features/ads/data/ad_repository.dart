import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/ad_campaign.dart';

class AdRepository {
  final _client = Supabase.instance.client;

  Future<void> submit(AdCampaign campaign) async {
    await _client.from('ad_campaigns').insert(campaign.toMap());
  }

  Future<List<AdCampaign>> fetchAdsByPlacement(String placement) async {
    try {
      final res = await _client
          .from('ad_campaigns')
          .select()
          .eq('placement', placement)
          .filter('status', 'in', '("approved","active")')
          .order('created_at', ascending: false);

      return (res as List).map((map) => AdCampaign.fromMap(map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<AdCampaign>> fetchActiveHomeAds() async {
    try {
      final res = await _client
          .from('ad_campaigns')
          .select()
          .filter('status', 'in', '("approved","active")')
          .order('created_at', ascending: false);

      return (res as List).map((map) => AdCampaign.fromMap(map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> logClick(String adId) async {
    try {
      await _client.rpc('increment_ad_click', params: {'ad_id': adId});
    } catch (_) {}
  }
}
