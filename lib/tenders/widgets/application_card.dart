// Application tracking card widget
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/tender_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kUrgent = Color(0xFFD32F2F);
const Color _kWarning = Color(0xFFE65100);

class ApplicationCard extends StatelessWidget {
  final TenderApplication application;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ApplicationCard({
    super.key,
    required this.application,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    return Dismissible(
      key: Key('app-${application.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        if (onDelete == null) return false;
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(isSwahili ? 'Futa Ombi' : 'Delete Application'),
            content: Text(isSwahili
                ? 'Una uhakika unataka kufuta ombi hili?'
                : 'Are you sure you want to delete this application?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(isSwahili ? 'Hapana' : 'Cancel', style: const TextStyle(color: _kSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(isSwahili ? 'Futa' : 'Delete', style: const TextStyle(color: _kUrgent)),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: _kUrgent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: _kUrgent),
      ),
      child: GestureDetector(
        onTap: onTap ?? onEdit,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badge + deadline
                Row(
                  children: [
                    _buildStatusBadge(),
                    const Spacer(),
                    if (application.deadline != null) _buildDeadline(isSwahili),
                  ],
                ),
                const SizedBox(height: 10),

                // Tender title
                Text(
                  application.tenderTitle ?? application.tenderId,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Institution
                if (application.institutionSlug != null)
                  Text(
                    application.institutionDisplay,
                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                // Notes preview
                if (application.notes != null && application.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      application.notes!,
                      style: const TextStyle(fontSize: 12, color: _kSecondary, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // Bottom: edit hint
                Row(
                  children: [
                    Icon(Icons.touch_app_rounded, size: 14, color: _kSecondary.withValues(alpha: 0.4)),
                    const SizedBox(width: 4),
                    Text(
                      isSwahili ? 'Gusa kubadilisha hali' : 'Tap to change status',
                      style: TextStyle(fontSize: 11, color: _kSecondary.withValues(alpha: 0.5)),
                    ),
                    const Spacer(),
                    Text(
                      isSwahili ? 'Telezesha kufuta' : 'Swipe to delete',
                      style: TextStyle(fontSize: 11, color: _kSecondary.withValues(alpha: 0.5)),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.swipe_left_rounded, size: 14, color: _kSecondary.withValues(alpha: 0.4)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final status = application.status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 13, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadline(bool isSwahili) {
    final days = application.daysToDeadline;
    if (days < 0) {
      return Text(
        isSwahili ? 'Imepita' : 'Overdue',
        style: TextStyle(fontSize: 12, color: _kSecondary.withValues(alpha: 0.6)),
      );
    }

    final isUrgent = days <= 3;
    final isWarning = days <= 7;
    final color = isUrgent ? _kUrgent : isWarning ? _kWarning : _kSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule_rounded, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          days == 0
              ? (isSwahili ? 'Leo!' : 'Today!')
              : (isSwahili ? 'Siku $days' : '$days days'),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
        ),
      ],
    );
  }
}
