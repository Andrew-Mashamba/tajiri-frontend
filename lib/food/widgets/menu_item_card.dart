// lib/food/widgets/menu_item_card.dart
import 'package:flutter/material.dart';
import '../../widgets/cached_media_image.dart';
import '../models/food_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class MenuItemCard extends StatelessWidget {
  final MenuItem menuItem;
  final VoidCallback? onAdd;

  const MenuItemCard({super.key, required this.menuItem, this.onAdd});

  String _fmtPrice(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Image
            if (menuItem.imageUrl != null) ...[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _kPrimary.withValues(alpha: 0.08),
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedMediaImage(
                  imageUrl: menuItem.imageUrl!,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
            ],
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          menuItem.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (menuItem.isPopular)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Maarufu',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.orange),
                          ),
                        ),
                    ],
                  ),
                  if (menuItem.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      menuItem.description!,
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'TZS ${_fmtPrice(menuItem.price)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (menuItem.isAvailable && onAdd != null)
                        Material(
                          color: _kPrimary,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: onAdd,
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Text(
                                'Ongeza',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                            ),
                          ),
                        )
                      else if (!menuItem.isAvailable)
                        Text(
                          'Haipatikani',
                          style: TextStyle(fontSize: 12, color: Colors.red.shade400),
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
}
