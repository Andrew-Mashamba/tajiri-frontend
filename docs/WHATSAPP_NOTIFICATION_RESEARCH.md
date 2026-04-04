# WhatsApp Notification System: Comprehensive Research

> Research document for building a complete notification system for TAJIRI (Flutter + Laravel + FCM).

---

## 1. Architecture Overview

### High-Level Flow

```
Sender Device → WhatsApp Server → Notification Service → FCM/APNs → Recipient OS → App Processing → Display
```

### Key Components

1. **Message Server** — Receives encrypted messages via persistent XMPP/WebSocket connections
2. **Storage Service** — Temporarily stores encrypted messages for offline recipients
3. **Notification Service** — Prepares lightweight push payloads when recipient is offline
4. **FCM (Android)** / **APNs (iOS)** — OS-level push delivery infrastructure
5. **Client App** — Decrypts, stores locally, constructs rich local notifications

### Message Routing Logic

| Recipient State | Delivery Method |
|---|---|
| **Online (foreground)** | Direct delivery via persistent WebSocket/XMPP connection. Notification bypasses system tray, goes straight to the app UI. |
| **Online (background)** | App receives data push, fetches message from server, decrypts, saves to local DB, then posts a local notification with sender name + preview. |
| **Offline (app killed)** | Server queues encrypted message in Storage Service. Sends lightweight FCM/APNs push with metadata only. OS displays a generic notification. When app opens, it fetches + decrypts all queued messages. |

### Privacy-First Design

- Push payloads contain **metadata only** (sender ID, message reference, timestamp) — never the actual message content.
- The server cannot read message content due to E2E encryption.
- On iOS, a **Notification Service Extension** runs even when the app is killed, decrypts the message, and updates the notification with the actual sender name and message preview before display.
- On Android, a background receiver is woken by the OS to do equivalent processing.

---

## 2. Push Notification Technical Implementation

### FCM (Android)

**Message Type: Data-only messages**
WhatsApp primarily uses **data messages** (not notification messages) on Android. This gives the app full control over notification construction regardless of app state.

```json
{
  "to": "<device_token>",
  "data": {
    "sender_id": "12345",
    "message_id": "msg_abc123",
    "chat_id": "chat_xyz",
    "timestamp": "1711900000",
    "type": "text",
    "encrypted_preview": "<encrypted_blob>"
  },
  "priority": "high"
}
```

**Why data-only:**
- App always processes the notification (foreground, background, and killed states on Android)
- Full control over notification appearance, grouping, channels, and actions
- Can decrypt content before showing
- Can batch/coalesce multiple messages into grouped notifications

**Payload size limit:** 4 KB (FCM limit). Actual message content is fetched separately.

**Reserved keys to avoid:** `from`, `message_type`, anything starting with `google` or `gcm`.

### APNs (iOS)

**Two push types used:**

1. **Regular APNs push** (for messages):
   - Contains `mutable-content: 1` flag to trigger Notification Service Extension
   - Extension decrypts the payload, fetches message from server, updates notification title/body
   - Works even when app is killed by user

2. **VoIP push via PushKit** (for calls):
   - Bypasses all power management, guaranteed immediate delivery
   - iOS requires VoIP pushes to invoke CallKit's `reportNewIncomingCall`
   - WhatsApp has a special Apple entitlement (`com.apple.developer.pushkit.unrestricted-voip`) allowing flexibility

**Notification Service Extension responsibilities:**
- Receives push notification before display
- Decrypts encrypted payload
- Stores message in local database
- Sends delivery receipt back to server (triggers double gray check mark)
- Updates notification with decrypted sender name + message preview
- Must complete within ~30 seconds or iOS terminates it

**Potential issue:** iOS Jetsam can kill the extension for exceeding memory limits, causing delayed or generic notifications.

### "Checking for new messages" Behavior

When WhatsApp receives a silent/data push, it sometimes shows a transient "Checking for new messages..." notification while it fetches and decrypts. This disappears once the real notification is constructed.

---

## 3. Notification Categories & Types

### Complete Notification Type Inventory

