import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/subscription_models.dart';
import '../../services/subscription_service.dart';
import 'subscriber_list_screen.dart';
import 'payout_request_screen.dart';
import 'payout_history_screen.dart';

/// Creator earnings dashboard showing summary, recent earnings, and quick actions
class EarningsDashboardScreen extends StatefulWidget {
  final int currentUserId;

  const EarningsDashboardScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  State<EarningsDashboardScreen> createState() => _EarningsDashboardScreenState();
}

class _EarningsDashboardScreenState extends State<EarningsDashboardScreen> {
  static const Color _kBg = Color(0xFFFAFAFA);
  static const Color _kPrimary = Color(0xFF1A1A1A);
  static const Color _kSecondary = Color(0xFF666666);
  static const Color _kSuccess = Color(0xFF22C55E);
  static const Color _kWarning = Color(0xFFF59E0B);
  static const Color _kDanger = Color(0xFFEF4444);

  final SubscriptionService _subscriptionService = SubscriptionService();

  EarningsSummary? _summary;
  List<CreatorEarning> _recentEarnings = [];
  int _subscriberCount = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Load summary, recent earnings, and subscriber count in parallel
    final summaryFuture = _subscriptionService.getEarningsSummary(widget.currentUserId);
    final earningsFuture = _subscriptionService.getEarnings(
      userId: widget.currentUserId,
      page: 1,
      perPage: 10,
    );
    final subscribersFuture = _subscriptionService.getSubscribers(
      userId: widget.currentUserId,
      page: 1,
      perPage: 1,
    );

    final results = await Future.wait([summaryFuture, earningsFuture, subscribersFuture]);

    if (!mounted) return;

    final summaryResult = results[0] as EarningsSummaryResult;
    final earningsResult = results[1] as EarningsListResult;
    final subscribersResult = results[2] as SubscriptionListResult;

    if (summaryResult.success) {
      setState(() {
        _isLoading = false;
        _summary = summaryResult.summary;
        _recentEarnings = earningsResult.earnings;
        _subscriberCount = subscribersResult.meta?.total ?? 0;
      });
    } else {
      setState(() {
        _isLoading = false;
        _error = summaryResult.message;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  void _openSubscriberList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubscriberListScreen(currentUserId: widget.currentUserId),
      ),
    );
  }

  void _openPayoutRequest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PayoutRequestScreen(
          currentUserId: widget.currentUserId,
          availableBalance: _summary?.pending ?? 0,
        ),
      ),
    ).then((_) => _loadData());
  }

  void _openPayoutHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PayoutHistoryScreen(currentUserId: widget.currentUserId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(s?.creatorEarnings ?? 'Creator Earnings'),
        backgroundColor: Colors.white,
        foregroundColor: _kPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState(s)
                : RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: _kPrimary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Balance summary card
                          _buildBalanceCard(s),
                          const SizedBox(height: 16),

                          // Quick actions
                          _buildQuickActions(s),
                          const SizedBox(height: 16),

                          // Subscribers summary
                          _buildSubscribersSummary(s),
                          const SizedBox(height: 24),

                          // Recent earnings header
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s?.recentEarnings ?? 'Recent Earnings',
                                  style: const TextStyle(
                                    color: _kPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Recent earnings list
                          if (_recentEarnings.isEmpty)
                            _buildEmptyEarnings(s)
                          else
                            ..._recentEarnings.map((e) => _buildEarningItem(e, s)),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildErrorState(AppStrings? s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _error ?? s?.loadingFailed ?? 'Failed to load',
              style: const TextStyle(color: _kPrimary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: _loadData,
              child: Text(s?.retry ?? 'Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(AppStrings? s) {
    final summary = _summary ?? EarningsSummary(
      totalGross: 0,
      totalNet: 0,
      pending: 0,
      thisMonth: 0,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kPrimary, Color(0xFF333333)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s?.totalEarnings ?? 'Total Earnings',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'TZS ${summary.totalNet.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildBalanceItem(
                  s?.thisMonth ?? 'This Month',
                  'TZS ${summary.thisMonth.toStringAsFixed(0)}',
                  Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBalanceItem(
                  s?.pendingEarnings ?? 'Pending',
                  'TZS ${summary.pending.toStringAsFixed(0)}',
                  _kSuccess,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(AppStrings? s) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.account_balance_wallet_outlined,
            label: s?.requestPayout ?? 'Request Payout',
            onTap: _openPayoutRequest,
            isPrimary: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.history,
            label: s?.payoutHistory ?? 'Payout History',
            onTap: _openPayoutHistory,
            isPrimary: false,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return Material(
      color: isPrimary ? _kPrimary : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: isPrimary
              ? null
              : BoxDecoration(
                  border: Border.all(color: _kSecondary.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isPrimary ? Colors.white : _kPrimary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isPrimary ? Colors.white : _kPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscribersSummary(AppStrings? s) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _openSubscriberList,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _kSuccess.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.people_outline,
                  color: _kSuccess,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s?.mySubscribers ?? 'My Subscribers',
                      style: const TextStyle(
                        color: _kPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s?.subscriberCountNum(_subscriberCount) ?? '$_subscriberCount subscribers',
                      style: const TextStyle(
                        color: _kSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: _kSecondary.withValues(alpha: 0.6),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyEarnings(AppStrings? s) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            s?.noEarningsYet ?? 'No earnings yet',
            style: const TextStyle(
              color: _kPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s?.startCreatingContent ?? 'Start creating content to earn from your subscribers',
            style: const TextStyle(
              color: _kSecondary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEarningItem(CreatorEarning earning, AppStrings? s) {
    IconData icon;
    Color iconColor;
    String typeLabel;

    switch (earning.type) {
      case 'subscription':
        icon = Icons.card_membership;
        iconColor = _kPrimary;
        typeLabel = s?.subscription ?? 'Subscription';
        break;
      case 'tip':
        icon = Icons.favorite;
        iconColor = _kDanger;
        typeLabel = s?.tip ?? 'Tip';
        break;
      case 'gift':
        icon = Icons.card_giftcard;
        iconColor = _kWarning;
        typeLabel = s?.gift ?? 'Gift';
        break;
      default:
        icon = Icons.monetization_on;
        iconColor = _kSecondary;
        typeLabel = earning.type;
    }

    Color statusColor;
    String statusLabel;
    switch (earning.status) {
      case 'pending':
        statusColor = _kWarning;
        statusLabel = s?.payoutPending ?? 'Pending';
        break;
      case 'paid':
        statusColor = _kSuccess;
        statusLabel = s?.payoutCompleted ?? 'Paid';
        break;
      default:
        statusColor = _kSecondary;
        statusLabel = earning.status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeLabel,
                  style: const TextStyle(
                    color: _kPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(earning.createdAt),
                  style: const TextStyle(
                    color: _kSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+TZS ${earning.netAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: _kSuccess,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
