class ExamPaper {
  final String id, authorId, authorName, subject, track, year, content;
  final List<String> images;
  final DateTime createdAt;

  const ExamPaper({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.subject,
    required this.track,
    required this.year,
    required this.content,
    required this.images,
    required this.createdAt,
  });

  factory ExamPaper.fromMap(Map<String, dynamic> d) => ExamPaper(
    id: '${d['id'] ?? ''}',
    authorId: '${d['authorId'] ?? ''}',
    authorName: '${d['authorName'] ?? ''}',
    subject: '${d['subject'] ?? ''}',
    track: '${d['track'] ?? 'scientific'}',
    year: '${d['year'] ?? ''}',
    content: '${d['content'] ?? ''}',
    images: ((d['images'] as List?) ?? const []).map((x) => '$x').toList(),
    createdAt: DateTime.tryParse('${d['createdAt'] ?? ''}') ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'authorId': authorId,
    'authorName': authorName,
    'subject': subject,
    'track': track,
    'year': year,
    'content': content,
    'images': images,
  };
}
