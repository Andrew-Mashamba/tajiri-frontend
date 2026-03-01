# Video & Audio Calls — Flutter + WebRTC Implementation

**Audience:** Flutter developers  
**Stack:** Flutter (this repo), Laravel signaling backend  
**Source:** `../VIDEO_AUDIO_CALLS.md`

---

## 1. Overview

- **Signaling:** Flutter talks to Laravel over REST + WebSockets (or Echo) to create/accept/reject/end calls and exchange SDP/ICE.
- **Media:** Flutter uses WebRTC (via `flutter_webrtc`) to capture mic/camera, create `RTCPeerConnection`, and send/receive streams. Media goes P2P or via TURN; Laravel never sees media.

---

## 2. Dependencies

**pubspec.yaml:**

```yaml
dependencies:
  flutter_webrtc: ^0.11.0   # or latest compatible
  web_socket_channel: ^2.4.0
  # or laravel_echo + pusher for Laravel Reverb
```

**Platform:**

- **Android:** `minSdkVersion` 21+; permissions `RECORD_AUDIO`, `CAMERA`, `INTERNET`, `MODIFY_AUDIO_SETTINGS`.
- **iOS:** `NSMicrophoneUsageDescription`, `NSCameraUsageDescription`, `UIBackgroundModes` (e.g. `voip`) if you need background call handling.

---

## 3. High-level flow in Flutter

1. **Outgoing call:** User taps call → call Laravel `POST /api/calls` with callee id and type (voice/video) → subscribe to `private-call.{call_id}` → wait for `CallAccepted` / `CallRejected` / timeout.
2. **Incoming call:** Receive `CallIncoming` on channel (or push) → show incoming UI → on accept: `POST /api/calls/{id}/accept` → subscribe to channel → exchange SDP/ICE with peer via Laravel.
3. **Connect WebRTC:** Once SDP/answer and ICE are exchanged, `RTCPeerConnection` goes to “connected” → attach remote stream to `RTCVideoRenderer` (video) or play audio track.
4. **Hangup:** Call `POST /api/calls/{id}/end` and close `RTCPeerConnection`, dispose renderers.

---

## 4. WebRTC setup

**Get TURN/STUN from Laravel:**

```dart
final response = await http.get(
  Uri.parse('$baseUrl/api/calls/turn-credentials'),
  headers: authHeaders,
);
final json = jsonDecode(response.body);
final iceServers = (json['iceServers'] as List)
    .map((e) => RTCIceServer(
          urls: e['urls'],
          username: e['username'],
          credential: e['credential'],
        ))
    .toList();
```

**Create peer connection:**

```dart
final config = RTCConfiguration(
  iceServers: iceServers,
  sdpSemantics: 'unified-plan',
);

final pc = await createPeerConnection(config);
```

**Add local stream (voice + video):**

```dart
final stream = await navigator.mediaDevices.getUserMedia({
  'audio': true,
  'video': videoCall ? {
    'facingMode': 'user',
    'width': {'ideal': 1280},
    'height': {'ideal': 720},
  } : false,
});

stream.getTracks().forEach((track) {
  pc.addTrack(track, stream);
});
```

**Listen for remote stream:**

```dart
pc.onTrack = (event) {
  if (event.streams != null && event.streams!.isNotEmpty) {
    remoteStream = event.streams!.first;
    // Notify UI to attach to RTCVideoRenderer (video) or play audio
  }
};
```

**ICE candidates:** Send each candidate to Laravel so it can forward to the other peer; when receiving from Laravel, call `pc.addIceCandidate(candidate)`.

**SDP:** On offer/answer from Laravel, call `pc.setRemoteDescription(description)` then, if caller, `pc.createAnswer()` and send back to Laravel.

---

## 5. UI binding (Flutter)

- **Local video:** Use `RTCVideoRenderer` with `localStream` and place in the small PiP (see `02-ui-specification-flutter.md`).
- **Remote video:** Use `RTCVideoRenderer` with `remoteStream` for the main full-screen view.
- **Voice only:** No video renderers; show avatar and bottom bar (mute, speaker, end, add).
- **Mute:** Mute/unmute the local audio track: `await track.enable(false);` / `true`.
- **Camera off:** Same for video track; in UI show avatar or placeholder.
- **Speaker:** Use `flutter_webrtc` audio routing or a plugin (e.g. `speaker`) to switch output.

---

## 6. Screen sharing (optional)

- **Mobile:** Limited; some platforms allow screen capture in certain contexts.
- **Approach:** Add a second video track from `getDisplayMedia` (if available) or a platform channel; send via same `RTCPeerConnection` or a second one, and signal “screen share on” to the other side so they show it in UI.

---

## 7. Group calls (SFU)

- Laravel returns SFU URL and room id when creating/joining a group call.
- Flutter connects to SFU (e.g. over WebSocket), joins the room, and sends one stream (audio + video) to SFU and receives N−1 streams from SFU.
- Use the same `flutter_webrtc` primitives; SFU client SDK (e.g. mediasoup-client) may have a different API but still uses `RTCPeerConnection` under the hood.

---

## 8. Reconnection

- On `iceConnectionState` “disconnected” or “failed”, try ICE restart: create new offer with `iceRestart: true`, send via Laravel, and re-exchange ICE candidates.
- Optionally show “Reconnecting…” in UI (see `02-ui-specification-flutter.md`).

---

## 9. Permissions

- Before starting a call, request microphone (and camera for video) with `Permission.microphone` / `Permission.camera`; explain why in the dialog.
- If user denies, show a message and do not start the call.

---

## 10. Testing

- Test on real devices (two phones or one phone + Chrome) for P2P and TURN.
- Test with poor network (e.g. throttling) to verify adaptive quality and reconnection behavior.

---

*Next: [02-ui-specification-flutter.md](02-ui-specification-flutter.md) | [04-backend-implementation-laravel.md](04-backend-implementation-laravel.md) | [06-performance-targets.md](06-performance-targets.md)*
