import 'package:flutter/material.dart';

import '../models/tajirika_models.dart';
import '../services/partner_product_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kAccent = Color(0xFF4CAF50);
const Color _kMuted = Color(0xFFBDBDBD);

String _fmtTzs(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return 'TSh ${buf.toString()}';
}

/// Horizontal 12-card rail of active partner_products filtered by domain
/// (food / mafundi / events / skincare / hair_nails / fitness / housing).
/// Each vertical home page mounts its own instance with the cluster-specific
/// title + domain. Tap routes to a per-vertical detail page via [onTapProduct].
class PartnerProductRail extends StatefulWidget {
  final String titleSwahili;
  final String domain;
  final void Function(PartnerProduct product) onTapProduct;
  final int limit;

  const PartnerProductRail({
    super.key,
    required this.titleSwahili,
    required this.domain,
    required this.onTapProduct,
    this.limit = 12,
  });

  @override
  State<PartnerProductRail> createState() => _PartnerProductRailState();
}

class _PartnerProductRailState extends State<PartnerProductRail> {
  bool _loading = true;
  String? _error;
  List<PartnerProduct> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await PartnerProductService.listProducts(
      domain: widget.domain,
      activeOnly: true,
      limit: widget.limit,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success) {
        _items = res.products;
      } else {
        _error = res.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
          ),
        ),
      );
    }
    if (_error != null && _items.isEmpty) return const SizedBox.shrink();
    if (_items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            widget.titleSwahili,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _RailCard(
              product: _items[i],
              onTap: () => widget.onTapProduct(_items[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _RailCard extends StatelessWidget {
  final PartnerProduct product;
  final VoidCallback onTap;

  const _RailCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lead = product.leadTimeHours;
    final leadLabel = lead < 24 ? 'Saa $lead' : 'Siku ${(lead / 24).round()}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: _kCardBg,
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                child: _buildPhoto(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.partnerName ?? '',
                    style: const TextStyle(fontSize: 10, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kAccent.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          _fmtTzs(product.basePriceTzs),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _kAccent,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kBorder,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          leadLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _kSecondary,
                          ),
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
    );
  }

  Widget _buildPhoto() {
    final url = product.heroPhotoUrl;
    if (url == null || url.isEmpty) {
      return Container(
        color: _kBorder,
        child: const Icon(Icons.image_rounded, size: 30, color: _kMuted),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: _kBorder,
        child: const Icon(Icons.broken_image_rounded,
            size: 24, color: _kMuted),
      ),
    );
  }
}
