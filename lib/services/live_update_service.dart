import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Event types emitted when backend data changes (Firestore is used as a notification channel).
/// Backend writes to Firestore on DB change; app refetches from REST API and updates UI instantly.
sealed class LiveUpdateEvent {
  const LiveUpdateEvent();
}

/// Feed or stories changed — refresh feed list / stories.
class FeedUpdateEvent extends LiveUpdateEvent {
  const FeedUpdateEvent();
}

/// A specific post changed (like, comment, etc.) — refresh that post.
class PostUpdateEvent extends LiveUpdateEvent {
  final int postId;
  const PostUpdateEvent(this.postId);
}

/// User profile or followers changed — refresh profile.
class ProfileUpdateEvent extends LiveUpdateEvent {
  final int? userId;
  const ProfileUpdateEvent([this.userId]);
}

/// Messages or conversations changed — refresh chat list or conversation.
class MessagesUpdateEvent extends LiveUpdateEvent {
  final int? conversationId;
  const MessagesUpdateEvent([this.conversationId]);
}

/// Stories row changed (friend posted or deleted a story) — refresh stories list.
class StoriesUpdateEvent extends LiveUpdateEvent {
  const StoriesUpdateEvent();
}

/// Global live-update service: listens to Firestore `updates/{userId}` and broadcasts events
/// so the UI can refetch from the REST API and update instantly.
class LiveUpdateService {
  LiveUpdateService._();
  static final LiveUpdateService instance = LiveUpdateService._();

  final _controller = StreamController<LiveUpdateEvent>.broadcast();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;
  int? _currentUserId;
  /// Deduplicate: ignore snapshot if ts unchanged (e.g. app restart).
  int? _lastSeenTs;
  /// Track permission errors to avoid spamming retries.
  bool _permissionDenied = false;

  /// Stream of live-update events. Screens listen and refetch as needed.
  Stream<LiveUpdateEvent> get stream => _controller.stream;

  bool get isActive => _currentUserId != null && _subscription != null;

  /// Start listening for updates for this user. Call after login.
  void start(int userId) {
    if (_currentUserId == userId) return;
    stop();
    _currentUserId = userId;

    if (Firebase.apps.isEmpty) {
      if (kDebugMode) debugPrint('[LiveUpdate] Firebase not initialized; live updates disabled.');
      return;
    }

    if (_permissionDenied) {
      if (kDebugMode) debugPrint('[LiveUpdate] Skipped — Firestore permission denied (requires Firebase rules update)');
      return;
    }

    try {
      final doc = FirebaseFirestore.instance.collection('updates').doc(userId.toString());
      _subscription = doc.snapshots().listen(
        _onSnapshot,
        onError: (e) {
          final msg = e.toString();
          if (msg.contains('permission-denied')) {
            _permissionDenied = true;
            _subscription?.cancel();
            _subscription = null;
            if (kDebugMode) debugPrint('[LiveUpdate] Firestore permission denied — live updates disabled until app restart. Backend needs to update Firebase security rules for the "updates" collection.');
          } else {
            if (kDebugMode) debugPrint('[LiveUpdate] Listen error: $e');
          }
        },
      );
      if (kDebugMode) debugPrint('[LiveUpdate] Listening for user $userId');
    } catch (e) {
      if (kDebugMode) debugPrint('[LiveUpdate] Start failed: $e');
      _currentUserId = null;
    }
  }

  void _onSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    if (!snapshot.exists || snapshot.data() == null) return;
    final data = snapshot.data()!;
    final ts = data['ts'];
    final tsInt = ts is int ? ts : (ts is num ? ts.toInt() : null);
    if (tsInt != null && tsInt == _lastSeenTs) return;
    _lastSeenTs = tsInt;

    final event = data['event'] as String?;
    final payload = data['payload'] is Map ? data['payload'] as Map<String, dynamic>? : null;
    final postId = payload?['post_id'] ?? payload?['postId'];

    LiveUpdateEvent? ev;
    switch (event) {
      case 'feed_updated':
        ev = const FeedUpdateEvent();
        break;
      case 'post_updated':
        if (postId != null) ev = PostUpdateEvent((postId is int) ? postId : int.tryParse(postId.toString()) ?? 0);
        break;
      case 'profile_updated':
      case 'followers_updated':
        ev = const ProfileUpdateEvent();
        break;
      case 'messages_updated':
        final convId = payload?['conversation_id'] ?? payload?['conversationId'];
        ev = MessagesUpdateEvent(convId is int ? convId : (convId != null ? int.tryParse(convId.toString()) : null));
        break;
      case 'stories_updated':
        ev = const StoriesUpdateEvent();
        break;
      default:
        if (event != null && event.isNotEmpty) {
          ev = const FeedUpdateEvent();
        }
    }
    if (ev != null && _controller.hasListener) {
      _controller.add(ev);
    }
  }

  /// Stop listening. Call on logout.
  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _currentUserId = null;
    _lastSeenTs = null;
    if (kDebugMode) debugPrint('[LiveUpdate] Stopped');
  }

  /// Dispose the stream controller (e.g. on app shutdown).
  void dispose() {
    stop();
    _controller.close();
  }
}
