/// Voting Progress Widget
///
/// Displays voting progress for loan applications with circular indicator and vote breakdown.

import 'package:flutter/material.dart';
import '../../models/loan_models.dart';
import 'dart:math' as math;

class VotingProgressWidget extends StatelessWidget {
  final LoanVotingSummary voting;
  final VoidCallback? onVote;
  final bool hasVoted;
  final String? userVote;
  final bool compact;

  const VotingProgressWidget({
    Key? key,
    required this.voting,
    this.onVote,
    this.hasVoted = false,
    this.userVote,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact(context);
    }
    return _buildFull(context);
  }

  Widget _buildFull(BuildContext context) {
    final percent = voting.approvalPercentage / 100;
    final progressColor = _getProgressColor();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.how_to_vote,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Hali ya Kura',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Circular progress
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                children: [
                  // Background circle
                  CustomPaint(
                    size: const Size(140, 140),
                    painter: _CircularProgressPainter(
                      progress: percent.clamp(0, 1),
                      progressColor: progressColor,
                      backgroundColor: Colors.grey.shade200,
                      threshold: voting.threshold / 100,
                      strokeWidth: 12,
                    ),
                  ),
                  // Center text
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${voting.approvalPercentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: progressColor,
                          ),
                        ),
                        Text(
                          'ya ${voting.threshold.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Vote counts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _VoteCount(
                  label: 'Ndiyo',
                  count: voting.yesVotes,
                  color: Colors.green,
                ),
                _VoteCount(
                  label: 'Hapana',
                  count: voting.noVotes,
                  color: Colors.red,
                ),
                _VoteCount(
                  label: 'Sijui',
                  count: voting.abstainVotes,
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              'Jumla ya kura: ${voting.totalVotes}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),

            // Threshold indicator
            if (voting.hasReachedThreshold) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Kiwango kimefikiwa!',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Minimum votes warning
            if (!voting.hasMinimumVotes) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info, color: Colors.orange.shade700, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Kura zaidi zinahitajika',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Vote button or voted indicator
            if (!hasVoted && onVote != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onVote,
                  icon: const Icon(Icons.how_to_vote),
                  label: const Text('Piga Kura'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],

            if (hasVoted) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Umeshapiga kura${userVote != null ? ': ${_getVoteDisplay(userVote!)}' : ''}',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final percent = voting.approvalPercentage / 100;
    final progressColor = _getProgressColor();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Mini circular progress
          SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: percent.clamp(0, 1),
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  strokeWidth: 4,
                ),
                Center(
                  child: Text(
                    '${voting.approvalPercentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Vote counts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kura: ${voting.yesVotes}/${voting.totalVotes}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _MiniVoteCount(count: voting.yesVotes, color: Colors.green),
                    const SizedBox(width: 8),
                    _MiniVoteCount(count: voting.noVotes, color: Colors.red),
                    const SizedBox(width: 8),
                    _MiniVoteCount(count: voting.abstainVotes, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),
          // Status indicator
          if (voting.hasReachedThreshold)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.green, size: 16),
            ),
        ],
      ),
    );
  }

  Color _getProgressColor() {
    if (voting.approvalPercentage >= voting.threshold) return Colors.green;
    if (voting.rejectionPercentage >= 50) return Colors.red;
    return Colors.orange;
  }

  String _getVoteDisplay(String vote) {
    switch (vote.toLowerCase()) {
      case 'yes':
        return 'Ndiyo';
      case 'no':
        return 'Hapana';
      case 'abstain':
        return 'Sijui';
      default:
        return vote;
    }
  }
}

class _VoteCount extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _VoteCount({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _MiniVoteCount extends StatelessWidget {
  final int count;
  final Color color;

  const _MiniVoteCount({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for circular progress with threshold marker
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;
  final double threshold;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
    required this.threshold,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );

    // Threshold marker
    final thresholdAngle = startAngle + (2 * math.pi * threshold);
    final markerLength = strokeWidth + 6;
    final innerRadius = radius - markerLength / 2;
    final outerRadius = radius + markerLength / 2;

    final markerStart = Offset(
      center.dx + innerRadius * math.cos(thresholdAngle),
      center.dy + innerRadius * math.sin(thresholdAngle),
    );
    final markerEnd = Offset(
      center.dx + outerRadius * math.cos(thresholdAngle),
      center.dy + outerRadius * math.sin(thresholdAngle),
    );

    final markerPaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(markerStart, markerEnd, markerPaint);
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.threshold != threshold;
  }
}
