// Video & Audio Calls — Outgoing call flow (docs/video-audio-calls, 1.F.10)
// Create call → subscribe WS → init PC → wait for CallAccepted → create offer → send → wait for answer/ICE → show ActiveCallScreen.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../calls/call_state.dart';
import '../../calls/call_channel_service.dart';
import '../../services/call_signaling_service.dart';
import '../../services/call_webrtc_service.dart';
import '../../widgets/user_avatar.dart';
import 'active_call_screen.dart';

class OutgoingCallFlowScreen extends StatefulWidget {
  final int currentUserId;
  final String? authToken;
  final int calleeId;
  final String calleeName;
  final String? calleeAvatarUrl;
  final String type; // voice | video
  /// When starting a scheduled call, backend returns call_id + ice_servers; pass them to skip create.
  final String? existingCallId;
  final List<Map<String, dynamic>>? existingIceServers;

  const OutgoingCallFlowScreen({
    super.key,
    required this.currentUserId,
    this.authToken,
    required this.calleeId,
    required this.calleeName,
    this.calleeAvatarUrl,
    required this.type,
    this.existingCallId,
    this.existingIceServers,
  });

  @override
  State<OutgoingCallFlowScreen> createState() => _OutgoingCallFlowScreenState();
}

class _OutgoingCallFlowScreenState extends State<OutgoingCallFlowScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  final CallState _callState = CallState();
  final CallSignalingService _signaling = CallSignalingService();
  final CallChannelService _channel = CallChannelService();
  final CallWebRTCService _webrtc = CallWebRTCService();

  StreamSubscription? _answerSub;
  StreamSubscription? _acceptedSub;
  StreamSubscription? _iceSub;
  StreamSubscription? _rejectedSub;
  StreamSubscription? _endedSub;
  StreamSubscription? _iceCandidateSub;
  StreamSubscription? _remoteStreamSub;
  StreamSubscription? _connectionStateSub;
  StreamSubscription? _iceConnectionStateSub;
  Timer? _noAnswerTimer;
  bool _disposed = false;
  bool _navigatedToActive = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startCall();
  }

  Future<void> _startCall() async {
    final token = widget.authToken;
    final userId = widget.currentUserId;

    debugPrint('[CallFlow][Outgoing] START ${widget.type} call to ${widget.calleeName} (${widget.calleeId})');

    // Request permissions before creating call (spec 1.F.10)
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (!_disposed && mounted) {
        _callState.setError('Microphone permission required');
        await _popAfterDelay();
      }
      return;
    }
    if (widget.type == 'video') {
      final camera = await Permission.camera.request();
      if (!camera.isGranted) {
        if (!_disposed && mounted) {
          _callState.setError('Camera permission required for video call');
          await _popAfterDelay();
        }
        return;
      }
    }

    _callState.startOutgoing(
      callId: widget.existingCallId ?? '',
      remoteUser: RemoteUserInfo(
        userId: widget.calleeId,
        displayName: widget.calleeName,
        avatarUrl: widget.calleeAvatarUrl,
      ),
      type: widget.type,
    );

    String callId;
    List<Map<String, dynamic>> iceServers;

    if (widget.existingCallId != null && widget.existingCallId!.isNotEmpty) {
      callId = widget.existingCallId!;
      _callState.setCallId(callId);
      iceServers = widget.existingIceServers ?? [];
      if (iceServers.isEmpty) {
        final turnResp = await _signaling.getTurnCredentials(authToken: token, userId: userId);
        if (turnResp.success) iceServers = turnResp.iceServers;
      }
    } else {
      final createResp = await _signaling.createCall(
        calleeId: widget.calleeId,
        type: widget.type,
        authToken: token,
        userId: userId,
      );
      if (!createResp.success || createResp.callId == null || createResp.callId!.isEmpty) {
        if (!_disposed && mounted) {
          _callState.setError(createResp.message ?? 'Failed to create call');
          await _popAfterDelay();
        }
        return;
      }
      callId = createResp.callId!;
      _callState.setCallId(callId);
      iceServers = createResp.iceServers;
      if (iceServers.isEmpty) {
        final turnResp = await _signaling.getTurnCredentials(authToken: token, userId: userId);
        if (turnResp.success) iceServers = turnResp.iceServers;
      }
    }

    debugPrint('[CallFlow][Outgoing] callId=$callId, iceServers=${iceServers.length}');
    if (_disposed) return;

    // Subscribe to channel
    final wsSubscribed = await _channel.subscribe(
      callId: callId,
      authToken: token,
      userId: userId,
    );
    if (_disposed) return;

    if (wsSubscribed) {
      _answerSub = _channel.onSignalingAnswer.listen((e) {
        if (e.callId != callId) return;
        if (e.fromUserId == userId) return; // ignore own echo
        _onRemoteAnswer(e.sdp);
      });
      _acceptedSub = _channel.onCallAccepted.listen((e) async {
        if (e.callId != callId) return;
        _noAnswerTimer?.cancel();
        _callState.setConnecting();
        if (e.sdpAnswer != null) {
          _onRemoteAnswer(e.sdpAnswer);
        } else {
          debugPrint('[CallFlow][Outgoing] CallAccepted — creating offer');
          final offer = await _webrtc.createOffer();
          if (_disposed) return;
          if (offer != null) {
            await _signaling.sendSignaling(
              callId: callId,
              type: 'offer',
              sdp: offer,
              authToken: token,
              userId: userId,
            );
          }
        }
      });
      _iceSub = _channel.onSignalingIceCandidate.listen((e) {
        if (e.callId != callId) return;
        if (e.fromUserId == userId) return;
        _onRemoteIce(e.candidate);
      });
      _rejectedSub = _channel.onCallRejected.listen((e) {
        if (e.callId != callId) return;
        if (!_disposed && mounted) {
          _callState.setRejected();
          _cleanup();
          Navigator.of(context).pop();
        }
      });
      _endedSub = _channel.onCallEnded.listen((e) {
        if (e.callId != callId) return;
        if (!_disposed && mounted) {
          _cleanup();
          Navigator.of(context).pop();
        }
      });
    } else {
      debugPrint('[CallFlow][Outgoing] ✗ WebSocket failed — REST only');
    }

    // Init peer connection + getUserMedia
    try {
      await _webrtc.initPeerConnection(iceServers);
    } catch (e) {
      if (!_disposed && mounted) {
        _callState.setError('Failed to create peer connection: $e');
        await _popAfterDelay();
      }
      return;
    }

    try {
      await _webrtc.getUserMedia(video: widget.type == 'video');
    } catch (e) {
      if (!_disposed && mounted) {
        _callState.setError('Failed to get media: $e');
        await _popAfterDelay();
      }
      return;
    }

    if (_disposed) return;
    await _webrtc.addLocalStreamToPeerConnection();
    if (_disposed) return;

    _callState.setLocalStream(_webrtc.localStream);

    // Set up listeners; ICE candidates fire after offer is created in onCallAccepted.
    _iceCandidateSub = _webrtc.onIceCandidate.listen((candidate) {
      _signaling.sendSignaling(
        callId: callId,
        type: 'ice_candidate',
        candidate: candidate,
        authToken: token,
        userId: userId,
      );
    });

    _remoteStreamSub = _webrtc.onRemoteStream.listen((stream) {
      _callState.setRemoteStream(stream);
    });

    _connectionStateSub = _webrtc.onConnectionState.listen((state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected && !_disposed && mounted) {
        debugPrint('[CallFlow][Outgoing] CONNECTED');
        _noAnswerTimer?.cancel();
        _callState.setConnected();
        _navigateToActiveCall();
      }
    });
    _iceConnectionStateSub = _webrtc.onIceConnectionState.listen((state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected && !_disposed && mounted) {
        _noAnswerTimer?.cancel();
        _callState.setConnected();
        _navigateToActiveCall();
      }
    });

    // No-answer timeout (45 seconds)
    _noAnswerTimer = Timer(const Duration(seconds: 45), () {
      if (!_disposed && mounted && _callState.status != CallStatus.connected) {
        _callState.setNoAnswer();
        _endCall();
      }
    });

    debugPrint('[CallFlow][Outgoing] Setup complete — waiting for answer');
  }

  void _onRemoteAnswer(Map<String, dynamic>? sdp) async {
    if (sdp == null) return;
    try {
      await _webrtc.setRemoteAnswer(sdp);
    } catch (e) {
      debugPrint('[CallFlow][Outgoing] ✗ setRemoteAnswer: $e');
    }
  }

  void _onRemoteIce(Map<String, dynamic>? candidate) async {
    if (candidate == null) return;
    try {
      await _webrtc.addIceCandidate(candidate);
    } catch (e) {
      debugPrint('[CallFlow][Outgoing] ✗ addIceCandidate: $e');
    }
  }

  void _navigateToActiveCall() {
    if (_navigatedToActive || _disposed || !mounted) return;
    _navigatedToActive = true;
    final callId = _callState.callId;
    if (callId == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ActiveCallScreen(
          callState: _callState,
          webrtcService: _webrtc,
          signalingService: _signaling,
          channelService: _channel,
          callId: callId,
          currentUserId: widget.currentUserId,
          authToken: widget.authToken,
        ),
      ),
    );
  }

  Future<void> _endCall() async {
    if (_disposed) return; // Already handled by WS listener
    final callId = _callState.callId;
    debugPrint('[CallFlow][Outgoing] _endCall callId=$callId');
    // Cancel WS listeners BEFORE the API call to prevent double-pop race
    _endedSub?.cancel();
    _rejectedSub?.cancel();
    if (callId != null) {
      await _signaling.endCall(callId: callId, authToken: widget.authToken, userId: widget.currentUserId);
    }
    if (_disposed) return; // Guard against disposal during await
    _cleanup();
    if (mounted) Navigator.of(context).pop();
  }

  void _cleanup() {
    _disposed = true;
    _noAnswerTimer?.cancel();
    _answerSub?.cancel();
    _acceptedSub?.cancel();
    _iceSub?.cancel();
    _rejectedSub?.cancel();
    _endedSub?.cancel();
    _iceCandidateSub?.cancel();
    _remoteStreamSub?.cancel();
    _connectionStateSub?.cancel();
    _iceConnectionStateSub?.cancel();
    _webrtc.dispose();
    _channel.disconnect();
    _callState.reset();
  }

  Future<void> _popAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    if (!_disposed) {
      if (_navigatedToActive) {
        // Resources are handed off to ActiveCallScreen — only cancel our subscriptions.
        _disposed = true;
        _noAnswerTimer?.cancel();
        _answerSub?.cancel();
        _acceptedSub?.cancel();
        _iceSub?.cancel();
        _rejectedSub?.cancel();
        _endedSub?.cancel();
        _iceCandidateSub?.cancel();
        _remoteStreamSub?.cancel();
        _connectionStateSub?.cancel();
        _iceConnectionStateSub?.cancel();
      } else {
        _cleanup();
      }
    }
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _callState,
      builder: (context, _) {
        final name = _callState.remoteUser?.displayName ?? widget.calleeName;
        final avatarUrl = _callState.remoteUser?.avatarUrl ?? widget.calleeAvatarUrl;
        final status = _callState.status;

        String statusText = 'Calling…';
        if (status == CallStatus.rejected) {
          statusText = 'Declined';
        } else if (status == CallStatus.noAnswer) {
          statusText = 'No answer';
        } else if (status == CallStatus.connecting) {
          statusText = 'Connecting…';
        } else if (status == CallStatus.connected) {
          statusText = 'Connected';
        } else if (status == CallStatus.error) {
          statusText = _callState.errorMessage ?? 'Error';
        }

        final bool isCalling = status == CallStatus.ringing ||
            status == CallStatus.idle ||
            status == CallStatus.pending;

        return Scaffold(
          backgroundColor: const Color(0xFF1A1A1A),
          body: SafeArea(
            child: Column(
              children: [
                // Top bar with back arrow and label
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: IconButton(
                          onPressed: _endCall,
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Outgoing Call',
                        style: TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Avatar with pulse animation during calling state
                ScaleTransition(
                  scale: isCalling ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                  child: UserAvatar(photoUrl: avatarUrl, name: name, radius: 60),
                ),
                const SizedBox(height: 24),
                // Callee name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    statusText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const Spacer(),
                // End call button
                Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: Material(
                          color: const Color(0xFF2A2A2A),
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: _endCall,
                            child: Icon(
                              Icons.call_end_rounded,
                              color: Colors.red.shade400,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'End Call',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
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
}
