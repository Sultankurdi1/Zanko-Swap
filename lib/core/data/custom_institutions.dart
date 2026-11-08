import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'kurdistan_institutions.dart';

class CustomInstitutionsService {
  static const _key = 'custom_institutions_v1';

  static Future<List<EduInstitution>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(
            (e) => EduInstitution(
              id: (e['id'] ?? '').toString(),
              nameKu: (e['nameKu'] ?? '').toString(),
              nameEn: (e['nameEn'] ?? '').toString(),
              city: (e['city'] ?? '').toString(),
              ownership: (e['ownership'] ?? 'government') == 'private'
                  ? EduOwnership.private
                  : EduOwnership.government,
              kind: (e['kind'] ?? 'institute') == 'university'
                  ? EduKind.university
                  : EduKind.institute,
              colleges: ((e['colleges'] ?? []) as List<dynamic>)
                  .map(
                    (c) => EduCollege(
                      (c['nameKu'] ?? '').toString(),
                      (c['nameEn'] ?? '').toString(),
                    ),
                  )
                  .toList(),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<EduInstitution> add({
    required String name,
    required String city,
    required EduOwnership ownership,
    required EduKind kind,
    List<String> colleges = const [],
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadAll();
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final inst = EduInstitution(
      id: id,
      nameKu: name,
      nameEn: name,
      city: city,
      ownership: ownership,
      kind: kind,
      colleges: colleges.map((c) => EduCollege(c, c)).toList(),
    );
    existing.add(inst);
    await prefs.setString(_key, jsonEncode(existing.map(_toJson).toList()));
    return inst;
  }

  static Map<String, dynamic> _toJson(EduInstitution x) => {
    'id': x.id,
    'nameKu': x.nameKu,
    'nameEn': x.nameEn,
    'city': x.city,
    'ownership': x.ownership == EduOwnership.private ? 'private' : 'government',
    'kind': x.kind == EduKind.university ? 'university' : 'institute',
    'colleges': x.colleges
        .map((c) => {'nameKu': c.nameKu, 'nameEn': c.nameEn})
        .toList(),
  };

  static Future<List<EduInstitution>> getAll() async {
    final custom = await loadAll();
    return [...kurdistanInstitutions, ...custom];
  }
}
