import 'package:flutter/material.dart';
import '../../../l10n/app_strings_scope.dart';

enum FollowerAction { view, mute, unmute, remove, block }

class FollowerActionsSheet {
  static Future<FollowerAction?> show(
    BuildContext context, {
    required bool isMuted,
    String? removeLabelEn,
    String? removeLabelSw,
  }) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return showModalBottomSheet<FollowerAction>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5E5),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.person_outline_rounded,
                  color: Color(0xFF1A1A1A)),
              title: Text(isSw ? 'Tazama wasifu' : 'View profile'),
              onTap: () => Navigator.of(sheetCtx).pop(FollowerAction.view),
            ),
            ListTile(
              leading: Icon(
                isMuted
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                color: const Color(0xFF1A1A1A),
              ),
              title: Text(
                isMuted
                    ? (isSw ? 'Achilia' : 'Unmute')
                    : (isSw ? 'Nyamazisha' : 'Mute'),
              ),
              onTap: () => Navigator.of(sheetCtx).pop(
                isMuted ? FollowerAction.unmute : FollowerAction.mute,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_remove_outlined,
                  color: Color(0xFFD32F2F)),
              title: Text(
                isSw
                    ? (removeLabelSw ?? 'Ondoa mfuasi')
                    : (removeLabelEn ?? 'Remove follower'),
                style: const TextStyle(color: Color(0xFFD32F2F)),
              ),
              onTap: () => Navigator.of(sheetCtx).pop(FollowerAction.remove),
            ),
            ListTile(
              leading: const Icon(Icons.block_rounded,
                  color: Color(0xFFD32F2F)),
              title: Text(
                isSw ? 'Zuia' : 'Block',
                style: const TextStyle(color: Color(0xFFD32F2F)),
              ),
              onTap: () => Navigator.of(sheetCtx).pop(FollowerAction.block),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
