import 'package:flutter/material.dart';
import '../../../models/shop_models.dart';
import '../../data/repositories/shop_repository.dart';

const Color _kBg = Color(0xFFFAFAFA);

/// Full-screen reviews list linked from product detail.
class ProductReviewsListScreen extends StatefulWidget {
  const ProductReviewsListScreen({
    super.key,
    required this.productId,
    required this.currentUserId,
  });

  final int productId;
  final int currentUserId;

  @override
  State<ProductReviewsListScreen> createState() => _ProductReviewsListScreenState();
}

class _ProductReviewsListScreenState extends State<ProductReviewsListScreen> {
  final ShopRepository _repo = ShopRepository.instance;
  List<Review> _reviews = [];
  bool _loading = true;
  int _starFilter = 0; // 0 = All

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await _repo.getProductReviews(
      widget.productId,
      currentUserId: widget.currentUserId,
      perPage: 50,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r.success) _reviews = r.reviews;
    });
  }

  List<Review> get _filtered =>
      _starFilter == 0 ? _reviews : _reviews.where((r) => r.rating == _starFilter).toList();

  double get _average {
    if (_reviews.isEmpty) return 0.0;
    final sum = _reviews.fold<int>(0, (acc, r) => acc + r.rating);
    return sum / _reviews.length;
  }

  int _countForStar(int star) => _reviews.where((r) => r.rating == star).length;

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  Future<void> _markHelpful(Review review) async {
    await _repo.markReviewHelpful(review.id, widget.currentUserId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marked as helpful')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayed = _filtered;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Reviews'),
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: const Color(0xFF1A1A1A),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A1A)))
            : RefreshIndicator(
                color: const Color(0xFF1A1A1A),
                onRefresh: _load,
                child: CustomScrollView(
                  slivers: [
                    // Rating summary header
                    if (_reviews.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _buildRatingSummary(),
                      ),
                    // Star filter chips
                    SliverToBoxAdapter(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        child: Row(
                          children: [
                            _buildStarChip(0, 'All'),
                            ...[5, 4, 3, 2, 1].map((s) => _buildStarChip(s, '$s ★')),
                          ],
                        ),
                      ),
                    ),
                    // Reviews list or empty
                    if (displayed.isEmpty)
                      SliverFillRemaining(child: _buildEmptyState())
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => Column(
                              children: [
                                _buildReviewRow(displayed[i]),
                                if (i < displayed.length - 1)
                                  const Divider(height: 24),
                              ],
                            ),
                            childCount: displayed.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildRatingSummary() {
    final avg = _average;
    final total = _reviews.length;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
        children: [
          // Average score
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                avg.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < avg.round() ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 16,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$total review${total == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(width: 20),
          // Star breakdown bars
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [5, 4, 3, 2, 1].map((star) {
                final count = _countForStar(star);
                final fraction = total > 0 ? count / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1A1A1A)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 24,
                        child: Text(
                          '$count',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarChip(int star, String label) {
    final selected = _starFilter == star;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _starFilter = star),
        selectedColor: const Color(0xFF1A1A1A),
        labelStyle: TextStyle(
          color: selected ? Colors.white : const Color(0xFF1A1A1A),
          fontSize: 13,
        ),
        showCheckmark: false,
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildReviewRow(Review r) {
    final name = r.user != null
        ? r.user!.fullName.isNotEmpty
            ? r.user!.fullName
            : 'User #${r.userId}'
        : 'User #${r.userId}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.grey.shade200,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
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
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _timeAgo(r.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: List.generate(
                  5,
                  (si) => Icon(
                    si < r.rating ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 14,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ),
              if (r.comment != null && r.comment!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  r.comment!,
                  style: const TextStyle(color: Color(0xFF444444), fontSize: 14),
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _markHelpful(r),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.thumb_up_outlined,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      r.helpfulCount > 0
                          ? 'Helpful (${r.helpfulCount})'
                          : 'Helpful',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.rate_review_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No reviews yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Be the first to leave a review',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
