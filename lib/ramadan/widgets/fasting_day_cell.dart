// lib/ramadan/widgets/fasting_day_cell.dart
import 'package:flutter/material.dart';
import '../models/ramadan_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

class FastingDayCell extends StatelessWidget {
  final RamadanDay day;
  final VoidCallback? onTap;

  const FastingDayCell({super.key, required this.day, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: day.isFasted ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: day.isFasted ? _kPrimary : Colors.grey.shade200,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.dayNumber}',
              style: TextStyle(
                color: day.isFasted ? Colors.white : _kPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Icon(
              day.isFasted
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: day.isFasted ? Colors.white70 : Colors.grey.shade300,
              size: 14,
            ),
            const SizedBox(height: 2),
            Text(
              day.suhoorTime,
              style: TextStyle(
                color: day.isFasted ? Colors.white54 : Colors.grey.shade400,
                fontSize: 9,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
