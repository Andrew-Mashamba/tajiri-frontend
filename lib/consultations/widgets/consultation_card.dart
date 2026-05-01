import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/consultation.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

/// Reusable consultation card for list views.
/// Shows partner info, status, scheduled time, and a wait-time badge when
/// [avgWaitMinutes] is present.
class ConsultationCard extends StatelessWidget {
  final Consultation consultation;
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

  @override
  Widget build(BuildContext context) {
    final c = consultation;
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
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
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _kPrimary.withValues(alpha: 0.06),
                    child: Text(
                      (c.partnerName ?? '?').characters.first,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.partnerName ?? '—',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          isSw ? c.vertical.labelSwahili : c.vertical.label,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _kSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(c.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isSw ? c.status.labelSwahili : c.status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(c.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: _kSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${c.startsAt.day} ${_month(c.startsAt.month)} ${c.startsAt.year}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: _kPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: _kSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${c.startsAt.hour.toString().padLeft(2, '0')}:${c.startsAt.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: _kPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Icon(c.mode.icon, size: 14, color: _kSecondary),
                  const SizedBox(width: 4),
                  Text(
                    isSw ? c.mode.labelSwahili : c.mode.label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _kSecondary,
                    ),
                  ),
                ],
              ),
              if (c.serviceTitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  c.serviceTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (c.avgWaitMinutes != null && c.avgWaitMinutes! > 0) ...[
                const SizedBox(height: 10),
                _waitTimeBadge(c.avgWaitMinutes!, isSw),
              ],
              if (c.isJoinable || c.isCancellableByEither) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (c.isJoinable && onJoin != null)
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: FilledButton.icon(
                            onPressed: onJoin,
                            icon: Icon(c.mode.icon, size: 16),
                            label: Text(isSw ? 'Jiunge' : 'Join'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (c.isJoinable &&
                        c.isCancellableByEither &&
                        onCancel != null)
                      const SizedBox(width: 10),
                    if (c.isCancellableByEither && onCancel != null)
                      SizedBox(
                        height: 40,
                        child: OutlinedButton(
                          onPressed: onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(isSw ? 'Ghairi' : 'Cancel'),
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

  Widget _waitTimeBadge(int minutes, bool isSw) {
    final (bg, fg) = minutes > 30
        ? (const Color(0xFFFFF8E1), const Color(0xFFE65100))
        : minutes < 15
            ? (const Color(0xFFE8F5E9), const Color(0xFF1B5E20))
            : (const Color(0xFFFFF8E1), const Color(0xFFE65100));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            isSw
                ? 'Muda wa kusubiri ~$minutes daka'
                : 'Wait time ~$minutes min',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(ConsultationStatus status) {
    switch (status) {
      case ConsultationStatus.pending:
        return const Color(0xFFFFA726);
      case ConsultationStatus.confirmed:
        return const Color(0xFF4CAF50);
      case ConsultationStatus.inProgress:
        return const Color(0xFF4527A0);
      case ConsultationStatus.completed:
        return const Color(0xFF1B5E20);
      case ConsultationStatus.cancelled:
      case ConsultationStatus.rejected:
        return const Color(0xFFB71C1C);
    }
  }

  String _month(int m) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return months[m - 1];
  }
}