| Category | Trigger | Priority | Groupable |
|---|---|---|---|
| **1:1 Message** | New message in individual chat | High | Yes (per conversation) |
| **Group Message** | New message in group chat | High (or filtered) | Yes (per group) |
| **Reaction** | Someone reacts to your message | Default | Yes (per conversation) |
| **Missed Call** | Unanswered voice/video call | High | No |
| **Incoming Call** | Active incoming call | Critical/Max | No (full-screen) |
| **Status Update** | Contact posts a new status | Low | Yes (bundled) |
| **Security Code Change** | Contact's encryption key changes | Default | No |
| **Voicemail** | Voice/video message left after missed call | High | No |
| **Channel Update** | New post in followed WhatsApp Channel | Default | Yes (per channel) |
| **Mention in Group** | @mentioned in a muted group | High | No |
| **Reply in Group** | Someone replies to your message in group | High | No |
| **Media download** | Background media download complete | Silent/Low | N/A |
| **Backup** | Chat backup in progress/complete | Low | N/A |
| **App Update** | Critical app alerts | Low | N/A |

### Who Gets Notified for Reactions

- **Only the message sender** receives a reaction notification
- Other group members can see the reaction in-chat but get no notification
- Changing a reaction sends a new notification to the sender
- Removing a reaction does NOT notify the sender
- Single global toggle to disable reaction notifications (no per-chat granularity)

---

## 4. Android Notification Channels

Android 8.0+ requires apps to declare notification channels. WhatsApp registers approximately **10 channels**:

| Channel | Purpose | Default Importance |
|---|---|---|
| **Message notifications** | Individual chat messages | High (sound + heads-up) |
| **Group notifications** | Group chat messages | High (sound + heads-up) |
| **Incoming calls** | Ringing for voice/video calls | Max (full-screen intent) |
| **Missed calls** | Missed call alerts | High |
| **Chat history backup** | Backup progress/completion | Low (silent) |
| **Critical app alerts** | Important app-level notices | High |
| **Failure notifications** | Send failures, connection errors | Default |
| **Media playback** | Audio/video playback controls | Low |
| **Sending media** | Upload progress | Low (silent) |
| **Silent notifications** | Background processing | Min (no sound, no visual) |

### Per-Channel Customization (OS-level)

Users can configure per channel:
- **Importance level**: Urgent / High / Medium / Low
- **Sound**: Custom notification sound
- **Vibration**: On/off + pattern
- **Lock screen visibility**: Show / Hide sensitive content / Don't show
- **Notification dots**: Show/hide badge dot on app icon
- **Do Not Disturb override**: Allow in DND mode
- **Pop-up / Heads-up**: Show floating notification

### Quick Channel Management

Long-press any WhatsApp notification to see its channel type and instantly toggle it off or adjust priority.

---

## 5. Notification Settings & Controls

### Global Settings (WhatsApp > Settings > Notifications)

#### Message Notifications
- **Show notifications** — Master toggle for individual chat notifications
- **Notification tone** — Select system or custom sound for messages
- **Vibrate** — Off / Default / Short / Long
- **Popup notification** — No popup / Only when screen on / Only when screen off / Always
- **Light** — LED notification color (on supported devices): None / White / Red / Yellow / Green / Cyan / Blue / Purple
- **Use high priority notifications** — Show preview at top of screen (heads-up)
- **Reaction notifications** — Toggle for message reaction alerts

#### Group Notifications
- **Show notifications** — Master toggle for group notifications
- **Notification tone** — Separate tone for group messages
- **Vibrate** — Off / Default / Short / Long
- **Popup notification** — Same options as messages
- **Light** — Same LED color options
- **Use high priority notifications** — Heads-up toggle
- **Reaction notifications** — Toggle for group reaction alerts

#### Calls
- **Ringtone** — Select ringtone for incoming WhatsApp calls
- **Vibrate** — Toggle vibration for calls

#### General
- **Conversation tones** — Play sounds for incoming/outgoing messages when in-app

### Per-Chat / Per-Group Settings

Accessible via Contact Info or Group Info > Custom Notifications:

