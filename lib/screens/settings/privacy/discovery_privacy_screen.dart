import 'package:flutter/material.dart';

import '../../../l10n/app_strings_scope.dart';
import '../../../models/privacy_settings_model.dart';
import '../../../services/privacy_service.dart';
import '_privacy_widgets.dart';

/// Discovery — searchability, friend-suggestion presence, account opt-outs.
class DiscoveryPrivacyScreen extends StatefulWidget {
  final int currentUserId;
  const DiscoveryPrivacyScreen({super.key, required this.currentUserId});

  @override
  State<DiscoveryPrivacyScreen> createState() => _DiscoveryPrivacyScreenState();
}

class _DiscoveryPrivacyScreenState extends State<DiscoveryPrivacyScreen> {
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

  Future<void> _toggle(String key, bool value, bool currentValue) async {
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
          title: Text(s?.faraghaCardDiscovery ?? 'Discovery'),
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

                    FaraghaSwitchTile(
                      icon: Icons.phone_in_talk_outlined,
                      title: s?.faraghaSearchableByPhone ?? 'Findable by phone number',
                      value: _s.searchableByPhone,
                      saving: _saving.contains('searchable_by_phone'),
                      onChanged: (v) => _toggle('searchable_by_phone', v, _s.searchableByPhone),
                    ),
                    FaraghaSwitchTile(
                      icon: Icons.email_outlined,
                      title: s?.faraghaSearchableByEmail ?? 'Findable by email',
                      value: _s.searchableByEmail,
                      saving: _saving.contains('searchable_by_email'),
                      onChanged: (v) => _toggle('searchable_by_email', v, _s.searchableByEmail),
                    ),
                    FaraghaSwitchTile(
                      icon: Icons.group_outlined,
                      title: s?.faraghaDiscoverable ?? 'Show me in friend suggestions',
                      value: _s.discoverable,
                      saving: _saving.contains('discoverable'),
                      onChanged: (v) => _toggle('discoverable', v, _s.discoverable),
                    ),

                    FaraghaSection(title: isSw ? 'Mapendekezo ya kiotomatiki' : 'Automated suggestions'),
                    FaraghaSwitchTile(
                      icon: Icons.campaign_outlined,
                      title: s?.faraghaOptOutSponsored ?? 'Exclude me from sponsor matches',
                      value: _s.optOutSponsored,
                      saving: _saving.contains('opt_out_sponsored'),
                      onChanged: (v) => _toggle('opt_out_sponsored', v, _s.optOutSponsored),
                    ),
                    FaraghaSwitchTile(
                      icon: Icons.handshake_outlined,
                      title: s?.faraghaOptOutCollaboration ?? 'Exclude me from collab matches',
                      value: _s.optOutCollaboration,
                      saving: _saving.contains('opt_out_collaboration'),
                      onChanged: (v) => _toggle('opt_out_collaboration', v, _s.optOutCollaboration),
                    ),
                    FaraghaSwitchTile(
                      icon: Icons.sports_kabaddi_outlined,
                      title: s?.faraghaOptOutBattles ?? 'Exclude me from battle invites',
                      value: _s.optOutBattles,
                      saving: _saving.contains('opt_out_battles'),
                      onChanged: (v) => _toggle('opt_out_battles', v, _s.optOutBattles),
                    ),
                    FaraghaSwitchTile(
                      icon: Icons.forum_outlined,
                      title: s?.faraghaOptOutThreads ?? 'Exclude me from auto-detected threads',
                      value: _s.optOutThreads,
                      saving: _saving.contains('opt_out_threads'),
                      onChanged: (v) => _toggle('opt_out_threads', v, _s.optOutThreads),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
        ),
      ),
    );
  }
}
