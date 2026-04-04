import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/message_models.dart';
import '../../services/message_service.dart';
import '../../services/message_database.dart';
import '../../config/api_config.dart';

class StarredMessagesScreen extends StatefulWidget {
  final int currentUserId;
  const StarredMessagesScreen({super.key, required this.currentUserId});

  @override
  State<StarredMessagesScreen> createState() => _StarredMessagesScreenState();
}

class _StarredMessagesScreenState extends State<StarredMessagesScreen> {
  List<Message> _messages = [];
  bool _loading = true;
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Load from local DB first for instant display
    try {
      final localStarred = await MessageDatabase.instance
          .getStarredMessages(limit: 20, offset: 0);
      if (localStarred.isNotEmpty && mounted) {
        setState(() {
          _messages = localStarred;
          _loading = false;
        });
      }
    } catch (_) {
      // Local DB read failed — continue to API fetch
    }

    // Then fetch from API for completeness
    try {
      final result = await MessageService.getStarredMessages(widget.currentUserId, page: _page);
      if (mounted) {
        // Cache API results back to SQLite so they're available offline
        if (result.messages.isNotEmpty) {
          MessageDatabase.instance.upsertMessages(result.messages);
        }
        setState(() {
          _messages = result.messages;
          _hasMore = result.messages.length >= 20;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        if (_messages.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load starred messages: $e')),
          );
        }
      }
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore) return;
    _page++;
    try {
      final result = await MessageService.getStarredMessages(widget.currentUserId, page: _page);
      if (mounted) {
        // Cache paginated results to SQLite
        if (result.messages.isNotEmpty) {
          MessageDatabase.instance.upsertMessages(result.messages);
        }
        setState(() {
          _messages.addAll(result.messages);
          _hasMore = result.messages.length >= 20;
        });
      }
    } catch (e) {
      _page--; // revert page increment on failure
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load more: $e')),
        );
      }
    }
  }

  Future<bool> _unstar(Message message) async {
    final success = await MessageService.toggleStar(
      message.conversationId,
      message.id,
      widget.currentUserId,
    );
    if (success && mounted) {
      await MessageDatabase.instance.toggleMessageStar(message.id, false);
      setState(() => _messages.removeWhere((m) => m.id == message.id));
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to unstar message')),
      );
    }
    return success;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          'Starred Messages',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_border, size: 48, color: Color(0xFFBDBDBD)),
                      SizedBox(height: 12),
                      Text(
                        'No starred messages',
                        style: TextStyle(color: Color(0xFF999999), fontSize: 15),
                      ),
                    ],
                  ),
                )
              : NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n is ScrollEndNotification &&
                        n.metrics.pixels > n.metrics.maxScrollExtent - 200) {
                      _loadMore();
                    }
                    return false;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _messages.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (context, index) =>
                        _buildTile(_messages[index]),
                  ),
                ),
    );
  }

  Widget _buildTile(Message message) {
    final df = DateFormat('MMM d, HH:mm');
    final isMe = message.senderId == widget.currentUserId;
    final senderName = isMe
        ? 'You'
        : (message.sender?.fullName ?? 'User ${message.senderId}');
    final photo = message.sender?.profilePhotoPath;

    return Dismissible(
      key: ValueKey(message.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: const Color(0xFFE0E0E0),
        child: const Icon(Icons.star_border, color: Color(0xFF1A1A1A)),
      ),
      confirmDismiss: (_) => _unstar(message),
      child: ListTile(
        onTap: () {
          if (message.conversationId > 0) {
            Navigator.pushNamed(context, '/chat/${message.conversationId}');
          }
        },
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFE0E0E0),
          backgroundImage: photo != null
              ? NetworkImage(
                  photo.startsWith('http')
                      ? photo
                      : '${ApiConfig.storageUrl}/$photo',
                )
              : null,
          child: photo == null
              ? Text(
                  senderName[0].toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                )
              : null,
        ),
        title: Text(
          senderName,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle: Text(
          message.content ?? message.preview,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
        ),
        trailing: Text(
          df.format(message.createdAt),
          style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
        ),
      ),
    );
  }
}
