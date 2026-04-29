import 'package:flutter/material.dart';

import '../models/tajirika_models.dart';
import 'jss_badge.dart';

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

class PartnerProductCard extends StatelessWidget {
  final PartnerProduct product;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleActive;
  final VoidCallback? onDelete;
  /// Spec line 305 — partner-only inline stock toggle.
  final VoidCallback? onToggleStock;
  final bool showOwnerActions;

  const PartnerProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onEdit,
    this.onToggleActive,
    this.onDelete,
    this.onToggleStock,
    this.showOwnerActions = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPhoto(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.title,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _kPrimary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!product.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _kMuted.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Imezimwa',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _kSecondary),
                          ),
                        )
                      else if (!product.isInStock)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Imekwisha',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFB71C1C)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        product.skillCategory?.icon ?? Icons.work_rounded,
                        size: 12,
                        color: _kSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.skillCategory?.labelSwahili ??
                              product.skillCategoryRaw,
                          style: const TextStyle(
                              fontSize: 11, color: _kSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _kindChip(),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        _fmtTzs(product.basePriceTzs),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _kAccent),
                      ),
                      if (product.partnerJobSuccessScore != null) ...[
                        const SizedBox(width: 8),
                        JssBadge(
                          score: product.partnerJobSuccessScore,
                          compact: true,
                        ),
                      ],
                    ],
                  ),
                  if (product.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: const TextStyle(
                          fontSize: 12, color: _kSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (showOwnerActions) ...[
                    const SizedBox(height: 8),
                    _ownerActionsRow(),
                  ],
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
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        child: url == null || url.isEmpty
            ? Container(
                color: _kBorder,
                child: const Icon(Icons.image_rounded,
                    size: 36, color: _kMuted),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: _kBorder,
                  child: const Icon(Icons.broken_image_rounded,
                      size: 32, color: _kMuted),
                ),
              ),
      ),
    );
  }

  Widget _kindChip() {
    Color bg;
    String label;
    switch (product.kind) {
      case PartnerProductKind.amc:
        bg = const Color(0xFFFFF8E1);
        label = 'AMC';
        break;
      case PartnerProductKind.productized:
        bg = const Color(0xFFE3F2FD);
        label = 'SKU';
        break;
      case PartnerProductKind.standard:
        return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: _kPrimary)),
    );
  }

  Widget _ownerActionsRow() {
    return Row(
      children: [
        if (onEdit != null) _smallAction(Icons.edit_rounded, 'Hariri', onEdit!),
        if (onToggleStock != null) ...[
          const SizedBox(width: 8),
          _smallAction(
            product.isInStock
                ? Icons.inventory_2_rounded
                : Icons.inventory_2_outlined,
            product.isInStock ? 'Imekwisha' : 'Iko',
            onToggleStock!,
            color: product.isInStock ? _kPrimary : const Color(0xFF1B5E20),
          ),
        ],
        if (onToggleActive != null) ...[
          const SizedBox(width: 8),
          _smallAction(
            product.isActive ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            product.isActive ? 'Zima' : 'Washa',
            onToggleActive!,
          ),
        ],
        const Spacer(),
        if (onDelete != null)
          _smallAction(Icons.delete_outline_rounded, 'Futa', onDelete!,
              color: const Color(0xFFE53935)),
      ],
    );
  }

  Widget _smallAction(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    final c = color ?? _kPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: c)),
          ],
        ),
      ),
    );
  }
}
