import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings_scope.dart';
import '../services/partner_availability_mode_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

/// Spec line 309 — sticky banner shown on tajirika_home_page when the
/// partner has been auto-paused after 3 consecutive missed/declined orders.
/// One-tap Resume calls `/partners/{id}/resume`.
class AutoPauseBanner extends StatefulWidget {
  final int partnerUserId;
  final DateTime pausedAt;
  final int consecutiveMisses;
  final VoidCallback onResumed;
  const AutoPauseBanner({
    super.key,
    required this.partnerUserId,
    required this.pausedAt,
    required this.consecutiveMisses,
    required this.onResumed,
  });

  @override
  State<AutoPauseBanner> createState() => _AutoPauseBannerState();
}

class _AutoPauseBannerState extends State<AutoPauseBanner> {
  bool _busy = false;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  Future<void> _resume() async {
    setState(() => _busy = true);
    final ok =
        await PartnerAvailabilityModeService.resume(widget.partnerUserId);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      widget.onResumed();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSwahili ? 'Imeshindikana' : 'Failed to resume'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    final pausedAt = DateFormat('d MMM HH:mm').format(widget.pausedAt.toLocal());
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        border: Border(
          left: BorderSide(
            color: const Color(0xFFB71C1C).withValues(alpha: 0.6),
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.pause_circle_filled_rounded,
              size: 24, color: Color(0xFFB71C1C)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSw
                      ? 'Akaunti yako imezuiliwa kupokea oda mpya'
                      : 'Your account is paused for new orders',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB71C1C),
                  ),
                ),
                Text(
                  isSw
                      ? 'Sababu: oda ${widget.consecutiveMisses} mfululizo zimepuuzwa tangu $pausedAt.'
                      : '${widget.consecutiveMisses} consecutive misses since $pausedAt.',
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _busy ? null : _resume,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: _busy
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(
                    isSw ? 'Washa tena' : 'Resume',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w800),
                  ),
          ),
        ],
      ),
    );
  }
}
