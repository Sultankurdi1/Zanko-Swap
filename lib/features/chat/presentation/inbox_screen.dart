import 'package:flutter/material.dart';
import '../../../core/models/chat.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../data/chat_repository.dart';
import 'chat_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final _repo = ChatRepository();
  String? _profileIdsKey;
  Future<Map<String, Map<String, String?>>>? _profilesFuture;

  Future<Map<String, Map<String, String?>>> _profilesFor(List<String> userIds) {
    final sortedIds = [...userIds]..sort();
    final key = sortedIds.join('|');
    if (_profilesFuture == null || _profileIdsKey != key) {
      _profileIdsKey = key;
      _profilesFuture = _repo.fetchProfiles(sortedIds);
    }
    return _profilesFuture!;
  }

  Future<void> _confirmDeleteChat(Chat chat) async {
    final s = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          s.isKurdish
              ? 'سڕینەوەی چات'
              : s.isArabic
              ? 'حذف المحادثة'
              : 'Delete chat',
        ),
        content: Text(
          s.isKurdish
              ? 'چات و هەموو نامەکانی لە لای هەردوو بەکارهێنەرەوە دەسڕدرێنەوە. دڵنیایت؟'
              : 'This deletes the chat and all its messages for both people. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              s.isKurdish
                  ? 'پاشگەزبوونەوە'
                  : s.isArabic
                  ? 'إلغاء'
                  : 'Cancel',
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              s.isKurdish
                  ? 'بسڕەوە'
                  : s.isArabic
                  ? 'حذف'
                  : 'Delete',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _repo.deleteChat(chat.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              s.isKurdish
                  ? 'چاتەکە سڕایەوە'
                  : s.isArabic
                  ? 'تم حذف المحادثة'
                  : 'Chat deleted',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              s.isKurdish
                  ? 'سڕینەوەی چات سەرکەوتوو نەبوو. مایگرەیشنی دیتابەیس جێبەجێ بکە.'
                  : 'Could not delete chat. Apply the chat deletion database migration.',
            ),
          ),
        );
      }
    }
  }

  String _formatTime(DateTime? dt, AppStrings s) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);

    if (diff.inMinutes < 1) {
      return s.isKurdish
          ? 'ئێستا'
          : s.isArabic
          ? 'الآن'
          : 'now';
    }
    if (diff.inHours < 12) {
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inHours < 24) {
      final time =
          '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
      return s.isKurdish
          ? 'دوێنێ $time'
          : s.isArabic
          ? 'أمس $time'
          : 'Yesterday $time';
    }
    return '${local.day}/${local.month}';
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final palette = AppThemeScope.of(context);

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.bg,
        elevation: 0,
        title: Text(
          s.messages,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: palette.textPrimary,
          ),
        ),
      ),
      body: StreamBuilder<List<Chat>>(
        stream: _repo.streamMyChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: palette.primary),
            );
          }

          final chats = snapshot.data ?? [];
          final validChats = chats
              .where((c) => c.lastMessage.trim().isNotEmpty)
              .toList();

          if (validChats.isEmpty) {
            return _EmptyState(palette: palette, s: s);
          }

          final otherIds = validChats
              .map((c) => c.otherUserId(_repo.myId))
              .toSet()
              .toList();

          return FutureBuilder<Map<String, Map<String, String?>>>(
            future: _profilesFor(otherIds),
            builder: (context, profileSnap) {
              final profiles = profileSnap.data ?? {};

              return RefreshIndicator(
                color: palette.primary,
                onRefresh: () async {
                  setState(() {
                    _profilesFuture = null;
                    _profileIdsKey = null;
                  });
                },
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  itemCount: validChats.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final chat = validChats[i];
                    final otherId = chat.otherUserId(_repo.myId);
                    final profile = profiles[otherId] ?? {};
                    final name = (profile['name'] ?? '').toString().trim();
                    final avatar = profile['avatar'];

                    return _ChatTile(
                      chat: chat,
                      otherUserId: otherId,
                      displayName: name.isNotEmpty
                          ? name
                          : (s.isKurdish
                                ? 'قوتابی'
                                : s.isArabic
                                ? 'طالب'
                                : 'Student'),
                      avatarUrl: avatar,
                      timeLabel: _formatTime(
                        chat.lastMessageAt ?? chat.updatedAt,
                        s,
                      ),
                      myId: _repo.myId,
                      palette: palette,
                      s: s,
                      onDelete: () => _confirmDeleteChat(chat),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              listingId: chat.listingId ?? '',
                              otherUserId: otherId,
                              otherUserName: name.isNotEmpty
                                  ? name
                                  : (s.isKurdish
                                        ? 'قوتابی'
                                        : s.isArabic
                                        ? 'طالب'
                                        : 'Student'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppPalette palette;
  final AppStrings s;

  const _EmptyState({required this.palette, required this.s});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: palette.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 14),
          Text(
            s.isKurdish
                ? 'هیچ گفتوگۆیەک نییە'
                : s.isArabic
                ? 'لا توجد محادثات بعد'
                : 'No conversations yet',
            style: TextStyle(color: palette.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final Chat chat;
  final String otherUserId;
  final String displayName;
  final String? avatarUrl;
  final String timeLabel;
  final String myId;
  final AppPalette palette;
  final AppStrings s;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ChatTile({
    required this.chat,
    required this.otherUserId,
    required this.displayName,
    this.avatarUrl,
    required this.timeLabel,
    required this.myId,
    required this.palette,
    required this.s,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.trim().isNotEmpty;
    final isMeSender = chat.lastSenderId == myId;
    final isSeen = chat.isRead;
    final hasUnreadMessage = !isMeSender && !isSeen;
    final unreadColor = Colors.red.shade700;
    return Container(
      decoration: BoxDecoration(
        color: hasUnreadMessage
            ? Colors.red.withValues(alpha: palette.isDark ? 0.18 : 0.07)
            : palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasUnreadMessage
              ? unreadColor.withValues(alpha: 0.75)
              : palette.border.withValues(alpha: 0.6),
          width: hasUnreadMessage ? 1.4 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: palette.primary.withValues(alpha: 0.12),
          backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
          child: !hasAvatar
              ? Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S',
                  style: TextStyle(
                    color: palette.accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                displayName,
                style: TextStyle(
                  color: hasUnreadMessage ? unreadColor : palette.textPrimary,
                  fontWeight: hasUnreadMessage
                      ? FontWeight.w900
                      : FontWeight.w800,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (timeLabel.isNotEmpty)
              Text(
                timeLabel,
                style: TextStyle(
                  color: hasUnreadMessage
                      ? unreadColor
                      : palette.textSecondary.withValues(alpha: 0.6),
                  fontSize: 11.5,
                  fontWeight: hasUnreadMessage
                      ? FontWeight.w800
                      : FontWeight.normal,
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              if (isMeSender) ...[
                Icon(
                  isSeen ? Icons.done_all_rounded : Icons.check_rounded,
                  size: 16,
                  color: isSeen
                      ? Colors.blue
                      : palette.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  chat.lastMessage.isNotEmpty
                      ? chat.lastMessage
                      : (s.isKurdish
                            ? 'نامە...'
                            : s.isArabic
                            ? 'رسالة...'
                            : 'Message...'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasUnreadMessage
                        ? unreadColor
                        : palette.textSecondary,
                    fontSize: 13,
                    fontWeight: hasUnreadMessage
                        ? FontWeight.w800
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (hasUnreadMessage) ...[
                const SizedBox(width: 8),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: unreadColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: IconButton(
          tooltip: s.isKurdish
              ? 'سڕینەوەی چات'
              : s.isArabic
              ? 'حذف المحادثة'
              : 'Delete chat',
          icon: Icon(
            Icons.delete_outline_rounded,
            color: palette.textSecondary,
          ),
          onPressed: onDelete,
        ),
        onTap: onTap,
        onLongPress: onDelete,
      ),
    );
  }
}
