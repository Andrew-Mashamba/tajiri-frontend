// lib/reminders/widgets/reminder_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings_scope.dart';
import '../models/reminder_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFFFFFF);

class ReminderCard extends StatelessWidget {
  final ReminderItem item;
  final VoidCallback onTap;
  final VoidCallback onDone;
  final VoidCallback onUndoDone;
  final void Function(Duration snooze) onSnooze;
  final VoidCallback? onDelete;

  const ReminderCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDone,
    required this.onUndoDone,
    required this.onSnooze,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final sw = s?.isSwahili ?? false;

    return Slidable(
      key: ValueKey(item.id),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => item.isDone ? onUndoDone() : onDone(),
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            icon: item.isDone ? Icons.undo_rounded : Icons.check_rounded,
            label: item.isDone
                ? (s?.remindersSlidableUndo ?? 'Undo')
                : (s?.remindersSlidableDone ?? 'Done'),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _showSnoozeSheet(context),
            backgroundColor: const Color(0xFF555555),
            foregroundColor: Colors.white,
            icon: Icons.snooze_rounded,
            label: s?.remindersSlidableSnooze ?? 'Snooze',
          ),
          if (onDelete != null)
            SlidableAction(
              onPressed: (_) => onDelete!(),
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              icon: Icons.delete_rounded,
              label: s?.remindersSlidableDelete ?? 'Delete',
            ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Container(
            color: _kBg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
            children: [
              _CategoryDot(category: item.category),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: item.isDone ? _kSecondary : _kPrimary,
                        decoration:
                            item.isDone ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle!,
                        style: const TextStyle(
                            fontSize: 12, color: _kSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _formatDue(context, item.dueAt, sw),
                          style: TextStyle(
                            fontSize: 11,
                            color: _isOverdue(item)
                                ? Colors.red.shade700
                                : _kSecondary,
                            fontWeight: _isOverdue(item)
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        if (!item.isStandalone) ...[
                          const SizedBox(width: 6),
                          _SourceBadge(
                            category: item.category,
                            useSwahili: sw,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(item.category.icon, size: 18, color: _kSecondary),
            ],
          ),
          ),
        ),
      ),
    );
  }

  bool _isOverdue(ReminderItem item) =>
      !item.isDone && item.dueAt.isBefore(DateTime.now());

  String _formatDue(BuildContext context, DateTime dt, bool sw) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(dt.year, dt.month, dt.day);
    final diff = itemDay.difference(today).inDays;
    final timeStr = DateFormat('HH:mm').format(dt);
    if (diff == 0) {
      return sw ? 'Leo $timeStr' : 'Today $timeStr';
    }
    if (diff == 1) {
      return sw ? 'Kesho $timeStr' : 'Tomorrow $timeStr';
    }
    if (diff == -1) {
      return sw ? 'Jana' : 'Yesterday';
    }
    if (diff < 0) {
      return sw
          ? 'Imechelewa ${-diff} siku'
          : '${-diff} days overdue';
    }
    if (diff < 7) {
      return sw ? 'Baada ya siku $diff' : 'In $diff days';
    }
    final loc = Localizations.localeOf(context).toString();
    return DateFormat('d MMM yyyy', loc).format(dt);
  }

  void _showSnoozeSheet(BuildContext context) {
    final s = AppStringsScope.of(context);
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s?.remindersSnoozeSheetTitle ?? 'Snooze',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.timer_rounded),
              title: Text(s?.remindersSnooze15m ?? '15 minutes'),
              onTap: () {
                Navigator.pop(context);
                onSnooze(const Duration(minutes: 15));
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule_rounded),
              title: Text(s?.remindersSnooze1h ?? '1 hour'),
              onTap: () {
                Navigator.pop(context);
                onSnooze(const Duration(hours: 1));
              },
            ),
            ListTile(
              leading: const Icon(Icons.wb_sunny_rounded),
              title: Text(s?.remindersSnoozeTomorrow ?? 'Tomorrow'),
              onTap: () {
                Navigator.pop(context);
                onSnooze(const Duration(days: 1));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _CategoryDot extends StatelessWidget {
  final ReminderCategory category;
  const _CategoryDot({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(category.icon, size: 18, color: const Color(0xFF1A1A1A)),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final ReminderCategory category;
  final bool useSwahili;

  const _SourceBadge({
    required this.category,
    required this.useSwahili,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        useSwahili ? category.displayName : category.subtitle,
        style: const TextStyle(fontSize: 10, color: Color(0xFF666666)),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
