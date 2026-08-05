// lib/services/stream_deep_link_service.dart
//
// Phase G — universal/app-link handler for stream URLs.
//
// Routes incoming URIs of the form
//   https://tajiri.zimasystems.com/streams/{id}?share_uid=...&from=tiktok&via=11
// into StreamViewerScreen with attribution args populated:
//   - shareUid           → fires view_from_share·sharer on join
//   - crossPostSharerId  → from `via` param
//   - crossPostPlatform  → from `from` param (fires cross_post_view·sharer)
//
// Wire-up:
//   1) Call StreamDeepLinkService.attach(navigatorKey) once after the
//      app has a navigator (init() in TajiriApp).
//   2) iOS: register associated domain `applinks:tajiri.zimasystems.com`.
//   3) Android: intent-filter on the launcher activity for the host.
//
// On platforms where app_links isn't supported, the listener no-ops.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import '../services/livestream_service.dart';
import '../services/local_storage_service.dart';
import '../screens/clips/streamviewer_screen.dart';

class StreamDeepLinkService {
  StreamDeepLinkService._();
  static final StreamDeepLinkService _instance = StreamDeepLinkService._();
  factory StreamDeepLinkService() => _instance;

  final AppLinks _appLinks = AppLinks();
  final LiveStreamService _streamService = LiveStreamService();
  StreamSubscription<Uri>? _uriSub;
  GlobalKey<NavigatorState>? _navKey;
  bool _attached = false;

  /// Attach the listener. Idempotent — safe to call from initState.
  Future<void> attach(GlobalKey<NavigatorState> navKey) async {
    if (_attached) return;
    _attached = true;
    _navKey = navKey;

    // Cold start — link that launched the app.
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handle(initial);
    } catch (_) { /* platform unsupported — silently no-op */ }

    // Warm starts.
    _uriSub = _appLinks.uriLinkStream.listen(
      (uri) => _handle(uri),
      onError: (_) { /* swallow — never crash the app over a bad URI */ },
    );
  }

  Future<void> dispose() async {
    await _uriSub?.cancel();
    _uriSub = null;
    _attached = false;
  }

  void _handle(Uri uri) async {
    // Only handle our own host.
    if (uri.host != 'tajiri.zimasystems.com' &&
        uri.host != 'www.tajiri.zimasystems.com') {
      return;
    }
    // Path: /streams/{id}
    final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segs.length < 2 || segs[0] != 'streams') return;
    final streamId = int.tryParse(segs[1]);
    if (streamId == null) return;

    final shareUid = uri.queryParameters['share_uid'];
    final platform = uri.queryParameters['from']; // tiktok|instagram|...
    final viaUserId = int.tryParse(uri.queryParameters['via'] ?? '');

    final storage = await LocalStorageService.getInstance();
    final user = storage.getUser();
    final currentUserId = user?.userId;
    if (currentUserId == null) return; // not logged in — splash will route to login

    // Fetch lightweight stream metadata.
    final result = await _streamService.getStream(streamId,
        currentUserId: currentUserId);
    final stream = result.stream;
    if (stream == null) return;

    final navState = _navKey?.currentState;
    if (navState == null) return;
    navState.push(MaterialPageRoute<void>(
      builder: (_) => StreamViewerScreen(
        stream: stream,
        currentUserId: currentUserId,
        shareUid: shareUid,
        crossPostSharerId: viaUserId,
        crossPostPlatform: _normalizePlatform(platform),
      ),
    ));
  }

  String? _normalizePlatform(String? raw) {
    if (raw == null) return null;
    const allowed = {
      'tiktok', 'instagram', 'youtube', 'facebook', 'x', 'twitter',
      'whatsapp', 'telegram', 'other',
    };
    final lower = raw.toLowerCase();
    if (allowed.contains(lower)) return lower == 'twitter' ? 'x' : lower;
    return 'other';
  }

  /// Fallback used by the share builder so frontend-built URLs use a
  /// consistent shape with the backend `share_url` response.
  static String buildShareUrl(int streamId,
      {String? shareUid, int? viaUserId, String? fromPlatform}) {
    final qp = <String, String>{};
    if (shareUid != null) qp['share_uid'] = shareUid;
    if (fromPlatform != null) qp['from'] = fromPlatform;
    if (viaUserId != null) qp['via'] = viaUserId.toString();
    final uri = Uri.https('tajiri.zimasystems.com', '/streams/$streamId', qp);
    return uri.toString();
  }
}
