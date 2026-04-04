§§# Production Calling Architecture Research

> Extensive research on how WhatsApp, Telegram, Signal, and other production apps implement voice/video calling.
> Focused on actionable findings for TAJIRI (Flutter + Laravel + WebRTC).

---

## 1. WhatsApp's Calling Architecture

### Signaling Protocol

WhatsApp uses a **modified XMPP protocol** (internally called "FunXMPP") for all real-time communication, including call signaling. Key characteristics:

- **Binary-compressed XMPP**: Standard XMPP uses verbose XML (~180 bytes per stanza). WhatsApp replaces this with a **single-byte token format** (~20 bytes), making it viable on 2G networks.
- **Persistent connection**: Every online device maintains a single persistent TCP/TLS connection to WhatsApp's Erlang-based Ejabberd servers. This connection handles messages, presence, AND call signaling.
- **Call signaling messages** (offer, answer, ICE candidates, call state changes) flow through this same persistent connection — they do NOT use a separate WebSocket channel.

### Call Flow

1. **Caller initiates**: Device generates an SRTP master secret, creates a WebRTC offer, and sends it via the persistent XMPP connection to WhatsApp's server.
2. **Server routes**: The Ejabberd server routes the signaling message to all of the callee's registered devices.
3. **Callee responds**: One device accepts — it uses the shared SRTP master secret to establish the encrypted media connection.
4. **Media flows P2P**: Once ICE negotiation completes, media flows directly peer-to-peer (or through TURN if NAT prevents direct connection).

### Incoming Call Notification (Critical for TAJIRI)

WhatsApp's approach to waking a device for an incoming call:

| Platform | Mechanism | Behavior |
|----------|-----------|----------|
| **iOS** | **PushKit VoIP push** | Bypasses all power management. iOS guarantees immediate delivery and wakes the app even from terminated state. WhatsApp has a special Apple entitlement (`com.apple.developer.pushkit.unrestricted-voip`) but normal apps must use standard PushKit + CallKit. |
| **Android** | **High-priority FCM data message** | FCM wakes the device from Doze. WhatsApp uses data-only messages (not notification messages) for full control over the call UI display. |

### Offline/Queue Architecture

- **Message queue in Mnesia**: When callee is offline, the server stores the call invitation in an in-memory Mnesia queue, replicated to backup servers.
- **Short TTL**: Call invitations have a short time-to-live (~45-60 seconds). If the callee doesn't come online, the caller gets "No answer."
- **Multiple devices**: The invitation is sent to ALL registered devices simultaneously. First to accept wins; the server cancels the invitation on all other devices.

### Key Takeaway for TAJIRI

WhatsApp's approach works because they have a **persistent connection** always open. TAJIRI uses Laravel Reverb (WebSocket) which is NOT always connected — particularly when the app is killed. Therefore, TAJIRI **must** rely on push notifications (FCM + PushKit) as the primary mechanism for incoming calls, with the WebSocket channel as an optimization for when the app is already open.

---

## 2. Telegram's Calling Architecture

### Signaling

Telegram uses **two channels**:
1. **Signaling channel**: Via the Telegram MTProto API (slower but reliable). Used for call setup, key exchange, and state management.
2. **Transport channel**: WebRTC-based for actual media and fast signaling (ICE candidates).

### Call Flow

1. Caller invokes `phone.requestCall` with a hashed Diffie-Hellman value.
2. Server notifies callee.
3. Callee accepts via `phone.acceptCall`, sending their DH public value.
4. Caller confirms with `phone.confirmCall`.
5. Both derive the shared encryption key.
6. WebRTC ICE negotiation begins using "reflector" relay servers.

### Encryption

Telegram does NOT use standard SRTP. Instead, it uses an **optimized MTProto 2.0 with AES-CTR encryption** derived from the DH-exchanged key. This is their own protocol, not interoperable with standard WebRTC encryption.

### Relay Servers ("Reflectors")

Telegram operates its own relay servers instead of standard TURN servers. ICE candidates include both direct P2P routes and reflector routes, with the lowest-overhead route chosen automatically.

### Key Takeaway for TAJIRI

Telegram's approach of using the **existing messaging API for call signaling** (rather than a separate WebSocket) is resilient. For TAJIRI, this maps to: use **REST API calls for critical signaling** (create call, accept, reject, end) and WebSocket only for **real-time SDP/ICE exchange** where latency matters.

---

## 3. Signal's Calling Architecture

Signal uses standard WebRTC with their own signaling server. Key points:

- **Signaling via Signal Protocol**: Call offers/answers are sent as encrypted Signal messages through the same message delivery infrastructure.
- **TURN servers**: Signal operates its own TURN servers. They relay 100% of call traffic through TURN by default for privacy (prevents IP address leakage between peers).
- **Group calls**: Use an SFU (Selective Forwarding Unit) server rather than mesh P2P.

### Key Takeaway for TAJIRI

Signal's "TURN always" approach is the gold standard for privacy but expensive in bandwidth. For TAJIRI, use TURN as fallback only (saves ~80% relay bandwidth) unless user privacy settings demand it.

---

## 4. WebRTC Best Practices for Mobile Apps

