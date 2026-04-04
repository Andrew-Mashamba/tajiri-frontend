import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../services/audio_room_service.dart';
import '../../l10n/app_strings_scope.dart';

/// In-room screen for a single Audio Room. Shows speakers, listeners,
/// raised-hand requests (host only), and bottom action bar.
/// Polls room state every 5 seconds to keep participant list fresh.
class AudioRoomScreen extends StatefulWidget {
  final int roomId;
  final int currentUserId;
  final AudioRoom? initialRoom;

  const AudioRoomScreen({
    super.key,
    required this.roomId,
    required this.currentUserId,
    this.initialRoom,
  });

  @override
  State<AudioRoomScreen> createState() => _AudioRoomScreenState();
}

class _AudioRoomScreenState extends State<AudioRoomScreen> {
  static const Color _background = Color(0xFFFAFAFA);
  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);
  static const double _touchTarget = 48.0;

  AudioRoom? _room;
  bool _isLoading = true;
  bool _isMuted = true;
  bool _handRaised = false;
  Timer? _pollTimer;

  // My participant role (derived from participants list)
  AudioRoomParticipant? _myParticipant;

  @override
  void initState() {
    super.initState();
    if (widget.initialRoom != null) {
      _room = widget.initialRoom;
      _isLoading = false;
      _deriveMyState();
    }
    _fetchRoom();
    // Poll every 5s for participant changes
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _fetchRoom(silent: true),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _deriveMyState() {
    if (_room == null) return;
    _myParticipant = _room!.participants
        .cast<AudioRoomParticipant?>()
        .firstWhere(
          (p) => p!.userId == widget.currentUserId,
          orElse: () => null,
        );
    if (_myParticipant != null) {
      _isMuted = _myParticipant!.isMuted;
      _handRaised = _myParticipant!.hasRaisedHand;
    }
  }

  Future<void> _fetchRoom({bool silent = false}) async {
    if (!silent && mounted) setState(() => _isLoading = true);
    final room = await AudioRoomService.getRoom(widget.roomId);
    if (room != null && mounted) {
      setState(() {
        _room = room;
        _isLoading = false;
        _deriveMyState();
      });
      // If room ended while we're in it, pop back
      if (!room.isActive) {
        _showEndedAndPop();
      }
    } else if (!silent && mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showEndedAndPop() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This room has ended')),
    );
    Navigator.pop(context);
  }

  bool get _isHost => _room?.hostId == widget.currentUserId;
  bool get _isSpeaker => _myParticipant?.isSpeaker ?? _isHost;
  bool get _isListener => _myParticipant?.isListener ?? false;

  Future<void> _toggleMute() async {
    final newMuted = !_isMuted;
    setState(() => _isMuted = newMuted);
    await AudioRoomService.toggleMute(widget.roomId, newMuted);
  }

  Future<void> _toggleRaiseHand() async {
    final newRaised = !_handRaised;
    setState(() => _handRaised = newRaised);
    await AudioRoomService.toggleRaiseHand(widget.roomId, newRaised);
  }

  Future<void> _leaveRoom() async {
    await AudioRoomService.leaveRoom(widget.roomId);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _endRoom() async {
    final s = AppStringsScope.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s?.isSwahili == true ? 'Maliza Chumba' : 'End Room'),
        content: Text(
          s?.isSwahili == true
              ? 'Je, una uhakika unataka kumaliza chumba hiki? Washiriki wote watatolewa.'
              : 'Are you sure you want to end this room? All participants will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s?.isSwahili == true ? 'Ghairi' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              s?.isSwahili == true ? 'Maliza' : 'End',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AudioRoomService.endRoom(widget.roomId);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _promoteSpeaker(AudioRoomParticipant participant) async {
    final ok =
        await AudioRoomService.promoteSpeaker(widget.roomId, participant.userId);
    if (ok) _fetchRoom(silent: true);
  }

  Future<void> _demoteSpeaker(AudioRoomParticipant participant) async {
    final ok =
        await AudioRoomService.demoteSpeaker(widget.roomId, participant.userId);
    if (ok) _fetchRoom(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    if (_isLoading && _room == null) {
      return Scaffold(
        backgroundColor: _background,
        body: const SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_room == null) {
      return Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Center(
            child: Text(
              s?.isSwahili == true
                  ? 'Chumba hakipatikani'
                  : 'Room not found',
              style: const TextStyle(color: _secondaryText),
            ),
          ),
        ),
      );
    }

    final speakers = _room!.participants.where((p) => p.isSpeaker).toList();
    final listeners = _room!.participants.where((p) => p.isListener).toList();
    final raisedHands =
        listeners.where((p) => p.hasRaisedHand).toList();

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: back + end/leave
            _buildTopBar(s),
            // Scrollable content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchRoom,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const SizedBox(height: 8),
                    // Title
                    Text(
                      _room!.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _primaryText,
                      ),
                    ),
                    if (_room!.description != null &&
                        _room!.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        _room!.description!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _secondaryText,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Speakers section
                    _sectionHeader(
                      s?.isSwahili == true ? 'Wasemaji' : 'Speakers',
                      speakers.length,
                    ),
                    const SizedBox(height: 12),
                    _buildSpeakersGrid(speakers),
                    const SizedBox(height: 24),

                    // Raised hands (host only)
                    if (_isHost && raisedHands.isNotEmpty) ...[
                      _sectionHeader(
                        s?.isSwahili == true
                            ? 'Wameomba Kusema'
                            : 'Raised Hands',
                        raisedHands.length,
                      ),
                      const SizedBox(height: 8),
                      _buildRaisedHandsList(raisedHands),
                      const SizedBox(height: 24),
                    ],

                    // Listeners section
                    _sectionHeader(
                      s?.isSwahili == true ? 'Wasikilizaji' : 'Listeners',
                      listeners.length,
                    ),
                    const SizedBox(height: 12),
                    _buildListenersGrid(listeners),
                    const SizedBox(height: 100), // space for bottom bar
                  ],
                ),
              ),
            ),
            // Bottom action bar
            _buildBottomBar(s),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(dynamic s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const HeroIcon(HeroIcons.chevronDown, size: 24),
            onPressed: () => Navigator.pop(context),
            constraints: const BoxConstraints(
              minWidth: _touchTarget,
              minHeight: _touchTarget,
            ),
          ),
          const Spacer(),
          // Participant count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const HeroIcon(HeroIcons.userGroup, size: 14,
                    color: _secondaryText),
                const SizedBox(width: 4),
                Text(
                  '${_room?.participantCount ?? 0}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _primaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label, int count) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _primaryText,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _secondaryText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeakersGrid(List<AudioRoomParticipant> speakers) {
    if (speakers.isEmpty) {
      return const SizedBox(
        height: 60,
        child: Center(
          child: Text(
            'No speakers yet',
            style: TextStyle(color: _secondaryText, fontSize: 13),
          ),
        ),
      );
    }
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: speakers.map((p) => _SpeakerTile(
        participant: p,
        isHost: _isHost,
        isMe: p.userId == widget.currentUserId,
        onDemote: _isHost && p.userId != widget.currentUserId
            ? () => _demoteSpeaker(p)
            : null,
      )).toList(),
    );
  }

  Widget _buildListenersGrid(List<AudioRoomParticipant> listeners) {
    if (listeners.isEmpty) {
      return const SizedBox(height: 40);
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: listeners.map((p) => _ListenerTile(
        participant: p,
        isMe: p.userId == widget.currentUserId,
      )).toList(),
    );
  }

  Widget _buildRaisedHandsList(List<AudioRoomParticipant> hands) {
    return Column(
      children: hands.map((p) {
        final name = p.user?.fullName ?? 'User ${p.userId}';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              _buildSmallAvatar(p.user, 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _primaryText,
                  ),
                ),
              ),
              // Approve button
              SizedBox(
                width: _touchTarget,
                height: _touchTarget,
                child: IconButton(
                  icon: const HeroIcon(HeroIcons.check, size: 20),
                  color: _primaryText,
                  onPressed: () => _promoteSpeaker(p),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar(dynamic s) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute/Unmute (speakers only)
          if (_isSpeaker)
            _BottomBarButton(
              icon: _isMuted ? HeroIcons.microphone : HeroIcons.microphone,
              label: _isMuted
                  ? (s?.isSwahili == true ? 'Fungua' : 'Unmute')
                  : (s?.isSwahili == true ? 'Nyamaza' : 'Mute'),
              isActive: !_isMuted,
              onTap: _toggleMute,
            ),

          // Raise hand (listeners only)
          if (_isListener)
            _BottomBarButton(
              icon: HeroIcons.handRaised,
              label: _handRaised
                  ? (s?.isSwahili == true ? 'Shusha' : 'Lower')
                  : (s?.isSwahili == true ? 'Omba' : 'Raise'),
              isActive: _handRaised,
              onTap: _toggleRaiseHand,
            ),

          // Leave
          _BottomBarButton(
            icon: HeroIcons.arrowRightOnRectangle,
            label: s?.isSwahili == true ? 'Ondoka' : 'Leave',
            isDestructive: true,
            onTap: _leaveRoom,
          ),

          // End room (host only)
          if (_isHost)
            _BottomBarButton(
              icon: HeroIcons.xMark,
              label: s?.isSwahili == true ? 'Maliza' : 'End',
              isDestructive: true,
              onTap: _endRoom,
            ),
        ],
      ),
    );
  }

  Widget _buildSmallAvatar(AudioRoomUser? user, double radius) {
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
                fontSize: radius * 0.85,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF666666),
              ),
            )
          : null,
    );
  }
}

