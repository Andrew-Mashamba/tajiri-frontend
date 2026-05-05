// CoverPhotoActionsSheet — modal bottom sheet for the cover-photo flow.
// Spec: docs/superpowers/specs/2026-05-02-cover-photo-upload-design.md §4.1
//
// Surfaces three actions:
//   • Take photo  (rear camera)
//   • Choose from gallery
//   • Remove cover photo  (only when a cover already exists)

import 'package:flutter/material.dart';
import '../../../l10n/app_strings_scope.dart';

enum CoverPhotoAction { camera, gallery, remove }

class CoverPhotoActionsSheet extends StatelessWidget {
  /// When false, the "Remove cover photo" tile is hidden — used when the
  /// user has no cover yet.
  final bool hasExistingCover;

  const CoverPhotoActionsSheet({
    super.key,
    required this.hasExistingCover,
  });

  /// Convenience launcher. Returns the user's choice or null if dismissed.
  static Future<CoverPhotoAction?> show(
    BuildContext context, {
    required bool hasExistingCover,
  }) {
    return showModalBottomSheet<CoverPhotoAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CoverPhotoActionsSheet(hasExistingCover: hasExistingCover),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle (playbook standard: 40×4 grey.shade300)
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSw ? 'Picha ya jalada' : 'Cover photo',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.photo_camera_rounded,
              label: isSw ? 'Piga picha' : 'Take photo',
              onTap: () => Navigator.of(context).pop(CoverPhotoAction.camera),
            ),
            _ActionTile(
              icon: Icons.photo_library_rounded,
              label: isSw ? 'Chagua kutoka kwenye picha' : 'Choose from gallery',
              onTap: () => Navigator.of(context).pop(CoverPhotoAction.gallery),
            ),
            if (hasExistingCover)
              _ActionTile(
                icon: Icons.delete_outline_rounded,
                label: isSw ? 'Ondoa picha ya jalada' : 'Remove cover photo',
                onTap: () => Navigator.of(context).pop(CoverPhotoAction.remove),
                isDestructive: true,
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? const Color(0xFFC62828) : const Color(0xFF1A1A1A);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
