# TAJIRI Messaging — Remaining Gaps & Prioritized Roadmap

> Based on gap analysis of codebase (frontend + backend) against `docs/MESSAGES.md`. Generated 2026-03-31.

---

## Partial Implementations (12 items)

| # | Feature | What Works | What's Missing |
|---|---------|------------|----------------|
| 14 | **Animated/seasonal stickers** | Emoji-only sticker picker (`_showStickerPicker()` with 10 hardcoded emojis sent as `[sticker:emoji]` text) | No animated sticker packs, no seasonal collections, no sticker store/library, no dedicated `sticker` message type on backend |
| 15 | **GIFs and custom animated stickers** | Full Giphy integration (`_GifPickerContent` with trending + search). GIFs sent as URL strings | GIF URLs render as plain text in bubbles — not as animated images. No custom animated sticker creation. No `gif` message type |
| 17 | **Built-in document scanning** | Camera capture via `ImagePicker` in `_scanDocument()`, sent as `messageType: 'document'` | No edge detection, perspective correction, OCR, or multi-page PDF assembly. Functionally a "photo as document" |
| 23 | **Scheduled calls (guest chats)** | Scheduled calls fully working (CRUD + reminders + start). `ScheduledCallController` with invitee notifications | Guest chat absent — no unauthenticated link-based access for users not on the platform |
| 26 | **Speaker spotlight + emoji reactions in calls** | Emoji reactions done (`_lastReactionEmoji`, `CallChannelService.onCallReaction`, fullscreen display). Raise hand implemented | No dominant-speaker detection. No spotlight UI that auto-focuses the active speaker's video tile |
| 27 | **Favorite contacts and call filters** | Missed call filter chip in Calls tab (`_callsFilter: 'missed'`) | No "favorite contacts" shortcut for quick-dialing. Chat favorites (`isStarred`) not surfaced in Calls tab |
| 29 | **Group metadata and member tags** | Group name, avatar, member count, "Admin" badge per member in `GroupInfoScreen` | No custom member tags beyond admin (e.g. moderator, VIP). No editable group metadata fields (description, rules) |
| 31 | **Group polls in chat** | Full poll system exists (`PollController` — create, vote, close, view voters). `createpoll_screen.dart` works as standalone | Polls not embedded inline in chat message flow. No `poll` message type. No "Create poll" in chat attachment menu |
| 40 | **Favorites tab (calls)** | Chat favorites fully working — `_isFavorite()` reads `participant.isStarred`, `_chatsFilter = 'favorites'` filters correctly | No dedicated favorite contacts section in the Calls tab for one-tap calling |
| 42 | **Smart search (media and links)** | Full-text message search working (in-chat + global via `MessageService.searchMessages`). Backend GIN FTS index on `messages.content` | No media-only or link-only search tabs. Backend FTS indexes `content` column only — doesn't search `link_preview_title`, `link_preview_url`, `media_path`, or `media_type` |
| 9* | **Recording waveform** | Timer counter during recording (`_recordingDurationSec`). Backend notified via `startRecording()`/`stopRecording()` | No audio waveform visualization during recording (just a text timer) |
| 15* | **GIF rendering** | (Same as #15 above) | GIF URLs in received messages not rendered as animated `Image.network` — displayed as clickable text |

---

## Missing Features (11 items)

| # | Feature | Description | Effort | Notes |
|---|---------|-------------|--------|-------|
| 8 | **Voice auto-transcription** | On-device or server-side speech-to-text for audio messages | Medium | Whisper service (`AudioTranscriptionService`) already processes posts/music. Wire to audio messages + display transcript below voice player |
| 13 | **Live Photos / Motion Photos** | Support iOS Live Photos and Android Motion Photos in chat | Small | Requires detecting HEIC/motion metadata, playing short video loop on long-press |
| 18 | **Drag-and-drop file sharing** | Web/desktop drag file into chat to attach | Small | Flutter `DropRegion` widget. Only relevant when web/desktop targets are built |
| 21 | **Adaptive bandwidth / video quality** | Dynamic resolution and bitrate scaling based on network conditions | Medium | WebRTC has `RTCRtpSender.setParameters()` for bitrate. Add network quality callback + resolution downscaling |
| 22 | **Pinch-to-zoom in video calls** | Zoom into remote video during calls | Small | Add `ScaleGestureRecognizer` / `onScaleUpdate` to video renderer in `active_call_screen.dart`, apply `Matrix4` transform |
| 25 | **Group voice chats (audio rooms)** | Persistent audio rooms where many listen, few speak (stage model) | Large | Requires new "room" concept distinct from calls — permissions (speaker/listener), raise-hand-to-speak queue, persistent state |
| 32 | **Group spam safety** | Prevent unknown users from adding you to groups | Small | Add `who_can_add_to_groups` privacy setting (everyone/friends/nobody). Backend checks on `addParticipant()` |
| 37 | **Two-step verification** | PIN or TOTP-based 2FA for account login | Medium | Laravel Fortify 2FA is configured (web routes exist, DB columns present). Need `/api/` wrapper routes + mobile PIN entry screen |
| 38 | **Account protection toggle** | Enhanced security mode (login alerts, device management) | Medium | New settings screen showing active sessions, trusted devices, login notifications |
| 46 | **Apple Watch companion** | WatchOS app for quick replies and call notifications | Large | Requires native watchOS target, WatchConnectivity framework, companion app |
| 47 | **Third-party chat interop** | Federation with external messaging platforms | Large | Matrix/XMPP bridge or EU DMA compliance. Architectural decision needed |

---

## Recommended Implementation Order

> Prioritized by: user impact (high → low) × effort (low → high). Quick wins first.

### Sprint 1: Quick Wins (small effort, noticeable quality)

| Priority | Feature | Effort | Impact | What to Do |
|----------|---------|--------|--------|------------|
| 1 | **GIF rendering in bubbles** (#15) | Small | High | In `_MessageBubble`, detect GIF URLs (`*.gif` or Giphy domains) and render as `Image.network` with `gaplessPlayback: true` instead of plain text link |
| 2 | **Pinch-to-zoom video** (#22) | Small | Medium | Add `InteractiveViewer` or `GestureDetector` with `onScaleUpdate` wrapping the remote video `RTCVideoView` in `active_call_screen.dart` |
| 3 | **Group spam safety** (#32) | Small | High | Backend: add `who_can_add_to_groups` column to `user_profiles`, check in `addParticipant()`. Frontend: add picker in `privacy_settings_screen.dart` |
| 4 | **Recording waveform** (#9) | Small | Medium | Use `flutter_sound` `onProgress` stream's `decibels` value to drive an `AnimatedBuilder` bar visualization |

### Sprint 2: Medium Effort, High Impact

| Priority | Feature | Effort | Impact | What to Do |
|----------|---------|--------|--------|------------|
| 5 | **Voice auto-transcription** (#8) | Medium | High | Backend: after saving audio message, dispatch `TranscribeAudioMessage` job using existing Whisper service. Save transcript to `messages.transcript` column. Frontend: show collapsible transcript below voice player |
| 6 | **2FA mobile API** (#37) | Medium | High | Backend: create `Api\TwoFactorController` wrapping Fortify's enable/disable/challenge. Frontend: add 2FA setup screen in settings with QR code display and recovery codes |
| 7 | **Inline polls in chat** (#31) | Medium | High | Backend: add `poll` message type, store `poll_id` on message. Frontend: add "Poll" to attachment menu, render `PollCard` widget inside message bubble, vote inline |
| 8 | **Search media/links tabs** (#42) | Medium | Medium | Backend: extend FTS index to include `link_preview_title`. Add `?type=media` and `?type=links` filters to search endpoint. Frontend: add filter chips in search results (Text / Media / Links) |

### Sprint 3: Larger Features

| Priority | Feature | Effort | Impact | What to Do |
|----------|---------|--------|--------|------------|
| 9 | **Speaker spotlight** (#26) | Medium | Medium | Use WebRTC `getStats()` to detect loudest audio track, auto-enlarge that participant's video tile |
| 10 | **Adaptive bandwidth** (#21) | Medium | Medium | Monitor `RTCPeerConnection` stats for packet loss/jitter, dynamically adjust `maxBitrate` via `setParameters()` |
| 11 | **Favorite contacts in calls** (#27, #40) | Small | Low | Surface `isStarred` conversations as quick-dial chips at top of Calls tab |
| 12 | **Sticker packs** (#14) | Medium | Medium | Create sticker pack model (server-hosted image sets), sticker browser UI, `sticker` message type |

### Future / Platform-Dependent

| Priority | Feature | Effort | Impact | Notes |
|----------|---------|--------|--------|-------|
| 13 | **Live Photos / Motion Photos** (#13) | Small | Low | Niche — only visible to iOS/Android users who share them |
| 14 | **Document scanning** (#17) | Medium | Low | Use `google_mlkit_document_scanner` or `edge_detection` package |
| 15 | **Drag-and-drop** (#18) | Small | Low | Only relevant when web/desktop builds ship |
| 16 | **Guest chats** (#23) | Medium | Low | Requires unauthenticated WebSocket + temporary session tokens |
| 17 | **Custom member tags** (#29) | Small | Low | Add `tag` field to `conversation_participants` pivot |
| 18 | **Account protection** (#38) | Medium | Medium | Session management, trusted devices, login alerts |
| 19 | **Audio rooms** (#25) | Large | Medium | New architecture — persistent rooms, speaker queue, listener mode |
| 20 | **Apple Watch** (#46) | Large | Low | Native watchOS companion app |
| 21 | **Third-party interop** (#47) | Large | Low | Federation protocol — regulatory/architectural decision |

---

## Server Reference

- **Server:** `root@172.240.241.180`
- **Laravel app:** `/var/www/tajiri.zimasystems.com`
- **SSH:** `sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 '<command>'`
- **Backend AI assistant:** `./scripts/ask_backend.sh "your prompt"`

---

*Generated 2026-03-31 from codebase audit against docs/MESSAGES.md*
