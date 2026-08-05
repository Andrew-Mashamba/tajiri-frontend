import 'package:flutter/material.dart';
import '../../../services/local_storage_service.dart';
import '../models/escrow_models.dart';
import '../services/escrow_service.dart';
import 'dispute_detail_screen.dart';

// DESIGN.md tokens
const Color _kBg = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const BoxShadow _kShadow = BoxShadow(
  color: Color(0x1A000000),
  blurRadius: 4,
  offset: Offset(0, 2),
);

/// Seller or admin dispute list with filter tabs.
class DisputesListScreen extends StatefulWidget {
  final int currentUserId;

  const DisputesListScreen({super.key, required this.currentUserId});

  @override
  State<DisputesListScreen> createState() => _DisputesListScreenState();
}

class _DisputesListScreenState extends State<DisputesListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<(String?, String)> _tabs = [
    (null, 'All'),
    ('open', 'Open'),
    ('under_review', 'Under Review'),
    ('resolved_seller', 'Resolved'),
  ];

  List<EscrowDispute> _disputes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadDisputes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) _loadDisputes();
  }

  Future<void> _loadDisputes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken() ?? '';
      final statusFilter = _tabs[_tabController.index].$1;

      // For resolved tab include both seller and buyer resolved
      List<EscrowDispute> results;
      if (statusFilter == 'resolved_seller') {
        final seller = await EscrowService.listDisputes(token,
            status: 'resolved_seller');
        final buyer = await EscrowService.listDisputes(token,
            status: 'resolved_buyer');
        results = [...seller, ...buyer]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        results = await EscrowService.listDisputes(token, status: statusFilter);
      }

      if (mounted) {
        setState(() {
          _loading = false;
          _disputes = results;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Error loading disputes: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text(
          'Disputes',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary),
        ),
        backgroundColor: _kSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: _tabs.map((t) => Tab(text: t.$2)).toList(),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: _tabs.map((_) => _buildList()).toList(),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: _kTertiary),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: _kSecondary)),
            const SizedBox(height: 16),
            OutlinedButton(
                onPressed: _loadDisputes, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_disputes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gavel_rounded, size: 48, color: _kTertiary),
            SizedBox(height: 16),
            Text('No disputes',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _kPrimary)),
            SizedBox(height: 8),
            Text('Disputes on your orders will appear here',
                style: TextStyle(fontSize: 14, color: _kSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadDisputes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _disputes.length,
        itemBuilder: (context, i) => _buildDisputeCard(_disputes[i]),
      ),
    );
  }

  Widget _buildDisputeCard(EscrowDispute d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [_kShadow],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DisputeDetailScreen(
                orderId: d.orderId ?? 0,
                initialDispute: d,
                isSeller: true,
              ),
            ),
          ).then((_) => _loadDisputes()),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.reasonLabel,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _kPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Raised ${_formatDate(d.createdAt)}',
                            style: const TextStyle(
                                fontSize: 12, color: _kTertiary),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(d.status),
                  ],
                ),
                if (d.description != null && d.description!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    d.description!,
                    style: const TextStyle(
                        fontSize: 13, color: _kSecondary, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        size: 14, color: _kTertiary),
                    const SizedBox(width: 4),
                    Text(
                      'Dispute #${d.id}',
                      style: const TextStyle(
                          fontSize: 12, color: _kTertiary),
                    ),
                    if (d.priority != 'normal') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: d.priority == 'urgent'
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          d.priorityLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: d.priority == 'urgent'
                                ? const Color(0xFFDC2626)
                                : const Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (d.isOpen && d.sellerResponse == null)
                      const Text(
                        'Action required',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final (bg, fg, label) = switch (status) {
      'under_review' => (
          const Color(0xFFDBEAFE),
          const Color(0xFF2563EB),
          'Under Review'
        ),
      'resolved_seller' => (
          const Color(0xFFD1FAE5),
          const Color(0xFF059669),
          'Resolved — Seller'
        ),
      'resolved_buyer' => (
          const Color(0xFFD1FAE5),
          const Color(0xFF047857),
          'Resolved — Buyer'
        ),
      'closed' => (
          const Color(0xFFF3F4F6),
          const Color(0xFF6B7280),
          'Closed'
        ),
      _ => (
          const Color(0xFFFEF3C7),
          const Color(0xFFD97706),
          'Open'
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: fg),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.day}/${d.month}/${d.year}';
  }
}
