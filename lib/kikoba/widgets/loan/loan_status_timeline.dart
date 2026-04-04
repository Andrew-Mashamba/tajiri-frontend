/// Loan Status Timeline Widget
///
/// Visual timeline showing the progress of a loan application through its stages.

import 'package:flutter/material.dart';
import '../../models/loan_models.dart';
import 'package:intl/intl.dart';

class LoanStatusTimeline extends StatelessWidget {
  final LoanApplication application;
  final bool showDetails;

  const LoanStatusTimeline({
    Key? key,
    required this.application,
    this.showDetails = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final steps = _buildTimelineSteps();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.timeline, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Hatua za Mkopo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isFirst = index == 0;
          final isLast = index == steps.length - 1;

          return _TimelineItem(
            step: step,
            isFirst: isFirst,
            isLast: isLast,
            showDetails: showDetails,
          );
        }),
      ],
    );
  }

  List<TimelineStep> _buildTimelineSteps() {
    final status = application.status;
    final steps = <TimelineStep>[];

    // Step 1: Submitted
    steps.add(TimelineStep(
      title: 'Ombi Limewasilishwa',
      subtitle: 'Ombi lako limepokelewa',
      timestamp: application.applicationDate,
      isCompleted: true,
      isCurrent: false,
      icon: Icons.send,
    ));

    // Step 2: Guarantor Approval
    final guarantorProgress =
        '${application.approvedGuarantorsCount}/${application.guarantors.length}';
    final guarantorCompleted = application.allGuarantorsApproved ||
        status.index > LoanStatus.guarantorPending.index;

    String guarantorSubtitle = 'Wadhamini: $guarantorProgress';
    if (application.anyGuarantorRejected) {
      guarantorSubtitle = 'Mdhamini amekataa';
    } else if (application.pendingGuarantorsCount > 0) {
      guarantorSubtitle += ' - Wanasubiri: ${application.pendingGuarantorsCount}';
    }

    steps.add(TimelineStep(
      title: 'Wadhamini Wanaidhinisha',
      subtitle: guarantorSubtitle,
      isCompleted: guarantorCompleted && !application.anyGuarantorRejected,
      isCurrent: status == LoanStatus.guarantorPending,
      isFailed: application.anyGuarantorRejected || status == LoanStatus.guarantorRejected,
      icon: Icons.people,
    ));

    // Step 3: Voting
    String votingSubtitle;
    if (application.voting != null) {
      votingSubtitle = 'Kura: ${application.voting!.approvalPercentage.toStringAsFixed(0)}% ya ${application.voting!.threshold.toStringAsFixed(0)}%';
    } else {
      votingSubtitle = 'Inasubiri kura za wanachama';
    }

    final votingCompleted = [
      LoanStatus.approved,
      LoanStatus.disbursing,
      LoanStatus.disbursed,
      LoanStatus.active,
      LoanStatus.closed,
    ].contains(status);

    steps.add(TimelineStep(
      title: 'Kura za Wanachama',
      subtitle: votingSubtitle,
      isCompleted: votingCompleted,
      isCurrent: status == LoanStatus.pendingApproval,
      isFailed: status == LoanStatus.rejected,
      icon: Icons.how_to_vote,
    ));

    // Step 4: Approval
    steps.add(TimelineStep(
      title: 'Imeidhinishwa',
      subtitle: application.approvedByName != null
          ? 'Na: ${application.approvedByName}'
          : application.approvedBy != null
              ? 'Na: ${application.approvedBy}'
              : null,
      timestamp: application.approvedDate,
      isCompleted: [
        LoanStatus.approved,
        LoanStatus.disbursing,
        LoanStatus.disbursed,
        LoanStatus.active,
        LoanStatus.closed,
      ].contains(status),
      isCurrent: status == LoanStatus.approved,
      icon: Icons.check_circle,
    ));

    // Step 5: Disbursement
    String? disbursementSubtitle;
    if (status == LoanStatus.disbursing) {
      disbursementSubtitle = 'Fedha zinatumwa...';
    } else if (status == LoanStatus.failed) {
      disbursementSubtitle = application.failureReason ?? 'Imeshindikana kutuma fedha';
    } else if (application.disbursedDate != null) {
      disbursementSubtitle = 'Fedha zimetumwa';
    }

    steps.add(TimelineStep(
      title: 'Fedha Zimetumwa',
      subtitle: disbursementSubtitle,
      timestamp: application.disbursedDate,
      isCompleted: [
        LoanStatus.disbursed,
        LoanStatus.active,
        LoanStatus.closed,
      ].contains(status),
      isCurrent: status == LoanStatus.disbursing || status == LoanStatus.disbursed,
      isFailed: status == LoanStatus.failed,
      icon: Icons.account_balance_wallet,
    ));

    // Step 6: Active/Closed (only if relevant)
    if (status == LoanStatus.active ||
        status == LoanStatus.closed ||
        status == LoanStatus.defaulted) {
      steps.add(TimelineStep(
        title: status == LoanStatus.closed
            ? 'Mkopo Umekamilika'
            : status == LoanStatus.defaulted
                ? 'Mkopo Umechelewa'
                : 'Inalipwa',
        subtitle: status == LoanStatus.closed
            ? 'Malipo yote yamekamilika'
            : status == LoanStatus.defaulted
                ? 'Malipo yamechelewa'
                : 'Mkopo unaendelea kulipwa',
        isCompleted: status == LoanStatus.closed,
        isCurrent: status == LoanStatus.active,
        isFailed: status == LoanStatus.defaulted,
        icon: status == LoanStatus.closed
            ? Icons.done_all
            : status == LoanStatus.defaulted
                ? Icons.warning
                : Icons.payments,
      ));
    }

    // Handle rejection cases
    if (application.isRejected && status != LoanStatus.guarantorRejected) {
      steps.add(TimelineStep(
        title: 'Imekataliwa',
        subtitle: application.rejectionReason,
        timestamp: application.rejectedAt,
        isCompleted: true,
        isCurrent: true,
        isFailed: true,
        icon: Icons.cancel,
      ));
    }

    // Handle cancellation
    if (status == LoanStatus.cancelled) {
      steps.add(TimelineStep(
        title: 'Imefutwa',
        subtitle: application.cancellationReason ?? 'Ombi limefutwa',
        timestamp: application.cancelledAt,
        isCompleted: true,
        isCurrent: true,
        isFailed: true,
        icon: Icons.block,
      ));
    }

    return steps;
  }
}

