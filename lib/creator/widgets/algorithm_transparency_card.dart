import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';

/// Algorithm transparency card (Lever 8).
///
/// Shows creators WHY their post performed the way it did.
/// Attach to post detail, analytics, or weekly report.
///
/// Example data:
/// ```
/// AlgorithmTransparencyCard(
///   reach: 12400,
///   reachChangePercent: 18,
///   topDriver: 'Shared 38× in groups',
///   watchTimeDecay: 'Viewers drop at 8s — try a stronger hook',
///   predictedEarnings: 2400,
///   communityMultiplier: 1.3,
///   viralityMultiplier: 1.1,
/// )
/// ```
class AlgorithmTransparencyCard extends StatelessWidget {
  final int reach;
  final int reachChangePercent;
  final String? topDriver;
  final String? watchTimeDecay;
  final double? predictedEarnings;
  final double? communityMultiplier;
  final double? viralityMultiplier;
  final VoidCallback? onActionTap;

  const AlgorithmTransparencyCard({
    super.key,
    required this.reach,
    required this.reachChangePercent,
    this.topDriver,
    this.watchTimeDecay,
    this.predictedEarnings,
    this.communityMultiplier,
    this.viralityMultiplier,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isPositive = reachChangePercent >= 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_graph_rounded, size: 18, color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (s?.isSwahili == true) ? 'Kwanini Chapisho Hili?' : 'Why This Post?',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (s?.isSwahili == true) ? 'Fumbo la algorithm wazi' : 'Algorithm transparency',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Reach hero
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatNumber(reach),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive ? const Color(0xFFF5F5F5) : const Color(0xFFFFE5E5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      size: 14,
                      color: isPositive ? const Color(0xFF1A1A1A) : const Color(0xFFD32F2F),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isPositive ? '+' : ''}$reachChangePercent%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isPositive ? const Color(0xFF1A1A1A) : const Color(0xFFD32F2F),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            (s?.isSwahili == true) ? 'watu walioona' : 'people reached',
            style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 16),

          // Driver + decay (monochrome icons — color reserved for status badges only)
          if (topDriver != null && topDriver!.isNotEmpty) ...[
            _buildInsightRow(
              icon: Icons.rocket_launch_rounded,
              label: (s?.isSwahili == true) ? 'Kichocheo Kikuu' : 'Top Driver',
              value: topDriver!,
            ),
            const SizedBox(height: 12),
          ],
          if (watchTimeDecay != null && watchTimeDecay!.isNotEmpty) ...[
            _buildInsightRow(
              icon: Icons.timer_rounded,
              label: (s?.isSwahili == true) ? 'Muda wa Kutazama' : 'Watch Time',
              value: watchTimeDecay!,
            ),
            const SizedBox(height: 12),
          ],

          // Multipliers
          if (communityMultiplier != null || viralityMultiplier != null) ...[
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (communityMultiplier != null)
                  _buildMultiplierChip(
                    Icons.people_rounded,
                    (s?.isSwahili == true) ? 'Jamii' : 'Community',
                    communityMultiplier!,
                  ),
                if (viralityMultiplier != null)
                  _buildMultiplierChip(
                    Icons.flash_on_rounded,
                    (s?.isSwahili == true) ? 'Uenezi' : 'Virality',
                    viralityMultiplier!,
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Predicted earnings
          if (predictedEarnings != null && predictedEarnings! > 0) ...[
            const Divider(height: 24, color: Color(0xFFE5E5E5)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  (s?.isSwahili == true) ? 'Mapato Yanayotarajiwa' : 'Predicted Earnings',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
                ),
                Text(
                  'TSh ${_formatNumber(predictedEarnings!.toInt())}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                ),
              ],
            ),
          ],

          // Action button
          if (onActionTap != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: onActionTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A1A1A),
                  side: const BorderSide(color: Color(0xFFE5E5E5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  (s?.isSwahili == true) ? 'Angalia Takwimu Zaidi' : 'View Full Analytics',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: const Color(0xFF1A1A1A)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMultiplierChip(IconData icon, String label, double value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF666666)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
          const SizedBox(width: 4),
          Text('${value.toStringAsFixed(1)}x', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}
