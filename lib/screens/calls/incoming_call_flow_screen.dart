// Video & Audio Calls — Incoming call flow (docs/video-audio-calls, 1.F.11)
// Show incoming UI; Accept → POST accept → subscribe → create PC → on offer answer → ActiveCallScreen.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
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
  bool _disposed = false;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _callState.startIncoming(
      callId: widget.incoming.callId,
      remoteUser: RemoteUserInfo(
        userId: widget.incoming.callerId,
        displayName: widget.incoming.callerName,
        avatarUrl: widget.incoming.callerAvatarUrl,
      ),
      type: widget.incoming.type,
    );
  }

  Future<void> _accept() async {
    if (_accepting) return;
    _accepting = true;
    setState(() {});

    final callId = widget.incoming.callId;
    final token = widget.authToken;
    final userId = widget.currentUserId;

    _callState.setConnecting();

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

    List<Map<String, dynamic>> iceServers = acceptResp.iceServers;
    if (iceServers.isEmpty) {
      final turnResp = await _signaling.getTurnCredentials(authToken: token, userId: userId);
      if (turnResp.success) iceServers = turnResp.iceServers;
    }

    await _channel.subscribe(callId: callId, authToken: token);

    await _webrtc.initPeerConnection(iceServers);
    await _webrtc.getUserMedia(video: widget.incoming.type == 'video');
    await _webrtc.addLocalStreamToPeerConnection();
    _callState.setLocalStream(_webrtc.localStream);

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
      final answer = await _webrtc.setRemoteOfferAndCreateAnswer(e.sdp!);
      if (answer != null) {
        await _signaling.sendSignaling(
          callId: callId,
          type: 'answer',
          sdp: answer,
          authToken: token,
          userId: userId,
        );
      }
    });

    _iceSub = _channel.onSignalingIceCandidate.listen((e) async {
      if (e.callId != callId || e.candidate == null) return;
      await _webrtc.addIceCandidate(e.candidate!);
    });

    _endedSub = _channel.onCallEnded.listen((e) {
      if (e.callId == callId && !_disposed && mounted) {
        _cleanup();
        Navigator.of(context).pop();
      }
    });

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

  Future<void> _reject() async {
    await _signaling.rejectCall(
      callId: widget.incoming.callId,
      authToken: widget.authToken,
      userId: widget.currentUserId,
    );
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
    } catch (_) {}
  }

  void _cleanup() {
    _disposed = true;
    _offerSub?.cancel();
    _iceSub?.cancel();
    _endedSub?.cancel();
    _iceCandidateSub?.cancel();
    _webrtc.dispose();
    _channel.disconnect();
    _callState.reset();
  }

  @override
  void dispose() {
    if (!_disposed) _cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.incoming.callerName;
    final avatarUrl = widget.incoming.callerAvatarUrl;
    final isVideo = widget.incoming.type == 'video';
    final isGroupAdd = widget.incoming.isGroupAdd;
    final subtitle = isGroupAdd
        ? 'Added to group call'
        : (isVideo ? 'Incoming video call' : 'Incoming voice call');

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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            if (_accepting)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: CircularProgressIndicator(color: Colors.white70),
              ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.large(
                      heroTag: 'decline',
                      backgroundColor: Colors.red,
                      onPressed: _accepting ? null : _reject,
                      child: const Icon(Icons.call_end, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text('Decline', style: TextStyle(color: Colors.white70)),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.large(
                      heroTag: 'answer',
                      backgroundColor: Colors.green,
                      onPressed: _accepting ? null : _accept,
                      child: Icon(
                        isVideo ? Icons.videocam : Icons.call,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(isVideo ? 'Accept (video)' : 'Accept', style: const TextStyle(color: Colors.white70)),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      heroTag: 'message',
                      backgroundColor: Colors.grey.shade700,
                      onPressed: _accepting ? null : _openMessage,
                      child: const Icon(Icons.message, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text('Message', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
