import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../HttpService.dart';
import '../DataStore.dart';
import '../widgets/voting_card.dart';

// Monochrome design colors (from design-guidelines.md)
const _primaryBg = Color(0xFFFAFAFA);
const _buttonBg = Color(0xFFFFFFFF);
const _primaryText = Color(0xFF1A1A1A);
const _secondaryText = Color(0xFF666666);
const _iconBg = Color(0xFF1A1A1A);
const _accent = Color(0xFF999999);

/// Base class for voting detail screens
abstract class _BaseVotingScreen extends StatefulWidget {
  final String? kikobaId;
  final String? requestId;

  const _BaseVotingScreen({
    super.key,
    this.kikobaId,
    this.requestId,
  });
}

abstract class _BaseVotingScreenState<T extends _BaseVotingScreen> extends State<T> {
  final Logger _logger = Logger();

  bool _isLoading = true;
  bool _isVoting = false;
  String? _error;
  Map<String, dynamic>? _item;

  String get voteableType;
  String get screenTitle;
  IconData get screenIcon;

  String get _kikobaId => widget.kikobaId ?? DataStore.currentKikobaId ?? '';
  String get _requestId => widget.requestId ?? '';

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  Future<void> _loadItem();

  Future<void> _castVote(String vote) async {
    if (_item == null) return;

    final itemId = _item!['id']?.toString() ?? _requestId;
    if (itemId.isEmpty) {
      _showError('ID ya ombi haijulikani');
      return;
    }

    _logger.i('🗳️ Casting vote: "$vote" on $voteableType #$itemId');

    setState(() => _isVoting = true);

    try {
      final response = await HttpService.castVote(
        voteableType: voteableType,
        voteableId: itemId,
        vote: vote,
      );
      _logger.i('🗳️ Vote response: ${response['code']} - ${response['message']}');

      final code = response['code']?.toString() ?? '';

      if (response['success'] == true) {
        _showSuccess('Kura yako imesajiliwa');
        await _loadItem(); // Refresh data
      } else {
        // Show specific error messages based on code
        final errorMessage = _getVoteErrorMessage(code, response['message']);
        _showError(errorMessage);
      }
    } catch (e) {
      _logger.e('Error casting vote: $e');
      _showError('Tatizo la mtandao. Jaribu tena.');
    } finally {
      setState(() => _isVoting = false);
    }
  }

  String _getVoteErrorMessage(String code, dynamic defaultMessage) {
    switch (code) {
      case 'CREATOR_CANNOT_VOTE':
        return 'Huwezi kupiga kura kwenye ombi lako mwenyewe';
      case 'ALREADY_VOTED':
        return 'Tayari umeshapiga kura';
      case 'NOT_A_MEMBER':
        return 'Wewe si mwanachama wa kikoba hiki';
      case 'VOTING_CLOSED':
        return 'Upigaji kura umefungwa';
      case 'REQUEST_NOT_FOUND':
        return 'Ombi halipatikani';
      case 'INVALID_VOTE':
        return 'Kura si sahihi';
      default:
        return defaultMessage?.toString() ?? 'Imeshindwa kupiga kura';
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: _buttonBg, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(color: _buttonBg))),
          ],
        ),
        backgroundColor: _secondaryText,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: _buttonBg, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(color: _buttonBg))),
          ],
        ),
        backgroundColor: _iconBg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryBg,
      appBar: AppBar(
        backgroundColor: _buttonBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: _primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(screenIcon, color: _buttonBg, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              screenTitle,
              style: const TextStyle(
                color: _primaryText,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _iconBg),
            onPressed: _loadItem,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: _iconBg),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_item == null) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadItem,
      color: _iconBg,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildItemCard(),
            const SizedBox(height: 24),
            buildAdditionalDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.error_outline_rounded, size: 32, color: _secondaryText),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _secondaryText),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _loadItem,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.refresh_rounded, size: 18, color: _buttonBg),
                        SizedBox(width: 8),
                        Text('Jaribu Tena', style: TextStyle(color: _buttonBg, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(screenIcon, size: 32, color: _secondaryText),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ombi halipatikani',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard() {
    final title = _item!['title']?.toString() ?? _item!['description']?.toString() ?? 'Ombi';
    final description = _item!['description']?.toString() ?? _item!['reason']?.toString() ?? '';
    final status = _item!['status']?.toString() ?? 'pending';
    final createdBy = _item!['created_by_name']?.toString() ?? _item!['requester_name']?.toString();
    final createdAt = _item!['created_at']?.toString();

    // Voting data
    final voting = _item!['voting'] as Map<String, dynamic>? ?? {};
    final yesCount = voting['yes_count'] as int? ?? 0;
    final noCount = voting['no_count'] as int? ?? 0;
    final abstainCount = voting['abstain_count'] as int? ?? 0;
    final totalVotes = voting['total_votes'] as int? ?? 0;
    final approvalPercentage = (voting['approval_percentage'] as num?)?.toDouble() ?? 0.0;
    final approvalThreshold = (voting['approval_threshold'] as num?)?.toDouble() ?? 50.0;
    final hasVoted = voting['user_has_voted'] == true;
    final userVote = voting['user_vote']?.toString();

    // Extract config for dynamic min_votes
    final config = voting['config'] as Map<String, dynamic>? ?? {};
    final minVotes = config['min_votes'] as int?;
    final totalMembers = config['total_members'] as int?;

    return VotingCard(
      title: title,
      description: description,
      type: voteableType,
      status: status,
      createdBy: createdBy,
      createdAt: createdAt,
      yesCount: yesCount,
      noCount: noCount,
      abstainCount: abstainCount,
      totalVotes: totalVotes,
      approvalPercentage: approvalPercentage,
      approvalThreshold: approvalThreshold,
      minVotes: minVotes,
      totalMembers: totalMembers,
      hasVoted: hasVoted,
      userVote: userVote,
      isLoading: _isVoting,
      onVoteYes: () => _castVote('yes'),
      onVoteNo: () => _castVote('no'),
      onVoteAbstain: () => _castVote('abstain'),
    );
  }

  Widget buildAdditionalDetails();
}

