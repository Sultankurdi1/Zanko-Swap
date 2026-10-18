import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final dynamic listingId;
  final String listingTitle;
  final String listingImage;
  final String listingPrice;
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.listingId,
    this.listingTitle = '',
    this.listingImage = '',
    this.listingPrice = '',
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String _displayName;
  String? _avatarUrl;
  bool _isSending = false;
  bool _isBlocked = false;
  bool _moderationBusy = false;
  bool _readSyncInProgress = false;
  int _lastRenderedMessageCount = 0;

  String get chatId {
    final me = Supabase.instance.client.auth.currentUser?.id;
    if (me == null || widget.otherUserId.isEmpty) return '';
    final u = [me, widget.otherUserId]..sort();
    final lId = widget.listingId?.toString().trim() ?? '';
    return lId.isNotEmpty ? '${u[0]}_${u[1]}_$lId' : '${u[0]}_${u[1]}';
  }

  @override
  void initState() {
    super.initState();

    _displayName = widget.otherUserName.trim();
    if (_displayName == 'قوتابی' || _displayName == 'Student') {
      _displayName = '';
    }
    _fetchProfile();
    _checkBlocked();
    _markAsRead();
  }

  Future<void> _checkBlocked() async {
    final me = Supabase.instance.client.auth.currentUser?.id;
    if (me == null || widget.otherUserId.isEmpty) return;
    try {
      final row = await Supabase.instance.client
          .from('user_blocks')
          .select('id')
          .eq('blocker_id', me)
          .eq('blocked_id', widget.otherUserId)
          .maybeSingle();
      if (mounted) setState(() => _isBlocked = row != null);
    } catch (_) {}
  }

  Future<void> _reportUser() async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            const ListTile(title: Text('Why are you reporting this person?')),
            for (final item in const <(String, String)>[
              ('harassment', 'Harassment or bullying'),
              ('spam', 'Spam or scam'),
              ('inappropriate', 'Inappropriate messages'),
              ('other', 'Something else'),
            ])
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: Text(item.$2),
                onTap: () => Navigator.pop(ctx, item.$1),
              ),
          ],
        ),
      ),
    );
    if (reason == null || !mounted) return;
    try {
      final me = Supabase.instance.client.auth.currentUser?.id;
      if (me == null) throw StateError('Sign in to report a user.');
      await Supabase.instance.client.from('user_reports').insert({
        'reporter_id': me,
        'reported_user_id': widget.otherUserId,
        'chat_id': chatId,
        'reason': reason,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report sent. Thank you.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not send report: $e')));
      }
    }
  }

  Future<void> _toggleBlock() async {
    if (_moderationBusy) return;
    final shouldBlock = !_isBlocked;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(shouldBlock ? 'Block $otherName' : 'Unblock $otherName'),
        content: Text(
          shouldBlock
              ? 'They will not be able to message you in this chat.'
              : 'They will be able to message you again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(shouldBlock ? 'Block' : 'Unblock'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _moderationBusy = true);
    try {
      final me = Supabase.instance.client.auth.currentUser?.id;
      if (me == null) throw StateError('Sign in to manage blocked users.');
      final db = Supabase.instance.client;
      if (shouldBlock) {
        await db.from('user_blocks').insert({
          'blocker_id': me,
          'blocked_id': widget.otherUserId,
        });
      } else {
        await db
            .from('user_blocks')
            .delete()
            .eq('blocker_id', me)
            .eq('blocked_id', widget.otherUserId);
      }
      if (mounted) {
        setState(() => _isBlocked = shouldBlock);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(shouldBlock ? 'User blocked.' : 'User unblocked.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not update block: $e')));
      }
    } finally {
      if (mounted) setState(() => _moderationBusy = false);
    }
  }

  String get otherName => _displayName.isEmpty ? 'this user' : _displayName;

  Future<void> _fetchProfile() async {
    if (widget.otherUserId.isEmpty) return;
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', widget.otherUserId)
          .maybeSingle();

      if (res != null && mounted) {
        final name =
            (res['displayName'] ??
                    res['display_name'] ??
                    res['name'] ??
                    res['full_name'] ??
                    '')
                .toString()
                .trim();
        final avatar =
            (res['photoUrl'] ??
                    res['photo_url'] ??
                    res['avatar_url'] ??
                    res['image_url'])
                ?.toString()
                .trim();

        setState(() {
          if (name.isNotEmpty && name != 'قوتابی' && name != 'Student') {
            _displayName = name;
          }
          if (avatar != null && avatar.isNotEmpty) {
            _avatarUrl = avatar;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _markAsRead() async {
    final me = Supabase.instance.client.auth.currentUser?.id;
    if (me == null || chatId.isEmpty || _readSyncInProgress) return;
    _readSyncInProgress = true;
    try {
      final db = Supabase.instance.client;
      await db
          .from('messages')
          .update({'isRead': true})
          .eq('chatId', chatId)
          .neq('senderId', me);
      await db
          .from('chats')
          .update({'isRead': true})
          .eq('id', chatId)
          .neq('lastSenderId', me);
    } catch (_) {
    } finally {
      _readSyncInProgress = false;
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await Supabase.instance.client
          .from('messages')
          .delete()
          .eq('id', messageId);

      final remaining = await Supabase.instance.client
          .from('messages')
          .select('text,senderId,type,createdAt')
          .eq('chatId', chatId)
          .order('createdAt', ascending: false)
          .limit(1);
      final last = remaining.isEmpty ? null : remaining.first;
      await Supabase.instance.client
          .from('chats')
          .update({
            'lastMessage': last?['type'] == 'item_card'
                ? '📦 ${_cardTitle(last?['text'])}'
                : (last?['text'] ?? ''),
            'lastSenderId': last?['senderId'],
            'lastMessageAt': last?['createdAt'],
            'updatedAt': DateTime.now().toUtc().toIso8601String(),
            'isRead': true,
          })
          .eq('id', chatId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('نامەکە بە سەرکەوتوویی سڕایەوە'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('هەڵە لە سڕینەوە: $e')));
      }
    }
  }

  String _cardTitle(dynamic raw) {
    try {
      final parsed = jsonDecode(raw?.toString() ?? '');
      if (parsed is Map) return (parsed['title'] ?? '').toString();
    } catch (_) {}
    return raw?.toString() ?? '';
  }

  void _showMessageOptions(Map<String, dynamic> message, bool isMine) {
    final text = message['text']?.toString() ?? '';
    final messageId = message['id']?.toString() ?? '';
    final type = message['type']?.toString() ?? 'text';
    final copyText = type == 'item_card' ? _cardTitle(text) : text;

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            if (copyText.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: Text(
                  type == 'item_card' ? 'Copy item title' : 'Copy text',
                ),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: copyText));
                  Navigator.pop(ctx);
                },
              ),
            if (isMine && messageId.isNotEmpty)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Delete message',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteMessage(messageId);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> send() async {
    final text = controller.text.trim();
    final me = Supabase.instance.client.auth.currentUser?.id;
    if (text.isEmpty ||
        me == null ||
        chatId.isEmpty ||
        _isSending ||
        _isBlocked) {
      return;
    }

    final db = Supabase.instance.client;
    setState(() => _isSending = true);
    try {
      final now = DateTime.now().toUtc().toIso8601String();

      final existingChat = await db
          .from('chats')
          .select('id')
          .eq('id', chatId)
          .maybeSingle();

      final existingItemCard = await db
          .from('messages')
          .select('id')
          .eq('chatId', chatId)
          .eq('type', 'item_card')
          .limit(1);
      final hasItemCard = existingItemCard.isNotEmpty;

      if (existingChat == null) {
        final chatData = <String, dynamic>{
          'id': chatId,
          'buyerId': me,
          'sellerId': widget.otherUserId,
          'lastMessage': text,
          'lastSenderId': me,
          'isRead': false,
          'lastMessageAt': now,
          'updatedAt': now,
        };
        final listing = int.tryParse(widget.listingId?.toString() ?? '');
        if (listing != null && listing > 0) chatData['listingId'] = listing;
        await db.from('chats').insert(chatData);
      } else {
        await db
            .from('chats')
            .update({
              'lastMessage': text,
              'lastSenderId': me,
              'isRead': false,
              'lastMessageAt': now,
              'updatedAt': now,
            })
            .eq('id', chatId);
      }
      if (!hasItemCard &&
          (widget.listingTitle.isNotEmpty || widget.listingImage.isNotEmpty)) {
        final cardData = jsonEncode({
          'title': widget.listingTitle,
          'price': widget.listingPrice,
          'image': widget.listingImage,
        });

        await db.from('messages').insert({
          'chatId': chatId,
          'senderId': me,
          'text': cardData,
          'type': 'item_card',
          'isRead': false,
          'createdAt': now,
        });
      }

      final sentMessage = await db
          .from('messages')
          .insert({
            'chatId': chatId,
            'senderId': me,
            'text': text,
            'type': 'text',
            'isRead': false,
            'createdAt': DateTime.now().toUtc().toIso8601String(),
          })
          .select('id')
          .single();

      try {
        await db.functions.invoke(
          'send-chat-notification',
          body: {'messageId': sentMessage['id'].toString()},
        );
      } catch (_) {}

      controller.clear();

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message was not sent: $e'),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeScope.of(context);
    final s = AppStrings.of(context);
    final me = Supabase.instance.client.auth.currentUser?.id;

    final titleToShow = _displayName.isEmpty
        ? (s.isKurdish
              ? 'بەکارهێنەر'
              : s.isArabic
              ? 'مستخدم'
              : 'User')
        : _displayName;

    final stream = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chatId', chatId)
        .order('createdAt', ascending: true);

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: palette.textSecondary),
          onPressed: () {
            _markAsRead();
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: palette.primary.withValues(alpha: 0.2),
              backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                  ? NetworkImage(_avatarUrl!)
                  : null,
              child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                  ? (titleToShow.isEmpty
                        ? const SizedBox.shrink()
                        : Text(
                            titleToShow[0].toUpperCase(),
                            style: TextStyle(
                              color: palette.accent,
                              fontWeight: FontWeight.w900,
                            ),
                          ))
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                titleToShow,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Chat safety options',
            onSelected: (value) {
              if (value == 'report') _reportUser();
              if (value == 'block') _toggleBlock();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'report',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.flag_outlined),
                  title: Text('Report user'),
                ),
              ),
              PopupMenuItem(
                value: 'block',
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    _isBlocked ? Icons.lock_open_outlined : Icons.block,
                  ),
                  title: Text(_isBlocked ? 'Unblock user' : 'Block user'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: stream,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: palette.primary),
                  );
                }

                final docs = snap.data ?? [];
                if (docs.any(
                  (d) =>
                      (d['senderId'] ?? d['sender_id']) != me &&
                      d['isRead'] != true &&
                      d['is_read'] != true,
                )) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _markAsRead(),
                  );
                }
                if (docs.length > _lastRenderedMessageCount) {
                  _lastRenderedMessageCount = docs.length;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(
                        _scrollController.position.maxScrollExtent,
                      );
                    }
                  });
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      s.isKurdish
                          ? 'دەست بە گفتوگۆ بکە'
                          : s.isArabic
                          ? 'ابدأ المحادثة'
                          : 'Start conversation',
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i];
                    final sender = (d['senderId'] ?? d['sender_id'])
                        ?.toString();
                    final mine =
                        sender?.trim().toLowerCase() ==
                        me?.trim().toLowerCase();
                    final isRead = d['isRead'] == true || d['is_read'] == true;
                    final type = d['type']?.toString() ?? 'text';

                    if (type == 'item_card') {
                      String itemTitle = widget.listingTitle;
                      String itemPrice = widget.listingPrice;
                      String itemImage = widget.listingImage;

                      try {
                        final rawText = d['text']?.toString() ?? '';
                        if (rawText.startsWith('{') && rawText.endsWith('}')) {
                          final parsed = jsonDecode(rawText);
                          if (parsed is Map) {
                            if (parsed['title'] != null &&
                                parsed['title'].toString().isNotEmpty) {
                              itemTitle = parsed['title'].toString();
                            }
                            if (parsed['price'] != null &&
                                parsed['price'].toString().isNotEmpty) {
                              itemPrice = parsed['price'].toString();
                            }
                            if (parsed['image'] != null &&
                                parsed['image'].toString().isNotEmpty) {
                              itemImage = parsed['image'].toString();
                            }
                          }
                        } else {
                          itemTitle = rawText;
                        }
                      } catch (_) {}

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onLongPress: () => _showMessageOptions(d, mine),
                        child: Align(
                          alignment: mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(10),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: palette.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: palette.primary.withValues(alpha: 0.5),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (itemImage.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      itemImage,
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const SizedBox.shrink(),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  itemTitle.isNotEmpty
                                      ? itemTitle
                                      : (s.isKurdish
                                            ? 'کاڵا'
                                            : s.isArabic
                                            ? 'منتج'
                                            : 'Product'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: palette.textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (itemPrice.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    itemPrice,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      color: palette.accent,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onLongPress: () => _showMessageOptions(d, mine),
                      child: Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: mine
                                ? (palette.isDark
                                      ? palette.surfaceHighlight
                                      : palette.primary.withValues(alpha: 0.12))
                                : palette.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: mine
                                  ? palette.primary.withValues(alpha: 0.3)
                                  : palette.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Text(
                                  '${d['text'] ?? ''}',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ),
                              if (mine) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  isRead
                                      ? Icons.done_all_rounded
                                      : Icons.check_rounded,
                                  size: 15,
                                  color: isRead
                                      ? Colors.blue
                                      : palette.textSecondary.withValues(
                                          alpha: 0.6,
                                        ),
                                ),
                                IconButton(
                                  tooltip: 'Message options',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  iconSize: 18,
                                  icon: Icon(
                                    Icons.more_horiz,
                                    color: palette.textSecondary,
                                  ),
                                  onPressed: () => _showMessageOptions(d, mine),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_isBlocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: palette.surfaceHighlight,
              child: Text(
                'You blocked this user. Unblock them to send messages.',
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.textSecondary),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: palette.surfaceHighlight,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: palette.border),
                      ),
                      child: TextField(
                        enabled: !_isBlocked,
                        controller: controller,
                        textInputAction: TextInputAction.send,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          hintText: s.isKurdish
                              ? 'نامە بنووسە...'
                              : 'Write message...',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) {
                          if (!_isSending) send();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSending || _isBlocked ? null : send,
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    color: palette.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