- **Use custom notifications** — Override global settings for this chat
- **Notification tone** — Per-chat custom sound
- **Vibrate** — Per-chat vibration setting
- **Popup notification** — Per-chat popup behavior
- **Light** — Per-chat LED color
- **Call ringtone** — Custom ringtone for calls from this contact (Android only)

### Mute Settings

Available per individual chat or group:
- **8 hours** — Mute for a workday
- **1 week** — Mid-range mute
- **Always** — Indefinite mute until manually unmuted

**Critical behavior:** Even when muted, you still receive notifications for:
- **@mentions** directed at you
- **Replies** to your messages (in newer versions)

### Group-Specific Notification Filter (New)

Two options for group notification filtering:
- **All** — Notifications for every message
- **Relevant to me** — Only mentions and replies to your messages

### iOS-Specific Differences

- Cannot set custom call ringtones per contact (Android only)
- Custom tones are set via Contact Info > Wallpaper & Sound > Alert tone
- "Show Preview" toggle in WhatsApp Settings > Notifications
- "Clear Badge" toggle (beta) — auto-clears unread count when opening app

---

## 6. Notification Grouping & Bundling

### Android Grouping

WhatsApp uses Android's `NotificationCompat.Group` API:

- **Per-conversation grouping**: Messages from the same chat are grouped into a single expandable notification
- **Summary notification**: When collapsed, shows "N messages from M chats" as a summary
- **Expanded view**: Each individual message is visible when expanded
- **MessagingStyle**: Uses `NotificationCompat.MessagingStyle` to show conversation-like UI with sender avatars and message bubbles in the notification shade

**Behavior:**
- First message from a chat: standalone notification
- Second+ message from same chat: grouped under conversation
- Messages from multiple chats: grouped under app-level summary with per-chat sub-groups

### iOS Grouping

- Uses iOS `threadIdentifier` to group notifications per conversation
- iOS 12+ automatic grouping: all notifications from same thread stack together
- Expandable to see individual messages
- Summary text: "N more messages" or "N messages from Contact Name"
- 3D Touch / long-press to expand grouped notification

### Smart Coalescing

- If multiple messages arrive rapidly from the same sender, WhatsApp may coalesce them into a single updated notification rather than posting multiple
- The notification content updates in-place to show the latest message
- Unread count in the notification reflects total unread, not just the latest

---

## 7. Notification Sounds & Custom Ringtones

### Default Sounds

- **Messages**: Default WhatsApp notification sound (distinct from system default)
- **Groups**: Separate default sound (can be same or different)
- **Calls**: Default WhatsApp ringtone
- **Conversation tones**: In-app send/receive sounds

### Customization Levels

| Level | Messages | Calls |
|---|---|---|
| **Global** | WhatsApp Settings > Notifications > Tone | WhatsApp Settings > Notifications > Ringtone |
| **Per-chat** | Contact/Group Info > Custom Notifications > Tone | Contact Info > Custom Notifications > Call ringtone (Android only) |
| **OS-level** | Android Settings > Apps > WhatsApp > Notification channels | N/A |

### Sound Selection

- Android: Can choose any sound file on device, including custom `.mp3`/`.ogg` files placed in `/Notifications/` folder
- iOS: Limited to WhatsApp's built-in tone options (system integration is more restricted)

### Vibration Patterns

- Off / Default / Short / Long
- Configurable separately for messages and groups at global level
- Overridable per-chat

### LED Colors (Android, supported devices)

None / White / Red / Yellow / Green / Cyan / Blue / Purple — configurable per notification category and per chat.

---

## 8. Call Notification Handling

### Incoming Call Flow

```
Server → VoIP Push (iOS) or High-Priority FCM (Android) → OS → Full-Screen Call UI
```

### iOS Call Handling

1. **PushKit VoIP push** received by OS (guaranteed delivery even if app killed)
2. App must call `CKCallController.reportNewIncomingCall()` within a few seconds
3. **CallKit** displays native iOS call screen:
   - Full-screen UI on locked devices
   - Dynamic Island on iPhone 14 Pro+
   - Banner on unlocked devices
