import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/subscription_models.dart';
import '../../services/subscription_service.dart';

/// Screen showing creator's payout history with status filtering
class PayoutHistoryScreen extends StatefulWidget {
  final int currentUserId;

  const PayoutHistoryScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  State<PayoutHistoryScreen> createState() => _PayoutHistoryScreenState();
}

class _PayoutHistoryScreenState extends State<PayoutHistoryScreen> {
  static const Color _kBg = Color(0xFFFAFAFA);
  static const Color _kPrimary = Color(0xFF1A1A1A);
  static const Color _kSecondary = Color(0xFF666666);
  static const Color _kSuccess = Color(0xFF22C55E);
  static const Color _kWarning = Color(0xFFF59E0B);
  static const Color _kDanger = Color(0xFFEF4444);
  static const Color _kInfo = Color(0xFF3B82F6);

  final SubscriptionService _subscriptionService = SubscriptionService();

  List<CreatorPayout> _payouts = [];
  String? _selectedStatus;
  bool _isLoading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _lastPage = 1;

  final List<Map<String, dynamic>> _statusFilters = [
    {'id': null, 'label': 'All'},
    {'id': 'pending', 'label': 'Pending'},
    {'id': 'processing', 'label': 'Processing'},
    {'id': 'completed', 'label': 'Completed'},
    {'id': 'failed', 'label': 'Failed'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPayouts();
  }

  Future<void> _loadPayouts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _subscriptionService.getPayouts(
      userId: widget.currentUserId,
      page: _page,
      status: _selectedStatus,
    );

    if (!mounted) return;
    if (result.success) {
      setState(() {
        _isLoading = false;
        _payouts = result.payouts;
        _lastPage = result.meta?.lastPage ?? 1;
      });
    } else {
      setState(() {
        _isLoading = false;
        _error = result.message;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page >= _lastPage) return;

    setState(() => _loadingMore = true);
    _page++;

    final result = await _subscriptionService.getPayouts(
      userId: widget.currentUserId,
      page: _page,
      status: _selectedStatus,
    );

    if (!mounted) return;
    if (result.success) {
      setState(() {
        _loadingMore = false;
        _payouts.addAll(result.payouts);
      });
    } else {
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _onRefresh() async {
    _page = 1;
    await _loadPayouts();
  }

  void _selectStatus(String? status) {
    if (status == _selectedStatus) return;
    setState(() {
      _selectedStatus = status;
      _page = 1;
    });
    _loadPayouts();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(s?.payoutHistory ?? 'Payout History'),
        backgroundColor: Colors.white,
        foregroundColor: _kPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status filter
            _buildStatusFilter(s),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorState(s)
                      : _payouts.isEmpty
                          ? _buildEmptyState(s)
                          : _buildPayoutsList(s),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter(AppStrings? s) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _statusFilters.map((filter) {
            final isSelected = _selectedStatus == filter['id'];
            String label = filter['label'] as String;

            // Localize labels
            if (s != null) {
              switch (filter['id']) {
                case null:
                  label = s.allSubscriptions;
                  break;
                case 'pending':
                  label = s.payoutPending;
                  break;
                case 'processing':
                  label = s.payoutProcessing;
                  break;
                case 'completed':
                  label = s.payoutCompleted;
                  break;
                case 'failed':
                  label = s.payoutFailed;
                  break;
              }
            }

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(
                label: label,
                isSelected: isSelected,
                onTap: () => _selectStatus(filter['id'] as String?),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? _kPrimary : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? _kPrimary : _kSecondary.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : _kPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
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
              onPressed: _loadPayouts,
              child: Text(s?.retry ?? 'Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppStrings? s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              s?.noPayoutsYet ?? 'No payouts yet',
              style: const TextStyle(
                color: _kPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              s?.requestPayoutToSee ?? 'Request a payout to see your history here',
              style: const TextStyle(
                color: _kSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutsList(AppStrings? s) {
    final hasMore = _page < _lastPage;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: _kPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _payouts.length + (hasMore || _loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _payouts.length) {
            if (_loadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              );
            }
            if (hasMore) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
            }
            return const SizedBox.shrink();
          }

          final payout = _payouts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildPayoutCard(payout, s),
          );
        },
      ),
    );
  }

  Widget _buildPayoutCard(CreatorPayout payout, AppStrings? s) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (payout.status) {
      case 'pending':
        statusColor = _kWarning;
        statusLabel = s?.payoutPending ?? 'Pending';
        statusIcon = Icons.hourglass_empty;
        break;
      case 'processing':
        statusColor = _kInfo;
        statusLabel = s?.payoutProcessing ?? 'Processing';
        statusIcon = Icons.sync;
        break;
      case 'completed':
        statusColor = _kSuccess;
        statusLabel = s?.payoutCompleted ?? 'Completed';
        statusIcon = Icons.check_circle_outline;
        break;
      case 'failed':
        statusColor = _kDanger;
        statusLabel = s?.payoutFailed ?? 'Failed';
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = _kSecondary;
        statusLabel = payout.status;
        statusIcon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TZS ${payout.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: _kPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getProviderDisplayName(payout.provider),
                      style: const TextStyle(
                        color: _kSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Details
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.person_outline,
                  label: s?.accountName ?? 'Account',
                  value: payout.accountName,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.phone_outlined,
                  label: s?.phoneNumber ?? 'Phone',
                  value: payout.accountNumber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.calendar_today_outlined,
                  label: s?.requestedOn ?? 'Requested',
                  value: _formatDate(payout.createdAt),
                ),
              ),
              if (payout.processedAt != null) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.check_circle_outline,
                    label: s?.processedOn ?? 'Processed',
                    value: _formatDate(payout.processedAt!),
                  ),
                ),
              ],
            ],
          ),

          // Failure reason
          if (payout.status == 'failed' && payout.failureReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kDanger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: _kDanger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      payout.failureReason!,
                      style: const TextStyle(
                        color: _kDanger,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Transaction ID
          if (payout.transactionId != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.tag, size: 14, color: _kSecondary),
                const SizedBox(width: 6),
                Text(
                  'ID: ${payout.transactionId}',
                  style: const TextStyle(
                    color: _kSecondary,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _kSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _kSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: _kPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getProviderDisplayName(String? provider) {
    switch (provider) {
      case 'mpesa':
        return 'M-Pesa';
      case 'tigopesa':
        return 'Tigo Pesa';
      case 'airtel':
        return 'Airtel Money';
      case 'halopesa':
        return 'Halo Pesa';
      default:
        return provider ?? 'Mobile Money';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
