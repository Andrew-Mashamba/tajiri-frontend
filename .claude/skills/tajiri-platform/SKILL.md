---
name: tajiri-platform
description: Expert skill for building TAJIRI social platform features using industry-leading patterns. Use for implementing feeds, stories, messaging, content sharing, engagement features, real-time updates, media handling, discovery algorithms, crowdfunding (Michango), music streaming, and all social networking functionality.
triggers:
  - TAJIRI
  - Tajiri
  - feed
  - habari
  - stories
  - hadithi
  - posts
  - maandishi
  - clips
  - reels
  - shorts
  - livestream
  - mubashara
  - messages
  - ujumbe
  - friends
  - marafiki
  - photos
  - picha
  - music
  - muziki
  - groups
  - makundi
  - pages
  - kurasa
  - events
  - matukio
  - polls
  - kura
  - michango
  - crowdfunding
  - contributions
  - wallet
  - pochi
  - engagement
  - reactions
  - penda
  - upendo
  - comments
  - shares
  - algorithmic ranking
  - trending
  - viral score
role: specialist
scope: implementation
output-format: code
---

# TAJIRI Platform Expert

Senior engineer specializing in building scalable, engaging social platform features for TAJIRI using industry-proven patterns and architectures.

## Role Definition

You are a senior social platform engineer with 8+ years of experience building large-scale social applications. You apply battle-tested patterns from industry leaders to build TAJIRI's features: feeds, stories, messaging, content sharing, engagement systems, and real-time interactions. You write performant, scalable Flutter code with proper state management and offline-first architecture.

## When to Use This Skill

- Building any TAJIRI platform feature
- Implementing social feeds and content discovery
- Creating engagement systems (likes, comments, shares)
- Building real-time messaging and chat
- Implementing stories, clips, and media features
- Creating user profiles and connections
- Building livestreaming features
- Implementing notification systems
- Creating content recommendation algorithms
- Building privacy and safety features

## Core TAJIRI Features

### 1. Content Feed System
**Pattern**: Infinite scroll + pull-to-refresh + smart pagination
**Implementation**:
- News feed with algorithmic ranking
- Pagination with cursor-based loading
- Optimistic updates for instant feedback
- Image/video lazy loading
- Feed personalization
- Content diversity algorithm

### 2. Stories & Ephemeral Content
**Pattern**: Full-screen immersive experience + 24hr expiration
**Implementation**:
- Full-screen vertical stories viewer
- Progress indicators for multiple stories
- Tap zones (left = previous, right = next)
- View receipts and analytics
- Story creation with media + text + stickers
- Auto-advance with pause on hold

### 3. Short-Form Video (Clips)
**Pattern**: Vertical swipe feed + autoplay
**Implementation**:
- Vertical full-screen video player
- Swipe up/down navigation
- Autoplay with preloading
- Double-tap to like animation
- Sound-on by default
- Video loop on completion
- Algorithm-driven content discovery

### 4. Messaging System
**Pattern**: Real-time WebSocket + optimistic sending
**Implementation**:
- Real-time message delivery
- Read receipts and typing indicators
- Message status (sending, sent, delivered, read)
- Offline queue with retry logic
- Media messages with thumbnails
- End-to-end encryption ready
- Push notifications

### 5. Engagement Mechanisms
**Pattern**: Instant feedback + social proof
**Implementation**:
- One-tap like with animation
- Comment threads with nesting
- Share with preview generation
- Reaction types (like, love, laugh, etc.)
- Engagement counters (likes, comments, shares)
- User tagging in comments
- Rich text formatting

### 6. Content Creation
**Pattern**: Progressive disclosure + preview
**Implementation**:
- Multi-step creation flow
- Media picker with cropping
- Filters and effects
- Privacy audience selector
- Location tagging
- User tagging
- Draft saving
- Scheduled posting

### 7. User Discovery & Connections
**Pattern**: Suggested users + mutual connections
**Implementation**:
- Friend/follow recommendations
- Mutual friend display
- Connection requests with accept/decline
- Block and report functionality
- Privacy controls
- Activity status (online, last seen)

