class AcademicPath {
  final String institutionId;
  final String institutionName;
  final String collegeName;
  final String departmentName;
  final String stage;

  const AcademicPath({
    this.institutionId = '',
    this.institutionName = '',
    this.collegeName = '',
    this.departmentName = '',
    this.stage = '',
  });

  bool get isEmpty => institutionName.isEmpty;

  String get summary => [
    institutionName,
    collegeName,
    departmentName,
    stage,
  ].where((x) => x.trim().isNotEmpty).join(' • ');

  Map<String, dynamic> toMap() => {
    'universityId': institutionId,
    'universityName': institutionName,
    'collegeId': collegeName,
    'departmentId': departmentName,
    'stageLabel': stage,
  };

  factory AcademicPath.fromMap(Map<String, dynamic> d) => AcademicPath(
    institutionId: d['universityId'] ?? '',
    institutionName: d['universityName'] ?? '',
    collegeName: d['collegeId'] ?? '',
    departmentName: d['departmentId'] ?? '',
    stage: d['stageLabel'] ?? '',
  );
}
