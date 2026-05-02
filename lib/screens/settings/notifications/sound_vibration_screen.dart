import 'package:flutter/material.dart';

import '../../../l10n/app_strings_scope.dart';
import '../../../services/notification_preferences_service.dart';
import '_arifa_widgets.dart';

class SoundVibrationScreen extends StatefulWidget {
  final int currentUserId;
  const SoundVibrationScreen({super.key, required this.currentUserId});

  @override
  State<SoundVibrationScreen> createState() => _SoundVibrationScreenState();
}

class _SoundVibrationScreenState extends State<SoundVibrationScreen> {
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

  Future<void> _setVibrate(bool v) async {
    const key = 'global_vibrate';
    final prev = _prefs;
    setState(() {
      _saving.add(key);
      _prefs = _prefs.withGlobals(vibrate: v);
      _formError = null;
    });
    final updated = await _service.patch({'global_vibrate': v});
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

  Future<void> _pickSound(AppStrings s) async {
    final options = <_SoundOption>[
      _SoundOption(code: null, label: s.notifSoundDefault),
      _SoundOption(code: 'chime', label: s.notifSoundChime),
      _SoundOption(code: 'bell', label: s.notifSoundBell),
      _SoundOption(code: 'silent', label: s.notifSoundNone),
    ];
    final picked = await showModalBottomSheet<_SoundOption>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                s.notifSoundTitle,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            ...options.map((o) => ListTile(
                  leading: Icon(
                    o.code == null
                        ? Icons.notifications_outlined
                        : o.code == 'silent'
                            ? Icons.notifications_off_outlined
                            : Icons.music_note_outlined,
                  ),
                  title: Text(o.label),
                  trailing: ((_prefs.sound ?? '') == (o.code ?? ''))
                      ? const Icon(Icons.check_rounded, color: kArifaPrimary)
                      : null,
                  onTap: () => Navigator.pop(ctx, o),
                )),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    if ((picked.code ?? '') == (_prefs.sound ?? '')) return;
    const key = 'global_sound';
    final prev = _prefs;
    setState(() {
      _saving.add(key);
      _prefs = _prefs.withGlobals(sound: picked.code);
      _formError = null;
    });
    final updated = await _service.patch({'global_sound': picked.code});
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

  String _soundLabel(AppStrings s) {
    switch (_prefs.sound) {
      case 'chime':
        return s.notifSoundChime;
      case 'bell':
        return s.notifSoundBell;
      case 'silent':
        return s.notifSoundNone;
      default:
        return s.notifSoundDefault;
    }
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
          title: Text(s?.arifaCardSound ?? 'Sound & vibration'),
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
                      icon: Icons.vibration,
                      title: s?.notifVibrateTitle ?? 'Vibrate',
                      subtitle: s?.notifVibrateSubtitle,
                      value: _prefs.vibrate,
                      saving: _saving.contains('global_vibrate'),
                      onChanged: _setVibrate,
                    ),
                    if (s != null)
                      ArifaNavTile(
                        icon: Icons.music_note_outlined,
                        title: s.notifSoundTitle,
                        subtitle: s.notifSoundSubtitle,
                        trailing: _soundLabel(s),
                        saving: _saving.contains('global_sound'),
                        onTap: () => _pickSound(s),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SoundOption {
  final String? code;
  final String label;
  _SoundOption({required this.code, required this.label});
}
