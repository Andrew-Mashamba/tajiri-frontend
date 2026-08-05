import 'dart:async';

import 'package:flutter/material.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kText = Color(0xFF1A1A1A);
const Color _kSubtext = Color(0xFF666666);

class TrendingSearchesScreen extends StatefulWidget {
  const TrendingSearchesScreen({super.key});

  @override
  State<TrendingSearchesScreen> createState() => _TrendingSearchesScreenState();
}

class _TrendingSearchesScreenState extends State<TrendingSearchesScreen> {
  bool _loading = true;
  late Timer _shimmerTimer;

  final List<_TrendingTerm> _trending = const [
    _TrendingTerm('Ankara dress', 15420),
    _TrendingTerm('Maasai beads', 12890),
    _TrendingTerm('Kikoy fabric', 11230),
    _TrendingTerm('Leather sandals', 9870),
    _TrendingTerm('Sisal basket', 8340),
    _TrendingTerm('Wooden sculpture', 7210),
    _TrendingTerm('Batik shirt', 6540),
    _TrendingTerm('Silver jewelry', 5920),
    _TrendingTerm('Kanga print', 5100),
    _TrendingTerm('Tie dye set', 4380),
  ];

  List<String> _recentSearches = [
    'beaded necklace',
    'cotton kitenge',
    'handmade shoes',
  ];

  @override
  void initState() {
    super.initState();
    _shimmerTimer = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _shimmerTimer.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _navigateToSearch(String term) {
    Navigator.pushNamed(
      context,
      '/shop/search-results',
      arguments: {'query': term, 'currentUserId': 0},
    );
  }

  void _clearHistory() {
    setState(() => _recentSearches = []);
  }

  void _removeRecent(String term) {
    setState(() => _recentSearches.remove(term));
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K searches';
    }
    return '$count searches';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text(
          'Trending Searches',
          style: TextStyle(color: _kText, fontWeight: FontWeight.w600),
        ),
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: _kText,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _kText,
          onRefresh: _refresh,
          child: _loading ? _buildShimmer() : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
        10,
        (_) => Container(
          height: 56,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildTrendingSection(),
        const SizedBox(height: 24),
        _buildRecentSection(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTrendingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_fire_department_rounded, size: 20, color: _kText),
            const SizedBox(width: 6),
            const Text(
              'Trending Now',
              style: TextStyle(
                color: _kText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
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
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _trending.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, indent: 60, endIndent: 16),
            itemBuilder: (ctx, i) => _buildTrendingRow(_trending[i], i + 1),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingRow(_TrendingTerm term, int rank) {
    final isTop3 = rank <= 3;
    BorderRadius? borderRadius;
    if (rank == 1) {
      borderRadius = const BorderRadius.vertical(top: Radius.circular(16));
    } else if (rank == 10) {
      borderRadius = const BorderRadius.vertical(bottom: Radius.circular(16));
    }

    return InkWell(
      onTap: () => _navigateToSearch(term.term),
      borderRadius: borderRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '$rank',
                style: TextStyle(
                  color: isTop3 ? _kText : _kSubtext,
                  fontSize: isTop3 ? 16 : 14,
                  fontWeight:
                      isTop3 ? FontWeight.w800 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isTop3
                  ? Icons.local_fire_department_rounded
                  : Icons.trending_up_rounded,
              size: 18,
              color: isTop3 ? _kText : Colors.grey.shade400,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    term.term,
                    style: const TextStyle(
                      color: _kText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _formatCount(term.searchCount),
                    style: const TextStyle(color: _kSubtext, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFFBBBBBB),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded, size: 20, color: _kText),
            const SizedBox(width: 6),
            const Text(
              'Recent Searches',
              style: TextStyle(
                color: _kText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (_recentSearches.isNotEmpty)
              TextButton(
                onPressed: _clearHistory,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(48, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    color: _kSubtext,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentSearches.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No recent searches',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your search history will appear here',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches.map((term) {
              return InputChip(
                label: Text(
                  term,
                  style: const TextStyle(
                    color: _kText,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFE0E0E0)),
                deleteIcon: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: _kSubtext,
                ),
                onDeleted: () => _removeRecent(term),
                onPressed: () => _navigateToSearch(term),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _TrendingTerm {
  final String term;
  final int searchCount;
  const _TrendingTerm(this.term, this.searchCount);
}