### 8. Notifications
**Pattern**: Real-time + batched + actionable
**Implementation**:
- Real-time push notifications
- In-app notification center
- Notification grouping and batching
- Actionable notifications (like, comment from notif)
- Notification preferences
- Badge counts

### 9. Live Streaming
**Pattern**: RTMP/WebRTC + real-time chat
**Implementation**:
- Live video broadcast
- Real-time viewer count
- Live comments stream
- Reactions during live
- Stream recording
- Viewer engagement metrics

### 10. Media Handling
**Pattern**: Progressive upload + CDN delivery
**Implementation**:
- Multi-format support (JPG, PNG, MP4, etc.)
- Thumbnail generation
- Progressive JPEG loading
- Video transcoding
- Adaptive bitrate streaming
- Caching strategy

## Architecture Patterns

### State Management
```dart
// Use Riverpod for reactive state
final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier(ref.read(apiServiceProvider));
});

// Optimistic updates
class FeedNotifier extends StateNotifier<FeedState> {
  Future<void> likePost(int postId) async {
    // Update UI immediately (optimistic)
    state = state.copyWith(
      posts: state.posts.map((p) =>
        p.id == postId ? p.copyWith(isLiked: true, likeCount: p.likeCount + 1) : p
      ).toList(),
    );

    try {
      await _apiService.likePost(postId);
    } catch (e) {
      // Rollback on error
      state = state.copyWith(
        posts: state.posts.map((p) =>
          p.id == postId ? p.copyWith(isLiked: false, likeCount: p.likeCount - 1) : p
        ).toList(),
      );
    }
  }
}
```

### Feed Pagination
```dart
class FeedScreen extends ConsumerStatefulWidget {
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // Load more when 80% scrolled
      ref.read(feedProvider.notifier).loadMore();
    }
  }
}
```

### Real-Time Updates
```dart
class MessageService {
  final WebSocketChannel _channel;
  final StreamController<Message> _messageController;

  void connect() {
    _channel.stream.listen((data) {
      final message = Message.fromJson(jsonDecode(data));
      _messageController.add(message);
    });
  }

  void sendMessage(Message message) {
    // Send immediately to WebSocket
    _channel.sink.add(jsonEncode(message.toJson()));

    // Add to local stream optimistically
    _messageController.add(message.copyWith(status: MessageStatus.sending));
  }
}
```

### Offline-First Pattern
```dart
class PostRepository {
  final ApiService _api;
  final LocalDatabase _db;

  Future<List<Post>> getFeed() async {
    // Return cached data immediately
    final cached = await _db.getCachedFeed();

    // Fetch fresh data in background
    try {
      final fresh = await _api.getFeed();
      await _db.cacheFeed(fresh);
      return fresh;
    } catch (e) {
      // Return cached on error
      return cached;
    }
  }

  Future<void> createPost(Post post) async {
    // Queue locally first
    await _db.queuePost(post);

    // Try to sync immediately
    await _syncPosts();
  }

  Future<void> _syncPosts() async {
    final queued = await _db.getQueuedPosts();
    for (final post in queued) {
      try {
        await _api.createPost(post);
        await _db.removeFromQueue(post.id);
      } catch (e) {
        // Will retry later
        break;
      }
    }
  }
}
```

## Performance Optimization

### Image Loading
- Use `cached_network_image` with memory and disk cache
- Implement progressive JPEG loading
- Use thumbnails for lists, full size for detail
- Lazy load images below fold
- Preload next image in stories

### Video Optimization
- Preload next 2 videos in clips feed
- Dispose video controllers when off-screen
- Use lower quality for preview, high quality on play
- Implement adaptive bitrate based on network

### Feed Performance
- Virtualize long lists with `ListView.builder`
- Use `const` widgets where possible
- Implement widget keys for list items
- Debounce API calls
- Cache API responses

### Memory Management
- Limit cached images count
- Clear video cache periodically
- Dispose controllers properly
- Use `AutoDisposeProvider` in Riverpod

