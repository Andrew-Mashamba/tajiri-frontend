// lib/ibada/widgets/hymn_tile.dart
import 'package:flutter/material.dart';
import '../models/ibada_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class HymnTile extends StatelessWidget {
  final Hymn hymn;
  final VoidCallback? onTap;

  const HymnTile({super.key, required this.hymn, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text('${hymn.number}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hymn.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (hymn.book != null)
                    Text(hymn.book!,
                        style: const TextStyle(fontSize: 11, color: _kSecondary)),
                ],
              ),
            ),
            if (hymn.isFavorite)
              const Icon(Icons.favorite_rounded, size: 16, color: Colors.red),
            if (hymn.audioUrl != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.headphones_rounded, size: 16, color: _kSecondary),
            ],
          ],
        ),
      ),
    );
  }
}
