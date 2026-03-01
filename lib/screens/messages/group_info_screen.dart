// Group metadata and member tags (MESSAGES.md). Reuses profile group when conversation.groupId is set (MESSAGES_BACKEND_IMPLEMENTATION_DIRECTIVE).
import 'package:flutter/material.dart';
import '../../models/message_models.dart';
import '../../widgets/user_avatar.dart';
import '../groups/group_detail_screen.dart';

const Color _kBackground = Color(0xFFFAFAFA);
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);

class GroupInfoScreen extends StatelessWidget {
  final Conversation conversation;
  final int currentUserId;

  const GroupInfoScreen({
    super.key,
    required this.conversation,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (!conversation.isGroup) {
      return Scaffold(
        appBar: AppBar(title: const Text('Info')),
        body: const Center(child: Text('Not a group')),
      );
    }

    final name = conversation.name ?? conversation.title;
    final avatarUrl = conversation.avatarUrl;
    final members = conversation.participants;
    const int maxParticipantsHint = 32;
    final hasLinkedGroup = conversation.groupId != null;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _kPrimaryText,
        title: const Text('Group info'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  UserAvatar(
                    photoUrl: avatarUrl,
                    name: name,
                    radius: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: _kPrimaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${members.length} members • Up to $maxParticipantsHint in group calls',
                    style: const TextStyle(fontSize: 13, color: _kSecondaryText),
                  ),
                ],
              ),
            ),
            if (hasLinkedGroup) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => GroupDetailScreen(
                          groupId: conversation.groupId!,
                          currentUserId: currentUserId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('View full group'),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Members',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kPrimaryText,
              ),
            ),
            const SizedBox(height: 12),
            ...members.map((p) {
              final isMe = p.userId == currentUserId;
              final displayName = isMe ? 'You' : (p.user?.fullName ?? 'Member');
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: UserAvatar(
                  photoUrl: p.user?.profilePhotoUrl,
                  name: displayName,
                  radius: 24,
                ),
                title: Row(
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        color: _kPrimaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (p.isAdmin) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kSecondaryText.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Admin',
                          style: TextStyle(fontSize: 11, color: _kSecondaryText),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: isMe ? const Text('(You)', style: TextStyle(fontSize: 12, color: _kSecondaryText)) : null,
              );
            }),
          ],
        ),
      ),
    );
  }
}
