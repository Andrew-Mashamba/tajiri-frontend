// lib/my_wallet/pages/payment_requests_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/wallet_models.dart';
import '../../services/wallet_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class PaymentRequestsPage extends StatefulWidget {
  final int userId;
  const PaymentRequestsPage({super.key, required this.userId});

  @override
  State<PaymentRequestsPage> createState() => _PaymentRequestsPageState();
}

class _PaymentRequestsPageState extends State<PaymentRequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final WalletService _walletService = WalletService();

  List<PaymentRequest> _received = [];
  List<PaymentRequest> _sent = [];
  bool _isLoadingReceived = true;
  bool _isLoadingSent = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReceived();
    _loadSent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReceived() async {
    setState(() => _isLoadingReceived = true);
    try {
      final result = await _walletService.getPaymentRequests(
        userId: widget.userId,
        direction: 'received',
      );
      if (mounted) {
        setState(() {
          _isLoadingReceived = false;
          if (result.success) _received = result.requests;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingReceived = false);
    }
  }

  Future<void> _loadSent() async {
    setState(() => _isLoadingSent = true);
    try {
      final result = await _walletService.getPaymentRequests(
        userId: widget.userId,
        direction: 'sent',
      );
      if (mounted) {
        setState(() {
          _isLoadingSent = false;
          if (result.success) _sent = result.requests;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSent = false);
    }
  }

  String _formatAmount(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(',');
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }

  String _formatDate(DateTime date, bool isSwahili) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return isSwahili ? 'Leo' : 'Today';
    if (diff.inDays == 1) return isSwahili ? 'Jana' : 'Yesterday';
    if (diff.inDays < 7) return isSwahili ? '${diff.inDays} siku zilizopita' : '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          isSwahili ? 'Maombi ya Malipo' : 'Payment Requests',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          tabs: [
            Tab(text: '${isSwahili ? 'Nimepokelewa' : 'Received'} (${_received.length})'),
            Tab(text: '${isSwahili ? 'Nimetuma' : 'Sent'} (${_sent.length})'),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: TabBarView(
          controller: _tabController,
          children: [
            // Received
            _buildRequestList(_received, _isLoadingReceived, isReceived: true),
            // Sent
            _buildRequestList(_sent, _isLoadingSent, isReceived: false),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestList(List<PaymentRequest> requests, bool isLoading, {required bool isReceived}) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
    }

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              isSwahili ? 'Hakuna maombi' : 'No requests',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: isReceived ? _loadReceived : _loadSent,
      color: _kPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          final person = isReceived ? request.requester : request.payer;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _kPrimary.withValues(alpha: 0.1),
                      child: Text(
                        (person?.fullName ?? '?')[0].toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            person?.fullName ?? (isSwahili ? 'Mtumiaji' : 'User'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _formatDate(request.createdAt, isSwahili),
                            style: const TextStyle(fontSize: 12, color: _kSecondary),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'TZS ${_formatAmount(request.amount)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                  ],
                ),
                if (request.description != null && request.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    request.description!,
                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (request.isPending && isReceived) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () {
                              // TODO: Decline payment request
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _kSecondary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(isSwahili ? 'Kataa' : 'Decline'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: () {
                              // TODO: Pay request
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: _kPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(isSwahili ? 'Lipa' : 'Pay'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (!request.isPending) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: request.status == 'paid'
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      request.status == 'paid'
                          ? (isSwahili ? 'Imelipwa' : 'Paid')
                          : (isSwahili ? 'Imeisha muda' : 'Expired'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: request.status == 'paid'
                            ? const Color(0xFF4CAF50)
                            : _kSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
