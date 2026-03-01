# TAJIRI Architecture

## Project Structure #architecture

**Date**: 2026-01-28
**Context**: Overall codebase organization

**Structure**:
```
lib/
├── main.dart                 # App entry point, routing
├── config/                   # Configuration files
├── models/                   # Data models (24 files)
│   ├── user_models.dart
│   ├── post_models.dart
│   ├── story_models.dart
│   ├── clip_models.dart
│   ├── message_models.dart
│   ├── conversation_models.dart
│   └── ... (18 more)
├── screens/                  # UI screens (59 files)
│   ├── home/
│   ├── feed/
│   ├── messages/
│   ├── friends/
│   ├── photos/
│   ├── music/
│   ├── calls/
│   ├── settings/
│   ├── splash/
│   └── registration/
├── services/                 # Business logic (33 files)
│   ├── api_service.dart
│   ├── local_storage_service.dart
│   ├── auth_service.dart
│   ├── feed_service.dart
│   └── ... (29 more)
└── widgets/                  # Reusable UI components
```

**Key lesson**: Three-layer architecture: Models (data), Services (logic), Screens (UI). Widgets for shared components.
**Tags**: #architecture #structure

---

## Data Flow #architecture

**Date**: 2026-01-28
**Context**: How data moves through the app

**Flow**:
1. **UI Layer** (Screens) - User interactions
2. **Service Layer** - Business logic, API calls
3. **Storage Layer** - Local cache (Hive), Remote API
4. **Model Layer** - Data structures

**Pattern**:
- Screen calls Service method
- Service checks Cache (LocalStorage)
- If miss, Service calls API
- Service updates Cache
- Service returns to Screen
- Screen updates UI

**Key lesson**: Screens never call API directly. Always go through Services. Services manage cache.
**Tags**: #architecture #dataflow

---

## Offline-First Architecture #architecture

**Date**: 2026-01-28
**Context**: Design for offline-first experience

**Principles**:
1. **Read**: Always try cache first, fetch from API in background
2. **Write**: Queue locally, sync when online
3. **Sync**: Periodic sync of queued actions
4. **Conflict**: Last-write-wins or server-authoritative

**Implementation**:
- LocalStorageService for all cache operations
- SyncService for background sync
- Queue pending actions in Hive
- Network status monitoring

**Key lesson**: App should work fully offline. User should never see "no internet" blocking them.
**Tags**: #architecture #offline #sync

---

## Security Architecture #architecture

**Date**: 2026-01-28
**Context**: Authentication and data security

**Security layers**:
1. **Auth**: Token-based authentication
2. **Storage**: Sensitive data in Hive (encrypted)
3. **API**: HTTPS only, token in headers
4. **Validation**: Input sanitization, XSS prevention

**Auth flow**:
- User logs in → Server returns token
- Store token in LocalStorage (secure)
- Include token in all API requests
- Refresh token before expiry
- Clear token on logout

**Key lesson**: Never log tokens. Use HTTPS. Encrypt local storage. Validate all inputs.
**Tags**: #architecture #security #auth

---

## Performance Architecture #architecture

**Date**: 2026-01-28
**Context**: Optimization strategies

**Strategies**:
1. **Images**: cached_network_image with memory/disk cache
2. **Lists**: ListView.builder for virtualization
3. **State**: const widgets, minimize rebuilds
4. **API**: Debounce calls, batch requests
5. **Memory**: Dispose controllers, clear caches

**Monitoring**:
- Profile with Flutter DevTools
- Monitor memory usage
- Track API latency
- Measure frame rate (60fps target)

**Key lesson**: Profile on low-end devices. Optimize for 60fps. Monitor memory leaks.
**Tags**: #architecture #performance #optimization

---

## API Architecture #architecture

**Date**: 2026-01-28
**Context**: Backend API integration

**API Design**:
- RESTful endpoints
- JSON payloads
- Token authentication
- Pagination (cursor-based)
- Error responses with codes

**ApiService pattern**:
```dart
class ApiService {
  Future<T> get<T>(String endpoint);
  Future<T> post<T>(String endpoint, Map data);
  Future<T> put<T>(String endpoint, Map data);
  Future<T> delete<T>(String endpoint);
}
```

**Key lesson**: Centralize all API calls in ApiService. Handle auth, errors, retries in one place.
**Files**: `lib/services/api_service.dart`
**Tags**: #architecture #api #rest

---

## Real-Time Architecture #architecture

**Date**: 2026-01-28
**Context**: Live updates for messages, notifications

**Real-time tech**:
- **WebSocket**: Bi-directional (chat, typing indicators)
- **SSE**: Server-push (notifications, feed updates)
- **Polling**: Fallback (presence, online status)

**MessageService pattern**:
- Connect WebSocket on app start
- Listen for incoming messages
- Send via WebSocket.sink
- Reconnect on disconnect
- Queue messages when offline

**Key lesson**: Use WebSocket for instant messaging. Implement reconnection logic. Handle offline gracefully.
**Expected files**: `lib/services/message_service.dart`
**Tags**: #architecture #realtime #websocket

---

## Media Architecture #architecture

**Date**: 2026-01-28
**Context**: Photos, videos, music handling

**Media pipeline**:
1. **Capture/Pick**: Camera or gallery
2. **Compress**: Reduce file size
3. **Upload**: Progressive with progress
4. **Process**: Server-side (thumbnails, transcoding)
5. **Deliver**: CDN with caching

**Local handling**:
- Image: cached_network_image
- Video: video_player with caching
- Audio: audioplayers with streaming

**Key lesson**: Always compress before upload. Use CDN for delivery. Cache aggressively. Generate thumbnails.
**Expected files**: `lib/services/media_service.dart`
**Tags**: #architecture #media #cdn

---

## Testing Architecture #architecture

**Date**: 2026-01-28
**Context**: Testing strategy

**Test pyramid**:
1. **Unit Tests**: Models, Services (70%)
2. **Widget Tests**: UI components (20%)
3. **Integration Tests**: E2E flows (10%)

**Focus areas**:
- API service methods
- Local storage operations
- Business logic in services
- Critical user flows

**Key lesson**: Test services heavily. Mock API calls. Test offline scenarios. Automate critical flows.
**Tags**: #architecture #testing #quality

---

## Scaling Considerations #architecture

**Date**: 2026-01-28
**Context**: Preparing for growth

**Scale strategies**:
1. **Caching**: Aggressive client-side caching
2. **Pagination**: Cursor-based, not offset
3. **Lazy Loading**: Load content on-demand
4. **Image Optimization**: WebP, progressive JPEG
5. **Code Splitting**: Feature-based modules

**Monitoring**:
- Track API latency
- Monitor crash rates
- Measure engagement metrics
- User feedback collection

**Key lesson**: Build for scale from day one. Monitor everything. Optimize based on data.
**Tags**: #architecture #scaling #monitoring

---

## Deployment Architecture #architecture

**Date**: 2026-01-28
**Context**: Build and release process

**Environments**:
- **Development**: Local testing
- **Staging**: Pre-production testing
- **Production**: Live users

**Build process**:
1. Run tests
2. Build APK/IPA
3. Version bump
4. Deploy to stores
5. Monitor rollout

**Key lesson**: Automate builds. Use staged rollouts. Monitor crash rates post-deploy.
**Tags**: #architecture #deployment #cicd