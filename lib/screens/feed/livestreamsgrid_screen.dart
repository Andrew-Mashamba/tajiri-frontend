/// Story 88: Feed Live Tab — see live streams in feed.
///
/// Navigation: Home → Feed → Tab [Live] → LiveStreamsGrid (this screen).
/// Design: DOCS/DESIGN.md (SafeArea, touch targets 48dp min, colors).
import 'package:flutter/material.dart';
import '../../widgets/live_streams_grid.dart';

/// Screen that shows the live streams grid in the Feed Live tab.
/// Wraps [LiveStreamsGrid] for use as tab content in [FeedScreen].
class LiveStreamsGridScreen extends StatelessWidget {
  final int currentUserId;

  const LiveStreamsGridScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return LiveStreamsGrid(currentUserId: currentUserId);
  }
}
