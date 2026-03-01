import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/shop_models.dart';
import '../cached_media_image.dart';

// DESIGN.md tokens for ProductCard (monochrome palette)
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const Color _kTertiaryText = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kBackground = Color(0xFFFAFAFA);
const double _kCardRadius = 16.0;

/// Compact product card for grid display in marketplace.
/// DESIGN.md: surface, primary/secondary text, 16px radius, 48dp touch targets.
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onAddToCart;
  final bool showSeller;
  final bool compact;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onFavorite,
    this.onAddToCart,
    this.showSeller = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(_kCardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            _buildProductImage(context),

            // Product info
            Padding(
              padding: EdgeInsets.all(compact ? 8 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    product.title,
                    style: TextStyle(
                      color: _kPrimaryText,
                      fontSize: compact ? 13 : 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: compact ? 4 : 6),

                  // Price row
                  _buildPriceRow(),

                  if (!compact) ...[
                    const SizedBox(height: 6),
                    // Rating and sold count
                    _buildRatingRow(context),
                  ],

                  if (!compact && product.locationName != null) ...[
                    const SizedBox(height: 4),
                    _buildLocationRow(),
                  ],

                  if (showSeller && product.seller != null && !compact) ...[
                    const SizedBox(height: 8),
                    _buildSellerRow(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(BuildContext context) {
    final s = AppStringsScope.of(context);
    return AspectRatio(
      aspectRatio: compact ? 1 : 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          product.thumbnailUrl.isNotEmpty
              ? CachedMediaImage(
                  imageUrl: product.thumbnailUrl,
                  fit: BoxFit.cover,
                )
              : Container(
                  color: _kBackground,
                  child: const Center(
                    child: HeroIcon(
                      HeroIcons.photo,
                      size: 40,
                      color: _kTertiaryText,
                    ),
                  ),
                ),

          // Discount badge
          if (product.hasDiscount)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  product.discountPercentFormatted,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Product type badge for digital/service
          if (product.type != ProductType.physical)
            Positioned(
              top: 8,
              left: product.hasDiscount ? null : 8,
              right: product.hasDiscount ? 8 : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _kPrimaryText.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HeroIcon(
                      product.isDigital
                          ? HeroIcons.arrowDownTray
                          : HeroIcons.wrenchScrewdriver,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      product.type.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Favorite button
          if (onFavorite != null)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onFavorite,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kSurface.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: HeroIcon(
                    product.isFavorited
                        ? HeroIcons.heart
                        : HeroIcons.heart,
                    style: product.isFavorited
                        ? HeroIconStyle.solid
                        : HeroIconStyle.outline,
                    size: 18,
                    color: product.isFavorited
                        ? const Color(0xFFDC2626)
                        : _kSecondaryText,
                  ),
                ),
              ),
            ),

          // Out of stock overlay
          if (!product.isInStock)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _kSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      s?.outOfStock ?? 'Out of Stock',
                      style: const TextStyle(
                        color: _kPrimaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceRow() {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                product.priceFormatted,
                style: TextStyle(
                  color: _kPrimaryText,
                  fontSize: compact ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (product.hasDiscount)
                Text(
                  product.compareAtPriceFormatted,
                  style: TextStyle(
                    color: _kTertiaryText,
                    fontSize: compact ? 11 : 12,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
            ],
          ),
        ),
        if (onAddToCart != null && product.isInStock && !compact)
          GestureDetector(
            onTap: onAddToCart,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kPrimaryText,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const HeroIcon(
                HeroIcons.shoppingCart,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRatingRow(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Row(
      children: [
        if (product.reviewsCount > 0) ...[
          const HeroIcon(
            HeroIcons.star,
            style: HeroIconStyle.solid,
            size: 14,
            color: Color(0xFFF59E0B),
          ),
          const SizedBox(width: 2),
          Text(
            product.ratingFormatted,
            style: const TextStyle(
              color: _kSecondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(${product.reviewsCount})',
            style: const TextStyle(
              color: _kTertiaryText,
              fontSize: 11,
            ),
          ),
          if (product.ordersCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              width: 3,
              height: 3,
              decoration: const BoxDecoration(
                color: _kTertiaryText,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
        if (product.ordersCount > 0)
          Text(
            '${product.ordersCount} ${s?.sold ?? 'sold'}',
            style: const TextStyle(
              color: _kTertiaryText,
              fontSize: 11,
            ),
          ),
      ],
    );
  }

  Widget _buildLocationRow() {
    return Row(
      children: [
        const HeroIcon(
          HeroIcons.mapPin,
          size: 12,
          color: _kTertiaryText,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            product.locationName!,
            style: const TextStyle(
              color: _kTertiaryText,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSellerRow() {
    final seller = product.seller!;
    return Row(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundImage: seller.avatarUrl.isNotEmpty
              ? NetworkImage(seller.avatarUrl)
              : null,
          backgroundColor: _kBackground,
          child: seller.avatarUrl.isEmpty
              ? Text(
                  seller.firstName.isNotEmpty ? seller.firstName[0] : 'U',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            seller.displayName,
            style: const TextStyle(
              color: _kSecondaryText,
              fontSize: 11,
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
              style: HeroIconStyle.solid,
              size: 14,
              color: Color(0xFF3B82F6),
            ),
          ),
      ],
    );
  }
}

/// Horizontal product card for lists and search results.
class ProductListCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final Widget? trailing;

  const ProductListCard({
    super.key,
    required this.product,
    this.onTap,
    this.onFavorite,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(_kCardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 80,
                height: 80,
                child: product.thumbnailUrl.isNotEmpty
                    ? CachedMediaImage(
                        imageUrl: product.thumbnailUrl,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: _kBackground,
                        child: const Center(
                          child: HeroIcon(
                            HeroIcons.photo,
                            size: 24,
                            color: _kTertiaryText,
                          ),
                        ),
                      ),
              ),
            ),

            const SizedBox(width: 12),

            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      color: _kPrimaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        product.priceFormatted,
                        style: const TextStyle(
                          color: _kPrimaryText,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (product.hasDiscount) ...[
                        const SizedBox(width: 8),
                        Text(
                          product.compareAtPriceFormatted,
                          style: const TextStyle(
                            color: _kTertiaryText,
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (product.reviewsCount > 0) ...[
                        const HeroIcon(
                          HeroIcons.star,
                          style: HeroIconStyle.solid,
                          size: 12,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          product.ratingFormatted,
                          style: const TextStyle(
                            color: _kSecondaryText,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (product.ordersCount > 0)
                        Text(
                          '${product.ordersCount} sold',
                          style: const TextStyle(
                            color: _kTertiaryText,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Trailing widget or favorite button
            if (trailing != null)
              trailing!
            else if (onFavorite != null)
              IconButton(
                onPressed: onFavorite,
                icon: HeroIcon(
                  HeroIcons.heart,
                  style: product.isFavorited
                      ? HeroIconStyle.solid
                      : HeroIconStyle.outline,
                  size: 22,
                  color: product.isFavorited
                      ? const Color(0xFFDC2626)
                      : _kSecondaryText,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Small product card for horizontal scrolling sections.
class ProductSmallCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final double width;

  const ProductSmallCard({
    super.key,
    required this.product,
    this.onTap,
    this.width = 140,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  product.thumbnailUrl.isNotEmpty
                      ? CachedMediaImage(
                          imageUrl: product.thumbnailUrl,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: _kBackground,
                          child: const Center(
                            child: HeroIcon(
                              HeroIcons.photo,
                              size: 28,
                              color: _kTertiaryText,
                            ),
                          ),
                        ),
                  if (product.hasDiscount)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.discountPercentFormatted,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      color: _kPrimaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.priceFormatted,
                    style: const TextStyle(
                      color: _kPrimaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Category chip for filtering products.
class CategoryChip extends StatelessWidget {
  final ProductCategory category;
  final bool isSelected;
  final VoidCallback? onTap;

  const CategoryChip({
    super.key,
    required this.category,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimaryText : _kSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? _kPrimaryText : _kDivider,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category.icon != null) ...[
              Text(
                category.icon!,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              category.name,
              style: TextStyle(
                color: isSelected ? Colors.white : _kPrimaryText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cart item card for shopping cart screen.
class CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback? onRemove;
  final ValueChanged<int>? onQuantityChanged;

  const CartItemCard({
    super.key,
    required this.item,
    this.onRemove,
    this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final s = AppStringsScope.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 80,
              height: 80,
              child: product?.thumbnailUrl.isNotEmpty == true
                  ? CachedMediaImage(
                      imageUrl: product!.thumbnailUrl,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: _kBackground,
                      child: const Center(
                        child: HeroIcon(
                          HeroIcons.photo,
                          size: 24,
                          color: _kTertiaryText,
                        ),
                      ),
                    ),
            ),
          ),

          const SizedBox(width: 12),

          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product?.title ?? s?.product ?? 'Product',
                  style: const TextStyle(
                    color: _kPrimaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  item.lineTotalFormatted,
                  style: const TextStyle(
                    color: _kPrimaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Quantity controls
          Column(
            children: [
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const HeroIcon(
                    HeroIcons.xMark,
                    size: 18,
                    color: _kTertiaryText,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
              const SizedBox(height: 4),
              if (onQuantityChanged != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildQuantityButton(
                      icon: HeroIcons.minus,
                      onTap: item.quantity > 1
                          ? () => onQuantityChanged!(item.quantity - 1)
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          color: _kPrimaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _buildQuantityButton(
                      icon: HeroIcons.plus,
                      onTap: () => onQuantityChanged!(item.quantity + 1),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required HeroIcons icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: onTap != null ? _kPrimaryText : _kDivider,
          borderRadius: BorderRadius.circular(6),
        ),
        child: HeroIcon(
          icon,
          size: 14,
          color: onTap != null ? Colors.white : _kTertiaryText,
        ),
      ),
    );
  }
}

/// Order card for order history screens.
class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;
  final bool isSeller;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.isSeller = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(_kCardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${s?.order ?? 'Order'} #${order.orderNumber}',
                        style: const TextStyle(
                          color: _kPrimaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(context, order.createdAt),
                        style: const TextStyle(
                          color: _kTertiaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: _kDivider, height: 1),
            const SizedBox(height: 12),

            // Product info
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: order.product?.thumbnailUrl.isNotEmpty == true
                        ? CachedMediaImage(
                            imageUrl: order.product!.thumbnailUrl,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: _kBackground,
                            child: const Center(
                              child: HeroIcon(
                                HeroIcons.photo,
                                size: 20,
                                color: _kTertiaryText,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.product?.title ?? s?.product ?? 'Product',
                        style: const TextStyle(
                          color: _kPrimaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'x${order.quantity}',
                        style: const TextStyle(
                          color: _kSecondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  order.totalFormatted,
                  style: const TextStyle(
                    color: _kPrimaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Buyer/Seller info
            if (isSeller && order.buyer != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const HeroIcon(
                    HeroIcons.user,
                    size: 14,
                    color: _kSecondaryText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${s?.buyer ?? 'Buyer'}: ${order.buyer!.fullName}',
                    style: const TextStyle(
                      color: _kSecondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
            if (!isSeller && order.seller != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const HeroIcon(
                    HeroIcons.buildingStorefront,
                    size: 14,
                    color: _kSecondaryText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${s?.seller ?? 'Seller'}: ${order.seller!.fullName}',
                    style: const TextStyle(
                      color: _kSecondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor;

    switch (order.status) {
      case OrderStatus.pending:
        backgroundColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFD97706);
        break;
      case OrderStatus.confirmed:
      case OrderStatus.processing:
        backgroundColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF2563EB);
        break;
      case OrderStatus.shipped:
        backgroundColor = const Color(0xFFE0E7FF);
        textColor = const Color(0xFF4F46E5);
        break;
      case OrderStatus.delivered:
        backgroundColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF059669);
        break;
      case OrderStatus.completed:
        backgroundColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF047857);
        break;
      case OrderStatus.cancelled:
        backgroundColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFDC2626);
        break;
      case OrderStatus.refunded:
        backgroundColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        order.status.label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final s = AppStringsScope.of(context);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return s?.today ?? 'Today';
    } else if (diff.inDays == 1) {
      return s?.yesterday ?? 'Yesterday';
    } else if (diff.inDays < 7) {
      return s?.daysAgo(diff.inDays) ?? '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Review card for product reviews section.
class ReviewCard extends StatelessWidget {
  final Review review;
  final VoidCallback? onHelpful;

  const ReviewCard({
    super.key,
    required this.review,
    this.onHelpful,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: _kDivider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: review.user?.avatarUrl.isNotEmpty == true
                    ? NetworkImage(review.user!.avatarUrl)
                    : null,
                backgroundColor: _kBackground,
                child: review.user?.avatarUrl.isEmpty != false
                    ? Text(
                        review.user?.firstName.isNotEmpty == true
                            ? review.user!.firstName[0]
                            : 'U',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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
                        Text(
                          review.user?.fullName ?? s?.user ?? 'User',
                          style: const TextStyle(
                            color: _kPrimaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (review.isVerifiedPurchase) ...[
                          const SizedBox(width: 6),
                          const HeroIcon(
                            HeroIcons.checkBadge,
                            style: HeroIconStyle.solid,
                            size: 14,
                            color: Color(0xFF10B981),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => HeroIcon(
                            HeroIcons.star,
                            style: index < review.rating
                                ? HeroIconStyle.solid
                                : HeroIconStyle.outline,
                            size: 12,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(context, review.createdAt),
                          style: const TextStyle(
                            color: _kTertiaryText,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Comment
          if (review.comment?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(
              review.comment!,
              style: const TextStyle(
                color: _kSecondaryText,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],

          // Images
          if (review.hasImages) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.imageUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedMediaImage(
                      imageUrl: review.imageUrls[index],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ],

          // Helpful button
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: onHelpful,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: review.isHelpful == true ? _kPrimaryText : _kBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HeroIcon(
                        HeroIcons.handThumbUp,
                        style: review.isHelpful == true
                            ? HeroIconStyle.solid
                            : HeroIconStyle.outline,
                        size: 14,
                        color: review.isHelpful == true
                            ? Colors.white
                            : _kSecondaryText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${s?.helpful ?? 'Helpful'} (${review.helpfulCount})',
                        style: TextStyle(
                          color: review.isHelpful == true
                              ? Colors.white
                              : _kSecondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final s = AppStringsScope.of(context);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return s?.today ?? 'Today';
    } else if (diff.inDays == 1) {
      return s?.yesterday ?? 'Yesterday';
    } else if (diff.inDays < 30) {
      return s?.daysAgo(diff.inDays) ?? '${diff.inDays} days ago';
    } else if (diff.inDays < 365) {
      final months = diff.inDays ~/ 30;
      return s?.monthsAgo(months) ?? '$months months ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