class _TimelineItem extends StatelessWidget {
  final TimelineStep step;
  final bool isFirst;
  final bool isLast;
  final bool showDetails;

  const _TimelineItem({
    required this.step,
    required this.isFirst,
    required this.isLast,
    required this.showDetails,
  });

  @override
  Widget build(BuildContext context) {
    final Color stepColor;
    if (step.isFailed) {
      stepColor = Colors.red;
    } else if (step.isCompleted) {
      stepColor = Colors.green;
    } else if (step.isCurrent) {
      stepColor = Colors.orange;
    } else {
      stepColor = Colors.grey.shade300;
    }

    final Color lineColor = step.isCompleted && !step.isFailed
        ? Colors.green
        : Colors.grey.shade300;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline column
          SizedBox(
            width: 60,
            child: Column(
              children: [
                // Top line
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 16,
                    color: lineColor,
                  ),
                // Circle indicator
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: stepColor,
                    shape: BoxShape.circle,
                    boxShadow: step.isCurrent
                        ? [
                            BoxShadow(
                              color: stepColor.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    step.isCompleted || step.isFailed
                        ? (step.isFailed ? Icons.close : Icons.check)
                        : step.isCurrent
                            ? Icons.radio_button_checked
                            : step.icon ?? Icons.circle_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                // Bottom line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: step.isCompleted && !step.isFailed
                          ? Colors.green
                          : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          ),
          // Content column
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: 16,
                bottom: isLast ? 16 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: step.isCurrent
                          ? stepColor
                          : step.isCompleted
                              ? Colors.black87
                              : Colors.grey,
                    ),
                  ),
                  if (step.subtitle != null && showDetails)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        step.subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: step.isFailed
                              ? Colors.red.shade700
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  if (step.timestamp != null && showDetails)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatDateTime(step.timestamp!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('d MMM yyyy, HH:mm', 'sw').format(date);
  }
}

/// Timeline step data model
class TimelineStep {
  final String title;
  final String? subtitle;
  final DateTime? timestamp;
  final bool isCompleted;
  final bool isCurrent;
  final bool isFailed;
  final IconData? icon;

  TimelineStep({
    required this.title,
    this.subtitle,
    this.timestamp,
    required this.isCompleted,
    required this.isCurrent,
    this.isFailed = false,
    this.icon,
  });
}
