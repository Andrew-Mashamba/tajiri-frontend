// lib/widgets/offline_banner_host.dart
//
// Wraps the entire app body and renders a persistent MaterialBanner
// directly under the system status bar when the device is offline.
// Per docs/ENGINEERING_PLAYBOOK.md → Part VII (Network state UI), the
// banner is NOT a SnackBar — it stays until reconnection.
//
// Mounted once in MaterialApp.builder so every screen inherits it.

import 'package:flutter/material.dart';

import '../l10n/app_strings_scope.dart';
import '../services/network_state_service.dart';

class OfflineBannerHost extends StatelessWidget {
  final Widget child;
  const OfflineBannerHost({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: NetworkStateService.instance.offline,
      child: child,
      builder: (context, offline, child) {
        return Stack(
          children: [
            child!,
            if (offline)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Material(
                    color: Colors.transparent,
                    child: _OfflinePill(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OfflinePill extends StatelessWidget {
  static const Color _kAmberBg = Color(0xFFFFF3E0);
  static const Color _kAmberFg = Color(0xFF8C5500);
  static const Color _kAmberBorder = Color(0xFFFFCC80);

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _kAmberBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kAmberBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 16, color: _kAmberFg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isSw
                  ? 'Hauko mtandaoni. Inaonyesha taarifa zilizohifadhiwa.'
                  : "You're offline. Showing cached data.",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kAmberFg,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
