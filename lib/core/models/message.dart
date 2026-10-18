class Message {
  final int? id;
  final String chatId;
  final String senderId;
  final String text;
  final String type;
  final bool isRead;
  final DateTime? createdAt;

  const Message({
    this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    this.type = 'text',
    required this.isRead,
    this.createdAt,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] is int
          ? map['id'] as int
          : int.tryParse(map['id']?.toString() ?? ''),
      chatId: map['chatId']?.toString() ?? '',
      senderId: map['senderId']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      type: map['type']?.toString() ?? 'text',
      isRead: map['isRead'] == true,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  bool isMine(String myId) => senderId == myId;
}
