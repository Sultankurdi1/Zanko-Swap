import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/institution.dart';

class InstitutionRepository {
  final SupabaseClient db;
  InstitutionRepository({SupabaseClient? client})
    : db = client ?? Supabase.instance.client;
  Stream<List<Institution>> streamByType(InstitutionType type) => db
      .from('institutions')
      .stream(primaryKey: ['id'])
      .eq('type', type.name)
      .eq('active', true)
      .map((r) => r.map(Institution.fromMap).toList());
  Stream<List<Institution>> streamAll() => db
      .from('institutions')
      .stream(primaryKey: ['id'])
      .eq('active', true)
      .map((r) => r.map(Institution.fromMap).toList());
  Future<void> create(Institution item) =>
      db.from('institutions').insert(item.toMap());
  Future<void> update(Institution item) =>
      db.from('institutions').update(item.toMap()).eq('id', item.id);
}
