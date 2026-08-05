import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heroicons/heroicons.dart';
import 'package:share_plus/share_plus.dart';
import '../../../l10n/app_strings_scope.dart';
import '../../../models/shop_models.dart';
import '../../../config/api_config.dart';
import '../../../services/local_storage_service.dart';
import '../../data/repositories/shop_repository.dart';
import '../../../services/shop_database.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/review_section.dart';
import '../../shared/widgets/stock_urgency_badge.dart';
import '../../shared/widgets/zoomable_image_gallery.dart';
import '../../seller/models/trust_models.dart';
import '../../seller/services/seller_verification_service.dart';
import '../../seller/widgets/trust_badge_row.dart';
import '../../offers/screens/make_offer_screen.dart';

// DESIGN.md tokens
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const Color _kTertiaryText = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);

// ─── Bilingual label helpers ────────────────────────────────────────────

String _productTypeLabel(BuildContext context, ProductType type) {
  final s = AppStringsScope.of(context);
  switch (type) {
    case ProductType.physical:
      return s?.productTypePhysical ?? 'Physical';
    case ProductType.digital:
      return s?.productTypeDigital ?? 'Digital';
    case ProductType.service:
      return s?.productTypeService ?? 'Service';
  }
}

String _conditionLabel(BuildContext context, ProductCondition condition) {
  final s = AppStringsScope.of(context);
  switch (condition) {
    case ProductCondition.brandNew:
      return s?.conditionNew ?? 'New';
    case ProductCondition.used:
      return s?.conditionUsed ?? 'Used';
    case ProductCondition.refurbished:
      return s?.conditionRefurbished ?? 'Refurbished';
  }
}

/// Product detail screen showing full product information.
class ProductDetailScreen extends StatefulWidget {
  final int productId;
  final int currentUserId;

  /// UN-012: when this screen is opened from a post tagged-product chip,
  /// the post id is forwarded so backend fires product_expand·author.
  final int? originPostId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.currentUserId,
    this.originPostId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ShopRepository _repo = ShopRepository.instance;

  Product? _product;
  bool _isLoading = true;
  String? _error;

  // Trust profile
  SellerTrustProfile? _sellerTrustProfile;

  // Reviews
  List<Review> _reviews = [];
  ReviewStats? _reviewStats;
  bool _reviewsLoading = true;

  // Related products
  List<Product> _relatedProducts = [];
  bool _relatedLoading = true;

  // Description expand/collapse
  bool _descriptionExpanded = false;

  // Add to cart state
  int _quantity = 1;
  DeliveryMethod _selectedDelivery = DeliveryMethod.pickup;