4. Shows caller name, contact photo
5. Accept / Decline buttons
6. If declined: caller gets "call declined" status

### Android Call Handling

1. High-priority FCM data message triggers foreground service
2. **Full-screen intent** notification shows call screen even on lock screen
3. Custom call UI with:
   - Caller name and avatar
   - Accept (green) / Decline (red) buttons
   - Audio/Video toggle
4. Ongoing call notification with duration timer, mute, speaker controls

### Missed Call Notifications

- Persistent notification showing "Missed voice/video call from [Name]"
- Tap opens chat with the contact
- Action buttons: "Call back" / "Message"
- **Voicemail feature** (new): After missed call, option to leave voice note (voice call) or video message (video call), automatically sent to chat thread

### Silence Unknown Callers

- Setting: WhatsApp > Settings > Privacy > Calls > Silence Unknown Callers
- Calls from numbers not in contacts are silenced (no ring)
- Still appear in Calls tab
- Prevents spam calls without blocking

---

## 9. Privacy & Lock Screen

### Notification Content Privacy

**Three tiers of content visibility:**

| Setting | Lock Screen Shows | Notification Shade Shows |
|---|---|---|
| **Full preview** | "John: Hey, are you free tonight?" | Full message + sender |
| **Sender only** | "John: Message" | Sender name only |
| **Hidden** | "WhatsApp: New message" | Generic text only |

### WhatsApp-Level Controls

- **Show Preview** (iOS): Toggle in WhatsApp > Settings > Notifications
- **High Priority Notifications** (Android): When off, suppresses heads-up previews that appear over other apps

### OS-Level Controls

- **Android**: Settings > Lock screen > Notifications > "Hide sensitive content" or "Don't show notifications"
- **iOS**: Settings > Notifications > WhatsApp > Show Previews: Always / When Unlocked / Never

### Chat Lock Feature

- Lock specific conversations behind biometric/passcode authentication
- Locked chats are hidden from the main chat list, moved to a "Locked Chats" folder
- Notifications from locked chats show generic "WhatsApp: New message" instead of sender name or content
- Prevents notification content leaking even with previews enabled globally

### End-to-End Encrypted Notifications

- Security code change notifications alert when a contact's encryption key changes (e.g., new phone)
- Displayed as in-chat system message: "[Contact] security code changed"
- Can enable/disable these alerts in Settings > Security

---

## 10. Badge Count & App Icon

### Badge Behavior

- Shows total count of **unread messages + missed calls** as a number on the app icon
- Updates in real-time as new messages arrive and are read
- Reading a message (in-app or via notification quick reply) decrements the count

### Platform Differences

**Android:**
- Uses launcher-specific badge APIs (Samsung, Huawei, etc. have different implementations)
- Some launchers show dots instead of numbers
- Badge count synced from local unread message database

**iOS:**
- Standard `UIApplication.applicationIconBadgeNumber`
- Set via APNs payload `badge` field or locally by the app
- **Clear Badge toggle** (beta): When enabled, badge auto-clears when opening WhatsApp, even if unread messages remain
- When disabled, badge persists showing total unread count

### In-App Badges

- Tab bar badges: Chats tab shows unread count, Calls tab shows missed call count
- Per-chat unread count displayed in chat list
- Muted chats contribute to badge count but may be styled differently (e.g., gray badge vs. green)

---

## 11. Rich Notifications (iOS)

### Media Previews

Using iOS **Notification Content Extension** and **Notification Service Extension**:

- **Images**: Thumbnail preview visible when expanding notification (3D Touch / long-press)
- **GIFs**: Animated preview in expanded notification
- **Videos**: Static thumbnail (video itself not playable in notification)
- **Audio**: Duration indicator, not playable from notification
- **Documents**: File type icon + filename

### Implementation

1. Push arrives with `mutable-content: 1`
2. **Notification Service Extension** intercepts before display
3. Extension downloads media attachment from WhatsApp servers
4. Attaches media to notification via `UNNotificationAttachment`
5. iOS renders the rich preview automatically

