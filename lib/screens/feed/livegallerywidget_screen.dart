import 'package:flutter/material.dart';
import '../../widgets/gallery/live_gallery_widget.dart';

/// Me → Live tab. DESIGN.md §13.4: same pattern as Video/Music (no AppBar when embedded in profile).
/// Scaffold(#FAFAFA) + SafeArea + LiveGalleryWidget.
class LiveGalleryWidgetScreen extends StatelessWidget {
  final int userId;
  final bool isOwnProfile;
  final VoidCallback? onGoLive;

  const LiveGalleryWidgetScreen({
    super.key,
    required this.userId,
    this.isOwnProfile = false,
    this.onGoLive,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: LiveGalleryWidget(
          userId: userId,
          isOwnProfile: isOwnProfile,
          onGoLive: onGoLive,
        ),
      ),
    );
  }
}
