// lib/reminders/pages/reminder_detail_page.dart
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings_scope.dart';
import '../models/reminder_models.dart';
import '../reminder_navigation.dart';
import '../services/reminder_detail_prefs.dart';
import '../services/reminder_ringtone_platform.dart';
import '../services/reminders_aggregator.dart';
import '../services/reminders_dismissed_store.dart';
import '../services/reminders_snooze_override_store.dart';
import '../services/reminders_notification_service.dart';
import '../services/reminders_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ReminderDetailPage extends StatefulWidget {
  final int userId;
  final ReminderItem item;
  final String? token;
  final Future<void> Function(ReminderItem item, Duration by) onSnooze;

  const ReminderDetailPage({
    super.key,
    required this.userId,
    required this.item,
    required this.token,
    required this.onSnooze,
  });

  @override
  State<ReminderDetailPage> createState() => _ReminderDetailPageState();
}

class _ReminderDetailPageState extends State<ReminderDetailPage> {
  late ReminderItem _item;
  late TextEditingController _titleCtrl;
  late TextEditingController _noteCtrl;
  late DateTime _dueAt;
  late ReminderCategory _category;
  late ReminderRepeat _repeat;
  String _sound = 'default';
  String? _androidSoundUri;
  int _snoozeMinutes = 15;
  bool _notificationsEnabled = true;
  bool _saving = false;
  bool _deleting = false;
  bool _prefsLoaded = false;

  bool get _editable => _item.isStandalone;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Avoid invalid dropdown value when prefs say `system` on iOS.
  String get _soundDropdownValue =>
      (_sound == 'system' && !_isAndroid) ? 'default' : _sound;

