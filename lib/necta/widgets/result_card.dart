// lib/necta/widgets/result_card.dart
import 'package:flutter/material.dart';
import '../models/necta_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class ResultCard extends StatelessWidget {
  final ExamResult result;
  final bool isSwahili;

  const ResultCard({
    super.key,
    required this.result,
    required this.isSwahili,
  });

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.teal;
      case 'D':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(result.candidateName,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              if (result.division != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Div ${result.division}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${result.candidateNumber}  |  ${result.examType.toUpperCase()} ${result.year}',
            style: const TextStyle(fontSize: 12, color: _kSecondary),
          ),
          if (result.schoolName != null) ...[
            const SizedBox(height: 2),
            Text(result.schoolName!,
                style: const TextStyle(fontSize: 12, color: _kSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
          if (result.subjects.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...result.subjects.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(s.subject,
                            style: const TextStyle(
                                fontSize: 13, color: _kPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        width: 28,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _gradeColor(s.grade).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s.grade,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _gradeColor(s.grade)),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