### 4.1 Correct Order of Operations for Offer/Answer Exchange

**Caller side:**
```
1. getUserMedia() → get local stream
2. createPeerConnection(iceServers)
3. addTrack() for each local track
4. Set up onIceCandidate listener → sends to signaling
5. Set up onTrack listener → receives remote stream
6. createOffer()
7. setLocalDescription(offer)
8. Send offer via signaling
9. [Wait for answer via signaling]
10. setRemoteDescription(answer)
11. [ICE candidates trickle in both directions]
12. Connection established
```

**Callee side:**
```
1. [Receive offer via signaling]
2. getUserMedia() → get local stream
3. createPeerConnection(iceServers)
4. addTrack() for each local track
5. Set up onIceCandidate listener → sends to signaling
6. Set up onTrack listener → receives remote stream
7. setRemoteDescription(offer)
8. createAnswer()
9. setLocalDescription(answer)
10. Send answer via signaling
11. [ICE candidates trickle in both directions]
12. Connection established
```

**Critical rule**: You MUST call `addTrack()` BEFORE `createOffer()`/`createAnswer()`. If you add tracks after, you'll need renegotiation.

### 4.2 The "Callee Not Ready" Problem

This is the **#1 race condition** in WebRTC calling apps. The problem:

1. Caller creates offer and sends it via signaling.
2. Callee hasn't subscribed to the signaling channel yet (app is launching from push notification).
3. Offer is lost.

**Production solutions (ranked by reliability):**

**Solution A: Server-side message queue (RECOMMENDED)**
```
Caller sends offer → Server stores offer in DB/Redis
Callee subscribes → Server replays stored offer
```
The signaling server maintains a per-call message queue. When the callee subscribes to the call channel, the server replays all pending messages (offer + any ICE candidates) in order.

**Solution B: Caller re-sends offer on "callee ready" signal**
```
Callee subscribes → Callee sends "ready" signal
Caller receives "ready" → Caller re-sends offer
```
This is what TAJIRI currently does (re-sends offer after CallAccepted event) but with a fragile 1-second delay.

**Solution C: Subscribe-before-accept pattern (RECOMMENDED)**
```
Callee receives push → Callee subscribes to WS channel
Callee sends "subscribed" ack → Server notifies caller
Caller sends offer → Callee receives offer reliably
Callee accepts call (after subscription confirmed)
```
This is what TAJIRI's IncomingCallFlowScreen already implements (Step 1: subscribe BEFORE accept).

**The robust approach combines A + C**: The server queues signaling messages AND the callee subscribes before accepting. Belt and suspenders.

### 4.3 ICE Candidate Trickle Timing and Queuing

**The problem**: ICE candidates start generating the moment you call `setLocalDescription()`. If the remote peer hasn't set its remote description yet, `addIceCandidate()` will fail.

**Production solution — ICE candidate queue:**

```dart
// Callee side — queue candidates until remote description is set
final List<RTCIceCandidate> _pendingCandidates = [];
bool _remoteDescriptionSet = false;

void onRemoteIceCandidate(Map<String, dynamic> candidate) {
  final iceCandidate = RTCIceCandidate(
    candidate['candidate'],
    candidate['sdpMid'],
    candidate['sdpMLineIndex'],
  );

  if (_remoteDescriptionSet) {
    _peerConnection.addCandidate(iceCandidate);
  } else {
    _pendingCandidates.add(iceCandidate);
  }
}

Future<void> onRemoteOffer(Map<String, dynamic> sdp) async {
  await _peerConnection.setRemoteDescription(
    RTCSessionDescription(sdp['sdp'], sdp['type']),
  );
  _remoteDescriptionSet = true;

  // Drain queued candidates
  for (final candidate in _pendingCandidates) {
    await _peerConnection.addCandidate(candidate);
  }
  _pendingCandidates.clear();

  // Now create and send answer
  final answer = await _peerConnection.createAnswer();
  await _peerConnection.setLocalDescription(answer);
  // ... send answer via signaling
}
```

**TAJIRI status**: The `IncomingCallFlowScreen` already implements this pattern correctly with `pendingIceCandidates` and `remoteDescriptionSet`. Good.

### 4.4 TURN Server Usage Patterns

**Production statistics**: ~15-20% of WebRTC connections require TURN relay. This means 80%+ connect directly via STUN, but TURN is absolutely essential for the remaining 20% (corporate firewalls, symmetric NATs, etc.).

**ICE server configuration order matters:**
```dart
final iceServers = [
  // STUN first (free, fast)
  {'urls': 'stun:stun.l.google.com:19302'},
  // TURN UDP (most common fallback)
  {
    'urls': 'turn:turn.yourdomain.com:3478?transport=udp',
    'username': 'user',
    'credential': 'pass',
  },
  // TURN TCP (corporate firewalls that block UDP)
  {
    'urls': 'turn:turn.yourdomain.com:3478?transport=tcp',
    'username': 'user',
    'credential': 'pass',
  },
  // TURNS (TURN over TLS on port 443 — last resort, gets through everything)
  {
    'urls': 'turns:turn.yourdomain.com:443?transport=tcp',
    'username': 'user',
    'credential': 'pass',
  },
];
```

