# TAJIRI Livestreaming - Advanced Backend Requirements

**Version**: 2.0
**Date**: 2026-01-28
**Status**: Implementation Ready
**Priority**: HIGH

## Table of Contents

1. [Overview](#overview)
2. [Architecture Updates](#architecture-updates)
3. [Database Schema](#database-schema)
4. [API Endpoints](#api-endpoints)
5. [WebSocket Events](#websocket-events)
6. [RTMP Streaming Setup](#rtmp-streaming-setup)
7. [Implementation Checklist](#implementation-checklist)

---

## Overview

This document outlines the backend requirements for **TAJIRI's advanced livestreaming features**, including:

- ✅ Professional camera streaming (ZEGOCLOUD integration)
- ✅ Real-time floating reactions
- ✅ Live polls with real-time voting
- ✅ Q&A mode with upvoting
- ✅ Super chat (tiered donations)
- ✅ Battle mode (PK battles between streamers)
- ✅ Stream health monitoring
- ✅ Live analytics

### Technology Stack

- **Backend**: Laravel 10+
- **WebSocket**: Laravel WebSockets (BeyondCode) or Pusher
- **RTMP Server**: nginx-rtmp-module or Wowza Streaming Engine
- **HLS Transcoding**: FFmpeg
- **Database**: MySQL 8.0+ or PostgreSQL 13+
- **Cache**: Redis 7.0+
- **Queue**: Laravel Queue (Redis driver)

---

## Architecture Updates

### High-Level Flow

```
[Flutter App - ZEGOCLOUD SDK]
         ↓ RTMP Push
[Laravel RTMP Server]
         ↓ Transcode
[HLS Segments]
         ↓ CDN
[Viewers - HLS Player]
```

### Real-time Communication

```
[Flutter App]
    ↕ WebSocket
[Laravel WebSocket Server]
    ↕ Redis Pub/Sub
[Laravel Backend Workers]
    ↕ Database
```

---

## Database Schema

### 1. Update `streams` Table

```sql
-- Add new columns to existing streams table
ALTER TABLE `streams` ADD COLUMN `beauty_filter_level` TINYINT UNSIGNED DEFAULT 50 AFTER `status`;
ALTER TABLE `streams` ADD COLUMN `network_quality` VARCHAR(20) DEFAULT 'good' AFTER `beauty_filter_level`;
ALTER TABLE `streams` ADD COLUMN `average_bitrate` INT UNSIGNED DEFAULT 0 AFTER `network_quality`;
ALTER TABLE `streams` ADD COLUMN `average_fps` TINYINT UNSIGNED DEFAULT 30 AFTER `average_bitrate`;
ALTER TABLE `streams` ADD COLUMN `total_dropped_frames` INT UNSIGNED DEFAULT 0 AFTER `average_fps`;
ALTER TABLE `streams` ADD COLUMN `average_latency` DECIMAL(5,2) DEFAULT 0.00 AFTER `total_dropped_frames`;

-- Indexes for performance
CREATE INDEX `idx_streams_status_scheduled` ON `streams` (`status`, `scheduled_at`);
```

### 2. Create `stream_reactions` Table

```sql
CREATE TABLE `stream_reactions` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `stream_id` BIGINT UNSIGNED NOT NULL,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `reaction_type` ENUM('heart', 'fire', 'clap', 'wow', 'laugh', 'sad') NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (`stream_id`) REFERENCES `streams`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,

    INDEX `idx_stream_reactions_stream` (`stream_id`, `created_at`),
    INDEX `idx_stream_reactions_user` (`user_id`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 3. Create `stream_polls` Table

```sql
CREATE TABLE `stream_polls` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `stream_id` BIGINT UNSIGNED NOT NULL,
    `question` VARCHAR(255) NOT NULL,
    `is_closed` BOOLEAN DEFAULT FALSE,
    `created_by` BIGINT UNSIGNED NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `closed_at` TIMESTAMP NULL,

    FOREIGN KEY (`stream_id`) REFERENCES `streams`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`created_by`) REFERENCES `users`(`id`) ON DELETE CASCADE,

    INDEX `idx_stream_polls_stream` (`stream_id`, `is_closed`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 4. Create `stream_poll_options` Table

```sql
CREATE TABLE `stream_poll_options` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `poll_id` BIGINT UNSIGNED NOT NULL,
    `text` VARCHAR(100) NOT NULL,
    `votes` INT UNSIGNED DEFAULT 0,

    FOREIGN KEY (`poll_id`) REFERENCES `stream_polls`(`id`) ON DELETE CASCADE,

    INDEX `idx_poll_options_poll` (`poll_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5. Create `stream_poll_votes` Table

```sql
CREATE TABLE `stream_poll_votes` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `poll_id` BIGINT UNSIGNED NOT NULL,
    `option_id` BIGINT UNSIGNED NOT NULL,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (`poll_id`) REFERENCES `stream_polls`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`option_id`) REFERENCES `stream_poll_options`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,

    UNIQUE KEY `unique_user_poll_vote` (`poll_id`, `user_id`),
    INDEX `idx_poll_votes_option` (`option_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 6. Create `stream_questions` Table

```sql
CREATE TABLE `stream_questions` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `stream_id` BIGINT UNSIGNED NOT NULL,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `question` TEXT NOT NULL,
    `upvotes` INT UNSIGNED DEFAULT 0,
    `is_answered` BOOLEAN DEFAULT FALSE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `answered_at` TIMESTAMP NULL,

    FOREIGN KEY (`stream_id`) REFERENCES `streams`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,

    INDEX `idx_stream_questions_stream` (`stream_id`, `upvotes` DESC),
    INDEX `idx_stream_questions_answered` (`stream_id`, `is_answered`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 7. Create `stream_question_upvotes` Table

```sql
CREATE TABLE `stream_question_upvotes` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `question_id` BIGINT UNSIGNED NOT NULL,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (`question_id`) REFERENCES `stream_questions`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,

    UNIQUE KEY `unique_user_question_upvote` (`question_id`, `user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 8. Create `stream_super_chats` Table

```sql
CREATE TABLE `stream_super_chats` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `stream_id` BIGINT UNSIGNED NOT NULL,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `message` TEXT NOT NULL,
    `amount` DECIMAL(10,2) NOT NULL,
    `tier` ENUM('low', 'medium', 'high') NOT NULL,
    `duration` TINYINT UNSIGNED DEFAULT 5, -- seconds to display
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (`stream_id`) REFERENCES `streams`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,

    INDEX `idx_super_chats_stream` (`stream_id`, `created_at` DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 9. Create `stream_battles` Table (PK Battles)

```sql
CREATE TABLE `stream_battles` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `stream_id_1` BIGINT UNSIGNED NOT NULL,
    `stream_id_2` BIGINT UNSIGNED NOT NULL,
    `status` ENUM('pending', 'active', 'ended', 'cancelled') DEFAULT 'pending',
    `score_1` INT UNSIGNED DEFAULT 0,
    `score_2` INT UNSIGNED DEFAULT 0,
    `winner_stream_id` BIGINT UNSIGNED NULL,
    `started_at` TIMESTAMP NULL,
    `ended_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (`stream_id_1`) REFERENCES `streams`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`stream_id_2`) REFERENCES `streams`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`winner_stream_id`) REFERENCES `streams`(`id`) ON DELETE SET NULL,

    INDEX `idx_battles_status` (`status`),
    INDEX `idx_battles_streams` (`stream_id_1`, `stream_id_2`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 10. Update `virtual_gifts` Table

```sql
-- Add super chat tier mapping
ALTER TABLE `virtual_gifts` ADD COLUMN `super_chat_tier` ENUM('low', 'medium', 'high') NULL AFTER `icon`;

-- Example data
INSERT INTO `virtual_gifts` (`name`, `price`, `icon`, `super_chat_tier`) VALUES
('Super Chat Low', 1000, 'chat_low.png', 'low'),
('Super Chat Medium', 5000, 'chat_medium.png', 'medium'),
('Super Chat High', 10000, 'chat_high.png', 'high');
```

---

## API Endpoints

### 1. Reactions

#### `POST /api/streams/{id}/reactions`

Send a reaction to a stream.

**Request**:
```json
{
    "reaction_type": "heart"  // heart, fire, clap, wow, laugh, sad
}
```

**Response** (200 OK):
```json
{
    "success": true,
    "message": "Reaction sent successfully"
}
```

**WebSocket Broadcast**:
```json
{
    "event": "reaction",
    "data": {
        "user_id": 123,
        "reaction_type": "heart",
        "timestamp": "2026-01-28T10:30:00Z"
    }
}
```

---

### 2. Polls

#### `POST /api/streams/{id}/polls`

Create a live poll (broadcaster only).

**Request**:
```json
{
    "question": "Which feature do you like most?",
    "options": ["Polls", "Q&A", "Super Chat", "Battle Mode"]
}
```

**Response** (201 Created):
```json
{
    "success": true,
    "poll": {
        "id": 456,
        "stream_id": 123,
        "question": "Which feature do you like most?",
        "options": [
            {"id": 1, "text": "Polls", "votes": 0},
            {"id": 2, "text": "Q&A", "votes": 0},
            {"id": 3, "text": "Super Chat", "votes": 0},
            {"id": 4, "text": "Battle Mode", "votes": 0}
        ],
        "is_closed": false,
        "created_by": 456,
        "created_at": "2026-01-28T10:30:00Z"
    }
}
```

**WebSocket Broadcast**:
```json
{
    "event": "poll_created",
    "data": {
        "poll_id": 456,
        "question": "Which feature do you like most?",
        "options": [...]
    }
}
```

#### `POST /api/streams/{id}/polls/{poll_id}/vote`

Vote on a poll option.

**Request**:
```json
{
    "option_id": 1
}
```

**Response** (200 OK):
```json
{
    "success": true,
    "poll": {
        "id": 456,
        "options": [
            {"id": 1, "text": "Polls", "votes": 15},
            {"id": 2, "text": "Q&A", "votes": 8},
            {"id": 3, "text": "Super Chat", "votes": 12},
            {"id": 4, "text": "Battle Mode", "votes": 20}
        ]
    }
}
```

**WebSocket Broadcast**:
```json
{
    "event": "poll_vote",
    "data": {
        "poll_id": 456,
        "option_id": 1,
        "user_id": 789,
        "votes": 15,
        "timestamp": "2026-01-28T10:31:00Z"
    }
}
```

#### `POST /api/streams/{id}/polls/{poll_id}/close`

Close a poll (broadcaster only).

**Response** (200 OK):
```json
{
    "success": true,
    "message": "Poll closed successfully"
}
```

**WebSocket Broadcast**:
```json
{
    "event": "poll_closed",
    "data": {
        "poll_id": 456,
        "final_results": [...]
    }
}
```

---

### 3. Q&A Mode

#### `POST /api/streams/{id}/questions`

Submit a question (viewers).

**Request**:
```json
{
    "question": "How long have you been streaming?"
}
```

**Response** (201 Created):
```json
{
    "success": true,
    "question": {
        "id": 789,
        "stream_id": 123,
        "user_id": 456,
        "question": "How long have you been streaming?",
        "upvotes": 0,
        "is_answered": false,
        "created_at": "2026-01-28T10:30:00Z"
    }
}
```

**WebSocket Broadcast**:
```json
{
    "event": "question_submitted",
    "data": {
        "question_id": 789,
        "user_id": 456,
        "username": "JohnDoe",
        "question": "How long have you been streaming?",
        "upvotes": 0,
        "timestamp": "2026-01-28T10:30:00Z"
    }
}
```

#### `POST /api/streams/{id}/questions/{question_id}/upvote`

Upvote a question.

**Response** (200 OK):
```json
{
    "success": true,
    "upvotes": 15
}
```

**WebSocket Broadcast**:
```json
{
    "event": "question_upvoted",
    "data": {
        "question_id": 789,
        "upvotes": 15,
        "timestamp": "2026-01-28T10:31:00Z"
    }
}
```

#### `POST /api/streams/{id}/questions/{question_id}/answer`

Mark question as answered (broadcaster only).

**Response** (200 OK):
```json
{
    "success": true,
    "message": "Question marked as answered"
}
```

**WebSocket Broadcast**:
```json
{
    "event": "question_answered",
    "data": {
        "question_id": 789,
        "timestamp": "2026-01-28T10:32:00Z"
    }
}
```

#### `GET /api/streams/{id}/questions`

Get all questions for a stream (sorted by upvotes).

**Response** (200 OK):
```json
{
    "success": true,
    "questions": [
        {
            "id": 789,
            "user_id": 456,
            "username": "JohnDoe",
            "question": "How long have you been streaming?",
            "upvotes": 15,
            "is_answered": false,
            "created_at": "2026-01-28T10:30:00Z"
        }
    ]
}
```

---

### 4. Super Chat

#### `POST /api/streams/{id}/super-chats`

Send a super chat with payment.

**Request**:
```json
{
    "message": "Love your content! Keep it up!",
    "amount": 5000.00,  // TZS
    "payment_method": "mpesa",  // or card, wallet, etc.
    "payment_reference": "MPESA123456"
}
```

**Response** (201 Created):
```json
{
    "success": true,
    "super_chat": {
        "id": 123,
        "stream_id": 456,
        "user_id": 789,
        "message": "Love your content! Keep it up!",
        "amount": 5000.00,
        "tier": "medium",  // Calculated based on amount
        "duration": 10,  // seconds
        "created_at": "2026-01-28T10:30:00Z"
    }
}
```

**Tier Calculation**:
- Low: TZS 1,000 - 2,999 (duration: 5s, blue)
- Medium: TZS 3,000 - 9,999 (duration: 10s, amber)
- High: TZS 10,000+ (duration: 15s, red)

**WebSocket Broadcast**:
```json
{
    "event": "super_chat_sent",
    "data": {
        "user_id": 789,
        "username": "JohnDoe",
        "message": "Love your content!",
        "amount": 5000.00,
        "tier": "medium",
        "duration": 10,
        "timestamp": "2026-01-28T10:30:00Z"
    }
}
```

---

### 5. Battle Mode (PK Battles)

#### `POST /api/streams/{id}/battles/invite`

Invite another streamer to a battle.

**Request**:
```json
{
    "opponent_stream_id": 789
}
```

**Response** (201 Created):
```json
{
    "success": true,
    "battle": {
        "id": 123,
        "stream_id_1": 456,
        "stream_id_2": 789,
        "status": "pending",
        "created_at": "2026-01-28T10:30:00Z"
    }
}
```

**WebSocket Broadcast** (to opponent):
```json
{
    "event": "battle_invite",
    "data": {
        "battle_id": 123,
        "opponent_id": 456,
        "opponent_name": "StreamerA",
        "timestamp": "2026-01-28T10:30:00Z"
    }
}
```

#### `POST /api/battles/{battle_id}/accept`

Accept a battle invitation.

**Response** (200 OK):
```json
{
    "success": true,
    "battle": {
        "id": 123,
        "status": "active",
        "started_at": "2026-01-28T10:31:00Z"
    }
}
```

**WebSocket Broadcast** (to both streams):
```json
{
    "event": "battle_accepted",
    "data": {
        "battle_id": 123,
        "opponent_id": 789,
        "opponent_name": "StreamerB",
        "timestamp": "2026-01-28T10:31:00Z"
    }
}
```

#### `POST /api/battles/{battle_id}/decline`

Decline a battle invitation.

**Response** (200 OK):
```json
{
    "success": true,
    "message": "Battle invitation declined"
}
```

#### `GET /api/battles/{battle_id}`

Get battle status and scores.

**Response** (200 OK):
```json
{
    "success": true,
    "battle": {
        "id": 123,
        "stream_1": {
            "id": 456,
            "name": "StreamerA",
            "score": 15000
        },
        "stream_2": {
            "id": 789,
            "name": "StreamerB",
            "score": 12500
        },
        "status": "active",
        "started_at": "2026-01-28T10:31:00Z"
    }
}
```

**Score Calculation**:
- Scores updated when viewers send gifts
- Gift value = battle points
- Real-time WebSocket updates

**WebSocket Broadcast** (score update):
```json
{
    "event": "battle_score_update",
    "data": {
        "battle_id": 123,
        "my_score": 15000,
        "opponent_score": 12500,
        "timestamp": "2026-01-28T10:35:00Z"
    }
}
```

#### `POST /api/battles/{battle_id}/end`

End a battle (automatic after 5 minutes or manual).

**Response** (200 OK):
```json
{
    "success": true,
    "battle": {
        "id": 123,
        "status": "ended",
        "winner_stream_id": 456,
        "final_scores": {
            "stream_1": 15000,
            "stream_2": 12500
        },
        "ended_at": "2026-01-28T10:36:00Z"
    }
}
```

**WebSocket Broadcast**:
```json
{
    "event": "battle_ended",
    "data": {
        "battle_id": 123,
        "winner_id": 456,
        "my_score": 15000,
        "opponent_score": 12500,
        "timestamp": "2026-01-28T10:36:00Z"
    }
}
```

---

### 6. Stream Health Metrics

#### `POST /api/streams/{id}/health`

Report stream health metrics (from ZEGOCLOUD).

**Request**:
```json
{
    "network_quality": "excellent",  // excellent, good, poor
    "bitrate": 3500,  // kbps
    "fps": 30,
    "dropped_frames": 5,
    "latency": 2.5  // seconds
}
```

**Response** (200 OK):
```json
{
    "success": true,
    "message": "Health metrics recorded"
}
```

---

## WebSocket Events

### Connection

**URL**: `wss://zima-uat.site:8003/streams/{stream_id}?user_id={user_id}`

**On Connect**:
```json
{
    "event": "connected",
    "data": {
        "stream_id": 123,
        "user_id": 456,
        "timestamp": "2026-01-28T10:30:00Z"
    }
}
```

### Event Summary

| Event | Direction | Description |
|-------|-----------|-------------|
| `reaction` | Server → Client | Someone sent a reaction |
| `poll_created` | Server → Client | Broadcaster created a poll |
| `poll_vote` | Server → Client | Someone voted on a poll |
| `poll_closed` | Server → Client | Broadcaster closed a poll |
| `question_submitted` | Server → Client | Viewer submitted a question |
| `question_upvoted` | Server → Client | Question upvote count updated |
| `question_answered` | Server → Client | Broadcaster answered a question |
| `super_chat_sent` | Server → Client | Someone sent a super chat |
| `battle_invite` | Server → Client | Another streamer invites to battle |
| `battle_accepted` | Server → Client | Battle invitation accepted |
| `battle_score_update` | Server → Client | Battle scores updated |
| `battle_ended` | Server → Client | Battle ended with winner |
| `viewer_count_updated` | Server → Client | Viewer count changed |
| `gift_sent` | Server → Client | Someone sent a virtual gift |
| `new_comment` | Server → Client | New comment posted |
| `status_changed` | Server → Client | Stream status changed |

---

## RTMP Streaming Setup

### 1. nginx-rtmp Configuration

Install nginx with RTMP module:

```bash
sudo apt update
sudo apt install build-essential libpcre3 libpcre3-dev libssl-dev zlib1g-dev
wget http://nginx.org/download/nginx-1.25.0.tar.gz
wget https://github.com/arut/nginx-rtmp-module/archive/master.zip
tar -zxvf nginx-1.25.0.tar.gz
unzip master.zip
cd nginx-1.25.0
./configure --with-http_ssl_module --add-module=../nginx-rtmp-module-master
make
sudo make install
```

Configure `/usr/local/nginx/conf/nginx.conf`:

```nginx
rtmp {
    server {
        listen 1935;
        chunk_size 4096;

        application live {
            live on;
            record off;

            # Enable HLS
            hls on;
            hls_path /var/www/hls;
            hls_fragment 2s;
            hls_playlist_length 10s;

            # Authentication callback
            on_publish http://zima-uat.site:8003/api/rtmp/auth;
            on_publish_done http://zima-uat.site:8003/api/rtmp/done;
        }
    }
}

http {
    server {
        listen 8003 ssl;
        server_name zima-uat.site;

        ssl_certificate /etc/letsencrypt/live/zima-uat.site/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/zima-uat.site/privkey.pem;

        location /live {
            types {
                application/vnd.apple.mpegurl m3u8;
                video/mp2t ts;
            }
            alias /var/www/hls;
            add_header Cache-Control no-cache;
            add_header Access-Control-Allow-Origin *;
        }

        location /api {
            proxy_pass http://localhost:8000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }
    }
}
```

### 2. Laravel RTMP Authentication

Create controller `app/Http/Controllers/RtmpController.php`:

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Stream;

class RtmpController extends Controller
{
    public function auth(Request $request)
    {
        $streamId = $request->input('name'); // RTMP stream key = stream ID

        $stream = Stream::find($streamId);

        if (!$stream || $stream->status !== 'pre_live') {
            return response('Unauthorized', 403);
        }

        return response('OK', 200);
    }

    public function done(Request $request)
    {
        $streamId = $request->input('name');

        $stream = Stream::find($streamId);
        if ($stream) {
            $stream->update(['status' => 'ending']);
        }

        return response('OK', 200);
    }
}
```

Add routes in `routes/api.php`:

```php
Route::post('/rtmp/auth', [RtmpController::class, 'auth']);
Route::post('/rtmp/done', [RtmpController::class, 'done']);
```

### 3. HLS URL Format

```
https://zima-uat.site:8003/live/{stream_id}.m3u8
```

---

## Implementation Checklist

### Database
- [ ] Create all new tables (`stream_reactions`, `stream_polls`, etc.)
- [ ] Add new columns to `streams` table
- [ ] Create indexes for performance
- [ ] Seed test data for development

### API Endpoints
- [ ] Implement reaction endpoints
- [ ] Implement poll endpoints (CRUD + voting)
- [ ] Implement Q&A endpoints (submit, upvote, answer)
- [ ] Implement super chat endpoint with payment processing
- [ ] Implement battle mode endpoints (invite, accept, decline, scores)
- [ ] Implement stream health metrics endpoint
- [ ] Add authentication and authorization
- [ ] Add rate limiting
- [ ] Add validation rules
- [ ] Write API tests

### WebSocket Server
- [ ] Install Laravel WebSockets or configure Pusher
- [ ] Implement all WebSocket events
- [ ] Test event broadcasting
- [ ] Add authentication for WebSocket connections
- [ ] Monitor WebSocket performance

### RTMP Streaming
- [ ] Install and configure nginx-rtmp
- [ ] Set up HLS transcoding with FFmpeg
- [ ] Implement RTMP authentication
- [ ] Configure SSL certificates
- [ ] Set up CDN (optional, CloudFlare/AWS CloudFront)
- [ ] Test RTMP push from ZEGOCLOUD
- [ ] Verify HLS playback

### Business Logic
- [ ] Implement super chat tier calculation
- [ ] Implement battle score calculation
- [ ] Implement automatic battle ending (5 min timer)
- [ ] Implement payment processing for super chats
- [ ] Implement earnings distribution to streamers
- [ ] Add fraud prevention for voting/upvoting
- [ ] Add spam prevention for reactions

### Performance & Scalability
- [ ] Set up Redis for caching and queues
- [ ] Configure Laravel Queue workers
- [ ] Optimize database queries (indexes, eager loading)
- [ ] Set up horizontal scaling for WebSocket servers
- [ ] Monitor server resources (CPU, RAM, bandwidth)
- [ ] Load testing (50+ concurrent streams)

### Monitoring & Logging
- [ ] Set up application logging
- [ ] Monitor RTMP server performance
- [ ] Monitor WebSocket connections
- [ ] Set up alerting for failures
- [ ] Track stream metrics (viewers, duration, earnings)
- [ ] Create admin dashboard for monitoring

### Security
- [ ] Implement rate limiting on all endpoints
- [ ] Add CAPTCHA for critical actions
- [ ] Validate and sanitize all inputs
- [ ] Implement CORS properly
- [ ] Secure WebSocket connections (WSS)
- [ ] Implement IP whitelisting for RTMP (optional)
- [ ] Add abuse reporting system

---

## Testing Endpoints

Use these curl commands to test:

### Test Reaction
```bash
curl -X POST https://zima-uat.site:8003/api/streams/123/reactions \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"reaction_type": "heart"}'
```

### Test Poll Creation
```bash
curl -X POST https://zima-uat.site:8003/api/streams/123/polls \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "Which feature?",
    "options": ["Polls", "Q&A", "Super Chat"]
  }'
```

### Test Super Chat
```bash
curl -X POST https://zima-uat.site:8003/api/streams/123/super-chats \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Great stream!",
    "amount": 5000,
    "payment_method": "mpesa",
    "payment_reference": "MPESA123"
  }'
```

---

**Backend Team Contact**: [Contact Information]
**Priority Issues**: Slack #backend-livestreaming
**Documentation**: This file + Frontend LIVESTREAM_TESTING_GUIDE.md
