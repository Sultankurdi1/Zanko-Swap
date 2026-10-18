class AdCampaign {
  final String id;
  final String title;
  final String subtitle;
  final String advertiser;
  final String imageUrl;
  final String receiptUrl;
  final String targetUrl;
  final String targetRoute;
  final String category;
  final String placement;
  final String status;
  final String badgeText;
  final int budgetIQD;
  final int days;
  final DateTime endDate;
  final DateTime createdAt;
  final bool isActive;
  final int viewsCount;
  final int clicksCount;

  AdCampaign({
    this.id = '',
    required this.title,
    this.subtitle = '',
    required this.advertiser,
    this.imageUrl = '',
    this.receiptUrl = '',
    this.targetUrl = '',
    this.targetRoute = '',
    this.category = 'home',
    this.placement = 'home_banner',
    this.status = 'pending',
    this.badgeText = 'SPONSORED',
    this.budgetIQD = 0,
    this.days = 30,
    DateTime? endDate,
    DateTime? createdAt,
    this.isActive = false,
    this.viewsCount = 0,
    this.clicksCount = 0,
  }) : endDate = endDate ?? DateTime.now().add(Duration(days: days)),
       createdAt = createdAt ?? DateTime.now();

  factory AdCampaign.fromMap(Map<String, dynamic> map) {
    return AdCampaign(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      advertiser: map['advertiser'] ?? '',
      imageUrl: map['image_url'] ?? '',
      receiptUrl: map['receipt_url'] ?? '',
      targetUrl: map['target_url'] ?? '',
      targetRoute: map['target_route'] ?? '',
      category: map['category'] ?? 'home',
      placement: map['placement'] ?? 'home_banner',
      status: map['status'] ?? 'pending',
      badgeText: map['badge_text'] ?? 'SPONSORED',
      budgetIQD: (map['budget_iqd'] as num?)?.toInt() ?? 0,
      days: (map['days'] as num?)?.toInt() ?? 30,
      endDate: DateTime.tryParse(map['end_date'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      isActive: map['is_active'] ?? false,
      viewsCount: (map['views_count'] as num?)?.toInt() ?? 0,
      clicksCount: (map['clicks_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'advertiser': advertiser,
      'image_url': imageUrl,
      'receipt_url': receiptUrl,
      'target_url': targetUrl,
      'target_route': targetRoute,
      'category': category,
      'placement': placement,
      'status': status,
      'badge_text': badgeText,
      'budget_iqd': budgetIQD,
      'days': days,
      'end_date': endDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }
}
