# TAJIRI Livestreaming Integration Guide

## Overview
This guide documents the complete integration of the military-grade livestreaming system into the TAJIRI platform, including video player setup and real-time WebSocket connectivity.

---

## 📦 Required Package

### Add to `pubspec.yaml`

The following package is **required** for WebSocket functionality:

```yaml
dependencies:
  # ... existing dependencies ...

  # WebSocket for real-time livestream updates
  web_socket_channel: ^3.0.1  # ✅ INSTALLED (v3.0.3)
```

**Already Installed** (verified):
- ✅ `video_player: ^2.10.1` - Video playback engine
- ✅ `chewie: ^1.13.0` - Video player UI controls
- ✅ `wakelock_plus: ^1.2.8` - Keep screen awake during streams

### Installation Command

After adding `web_socket_channel` to pubspec.yaml, run:

```bash
flutter pub get
```

---

## 🎯 Implementation Summary

### 1. Video Player Integration ✅

**File Modified**: `lib/screens/streams/stream_viewer_screen.dart`

**Key Features**:
- **HLS Stream Playback**: Automatically constructs HLS URL from stream ID
- **Auto-play on Join**: Video starts immediately when user joins stream
- **Error Handling**: Graceful error display with retry button
- **Loading States**: Shows loading indicator while initializing
- **Custom Controls**: No built-in controls (chat/gifts overlay instead)
- **Screen Wake Lock**: Prevents screen from sleeping during playback
- **Proper Cleanup**: Disposes video controllers on exit

**HLS URL Format**:
```
https://zima-uat.site:8003/live/{stream_id}.m3u8
```

**Usage Example**:
```dart
// Video player initializes automatically in StreamViewerScreen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => StreamViewerScreen(
      stream: liveStream,
      currentUserId: currentUserId,
    ),
  ),
);
```

---

### 2. WebSocket Real-Time Updates ✅

**File Created**: `lib/services/websocket_service.dart`

**Features**:
- **Auto-Reconnection**: Attempts to reconnect up to 5 times with exponential backoff
- **Heartbeat Mechanism**: Sends ping every 30 seconds to keep connection alive
- **Event Broadcasting**: Separate streams for each event type
- **Connection Monitoring**: Notifies UI of connection status changes
- **Graceful Cleanup**: Properly closes connections and cancels timers

**WebSocket URL Format**:
```
wss://zima-uat.site/streams/{stream_id}?user_id={user_id}
```

**Event Types Handled**:

| Event | Description | Data Structure |
|-------|-------------|----------------|
| `viewer_count_updated` | Current and peak viewer counts | `{current_viewers: int, peak_viewers: int}` |
| `new_comment` | Live comment from viewer | `StreamComment` JSON |
| `gift_sent` | Virtual gift sent to streamer | `{sender: User, gift: Gift, quantity: int}` |
| `reaction` | Quick reaction (heart, fire, etc.) | `{user_id: int, reaction_type: string}` |
| `status_changed` | Stream status transition | `{old_status: string, new_status: string}` |
| `ping/pong` | Heartbeat keepalive | `{timestamp: string}` |

---

### 3. Stream Viewer Screen Updates ✅

**Real-Time Features Integrated**:

#### Viewer Count Updates
- Automatically updates viewer count badge in real-time
- No page refresh required

#### Live Comments
- New comments appear instantly in chat overlay
- Auto-scrolls to latest comment
- Smooth animations

#### Gift Animations
- Full-screen animated overlay when gifts are sent
- Shows sender avatar, name, and gift details
- 2-second animation with scale and fade effects
- Purple-pink gradient design

#### Connection Resilience
- Shows snackbar notification if connection drops
- Automatically attempts to reconnect after 3 seconds
- Continues attempting until max retries reached

---

## 🔧 Backend Requirements

### WebSocket Server Setup

The Laravel backend must implement a WebSocket server that:

1. **Accepts Connections**: `wss://zima-uat.site/streams/{stream_id}?user_id={user_id}`
2. **Broadcasts Events**: Sends JSON messages in this format:
   ```json
   {
     "event": "new_comment",
     "data": {
       "id": 123,
       "user": {...},
       "content": "Great stream!",
       "created_at": "2026-01-28T10:30:00Z"
     }
   }
   ```
3. **Handles Client Messages**: Receives JSON messages from clients
4. **Heartbeat Support**: Responds to `ping` with `pong`

