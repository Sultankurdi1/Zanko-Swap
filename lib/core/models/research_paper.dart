import 'academic_path.dart';

class ResearchPaper {
  final String id, authorId, authorName, title, description, linkOrContent;
  final AcademicPath path;
  final DateTime createdAt;

  const ResearchPaper({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.description,
    required this.linkOrContent,
    required this.path,
    required this.createdAt,
  });

  factory ResearchPaper.fromMap(Map<String, dynamic> d) {
    final stageValue = '${d['stage'] ?? d['stageLabel'] ?? ''}';
    return ResearchPaper(
      id: '${d['id'] ?? ''}',
      authorId: '${d['authorId'] ?? d['author_id'] ?? ''}',
      authorName: '${d['authorName'] ?? ''}',
      title: '${d['title'] ?? ''}',
      description: '${d['description'] ?? ''}',
      linkOrContent: '${d['file_url'] ?? d['linkOrContent'] ?? ''}',
      path: AcademicPath.fromMap({...d, 'stageLabel': stageValue}),
      createdAt:
          DateTime.tryParse('${d['createdAt'] ?? d['created_at'] ?? ''}') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'authorId': authorId,
    'authorName': authorName,
    'title': title,
    'description': description,
    'file_url': linkOrContent,
    'stage': path.stage,
    'universityId': path.institutionId,
    'universityName': path.institutionName,
    'collegeId': path.collegeName,
    'departmentId': path.departmentName,
  };
}
