# Backend Implementation for Live Viewer Experience

**For**: TAJIRI Streaming Platform - Viewer/Consumer Support
**Goal**: Real-time updates for live streams grid
**Stack**: Laravel + Reverb + Redis + WebSocket
**Date**: January 28, 2026

---

## 🎯 Overview

The frontend viewer experience needs backend support for:
1. ✅ API endpoints for live/upcoming streams (Already exists)
2. ⚠️ **WebSocket global channel** (Needs implementation)
3. ⚠️ **Real-time viewer count broadcasting** (Needs implementation)
4. ⚠️ **Real-time stream status broadcasting** (Needs implementation)

---

## 📋 What Needs to Be Implemented

### 1. Laravel Events for Broadcasting

Create events that will be broadcast to all viewers watching the Live tab.

### 2. Global Streams WebSocket Channel

Setup a WebSocket channel that broadcasts to ALL users (not just viewers of one stream).

### 3. Broadcasting Logic

Trigger events when:
- Viewer count changes on any stream
- Stream status changes (goes live, ends, etc.)
- New stream starts

---

## 🚀 Implementation Guide

### Step 1: Create Broadcasting Events

**File**: `app/Events/StreamViewerCountUpdated.php`

```php
<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Broadcast viewer count updates to all users on Live tab
 * This allows real-time viewer count updates without page refresh
 */
class StreamViewerCountUpdated implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public int $streamId;
    public int $viewersCount;
    public int $peakViewers;

    public function __construct(int $streamId, int $viewersCount, int $peakViewers)
    {
        $this->streamId = $streamId;
        $this->viewersCount = $viewersCount;
        $this->peakViewers = $peakViewers;
    }

    /**
     * Get the channels the event should broadcast on.
     * Using a public channel so all users can receive updates
     */
    public function broadcastOn(): Channel
    {
        return new Channel('live-streams');
    }

    /**
     * The event name
     */
    public function broadcastAs(): string
    {
        return 'viewer_count_updated';
    }

    /**
     * Data to broadcast
     */
    public function broadcastWith(): array
    {
        return [
            'stream_id' => $this->streamId,
            'viewers_count' => $this->viewersCount,
            'peak_viewers' => $this->peakViewers,
            'timestamp' => now()->toIso8601String(),
        ];
    }
}
```

---

**File**: `app/Events/StreamStatusChanged.php`

```php
<?php

namespace App\Events;

use App\Models\Stream;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Broadcast stream status changes to all users
 * Allows Live tab to update when streams go live or end
 */
class StreamStatusChanged implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public Stream $stream;
    public string $oldStatus;
    public string $newStatus;

    public function __construct(Stream $stream, string $oldStatus, string $newStatus)
    {
        $this->stream = $stream;
        $this->oldStatus = $oldStatus;
        $this->newStatus = $newStatus;
    }

    /**
     * Broadcast on public channel for all users
     */
    public function broadcastOn(): Channel
    {
        return new Channel('live-streams');
    }

    /**
     * The event name
     */
    public function broadcastAs(): string
    {
        return 'stream_status_changed';
    }

    /**
     * Data to broadcast
     */
    public function broadcastWith(): array
    {
        return [
            'stream_id' => $this->stream->id,
            'old_status' => $this->oldStatus,
            'new_status' => $this->newStatus,
            'stream' => [
                'id' => $this->stream->id,
                'title' => $this->stream->title,
                'status' => $this->stream->status,
                'viewers_count' => $this->stream->viewers_count ?? 0,
                'user' => [
                    'id' => $this->stream->user->id,
                    'first_name' => $this->stream->user->first_name,
                    'last_name' => $this->stream->user->last_name,
                ],
            ],
            'timestamp' => now()->toIso8601String(),
        ];
    }
}
```

---

### Step 2: Update Stream Controller to Broadcast Events

**File**: `app/Http/Controllers/StreamController.php` (Update existing)

