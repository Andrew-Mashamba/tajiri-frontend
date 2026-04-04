/// Guarantor Progress Card Widget
///
/// Shows the approval status of all guarantors for a loan application.

import 'package:flutter/material.dart';
import '../../models/loan_models.dart';
import 'package:intl/intl.dart';

class GuarantorProgressCard extends StatelessWidget {
  final List<Guarantor> guarantors;
  final VoidCallback? onViewDetails;
  final bool showAmount;

  const GuarantorProgressCard({
    Key? key,
    required this.guarantors,
    this.onViewDetails,
    this.showAmount = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final approved = guarantors.where((g) => g.isApproved).length;
    final pending = guarantors.where((g) => g.isPending).length;
    final rejected = guarantors.where((g) => g.isRejected).length;
    final total = guarantors.length;

    final hasRejection = rejected > 0;
    final progressColor = hasRejection ? Colors.red : Colors.green;
    final progressValue = total > 0 ? approved / total : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.people,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Hali ya Wadhamini',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (onViewDetails != null)
                  TextButton(
                    onPressed: onViewDetails,
                    child: const Text('Ona Zaidi'),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressValue,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),

            // Progress text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$approved / $total wameidhinisha',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '${(progressValue * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: Icons.check_circle,
                  color: Colors.green,
                  label: 'Wameidhinisha',
                  count: approved,
                ),
                _StatItem(
                  icon: Icons.hourglass_empty,
                  color: Colors.orange,
                  label: 'Wanasubiri',
                  count: pending,
                ),
                _StatItem(
                  icon: Icons.cancel,
                  color: Colors.red,
                  label: 'Wamekataa',
                  count: rejected,
                ),
              ],
            ),

            if (guarantors.isNotEmpty) ...[
              const Divider(height: 24),
              // Individual guarantors
              ...guarantors.map((g) => _GuarantorRow(
                    guarantor: g,
                    showAmount: showAmount,
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;

  const _StatItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _GuarantorRow extends StatelessWidget {
  final Guarantor guarantor;
  final bool showAmount;

  const _GuarantorRow({
    required this.guarantor,
    required this.showAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Avatar with status
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: guarantor.statusColor.withOpacity(0.15),
                child: Text(
                  _getInitials(guarantor.guarantorName),
                  style: TextStyle(
                    color: guarantor.statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    guarantor.statusIcon,
                    color: guarantor.statusColor,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Name and amount
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guarantor.guarantorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                if (showAmount && guarantor.guaranteedAmount > 0)
                  Text(
                    'TSh ${_formatAmount(guarantor.guaranteedAmount)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                if (guarantor.isRejected && guarantor.rejectionReason != null)
                  Text(
                    guarantor.rejectionReason!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: guarantor.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              guarantor.statusDisplayName,
              style: TextStyle(
                fontSize: 11,
                color: guarantor.statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(amount);
  }
}

/// Compact version for smaller spaces
class GuarantorProgressIndicator extends StatelessWidget {
  final List<Guarantor> guarantors;
  final double size;

  const GuarantorProgressIndicator({
    Key? key,
    required this.guarantors,
    this.size = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final approved = guarantors.where((g) => g.isApproved).length;
    final total = guarantors.length;
    final hasRejection = guarantors.any((g) => g.isRejected);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          CircularProgressIndicator(
            value: total > 0 ? approved / total : 0,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              hasRejection ? Colors.red : Colors.green,
            ),
            strokeWidth: 4,
          ),
          Center(
            child: Text(
              '$approved/$total',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