/// Speaker tile: larger avatar with name and mute indicator.
class _SpeakerTile extends StatelessWidget {
  final AudioRoomParticipant participant;
  final bool isHost;
  final bool isMe;
  final VoidCallback? onDemote;

  const _SpeakerTile({
    required this.participant,
    required this.isHost,
    required this.isMe,
    this.onDemote,
  });

  @override
  Widget build(BuildContext context) {
    final user = participant.user;
    final name = user?.fullName ?? 'User ${participant.userId}';
    final url = user?.avatarUrl ?? '';
    final isMuted = participant.isMuted;

    return GestureDetector(
      onLongPress: onDemote,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Avatar ring: solid for speaking, dashed/grey for muted
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isMuted
                          ? Colors.grey.shade300
                          : const Color(0xFF1A1A1A),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey[200],
                    backgroundImage:
                        url.isNotEmpty ? NetworkImage(url) : null,
                    child: url.isEmpty
                        ? Text(
                            (user?.firstName.isNotEmpty == true)
                                ? user!.firstName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF666666),
                            ),
                          )
                        : null,
                  ),
                ),
                // Mute badge
                if (isMuted)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: const HeroIcon(
                          HeroIcons.microphone,
                          size: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                  ),
                // Host crown
                if (participant.isHost)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const HeroIcon(
                        HeroIcons.star,
                        size: 14,
                        color: Color(0xFF1A1A1A),
                        style: HeroIconStyle.solid,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isMe ? 'You' : name.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Listener tile: smaller avatar with name.
class _ListenerTile extends StatelessWidget {
  final AudioRoomParticipant participant;
  final bool isMe;

  const _ListenerTile({required this.participant, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final user = participant.user;
    final name = user?.fullName ?? 'User ${participant.userId}';
    final url = user?.avatarUrl ?? '';

    return SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey[200],
                backgroundImage:
                    url.isNotEmpty ? NetworkImage(url) : null,
                child: url.isEmpty
                    ? Text(
                        (user?.firstName.isNotEmpty == true)
                            ? user!.firstName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                        ),
                      )
                    : null,
              ),
              // Raised hand indicator
              if (participant.hasRaisedHand)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const HeroIcon(
                      HeroIcons.handRaised,
                      size: 14,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isMe ? 'You' : name.split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom bar action button.
class _BottomBarButton extends StatelessWidget {
  final HeroIcons icon;
  final String label;
  final bool isActive;
  final bool isDestructive;
  final VoidCallback onTap;

  const _BottomBarButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? Colors.red[400]!
        : isActive
            ? const Color(0xFF1A1A1A)
            : const Color(0xFF999999);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red[50]
                    : isActive
                        ? const Color(0xFFF0F0F0)
                        : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: HeroIcon(icon, size: 20, color: color),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