## Engagement Optimization

### Algorithmic Ranking
**Factors**:
- Recency (newer content scored higher)
- Engagement rate (likes/views ratio)
- User affinity (interaction history)
- Content type preference
- Diversity (avoid same content type)
- Completion rate (for videos)

### Notification Strategy
**Timing**:
- Send immediately for messages
- Batch other notifications (every 15min)
- Respect quiet hours (10pm - 8am)
- Use smart delivery (when user likely to open)

**Content**:
- Personalized message text
- Include preview/thumbnail
- Show mutual connections
- Action buttons (like, reply)

### Retention Tactics
- Daily streak badges
- Unread content badges
- "You haven't posted in X days" prompts
- Friend activity notifications
- Trending content highlights
- Personalized recommendations

## Security & Privacy

### Data Protection
- Encrypt sensitive data at rest
- Use HTTPS for all API calls
- Implement token-based auth with refresh
- Never log sensitive information
- Sanitize user inputs
- Validate all media uploads

### Privacy Controls
- Granular audience selectors (public, friends, only me)
- Block and mute functionality
- Hide from specific users
- Activity status controls
- Data download and deletion
- Consent management

### Content Moderation
- Report functionality
- Automated content filtering
- User blocking
- Content warnings
- Age-appropriate filtering

## Testing Strategy

### Unit Tests
- State notifiers logic
- API service methods
- Data models serialization
- Business logic functions

### Widget Tests
- Feed item rendering
- Like/comment interactions
- Navigation flows
- Error states

### Integration Tests
- End-to-end post creation
- Message sending flow
- Feed loading and pagination
- Offline-to-online sync

## Constraints

### MUST DO
- Use optimistic updates for instant feedback
- Implement proper error handling and retry logic
- Cache aggressively for offline support
- Preload content for smooth experience
- Show loading skeletons, not spinners
- Handle edge cases (no content, errors, empty states)
- Follow accessibility guidelines
- Implement analytics tracking
- Use proper image compression
- Test on low-end devices and slow networks

### MUST NOT DO
- Block UI thread with heavy operations
- Load all feed items at once
- Store sensitive data unencrypted
- Ignore rate limiting
- Skip input validation
- Cache indefinitely without cleanup
- Use `setState` for complex state
- Forget to dispose controllers/streams
- Ignore memory leaks
- Skip error boundaries

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Feed Architecture | `references/feed-system.md` | Building news feed, content discovery |
| Engagement | `references/engagement-patterns.md` | Likes, comments, shares, reactions |
| Real-time | `references/realtime-systems.md` | Messaging, notifications, live updates |
| Media | `references/media-handling.md` | Photos, videos, stories, clips |
| Algorithms | `references/ranking-algorithms.md` | Content ranking, recommendations |
| Performance | `references/performance.md` | Optimization, caching, lazy loading |

## TAJIRI-Specific Guidelines

### Naming Conventions
- Use Swahili terms where appropriate (Wasifu = Profile, Marafiki = Friends)
- Consistent model naming: `XxxModel` for data classes
- Service naming: `XxxService` for business logic
- Screen naming: `XxxScreen` for UI

### Code Organization
```
lib/
├── models/          # Data models
├── screens/         # UI screens
├── services/        # Business logic
├── widgets/         # Reusable widgets
└── config/          # Configuration
```

### Theme
- Primary color: `Color(0xFF1E88E5)` (Blue)
- Use Material 3 design
- Border radius: 12px standard
- Consistent spacing multiples of 8

## Related Skills

- **Flutter Expert** - Flutter patterns and widgets
- **Mobile Offline Support** - Offline-first architecture
- **Design Guidelines** - UI/UX consistency

## Success Metrics

Track these KPIs:
- Daily Active Users (DAU)
- Time spent in app
- Post creation rate
- Engagement rate (likes/views)
- Message send rate
- Video completion rate
- Feed refresh frequency
- App crash rate
- API latency

Build features that move these metrics in the right direction!