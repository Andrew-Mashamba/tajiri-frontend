import 'package:flutter/material.dart';
import '../models/battle_models.dart';
import '../l10n/app_strings_scope.dart';

/// Split card showing Side A vs Side B with vote progress bars.
class BattleThreadCard extends StatelessWidget {
  final CreatorBattle battle;
  final VoidCallback? onTap;

  const BattleThreadCard({super.key, required this.battle, this.onTap});

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Topic
                Text(
                  battle.topic,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 12),
                // Side A vs Side B
                Row(
                  children: [
                    Expanded(
                      child: _buildSide(
                        name: battle.creatorAName ?? (strings?.sideA ?? 'Side A'),
                        percent: battle.percentA,
                        isLeft: true,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        strings?.vs ?? 'vs',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF999999)),
                      ),
                    ),
                    Expanded(
                      child: _buildSide(
                        name: battle.creatorBName ?? (strings?.sideB ?? 'Side B'),
                        percent: battle.percentB,
                        isLeft: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Vote bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: battle.percentA.round().clamp(1, 99),
                        child: Container(height: 6, color: const Color(0xFF1A1A1A)),
                      ),
                      Expanded(
                        flex: battle.percentB.round().clamp(1, 99),
                        child: Container(height: 6, color: const Color(0xFFCCCCCC)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Vote count
                Text(
                  '${battle.totalVotes} ${strings?.votes ?? "votes"}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSide({required String name, required double percent, required bool isLeft}) {
    return Column(
      crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isLeft ? const Color(0xFF1A1A1A) : const Color(0xFF666666),
          ),
        ),
        Text(
          '${percent.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isLeft ? const Color(0xFF1A1A1A) : const Color(0xFF666666),
          ),
        ),
      ],
    );
  }
}
