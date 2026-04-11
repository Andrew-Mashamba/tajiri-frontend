import 'package:flutter/material.dart';

/// Warning card shown when unallocated funds exist.
/// Displays the unallocated amount with an "Allocate Now" button.
class UnallocatedCard extends StatelessWidget {
  final double amount;
  final VoidCallback? onAllocate;
  final bool isSwahili;

  const UnallocatedCard({
    super.key,
    required this.amount,
    this.onAllocate,
    this.isSwahili = false,
  });

  static const Color _kWarning = Color(0xFFFF9800);

  String _formatTZS(double value) {
    if (value >= 1000000) {
      return 'TZS ${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return 'TZS ${(value / 1000).toStringAsFixed(0)}K';
    }
    return 'TZS ${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    if (amount <= 0) return const SizedBox.shrink();

    return Card(
      color: _kWarning.withValues(alpha:0.08),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: _kWarning.withValues(alpha:0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: _kWarning,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSwahili
                        ? 'Pesa ambayo haijatengwa'
                        : 'Unallocated funds',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _kWarning.withValues(alpha:0.9),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTZS(amount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _kWarning,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: TextButton(
                onPressed: onAllocate,
                style: TextButton.styleFrom(
                  foregroundColor: _kWarning,
                  backgroundColor: _kWarning.withValues(alpha:0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: Text(
                  isSwahili ? 'Tenga Sasa' : 'Allocate Now',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