```php
<?php

namespace App\Http\Controllers;

use App\Models\Stream;
use App\Events\StreamViewerCountUpdated;
use App\Events\StreamStatusChanged;
use Illuminate\Http\Request;

class StreamController extends Controller
{
    /**
     * Start a stream (update status from scheduled -> pre_live -> live)
     */
    public function start(Request $request, int $id)
    {
        $stream = Stream::findOrFail($id);

        // Save old status
        $oldStatus = $stream->status;

        // Update status to live
        $stream->update([
            'status' => 'live',
            'started_at' => now(),
        ]);

        // Broadcast status change to all users on Live tab
        broadcast(new StreamStatusChanged($stream->load('user'), $oldStatus, 'live'));

        return response()->json([
            'success' => true,
            'data' => $stream->load('user'),
            'message' => 'Stream started successfully',
        ]);
    }

    /**
     * End a stream
     */
    public function end(Request $request, int $id)
    {
        $stream = Stream::findOrFail($id);

        // Save old status
        $oldStatus = $stream->status;

        // Calculate duration
        $duration = $stream->started_at
            ? now()->diffInSeconds($stream->started_at)
            : 0;

        // Update status to ended
        $stream->update([
            'status' => 'ended',
            'ended_at' => now(),
            'duration' => $duration,
        ]);

        // Broadcast status change to all users
        broadcast(new StreamStatusChanged($stream->load('user'), $oldStatus, 'ended'));

        return response()->json([
            'success' => true,
            'data' => $stream,
            'message' => 'Stream ended successfully',
        ]);
    }

    /**
     * User joins stream (increment viewer count)
     */
    public function join(Request $request, int $id)
    {
        $stream = Stream::findOrFail($id);

        // Increment viewers count
        $stream->increment('viewers_count');

        // Update peak viewers if needed
        if ($stream->viewers_count > $stream->peak_viewers) {
            $stream->update(['peak_viewers' => $stream->viewers_count]);
        }

        // Refresh to get updated counts
        $stream->refresh();

        // Broadcast viewer count update to all users on Live tab
        broadcast(new StreamViewerCountUpdated(
            $stream->id,
            $stream->viewers_count,
            $stream->peak_viewers
        ));

        return response()->json([
            'success' => true,
            'message' => 'Joined stream',
        ]);
    }

    /**
     * User leaves stream (decrement viewer count)
     */
    public function leave(Request $request, int $id)
    {
        $stream = Stream::findOrFail($id);

        // Decrement viewers count (don't go below 0)
        if ($stream->viewers_count > 0) {
            $stream->decrement('viewers_count');
            $stream->refresh();

            // Broadcast viewer count update
            broadcast(new StreamViewerCountUpdated(
                $stream->id,
                $stream->viewers_count,
                $stream->peak_viewers
            ));
        }

        return response()->json([
            'success' => true,
            'message' => 'Left stream',
        ]);
    }

    /**
     * Get live streams (for viewer grid)
     */
    public function index(Request $request)
    {
        $query = Stream::with('user:id,first_name,last_name,username,profile_photo_path');

        // Filter by status if provided
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        // Order by viewers count (most popular first)
        $query->orderBy('viewers_count', 'desc')
              ->orderBy('started_at', 'desc');

        $streams = $query->get();

        return response()->json([
            'success' => true,
            'data' => $streams,
        ]);
    }
}
```

---

### Step 3: Setup Routes

**File**: `routes/api.php` (Add/Update)

