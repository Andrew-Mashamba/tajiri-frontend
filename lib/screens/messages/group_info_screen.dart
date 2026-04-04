// Group metadata and member tags (MESSAGES.md). Reuses profile group when conversation.groupId is set (MESSAGES_BACKEND_IMPLEMENTATION_DIRECTIVE).
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../models/message_models.dart';
import '../../services/message_service.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/user_avatar.dart';
import '../groups/group_detail_screen.dart';
import 'invite_link_screen.dart';

const Color _kBackground = Color(0xFFFAFAFA);
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);

/// Tag color mapping for custom member tags.
Color _tagColor(String tag) {
  switch (tag.toLowerCase()) {
    case 'moderator':
      return const Color(0xFF2196F3);
    case 'vip':
      return const Color(0xFFF59E0B);
    default:
      return _kSecondaryText;
  }
}

class GroupInfoScreen extends StatefulWidget {
  final Conversation conversation;
  final int currentUserId;

  const GroupInfoScreen({
    super.key,
    required this.conversation,
    required this.currentUserId,
  });

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  /// Local copy of participants so we can update tags without refetching.
  late List<ConversationParticipant> _members;
  late int _disappearingTimer;

  // Group safety settings
  bool _joinApprovalRequired = false;
  bool _contactsOnly = false;

  bool get _isCurrentUserAdmin {
    return widget.conversation.participants.any(
      (p) => p.userId == widget.currentUserId && p.isAdmin,
    );
  }

  @override
  void initState() {
    super.initState();
    _members = List.of(widget.conversation.participants);
    _disappearingTimer = widget.conversation.disappearingTimer ?? 0;
    _loadGroupSafetySettings();
  }

