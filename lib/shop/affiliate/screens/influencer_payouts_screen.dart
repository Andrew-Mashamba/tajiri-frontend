import 'dart:async';
import 'package:flutter/material.dart';

class InfluencerPayoutsScreen extends StatefulWidget {
  const InfluencerPayoutsScreen({super.key});

  @override
  State<InfluencerPayoutsScreen> createState() =>
      _InfluencerPayoutsScreenState();
}

class _InfluencerPayoutsScreenState extends State<InfluencerPayoutsScreen> {
  bool _loading = true;
  bool _requestingPayout = false;

  static const double _pendingAmount = 5860.0;
  static const double _minThreshold = 2000.0;

  final List<Map<String, String>> _payouts = [
    {
      'amount': 'TZS 12,400',
      'date': 'Apr 28, 2026',
      'method': 'Tajiri Pay',
      'reference': 'TXN-20260428-001',
      'status': 'Completed',
    },
    {
      'amount': 'TZS 8,750',
      'date': 'Apr 14, 2026',
      'method': 'Tajiri Pay',
      'reference': 'TXN-20260414-003',
      'status': 'Completed',
    },
    {
      'amount': 'TZS 15,200',
      'date': 'Mar 31, 2026',
      'method': 'Bank Transfer',
      'reference': 'TXN-20260331-007',
      'status': 'Completed',
    },
    {
      'amount': 'TZS 6,300',
      'date': 'Mar 15, 2026',
      'method': 'Tajiri Pay',
      'reference': 'TXN-20260315-002',
      'status': 'Completed',
    },
    {
      'amount': 'TZS 9,100',
      'date': 'Feb 28, 2026',
      'method': 'Bank Transfer',
      'reference': 'TXN-20260228-005',
      'status': 'Completed',
    },
    {
      'amount': 'TZS 3,450',
      'date': 'Feb 14, 2026',
      'method': 'Tajiri Pay',
      'reference': 'TXN-20260214-001',
      'status': 'Failed',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _onRefresh() async {
    setState(() => _loading = true);
    await _loadData();
  }

  Future<void> _requestPayout() async {
    setState(() => _requestingPayout = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _requestingPayout = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Payout request submitted successfully'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return const Color(0xFF2E7D32);
      case 'Processing':
        return const Color(0xFFF57C00);
      case 'Failed':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF666666);
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'Completed':
        return const Color(0xFFE8F5E9);
      case 'Processing':
        return const Color(0xFFFFF3E0);
      case 'Failed':
        return const Color(0xFFFFEBEE);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  IconData _methodIcon(String method) {
    return method == 'Tajiri Pay'
        ? Icons.account_balance_wallet_rounded
        : Icons.account_balance_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Payouts',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? _buildShimmer()
            : RefreshIndicator(
                color: const Color(0xFF1A1A1A),
                onRefresh: _onRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPendingBanner(),
                      const SizedBox(height: 20),
                      _buildThresholdNote(),
                      const SizedBox(height: 20),
                      _buildPayoutHistory(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPendingBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pending Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'TZS ${_pendingAmount.toStringAsFixed(0).replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]},',
            )}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _requestingPayout ? null : _requestPayout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1A1A1A),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: _requestingPayout
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF1A1A1A),
                      ),
                    )
                  : const Text(
                      'Request Payout',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFF666666),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Minimum payout threshold is TZS ${_minThreshold.toStringAsFixed(0)}. '
              'Payouts are processed within 1-3 business days.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payout History',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        if (_payouts.isEmpty)
          _buildEmptyState()
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: _payouts.asMap().entries.map((entry) {
                final i = entry.key;
                final p = entry.value;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _methodIcon(p['method']!),
                              size: 20,
                              color: const Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p['method']!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p['reference']!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF999999),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p['date']!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF999999),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                p['amount']!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusBg(p['status']!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  p['status']!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _statusColor(p['status']!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (i < _payouts.length - 1)
                      const Divider(height: 1, indent: 72),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.account_balance_wallet_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No payouts yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your payout history will appear here',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 360,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }
}
