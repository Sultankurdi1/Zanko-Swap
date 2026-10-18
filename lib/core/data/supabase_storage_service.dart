import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const url = 'https://sbjkeyhihfypoieexfga.supabase.co';
  static const publishableKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNiamtleWhpaGZ5cG9pZWV4ZmdhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk4ODUwODcsImV4cCI6MjEwNTQ2MTA4N30.grSaOxsePJh5Cu8TGzfO9cI20c4yI1CFmvoUekdAMQw';

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}

class SupabaseStorageService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<String> uploadListingImage({
    required String ownerId,
    required File file,
    required String fileName,
  }) async {
    final path = '$ownerId/$fileName';
    await client.storage
        .from('listing-images')
        .upload(
          path,
          file,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );
    return client.storage.from('listing-images').getPublicUrl(path);
  }

  static Future<String> uploadProfileImage({
    required String userId,
    required File file,
  }) async {
    final isPng = file.path.toLowerCase().endsWith('.png');
    final path = '$userId/profile.${isPng ? 'png' : 'jpg'}';
    await client.storage
        .from('profile-images')
        .upload(
          path,
          file,
          fileOptions: FileOptions(
            upsert: true,
            contentType: isPng ? 'image/png' : 'image/jpeg',
          ),
        );
    return client.storage.from('profile-images').getPublicUrl(path);
  }

  static Future<String> uploadServiceImage({
    required String ownerId,
    required File file,
  }) async {
    final ext = file.path.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
    final path = '$ownerId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await client.storage
        .from('service-images')
        .upload(
          path,
          file,
          fileOptions: FileOptions(
            upsert: true,
            contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
          ),
        );
    return client.storage.from('service-images').getPublicUrl(path);
  }
}
