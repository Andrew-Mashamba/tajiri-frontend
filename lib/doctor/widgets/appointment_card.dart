// lib/doctor/widgets/appointment_card.dart
import 'package:flutter/material.dart';
import '../models/doctor_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final VoidCallback? onCancel;

  const AppointmentCard({
    super.key,
    required this.appointment,
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
    final doc = appointment.doctor;
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
              // Header: doctor name + status
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: appointment.status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(appointment.typeIcon, size: 20, color: appointment.status.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc != null ? 'Dk. ${doc.fullName}' : 'Daktari #${appointment.doctorId}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (doc != null)
                          Text(
                            doc.specialty.displayName,
                            style: const TextStyle(fontSize: 12, color: _kSecondary),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: appointment.status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      appointment.status.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: appointment.status.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date, time, type row
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 14, color: _kSecondary),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(appointment.scheduledAt),
                    style: const TextStyle(fontSize: 13, color: _kPrimary, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 14),
                  Icon(Icons.access_time_rounded, size: 14, color: _kSecondary),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(appointment.scheduledAt),
                    style: const TextStyle(fontSize: 13, color: _kPrimary, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 14),
                  Icon(appointment.typeIcon, size: 14, color: _kSecondary),
                  const SizedBox(width: 4),
                  Text(
                    appointment.typeLabel,
                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                  ),
                ],
              ),

              if (appointment.reason != null && appointment.reason!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  appointment.reason!,
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Action buttons
              if (appointment.canJoin || appointment.isUpcoming) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (appointment.canJoin && onJoin != null)
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: FilledButton.icon(
                            onPressed: onJoin,
                            icon: Icon(appointment.typeIcon, size: 16),
                            label: const Text('Ingia'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ),
                    if (appointment.canJoin && appointment.isUpcoming && onCancel != null)
                      const SizedBox(width: 10),
                    if (appointment.isUpcoming && onCancel != null)
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
