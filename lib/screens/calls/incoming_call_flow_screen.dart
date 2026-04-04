// Video & Audio Calls — Incoming call flow (docs/video-audio-calls, 1.F.11)
// Show incoming UI; Accept → POST accept → subscribe → create PC → on offer answer → ActiveCallScreen.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../calls/call_state.dart';
import '../../calls/call_channel_service.dart';
import '../../services/call_signaling_service.dart';
import '../../services/call_webrtc_service.dart';
import '../../widgets/user_avatar.dart';
import '../../services/message_service.dart';
import '../messages/chat_screen.dart';
import 'active_call_screen.dart';

class IncomingCallFlowScreen extends StatefulWidget {
  final int currentUserId;
  final String? authToken;
  /// Incoming call payload (from WebSocket CallIncoming or push).
  final CallIncomingEvent incoming;

  const IncomingCallFlowScreen({
    super.key,
    required this.currentUserId,
    this.authToken,
    required this.incoming,
  });

  @override
  State<IncomingCallFlowScreen> createState() => _IncomingCallFlowScreenState();
}

class _IncomingCallFlowScreenState extends State<IncomingCallFlowScreen> {
  final CallState _callState = CallState();
  final CallSignalingService _signaling = CallSignalingService();
  final CallChannelService _channel = CallChannelService();
  final CallWebRTCService _webrtc = CallWebRTCService();
  final MessageService _messageService = MessageService();

  StreamSubscription? _offerSub;
  StreamSubscription? _iceSub;
  StreamSubscription? _endedSub;
  StreamSubscription? _iceCandidateSub;
  StreamSubscription? _remoteStreamSub;
  StreamSubscription? _connectionStateSub;
  StreamSubscription? _iceConnectionStateSub;
  bool _disposed = false;
  bool _accepting = false;
  bool _navigatedToActive = false;
  final AudioPlayer _ringtonePlayer = AudioPlayer();
  Timer? _vibrationTimer;

  @override
  void initState() {
    super.initState();
    debugPrint('[CallFlow][Incoming] ═══ INCOMING CALL ═══');
    debugPrint('[CallFlow][Incoming] callId=${widget.incoming.callId}, type=${widget.incoming.type}');
    debugPrint('[CallFlow][Incoming] callerId=${widget.incoming.callerId}, callerName=${widget.incoming.callerName}');
    debugPrint('[CallFlow][Incoming] isGroupAdd=${widget.incoming.isGroupAdd}');
    _callState.startIncoming(
      callId: widget.incoming.callId,
      remoteUser: RemoteUserInfo(
        userId: widget.incoming.callerId,
        displayName: widget.incoming.callerName,
        avatarUrl: widget.incoming.callerAvatarUrl,
      ),
      type: widget.incoming.type,
    );
    _startRingtone();
  }

