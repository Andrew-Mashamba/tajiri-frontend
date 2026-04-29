import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_strings_scope.dart';

/// Spec line 936 — Matterport-equivalent 360° tour CTA. The backend hosts a
/// Pannellum (open-source) viewer at the configured URL; tapping launches it
/// in the system browser. This avoids vendor SDK fees and keeps APK size
/// small. A future upgrade can swap to webview_flutter for in-app rendering.
class PanoramaLauncher extends StatelessWidget {
  final String url;
  const PanoramaLauncher({super.key, required this.url});

  Future<void> _launch(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final uri = Uri.tryParse(url);
    if (uri == null) {
      messenger.showSnackBar(SnackBar(
        content: Text(isSw ? 'URL si halali' : 'Invalid URL'),
      ));
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      messenger.showSnackBar(SnackBar(
        content: Text(isSw
            ? 'Imeshindikana kufungua kivinjari'
            : 'Could not open browser'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        border: Border.all(color: const Color(0xFF0D47A1).withValues(alpha: 0.30)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.view_in_ar_rounded,
              size: 24, color: Color(0xFF0D47A1)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSw ? 'Ziara ya 3D (360°)' : '3D Tour (360°)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D47A1),
                  ),
                ),
                Text(
                  isSw
                      ? 'Tembea ndani ya nyumba kupitia kivinjari'
                      : 'Walk through the property in your browser',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _launch(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              isSw ? 'Fungua' : 'Open',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
