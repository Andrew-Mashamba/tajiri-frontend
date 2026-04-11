// lib/lawyer/widgets/consultation_card.dart
import 'package:flutter/material.dart';
import '../models/lawyer_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class ConsultationCard extends StatelessWidget {
  final LegalConsultation consultation;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final VoidCallback? onCancel;

  const ConsultationCard({
    super.key,
    required this.consultation,
    this.onTap,
    this.onJoin,
    this.onCancel,
  });

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final law = consultation.lawyer;
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: lawyer name + status
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: consultation.status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(consultation.typeIcon, size: 20, color: consultation.status.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          law != null ? 'Wkl. ${law.fullName}' : 'Wakili #${consultation.lawyerId}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (law != null)
                          Text(
                            law.specialty.displayName,
                            style: const TextStyle(fontSize: 12, color: _kSecondary),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: consultation.status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      consultation.status.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: consultation.status.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date, time, type row
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: _kSecondary),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(consultation.scheduledAt),
                    style: const TextStyle(fontSize: 13, color: _kPrimary, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 14),
                  const Icon(Icons.access_time_rounded, size: 14, color: _kSecondary),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(consultation.scheduledAt),
                    style: const TextStyle(fontSize: 13, color: _kPrimary, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 14),
                  Icon(consultation.typeIcon, size: 14, color: _kSecondary),
                  const SizedBox(width: 4),
                  Text(
                    consultation.typeLabel,
                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                  ),
                ],
              ),

              if (consultation.issue != null && consultation.issue!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  consultation.issue!,
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Action buttons
              if (consultation.canJoin || consultation.isUpcoming) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (consultation.canJoin && onJoin != null)
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: FilledButton.icon(
                            onPressed: onJoin,
                            icon: Icon(consultation.typeIcon, size: 16),
                            label: const Text('Ingia'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ),
                    if (consultation.canJoin && consultation.isUpcoming && onCancel != null)
                      const SizedBox(width: 10),
                    if (consultation.isUpcoming && onCancel != null)
                      SizedBox(
                        height: 40,
                        child: OutlinedButton(
                          onPressed: onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Ghairi'),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
