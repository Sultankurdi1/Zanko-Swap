import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/research_paper.dart';

class ResearchRepository {
  ResearchRepository({SupabaseClient? client})
    : db = client ?? Supabase.instance.client;
  final SupabaseClient db;

  Future<String> add(Map<String, dynamic> data) async {
    try {
      final payload = Map<String, dynamic>.from(data)
        ..removeWhere((_, value) => value == null);

      final res = await db.from('research').insert(payload).select('id');
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

  Stream<List<ResearchPaper>> stream({String? departmentId, String? stage}) {
    var query = db.from('research').stream(primaryKey: ['id']);
    final department = departmentId?.trim();
    if (department != null && department.isNotEmpty) {
      query = query.eq('departmentId', department);
    }
    final stageValue = stage?.trim();
    if (stageValue != null && stageValue.isNotEmpty) {
      query = query.eq('stage', stageValue);
    }
    return query
        .order('createdAt', ascending: false)
        .map((rows) => rows.map(ResearchPaper.fromMap).toList());
  }

  Future<void> update(String id, Map<String, dynamic> data) =>
      db.from('research').update(data).eq('id', id);

  Future<void> delete(String id) => db.from('research').delete().eq('id', id);
}
