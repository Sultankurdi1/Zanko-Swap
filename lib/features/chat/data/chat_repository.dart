import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/chat.dart';
import '../../../core/models/message.dart';

class ChatRepository {
  final _client = Supabase.instance.client;

  String get myId => _client.auth.currentUser?.id ?? '';

  String generateChatId(String otherUserId, {int? listingId}) {
    final ids = [myId, otherUserId]..sort();
    final base = '${ids[0]}_${ids[1]}';
    return listingId == null ? base : '${base}_$listingId';
  }

  Future<Chat?> getOrCreateChat({
    required String otherUserId,
    int? listingId,
    String? initialMessage,
  }) async {
    if (myId.isEmpty || otherUserId.isEmpty) return null;

    final chatId = generateChatId(otherUserId, listingId: listingId);

    try {
      final existing = await _client
          .from('chats')
          .select()
          .eq('id', chatId)
          .maybeSingle();

      if (existing != null) {
        return Chat.fromMap(existing);
      }

      final now = DateTime.now().toUtc().toIso8601String();
      final chatData = <String, dynamic>{
        'id': chatId,
        'buyerId': myId,
        'sellerId': otherUserId,
        'lastMessage': initialMessage ?? '',
        'lastSenderId': initialMessage != null ? myId : null,
        'isRead': initialMessage == null,
        'updatedAt': now,
      };
      if (listingId != null) {
        chatData['listingId'] = listingId;
      }

      await _client.from('chats').insert(chatData);

      final created = await _client
          .from('chats')
          .select()
          .eq('id', chatId)
          .single();

      return Chat.fromMap(created);
    } catch (_) {
      return null;
    }
  }

  Future<bool> sendMessage({
    required String otherUserId,
    required String text,
    int? listingId,
  }) async {
    if (myId.isEmpty || text.trim().isEmpty) return false;

    try {
      final chatId = generateChatId(otherUserId, listingId: listingId);
      final now = DateTime.now().toUtc().toIso8601String();

      final chat = await getOrCreateChat(
        otherUserId: otherUserId,
        listingId: listingId,
      );
      if (chat == null) return false;

      final sentMessage = await _client
          .from('messages')
          .insert({
            'chatId': chatId,
            'senderId': myId,
            'text': text.trim(),
            'type': 'text',
            'isRead': false,
            'createdAt': now,
          })
          .select('id')
          .single();

      try {
        await _client.functions.invoke(
          'send-chat-notification',
          body: {'messageId': sentMessage['id'].toString()},
        );
      } catch (_) {}

      await _client
          .from('chats')
          .update({
            'lastMessage': text.trim(),
            'lastMessageAt': now,
            'lastSenderId': myId,
            'isRead': false,
            'updatedAt': now,
            if (listingId != null) 'listingId': listingId,
          })
          .eq('id', chatId);

      return true;
    } catch (_) {
      return false;
    }
  }

  Stream<List<Message>> streamMessages(String otherUserId, {int? listingId}) {
    final chatId = generateChatId(otherUserId, listingId: listingId);
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chatId', chatId)
        .order('createdAt', ascending: true)
        .map((rows) => rows.map((r) => Message.fromMap(r)).toList());
  }

  Stream<List<Chat>> streamMyChats() {
    return _client
        .from('chats')
        .stream(primaryKey: ['id'])
        .order('updatedAt', ascending: false)
        .map((rows) {
          return rows
              .where((r) => r['buyerId'] == myId || r['sellerId'] == myId)
              .map((r) => Chat.fromMap(r))
              .toList();
        });
  }

  Future<void> deleteChat(String chatId) async {
    if (myId.isEmpty || chatId.isEmpty) {
      throw StateError('You must be signed in to delete a conversation.');
    }
    await _client.from('chats').delete().eq('id', chatId);
  }

  Future<void> markAsRead(String otherUserId, {int? listingId}) async {
    if (myId.isEmpty) return;
    final chatId = generateChatId(otherUserId, listingId: listingId);
    try {
      await _client
          .from('messages')
          .update({'isRead': true})
          .eq('chatId', chatId)
          .neq('senderId', myId);

      await _client
          .from('chats')
          .update({'isRead': true})
          .eq('id', chatId)
          .neq('lastSenderId', myId);
    } catch (_) {}
  }

  Future<Map<String, String?>> fetchProfile(String userId) async {
    try {
      final res = await _client
          .from('profiles')
          .select('displayName, photoUrl')
          .eq('id', userId)
          .maybeSingle();

      if (res == null) return {'name': null, 'avatar': null};

      final name = (res['displayName'] ?? '').toString().trim();
      final avatar = (res['photoUrl'] ?? '').toString().trim();

      return {
        'name': name.isEmpty ? null : name,
        'avatar': avatar.isEmpty ? null : avatar,
      };
    } catch (_) {
      return {'name': null, 'avatar': null};
    }
  }

  Future<Map<String, Map<String, String?>>> fetchProfiles(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};
    try {
      final res = await _client
          .from('profiles')
          .select('id, displayName, photoUrl')
          .inFilter('id', userIds);

      final map = <String, Map<String, String?>>{};
      for (final row in res) {
        final id = row['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        final name = (row['displayName'] ?? '').toString().trim();
        final avatar = (row['photoUrl'] ?? '').toString().trim();
        map[id] = {
          'name': name.isEmpty ? null : name,
          'avatar': avatar.isEmpty ? null : avatar,
        };
      }
      return map;
    } catch (_) {
      return {};
    }
  }
}
