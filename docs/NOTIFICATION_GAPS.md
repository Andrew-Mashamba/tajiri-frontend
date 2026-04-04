# TAJIRI Notifications — WhatsApp Reference & Gap Analysis

> Based on WhatsApp notification research + TAJIRI codebase audit. Generated 2026-03-31.

---

## How WhatsApp Does It

### Architecture

Privacy-first. Push payloads contain metadata only (sender ID, conversation ID, type) — never message content. The app decrypts and assembles the notification locally.

### 15 Notification Types

1. 1:1 messages
2. Group messages
3. Reactions
4. Incoming calls
5. Missed calls
6. Voicemail
7. Status updates
8. Mentions
9. Channel updates
10. Security alerts
11. Payment
12. Business
13. Live location
14. Sticker/GIF
15. Broadcast

### Platform Implementation

- **Android:** FCM data-only messages (app controls everything), 10 notification channels:
  1. Messages
  2. Groups
  3. Incoming calls
  4. Missed calls
  5. Backup
  6. Critical alerts
  7. Failures
  8. Media playback
  9. Sending media
  10. Silent

- **iOS:** APNs with `mutable-content` + Notification Service Extension for decryption/rich media, VoIP/PushKit for calls with CallKit + Dynamic Island

### Grouping

Per-conversation bundling via `MessagingStyle` (Android) / `threadIdentifier` (iOS). Summary notification: "3 conversations, 12 messages."

### Actions

Quick Reply (inline text without opening app), Mark as Read, Mute, Archive — all from the notification itself.

### Privacy Controls

3 tiers of lock screen visibility. Chat Lock hides notifications for locked chats entirely.

### Settings

Global tone/vibration/popup/LED + per-chat custom overrides + mute durations (8h/1w/always) + group filter "All vs Relevant to me."

### Rich Notifications

Image/GIF/video thumbnails via Notification Service Extension (iOS). Custom sounds per chat.

### Badge Count

Unread messages + missed calls. Updated in real-time.

---

## Critical Gaps

| # | Gap | Impact |
|---|-----|--------|
| 1 | `NotificationsScreen` is an empty stub | Users see "No notifications" always |
| 2 | No notification history API | Backend writes to `notifications` table but never reads |
| 3 | No read/unread state | `read_at` column exists but never populated |
| 4 | No notification preferences UI | Users can't control what they receive |
| 5 | No quiet hours / DND | No time-based muting |
| 6 | No per-chat notification customization | No custom tone/vibration per conversation |
| 7 | No notification grouping/bundling | Each push is standalone |
| 8 | No quick reply from notification | Must open app to respond |
| 9 | No badge count management | No unread badge on app icon |
| 10 | No rich notifications (iOS) | No image/media previews in notifications |
| 11 | No Android notification channels | All use default `tajiri_default` channel |
| 12 | `flutter_local_notifications` installed but unused | Package exists in pubspec but never initialized |
| 13 | No rate limiting enforcement | `max_per_day` field exists but unchecked |

---

## Recommended Implementation Order

> Prioritized by: user impact (high → low) x effort (low → high). Quick wins first.

### Sprint 1: Foundation (must-have infrastructure)

| Priority | Gap | Effort | Impact | What to Do |
|----------|-----|--------|--------|------------|
| 1 | **Notification history API** (#2) | Small | High | Backend: add `GET /api/notifications` endpoint reading existing `notifications` table with pagination. Return `id, type, data, title, body, read_at, created_at` |
| 2 | **NotificationsScreen** (#1) | Medium | High | Frontend: replace stub with paginated list. Group by date (Today/Yesterday/Earlier). Each tile shows icon by type, title, body, timestamp, unread dot. Pull-to-refresh. Tap routes to relevant screen |
| 3 | **Read/unread state** (#3) | Small | High | Backend: add `POST /api/notifications/mark-read` (single) and `POST /api/notifications/mark-all-read`. Frontend: mark as read on tap, "Mark all read" button in appbar |
| 4 | **Badge count** (#9) | Small | High | Backend: include `unread_count` in notification list response. Frontend: show badge on notifications tab icon in `HomeScreen`. Use `flutter_app_badger` for app icon badge |

### Sprint 2: Notification Quality

| Priority | Gap | Effort | Impact | What to Do |
|----------|-----|--------|--------|------------|
| 5 | **Android notification channels** (#11) | Small | High | Initialize `flutter_local_notifications` with 6 channels: `messages` (high), `groups` (high), `calls` (max/full-screen), `missed_calls` (high), `social` (default), `system` (low). Route FCM payloads to correct channel by type |
| 6 | **Initialize flutter_local_notifications** (#12) | Small | High | Set up `FlutterLocalNotificationsPlugin` in `FcmService.init()`. Use it to show foreground notifications with proper channel, sound, and icon. Currently foreground messages are silent |
| 7 | **Notification grouping** (#7) | Medium | Medium | Android: use `groupKey` per conversation ID in local notification. Set summary notification with `setAsGroupSummary`. iOS: set `threadIdentifier` to conversation ID |
| 8 | **Quick reply from notification** (#8) | Medium | High | Android: add `AndroidNotificationAction` with `TextInput` for message notifications. On reply, call `MessageService.sendMessage()` directly without opening app. iOS: add `UNTextInputNotificationAction` in category |

### Sprint 3: User Controls

| Priority | Gap | Effort | Impact | What to Do |
|----------|-----|--------|--------|------------|
| 9 | **Notification preferences UI** (#4) | Medium | Medium | Backend: add `notification_preferences` table (`user_id, type, enabled, sound, vibrate`). Frontend: new `NotificationSettingsScreen` under Settings with toggles per notification type (Messages, Groups, Calls, Reactions, Mentions, Social, System) |
| 10 | **Per-chat notification customization** (#6) | Medium | Medium | Backend: add `custom_tone, custom_vibrate, custom_light` columns to `conversation_participants`. Frontend: add "Custom notifications" option in chat info/group info with tone picker, vibration toggle |
| 11 | **Quiet hours / DND** (#5) | Medium | Medium | Backend: add `quiet_hours_start, quiet_hours_end, quiet_hours_enabled` to `notification_preferences`. Frontend: time range picker in notification settings. Backend: check quiet hours before sending push |
| 12 | **Rate limiting enforcement** (#13) | Small | Low | Backend: in `FcmNotificationService.sendToUser()`, query `notifications` table count for user+type in last 24h. Skip if >= `max_per_day` from `NotificationTemplate` |

### Sprint 4: Rich Experience

| Priority | Gap | Effort | Impact | What to Do |
|----------|-----|--------|--------|------------|
| 13 | **Rich notifications (iOS)** (#10) | Large | Medium | Create iOS Notification Service Extension target. Download and attach image/video thumbnail when notification payload includes `media_url`. Requires Xcode native target setup, shared keychain for auth token, `UNNotificationAttachment` |

---

## Server Reference

- **Server:** `root@172.240.241.180`
- **Laravel app:** `/var/www/tajiri.zimasystems.com`
- **SSH:** `sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 '<command>'`
- **Backend AI assistant:** `./scripts/ask_backend.sh "your prompt"`

---

*Generated 2026-03-31 from WhatsApp notification research + TAJIRI codebase audit*
