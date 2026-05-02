import 'package:flutter/material.dart';

import '../../../l10n/app_strings_scope.dart';
import '../../../models/privacy_settings_model.dart';
import '../../../services/privacy_service.dart';
import '_privacy_widgets.dart';

/// Connections — who can interact with you, plus block + close-friends lists.
class ConnectionsPrivacyScreen extends StatefulWidget {
  final int currentUserId;
  const ConnectionsPrivacyScreen({super.key, required this.currentUserId});

  @override
  State<ConnectionsPrivacyScreen> createState() => _ConnectionsPrivacyScreenState();
}

class _ConnectionsPrivacyScreenState extends State<ConnectionsPrivacyScreen> {
  final _service = PrivacyService();
  PrivacySettings _s = const PrivacySettings();
  List<BlockedUserItem> _blocked = const [];
  List<CloseFriendItem> _close = const [];
  bool _loading = true;
  String? _formError;
  final Set<String> _saving = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    final results = await Future.wait([
      _service.getPrivacySettings(widget.currentUserId),
      _service.blockedUsers(widget.currentUserId),
      _service.closeFriends(widget.currentUserId),
    ]);
    if (!mounted) return;
    final pr = results[0] as PrivacySettingsResult;
    setState(() {
      _loading = false;
      if (pr.success && pr.settings != null) {
        _s = pr.settings!;
      }
      _blocked = results[1] as List<BlockedUserItem>;
      _close = results[2] as List<CloseFriendItem>;
    });
  }

  Future<void> _saveField(String key, String value) async {
    final prev = _s;
    setState(() {
      _saving.add(key);
      _s = _s.copyWith({key: value});
      _formError = null;
    });
    final updated = await _service.patch(widget.currentUserId, {key: value});
    if (!mounted) return;
    setState(() {
      _saving.remove(key);
      if (updated == null) {
        _s = prev;
        _formError = 'save_failed';
      } else {
        _s = updated;
      }
    });
  }

  Future<void> _unblock(BlockedUserItem item) async {
    final ok = await _service.unblock(widget.currentUserId, item.blockedUserId);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _blocked = _blocked.where((b) => b.blockedUserId != item.blockedUserId).toList();
      });
    } else {
      setState(() => _formError = 'save_failed');
    }
  }

  Future<void> _removeClose(CloseFriendItem item) async {
    final ok = await _service.removeCloseFriend(widget.currentUserId, item.friendId);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _close = _close.where((c) => c.friendId != item.friendId).toList();
      });
    } else {
      setState(() => _formError = 'save_failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: kFaraghaBg,
        appBar: AppBar(
          title: Text(s?.faraghaCardConnections ?? 'Connections'),
          backgroundColor: kFaraghaCard,
          foregroundColor: kFaraghaPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: kFaraghaPrimary))
              : ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  children: [
                    FaraghaInlineErrorBanner(
                      message: _formError == 'save_failed'
                          ? (isSw ? 'Imeshindwa kuhifadhi' : 'Could not save change')
                          : null,
                      onDismiss: () => setState(() => _formError = null),
                      closeLabel: s?.close ?? 'Close',
                    ),

                    FaraghaSection(title: s?.privacySectionMessages ?? 'Messages'),
                    FaraghaAudienceTile(
                      icon: Icons.message_outlined,
                      title: s?.privacyWhoCanMessage ?? 'Who can message you',
                      value: _s.whoCanMessage,
                      saving: _saving.contains('who_can_message'),
                      allowedOptions: const ['everyone', 'friends', 'nobody'],
                      onChanged: (v) => _saveField('who_can_message', v),
                      isSwahili: isSw,
                    ),
                    FaraghaAudienceTile(
                      icon: Icons.call_outlined,
                      title: s?.faraghaWhoCanCall ?? 'Who can call you',
                      value: _s.whoCanCall,
                      saving: _saving.contains('who_can_call'),
                      allowedOptions: const ['everyone', 'friends', 'nobody'],
                      onChanged: (v) => _saveField('who_can_call', v),
                      isSwahili: isSw,
                    ),
                    FaraghaAudienceTile(
                      icon: Icons.group_add_outlined,
                      title: s?.faraghaWhoCanAddToGroups ?? 'Who can add you to groups',
                      value: _s.whoCanAddToGroups,
                      saving: _saving.contains('who_can_add_to_groups'),
                      allowedOptions: const ['everyone', 'friends', 'nobody'],
                      onChanged: (v) => _saveField('who_can_add_to_groups', v),
                      isSwahili: isSw,
                    ),
                    FaraghaAudienceTile(
                      icon: Icons.repeat_rounded,
                      title: s?.faraghaWhoCanResendStatus ?? 'Who can reshare your status',
                      value: _s.whoCanResendStatus,
                      saving: _saving.contains('who_can_resend_status'),
                      allowedOptions: const ['everyone', 'friends', 'nobody'],
                      onChanged: (v) => _saveField('who_can_resend_status', v),
                      isSwahili: isSw,
                    ),
                    FaraghaAudienceTile(
                      icon: Icons.feed_outlined,
                      title: s?.privacyWhoCanSeePosts ?? 'Who can see your posts',
                      value: _s.whoCanSeePosts,
                      saving: _saving.contains('who_can_see_posts'),
                      allowedOptions: const ['everyone', 'friends', 'only_me'],
                      onChanged: (v) => _saveField('who_can_see_posts', v),
                      isSwahili: isSw,
                    ),

                    FaraghaSection(title: s?.faraghaBlockedUsers ?? 'Blocked users'),
                    if (_blocked.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          s?.faraghaBlockedEmpty ?? 'You have not blocked anyone',
                          style: const TextStyle(fontSize: 12, color: kFaraghaSecondary),
                        ),
                      )
                    else
                      ..._blocked.map((b) => _userRow(
                            name: b.displayName,
                            username: b.username,
                            avatar: b.avatarPath,
                            actionLabel: s?.faraghaUnblock ?? 'Unblock',
                            onAction: () => _unblock(b),
                          )),

                    FaraghaSection(title: s?.faraghaCloseFriends ?? 'Close friends'),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Text(
                        s?.faraghaCloseFriendsSub ?? '',
                        style: const TextStyle(fontSize: 12, color: kFaraghaSecondary),
                      ),
                    ),
                    if (_close.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          s?.faraghaCloseFriendsEmpty ?? 'No close friends added yet',
                          style: const TextStyle(fontSize: 12, color: kFaraghaSecondary),
                        ),
                      )
                    else
                      ..._close.map((c) => _userRow(
                            name: c.displayName,
                            username: c.username,
                            avatar: c.avatarPath,
                            actionLabel: s?.faraghaRemove ?? 'Remove',
                            onAction: () => _removeClose(c),
                          )),
                    const SizedBox(height: 24),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _userRow({
    required String name,
    String? username,
    String? avatar,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: kFaraghaCard,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
            child: (avatar == null || avatar.isEmpty)
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: kFaraghaPrimary),
                  )
                : null,
          ),
          title: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kFaraghaPrimary,
            ),
          ),
          subtitle: username == null || username.isEmpty
              ? null
              : Text(
                  '@$username',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: kFaraghaSecondary),
                ),
          trailing: TextButton(
            onPressed: onAction,
            child: Text(actionLabel, style: const TextStyle(color: Colors.red)),
          ),
        ),
      ),
    );
  }
}