**TURNS on port 443** is the nuclear option — it tunnels TURN over TLS on the HTTPS port, getting through even the most restrictive corporate firewalls and deep packet inspection.

### 4.5 Handling Network Transitions (WiFi <-> Cellular)

**The "walk out of the door" problem**: User starts a call on WiFi, walks outside, phone switches to cellular.

**Detection**: Monitor `RTCIceConnectionState`:
- `connected` → `disconnected`: Network changed, attempt recovery
- `disconnected` → `failed` (after ~30 seconds): ICE restart needed

**Best practice — ICE Restart:**

```dart
// In CallWebRTCService — already exists as createOfferIceRestart()

void _monitorIceState() {
  _peerConnection.onIceConnectionState = (state) {
    if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
      // Wait 3-4 seconds before attempting restart
      // (brief disconnections during handoff may self-heal)
      _iceRestartTimer = Timer(const Duration(seconds: 4), () async {
        if (_peerConnection?.iceConnectionState ==
            RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
          debugPrint('[WebRTC] ICE restart after WiFi/cellular transition');
          final offer = await createOfferIceRestart();
          // Send offer via signaling to peer
          _onIceRestartOffer?.call(offer);
        }
      });
    } else if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
      _iceRestartTimer?.cancel();
    }
  };
}
```

**Key timing**:
- Wait **3-4 seconds** after `disconnected` before ICE restart (not 30 seconds for `failed`).
- ICE restart succeeds in ~67% of cases.
- If ICE restart fails, do a full renegotiation (new offer/answer exchange).
- Limit retry attempts (e.g., 10) before giving up.

**During ICE restart**: Media continues flowing on the old connection until the new one is established, then seamlessly switches. The user may experience a brief audio gap (~1-3 seconds).

### 4.6 The Perfect Negotiation Pattern

For robust negotiation (especially important for renegotiation mid-call), use the "perfect negotiation" pattern:

**Concept**: Assign each peer a role:
- **Polite peer** (callee): When offer collision occurs, drops its own offer and accepts the incoming one.
- **Impolite peer** (caller): Always ignores incoming offers that collide with its own.

**Key flags:**
- `makingOffer`: True while creating and sending an offer
- `ignoreOffer`: True when impolite peer should ignore a colliding offer
- `isSettingRemoteAnswerPending`: True while processing an incoming answer

```dart
// Simplified Dart adaptation of the perfect negotiation pattern
class PerfectNegotiator {
  final RTCPeerConnection pc;
  final bool polite; // true for callee, false for caller
  bool _makingOffer = false;
  bool _ignoreOffer = false;
  bool _isSettingRemoteAnswerPending = false;

  // Called when onnegotiationneeded fires
  Future<void> onNegotiationNeeded() async {
    try {
      _makingOffer = true;
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      sendViaSignaling({'type': offer.type, 'sdp': offer.sdp});
    } finally {
      _makingOffer = false;
    }
  }

  // Called when description arrives from signaling
  Future<void> onDescription(Map<String, dynamic> desc) async {
    final isOffer = desc['type'] == 'offer';

    final readyForOffer = !_makingOffer &&
      (pc.signalingState == RTCSignalingState.RTCSignalingStateStable ||
       _isSettingRemoteAnswerPending);

    final offerCollision = isOffer && !readyForOffer;

    _ignoreOffer = !polite && offerCollision;
    if (_ignoreOffer) return;

    _isSettingRemoteAnswerPending = !isOffer;
    await pc.setRemoteDescription(
      RTCSessionDescription(desc['sdp'], desc['type']),
    );
    _isSettingRemoteAnswerPending = false;

    if (isOffer) {
      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);
      sendViaSignaling({'type': answer.type, 'sdp': answer.sdp});
    }
  }

  // Called when ICE candidate arrives from signaling
  Future<void> onCandidate(Map<String, dynamic> candidate) async {
    try {
      await pc.addCandidate(RTCIceCandidate(
        candidate['candidate'],
        candidate['sdpMid'],
        candidate['sdpMLineIndex'],
      ));
    } catch (e) {
      if (!_ignoreOffer) rethrow;
    }
  }
}
```

---

## 5. Flutter-Specific WebRTC Calling

### 5.1 Best Packages

| Package | Purpose | Status |
|---------|---------|--------|
| **flutter_webrtc** (^0.12.12) | Core WebRTC — peer connections, media streams | TAJIRI already uses this. Solid. |
| **flutter_callkit_incoming** (^3.0.0) | Native incoming call UI (CallKit on iOS, custom on Android) | **MUST ADD** for production calls |
| **permission_handler** (^12.0.1) | Runtime permissions for mic/camera | TAJIRI already uses this |
| **web_socket_channel** (^3.0.1) | WebSocket for signaling | TAJIRI already uses this |

### 5.2 flutter_callkit_incoming — Integration Pattern

This is the **critical missing piece** in TAJIRI's current implementation. Without it, incoming calls only work when the app is in the foreground.

