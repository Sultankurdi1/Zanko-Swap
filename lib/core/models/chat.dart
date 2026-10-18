class Chat {
  final String id;
  final String buyerId;
  final String sellerId;
  final int? listingId;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final DateTime? updatedAt;
  final String? lastSenderId;
  final bool isRead;

  final String? otherUserName;
  final String? otherUserAvatar;

  const Chat({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    this.listingId,
    required this.lastMessage,
    this.lastMessageAt,
    this.updatedAt,
    this.lastSenderId,
    required this.isRead,
    this.otherUserName,
    this.otherUserAvatar,
  });

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id']?.toString() ?? '',
      buyerId: map['buyerId']?.toString() ?? '',
      sellerId: map['sellerId']?.toString() ?? '',
      listingId: map['listingId'] is int
          ? map['listingId'] as int
          : int.tryParse(map['listingId']?.toString() ?? ''),
      lastMessage: map['lastMessage']?.toString() ?? '',
      lastMessageAt: map['lastMessageAt'] != null
          ? DateTime.tryParse(map['lastMessageAt'].toString())
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString())
          : null,
      lastSenderId: map['lastSenderId']?.toString(),
      isRead: map['isRead'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'buyerId': buyerId,
      'sellerId': sellerId,
      if (listingId != null) 'listingId': listingId,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastSenderId': lastSenderId,
      'isRead': isRead,
    };
  }

  String otherUserId(String myId) {
    return myId == buyerId ? sellerId : buyerId;
  }

  bool isMeLastSender(String myId) {
    return lastSenderId == myId;
  }
}
