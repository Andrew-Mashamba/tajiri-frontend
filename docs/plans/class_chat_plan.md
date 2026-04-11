# Class Chat / Gumzo la Darasa — Implementation Plan

## Overview
Organized class communication replacing WhatsApp chaos. Channels per subject, threaded replies, pinned messages, announcements (CR/lecturer only), polls, Q&A board with answered/unanswered tracking, file sharing without compression, and role-based permissions. Auto-created when a class is formed in My Class module.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/class_chat/
├── class_chat_module.dart
├── models/
│   ├── channel.dart
│   ├── chat_message.dart
│   ├── poll.dart
│   └── question.dart
├── services/
│   └── class_chat_service.dart      — AuthenticatedDio.instance
├── pages/
│   ├── class_chat_home_page.dart
│   ├── channel_view_page.dart
│   ├── announcements_page.dart
│   ├── pinned_messages_page.dart
│   ├── qa_board_page.dart
│   ├── media_gallery_page.dart
│   ├── poll_page.dart
│   ├── search_page.dart
│   └── channel_settings_page.dart
└── widgets/
    ├── channel_tile.dart
    ├── message_bubble.dart
    ├── thread_view.dart
    ├── poll_card.dart
    ├── question_card.dart
    ├── mention_chip.dart
    └── formatting_toolbar.dart
```

### Data Models
```dart
class Channel {
  final int id, classId;
  final String name, type;   // general, announcements, subject
  final int unreadCount;
  final ChatMessage? lastMessage;
  factory Channel.fromJson(Map<String, dynamic> j) => Channel(
    id: _parseInt(j['id']),
    classId: _parseInt(j['class_id']),
    name: j['name'] ?? '',
    type: j['type'] ?? 'general',
    unreadCount: _parseInt(j['unread_count']),
  );
}

class ChatMessage {
  int id, channelId, senderId;
  String body, senderName;
  String? parentId;           // for threads
  bool pinned, isQuestion, isAnswered;
  List<String> attachmentUrls;
  DateTime createdAt;
}

