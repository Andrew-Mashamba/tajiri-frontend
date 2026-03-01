import 'package:flutter/material.dart';

/// Widget for selecting a schedule date/time for posts
class SchedulePostWidget extends StatefulWidget {
  final DateTime? initialScheduledAt;
  final ValueChanged<DateTime?> onScheduleChanged;
  final bool isEnabled;

  const SchedulePostWidget({
    super.key,
    this.initialScheduledAt,
    required this.onScheduleChanged,
    this.isEnabled = true,
  });

  @override
  State<SchedulePostWidget> createState() => _SchedulePostWidgetState();
}

class _SchedulePostWidgetState extends State<SchedulePostWidget> {
  DateTime? _scheduledAt;
  bool _isSchedulingEnabled = false;

  @override
  void initState() {
    super.initState();
    _scheduledAt = widget.initialScheduledAt;
    _isSchedulingEnabled = widget.initialScheduledAt != null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isSchedulingEnabled ? Colors.orange.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isSchedulingEnabled ? Colors.orange.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule_send,
                color: _isSchedulingEnabled ? Colors.orange.shade700 : Colors.grey.shade600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Schedule Post',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _isSchedulingEnabled ? Colors.orange.shade900 : Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      _isSchedulingEnabled && _scheduledAt != null
                          ? _formatScheduledDate(_scheduledAt!)
                          : 'Publish at a specific time',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isSchedulingEnabled ? Colors.orange.shade700 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isSchedulingEnabled,
                onChanged: widget.isEnabled
                    ? (value) {
                        setState(() {
                          _isSchedulingEnabled = value;
                          if (!value) {
                            _scheduledAt = null;
                            widget.onScheduleChanged(null);
                          } else {
                            // Default to 1 hour from now
                            _scheduledAt = DateTime.now().add(const Duration(hours: 1));
                            widget.onScheduleChanged(_scheduledAt);
                          }
                        });
                      }
                    : null,
                activeColor: Colors.orange.shade700,
              ),
            ],
          ),
          if (_isSchedulingEnabled) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _DateTimeButton(
                    icon: Icons.calendar_today,
                    label: _scheduledAt != null
                        ? '${_scheduledAt!.day}/${_scheduledAt!.month}/${_scheduledAt!.year}'
                        : 'Select Date',
                    onTap: () => _selectDate(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateTimeButton(
                    icon: Icons.access_time,
                    label: _scheduledAt != null
                        ? '${_scheduledAt!.hour.toString().padLeft(2, '0')}:${_scheduledAt!.minute.toString().padLeft(2, '0')}'
                        : 'Select Time',
                    onTap: () => _selectTime(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Quick select buttons
            Wrap(
              spacing: 8,
              children: [
                _QuickSelectChip(
                  label: '1 hour',
                  onTap: () => _setQuickSchedule(const Duration(hours: 1)),
                ),
                _QuickSelectChip(
                  label: '3 hours',
                  onTap: () => _setQuickSchedule(const Duration(hours: 3)),
                ),
                _QuickSelectChip(
                  label: 'Tomorrow 9AM',
                  onTap: () => _setTomorrowMorning(),
                ),
                _QuickSelectChip(
                  label: 'Weekend',
                  onTap: () => _setNextWeekend(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _scheduledAt = DateTime(
          date.year,
          date.month,
          date.day,
          _scheduledAt?.hour ?? 9,
          _scheduledAt?.minute ?? 0,
        );
        widget.onScheduleChanged(_scheduledAt);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: _scheduledAt != null
          ? TimeOfDay.fromDateTime(_scheduledAt!)
          : const TimeOfDay(hour: 9, minute: 0),
    );

    if (time != null) {
      setState(() {
        final date = _scheduledAt ?? DateTime.now().add(const Duration(hours: 1));
        _scheduledAt = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        widget.onScheduleChanged(_scheduledAt);
      });
    }
  }

  void _setQuickSchedule(Duration duration) {
    setState(() {
      _scheduledAt = DateTime.now().add(duration);
      widget.onScheduleChanged(_scheduledAt);
    });
  }

  void _setTomorrowMorning() {
    final now = DateTime.now();
    setState(() {
      _scheduledAt = DateTime(now.year, now.month, now.day + 1, 9, 0);
      widget.onScheduleChanged(_scheduledAt);
    });
  }

  void _setNextWeekend() {
    var date = DateTime.now();
    // Find next Saturday
    while (date.weekday != DateTime.saturday) {
      date = date.add(const Duration(days: 1));
    }
    setState(() {
      _scheduledAt = DateTime(date.year, date.month, date.day, 10, 0);
      widget.onScheduleChanged(_scheduledAt);
    });
  }

  String _formatScheduledDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);

    String dateStr;
    if (diff.inDays == 0 && date.day == now.day) {
      dateStr = 'Today';
    } else if (diff.inDays <= 1 && date.day == now.day + 1) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = '${date.day}/${date.month}/${date.year}';
    }

    return '$dateStr at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _DateTimeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DateTimeButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickSelectChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickSelectChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