// ============================================================================
// Membership Removal Voting Screen
// ============================================================================
class MembershipRemovalVotingScreen extends _BaseVotingScreen {
  const MembershipRemovalVotingScreen({
    super.key,
    super.kikobaId,
    super.requestId,
  });

  @override
  State<MembershipRemovalVotingScreen> createState() => _MembershipRemovalVotingScreenState();
}

class _MembershipRemovalVotingScreenState extends _BaseVotingScreenState<MembershipRemovalVotingScreen> {
  @override
  String get voteableType => 'membership_removal';

  @override
  String get screenTitle => 'Kuondoa Mwanachama';

  @override
  IconData get screenIcon => Icons.person_remove_rounded;

  @override
  Future<void> _loadItem() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await HttpService.getMembershipRemovalDetails(
        requestId: _requestId,
      );

      if (response['success'] == true) {
        setState(() {
          _item = response['data'] as Map<String, dynamic>?;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Imeshindwa kupakia maelezo';
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.e('Error loading membership removal: $e');
      setState(() {
        _error = 'Tatizo la mtandao. Jaribu tena.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget buildAdditionalDetails() {
    if (_item == null) return const SizedBox.shrink();

    final memberName = _item!['member_name']?.toString();
    final memberPhone = _item!['member_phone']?.toString();
    final removalType = _item!['removal_type']?.toString();
    final reason = _item!['reason']?.toString();

    return Container(
      decoration: BoxDecoration(
        color: _buttonBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Maelezo ya Mwanachama',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _primaryText,
              ),
            ),
            const SizedBox(height: 16),
            if (memberName != null)
              _buildInfoRow(Icons.person_rounded, 'Jina', memberName),
            if (memberPhone != null)
              _buildInfoRow(Icons.phone_rounded, 'Simu', memberPhone),
            if (removalType != null)
              _buildInfoRow(Icons.category_rounded, 'Aina', _getRemovalTypeLabel(removalType)),
            if (reason != null)
              _buildInfoRow(Icons.description_rounded, 'Sababu', reason),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: _buttonBg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: _secondaryText),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _primaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRemovalTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'voluntary':
        return 'Hiari';
      case 'disciplinary':
        return 'Nidhamu';
      case 'inactive':
        return 'Kutokuwa hai';
      case 'deceased':
        return 'Amefariki';
      default:
        return type;
    }
  }
}

// ============================================================================
// Expense Request Voting Screen
// ============================================================================
class ExpenseRequestVotingScreen extends _BaseVotingScreen {
  const ExpenseRequestVotingScreen({
    super.key,
    super.kikobaId,
    super.requestId,
  });

  @override
  State<ExpenseRequestVotingScreen> createState() => _ExpenseRequestVotingScreenState();
}

class _ExpenseRequestVotingScreenState extends _BaseVotingScreenState<ExpenseRequestVotingScreen> {
  @override
  String get voteableType => 'expense_request';

  @override
  String get screenTitle => 'Ombi la Matumizi';

  @override
  IconData get screenIcon => Icons.receipt_long_rounded;

  @override
  Future<void> _loadItem() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await HttpService.getExpenseRequestDetails(
        requestId: _requestId,
      );

      if (response['success'] == true) {
        setState(() {
          _item = response['data'] as Map<String, dynamic>?;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Imeshindwa kupakia maelezo';
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.e('Error loading expense request: $e');
      setState(() {
        _error = 'Tatizo la mtandao. Jaribu tena.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget buildAdditionalDetails() {
    if (_item == null) return const SizedBox.shrink();

    final amount = _item!['amount'];
    final category = _item!['category']?.toString();
    final payeeName = _item!['payee_name']?.toString();
    final accountName = _item!['account_name']?.toString();

    return Container(
      decoration: BoxDecoration(
        color: _buttonBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Maelezo ya Matumizi',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _primaryText,
              ),
            ),
            const SizedBox(height: 16),
            // Amount highlight
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _buttonBg.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.payments_rounded, size: 20, color: _buttonBg),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kiasi',
                        style: TextStyle(fontSize: 11, color: _buttonBg.withOpacity(0.7)),
                      ),
                      Text(
                        'TZS ${_formatAmount(amount)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _buttonBg,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (category != null)
              _buildInfoRow(Icons.category_rounded, 'Kategoria', category),
            if (payeeName != null)
              _buildInfoRow(Icons.person_rounded, 'Mpokeaji', payeeName),
            if (accountName != null)
              _buildInfoRow(Icons.account_balance_wallet_rounded, 'Akaunti', accountName),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: _secondaryText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: _secondaryText)),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _primaryText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    final num = double.tryParse(amount.toString()) ?? 0;
    return num.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

// ============================================================================
// Katiba Change Voting Screen
// ============================================================================
class KatibaChangeVotingScreen extends _BaseVotingScreen {
  const KatibaChangeVotingScreen({
    super.key,
    super.kikobaId,
    super.requestId,
  });

  @override
  State<KatibaChangeVotingScreen> createState() => _KatibaChangeVotingScreenState();
}

class _KatibaChangeVotingScreenState extends _BaseVotingScreenState<KatibaChangeVotingScreen> {
  @override
  String get voteableType => 'katiba_change';

  @override
  String get screenTitle => 'Mabadiliko ya Katiba';

  @override
  IconData get screenIcon => Icons.gavel_rounded;

  @override
  Future<void> _loadItem() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await HttpService.getKatibaChangeDetails(
        requestId: _requestId,
      );

      if (response['success'] == true) {
        setState(() {
          _item = response['data'] as Map<String, dynamic>?;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Imeshindwa kupakia maelezo';
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.e('Error loading katiba change: $e');
      setState(() {
        _error = 'Tatizo la mtandao. Jaribu tena.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget buildAdditionalDetails() {
    // All content is now in _buildItemCard via additionalContent
    return const SizedBox.shrink();
  }

  /// Build the change comparison widget to pass as additionalContent
  Widget _buildChangeComparison() {
    final changeType = _item!['change_type']?.toString() ?? '';
    final currentValue = _item!['current_value'];
    final proposedValue = _item!['proposed_value'];

    final currentDisplay = _formatValue(currentValue, changeType);
    final proposedDisplay = _formatValue(proposedValue, changeType);
    final changeInfo = _getChangeInfo(changeType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Change type indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: changeInfo.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(changeInfo.icon, color: changeInfo.color, size: 14),
              const SizedBox(width: 6),
              Text(
                changeInfo.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: changeInfo.color,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Before/After comparison
        Row(
          children: [
            // Current value
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Sasa',
                      style: TextStyle(fontSize: 10, color: _secondaryText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentDisplay,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _primaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Arrow
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward_rounded, color: Colors.green, size: 20),
            ),

            // Proposed value
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Mpya',
                      style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      proposedDisplay,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget _buildItemCard() {
    if (_item == null) return const SizedBox.shrink();

    final title = _item!['title']?.toString() ?? _item!['description']?.toString() ?? 'Ombi la Mabadiliko';
    final description = _item!['description']?.toString() ?? _item!['reason']?.toString() ?? '';
    final status = _item!['status']?.toString() ?? 'pending';
    final createdBy = _item!['created_by_name']?.toString() ?? _item!['requester_name']?.toString();
    final createdAt = _item!['created_at']?.toString();

    // Voting data
    final voting = _item!['voting'] as Map<String, dynamic>? ?? {};
    final yesCount = voting['yes_count'] as int? ?? 0;
    final noCount = voting['no_count'] as int? ?? 0;
    final abstainCount = voting['abstain_count'] as int? ?? 0;
    final totalVotes = voting['total_votes'] as int? ?? 0;
    final approvalPercentage = (voting['approval_percentage'] as num?)?.toDouble() ?? 0.0;
    final approvalThreshold = (voting['approval_threshold'] as num?)?.toDouble() ?? 50.0;
    final hasVoted = voting['user_has_voted'] == true;
    final userVote = voting['user_vote']?.toString();

    // Extract config for dynamic min_votes
    final config = voting['config'] as Map<String, dynamic>? ?? {};
    final minVotes = config['min_votes'] as int?;
    final totalMembers = config['total_members'] as int?;

    return VotingCard(
      title: title,
      description: description,
      type: voteableType,
      status: status,
      createdBy: createdBy,
      createdAt: createdAt,
      yesCount: yesCount,
      noCount: noCount,
      abstainCount: abstainCount,
      totalVotes: totalVotes,
      approvalPercentage: approvalPercentage,
      approvalThreshold: approvalThreshold,
      minVotes: minVotes,
      totalMembers: totalMembers,
      hasVoted: hasVoted,
      userVote: userVote,
      isLoading: _isVoting,
      onVoteYes: () => _castVote('yes'),
      onVoteNo: () => _castVote('no'),
      onVoteAbstain: () => _castVote('abstain'),
      additionalContent: _buildChangeComparison(),
      margin: EdgeInsets.zero,
    );
  }

  /// Format value based on change type
  String _formatValue(dynamic value, String changeType) {
    if (value == null) return 'Hakuna';

    // Handle Map/JSON objects
    if (value is Map) {
      // Extract amount or value from map
      final amount = value['amount'] ?? value['value'] ?? value['kiasi'];
      final status = value['status'];

      if (amount != null) {
        return _formatAmount(amount, changeType);
      }
      if (status != null) {
        return status == '1' || status == 'inactive' ? 'Imezimwa' : 'Imewashwa';
      }
      // Return first meaningful value
      for (var key in ['name', 'label', 'description']) {
        if (value[key] != null) return value[key].toString();
      }
      return 'Hakuna';
    }

    // Handle string/number values
    return _formatAmount(value, changeType);
  }

  /// Format amount with currency or percentage
  String _formatAmount(dynamic value, String changeType) {
    // Check if it's a status value
    if (value == '1' || value == 'inactive' || value == 'disabled') {
      return 'Imezimwa';
    }
    if (value == '0' || value == 'active' || value == 'enabled') {
      return 'Imewashwa';
    }

    // Try to parse as number
    num? numValue;
    if (value is num) {
      numValue = value;
    } else {
      numValue = num.tryParse(value.toString().replaceAll(',', ''));
    }

    if (numValue == null) {
      return value.toString();
    }

    // Format based on change type
    if (changeType.toLowerCase() == 'riba') {
      return '${numValue.toStringAsFixed(1)}%';
    }

    // Currency format for amounts
    return 'TZS ${_formatNumber(numValue)}';
  }

  /// Format number with thousand separators
  String _formatNumber(num value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  /// Get change type info with icon and color
  _ChangeTypeInfo _getChangeInfo(String type) {
    switch (type.toLowerCase()) {
      case 'kiingilio':
        return _ChangeTypeInfo(
          label: 'Kiingilio',
          description: 'Ada ya kujiunga na kikoba',
          icon: Icons.person_add_rounded,
          color: Colors.blue,
        );
      case 'ada':
        return _ChangeTypeInfo(
          label: 'Ada ya Mwezi',
          description: 'Mchango wa kila mwezi',
          icon: Icons.calendar_month_rounded,
          color: Colors.purple,
        );
      case 'hisa':
        return _ChangeTypeInfo(
          label: 'Hisa',
          description: 'Kiasi cha hisa kwa mwezi',
          icon: Icons.pie_chart_rounded,
          color: Colors.teal,
        );
      case 'riba':
        return _ChangeTypeInfo(
          label: 'Riba',
          description: 'Asilimia ya riba kwa mikopo',
          icon: Icons.percent_rounded,
          color: Colors.orange,
        );
      case 'faini_vikao':
        return _ChangeTypeInfo(
          label: 'Faini ya Vikao',
          description: 'Adhabu ya kutokuhudhuria vikao',
          icon: Icons.event_busy_rounded,
          color: Colors.red,
        );
      case 'faini_ada':
        return _ChangeTypeInfo(
          label: 'Faini ya Ada',
          description: 'Adhabu ya kuchelewa kulipa ada',
          icon: Icons.money_off_rounded,
          color: Colors.red,
        );
      case 'faini_hisa':
        return _ChangeTypeInfo(
          label: 'Faini ya Hisa',
          description: 'Adhabu ya kuchelewa kununua hisa',
          icon: Icons.trending_down_rounded,
          color: Colors.red,
        );
      case 'faini_michango':
        return _ChangeTypeInfo(
          label: 'Faini ya Michango',
          description: 'Adhabu ya kuchelewa kutoa mchango',
          icon: Icons.volunteer_activism_rounded,
          color: Colors.red,
        );
      case 'loan_product':
        return _ChangeTypeInfo(
          label: 'Bidhaa ya Mkopo',
          description: 'Mabadiliko ya bidhaa za mikopo',
          icon: Icons.account_balance_rounded,
          color: Colors.indigo,
        );
      default:
        return _ChangeTypeInfo(
          label: 'Mabadiliko ya Katiba',
          description: 'Marekebisho ya sheria za kikoba',
          icon: Icons.gavel_rounded,
          color: _iconBg,
        );
    }
  }

  /// Get impact message based on change type
  String _getImpactMessage(String changeType) {
    switch (changeType.toLowerCase()) {
      case 'kiingilio':
        return 'Mabadiliko haya yataathiri wanachama wapya wanaojiunga na kikoba.';
      case 'ada':
        return 'Mabadiliko haya yataathiri ada ya kila mwezi kwa wanachama wote.';
      case 'hisa':
        return 'Mabadiliko haya yataathiri kiasi cha hisa kinachohitajika kwa kila mwanachama.';
      case 'riba':
        return 'Mabadiliko haya yataathiri riba ya mikopo yote mipya.';
      case 'faini_vikao':
      case 'faini_ada':
      case 'faini_hisa':
      case 'faini_michango':
        return 'Mabadiliko haya yataathiri faini kwa wanachama wanaokiuka sheria.';
      default:
        return 'Mabadiliko haya yataathiri utendaji wa kikoba. Tafadhali soma kwa makini.';
    }
  }
}

/// Helper class for change type info
class _ChangeTypeInfo {
  final String label;
  final String description;
  final IconData icon;
  final Color color;

  _ChangeTypeInfo({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });
}

// ============================================================================
// Fine Approval Voting Screen
// ============================================================================
class FineApprovalVotingScreen extends _BaseVotingScreen {
  const FineApprovalVotingScreen({
    super.key,
    super.kikobaId,
    super.requestId,
  });

  @override
  State<FineApprovalVotingScreen> createState() => _FineApprovalVotingScreenState();
}

class _FineApprovalVotingScreenState extends _BaseVotingScreenState<FineApprovalVotingScreen> {
  @override
  String get voteableType => 'fine_approval';

  @override
  String get screenTitle => 'Idhini ya Faini';

  @override
  IconData get screenIcon => Icons.money_off_rounded;

  @override
  Future<void> _loadItem() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await HttpService.getFineApprovalDetails(
        requestId: _requestId,
      );

      if (response['success'] == true) {
        setState(() {
          _item = response['data'] as Map<String, dynamic>?;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Imeshindwa kupakia maelezo';
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.e('Error loading fine approval: $e');
      setState(() {
        _error = 'Tatizo la mtandao. Jaribu tena.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget buildAdditionalDetails() {
    if (_item == null) return const SizedBox.shrink();

    final memberName = _item!['member_name']?.toString();
    final fineType = _item!['fine_type']?.toString();
    final amount = _item!['amount'];
    final reason = _item!['reason']?.toString();

    return Container(
      decoration: BoxDecoration(
        color: _buttonBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Maelezo ya Faini',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _primaryText,
              ),
            ),
            const SizedBox(height: 16),
            // Amount highlight
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _buttonBg.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.money_off_rounded, size: 20, color: _buttonBg),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kiasi cha Faini',
                        style: TextStyle(fontSize: 11, color: _buttonBg.withOpacity(0.7)),
                      ),
                      Text(
                        'TZS ${_formatAmount(amount)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _buttonBg,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (memberName != null)
              _buildInfoRow(Icons.person_rounded, 'Mwanachama', memberName),
            if (fineType != null)
              _buildInfoRow(Icons.category_rounded, 'Aina ya Faini', _getFineTypeLabel(fineType)),
            if (reason != null)
              _buildInfoRow(Icons.description_rounded, 'Sababu', reason),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: _secondaryText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: _secondaryText)),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _primaryText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    final num = double.tryParse(amount.toString()) ?? 0;
    return num.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _getFineTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'vikao':
        return 'Faini ya Vikao';
      case 'ada':
        return 'Faini ya Ada';
      case 'hisa':
        return 'Faini ya Hisa';
      case 'michango':
        return 'Faini ya Michango';
      default:
        return type;
    }
  }
}

// ============================================================================
// Loan Application Voting Screen
// ============================================================================

class LoanApplicationVotingScreen extends _BaseVotingScreen {
  final String? applicationId;

  const LoanApplicationVotingScreen({
    super.key,
    super.kikobaId,
    super.requestId,
    this.applicationId,
  });

  @override
  State<LoanApplicationVotingScreen> createState() => _LoanApplicationVotingScreenState();
}

class _LoanApplicationVotingScreenState extends _BaseVotingScreenState<LoanApplicationVotingScreen> {
  @override
  String get voteableType => 'loan_application';

  @override
  String get screenTitle => 'Ombi la Mkopo';

  @override
  IconData get screenIcon => Icons.account_balance_rounded;

  String get _applicationId => widget.applicationId ?? widget.requestId ?? '';

  @override
  Future<void> _loadItem() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await HttpService.getLoanApplicationDetails(
        applicationId: _applicationId,
      );

      if (response['success'] == true) {
        setState(() {
          _item = response['data'] as Map<String, dynamic>?;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Imeshindwa kupakia maelezo ya mkopo';
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.e('Error loading loan application: $e');
      setState(() {
        _error = 'Tatizo la mtandao. Jaribu tena.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget buildAdditionalDetails() {
    if (_item == null) return const SizedBox.shrink();

    final applicantName = _item!['applicant_name']?.toString() ?? _item!['member_name']?.toString();
    final amount = _item!['amount'] ?? _item!['principal_amount'];
    final tenure = _item!['tenure']?.toString();
    final purpose = _item!['purpose']?.toString() ?? _item!['reason']?.toString();
    final interestRate = _item!['interest_rate'];
    final monthlyPayment = _item!['monthly_payment'] ?? _item!['monthly_installment'];
    final totalRepayment = _item!['total_repayment'];
    final guarantors = _item!['guarantors'] as List<dynamic>?;
    final loanProduct = _item!['loan_product'] as Map<String, dynamic>?;

    return Column(
      children: [
        // Main loan details card
        Container(
          decoration: BoxDecoration(
            color: _buttonBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Maelezo ya Mkopo',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _primaryText,
                  ),
                ),
                const SizedBox(height: 16),
                // Amount highlight
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _buttonBg.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.attach_money_rounded, size: 20, color: _buttonBg),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kiasi Kinachoombwa',
                            style: TextStyle(fontSize: 11, color: _buttonBg.withOpacity(0.7)),
                          ),
                          Text(
                            'TZS ${_formatAmount(amount)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: _buttonBg,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (applicantName != null)
                  _buildInfoRow(Icons.person_rounded, 'Mwombaji', applicantName),
                if (tenure != null)
                  _buildInfoRow(Icons.calendar_month_rounded, 'Muda wa Kulipa', '$tenure miezi'),
                if (interestRate != null)
                  _buildInfoRow(Icons.percent_rounded, 'Riba', '${interestRate}%'),
                if (monthlyPayment != null)
                  _buildInfoRow(Icons.payments_rounded, 'Malipo ya Kila Mwezi', 'TZS ${_formatAmount(monthlyPayment)}'),
                if (totalRepayment != null)
                  _buildInfoRow(Icons.account_balance_wallet_rounded, 'Jumla ya Kulipa', 'TZS ${_formatAmount(totalRepayment)}'),
                if (purpose != null)
                  _buildInfoRow(Icons.description_rounded, 'Sababu/Madhumuni', purpose),
                if (loanProduct != null && loanProduct['name'] != null)
                  _buildInfoRow(Icons.inventory_2_rounded, 'Aina ya Mkopo', loanProduct['name'].toString()),
              ],
            ),
          ),
        ),

        // Guarantors section
        if (guarantors != null && guarantors.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildGuarantorsSection(guarantors),
        ],
      ],
    );
  }

  Widget _buildGuarantorsSection(List<dynamic> guarantors) {
    return Container(
      decoration: BoxDecoration(
        color: _buttonBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.people_rounded, size: 14, color: _buttonBg),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Wadhamini',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _primaryText,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${guarantors.length}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _secondaryText),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...guarantors.map((g) {
              final guarantor = g as Map<String, dynamic>?;
              if (guarantor == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_outline_rounded, size: 16, color: _secondaryText),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            guarantor['name']?.toString() ?? guarantor['guarantor_name']?.toString() ?? 'Mdhamini',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _primaryText),
                          ),
                          if (guarantor['phone'] != null || guarantor['guarantor_phone'] != null)
                            Text(
                              guarantor['phone']?.toString() ?? guarantor['guarantor_phone']?.toString() ?? '',
                              style: const TextStyle(fontSize: 11, color: _secondaryText),
                            ),
                        ],
                      ),
                    ),
                    if (guarantor['status'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getGuarantorStatusColor(guarantor['status'].toString()),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getGuarantorStatusLabel(guarantor['status'].toString()),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _buttonBg),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getGuarantorStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'accepted':
        return const Color(0xFF2E7D32);
      case 'rejected':
      case 'declined':
        return const Color(0xFFC62828);
      case 'pending':
      default:
        return _secondaryText;
    }
  }

  String _getGuarantorStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'accepted':
        return 'Amekubali';
      case 'rejected':
      case 'declined':
        return 'Amekataa';
      case 'pending':
      default:
        return 'Anasubiri';
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: _secondaryText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: _secondaryText)),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _primaryText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    final num = double.tryParse(amount.toString()) ?? 0;
    return num.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

// ============================================================================
// Membership Request (Join) Voting Screen
// ============================================================================
class MembershipRequestVotingScreen extends _BaseVotingScreen {
  const MembershipRequestVotingScreen({
    super.key,
    super.kikobaId,
    super.requestId,
  });

  @override
  State<MembershipRequestVotingScreen> createState() => _MembershipRequestVotingScreenState();
}

class _MembershipRequestVotingScreenState extends _BaseVotingScreenState<MembershipRequestVotingScreen> {
  @override
  String get voteableType => 'membership_request';

  @override
  String get screenTitle => 'Ombi la Kujiunga';

  @override
  IconData get screenIcon => Icons.person_add_rounded;

  @override
  Future<void> _loadItem() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await HttpService.getMembershipRequestDetails(
        requestId: _requestId,
      );

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>?;

        if (data != null) {
          // Transform response to match base class expectations
          final requester = data['requester'] as Map<String, dynamic>?;
          final kikoba = data['kikoba'] as Map<String, dynamic>?;
          final votes = data['votes'] as Map<String, dynamic>?;

          final yesCount = votes?['yes'] as int? ?? 0;
          final noCount = votes?['no'] as int? ?? 0;
          final totalVotes = votes?['total'] as int? ?? (yesCount + noCount);
          final approvalPercentage = totalVotes > 0
              ? (yesCount / totalVotes * 100)
              : 0.0;

          // Normalize data structure for base class
          data['id'] = data['request_id'];
          data['title'] = 'Ombi la Kujiunga';
          data['description'] = '${requester?['name'] ?? 'Mtu'} anaomba kujiunga na kikoba "${kikoba?['name'] ?? ''}"';
          data['created_by_name'] = requester?['name'];
          data['voting'] = {
            'yes_count': yesCount,
            'no_count': noCount,
            'abstain_count': 0,
            'total_votes': totalVotes,
            'approval_percentage': approvalPercentage,
            'approval_threshold': 66.67, // 2/3 majority for membership
          };
        }

        setState(() {
          _item = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Imeshindwa kupakia maelezo';
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.e('Error loading membership request: $e');
      setState(() {
        _error = 'Tatizo la mtandao. Jaribu tena.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget buildAdditionalDetails() {
    // All content is now in _buildItemCard via additionalContent
    return const SizedBox.shrink();
  }

  /// Build applicant details widget to pass as additionalContent
  Widget _buildApplicantDetails() {
    final requester = _item!['requester'] as Map<String, dynamic>?;
    final kikoba = _item!['kikoba'] as Map<String, dynamic>?;

    final requesterName = requester?['name']?.toString() ?? 'Mwombaji';
    final requesterPhone = requester?['phone']?.toString();
    final memberCount = kikoba?['member_count'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Applicant profile section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    requesterName.isNotEmpty ? requesterName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _buttonBg,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name and phone
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requesterName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _primaryText,
                      ),
                    ),
                    if (requesterPhone != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone_rounded, size: 12, color: _secondaryText),
                          const SizedBox(width: 4),
                          Text(
                            requesterPhone,
                            style: TextStyle(
                              fontSize: 12,
                              color: _secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Member count badge
              if (memberCount != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _iconBg.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_rounded, size: 14, color: _iconBg),
                      const SizedBox(width: 4),
                      Text(
                        '$memberCount',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Action indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.how_to_reg_rounded, color: Colors.blue.shade700, size: 14),
              const SizedBox(width: 6),
              Text(
                'Anaomba kuwa mwanachama',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget _buildItemCard() {
    if (_item == null) return const SizedBox.shrink();

    final title = _item!['title']?.toString() ?? 'Ombi la Kujiunga';
    final description = _item!['description']?.toString() ?? '';
    final status = _item!['status']?.toString() ?? 'pending';
    final createdBy = _item!['created_by_name']?.toString();
    final createdAt = _item!['created_at']?.toString();

    // Voting data
    final voting = _item!['voting'] as Map<String, dynamic>? ?? {};
    final yesCount = voting['yes_count'] as int? ?? 0;
    final noCount = voting['no_count'] as int? ?? 0;
    final abstainCount = voting['abstain_count'] as int? ?? 0;
    final totalVotes = voting['total_votes'] as int? ?? 0;
    final approvalPercentage = (voting['approval_percentage'] as num?)?.toDouble() ?? 0.0;
    final approvalThreshold = (voting['approval_threshold'] as num?)?.toDouble() ?? 66.67;
    final hasVoted = voting['user_has_voted'] == true;
    final userVote = voting['user_vote']?.toString();

    // Extract config for dynamic min_votes
    final config = voting['config'] as Map<String, dynamic>? ?? {};
    final minVotes = config['min_votes'] as int?;
    final totalMembers = config['total_members'] as int?;

    return VotingCard(
      title: title,
      description: description,
      type: voteableType,
      status: status,
      createdBy: createdBy,
      createdAt: createdAt != null ? _formatDate(createdAt) : null,
      yesCount: yesCount,
      noCount: noCount,
      abstainCount: abstainCount,
      totalVotes: totalVotes,
      approvalPercentage: approvalPercentage,
      approvalThreshold: approvalThreshold,
      minVotes: minVotes,
      totalMembers: totalMembers,
      hasVoted: hasVoted,
      userVote: userVote,
      isLoading: _isVoting,
      onVoteYes: () => _castVote('yes'),
      onVoteNo: () => _castVote('no'),
      onVoteAbstain: () => _castVote('abstain'),
      additionalContent: _buildApplicantDetails(),
      margin: EdgeInsets.zero,
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}