  static const _snoozeChoices = [5, 10, 15, 30, 60, 120];

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _titleCtrl = TextEditingController(text: _item.title);
    _noteCtrl = TextEditingController(text: _item.subtitle ?? '');
    _dueAt = _item.dueAt;
    _category = _item.category;
    _repeat = _item.repeat;
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await ReminderDetailPrefsStore.get(_item.id);
    if (!mounted) return;
    setState(() {
      if (p != null) {
        _sound = p.sound;
        _androidSoundUri = p.androidSoundUri;
        if (!_isAndroid && _sound == 'system') {
          _sound = 'default';
          _androidSoundUri = null;
        }
        final m = p.defaultSnoozeMinutes;
        _snoozeMinutes =
            _snoozeChoices.contains(m) ? m : 15;
        _notificationsEnabled = p.notificationsEnabled;
      }
      _prefsLoaded = true;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    if (!_editable) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(_dueAt.year, _dueAt.month, _dueAt.day);
    final lastDate = today.add(const Duration(days: 365 * 5));
    var firstDate = dueDay.isBefore(today) ? dueDay : today;
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

  Future<void> _persistPrefs() async {
    await ReminderDetailPrefsStore.put(
      _item.id,
      ReminderDetailPrefs(
        sound: _sound,
        defaultSnoozeMinutes: _snoozeMinutes,
        androidSoundUri: _sound == 'system' ? _androidSoundUri : null,
        notificationsEnabled: _notificationsEnabled,
      ),
    );
  }

  Future<void> _pickSystemSound() async {
    final uri = await ReminderRingtonePlatform.pickNotificationSound(
      existingUri: _androidSoundUri,
    );
    if (!mounted) return;
    if (uri != null && uri.isNotEmpty) {
      setState(() {
        _sound = 'system';
        _androidSoundUri = uri;
      });
    } else {
      setState(() {
        _sound = 'default';
        _androidSoundUri = null;
      });
    }
  }

  Future<void> _save() async {
    final s = AppStringsScope.of(context);
    setState(() => _saving = true);
    await _persistPrefs();

    if (_editable) {
      if (widget.token == null) {
        if (mounted) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                s?.remindersSignInToSave ?? 'Sign in to save',
              ),
            ),
          );
        }
        return;
      }
      final updated = ReminderItem(
        id: _item.id,
        title: _titleCtrl.text.trim(),
        subtitle: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        dueAt: _dueAt,
        category: _category,
        repeat: _repeat,
        isDone: _item.isDone,
        isStandalone: true,
        sourceRoute: _item.sourceRoute,
        serverId: _item.serverId,
        eventKind: _item.eventKind,
      );
      final result =
          await RemindersService.update(updated, token: widget.token!);
      if (!mounted) return;
      if (result.success && result.data != null) {
        setState(() => _item = result.data!);
      } else {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message ?? (s?.remindersSaveFailed ?? 'Could not save'),
            ),
          ),
        );
        return;
      }
    }

    if (widget.token != null) {
      try {
        final items = await RemindersAggregator.getAllStrictWithRetries(
          token: widget.token!,
          userId: widget.userId,
        );
        await RemindersNotificationService.scheduleAll(items);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                s?.remindersSavedNotifySyncFailed ??
                    'Saved, but notifications could not refresh.',
              ),
            ),
          );
        }
      }
    }
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context, true);
    }
  }

  Future<void> _confirmDelete() async {
    final s = AppStringsScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s?.remindersDeleteTitle ?? 'Delete reminder?'),
        content: Text(s?.remindersDeleteMessage ?? 'This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red[800]),
            child: Text(s?.delete ?? 'Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) await _deleteReminder();
  }

  Future<void> _deleteReminder() async {
    if (!_editable || widget.token == null) return;
    final s = AppStringsScope.of(context);
    setState(() => _deleting = true);
    try {
      await RemindersService.delete(_item.id, token: widget.token!);
      await ReminderDetailPrefsStore.remove(_item.id);
      await RemindersDismissedStore.remove(_item.id);
      await RemindersSnoozeOverrideStore.remove(_item.id);
      await RemindersNotificationService.cancel(_item.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              s?.remindersSaveFailed ?? 'Something went wrong',
            ),
          ),
        );
      }
    }
  }

  Future<void> _snoozeNow() async {
    await widget.onSnooze(_item, Duration(minutes: _snoozeMinutes));
    if (!mounted) return;
    await _persistPrefs();
    try {
      if (widget.token != null) {
        final items = await RemindersAggregator.getAllStrictWithRetries(
          token: widget.token!,
          userId: widget.userId,
        );
        await RemindersNotificationService.scheduleAll(items);
      }
    } catch (_) {
      if (mounted) {
        final s = AppStringsScope.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              s?.remindersSavedNotifySyncFailed ??
                  'Saved, but notifications could not refresh.',
            ),
          ),
        );
      }
    }
    if (mounted) Navigator.pop(context, true);
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
          s?.remindersDetailTitle ?? 'Reminder details',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _kPrimary,
          ),
        ),
        iconTheme: const IconThemeData(color: _kPrimary),
        actions: [
          TextButton(
            onPressed: (_saving || !_prefsLoaded) ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    s?.remindersSaveDetails ?? 'Save preferences',
                    style: const TextStyle(
                      color: _kPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: !_prefsLoaded
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _kPrimary,
                ),
              )
            : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_editable) ...[
              Text(
                s?.remindersAggregatedHint ?? '',
                style: const TextStyle(fontSize: 13, color: _kSecondary),
              ),
              const SizedBox(height: 12),
            ],
            if (_editable) ...[
              TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: s?.remindersTitleLabel ?? 'Title *',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteCtrl,
                decoration: InputDecoration(
                  labelText: s?.remindersNotesLabel ?? 'Notes (optional)',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ] else ...[
              Text(
                _item.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              if (_item.subtitle != null && _item.subtitle!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _item.subtitle!,
                  style: const TextStyle(fontSize: 14, color: _kSecondary),
                ),
              ],
            ],
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_rounded, color: _kPrimary),
              title: Text(
                DateFormat('EEE, d MMM yyyy • HH:mm').format(_dueAt),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(s?.remindersDateTimeLabel ?? 'Date and time'),
              onTap: _editable ? _pickDateTime : null,
            ),
            if (_editable) ...[
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
              const SizedBox(height: 12),
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
            ] else ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(sw ? _item.category.displayName : _item.category.subtitle),
                subtitle: Text(s?.remindersCategorySection ?? 'Type'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(sw ? _item.repeat.displayName : _item.repeat.subtitle),
                subtitle: Text(s?.remindersRepeatSection ?? 'Repeat'),
              ),
            ],
            const Divider(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _notificationsEnabled,
              activeThumbColor: _kPrimary,
              title: Text(
                s?.remindersNotifyEnabledTitle ?? 'Reminder notifications',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: _kPrimary,
                ),
              ),
              subtitle: Text(
                s?.remindersNotifyEnabledSubtitle ?? '',
                style: const TextStyle(fontSize: 13, color: _kSecondary),
              ),
              onChanged: (v) => setState(() => _notificationsEnabled = v),
            ),
            const Divider(height: 32),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                s?.remindersSoundSection ?? 'Sound',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kSecondary,
                ),
              ),
            ),
            DropdownButtonFormField<String>(
              key: ValueKey('${_sound}_${_androidSoundUri ?? ''}'),
              initialValue: _soundDropdownValue,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                DropdownMenuItem(
                  value: 'default',
                  child: Text(s?.remindersSoundDefault ?? 'Default'),
                ),
                DropdownMenuItem(
                  value: 'silent',
                  child: Text(s?.remindersSoundSilent ?? 'Silent'),
                ),
                if (_isAndroid)
                  DropdownMenuItem(
                    value: 'system',
                    child: Text(s?.remindersSoundPhone ?? 'Phone sound'),
                  ),
              ],
              onChanged: (v) async {
                if (v == null) return;
                if (v == 'system' && _isAndroid) {
                  await _pickSystemSound();
                } else {
                  setState(() {
                    _sound = v;
                    _androidSoundUri = null;
                  });
                }
              },
            ),
            if (_isAndroid &&
                _sound == 'system' &&
                _androidSoundUri != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _pickSystemSound,
                  child: Text(s?.remindersSoundChange ?? 'Change sound'),
                ),
              ),
            ],
            if (!_isAndroid) ...[
              const SizedBox(height: 8),
              Text(
                s?.remindersSoundIosNote ?? '',
                style: const TextStyle(fontSize: 12, color: _kSecondary),
              ),
            ],
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                s?.remindersSnoozeDefaultSection ?? 'Default snooze duration',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kSecondary,
                ),
              ),
            ),
            DropdownButtonFormField<int>(
              key: ValueKey(_snoozeMinutes),
              initialValue: _snoozeMinutes,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _snoozeChoices
                  .map(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text(
                        s?.remindersSnoozeOptionMinutes(m) ?? '$m min',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _snoozeMinutes = v ?? 15),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: (_notificationsEnabled && !_deleting) ? _snoozeNow : null,
                child: Text(s?.remindersSnoozeNowButton ?? 'Snooze now'),
              ),
            ),
            if (_editable) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[800],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: (_saving || _deleting || widget.token == null)
                      ? null
                      : _confirmDelete,
                  child: _deleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(s?.remindersSlidableDelete ?? 'Delete'),
                ),
              ),
            ],
            if (_item.sourceRoute != null &&
                _item.sourceRoute!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  ReminderNavigation.openSource(
                    context,
                    item: _item,
                    profileUserId: widget.userId,
                  );
                },
                child: Text(s?.remindersOpenSourceButton ?? 'Open source'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