### Recommended Laravel Package

**Laravel WebSockets** by BeyondCode:
```bash
composer require beyondcode/laravel-websockets
```

Or **Pusher Channels** (managed service):
```bash
composer require pusher/pusher-php-server
```

### WebSocket Events to Broadcast

```php
// When viewer joins
broadcast(new ViewerJoined($streamId, $userId));

// When new comment posted
broadcast(new CommentPosted($streamId, $comment));

// When gift sent
broadcast(new GiftSent($streamId, $gift, $sender));

// When viewer count changes
broadcast(new ViewerCountUpdated($streamId, $currentCount, $peakCount));

// When stream status changes
broadcast(new StreamStatusChanged($streamId, $oldStatus, $newStatus));
```

---

## 🚀 Usage Guide

### For Developers

#### Starting a Livestream

1. User navigates to "Live" tab in Nyumbani (Home)
2. Sees grid of live and upcoming streams
3. Taps on a live stream card
4. `StreamViewerScreen` opens automatically:
   - Initializes video player with HLS stream
   - Connects to WebSocket for real-time updates
   - Joins stream via REST API (`POST /streams/{id}/join`)
   - Enables screen wake lock

#### Viewing Experience

- **Video**: Fullscreen HLS playback with auto-quality adjustment
- **Chat**: Live comments scroll from bottom, auto-updating
- **Engagement**: Like button, gift button, share button on right side
- **Viewer Count**: Live updating count in top right
- **Host Info**: Streamer name and title in top left
- **Exit**: Close button or back navigation (sends leave event)

#### Real-Time Updates

All updates happen automatically via WebSocket:
- New viewers join → count updates
- Comments posted → appear instantly
- Gifts sent → animated overlay shows
- Stream ends → status change event received

---

## 🎨 UI/UX Features

### Gift Animation

When a gift is received:
1. **Overlay appears** at center-screen
2. **Scales up** from 50% to 100% (0.5s)
3. **Shows**:
   - Sender avatar (circular)
   - Sender name
   - Gift name and quantity
   - Gift icon
4. **Fades out** after 1.5s
5. **Gradient**: Purple-to-pink with glow shadow

### Loading States

- **Video Loading**: "Inapakia mtiririko..." with spinner
- **Connection Lost**: Snackbar with "Muunganisho umepotea..."
- **Video Error**: Error icon + message + "Jaribu Tena" button

### Smooth Transitions

- Chat comments: 300ms ease-out scroll
- Gift animation: 2000ms scale + fade
- Like button: Instant optimistic update

---

## 📊 Performance Optimizations

### Video Player
- Uses native platform players (ExoPlayer on Android, AVPlayer on iOS)
- Adaptive bitrate streaming (HLS handles automatically)
- Hardware acceleration enabled
- Efficient memory management with proper disposal

### WebSocket
- Single persistent connection per stream
- Broadcast streams prevent duplicate listeners
- Automatic reconnection with exponential backoff
- Heartbeat keeps connection alive (reduces reconnect frequency)

