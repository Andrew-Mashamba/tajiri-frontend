// Video & Audio Calls — Active call UI (docs/video-audio-calls, 02-ui-spec, 1.F.12, 1.F.13)
// Voice: header, avatar, bottom bar (Mute, Speaker, Add, End). Video: full-screen remote, PiP self, bottom bar.

import 'dart:async';
import 'dart:ui';
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

/// Network quality levels for adaptive bandwidth (Feature #21).
enum NetworkQuality { good, medium, poor }

class _ActiveCallScreenState extends State<ActiveCallScreen>
    with SingleTickerProviderStateMixin {
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
  bool _popped = false;
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

  // Feature #22: Pinch-to-zoom on remote video
  double _currentScale = 1.0;
  double _baseScale = 1.0;

  // Feature #21: Adaptive bandwidth — network quality monitoring
  NetworkQuality _networkQuality = NetworkQuality.good;
  Timer? _bandwidthStatsTimer;

  // Avatar ring animation for connected state
  late AnimationController _avatarRingController;

  @override
  void initState() {
    super.initState();
    _avatarRingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _channelListen();
    _channelSignalingForReconnect();
    _iceReconnectListen();
    _reactionAndRaiseHandListen();
    _bindStreams();
    _startOverlayHideTimer();
    _startBandwidthMonitor();
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
        if (!_reconnecting) {
          // Show weak network immediately, then attempt ICE restart
          setState(() {
            _weakNetwork = true;
            _reconnecting = true;
          });
        } else {
          setState(() => _reconnecting = true);
        }
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
      // Defer to avoid notifyListeners during build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.callState.setRemoteStream(remote);
        _initRenderersIfNeeded();
        if (mounted) setState(() {});
      });
    }
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

  // ── Feature #21: Adaptive bandwidth monitoring ──────────────────────
  void _startBandwidthMonitor() {
    _bandwidthStatsTimer?.cancel();
    _bandwidthStatsTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final pc = widget.webrtcService.peerConnection;
      if (pc == null) return;
      try {
        final stats = await pc.getStats();
        int totalPacketsLost = 0;
        int totalPacketsSent = 0;
        for (final report in stats) {
          final values = report.values;
          if (report.type == 'outbound-rtp' && values['kind'] == 'video') {
            totalPacketsSent += (values['packetsSent'] as int?) ?? 0;
          }
          if (report.type == 'remote-inbound-rtp' && values['kind'] == 'video') {
            totalPacketsLost += (values['packetsLost'] as int?) ?? 0;
          }
        }
        // Calculate packet loss ratio
        final totalPackets = totalPacketsSent + totalPacketsLost;
        final lossPercent = totalPackets > 0 ? (totalPacketsLost / totalPackets) * 100.0 : 0.0;

        NetworkQuality newQuality;
        if (lossPercent > 5.0) {
          newQuality = NetworkQuality.poor;
        } else if (lossPercent > 2.0) {
          newQuality = NetworkQuality.medium;
        } else {
          newQuality = NetworkQuality.good;
        }

        if (mounted && newQuality != _networkQuality) {
          setState(() => _networkQuality = newQuality);
        }

        // Adjust bitrate via sender parameters
        _adaptBitrate(newQuality);
      } catch (_) {
        // Stats unavailable — keep current quality
      }
    });
  }

  Future<void> _adaptBitrate(NetworkQuality quality) async {
    final pc = widget.webrtcService.peerConnection;
    if (pc == null) return;
    int targetBitrate;
    switch (quality) {
      case NetworkQuality.good:
        targetBitrate = 1500000; // 1500 kbps
      case NetworkQuality.medium:
        targetBitrate = 800000; // 800 kbps
      case NetworkQuality.poor:
        targetBitrate = 400000; // 400 kbps
    }
    try {
      final senders = await pc.getSenders();
      for (final sender in senders) {
        if (sender.track?.kind == 'video') {
          final params = sender.parameters;
          if (params.encodings != null && params.encodings!.isNotEmpty) {
            params.encodings!.first.maxBitrate = targetBitrate;
            await sender.setParameters(params);
          }
          break;
        }
      }
    } catch (_) {
      // Sender parameter adjustment not supported — ignore
    }
  }

  /// Build a small network quality bars indicator (Feature #21).
  Widget _buildNetworkQualityIndicator() {
    final Color activeBarColor;
    final int activeBars;
    switch (_networkQuality) {
      case NetworkQuality.good:
        activeBarColor = Colors.white;
        activeBars = 3;
      case NetworkQuality.medium:
        activeBarColor = Colors.white60;
        activeBars = 2;
      case NetworkQuality.poor:
        activeBarColor = Colors.white30;
        activeBars = 1;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        final height = 6.0 + (i * 4.0); // 6, 10, 14
        final isActive = i < activeBars;
        return Container(
          width: 4,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: isActive ? activeBarColor : Colors.white10,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
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
    if (_popped) return; // Already handled by WS listener
    // Cancel WS listener BEFORE the API call to prevent double-pop race
    _endedSub?.cancel();
    await widget.signalingService.endCall(
      callId: widget.callId,
      authToken: widget.authToken,
      userId: widget.currentUserId,
    );
    _cleanupAndPop();
  }

  /// Leave call without ending for others (Phase 2). Use for group calls.
  Future<void> _leaveCall() async {
    if (_popped) return;
    _endedSub?.cancel();
    await widget.signalingService.leaveCall(
      callId: widget.callId,
      authToken: widget.authToken,
      userId: widget.currentUserId,
    );
    _cleanupAndPop();
  }

  void _cleanupAndPop() {
    if (_popped) return; // Prevent double-pop race condition
    _popped = true;
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
    _bandwidthStatsTimer?.cancel();
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
    _avatarRingController.dispose();
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
    final isConnected = widget.callState.status == CallStatus.connected;
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          children: [
            // Duration pill chip at top
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _reconnecting
                        ? 'Reconnecting...'
                        : isConnected
                            ? _durationText
                            : 'Connecting...',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildNetworkQualityIndicator(),
                ],
              ),
            ),
            // Header: back arrow + name + status
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 0),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                      onPressed: () => _endCall(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _reconnecting
                              ? 'Reconnecting...'
                              : isConnected
                                  ? 'Voice call'
                                  : 'Connecting...',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Center avatar with subtle ring animation when connected
            AnimatedBuilder(
              animation: _avatarRingController,
              builder: (context, child) {
                final animValue = _avatarRingController.value;
                final ringOpacity = isConnected ? (0.15 + 0.15 * (1.0 - animValue)) : 0.0;
                final ringScale = isConnected ? 1.0 + (0.08 * animValue) : 1.0;
                return Transform.scale(
                  scale: ringScale,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(ringOpacity),
                        width: 3,
                      ),
                    ),
                    child: child,
                  ),
                );
              },
              child: UserAvatar(
                photoUrl: avatarUrl,
                name: name,
                radius: 70,
              ),
            ),
            const Spacer(),
            // Bottom bar: Mute, Speaker, Add, Leave, End
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _controlButton(
                    icon: widget.callState.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    label: widget.callState.isMuted ? 'Unmute' : 'Mute',
                    isActive: widget.callState.isMuted,
                    onPressed: () {
                      widget.callState.setMuted(!widget.callState.isMuted);
                      widget.webrtcService.setMicrophoneEnabled(!widget.callState.isMuted);
                    },
                  ),
                  _controlButton(
                    icon: widget.callState.isSpeakerOn
                        ? Icons.volume_up_rounded
                        : Icons.volume_down_rounded,
                    label: 'Speaker',
                    isActive: widget.callState.isSpeakerOn,
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
                    icon: Icons.person_add_rounded,
                    label: 'Add',
                    onPressed: _showAddParticipantSheet,
                  ),
                  _controlButton(
                    icon: Icons.exit_to_app_rounded,
                    label: 'Leave',
                    onPressed: _leaveCall,
                  ),
                  _controlButton(
                    icon: Icons.call_end_rounded,
                    label: 'End',
                    isDestructive: true,
                    onPressed: _endCall,
                  ),
                ],
              ),
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
                // Main video: tap = show overlay + swap, pinch-to-zoom (#22), double-tap = reset zoom
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _overlayVisible = true;
                      _mainIsRemote = !_mainIsRemote;
                    });
                    _startOverlayHideTimer();
                  },
                  onDoubleTap: () {
                    setState(() {
                      _currentScale = 1.0;
                      _overlayVisible = true;
                    });
                    _startOverlayHideTimer();
                  },
                  onScaleStart: (details) => _baseScale = _currentScale,
                  onScaleUpdate: (details) {
                    setState(() {
                      _currentScale = (_baseScale * details.scale).clamp(1.0, 4.0);
                    });
                  },
                  onScaleEnd: (_) {
                    // Snap back to 1x if barely zoomed
                    if (_currentScale < 1.1) {
                      setState(() => _currentScale = 1.0);
                    }
                  },
                  child: Transform.scale(
                    scale: _currentScale,
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
                // Self PiP: draggable, tap to swap — with subtle border/shadow
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
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: RTCVideoView(
                            pipRenderer,
                            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Reconnecting banner — monochromatic
                if (_reconnecting)
                  Positioned(
                    top: 8,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(12),
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
                            'Reconnecting...',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Weak network banner — monochromatic
                if (_weakNetwork && !_reconnecting)
                  Positioned(
                    top: _reconnecting ? 48 : 8,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.signal_cellular_alt_rounded, color: Colors.white.withOpacity(0.7), size: 18),
                          const SizedBox(width: 8),
                          const Text(
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
                    child: const Icon(Icons.back_hand_rounded, color: Colors.white, size: 32),
                  ),
                // Network quality indicator (Feature #21)
                Positioned(
                  top: (_reconnecting || _weakNetwork) ? 52 : 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: _buildNetworkQualityIndicator(),
                  ),
                ),
                // Top overlay: name, timer — frosted glass style (auto-hide after 3s)
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
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
                                  _reconnecting ? 'Reconnecting...' : _durationText,
                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Bottom bar: Mute, Camera, End, Add, Leave, More (auto-hide with overlay)
                if (_overlayVisible)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 24,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _controlButton(
                          icon: widget.callState.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                          label: 'Mute',
                          isActive: widget.callState.isMuted,
                          size: 48,
                          onPressed: () {
                            widget.callState.setMuted(!widget.callState.isMuted);
                            widget.webrtcService.setMicrophoneEnabled(!widget.callState.isMuted);
                          },
                        ),
                        _controlButton(
                          icon: widget.callState.isCameraOff
                              ? Icons.videocam_off_rounded
                              : Icons.videocam_rounded,
                          label: 'Camera',
                          isActive: widget.callState.isCameraOff,
                          size: 48,
                          onPressed: () {
                            widget.callState.setCameraOff(!widget.callState.isCameraOff);
                            widget.webrtcService.setCameraEnabled(!widget.callState.isCameraOff);
                          },
                        ),
                        _controlButton(
                          icon: Icons.call_end_rounded,
                          label: 'End',
                          isDestructive: true,
                          size: 48,
                          onPressed: _endCall,
                        ),
                        _controlButton(
                          icon: Icons.person_add_rounded,
                          label: 'Add',
                          size: 48,
                          onPressed: _showAddParticipantSheet,
                        ),
                        _controlButton(
                          icon: Icons.exit_to_app_rounded,
                          label: 'Leave',
                          size: 48,
                          onPressed: _leaveCall,
                        ),
                        _controlButton(
                          icon: Icons.more_horiz_rounded,
                          label: 'More',
                          size: 48,
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
      backgroundColor: const Color(0xFFFAFAFA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => FutureBuilder<FriendListResult>(
        future: _friendService.getFriends(userId: widget.currentUserId, perPage: 50),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) {
            return const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF1A1A1A))),
              ),
            );
          }
          final result = snapshot.data!;
          final list = result.success ? result.friends : <UserProfile>[];
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                // Handle bar
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF999999),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Add participant',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                Flexible(
                  child: list.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No contacts',
                            style: TextStyle(color: Color(0xFF666666)),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: list.length,
                          itemBuilder: (ctx, index) {
                            final u = list[index];
                            return ListTile(
                              leading: UserAvatar(photoUrl: u.profilePhotoUrl, name: u.fullName, radius: 24),
                              title: Text(
                                u.fullName,
                                style: const TextStyle(color: Color(0xFF1A1A1A)),
                              ),
                              trailing: const Icon(Icons.person_add_rounded, color: Color(0xFF666666)),
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
      backgroundColor: const Color(0xFFFAFAFA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // Handle bar
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF999999),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            if (widget.callState.isVideo)
              ListTile(
                leading: const Icon(Icons.cameraswitch_rounded, color: Color(0xFF1A1A1A)),
                title: const Text(
                  'Switch camera',
                  style: TextStyle(color: Color(0xFF1A1A1A)),
                ),
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
              leading: Icon(
                _screenSharing ? Icons.stop_screen_share_rounded : Icons.screen_share_rounded,
                color: const Color(0xFF1A1A1A),
              ),
              title: Text(
                _screenSharing ? 'Stop sharing' : 'Share screen',
                style: const TextStyle(color: Color(0xFF1A1A1A)),
              ),
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
              leading: Icon(
                _handRaised ? Icons.back_hand_rounded : Icons.back_hand_rounded,
                color: const Color(0xFF1A1A1A),
              ),
              title: Text(
                _handRaised ? 'Lower hand' : 'Raise hand',
                style: const TextStyle(color: Color(0xFF1A1A1A)),
              ),
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
              leading: const Icon(Icons.emoji_emotions_rounded, color: Color(0xFF1A1A1A)),
              title: const Text(
                'Send reaction',
                style: TextStyle(color: Color(0xFF1A1A1A)),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showReactionPicker(ctx);
              },
            ),
            // Video effects: Not yet implemented — hidden until ready.
          ],
        ),
      ),
    );
  }

  void _showReactionPicker(BuildContext _) {
    const emojis = ['👍', '❤️', '😂', '👏', '🙌'];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFFAFAFA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // Handle bar
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF999999),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: emojis.map((emoji) {
                  return SizedBox(
                    width: 48,
                    height: 48,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await widget.signalingService.sendReaction(
                          callId: widget.callId,
                          emoji: emoji,
                          authToken: widget.authToken,
                          userId: widget.currentUserId,
                        );
                      },
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 32)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    bool isActive = false,
    bool isDestructive = false,
    double size = 56,
  }) {
    final bgColor = isDestructive
        ? const Color(0xFF2A2A2A)
        : isActive
            ? const Color(0xFFFFFFFF)
            : const Color(0xFF2A2A2A);
    final iconColor = isDestructive
        ? Colors.red.shade400
        : isActive
            ? const Color(0xFF1A1A1A)
            : Colors.white;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Material(
            color: bgColor,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: Icon(icon, color: iconColor, size: size * 0.43),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
