// Native incoming call UI — CallKit (iOS) / ConnectionService (Android).
// Shows system-level call screen when app is backgrounded/killed.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import '../calls/call_channel_service.dart';
import 'local_storage_service.dart';
import 'call_signaling_service.dart';

class CallKitService {
  CallKitService._();
  static final CallKitService instance = CallKitService._();

  StreamSubscription? _callKitSubscription;
  final StreamController<CallIncomingEvent> _acceptedController =
      StreamController<CallIncomingEvent>.broadcast();

  /// Emits when user accepts a call via the native CallKit/Android UI.
  Stream<CallIncomingEvent> get onCallAccepted => _acceptedController.stream;

  void init() {
    debugPrint('[CallKit] ═══ Initializing CallKitService ═══');
    _callKitSubscription = FlutterCallkitIncoming.onEvent.listen((event) {
      debugPrint('[CallKit] Event: ${event?.event}, body: ${event?.body}');
      switch (event?.event) {
        case Event.actionCallAccept:
          final data = event!.body as Map<String, dynamic>? ?? {};
          final callId = data['id']?.toString() ?? data['extra']?['call_id']?.toString() ?? '';
          final callerId = int.tryParse(data['extra']?['caller_id']?.toString() ?? '0') ?? 0;
          final callerName = data['nameCaller']?.toString() ?? 'Caller';
          debugPrint('[CallKit] ✓ Call ACCEPTED via native UI: callId=$callId, caller=$callerName (id=$callerId)');
          _acceptedController.add(CallIncomingEvent(
            callId: callId,
            callerId: callerId,
            callerName: callerName,
            callerAvatarUrl: data['avatar'] as String?,
            type: data['extra']?['call_type']?.toString() ?? 'voice',
          ));
          break;
        case Event.actionCallDecline:
          final data = event!.body as Map<String, dynamic>? ?? {};
          final callId = data['id']?.toString() ?? data['extra']?['call_id']?.toString();
          debugPrint('[CallKit] ✗ Call DECLINED via native UI: callId=$callId');
          if (callId != null) {
            _rejectCall(callId);
          }
          break;
        case Event.actionCallEnded:
          debugPrint('[CallKit] Call ENDED via native UI');
          break;
        case Event.actionCallTimeout:
          debugPrint('[CallKit] Call TIMEOUT via native UI');
          break;
        case Event.actionCallCallback:
          debugPrint('[CallKit] Call CALLBACK via native UI');
          break;
        default:
          debugPrint('[CallKit] Unhandled event: ${event?.event}');
          break;
      }
    });
  }

  /// Show native incoming call UI.
  Future<void> showIncomingCall({
    required String callId,
    required String callerName,
    String? callerAvatarUrl,
    String type = 'voice',
    int callerId = 0,
  }) async {
    debugPrint('[CallKit] showIncomingCall: callId=$callId, caller=$callerName, type=$type, callerId=$callerId');
    final params = CallKitParams(
      id: callId,
      nameCaller: callerName,
      avatar: callerAvatarUrl,
      handle: callerName,
      type: type == 'video' ? 1 : 0,
      duration: 45000,
      textAccept: 'Accept',
      textDecline: 'Decline',
      extra: <String, dynamic>{
        'call_id': callId,
        'caller_id': callerId.toString(),
        'call_type': type,
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#1A1A1A',
        actionColor: '#4CAF50',
        isShowFullLockedScreen: true,
      ),
      ios: const IOSParams(
        iconName: 'AppIcon',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
      ),
    );
    await FlutterCallkitIncoming.showCallkitIncoming(params);
    debugPrint('[CallKit] ✓ Native call UI shown for callId=$callId');
  }

  /// End the native call UI.
  Future<void> endCall(String callId) async {
    debugPrint('[CallKit] endCall: callId=$callId');
    await FlutterCallkitIncoming.endCall(callId);
  }

  /// End all calls.
  Future<void> endAllCalls() async {
    debugPrint('[CallKit] endAllCalls');
    await FlutterCallkitIncoming.endAllCalls();
  }

  Future<void> _rejectCall(String callId) async {
    debugPrint('[CallKit] _rejectCall: callId=$callId');
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      final userId = storage.getUser()?.userId;
      debugPrint('[CallKit] _rejectCall: userId=$userId, hasToken=${token != null}');
      if (userId != null) {
        final signaling = CallSignalingService();
        await signaling.rejectCall(
          callId: callId,
          authToken: token,
          userId: userId,
        );
        debugPrint('[CallKit] ✓ Reject API call sent for callId=$callId');
      }
    } catch (e) {
      debugPrint('[CallKit] ✗ _rejectCall failed: $e');
    }
  }

  void dispose() {
    _callKitSubscription?.cancel();
    _acceptedController.close();
  }
}
