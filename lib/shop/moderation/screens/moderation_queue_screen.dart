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

enum _QueueFilter { all, products, reviews, reports }

enum _ItemStatus { pending, approved, rejected }

class _QueueItem {
  final String id;
  final String title;
  final String preview;
  final String reason;
  final String dateReported;
  final int reporterCount;
  final _QueueFilter type;
  final _ItemStatus status;

  const _QueueItem({
    required this.id,
    required this.title,
    required this.preview,
    required this.reason,
    required this.dateReported,
    required this.reporterCount,
    required this.type,
    required this.status,
  });
}

/// Moderation queue — items pending admin/seller review.
class ModerationQueueScreen extends StatefulWidget {
  const ModerationQueueScreen({super.key});

  @override
  State<ModerationQueueScreen> createState() => _ModerationQueueScreenState();
}

class _ModerationQueueScreenState extends State<ModerationQueueScreen> {
  bool _loading = true;
  _QueueFilter _filter = _QueueFilter.all;
  final List<_QueueItem> _items = [];

  static const _mockItems = [
    _QueueItem(
      id: 'MQ-001',
      title: 'Wireless Earbuds Pro Max',
      preview: 'Product listing flagged for misleading specifications',
      reason: 'Misleading product description',
      dateReported: 'May 6, 2026',
      reporterCount: 4,
      type: _QueueFilter.products,
      status: _ItemStatus.pending,
    ),
    _QueueItem(
      id: 'MQ-002',
      title: 'Review on "Vitenge Fabric"',
      preview: '"This seller is a scam, never delivered my order and blocked me"',
      reason: 'Inappropriate / abusive content',
      dateReported: 'May 5, 2026',
      reporterCount: 2,
      type: _QueueFilter.reviews,
      status: _ItemStatus.pending,
    ),
    _QueueItem(
      id: 'MQ-003',
      title: 'Report: Counterfeit Shoes',
      preview: 'Multiple buyers report receiving fake branded shoes',
      reason: 'Counterfeit goods',
      dateReported: 'May 4, 2026',
      reporterCount: 7,
      type: _QueueFilter.reports,
      status: _ItemStatus.pending,
    ),
    _QueueItem(
      id: 'MQ-004',
      title: 'Laptop 16GB RAM i7',
      preview: 'Listing uses stock photos that do not match delivered product',
      reason: 'Fraudulent images',
      dateReported: 'May 3, 2026',
      reporterCount: 3,
      type: _QueueFilter.products,
      status: _ItemStatus.approved,
    ),
    _QueueItem(
      id: 'MQ-005',
      title: 'Review on "Samsung TV 55\'"',
      preview: '"Seller offered bribe to remove my 1-star review"',
      reason: 'Review manipulation',
      dateReported: 'May 2, 2026',
      reporterCount: 1,
      type: _QueueFilter.reviews,
      status: _ItemStatus.rejected,
    ),
    _QueueItem(
      id: 'MQ-006',
      title: 'Report: Unsafe Children Toys',
      preview: 'Products contain small parts harmful to children under 3',
      reason: 'Safety concern',
      dateReported: 'May 1, 2026',
      reporterCount: 5,
      type: _QueueFilter.reports,
      status: _ItemStatus.pending,
    ),
  ];

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
      _items
        ..clear()
        ..addAll(_mockItems);
    });
  }

  Future<void> _refresh() => _load();

  List<_QueueItem> get _filtered {
    if (_filter == _QueueFilter.all) return _items;
    return _items.where((i) => i.type == _filter).toList();
  }

  int get _pendingCount =>
      _items.where((i) => i.status == _ItemStatus.pending).length;

  void _handleAction(String itemId, String action) {
    final idx = _items.indexWhere((i) => i.id == itemId);
    if (idx == -1) return;
    final newStatus = action == 'approve'
        ? _ItemStatus.approved
        : _ItemStatus.rejected;
    setState(() {
      _items[idx] = _QueueItem(
        id: _items[idx].id,
        title: _items[idx].title,
        preview: _items[idx].preview,
        reason: _items[idx].reason,
        dateReported: _items[idx].dateReported,
        reporterCount: _items[idx].reporterCount,
        type: _items[idx].type,
        status: newStatus,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(action == 'approve'
            ? 'Item approved successfully'
            : 'Item rejected'),
      ),
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
          'Moderation Queue',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: _kText),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(strokeWidth: 2, color: _kText))
            : RefreshIndicator(
                color: _kText,
                onRefresh: _refresh,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildSummary()),
                    SliverToBoxAdapter(child: _buildFilterChips()),
                    if (_filtered.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => _QueueCard(
                              item: _filtered[i],
                              onAction: _handleAction,
                            ),
                            childCount: _filtered.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [_kCardShadow],
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.pending_actions_rounded,
                size: 22, color: _kText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_pendingCount item${_pendingCount == 1 ? '' : 's'} pending review',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _kText),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Review and take action on each item below.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: _kMuted),
                  ),
                ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _Chip(
            label: 'All',
            selected: _filter == _QueueFilter.all,
            onTap: () => setState(() => _filter = _QueueFilter.all),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Products',
            selected: _filter == _QueueFilter.products,
            onTap: () => setState(() => _filter = _QueueFilter.products),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Reviews',
            selected: _filter == _QueueFilter.reviews,
            onTap: () => setState(() => _filter = _QueueFilter.reviews),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Reports',
            selected: _filter == _QueueFilter.reports,
            onTap: () => setState(() => _filter = _QueueFilter.reports),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          'Queue is clear',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500),
        ),
        const SizedBox(height: 8),
        Text(
          'No items match the selected filter.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
        ),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kText : _kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _kText : _kDivider),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : _kMuted,
          ),
        ),
      ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({required this.item, required this.onAction});
  final _QueueItem item;
  final void Function(String id, String action) onAction;

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
          _TypeIcon(type: item.type),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kText),
              ),
              const SizedBox(height: 2),
              Text(
                item.dateReported,
                style: const TextStyle(fontSize: 12, color: _kFaint),
              ),
            ]),
          ),
          const SizedBox(width: 8),
          _StatusBadge(status: item.status),
        ]),
        const SizedBox(height: 12),
        Text(
          item.preview,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: _kMuted),
        ),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.flag_outlined, size: 14, color: _kFaint),
          const SizedBox(width: 4),
          Text(
            item.reason,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: _kFaint),
          ),
          const Spacer(),
          if (item.reporterCount > 1)
            Row(children: [
              const Icon(Icons.people_outline_rounded,
                  size: 14, color: _kFaint),
              const SizedBox(width: 3),
              Text(
                '${item.reporterCount} reporters',
                style: const TextStyle(fontSize: 12, color: _kFaint),
              ),
            ]),
        ]),
        if (item.status == _ItemStatus.pending) ...[
          const SizedBox(height: 12),
          const Divider(height: 1, color: _kDivider),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  foregroundColor: _kText,
                  side: const BorderSide(color: _kDivider),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('View',
                    style: TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => onAction(item.id, 'reject'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  foregroundColor: const Color(0xFFD32F2F),
                  side: const BorderSide(color: Color(0xFFD32F2F)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Reject',
                    style: TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => onAction(item.id, 'approve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kText,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 40),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Approve',
                    style: TextStyle(fontSize: 13)),
              ),
            ),
          ]),
        ],
      ]),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.type});
  final _QueueFilter type;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (type) {
      case _QueueFilter.products:
        icon = Icons.inventory_2_rounded;
        break;
      case _QueueFilter.reviews:
        icon = Icons.star_outline_rounded;
        break;
      case _QueueFilter.reports:
        icon = Icons.report_outlined;
        break;
      case _QueueFilter.all:
        icon = Icons.list_alt_rounded;
        break;
    }
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: _kText),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final _ItemStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case _ItemStatus.pending:
        color = const Color(0xFFF57C00);
        label = 'Pending';
        break;
      case _ItemStatus.approved:
        color = const Color(0xFF2E7D32);
        label = 'Approved';
        break;
      case _ItemStatus.rejected:
        color = const Color(0xFFD32F2F);
        label = 'Rejected';
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
