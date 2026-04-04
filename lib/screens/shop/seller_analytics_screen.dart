import 'package:flutter/material.dart';
import '../../services/shop_service.dart';

// Design tokens — monochromatic palette per DESIGN.md
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const Color _kTertiaryText = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kSuccess = Color(0xFF22C55E);
const Color _kWarning = Color(0xFFF59E0B);
const Color _kError = Color(0xFFDC2626);
const Color _kInfo = Color(0xFF3B82F6);

const BoxShadow _kCardShadow = BoxShadow(
  color: Color(0x1A000000),
  blurRadius: 4,
  offset: Offset(0, 2),
);

class SellerAnalyticsScreen extends StatefulWidget {
  final int sellerId;

  const SellerAnalyticsScreen({super.key, required this.sellerId});

  @override
  State<SellerAnalyticsScreen> createState() => _SellerAnalyticsScreenState();
}

class _SellerAnalyticsScreenState extends State<SellerAnalyticsScreen> {
  final ShopService _shopService = ShopService();
  SellerStats? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await _shopService.getSellerStats(widget.sellerId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _stats = result.stats;
        } else {
          _error = result.message ?? 'Imeshindwa kupakia takwimu';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Analytics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _kPrimaryText,
          ),
        ),
        iconTheme: const IconThemeData(color: _kPrimaryText),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _kPrimaryText),
            tooltip: 'Refresh',
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: _kTertiaryText),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _kSecondaryText, fontSize: 14),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loadStats,
                style: FilledButton.styleFrom(backgroundColor: _kPrimaryText),
                child: const Text('Jaribu Tena'),
              ),
            ],
          ),
        ),
      );
    }

    final stats = _stats ?? SellerStats();
    return RefreshIndicator(
      onRefresh: _loadStats,
      color: _kPrimaryText,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Revenue Hero Card ──────────────────────────────────────────
          _buildRevenueCard(stats),
          const SizedBox(height: 16),

          // ── 2x4 Mini Stats Grid ────────────────────────────────────────
          _buildSectionLabel('Muhtasari wa Duka'),
          const SizedBox(height: 12),
          _buildMiniStatsGrid(stats),
          const SizedBox(height: 20),

          // ── Product Status Breakdown ───────────────────────────────────
          _buildSectionLabel('Hali ya Bidhaa'),
          const SizedBox(height: 12),
          _buildProductStatusCard(stats),
          const SizedBox(height: 20),

          // ── Conversion Rate Card ───────────────────────────────────────
          _buildSectionLabel('Kiwango cha Mauzo'),
          const SizedBox(height: 12),
          _buildConversionCard(stats),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Revenue Hero Card ──────────────────────────────────────────────────────

  Widget _buildRevenueCard(SellerStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [_kCardShadow],
        border: Border.all(color: _kDivider),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _kSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, color: _kSuccess, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mapato Yote',
                  style: TextStyle(
                    fontSize: 13,
                    color: _kSecondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stats.revenueFormatted,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: _kPrimaryText,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${stats.completedOrders} agizo zilizokamilika',
                  style: const TextStyle(fontSize: 12, color: _kTertiaryText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _kSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Mapato',
              style: TextStyle(
                fontSize: 12,
                color: _kSuccess,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2×4 Mini Stats Grid ────────────────────────────────────────────────────

  Widget _buildMiniStatsGrid(SellerStats stats) {
    final items = [
      _MiniStatItem(
        icon: Icons.inventory_2_rounded,
        label: 'Bidhaa Zote',
        value: '${stats.totalProducts}',
        color: _kPrimaryText,
      ),
      _MiniStatItem(
        icon: Icons.check_circle_outline_rounded,
        label: 'Zinazouzwa',
        value: '${stats.activeProducts}',
        color: _kSuccess,
      ),
      _MiniStatItem(
        icon: Icons.receipt_long_rounded,
        label: 'Maagizo Yote',
        value: '${stats.totalOrders}',
        color: _kPrimaryText,
      ),
      _MiniStatItem(
        icon: Icons.pending_actions_rounded,
        label: 'Yanasubiri',
        value: '${stats.pendingOrders}',
        color: stats.pendingOrders > 0 ? _kWarning : _kTertiaryText,
      ),
      _MiniStatItem(
        icon: Icons.visibility_rounded,
        label: 'Mionekano',
        value: _formatCount(stats.totalViews),
        color: _kInfo,
      ),
      _MiniStatItem(
        icon: Icons.star_rounded,
        label: 'Ukadiriaji',
        value: stats.averageRating.toStringAsFixed(1),
        color: _kWarning,
      ),
      _MiniStatItem(
        icon: Icons.rate_review_rounded,
        label: 'Maoni',
        value: _formatCount(stats.totalReviews),
        color: _kSecondaryText,
      ),
      _MiniStatItem(
        icon: Icons.done_all_rounded,
        label: 'Zilizokamilika',
        value: '${stats.completedOrders}',
        color: _kSuccess,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildMiniCard(items[index]),
    );
  }

  Widget _buildMiniCard(_MiniStatItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [_kCardShadow],
        border: Border.all(color: _kDivider),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _kPrimaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.label,
                  style: const TextStyle(fontSize: 11, color: _kTertiaryText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Product Status Breakdown Bar ───────────────────────────────────────────

  Widget _buildProductStatusCard(SellerStats stats) {
    final total = stats.totalProducts;
    final segments = [
      _StatusSegment(label: 'Zinazouzwa', count: stats.activeProducts, color: _kSuccess),
      _StatusSegment(label: 'Rasimu', count: stats.draftProducts, color: _kWarning),
      _StatusSegment(label: 'Zimeisha', count: stats.soldOutProducts, color: _kError),
      _StatusSegment(label: 'Zimehifadhiwa', count: stats.archivedProducts, color: _kTertiaryText),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [_kCardShadow],
        border: Border.all(color: _kDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stacked progress bar
          if (total > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: segments.map((seg) {
                    final flex = seg.count > 0 ? seg.count : 0;
                    if (flex == 0) return const SizedBox.shrink();
                    return Flexible(
                      flex: flex,
                      child: Container(color: seg.color),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: _kDivider,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: segments.map((seg) => _buildStatusLegendItem(seg, total)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusLegendItem(_StatusSegment seg, int total) {
    final pct = total > 0 ? (seg.count / total * 100).round() : 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: seg.color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${seg.label} (${seg.count}) · $pct%',
          style: const TextStyle(fontSize: 12, color: _kSecondaryText),
        ),
      ],
    );
  }

  // ── Conversion Rate Card ───────────────────────────────────────────────────

  Widget _buildConversionCard(SellerStats stats) {
    final views = stats.totalViews;
    final orders = stats.totalOrders;
    final rate = views > 0 ? (orders / views * 100) : 0.0;
    final rateStr = rate.toStringAsFixed(1);
    final barWidth = (rate.clamp(0, 100) / 100);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [_kCardShadow],
        border: Border.all(color: _kDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, size: 20, color: _kPrimaryText),
              const SizedBox(width: 8),
              const Text(
                'Mauzo kwa kila Mionekano 100',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimaryText,
                ),
              ),
              const Spacer(),
              Text(
                '$rateStr%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _kPrimaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    Container(color: _kDivider),
                    FractionallySizedBox(
                      widthFactor: barWidth.toDouble(),
                      child: Container(color: _kPrimaryText),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildConversionStat('Mionekano', _formatCount(views), _kInfo),
              const SizedBox(width: 24),
              _buildConversionStat('Maagizo', '$orders', _kSuccess),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConversionStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: _kTertiaryText),
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: _kPrimaryText,
      ),
    );
  }

  static String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}

// ── Data classes ───────────────────────────────────────────────────────────

class _MiniStatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _MiniStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _StatusSegment {
  final String label;
  final int count;
  final Color color;
  const _StatusSegment({
    required this.label,
    required this.count,
    required this.color,
  });
}
