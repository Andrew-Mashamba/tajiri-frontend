import 'package:flutter/material.dart';
import '../../widgets/gallery/michango_gallery_widget.dart';

/// Story 81: View & Manage Campaigns (Michango).
/// Navigation: Home → Profile → Tab [Michango] → MichangoGalleryWidget.
/// Wraps [MichangoGalleryWidget] with SafeArea and optional AppBar for direct routes.
/// Design: DOCS/DESIGN.md (SafeArea, touch targets 48dp min, #FAFAFA, #1A1A1A).
class MichangoGalleryWidgetScreen extends StatelessWidget {
  final int userId;
  final bool isOwnProfile;
  final VoidCallback? onCreateCampaign;
  /// When true, shows AppBar with back button (e.g. when opened via /profile/:id/michango).
  final bool showAppBar;

  const MichangoGalleryWidgetScreen({
    super.key,
    required this.userId,
    this.isOwnProfile = false,
    this.onCreateCampaign,
    this.showAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = MichangoGalleryWidget(
      userId: userId,
      isOwnProfile: isOwnProfile,
      onCreateCampaign: onCreateCampaign,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: showAppBar
          ? AppBar(
              title: const Text(
                'Michango',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              backgroundColor: const Color(0xFFFAFAFA),
              elevation: 0,
              scrolledUnderElevation: 2,
              iconTheme: const IconThemeData(color: Color(0xFF1A1A1A), size: 24),
              leading: IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Rudi',
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: content,
      ),
    );
  }
}
