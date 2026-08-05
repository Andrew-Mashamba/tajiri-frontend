// lib/creator/screens/post_type_earnings_screens.dart
//
// Thin wrappers for the strategy-renderer screens, one per post
// type. The actual UI lives in PostTypeEarningsScreen
// (photo_earnings_screen.dart). Each wrapper just supplies the
// `postType` wire string — the renderer pulls labels, icons, and
// per-row applicability from
// lib/creator/models/post_type_earnings_taxonomy.dart.

import 'package:flutter/material.dart';

import 'photo_earnings_screen.dart';

class TextEarningsScreen extends StatelessWidget {
  final int creatorId;
  const TextEarningsScreen({super.key, required this.creatorId});
  @override
  Widget build(BuildContext context) =>
      PostTypeEarningsScreen(creatorId: creatorId, postType: 'text');
}

class ImageTextEarningsScreen extends StatelessWidget {
  final int creatorId;
  const ImageTextEarningsScreen({super.key, required this.creatorId});
  @override
  Widget build(BuildContext context) =>
      PostTypeEarningsScreen(creatorId: creatorId, postType: 'image_text');
}

class AudioEarningsScreen extends StatelessWidget {
  final int creatorId;
  const AudioEarningsScreen({super.key, required this.creatorId});
  @override
  Widget build(BuildContext context) =>
      PostTypeEarningsScreen(creatorId: creatorId, postType: 'audio');
}

class AudioTextEarningsScreen extends StatelessWidget {
  final int creatorId;
  const AudioTextEarningsScreen({super.key, required this.creatorId});
  @override
  Widget build(BuildContext context) =>
      PostTypeEarningsScreen(creatorId: creatorId, postType: 'audio_text');
}

class VideoEarningsScreen extends StatelessWidget {
  final int creatorId;
  const VideoEarningsScreen({super.key, required this.creatorId});
  @override
  Widget build(BuildContext context) =>
      PostTypeEarningsScreen(creatorId: creatorId, postType: 'video');
}

class ShortVideoEarningsScreen extends StatelessWidget {
  final int creatorId;
  const ShortVideoEarningsScreen({super.key, required this.creatorId});
  @override
  Widget build(BuildContext context) =>
      PostTypeEarningsScreen(creatorId: creatorId, postType: 'short_video');
}

class PollEarningsScreen extends StatelessWidget {
  final int creatorId;
  const PollEarningsScreen({super.key, required this.creatorId});
  @override
  Widget build(BuildContext context) =>
      PostTypeEarningsScreen(creatorId: creatorId, postType: 'poll');
}