class Poll { int id; String question; List<PollOption> options; DateTime? expiresAt; }
class PollOption { int id; String text; int voteCount; bool userVoted; }
class Question { int id; String body; String senderName; bool answered; int replyCount; }
```

### Service Layer
```dart
class ClassChatService {
  static Future<List<Channel>> getChannels(String token, int classId);         // GET /api/classes/{id}/channels
  static Future<Channel> createChannel(String token, int classId, Map body);   // POST /api/classes/{id}/channels
  static Future<List<ChatMessage>> getMessages(String token, int channelId, {int? before}); // GET /api/channels/{id}/messages
  static Future<ChatMessage> sendMessage(String token, int channelId, Map b);  // POST /api/channels/{id}/messages
  static Future<void> pinMessage(String token, int msgId);                     // POST /api/messages/{id}/pin
  static Future<void> markAsQuestion(String token, int msgId);                 // POST /api/messages/{id}/mark-question
  static Future<void> markAnswered(String token, int msgId);                   // POST /api/messages/{id}/mark-answered
  static Future<Poll> createPoll(String token, int channelId, Map body);       // POST /api/channels/{id}/polls
  static Future<void> votePoll(String token, int pollId, int optionId);        // POST /api/polls/{id}/vote
  static Future<List<ChatMessage>> search(String token, int classId, String q); // GET /api/classes/{id}/search?q=
}
```

### Pages & Widgets
- **ClassChatHomePage**: list of channels with unread counts, last message preview, FAB to create channel
- **ChannelViewPage**: message thread with input bar, attachment, formatting tools, @mention autocomplete
- **AnnouncementsPage**: chronological official announcements with read status indicators
- **QaBoardPage**: filtered view of questions with answered/unanswered tabs
- **PollPage**: create poll with options, view live results with percentages
- **MediaGalleryPage**: grid of all shared files, photos, documents in channel

---

## 2. UI Design
- Monochromatic: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- 48dp touch targets, maxLines + ellipsis, _rounded icons
- Channel list uses subtle left-border color per type (announcements = accent, Q&A = muted)
- Message bubbles: sender-aligned, threaded replies indented

### Main Screen Wireframe
```
┌──────────────────────────────┐
│  CS 201 Chat           [🔍]  │
├──────────────────────────────┤
│ # announcements         ● 2  │
│ # general                    │
│ # cs201-data-structures  ● 5 │
│ # cs202-algorithms           │
│ # q-and-a               ● 1  │
├──────────────────────────────┤
│ PINNED                       │
│ ┌──────────────────────────┐ │
│ │ 📌 Exam: June 15, NB101 │ │
│ └──────────────────────────┘ │
│                              │
│ POLLS                        │
│ ┌──────────────────────────┐ │
│ │ Meeting time? (12 votes) │ │
│ └──────────────────────────┘ │
└──────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE channels(id INTEGER PRIMARY KEY, class_id INTEGER, name TEXT, type TEXT, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_channels_class ON channels(class_id);

CREATE TABLE chat_messages(id INTEGER PRIMARY KEY, channel_id INTEGER, sender_id INTEGER, body TEXT, pinned INTEGER, is_question INTEGER, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_msgs_channel ON chat_messages(channel_id);

CREATE TABLE polls(id INTEGER PRIMARY KEY, channel_id INTEGER, json_data TEXT, synced_at TEXT);
```
- SQLite first, API background refresh (stale-while-revalidate)
- Offline read: YES — messages, channels, polls cached
- Offline write: pending_queue for messages (auto-send on reconnect)

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE class_channels(
  id SERIAL PRIMARY KEY, classroom_id INT REFERENCES classrooms(id),
  name VARCHAR(100), type VARCHAR(30) DEFAULT 'general',
  description TEXT, created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE channel_messages(
  id SERIAL PRIMARY KEY, channel_id INT REFERENCES class_channels(id),
  sender_id INT REFERENCES users(id), body TEXT,
  parent_message_id INT REFERENCES channel_messages(id),
  pinned BOOLEAN DEFAULT FALSE, is_question BOOLEAN DEFAULT FALSE,
  is_answered BOOLEAN DEFAULT FALSE, created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE message_attachments(
  id SERIAL PRIMARY KEY, message_id INT REFERENCES channel_messages(id),
  file_url TEXT, file_type VARCHAR(50), file_size BIGINT
);
CREATE TABLE channel_polls(
  id SERIAL PRIMARY KEY, channel_id INT REFERENCES class_channels(id),
  creator_id INT REFERENCES users(id), question TEXT,
  expires_at TIMESTAMP, created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE poll_options(
  id SERIAL PRIMARY KEY, poll_id INT REFERENCES channel_polls(id), text VARCHAR(255)
);
CREATE TABLE poll_votes(
  id SERIAL PRIMARY KEY, option_id INT REFERENCES poll_options(id),
  user_id INT REFERENCES users(id), UNIQUE(option_id, user_id)
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/classes/{id}/channels | List channels | Bearer |
| POST | /api/classes/{id}/channels | Create channel | Bearer (CR) |
| GET | /api/channels/{id}/messages | Messages (paginated) | Bearer |
| POST | /api/channels/{id}/messages | Send message | Bearer |
| POST | /api/messages/{id}/pin | Pin/unpin | Bearer (CR/Lecturer) |
| POST | /api/messages/{id}/mark-question | Tag as question | Bearer |
| POST | /api/messages/{id}/mark-answered | Mark answered | Bearer (CR/Lecturer) |
| POST | /api/channels/{id}/polls | Create poll | Bearer (CR) |
| POST | /api/polls/{id}/vote | Vote on poll | Bearer |
| GET | /api/classes/{id}/search | Search messages | Bearer |

### Controller
`app/Http/Controllers/Api/ClassChatController.php`

---

## 5. Integration Wiring
- MessageService — class chat extends TAJIRI messaging infrastructure
- GroupService — auto-created when class is formed; membership synced with roster
- NotificationService + FCM — announcement push, @mention alerts, urgent broadcasts
- LiveUpdateService — real-time message delivery and read receipts
- class_notes module — files shared in chat "promoted" to notes repository
- assignments module — assignment discussions link to dedicated threads
- newton module — @newton mention triggers AI response in conversation
- study_groups module — spin off study group conversations from chat

---

## 6. Implementation Phases

### Phase 1 — Core Messaging (Week 1-2)
- [ ] Channel and ChatMessage models, service, SQLite cache
- [ ] Channel list page with unread counts
- [ ] Channel message view with send/receive
- [ ] Auto-create channels on class creation (general, announcements)

### Phase 2 — Organization (Week 3)
- [ ] Threaded replies (parent message linking)
- [ ] Pin messages (CR/lecturer permission)
- [ ] @mention support with autocomplete
- [ ] Message search across channels

### Phase 3 — Q&A & Polls (Week 4)
- [ ] Question tagging and answered/unanswered tracking
- [ ] Q&A board filtered view
- [ ] Poll creation and voting with live results
- [ ] Media gallery page

### Phase 4 — Advanced (Week 5)
- [ ] File sharing without compression (original quality)
- [ ] Voice messages with playback speed control
- [ ] Scheduled messages for CRs
- [ ] Read receipts for announcements
- [ ] Offline message queue

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| TAJIRI MessageService (internal) | TAJIRI | In-app messaging infrastructure | N/A | Already built. Class chat leverages existing TAJIRI chat with class-specific group channels. **No external API needed.** |
| TAJIRI LiveUpdateService (internal) | TAJIRI | Real-time message delivery via Firebase Firestore | N/A | Already built. Provides real-time message notifications and read receipts. |
| TAJIRI GroupService (internal) | TAJIRI | Group management, membership sync with class roster | N/A | Already built. Auto-created when class is formed; membership synced. |
| Stream Chat API | Stream | Scalable chat with moderation, threads | Free: 10K MAU; Paid from $399/mo | Flutter SDK: `stream_chat_flutter`. Only needed if TAJIRI messaging can't scale. |

**Recommendation:** Use TAJIRI's existing messaging system with class-specific group channels. No external API needed for core functionality.

### Integration Priority
1. **Immediate** -- TAJIRI MessageService + GroupService + LiveUpdateService (all internal, already built)
2. **Short-term** -- None required; existing infrastructure covers all class chat needs
3. **Partnership** -- Stream/CometChat only if TAJIRI messaging infrastructure needs replacement at scale
