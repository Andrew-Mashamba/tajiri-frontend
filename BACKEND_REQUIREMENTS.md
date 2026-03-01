# 🎖️ TAJIRI Livestreaming - Laravel Backend Requirements

## Military-Grade Livestreaming System - Backend Specification

This document outlines the complete backend infrastructure required to support TAJIRI's top-tier livestreaming platform with smooth real-time features.

> **📅 Last Updated:** 2026-01-28
> **✨ Latest Changes:**
> - Added detailed **Plain WebSocket implementation** (Section 3, Option 1) with event formats and Laravel code examples
> - Documented WebSocket connection handling, broadcasting, and viewer count tracking
> - Added backend pseudocode for real-time comment/gift broadcasting
> - Kept Pusher/Laravel Echo option as alternative (Section 3, Option 2)

---

## Table of Contents

1. [Database Schema](#1-database-schema)
2. [API Endpoints](#2-api-endpoints)
3. [WebSocket/Real-Time Events](#3-websocketreal-time-events)
4. [Status Transition Logic](#4-status-transition-logic)
5. [Notification System](#5-notification-system)
6. [Streaming Infrastructure](#6-streaming-infrastructure)
7. [Analytics & Tracking](#7-analytics--tracking)
8. [Security & Performance](#8-security--performance)

---

## 1. Database Schema

### Table: `live_streams`

```sql
CREATE TABLE live_streams (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    stream_key VARCHAR(255) UNIQUE NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NULL,
    thumbnail_path VARCHAR(255) NULL,
    category VARCHAR(100) NULL,
    tags JSON NULL,

    -- Status & Timing
    status ENUM('scheduled', 'pre_live', 'live', 'ending', 'ended', 'cancelled') DEFAULT 'scheduled',
    scheduled_at TIMESTAMP NULL,
    pre_live_started_at TIMESTAMP NULL,
    live_started_at TIMESTAMP NULL,
    ended_at TIMESTAMP NULL,
    duration INT UNSIGNED NULL COMMENT 'Duration in seconds',

    -- Settings
    privacy ENUM('public', 'friends', 'private') DEFAULT 'public',
    is_recorded BOOLEAN DEFAULT TRUE,
    allow_comments BOOLEAN DEFAULT TRUE,
    allow_gifts BOOLEAN DEFAULT TRUE,
    allow_co_hosts BOOLEAN DEFAULT FALSE,

    -- URLs
    stream_url VARCHAR(255) NULL COMMENT 'RTMP ingest URL',
    playback_url VARCHAR(255) NULL COMMENT 'HLS/DASH playback URL',
    recording_path VARCHAR(255) NULL,

    -- Analytics (cached/real-time)
    current_viewers INT UNSIGNED DEFAULT 0,
    peak_viewers INT UNSIGNED DEFAULT 0,
    total_viewers INT UNSIGNED DEFAULT 0,
    unique_viewers INT UNSIGNED DEFAULT 0,
    likes_count INT UNSIGNED DEFAULT 0,
    comments_count INT UNSIGNED DEFAULT 0,
    shares_count INT UNSIGNED DEFAULT 0,
    gifts_count INT UNSIGNED DEFAULT 0,
    gifts_value DECIMAL(10, 2) DEFAULT 0.00,
    reaction_counts JSON NULL COMMENT '{"like": 10, "love": 5, "fire": 3}',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_scheduled_at (scheduled_at),
    INDEX idx_live_started_at (live_started_at),

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Table: `stream_co_hosts`

```sql
CREATE TABLE stream_co_hosts (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    stream_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    is_active BOOLEAN DEFAULT FALSE,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    left_at TIMESTAMP NULL,

    FOREIGN KEY (stream_id) REFERENCES live_streams(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,

    UNIQUE KEY unique_stream_user (stream_id, user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Table: `stream_viewers`

```sql
CREATE TABLE stream_viewers (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    stream_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NULL COMMENT 'NULL for anonymous',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    left_at TIMESTAMP NULL,
    watch_time INT UNSIGNED DEFAULT 0 COMMENT 'Seconds watched',
    is_currently_watching BOOLEAN DEFAULT TRUE,

    INDEX idx_stream_id (stream_id),
    INDEX idx_user_id (user_id),
    INDEX idx_currently_watching (stream_id, is_currently_watching),

    FOREIGN KEY (stream_id) REFERENCES live_streams(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Table: `stream_comments`

```sql
CREATE TABLE stream_comments (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    stream_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    message TEXT NOT NULL,
    is_pinned BOOLEAN DEFAULT FALSE,
    is_highlighted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_stream_id (stream_id),
    INDEX idx_created_at (stream_id, created_at),

    FOREIGN KEY (stream_id) REFERENCES live_streams(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Table: `stream_gifts`

```sql
CREATE TABLE stream_gifts (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    stream_id BIGINT UNSIGNED NOT NULL,
    sender_id BIGINT UNSIGNED NOT NULL,
    gift_id INT UNSIGNED NOT NULL,
    quantity INT UNSIGNED DEFAULT 1,
    total_value DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_stream_id (stream_id),

    FOREIGN KEY (stream_id) REFERENCES live_streams(id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (gift_id) REFERENCES virtual_gifts(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Table: `virtual_gifts`

```sql
CREATE TABLE virtual_gifts (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    icon_path VARCHAR(255) NOT NULL,
    animation VARCHAR(255) NULL,
    value DECIMAL(10, 2) NOT NULL COMMENT 'Price in TZS',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Table: `stream_notifications`

```sql
CREATE TABLE stream_notifications (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    stream_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    type ENUM('scheduled', 'starting_soon', 'now_live', 'ended') NOT NULL,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_stream_user (stream_id, user_id),

    FOREIGN KEY (stream_id) REFERENCES live_streams(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Table: `stream_analytics`

```sql
CREATE TABLE stream_analytics (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    stream_id BIGINT UNSIGNED NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    viewers_count INT UNSIGNED DEFAULT 0,
    engagement_rate DECIMAL(5, 2) DEFAULT 0.00,
    data JSON NULL COMMENT 'Additional metrics',

    INDEX idx_stream_timestamp (stream_id, timestamp),

    FOREIGN KEY (stream_id) REFERENCES live_streams(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 2. API Endpoints

### 2.1 Stream Management

#### POST `/api/streams`
Create a new livestream

**Request:**
```json
{
  "title": "My First Stream",
  "description": "Learning to stream",
  "category": "Elimu",
  "tags": ["tutorial", "beginner"],
  "privacy": "public",
  "is_recorded": true,
  "allow_comments": true,
  "allow_gifts": true,
  "scheduled_at": "2026-01-28T20:00:00Z",
  "thumbnail": "base64_or_file"
}
```

**Response:**
```json
{
  "success": true,
  "stream": {
    "id": 123,
    "stream_key": "unique_stream_key_abc123",
    "user_id": 456,
    "title": "My First Stream",
    "status": "scheduled",
    "stream_url": "rtmp://zima-uat.site/live/unique_stream_key_abc123",
    "scheduled_at": "2026-01-28T20:00:00Z",
    "created_at": "2026-01-28T10:00:00Z"
  }
}
```

#### PATCH `/api/streams/{id}/status`
Change stream status (status transitions)

**Request:**
```json
{
  "status": "pre_live"  // scheduled → pre_live → live → ending → ended
}
```

**Response:**
```json
{
  "success": true,
  "stream": { /* updated stream object */ },
  "message": "Stream moved to pre-live status. Notifications sent."
}
```

**Status Transition Rules:**
- `scheduled` → `pre_live` (15-30 min before scheduled_at)
- `pre_live` → `live` (streamer clicks "Go Live")
- `live` → `ending` (streamer clicks "End Stream")
- `ending` → `ended` (after 5 seconds outro)
- Any status → `cancelled` (cancel stream)

#### POST `/api/streams/{id}/start`
Start streaming (pre_live → live)

**Response:**
```json
{
  "success": true,
  "stream": { /* updated stream with playback_url */ },
  "playback_url": "https://zima-uat.site:8003/live/stream_id_123.m3u8"
}
```

#### POST `/api/streams/{id}/end`
End streaming (live → ending → ended)

**Response:**
```json
{
  "success": true,
  "stream": { /* ended stream with analytics */ },
  "analytics": {
    "total_viewers": 1250,
    "peak_viewers": 450,
    "average_watch_time": 320,
    "total_gifts": 50,
    "revenue": 125000.00
  }
}
```

#### GET `/api/streams/{id}`
Get stream details

**Response:** Full stream object with user, co-hosts, viewer count

#### GET `/api/streams`
Get streams list (paginated, filtered)

**Query Params:**
- `status`: scheduled, pre_live, live, ended
- `user_id`: Filter by streamer
- `category`: Filter by category
- `page`: Pagination

---

### 2.2 Real-Time Engagement

#### POST `/api/streams/{id}/join`
Join a stream as viewer

**Response:**
```json
{
  "success": true,
  "viewer_token": "unique_token_for_analytics",
  "playback_url": "https://zima-uat.site:8003/live/stream_id_123.m3u8",
  "current_viewers": 125
}
```

#### POST `/api/streams/{id}/leave`
Leave stream

#### POST `/api/streams/{id}/like`
Like stream (toggle)

#### POST `/api/streams/{id}/comments`
Post comment during stream

**Request:**
```json
{
  "message": "Great stream! 🔥"
}
```

#### POST `/api/streams/{id}/gifts`
Send virtual gift

**Request:**
```json
{
  "gift_id": 5,
  "quantity": 3
}
```

#### GET `/api/streams/{id}/comments`
Get stream comments (paginated, real-time)

**Query:** `?last_id=123&limit=50`

---

### 2.3 Notifications

#### POST `/api/streams/{id}/notify-followers`
Manually trigger follower notifications

#### GET `/api/users/{id}/stream-notifications`
Get user's stream notifications

---

### 2.4 Analytics

#### GET `/api/streams/{id}/analytics`
Get detailed stream analytics

**Response:**
```json
{
  "stream_id": 123,
  "total_viewers": 1250,
  "unique_viewers": 980,
  "peak_viewers": 450,
  "average_watch_time": 320,
  "total_likes": 2340,
  "total_comments": 567,
  "total_shares": 89,
  "total_gifts": 50,
  "total_revenue": 125000.00,
  "viewers_by_region": {
    "Dar es Salaam": 450,
    "Arusha": 200,
    "Mwanza": 150
  },
  "retention_data": [
    {"timestamp": 0, "viewers": 100},
    {"timestamp": 60, "viewers": 150},
    {"timestamp": 120, "viewers": 200}
  ]
}
```

---

## 3. WebSocket/Real-Time Events

> **✅ UPDATED 2026-01-28:** Added detailed Plain WebSocket implementation (Option 1) with exact event formats, connection handling, and Laravel code examples. This matches the `WebSocketService` implementation in the Flutter app.

### Implementation Options

The Flutter app supports **two WebSocket approaches**:

1. **Plain WebSocket** (Recommended - Currently Implemented)
2. **Pusher/Laravel Echo** (Alternative)

Choose one based on your infrastructure preferences.

---

### Option 1: Plain WebSocket (Recommended) ✅

**Connection URL:** `wss://zima-uat.site/streams/{stream_id}?user_id={user_id}`

**Message Format:**
```json
{
  "event": "event_name",
  "data": { /* event-specific payload */ }
}
```

**Required Events to Broadcast:**

#### Event: `viewer_count_updated`
Broadcast every 3-5 seconds during live stream

```json
{
  "event": "viewer_count_updated",
  "data": {
    "current_viewers": 125,
    "peak_viewers": 150
  }
}
```

#### Event: `new_comment`
Broadcast immediately when comment posted

```json
{
  "event": "new_comment",
  "data": {
    "id": 456,
    "user_id": 789,
    "user": {
      "id": 789,
      "first_name": "John",
      "last_name": "Doe",
      "display_name": "John Doe",
      "avatar_url": "https://..."
    },
    "content": "Great stream!",
    "created_at": "2026-01-28T20:05:30Z"
  }
}
```

#### Event: `gift_sent`
Broadcast immediately when gift sent

```json
{
  "event": "gift_sent",
  "data": {
    "sender": {
      "id": 789,
      "first_name": "Jane",
      "last_name": "Doe",
      "display_name": "Jane Doe",
      "avatar_url": "https://..."
    },
    "gift": {
      "id": 5,
      "name": "Rose",
      "icon_url": "https://...",
      "price": 5000.00
    },
    "quantity": 3,
    "message": "Amazing!" // optional
  }
}
```

#### Event: `reaction`
Broadcast when quick reaction sent (hearts, fire, etc.)

```json
{
  "event": "reaction",
  "data": {
    "user_id": 789,
    "reaction_type": "heart" // heart, fire, love, wow, etc.
  }
}
```

#### Event: `status_changed`
Broadcast when stream status changes

```json
{
  "event": "status_changed",
  "data": {
    "old_status": "pre_live",
    "new_status": "live"
  }
}
```

#### Event: `ping` / `pong` (Heartbeat)
Client sends ping every 30 seconds, server responds with pong

```json
// Client → Server
{
  "event": "ping",
  "data": {
    "timestamp": "2026-01-28T20:05:30Z"
  }
}

// Server → Client
{
  "event": "pong",
  "data": {
    "timestamp": "2026-01-28T20:05:30Z"
  }
}
```

**Laravel WebSocket Package Recommendation:**
- [BeyondCode Laravel WebSockets](https://github.com/beyondcode/laravel-websockets)
- Drop-in replacement for Pusher
- Self-hosted, no external dependencies
- Supports same protocol as Pusher

**Installation:**
```bash
composer require beyondcode/laravel-websockets
php artisan vendor:publish --provider="BeyondCode\LaravelWebSockets\WebSocketsServiceProvider"
php artisan migrate
```

---

### Option 2: Pusher/Laravel Echo (Alternative)

**Channel:** `stream.{stream_id}`

**Note:** To use Pusher, the Flutter app needs to be modified to use `pusher_channels_flutter` package instead of `web_socket_channel`. The plain WebSocket approach (Option 1) is currently implemented and recommended.

**Pusher Events (if using this approach):**

#### Event: `StreamStatusChanged`
```json
{
  "stream_id": 123,
  "status": "live",
  "updated_at": "2026-01-28T20:00:05Z"
}
```

#### Event: `ViewerCountUpdated`
```json
{
  "stream_id": 123,
  "current_viewers": 125,
  "peak_viewers": 150
}
```

#### Event: `NewComment`
```json
{
  "id": 456,
  "stream_id": 123,
  "user": { "id": 789, "name": "John Doe", "photo": "url" },
  "message": "Great stream!",
  "created_at": "2026-01-28T20:05:30Z"
}
```

#### Event: `GiftReceived`
```json
{
  "stream_id": 123,
  "sender": { "id": 789, "name": "Jane Doe" },
  "gift": { "id": 5, "name": "Rose", "icon": "url" },
  "quantity": 3,
  "total_value": 15000.00
}
```

---

### WebSocket Server Implementation (Option 1)

**Connection Handling:**

1. **Accept Connection:** `wss://zima-uat.site/streams/{stream_id}?user_id={user_id}`
2. **Authenticate:** Verify user_id is valid and has permission to view stream
3. **Track Viewer:** Increment current viewers count, broadcast update
4. **Listen for Messages:** Handle ping, reactions, or other client events
5. **Broadcast Events:** Send real-time updates to all connected viewers
6. **Handle Disconnect:** Decrement viewer count, update analytics

**Backend Pseudocode (Laravel):**

```php
// WebSocket Connection Handler
class StreamWebSocketHandler
{
    public function onConnection($connection, $streamId, $userId)
    {
        // Authenticate user
        $user = User::find($userId);
        if (!$user) {
            $connection->close();
            return;
        }

        // Join stream room
        $this->joinRoom($connection, "stream_{$streamId}");

        // Increment viewer count
        Redis::incr("stream:{$streamId}:viewers");
        $currentViewers = Redis::get("stream:{$streamId}:viewers");

        // Broadcast viewer count update
        $this->broadcast("stream_{$streamId}", [
            'event' => 'viewer_count_updated',
            'data' => [
                'current_viewers' => (int)$currentViewers,
                'peak_viewers' => (int)Redis::get("stream:{$streamId}:peak_viewers")
            ]
        ]);

        // Log join event
        StreamViewer::create([
            'stream_id' => $streamId,
            'user_id' => $userId,
            'joined_at' => now()
        ]);
    }

    public function onMessage($connection, $message)
    {
        $data = json_decode($message, true);

        switch ($data['event']) {
            case 'ping':
                $connection->send(json_encode([
                    'event' => 'pong',
                    'data' => ['timestamp' => now()->toIso8601String()]
                ]));
                break;
            // Handle other client events...
        }
    }

    public function onDisconnect($connection, $streamId, $userId)
    {
        // Decrement viewer count
        Redis::decr("stream:{$streamId}:viewers");
        $currentViewers = Redis::get("stream:{$streamId}:viewers");

        // Broadcast viewer count update
        $this->broadcast("stream_{$streamId}", [
            'event' => 'viewer_count_updated',
            'data' => ['current_viewers' => (int)$currentViewers]
        ]);

        // Update viewer record
        StreamViewer::where('stream_id', $streamId)
            ->where('user_id', $userId)
            ->whereNull('left_at')
            ->update(['left_at' => now()]);
    }
}
```

**Broadcasting Events from REST API:**

```php
// When comment is posted (POST /api/streams/{id}/comments)
public function storeComment(Request $request, $streamId)
{
    $comment = StreamComment::create([
        'stream_id' => $streamId,
        'user_id' => $request->user_id,
        'content' => $request->content
    ]);

    $comment->load('user'); // Load user relationship

    // Broadcast to all viewers via WebSocket
    WebSocket::broadcast("stream_{$streamId}", [
        'event' => 'new_comment',
        'data' => [
            'id' => $comment->id,
            'user_id' => $comment->user_id,
            'user' => [
                'id' => $comment->user->id,
                'first_name' => $comment->user->first_name,
                'last_name' => $comment->user->last_name,
                'display_name' => $comment->user->display_name,
                'avatar_url' => $comment->user->avatar_url
            ],
            'content' => $comment->content,
            'created_at' => $comment->created_at->toIso8601String()
        ]
    ]);

    return response()->json(['success' => true, 'data' => $comment]);
}
```

**Recommended Package:**
- **BeyondCode Laravel WebSockets**: Compatible with Pusher protocol, self-hosted
- Alternatively: Build custom WebSocket server using Ratchet or Swoole

---

## 4. Status Transition Logic

### Automatic Transitions (Cron Jobs Required)

#### Job 1: `TransitionToPreLive`
**Schedule:** Every minute
**Logic:**
```php
// Find scheduled streams where scheduled_at is 15-30 min away
$streams = LiveStream::where('status', 'scheduled')
    ->whereBetween('scheduled_at', [
        now()->addMinutes(15),
        now()->addMinutes(30)
    ])
    ->get();

foreach ($streams as $stream) {
    $stream->update(['status' => 'pre_live', 'pre_live_started_at' => now()]);

    // Send notifications
    SendStreamStartingSoonNotification::dispatch($stream);

    // Broadcast event
    broadcast(new StreamStatusChanged($stream));
}
```

#### Job 2: `TransitionToEnded`
**Schedule:** Every 10 seconds
**Logic:**
```php
// Find streams in "ending" status for > 5 seconds
$streams = LiveStream::where('status', 'ending')
    ->where('updated_at', '<', now()->subSeconds(5))
    ->get();

foreach ($streams as $stream) {
    $stream->update([
        'status' => 'ended',
        'ended_at' => now(),
        'duration' => $stream->live_started_at->diffInSeconds($stream->ended_at)
    ]);

    // Generate final analytics
    GenerateStreamAnalytics::dispatch($stream);

    // Notify viewers
    broadcast(new StreamEnded($stream));
}
```

#### Job 3: `UpdateViewerCount`
**Schedule:** Every 5 seconds (for live streams only)
**Logic:**
```php
$liveStreams = LiveStream::where('status', 'live')->get();

foreach ($liveStreams as $stream) {
    $currentViewers = StreamViewer::where('stream_id', $stream->id)
        ->where('is_currently_watching', true)
        ->count();

    $stream->update(['current_viewers' => $currentViewers]);

    if ($currentViewers > $stream->peak_viewers) {
        $stream->update(['peak_viewers' => $currentViewers]);
    }

    // Broadcast update
    broadcast(new ViewerCountUpdated($stream));
}
```

---

## 5. Notification System

### Push Notifications Required

#### 1. **Stream Scheduled** (Immediate)
When stream is created with future `scheduled_at`

**Recipients:** Streamer's followers
**Message:** "{Streamer} has scheduled a livestream: {Title} on {Date} at {Time}"
**Action:** Open standby screen

#### 2. **Starting Soon** (15 min before)
When stream transitions to `pre_live`

**Recipients:** Streamer + Followers who opted in
**Message:** "{Streamer}'s livestream '{Title}' is starting in 15 minutes!"
**Action:** Open standby screen

#### 3. **Now Live** (When goes live)
When stream transitions to `live`

**Recipients:** All followers
**Message:** "{Streamer} is LIVE now! Join '{Title}'"
**Action:** Open live viewer screen

#### 4. **Stream Ended** (After stream)
When stream transitions to `ended`

**Recipients:** Viewers who watched
**Message:** "Thanks for watching '{Title}'! Replay available."
**Action:** Open replay/recording

### In-App Notifications

- Badge on "Live" tab when followed streamers go live
- Red "LIVE" indicator on streamer profiles
- Banner at top of feed when followed streamers go live

---

## 6. Streaming Infrastructure

### RTMP Ingest

**Required Setup:**
- **RTMP Server:** Nginx-RTMP or Wowza or AWS IVS
- **Ingest URL Format:** `rtmp://zima-uat.site/live/{stream_key}`
- **Stream Key:** Unique per stream, generated on creation

### HLS/DASH Playback

**Required:**
- **CDN:** CloudFront, Cloudflare Stream, or Bunny.net
- **Transcoding:** Multiple qualities (360p, 480p, 720p, 1080p)
- **Latency:** Target <3 seconds (Low-Latency HLS)
- **Playback URL Format:** `https://zima-uat.site:8003/live/{stream_id}.m3u8`

### Recording

**Required:**
- Auto-record streams where `is_recorded = true`
- Store recordings in S3/Cloud Storage
- Generate thumbnails and previews
- Make available within 5 min after stream ends

### Recommended Services

1. **AWS IVS** (Interactive Video Service) - Fully managed
2. **Mux** - Developer-friendly video API
3. **Cloudflare Stream** - Global CDN with low latency
4. **Agora.io** - Real-time engagement SDK

---

## 7. Analytics & Tracking

### Real-Time Metrics (During Stream)

Track every 5 seconds:
- Current viewer count
- Viewer join/leave events
- Comments per minute
- Gifts per minute
- Like rate

### Post-Stream Analytics

Calculate after stream ends:
- Total unique viewers
- Peak concurrent viewers
- Average watch time
- Viewer retention curve
- Engagement rate (likes + comments / viewers)
- Revenue from gifts
- Geographic distribution
- Top viewers (by watch time)

### Database Storage

- Store snapshots in `stream_analytics` table
- Keep detailed viewer logs for 30 days
- Aggregate data for long-term storage

---

## 8. Security & Performance

### Security Requirements

1. **Stream Key Protection**
   - Generate unique, long keys (32+ characters)
   - Never expose in client logs
   - Rotate keys after stream ends

2. **Playback Authentication**
   - Signed URLs with expiration
   - IP-based rate limiting
   - Bot detection

3. **Comment Moderation**
   - Bad word filtering
   - Spam detection
   - Rate limiting (1 comment per 3 seconds)
   - Streamer ban/mute controls

4. **Gift Fraud Prevention**
   - Verify payment before sending gift
   - Transaction logging
   - Refund mechanism

### Performance Requirements

1. **API Response Times**
   - Stream creation: <500ms
   - Join stream: <200ms
   - Post comment: <100ms
   - Analytics fetch: <1s

2. **WebSocket**
   - Real-time updates: <100ms latency
   - Connection limit: 10,000+ concurrent per stream

3. **Database Optimization**
   - Index all foreign keys
   - Partition large tables (viewers, comments)
   - Cache hot data (Redis)

4. **Scaling**
   - Horizontal scaling for API servers
   - CDN for playback (global)
   - Queue workers for async jobs (notifications, analytics)

---

## 9. Implementation Priority

### Phase 1: Core Functionality ⭐⭐⭐
- [ ] Database schema setup
- [ ] Stream CRUD endpoints
- [ ] Status transition logic
- [ ] RTMP ingest setup
- [ ] HLS playback

### Phase 2: Real-Time Features ⭐⭐
- [ ] WebSocket events (Pusher/Echo)
- [ ] Live comments
- [ ] Viewer count updates
- [ ] Notification system

### Phase 3: Engagement ⭐
- [ ] Virtual gifts
- [ ] Reactions
- [ ] Co-hosts
- [ ] Analytics dashboard

### Phase 4: Advanced Features
- [ ] Recording & replay
- [ ] Stream scheduling UI
- [ ] Advanced moderation tools
- [ ] Revenue tracking

---

## 10. Testing Requirements

### Load Testing Targets

- **Concurrent streams:** 100+
- **Viewers per stream:** 10,000+
- **Comments per second:** 100+
- **Gift transactions:** 10/second

### Test Scenarios

1. Stream creation and immediate go-live
2. Scheduled stream → pre-live → live transition
3. 1000+ concurrent viewers joining
4. High comment volume (100+/sec)
5. Gift sending under load
6. Abrupt stream termination
7. Network interruption recovery

---

## Summary

This backend requires:
✅ 8 database tables with proper indexes
✅ 15+ RESTful API endpoints
✅ 5+ real-time WebSocket events
✅ 3 cron jobs for status automation
✅ 4-tier notification system
✅ RTMP ingest + HLS playback infrastructure
✅ Comprehensive analytics tracking
✅ Security & performance optimizations

**Estimated Implementation Time:** 4-6 weeks for full-stack team

**Recommended Stack:**
- Laravel 10+ (API)
- Pusher/Laravel Echo (WebSocket)
- Redis (Caching & Queues)
- AWS IVS / Mux / Cloudflare Stream (Video)
- MySQL 8.0+ (Database)
- Firebase Cloud Messaging (Push notifications)

---

**Built for TAJIRI - Tanzania's Premier Social Platform**
*Military-Grade Quality, Smooth as Silk* 🎖️
