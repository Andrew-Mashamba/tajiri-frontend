// lib/widgets/stream_product_overlay.dart
//
// Phase D — Lever 12: live commerce overlay shown on top of the live
// video. Streamer pins products from the broadcaster's "Streamer tools"
// sheet (Phase B) and viewers see the overlay here.
//
// Tapping the overlay fires `live_product_expand·author`; "Add to
// wishlist" fires `live_wishlist_add·author`; "Buy now" pushes through
// the existing order flow with `origin_stream_id`.
//
// Mirrors TikTok LIVE Shopping overlay UX (small pill bottom-right that
// expands to a bottom sheet on tap).

import 'package:flutter/material.dart';

import '../services/livestream_service.dart';

/// Pinned product as returned by the streamer-side pin endpoint /
/// broadcast over WebSocket. Lightweight POJO — keep aligned with
/// `stream_products` table columns.
class PinnedStreamProduct {
  final int id; // stream_products.id
  final int streamId;
  final int? productId;
  final String? externalUrl;
  final String? label;
  final String? imageUrl;
  final num? priceTsh;

  const PinnedStreamProduct({
    required this.id,
    required this.streamId,
    this.productId,
    this.externalUrl,
    this.label,
    this.imageUrl,
    this.priceTsh,
  });

  factory PinnedStreamProduct.fromJson(Map<String, dynamic> j) =>
      PinnedStreamProduct(
        id: (j['id'] as num).toInt(),
        streamId: (j['stream_id'] as num).toInt(),
        productId: j['product_id'] is num ? (j['product_id'] as num).toInt() : null,
        externalUrl: j['external_url'] as String?,
        label: j['label'] as String?,
        imageUrl: j['image_url'] as String?,
        priceTsh: j['price_tsh'] is num ? j['price_tsh'] as num : null,
      );
}

/// Compact pill overlay anchored bottom-right of the video. Tap →
/// detail sheet.
class StreamProductOverlay extends StatelessWidget {
  final PinnedStreamProduct product;
  final int viewerUserId;
  final VoidCallback? onPurchaseTap;

  const StreamProductOverlay({
    super.key,
    required this.product,
    required this.viewerUserId,
    this.onPurchaseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetailSheet(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          constraints: const BoxConstraints(maxWidth: 220, minHeight: 48),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shopping_bag_rounded,
                  color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  product.label ?? 'Featured product',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetailSheet(BuildContext context) {
    // streams.md §IX row 55 — live_product_expand·author.
    LiveStreamService().expandStreamProduct(
      streamId: product.streamId,
      streamProductId: product.id,
      userId: viewerUserId,
    );

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              if (product.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    product.imageUrl!, height: 180, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180, color: Colors.white10,
                      child: const Icon(Icons.image_rounded, color: Colors.white24),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                product.label ?? 'Product',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              if (product.priceTsh != null) ...[
                const SizedBox(height: 6),
                Text('TSh ${product.priceTsh!.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.bookmark_add_outlined, color: Colors.white),
                    label: const Text('Wishlist',
                        style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      // §IX row 56 — live_wishlist_add·author.
                      await LiveStreamService().wishlistStreamProduct(
                        streamId: product.streamId,
                        streamProductId: product.id,
                        userId: viewerUserId,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to wishlist')),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_cart_rounded),
                    label: const Text('Buy now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      // §IX row 57 — live_purchase·author. Order flow consumes
                      // origin_stream_id via OrderController to fire the
                      // earnings event after payment confirmation.
                      onPurchaseTap?.call();
                    },
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
