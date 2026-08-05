import 'package:flutter/material.dart';
import '../../../models/shop_models.dart';
import '../../data/repositories/shop_repository.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kText = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class SellerReviewsScreen extends StatefulWidget {
  const SellerReviewsScreen({super.key});

  @override
  State<SellerReviewsScreen> createState() => _SellerReviewsScreenState();
}

class _SellerReviewsScreenState extends State<SellerReviewsScreen> {
  final ShopRepository _repo = ShopRepository.instance;

  List<Review> _allReviews = [];
  bool _loading = true;
  int _selectedFilter = 0; // 0 = All, 1-5 = star filter
  ReviewStats _stats = ReviewStats();

  static final List<Review> _mockReviews = [
    Review(
      id: 1,
      productId: 1,
      userId: 101,
      rating: 5,
      comment: 'Excellent product! Quality is top-notch and delivery was fast. Would definitely buy again.',
      isVerifiedPurchase: true,
      helpfulCount: 12,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      user: ReviewUser(id: 101, firstName: 'Amina', lastName: 'Hassan'),
    ),
    Review(
      id: 2,
      productId: 1,
      userId: 102,
      rating: 4,
      comment: 'Good quality overall. Packaging could be improved but the product itself is great.',
      isVerifiedPurchase: true,
      helpfulCount: 5,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      user: ReviewUser(id: 102, firstName: 'Juma', lastName: 'Mwangi'),
    ),
    Review(
      id: 3,
      productId: 2,
      userId: 103,
      rating: 5,
      comment: 'Perfect! Exactly as described. The seller was very helpful and responsive.',
      isVerifiedPurchase: false,
      helpfulCount: 8,
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      user: ReviewUser(id: 103, firstName: 'Fatuma', lastName: 'Ali'),
    ),
    Review(
      id: 4,
      productId: 2,
      userId: 104,
      rating: 3,
      comment: 'Average quality. The product works but didn\'t quite match the photos.',
      isVerifiedPurchase: true,
      helpfulCount: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      user: ReviewUser(id: 104, firstName: 'Brian', lastName: 'Odhiambo'),
    ),
    Review(
      id: 5,
      productId: 3,
      userId: 105,
      rating: 5,
      comment: 'Absolutely love it! Great value for money. Highly recommend this seller.',
      isVerifiedPurchase: true,
      helpfulCount: 20,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      user: ReviewUser(id: 105, firstName: 'Wanjiru', lastName: 'Kamau'),
    ),
    Review(
      id: 6,
      productId: 3,
      userId: 106,
      rating: 2,
      comment: 'Delivery took too long and the item had a small defect. Seller offered a partial refund.',
      isVerifiedPurchase: true,
      helpfulCount: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      user: ReviewUser(id: 106, firstName: 'Denis', lastName: 'Otieno'),
    ),
  ];

  static ReviewStats _buildMockStats(List<Review> reviews) {
    final dist = <int, int>{};
    for (final r in reviews) {
      dist[r.rating] = (dist[r.rating] ?? 0) + 1;
    }
    final total = reviews.length;
    final avg = total == 0
        ? 0.0
        : reviews.fold<int>(0, (s, r) => s + r.rating) / total;
    return ReviewStats(
      averageRating: avg,
      totalReviews: total,
      ratingDistribution: dist,
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await _repo.getProductReviews(1, perPage: 50);
      if (!mounted) return;
      if (result.success && result.reviews.isNotEmpty) {
        final reviews = result.reviews;
        final stats = result.stats ?? _buildMockStats(reviews);
        setState(() {
          _allReviews = reviews;
          _stats = stats;
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _allReviews = _mockReviews;
      _stats = _buildMockStats(_mockReviews);
      _loading = false;
    });
  }

  List<Review> get _filtered {
    if (_selectedFilter == 0) return _allReviews;
    return _allReviews.where((r) => r.rating == _selectedFilter).toList();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 30) {
      final months = (diff.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    }
    if (diff.inDays >= 1) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text(
          'Reviews',
          style: TextStyle(color: _kText, fontWeight: FontWeight.w600),
        ),
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: _kText,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kText))
            : RefreshIndicator(
                color: _kText,
                onRefresh: _load,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildSummaryCard()),
                    SliverToBoxAdapter(child: _buildFilterRow()),
                    if (_filtered.isEmpty)
                      SliverFillRemaining(child: _buildEmptyState())
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => _buildReviewTile(_filtered[i]),
                          childCount: _filtered.length,
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Text(
                _stats.averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: _kText,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < _stats.averageRating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 16,
                    color: _kText,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_stats.totalReviews} review${_stats.totalReviews != 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 12, color: _kSecondary),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final pct = _stats.getPercentForRating(star);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text('$star', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded, size: 12, color: _kSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct / 100,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFEEEEEE),
                            valueColor: const AlwaysStoppedAnimation<Color>(_kText),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 28,
                        child: Text(
                          _stats.getCountForRating(star).toString(),
                          style: const TextStyle(fontSize: 12, color: _kSecondary),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    final filters = ['All', '5★', '4★', '3★', '2★', '1★'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(filters.length, (i) {
            final isSelected = _selectedFilter == i;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  filters[i],
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected ? Colors.white : _kText,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _selectedFilter = i);
                },
                selectedColor: _kText,
                backgroundColor: Colors.white,
                side: BorderSide(color: isSelected ? _kText : const Color(0xFFDDDDDD)),
                showCheckmark: false,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildReviewTile(Review review) {
    final name = review.user?.fullName ?? 'Anonymous';
    final initials = name.isNotEmpty
        ? name.split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase()
        : 'A';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFEEEEEE),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kText,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                            size: 14,
                            color: _kText,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _timeAgo(review.createdAt),
                          style: const TextStyle(fontSize: 11, color: _kSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (review.isVerifiedPurchase)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Verified',
                    style: TextStyle(fontSize: 10, color: _kSecondary),
                  ),
                ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!,
              style: const TextStyle(fontSize: 14, color: Color(0xFF444444), height: 1.5),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _HelpfulButton(
                count: review.helpfulCount,
                isHelpful: review.isHelpful ?? false,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_border_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reviews will appear here once customers leave feedback.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpfulButton extends StatefulWidget {
  final int count;
  final bool isHelpful;
  final VoidCallback onTap;

  const _HelpfulButton({
    required this.count,
    required this.isHelpful,
    required this.onTap,
  });

  @override
  State<_HelpfulButton> createState() => _HelpfulButtonState();
}

class _HelpfulButtonState extends State<_HelpfulButton> {
  late bool _helpful;
  late int _count;

  @override
  void initState() {
    super.initState();
    _helpful = widget.isHelpful;
    _count = widget.count;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_helpful) {
            _helpful = false;
            _count--;
          } else {
            _helpful = true;
            _count++;
          }
        });
        widget.onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _helpful ? _kText : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _helpful ? _kText : const Color(0xFFDDDDDD),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.thumb_up_rounded,
              size: 13,
              color: _helpful ? Colors.white : _kSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              'Helpful${_count > 0 ? ' ($_count)' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: _helpful ? Colors.white : _kSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
