import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../tajirika/models/partner_product.dart';
import '../../tajirika/services/partner_product_service.dart';
import '../models/customer_order.dart';
import '../services/customer_orders_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kAccent = Color(0xFF4CAF50);

/// Spec §2 — "Tena? / Order again?" rail.
///
/// Fetches the customer's last [limit] completed partner-product orders,
/// de-duplicates by source_ref_id, and renders a horizontal scrollable
/// rail with one-tap navigation back to the product detail page.
class ReorderCarousel extends StatefulWidget {
  final int userId;
  final String? domain;
  final int limit;
  final void Function(PartnerProduct product) onTapProduct;

  const ReorderCarousel({
    super.key,
    required this.userId,
    this.domain,
    this.limit = 5,
    required this.onTapProduct,
  });

  @override
  State<ReorderCarousel> createState() => _ReorderCarouselState();
}

class _ReorderCarouselState extends State<ReorderCarousel> {
  bool _loading = true;
  List<_ReorderItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    // 1. Fetch recent completed partner-product orders.
    final orderRes = await CustomerOrdersService.list(
      userId: widget.userId,
      role: 'customer',
      status: 'completed',
      limit: 20,
    );

    if (!mounted) return;

    if (!orderRes.success || orderRes.items.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    // Filter to partner_product source only; de-duplicate by sourceRefId.
    final seen = <int>{};
    final orders = <CustomerOrder>[];
    for (final o in orderRes.items) {
      if (o.source != CustomerOrderSource.partnerProduct) continue;
      if (widget.domain != null && o.skillCategoryRaw != null) {
        // Rough domain filter — skip if skill doesn't map to requested domain.
        // This is best-effort client-side; the backend order doesn't store domain.
        final skill = o.skillCategoryRaw!;
        final domainMatch = _skillToDomain(skill);
        if (domainMatch != widget.domain) continue;
      }
      if (seen.add(o.sourceRefId)) {
        orders.add(o);
      }
      if (orders.length >= widget.limit) break;
    }

    if (orders.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    // 2. Fetch current product details for each unique sourceRefId.
    final items = <_ReorderItem>[];
    for (final o in orders) {
      final pRes = await PartnerProductService.getProduct(o.sourceRefId);
      if (pRes.success && pRes.product != null) {
        items.add(_ReorderItem(
          order: o,
          product: pRes.product!,
        ));
      }
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = items;
    });
  }

  static String? _skillToDomain(String skill) {
    const map = {
      'cooking': 'food',
      'catering': 'food',
      'baking': 'food',
      'carpentry': 'mafundi',
      'plumbing': 'mafundi',
      'electrical': 'mafundi',
      'welding': 'mafundi',
      'masonry': 'mafundi',
      'roofing': 'mafundi',
      'tiling': 'mafundi',
      'painting': 'mafundi',
      'solarInstallation': 'mafundi',
      'autoMechanic': 'auto',
      'autoElectrician': 'auto',
      'panelBeating': 'auto',
      'sprayPainting': 'auto',
      'hairstyling': 'hair_nails',
      'barbering': 'hair_nails',
      'nailTechnician': 'hair_nails',
      'skincare': 'skincare',
      'makeup': 'skincare',
      'personalTraining': 'fitness',
      'nutrition': 'fitness',
      'eventPlanning': 'events',
      'photography': 'events',
      'videography': 'events',
      'djing': 'events',
      'mc': 'events',
      'medical': 'doctor',
      'nursing': 'doctor',
      'pharmacy': 'doctor',
      'legal': 'legal',
      'accounting': 'business',
      'taxAdvisory': 'business',
      'businessConsulting': 'business',
      'hrConsulting': 'business',
      'careerCoaching': 'business',
      'realEstate': 'housing',
      'propertyManagement': 'housing',
      'homeInspection': 'housing',
      'interiorDesign': 'housing',
      'tourGuide': 'travel',
      'travelAgent': 'travel',
      'safariOperator': 'travel',
    };
    return map[skill];
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
          ),
        ),
      );
    }

    if (_items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            isSw ? 'Tena?' : 'Order again?',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _ReorderCard(
              item: _items[i],
              isSwahili: isSw,
              onTap: () => widget.onTapProduct(_items[i].product),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReorderItem {
  final CustomerOrder order;
  final PartnerProduct product;
  const _ReorderItem({required this.order, required this.product});
}

class _ReorderCard extends StatelessWidget {
  final _ReorderItem item;
  final bool isSwahili;
  final VoidCallback onTap;

  const _ReorderCard({
    required this.item,
    required this.isSwahili,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = item.product.heroPhotoUrl;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _kCardBg,
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: photoUrl.isNotEmpty
                  ? Image.network(
                      photoUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, __) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.product.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.product.partnerName ?? '',
                    style: const TextStyle(fontSize: 10, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kAccent.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          _fmtTzs(item.product.basePriceTzs),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _kAccent,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        isSwahili ? 'Agiza tena' : 'Reorder',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded, size: 12, color: _kPrimary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 56,
      color: _kBorder,
      child: const Icon(Icons.image_rounded, size: 20, color: _kSecondary),
    );
  }
}

String _fmtTzs(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return 'TSh ${buf.toString()}';
}
