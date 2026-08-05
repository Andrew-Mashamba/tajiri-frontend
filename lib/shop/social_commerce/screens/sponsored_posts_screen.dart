import 'package:flutter/material.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kText = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF666666);
const Color _kFaint = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);

enum _CampaignStatus { active, paused, ended }

class _SponsoredPost {
  final String title;
  final String productName;
  final int budget;
  final int spent;
  final int impressions;
  final int clicks;
  final _CampaignStatus status;
  const _SponsoredPost(this.title, this.productName, this.budget, this.spent,
      this.impressions, this.clicks, this.status);

  double get ctr =>
      impressions == 0 ? 0 : (clicks / impressions) * 100;
}

/// Sponsored/boosted posts manager — campaigns, stats, boost.
class SponsoredPostsScreen extends StatefulWidget {
  const SponsoredPostsScreen({super.key});

  @override
  State<SponsoredPostsScreen> createState() => _SponsoredPostsScreenState();
}

class _SponsoredPostsScreenState extends State<SponsoredPostsScreen> {
  int _filterIdx = 0;
  final List<String> _filters = ['All', 'Active', 'Paused', 'Ended'];

  final List<_SponsoredPost> _allPosts = const [
    _SponsoredPost('New Arrivals Drop', 'Blue Leso Fabric', 50000, 32100,
        18500, 420, _CampaignStatus.active),
    _SponsoredPost('Flash Sale Campaign', 'Kitenge Dress', 80000, 79200,
        42000, 1100, _CampaignStatus.active),
    _SponsoredPost('Accessories Boost', 'Beaded Bracelet', 30000, 14800,
        9200, 215, _CampaignStatus.paused),
    _SponsoredPost('Leather Bag Promo', 'Handmade Leather Bag', 60000, 60000,
        31000, 870, _CampaignStatus.ended),
    _SponsoredPost('Homewares Sale', 'Wooden Bowl Set', 20000, 20000, 7800,
        190, _CampaignStatus.ended),
    _SponsoredPost('Spring Textiles', 'Sisal Basket', 35000, 8400, 5100, 88,
        _CampaignStatus.paused),
  ];

  List<_SponsoredPost> get _filtered {
    switch (_filterIdx) {
      case 1:
        return _allPosts
            .where((p) => p.status == _CampaignStatus.active)
            .toList();
      case 2:
        return _allPosts
            .where((p) => p.status == _CampaignStatus.paused)
            .toList();
      case 3:
        return _allPosts
            .where((p) => p.status == _CampaignStatus.ended)
            .toList();
      default:
        return _allPosts;
    }
  }

  int get _activeCampaigns =>
      _allPosts.where((p) => p.status == _CampaignStatus.active).length;

  int get _totalSpend =>
      _allPosts.fold(0, (s, p) => s + p.spent);

  int get _totalImpressions =>
      _allPosts.fold(0, (s, p) => s + p.impressions);

  int get _totalClicks =>
      _allPosts.fold(0, (s, p) => s + p.clicks);

