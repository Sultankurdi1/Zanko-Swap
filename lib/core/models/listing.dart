class Listing {
  final String id,
      sellerId,
      sellerName,
      title,
      description,
      type,
      transactionType,
      condition;
  final int priceIQD;
  final String? edition, subject, pdfUrl;
  final int? semester;
  final List<String> images;
  final String cityId,
      universityId,
      universityName,
      collegeId,
      departmentId,
      stageLabel,
      status;
  final int stage;
  final DateTime createdAt;
  const Listing({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.title,
    required this.description,
    required this.type,
    required this.transactionType,
    required this.priceIQD,
    required this.condition,
    this.edition,
    this.subject,
    this.semester,
    required this.images,
    this.pdfUrl,
    required this.cityId,
    required this.universityId,
    this.universityName = '',
    required this.collegeId,
    required this.departmentId,
    this.stage = 1,
    this.stageLabel = '',
    required this.status,
    required this.createdAt,
  });
  factory Listing.fromMap(Map<String, dynamic> d) {
    DateTime dt =
        DateTime.tryParse('${d['createdAt'] ?? ''}') ?? DateTime.now();
    return Listing(
      id: '${d['id'] ?? ''}',
      sellerId: '${d['sellerId'] ?? ''}',
      sellerName: '${d['sellerName'] ?? ''}',
      title: '${d['title'] ?? ''}',
      description: '${d['description'] ?? ''}',
      type: '${d['type'] ?? 'book'}',
      transactionType: '${d['transactionType'] ?? 'free'}',
      priceIQD: int.tryParse('${d['priceIQD'] ?? 0}') ?? 0,
      condition: '${d['condition'] ?? 'good'}',
      edition: d['edition']?.toString(),
      subject: d['subject']?.toString(),
      semester: int.tryParse('${d['semester'] ?? ''}'),
      images: List<String>.from(d['images'] ?? const []),
      pdfUrl: d['pdfUrl']?.toString(),
      cityId: '${d['cityId'] ?? ''}',
      universityId: '${d['universityId'] ?? ''}',
      universityName: '${d['universityName'] ?? ''}',
      collegeId: '${d['collegeId'] ?? ''}',
      departmentId: '${d['departmentId'] ?? ''}',
      stage: int.tryParse('${d['stage'] ?? 1}') ?? 1,
      stageLabel: '${d['stageLabel'] ?? ''}',
      status: '${d['status'] ?? 'active'}',
      createdAt: dt,
    );
  }
}
