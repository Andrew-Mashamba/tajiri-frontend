import 'package:flutter/material.dart';

import '../../../l10n/app_strings_scope.dart';
import '../../../services/notification_preferences_service.dart';
import '_arifa_widgets.dart';

class QuietHoursScreen extends StatefulWidget {
  final int currentUserId;
  const QuietHoursScreen({super.key, required this.currentUserId});

  @override
  State<QuietHoursScreen> createState() => _QuietHoursScreenState();
}

class _QuietHoursScreenState extends State<QuietHoursScreen> {
  late final NotificationPreferencesService _service;
  NotificationPreferences _prefs = const NotificationPreferences();
  bool _loading = true;
  String? _formError;
  final Set<String> _saving = {};

  @override
  void initState() {
    super.initState();
    _service = NotificationPreferencesService(widget.currentUserId);
    _load();
  }

  Future<void> _load() async {
    final r = await _service.load();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r.success && r.prefs != null) _prefs = r.prefs!;
    });
  }

  Future<void> _setEnabled(bool v) async {
    const key = 'quiet_hours_enabled';
    final prev = _prefs;
    setState(() {
      _saving.add(key);
      _prefs = _prefs.withGlobals(quietEnabled: v);
      _formError = null;
    });
    final updated = await _service.patch({'quiet_hours_enabled': v});
    if (!mounted) return;
    setState(() {
      _saving.remove(key);
      if (updated == null) {
        _prefs = prev;
        _formError = 'save_failed';
      } else {
        _prefs = updated;
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _prefs.quietStart : _prefs.quietEnd;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;
    final key = isStart ? 'quiet_hours_start' : 'quiet_hours_end';
    final prev = _prefs;
    setState(() {
      _saving.add(key);
      _prefs = isStart
          ? _prefs.withGlobals(quietStart: picked)
          : _prefs.withGlobals(quietEnd: picked);
      _formError = null;
    });
    final updated = await _service.patch({key: formatHHmm(picked)});
    if (!mounted) return;
    setState(() {
      _saving.remove(key);
      if (updated == null) {
        _prefs = prev;
        _formError = 'save_failed';
      } else {
        _prefs = updated;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: kArifaBg,
        appBar: AppBar(
          title: Text(s?.arifaCardQuiet ?? 'Quiet hours'),
          backgroundColor: kArifaCard,
          foregroundColor: kArifaPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: kArifaPrimary))
              : ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  children: [
                    ArifaInlineErrorBanner(
                      message: _formError == null
                          ? null
                          : (s?.notifFailedSave ?? 'Could not save change'),
                      onDismiss: () => setState(() => _formError = null),
                      closeLabel: s?.close ?? 'Close',
                    ),
                    ArifaSwitchTile(
                      icon: Icons.bedtime_outlined,
                      title: s?.notifQuietHoursTitle ?? 'Quiet hours',
                      subtitle: s?.notifQuietHoursSubtitle,
                      value: _prefs.quietEnabled,
                      saving: _saving.contains('quiet_hours_enabled'),
                      onChanged: _setEnabled,
                    ),
                    if (_prefs.quietEnabled) ...[
                      ArifaNavTile(
                        icon: Icons.schedule,
                        title: s?.notifQuietStartLabel ?? 'Start',
                        trailing: _prefs.quietStart.format(context),
                        saving: _saving.contains('quiet_hours_start'),
                        onTap: () => _pickTime(isStart: true),
                      ),
                      ArifaNavTile(
                        icon: Icons.schedule,
                        title: s?.notifQuietEndLabel ?? 'End',
                        trailing: _prefs.quietEnd.format(context),
                        saving: _saving.contains('quiet_hours_end'),
                        onTap: () => _pickTime(isStart: false),
                      ),
                    ],
                    if (s != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                        child: Text(
                          s.notifSystemAlwaysOn,
                          style: const TextStyle(
                            fontSize: 11,
                            color: kArifaSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
        ),
      ),
    );
  }
}
