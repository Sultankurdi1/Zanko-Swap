import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/academic_path.dart';
import '../models/listing.dart';

/// The student's own university, department and stage. Saved only on this
/// phone (never sent to the server) and used for "For my department".
class MyStudyPath {
  const MyStudyPath._();

  static const _key = 'my_study_path';

  static Future<AcademicPath> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return const AcademicPath();
      return AcademicPath.fromMap(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return const AcademicPath();
    }
  }

  static Future<void> save(AcademicPath path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(path.toMap()));
  }

  static bool matches(Listing x, AcademicPath path) {
    if (path.isEmpty) return true;
    bool same(String a, String b) =>
        a.trim().isEmpty || b.trim().isEmpty || a.trim() == b.trim();
    if (path.institutionId.isNotEmpty && x.universityId != path.institutionId) {
      return false;
    }
    return same(x.collegeId, path.collegeName) &&
        same(x.departmentId, path.departmentName) &&
        same(x.stageLabel, path.stage);
  }
}
