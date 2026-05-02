import 'package:flutter/material.dart';

import '../../../l10n/app_strings_scope.dart';
import '../../../models/privacy_settings_model.dart';
import '../../../services/privacy_service.dart';
import '_privacy_widgets.dart';

/// Activity & presence — last seen, online status, read receipts.
class ActivityPrivacyScreen extends StatefulWidget {
  final int currentUserId;
  const ActivityPrivacyScreen({super.key, required this.currentUserId});

  @override
  State<ActivityPrivacyScreen> createState() => _ActivityPrivacyScreenState();
}

class _ActivityPrivacyScreenState extends State<ActivityPrivacyScreen> {
  final _service = PrivacyService();
  PrivacySettings _s = const PrivacySettings();
  bool _loading = true;
  String? _formError;
  final Set<String> _saving = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await _service.getPrivacySettings(widget.currentUserId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r.success && r.settings != null) _s = r.settings!;
    });
  }

  Future<void> _saveField(String key, String value) async {
    final prev = _s;
    setState(() {
      _saving.add(key);
      _s = _s.copyWith({key: value});
      _formError = null;
    });
    final updated = await _service.patch(widget.currentUserId, {key: value});
    if (!mounted) return;
    setState(() {
      _saving.remove(key);
      if (updated == null) {
        _s = prev;
        _formError = 'save_failed';
      } else {
        _s = updated;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: kFaraghaBg,
        appBar: AppBar(
          title: Text(s?.faraghaCardActivity ?? 'Activity & presence'),
          backgroundColor: kFaraghaCard,
          foregroundColor: kFaraghaPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: kFaraghaPrimary))
              : ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  children: [
                    FaraghaInlineErrorBanner(
                      message: _formError == 'save_failed'
                          ? (isSw ? 'Imeshindwa kuhifadhi' : 'Could not save change')
                          : null,
                      onDismiss: () => setState(() => _formError = null),
                      closeLabel: s?.close ?? 'Close',
                    ),
                    FaraghaAudienceTile(
                      icon: Icons.access_time,
                      title: s?.privacyShowLastSeen ?? 'Show "last seen"',
                      value: _s.lastSeenVisibility,
                      saving: _saving.contains('last_seen_visibility'),
                      allowedOptions: const ['everyone', 'friends', 'nobody'],
                      onChanged: (v) => _saveField('last_seen_visibility', v),
                      isSwahili: isSw,
                    ),
                    FaraghaAudienceTile(
                      icon: Icons.circle,
                      title: s?.faraghaShowOnlineStatus ?? 'Show online status',
                      value: _s.onlineStatusVisibility,
                      saving: _saving.contains('online_status_visibility'),
                      allowedOptions: const ['everyone', 'friends', 'nobody'],
                      onChanged: (v) => _saveField('online_status_visibility', v),
                      isSwahili: isSw,
                    ),
                    FaraghaAudienceTile(
                      icon: Icons.done_all,
                      title: s?.faraghaShowReadReceipts ?? 'Show read receipts',
                      value: _s.readReceiptsVisibility,
                      saving: _saving.contains('read_receipts_visibility'),
                      allowedOptions: const ['everyone', 'nobody'],
                      onChanged: (v) => _saveField('read_receipts_visibility', v),
                      isSwahili: isSw,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
        ),
      ),
    );
  }
}
