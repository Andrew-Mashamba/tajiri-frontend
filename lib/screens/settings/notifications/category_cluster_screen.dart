import 'package:flutter/material.dart';

import '../../../l10n/app_strings_scope.dart';
import '../../../services/notification_preferences_service.dart';
import '_arifa_widgets.dart';

/// Renders one category cluster: each category in the cluster gets a card
/// with its 4 channel toggles + a description of what the category covers.
///
/// Generic — instantiated from the home page with a different cluster.
class CategoryClusterScreen extends StatefulWidget {
  final int currentUserId;
  final ArifaCluster cluster;
  final String title;
  const CategoryClusterScreen({
    super.key,
    required this.currentUserId,
    required this.cluster,
    required this.title,
  });

  @override
  State<CategoryClusterScreen> createState() => _CategoryClusterScreenState();
}

class _CategoryClusterScreenState extends State<CategoryClusterScreen> {
  late final NotificationPreferencesService _service;
  NotificationPreferences _prefs = const NotificationPreferences();
  bool _loading = true;
  String? _loadError;
  String? _formError;
  final Set<String> _saving = {};

  @override
  void initState() {
    super.initState();
    _service = NotificationPreferencesService(widget.currentUserId);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final r = await _service.load();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r.success && r.prefs != null) {
        _prefs = r.prefs!;
      } else {
        _loadError = r.message ?? 'load_failed';
      }
    });
  }

  Future<void> _toggleCell(String category, String channel, bool value) async {
    final cellKey = '$category:$channel';
    final prev = _prefs;
    setState(() {
      _saving.add(cellKey);
      _prefs = _prefs.withCell(category, channel, value);
      _formError = null;
    });
    final updated = await _service.patch({
      'category_channels': {
        category: {channel: value},
      },
    });
    if (!mounted) return;
    setState(() {
      _saving.remove(cellKey);
      if (updated == null) {
        _prefs = prev;
        _formError = 'save_failed';
      } else {
        _prefs = updated;
      }
    });
  }

  String _err(AppStrings? s) => switch (_loadError) {
        'not_signed_in' => s?.notifNotSignedIn ?? 'Not signed in',
        'load_failed' => s?.notifFailedLoad ?? 'Could not load preferences',
        _ => s?.notifFailedLoad ?? 'Could not load preferences',
      };

  String _formErr(AppStrings? s) => s?.notifFailedSave ?? 'Could not save change';

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: kArifaBg,
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: kArifaCard,
          foregroundColor: kArifaPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: kArifaPrimary))
              : _loadError != null
                  ? _errorState(s)
                  : _buildList(s!),
        ),
      ),
    );
  }

  Widget _errorState(AppStrings? s) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(_err(s), style: const TextStyle(color: kArifaSecondary), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: Text(s?.retry ?? 'Retry')),
            ],
          ),
        ),
      );

  Widget _buildList(AppStrings s) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        ArifaInlineErrorBanner(
          message: _formError == null ? null : _formErr(s),
          onDismiss: () => setState(() => _formError = null),
          closeLabel: s.close,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Text(
            s.notifColumnsHint,
            style: const TextStyle(fontSize: 12, color: kArifaSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        for (final catKey in widget.cluster.categories) _categoryCard(catKey, s),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _categoryCard(String catKey, AppStrings s) {
    final meta = ArifaCategoryMeta.forKey(catKey);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: kArifaCard,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kArifaIconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(meta.icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          meta.title(s),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: kArifaPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          meta.subtitle(s),
                          style: const TextStyle(
                            fontSize: 12,
                            color: kArifaSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final ch in ArifaChannel.all)
                    Expanded(
                      child: _channelCell(
                        catKey: catKey,
                        channel: ch,
                        value: _prefs.channel(catKey, ch),
                        s: s,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _channelCell({
    required String catKey,
    required String channel,
    required bool value,
    required AppStrings s,
  }) {
    final cellKey = '$catKey:$channel';
    final isSaving = _saving.contains(cellKey);
    final label = switch (channel) {
      ArifaChannel.push => (s.notifChannelPush, Icons.notifications_active_outlined),
      ArifaChannel.email => (s.notifChannelEmail, Icons.email_outlined),
      ArifaChannel.sms => (s.notifChannelSms, Icons.sms_outlined),
      ArifaChannel.inApp => (s.notifChannelInApp, Icons.phone_iphone_outlined),
      _ => (channel, Icons.tune),
    };

    return Semantics(
      toggled: value,
      label: '${ArifaCategoryMeta.forKey(catKey).title(s)} — ${label.$1}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(label.$2, size: 16, color: kArifaSecondary),
            const SizedBox(height: 2),
            Text(
              label.$1,
              style: const TextStyle(fontSize: 10, color: kArifaSecondary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: kArifaSecondary),
                  )
                : Switch(
                    value: value,
                    onChanged: (v) => _toggleCell(catKey, channel, v),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    activeTrackColor: kArifaPrimary.withValues(alpha: 0.5),
                    activeThumbColor: kArifaPrimary,
                  ),
          ],
        ),
      ),
    );
  }
}