```php
<?php

use App\Http\Controllers\StreamController;

Route::prefix('streams')->group(function () {
    // Get streams (live, upcoming, etc)
    Route::get('/', [StreamController::class, 'index']);

    // Get specific stream
    Route::get('/{id}', [StreamController::class, 'show']);

    // Create stream
    Route::post('/', [StreamController::class, 'store']);

    // Start stream
    Route::post('/{id}/start', [StreamController::class, 'start']);

    // End stream
    Route::post('/{id}/end', [StreamController::class, 'end']);

    // Join stream (increment viewer count)
    Route::post('/{id}/join', [StreamController::class, 'join']);

    // Leave stream (decrement viewer count)
    Route::post('/{id}/leave', [StreamController::class, 'leave']);

    // Like stream
    Route::post('/{id}/like', [StreamController::class, 'like']);

    // Comments
    Route::get('/{id}/comments', [StreamController::class, 'getComments']);
    Route::post('/{id}/comments', [StreamController::class, 'addComment']);
    Route::post('/{id}/comments/{commentId}/pin', [StreamController::class, 'pinComment']);

    // Gifts
    Route::get('/gifts', [StreamController::class, 'getAvailableGifts']);
    Route::post('/{id}/gifts', [StreamController::class, 'sendGift']);

    // Viewers
    Route::get('/{id}/viewers', [StreamController::class, 'getViewers']);
});
```

---

### Step 4: Configure Laravel Reverb for Public Channel

**File**: `config/broadcasting.php` (Update)

```php
<?php

return [
    'default' => env('BROADCAST_DRIVER', 'reverb'),

    'connections' => [
        'reverb' => [
            'driver' => 'reverb',
            'app_id' => env('REVERB_APP_ID'),
            'app_key' => env('REVERB_APP_KEY'),
            'app_secret' => env('REVERB_APP_SECRET'),
            'host' => env('REVERB_HOST', '0.0.0.0'),
            'port' => env('REVERB_PORT', 8080),
            'scheme' => env('REVERB_SCHEME', 'http'),
            'options' => [
                'tls' => [],
            ],
            'useTLS' => env('REVERB_SCHEME', 'http') === 'https',
        ],
    ],
];
```

**File**: `.env` (Add/Update)

```env
BROADCAST_DRIVER=reverb

REVERB_APP_ID=tajiri-app
REVERB_APP_KEY=your-app-key-here
REVERB_APP_SECRET=your-secret-key-here
REVERB_HOST=0.0.0.0
REVERB_PORT=8080
REVERB_SCHEME=http
```

---

### Step 5: Setup Broadcasting Channel Authorization (Optional)

**File**: `routes/channels.php`

```php
<?php

use Illuminate\Support\Facades\Broadcast;

/*
|--------------------------------------------------------------------------
| Broadcast Channels
|--------------------------------------------------------------------------
*/

// Public channel for live streams updates (anyone can listen)
Broadcast::channel('live-streams', function () {
    // Public channel - no authentication needed
    return true;
});

// Private channel for specific stream (only viewers of that stream)
Broadcast::channel('stream.{streamId}', function ($user, $streamId) {
    // Anyone can join to watch
    return true;
});
```

---

### Step 6: Start Laravel Reverb Server

**Command Line**:

```bash
# Install Laravel Reverb if not already installed
composer require laravel/reverb

# Publish configuration
php artisan reverb:install

# Run migrations (if needed)
php artisan migrate

# Start Reverb WebSocket server
php artisan reverb:start

# Or use Supervisor for production (recommended)
```

**Supervisor Config** (`/etc/supervisor/conf.d/reverb.conf`):

```ini
[program:tajiri-reverb]
command=php /var/www/html/artisan reverb:start
directory=/var/www/html
user=www-data
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/www/html/storage/logs/reverb.log
stopwaitsecs=3600
```

```bash
# Reload supervisor
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start tajiri-reverb
```

---

### Step 7: Test Broadcasting

**Test Script**: `test-broadcasting.php`

```php
<?php

// In artisan tinker or a test script:

// Test viewer count update
use App\Events\StreamViewerCountUpdated;
broadcast(new StreamViewerCountUpdated(
    streamId: 1,
    viewersCount: 150,
    peakViewers: 200
));

// Test stream status change
use App\Events\StreamStatusChanged;
use App\Models\Stream;
$stream = Stream::with('user')->find(1);
broadcast(new StreamStatusChanged(
    stream: $stream,
    oldStatus: 'scheduled',
    newStatus: 'live'
));
```

**Expected Output** (in browser console):

