// lib/spare_parts/widgets/part_card.dart
import 'package:flutter/material.dart';
import '../models/spare_parts_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class PartCard extends StatelessWidget {
  final SparePart part_;
  final VoidCallback? onTap;

  const PartCard({super.key, required this.part_, this.onTap});

  Color _conditionColor(PartCondition c) {
    switch (c) {
      case PartCondition.newGenuine: return const Color(0xFF2E7D32);
      case PartCondition.newAftermarket: return const Color(0xFF1565C0);
      case PartCondition.usedA: return const Color(0xFFE65100);
      case PartCondition.usedB: return const Color(0xFFEF6C00);
      case PartCondition.usedC: return const Color(0xFFBF360C);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo with condition badge
            AspectRatio(
              aspectRatio: 1.2,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: part_.photos.isNotEmpty
                        ? Image.network(part_.photos.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder())
                        : _placeholder(),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: _conditionColor(part_.condition),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(part_.condition.label,
                          style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  if (part_.isFlagged)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFC62828),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_rounded, size: 12, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(part_.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (part_.make != null) ...[
                    const SizedBox(height: 2),
                    Text('${part_.make} ${part_.model ?? ''}',
                        style: const TextStyle(fontSize: 11, color: _kSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 4),
                  Text('TZS ${part_.price.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
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
      color: const Color(0xFFE8E8E8),
      child: const Center(child: Icon(Icons.build_rounded, size: 32, color: _kSecondary)),
    );
  }
}
