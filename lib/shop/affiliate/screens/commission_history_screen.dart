import 'dart:async';
import 'package:flutter/material.dart';

class CommissionHistoryScreen extends StatefulWidget {
  const CommissionHistoryScreen({super.key});

  @override
  State<CommissionHistoryScreen> createState() =>
      _CommissionHistoryScreenState();
}

class _CommissionHistoryScreenState extends State<CommissionHistoryScreen> {
  bool _loading = true;
  String _filter = 'All';
  final ScrollController _scrollController = ScrollController();
  bool _loadingMore = false;

  static const List<String> _filters = ['All', 'Pending', 'Paid', 'Cancelled'];

  final List<Map<String, String>> _allCommissions = [
    {
      'product': 'Wireless Earbuds Pro',
      'orderAmount': 'TZS 15,000',
      'commission': 'TZS 1,200',
      'date': 'May 6, 2026',
      'status': 'Paid',
      'thumb': '',
    },
    {
      'product': 'Slim Leather Wallet',
      'orderAmount': 'TZS 4,250',
      'commission': 'TZS 340',
      'date': 'May 5, 2026',
      'status': 'Pending',
      'thumb': '',
    },
    {
      'product': 'Running Shoes X1',
      'orderAmount': 'TZS 9,750',
      'commission': 'TZS 780',
      'date': 'May 4, 2026',
      'status': 'Paid',
      'thumb': '',
    },
    {
      'product': 'Smart Watch Series 3',
      'orderAmount': 'TZS 26,250',
      'commission': 'TZS 2,100',
      'date': 'May 3, 2026',
      'status': 'Paid',
      'thumb': '',
    },
    {
      'product': 'Portable Charger 20K',
      'orderAmount': 'TZS 5,250',
      'commission': 'TZS 420',
      'date': 'May 2, 2026',
      'status': 'Cancelled',
      'thumb': '',
    },
    {
      'product': 'Noise Cancelling Headphones',
      'orderAmount': 'TZS 18,500',
      'commission': 'TZS 1,480',
      'date': 'May 1, 2026',
      'status': 'Paid',
      'thumb': '',
    },
    {
      'product': 'Bluetooth Speaker Mini',
      'orderAmount': 'TZS 6,800',
      'commission': 'TZS 544',
      'date': 'Apr 30, 2026',
      'status': 'Pending',
      'thumb': '',
    },
    {
      'product': 'USB-C Hub 7-in-1',
      'orderAmount': 'TZS 3,200',
      'commission': 'TZS 256',
      'date': 'Apr 29, 2026',
      'status': 'Paid',
      'thumb': '',
    },
    {
      'product': 'Laptop Stand Adjustable',
      'orderAmount': 'TZS 4,500',
      'commission': 'TZS 360',
      'date': 'Apr 28, 2026',
      'status': 'Cancelled',
      'thumb': '',
    },
    {
      'product': 'Mechanical Keyboard TKL',
      'orderAmount': 'TZS 12,000',
      'commission': 'TZS 960',
      'date': 'Apr 27, 2026',
      'status': 'Paid',
      'thumb': '',
    },
  ];

  List<Map<String, String>> _displayed = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _displayed = _filteredCommissions().take(6).toList();
    });
  }

  List<Map<String, String>> _filteredCommissions() {
    if (_filter == 'All') return _allCommissions;
    return _allCommissions
        .where((c) => c['status'] == _filter)
        .toList();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_loadingMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    final full = _filteredCommissions();
    if (_displayed.length >= full.length) return;
    if (!mounted) return;
    setState(() => _loadingMore = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final next = full.skip(_displayed.length).take(4).toList();
    setState(() {
      _displayed = [..._displayed, ...next];
      _loadingMore = false;
    });
  }

  Future<void> _onRefresh() async {
    setState(() => _loading = true);
    await _loadData();
  }

  void _applyFilter(String f) {
    setState(() {
      _filter = f;
      _displayed = _filteredCommissions().take(6).toList();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Paid':
        return const Color(0xFF2E7D32);
      case 'Pending':
        return const Color(0xFFF57C00);
      case 'Cancelled':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF666666);
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'Paid':
        return const Color(0xFFE8F5E9);
      case 'Pending':
        return const Color(0xFFFFF3E0);
      case 'Cancelled':
        return const Color(0xFFFFEBEE);
      default:
        return const Color(0xFFF5F5F5);
    }
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
          'Commission History',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? _buildShimmer()
            : RefreshIndicator(
                color: const Color(0xFF1A1A1A),
                onRefresh: _onRefresh,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildFilterChips(),
                    ),
                    if (_displayed.isEmpty)
                      SliverFillRemaining(
                        child: _buildEmptyState(),
                      )
                    else ...[
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index == _displayed.length) {
                                return _loadingMore
                                    ? const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFF1A1A1A),
                                            ),
                                          ),
                                        ),
                                      )
                                    : const SizedBox(height: 16);
                              }
                              return _buildCommissionRow(
                                _displayed[index],
                                index,
                              );
                            },
                            childCount: _displayed.length + 1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: _filters.map((f) {
          final selected = _filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _applyFilter(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF1A1A1A)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFFE0E0E0),
                  ),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selected
                        ? Colors.white
                        : const Color(0xFF666666),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCommissionRow(Map<String, String> c, int index) {
    final isLast = index == _displayed.length - 1;
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                size: 22,
                color: Color(0xFF999999),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c['product']!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Order: ${c['orderAmount']!}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c['date']!,
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
                  c['commission']!,
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
                    color: _statusBg(c['status']!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    c['status']!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(c['status']!),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No commissions yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commissions for $_filter will appear here',
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
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) => Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
