import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/tajirika_models.dart';

class PortfolioItemCard extends StatelessWidget {
  final PortfolioItem item;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const PortfolioItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: Colors.grey.shade200,
              child: Image.network(
                item.displayThumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.image_rounded, color: Color(0xFF9E9E9E), size: 32),
                ),
              ),
            ),
            if (item.isVideo)
              const Center(
                child: Icon(
                  Icons.play_circle_filled_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            if (item.caption != null && item.caption!.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                  child: Text(
                    item.caption!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            if (item.skillCategory != null)
              Positioned(
                top: 6,
                left: 6,
                child: Builder(
                  builder: (context) {
                    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.skillCategory!.icon, size: 10, color: Colors.white70),
                          const SizedBox(width: 3),
                          Text(
                            isSwahili ? item.skillCategory!.labelSwahili : item.skillCategory!.label,
                            style: const TextStyle(color: Colors.white70, fontSize: 9),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