### Requirements

- iOS 10+ for basic rich notifications
- iOS 12+ for grouped rich notifications
- Media must be downloaded within ~30 seconds or extension is terminated
- Supports JPEG, PNG, GIF, MP4, MP3 attachments

### Automatic Download Setting

If user has disabled auto-download for media, the notification shows a "Download" button to manually fetch the media preview.

---

## 12. Notification Actions (Quick Reply, Mark as Read)

### Available Actions

| Platform | Action | Description |
|---|---|---|
| Android + iOS | **Reply** | Inline text input to reply without opening app |
| Android + iOS | **Mark as Read** | Dismisses notification and marks conversation as read |
| Android | **Mute** | Quick-mute the conversation from notification |
| iOS | **View** | Opens the specific chat |
| Android | **Archive** | Archive the conversation |

### Quick Reply Behavior

- Tap "Reply" on notification to get inline text input
- Type and send without opening WhatsApp
- **Does not** update "Last Seen" or show "Online" status
- **Does** send read receipts (blue ticks) for the conversation
- Supports text replies only (no media from notification)

### Mark as Read

- Single tap clears the notification
- Sends read receipt to sender (blue ticks appear)
- Decrements badge count
- Does not open the app

### Android Notification Actions

Configured via `NotificationCompat.Action`:
```
action.addRemoteInput(remoteInput)  // For inline reply
action.setSemanticAction(SEMANTIC_ACTION_REPLY)
action.setSemanticAction(SEMANTIC_ACTION_MARK_AS_READ)
```

### iOS Notification Actions

Configured via `UNNotificationCategory` with `UNTextInputNotificationAction`:
- Reply action with text input
- Read action (custom)
- Actions appear on long-press or swipe-left > View

---

## 13. Delivery Receipts via Notifications

### Check Mark System

| Visual | State | Trigger |
|---|---|---|
| Single gray tick | **Sent** | Message reached WhatsApp server |
| Double gray ticks | **Delivered** | Message reached recipient's device (notification service extension sent ack) |
| Double blue ticks | **Read** | Recipient opened the chat or read via notification |

### Technical Flow for Delivery Receipt

1. Sender sends message → Server stores and returns single gray tick
2. Recipient's Notification Service Extension receives push, decrypts message, sends **delivery acknowledgment** back to server → Server forwards to sender → Double gray ticks
3. Recipient opens chat or taps "Mark as Read" → App sends **read acknowledgment** → Server forwards → Double blue ticks

### Privacy Control

- **Read receipts toggle**: Settings > Privacy > Read Receipts
- When off: sender never sees blue ticks (stays at double gray)
- **Exception**: Group chats always show read receipts regardless of individual setting
- **Exception**: Voice messages always show blue ticks when played

---

## 14. Edge Cases & Smart Behaviors

### Multi-Device Handling

- WhatsApp supports linked devices (up to 4)
- Reading a message on any linked device marks it as read on all devices
- Notifications are dismissed on other devices when read on one
- Push tokens registered per device; server sends to all registered tokens

### Offline Message Queuing

- Server queues messages for offline recipients for up to **30 days**
- Multiple queued messages delivered as a batch when recipient comes online
- Notifications are grouped/coalesced for batch delivery
- Older messages may arrive with historical timestamps

### Network Transitions

- When switching from WiFi to cellular (or vice versa), persistent connection drops momentarily
- FCM/APNs handle delivery during connection gaps
- App reconciles message state on reconnection

### Duplicate Notification Prevention

- Each message has a unique ID
- App deduplicates before posting notification
- If notification service extension already posted the notification, app update in background doesn't re-notify

### Battery Optimization Handling

- Android: WhatsApp requests exclusion from battery optimization (Doze mode)
- Guides users to disable battery optimization for reliable notification delivery
- Samsung, Xiaomi, Huawei have aggressive battery management that can kill background services
- WhatsApp actively fights manufacturer-specific battery killers

### Notification Ordering

- Notifications arrive in chronological order when possible
- If server queues multiple messages, they're delivered in order
- Network latency can cause out-of-order delivery; app reorders based on timestamp

