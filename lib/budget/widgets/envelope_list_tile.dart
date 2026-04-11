import 'package:flutter/material.dart';
import '../models/budget_models.dart';
import 'spending_pace_badge.dart';

/// Envelope row for the budget list showing name, allocated/spent amounts,
/// progress bar, and spending pace badge.
///
/// When [compact] is true, renders a simplified row without progress bar
/// or pace badge — just icon, name, amounts, and a trailing checkmark.
class EnvelopeListTile extends StatelessWidget {
  final BudgetEnvelope envelope;
  final bool isSwahili;
  final VoidCallback? onTap;
  final bool compact;

  const EnvelopeListTile({
    super.key,
    required this.envelope,
    this.isSwahili = false,
    this.onTap,
    this.compact = false,
  });

  static const Color _kPrimary = Color(0xFF1A1A1A);
  static const Color _kSecondary = Color(0xFF666666);
  static const Color _kSuccess = Color(0xFF4CAF50);
  static const Color _kWarning = Color(0xFFFF9800);
  static const Color _kError = Color(0xFFE53935);

  String _formatTZS(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Color _parseEnvelopeColor() {
    try {
      final hex = envelope.color.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return _kPrimary;
    }
  }

  String get _paceStatus {
    final pct = envelope.percentUsed;
    if (pct > 100) return 'over_budget';
    if (pct > 75) return 'caution';
    return 'on_track';
  }

  Color get _progressColor {
    final pct = envelope.percentUsed;
    if (pct > 100) return _kError;
    if (pct > 75) return _kWarning;
    return _kSuccess;
  }

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact();
    return _buildFull();
  }

  Widget _buildCompact() {
    final envelopeColor = _parseEnvelopeColor();
    final total = envelope.allocatedAmount + envelope.rolledOverAmount;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: SizedBox(
          height: 40,
          child: Row(
            children: [
              // Icon circle (smaller)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: envelopeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _resolveIcon(envelope.icon),
                  color: envelopeColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              // Name
              Expanded(
                child: Text(
                  envelope.displayName(isSwahili),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Amounts: "38K / 50K"
              Text(
                '${_formatTZS(envelope.spentAmount)} / ${_formatTZS(total)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _kSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              // Trailing checkmark
              const Icon(
                Icons.check_rounded,
                color: _kSuccess,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFull() {
    final envelopeColor = _parseEnvelopeColor();
    final total = envelope.allocatedAmount + envelope.rolledOverAmount;
    final progress = total > 0
        ? (envelope.spentAmount / total).clamp(0.0, 1.5)
        : 0.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: envelopeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _resolveIcon(envelope.icon),
                color: envelopeColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Name + amounts + progress
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          envelope.displayName(isSwahili),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _kPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SpendingPaceBadge(
                        status: _paceStatus,
                        isSwahili: isSwahili,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: const Color(0xFFEEEEEE),
                      valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${isSwahili ? "Matumizi" : "Spent"}: ${_formatTZS(envelope.spentAmount)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _kSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${isSwahili ? "Bajeti" : "Budget"}: ${_formatTZS(total)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _kSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: _kSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Resolve a string icon name to an IconData.
  static IconData _resolveIcon(String name) {
    const iconMap = <String, IconData>{
      'restaurant': Icons.restaurant_rounded,
      'directions_bus': Icons.directions_bus_rounded,
      'home': Icons.home_rounded,
      'school': Icons.school_rounded,
      'local_hospital': Icons.local_hospital_rounded,
      'checkroom': Icons.checkroom_rounded,
      'savings': Icons.savings_rounded,
      'shopping_bag': Icons.shopping_bag_rounded,
      'phone_android': Icons.phone_android_rounded,
      'bolt': Icons.bolt_rounded,
      'water_drop': Icons.water_drop_rounded,
      'movie': Icons.movie_rounded,
      'fitness_center': Icons.fitness_center_rounded,
      'pets': Icons.pets_rounded,
      'child_care': Icons.child_care_rounded,
      'church': Icons.church_rounded,
      'volunteer_activism': Icons.volunteer_activism_rounded,
      'flight': Icons.flight_rounded,
      'more_horiz': Icons.more_horiz_rounded,
      'category': Icons.category_rounded,
    };
    return iconMap[name] ?? Icons.category_rounded;
  }
}
