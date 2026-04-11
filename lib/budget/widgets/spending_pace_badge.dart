import 'package:flutter/material.dart';

/// Small chip showing spending pace status.
/// "On Track" (grey), "Caution" (amber), "Over Budget" (red).
class SpendingPaceBadge extends StatelessWidget {
  final String status;
  final bool isSwahili;

  const SpendingPaceBadge({
    super.key,
    required this.status,
    this.isSwahili = false,
  });

  static const Color _kSecondary = Color(0xFF666666);
  static const Color _kWarning = Color(0xFFFF9800);
  static const Color _kError = Color(0xFFE53935);

  Color get _color {
    switch (status) {
      case 'caution':
        return _kWarning;
      case 'over_budget':
        return _kError;
      default:
        return _kSecondary;
    }
  }

  String get _label {
    switch (status) {
      case 'caution':
        return isSwahili ? 'Tahadhari' : 'Caution';
      case 'over_budget':
        return isSwahili ? 'Umezidi' : 'Over Budget';
      default:
        return isSwahili ? 'Vizuri' : 'On Track';
    }
  }

  IconData get _icon {
    switch (status) {
      case 'caution':
        return Icons.trending_up_rounded;
      case 'over_budget':
        return Icons.trending_up_rounded;
      default:
        return Icons.check_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            _label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
