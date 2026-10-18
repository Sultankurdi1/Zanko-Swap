import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPermissions {
  AuthPermissions({SupabaseClient? client})
    : db = client ?? Supabase.instance.client;
  final SupabaseClient db;

  User? get currentUser => db.auth.currentUser;
  bool get isSignedIn => currentUser != null;

  bool owns(String? ownerId) =>
      isSignedIn && ownerId != null && ownerId == currentUser!.id;

  bool get isAdmin {
    final metadata = currentUser?.appMetadata ?? const <String, dynamic>{};
    final userMetadata = currentUser?.userMetadata ?? const <String, dynamic>{};
    return metadata['role'] == 'admin' ||
        metadata['is_admin'] == true ||
        userMetadata['role'] == 'admin' ||
        userMetadata['is_admin'] == true;
  }

  bool canManage(String? ownerId) => owns(ownerId) || isAdmin;
}
