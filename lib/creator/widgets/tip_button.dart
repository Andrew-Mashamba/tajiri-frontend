import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_strings_scope.dart';

/// Compact "Buy me a chai" tipping button for posts (Lever 1).
///
/// Place on PostCard, profile header, or live stream overlay.
/// Tapping opens a bottom sheet with preset tip amounts.
class TipButton extends StatelessWidget {
  final int creatorId;
  final String? creatorName;
  final VoidCallback? onTap;
  final bool compact;

  const TipButton({
    super.key,
    required this.creatorId,
    this.creatorName,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);

    if (compact) {
      return InkWell(
        onTap: () => _openTipSheet(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite_rounded, size: 14, color: Color(0xFF4CAF50)),
              const SizedBox(width: 4),
              Text(
                s?.tip ?? 'Tip',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: () => _openTipSheet(context),
        icon: const Icon(Icons.favorite_rounded, size: 16, color: Color(0xFF4CAF50)),
        label: Text(
          s?.sendTip ?? 'Send tip',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1A1A1A),
          side: const BorderSide(color: Color(0xFFE0E0E0)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }

  void _openTipSheet(BuildContext context) {
    HapticFeedback.selectionClick();
    if (onTap != null) {
      onTap!();
      return;
    }
    _showTipBottomSheet(context);
  }

  void _showTipBottomSheet(BuildContext context) {
    final s = AppStringsScope.of(context);
    final name = creatorName ?? (s?.thisCreator ?? 'this creator');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TipAmountSheet(
        creatorId: creatorId,
        creatorName: name,
        s: s,
      ),
    );
  }
}

// ── Bottom Sheet ────────────────────────────────────────────────────────────

class _TipAmountSheet extends StatefulWidget {
  final int creatorId;
  final String creatorName;
  final AppStrings? s;

  const _TipAmountSheet({
    required this.creatorId,
    required this.creatorName,
    required this.s,
  });

  @override
  State<_TipAmountSheet> createState() => _TipAmountSheetState();
}

class _TipAmountSheetState extends State<_TipAmountSheet> {
  static const List<double> _amounts = [500, 1000, 2000, 5000, 10000];
  double? _selected;

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              (s?.isSwahili == true) ? 'Tuma Bahshishi' : 'Send a Tip',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              (s?.isSwahili == true)
                  ? 'Msaada mwandishi ${widget.creatorName} kununua chai'
                  : 'Support ${widget.creatorName} with a chai',
              style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _amounts.map((a) => _buildAmountChip(a)).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _selected != null ? _confirm : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  (s?.isSwahili == true) ? 'Thibitisha' : 'Confirm',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountChip(double amount) {
    final selected = _selected == amount;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selected = amount);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? const Color(0xFF1A1A1A) : const Color(0xFFE0E0E0)),
          boxShadow: [
            if (!selected)
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Text(
          'TSh ${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF1A1A1A),
          ),
        ),
      ),
    );
  }

  void _confirm() {
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
    // Navigate to full SendTipScreen with pre-selected amount
    Navigator.pushNamed(
      context,
      '/send-tip',
      arguments: {
        'creatorId': widget.creatorId,
        'creatorName': widget.creatorName,
        'amount': _selected,
      },
    );
  }
}
