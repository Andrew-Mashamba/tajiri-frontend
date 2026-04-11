// lib/my_baby/widgets/vaccination_card.dart
import 'package:flutter/material.dart';
import '../models/my_baby_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class VaccinationCard extends StatelessWidget {
  final Vaccination vaccination;
  final bool isSwahili;
  final VoidCallback? onMarkDone;
  final DateTime? babyDob;

  const VaccinationCard({
    super.key,
    required this.vaccination,
    this.isSwahili = true,
    this.onMarkDone,
    this.babyDob,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = babyDob != null
        ? vaccination.isOverdueWithDob(babyDob)
        : vaccination.isOverdue;
    final isDone = vaccination.isDone;
    // Fix 10: Use effective due date (client-side fallback)
    final effectiveDueDate = vaccination.effectiveDueDate(babyDob);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue
              ? Colors.red.shade300
              : isDone
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                  : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                  : isOverdue
                      ? Colors.red.shade50
                      : _kPrimary.withValues(alpha: 0.06),
            ),
            child: Icon(
              isDone
                  ? Icons.check_circle_rounded
                  : isOverdue
                      ? Icons.warning_rounded
                      : Icons.vaccines_rounded,
              size: 20,
              color: isDone
                  ? const Color(0xFF4CAF50)
                  : isOverdue
                      ? Colors.red
                      : _kSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSwahili
                      ? (vaccination.swahiliName.isNotEmpty
                          ? vaccination.swahiliName
                          : vaccination.name)
                      : vaccination.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if (!isSwahili && vaccination.swahiliName.isNotEmpty)
                  Text(
                    vaccination.swahiliName,
                    style: const TextStyle(fontSize: 11, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    vaccination.name,
                    style: const TextStyle(fontSize: 11, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        vaccination.ageLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _kSecondary,
                        ),
                      ),
                    ),
                    if (effectiveDueDate != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(effectiveDueDate),
                        style: TextStyle(
                          fontSize: 10,
                          color: isOverdue ? Colors.red : _kSecondary,
                          fontWeight:
                              isOverdue ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                    if (isDone && vaccination.givenDate != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        isSwahili
                            ? 'Imetolewa: ${_formatDate(vaccination.givenDate!)}'
                            : 'Given: ${_formatDate(vaccination.givenDate!)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (!isDone && onMarkDone != null)
            SizedBox(
              height: 32,
              child: TextButton(
                onPressed: onMarkDone,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  foregroundColor: _kPrimary,
                ),
                child: Text(
                  isSwahili ? 'Kamilisha' : 'Complete',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (isOverdue && !isDone)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isSwahili ? 'Imechelewa' : 'Overdue',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = isSwahili
        ? ['Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun', 'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des']
        : ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
