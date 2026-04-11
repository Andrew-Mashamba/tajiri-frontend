// lib/games/widgets/stake_selector.dart
import 'package:flutter/material.dart';
import '../core/game_enums.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

/// Horizontal scrolling stake tier selector.
/// Greys out tiers the user cannot afford.
class StakeSelector extends StatefulWidget {
  final StakeTier selectedTier;
  final double walletBalance;
  final StakeTier maxTier;
  final ValueChanged<StakeTier> onTierChanged;
  final ValueChanged<double>? onCustomAmountChanged;

  const StakeSelector({
    super.key,
    required this.selectedTier,
    required this.walletBalance,
    this.maxTier = StakeTier.diamond,
    required this.onTierChanged,
    this.onCustomAmountChanged,
  });

  @override
  State<StakeSelector> createState() => _StakeSelectorState();
}

class _StakeSelectorState extends State<StakeSelector> {
  final TextEditingController _customCtrl = TextEditingController();

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  bool _canAfford(StakeTier tier) {
    if (tier == StakeTier.free) return true;
    if (tier == StakeTier.custom) return true;
    return widget.walletBalance >= tier.amount;
  }

  bool _isAllowed(StakeTier tier) {
    return tier.index <= widget.maxTier.index;
  }

  @override
  Widget build(BuildContext context) {
    final tiers = StakeTier.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tier chips
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tiers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final tier = tiers[i];
              final selected = tier == widget.selectedTier;
              final affordable = _canAfford(tier);
              final allowed = _isAllowed(tier);
              final enabled = affordable && allowed;

              String label;
              if (tier == StakeTier.free) {
                label = 'Free';
              } else if (tier == StakeTier.custom) {
                label = 'Custom';
              } else {
                label = '${tier.displayName} ${tier.formattedAmount}';
              }

              return GestureDetector(
                onTap: enabled
                    ? () => widget.onTierChanged(tier)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? _kPrimary
                        : enabled
                            ? Colors.white
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? _kPrimary
                          : enabled
                              ? Colors.grey.shade300
                              : Colors.grey.shade200,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected
                            ? Colors.white
                            : enabled
                                ? _kPrimary
                                : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // Wallet balance
        Text(
          'Wallet: TZS ${widget.walletBalance.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 12, color: _kSecondary),
        ),

        // Custom amount input
        if (widget.selectedTier == StakeTier.custom) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _customCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter amount (TZS)',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixText: 'TZS ',
              prefixStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kPrimary),
              ),
            ),
            onChanged: (val) {
              final amount = double.tryParse(val) ?? 0;
              widget.onCustomAmountChanged?.call(amount);
            },
          ),
        ],
      ],
    );
  }
}
