// Video & Audio Calls — WebRTC (docs/video-audio-calls, 05-flutter-webrtc-implementation)
// Manages RTCPeerConnection, getUserMedia, offer/answer, ICE, local/remote streams.

import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallWebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  MediaStream? _screenStream;

  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  MediaStream? get screenStream => _screenStream;
  bool get isScreenSharing => _screenStream != null;
  RTCPeerConnection? get peerConnection => _peerConnection;

  final StreamController<MediaStream> _remoteStreamController =
      StreamController<MediaStream>.broadcast();
  Stream<MediaStream> get onRemoteStream => _remoteStreamController.stream;

  final StreamController<RTCPeerConnectionState> _connectionStateController =
      StreamController<RTCPeerConnectionState>.broadcast();
  Stream<RTCPeerConnectionState> get onConnectionState =>
      _connectionStateController.stream;

  final StreamController<RTCIceConnectionState> _iceStateController =
      StreamController<RTCIceConnectionState>.broadcast();
  Stream<RTCIceConnectionState> get onIceConnectionState =>
      _iceStateController.stream;

  final StreamController<Map<String, dynamic>> _iceCandidateController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onIceCandidate => _iceCandidateController.stream;

  /// Build configuration map from backend ice_servers list (for createPeerConnection).
  static Map<String, dynamic> configurationFromIceServers(
    List<Map<String, dynamic>> iceServers,
  ) {
    return {
      'iceServers': iceServers,
      'sdpSemantics': 'unified-plan',
    };
  }

  /// Create peer connection with TURN/STUN config. Uses global createPeerConnection from flutter_webrtc.
  Future<RTCPeerConnection?> initPeerConnection(
    List<Map<String, dynamic>> iceServers,
  ) async {
    await dispose();
    final config = configurationFromIceServers(iceServers);
    _peerConnection = await createPeerConnection(config);

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
        _remoteStreamController.add(_remoteStream!);
      }
    };

    _peerConnection!.onIceConnectionState = (state) {
      _iceStateController.add(state);
    };

    _peerConnection!.onConnectionState = (state) {
      _connectionStateController.add(state);
    };

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      _iceCandidateController.add({
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    return _peerConnection;
  }

  /// Get user media (audio only for voice, audio+video for video call).
  Future<MediaStream?> getUserMedia({required bool video}) async {
    final constraints = <String, dynamic>{
      'audio': true,
      'video': video
          ? {
              'facingMode': 'user',
              'width': {'ideal': 1280},
              'height': {'ideal': 720},
            }
          : false,
    };
    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    return _localStream;
  }

  /// Add local stream tracks to the peer connection.
  Future<void> addLocalStreamToPeerConnection() async {
    if (_peerConnection == null || _localStream == null) return;
    for (final track in _localStream!.getTracks()) {
      await _peerConnection!.addTrack(track, _localStream!);
    }
  }

  /// Create offer (caller). Returns SDP map for signaling.
  Future<Map<String, dynamic>?> createOffer() async {
    if (_peerConnection == null) return null;
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    return {
      'type': offer.type,
      'sdp': offer.sdp,
    };
  }

  /// Set remote description (offer from peer) and create answer (callee). Returns SDP map.
  Future<Map<String, dynamic>?> setRemoteOfferAndCreateAnswer(
    Map<String, dynamic> sdpMap,
  ) async {
    if (_peerConnection == null) return null;
    final sdp = sdpMap['sdp'] as String? ?? '';
    final type = sdpMap['type'] as String? ?? 'offer';
    final description = RTCSessionDescription(sdp, type);
    await _peerConnection!.setRemoteDescription(description);
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    return {
      'type': answer.type,
      'sdp': answer.sdp,
    };
  }

  /// Set remote description (answer from peer). Caller uses this.
  Future<void> setRemoteAnswer(Map<String, dynamic> sdpMap) async {
    if (_peerConnection == null) return;
    final sdp = sdpMap['sdp'] as String? ?? '';
    final type = sdpMap['type'] as String? ?? 'answer';
    final description = RTCSessionDescription(sdp, type);
    await _peerConnection!.setRemoteDescription(description);
  }

  /// Add ICE candidate from signaling.
  Future<void> addIceCandidate(Map<String, dynamic> candidateMap) async {
    if (_peerConnection == null) return;
    final candidate = RTCIceCandidate(
      candidateMap['candidate'] as String? ?? '',
      candidateMap['sdpMid'] as String? ?? '',
      candidateMap['sdpMLineIndex'] as int? ?? 0,
    );
    await _peerConnection!.addCandidate(candidate);
  }

  /// Mute/unmute local audio track.
  void setMicrophoneEnabled(bool enabled) {
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = enabled;
    });
  }

  /// Enable/disable local video track.
  void setCameraEnabled(bool enabled) {
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = enabled;
    });
  }

  /// Start screen share (Phase 3). getDisplayMedia, add track, create offer for renegotiation.
  Future<Map<String, dynamic>?> startScreenShare() async {
    if (_peerConnection == null) return null;
    try {
      _screenStream = await navigator.mediaDevices.getDisplayMedia({'video': true});
      final videoTracks = _screenStream!.getVideoTracks();
      if (videoTracks.isEmpty) return null;
      await _peerConnection!.addTrack(videoTracks.first, _screenStream!);
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      return {'type': offer.type, 'sdp': offer.sdp};
    } catch (_) {
      return null;
    }
  }

  /// Stop screen share: remove track, create offer for renegotiation.
  Future<Map<String, dynamic>?> stopScreenShare() async {
    if (_peerConnection == null || _screenStream == null) return null;
    try {
      final senders = await _peerConnection!.getSenders();
      for (final sender in senders) {
        if (sender.track?.kind == 'video' && _screenStream!.getTracks().contains(sender.track)) {
          await _peerConnection!.removeTrack(sender);
          break;
        }
      }
      for (final t in _screenStream!.getTracks()) {
        t.stop();
      }
      _screenStream = null;
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      return {'type': offer.type, 'sdp': offer.sdp};
    } catch (_) {
      return null;
    }
  }

  /// ICE restart (reconnection). Create new offer with iceRestart.
  Future<Map<String, dynamic>?> createOfferIceRestart() async {
    if (_peerConnection == null) return null;
    final offer = await _peerConnection!.createOffer({'iceRestart': true});
    await _peerConnection!.setLocalDescription(offer);
    return {
      'type': offer.type,
      'sdp': offer.sdp,
    };
  }

  /// Close and dispose.
  Future<void> dispose() async {
    for (final track in _screenStream?.getTracks() ?? <MediaStreamTrack>[]) {
      track.stop();
    }
    _screenStream = null;
    await _peerConnection?.close();
    _peerConnection = null;
    for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      track.stop();
    }
    _localStream = null;
    _remoteStream = null;
    await _remoteStreamController.close();
    await _connectionStateController.close();
    await _iceStateController.close();
    await _iceCandidateController.close();
  }
}
