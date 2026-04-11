// lib/hair_nails/widgets/style_card.dart
import 'package:flutter/material.dart';
import '../models/hair_nails_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class StyleCard extends StatelessWidget {
  final StyleInspiration style;
  final VoidCallback? onTap;
  final VoidCallback? onSave;

  const StyleCard({super.key, required this.style, this.onTap, this.onSave});

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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  style.imageUrl != null
                      ? Image.network(style.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
                      : _placeholder(),
                  // Save button
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: onSave,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          style.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(style.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (style.estimatedPrice != null)
                        Text('TZS ${_fmtPrice(style.estimatedPrice!)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kPrimary)),
                      if (style.estimatedPrice != null && style.estimatedDurationMinutes != null)
                        const Text(' \u00b7 ', style: TextStyle(fontSize: 11, color: _kSecondary)),
                      if (style.estimatedDurationMinutes != null)
                        Text(style.durationLabel, style: const TextStyle(fontSize: 11, color: _kSecondary)),
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
      color: _kPrimary.withValues(alpha: 0.06),
      child: const Center(child: Icon(Icons.auto_awesome_rounded, size: 36, color: _kSecondary)),
    );
  }
}
