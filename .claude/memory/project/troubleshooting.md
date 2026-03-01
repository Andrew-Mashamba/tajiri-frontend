# TAJIRI Troubleshooting Guide

## Hive Initialization Error #issue
**Date**: 2026-01-28
**Context**: App crashes on startup with Hive error

**Problem**: Hive not initialized before use
**Solution**: Ensure `await Hive.initFlutter()` called in main() before runApp()
**Prevention**: Always initialize async services before app starts

**Files**: `lib/main.dart:18`
**Tags**: #hive #initialization #error

---

## currentUserId is null #issue
**Date**: 2026-01-28
**Context**: Screens crash when accessing user data

**Problem**: User not logged in or session expired
**Solution**: Check `LocalStorageService.getUser()` returns valid user. Redirect to login if null.
**Prevention**: Wrap authenticated routes in auth check

**Pattern**:
```dart
final user = storage.getUser();
if (user == null) {
  Navigator.pushReplacementNamed(context, '/login');
  return;
}
```

**Tags**: #auth #null #error

---

## Images Not Loading #issue
**Date**: 2026-01-28
**Context**: Network images show placeholder

**Problem**: HTTPS URLs blocked or cache issues
**Solution**:
1. Check internet connectivity
2. Verify image URLs are valid
3. Clear image cache if needed
4. Add error handling with placeholder

**Prevention**: Always provide placeholder and error widgets for images

**Tags**: #images #network #cache

---

## Offline Data Not Syncing #issue
**Date**: 2026-01-28
**Context**: Actions performed offline not reflected when online

**Problem**: Sync service not running or queue not processing
**Solution**:
1. Check network status detection
2. Verify sync service is running
3. Check queue in LocalStorage
4. Manually trigger sync

**Prevention**: Implement robust sync logic with retry and error handling

**Tags**: #offline #sync #queue

---

## Scroll Performance Issues #issue
**Date**: 2026-01-28
**Context**: Feed scroll is janky

**Problem**: Too many widgets rebuilding or images not cached
**Solution**:
1. Use `const` constructors
2. Implement `ListView.builder` for virtualization
3. Add proper keys to list items
4. Use cached_network_image
5. Profile with DevTools

**Prevention**: Profile on low-end devices. Keep build methods light.

**Tags**: #performance #scroll #jank

---

## Video Not Playing #issue
**Date**: 2026-01-28
**Context**: Video player shows black screen

**Problem**: Controller not initialized or format unsupported
**Solution**:
1. Initialize VideoPlayerController before use
2. Check video format (MP4 recommended)
3. Dispose controller properly
4. Handle errors with try-catch

**Prevention**: Always initialize and dispose video controllers properly

**Tags**: #video #player #error

---

## Memory Leak #issue
**Date**: 2026-01-28
**Context**: App memory usage increases over time

**Problem**: Controllers/listeners not disposed
**Solution**:
1. Dispose all controllers in dispose()
2. Cancel stream subscriptions
3. Clear image caches periodically
4. Use AutoDisposeProvider in Riverpod

**Prevention**: Always dispose resources. Profile memory usage regularly.

**Tags**: #memory #leak #performance

---

## API Timeout #issue
**Date**: 2026-01-28
**Context**: API calls fail with timeout

**Problem**: Network slow or server unresponsive
**Solution**:
1. Increase timeout duration
2. Implement retry logic
3. Show loading indicator
4. Fallback to cached data

**Prevention**: Set reasonable timeouts. Always cache API responses.

**Pattern**:
```dart
try {
  final response = await api.get('/feed')
    .timeout(Duration(seconds: 30));
} on TimeoutException {
  // Return cached data
  return await cache.getFeed();
}
```

**Tags**: #api #timeout #network

---

## Push Notifications Not Working #issue
**Date**: 2026-01-28
**Context**: Notifications not received

**Problem**: FCM token not registered or permissions denied
**Solution**:
1. Request notification permission
2. Register FCM token with server
3. Handle token refresh
4. Test on physical device (not simulator)

**Prevention**: Check permissions on app start. Handle token updates.

**Tags**: #notifications #fcm #permissions

---

## Build Fails on iOS #issue
**Date**: 2026-01-28
**Context**: Flutter build ios fails

**Problem**: Pods outdated or signing issues
**Solution**:
1. Run `pod install` in ios/
2. Update CocoaPods: `pod repo update`
3. Clean build: `flutter clean`
4. Check signing in Xcode

**Prevention**: Keep dependencies updated. Use proper signing certificates.

**Tags**: #ios #build #pods

---

## State Not Updating #issue
**Date**: 2026-01-28
**Context**: UI doesn't reflect data changes

**Problem**: setState not called or provider not notifying
**Solution**:
1. Call setState() after state changes
2. Use state.copyWith() for immutable updates
3. Notify listeners in Riverpod providers
4. Check widget rebuild conditions

**Prevention**: Use proper state management. Profile widget rebuilds.

**Tags**: #state #ui #update

---

## Database Migration Failed #issue
**Date**: 2026-01-28
**Context**: App crashes after Hive schema change

**Problem**: Stored data incompatible with new schema
**Solution**:
1. Delete Hive boxes: `await Hive.deleteBoxFromDisk('boxName')`
2. Clear app data (development only)
3. Implement migration logic
4. Version your schemas

**Prevention**: Plan schema changes. Implement migrations. Test thoroughly.

**Tags**: #hive #migration #schema

---

## Route Not Found #issue
**Date**: 2026-01-28
**Context**: Navigation fails with "Route not found"

**Problem**: Route not defined in onGenerateRoute
**Solution**:
1. Check route name spelling
2. Add route case in onGenerateRoute
3. Provide fallback route
4. Use named constants for routes

**Prevention**: Use route constants. Always provide fallback.

**Files**: `lib/main.dart:48-189`
**Tags**: #routing #navigation #error

---

## Text Overflow #issue
**Date**: 2026-01-28
**Context**: Text gets cut off with yellow/black stripes

**Problem**: Text too long for container
**Solution**:
1. Wrap Text in Expanded or Flexible
2. Set maxLines with overflow: TextOverflow.ellipsis
3. Use SingleChildScrollView for long text
4. Responsive design with MediaQuery

**Prevention**: Always handle long text. Test with various text lengths.

**Tags**: #ui #text #overflow

---

## Hot Reload Not Working #issue
**Date**: 2026-01-28
**Context**: Changes not appearing after hot reload

**Problem**: Stateful widget state preserved or const changes
**Solution**:
1. Use hot restart (not reload)
2. Check if widget is const
3. Verify code saved
4. Restart IDE if necessary

**Prevention**: Understand hot reload limitations. Use hot restart for significant changes.

**Tags**: #development #hotreload #flutter