**What it provides:**
- **iOS**: Uses Apple CallKit to show the native iOS incoming call screen (same as FaceTime/phone app). Works from terminated state via PushKit VoIP push.
- **Android**: Shows a custom full-screen incoming call notification (heads-up notification + full-screen intent on lock screen).

**Setup:**

**pubspec.yaml:**
```yaml
dependencies:
  flutter_callkit_incoming: ^3.0.0
```

**Android (AndroidManifest.xml):**
```xml
<activity
    android:name=".MainActivity"
    android:launchMode="singleInstance">
</activity>

<!-- Required for Android 13+ -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<!-- Required for full-screen on lock screen (Android 14+) -->
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
```

**iOS (Info.plist):**
```xml
<key>UIBackgroundModes</key>
<array>
    <string>voip</string>
    <string>remote-notification</string>
    <string>processing</string>
</array>
```

**iOS (AppDelegate.swift) — PushKit + CallKit integration:**
```swift
import UIKit
import Flutter
import PushKit
import flutter_callkit_incoming

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate {

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // Register for VoIP push notifications
        let voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [.voIP]

        // WebRTC audio session config (CRITICAL)
        // Without this, audio won't work after CallKit answers
        RTCAudioSession.sharedInstance().useManualAudio = true
        RTCAudioSession.sharedInstance().isAudioEnabled = false

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - PushKit VoIP

    func pushRegistry(_ registry: PKPushRegistry,
                      didUpdate pushCredentials: PKPushCredentials,
                      for type: PKPushType) {
        let token = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
        // Send VoIP token to your server (separate from FCM token!)
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(token)
    }

    func pushRegistry(_ registry: PKPushRegistry,
                      didReceiveIncomingPushWith payload: PKPushPayload,
                      for type: PKPushType,
                      completion: @escaping () -> Void) {
        guard type == .voIP else {
            completion()
            return
        }

        let data = payload.dictionaryPayload
        let callId = data["call_id"] as? String ?? UUID().uuidString
        let callerName = data["caller_name"] as? String ?? "Incoming Call"
        let callType = data["call_type"] as? String ?? "voice"
        let hasVideo = callType == "video"

        let callData = flutter_callkit_incoming.Data(
            id: callId,
            nameCaller: callerName,
            handle: callerName,
            type: hasVideo ? 1 : 0
        )
        callData.extra = data as NSDictionary as! [String: Any]

        // MUST call this to show CallKit UI — iOS will terminate app if you don't
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(
            callData,
            fromPushKit: true
        )

        // MUST call completion — iOS terminates app after repeated violations
        completion()
    }

    func pushRegistry(_ registry: PKPushRegistry,
                      didInvalidatePushTokenFor type: PKPushType) {
        // Token expired, will get a new one
    }
}
```

**Dart side — listening for call events:**
```dart
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

class CallKitHandler {
  static void init() {
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) async {
      switch (event?.event) {
        case Event.actionCallIncoming:
          // Call UI is showing (iOS CallKit / Android notification)
          break;

        case Event.actionCallAccept:
          // User accepted the call
          final data = event?.body;
          final callId = data?['id'] as String?;
          final extra = data?['extra'] as Map<String, dynamic>?;
          // Navigate to IncomingCallFlowScreen with call details
          _navigateToIncomingCall(callId, extra);
          break;

        case Event.actionCallDecline:
          // User declined the call
          final callId = event?.body?['id'] as String?;
          // POST /api/calls/{callId}/reject
          _rejectCall(callId);
          break;

        case Event.actionCallEnded:
          // Call ended (by either party)
          break;

        case Event.actionCallTimeout:
          // Call timed out (no answer)
          final callId = event?.body?['id'] as String?;
          _missedCall(callId);
          break;

        default:
          break;
      }
    });
  }

  /// Show incoming call UI (from FCM data message handler)
  static Future<void> showIncomingCall({
    required String callId,
    required String callerName,
    String? callerAvatar,
    bool isVideo = false,
    Map<String, dynamic>? extra,
  }) async {
    final params = CallKitParams(
      id: callId,
      nameCaller: callerName,
      avatar: callerAvatar,
      type: isVideo ? 1 : 0,
      duration: 45000, // 45 second ring timeout
      textAccept: 'Accept',
      textDecline: 'Decline',
      extra: extra ?? {},
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
        ringtonePath: 'system_ringtone_default',
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }
}
```

### 5.3 Handling Background/Killed State Incoming Calls

**The full flow:**

```
1. Server creates call → sends high-priority FCM data message + VoIP push (iOS)
2. Platform receives push:
   iOS: PushKit wakes app → AppDelegate shows CallKit UI
   Android: FCM wakes app → onMessageReceived shows flutter_callkit_incoming UI
3. User sees native incoming call UI (works on lock screen, even if app was killed)
4. User taps Accept:
   iOS: CallKit sends actionCallAccept event to Flutter
   Android: flutter_callkit_incoming sends actionCallAccept event to Flutter
5. Flutter receives event → launches IncomingCallFlowScreen
6. Normal WebRTC flow begins (subscribe WS → init PC → offer/answer → connected)
```

**Android killed state workaround:**

