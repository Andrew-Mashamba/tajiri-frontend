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

enum _BanType { all, temporary, permanent }

class _BannedSeller {
  final String id;
  final String name;
  final String email;
  final String banReason;
  final String banDate;
  final bool isPermanent;

  const _BannedSeller({
    required this.id,
    required this.name,
    required this.email,
    required this.banReason,
    required this.banDate,
    required this.isPermanent,
  });
}

/// Admin view of banned/suspended sellers on the platform.
class BannedSellersScreen extends StatefulWidget {
  const BannedSellersScreen({super.key});

  @override
  State<BannedSellersScreen> createState() => _BannedSellersScreenState();
}

class _BannedSellersScreenState extends State<BannedSellersScreen> {
  bool _loading = true;
  _BanType _filter = _BanType.all;
  final List<_BannedSeller> _sellers = [];

  int _totalBanned = 0;
  int _bannedThisWeek = 0;

  static const _mockSellers = [
    _BannedSeller(
      id: 'S-1021',
      name: 'TechDrop Store',
      email: 'techdrop@example.com',
      banReason: 'Selling counterfeit electronics',
      banDate: 'May 3, 2026',
      isPermanent: true,
    ),
    _BannedSeller(
      id: 'S-0987',
      name: 'Quick Gadgets TZ',
      email: 'qgtz@example.com',
      banReason: 'Multiple customer fraud reports',
      banDate: 'May 1, 2026',
      isPermanent: true,
    ),
    _BannedSeller(
      id: 'S-0845',
      name: 'Mzigo Deals',
      email: 'mzigo@example.com',
      banReason: 'Policy violation — misleading listings',
      banDate: 'Apr 28, 2026',
      isPermanent: false,
    ),
    _BannedSeller(
      id: 'S-0712',
      name: 'FastShip DSM',
      email: 'fastship@example.com',
      banReason: 'Non-delivery of paid orders',
      banDate: 'Apr 22, 2026',
      isPermanent: false,
    ),
    _BannedSeller(
      id: 'S-0634',
      name: 'Sokoni Imports',
      email: 'sokoni@example.com',
      banReason: 'Tax evasion — flagged by compliance',
      banDate: 'Apr 15, 2026',
      isPermanent: true,
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
      _sellers
        ..clear()
        ..addAll(_mockSellers);
      _totalBanned = _mockSellers.length;
      _bannedThisWeek = 2;
    });
  }

  Future<void> _refresh() => _load();

  List<_BannedSeller> get _filtered {
    if (_filter == _BanType.permanent) {
      return _sellers.where((s) => s.isPermanent).toList();
    } else if (_filter == _BanType.temporary) {
      return _sellers.where((s) => !s.isPermanent).toList();
    }
    return _sellers;
  }

  void _showUnbanConfirm(_BannedSeller seller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.lock_open_rounded, size: 40, color: _kText),
            const SizedBox(height: 12),
            Text(
              'Unban ${seller.name}?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: _kText),
            ),
            const SizedBox(height: 8),
            Text(
              'This will restore the seller\'s ability to list products and accept orders.',
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: _kMuted),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child:
                      const Text('Cancel', style: TextStyle(color: _kText)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (!mounted) return;
                    setState(() => _sellers.removeWhere((s) => s.id == seller.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${seller.name} has been unbanned')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kText,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Unban Seller'),
                ),
              ),
            ]),
          ]),
        ),
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
          'Banned Sellers',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: _kText),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kText))
            : RefreshIndicator(
                color: _kText,
                onRefresh: _refresh,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildStats()),
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
                            (context, i) => _SellerBanCard(
                              seller: _filtered[i],
                              onUnban: _showUnbanConfirm,
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

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Expanded(
          child: _StatCard(
            label: 'Total Banned',
            value: '$_totalBanned',
            icon: Icons.block_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Banned This Week',
            value: '$_bannedThisWeek',
            icon: Icons.calendar_today_rounded,
          ),
        ),
      ]),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _FilterChip(
            label: 'All',
            selected: _filter == _BanType.all,
            onTap: () => setState(() => _filter = _BanType.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Temporary',
            selected: _filter == _BanType.temporary,
            onTap: () => setState(() => _filter = _BanType.temporary),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Permanent',
            selected: _filter == _BanType.permanent,
            onTap: () => setState(() => _filter = _BanType.permanent),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle_outline_rounded,
            size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('No banned sellers',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500)),
        const SizedBox(height: 8),
        Text('All sellers are in good standing.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [_kCardShadow],
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: _kText),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _kText)),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 12, color: _kMuted)),
          ]),
        ),
      ]),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
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

class _SellerBanCard extends StatelessWidget {
  const _SellerBanCard({
    required this.seller,
    required this.onUnban,
  });
  final _BannedSeller seller;
  final void Function(_BannedSeller) onUnban;

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
          // Avatar placeholder
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.storefront_rounded,
                size: 22, color: _kMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                seller.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kText),
              ),
              Text(
                seller.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: _kMuted),
              ),
            ]),
          ),
          const SizedBox(width: 8),
          _BanBadge(isPermanent: seller.isPermanent),
        ]),
        const SizedBox(height: 12),
        const Divider(height: 1, color: _kDivider),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: _kMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              seller.banReason,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: _kMuted),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.calendar_month_rounded, size: 14, color: _kFaint),
          const SizedBox(width: 4),
          Text(
            'Banned ${seller.banDate}',
            style: const TextStyle(fontSize: 12, color: _kFaint),
          ),
        ]),
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
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () => onUnban(seller),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kText,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Unban',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _BanBadge extends StatelessWidget {
  const _BanBadge({required this.isPermanent});
  final bool isPermanent;

  @override
  Widget build(BuildContext context) {
    final color = isPermanent ? const Color(0xFFD32F2F) : const Color(0xFFF57C00);
    final label = isPermanent ? 'Permanent' : 'Temporary';
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

