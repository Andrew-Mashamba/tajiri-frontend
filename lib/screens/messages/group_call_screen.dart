// Story 60: Group Call — Home → Messages → Group chat → Group call
// Design: DOCS/DESIGN.md — #FAFAFA, 48dp min touch targets, SafeArea

import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/message_models.dart';
import '../../models/friend_models.dart';
import '../../services/group_call_service.dart';
import '../../services/friend_service.dart';
import '../../widgets/user_avatar.dart';

const double _kMinTouchTarget = 48.0;
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const Color _kIconBg = Color(0xFF1A1A1A);

class GroupCallScreen extends StatefulWidget {
  final int conversationId;
  final int currentUserId;
  final Conversation conversation;

  const GroupCallScreen({
    super.key,
    required this.conversationId,
    required this.currentUserId,
    required this.conversation,
  });

  @override
  State<GroupCallScreen> createState() => _GroupCallScreenState();
}

const int _kMaxGroupCallParticipants = 32;

class _GroupCallScreenState extends State<GroupCallScreen> {
  final GroupCallService _callService = GroupCallService();
  final FriendService _friendService = FriendService();

  bool _isLoading = true;
  String? _errorMessage;
  String? _callId;
  List<GroupCallParticipantState> _participants = [];
  bool _isMuted = false;
  bool _isVideoOn = true;
  bool _isLeaving = false;

  // Feature #26: Speaker spotlight — track active speaker
  int? _activeSpeakerId;
  Timer? _speakerDetectionTimer;

  @override
  void initState() {
    super.initState();
    _joinCall();
    _startSpeakerDetection();
  }

  @override
  void dispose() {
    _speakerDetectionTimer?.cancel();
    super.dispose();
  }

  Future<void> _joinCall() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _callService.startOrJoinGroupCall(
      conversationId: widget.conversationId,
      userId: widget.currentUserId,
    );

    if (!mounted) return;