The flutter_callkit_incoming package does NOT provide callbacks when the app is killed on Android. The workaround is to check the launch intent:

```dart
// In main.dart, after app initialization
void _checkForCallIntent() async {
  // Check if app was launched by accepting a call
  final activeCall = await FlutterCallkitIncoming.activeCalls();
  if (activeCall is List && activeCall.isNotEmpty) {
    final call = activeCall.first;
    if (call['accepted'] == true) {
      // App was launched by accepting a call — navigate to call screen
      _navigateToIncomingCall(call['id'], call['extra']);
    }
  }
}
```

### 5.4 iOS Audio Session Management (Critical)

When using CallKit on iOS, WebRTC audio requires special handling:

```swift
// In AppDelegate.swift
// These MUST be set before CallKit answers
RTCAudioSession.sharedInstance().useManualAudio = true
RTCAudioSession.sharedInstance().isAudioEnabled = false

// In the CXProviderDelegate (handled by flutter_callkit_incoming):
func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
    RTCAudioSession.sharedInstance().audioSessionDidActivate(audioSession)
    RTCAudioSession.sharedInstance().isAudioEnabled = true
}

func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
    RTCAudioSession.sharedInstance().audioSessionDidDeactivate(audioSession)
    RTCAudioSession.sharedInstance().isAudioEnabled = false
}
```

Without this, you'll get **silent calls** on iOS — the WebRTC audio engine and CallKit will fight over the audio session.

---

## 6. Push Notifications for Calls

### 6.1 iOS: VoIP Push via PushKit

**Why PushKit, not regular APNs:**

| Feature | Regular APNs | PushKit VoIP |
|---------|-------------|--------------|
| Wakes killed app | No | **Yes** |
| Delivery priority | Best-effort | **Immediate, guaranteed** |
| Power management | Throttled in Doze | **Bypasses all throttling** |
| CallKit required | No | **Yes (since iOS 13)** |
| Background processing | 30 seconds (extension) | **Until call ends** |

**Apple's hard requirement (since iOS 13):** Every PushKit VoIP push MUST result in a `reportNewIncomingCall()` to CallKit. If you receive a VoIP push and don't report a call, iOS will terminate your app after a few violations.

**Server-side (Laravel) VoIP push:**

```php
// Laravel — send VoIP push via APNs
// Requires a separate VoIP Services Certificate (not your regular push cert)
use Edamov\PushNotification\PushNotification;

$push = new PushNotification('apn');
$push->setMessage([
    'call_id' => $call->id,
    'caller_id' => $caller->id,
    'caller_name' => $caller->name,
    'caller_avatar_url' => $caller->avatar_url,
    'call_type' => $call->type, // 'voice' or 'video'
    'type' => 'call_incoming',
])
->setDevicesToken([$calleeVoipToken])
->setConfig([
    'certificate' => storage_path('app/voip_push.pem'),
    'passPhrase' => '',
    'topic' => 'com.your.app.voip', // Note: .voip suffix
])
->send();
```

### 6.2 Android: High-Priority FCM Data Messages

**Requirements for reliable call notifications on Android:**

1. **Use data-only messages** (not notification messages) — gives you control in all states
2. **Set priority to "high"** — wakes device from Doze
3. **Use full-screen intent** for lock screen display

**Server-side (Laravel) FCM:**

```php
// Laravel — send high-priority FCM for incoming call
$message = CloudMessage::new()
    ->withChangedTarget('token', $deviceFcmToken)
    ->withData([
        'type' => 'call_incoming',
        'call_id' => $call->id,
        'caller_id' => $caller->id,
        'caller_name' => $caller->name,
        'caller_avatar_url' => $caller->avatar_url,
        'call_type' => $call->type,
    ])
    ->withAndroidConfig(
        AndroidConfig::new()
            ->withPriority('high')
            // Do NOT include notification payload — data-only
    );
```

### 6.3 Android 14/15 Full-Screen Intent Changes

**Critical change**: Starting Android 14, `USE_FULL_SCREEN_INTENT` is restricted to **calling and alarm apps only**.

- **Calling apps** get this permission automatically (if declared in manifest and approved on Play Store).
- **Other apps** must request user permission via `ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT`.
- TAJIRI qualifies as a calling app since it has calling functionality.

**Check permission at runtime:**
```dart
// Check if full-screen intent is available
final notificationManager = // platform channel to NotificationManager
final canUseFullScreen = await notificationManager.canUseFullScreenIntent();
if (!canUseFullScreen) {
  // Direct user to Settings > Special App Access > Full screen intents
}
```

**Play Store declaration:** Submit a USE_FULL_SCREEN_INTENT declaration form on Play Console indicating your app has calling functionality.

---

## 7. Signaling Architecture

### 7.1 WebSocket vs REST for Signaling

**Use BOTH — each for what it's best at:**

| Operation | Transport | Why |
|-----------|-----------|-----|
| Create call | REST `POST /api/calls` | Reliable, has response with call_id |
| Accept call | REST `POST /api/calls/{id}/accept` | Reliable, must succeed |
| Reject call | REST `POST /api/calls/{id}/reject` | Reliable, must succeed |
| End call | REST `POST /api/calls/{id}/end` | Reliable, must succeed |
| SDP offer/answer | WebSocket (preferred) + REST fallback | Low latency needed |
| ICE candidates | WebSocket (preferred) + REST fallback | Low latency, many messages |
| Call state events | WebSocket broadcast | Real-time UI updates |

