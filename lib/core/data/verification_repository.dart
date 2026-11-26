import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// One verification request (student ID photo checked by the admin).
class VerificationRequest {
  final int id;
  final String userId;
  final String imagePath;
  final String status; // pending, approved, rejected
  final DateTime? createdAt;

  const VerificationRequest({
    required this.id,
    required this.userId,
    required this.imagePath,
    required this.status,
    this.createdAt,
  });

  factory VerificationRequest.fromMap(Map<String, dynamic> m) =>
      VerificationRequest(
        id: (m['id'] as num).toInt(),
        userId: '${m['user_id'] ?? ''}',
        imagePath: '${m['image_path'] ?? ''}',
        status: '${m['status'] ?? 'pending'}',
        createdAt: DateTime.tryParse('${m['created_at'] ?? ''}'),
      );
}

/// Verified students: request, check, and (for the admin) review.
class VerificationRepository {
  VerificationRepository({SupabaseClient? client})
    : db = client ?? Supabase.instance.client;
  final SupabaseClient db;

  static const bucket = 'student-ids';
  static final Map<String, bool> _cache = {};

  /// Whether a user has the verified badge (cached for this session).
  Future<bool> isVerified(String userId) async {
    if (userId.isEmpty) return false;
    final cached = _cache[userId];
    if (cached != null) return cached;
    try {
      final value = await db.rpc('is_user_verified', params: {'uid': userId});
      return _cache[userId] = value == true;
    } catch (_) {
      return false;
    }
  }

  /// The signed-in user's newest request, or null if they never asked.
  Future<VerificationRequest?> myLatestRequest() async {
    final me = db.auth.currentUser?.id;
    if (me == null) return null;
    final row = await db
        .from('verification_requests')
        .select()
        .eq('user_id', me)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : VerificationRequest.fromMap(row);
  }

  /// Uploads the student ID photo privately and creates a pending request.
  Future<void> submit(XFile photo) async {
    final me = db.auth.currentUser?.id;
    if (me == null) throw StateError('not signed in');
    final bytes = await photo.readAsBytes();
    final kind = _imageKind(bytes);
    if (kind == null) throw StateError('invalid_mime_type');
    final path = '$me/${DateTime.now().millisecondsSinceEpoch}.${kind.$1}';
    await db.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: kind.$2),
        );
    try {
      await db.from('verification_requests').insert({'image_path': path});
    } catch (_) {
      await db.storage
          .from(bucket)
          .remove([path])
          .catchError((_) => <FileObject>[]);
      rethrow;
    }
  }

  /// Withdraws a pending request and deletes its photo.
  Future<void> cancel(VerificationRequest request) async {
    if (request.imagePath.isNotEmpty) {
      await db.storage.from(bucket).remove([request.imagePath]);
    }
    await db.from('verification_requests').delete().eq('id', request.id);
  }

  // ---- Admin ----

  Future<List<VerificationRequest>> pending() async {
    final rows = await db
        .from('verification_requests')
        .select()
        .eq('status', 'pending')
        .order('created_at');
    return rows.map(VerificationRequest.fromMap).toList();
  }

  /// A link to the private photo that works for 10 minutes.
  Future<String> photoUrl(String path) =>
      db.storage.from(bucket).createSignedUrl(path, 600);

  /// Approves or rejects, then deletes the student ID photo for privacy.
  Future<void> review(
    VerificationRequest request, {
    required bool approve,
  }) async {
    final path = await db.rpc(
      'review_verification',
      params: {'request_id': request.id, 'approve': approve},
    );
    _cache.remove(request.userId);
    final toDelete = '${path ?? ''}';
    if (toDelete.isNotEmpty) {
      await db.storage.from(bucket).remove([toDelete]);
    }
  }

  static (String, String)? _imageKind(Uint8List b) {
    if (b.length > 3 && b[0] == 0xff && b[1] == 0xd8 && b[2] == 0xff) {
      return ('jpg', 'image/jpeg');
    }
    if (b.length > 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4e) {
      return ('png', 'image/png');
    }
    if (b.length > 12 &&
        String.fromCharCodes(b.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(b.sublist(8, 12)) == 'WEBP') {
      return ('webp', 'image/webp');
    }
    return null;
  }
}
