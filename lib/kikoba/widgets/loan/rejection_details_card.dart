/// Rejection Details Card
///
/// Shows detailed rejection information with remediation steps.

import 'package:flutter/material.dart';
import '../../models/loan_models.dart';
import 'package:intl/intl.dart';

class RejectionDetailsCard extends StatelessWidget {
  final LoanApplication application;
  final VoidCallback? onReapply;
  final bool showRemediationSteps;

  const RejectionDetailsCard({
    Key? key,
    required this.application,
    this.onReapply,
    this.showRemediationSteps = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!application.isRejected &&
        application.status != LoanStatus.cancelled &&
        application.status != LoanStatus.failed) {
      return const SizedBox.shrink();
    }

    final isGuarantorRejection = application.status == LoanStatus.guarantorRejected;
    final isCancelled = application.status == LoanStatus.cancelled;
    final isFailed = application.status == LoanStatus.failed;

    final Color cardColor;
    final IconData cardIcon;
    final String cardTitle;

    if (isCancelled) {
      cardColor = Colors.grey;
      cardIcon = Icons.block;
      cardTitle = 'Ombi Limefutwa';
    } else if (isFailed) {
      cardColor = Colors.red;
      cardIcon = Icons.error;
      cardTitle = 'Kutuma Fedha Kushindikana';
    } else if (isGuarantorRejection) {
      cardColor = Colors.orange;
      cardIcon = Icons.person_remove;
      cardTitle = 'Mdhamini Amekataa';
    } else {
      cardColor = Colors.red;
      cardIcon = Icons.cancel;
      cardTitle = 'Ombi Limekataliwa';
    }

    return Card(
      elevation: 2,
      color: cardColor.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cardColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(cardIcon, color: cardColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cardTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cardColor.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Details
            if (application.rejectedAt != null || application.failedAt != null || application.cancelledAt != null)
              _DetailRow(
                label: 'Tarehe',
                value: _formatDate(application.rejectedAt ?? application.failedAt ?? application.cancelledAt!),
              ),

            if (application.rejectedByName != null || application.rejectedBy != null)
              _DetailRow(
                label: isGuarantorRejection ? 'Mdhamini' : 'Imekataliwa na',
                value: application.rejectedByName ?? application.rejectedBy!,
              ),

            // Reason
            if (_hasReason) ...[
              const SizedBox(height: 12),
              Text(
                'Sababu:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cardColor.withOpacity(0.3)),
                ),
                child: Text(
                  _reason!,
                  style: TextStyle(
                    color: cardColor.shade800,
                    height: 1.4,
                  ),
                ),
              ),
            ],

            // Guarantor rejections details
            if (isGuarantorRejection && application.guarantors.any((g) => g.isRejected)) ...[
              const SizedBox(height: 16),
              Text(
                'Wadhamini waliokataa:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              ...application.guarantors
                  .where((g) => g.isRejected)
                  .map((g) => _GuarantorRejectionRow(guarantor: g)),
            ],

            // Remediation steps
            if (showRemediationSteps) ...[
              const SizedBox(height: 16),
              _RemediationSteps(
                status: application.status,
                isGuarantorRejection: isGuarantorRejection,
              ),
            ],

            // Reapply button
            if (onReapply != null && !isCancelled) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onReapply,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Omba Tena'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _hasReason =>
      application.rejectionReason != null ||
      application.failureReason != null ||
      application.cancellationReason != null;

  String? get _reason =>
      application.rejectionReason ??
      application.failureReason ??
      application.cancellationReason;

  String _formatDate(DateTime date) {
    return DateFormat('d MMMM yyyy', 'sw').format(date);
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _GuarantorRejectionRow extends StatelessWidget {
  final Guarantor guarantor;

  const _GuarantorRejectionRow({required this.guarantor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.red.withOpacity(0.1),
            child: const Icon(Icons.person, color: Colors.red, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guarantor.guarantorName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (guarantor.rejectionReason != null)
                  Text(
                    guarantor.rejectionReason!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RemediationSteps extends StatelessWidget {
  final LoanStatus status;
  final bool isGuarantorRejection;

  const _RemediationSteps({
    required this.status,
    required this.isGuarantorRejection,
  });

  @override
  Widget build(BuildContext context) {
    final steps = _getRemediationSteps();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Nini cha kufanya:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  List<String> _getRemediationSteps() {
    if (isGuarantorRejection || status == LoanStatus.guarantorRejected) {
      return [
        'Omba wadhamini wapya wenye uwezo wa kukudhamini',
        'Hakikisha wadhamini wanakuamini na wanajua masharti ya udhamini',
        'Punguza kiasi cha mkopo ikiwa wadhamini hawana uwezo',
        'Wasiliana na mdhamini aliyekataa kujua sababu zaidi',
        'Hakikisha akiba yako inaonyesha uwezo wako wa kulipa',
      ];
    }

    if (status == LoanStatus.failed) {
      return [
        'Hakikisha maelezo yako ya benki ni sahihi',
        'Wasiliana na kikoba kupata msaada',
        'Jaribu tena baadaye ikiwa ni tatizo la muda',
      ];
    }

    return [
      'Soma sababu ya kukataliwa kwa makini',
      'Rekebisha matatizo yaliyoainishwa',
      'Hakikisha una akiba ya kutosha',
      'Angalia rekodi yako ya malipo ya zamani',
      'Wasiliana na kamati kwa maelezo zaidi',
      'Fikiria kupunguza kiasi cha mkopo unaoomba',
    ];
  }
}

/// Compact rejection badge for lists
class RejectionBadge extends StatelessWidget {
  final LoanStatus status;
  final String? reason;

  const RejectionBadge({
    Key? key,
    required this.status,
    this.reason,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String text;

    switch (status) {
      case LoanStatus.rejected:
        color = Colors.red;
        text = 'Imekataliwa';
        break;
      case LoanStatus.guarantorRejected:
        color = Colors.orange;
        text = 'Mdhamini Amekataa';
        break;
      case LoanStatus.cancelled:
        color = Colors.grey;
        text = 'Imefutwa';
        break;
      case LoanStatus.failed:
        color = Colors.red;
        text = 'Imeshindikana';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == LoanStatus.cancelled ? Icons.block : Icons.cancel,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

extension on Color {
  Color get shade700 => HSLColor.fromColor(this).withLightness(0.3).toColor();
  Color get shade800 => HSLColor.fromColor(this).withLightness(0.25).toColor();
}
