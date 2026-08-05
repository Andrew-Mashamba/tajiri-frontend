import 'package:flutter/material.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kText = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF666666);
const Color _kFaint = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);

class _Review {
  final String author;
  final double rating;
  final String body;
  final String date;
  const _Review(this.author, this.rating, this.body, this.date);
}

class _RelatedProduct {
  final String name;
  final String price;
  const _RelatedProduct(this.name, this.price);
}

/// Social media-style product detail (Instagram-like).
class SocialProductDetailScreen extends StatefulWidget {
  const SocialProductDetailScreen({super.key, this.productId});

  final int? productId;

  @override
  State<SocialProductDetailScreen> createState() =>
      _SocialProductDetailScreenState();
}

class _SocialProductDetailScreenState
    extends State<SocialProductDetailScreen> {
  bool _liked = false;
  bool _saved = false;
  final int _likeCount = 412;

  final List<_Review> _reviews = const [
    _Review('Fatuma K.', 4.5,
        'Beautiful quality — exactly as pictured. Very fast delivery!',
        'Apr 28, 2026'),
    _Review('John M.', 5.0,
        'Absolutely love it. Great craftsmanship. Will buy again.',
        'Apr 20, 2026'),
    _Review('Amina S.', 4.0,
        'Good product, packaging could be better. Overall happy.',
        'Apr 14, 2026'),
  ];

  final List<_RelatedProduct> _related = const [
    _RelatedProduct('Red Leso Fabric', 'TZS 16,000'),
    _RelatedProduct('Kitenge Dress', 'TZS 45,000'),
    _RelatedProduct('Sisal Basket', 'TZS 14,000'),
    _RelatedProduct('Beaded Bracelet', 'TZS 9,500'),
    _RelatedProduct('Wooden Bowl', 'TZS 32,000'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildProductInfo(),
              _buildSocialActions(),
              const Divider(height: 1, color: _kDivider),
              _buildActionButtons(),
              const SizedBox(height: 20),
              _buildReviewsSection(),
              const SizedBox(height: 20),
              _buildRelatedSection(),
              const SizedBox(height: 40),
            ]),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: _kSurface,
      foregroundColor: _kText,
      elevation: 0,
      scrolledUnderElevation: 1,
      expandedHeight: 340,
      pinned: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.share_rounded),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: const Color(0xFFEEEEEE),
          child: const Center(
            child: Icon(Icons.image_rounded, size: 80, color: _kMuted),
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Blue Leso Fabric — Traditional',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: _kText),
          ),
          const SizedBox(height: 6),
          const Text(
            'TZS 18,500',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: _kText),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEEEEEE),
                ),
                child: const Icon(Icons.person_rounded,
                    size: 16, color: _kMuted),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Amina Designs · 4.2K followers',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: _kMuted),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: _kText),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Follow',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kText),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Beautifully dyed traditional leso fabric — vibrant, '
            'durable, and handcrafted by local artisans in Dar es Salaam. '
            'Perfect for dresses, wraps, and gifts.',
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 13, color: _kMuted, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      child: Row(
        children: [
          _SocialActionButton(
            icon: _liked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            label: '${_likeCount + (_liked ? 1 : 0)}',
            active: _liked,
            onTap: () => setState(() {
              _liked = !_liked;
            }),
          ),
          _SocialActionButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: '34',
            active: false,
            onTap: () {},
          ),
          _SocialActionButton(
            icon: Icons.share_rounded,
            label: 'Share',
            active: false,
            onTap: () {},
          ),
          const Spacer(),
          _SocialActionButton(
            icon: _saved
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            label: '',
            active: _saved,
            onTap: () => setState(() {
              _saved = !_saved;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: _kText,
                side: const BorderSide(color: _kText),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(0, 48),
              ),
              child: const Text(
                'Add to Cart',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: _kText,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(0, 48),
                elevation: 0,
              ),
              child: const Text(
                'Buy Now',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              const Text(
                'Reviews',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kText),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kDivider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 13, color: Color(0xFFFFC107)),
                    const SizedBox(width: 3),
                    const Text(
                      '4.5',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _kText),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                    foregroundColor: _kText,
                    padding: EdgeInsets.zero),
                child: const Text(
                  'See all',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        ..._reviews.map((r) => _ReviewCard(review: r)),
      ],
    );
  }

  Widget _buildRelatedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            'Related Products',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: _kText),
          ),
        ),
        SizedBox(
          height: 170,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _related.length,
            separatorBuilder: (_, i) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) =>
                _RelatedProductCard(product: _related[i]),
          ),
        ),
      ],
    );
  }
}

class _SocialActionButton extends StatelessWidget {
  const _SocialActionButton(
      {required this.icon,
      required this.label,
      required this.active,
      required this.onTap});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 22,
                color: active ? _kText : _kFaint),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                    fontSize: 13,
                    color: active ? _kText : _kFaint,
                    fontWeight: active
                        ? FontWeight.w600
                        : FontWeight.normal),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final _Review review;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
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
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEEEEEE),
                ),
                child: const Icon(Icons.person_rounded,
                    size: 16, color: _kMuted),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  review.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kText),
                ),
              ),
              Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                          i < review.rating.floor()
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 13,
                          color: const Color(0xFFFFC107),
                        )),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 13, color: _kMuted, height: 1.45),
          ),
          const SizedBox(height: 6),
          Text(
            review.date,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: _kFaint),
          ),
        ],
      ),
    );
  }
}

class _RelatedProductCard extends StatelessWidget {
  const _RelatedProductCard({required this.product});
  final _RelatedProduct product;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: SizedBox(
        width: 120,
        child: Container(
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
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEEEEE),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: const Center(
                    child: Icon(Icons.image_rounded,
                        size: 36, color: _kMuted),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _kText,
                          height: 1.3),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.price,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _kText),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
