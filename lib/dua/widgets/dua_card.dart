// lib/dua/widgets/dua_card.dart
import 'package:flutter/material.dart';
import '../models/dua_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class DuaCard extends StatelessWidget {
  final Dua dua;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;

  const DuaCard({super.key, required this.dua, this.onTap, this.onFavorite});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dua.titleSwahili.isNotEmpty
                        ? dua.titleSwahili
                        : dua.titleEnglish,
                    style: const TextStyle(
                      color: _kPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onFavorite != null)
                  IconButton(
                    icon: Icon(
                      dua.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 18,
                    ),
                    color: dua.isFavorite ? Colors.red : _kSecondary,
                    onPressed: onFavorite,
                    constraints: const BoxConstraints(
                        minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              dua.textArabic,
              style: const TextStyle(color: _kPrimary, fontSize: 16, height: 1.6),
              textDirection: TextDirection.rtl,
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              dua.translationSwahili,
              style: const TextStyle(color: _kSecondary, fontSize: 13, height: 1.4),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(dua.source,
                style: const TextStyle(color: _kSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