  void _startRingtone() {
    // Vibration pattern: vibrate every 1.5s
    HapticFeedback.heavyImpact();
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (!_disposed) HapticFeedback.heavyImpact();
    });
    // Play system-like ringtone (uses device's default alert sound via URL)
    _ringtonePlayer.setReleaseMode(ReleaseMode.loop);
    _ringtonePlayer.setVolume(1.0);
    // Use a built-in ringtone URL; fallback gracefully if unavailable
    _ringtonePlayer.play(UrlSource('https://tajiri.zimasystems.com/sounds/ringtone.mp3')).catchError((_) {
      debugPrint('[CallFlow][Incoming] Ringtone playback failed — continuing without sound');
    });
  }

  void _stopRingtone() {
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    _ringtonePlayer.stop();
  }

  Future<void> _accept() async {
    if (_accepting) return;
    _accepting = true;
    _stopRingtone();
    setState(() {});

    final callId = widget.incoming.callId;
    final token = widget.authToken;
    final userId = widget.currentUserId;

    debugPrint('[CallFlow][Incoming] Accepting call $callId');

    _callState.setConnecting();

    // Subscribe to WS FIRST (before accept) so we're ready for the offer
    await _channel.subscribe(callId: callId, authToken: token, userId: userId);
    if (_disposed) return;

    // Fetch ICE servers
    List<Map<String, dynamic>> iceServers = [];
    final turnResp = await _signaling.getTurnCredentials(authToken: token, userId: userId);
    if (turnResp.success) iceServers = turnResp.iceServers;
    if (iceServers.isEmpty) {
      iceServers = [{'urls': ['stun:stun.l.google.com:19302', 'stun:stun1.l.google.com:19302']}];
    }

    // Init peer connection (NO media yet — callee must setRemoteDescription first)
    try {
      await _webrtc.initPeerConnection(iceServers);
    } catch (e) {
      debugPrint('[CallFlow][Incoming] ✗ Peer connection failed: $e');
      return;
    }
    if (_disposed) return;

    _remoteStreamSub = _webrtc.onRemoteStream.listen((stream) {
      _callState.setRemoteStream(stream);
    });

    // Queue ICE candidates that arrive before remote description is set
    final List<Map<String, dynamic>> pendingIceCandidates = [];
    bool remoteDescriptionSet = false;

    _iceCandidateSub = _webrtc.onIceCandidate.listen((candidate) {
      _signaling.sendSignaling(
        callId: callId,
        type: 'ice_candidate',
        candidate: candidate,
        authToken: token,
        userId: userId,
      );
    });

    _offerSub = _channel.onSignalingOffer.listen((e) async {
      if (e.callId != callId || e.sdp == null) return;
      if (e.fromUserId == userId) return;
      try {
        final extracted = CallWebRTCService.extractSdp(e.sdp!);
        if (extracted.sdp.isEmpty) return;

        await _webrtc.setRemoteDescription(extracted.sdp, extracted.type);
        remoteDescriptionSet = true;

        await _webrtc.getUserMedia(video: widget.incoming.type == 'video');
        if (_disposed) return;
        await _webrtc.addLocalStreamToPeerConnection();
        _callState.setLocalStream(_webrtc.localStream);

        final answer = await _webrtc.createAnswerOnly();
        if (answer != null) {
          await _signaling.sendSignaling(
            callId: callId,
            type: 'answer',
            sdp: answer,
            authToken: token,
            userId: userId,
          );
        }
        // Drain queued ICE candidates
        if (pendingIceCandidates.isNotEmpty) {
          for (final c in pendingIceCandidates) {
            try {
              await _webrtc.addIceCandidate(c);
            } catch (_) {}
          }
          pendingIceCandidates.clear();
        }
      } catch (e) {
        debugPrint('[CallFlow][Incoming] ✗ Offer handling failed: $e');
      }
    });

    _iceSub = _channel.onSignalingIceCandidate.listen((e) async {
      if (e.callId != callId || e.candidate == null) return;
      if (e.fromUserId == userId) return;
      if (!remoteDescriptionSet) {
        pendingIceCandidates.add(e.candidate!);
        return;
      }
      try {
        await _webrtc.addIceCandidate(e.candidate!);
      } catch (e) {
        debugPrint('[CallFlow][Incoming] ✗ addIceCandidate: $e');
      }
    });

    _endedSub = _channel.onCallEnded.listen((e) {
      if (e.callId == callId && !_disposed && mounted) {
        _cleanup();
        Navigator.of(context).pop();
      }
    });

    _connectionStateSub = _webrtc.onConnectionState.listen((state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected && !_disposed && mounted) {
        debugPrint('[CallFlow][Incoming] CONNECTED');
        _callState.setConnected();
        _navigateToActiveCall();
      }
    });
    _iceConnectionStateSub = _webrtc.onIceConnectionState.listen((state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected && !_disposed && mounted) {
        _callState.setConnected();
        _navigateToActiveCall();
      }
    });

    // NOW accept the call (triggers CallAccepted → caller sends offer)
    final acceptResp = await _signaling.acceptCall(
      callId: callId,
      authToken: token,
      userId: userId,
    );

    if (!acceptResp.success) {
      if (mounted) {
        _callState.setError(acceptResp.message ?? 'Failed to accept');
        _accepting = false;
        setState(() {});
      }
      return;
    }

    debugPrint('[CallFlow][Incoming] Accepted — waiting for offer');
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

  Future<void> _reject() async {
    if (_disposed) return; // Already handled by WS listener
    _stopRingtone();
    debugPrint('[CallFlow][Incoming] Rejecting call ${widget.incoming.callId}');
    // Cancel WS listener BEFORE the API call to prevent double-pop race
    _endedSub?.cancel();
    await _signaling.rejectCall(
      callId: widget.incoming.callId,
      authToken: widget.authToken,
      userId: widget.currentUserId,
    );
    if (_disposed) return; // Guard against disposal during await
    _callState.setRejected();
    if (mounted) Navigator.of(context).pop();
  }

  /// Open chat with caller (optional Message shortcut per 02-ui-spec § 2.4).
  Future<void> _openMessage() async {
    try {
      final res = await _messageService.getPrivateConversation(
        widget.currentUserId,
        widget.incoming.callerId,
      );
      if (!mounted) return;
      final conv = res.conversation;
      if (conv != null) {
        Navigator.of(context).pop(); // dismiss incoming screen
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ChatScreen(
              conversationId: conv.id,
              currentUserId: widget.currentUserId,
              conversation: conv,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[CallFlow][Incoming] _openMessage error: $e');
    }
  }

  void _cleanup() {
    _disposed = true;
    _stopRingtone();
    _ringtonePlayer.dispose();
    _offerSub?.cancel();
    _iceSub?.cancel();
    _endedSub?.cancel();
    _iceCandidateSub?.cancel();
    _remoteStreamSub?.cancel();
    _connectionStateSub?.cancel();
    _iceConnectionStateSub?.cancel();
    _webrtc.dispose();
    _channel.disconnect();
    _callState.reset();
  }

  @override
  void dispose() {
    if (!_disposed) {
      if (_navigatedToActive) {
        // Resources are handed off to ActiveCallScreen — only cancel our subscriptions.
        _disposed = true;
        _stopRingtone();
        _ringtonePlayer.dispose();
        _offerSub?.cancel();
        _iceSub?.cancel();
        _endedSub?.cancel();
        _iceCandidateSub?.cancel();
        _remoteStreamSub?.cancel();
        _connectionStateSub?.cancel();
        _iceConnectionStateSub?.cancel();
      } else {
        _cleanup();
      }
    }
    super.dispose();
  }

  Widget _controlButton({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String label,
    required VoidCallback? onPressed,
    double size = 64,
    double iconSize = 28,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Material(
            color: backgroundColor,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: Center(
                child: Icon(icon, color: iconColor, size: iconSize),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.incoming.callerName;
    final avatarUrl = widget.incoming.callerAvatarUrl;
    final isVideo = widget.incoming.type == 'video';
    final isGroupAdd = widget.incoming.isGroupAdd;

    return ListenableBuilder(
      listenable: _callState,
      builder: (context, _) {
        final status = _callState.status;
        String subtitle;
        if (status == CallStatus.connecting) {
          subtitle = 'Connecting…';
        } else if (status == CallStatus.error) {
          subtitle = _callState.errorMessage ?? 'Error';
        } else if (isGroupAdd) {
          subtitle = 'Added to group call';
        } else {
          subtitle = isVideo ? 'Incoming video call' : 'Incoming voice call';
        }

        return Scaffold(
          backgroundColor: const Color(0xFF1A1A1A),
          body: SafeArea(
            child: Column(
              children: [
                // Top status label
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isVideo ? 'Incoming Video Call' : 'Incoming Voice Call',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                // Caller avatar
                UserAvatar(photoUrl: avatarUrl, name: name, radius: 60),
                const SizedBox(height: 24),
                // Caller name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                // Connecting indicator
                if (_accepting)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white38,
                        strokeWidth: 2.0,
                      ),
                    ),
                  ),
                const Spacer(),
                // Control buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _controlButton(
                        icon: Icons.call_end_rounded,
                        iconColor: Colors.red.shade400,
                        backgroundColor: const Color(0xFF2A2A2A),
                        label: 'Decline',
                        onPressed: _accepting ? null : _reject,
                      ),
                      _controlButton(
                        icon: isVideo
                            ? Icons.videocam_rounded
                            : Icons.call_rounded,
                        iconColor: const Color(0xFF1A1A1A),
                        backgroundColor: const Color(0xFFFFFFFF),
                        label: 'Accept',
                        onPressed: _accepting ? null : _accept,
                      ),
                      _controlButton(
                        icon: Icons.message_rounded,
                        iconColor: Colors.white,
                        backgroundColor: const Color(0xFF2A2A2A),
                        label: 'Message',
                        onPressed: _accepting ? null : _openMessage,
                        size: 48,
                        iconSize: 22,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        );
      },
    );
  }
}
