import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<String> _moderatedUpload(String bucket, File file) async {
    final response = await client.functions.invoke(
      'moderate-upload',
      queryParameters: {'bucket': bucket},
      files: [await http.MultipartFile.fromPath('file', file.path)],
    );
    final data = response.data;
    final url = data is Map ? data['url']?.toString() : null;
    if (url == null || url.isEmpty) {
      throw StateError('upload_failed');
    }
    return url;
  }

  static Future<String> uploadListingImage({
    required String ownerId,
    required File file,
    required String fileName,
  }) => _moderatedUpload('listing-images', file);

  static Future<String> uploadProfileImage({
    required String userId,
    required File file,
  }) => _moderatedUpload('profile-images', file);

  static Future<String> uploadServiceImage({
    required String ownerId,
    required File file,
  }) => _moderatedUpload('service-images', file);

  static const receiptBucket = 'ad-receipts';

  static Future<String> uploadReceipt({
    required String ownerId,
    required File file,
  }) async {
    final path =
        '$ownerId/receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await client.storage
        .from(receiptBucket)
        .upload(
          path,
          file,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
    return '$receiptBucket/$path';
  }

  static Future<String?> receiptViewUrl(String stored) async {
    if (stored.startsWith('http://') || stored.startsWith('https://')) {
      return stored;
    }
    if (!stored.startsWith('$receiptBucket/')) return null;
    try {
      return await client.storage
          .from(receiptBucket)
          .createSignedUrl(stored.substring(receiptBucket.length + 1), 600);
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteAllUserFiles(String userId) async {
    const buckets = [
      'listing-images',
      'profile-images',
      'service-images',
      receiptBucket,
    ];
    for (final bucket in buckets) {
      try {
        final files = await client.storage
            .from(bucket)
            .list(
              path: userId,
              searchOptions: const SearchOptions(limit: 1000),
            );
        final paths = files.map((f) => '$userId/${f.name}').toList();
        if (paths.isNotEmpty) {
          await client.storage.from(bucket).remove(paths);
        }
      } catch (_) {}
    }
  }
}
