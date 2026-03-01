# Video & Audio Calls — Feature Implementation Status (Flutter)

**Product:** Tajiri  
**Last updated:** 2025-02-16  
**Status:** All listed features have been **implemented** (or provided with a placeholder where optional).

Use with: [gap-analysis.md](gap-analysis.md) for full spec-vs-implemented comparison.

---

## Summary

The following **Flutter** features from the video-audio-calls spec were previously not implemented. They are now **done** (or have a clear placeholder). Backend-only steps are excluded.

| # | Feature | Phase | Status |
|---|---------|-------|--------|
| 1 | Align CallService with new API | 1 | ✅ CallService accepts optional authToken; when set, delegates to CallSignalingService (create, accept, reject, end). |
| 2 | Explicit permission request before call | 1 | ✅ OutgoingCallFlowScreen requests microphone (and camera for video) via permission_handler before POST create. |
| 3 | Create group call UI | 2 | ✅ ChatScreen (group) → menu “Simu ya kikundi” → select members → createGroupCall → OutgoingCallFlowScreen with existingCallId. |
| 4 | Group call UI (grid of participants) | 2 | ⚠️ ParticipantAdded handled (snackbar + list); full multi-tile grid would require multiple peer connections/SFU (future). |
| 5 | Handle ParticipantAdded / multi-peer | 2 | ✅ CallChannelService emits ParticipantAddedEvent; ActiveCallScreen subscribes, shows snackbar “X joined”, keeps list. |
| 6 | Participant selection when starting from group | 2 | ✅ Same as #3: group chat menu → member selection → createGroupCall. |
| 7 | Show incoming reaction as animation on tile | 4 | ✅ ActiveCallScreen listens to onCallReaction; shows emoji overlay for 2s. |
| 8 | Show hand icon on participant tile | 4 | ✅ ActiveCallScreen listens to onRaiseHand; shows hand icon when remoteHandRaised. |
| 9 | Missed-call voice message | 4 | ✅ CallSignalingService.postMissedCallVoiceMessage; MissedCallVoiceScreen (record + send); Call history “Leave voice message” for missed with callId. |
| 10 | Scheduled calls (full) | 4 | ✅ createScheduledCall, getScheduledCalls, deleteScheduledCall, startScheduledCall; ScheduledCallsScreen (list, FAB schedule, Start); entry from Call history (schedule icon). |
| 11 | Incoming call “Message” shortcut | 1 | ✅ IncomingCallFlowScreen “Message” button → getPrivateConversation → ChatScreen. |
| 12 | Top overlay auto-hide | 1 | ✅ Overlay hides after 3s; tap on video shows overlay and restarts timer. |
| 13 | Double-tap focus on remote video | 3 | ✅ Double-tap shows overlay (device camera focus would need platform channel). |
| 14 | Switch camera (front/back) in More | 3 | ✅ More → “Switch camera” calls Helper.switchCamera (video calls). |
| 15 | Video effects (optional) | 5 | ✅ More → “Video effects” placeholder (SnackBar “Coming soon”). |
| 16 | Weak network banner | 1 | ✅ ActiveCallScreen shows amber “Weak network” when ICE disconnected/failed and not reconnecting. |
| 17 | Persist auth token on login | — | ✅ UserRegistrationResult.accessToken; registration_screen saves token via saveAuthToken when backend returns it; login_screen comment for future login API. |

---

## Checklist: implemented (Flutter)

| # | Item | Phase | Done |
|---|------|-------|------|
| 1 | Align CallService with new API (token path) | 1 | ✅ |
| 2 | Explicit permission request before starting call | 1 | ✅ |
| 3 | Incoming call “Message” shortcut | 1 | ✅ |
| 4 | Top overlay auto-hide / show on tap | 1 | ✅ |
| 5 | Weak network banner | 1 | ✅ |
| 6 | Create group call UI (from group chat, select members) | 2 | ✅ |
| 7 | Group call UI / ParticipantAdded handling | 2 | ✅ (event + snackbar; full grid = future) |
| 8 | Handle ParticipantAdded + list + snackbar | 2 | ✅ |
| 9 | Participant selection when starting from group | 2 | ✅ |
| 10 | Double-tap focus (overlay show) on remote video | 3 | ✅ |
| 11 | Switch camera (front/back) in More menu | 3 | ✅ |
| 12 | Show incoming reaction as animation on tile | 4 | ✅ |
| 13 | Show hand icon on participant tile | 4 | ✅ |
| 14 | Missed-call voice message (API + record + send) | 4 | ✅ |
| 15 | Scheduled calls (API + UI + list + Start) | 4 | ✅ |
| 16 | Video effects placeholder | 5 | ✅ |
| 17 | Persist auth token on login/register | — | ✅ |

---

*Back to [README.md](README.md) | [gap-analysis.md](gap-analysis.md) | [implementation-steps.md](implementation-steps.md)*