**TAJIRI status**: Already implements this dual approach. Good architecture.

### 7.2 Guaranteeing Message Delivery for Offers/Answers

**The problem**: WebSocket messages are fire-and-forget. If the connection drops mid-send, the offer/answer is lost.

**Production solution — Server-side message queue:**

```
Backend stores signaling messages per call:
┌──────────────────────────────────────────┐
│ calls_signaling_queue                    │
│ ─────────────────────                    │
│ id, call_id, type, payload, created_at,  │
│ delivered_to_user_id, delivered_at       │
└──────────────────────────────────────────┘

When callee subscribes to channel:
1. Server checks queue for undelivered messages
2. Replays them in order (offer first, then ICE candidates)
3. Marks as delivered

When caller sends offer via REST /signaling:
1. Server stores in queue
2. Server broadcasts via WebSocket
3. If WebSocket delivery fails, message persists in queue
4. Callee can poll for missed messages
```

**Laravel implementation concept:**

```php
// In CallSignalingController::sendSignaling()
public function sendSignaling(Request $request, string $callId)
{
    $data = $request->validate([...]);

    // 1. Persist the signaling message
    $msg = CallSignalingMessage::create([
        'call_id' => $callId,
        'from_user_id' => auth()->id(),
        'type' => $data['type'], // offer, answer, ice_candidate
        'payload' => json_encode($data),
    ]);

    // 2. Broadcast via WebSocket (Reverb)
    broadcast(new SignalingEvent($callId, $data))->toOthers();

    // 3. Return success (message is persisted even if WS fails)
    return response()->json(['success' => true]);
}

// When callee subscribes to channel, replay pending messages
public function getPendingSignaling(string $callId)
{
    $messages = CallSignalingMessage::where('call_id', $callId)
        ->whereNull('delivered_at')
        ->where('from_user_id', '!=', auth()->id())
        ->orderBy('created_at')
        ->get();

    // Mark as delivered
    $messages->each->update(['delivered_at' => now()]);

    return response()->json(['data' => $messages]);
}
```

### 7.3 The Race Condition: Offer Arrives Before Callee Subscribes

**TAJIRI's current flow has this vulnerability:**

```
Caller: createOffer() → sendSignaling(offer) → [offer broadcast on WS]
Callee: [receives push] → [app launches] → [subscribes to WS] → ...offer already gone
```

**Fix — Add a "replay pending signals" step after subscribe:**

```dart
// In IncomingCallFlowScreen._accept(), after WS subscribe:
final wsSubscribed = await _channel.subscribe(callId: callId, ...);

if (wsSubscribed) {
  // NEW: Fetch any signaling messages that arrived before we subscribed
  final pendingResp = await http.get(
    Uri.parse('$baseUrl/calls/$callId/pending-signaling'),
    headers: authHeaders,
  );
  if (pendingResp.statusCode == 200) {
    final messages = jsonDecode(pendingResp.body)['data'] as List;
    for (final msg in messages) {
      // Process each pending message as if it arrived via WebSocket
      _processSignalingMessage(msg);
    }
  }
}
```

This eliminates the race condition entirely. Even if the WebSocket broadcast of the offer happened before the callee subscribed, the callee fetches it via REST as a fallback.

---

## 8. Call Quality

### 8.1 TURN Server Configuration for Production

**Recommended: coturn on a dedicated server**

**Installation:**
```bash
sudo apt install coturn
```

**Production `/etc/turnserver.conf`:**
```ini
# Network
listening-port=3478
tls-listening-port=5349
alt-listening-port=3479
alt-tls-listening-port=5350

# Your server's public IP
external-ip=203.0.113.50
listening-ip=0.0.0.0

# Domain
realm=turn.tajiri.app
server-name=turn.tajiri.app

# TLS (Let's Encrypt)
cert=/etc/letsencrypt/live/turn.tajiri.app/fullchain.pem
pkey=/etc/letsencrypt/live/turn.tajiri.app/privkey.pem

# Security — disable old TLS versions
no-tlsv1
no-tlsv1_1

# Authentication — use REST API (time-limited credentials)
use-auth-secret
static-auth-secret=YOUR_LONG_RANDOM_SECRET_HERE

# Relay ports
min-port=49152
max-port=65535

# Performance
total-quota=100
max-bps=0
stale-nonce=600

# Security hardening
no-loopback-peers
no-multicast-peers
denied-peer-ip=10.0.0.0-10.255.255.255
denied-peer-ip=172.16.0.0-172.31.255.255
denied-peer-ip=192.168.0.0-192.168.255.255

# Logging
log-file=/var/log/turnserver.log
verbose

# Fingerprint for STUN
fingerprint
```

**Firewall rules:**
```bash
sudo ufw allow 3478/tcp   # STUN/TURN
sudo ufw allow 3478/udp
sudo ufw allow 5349/tcp   # TURNS
sudo ufw allow 49152:65535/udp  # Relay ports
```