### UI Rendering
- Chat uses ListView.builder (lazy loading)
- Gift animations use Overlay (doesn't rebuild entire tree)
- Viewer count updates only rebuild small widget
- RepaintBoundary around video player prevents unnecessary repaints

---

## 🔍 Troubleshooting

### Video Won't Play

**Symptoms**: Black screen, error message, or infinite loading

**Possible Causes**:
1. HLS stream not available at URL
2. Stream not started by broadcaster
3. CORS issues (web platform only)
4. Network connectivity problems

**Solutions**:
- Verify backend is generating HLS stream at correct URL
- Check stream status is `live` (not `scheduled` or `ended`)
- Test HLS URL in VLC player or browser
- Check device internet connection

### WebSocket Connection Fails

**Symptoms**: No real-time updates, connection lost snackbar

**Possible Causes**:
1. WebSocket server not running
2. Firewall blocking WSS connections
3. SSL certificate issues
4. Backend not broadcasting events

**Solutions**:
- Verify WebSocket server is running: `wss://zima-uat.site/streams/test`
- Check SSL certificate is valid for domain
- Review Laravel logs for WebSocket errors
- Test broadcast events manually

### Comments Not Appearing

**Symptoms**: Comments sent but don't show in real-time

**Possible Causes**:
1. WebSocket not connected
2. Backend not broadcasting `new_comment` event
3. Comment API failing silently

**Solutions**:
- Check connection status via debug logs
- Verify backend is broadcasting after comment saved
- Test API endpoint directly: `POST /streams/{id}/comments`

---

## 🧪 Testing Checklist

### Manual Testing

- [ ] Video plays immediately on joining stream
- [ ] Viewer count updates when others join/leave
- [ ] Comments appear in real-time
- [ ] Sending comment works and appears instantly
- [ ] Like button toggles correctly
- [ ] Gifts can be sent and animation shows
- [ ] Screen stays awake during viewing
- [ ] Back button exits gracefully
- [ ] Connection lost notification appears when network drops
- [ ] Auto-reconnect works after network restored
- [ ] Video error state shows retry button
- [ ] Multiple streams can be viewed sequentially

### Performance Testing

- [ ] Video plays smoothly at 60fps
- [ ] No memory leaks when joining/leaving multiple times
- [ ] WebSocket reconnection doesn't cause crashes
- [ ] Gift animations don't block UI
- [ ] Chat scrolling is smooth with 100+ comments

### Edge Cases

- [ ] Stream ends while watching (status change event)
- [ ] Network interrupted mid-stream
- [ ] App backgrounded and resumed
- [ ] Low bandwidth scenarios
- [ ] Expired or invalid stream ID

---

## 📝 Implementation Notes

### Why Chewie?

Chewie wraps `video_player` with:
- Cross-platform consistency
- Better error handling
- Easy customization of controls
- Fullscreen support built-in

### Why web_socket_channel?

- Official Flutter team package
- Reliable and well-maintained
- Simple API
- Works across all platforms
- No external service dependencies

### Alternative: Pusher Channels

If preferred, can use `pusher_channels_flutter` instead:

**Pros**:
- Managed service (no server maintenance)
- Automatic scaling
- Built-in presence channels

**Cons**:
- Requires paid Pusher account
- External dependency
- Less control

**Migration Path**:
Replace `web_socket_channel` with `pusher_channels_flutter: ^2.2.1` and update `websocket_service.dart` to use Pusher client.

---

## 🎯 Next Steps

### Immediate (Required for Production)

1. **Add `web_socket_channel` package** to pubspec.yaml
2. **Set up WebSocket server** on Laravel backend
3. **Configure broadcasting** for all livestream events
4. **Test HLS streams** are accessible at correct URLs
5. **Deploy WebSocket server** to production

### Future Enhancements

1. **Picture-in-Picture**: Continue watching while browsing app
2. **Quality Selector**: Let users choose stream quality manually
3. **DVR Mode**: Pause/rewind live streams (if HLS DVR enabled)
4. **Co-Host Support**: Multi-camera livestreams
5. **Screen Sharing**: Streamers can share screen
6. **Landscape Mode**: Rotate for fullscreen viewing
7. **Analytics**: Track watch time, engagement metrics
8. **Moderation**: Block users, delete comments in real-time

---

## 🔗 Related Documentation

- [BACKEND_REQUIREMENTS.md](./BACKEND_REQUIREMENTS.md) - Complete backend API specification
- [LIVESTREAMING_IMPLEMENTATION.md](./LIVESTREAMING_IMPLEMENTATION.md) - System architecture and design

---

## 💡 Tips for Backend Developers

### Optimizing HLS Delivery

1. **Use CDN**: Serve .m3u8 and .ts files from CDN for global reach
2. **Adaptive Bitrate**: Generate multiple quality levels (360p, 720p, 1080p)
3. **Low Latency**: Use LL-HLS (Low-Latency HLS) for < 3 second delay
4. **Caching**: Cache manifests with short TTL (2-6 seconds)

### WebSocket Best Practices

1. **Authentication**: Verify user token on connection
2. **Rate Limiting**: Prevent spam (max 5 comments/min)
3. **Broadcasting**: Use Redis for pub/sub (scales horizontally)
4. **Monitoring**: Track connection count, message throughput
5. **Graceful Shutdown**: Close connections before server restart

### Database Optimization

1. **Viewer Counts**: Use Redis counter (don't hit DB on every join/leave)
2. **Comments**: Paginate API, broadcast only new ones
3. **Gifts**: Process async (queue job for analytics)
4. **Indexes**: Add indexes on `stream_id` and `created_at` columns

---

**Generated**: 2026-01-28
**Platform**: TAJIRI Flutter App
**Status**: Ready for Integration
**Backend**: Laravel 10+ with WebSocket support required
