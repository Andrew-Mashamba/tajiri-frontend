// lib/reminders/pages/add_reminder_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/reminder_models.dart';
import '../services/reminder_detail_prefs.dart';
import '../services/reminders_aggregator.dart';
import '../services/reminders_notification_service.dart';
import '../services/reminders_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class AddReminderPage extends StatefulWidget {
  final int userId;

  const AddReminderPage({super.key, required this.userId});

  @override
  State<AddReminderPage> createState() => _AddReminderPageState();
}

class _AddReminderPageState extends State<AddReminderPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _dueAt = DateTime.now().add(const Duration(hours: 1));
  ReminderCategory _category = ReminderCategory.general;
  ReminderRepeat _repeat = ReminderRepeat.none;
  bool _notify = true;
  bool _saving = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final s = await LocalStorageService.getInstance();
    _token = s.getAuthToken();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(_dueAt.year, _dueAt.month, _dueAt.day);
    final lastDate = today.add(const Duration(days: 365 * 5));
    final firstDate = dueDay.isBefore(today) ? dueDay : today;
    var initialDate = dueDay;
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueAt),
    );
    if (time == null || !mounted) return;
    setState(() {
      _dueAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    final strings = AppStringsScope.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings?.remindersSignInToSave ?? 'Sign in to save reminders',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);

    final item = ReminderItem(
      id: '',
      title: _titleCtrl.text.trim(),
      subtitle: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      dueAt: _dueAt,
      category: _category,
      repeat: _repeat,
      isDone: false,
      isStandalone: true,
    );

    final result = await RemindersService.create(item,
        token: _token!, userId: widget.userId);

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.success && result.data != null) {
      final saved = result.data!;
      final existing = await ReminderDetailPrefsStore.get(saved.id);
      await ReminderDetailPrefsStore.put(
        saved.id,
        ReminderDetailPrefs(
          sound: existing?.sound ?? 'default',
          defaultSnoozeMinutes: existing?.defaultSnoozeMinutes ?? 15,
          androidSoundUri: existing?.androidSoundUri,
          notificationsEnabled: _notify,
        ),
      );
      if (_token != null) {
        try {
          final items = await RemindersAggregator.getAllStrictWithRetries(
            token: _token!,
            userId: widget.userId,
          );
          await RemindersNotificationService.scheduleAll(items);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  strings?.remindersSavedNotifySyncFailed ??
                      'Saved, but notifications could not refresh.',
                ),
              ),
            );
          }
        }
      }
    }

    if (result.success && mounted) {
      Navigator.pop(context, result.data);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ??
                (strings?.remindersSaveFailed ?? 'Could not save'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final sw = s?.isSwahili ?? false;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          s?.remindersNew ?? 'New reminder',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _kPrimary,
          ),
        ),
        iconTheme: const IconThemeData(color: _kPrimary),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    s?.save ?? 'Save',
                    style: const TextStyle(
                      color: _kPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: s?.remindersTitleLabel ?? 'Title *',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 1,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return s?.remindersTitleRequired ?? 'Enter a title';
                  }
                  return null;
                },
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                labelText: s?.remindersNotesLabel ?? 'Notes (optional)',
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_rounded, color: _kPrimary),
              title: Text(
                DateFormat('EEE, d MMM yyyy • HH:mm').format(_dueAt),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(s?.remindersDateTimeLabel ?? 'Date and time'),
              onTap: _pickDateTime,
              tileColor: Colors.transparent,
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                s?.remindersCategorySection ?? 'Type',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kSecondary,
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ReminderCategory.values
                  .where((c) => c != ReminderCategory.calendar)
                  .map((c) => ChoiceChip(
                        label: Text(
                          sw ? c.displayName : c.subtitle,
                          style: const TextStyle(fontSize: 12),
                        ),
                        avatar: Icon(c.icon, size: 14),
                        selected: _category == c,
                        onSelected: (_) => setState(() => _category = c),
                        selectedColor: _kPrimary.withValues(alpha: 0.12),
                        checkmarkColor: _kPrimary,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                s?.remindersRepeatSection ?? 'Repeat',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kSecondary,
                ),
              ),
            ),
            DropdownButtonFormField<ReminderRepeat>(
              key: ValueKey(_repeat),
              initialValue: _repeat,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: ReminderRepeat.values
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(sw ? r.displayName : r.subtitle),
                      ))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _repeat = v ?? ReminderRepeat.none),
            ),
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(s?.remindersNotifyToggleTitle ?? 'Send notification'),
              subtitle: Text(
                s?.remindersNotifyToggleSubtitle ??
                    'Get an alert before the due time',
              ),
              value: _notify,
              onChanged: (v) => setState(() => _notify = v),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
