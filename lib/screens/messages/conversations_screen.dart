import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:heroicons/heroicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/message_models.dart';
import '../../models/call_models.dart';
import '../../models/group_models.dart';
import '../../models/friend_models.dart';
import '../../services/message_service.dart';
import '../../services/pending_message_store.dart';
import '../../services/call_service.dart';
import '../../services/friend_service.dart';
import '../../services/live_update_service.dart';
import '../groups/create_group_screen.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/tajiri_app_bar.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/app_strings_scope.dart';
import '../calls/call_history_screen.dart' show OutgoingCallScreen;
import '../calls/outgoing_call_flow_screen.dart';
import '../../services/local_storage_service.dart';
import '../../models/ad_models.dart';
import '../../services/ad_service.dart';
import '../../widgets/conversation_ad_card.dart';

// Design: DOCS/DESIGN.md — #FAFAFA background, #1A1A1A primary text, 48dp min touch targets.
// Pill tabs pattern from Posts → Live (streams_screen.dart).
class ConversationsScreen extends StatefulWidget {
  final int currentUserId;
  /// 0 = Chats, 1 = Groups, 2 = Calls. When set, opens Messages with this tab selected.
  final int initialTabIndex;

  const ConversationsScreen({
    super.key,
    required this.currentUserId,
    this.initialTabIndex = 0,
  });

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

const String _prefFavorites = 'chat_favorites';
const String _prefArchived = 'chat_archived';
const String _prefFolders = 'chat_folders';
const String _prefPinned = 'chat_pinned';
const String _draftKeyPrefix = 'chat_draft_';
/// Max pinned chats (WhatsApp-style).
const int _kMaxPinned = 3;
/// Named folders for chat organisation (MESSAGES.md: chat folders).
const List<String> kChatFolderNames = ['Work', 'Friends', 'Personal'];

class _ConversationsScreenState extends State<ConversationsScreen>
    with SingleTickerProviderStateMixin {
  final MessageService _messageService = MessageService();
  final CallService _callService = CallService();
  final FriendService _friendService = FriendService();
  late TabController _tabController;
  StreamSubscription<LiveUpdateEvent>? _liveUpdateSubscription;

  List<Conversation> _conversations = [];
  /// When set, Groups tab uses this (from GET with type=group). Cleared on full reload.
  List<Conversation>? _groupConversationsFromApi;
  bool _isLoading = true;
  String? _error;

  List<CallLog> _callLogs = [];
  bool _callsLoading = true;

  Set<int> _favoriteIds = {};
  Set<int> _archivedIds = {};
  /// Pinned conversation IDs (order preserved, max _kMaxPinned).
  List<int> _pinnedIds = [];
  /// conversationId -> folder name (one of kChatFolderNames)
  Map<int, String> _folderByConversation = {};
  /// Draft text per conversation (from SharedPreferences).
  Map<int, String> _draftsByConversationId = {};
  /// Conversations where someone is typing (for "Typing..." in green).
  Set<int> _typingConversationIds = {};
  /// Conversations where someone is recording (for "Recording audio..." in green).
  Set<int> _recordingConversationIds = {};
  /// User marked as unread (local only; badge shows as unread).
  Set<int> _unreadOverride = {};
  /// Archived section expanded in Chats list.
  bool _archivedExpanded = false;
  Timer? _typingPollTimer;
  String _chatsFilter = 'all'; // all | favorites | archived | Work | Friends | Personal
  String _callsFilter = 'all'; // all | missed

  /// Ads served in the conversations list (inserted every N conversations, server-controlled).
  List<ServedAd> _conversationAds = [];
  int _conversationAdFrequency = 5; // default; overridden from server settings in initState

  /// Search: chats + Tajiri users (+ contacts when available). DESIGN.md: 48dp touch, smooth clear/cancel.
  final TextEditingController _searchController = TextEditingController();
  static const Duration _searchDebounce = Duration(milliseconds: 320);
  Timer? _searchDebounceTimer;
  String _searchQuery = '';
  List<UserProfile> _searchUsers = [];
  bool _searchUsersLoading = false;
  final FocusNode _searchFocusNode = FocusNode();

  /// Groups tab: search input and query (filter by group name / participants).
  final TextEditingController _groupSearchController = TextEditingController();
  String _groupSearchQuery = '';

  static const Color _background = Color(0xFFFAFAFA);
  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);
  static const Color _accent = Color(0xFF999999);
  static const Color _brandGreen = Color(0xFF25D366); // UX: brand reinforcement (1️⃣9️⃣) — unread badge, read tick, swipe
  static const double _touchTarget = 48.0;
  /// Indent for list separator so line does not run under avatar (avatar 56 + gap 12)
  static const double _separatorIndent = 68.0;

  @override
  void initState() {
    super.initState();
    final index = widget.initialTabIndex.clamp(0, 2);
    _tabController = TabController(length: 3, vsync: this, initialIndex: index);
    _lastTabIndex = index;
    _tabController.addListener(_onTabIndexChanged);
    _searchController.addListener(_onSearchChanged);
    _groupSearchController.addListener(() {
      if (mounted) setState(() => _groupSearchQuery = _groupSearchController.text.trim());
    });
    // Read server-controlled ad frequency (falls back to 5 if not cached)
    final adStorage = LocalStorageService.instanceSync;
    if (adStorage != null) {
      _conversationAdFrequency = adStorage.getAdFrequency('ad_conversations_frequency', 5);
    }
    _loadChatPrefs();
    _loadConversations();
    _loadCallHistory();
    _loadConversationAds();
    // Real-time: refresh chat list on push (new message, etc.) so list stays in sync without polling
    _liveUpdateSubscription = LiveUpdateService.instance.stream.listen((event) {
      if (event is MessagesUpdateEvent && mounted) _loadConversations();
    });
    PendingMessageStore.instance.addListener(_onPendingMessagesChanged);
    if (index == 0) _startTypingPoll();
  }

