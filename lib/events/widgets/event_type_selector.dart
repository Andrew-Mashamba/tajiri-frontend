import 'package:flutter/material.dart';
import '../models/event_template.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class EventTypeSelector extends StatelessWidget {
  final EventTemplateType? selected;
  final ValueChanged<EventTemplateType> onSelected;
  const EventTypeSelector({super.key, this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: EventTemplateType.values.map((type) {
        final isSelected = type == selected;
        return GestureDetector(
          onTap: () => onSelected(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? _kPrimary : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? _kPrimary : Colors.grey.shade200, width: isSelected ? 2 : 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(type.icon, size: 28, color: isSelected ? Colors.white : _kPrimary),
                const SizedBox(height: 8),
                Text(type.displayName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : _kPrimary), textAlign: TextAlign.center),
                const SizedBox(height: 2),
                Text(type.subtitle, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : _kSecondary), textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
