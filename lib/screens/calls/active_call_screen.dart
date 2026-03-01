// Video & Audio Calls — Active call UI (docs/video-audio-calls, 02-ui-spec, 1.F.12, 1.F.13)
// Voice: header, avatar, bottom bar (Mute, Speaker, Add, End). Video: full-screen remote, PiP self, bottom bar.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../calls/call_state.dart';
import '../../services/call_signaling_service.dart';
import '../../services/call_webrtc_service.dart';
import '../../calls/call_channel_service.dart';
import '../../services/friend_service.dart';
import '../../models/friend_models.dart';
import '../../widgets/user_avatar.dart';

class ActiveCallScreen extends StatefulWidget {
  final CallState callState;
  final CallWebRTCService webrtcService;
  final CallSignalingService signalingService;
  final CallChannelService? channelService;
  final String callId;
  final int currentUserId;
  final String? authToken;
  final VoidCallback? onCallEnded;

  const ActiveCallScreen({
    super.key,
    required this.callState,
    required this.webrtcService,
    required this.signalingService,
    this.channelService,
    required this.callId,
    required this.currentUserId,
    this.authToken,
    this.onCallEnded,
  });

  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen> {
  StreamSubscription? _endedSub;
  StreamSubscription? _remoteStreamSub;
  Timer? _durationTimer;
  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;
  bool _renderersInitialized = false;
  // Video polish: draggable PiP position (null = default top-right)
  double? _pipLeft;
  double? _pipTop;
  static const double _pipWidth = 120;
  static const double _pipHeight = 160;
  // Tap to swap main/PiP: when false, main = local, PiP = remote
  bool _mainIsRemote = true;
  bool _reconnecting = false;
  bool _weakNetwork = false;
  bool _handRaised = false;
  bool _remoteHandRaised = false;
  String? _lastReactionEmoji;
  Timer? _reactionClearTimer;
  Timer? _overlayHideTimer;
  bool _overlayVisible = true;
  final FriendService _friendService = FriendService();
  StreamSubscription<RTCIceConnectionState>? _iceStateSub;
  StreamSubscription<CallReactionEvent>? _reactionSub;
  StreamSubscription<RaiseHandEvent>? _raiseHandSub;
  StreamSubscription<ParticipantAddedEvent>? _participantAddedSub;
  final List<ParticipantAddedEvent> _extraParticipants = [];
  StreamSubscription<Map<String, dynamic>>? _iceCandidateSub;
  StreamSubscription<SignalingAnswerEvent>? _signalingAnswerSub;
  StreamSubscription<SignalingIceCandidateEvent>? _signalingIceSub;
  StreamSubscription<SignalingOfferEvent>? _signalingOfferSub;
  bool _screenSharing = false;

  @override
  void initState() {
    super.initState();
    _channelListen();
    _channelSignalingForReconnect();
    _iceReconnectListen();
    _reactionAndRaiseHandListen();
    _bindStreams();
    _startOverlayHideTimer();
    if (widget.callState.status == CallStatus.connected) {
      _startDurationTimer();
    }
    if (widget.callState.isVideo) {
      _initRenderersIfNeeded();
    }
    widget.callState.addListener(_onStateChanged);
  }

  void _startOverlayHideTimer() {
    _overlayHideTimer?.cancel();
    _overlayHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _overlayVisible = false);
    });
  }

  void _reactionAndRaiseHandListen() {
    final channel = widget.channelService;
    if (channel == null) return;
    _reactionSub = channel.onCallReaction.listen((e) {
      if (e.callId != widget.callId) return;
      if (mounted) {
        setState(() {
          _lastReactionEmoji = e.emoji;
          _reactionClearTimer?.cancel();
          _reactionClearTimer = Timer(const Duration(seconds: 2), () {
            if (mounted) setState(() => _lastReactionEmoji = null);
          });
        });
      }
    });
    _raiseHandSub = channel.onRaiseHand.listen((e) {
      if (e.callId != widget.callId) return;
      if (mounted) setState(() => _remoteHandRaised = e.raised);
    });
    _participantAddedSub = channel.onParticipantAdded.listen((e) {
      if (e.callId != widget.callId) return;
      if (mounted) {
        setState(() {
          if (!_extraParticipants.any((p) => p.userId == e.userId)) {
            _extraParticipants.add(e);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${e.userName ?? 'Someone'} joined')),
        );
      }
    });
  }

  void _onStateChanged() {
    if (widget.callState.status == CallStatus.connected && _durationTimer == null) {
      _startDurationTimer();
    }
    if (mounted) setState(() {});
  }

  void _channelListen() {
    _endedSub = widget.channelService?.onCallEnded.listen((event) {
      if (event.callId == widget.callId && mounted) {
        _cleanupAndPop();
      }
    });
  }

  void _channelSignalingForReconnect() {
    final channel = widget.channelService;
    if (channel == null) return;
    _signalingAnswerSub = channel.onSignalingAnswer.listen((event) {
      if (event.callId != widget.callId || event.sdp == null) return;
      widget.webrtcService.setRemoteAnswer(event.sdp!);
    });
    _signalingOfferSub = channel.onSignalingOffer.listen((event) async {
      if (event.callId != widget.callId || event.sdp == null) return;
      final answer = await widget.webrtcService.setRemoteOfferAndCreateAnswer(event.sdp!);
      if (answer != null && mounted) {
        await widget.signalingService.sendSignaling(
          callId: widget.callId,
          type: 'answer',
          sdp: answer,
          authToken: widget.authToken,
          userId: widget.currentUserId,
        );
      }
    });
    _signalingIceSub = channel.onSignalingIceCandidate.listen((event) {
      if (event.callId != widget.callId || event.candidate == null) return;
      widget.webrtcService.addIceCandidate(event.candidate!);
    });
    _iceCandidateSub = widget.webrtcService.onIceCandidate.listen((candidate) {
      widget.signalingService.sendSignaling(
        callId: widget.callId,
        type: 'ice_candidate',
        candidate: candidate,
        authToken: widget.authToken,
        userId: widget.currentUserId,
      );
    });
  }

  void _iceReconnectListen() {
    _iceStateSub = widget.webrtcService.onIceConnectionState.listen((state) async {
      if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        if (!mounted) return;
        setState(() => _reconnecting = true);
        try {
          final offer = await widget.webrtcService.createOfferIceRestart();
          if (offer != null && mounted) {
            await widget.signalingService.sendSignaling(
              callId: widget.callId,
              type: 'offer',
              sdp: offer,
              authToken: widget.authToken,
              userId: widget.currentUserId,
            );
          }
        } catch (_) {}
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
        if (mounted) {
          setState(() {
            _reconnecting = false;
            _weakNetwork = false;
          });
        }
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        if (mounted && !_reconnecting) {
          setState(() => _weakNetwork = true);
        }
      }
    });
  }

  void _bindStreams() {
    _remoteStreamSub = widget.webrtcService.onRemoteStream.listen((stream) {
      widget.callState.setRemoteStream(stream);
      _initRenderersIfNeeded();
      if (mounted) setState(() {});
    });
    final remote = widget.webrtcService.remoteStream;
    if (remote != null) {
      widget.callState.setRemoteStream(remote);
      _initRenderersIfNeeded();
    }
    if (mounted) setState(() {});
  }

  Future<void> _initRenderersIfNeeded() async {
    if (!widget.callState.isVideo || _renderersInitialized) return;
    _localRenderer = RTCVideoRenderer();
    _remoteRenderer = RTCVideoRenderer();
    await _localRenderer!.initialize();
    await _remoteRenderer!.initialize();
    _localRenderer!.srcObject = widget.webrtcService.localStream;
    _remoteRenderer!.srcObject = widget.webrtcService.remoteStream;
    _renderersInitialized = true;
    if (mounted) setState(() {});
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (widget.callState.status != CallStatus.connected) return;
      final d = widget.callState.connectedDuration;
      widget.callState.setConnectedDuration(Duration(seconds: d.inSeconds + 1));
    });
  }

  Future<void> _endCall() async {
    await widget.signalingService.endCall(
      callId: widget.callId,
      authToken: widget.authToken,
      userId: widget.currentUserId,
    );
    _cleanupAndPop();
  }

  /// Leave call without ending for others (Phase 2). Use for group calls.
  Future<void> _leaveCall() async {
    await widget.signalingService.leaveCall(
      callId: widget.callId,
      authToken: widget.authToken,
      userId: widget.currentUserId,
    );
    _cleanupAndPop();
  }

  void _cleanupAndPop() {
    _durationTimer?.cancel();
    _endedSub?.cancel();
    _iceStateSub?.cancel();
    _iceCandidateSub?.cancel();
    _signalingAnswerSub?.cancel();
    _signalingOfferSub?.cancel();
    _signalingIceSub?.cancel();
    _remoteStreamSub?.cancel();
    widget.callState.removeListener(_onStateChanged);
    widget.webrtcService.dispose();
    widget.channelService?.disconnect();
    widget.callState.reset();
    widget.onCallEnded?.call();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _overlayHideTimer?.cancel();
    _reactionClearTimer?.cancel();
    _endedSub?.cancel();
    _iceStateSub?.cancel();
    _reactionSub?.cancel();
    _raiseHandSub?.cancel();
    _participantAddedSub?.cancel();
    _iceCandidateSub?.cancel();
    _signalingAnswerSub?.cancel();
    _signalingOfferSub?.cancel();
    _signalingIceSub?.cancel();
    _remoteStreamSub?.cancel();
    widget.callState.removeListener(_onStateChanged);
    _localRenderer?.dispose();
    _remoteRenderer?.dispose();
    super.dispose();
  }

  String get _durationText {
    final d = widget.callState.connectedDuration;
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.callState;
    final name = state.remoteUser?.displayName ?? 'User';
    final avatarUrl = state.remoteUser?.avatarUrl;

    if (state.isVideo) {
      return _buildVideoLayout(name, avatarUrl);
    }
    return _buildVoiceLayout(name, avatarUrl);
  }

  Widget _buildVoiceLayout(String name, String? avatarUrl) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: SafeArea(
        child: Column(
          children: [
            // Header: name, status/timer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: () => _endCall(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _reconnecting
                              ? 'Reconnecting…'
                              : (widget.callState.status == CallStatus.connected
                                  ? _durationText
                                  : 'Connecting…'),
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Center avatar
            UserAvatar(
              photoUrl: avatarUrl,
              name: name,
              radius: 70,
            ),
            const Spacer(),
            // Bottom bar: Mute, Speaker, Add, End
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _controlButton(
                  icon: widget.callState.isMuted ? Icons.mic_off : Icons.mic,
                  label: widget.callState.isMuted ? 'Unmute' : 'Mute',
                  onPressed: () {
                    widget.callState.setMuted(!widget.callState.isMuted);
                    widget.webrtcService.setMicrophoneEnabled(!widget.callState.isMuted);
                  },
                ),
                _controlButton(
                  icon: widget.callState.isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                  label: 'Speaker',
                  onPressed: () async {
                    final next = !widget.callState.isSpeakerOn;
                    widget.callState.setSpeakerOn(next);
                    try {
                      await Helper.setSpeakerphoneOn(next);
                    } catch (_) {
                      // Ignore on unsupported platforms (e.g. web)
                    }
                  },
                ),
                _controlButton(
                  icon: Icons.person_add,
                  label: 'Add',
                  onPressed: _showAddParticipantSheet,
                ),
                _controlButton(
                  icon: Icons.exit_to_app,
                  label: 'Leave',
                  onPressed: _leaveCall,
                ),
                _controlButton(
                  icon: Icons.call_end,
                  label: 'End',
                  backgroundColor: Colors.red,
                  onPressed: _endCall,
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoLayout(String name, String? avatarUrl) {
    final mainRenderer = _mainIsRemote ? _remoteRenderer : _localRenderer;
    final pipRenderer = _mainIsRemote ? _localRenderer : _remoteRenderer;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final defaultPipLeft = w - _pipWidth - 16;
        final defaultPipTop = 48.0;
        final pipLeft = _pipLeft ?? defaultPipLeft;
        final pipTop = _pipTop ?? defaultPipTop;
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Main video: tap = show overlay + swap, double-tap = focus feedback (02 § 3.2)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _overlayVisible = true;
                      _mainIsRemote = !_mainIsRemote;
                    });
                    _startOverlayHideTimer();
                  },
                  onDoubleTap: () {
                    setState(() => _overlayVisible = true);
                    _startOverlayHideTimer();
                  },
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: mainRenderer != null && _renderersInitialized
                        ? RTCVideoView(
                            mainRenderer,
                            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                          )
                        : Center(
                            child: UserAvatar(photoUrl: avatarUrl, name: name, radius: 60),
                          ),
                  ),
                ),
                // Self PiP: draggable, tap to swap
                if (pipRenderer != null && _renderersInitialized)
                  Positioned(
                    left: pipLeft.clamp(0.0, w - _pipWidth),
                    top: pipTop.clamp(0.0, h - _pipHeight - 80),
                    width: _pipWidth,
                    height: _pipHeight,
                    child: GestureDetector(
                      onTap: () => setState(() => _mainIsRemote = !_mainIsRemote),
                      onPanUpdate: (details) {
                        setState(() {
                          _pipLeft = (pipLeft + details.delta.dx).clamp(0.0, w - _pipWidth);
                          _pipTop = (pipTop + details.delta.dy).clamp(0.0, h - _pipHeight - 80);
                        });
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: RTCVideoView(
                          pipRenderer,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        ),
                      ),
                    ),
                  ),
            // Reconnecting banner
            if (_reconnecting)
              Positioned(
                top: 8,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Reconnecting…',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            // Weak network banner (02 § 2.5 optional)
            if (_weakNetwork && !_reconnecting)
              Positioned(
                top: _reconnecting ? 48 : 8,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.signal_cellular_alt, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Weak network',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            // Incoming reaction overlay (4.F.1)
            if (_lastReactionEmoji != null)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Text(
                    _lastReactionEmoji!,
                    style: const TextStyle(fontSize: 80),
                  ),
                ),
              ),
            // Remote raise hand icon on tile (4.F.2)
            if (_remoteHandRaised)
              Positioned(
                top: (_reconnecting ? 48 : 8) + 40,
                right: 24,
                child: const Icon(Icons.back_hand, color: Colors.white, size: 32),
              ),
            // Top overlay: name, timer (auto-hide after 3s, show on tap — 02 § 3.2)
            if (_overlayVisible)
              Positioned(
                top: (_reconnecting || _weakNetwork) ? 48 : 8,
                left: 16,
                right: 80,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _overlayVisible = true);
                    _startOverlayHideTimer();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _reconnecting ? 'Reconnecting…' : _durationText,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Bottom bar: Mute, Camera, End, Add, More (auto-hide with overlay)
            if (_overlayVisible)
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _controlButton(
                    icon: widget.callState.isMuted ? Icons.mic_off : Icons.mic,
                    label: 'Mute',
                    onPressed: () {
                      widget.callState.setMuted(!widget.callState.isMuted);
                      widget.webrtcService.setMicrophoneEnabled(!widget.callState.isMuted);
                    },
                  ),
                  _controlButton(
                    icon: widget.callState.isCameraOff ? Icons.videocam_off : Icons.videocam,
                    label: 'Camera',
                    onPressed: () {
                      widget.callState.setCameraOff(!widget.callState.isCameraOff);
                      widget.webrtcService.setCameraEnabled(!widget.callState.isCameraOff);
                    },
                  ),
                  _controlButton(
                    icon: Icons.call_end,
                    label: 'End',
                    backgroundColor: Colors.red,
                    onPressed: _endCall,
                  ),
                  _controlButton(
                    icon: Icons.person_add,
                    label: 'Add',
                    onPressed: _showAddParticipantSheet,
                  ),
                  _controlButton(
                    icon: Icons.exit_to_app,
                    label: 'Leave',
                    onPressed: _leaveCall,
                  ),
                  _controlButton(
                    icon: Icons.more_horiz,
                    label: 'More',
                    onPressed: _showMoreMenu,
                  ),
                ],
              ),
            ),
            ],
        ),
      ),
        );
      },
    );
  }

  void _showAddParticipantSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => FutureBuilder<FriendListResult>(
        future: _friendService.getFriends(userId: widget.currentUserId, perPage: 50),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) {
            return const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          final result = snapshot.data!;
          final list = result.success ? result.friends : <UserProfile>[];
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Add participant', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
                Flexible(
                  child: list.isEmpty
                      ? const Padding(padding: EdgeInsets.all(24), child: Text('No contacts'))
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: list.length,
                          itemBuilder: (ctx, index) {
                            final u = list[index];
                            return ListTile(
                              leading: UserAvatar(photoUrl: u.profilePhotoUrl, name: u.fullName, radius: 24),
                              title: Text(u.fullName),
                              onTap: () async {
                                Navigator.pop(ctx);
                                final ok = await widget.signalingService.addParticipant(
                                  callId: widget.callId,
                                  newUserId: u.id,
                                  authToken: widget.authToken,
                                  userId: widget.currentUserId,
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(ok ? 'Invitation sent to ${u.fullName}' : 'Failed to add participant'),
                                    ),
                                  );
                                }
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

  void _showMoreMenu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.callState.isVideo)
              ListTile(
                leading: const Icon(Icons.cameraswitch),
                title: const Text('Switch camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  try {
                    final stream = widget.webrtcService.localStream;
                    final videoTracks = stream?.getVideoTracks();
                    if (videoTracks != null && videoTracks.isNotEmpty) {
                      Helper.switchCamera(videoTracks.first);
                    }
                  } catch (_) {}
                },
              ),
            ListTile(
              leading: Icon(_screenSharing ? Icons.stop_screen_share : Icons.screen_share),
              title: Text(_screenSharing ? 'Stop sharing' : 'Share screen'),
              onTap: () async {
                Navigator.pop(ctx);
                if (_screenSharing) {
                  final offer = await widget.webrtcService.stopScreenShare();
                  if (offer != null && mounted) {
                    setState(() => _screenSharing = false);
                    await widget.signalingService.sendSignaling(
                      callId: widget.callId,
                      type: 'offer',
                      sdp: offer,
                      authToken: widget.authToken,
                      userId: widget.currentUserId,
                    );
                  }
                } else {
                  final offer = await widget.webrtcService.startScreenShare();
                  if (offer != null && mounted) {
                    setState(() => _screenSharing = true);
                    await widget.signalingService.sendSignaling(
                      callId: widget.callId,
                      type: 'offer',
                      sdp: offer,
                      authToken: widget.authToken,
                      userId: widget.currentUserId,
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: Icon(_handRaised ? Icons.back_hand : Icons.back_hand_outlined),
              title: Text(_handRaised ? 'Lower hand' : 'Raise hand'),
              onTap: () async {
                setState(() => _handRaised = !_handRaised);
                Navigator.pop(ctx);
                await widget.signalingService.sendRaiseHand(
                  callId: widget.callId,
                  raised: _handRaised,
                  authToken: widget.authToken,
                  userId: widget.currentUserId,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_emotions_outlined),
              title: const Text('Send reaction'),
              onTap: () {
                Navigator.pop(ctx);
                _showReactionPicker(ctx);
              },
            ),
            if (widget.callState.isVideo)
              ListTile(
                leading: const Icon(Icons.auto_fix_high),
                title: const Text('Video effects'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Video effects coming soon')),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showReactionPicker(BuildContext context) {
    const emojis = ['👍', '❤️', '😂', '👏', '🙌'];
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: emojis.map((emoji) {
              return IconButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await widget.signalingService.sendReaction(
                    callId: widget.callId,
                    emoji: emoji,
                    authToken: widget.authToken,
                    userId: widget.currentUserId,
                  );
                },
                icon: Text(emoji, style: const TextStyle(fontSize: 32)),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    Color? backgroundColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: backgroundColor ?? Colors.white24,
          shape: const CircleBorder(),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 28),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

