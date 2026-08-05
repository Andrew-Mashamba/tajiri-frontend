import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heroicons/heroicons.dart';
import '../../../l10n/app_strings_scope.dart';
import '../../../models/shop_models.dart';
import '../../data/repositories/shop_repository.dart';
import '../../../services/shop_database.dart';
import '../../../widgets/cached_media_image.dart';

// DESIGN.md tokens
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const Color _kTertiaryText = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);

/// Detail screen for service-type products.
/// Emphasises booking, provider info, and what's included.
class ServiceDetailScreen extends StatefulWidget {
  final int productId;
  final int currentUserId;

  const ServiceDetailScreen({
    super.key,
    required this.productId,
    required this.currentUserId,
  });

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  final ShopRepository _repo = ShopRepository.instance;

  Product? _product;
  bool _isLoading = true;
  String? _error;

  List<Review> _reviews = [];
  ReviewStats? _reviewStats;
  bool _reviewsLoading = true;

  bool _descriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
    _loadReviews();
    _recordView();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);
    try {
      final result = await _repo.getProduct(
        widget.productId,
        currentUserId: widget.currentUserId,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.success && result.product != null) {
          _product = result.product;
          ShopDatabase.instance.markViewed(_product!.id);
        } else {
          final s = AppStringsScope.of(context);
          _error = result.message ?? s?.productNotFound ?? 'Service not found';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Error: $e';
      });
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _reviewsLoading = true);
    final result = await _repo.getProductReviews(
      widget.productId,
      currentUserId: widget.currentUserId,
    );
    if (!mounted) return;
    setState(() {
      _reviewsLoading = false;
      if (result.success) {
        _reviews = result.reviews;
        _reviewStats = result.stats;
      }
    });
  }

  void _recordView() {
    _repo.recordProductView(widget.productId, userId: widget.currentUserId);
  }

  Future<void> _toggleFavorite() async {
    if (_product == null) return;
    final wasFavorited = _product!.isFavorited;
    setState(() {
      _product = _product!.copyWith(
        isFavorited: !wasFavorited,
        favoritesCount: _product!.favoritesCount + (wasFavorited ? -1 : 1),
      );
    });
    HapticFeedback.lightImpact();
    try {
      final result = await _repo.toggleFavorite(widget.currentUserId, _product!.id);
      if (!result.success && mounted) {
        setState(() {
          _product = _product!.copyWith(
            isFavorited: wasFavorited,
            favoritesCount: _product!.favoritesCount + (wasFavorited ? 1 : -1),
          );
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _product = _product!.copyWith(
            isFavorited: wasFavorited,
            favoritesCount: _product!.favoritesCount + (wasFavorited ? 1 : -1),
          );
        });
      }
    }
  }

  void _onBookNow() {
    if (_product == null) return;
    Navigator.pushNamed(
      context,
      '/shop/checkout',
      arguments: {
        'product': _product,
        'quantity': 1,
        'deliveryMethod': DeliveryMethod.pickup,
      },
    );
  }

  void _onMessageSeller() {
    if (_product?.seller == null) return;
    Navigator.pushNamed(
      context,
      '/chat/${_product!.seller!.id}',
    );
  }

  void _openSellerProfile() {
    if (_product?.seller == null) return;
    Navigator.pushNamed(context, '/profile/${_product!.seller!.id}');
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        top: false,
        child: _isLoading
            ? _buildShimmer()
            : _error != null
                ? _buildErrorState()
                : _buildContent(),
      ),
      bottomNavigationBar: _product != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildErrorState() {
    final s = AppStringsScope.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const HeroIcon(
            HeroIcons.exclamationTriangle,
            size: 64,
            color: _kTertiaryText,
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? s?.errorOccurred ?? 'An error occurred',
            style: const TextStyle(color: _kSecondaryText, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadProduct,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimaryText,
              foregroundColor: Colors.white,
            ),
            child: Text(s?.tryAgain ?? 'Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeroImage()),
        SliverToBoxAdapter(child: _buildServiceInfo()),
        SliverToBoxAdapter(child: _buildWhatsIncluded()),
        if (_product!.description?.isNotEmpty == true)
          SliverToBoxAdapter(child: _buildDescription()),
        if (_product!.seller != null)
          SliverToBoxAdapter(child: _buildProviderCard()),
        SliverToBoxAdapter(child: _buildReviewsSection()),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  // ── Hero image ────────────────────────────────────────────────────────

  Widget _buildHeroImage() {
    final topPadding = MediaQuery.of(context).padding.top;
    return Stack(
      children: [
        SizedBox(
          height: 280 + topPadding,
          width: double.infinity,
          child: _product!.thumbnailPath != null ||
                  _product!.images.isNotEmpty
              ? CachedMediaImage(
                  imageUrl: _product!.thumbnailUrl,
                  fit: BoxFit.cover,
                )
              : Container(
                  color: const Color(0xFFF0F0F0),
                  child: const Center(
                    child: HeroIcon(
                      HeroIcons.wrenchScrewdriver,
                      size: 72,
                      color: _kTertiaryText,
                    ),
                  ),
                ),
        ),
        // Dark gradient at top for icons
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: topPadding + 80,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Bottom gradient for readability
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 80,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Back button
        Positioned(
          top: topPadding + 8,
          left: 8,
          child: CircleAvatar(
            backgroundColor: _kSurface.withValues(alpha: 0.9),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const HeroIcon(
                HeroIcons.arrowLeft,
                size: 22,
                color: _kPrimaryText,
              ),
            ),
          ),
        ),
        // Favorite button
        Positioned(
          top: topPadding + 8,
          right: 8,
          child: CircleAvatar(
            backgroundColor: _kSurface.withValues(alpha: 0.9),
            child: IconButton(
              onPressed: _toggleFavorite,
              icon: HeroIcon(
                HeroIcons.heart,
                style: _product!.isFavorited
                    ? HeroIconStyle.solid
                    : HeroIconStyle.outline,
                size: 22,
                color: _product!.isFavorited
                    ? const Color(0xFFDC2626)
                    : _kPrimaryText,
              ),
            ),
          ),
        ),
        // Type badge
        Positioned(
          bottom: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kPrimaryText.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Service',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Service info ──────────────────────────────────────────────────────

  Widget _buildServiceInfo() {
    return Container(
      color: _kSurface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            _product!.title,
            style: const TextStyle(
              color: _kPrimaryText,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),

          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _product!.priceFormatted,
                style: const TextStyle(
                  color: _kPrimaryText,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_product!.hasDiscount) ...[
                const SizedBox(width: 10),
                Text(
                  _product!.compareAtPriceFormatted,
                  style: const TextStyle(
                    color: _kTertiaryText,
                    fontSize: 16,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _product!.discountPercentFormatted,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Rating + reviews
          if (_product!.reviewsCount > 0 || _product!.rating > 0)
            Row(
              children: [
                _buildStarRow(_product!.rating),
                const SizedBox(width: 6),
                Text(
                  _product!.ratingFormatted,
                  style: const TextStyle(
                    color: _kPrimaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${_product!.reviewsCount} ${_product!.reviewsCount == 1 ? 'review' : 'reviews'})',
                  style: const TextStyle(color: _kSecondaryText, fontSize: 13),
                ),
              ],
            ),

          // Meta: duration, location
          if (_product!.durationMinutes != null ||
              _product!.serviceLocation?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                if (_product!.durationMinutes != null)
                  _buildMetaChip(
                    icon: HeroIcons.clock,
                    label: _formatDuration(_product!.durationMinutes!),
                  ),
                if (_product!.serviceLocation?.isNotEmpty == true)
                  _buildMetaChip(
                    icon: HeroIcons.mapPin,
                    label: _product!.serviceLocation!,
                  ),
                if (_product!.ordersCount > 0)
                  _buildMetaChip(
                    icon: HeroIcons.checkBadge,
                    label: '${_product!.ordersCount} bookings',
                  ),
              ],
            ),
          ],

          // Provider name
          if (_product!.seller != null) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: _kDivider),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _openSellerProfile,
              child: Row(
                children: [
                  _buildAvatar(_product!.seller!, radius: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _product!.seller!.displayName,
                          style: const TextStyle(
                            color: _kPrimaryText,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Service Provider',
                          style: TextStyle(color: _kTertiaryText, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const HeroIcon(
                    HeroIcons.chevronRight,
                    size: 18,
                    color: _kTertiaryText,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── What's Included ───────────────────────────────────────────────────

  Widget _buildWhatsIncluded() {
    final items = _buildIncludedItems();
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: _kSurface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "What's Included",
            style: TextStyle(
              color: _kPrimaryText,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: HeroIcon(
                        HeroIcons.checkCircle,
                        size: 18,
                        color: _kPrimaryText,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: _kSecondaryText,
                          fontSize: 14,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  List<String> _buildIncludedItems() {
    // Use tags if available, else derive from product metadata
    final product = _product!;
    if (product.tags != null && product.tags!.isNotEmpty) {
      return product.tags!.take(6).toList();
    }
    // Fallback: generate from product fields
    final items = <String>[];
    if (product.durationMinutes != null) {
      items.add('${_formatDuration(product.durationMinutes!)} session');
    }
    if (product.serviceLocation?.isNotEmpty == true) {
      items.add('Available at: ${product.serviceLocation}');
    }
    if (product.allowPickup) items.add('In-person service');
    if (product.allowDelivery) items.add('Delivery / on-site visit');
    // Default inclusions for service products
    if (items.isEmpty) {
      items.addAll([
        'Professional service delivery',
        'Post-service support',
        'Satisfaction guarantee',
      ]);
    }
    return items;
  }

  // ── Description ───────────────────────────────────────────────────────

  Widget _buildDescription() {
    final desc = _product!.description ?? '';
    const maxChars = 200;
    final needsExpand = desc.length > maxChars;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: _kSurface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About this service',
            style: TextStyle(
              color: _kPrimaryText,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _descriptionExpanded || !needsExpand
                ? desc
                : '${desc.substring(0, maxChars)}…',
            style: const TextStyle(
              color: _kSecondaryText,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          if (needsExpand) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _descriptionExpanded = !_descriptionExpanded),
              child: Text(
                _descriptionExpanded ? 'Show less' : 'Read more',
                style: const TextStyle(
                  color: _kPrimaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Provider card ─────────────────────────────────────────────────────

  Widget _buildProviderCard() {
    final seller = _product!.seller!;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: _kSurface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About the Provider',
            style: TextStyle(
              color: _kPrimaryText,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _openSellerProfile,
            child: Row(
              children: [
                _buildAvatar(seller, radius: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              seller.displayName,
                              style: const TextStyle(
                                color: _kPrimaryText,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (seller.isVerified)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: HeroIcon(
                                HeroIcons.checkBadge,
                                size: 18,
                                color: _kPrimaryText,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (seller.rating > 0)
                        Row(
                          children: [
                            _buildStarRow(seller.rating),
                            const SizedBox(width: 4),
                            Text(
                              seller.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: _kSecondaryText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildProviderStat(
                  label: 'Total Sales',
                  value: '${seller.totalSales}',
                  icon: HeroIcons.shoppingBag,
                ),
              ),
              Container(width: 1, height: 36, color: _kDivider),
              Expanded(
                child: _buildProviderStat(
                  label: 'Listings',
                  value: '${seller.productCount}',
                  icon: HeroIcons.tag,
                ),
              ),
              if (_product!.ordersCount > 0) ...[
                Container(width: 1, height: 36, color: _kDivider),
                Expanded(
                  child: _buildProviderStat(
                    label: 'Bookings',
                    value: '${_product!.ordersCount}',
                    icon: HeroIcons.calendar,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProviderStat({
    required String label,
    required String value,
    required HeroIcons icon,
  }) {
    return Column(
      children: [
        HeroIcon(icon, size: 20, color: _kSecondaryText),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: _kPrimaryText,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: _kTertiaryText, fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ── Reviews section ───────────────────────────────────────────────────

  Widget _buildReviewsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: _kSurface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Reviews',
                  style: TextStyle(
                    color: _kPrimaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_reviewStats != null && _reviewStats!.totalReviews > 0)
                Text(
                  '${_reviewStats!.totalReviews} total',
                  style: const TextStyle(color: _kTertiaryText, fontSize: 13),
                ),
            ],
          ),

          // Rating summary
          if (_reviewStats != null && _reviewStats!.totalReviews > 0) ...[
            const SizedBox(height: 14),
            _buildRatingSummary(),
          ],

          const SizedBox(height: 14),

          if (_reviewsLoading) ...[
            _buildReviewShimmer(),
            const SizedBox(height: 8),
            _buildReviewShimmer(),
          ] else if (_reviews.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Icon(Icons.star_outline_rounded,
                        size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text(
                      'No reviews yet',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Be the first to review this service',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._reviews.take(3).map((review) => _buildReviewItem(review)),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    final stats = _reviewStats!;
    return Row(
      children: [
        Column(
          children: [
            Text(
              stats.averageRating.toStringAsFixed(1),
              style: const TextStyle(
                color: _kPrimaryText,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            _buildStarRow(stats.averageRating),
            const SizedBox(height: 2),
            Text(
              '${stats.totalReviews} reviews',
              style: const TextStyle(color: _kTertiaryText, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: List.generate(5, (i) {
              final star = 5 - i;
              final pct = stats.getPercentForRating(star) / 100;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text(
                      '$star',
                      style: const TextStyle(
                          color: _kTertiaryText, fontSize: 11),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: _kDivider,
                          color: _kPrimaryText,
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewItem(Review review) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _kDivider,
                backgroundImage: review.user?.avatarUrl.isNotEmpty == true
                    ? NetworkImage(review.user!.avatarUrl)
                    : null,
                child: review.user?.avatarUrl.isEmpty != false
                    ? Text(
                        (review.user?.firstName.isNotEmpty == true)
                            ? review.user!.firstName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: _kSecondaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.user?.fullName ?? 'Anonymous',
                      style: const TextStyle(
                        color: _kPrimaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        _buildStarRow(review.rating.toDouble(), size: 12),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(review.createdAt),
                          style: const TextStyle(
                              color: _kTertiaryText, fontSize: 11),
                        ),
                        if (review.isVerifiedPurchase) ...[
                          const SizedBox(width: 4),
                          const HeroIcon(
                            HeroIcons.checkBadge,
                            size: 12,
                            color: _kSecondaryText,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              review.comment!,
              style: const TextStyle(
                color: _kSecondaryText,
                fontSize: 13,
                height: 1.5,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          const Divider(height: 1, color: _kDivider),
        ],
      ),
    );
  }

  Widget _buildReviewShimmer() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _kDivider,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(width: 100, height: 12),
                const SizedBox(height: 6),
                _shimmerBox(height: 12),
                const SizedBox(height: 4),
                _shimmerBox(width: 200, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom action bar ─────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: _kSurface,
          border: const Border(top: BorderSide(color: _kDivider, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Message Seller
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _onMessageSeller,
                  icon: const HeroIcon(HeroIcons.chatBubbleOvalLeft, size: 18),
                  label: const Text(
                    'Message',
                    style: TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimaryText,
                    side: const BorderSide(color: _kPrimaryText, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Book Now
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 48,
                  child: ElevatedButton.icon(
                  onPressed: _onBookNow,
                  icon: const HeroIcon(HeroIcons.calendar, size: 18, color: Colors.white),
                  label: const Text(
                    'Book Now',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimaryText,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shimmer loading ───────────────────────────────────────────────────

  Widget _buildShimmer() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerBox(height: 280 + MediaQuery.of(context).padding.top, radius: 0),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(width: 220, height: 24),
                const SizedBox(height: 12),
                _shimmerBox(width: 140, height: 30),
                const SizedBox(height: 12),
                _shimmerBox(width: 180, height: 16),
                const SizedBox(height: 24),
                _shimmerBox(height: 1),
                const SizedBox(height: 16),
                _shimmerBox(height: 16),
                const SizedBox(height: 8),
                _shimmerBox(height: 16),
                const SizedBox(height: 8),
                _shimmerBox(width: 240, height: 16),
                const SizedBox(height: 24),
                _shimmerBox(height: 100, radius: 12),
                const SizedBox(height: 16),
                _shimmerBox(height: 48, radius: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox({double width = double.infinity, double height = 16, double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  Widget _buildStarRow(double rating, {double size = 14}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.floor();
        final half = !filled && i < rating;
        return Icon(
          filled
              ? Icons.star_rounded
              : half
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
          size: size,
          color: const Color(0xFFFFC107),
        );
      }),
    );
  }

  Widget _buildMetaChip({required HeroIcons icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kDivider, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HeroIcon(icon, size: 14, color: _kSecondaryText),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: _kSecondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ProductSeller seller, {double radius = 20}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _kDivider,
      backgroundImage: seller.avatarUrl.isNotEmpty
          ? NetworkImage(seller.avatarUrl)
          : null,
      child: seller.avatarUrl.isEmpty
          ? Text(
              seller.firstName.isNotEmpty
                  ? seller.firstName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: _kSecondaryText,
                fontSize: radius * 0.7,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays < 1) return 'Today';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }
}