  @override
  Widget build(BuildContext context) {
    final posts = _filtered;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text(
          'Sponsored Posts',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kText),
        ),
        backgroundColor: _kSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: _kText,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {},
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _kText,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Text(
                    'Create',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kSurface),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStatsRow(),
            _buildFilterRow(),
            Expanded(
              child: posts.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      color: _kText,
                      onRefresh: () async => await Future.delayed(
                          const Duration(milliseconds: 600)),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: posts.length,
                        separatorBuilder: (_, i) =>
                            const SizedBox(height: 8),
                        itemBuilder: (ctx, i) =>
                            _SponsoredCard(post: posts[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      color: _kSurface,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          _StatCell(
              value: '$_activeCampaigns',
              label: 'Active',
              icon: Icons.campaign_rounded),
          _vDivider(),
          _StatCell(
              value: _formatAmount(_totalSpend),
              label: 'Total Spend',
              icon: Icons.account_balance_wallet_rounded),
          _vDivider(),
          _StatCell(
              value: _formatCount(_totalImpressions),
              label: 'Impressions',
              icon: Icons.visibility_rounded),
          _vDivider(),
          _StatCell(
              value: _formatCount(_totalClicks),
              label: 'Clicks',
              icon: Icons.touch_app_rounded),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 36,
        color: _kDivider,
        margin: const EdgeInsets.symmetric(horizontal: 8),
      );

  Widget _buildFilterRow() {
    return Container(
      color: _kSurface,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          separatorBuilder: (_, i) => const SizedBox(width: 8),
          itemBuilder: (ctx, i) {
            final selected = _filterIdx == i;
            return GestureDetector(
              onTap: () => setState(() => _filterIdx = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: selected ? _kText : _kBg,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                      color: selected ? _kText : _kDivider),
                ),
                child: Center(
                  child: Text(
                    _filters[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? _kSurface : _kMuted,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.campaign_rounded,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No campaigns here',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500),
          ),
          const SizedBox(height: 6),
          Text(
            'Boost your posts to reach more buyers.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  static String _formatAmount(int v) {
    if (v >= 1000000) {
      return 'TZS ${(v / 1000000).toStringAsFixed(1)}M';
    } else if (v >= 1000) {
      return 'TZS ${(v / 1000).toStringAsFixed(0)}K';
    }
    return 'TZS $v';
  }

  static String _formatCount(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return '$v';
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell(
      {required this.value, required this.label, required this.icon});
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: _kMuted),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _kText),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: _kFaint),
          ),
        ],
      ),
    );
  }
}

class _SponsoredCard extends StatelessWidget {
  const _SponsoredCard({required this.post});
  final _SponsoredPost post;

  Color get _statusColor {
    switch (post.status) {
      case _CampaignStatus.active:
        return const Color(0xFF388E3C);
      case _CampaignStatus.paused:
        return const Color(0xFFF57C00);
      case _CampaignStatus.ended:
        return const Color(0xFF9E9E9E);
    }
  }

  Color get _statusBg {
    switch (post.status) {
      case _CampaignStatus.active:
        return const Color(0xFFE8F5E9);
      case _CampaignStatus.paused:
        return const Color(0xFFFFF3E0);
      case _CampaignStatus.ended:
        return const Color(0xFFF5F5F5);
    }
  }

  String get _statusLabel {
    switch (post.status) {
      case _CampaignStatus.active:
        return 'Active';
      case _CampaignStatus.paused:
        return 'Paused';
      case _CampaignStatus.ended:
        return 'Ended';
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetPct = post.budget == 0 ? 0.0 : post.spent / post.budget;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.image_rounded,
                    size: 26, color: _kMuted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            post.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _kText),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _statusLabel,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _statusColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      post.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: _kMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Budget progress
          Row(
            children: [
              Text(
                'TZS ${_fmt(post.spent)} / TZS ${_fmt(post.budget)}',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kMuted),
              ),
              const Spacer(),
              Text(
                '${(budgetPct * 100).toStringAsFixed(0)}% used',
                style: const TextStyle(fontSize: 11, color: _kFaint),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: budgetPct.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor: AlwaysStoppedAnimation<Color>(
                  budgetPct >= 1.0 ? const Color(0xFF9E9E9E) : _kText),
            ),
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              _MetricChip(
                  label: 'Impressions',
                  value: _fmtCount(post.impressions)),
              const SizedBox(width: 8),
              _MetricChip(
                  label: 'Clicks', value: _fmtCount(post.clicks)),
              const SizedBox(width: 8),
              _MetricChip(
                  label: 'CTR',
                  value: '${post.ctr.toStringAsFixed(1)}%'),
              const Spacer(),
              if (post.status != _CampaignStatus.ended)
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _kText,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Boost',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _kSurface),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmt(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return '$v';
  }

  static String _fmtCount(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return '$v';
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kDivider),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _kText),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, color: _kFaint),
          ),
        ],
      ),
    );
  }
}