**REST API credentials (time-limited, generated by Laravel):**

```php
// In Laravel — generate TURN credentials per call
public function getTurnCredentials()
{
    $secret = config('services.turn.secret');
    $ttl = 86400; // 24 hours
    $timestamp = time() + $ttl;
    $username = $timestamp . ':' . auth()->id();
    $credential = base64_encode(hash_hmac('sha1', $username, $secret, true));

    return response()->json([
        'success' => true,
        'data' => [
            'ice_servers' => [
                ['urls' => 'stun:turn.tajiri.app:3478'],
                [
                    'urls' => [
                        'turn:turn.tajiri.app:3478?transport=udp',
                        'turn:turn.tajiri.app:3478?transport=tcp',
                        'turns:turn.tajiri.app:5349?transport=tcp',
                    ],
                    'username' => $username,
                    'credential' => $credential,
                ],
            ],
            'ttl_seconds' => $ttl,
        ],
    ]);
}
```

### 8.2 Codec Selection

**Audio — Opus (mandatory in WebRTC):**
- Dynamically adjusts bitrate based on network conditions
- Voice: 6-20 kbps, Music: up to 128 kbps
- Built-in echo cancellation and noise suppression
- No configuration needed — WebRTC selects Opus by default

**Video — H.264 Constrained Baseline (preferred on mobile):**
- Hardware-accelerated on virtually all iOS and Android devices
- Lower CPU/battery usage than VP8 software encoding
- WebRTC uses H.264 CB by default on mobile

**To prefer H.264 over VP8 in SDP munging (optional optimization):**
```dart
// Reorder video codecs in SDP to prefer H.264
String _preferH264(String sdp) {
  // Find the H.264 payload type and move it to the front of m=video line
  // This is SDP munging — use with care
  final lines = sdp.split('\r\n');
  // ... reorder codec priority in m=video line
  return lines.join('\r\n');
}
```

In practice, flutter_webrtc on mobile already prefers H.264 when hardware support is available. No SDP munging needed for most devices.

### 8.3 Bandwidth Adaptation

WebRTC handles this automatically through:
- **REMB (Receiver Estimated Maximum Bitrate)**: Receiver tells sender what bandwidth is available
- **Transport-CC**: Transport-wide congestion control feedback
- **Dynamic resolution/framerate**: WebRTC reduces resolution and framerate as bandwidth drops

**Configurable constraints for mobile optimization:**
```dart
// Video constraints for mobile — start conservative
final videoConstraints = {
  'facingMode': 'user',
  'width': {'ideal': 640, 'max': 1280},  // Not 1920x1080
  'height': {'ideal': 480, 'max': 720},
  'frameRate': {'ideal': 24, 'max': 30},  // Not 60fps
};
```

Starting at 640x480@24fps instead of 1280x720@30fps reduces initial bandwidth needs by ~60% and lets WebRTC scale up if bandwidth permits, rather than starting high and causing initial stuttering.

### 8.4 Echo Cancellation and Noise Suppression

WebRTC includes built-in audio processing:
- **AEC (Acoustic Echo Cancellation)**: Enabled by default
- **AGC (Automatic Gain Control)**: Enabled by default
- **NS (Noise Suppression)**: Enabled by default

These are configured in the audio constraints:
```dart
final audioConstraints = {
  'echoCancellation': true,    // default: true
  'autoGainControl': true,     // default: true
  'noiseSuppression': true,    // default: true
  'channelCount': 1,           // mono for voice calls
};
```

No additional configuration needed — flutter_webrtc enables all three by default.

---

## 9. Gap Analysis: TAJIRI's Current Implementation vs. Production

### What TAJIRI Already Has (Working)

1. **CallState** (ChangeNotifier-based state management) — correct pattern
2. **CallSignalingService** — REST API for create/accept/reject/end/signaling
3. **CallWebRTCService** — peer connection, getUserMedia, offer/answer, ICE, screen share
4. **CallChannelService** — WebSocket subscription to Reverb private channels
5. **OutgoingCallFlowScreen** — correct order: permissions → create call → subscribe WS → init PC → offer → wait
6. **IncomingCallFlowScreen** — correct order: subscribe WS BEFORE accept → init PC → wait for offer → answer
7. **ICE candidate queuing** on callee side — correctly implemented
8. **ICE restart** — `createOfferIceRestart()` exists
9. **FCM handling** for `call_incoming` payload — routes to IncomingCallFlowScreen

### Critical Missing Pieces

| Gap | Priority | Impact |
|-----|----------|--------|
| **No flutter_callkit_incoming** | P0 | Calls don't work when app is killed/background. No native call UI. |
| **No PushKit VoIP push (iOS)** | P0 | iOS calls unreliable in background. Regular FCM can be delayed. |
| **No server-side signaling queue** | P1 | Race condition: offer lost if callee not subscribed yet |
| **No ICE restart monitoring** | P1 | WiFi→cellular transition drops call silently |
| **Caller re-sends offer with hardcoded 1s delay** | P2 | Fragile — should use server queue instead |
| **No perfect negotiation** | P2 | Mid-call renegotiation (add video, screen share) can glitch |
| **No TURN server deployed** | P1 | ~20% of calls will fail (NAT traversal) |
| **Video starts at 1280x720** | P3 | Excessive initial bandwidth on slow networks |
| **No network transition handling** | P1 | Call drops on WiFi↔cellular switch |
| **Android 14/15 FSI permission** | P2 | Full-screen incoming call may not show on lock screen |

