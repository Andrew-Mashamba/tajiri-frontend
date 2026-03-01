# Video & Audio Calls — UI Specification (Flutter)

**Audience:** Flutter developers, designers  
**Stack:** Flutter (this repo)  
**Source:** `../VIDEO_AUDIO_CALLS.md`

---

## 1. Design principles

- **Bottom-heavy controls** — Primary actions in thumb reach (bottom bar).
- **Minimal top clutter** — Status and timer only; overlay can auto-hide.
- **Red for destructive** — End/decline use a clear danger color.
- **Progressive disclosure** — Advanced options behind “More” or secondary screens.

---

## 2. Voice call UI (1:1)

### 2.1 Layout structure

```
┌──────────────────────────┐
│  Contact Name            │  ← AppBar / header
│  Calling / Ringing / 0:42 │
├──────────────────────────┤
│                          │
│     Profile Picture      │  ← Center (avatar)
│     (or placeholder)     │
│                          │
├──────────────────────────┤
│  Mute  Speaker  Add  End │  ← Bottom action bar
└──────────────────────────┘
```

### 2.2 Regions and Flutter mapping

| Region | Content | Widget suggestions |
|--------|---------|--------------------|
| **Top** | Contact name (bold), status (Calling / Ringing / Connected / Reconnecting), optional back | `AppBar` or custom `SafeArea` + `Row` |
| **Center** | Large circular avatar, optional pulsing when ringing, timer below when connected | `CircleAvatar`, `AnimatedContainer` or `AnimationController` for pulse |
| **Bottom** | Mute, Speaker, Add participant, End call | `Row` of `IconButton` or custom buttons, fixed at bottom |

### 2.3 Bottom bar — control order

| Position | Control | Icon | Behavior |
|----------|---------|------|----------|
| Left | Mute | Mic / MicOff | Toggle; filled or accent when muted |
| Mid-left | Speaker | Speaker / Earpiece | Cycle or menu: earpiece, speaker, Bluetooth |
| Mid-right | Add | PersonAdd | Opens “Add participant” flow |
| Right | End | CallEnd (red) | Terminates call |

### 2.4 Incoming voice call

- Full-screen or modal: contact name, avatar, “Incoming voice call”.
- **Decline** (e.g. red) and **Accept** (e.g. green).
- Optional: “Message” shortcut (opens chat).

### 2.5 States

- **Ringing (outgoing)** — “Calling…” or “Ringing…”
- **Ringing (incoming)** — “Incoming voice call” + Decline / Accept
- **Connecting** — “Connecting…”
- **Connected** — Show timer
- **Reconnecting** — Banner at top
- **Weak network** — Optional yellow/red banner

---

## 3. Video call UI (1:1)

### 3.1 Layout structure

```
┌──────────────────────────┐
│ Contact Name      0:42   │  ← Overlay (semi-transparent, auto-hide)
├──────────────────────────┤
│                          │
│   Remote Video (Full)    │  ← Primary canvas
│                          │
│   [Self Preview] PiP     │  ← Draggable, e.g. top-right
├──────────────────────────┤
│ Mute Video End Add More  │  ← Bottom action bar
└──────────────────────────┘
```

### 3.2 Regions

| Region | Content | Notes |
|--------|---------|--------|
| **Primary canvas** | Remote video full-screen | Support double-tap focus, pinch-to-zoom |
| **Self-view (PiP)** | Local camera preview | Rounded rect, draggable to corners; tap to swap main/PiP (optional) |
| **Top overlay** | Name, timer, optional network icon | Low opacity; hide after a few seconds, show on tap |
| **Bottom bar** | Mute, Camera off/on, End, Add, More | Same thumb-zone principle as voice |

### 3.3 Bottom bar — video

| Position | Control | Notes |
|----------|---------|--------|
| Left | Mute | Same as voice |
| Mid-left | Camera | Toggle video on/off (show avatar when off) |
| Center | End (red) | Prominent |
| Mid-right | Add | Escalate to group |
| Right | More (⋮) | Menu: switch camera, effects, screen share, audio output |

### 3.4 “More” menu contents

- Switch camera (front/back)
- Screen share (start/stop)
- Audio output (earpiece / speaker / Bluetooth)
- Optional: effects/filters, raise hand (for group)

---

## 4. Group call UI (voice & video)

### 4.1 Grid behavior

| Participants | Layout |
|--------------|--------|
| ≤ 4 | 2×2 equal grid |
| 5–8 | Adaptive grid; active speaker slightly larger |
| 9–32 | Scrollable list or paginated grid; speaker spotlight |

### 4.2 Speaker highlight

- Active speaker: subtle border or glow, optional waveform.
- Tile size can increase for active speaker.

### 4.3 Raise hand

- Small hand icon on participant tile or in list.
- Optional floating indicator.

### 4.4 Reactions

- Emoji floats up from sender tile; temporary; does not change grid layout.

### 4.5 Flutter implementation hints

- Use `GridView` or custom layout for tiles.
- One widget per participant (remote stream + label + state).
- `PageView` or `ListView` for many participants with speaker prioritization.

---

## 5. Visual design language

| Element | Recommendation |
|---------|----------------|
| **Accept / primary action** | Green or theme primary |
| **End / decline** | Red (danger) |
| **Neutral** | Gray/white; adapt to dark mode |
| **Buttons** | Circular or rounded; filled when active |
| **Tiles** | Rounded corners, soft shadow |
| **Typography** | Bold for name, medium for status, small for timer |

---

## 6. Gestures

| Gesture | Effect |
|---------|--------|
| Tap | Toggle control, accept/decline |
| Long press | Optional secondary menu |
| Drag | Move self-view PiP |
| Pinch | Zoom remote video (video only) |
| Swipe down | Minimize call (optional, Android-style) |

---

## 7. Privacy and permissions UI

- **Camera / mic indicator** — System or in-app indicator when in use.
- **Permission request** — Clear rationale before requesting mic/camera.
- **“End-to-end encrypted”** — Brief message or icon when call connects (optional).

---

## 8. Flutter package suggestions

- **WebRTC:** `flutter_webrtc` for media and device handling.
- **UI:** Material or Cupertino; custom overlays with `Stack`, `Positioned`, `GestureDetector`.
- **State:** Provider, Riverpod, or Bloc for call state (ringing, connected, muted, etc.).

---

*Next: [03-architecture-overview.md](03-architecture-overview.md) | [05-flutter-webrtc-implementation.md](05-flutter-webrtc-implementation.md)*