```javascript
// WebSocket message received:
{
  "event": "viewer_count_updated",
  "data": {
    "stream_id": 1,
    "viewers_count": 150,
    "peak_viewers": 200,
    "timestamp": "2026-01-28T10:30:00Z"
  }
}

{
  "event": "stream_status_changed",
  "data": {
    "stream_id": 1,
    "old_status": "scheduled",
    "new_status": "live",
    "stream": { ... },
    "timestamp": "2026-01-28T10:30:00Z"
  }
}
```

---

## 🔄 Real-Time Update Flow

### When User Joins Stream:

```
1. Frontend calls: POST /api/streams/{id}/join
2. Backend increments viewers_count
3. Backend broadcasts StreamViewerCountUpdated event
4. Laravel Reverb sends WebSocket message to all connected clients
5. Frontend receives update (<100ms)
6. UI updates viewer count automatically
```

### When Stream Goes Live:

```
1. Streamer starts streaming
2. Backend updates stream status to 'live'
3. Backend broadcasts StreamStatusChanged event
4. All users on Live tab receive WebSocket message
5. New live stream appears in grid automatically
```

---

## 📊 Database Schema Requirements

Make sure your `streams` table has these columns:

```sql
-- Streams table
CREATE TABLE streams (
    id BIGINT UNSIGNED PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    stream_key VARCHAR(255) NOT NULL UNIQUE,
    title VARCHAR(255) NOT NULL,
    description TEXT NULL,
    thumbnail_path VARCHAR(255) NULL,
    category VARCHAR(100) NULL,
    tags JSON NULL,
    status ENUM('scheduled', 'pre_live', 'live', 'ended') DEFAULT 'scheduled',
    privacy ENUM('public', 'followers', 'private') DEFAULT 'public',
    stream_url VARCHAR(255) NULL,
    playback_url VARCHAR(255) NULL,
    recording_path VARCHAR(255) NULL,
    is_recorded BOOLEAN DEFAULT true,
    allow_comments BOOLEAN DEFAULT true,
    allow_gifts BOOLEAN DEFAULT true,
    viewers_count INT UNSIGNED DEFAULT 0,
    peak_viewers INT UNSIGNED DEFAULT 0,
    total_viewers INT UNSIGNED DEFAULT 0,
    likes_count INT UNSIGNED DEFAULT 0,
    comments_count INT UNSIGNED DEFAULT 0,
    gifts_count INT UNSIGNED DEFAULT 0,
    shares_count INT UNSIGNED DEFAULT 0,
    gifts_value DECIMAL(10,2) DEFAULT 0.00,
    scheduled_at TIMESTAMP NULL,
    started_at TIMESTAMP NULL,
    ended_at TIMESTAMP NULL,
    duration INT UNSIGNED NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_status (status),
    INDEX idx_user_id (user_id),
    INDEX idx_viewers_count (viewers_count),
    INDEX idx_started_at (started_at),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

---

## 🧪 Testing Checklist

### API Endpoints
- [ ] `GET /api/streams?status=live` returns live streams
- [ ] `GET /api/streams?status=scheduled` returns upcoming streams
- [ ] `POST /api/streams/{id}/join` increments viewer count
- [ ] `POST /api/streams/{id}/leave` decrements viewer count
- [ ] `POST /api/streams/{id}/start` changes status to live
- [ ] `POST /api/streams/{id}/end` changes status to ended

### WebSocket Broadcasting
- [ ] Laravel Reverb server is running
- [ ] Can connect to `ws://server:8080`
- [ ] Public channel `live-streams` accepts connections
- [ ] Viewer count updates broadcast successfully
- [ ] Stream status changes broadcast successfully
- [ ] Frontend receives messages within 100ms

### Real-Time Updates
- [ ] When user joins stream, viewer count updates for all users
- [ ] When stream goes live, it appears in grid for all users
- [ ] When stream ends, it disappears from grid for all users
- [ ] No page refresh needed for updates

---

## 🚀 Production Deployment

### 1. Setup Reverb with Supervisor

