// lib/my_circle/widgets/flow_selector.dart
import 'package:flutter/material.dart';
import '../models/my_circle_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class FlowSelector extends StatelessWidget {
  final FlowIntensity selected;
  final ValueChanged<FlowIntensity> onChanged;
  final bool isSwahili;

  const FlowSelector({super.key, required this.selected, required this.onChanged, this.isSwahili = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isSwahili ? 'Kiwango cha hedhi' : 'Flow intensity', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: FlowIntensity.values.map((flow) {
            final isSelected = selected == flow;
            return GestureDetector(
              onTap: () => onChanged(flow),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? flow.color : flow.color.withValues(alpha: 0.15),
                      border: isSelected
                          ? Border.all(color: _kPrimary, width: 2.5)
                          : null,
                    ),
                    child: Center(
                      child: _buildFlowDots(flow, isSelected),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    flow.displayName(isSwahili),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? _kPrimary : _kSecondary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFlowDots(FlowIntensity flow, bool isSelected) {
    final dotColor = isSelected ? Colors.white : flow.color;
    final dotCount = flow.index; // none=0, spotting=1, light=2, medium=3, heavy=4

    if (dotCount == 0) {
      return Icon(Icons.remove_rounded, size: 20, color: isSelected ? Colors.white : const Color(0xFFBDBDBD));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        dotCount.clamp(1, 4),
        (_) => Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
        ),
      ),
    );
  }
}