### Recommended Implementation Order

1. **Deploy coturn TURN server** — without this, 20% of calls fail
2. **Add flutter_callkit_incoming** — native call UI + background/killed state support
3. **Add PushKit VoIP push for iOS** — reliable iOS call delivery
4. **Add server-side signaling queue** — eliminate offer race condition
5. **Add ICE restart on network transition** — prevent WiFi→cellular drops
6. **Add "replay pending signals" REST endpoint** — belt-and-suspenders for race condition
7. **Implement perfect negotiation** — robust mid-call renegotiation
8. **Lower default video constraints** — better initial experience on slow networks

---

## Sources

- [WhatsApp Business Calling API with WebRTC](https://webrtc.ventures/2025/11/how-to-integrate-the-whatsapp-business-calling-api-with-webrtc-to-enable-customer-voice-calls/)
- [How WhatsApp Works - Architecture Deep Dive](https://getstream.io/blog/whatsapp-works/)
- [WhatsApp System Design - Complete Architecture](https://medium.com/@yadavsatale/whatsapp-system-design-a-complete-architecture-deep-dive-8949f8d4eb2b)
- [Telegram End-to-End Encrypted Video Calls](https://core.telegram.org/api/end-to-end/video-calls)
- [Signal Protocol Integration](https://signal.org/blog/whatsapp-complete/)
- [flutter_callkit_incoming Package](https://pub.dev/packages/flutter_callkit_incoming)
- [flutter_callkit_incoming GitHub](https://github.com/hiennguyen92/flutter_callkit_incoming)
- [Flutter Callkit — Handle Actions in Killed State](https://medium.com/@Ayush_b58/flutter-callkit-handle-actions-in-the-killed-state-e6f296c603e6)
- [WebRTC Perfect Negotiation Pattern (MDN)](https://developer.mozilla.org/en-US/docs/Web/API/WebRTC_API/Perfect_negotiation)
- [Perfect Negotiation in WebRTC (Mozilla Blog)](https://blog.mozilla.org/webrtc/perfect-negotiation-in-webrtc/)
- [ICE Candidate Tutorial](https://getstream.io/resources/projects/webrtc/basics/ice-candidates/)
- [ICE Restarts (Mozilla Blog)](https://blog.mozilla.org/webrtc/just-begin-ice-restart/)
- [WebRTC Mobile Reconnection Mechanism](https://webrtc.ventures/2023/06/implementing-a-reconnection-mechanism-for-webrtc-mobile-applications/)
- [Trickle ICE RFC 8838](https://www.rfc-editor.org/rfc/rfc8838)
- [PushKit for iOS Calls](https://getstream.io/blog/pushkit-for-calls/)
- [Apple PushKit Documentation](https://developer.apple.com/documentation/PushKit)
- [Apple: Responding to VoIP Notifications](https://developer.apple.com/documentation/pushkit/responding-to-voip-notifications-from-pushkit)
- [How to Handle VoIP Push with CallKit (Vonage)](https://developer.vonage.com/en/blog/handling-voip-push-notifications-with-callkit)
- [FCM Android Message Priority](https://firebase.google.com/docs/cloud-messaging/android-message-priority)
- [FCM Best Practices 2025](https://firebase.blog/posts/2025/04/fcm-on-android/)
- [Android 14/15 Full-Screen Intent Changes](https://source.android.com/docs/core/permissions/fsi-limits)
- [Play Console FSI Requirements](https://support.google.com/googleplay/android-developer/answer/13392821)
- [Setting Up Coturn Server](https://icetester.org/blog/06-setting-up-coturn-server)
- [Coturn Wiki](https://github.com/coturn/coturn/wiki/turnserver)
- [Coturn Security Configuration](https://www.enablesecurity.com/blog/coturn-security-configuration-guide/)
- [WebRTC Codecs (MDN)](https://developer.mozilla.org/en-US/docs/Web/Media/Guides/Formats/WebRTC_codecs)
- [H.264 vs VP8 for WebRTC](https://bloggeek.me/webrtc-h264-vp8/)
- [Flutter WebRTC — TURN and Signaling Guide](https://dev.to/abdulrazack23/building-real-time-communication-in-flutter-a-guide-to-turn-and-signaling-servers-22fe)
- [Flutter WebRTC Complete Guide (VideoSDK)](https://www.videosdk.live/blog/flutter-webrtc)
- [WebRTC Signaling (WebRTC for the Curious)](https://webrtcforthecurious.com/docs/02-signaling/)
- [ConnectyCube Flutter Call Kit](https://github.com/ConnectyCube/connectycube-flutter-call-kit)
- [callkeep (flutter-webrtc)](https://github.com/flutter-webrtc/callkeep)