  void _onPendingMessagesChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    PendingMessageStore.instance.removeListener(_onPendingMessagesChanged);
    _typingPollTimer?.cancel();
    _searchDebounceTimer?.cancel();
    _tabController.removeListener(_onTabIndexChanged);
    _tabController.dispose();
    _searchController.dispose();
    _groupSearchController.dispose();
    _searchFocusNode.dispose();
    _liveUpdateSubscription?.cancel();
    super.dispose();
  }

  int? _lastTabIndex;

  void _startTypingPoll() {
    _typingPollTimer?.cancel();
    _typingPollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted || _tabController.index != 0) return;
      final ids = _filteredChatsPinnedFirst.take(5).map((c) => c.id).toList();
      if (ids.isEmpty) return;
      final Set<int> typing = {};
      final Set<int> recording = {};
      for (final id in ids) {
        final result = await _messageService.getTypingStatus(id, widget.currentUserId);
        if (result.success) {
          if (result.typingUsers.isNotEmpty) typing.add(id);
          if (result.recordingUsers.isNotEmpty) recording.add(id);
        }
      }
      if (mounted) setState(() {
        _typingConversationIds = typing;
        _recordingConversationIds = recording;
      });
    });
  }

  void _stopTypingPoll() {
    _typingPollTimer?.cancel();
    _typingPollTimer = null;
    if (mounted) setState(() {
      _typingConversationIds = {};
      _recordingConversationIds = {};
    });
  }

  void _onTabIndexChanged() {
    if (!_tabController.indexIsChanging && mounted) {
      final idx = _tabController.index;
      if (idx == 0) _startTypingPoll();
      else _stopTypingPoll();
      if (idx == 1 && _lastTabIndex != null && _lastTabIndex != 1) {
        _loadGroupConversations();
      }
      _lastTabIndex = idx;
    }
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim();
    _searchDebounceTimer?.cancel();
    setState(() => _searchQuery = q);
    if (q.isEmpty) {
      setState(() {
        _searchUsers = [];
        _searchUsersLoading = false;
      });
      return;
    }
    _searchDebounceTimer = Timer(_searchDebounce, () {
      if (!mounted) return;
      _performUserSearch(q);
    });
  }

  Future<void> _performUserSearch(String query) async {
    setState(() => _searchUsersLoading = true);
    final result = await _friendService.searchUsers(query, perPage: 15);
    if (!mounted) return;
    setState(() {
      _searchUsersLoading = false;
      _searchUsers = result.success ? result.friends : [];
    });
  }

  Future<void> _loadChatPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final fav = prefs.getString(_prefFavorites);
    final arch = prefs.getString(_prefArchived);
    final folders = prefs.getString(_prefFolders);
    final pinned = prefs.getString(_prefPinned);
    if (mounted) {
      setState(() {
        _favoriteIds = fav != null ? (jsonDecode(fav) as List).map((e) => (e as num).toInt()).toSet() : {};
        _archivedIds = arch != null ? (jsonDecode(arch) as List).map((e) => (e as num).toInt()).toSet() : {};
        _pinnedIds = pinned != null
            ? (jsonDecode(pinned) as List).map((e) => (e as num).toInt()).toList().take(_kMaxPinned).toList()
            : [];
        if (folders != null) {
          final decoded = jsonDecode(folders) as Map<String, dynamic>?;
          _folderByConversation = decoded?.map((k, v) => MapEntry(int.parse(k), v as String)) ?? {};
        } else {
          _folderByConversation = {};
        }
      });
    }
  }

  Future<void> _loadDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = _conversations.map((c) => c.id).toSet();
    final map = <int, String>{};
    for (final id in ids) {
      final v = prefs.getString('$_draftKeyPrefix$id');
      if (v != null && v.trim().isNotEmpty) map[id] = v.trim();
    }
    if (mounted) setState(() => _draftsByConversationId = map);
  }

  Future<void> _togglePin(int conversationId) async {
    if (_pinnedIds.contains(conversationId)) {
      _pinnedIds.remove(conversationId);
    } else {
      if (_pinnedIds.length >= _kMaxPinned) return;
      _pinnedIds.insert(0, conversationId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefPinned, jsonEncode(_pinnedIds));
    if (mounted) setState(() {});
  }

  void _markAsUnread(int conversationId) {
    setState(() => _unreadOverride.add(conversationId));
  }

  void _markAsRead(int conversationId) {
    _unreadOverride.remove(conversationId);
    _messageService.markAsRead(conversationId, widget.currentUserId);
    setState(() {});
  }

  Future<void> _setConversationFolder(int conversationId, String? folderName) async {
    if (folderName != null && folderName.isNotEmpty) {
      _folderByConversation[conversationId] = folderName;
    } else {
      _folderByConversation.remove(conversationId);
    }
    final prefs = await SharedPreferences.getInstance();
    final map = _folderByConversation.map((k, v) => MapEntry(k.toString(), v));
    await prefs.setString(_prefFolders, jsonEncode(map));
    if (mounted) setState(() {});
  }

  Future<void> _toggleFavorite(int conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    if (_favoriteIds.contains(conversationId)) {
      _favoriteIds.remove(conversationId);
    } else {
      _favoriteIds.add(conversationId);
    }
    await prefs.setString(_prefFavorites, jsonEncode(_favoriteIds.toList()));
    if (mounted) setState(() {});
  }

  Future<void> _toggleArchived(int conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    if (_archivedIds.contains(conversationId)) {
      _archivedIds.remove(conversationId);
    } else {
      _archivedIds.add(conversationId);
    }
    await prefs.setString(_prefArchived, jsonEncode(_archivedIds.toList()));
    if (mounted) setState(() {});
  }

  /// Fetch ads for the conversations list placement.
  Future<void> _loadConversationAds() async {
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      final ads = await AdService.getServedAds(token, 'conversations', 2);
      if (mounted && ads.isNotEmpty) {
        setState(() => _conversationAds = ads);
      }
    } catch (e) {
      debugPrint('[Messages] _loadConversationAds error: $e');
    }
  }

  void _recordAdImpression(ServedAd ad) async {
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    AdService.recordAdEvent(
      token, ad.campaignId, ad.creativeId,
      widget.currentUserId, 'conversations', 'impression',
    );
  }

  void _recordAdClick(ServedAd ad) async {
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    AdService.recordAdEvent(
      token, ad.campaignId, ad.creativeId,
      widget.currentUserId, 'conversations', 'click',
    );
  }

  Future<void> _loadConversations() async {
    if (!mounted) return;
    if (widget.currentUserId == 0) {
      setState(() {
        _isLoading = false;
        _error = 'Please sign in to see your conversations';
      });
      return;
    }
    if (kDebugMode) debugPrint('[Messages] Chats tab: loading all conversations (GET /conversations?user_id=${widget.currentUserId}&include_groups=1)');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _messageService.getConversations(
      userId: widget.currentUserId,
      perPage: 100,
    );

    if (!mounted) return;
    if (kDebugMode) {
      debugPrint('[Messages] Chats tab: response success=${result.success}, count=${result.conversations.length}${result.message != null ? ', message=${result.message}' : ''}');
    }
    setState(() {
      _isLoading = false;
      _groupConversationsFromApi = null;
      if (result.success) {
        final list = result.conversations;
        list.sort((a, b) {
          final aAt = a.lastMessageAt ?? a.updatedAt;
          final bAt = b.lastMessageAt ?? b.updatedAt;
          return bAt.compareTo(aAt);
        });
        _conversations = list;
      } else {
        _error = result.message;
      }
    });
    _loadDrafts();
  }

  /// Fetch only group conversations for the Groups tab (optional optimization).
  Future<void> _loadGroupConversations() async {
    if (!mounted || widget.currentUserId == 0) return;
    if (kDebugMode) debugPrint('[Messages] Groups tab: loading group conversations (GET /conversations?user_id=${widget.currentUserId}&type=group)');
    final result = await _messageService.getConversations(
      userId: widget.currentUserId,
      type: 'group',
    );
    if (!mounted) return;
    if (kDebugMode) {
      debugPrint('[Messages] Groups tab: response success=${result.success}, count=${result.conversations.length}${result.message != null ? ', message=${result.message}' : ''}');
    }
    if (result.success) {
      final list = result.conversations;
      list.sort((a, b) {
        final aAt = a.lastMessageAt ?? a.updatedAt;
        final bAt = b.lastMessageAt ?? b.updatedAt;
        return bAt.compareTo(aAt);
      });
      setState(() => _groupConversationsFromApi = list);
    }
  }

  Future<void> _loadCallHistory() async {
    if (!mounted) return;
    setState(() => _callsLoading = true);

    final result = await _callService.getCallHistory(
      userId: widget.currentUserId,
      perPage: 50,
    );

    if (!mounted) return;
    setState(() {
      _callsLoading = false;
      _callLogs = result.success ? result.logs : [];
    });
  }

  void _openChat(Conversation conversation) {
    _unreadOverride.remove(conversation.id);
    Navigator.pushNamed(
      context,
      '/chat/${conversation.id}',
      arguments: conversation,
    ).then((_) {
      if (mounted) _loadDrafts();
    });
  }

  /// Create group via GroupService (reuse profile groups per MESSAGES_BACKEND_IMPLEMENTATION_DIRECTIVE). On success, open its chat if backend returned conversation_id.
  Future<void> _openCreateGroup() async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute<dynamic>(
        builder: (_) => CreateGroupScreen(creatorId: widget.currentUserId),
      ),
    );
    if (!mounted) return;
    if (result is Group && result.conversationId != null) {
      final res = await _messageService.getConversation(result.conversationId!, widget.currentUserId);
      if (mounted && res.success && res.conversation != null) {
        _openChat(res.conversation!);
      } else {
        _loadConversations();
      }
    } else if (result == true || result is Group) {
      _loadConversations();
    }
  }

  void _createNewConversation() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(AppStringsScope.of(context)?.newMessage ?? 'New message'),
              onTap: () {
                Navigator.pop(context);
                _selectUserForChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: Text(AppStringsScope.of(context)?.createGroup ?? 'Create group'),
              onTap: () {
                Navigator.pop(context);
                _openCreateGroup();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectUserForChat() async {
    final result = await Navigator.pushNamed(context, '/select-user-chat');
    if (!mounted) return;
    if (result is Conversation) {
      Navigator.pushNamed(
        context,
        '/chat/${result.id}',
        arguments: <String, dynamic>{'conversation': result},
      );
    }
  }

  void _showCallOptions(CallLog call) {
    final s = AppStringsScope.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: UserAvatar(
                photoUrl: call.otherUser?.avatarUrl,
                name: call.otherUser?.displayName,
                radius: 24,
              ),
              title: Text(
                call.otherUser?.displayName ?? (s?.userLabel ?? 'User'),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(color: _primaryText),
              ),
              subtitle: Text(
                _formatCallTime(call.callTime),
                style: const TextStyle(color: _secondaryText, fontSize: 12),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _primaryText,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.call, color: Colors.white, size: 24),
              ),
              title: Text(s?.call ?? 'Call'),
              onTap: () {
                Navigator.pop(context);
                if (call.otherUserId != null) {
                  _initiateCall(
                    call.otherUserId!,
                    'voice',
                    calleeName: call.otherUser?.displayName,
                    calleeAvatarUrl: call.otherUser?.avatarUrl,
                  );
                }
              },
            ),
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _primaryText,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 24),
              ),
              title: Text(s?.video ?? 'Video'),
              onTap: () {
                Navigator.pop(context);
                if (call.otherUserId != null) {
                  _initiateCall(
                    call.otherUserId!,
                    'video',
                    calleeName: call.otherUser?.displayName,
                    calleeAvatarUrl: call.otherUser?.avatarUrl,
                  );
                }
              },
            ),
            if (call.wasMissed && call.otherUserId != null)
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _primaryText.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.mic_rounded, color: _primaryText, size: 24),
                ),
                title: Text(s?.voiceMessage ?? 'Send voice note'),
                onTap: () {
                  Navigator.pop(context);
                  _openChatWithVoiceNote(call.otherUserId!);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openChatWithVoiceNote(int otherUserId) async {
    final result = await _messageService.getPrivateConversation(
      widget.currentUserId,
      otherUserId,
    );
    if (!mounted) return;
    if (!result.success || result.conversation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Could not open chat')),
      );
      return;
    }
    final conv = result.conversation!;
    Navigator.pushNamed(
      context,
      '/chat/${conv.id}',
      arguments: <String, dynamic>{
        'conversation': conv,
        'promptAfterCall': 'voice',
      },
    );
  }

  /// Starts 1:1 call. Uses new flow (OutgoingCallFlowScreen) when authToken exists.
  Future<void> _initiateCall(
    int calleeId,
    String type, {
    String? calleeName,
    String? calleeAvatarUrl,
  }) async {
    final storage = await LocalStorageService.getInstance();
    final authToken = storage.getAuthToken();
    final name = calleeName ?? 'User';
    final avatar = calleeAvatarUrl;

    if (authToken != null && authToken.isNotEmpty && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => OutgoingCallFlowScreen(
            currentUserId: widget.currentUserId,
            authToken: authToken,
            calleeId: calleeId,
            calleeName: name,
            calleeAvatarUrl: avatar,
            type: type,
          ),
        ),
      ).then((_) {
        if (mounted) _loadCallHistory();
      });
      return;
    }

    final result = await _callService.initiateCall(
      userId: widget.currentUserId,
      calleeId: calleeId,
      type: type,
    );

    if (result.success && result.call != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => OutgoingCallScreen(
            currentUserId: widget.currentUserId,
            call: result.call!,
          ),
        ),
      ).then((_) {
        if (mounted) _loadCallHistory();
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Call failed')),
      );
    }
  }

  String _formatCallTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays == 0) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.day}/${time.month}';
  }

  List<Conversation> get _privateConversations =>
      _conversations.where((c) => !c.isGroup).toList();

  List<Conversation> get _groupConversations =>
      (_groupConversationsFromApi ?? _conversations.where((c) => c.isGroup).toList());

  /// Groups tab: filter by search query (group title or participant names).
  List<Conversation> get _filteredGroupConversations {
    if (_groupSearchQuery.isEmpty) return _groupConversations;
    final q = _groupSearchQuery.toLowerCase();
    return _groupConversations.where((c) {
      if (c.title.toLowerCase().contains(q)) return true;
      for (final p in c.participants) {
        final name = p.user?.firstName ?? '';
        final last = p.user?.lastName ?? '';
        final uname = p.user?.username ?? '';
        if (name.toLowerCase().contains(q) ||
            last.toLowerCase().contains(q) ||
            '$name $last'.toLowerCase().contains(q) ||
            uname.toLowerCase().contains(q)) return true;
      }
      return false;
    }).toList();
  }

  /// Folder pills (Work, Friends, Personal) only show when at least one chat is in that folder.
  List<String> get _activeFolderNames =>
      kChatFolderNames.where((f) => _folderByConversation.values.contains(f)).toList();

  List<Conversation> get _filteredChats {
    final list = _privateConversations;
    if (_chatsFilter == 'favorites') return list.where((c) => _favoriteIds.contains(c.id)).toList();
    if (_chatsFilter == 'archived') return list.where((c) => _archivedIds.contains(c.id)).toList();
    if (kChatFolderNames.contains(_chatsFilter)) return list.where((c) => _folderByConversation[c.id] == _chatsFilter).toList();
    return list.where((c) => !_archivedIds.contains(c.id)).toList();
  }

  /// Chats list with pinned first (order preserved), then rest by last activity.
  List<Conversation> get _filteredChatsPinnedFirst {
    final list = _filteredChats;
    if (list.isEmpty) return list;
    final pinned = _pinnedIds.where((id) => list.any((c) => c.id == id)).toList();
    final rest = list.where((c) => !_pinnedIds.contains(c.id)).toList();
    final order = <Conversation>[];
    for (final id in pinned) {
      final c = list.cast<Conversation?>().firstWhere((x) => x?.id == id, orElse: () => null);
      if (c != null) order.add(c);
    }
    order.addAll(rest);
    return order;
  }

  /// Archived private chats (for collapsed "Archived" section).
  List<Conversation> get _archivedChats =>
      _privateConversations.where((c) => _archivedIds.contains(c.id)).toList();

  /// Chats matching search query (title or participant names). Used when _searchQuery is not empty.
  List<Conversation> get _searchFilteredChats {
    if (_searchQuery.isEmpty) return _filteredChats;
    final q = _searchQuery.toLowerCase();
    return _filteredChats.where((c) {
      if (c.title.toLowerCase().contains(q)) return true;
      for (final p in c.participants) {
        final name = p.user?.firstName ?? '';
        final last = p.user?.lastName ?? '';
        final uname = p.user?.username ?? '';
        if (name.toLowerCase().contains(q) ||
            last.toLowerCase().contains(q) ||
            '$name $last'.toLowerCase().contains(q) ||
            uname.toLowerCase().contains(q)) return true;
      }
      return false;
    }).toList();
  }

  List<CallLog> get _filteredCalls {
    if (_callsFilter == 'missed') return _callLogs.where((c) => c.wasMissed).toList();
    return _callLogs;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final labels = [
      s?.chats ?? 'Chats',
      s?.groups ?? 'Groups',
      s?.calls ?? 'Calls',
    ];
    return Scaffold(
      backgroundColor: _background,
      appBar: TajiriAppBar(
        title: s?.messages ?? 'Messages',
        automaticallyImplyLeading: false,
        actions: [
          TajiriAppBar.action(
            icon: HeroIcons.magnifyingGlass,
            onPressed: () => Navigator.pushNamed(context, '/search-conversations'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _MessagesTabSegments(
                controller: _tabController,
                labels: labels,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildChatsBody(s),
            _buildGroupsBody(s),
            _buildCallsBody(s),
          ],
        ),
      ),
    );
  }

  Widget _buildChatsBody(AppStrings? s) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _primaryText));
    }
    if (_error != null) return _buildErrorState(s);
    // If selected filter is no longer visible, show default list
    if ((kChatFolderNames.contains(_chatsFilter) && !_activeFolderNames.contains(_chatsFilter)) ||
        _chatsFilter == 'favorites' ||
        _chatsFilter == 'archived') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _chatsFilter = 'all');
      });
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchBar(s),
        if (_searchQuery.isEmpty) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(0, 1, 16, 4),
            child: Row(
              children: [
                ..._activeFolderNames.map((f) => Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: _filterChip(f, _chatsFilter == f, () => setState(() => _chatsFilter = f)),
                )),
              ],
            ),
          ),
        ],
        Expanded(
          child: _searchQuery.isEmpty
              ? _buildChatsList(s)
              : _buildSearchResults(s),
        ),
      ],
    );
  }

  /// DESIGN.md: surface #FFFFFF, borderRadius 12, 48dp touch, primaryText/secondaryText.
  Widget _buildSearchBar(AppStrings? s) {
    final hasText = _searchController.text.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _primaryText.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  color: _primaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: s?.searchUsers ?? 'Search chats and people',
                  hintStyle: const TextStyle(color: _secondaryText, fontSize: 14),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(Icons.search_rounded, color: _secondaryText, size: 22),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: _touchTarget),
                  suffixIcon: hasText
                      ? Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _searchUsers = [];
                              });
                            },
                            borderRadius: BorderRadius.circular(24),
                            child: const SizedBox(
                              width: _touchTarget,
                              height: _touchTarget,
                              child: Icon(Icons.clear_rounded, color: _secondaryText, size: 20),
                            ),
                          ),
                        )
                      : null,
                  suffixIconConstraints: const BoxConstraints(minWidth: _touchTarget, minHeight: _touchTarget),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                ),
                maxLines: 1,
              ),
            ),
          ),
          if (hasText) ...[
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _searchController.clear();
                  _searchFocusNode.unfocus();
                  setState(() {
                    _searchQuery = '';
                    _searchUsers = [];
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: _touchTarget, minHeight: _touchTarget),
                    child: Center(
                      child: Text(
                        s?.cancel ?? 'Cancel',
                        style: const TextStyle(
                          color: _primaryText,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Chats list: virtualized (ListView.builder) so only visible rows render — optimized for 1,000+ chats.
  /// Real-time: list refreshes on push via _liveUpdateSubscription (MessagesUpdateEvent).
  Widget _buildChatsList(AppStrings? s) {
    final list = _filteredChatsPinnedFirst;
    final archived = _archivedChats;
    final hasMain = list.isNotEmpty;
    final hasArchived = archived.isNotEmpty;
    if (!hasMain && !hasArchived) {
      return RefreshIndicator(
        onRefresh: _loadConversations,
        color: _primaryText,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: _buildEmptyChats(s),
          ),
        ),
      );
    }

    // Single virtualized list: main tiles + ad slots, then divider + archived header, then (if expanded) archived tiles
    const double _cacheExtent = 400; // Pre-render ~5–6 rows off-screen for smooth scroll
    // Insert an ad after every _conversationAdFrequency conversations
    final int adStride = _conversationAdFrequency + 1; // stride = freq + 1 ad slot
    final int adSlots = _conversationAds.isNotEmpty ? (list.length ~/ _conversationAdFrequency) : 0;
    final int mainSectionCount = list.length + adSlots;
    final int archivedSectionCount = hasArchived ? 2 + (_archivedExpanded ? archived.length : 0) : 0;
    final int itemCount = mainSectionCount + archivedSectionCount;

    return RefreshIndicator(
      onRefresh: _loadConversations,
      color: _primaryText,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 1, 16, 4),
        itemCount: itemCount,
        cacheExtent: _cacheExtent,
        itemBuilder: (context, index) {
          if (index < mainSectionCount) {
            // Check if this index is an ad slot (every adStride-th item)
            if (_conversationAds.isNotEmpty && index > 0 && (index + 1) % adStride == 0) {
              final adIndex = ((index + 1) ~/ adStride - 1) % _conversationAds.length;
              final ad = _conversationAds[adIndex];
              return ConversationAdCard(
                servedAd: ad,
                onImpression: () => _recordAdImpression(ad),
                onClick: () => _recordAdClick(ad),
              );
            }
            // Map visual index back to conversation index (subtract ad slots before this index)
            final adsBefore = _conversationAds.isNotEmpty ? ((index + 1) ~/ adStride) : 0;
            final convIndex = index - adsBefore;
            if (convIndex >= list.length) return const SizedBox.shrink();
            final tile = _wrapSlidable(list[convIndex], s, showFavoriteArchive: false);
            final isLastConv = convIndex == list.length - 1;
            if (isLastConv) return tile;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                tile,
                Padding(
                  padding: const EdgeInsets.only(left: _separatorIndent),
                  child: const Divider(height: 1, thickness: 1),
                ),
              ],
            );
          }
          final archivedBaseIndex = mainSectionCount;
          if (hasArchived && index == archivedBaseIndex) {
            return const Divider(height: 1);
          }
          if (hasArchived && index == archivedBaseIndex + 1) {
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _archivedExpanded = !_archivedExpanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                  child: Row(
                    children: [
                      Icon(
                        _archivedExpanded ? Icons.expand_less : Icons.expand_more,
                        color: _secondaryText,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${s?.archived ?? 'Archived'} (${archived.length})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          if (_archivedExpanded && index < archivedBaseIndex + 2 + archived.length) {
            final tile = _wrapSlidable(archived[index - archivedBaseIndex - 2], s, showFavoriteArchive: false);
            final showSeparator = index < archivedBaseIndex + 2 + archived.length - 1;
            if (!showSeparator) return tile;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                tile,
                Padding(
                  padding: const EdgeInsets.only(left: _separatorIndent),
                  child: const Divider(height: 1, thickness: 1),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSearchResults(AppStrings? s) {
    final chatList = _searchFilteredChats;
    final users = _searchUsers.where((u) => u.id != widget.currentUserId).toList();
    final hasChats = chatList.isNotEmpty;
    final hasUsers = users.isNotEmpty;
    final loading = _searchUsersLoading && users.isEmpty;

    if (!hasChats && !hasUsers && !loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: _accent),
            const SizedBox(height: 16),
            Text(
              s?.noResults ?? 'No results',
              style: const TextStyle(fontSize: 15, color: _secondaryText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 1, 16, 4),
      children: [
        if (hasChats) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              s?.chats ?? 'Chats',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _secondaryText,
              ),
            ),
          ),
          ...chatList.map((c) => _wrapSlidable(c, s, showFavoriteArchive: false)),
          const SizedBox(height: 16),
        ],
        if (hasUsers || loading) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              s?.searchUsers ?? 'People',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _secondaryText,
              ),
            ),
          ),
          if (loading && users.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(color: _primaryText)),
            )
          else
            ...users.map((u) => _UserSearchTile(
              user: u,
              onTap: () => _openChatWithUser(u),
            )),
        ],
      ],
    );
  }

  Future<void> _openChatWithUser(UserProfile user) async {
    final result = await _messageService.getPrivateConversation(widget.currentUserId, user.id);
    if (!mounted) return;
    if (result.success && result.conversation != null) {
      _searchController.clear();
      _searchFocusNode.unfocus();
      setState(() {
        _searchQuery = '';
        _searchUsers = [];
      });
      Navigator.pushNamed(
        context,
        '/chat/${result.conversation!.id}',
        arguments: <String, dynamic>{'conversation': result.conversation},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Could not open chat')),
      );
    }
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: _accent.withOpacity(0.2),
      selectedColor: _primaryText.withOpacity(0.2),
    );
  }

  Widget _buildGroupsBody(AppStrings? s) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _primaryText));
    }
    if (_error != null) return _buildErrorState(s);
    final list = _filteredGroupConversations;
    final hasSearch = _groupSearchQuery.isNotEmpty;
    final noGroupsAtAll = _groupConversations.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildGroupsSearchBar(s),
        Expanded(
          child: list.isEmpty
              ? (noGroupsAtAll
                  ? _buildEmptyGroups(s)
                  : _buildEmptySearchResults(s))
              : _conversationList(list, s, showFavoriteArchive: false),
        ),
      ],
    );
  }

  Widget _buildEmptySearchResults(AppStrings? s) {
    return Center(
      child: Text(
        s?.noResults ?? 'No groups match your search',
        style: const TextStyle(fontSize: 16, color: _secondaryText),
      ),
    );
  }

  /// Groups tab: search bar (same style as Chats) with Create group icon on the right.
  Widget _buildGroupsSearchBar(AppStrings? s) {
    final hasText = _groupSearchController.text.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _primaryText.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _groupSearchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  color: _primaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: s?.searchGroups ?? 'Search groups',
                  hintStyle: const TextStyle(color: _secondaryText, fontSize: 14),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(Icons.search_rounded, color: _secondaryText, size: 22),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: _touchTarget),
                  suffixIcon: hasText
                      ? Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              _groupSearchController.clear();
                              setState(() => _groupSearchQuery = '');
                            },
                            borderRadius: BorderRadius.circular(24),
                            child: const SizedBox(
                              width: _touchTarget,
                              height: _touchTarget,
                              child: Icon(Icons.clear_rounded, color: _secondaryText, size: 20),
                            ),
                          ),
                        )
                      : null,
                  suffixIconConstraints: const BoxConstraints(minWidth: _touchTarget, minHeight: _touchTarget),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                ),
                maxLines: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openCreateGroup,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryText.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: HeroIcon(HeroIcons.userPlus, style: HeroIconStyle.outline, color: _primaryText, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallsBody(AppStrings? s) {
    if (_callsLoading) {
      return const Center(child: CircularProgressIndicator(color: _primaryText));
    }
    final list = _filteredCalls;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(0, 1, 16, 4),
          child: Row(
            children: [
              _filterChip('All', _callsFilter == 'all', () => setState(() => _callsFilter = 'all')),
              const SizedBox(width: 8),
              _filterChip('Missed', _callsFilter == 'missed', () => setState(() => _callsFilter = 'missed')),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? _buildEmptyCalls(s)
              : RefreshIndicator(
                  onRefresh: _loadCallHistory,
                  color: _primaryText,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(0, 1, 16, 4),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final call = list[index];
                      return _CallLogTile(
                        callLog: call,
                        onTap: () => _showCallOptions(call),
                        onCall: () {
                          if (call.otherUserId != null) {
                            _initiateCall(
                              call.otherUserId!,
                              call.type,
                              calleeName: call.otherUser?.displayName,
                              calleeAvatarUrl: call.otherUser?.avatarUrl,
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildErrorState(AppStrings? s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: _secondaryText, fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _loadConversations,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _primaryText,
                  elevation: 2,
                ),
                child: Text(s?.retry ?? 'Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChats(AppStrings? s) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 64, color: _accent),
          const SizedBox(height: 16),
          Text(
            s?.noConversations ?? 'No conversations',
            style: const TextStyle(fontSize: 16, color: _primaryText),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            s?.startNewConversation ?? 'Start new conversations',
            style: const TextStyle(fontSize: 12, color: _secondaryText),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGroups(AppStrings? s) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_outlined, size: 64, color: _accent),
          const SizedBox(height: 16),
          Text(
            s?.noGroups ?? 'No groups',
            style: const TextStyle(fontSize: 16, color: _primaryText),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            s?.createGroup ?? 'Create group',
            style: const TextStyle(fontSize: 12, color: _secondaryText),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCalls(AppStrings? s) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.call_outlined, size: 64, color: _accent),
          const SizedBox(height: 16),
          Text(
            s?.noCalls ?? 'No calls',
            style: const TextStyle(fontSize: 16, color: _primaryText),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSlidableChatTiles(List<Conversation> list, AppStrings? s, {bool showFavoriteArchive = false}) {
    return [
      for (int i = 0; i < list.length; i++) ...[
        if (i > 0) const Divider(height: 1),
        _wrapSlidable(list[i], s, showFavoriteArchive: showFavoriteArchive),
      ],
    ];
  }

  Widget _wrapSlidable(Conversation conversation, AppStrings? s, {bool showFavoriteArchive = false}) {
    final s0 = AppStringsScope.of(context);
    final isArchived = _archivedIds.contains(conversation.id);
    final effectiveUnread = _unreadOverride.contains(conversation.id)
        ? (conversation.unreadCount > 0 ? conversation.unreadCount : 1)
        : conversation.unreadCount;
    return Slidable(
      key: ValueKey(conversation.id),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) {
              if (effectiveUnread > 0) {
                _markAsRead(conversation.id);
              } else {
                _markAsUnread(conversation.id);
              }
            },
            backgroundColor: _brandGreen,
            foregroundColor: Colors.white,
            icon: effectiveUnread > 0 ? Icons.done_all : Icons.mark_email_unread_rounded,
            label: effectiveUnread > 0 ? (s0?.markAsRead ?? 'Read') : (s0?.markUnread ?? 'Unread'),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.75,
        children: [
          SlidableAction(
            onPressed: (_) => _toggleArchived(conversation.id),
            backgroundColor: const Color(0xFF9E9E9E),
            foregroundColor: Colors.white,
            icon: isArchived ? Icons.unarchive_rounded : Icons.archive_rounded,
            label: isArchived ? (s0?.unarchive ?? 'Unarchive') : (s0?.archive ?? 'Archive'),
          ),
          SlidableAction(
            onPressed: (_) => _showConversationMoreSheet(conversation),
            backgroundColor: const Color(0xFF757575),
            foregroundColor: Colors.white,
            icon: Icons.more_horiz_rounded,
            label: s0?.more ?? 'More',
          ),
          SlidableAction(
            onPressed: (_) => _confirmLeaveOrDeleteChat(conversation),
            backgroundColor: const Color(0xFFB00020),
            foregroundColor: Colors.white,
            icon: Icons.delete_outline_rounded,
            label: conversation.isGroup ? (s0?.leaveChat ?? 'Leave') : (s0?.delete ?? 'Delete'),
          ),
        ],
      ),
      child: _ConversationTile(
        conversation: conversation,
        currentUserId: widget.currentUserId,
        onTap: () => _openChat(conversation),
        isFavorite: _favoriteIds.contains(conversation.id),
        isArchived: isArchived,
        isPinned: _pinnedIds.contains(conversation.id),
        folderName: _folderByConversation[conversation.id],
        draftText: _draftsByConversationId[conversation.id],
        isTyping: _typingConversationIds.contains(conversation.id),
        isRecording: _recordingConversationIds.contains(conversation.id),
        pendingPreview: PendingMessageStore.instance.getPending(conversation.id)?.preview,
        isSending: PendingMessageStore.instance.hasPending(conversation.id),
        effectiveUnreadCount: effectiveUnread,
        onToggleFavorite: showFavoriteArchive ? () => _toggleFavorite(conversation.id) : null,
        onToggleArchived: showFavoriteArchive ? () => _toggleArchived(conversation.id) : null,
        onAssignFolder: showFavoriteArchive ? (name) => _setConversationFolder(conversation.id, name) : null,
      ),
    );
  }

  void _showConversationMoreSheet(Conversation conversation) {
    final s0 = AppStringsScope.of(context);
    final isPinned = _pinnedIds.contains(conversation.id);
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined),
              title: Text(isPinned ? (s0?.unpin ?? 'Unpin') : (s0?.pin ?? 'Pin')),
              onTap: () {
                Navigator.pop(ctx);
                _togglePin(conversation.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(s0?.moveToFolder ?? 'Move to folder'),
              onTap: () {
                Navigator.pop(ctx);
                _showFolderMenuForConversation(conversation.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFolderMenuForConversation(int conversationId) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Move to folder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            ListTile(
              title: const Text('No folder'),
              onTap: () {
                _setConversationFolder(conversationId, null);
                Navigator.pop(ctx);
              },
            ),
            ...kChatFolderNames.map((f) => ListTile(
              title: Text(f),
              onTap: () {
                _setConversationFolder(conversationId, f);
                Navigator.pop(ctx);
              },
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLeaveOrDeleteChat(Conversation conversation) async {
    final s0 = AppStringsScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(conversation.isGroup ? (s0?.leaveChat ?? 'Leave chat') : (s0?.delete ?? 'Delete')),
        content: Text(
          conversation.isGroup
              ? (s0?.leaveChatConfirm ?? 'Leave this conversation?')
              : (s0?.leaveChatConfirm ?? 'Delete this chat?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s0?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s0?.delete ?? 'Leave', style: const TextStyle(color: Color(0xFFB00020))),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await _messageService.leaveConversation(conversation.id, widget.currentUserId);
    if (mounted) {
      if (ok) {
        _archivedIds.remove(conversation.id);
        _conversations.removeWhere((c) => c.id == conversation.id);
        setState(() {});
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Done' : (s0?.error ?? 'Failed'))),
      );
    }
  }

  /// Groups list: virtualized (ListView.separated) + cacheExtent; thin separator indented so it doesn't run under avatar.
  Widget _conversationList(List<Conversation> list, AppStrings? s, {bool showFavoriteArchive = false}) {
    return RefreshIndicator(
      onRefresh: _loadConversations,
      color: _primaryText,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(0, 1, 16, 4),
        itemCount: list.length,
        cacheExtent: 400,
        separatorBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(left: _separatorIndent),
          child: const Divider(height: 1, thickness: 1),
        ),
        itemBuilder: (context, index) {
          final conversation = list[index];
          final effectiveUnread = _unreadOverride.contains(conversation.id)
              ? (conversation.unreadCount > 0 ? conversation.unreadCount : 1)
              : conversation.unreadCount;
          return Slidable(
            key: ValueKey(conversation.id),
            startActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.25,
              children: [
                SlidableAction(
                  onPressed: (_) {
                    if (effectiveUnread > 0) _markAsRead(conversation.id);
                    else _markAsUnread(conversation.id);
                  },
                  backgroundColor: _brandGreen,
                  foregroundColor: Colors.white,
                  icon: effectiveUnread > 0 ? Icons.done_all : Icons.mark_email_unread_rounded,
                  label: effectiveUnread > 0 ? (s?.markAsRead ?? 'Read') : (s?.markUnread ?? 'Unread'),
                ),
              ],
            ),
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.75,
              children: [
                SlidableAction(
                  onPressed: (_) => _toggleArchived(conversation.id),
                  backgroundColor: const Color(0xFF9E9E9E),
                  foregroundColor: Colors.white,
                  icon: _archivedIds.contains(conversation.id) ? Icons.unarchive_rounded : Icons.archive_rounded,
                  label: _archivedIds.contains(conversation.id) ? (s?.unarchive ?? 'Unarchive') : (s?.archive ?? 'Archive'),
                ),
                SlidableAction(
                  onPressed: (_) => _showConversationMoreSheet(conversation),
                  backgroundColor: const Color(0xFF757575),
                  foregroundColor: Colors.white,
                  icon: Icons.more_horiz_rounded,
                  label: s?.more ?? 'More',
                ),
                SlidableAction(
                  onPressed: (_) => _confirmLeaveOrDeleteChat(conversation),
                  backgroundColor: const Color(0xFFB00020),
                  foregroundColor: Colors.white,
                  icon: Icons.delete_outline_rounded,
                  label: conversation.isGroup ? (s?.leaveChat ?? 'Leave') : (s?.delete ?? 'Delete'),
                ),
              ],
            ),
            child: _ConversationTile(
              conversation: conversation,
              currentUserId: widget.currentUserId,
              onTap: () => _openChat(conversation),
              isFavorite: _favoriteIds.contains(conversation.id),
              isArchived: _archivedIds.contains(conversation.id),
              isPinned: _pinnedIds.contains(conversation.id),
              folderName: _folderByConversation[conversation.id],
              draftText: _draftsByConversationId[conversation.id],
              isTyping: _typingConversationIds.contains(conversation.id),
              isRecording: _recordingConversationIds.contains(conversation.id),
              pendingPreview: PendingMessageStore.instance.getPending(conversation.id)?.preview,
              isSending: PendingMessageStore.instance.hasPending(conversation.id),
              effectiveUnreadCount: effectiveUnread,
              onToggleFavorite: showFavoriteArchive ? () => _toggleFavorite(conversation.id) : null,
              onToggleArchived: showFavoriteArchive ? () => _toggleArchived(conversation.id) : null,
              onAssignFolder: showFavoriteArchive ? (name) => _setConversationFolder(conversation.id, name) : null,
            ),
          );
        },
      ),
    );
  }
}

/// Pill segment control (same pattern as Live tab in streams_screen.dart). DESIGN.md: 48dp, monochrome.
class _MessagesTabSegments extends StatelessWidget {
  const _MessagesTabSegments({
    required this.controller,
    required this.labels,
  });

  final TabController controller;
  final List<String> labels;

  static const double _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < labels.length; i++) ...[
              if (i > 0) const SizedBox(width: _gap),
              _Segment(
                label: labels[i],
                selected: controller.index == i,
                onTap: () => controller.animateTo(i),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const double _pillRadius = 20.0;
  static const double _pillPaddingH = 14.0;
  static const double _pillPaddingV = 6.0;
  static const Color _kPrimaryText = Color(0xFF1A1A1A);
  static const Color _kSecondaryText = Color(0xFF666666);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _kPrimaryText.withValues(alpha: 0.08) : Colors.transparent,
      borderRadius: BorderRadius.circular(_pillRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_pillRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _pillPaddingH,
            vertical: _pillPaddingV,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? _kPrimaryText : _kSecondaryText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _CallLogTile extends StatelessWidget {
  final CallLog callLog;
  final VoidCallback onTap;
  final VoidCallback onCall;

  const _CallLogTile({
    required this.callLog,
    required this.onTap,
    required this.onCall,
  });

  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);
  static const Color _iconBg = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final missedColor = callLog.wasMissed ? const Color(0xFFB00020) : _secondaryText;
    final s = AppStringsScope.of(context);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      minLeadingWidth: 56,
      leading: UserAvatar(
        photoUrl: callLog.otherUser?.avatarUrl,
        name: callLog.otherUser?.displayName,
        radius: 24,
      ),
      title: Text(
        callLog.otherUser?.displayName ?? (s?.userLabel ?? 'User'),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TextStyle(
          color: callLog.wasMissed ? const Color(0xFFB00020) : _primaryText,
          fontSize: 15,
        ),
      ),
      subtitle: Row(
        children: [
          Icon(
            callLog.isIncoming ? Icons.call_received : Icons.call_made,
            size: 14,
            color: missedColor,
          ),
          const SizedBox(width: 4),
          Icon(
            callLog.type == 'video' ? Icons.videocam_rounded : Icons.call_rounded,
            size: 14,
            color: _secondaryText,
          ),
          const SizedBox(width: 4),
          Text(
            _formatTime(callLog.callTime),
            style: const TextStyle(color: _secondaryText, fontSize: 13),
          ),
          if (callLog.wasAnswered && callLog.duration != null) ...[
            const SizedBox(width: 8),
            Text(
              callLog.durationFormatted,
              style: const TextStyle(color: _secondaryText, fontSize: 13),
            ),
          ],
        ],
      ),
      trailing: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onCall,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            child: Icon(
              callLog.type == 'video' ? Icons.videocam_rounded : Icons.call_rounded,
              color: _iconBg,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.year == now.year && time.month == now.month && time.day == now.day) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.day}/${time.month}';
  }
}

/// DESIGN.md: 48dp min touch, list tile for user search result.
class _UserSearchTile extends StatelessWidget {
  final UserProfile user;
  final VoidCallback onTap;

  const _UserSearchTile({required this.user, required this.onTap});

  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
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
                          color: _primaryText,
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
                            color: _secondaryText,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final int currentUserId;
  final VoidCallback onTap;
  final bool isFavorite;
  final bool isArchived;
  final bool isPinned;
  final String? folderName;
  final String? draftText;
  final bool isTyping;
  final bool isRecording;
  final String? pendingPreview;
  final bool isSending;
  final int effectiveUnreadCount;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onToggleArchived;
  final void Function(String? folderName)? onAssignFolder;

  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
    this.isFavorite = false,
    this.isArchived = false,
    this.isPinned = false,
    this.folderName,
    this.draftText,
    this.isTyping = false,
    this.isRecording = false,
    this.pendingPreview,
    this.isSending = false,
    this.effectiveUnreadCount = 0,
    this.onToggleFavorite,
    this.onToggleArchived,
    this.onAssignFolder,
  });

  // Design system: WhatsApp-style hierarchy & spacing (1️⃣5️⃣ 1️⃣6️⃣)
  // Hierarchy: 1) Identity (avatar) 2) Context (name + message) 3) Attention (unread, bold) 4) Metadata (time, mute, pin)
  // 4️⃣ Timestamp: top-right; Today=3:45 PM, Yesterday=Yesterday, <7d=Mon, >7d=12/02/25; color changes if unread
  // 6️⃣ Unread: green circle, bold white number, only if unread>0; name bold when unread
  // 7️⃣ Mute: small muted speaker (volume_off) next to timestamp when muted
  // 8️⃣ Pin: at top, pin icon on right; max 3 pinned
  // Spacing: avatar 48–56px, row 72–80px; timestamp top-right, unread bottom-right
  static const double _avatarRadius = 28; // 56px circle (within 48–56px)
  static const double _rowHeight = 68; // compact row
  static const double _paddingH = 16;
  static const double _paddingV = 6;
  static const double _gapNamePreview = 4; // space between name row and preview row (context block)
  static const Color _brandGreen = Color(0xFF25D366); // Brand reinforcement (unread badge, read tick)

  void _showFolderMenu(BuildContext context) {
    if (onAssignFolder == null) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Move to folder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            ListTile(
              title: const Text('No folder'),
              onTap: () {
                onAssignFolder!(null);
                Navigator.pop(context);
              },
            ),
            ...kChatFolderNames.map((f) => ListTile(
              title: Text(f),
              onTap: () {
                onAssignFolder!(f);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ConversationParticipant? otherUser;
    if (!conversation.isGroup && conversation.participants.isNotEmpty) {
      try {
        otherUser = conversation.participants.firstWhere(
          (p) => p.userId != currentUserId,
          orElse: () => conversation.participants.first,
        );
      } catch (_) {
        otherUser = conversation.participants.first;
      }
    }

    final s = AppStringsScope.of(context);
    final displayName = conversation.isGroup
        ? conversation.name ?? conversation.title
        : (otherUser?.user?.fullName ?? (s?.userLabel ?? 'User'));

    final photoUrl = conversation.isGroup
        ? conversation.avatarUrl
        : otherUser?.user?.profilePhotoUrl;

    final lastMessage = conversation.lastMessage;
    final hasUnread = effectiveUnreadCount > 0;
    final lastMessageFromMe = lastMessage != null && lastMessage.senderId == currentUserId;

    final theme = Theme.of(context);
    final primaryText = theme.colorScheme.onSurface;
    final secondaryText = theme.colorScheme.onSurfaceVariant;
    final unreadBadgeColor = _brandGreen; // Brand reinforcement (1️⃣9️⃣)

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: InkWell(
        onTap: onTap,
        onLongPress: onAssignFolder != null ? () => _showFolderMenu(context) : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _rowHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _paddingH, vertical: _paddingV),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    UserAvatar(
                      photoUrl: photoUrl,
                      name: displayName,
                      radius: _avatarRadius,
                    ),
                    if (conversation.isGroup)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.scaffoldBackgroundColor, width: 1.5),
                          ),
                          child: Icon(Icons.group_rounded, size: 14, color: primaryText),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Middle: Conversation context (name + last message); right: metadata top, unread bottom
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Row 1: Name (identity/context) | Timestamp + Mute + Pin (metadata, top-right)
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    displayName,
                                    style: TextStyle(
                                      fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                                      color: primaryText,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (folderName != null && folderName!.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: secondaryText.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      folderName!,
                                      style: TextStyle(fontSize: 10, color: secondaryText),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // 4️⃣ Timestamp top-right; 7️⃣ Mute (muted speaker); 8️⃣ Pin — metadata row, right-aligned
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                _formatTime(
                                  lastMessage?.createdAt ?? conversation.lastMessageAt ?? conversation.updatedAt,
                                  context,
                                ),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: hasUnread ? primaryText : secondaryText.withValues(alpha: 0.9),
                                  fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                                ),
                              ),
                              if (conversation.isMuted) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.volume_off_rounded, size: 14, color: secondaryText.withValues(alpha: 0.85)),
                              ],
                              if (isPinned) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.push_pin_rounded, size: 12, color: secondaryText.withValues(alpha: 0.85)),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: _gapNamePreview),
                      // Row 2: State icon + Preview (context) | Unread badge (attention, bottom-right)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (isSending)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(Icons.schedule_rounded, size: 16, color: secondaryText),
                            )
                          else if (lastMessageFromMe && lastMessage != null && draftText == null && !isTyping && !isRecording)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                lastMessage.isRead ? Icons.done_all : Icons.done,
                                size: 16,
                                color: lastMessage.isRead ? _brandGreen : secondaryText,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              isSending
                                  ? (pendingPreview != null && pendingPreview!.isNotEmpty
                                      ? pendingPreview!
                                      : (s?.sending ?? 'Sending...'))
                                  : draftText != null
                                      ? '${s?.draft ?? 'Draft'}: ${draftText!.trim()}'
                                      : isRecording
                                          ? (s?.recordingAudio ?? 'Recording audio...')
                                          : isTyping
                                              ? (s?.typing ?? 'Typing...')
                                              : lastMessage != null
                                                  ? _getMessagePreview(lastMessage, context, isGroup: conversation.isGroup)
                                                  : (s?.startConversation ?? 'Start conversation'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: isSending
                                    ? secondaryText
                                    : draftText != null
                                        ? const Color(0xFFB00020)
                                        : (isRecording || isTyping)
                                            ? _brandGreen
                                            : (hasUnread ? primaryText.withValues(alpha: 0.9) : secondaryText),
                                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (hasUnread && effectiveUnreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: unreadBadgeColor,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                effectiveUnreadCount > 99 ? '99+' : '$effectiveUnreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (onToggleFavorite != null || onToggleArchived != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onToggleFavorite != null)
                        IconButton(
                          icon: Icon(
                            isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                            color: primaryText,
                            size: 22,
                          ),
                          onPressed: onToggleFavorite,
                          style: IconButton.styleFrom(minimumSize: const Size(40, 40)),
                        ),
                      if (onToggleArchived != null)
                        IconButton(
                          icon: Icon(
                            isArchived ? Icons.archive_rounded : Icons.archive_outlined,
                            color: primaryText,
                            size: 22,
                          ),
                          onPressed: onToggleArchived,
                          style: IconButton.styleFrom(minimumSize: const Size(40, 40)),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// WhatsApp-style: Today = "3:45 PM", Yesterday = "Yesterday", < 7 days = "Mon", else "12/02/25".
  String _formatTime(DateTime time, BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final timeDate = DateTime(time.year, time.month, time.day);
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    if (timeDate == today) {
      final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
      final ampm = time.hour >= 12 ? 'PM' : 'AM';
      final min = time.minute.toString().padLeft(2, '0');
      return '$hour:$min $ampm';
    }
    if (timeDate == yesterday) return AppStringsScope.of(context)?.yesterday ?? 'Yesterday';
    final diffDays = today.difference(timeDate).inDays;
    if (diffDays < 7) return weekdays[time.weekday - 1];
    return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year % 100}';
  }

  String _getMessagePreview(Message message, BuildContext context, {bool isGroup = false}) {
    final s = AppStringsScope.of(context);
    String body;
    switch (message.messageType) {
      case MessageType.image:
        body = s?.photoPost ?? 'Photo';
        break;
      case MessageType.video:
        body = s?.video ?? 'Video';
        break;
      case MessageType.audio:
        body = s?.voiceMessage ?? 'Voice message';
        break;
      case MessageType.document:
        body = s?.file ?? 'File';
        break;
      default:
        body = message.content?.trim() ?? '';
    }
    if (isGroup && body.isNotEmpty && message.sender != null) {
      final name = message.sender!.fullName.trim();
      if (name.isNotEmpty) return '${name}: $body';
    }
    return body;
  }
}
