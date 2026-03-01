// Video & Audio Calls — Outgoing call flow (docs/video-audio-calls, 1.F.10)
// Create call → subscribe WS → init PC → offer → send → wait for answer/ICE → show ActiveCallScreen.

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

class _OutgoingCallFlowScreenState extends State<OutgoingCallFlowScreen> {
  final CallState _callState = CallState();
  final CallSignalingService _signaling = CallSignalingService();
  final CallChannelService _channel = CallChannelService();
  final CallWebRTCService _webrtc = CallWebRTCService();

  StreamSubscription? _answerSub;
  StreamSubscription? _iceSub;
  StreamSubscription? _rejectedSub;
  StreamSubscription? _endedSub;
  StreamSubscription? _iceCandidateSub;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _startCall();
  }

  Future<void> _startCall() async {
    final token = widget.authToken;
    final userId = widget.currentUserId;

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

    // 2. Subscribe to channel (optional; if Reverb not configured we continue with REST polling for answer)
    final wsSubscribed = await _channel.subscribe(
      callId: callId,
      authToken: token,
    );

    if (wsSubscribed) {
      _answerSub = _channel.onSignalingAnswer.listen((e) {
        if (e.callId != callId) return;
        _onRemoteAnswer(e.sdp);
      });
      _channel.onCallAccepted.listen((e) {
        if (e.callId != callId) return;
        if (e.sdpAnswer != null) _onRemoteAnswer(e.sdpAnswer);
      });
      _iceSub = _channel.onSignalingIceCandidate.listen((e) {
        if (e.callId != callId) return;
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
    }

    // 3. Init peer connection + getUserMedia
    await _webrtc.initPeerConnection(iceServers);
    await _webrtc.getUserMedia(video: widget.type == 'video');
    await _webrtc.addLocalStreamToPeerConnection();

    _callState.setLocalStream(_webrtc.localStream);

    // 4. Create offer and send
    final offer = await _webrtc.createOffer();
    if (offer != null) {
      await _signaling.sendSignaling(
        callId: callId,
        type: 'offer',
        sdp: offer,
        authToken: token,
        userId: userId,
      );
    }

    // 5. Send ICE candidates via signaling
    _iceCandidateSub = _webrtc.onIceCandidate.listen((candidate) {
      _signaling.sendSignaling(
        callId: callId,
        type: 'ice_candidate',
        candidate: candidate,
        authToken: token,
        userId: userId,
      );
    });

    // 6. Listen for connection state to show active screen
    _webrtc.onConnectionState.listen((state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected && !_disposed && mounted) {
        _callState.setConnected();
        _navigateToActiveCall();
      }
    });
    _webrtc.onIceConnectionState.listen((state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected && !_disposed && mounted) {
        _callState.setConnected();
        _navigateToActiveCall();
      }
    });
  }

  void _onRemoteAnswer(Map<String, dynamic>? sdp) async {
    if (sdp == null) return;
    await _webrtc.setRemoteAnswer(sdp);
  }

  void _onRemoteIce(Map<String, dynamic>? candidate) async {
    if (candidate == null) return;
    await _webrtc.addIceCandidate(candidate);
  }

  void _navigateToActiveCall() {
    if (_disposed || !mounted) return;
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
    final callId = _callState.callId;
    if (callId != null) {
      await _signaling.endCall(callId: callId, authToken: widget.authToken, userId: widget.currentUserId);
    }
    _cleanup();
    if (mounted) Navigator.of(context).pop();
  }

  void _cleanup() {
    _disposed = true;
    _answerSub?.cancel();
    _iceSub?.cancel();
    _rejectedSub?.cancel();
    _endedSub?.cancel();
    _iceCandidateSub?.cancel();
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
    if (!_disposed) _cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = _callState.remoteUser?.displayName ?? widget.calleeName;
    final avatarUrl = _callState.remoteUser?.avatarUrl ?? widget.calleeAvatarUrl;
    final status = _callState.status;

    String statusText = 'Calling…';
    if (status == CallStatus.rejected) {
      statusText = 'Declined';
    } else if (status == CallStatus.connecting) {
      statusText = 'Connecting…';
    } else if (status == CallStatus.connected) {
      statusText = 'Connected';
    } else if (status == CallStatus.error) {
      statusText = _callState.errorMessage ?? 'Error';
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            UserAvatar(photoUrl: avatarUrl, name: name, radius: 60),
            const SizedBox(height: 24),
            Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              statusText,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: FloatingActionButton.large(
                backgroundColor: Colors.red,
                onPressed: _endCall,
                child: const Icon(Icons.call_end, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
