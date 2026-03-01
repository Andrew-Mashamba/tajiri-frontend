import 'package:flutter/material.dart';
import '../music/music_screen.dart' as music;
import '../../models/music_models.dart';

/// Story 55: Music Library – entry point from clips/route.
/// Navigation: Home → Profile → Music tab → Library link OR direct MusicScreen.
/// Delegates to lib/screens/music/music_screen.dart for browse and play.
class MusicScreen extends StatelessWidget {
  final int currentUserId;
  final Function(MusicTrack)? onTrackSelected;

  const MusicScreen({
    super.key,
    required this.currentUserId,
    this.onTrackSelected,
  });

  @override
  Widget build(BuildContext context) {
    return music.MusicScreen(
      currentUserId: currentUserId,
      onTrackSelected: onTrackSelected,
    );
  }
}