```bash
# Create supervisor config
sudo nano /etc/supervisor/conf.d/tajiri-reverb.conf

# Paste config (see Step 6 above)

# Start service
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start tajiri-reverb
```

### 2. Configure Nginx for WebSocket

```nginx
# /etc/nginx/sites-available/tajiri-websocket

server {
    listen 80;
    server_name ws.zima-uat.site;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Important for WebSocket
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/tajiri-websocket /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 3. Update Frontend WebSocket URL

**Frontend** (`lib/config/api_config.dart`):

```dart
class ApiConfig {
  static const String baseUrl = 'https://zima-uat.site:8003/api';
  static const String wsUrl = 'wss://ws.zima-uat.site'; // Production WebSocket URL
}
```

---

## 💡 Performance Tips

### 1. Throttle Viewer Count Updates

```php
// In StreamController::join()
// Only broadcast every 5 seconds to reduce WebSocket traffic

use Illuminate\Support\Facades\Cache;

$cacheKey = "stream_{$stream->id}_last_broadcast";
$lastBroadcast = Cache::get($cacheKey);

if (!$lastBroadcast || now()->diffInSeconds($lastBroadcast) >= 5) {
    broadcast(new StreamViewerCountUpdated(
        $stream->id,
        $stream->viewers_count,
        $stream->peak_viewers
    ));

    Cache::put($cacheKey, now(), 10); // Cache for 10 seconds
}
```

### 2. Use Redis for Viewer Counting

```php
// Instead of database increments, use Redis for speed

use Illuminate\Support\Facades\Redis;

// Join stream
Redis::incr("stream:{$streamId}:viewers");
Redis::sadd("stream:{$streamId}:viewer_ids", $userId);

// Leave stream
Redis::decr("stream:{$streamId}:viewers");
Redis::srem("stream:{$streamId}:viewer_ids", $userId);

// Get count
$viewersCount = (int) Redis::get("stream:{$streamId}:viewers") ?: 0;
```

### 3. Batch Database Updates

```php
// Update database periodically (every 30 seconds) instead of every viewer change

// In a scheduled job (app/Console/Kernel.php)
protected function schedule(Schedule $schedule)
{
    $schedule->call(function () {
        $liveStreams = Stream::where('status', 'live')->get();

        foreach ($liveStreams as $stream) {
            $viewersCount = (int) Redis::get("stream:{$stream->id}:viewers") ?: 0;
            $stream->update(['viewers_count' => $viewersCount]);
        }
    })->everyThirtySeconds();
}
```

---

## ✅ Summary

### Backend Implementation Checklist

- [ ] **Create Events**
  - [ ] `StreamViewerCountUpdated.php`
  - [ ] `StreamStatusChanged.php`

- [ ] **Update Controller**
  - [ ] Add broadcasting to `start()` method
  - [ ] Add broadcasting to `end()` method
  - [ ] Add broadcasting to `join()` method
  - [ ] Add broadcasting to `leave()` method

- [ ] **Configure Broadcasting**
  - [ ] Setup `config/broadcasting.php`
  - [ ] Setup `.env` with Reverb credentials
  - [ ] Setup `routes/channels.php`

- [ ] **Start Reverb Server**
  - [ ] Install Laravel Reverb
  - [ ] Start server: `php artisan reverb:start`
  - [ ] Setup Supervisor for production

- [ ] **Configure Nginx**
  - [ ] Add WebSocket proxy configuration
  - [ ] Enable HTTPS/WSS

- [ ] **Test Everything**
  - [ ] Test API endpoints
  - [ ] Test WebSocket connection
  - [ ] Test real-time updates
  - [ ] Test with multiple clients

---

**Created**: January 28, 2026
**Status**: 📋 **IMPLEMENTATION GUIDE**
**Priority**: 🔴 **HIGH** (Required for viewer experience)
**Effort**: ⏱️ **2-3 hours** (backend team)

**Next**: Implement these backend changes, then the frontend viewer experience will work perfectly! 🚀
