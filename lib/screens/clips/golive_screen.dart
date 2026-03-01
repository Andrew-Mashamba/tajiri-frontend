/// Story 57: Go Live — Flutter target: lib/screens/clips/golive_screen.dart
///
/// As a creator, I want to start a live stream.
/// Navigation: Home → Profile → Live tab → Go Live OR Feed → Live tab → Go Live.
/// Design: DOCS/DESIGN.md (layout, touch targets 48dp min, colors).
/// Flow: GoLiveScreen (create/schedule) → BackstageScreen → start → LiveBroadcastScreenAdvanced (RTMP/camera).
/// StandbyScreen is used for scheduled streams (viewers see countdown).
import 'package:flutter/material.dart';
import '../streams/go_live_screen.dart' as streams;

/// Go Live entry screen (Story 57). Provides create/schedule stream form,
/// then BackstageScreen for camera/mic checks, then POST /api/streams/{id}/start
/// and RTMP/camera live broadcast via LiveBroadcastScreenAdvanced.
class GoLiveScreen extends StatelessWidget {
  /// Current user ID (creator). Required for POST /api/streams.
  final int userId;

  const GoLiveScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return streams.GoLiveScreen(userId: userId);
  }
}
