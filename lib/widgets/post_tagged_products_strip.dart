// lib/widgets/post_tagged_products_strip.dart
//
// UN-012 — strategy posts.md row 77 (product_expand·author). Renders a
// horizontal strip of tagged product chips below the caption. Tapping a
// chip navigates to ProductDetailScreen with origin_post_id so the
// post creator earns when the buyer expands the product.
//
// Lazily fetches; renders nothing if the post has no tagged products.

import 'package:flutter/material.dart';

import '../l10n/app_strings_scope.dart';
import '../services/post_tagged_product_service.dart';

class PostTaggedProductsStrip extends StatefulWidget {
  final int postId;
  final int currentUserId;

  const PostTaggedProductsStrip({
    super.key,
    required this.postId,
    required this.currentUserId,
  });

  @override
  State<PostTaggedProductsStrip> createState() =>
      _PostTaggedProductsStripState();
}

class _PostTaggedProductsStripState extends State<PostTaggedProductsStrip> {
  static const _kPrimary = Color(0xFF1A1A1A);
  static const _kSecondary = Color(0xFF666666);
  static const _kBorder = Color(0xFFE5E5E5);
  static const _kIconBg = Color(0xFFF5F5F5);

  final PostTaggedProductService _service = PostTaggedProductService();
  List<PostTaggedProduct> _items = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    final list = await _service.list(widget.postId);
    if (!mounted) return;
    setState(() {
      _items = list;
      _loaded = true;
    });
  }

  void _openProduct(PostTaggedProduct tag) {
    // ProductDetailScreen reads `origin_post_id` from route arguments and
    // forwards it to ShopService.recordProductView (UN-012 fires
    // product_expand·author). The wishlist favourite UI on the same screen
    // forwards it too (UN-013).
    Navigator.pushNamed(
      context,
      '/shop/product/${tag.productId}',
      arguments: {'origin_post_id': widget.postId},
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _items.isEmpty) return const SizedBox.shrink();
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_bag_rounded, size: 14, color: _kSecondary),
              const SizedBox(width: 4),
              Text(
                isSw ? 'Bidhaa' : 'Tagged products',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final tag = _items[i];
                return InkWell(
                  onTap: () => _openProduct(tag),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 36),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: _kIconBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tag_rounded, size: 12, color: _kPrimary),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 140),
                          child: Text(
                            tag.productName ?? 'Product',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary,
                            ),
                          ),
                        ),
                        if (tag.productPrice != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${tag.productPrice!.toStringAsFixed(0)} TZS',
                            style: const TextStyle(
                              fontSize: 11,
                              color: _kSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
