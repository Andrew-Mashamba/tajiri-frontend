import 'package:flutter/material.dart';

// DESIGN.md tokens
const Color _kBg = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kText = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF666666);
const Color _kFaint = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);

const BoxShadow _kCardShadow = BoxShadow(
  color: Color(0x0F000000),
  blurRadius: 8,
  offset: Offset(0, 2),
);

enum _ReportStatus { underReview, resolved, dismissed }

class _ReportedProduct {
  final String id;
  final String productName;
  final String reportReason;
  final int reportCount;
  final String dateReported;
  final _ReportStatus status;

  const _ReportedProduct({
    required this.id,
    required this.productName,
    required this.reportReason,
    required this.reportCount,
    required this.dateReported,
    required this.status,
  });
}

/// Seller view — products that have been reported by buyers.
class ReportedProductsScreen extends StatefulWidget {
  const ReportedProductsScreen({super.key});

  @override
  State<ReportedProductsScreen> createState() =>
      _ReportedProductsScreenState();
}

class _ReportedProductsScreenState extends State<ReportedProductsScreen> {
  bool _loading = true;
  final List<_ReportedProduct> _products = [];

  static const _mockProducts = [
    _ReportedProduct(
      id: 'RP-001',
      productName: 'Wireless Headphones 40H',
      reportReason: 'Item not as described — received different model',
      reportCount: 3,
      dateReported: 'May 5, 2026',
      status: _ReportStatus.underReview,
    ),
    _ReportedProduct(
      id: 'RP-002',
      productName: 'Vitenge Fabric (6 yards)',
      reportReason: 'Counterfeit / fake designer fabric',
      reportCount: 5,
      dateReported: 'May 3, 2026',
      status: _ReportStatus.underReview,
    ),
    _ReportedProduct(
      id: 'RP-003',
      productName: 'Children\'s Toy Set',
      reportReason: 'Safety concern — small parts, no age label',
      reportCount: 2,
      dateReported: 'Apr 28, 2026',
      status: _ReportStatus.resolved,
    ),
    _ReportedProduct(
      id: 'RP-004',
      productName: 'Cooking Oil 5L',
      reportReason: 'Expired product delivered to buyer',
      reportCount: 1,
      dateReported: 'Apr 20, 2026',
      status: _ReportStatus.dismissed,
    ),
  ];

  int get _totalReports => _products.fold(0, (sum, p) => sum + p.reportCount);
  int get _underReviewCount =>
      _products.where((p) => p.status == _ReportStatus.underReview).length;
  int get _resolvedCount =>
      _products.where((p) => p.status == _ReportStatus.resolved).length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _products
        ..clear()
        ..addAll(_mockProducts);
    });
  }

  Future<void> _refresh() => _load();

  void _showRespondSheet(_ReportedProduct product) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _RespondSheet(product: product, ctrl: ctrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: _kText,
        title: const Text(
          'Reported Products',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: _kText),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: _kText))
            : RefreshIndicator(
                color: _kText,
                onRefresh: _refresh,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildStats()),
                    if (_products.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => _ReportCard(
                              product: _products[i],
                              onRespond: _showRespondSheet,
                            ),
                            childCount: _products.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Expanded(
          child: _MiniStatCard(
            label: 'Total Reports',
            value: '$_totalReports',
            icon: Icons.flag_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            label: 'Under Review',
            value: '$_underReviewCount',
            icon: Icons.hourglass_top_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            label: 'Resolved',
            value: '$_resolvedCount',
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.verified_outlined, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          'No reported products',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500),
        ),
        const SizedBox(height: 8),
        Text(
          'Your products have no active reports.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
        ),
      ]),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [_kCardShadow],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: _kMuted),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: _kText)),
        const SizedBox(height: 2),
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: _kMuted)),
      ]),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.product, required this.onRespond});
  final _ReportedProduct product;
  final void Function(_ReportedProduct) onRespond;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [_kCardShadow],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Product image placeholder
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.image_rounded, size: 24, color: _kMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                product.productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kText),
              ),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.flag_rounded, size: 13, color: _kFaint),
                const SizedBox(width: 4),
                Text(
                  '${product.reportCount} report${product.reportCount == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 12, color: _kFaint),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.calendar_month_rounded,
                    size: 13, color: _kFaint),
                const SizedBox(width: 4),
                Text(
                  product.dateReported,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _kFaint),
                ),
              ]),
            ]),
          ),
          const SizedBox(width: 8),
          _ReportStatusBadge(status: product.status),
        ]),
        const SizedBox(height: 12),
        const Divider(height: 1, color: _kDivider),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline_rounded, size: 15, color: _kMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              product.reportReason,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: _kMuted),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 40,
          child: OutlinedButton(
            onPressed: () => onRespond(product),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kText,
              side: const BorderSide(color: _kDivider),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Respond to Report',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ),
      ]),
    );
  }
}

class _ReportStatusBadge extends StatelessWidget {
  const _ReportStatusBadge({required this.status});
  final _ReportStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case _ReportStatus.underReview:
        color = const Color(0xFFF57C00);
        label = 'Under Review';
        break;
      case _ReportStatus.resolved:
        color = const Color(0xFF2E7D32);
        label = 'Resolved';
        break;
      case _ReportStatus.dismissed:
        color = _kMuted;
        label = 'Dismissed';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _RespondSheet extends StatefulWidget {
  const _RespondSheet({required this.product, required this.ctrl});
  final _ReportedProduct product;
  final TextEditingController ctrl;

  @override
  State<_RespondSheet> createState() => _RespondSheetState();
}

class _RespondSheetState extends State<_RespondSheet> {
  bool _submitting = false;

  @override
  void dispose() {
    widget.ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Respond to Report',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _kText),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.product.productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: _kMuted),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.ctrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'Explain your response to this report...',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submitting
                  ? null
                  : () async {
                      setState(() => _submitting = true);
                      final nav = Navigator.of(context);
                      final sm = ScaffoldMessenger.of(context);
                      await Future.delayed(
                          const Duration(milliseconds: 800));
                      if (!mounted) return;
                      nav.pop();
                      sm.showSnackBar(
                        const SnackBar(
                            content: Text('Response submitted successfully')),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kText,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit Response',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}
