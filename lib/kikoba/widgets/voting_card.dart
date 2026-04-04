import 'package:flutter/material.dart';

// Monochrome design colors (from design-guidelines.md)
const _primaryBg = Color(0xFFFAFAFA);
const _buttonBg = Color(0xFFFFFFFF);
const _primaryText = Color(0xFF1A1A1A);
const _secondaryText = Color(0xFF666666);
const _iconBg = Color(0xFF1A1A1A);
const _accent = Color(0xFF999999);

/// Reusable voting card widget for displaying voteable items
class VotingCard extends StatelessWidget {
  final String title;
  final String description;
  final String type;
  final String status;
  final String? createdBy;
  final String? createdAt;
  final int yesCount;
  final int noCount;
  final int abstainCount;
  final int totalVotes;
  final double approvalPercentage;
  final double approvalThreshold;
  final int? minVotes;
  final int? totalMembers;
  final bool hasVoted;
  final String? userVote;
  final bool isLoading;
  final VoidCallback? onVoteYes;
  final VoidCallback? onVoteNo;
  final VoidCallback? onVoteAbstain;
  final VoidCallback? onTap;
  final Widget? additionalContent;
  final EdgeInsetsGeometry? margin;

  const VotingCard({
    super.key,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    this.createdBy,
    this.createdAt,
    this.yesCount = 0,
    this.noCount = 0,
    this.abstainCount = 0,
    this.totalVotes = 0,
    this.approvalPercentage = 0,
    this.approvalThreshold = 50,
    this.minVotes,
    this.totalMembers,
    this.hasVoted = false,
    this.userVote,
    this.isLoading = false,
    this.onVoteYes,
    this.onVoteNo,
    this.onVoteAbstain,
    this.onTap,
    this.additionalContent,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with type badge and status
              Row(
                children: [
                  _buildTypeBadge(),
                  const Spacer(),
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _primaryText,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: _secondaryText,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // Additional content (if any)
              if (additionalContent != null) ...[
                const SizedBox(height: 12),
                additionalContent!,
              ],

              const SizedBox(height: 16),

              // Voting progress
              _buildVotingProgress(),

              const SizedBox(height: 12),

              // Vote counts
              _buildVoteCounts(),

              // Voting buttons (if pending/pending_approval and not voted)
              if (_isPendingStatus(status) && !hasVoted) ...[
                const SizedBox(height: 16),
                _buildVotingButtons(),
              ],

              // User's vote indicator
              if (hasVoted && userVote != null) ...[
                const SizedBox(height: 12),
                _buildUserVoteIndicator(),
              ],

              // Creator and date info
              if (createdBy != null || createdAt != null) ...[
                const SizedBox(height: 12),
                _buildMetaInfo(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    IconData icon;
    String label;

    switch (type.toLowerCase()) {
      case 'membership_removal':
      case 'membership_removal_request':
        icon = Icons.person_remove_rounded;
        label = 'Kuondoa Mwanachama';
        break;
      case 'expense_request':
        icon = Icons.receipt_long_rounded;
        label = 'Matumizi';
        break;
      case 'katiba_change':
      case 'katiba_change_request':
        icon = Icons.gavel_rounded;
        label = 'Mabadiliko ya Katiba';
        break;
      case 'fine_approval':
      case 'fine_approval_request':
        icon = Icons.money_off_rounded;
        label = 'Faini';
        break;
      case 'loan_application':
        icon = Icons.account_balance_rounded;
        label = 'Mkopo';
        break;
      case 'akiba_withdrawal':
        icon = Icons.savings_rounded;
        label = 'Kutoa Akiba';
        break;
      case 'mchango':
        icon = Icons.volunteer_activism_rounded;
        label = 'Mchango';
        break;
      case 'voting_case':
        icon = Icons.how_to_vote_rounded;
        label = 'Kura';
        break;
      default:
        icon = Icons.ballot_rounded;
        label = 'Kura';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _iconBg.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: _iconBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 12, color: _buttonBg),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    String label;
    IconData icon;
    bool isDark;

    switch (status.toLowerCase()) {
      case 'pending':
        label = 'Inasubiri';
        icon = Icons.hourglass_empty_rounded;
        isDark = false;
        break;
      case 'approved':
        label = 'Imekubaliwa';
        icon = Icons.check_circle_rounded;
        isDark = true;
        break;
      case 'rejected':
        label = 'Imekataliwa';
        icon = Icons.cancel_rounded;
        isDark = false;
        break;
      default:
        label = status;
        icon = Icons.info_rounded;
        isDark = false;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? _iconBg : _accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isDark ? _buttonBg : _secondaryText),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? _buttonBg : _secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVotingProgress() {
    final percentage = approvalPercentage.clamp(0.0, 100.0);
    final thresholdPosition = approvalThreshold.clamp(0.0, 100.0) / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Maendeleo ya Kura',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _secondaryText,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: percentage >= approvalThreshold ? _iconBg : _secondaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            // Background
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Progress
            FractionallySizedBox(
              widthFactor: percentage / 100,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: _iconBg,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Threshold marker
            Positioned(
              left: 0,
              right: 0,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: thresholdPosition,
                child: Container(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 2,
                    height: 12,
                    color: _secondaryText,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kiwango cha kupita: ${approvalThreshold.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 10,
                color: _secondaryText,
              ),
            ),
            if (minVotes != null && totalMembers != null)
              Text(
                'Kura: $totalVotes/${minVotes!} (wanachama $totalMembers)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: totalVotes >= minVotes! ? FontWeight.w600 : FontWeight.w400,
                  color: totalVotes >= minVotes! ? _iconBg : _secondaryText,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildVoteCounts() {
    return Row(
      children: [
        _buildVoteCountChip('Ndiyo', yesCount, true),
        const SizedBox(width: 8),
        _buildVoteCountChip('Hapana', noCount, false),
        const SizedBox(width: 8),
        _buildVoteCountChip('Sijui', abstainCount, false),
        const Spacer(),
        Text(
          'Jumla: $totalVotes',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildVoteCountChip(String label, int count, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPrimary ? _iconBg : _accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isPrimary ? _buttonBg : _secondaryText,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isPrimary ? _buttonBg : _primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVotingButtons() {
    if (isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircularProgressIndicator(strokeWidth: 2, color: _iconBg),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: _iconBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onVoteYes,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.thumb_up_rounded, size: 16, color: _buttonBg),
                      SizedBox(width: 6),
                      Text(
                        'Ndiyo',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _buttonBg,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: _buttonBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _iconBg, width: 1.5),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onVoteNo,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.thumb_down_rounded, size: 16, color: _iconBg),
                      SizedBox(width: 6),
                      Text(
                        'Hapana',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _iconBg,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: _buttonBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _accent, width: 1),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onVoteAbstain,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Text(
                  'Sijui',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _secondaryText,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserVoteIndicator() {
    String label;
    IconData icon;
    bool isPrimary;

    switch (userVote?.toLowerCase()) {
      case 'yes':
        label = 'Umekubali';
        icon = Icons.thumb_up_rounded;
        isPrimary = true;
        break;
      case 'no':
        label = 'Umekataa';
        icon = Icons.thumb_down_rounded;
        isPrimary = false;
        break;
      case 'abstain':
        label = 'Hukupiga kura';
        icon = Icons.remove_circle_outline_rounded;
        isPrimary = false;
        break;
      default:
        label = 'Umepiga kura';
        icon = Icons.check_circle_rounded;
        isPrimary = true;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isPrimary ? _iconBg : _accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isPrimary ? _buttonBg : _secondaryText),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isPrimary ? _buttonBg : _secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaInfo() {
    return Row(
      children: [
        if (createdBy != null) ...[
          Icon(Icons.person_outline_rounded, size: 14, color: _secondaryText),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              createdBy!,
              style: TextStyle(fontSize: 11, color: _secondaryText),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        if (createdBy != null && createdAt != null) ...[
          const SizedBox(width: 12),
        ],
        if (createdAt != null) ...[
          Icon(Icons.schedule_rounded, size: 14, color: _secondaryText),
          const SizedBox(width: 4),
          Text(
            createdAt!,
            style: TextStyle(fontSize: 11, color: _secondaryText),
          ),
        ],
      ],
    );
  }

  bool _isPendingStatus(String status) {
    final s = status.toLowerCase();
    return s == 'pending' ||
        s == 'pending_approval' ||
        s == 'pending_vote' ||
        s == 'awaiting_vote' ||
        s == 'open';
  }
}
