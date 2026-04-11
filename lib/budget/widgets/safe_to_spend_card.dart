import 'package:flutter/material.dart';

/// Color-coded card showing safe-to-spend amount.
/// Green if healthy (>30%), amber if getting low (10-30%), red if danger (<10%).
///
/// When safe-to-spend equals wallet balance (nothing allocated), shows an
/// "Allocate" prompt instead of the status badge.
class SafeToSpendCard extends StatelessWidget {
  final double amount;
  final double walletBalance;
  final bool isSwahili;
  final VoidCallback? onAllocate;

  const SafeToSpendCard({
    super.key,
    required this.amount,
    required this.walletBalance,
    this.isSwahili = false,
    this.onAllocate,
  });

  static const Color _kSuccess = Color(0xFF4CAF50);
  static const Color _kWarning = Color(0xFFFF9800);
  static const Color _kError = Color(0xFFE53935);
  static const Color _kPrimary = Color(0xFF1A1A1A);

  String _formatTZS(double value) {
    if (value >= 1000000) {
      return 'TZS ${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return 'TZS ${(value / 1000).toStringAsFixed(0)}K';
    }
    return 'TZS ${value.toStringAsFixed(0)}';
  }

  double get _ratio => walletBalance > 0 ? amount / walletBalance : 0;

  /// True when nothing has been allocated yet (safe-to-spend == wallet balance).
  bool get _nothingAllocated =>
      walletBalance > 0 && (amount - walletBalance).abs() < 0.01;

  Color get _statusColor {
    if (_nothingAllocated) return _kWarning;
    if (_ratio > 0.3) return _kSuccess;
    if (_ratio > 0.1) return _kWarning;
    return _kError;
  }

  String get _statusLabel {
    if (_nothingAllocated) {
      return isSwahili ? 'Hajatengwa' : 'Unallocated';
    }
    if (_ratio > 0.3) {
      return isSwahili ? 'Hali nzuri' : 'Healthy';
    }
    if (_ratio > 0.1) {
      return isSwahili ? 'Punguza matumizi' : 'Getting low';
    }
    return isSwahili ? 'Hatari' : 'Danger';
  }

  IconData get _statusIcon {
    if (_nothingAllocated) return Icons.info_outline_rounded;
    if (_ratio > 0.3) return Icons.check_circle_rounded;
    if (_ratio > 0.1) return Icons.warning_rounded;
    return Icons.error_rounded;
  }

  String get _subtitle {
    if (_nothingAllocated) {
      return isSwahili ? 'Tenga pesa zako' : 'Allocate your funds';
    }
    return isSwahili ? 'Unaweza kutumia' : 'Safe to spend';
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;

    return Card(
      color: color.withValues(alpha: 0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(_statusIcon, color: color, size: 36),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTZS(amount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (_nothingAllocated && onAllocate != null)
              TextButton(
                onPressed: onAllocate,
                style: TextButton.styleFrom(
                  foregroundColor: _kPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  isSwahili ? 'Tenga' : 'Allocate',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