### Focus Mode / Do Not Disturb Integration

- WhatsApp respects OS-level DND/Focus modes
- Individual notification channels can be set to override DND
- Calls can be configured to break through DND (critical/max priority)
- iOS Focus modes can explicitly allow/block WhatsApp

### Conversation Tones vs. Push Notifications

- When app is in foreground and in a specific chat: only in-app sound plays, no system notification
- When app is in foreground but in a different chat: system notification appears
- When app is in foreground on chat list: system notification appears for new messages
- Conversation tones (send/receive sounds) are separate from notification sounds

---

## 15. Implementation Recommendations for TAJIRI

Based on WhatsApp's approach, here is the recommended implementation for TAJIRI's Flutter + Laravel + FCM stack:

### Backend (Laravel)

1. **Always send FCM data-only messages** (not notification messages) for maximum control:
   ```json
   {
     "to": "<token>",
     "data": {
       "type": "message|call|reaction|mention|status",
       "sender_id": "123",
       "sender_name": "John",
       "chat_id": "456",
       "message_id": "789",
       "chat_type": "individual|group",
       "preview": "Hey, are you...",
       "timestamp": "1711900000",
       "media_type": "text|image|video|audio|document",
       "media_thumbnail_url": "https://..."
     },
     "android": {
       "priority": "high"
     },
     "apns": {
       "headers": { "apns-priority": "10" },
       "payload": {
         "aps": {
           "mutable-content": 1,
           "alert": { "title": "John", "body": "New message" },
           "badge": 5,
           "sound": "default",
           "thread-id": "chat_456"
         }
       }
     }
   }
   ```

2. **Register notification channels** for Android:
   - `messages` (high priority)
   - `groups` (high priority)
   - `calls` (max priority, full-screen intent)
   - `missed_calls` (high priority)
   - `reactions` (default priority)
   - `status_updates` (low priority)
   - `system` (default priority)
   - `media_upload` (low/silent)

3. **Implement per-user notification preferences** table:
   ```
   notification_preferences:
     user_id, chat_id (nullable),
     muted_until (timestamp),
     custom_tone (string),
     custom_vibration (string),
     show_preview (boolean),
     notify_mentions_only (boolean)
   ```

4. **Server-side filtering**: Before sending push, check:
   - Is recipient muted for this chat?
   - Is it a group with "mentions only" and this isn't a mention?
   - Has the user disabled reaction notifications?
   - Is the sender blocked?

### Frontend (Flutter)

1. **Use `firebase_messaging` for FCM** with background message handler
2. **Use `flutter_local_notifications`** to construct rich notifications locally after processing FCM data
3. **Implement notification channels** via `flutter_local_notifications` Android config
4. **Group notifications** using `groupKey` parameter per conversation
5. **Quick reply actions** via `flutter_local_notifications` action buttons with `TextInput`
6. **Badge management** via `flutter_app_badger` package
7. **For iOS calls**: Use `flutter_callkit_incoming` or `callkeep` for native call UI
8. **For Android calls**: Use full-screen intent notification via `flutter_local_notifications`

### Database Tables Needed

```sql
-- Store device tokens per user per device
device_tokens (user_id, token, platform, device_id, created_at, updated_at)

-- Global notification preferences
notification_settings (user_id, messages_enabled, groups_enabled, calls_enabled,
  reactions_enabled, message_tone, group_tone, call_ringtone,
  message_vibrate, group_vibrate, show_preview, silence_unknown_callers)

-- Per-chat overrides
chat_notification_overrides (user_id, chat_id, muted_until, custom_tone,
  custom_vibrate, custom_led_color, mentions_only, custom_call_ringtone)

-- Notification delivery tracking
notification_log (id, user_id, type, payload, sent_at, delivered_at, read_at,
  fcm_message_id, status)
```

---

## Sources

