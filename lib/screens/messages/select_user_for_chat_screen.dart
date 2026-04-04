import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/friend_models.dart';
import '../../services/friend_service.dart';
import '../../services/message_service.dart';
import '../../widgets/tajiri_app_bar.dart';
import '../../widgets/user_avatar.dart';
import '../../l10n/app_strings_scope.dart';

// DESIGN.md: background #FAFAFA, primary #1A1A1A, secondary #666666, 48dp touch, spacing 16
const Color _kBg = Color(0xFFFAFAFA);
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const double _kMinTouchHeight = 48.0;

/// New chat: search from the whole pool of people (GET /users/search). Tapping a user opens private chat.
/// Closing the chat returns to Chats (ConversationsScreen).
class SelectUserForChatScreen extends StatefulWidget {
  final int currentUserId;

  const SelectUserForChatScreen({super.key, required this.currentUserId});

  @override
  State<SelectUserForChatScreen> createState() => _SelectUserForChatScreenState();
}

class _SelectUserForChatScreenState extends State<SelectUserForChatScreen> {
  final FriendService _friendService = FriendService();
  final MessageService _messageService = MessageService();
  final TextEditingController _queryController = TextEditingController();
  Timer? _debounce;
  static const Duration _debounceDuration = Duration(milliseconds: 350);

  List<UserProfile> _results = [];
  bool _isLoading = false;
  String? _error;
  bool _hasSearched = false;
  bool _openingChat = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    setState(() {
      if (value.trim().isEmpty) {
        _results = [];
        _error = null;
        _hasSearched = false;
      }
    });
    if (value.trim().isEmpty) return;
    _debounce = Timer(_debounceDuration, () {
      if (mounted) _performSearch(_queryController.text.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _hasSearched = true;
    });

    try {
      final result = await _friendService.searchUsers(query);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _results = result.success ? result.friends : [];
        _error = result.success ? null : (result.message ?? 'Search failed');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _results = [];
        _error = 'Search failed: $e';
      });
    }
  }

  Future<void> _openChatWithUser(UserProfile user) async {
    if (_openingChat || user.id == widget.currentUserId) return;
    setState(() => _openingChat = true);

    try {
      final result = await _messageService.getPrivateConversation(
        widget.currentUserId,
        user.id,
      );

      if (!mounted) return;
      setState(() => _openingChat = false);
      if (result.success && result.conversation != null) {
        Navigator.pop(context, result.conversation);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Could not open chat')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _openingChat = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open chat: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Scaffold(
      backgroundColor: _kBg,
      appBar: TajiriAppBar(
        title: s?.newMessage ?? 'New message',
        automaticallyImplyLeading: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _queryController,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                hintText: s?.searchUsers ?? 'Search users',
                hintStyle: const TextStyle(color: _kSecondaryText, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: _kSecondaryText, size: 24),
                suffixIcon: _queryController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: _kSecondaryText),
                        onPressed: () {
                          _queryController.clear();
                          _onQueryChanged('');
                        },
                      )
                    : null,
                suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: const TextStyle(color: _kPrimaryText, fontSize: 14),
              maxLines: 1,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _kPrimaryText))
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: _kSecondaryText, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : !_hasSearched
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                s?.searchUsers ?? 'Search by name or username to start a chat',
                                style: const TextStyle(color: _kSecondaryText, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : _results.isEmpty
                            ? Center(
                                child: Text(
                                  s?.noResults ?? 'No users found',
                                  style: const TextStyle(color: _kSecondaryText, fontSize: 14),
                                ),
                              )
                            : _buildUserList(),
          ),
        ],
      ),
    );
  }

  List<UserProfile> get _usersExcludingSelf {
    return _results.where((u) => u.id != widget.currentUserId).toList();
  }

  Widget _buildUserList() {
    final users = _usersExcludingSelf;
    if (users.isEmpty) {
      return Center(
        child: Text(
          AppStringsScope.of(context)?.noResults ?? 'No users found',
          style: const TextStyle(color: _kSecondaryText, fontSize: 14),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openingChat ? null : () => _openChatWithUser(user),
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _kMinTouchHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    UserAvatar(
                      photoUrl: user.profilePhotoUrl,
                      name: user.fullName,
                      radius: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user.fullName,
                            style: const TextStyle(
                              color: _kPrimaryText,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (user.username != null && user.username!.isNotEmpty)
                            Text(
                              '@${user.username}',
                              style: const TextStyle(
                                color: _kSecondaryText,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (_openingChat)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimaryText),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