    if (result.success) {
      _callId = result.callId;
      List<GroupCallParticipantState> list = List.from(result.participants);
      final hasMe = list.any((p) => p.userId == widget.currentUserId);
      if (!hasMe) {
        list.add(GroupCallParticipantState(
          userId: widget.currentUserId,
          displayName: 'You',
          isMuted: _isMuted,
          videoEnabled: _isVideoOn,
          isLocal: true,
        ));
      } else {
        list = list.map((p) {
          if (p.userId == widget.currentUserId) {
            return GroupCallParticipantState(
              userId: p.userId,
              displayName: p.displayName ?? 'You',
              avatarUrl: p.avatarUrl,
              isMuted: _isMuted,
              videoEnabled: _isVideoOn,
              isLocal: true,
            );
          }
          return p;
        }).toList();
      }
      if (list.isEmpty) {
        list = _buildParticipantsFromConversation();
      }
      setState(() {
        _participants = list;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result.message ?? 'Imeshindwa kujiunga na simu';
        _isLoading = false;
      });
    }
  }

  List<GroupCallParticipantState> _buildParticipantsFromConversation() {
    final list = <GroupCallParticipantState>[];
    for (final p in widget.conversation.participants) {
      final isMe = p.userId == widget.currentUserId;
      list.add(GroupCallParticipantState(
        userId: p.userId,
        displayName: isMe ? 'You' : (p.user?.fullName ?? 'Mtumiaji'),
        avatarUrl: p.user?.profilePhotoUrl,
        isMuted: isMe ? _isMuted : false,
        videoEnabled: isMe ? _isVideoOn : true,
        isLocal: isMe,
      ));
    }
    return list;
  }

  // ── Feature #26: Speaker spotlight — detect active speaker ──────────
  void _startSpeakerDetection() {
    _speakerDetectionTimer?.cancel();
    _speakerDetectionTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      // Poll the GroupCallService for the current active speaker.
      // The service checks audio levels or recent audio activity and
      // returns the userId of the loudest participant (null if silence).
      if (_callId == null || _participants.length < 2) return;
      try {
        final speakerId = await _callService.getActiveSpeaker(
          callId: _callId,
          conversationId: widget.conversationId,
          userId: widget.currentUserId,
        );
        if (mounted && speakerId != _activeSpeakerId) {
          setState(() => _activeSpeakerId = speakerId);
        }
      } catch (_) {
        // Speaker detection unavailable — keep previous state
      }
    });
  }

  Future<void> _leaveCall() async {
    if (_isLeaving) return;
    setState(() => _isLeaving = true);

    await _callService.leaveGroupCall(
      callId: _callId,
      conversationId: widget.conversationId,
      userId: widget.currentUserId,
    );

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _toggleMute() async {
    final next = !_isMuted;
    final success = await _callService.setMuted(
      callId: _callId,
      userId: widget.currentUserId,
      muted: next,
    );
    if (!mounted) return;
    if (success) {
      setState(() => _isMuted = next);
      _updateLocalParticipantState(muted: next);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imeshindwa kubadilisha hali ya sauti')),
      );
    }
  }

  Future<void> _toggleVideo() async {
    final next = !_isVideoOn;
    final success = await _callService.setVideoEnabled(
      callId: _callId,
      userId: widget.currentUserId,
      videoEnabled: next,
    );
    if (!mounted) return;
    if (success) {
      setState(() => _isVideoOn = next);
      _updateLocalParticipantState(videoEnabled: next);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imeshindwa kubadilisha hali ya video')),
      );
    }
  }

  void _updateLocalParticipantState({bool? muted, bool? videoEnabled}) {
    setState(() {
      _participants = _participants.map((p) {
        if (p.userId != widget.currentUserId) return p;
        return GroupCallParticipantState(
          userId: p.userId,
          displayName: p.displayName,
          avatarUrl: p.avatarUrl,
          isMuted: muted ?? p.isMuted,
          videoEnabled: videoEnabled ?? p.videoEnabled,
          isLocal: true,
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.conversation.name ?? 'Kikundi';

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _kPrimaryText,
        elevation: 0,
        title: Text(
          '$title • ${_participants.length}/$_kMaxGroupCallParticipants',
          style: const TextStyle(fontSize: 16, color: _kPrimaryText),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? _buildError()
                      : _buildParticipantGrid(),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: _kSecondaryText,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: TextButton(
                onPressed: () => _joinCall(),
                child: const Text('Jaribu tena'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantGrid() {
    if (_participants.isEmpty) {
      return const Center(
        child: Text(
          'Hakuna wanachama katika simu',
          style: TextStyle(fontSize: 14, color: _kSecondaryText),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final crossCount = constraints.maxWidth > 400 ? 3 : 2;
        final itemWidth =
            (constraints.maxWidth - spacing * (crossCount + 1)) / crossCount;
        final itemSize = itemWidth.clamp(100.0, 180.0);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            alignment: WrapAlignment.center,
            children: _participants.map((p) {
              final isSpeaking = _activeSpeakerId != null && p.userId == _activeSpeakerId;
              // Active speaker gets 1.3x tile size for spotlight effect
              final tileSize = isSpeaking ? (itemSize * 1.3).clamp(100.0, 220.0) : itemSize;
              return _ParticipantTile(
                size: tileSize,
                displayName: p.displayName ?? 'Mtumiaji',
                avatarUrl: p.avatarUrl,
                isMuted: p.isMuted,
                videoEnabled: p.videoEnabled,
                isLocal: p.isLocal,
                isSpeaking: isSpeaking,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showAddParticipant() {
    if (_participants.length >= _kMaxGroupCallParticipants) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group call limit reached ($_kMaxGroupCallParticipants)')),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => FutureBuilder<FriendListResult>(
        future: _friendService.getFriends(userId: widget.currentUserId, perPage: 30),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ));
          }
          final result = snapshot.data!;
          final list = result.success ? result.friends : <UserProfile>[];
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Add participant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                Flexible(
                  child: list.isEmpty
                      ? const Padding(padding: EdgeInsets.all(24), child: Text('No contacts'))
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final u = list[index];
                            return ListTile(
                              leading: UserAvatar(photoUrl: u.profilePhotoUrl, name: u.fullName, radius: 24),
                              title: Text(u.fullName),
                              onTap: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                Navigator.pop(context);
                                final success = await _callService.inviteToGroupCall(
                                  callId: _callId,
                                  conversationId: widget.conversationId,
                                  inviterId: widget.currentUserId,
                                  inviteeId: u.id,
                                );
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Mwaliko umetumwa kwa ${u.fullName}'
                                          : 'Imeshindwa kumwalika ${u.fullName}',
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            label: _isMuted ? 'Zima sauti' : 'Sauti',
            onPressed: _isLoading || _errorMessage != null ? null : _toggleMute,
          ),
          if (_participants.length < _kMaxGroupCallParticipants)
            _ControlButton(
              icon: Icons.person_add,
              label: 'Ongeza',
              onPressed: _isLoading || _errorMessage != null ? null : _showAddParticipant,
            ),
          _ControlButton(
            icon: _isVideoOn ? Icons.videocam : Icons.videocam_off,
            label: _isVideoOn ? 'Video' : 'Zima video',
            onPressed: _isLoading || _errorMessage != null ? null : _toggleVideo,
          ),
          _ControlButton(
            icon: Icons.call_end,
            label: 'Ondoka',
            onPressed: _isLeaving ? null : _leaveCall,
            isEnd: true,
          ),
        ],
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final double size;
  final String displayName;
  final String? avatarUrl;
  final bool isMuted;
  final bool videoEnabled;
  final bool isLocal;
  final bool isSpeaking;

  const _ParticipantTile({
    required this.size,
    required this.displayName,
    this.avatarUrl,
    required this.isMuted,
    required this.videoEnabled,
    required this.isLocal,
    this.isSpeaking = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(12),
                  border: isSpeaking
                      ? Border.all(color: Colors.green, width: 3)
                      : null,
                  boxShadow: [
                    if (isSpeaking)
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    else
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Center(
                  child: UserAvatar(
                    photoUrl: avatarUrl,
                    name: displayName,
                    radius: size * 0.4,
                  ),
                ),
              ),
              if (isMuted)
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: _kIconBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic_off,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              if (!videoEnabled)
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: _kIconBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.videocam_off,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              // Speaker spotlight label (Feature #26)
              if (isSpeaking)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Speaking',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 12,
              color: _kPrimaryText,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isEnd;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.isEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final minSize = const Size(_kMinTouchTarget, _kMinTouchTarget);
    final bgColor = isEnd ? const Color(0xFFB00020) : _kIconBg;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: onPressed == null ? _kIconBg.withValues(alpha: 0.4) : bgColor,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              constraints: BoxConstraints(
                minWidth: minSize.width,
                minHeight: minSize.height,
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _kSecondaryText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