- [Push Notifications in WhatsApp: Architecture, Flow, and Behavior](https://csetutorials.com/push-notifications-whatsapp-architecture-flow.html)
- [How WhatsApp Notifications Work Internally — A System Design Perspective](https://learnersstore.com/2025/10/18/how-whatsapp-notifications-work-internally-a-system-design-perspective/)
- [WhatsApp System Design Interview](https://newsletter.systemdesign.one/p/whatsapp-system-design)
- [WhatsApp Notification Channels on Android Oreo](https://www.bestusefultips.com/whatsapp-notification-channel-on-android-oreo-use/)
- [WhatsApp Adds Notification Channels on Android Oreo 8.0](https://www.androidpolice.com/2018/01/19/whatsapp-adds-notification-channels-android-oreo-8-0-can-now-choose-notification-type/)
- [How to Customize WhatsApp Notifications](https://beebom.com/customize-whatsapp-notification/)
- [PSA: Customize WhatsApp Notification Sounds for Specific Chats](https://www.howtogeek.com/you-can-customize-whatsapp-notification-sounds-for-specific-chats/)
- [How to manage your notifications — WhatsApp Help Center](https://faq.whatsapp.com/797069521522888)
- [How to mute or unmute chat notifications — WhatsApp Help Center](https://faq.whatsapp.com/694350718331007/?locale=en_US)
- [How to Enable or Disable Reaction Notifications on WhatsApp](https://www.guidingtech.com/how-to-disable-whatsapp-message-reaction-notifications/)
- [21 Things to Know About WhatsApp Message Reactions](https://techwiser.com/things-to-know-about-whatsapp-message-reactions/)
- [WhatsApp and VoIP push notifications on iOS 13 — Apple Developer Forums](https://developer.apple.com/forums/thread/130650)
- [Using PushKit Notification — How To Show an Incoming Call](https://getstream.io/blog/pushkit-for-calls/)
- [How to Hide WhatsApp Chat Content From Notification](https://www.mapsofindia.com/my-india/social-media/how-to-hide-whatsapp-chat-content-from-notification)
- [2 WhatsApp Privacy Settings You Should Enable](https://www.techadvisor.com/article/745464/2-whatsapp-privacy-settings-you-should-enable-right-now.html)
- [WhatsApp Rich Notification Media Previews iOS](https://www.idownloadblog.com/2018/07/24/whatsapp-notification-media-previews/)
- [WhatsApp Gains Image and GIF Previews in Notifications](https://www.idownloadblog.com/2018/09/04/whatsapp-notifications-preview/)
- [How to quick reply on iPhone — WhatsApp Help Center](https://faq.whatsapp.com/897625648199642)
- [WhatsApp Auto-Clear Badge Feature](https://www.idownloadblog.com/2025/02/18/whatsapp-unread-message-count-automatic-clear-test/)
- [WhatsApp Granular Notification Badge Controls](https://www.androidpolice.com/whatsapps-home-screen-notifications-easier-to-manage/)
- [New Privacy Features: Silence Unknown Callers — WhatsApp Blog](https://blog.whatsapp.com/new-privacy-features-silence-unknown-callers-and-privacy-checkup)
- [WhatsApp Voicemail Feature for Missed Calls](https://www.infohubfacts.com/whatsapp-voicemail-missed-calls-feature-2025-update)
- [About End-to-End Encrypted Notifications — WhatsApp Help Center](https://faq.whatsapp.com/1460487824884467)
- [WhatsApp New Group Notification Settings](https://www.neowin.net/news/whatsapp-is-getting-new-notification-settings-for-group-chats/)
- [How to Group Android Notifications Like WhatsApp](https://www.tutorialspoint.com/how-to-group-android-notifications-like-whatsapp)
- [How to Manage Notification Grouping on iPhone](https://www.howtogeek.com/805354/how-to-manage-notification-grouping-on-iphone/)
- [How to Silence Unknown Callers — WhatsApp Help Center](https://faq.whatsapp.com/1238612517047244)
- [Understanding WhatsApp Check Marks](https://www.pandasecurity.com/en/mediacenter/whatsapp-check-marks/)
- [How Push Notification Delivery Works Internally: APNs and FCM Deep Dive](https://blog.clix.so/how-push-notification-delivery-works-internally/)
