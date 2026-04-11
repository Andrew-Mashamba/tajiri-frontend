// lib/my_wallet/widgets/earnings_summary_card.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/subscription_service.dart';
import '../../models/subscription_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class EarningsSummaryCard extends StatefulWidget {
  final int userId;

  const EarningsSummaryCard({super.key, required this.userId});

  @override
  State<EarningsSummaryCard> createState() => _EarningsSummaryCardState();
}

class _EarningsSummaryCardState extends State<EarningsSummaryCard> {
  bool _isLoading = true;
  EarningsSummary? _summary;

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    try {
      final service = SubscriptionService();
      final result = await service.getEarningsSummary(widget.userId);
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result.success) _summary = result.summary;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.trending_up_rounded, size: 18, color: _kPrimary),
              ),
              const SizedBox(width: 10),
              Text(
                isSwahili ? 'Mapato ya Mwezi' : 'Monthly Earnings',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
              ),
            )
          else if (_summary != null) ...[
            // Total
            Text(
              'TZS ${_formatAmount(_summary!.totalNet)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 16),
            // Breakdown
            _EarningRow(
              icon: Icons.calendar_month_rounded,
              label: isSwahili ? 'Mwezi Huu' : 'This Month',
              amount: _summary!.thisMonth,
              formatAmount: _formatAmount,
            ),
            _EarningRow(
              icon: Icons.hourglass_empty_rounded,
              label: isSwahili ? 'Inasubiri' : 'Pending',
              amount: _summary!.pending,
              formatAmount: _formatAmount,
            ),
            _EarningRow(
              icon: Icons.account_balance_wallet_rounded,
              label: isSwahili ? 'Jumla (Ghafi)' : 'Total (Gross)',
              amount: _summary!.totalGross,
              formatAmount: _formatAmount,
            ),
          ],
        ],
      ),
    );
  }
}

class _EarningRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final String Function(double) formatAmount;

  const _EarningRow({
    required this.icon,
    required this.label,
    required this.amount,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _kSecondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: _kSecondary),
          ),
          const Spacer(),
          Text(
            'TZS ${formatAmount(amount)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
