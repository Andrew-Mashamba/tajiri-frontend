// Video & Audio Calls — Call state holder (docs/video-audio-calls, 1.F.4)
// Single place for: callId, status, isCaller, remoteUser, type, streams, so UI can react.

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

enum CallStatus {
  idle,
  pending,
  ringing,
  connecting,
  connected,
  ended,
  rejected,
  noAnswer,
  error,
}

class CallState extends ChangeNotifier {
  String? _callId;
  CallStatus _status = CallStatus.idle;
  bool _isCaller = false;
  RemoteUserInfo? _remoteUser;
  String _type = 'voice'; // voice | video
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = false;
  Duration _connectedDuration = Duration.zero;
  String? _errorMessage;

  String? get callId => _callId;
  CallStatus get status => _status;
  bool get isCaller => _isCaller;
  RemoteUserInfo? get remoteUser => _remoteUser;
  String get type => _type;
  bool get isVideo => _type == 'video';
  bool get isVoice => _type == 'voice';
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  bool get isMuted => _isMuted;
  bool get isCameraOff => _isCameraOff;
  bool get isSpeakerOn => _isSpeakerOn;
  Duration get connectedDuration => _connectedDuration;
  String? get errorMessage => _errorMessage;

  bool get isActive => status == CallStatus.connected || status == CallStatus.connecting;
  bool get isRinging => status == CallStatus.ringing || status == CallStatus.pending;

  void setCallId(String? v) {
    if (_callId == v) return;
    _callId = v;
    notifyListeners();
  }

  void setStatus(CallStatus v) {
    if (_status == v) return;
    _status = v;
    notifyListeners();
  }

  void setIsCaller(bool v) {
    if (_isCaller == v) return;
    _isCaller = v;
    notifyListeners();
  }

  void setRemoteUser(RemoteUserInfo? v) {
    _remoteUser = v;
    notifyListeners();
  }

  void setType(String v) {
    if (_type == v) return;
    _type = v;
    notifyListeners();
  }

  void setLocalStream(MediaStream? v) {
    _localStream = v;
    notifyListeners();
  }

  void setRemoteStream(MediaStream? v) {
    _remoteStream = v;
    notifyListeners();
  }

  void setMuted(bool v) {
    if (_isMuted == v) return;
    _isMuted = v;
    notifyListeners();
  }

  void setCameraOff(bool v) {
    if (_isCameraOff == v) return;
    _isCameraOff = v;
    notifyListeners();
  }

  void setSpeakerOn(bool v) {
    if (_isSpeakerOn == v) return;
    _isSpeakerOn = v;
    notifyListeners();
  }

  void setConnectedDuration(Duration v) {
    if (_connectedDuration == v) return;
    _connectedDuration = v;
    notifyListeners();
  }

  void setErrorMessage(String? v) {
    _errorMessage = v;
    notifyListeners();
  }

  void startOutgoing({required String callId, required RemoteUserInfo remoteUser, required String type}) {
    _callId = callId;
    _status = CallStatus.pending;
    _isCaller = true;
    _remoteUser = remoteUser;
    _type = type;
    _errorMessage = null;
    notifyListeners();
  }

  void startIncoming({required String callId, required RemoteUserInfo remoteUser, required String type}) {
    _callId = callId;
    _status = CallStatus.ringing;
    _isCaller = false;
    _remoteUser = remoteUser;
    _type = type;
    _errorMessage = null;
    notifyListeners();
  }

  void setConnecting() {
    _status = CallStatus.connecting;
    notifyListeners();
  }

  void setConnected() {
    _status = CallStatus.connected;
    _connectedDuration = Duration.zero;
    _errorMessage = null;
    notifyListeners();
  }

  void setEnded() {
    _status = CallStatus.ended;
    notifyListeners();
  }

  void setRejected() {
    _status = CallStatus.rejected;
    notifyListeners();
  }

  void setNoAnswer() {
    _status = CallStatus.noAnswer;
    notifyListeners();
  }

  void setError(String message) {
    _status = CallStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  void reset() {
    _callId = null;
    _status = CallStatus.idle;
    _isCaller = false;
    _remoteUser = null;
    _type = 'voice';
    _localStream = null;
    _remoteStream = null;
    _isMuted = false;
    _isCameraOff = false;
    _isSpeakerOn = false;
    _connectedDuration = Duration.zero;
    _errorMessage = null;
    notifyListeners();
  }
}

class RemoteUserInfo {
  final int userId;
  final String displayName;
  final String? avatarUrl;

  RemoteUserInfo({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
  });
}
