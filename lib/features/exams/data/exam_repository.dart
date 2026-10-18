import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/exam_paper.dart';

class ExamRepository {
  ExamRepository({SupabaseClient? client})
    : db = client ?? Supabase.instance.client;
  final SupabaseClient db;

  Future<String> add(Map<String, dynamic> data) async {
    try {
      final payload = Map<String, dynamic>.from(data)
        ..removeWhere((_, value) => value == null);

      final res = await db.from('exam_papers').insert(payload).select('id');
      final rows = res as List<dynamic>;
      if (rows.isEmpty) {
        throw Exception('هیچ داتایەک نەگەڕایەوە لە کاتی زیادکردندا');
      }
      final firstRow = rows.first as Map<String, dynamic>;
      return '${firstRow['id']}';
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<ExamPaper>> stream({
    String? track,
    String? year,
    String? subject,
  }) {
    var query = db.from('exam_papers').stream(primaryKey: ['id']);
    final normalizedTrack = track?.trim().toLowerCase();
    if (normalizedTrack == 'scientific' || normalizedTrack == 'literary') {
      query = query.eq('track', normalizedTrack!);
    }
    final normalizedYear = year?.trim();
    if (normalizedYear != null && normalizedYear.isNotEmpty) {
      query = query.eq('year', normalizedYear);
    }
    return query.order('createdAt', ascending: false).map((rows) {
      final filtered = subject == null || subject.trim().isEmpty
          ? rows
          : rows
                .where(
                  (row) => '${row['subject'] ?? ''}'.toLowerCase().contains(
                    subject.trim().toLowerCase(),
                  ),
                )
                .toList();
      return filtered.map(ExamPaper.fromMap).toList();
    });
  }

  Future<void> update(String id, Map<String, dynamic> data) =>
      db.from('exam_papers').update(data).eq('id', id);

  Future<void> delete(String id) =>
      db.from('exam_papers').delete().eq('id', id);
}
