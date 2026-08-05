import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_strings_scope.dart';
import '../../screens/wallet/send_tip_screen.dart';

/// Compact "Buy me a chai" tipping button (Lever 1).
///
/// Place on PostCard, profile header, or live stream overlay. Tapping pushes
/// [SendTipScreen] with stream/post attribution propagated so the backend
/// fires `live_tip·author` or `tip·author` correctly (streams.md §I row 7 /
/// posts.md tip row). If neither [streamId] nor [postId] is set the tip is
/// untagged — the creator still earns, but no source attribution is recorded.
class TipButton extends StatelessWidget {
  final int creatorId;
  final int currentUserId;
  final String? creatorName;
  final int? postId;
  final int? streamId;
  final VoidCallback? onTap;
  final bool compact;

  const TipButton({
    super.key,
    required this.creatorId,
    required this.currentUserId,
    this.creatorName,
    this.postId,
    this.streamId,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);

    if (compact) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleTap(context),
          borderRadius: BorderRadius.circular(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 32),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite_rounded, size: 14, color: Color(0xFF1A1A1A)),
                  const SizedBox(width: 4),
                  Text(
                    s?.tip ?? 'Tip',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => _handleTap(context),
        icon: const Icon(Icons.favorite_rounded, size: 16, color: Color(0xFF1A1A1A)),
        label: Text(
          s?.sendTip ?? 'Send tip',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1A1A1A),
          side: const BorderSide(color: Color(0xFFE5E5E5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    HapticFeedback.selectionClick();
    if (onTap != null) {
      onTap!();
      return;
    }
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SendTipScreen(
          creatorId: creatorId,
          currentUserId: currentUserId,
          creatorDisplayName: creatorName,
          postId: postId,
          streamId: streamId,
        ),
      ),
    );
  }
}