  // Offer state
  bool _offerSent = false;

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
          // Record view in SQLite for recently viewed
          ShopDatabase.instance.markViewed(_product!.id);
          _setDefaultDeliveryMethod();
          _loadRelatedProducts();
          _loadSellerTrust();
        } else {
          final s = AppStringsScope.of(context);
          _error = result.message ?? s?.productNotFound ?? 'Product not found';
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

  Future<void> _loadSellerTrust() async {
    if (_product?.seller == null) return;
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken() ?? '';
    final trust = await SellerVerificationService.getTrustProfile(
      _product!.seller!.id,
      token,
    );
    if (!mounted) return;
    setState(() => _sellerTrustProfile = trust);
  }

  Future<void> _loadRelatedProducts() async {
    if (_product?.categoryId == null) return;
    setState(() => _relatedLoading = true);
    final result = await _repo.getProducts(
      categoryId: _product!.categoryId,
      perPage: 10,
      currentUserId: widget.currentUserId,
    );
    if (!mounted) return;
    setState(() {
      _relatedLoading = false;
      if (result.success) {
        _relatedProducts = result.products
            .where((p) => p.id != widget.productId)
            .take(6)
            .toList();
      }
    });
  }

  void _recordView() {
    _repo.recordProductView(
      widget.productId,
      userId: widget.currentUserId,
      originPostId: widget.originPostId,
    );
  }

  void _setDefaultDeliveryMethod() {
    if (_product == null) return;
    if (_product!.isDigital) {
      _selectedDelivery = DeliveryMethod.digital;
    } else if (_product!.allowDelivery) {
      _selectedDelivery = DeliveryMethod.delivery;
    } else if (_product!.allowShipping) {
      _selectedDelivery = DeliveryMethod.shipping;
    } else {
      _selectedDelivery = DeliveryMethod.pickup;
    }
  }

  Future<void> _toggleFavorite() async {
    if (_product == null) return;
    final wasFavorited = _product!.isFavorited;

    // Optimistic update
    setState(() {
      _product = _product!.copyWith(
        isFavorited: !wasFavorited,
        favoritesCount: _product!.favoritesCount + (wasFavorited ? -1 : 1),
      );
    });
    HapticFeedback.lightImpact();

    // API call in background
    try {
      final result = await _repo.toggleFavorite(
        widget.currentUserId,
        _product!.id,
        originPostId: widget.originPostId,
      );
      if (!result.success && mounted) {
        // Revert on failure
        setState(() {
          _product = _product!.copyWith(
            isFavorited: wasFavorited,
            favoritesCount: _product!.favoritesCount + (wasFavorited ? 1 : -1),
          );
        });
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _product = _product!.copyWith(
            isFavorited: wasFavorited,
            favoritesCount: _product!.favoritesCount + (wasFavorited ? 1 : -1),
          );
        });
      }
    }

    // Sync SQLite wishlist
    try {
      if (!wasFavorited) {
        await ShopDatabase.instance.addToWishlist(_product!.id, _product!.price, jsonEncode(_product!.toJson()));
      } else {
        await ShopDatabase.instance.removeFromWishlist(_product!.id);
      }
    } catch (_) {
      // SQLite sync is best-effort
    }
  }

  void _buyNow() {
    if (_product == null) return;
    Navigator.pushNamed(
      context,
      '/shop/checkout',
      arguments: {
        'product': _product,
        'quantity': _quantity,
        'deliveryMethod': _selectedDelivery,
      },
    );
  }

  String get _productShareUrl =>
      '${ApiConfig.baseUrl.replaceFirst('/api', '')}/shop/product/${_product!.id}';

  String get _productShareText =>
      '${_product!.title} - ${_product!.priceFormatted}\n$_productShareUrl';

  void _shareProduct() {
    if (_product == null) return;
    final s = AppStringsScope.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _kDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                s?.shareProduct ?? 'Share product',
                style: const TextStyle(
                  color: _kPrimaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),

            // Share to external apps (like Instagram)
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kPrimaryText.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: HeroIcon(HeroIcons.share, size: 20, color: _kPrimaryText),
                ),
              ),
              title: Text(s?.shareToApps ?? 'Share to apps'),
              subtitle: Text(
                s?.shareVia ?? 'Share via...',
                style: const TextStyle(fontSize: 12, color: _kTertiaryText),
              ),
              onTap: () {
                Navigator.pop(ctx);
                SharePlus.instance.share(
                  ShareParams(text: _productShareText),
                );
              },
            ),

            // Send to a friend (internal message)
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kPrimaryText.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: HeroIcon(HeroIcons.paperAirplane, size: 20, color: _kPrimaryText),
                ),
              ),
              title: Text(s?.sendToFriend ?? 'Send to a friend'),
              onTap: () {
                Navigator.pop(ctx);
                // Navigate to select-user-chat to pick a friend, then
                // the product link can be shared via the share intent.
                Navigator.pushNamed(context, '/select-user-chat');
              },
            ),

            // Copy link
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kPrimaryText.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: HeroIcon(HeroIcons.link, size: 20, color: _kPrimaryText),
                ),
              ),
              title: Text(s?.copyLink ?? 'Copy link'),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: _productShareUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(s?.linkCopied ?? 'Link copied to clipboard'),
                  ),
                );
              },
            ),

            // Repost
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kPrimaryText.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: HeroIcon(HeroIcons.arrowPath, size: 20, color: _kPrimaryText),
                ),
              ),
              title: Text(s?.repost ?? 'Repost'),
              onTap: () {
                Navigator.pop(ctx);
                // Share as a post on user's feed
                Navigator.pushNamed(
                  context,
                  '/create-post',
                  arguments: {
                    'sharedProductId': _product!.id,
                    'sharedText': _productShareText,
                  },
                );
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openSellerProfile() {
    if (_product?.seller == null) return;
    Navigator.pushNamed(
      context,
      '/profile/${_product!.seller!.id}',
    );
  }

  void _showWriteReviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _WriteReviewSheet(
        productId: widget.productId,
        userId: widget.currentUserId,
        shopRepo: _repo,
        onSubmitted: (review) {
          setState(() {
            _reviews.insert(0, review);
          });
        },
      ),
    );
  }

  void _openReviews() {
    // Reviews are displayed inline in the ReviewSection widget below.
    // Scroll to the review section instead of navigating to an unregistered route.
    // For now, trigger write-review sheet as the "see all" action.
    _showWriteReviewSheet();
  }

  Widget _buildShimmer({double width = double.infinity, double height = 16, double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildPdpShimmer() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmer(height: 300, radius: 0), // image area
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmer(width: 200, height: 20),
                const SizedBox(height: 12),
                _buildShimmer(width: 120, height: 24),
                const SizedBox(height: 16),
                _buildShimmer(height: 14),
                const SizedBox(height: 8),
                _buildShimmer(height: 14),
                const SizedBox(height: 8),
                _buildShimmer(width: 180, height: 14),
                const SizedBox(height: 24),
                _buildShimmer(height: 48, radius: 12), // button placeholder
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        top: false, // image gallery extends behind status bar
        child: _isLoading
            ? _buildPdpShimmer()
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
            style: const TextStyle(
              color: _kSecondaryText,
              fontSize: 16,
            ),
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
        // Image gallery
        SliverToBoxAdapter(child: _buildImageGallery()),

        // Product info
        SliverToBoxAdapter(child: _buildProductInfo()),

        // Delivery options
        if (_product!.type != ProductType.digital)
          SliverToBoxAdapter(child: _buildDeliveryOptions()),

        // Location
        if (_product!.locationName != null &&
            _product!.locationName!.isNotEmpty)
          SliverToBoxAdapter(child: _buildLocationSection()),

        // Seller card
        if (_product!.seller != null)
          SliverToBoxAdapter(child: _buildSellerCard()),

        // Description
        if (_product!.description?.isNotEmpty == true)
          SliverToBoxAdapter(child: _buildDescription()),

        // Reviews section
        SliverToBoxAdapter(
          child: ReviewSection(
            reviews: _reviews,
            stats: _reviewStats,
            isLoading: _reviewsLoading,
            onWriteReview: _showWriteReviewSheet,
            onSeeAll: _openReviews,
          ),
        ),

        // Related products
        if (_relatedProducts.isNotEmpty || _relatedLoading)
          SliverToBoxAdapter(child: _buildRelatedProducts()),

        // Bottom padding for bottom bar
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildImageGallery() {
    return Stack(
      children: [
        ZoomableImageGallery(
          imageUrls: _product!.imageUrls,
          height: 350,
          heroTag: 'product_image_${widget.productId}',
        ),

        // Back button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
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

        // Share and favorite
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 8,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _kSurface.withValues(alpha: 0.9),
                child: IconButton(
                  onPressed: _shareProduct,
                  icon: const HeroIcon(
                    HeroIcons.share,
                    size: 22,
                    color: _kPrimaryText,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
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
            ],
          ),
        ),

        // Discount badge
        if (_product!.hasDiscount)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _product!.discountPercentFormatted,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: _kSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            _product!.title,
            style: const TextStyle(
              color: _kPrimaryText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 12),

          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _product!.priceFormatted,
                style: const TextStyle(
                  color: _kPrimaryText,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_product!.hasDiscount) ...[
                const SizedBox(width: 12),
                Text(
                  _product!.compareAtPriceFormatted,
                  style: const TextStyle(
                    color: _kTertiaryText,
                    fontSize: 16,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          StockUrgencyBadge(stockQuantity: _product!.stockQuantity),

          _buildBuyerProtectionBanner(),

          // Rating and stats
          Row(
            children: [
              if (_product!.reviewsCount > 0) ...[
                const HeroIcon(
                  HeroIcons.star,
                  style: HeroIconStyle.solid,
                  size: 18,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 4),
                Text(
                  _product!.ratingFormatted,
                  style: const TextStyle(
                    color: _kPrimaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Builder(builder: (context) {
                  final s = AppStringsScope.of(context);
                  return GestureDetector(
                    onTap: _openReviews,
                    child: Text(
                      '(${_product!.reviewsCount} ${s?.reviews ?? 'reviews'})',
                      style: const TextStyle(
                        color: _kSecondaryText,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 16),
              ],
              if (_product!.ordersCount > 0)
                Builder(builder: (context) {
                  final s = AppStringsScope.of(context);
                  return Text(
                    '${_product!.ordersCount} ${s?.sold ?? 'sold'}',
                    style: const TextStyle(
                      color: _kSecondaryText,
                      fontSize: 14,
                    ),
                  );
                }),
            ],
          ),

          const SizedBox(height: 16),

          // Badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Product type
              _buildBadge(
                icon: _product!.isDigital
                    ? HeroIcons.arrowDownTray
                    : _product!.isService
                        ? HeroIcons.wrenchScrewdriver
                        : HeroIcons.cube,
                text: _productTypeLabel(context, _product!.type),
              ),
              // Condition (physical only)
              if (_product!.type == ProductType.physical)
                _buildBadge(
                  icon: HeroIcons.tag,
                  text: _conditionLabel(context, _product!.condition),
                ),
              // Stock
              if (_product!.type == ProductType.physical)
                Builder(builder: (context) {
                  final s = AppStringsScope.of(context);
                  return _buildBadge(
                    icon: HeroIcons.archiveBox,
                    text: _product!.isInStock
                        ? '${s?.inStock ?? 'In Stock'} (${_product!.stockQuantity})'
                        : s?.outOfStock ?? 'Out of Stock',
                    color: _product!.isInStock
                        ? const Color(0xFF10B981)
                        : const Color(0xFFDC2626),
                  );
                }),
            ],
          ),

          // Quantity selector
          if (_product!.isInStock) ...[
            const SizedBox(height: 20),
            Builder(builder: (context) {
              final s = AppStringsScope.of(context);
              return Row(
                children: [
                  Text(
                    '${s?.quantity ?? 'Quantity'}:',
                    style: const TextStyle(
                      color: _kPrimaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildQuantitySelector(),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge({
    required HeroIcons icon,
    required String text,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? _kSecondaryText).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HeroIcon(
            icon,
            size: 14,
            color: color ?? _kSecondaryText,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color ?? _kSecondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _kDivider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _quantity > 1
                ? () => setState(() => _quantity--)
                : null,
            icon: const HeroIcon(HeroIcons.minus, size: 18),
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 40),
            alignment: Alignment.center,
            child: Text(
              '$_quantity',
              style: const TextStyle(
                color: _kPrimaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              final maxQty = _product!.stockQuantity > 0
                  ? _product!.stockQuantity
                  : 99;
              if (_quantity < maxQty) {
                setState(() => _quantity++);
              }
            },
            icon: const HeroIcon(HeroIcons.plus, size: 18),
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryOptions() {
    final s = AppStringsScope.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: _kSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s?.deliveryMethod ?? 'Delivery Method',
            style: const TextStyle(
              color: _kPrimaryText,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (_product!.allowPickup)
            _buildDeliveryOption(
              method: DeliveryMethod.pickup,
              icon: HeroIcons.mapPin,
              title: s?.pickup ?? 'Pickup',
              subtitle: _product!.pickupAddress ?? _product!.locationName ?? s?.sellerLocation ?? 'Seller\'s location',
              fee: null,
            ),

          if (_product!.allowDelivery)
            _buildDeliveryOption(
              method: DeliveryMethod.delivery,
              icon: HeroIcons.truck,
              title: s?.delivery ?? 'Delivery',
              subtitle: s?.withinCity ?? 'Within city',
              fee: _product!.deliveryFee,
            ),

          if (_product!.allowShipping)
            _buildDeliveryOption(
              method: DeliveryMethod.shipping,
              icon: HeroIcons.paperAirplane,
              title: s?.shipping ?? 'Shipping',
              subtitle: s?.nationwide ?? 'Nationwide',
              fee: _product!.deliveryFee,
            ),
        ],
      ),
    );
  }

  Widget _buildDeliveryOption({
    required DeliveryMethod method,
    required HeroIcons icon,
    required String title,
    required String subtitle,
    double? fee,
  }) {
    final isSelected = _selectedDelivery == method;

    return GestureDetector(
      onTap: () => setState(() => _selectedDelivery = method),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimaryText.withValues(alpha: 0.05) : _kBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _kPrimaryText : _kDivider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? _kPrimaryText : _kDivider,
                borderRadius: BorderRadius.circular(10),
              ),
              child: HeroIcon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : _kSecondaryText,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _kPrimaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _kSecondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (fee != null)
              Text(
                'TZS ${fee.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: _kPrimaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Builder(builder: (context) {
                final s = AppStringsScope.of(context);
                return Text(
                  s?.free ?? 'Free',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    final s = AppStringsScope.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: _kSurface,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kPrimaryText.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const HeroIcon(
              HeroIcons.mapPin,
              size: 20,
              color: _kPrimaryText,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s?.location ?? 'Location',
                  style: const TextStyle(
                    color: _kSecondaryText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _product!.locationName!,
                  style: const TextStyle(
                    color: _kPrimaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerCard() {
    final seller = _product!.seller!;
    final s = AppStringsScope.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: _kSurface,
      child: GestureDetector(
        onTap: _openSellerProfile,
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: seller.avatarUrl.isNotEmpty
                  ? NetworkImage(seller.avatarUrl)
                  : null,
              backgroundColor: _kBackground,
              child: seller.avatarUrl.isEmpty
                  ? Text(
                      seller.firstName.isNotEmpty
                          ? seller.firstName[0]
                          : 'U',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
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
                          seller.displayName,
                          style: const TextStyle(
                            color: _kPrimaryText,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (seller.isVerified || (_sellerTrustProfile?.isVerified == true)) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: Color(0xFF1A1A1A),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (_sellerTrustProfile != null)
                    TrustBadgeRow(profile: _sellerTrustProfile!),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const HeroIcon(
                        HeroIcons.star,
                        style: HeroIconStyle.solid,
                        size: 12,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${seller.rating.toStringAsFixed(1)} · ${seller.totalSales} ${s?.sales ?? 'sales'}',
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
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: _kPrimaryText),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                s?.viewShop ?? 'View Shop',
                style: const TextStyle(
                  color: _kPrimaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription() {
    final s = AppStringsScope.of(context);
    final description = _product!.description!;
    // Show expand toggle only for long descriptions (> 3 lines ~ 150 chars)
    final isLong = description.length > 150;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: _kSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s?.description ?? 'Description',
            style: const TextStyle(
              color: _kPrimaryText,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedCrossFade(
            firstChild: Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _kSecondaryText,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            secondChild: Text(
              description,
              style: const TextStyle(
                color: _kSecondaryText,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            crossFadeState: _descriptionExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
          if (isLong)
            GestureDetector(
              onTap: () =>
                  setState(() => _descriptionExpanded = !_descriptionExpanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _descriptionExpanded
                      ? (s?.showLess ?? 'Show less')
                      : (s?.showMore ?? 'Show more'),
                  style: const TextStyle(
                    color: _kPrimaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRelatedProducts() {
    final s = AppStringsScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            s?.relatedProducts ?? 'Related Products',
            style: const TextStyle(
              color: _kPrimaryText,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 220,
          child: _relatedLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: _kPrimaryText,
                    strokeWidth: 2,
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _relatedProducts.length,
                  separatorBuilder: (context, i) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final product = _relatedProducts[index];
                    return SizedBox(
                      width: 160,
                      child: ProductCard(
                        product: product,
                        compact: true,
                        showSeller: false,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/shop/product',
                            arguments: {'productId': product.id},
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _openMakeOffer() {
    if (_product == null) return;
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MakeOfferScreen(product: _product!),
      ),
    ).then((sent) {
      if (sent == true && mounted) {
        setState(() => _offerSent = true);
        Navigator.pushNamed(context, '/shop/my-offers');
      }
    });
  }

  Widget _buildBottomBar() {
    final p = _product!;
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    final isSeller = p.seller?.id == widget.currentUserId;
    final canOffer = !isSeller && !p.isDigital && p.isInStock;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: _kSurface,
        border: Border(top: BorderSide(color: _kDivider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Price row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.priceFormatted,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _kPrimaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (p.compareAtPrice != null && p.compareAtPrice! > p.price)
                      Text(
                        'TZS ${p.compareAtPrice!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9E9E9E),
                          decoration: TextDecoration.lineThrough,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Favorite + share icon buttons
              _buildIconBtn(
                icon: HeroIcon(
                  HeroIcons.heart,
                  style: p.isFavorited ? HeroIconStyle.solid : HeroIconStyle.outline,
                  size: 20,
                  color: p.isFavorited ? const Color(0xFFDC2626) : _kPrimaryText,
                ),
                onTap: _toggleFavorite,
              ),
              const SizedBox(width: 6),
              _buildIconBtn(
                icon: const HeroIcon(HeroIcons.share, size: 20, color: _kPrimaryText),
                onTap: _shareProduct,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Primary CTA row
          if (!p.isInStock)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isSwahili ? 'Imeisha' : 'Out of Stock',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
          else
            Row(
              children: [
                // Make an Offer (outlined) — shown for non-digital, non-seller products
                if (canOffer) ...[
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _offerSent ? null : _openMakeOffer,
                        icon: Icon(
                          _offerSent
                              ? Icons.check_circle_rounded
                              : Icons.local_offer_rounded,
                          size: 16,
                          color: _offerSent
                              ? const Color(0xFF059669)
                              : _kPrimaryText,
                        ),
                        label: Text(
                          _offerSent
                              ? (isSwahili ? 'Tuma' : 'Sent ✓')
                              : (isSwahili ? 'Toa Bei' : 'Make an Offer'),
                          style: TextStyle(
                            color: _offerSent
                                ? const Color(0xFF059669)
                                : _kPrimaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPrimaryText,
                          side: BorderSide(
                            color: _offerSent
                                ? const Color(0xFF10B981)
                                : _kPrimaryText,
                          ),
                          backgroundColor: _offerSent
                              ? const Color(0xFFD1FAE5)
                              : Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                // Pay Now (filled, default)
                Expanded(
                  flex: canOffer ? 1 : 2,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSeller ? null : _buyNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimaryText,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        isSwahili ? 'Lipa Sasa' : 'Pay Now',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildIconBtn({required Widget icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: _kDivider),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: icon),
      ),
    );
  }

  Widget _buildBuyerProtectionBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, color: Color(0xFF4CAF50), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Buyer Protection', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                SizedBox(height: 2),
                Text('Money held securely until you confirm delivery', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Write review bottom sheet.
class _WriteReviewSheet extends StatefulWidget {
  final int productId;
  final int userId;
  final ShopRepository shopRepo;
  final ValueChanged<Review> onSubmitted;

  const _WriteReviewSheet({
    required this.productId,
    required this.userId,
    required this.shopRepo,
    required this.onSubmitted,
  });

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  final TextEditingController _commentController = TextEditingController();
  int _selectedRating = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedRating == 0) return;
    setState(() => _submitting = true);

    try {
      final result = await widget.shopRepo.createReview(
        productId: widget.productId,
        userId: widget.userId,
        rating: _selectedRating,
        comment: _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : null,
      );

      if (!mounted) return;
      setState(() => _submitting = false);

      if (result.success) {
        if (result.review != null) {
          widget.onSubmitted(result.review!);
        }
        final messenger = ScaffoldMessenger.of(context);
        final s = AppStringsScope.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(s?.reviewSubmitted ?? 'Review submitted'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Failed to submit review'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting review: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _kDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Center(
            child: Text(
              s?.writeReview ?? 'Write a review',
              style: const TextStyle(
                color: _kPrimaryText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Star rating
          Center(
            child: Column(
              children: [
                Text(
                  s?.tapToRate ?? 'Tap to rate',
                  style: const TextStyle(
                    color: _kSecondaryText,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starNum = index + 1;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedRating = starNum),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: HeroIcon(
                          HeroIcons.star,
                          style: starNum <= _selectedRating
                              ? HeroIconStyle.solid
                              : HeroIconStyle.outline,
                          size: 36,
                          color: starNum <= _selectedRating
                              ? const Color(0xFFF59E0B)
                              : _kDivider,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Comment field
          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: s?.reviewHint ?? 'Share your experience...',
              hintStyle: const TextStyle(color: _kTertiaryText),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kDivider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kDivider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kPrimaryText, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedRating > 0 && !_submitting ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryText,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _kDivider,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      s?.submitReview ?? 'Submit review',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
