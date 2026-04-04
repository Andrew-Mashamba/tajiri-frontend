import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../services/audio_room_service.dart';
import '../../widgets/tajiri_app_bar.dart';
import '../../l10n/app_strings_scope.dart';
import 'audio_room_screen.dart';

/// Discovery feed for active Audio Rooms (Clubhouse/Spaces style).
/// Monochromatic design per DOCS/DESIGN.md.
class AudioRoomsDiscoveryScreen extends StatefulWidget {
  final int currentUserId;

  const AudioRoomsDiscoveryScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  State<AudioRoomsDiscoveryScreen> createState() =>
      _AudioRoomsDiscoveryScreenState();
}

class _AudioRoomsDiscoveryScreenState extends State<AudioRoomsDiscoveryScreen> {
  static const Color _background = Color(0xFFFAFAFA);
  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);
  List<AudioRoom> _rooms = [];
  bool _isLoading = true;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadRooms();
    // Poll every 30s for new rooms
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadRooms(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRooms({bool silent = false}) async {
    if (!silent && mounted) setState(() => _isLoading = true);
    try {
      final rooms = await AudioRoomService.getActiveRooms(page: 1);
      if (mounted) {
        setState(() {
          _rooms = rooms;
          _page = 1;
          _hasMore = rooms.length >= 15;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore) return;
    final nextPage = _page + 1;
    final rooms = await AudioRoomService.getActiveRooms(page: nextPage);
    if (mounted) {
      setState(() {
        _rooms.addAll(rooms);
        _page = nextPage;
        _hasMore = rooms.length >= 15;
      });
    }
  }

  Future<void> _joinRoom(AudioRoom room) async {
    final joined = await AudioRoomService.joinRoom(room.id);
    if (joined != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => AudioRoomScreen(
            roomId: joined.id,
            currentUserId: widget.currentUserId,
            initialRoom: joined,
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to join room')),
      );
    }
  }

  void _showCreateRoomSheet() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final s = AppStringsScope.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                s?.isSwahili == true
                    ? 'Anza Chumba cha Sauti'
                    : 'Start Audio Room',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _primaryText,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: s?.isSwahili == true ? 'Kichwa' : 'Title',
                  hintText: s?.isSwahili == true
                      ? 'Mada ya mazungumzo...'
                      : 'What are you talking about...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLength: 250,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: s?.isSwahili == true ? 'Maelezo' : 'Description',
                  hintText: s?.isSwahili == true
                      ? 'Maelezo ya ziada (hiari)...'
                      : 'Additional details (optional)...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;
                    Navigator.pop(ctx);
                    final room = await AudioRoomService.createRoom(
                      title: title,
                      description: descController.text.trim().isNotEmpty
                          ? descController.text.trim()
                          : null,
                    );
                    if (room != null && mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => AudioRoomScreen(
                            roomId: room.id,
                            currentUserId: widget.currentUserId,
                            initialRoom: room,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryText,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    s?.isSwahili == true ? 'Anza Sasa' : 'Start Now',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Scaffold(
      backgroundColor: _background,
      appBar: TajiriAppBar(
        title: s?.isSwahili == true ? 'Vyumba vya Sauti' : 'Audio Rooms',
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateRoomSheet,
        backgroundColor: _primaryText,
        foregroundColor: Colors.white,
        child: const HeroIcon(HeroIcons.plus, size: 24),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s?.isSwahili == true
                            ? 'Imeshindikana kupakia'
                            : 'Failed to load',
                        style: const TextStyle(color: _secondaryText),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _loadRooms,
                        child: Text(s?.isSwahili == true
                            ? 'Jaribu tena'
                            : 'Try again'),
                      ),
                    ],
                  ),
                )
              : _rooms.isEmpty
                  ? _buildEmptyState(s)
                  : RefreshIndicator(
                      onRefresh: _loadRooms,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (n) {
                          if (n is ScrollEndNotification &&
                              n.metrics.pixels >
                                  n.metrics.maxScrollExtent - 200) {
                            _loadMore();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          itemCount: _rooms.length,
                          itemBuilder: (_, i) =>
                              _AudioRoomCard(
                                room: _rooms[i],
                                onTap: () => _joinRoom(_rooms[i]),
                              ),
                        ),
                      ),
                    ),
    );
  }

  Widget _buildEmptyState(dynamic s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HeroIcon(
              HeroIcons.microphone,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              s?.isSwahili == true
                  ? 'Hakuna vyumba vinavyoendelea'
                  : 'No active rooms',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s?.isSwahili == true
                  ? 'Anza chumba kipya cha sauti na uzungumze na marafiki wako.'
                  : 'Start a new audio room and talk with your friends.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: _secondaryText,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _showCreateRoomSheet,
                icon: const HeroIcon(HeroIcons.plus, size: 20),
                label: Text(
                  s?.isSwahili == true ? 'Anza Chumba' : 'Start a Room',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryText,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card widget for a single audio room in the discovery feed.
class _AudioRoomCard extends StatelessWidget {
  final AudioRoom room;
  final VoidCallback onTap;

  const _AudioRoomCard({required this.room, required this.onTap});

  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);

  @override
  Widget build(BuildContext context) {
    // Up to 3 speaker avatars
    final speakers = room.participants
        .where((p) => p.isSpeaker)
        .take(3)
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  room.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _primaryText,
                  ),
                ),
                if (room.description != null &&
                    room.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    room.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _secondaryText,
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Host
                Row(
                  children: [
                    _buildAvatar(room.host, 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        room.host?.fullName ?? 'Host',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _primaryText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Bottom: speaker avatars + counts
                Row(
                  children: [
                    // Stacked speaker avatars
                    if (speakers.isNotEmpty) ...[
                      SizedBox(
                        width: 16.0 * speakers.length + 20,
                        height: 28,
                        child: Stack(
                          children: [
                            for (var i = 0; i < speakers.length; i++)
                              Positioned(
                                left: i * 16.0,
                                child:
                                    _buildAvatar(speakers[i].user, 14),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Participant count
                    HeroIcon(
                      HeroIcons.userGroup,
                      size: 16,
                      color: _secondaryText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${room.participantCount}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _secondaryText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Speaker count
                    HeroIcon(
                      HeroIcons.microphone,
                      size: 16,
                      color: _secondaryText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${room.speakerCount}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _secondaryText,
                      ),
                    ),
                    const Spacer(),
                    // LIVE indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _primaryText,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
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

  Widget _buildAvatar(AudioRoomUser? user, double radius) {
    final url = user?.avatarUrl ?? '';
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[200],
      backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
      child: url.isEmpty
          ? Text(
              (user?.firstName.isNotEmpty == true)
                  ? user!.firstName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: radius * 0.9,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF666666),
              ),
            )
          : null,
    );
  }
}