  Future<void> _loadGroupSafetySettings() async {
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) return;
      final resp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/conversations/${widget.conversation.id}/settings'),
        headers: ApiConfig.authHeaders(token),
      );
      if (resp.statusCode == 200 && mounted) {
        final data = jsonDecode(resp.body);
        setState(() {
          _joinApprovalRequired = data['join_approval_required'] == true;
          _contactsOnly = data['contacts_only'] == true;
        });
      }
    } catch (_) {
      // Settings not available, keep defaults
    }
  }

  Future<void> _updateGroupSafety(String key, bool value) async {
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) return;
      await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/conversations/${widget.conversation.id}/settings'),
        headers: {
          ...ApiConfig.authHeaders(token),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({key: value}),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imeshindwa kuhifadhi: $e')),
        );
      }
    }
  }

  String get _disappearingTimerLabel {
    if (_disappearingTimer <= 0) return 'Zima';
    if (_disappearingTimer <= 86400) return 'Saa 24';
    if (_disappearingTimer <= 604800) return 'Siku 7';
    return 'Siku 90';
  }

  void _showDisappearingTimerSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ujumbe unaopotea',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _kPrimaryText),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ujumbe mpya utapotea baada ya muda uliochaguliwa',
                style: TextStyle(fontSize: 13, color: _kSecondaryText),
              ),
              const SizedBox(height: 16),
              _buildTimerOption(ctx, 'Zima', 0),
              _buildTimerOption(ctx, 'Saa 24', 86400),
              _buildTimerOption(ctx, 'Siku 7', 604800),
              _buildTimerOption(ctx, 'Siku 90', 7776000),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerOption(BuildContext ctx, String label, int seconds) {
    final isSelected = _disappearingTimer == seconds;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          Navigator.pop(ctx);
          final timerValue = seconds == 0 ? null : seconds;
          final success = await MessageService.setDisappearingTimer(
            widget.conversation.id, widget.currentUserId, timerValue,
          );
          if (!mounted) return;
          if (success) {
            setState(() => _disappearingTimer = seconds);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(seconds == 0
                  ? 'Ujumbe unaopotea umezimwa'
                  : 'Ujumbe utapotea baada ya $label')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Imeshindikana kubadilisha muda wa ujumbe unaopotea'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: _kPrimaryText,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _kPrimaryText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setMemberTag(ConversationParticipant participant, String? tag) async {
    try {
      final url = '${ApiConfig.baseUrl}/conversations/${widget.conversation.id}/participants/${participant.userId}/tag';
      final resp = await http.put(
        Uri.parse(url),
        headers: ApiConfig.headers,
        body: jsonEncode({'tag': tag}),
      );
      if (resp.statusCode == 200 && mounted) {
        setState(() {
          final idx = _members.indexWhere((p) => p.userId == participant.userId);
          if (idx >= 0) {
            final old = _members[idx];
            _members[idx] = ConversationParticipant(
              id: old.id,
              conversationId: old.conversationId,
              userId: old.userId,
              isAdmin: old.isAdmin,
              lastReadAt: old.lastReadAt,
              unreadCount: old.unreadCount,
              isMuted: old.isMuted,
              user: old.user,
              isPinned: old.isPinned,
              isArchived: old.isArchived,
              mutedUntil: old.mutedUntil,
              isStarred: old.isStarred,
              tag: tag,
            );
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tag != null ? 'Tag updated to $tag' : 'Tag removed')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update tag'), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update tag'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showTagPicker(ConversationParticipant participant) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set member tag',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimaryText),
              ),
              const SizedBox(height: 16),
              _tagOption(ctx, participant, null, 'None'),
              _tagOption(ctx, participant, 'Moderator', 'Moderator'),
              _tagOption(ctx, participant, 'VIP', 'VIP'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tagOption(BuildContext ctx, ConversationParticipant participant, String? tagValue, String label) {
    final isSelected = participant.tag == tagValue;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(ctx);
          _setMemberTag(participant, tagValue);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _kPrimaryText),
                ),
              ),
              if (isSelected) const Icon(Icons.check, color: _kPrimaryText, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.conversation.isGroup) {
      return Scaffold(
        appBar: AppBar(title: const Text('Info')),
        body: const Center(child: Text('Not a group')),
      );
    }

    final name = widget.conversation.name ?? widget.conversation.title;
    final avatarUrl = widget.conversation.avatarUrl;
    const int maxParticipantsHint = 32;
    final hasLinkedGroup = widget.conversation.groupId != null;

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
                    '${_members.length} members • Up to $maxParticipantsHint in group calls',
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
                          groupId: widget.conversation.groupId!,
                          currentUserId: widget.currentUserId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('View full group'),
                ),
              ),
            ],
            // Invite link button (admin only)
            if (_isCurrentUserAdmin) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => showInviteLinkSheet(context, widget.conversation.id),
                  icon: const Icon(Icons.link_rounded, size: 18),
                  label: const Text('Kiungo cha mwaliko'),
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Disappearing messages section
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _isCurrentUserAdmin ? _showDisappearingTimerSheet : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.timer, size: 22, color: _kPrimaryText),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ujumbe unaopotea',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _kPrimaryText),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _disappearingTimerLabel,
                              style: const TextStyle(fontSize: 12, color: _kSecondaryText),
                            ),
                          ],
                        ),
                      ),
                      if (_isCurrentUserAdmin)
                        const Icon(Icons.chevron_right, size: 20, color: _kSecondaryText),
                    ],
                  ),
                ),
              ),
            ),
            if (!_isCurrentUserAdmin)
              const Padding(
                padding: EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  'Ni wasimamizi tu wanaweza kubadilisha muda',
                  style: TextStyle(fontSize: 11, color: _kSecondaryText),
                ),
              ),
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
            ..._members.map((p) {
              final isMe = p.userId == widget.currentUserId;
              final displayName = isMe ? 'You' : (p.user?.fullName ?? 'Member');
              return GestureDetector(
                onLongPress: _isCurrentUserAdmin && !isMe ? () => _showTagPicker(p) : null,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: isMe ? null : () => Navigator.pushNamed(context, '/profile/${p.userId}'),
                  leading: UserAvatar(
                    photoUrl: p.user?.profilePhotoUrl,
                    name: displayName,
                    radius: 24,
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 15,
                            color: _kPrimaryText,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (p.isAdmin) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _kSecondaryText.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Admin',
                            style: TextStyle(fontSize: 11, color: _kSecondaryText),
                          ),
                        ),
                      ],
                      if (p.tag != null && p.tag!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _tagColor(p.tag!).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            p.tag!,
                            style: TextStyle(fontSize: 11, color: _tagColor(p.tag!)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: isMe ? const Text('(You)', style: TextStyle(fontSize: 12, color: _kSecondaryText)) : null,
                ),
              );
            }),
            // Group safety section (admin only)
            if (_isCurrentUserAdmin) ...[
              const SizedBox(height: 28),
              const Text(
                'Usalama wa kikundi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimaryText,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Dhibiti nani anaweza kujiunga na kikundi',
                style: TextStyle(fontSize: 12, color: _kSecondaryText),
              ),
              const SizedBox(height: 12),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      title: const Text(
                        'Idhini ya kujiunga',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _kPrimaryText,
                        ),
                      ),
                      subtitle: const Text(
                        'Wanachama wapya wanahitaji idhini ya msimamizi',
                        style: TextStyle(fontSize: 12, color: _kSecondaryText),
                      ),
                      value: _joinApprovalRequired,
                      activeTrackColor: _kPrimaryText,
                      onChanged: (val) {
                        setState(() => _joinApprovalRequired = val);
                        _updateGroupSafety('join_approval_required', val);
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      title: const Text(
                        'Wasiliana tu',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _kPrimaryText,
                        ),
                      ),
                      subtitle: const Text(
                        'Ni mawasiliano ya wanachama tu wanaweza kuongezwa',
                        style: TextStyle(fontSize: 12, color: _kSecondaryText),
                      ),
                      value: _contactsOnly,
                      activeTrackColor: _kPrimaryText,
                      onChanged: (val) {
                        setState(() => _contactsOnly = val);
                        _updateGroupSafety('contacts_only', val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
