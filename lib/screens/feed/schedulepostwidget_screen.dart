import 'package:flutter/material.dart';
import '../../widgets/schedule_post_widget.dart';

/// Full-screen schedule post screen (Story 85).
/// Path: Home → Feed → Create Post → Schedule toggle → Date/time.
/// Lets the user pick a date/time for scheduling a post; returns [DateTime?] on confirm.
class SchedulePostWidgetScreen extends StatefulWidget {
  /// Initial date/time when rescheduling or editing.
  final DateTime? initialScheduledAt;

  const SchedulePostWidgetScreen({
    super.key,
    this.initialScheduledAt,
  });

  /// Call after pushing this screen to get the selected date/time.
  /// Example: `final picked = await Navigator.push<DateTime?>(context, ...);`
  static Future<DateTime?> navigate(
    BuildContext context, {
    DateTime? initialScheduledAt,
  }) {
    return Navigator.push<DateTime?>(
      context,
      MaterialPageRoute<DateTime?>(
        builder: (_) => SchedulePostWidgetScreen(
          initialScheduledAt: initialScheduledAt,
        ),
      ),
    );
  }

  @override
  State<SchedulePostWidgetScreen> createState() =>
      _SchedulePostWidgetScreenState();
}

class _SchedulePostWidgetScreenState extends State<SchedulePostWidgetScreen> {
  DateTime? _scheduledAt;

  @override
  void initState() {
    super.initState();
    _scheduledAt = widget.initialScheduledAt;
  }

  void _onConfirm() {
    if (_scheduledAt != null && _scheduledAt!.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scheduled time must be in the future'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    Navigator.pop(context, _scheduledAt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Schedule Post'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
          style: IconButton.styleFrom(
            minimumSize: const Size(48, 48),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.35,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.schedule_send,
                        size: 64,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Choose when to publish',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select date and time for your post',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: SchedulePostWidget(
                    initialScheduledAt: _scheduledAt,
                    onScheduleChanged: (date) {
                      setState(() => _scheduledAt = date);
                    },
                    isEnabled: true,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 72,
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 2,
                        shadowColor: Colors.black.withValues(alpha: 0.1),
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(16),
                          child: const Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 72,
                      child: Material(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(16),
                        elevation: 2,
                        shadowColor: Colors.black.withValues(alpha: 0.1),
                        child: InkWell(
                          onTap: _scheduledAt != null ? _onConfirm : null,
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: Text(
                              'Confirm',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _scheduledAt != null
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
