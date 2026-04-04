// Video & Audio Calls — WebRTC (docs/video-audio-calls, 05-flutter-webrtc-implementation)
// Manages RTCPeerConnection, getUserMedia, offer/answer, ICE, local/remote streams.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  // Buffer ICE candidates that arrive before remote description is set.
  bool _remoteDescriptionSet = false;
  final List<Map<String, dynamic>> _pendingIceCandidates = [];

  // StreamControllers are recreated on each initPeerConnection() to avoid
  // "Cannot add new events after calling close" errors.
  StreamController<MediaStream> _remoteStreamController =
      StreamController<MediaStream>.broadcast();
  Stream<MediaStream> get onRemoteStream => _remoteStreamController.stream;

  StreamController<RTCPeerConnectionState> _connectionStateController =
      StreamController<RTCPeerConnectionState>.broadcast();
  Stream<RTCPeerConnectionState> get onConnectionState =>
      _connectionStateController.stream;

  StreamController<RTCIceConnectionState> _iceStateController =
      StreamController<RTCIceConnectionState>.broadcast();
  Stream<RTCIceConnectionState> get onIceConnectionState =>
      _iceStateController.stream;

  StreamController<Map<String, dynamic>> _iceCandidateController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onIceCandidate => _iceCandidateController.stream;

  /// Build configuration map from backend ice_servers list (for createPeerConnection).
  /// Free public STUN servers used as fallback when backend returns none.
  static const List<Map<String, dynamic>> _fallbackStunServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
  ];

  static Map<String, dynamic> configurationFromIceServers(
    List<Map<String, dynamic>> iceServers,
  ) {
    final servers = iceServers.isNotEmpty ? iceServers : _fallbackStunServers;
    if (iceServers.isEmpty) {
      debugPrint('[CallFlow][WebRTC] No ICE servers from backend, using fallback STUN servers');
    }
    return {
      'iceServers': servers,
      'sdpSemantics': 'unified-plan',
    };
  }

  /// Close existing peer connection and streams without closing StreamControllers.
  /// Safe to call before reinitializing.
  Future<void> _closePeerConnection() async {
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
  }

  /// Recreate StreamControllers so listeners get fresh streams after reinit.
  void _resetStreamControllers() {
    if (!_remoteStreamController.isClosed) _remoteStreamController.close();
    if (!_connectionStateController.isClosed) _connectionStateController.close();
    if (!_iceStateController.isClosed) _iceStateController.close();
    if (!_iceCandidateController.isClosed) _iceCandidateController.close();

    _remoteStreamController = StreamController<MediaStream>.broadcast();
    _connectionStateController = StreamController<RTCPeerConnectionState>.broadcast();
    _iceStateController = StreamController<RTCIceConnectionState>.broadcast();
    _iceCandidateController = StreamController<Map<String, dynamic>>.broadcast();
  }

  /// Create peer connection with TURN/STUN config. Uses global createPeerConnection from flutter_webrtc.
  Future<RTCPeerConnection?> initPeerConnection(
    List<Map<String, dynamic>> iceServers,
  ) async {
    await _closePeerConnection();
    _resetStreamControllers();
    _remoteDescriptionSet = false;
    _pendingIceCandidates.clear();
    final config = configurationFromIceServers(iceServers);
    _peerConnection = await createPeerConnection(config);
    debugPrint('[CallFlow][WebRTC] ✓ Peer connection created (${iceServers.length} ICE servers)');

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      debugPrint('[CallFlow][WebRTC] onTrack: ${event.track.kind}');
      if (event.streams.isNotEmpty && !_remoteStreamController.isClosed) {
        _remoteStream = event.streams.first;
        _remoteStreamController.add(_remoteStream!);
      }
    };

    _peerConnection!.onIceConnectionState = (state) {
      if (!_iceStateController.isClosed) _iceStateController.add(state);
    };

    _peerConnection!.onConnectionState = (state) {
      debugPrint('[CallFlow][WebRTC] Connection state → $state');
      if (!_connectionStateController.isClosed) _connectionStateController.add(state);
    };

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (!_iceCandidateController.isClosed) {
        _iceCandidateController.add({
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      }
    };

    _peerConnection!.onSignalingState = (state) {
      debugPrint('[CallFlow][WebRTC] Signaling state → $state');
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
    debugPrint('[CallFlow][WebRTC] ✓ getUserMedia (video=$video)');
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
    if (_peerConnection == null) {
      debugPrint('[CallFlow][WebRTC] ✗ createOffer: peerConnection is null');
      return null;
    }
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    debugPrint('[CallFlow][WebRTC] ✓ Offer created, sdp length=${offer.sdp?.length ?? 0}');
    return {
      'type': offer.type,
      'sdp': offer.sdp,
    };
  }

  /// Normalize SDP line endings to \r\n (required by RFC 4566) and ensure
  /// the SDP ends with \r\n so the native parser doesn't reject it.
  static String _normalizeSdpLineEndings(String sdp) {
    var result = sdp.replaceAll('\r\n', '\n').replaceAll('\r', '\n').replaceAll('\n', '\r\n');
    if (!result.endsWith('\r\n')) result += '\r\n';
    return result;
  }

  /// Codecs that iOS WebRTC-SDK 125 cannot parse.
  /// H265 is the only codec Android includes that iOS doesn't support.
  static const _unsupportedCodecNames = {'H265'};

  /// Remove unsupported codec lines from SDP so iOS can parse Android-generated offers.
  /// Strips payload types for unsupported codecs from m= lines and removes all
  /// associated a=rtpmap, a=fmtp, a=rtcp-fb lines for those payload types.
  static String _removeUnsupportedCodecs(String sdp) {
    final lines = sdp.split('\r\n');
    // First pass: find payload types for unsupported codecs
    final unsupportedPts = <String>{};
    for (final line in lines) {
      if (!line.startsWith('a=rtpmap:')) continue;
      // Format: a=rtpmap:PT codec/clockrate[/channels]
      final match = RegExp(r'^a=rtpmap:(\d+)\s+(\S+)').firstMatch(line);
      if (match != null) {
        final pt = match.group(1)!;
        final codec = match.group(2)!.split('/').first;
        if (_unsupportedCodecNames.contains(codec)) {
          unsupportedPts.add(pt);
          debugPrint('[CallFlow][WebRTC] SDP munge: removing unsupported codec $codec (PT=$pt)');
        }
      }
    }
    if (unsupportedPts.isEmpty) return sdp;

    // Also find RTX payload types that reference unsupported codecs
    for (final line in lines) {
      if (!line.startsWith('a=fmtp:')) continue;
      // Format: a=fmtp:PT apt=XX
      final match = RegExp(r'^a=fmtp:(\d+)\s+apt=(\d+)').firstMatch(line);
      if (match != null && unsupportedPts.contains(match.group(2))) {
        unsupportedPts.add(match.group(1)!);
        debugPrint('[CallFlow][WebRTC] SDP munge: also removing RTX PT=${match.group(1)} (apt=${match.group(2)})');
      }
    }

    // Second pass: filter lines and m= payload type lists
    final result = <String>[];
    for (final line in lines) {
      // Remove a=rtpmap:PT, a=fmtp:PT, a=rtcp-fb:PT lines for unsupported PTs
      final ptMatch = RegExp(r'^a=(?:rtpmap|fmtp|rtcp-fb):(\d+)[\s/]').firstMatch(line);
      if (ptMatch != null && unsupportedPts.contains(ptMatch.group(1))) {
        continue; // skip this line
      }
      // Strip unsupported PTs from m= line payload type list
      if (line.startsWith('m=')) {
        // Format: m=media port proto PT1 PT2 PT3...
        final parts = line.split(' ');
        // parts[0]=m=media, [1]=port, [2]=proto, [3..]=PTs
        if (parts.length > 3) {
          final filtered = parts.sublist(0, 3);
          for (int i = 3; i < parts.length; i++) {
            if (!unsupportedPts.contains(parts[i])) {
              filtered.add(parts[i]);
            }
          }
          result.add(filtered.join(' '));
          continue;
        }
      }
      result.add(line);
    }

    final munged = result.join('\r\n');
    debugPrint('[CallFlow][WebRTC] SDP munge: ${sdp.length} → ${munged.length} bytes (removed ${unsupportedPts.length} payload types)');
    return munged;
  }

  /// Extract raw SDP string and type from a potentially nested sdp map.
  /// Handles: {'type': 'offer', 'sdp': 'v=0...'} and {'sdp': {'type': 'offer', 'sdp': 'v=0...'}}.
  /// Always normalizes line endings to \r\n for cross-platform compatibility.
  static ({String sdp, String type}) _extractSdp(Map<String, dynamic> sdpMap) {
    String rawSdp = '';
    String type = 'offer';

    // Case 1: sdpMap['sdp'] is another Map (double-nested)
    final innerSdp = sdpMap['sdp'];
    if (innerSdp is Map) {
      final raw = innerSdp['sdp'];
      type = innerSdp['type']?.toString() ?? sdpMap['type']?.toString() ?? 'offer';
      if (raw is String && raw.isNotEmpty) {
        rawSdp = raw;
      }
    }
    // Case 2: sdpMap['sdp'] is a JSON string that needs decoding
    else if (innerSdp is String && innerSdp.startsWith('{')) {
      try {
        final decoded = Map<String, dynamic>.from(
          jsonDecode(innerSdp) as Map<String, dynamic>,
        );
        rawSdp = decoded['sdp']?.toString() ?? '';
        type = decoded['type']?.toString() ?? sdpMap['type']?.toString() ?? 'offer';
      } catch (_) {
        // Not JSON — treat as raw SDP string
        rawSdp = innerSdp;
        type = sdpMap['type']?.toString() ?? 'offer';
      }
    }
    // Case 3: sdpMap['sdp'] is a plain SDP string
    else if (innerSdp is String && innerSdp.isNotEmpty) {
      rawSdp = innerSdp;
      type = sdpMap['type']?.toString() ?? 'offer';
    }

    // Normalize \r\n line endings and remove unsupported codecs for iOS compatibility
    if (rawSdp.isNotEmpty) {
      rawSdp = _normalizeSdpLineEndings(rawSdp);
      rawSdp = _removeUnsupportedCodecs(rawSdp);
    }

    return (sdp: rawSdp, type: type);
  }

  /// Public accessor for _extractSdp (used by incoming call flow).
  static ({String sdp, String type}) extractSdp(Map<String, dynamic> sdpMap) =>
      _extractSdp(sdpMap);

  /// Set remote description only (no answer creation). For callee pattern where
  /// tracks are added between setRemoteDescription and createAnswer.
  Future<void> setRemoteDescription(String sdp, String type) async {
    if (_peerConnection == null) {
      debugPrint('[CallFlow][WebRTC] ✗ setRemoteDescription: peerConnection is null');
      throw Exception('PeerConnection is null');
    }
    final description = RTCSessionDescription(sdp, type);
    await _peerConnection!.setRemoteDescription(description);
    _remoteDescriptionSet = true;
    debugPrint('[CallFlow][WebRTC] ✓ Remote description set');
    await _flushPendingIceCandidates();
  }

  /// Create answer and set as local description. Call AFTER setRemoteDescription + addTracks.
  Future<Map<String, dynamic>?> createAnswerOnly() async {
    if (_peerConnection == null) {
      debugPrint('[CallFlow][WebRTC] ✗ createAnswerOnly: peerConnection is null');
      return null;
    }
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    debugPrint('[CallFlow][WebRTC] ✓ Answer created, sdp length=${answer.sdp?.length ?? 0}');
    return {
      'type': answer.type,
      'sdp': answer.sdp,
    };
  }

  /// Set remote description (offer from peer) and create answer (callee). Returns SDP map.
  Future<Map<String, dynamic>?> setRemoteOfferAndCreateAnswer(
    Map<String, dynamic> sdpMap,
  ) async {
    if (_peerConnection == null) return null;
    final extracted = _extractSdp(sdpMap);
    if (extracted.sdp.isEmpty) {
      debugPrint('[CallFlow][WebRTC] ✗ SDP string is empty after extraction');
      return null;
    }

    final description = RTCSessionDescription(extracted.sdp, extracted.type);
    await _peerConnection!.setRemoteDescription(description);
    _remoteDescriptionSet = true;
    debugPrint('[CallFlow][WebRTC] ✓ Remote offer set');
    await _flushPendingIceCandidates();
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    debugPrint('[CallFlow][WebRTC] ✓ Answer created, sdp length=${answer.sdp?.length ?? 0}');
    return {
      'type': answer.type,
      'sdp': answer.sdp,
    };
  }

  /// Set remote description (answer from peer). Caller uses this.
  Future<void> setRemoteAnswer(Map<String, dynamic> sdpMap) async {
    if (_peerConnection == null) {
      debugPrint('[CallFlow][WebRTC] ✗ setRemoteAnswer: peerConnection is null');
      return;
    }
    final extracted = _extractSdp(sdpMap);
    if (extracted.sdp.isEmpty) {
      debugPrint('[CallFlow][WebRTC] ✗ Answer SDP string is empty after extraction');
      return;
    }
    final description = RTCSessionDescription(extracted.sdp, extracted.type);
    await _peerConnection!.setRemoteDescription(description);
    _remoteDescriptionSet = true;
    debugPrint('[CallFlow][WebRTC] ✓ Remote answer set');
    await _flushPendingIceCandidates();
  }

  /// Add ICE candidate from signaling. Buffers if remote description not yet set.
  Future<void> addIceCandidate(Map<String, dynamic> candidateMap) async {
    if (_peerConnection == null) return;
    if (!_remoteDescriptionSet) {
      _pendingIceCandidates.add(candidateMap);
      return;
    }
    final candidate = RTCIceCandidate(
      candidateMap['candidate'] as String? ?? '',
      candidateMap['sdpMid'] as String? ?? '',
      candidateMap['sdpMLineIndex'] as int? ?? 0,
    );
    await _peerConnection!.addCandidate(candidate);
  }

  /// Flush buffered ICE candidates after remote description is set.
  Future<void> _flushPendingIceCandidates() async {
    if (_pendingIceCandidates.isEmpty) return;
    debugPrint('[CallFlow][WebRTC] Flushing ${_pendingIceCandidates.length} buffered ICE candidates');
    final pending = List<Map<String, dynamic>>.from(_pendingIceCandidates);
    _pendingIceCandidates.clear();
    for (final c in pending) {
      await addIceCandidate(c);
    }
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

  /// Close and dispose permanently. Only call when this service won't be reused.
  Future<void> dispose() async {
    await _closePeerConnection();
    if (!_remoteStreamController.isClosed) await _remoteStreamController.close();
    if (!_connectionStateController.isClosed) await _connectionStateController.close();
    if (!_iceStateController.isClosed) await _iceStateController.close();
    if (!_iceCandidateController.isClosed) await _iceCandidateController.close();
  }
}
