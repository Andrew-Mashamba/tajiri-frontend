import 'package:flutter/material.dart';
import '../../../models/shop_models.dart';
import '../../../services/shop_service.dart' show SellerStats;
import '../../../services/local_storage_service.dart';
import '../../data/repositories/shop_repository.dart';
import '../../shared/widgets/product_card.dart';
import '../../seller/models/trust_models.dart';
import '../../seller/services/seller_verification_service.dart';
import '../../seller/widgets/trust_badge_row.dart';

const Color _kBg = Color(0xFFFAFAFA);

/// Seller storefront — catalog + stats (`docs/shop/shop.md` seller_profile_screen).
class SellerShopProfileScreen extends StatefulWidget {
  const SellerShopProfileScreen({
    super.key,
    required this.sellerId,
    required this.currentUserId,
  });

  final int sellerId;
  final int currentUserId;

  @override
  State<SellerShopProfileScreen> createState() => _SellerShopProfileScreenState();
}

class _SellerShopProfileScreenState extends State<SellerShopProfileScreen> {
  final ShopRepository _repo = ShopRepository.instance;
  SellerStats? _stats;
  SellerTrustProfile? _trustProfile;
  List<Product> _products = [];
  List<Review> _reviews = [];
  bool _loading = true;
  bool _loadingReviews = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken() ?? '';
    final statsF = _repo.getSellerStats(widget.sellerId);
    final prodF  = _repo.getSellerProducts(widget.sellerId, perPage: 40);
    final trustF = SellerVerificationService.getTrustProfile(widget.sellerId, token);
    final statsR = await statsF;
    final prodR  = await prodF;
    final trust  = await trustF;
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (statsR.success) _stats = statsR.stats;
      if (prodR.success) _products = prodR.products;
      _trustProfile = trust;
    });
  }

  Future<void> _loadReviews() async {
    if (_loadingReviews || _reviews.isNotEmpty) return;
    setState(() => _loadingReviews = true);
    // Use the first product's id if available, else skip
    if (_products.isNotEmpty) {
      final r = await _repo.getProductReviews(
        _products.first.id,
        currentUserId: widget.currentUserId,
        perPage: 30,
      );
      if (!mounted) return;
      setState(() {
        _loadingReviews = false;
        if (r.success) _reviews = r.reviews;
      });
    } else {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats ?? SellerStats();
    final sellerName = 'Seller #${widget.sellerId}';
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _kBg,
        body: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A1A)))
            : SafeArea(
                child: RefreshIndicator(
                  color: const Color(0xFF1A1A1A),
                  onRefresh: _load,
                  child: NestedScrollView(
                    headerSliverBuilder: (ctx, _) => [
                      SliverAppBar(
                        title: Text(
                          sellerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        backgroundColor: _kBg,
                        elevation: 0,
                        scrolledUnderElevation: 1,
                        foregroundColor: const Color(0xFF1A1A1A),
                        pinned: true,
                        bottom: const TabBar(
                          tabs: [
                            Tab(text: 'Products'),
                            Tab(text: 'Reviews'),
                          ],
                          labelColor: Color(0xFF1A1A1A),
                          unselectedLabelColor: Color(0xFF999999),
                          indicatorColor: Color(0xFF1A1A1A),
                          indicatorWeight: 2,
                        ),
                      ),
                      // Profile header
                      SliverToBoxAdapter(
                        child: _buildProfileHeader(stats, sellerName),
                      ),
                    ],
                    body: TabBarView(
                      children: [
                        _buildProductsTab(),
                        _buildReviewsTab(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildProfileHeader(SellerStats stats, String sellerName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar + name + action buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey.shade200,
                child: Text(
                  sellerName.isNotEmpty ? sellerName[0].toUpperCase() : 'S',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sellerName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_trustProfile != null && _trustProfile!.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: Color(0xFF1A1A1A),
                          ),
                        ],
                      ],
                    ),
                    if (_trustProfile != null) ...[
                      const SizedBox(height: 6),
                      TrustBadgeRow(profile: _trustProfile!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        // Follow + Message buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.person_add_outlined, size: 16),
                    label: const Text('Follow'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A1A1A),
                      side: const BorderSide(color: Color(0xFF1A1A1A)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.message_outlined, size: 16),
                    label: const Text('Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Stats row
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.symmetric(vertical: 14),
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
              _buildStatCell('${stats.totalOrders}', 'Sales'),
              _buildStatDivider(),
              _buildStatCell('${stats.totalProducts}', 'Products'),
              _buildStatDivider(),
              _buildStatCell(
                stats.averageRating > 0
                    ? stats.averageRating.toStringAsFixed(1)
                    : '—',
                'Rating',
              ),
              _buildStatDivider(),
              _buildStatCell('${stats.totalViews}', 'Views'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCell(String value, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 32, color: Colors.grey.shade200);
  }

  Widget _buildProductsTab() {
    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No products yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _products.length,
      itemBuilder: (ctx, i) => ProductCard(
        product: _products[i],
        onTap: () => Navigator.pushNamed(
          ctx,
          '/shop/product',
          arguments: {'productId': _products[i].id},
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    // Trigger lazy load of reviews when tab is shown
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReviews());

    if (_loadingReviews) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A1A)),
      );
    }
    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey.shade300),
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
              'Reviews will appear here',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _reviews.length,
      separatorBuilder: (_, index) => const Divider(height: 24),
      itemBuilder: (ctx, i) {
        final r = _reviews[i];
        final name = r.user != null && r.user!.fullName.isNotEmpty
            ? r.user!.fullName
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
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
