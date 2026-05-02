import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../services/profile_service.dart';

/// Creator preferences — the canonical home for opt-outs and creator-
/// specific toggles. Reachable from:
///   • Profile → Creator dashboard (entry point: "Preferences" link)
///   • Settings → Creator (single tile, replaces the 4 inline switches)
///   • Deep-link /settings/creator
///
/// Faragha → Discovery → "Automated suggestions" hosts copies of the
/// same toggles for users who think of these as privacy / discovery
/// concerns. Both surfaces hit the same backend columns
/// (`user_profiles.opt_out_*`) so the values stay in sync no matter
/// which screen flips them.
class CreatorSettingsScreen extends StatefulWidget {
  final int currentUserId;
  const CreatorSettingsScreen({super.key, required this.currentUserId});

  @override
  State<CreatorSettingsScreen> createState() => _CreatorSettingsScreenState();
}

class _CreatorSettingsScreenState extends State<CreatorSettingsScreen> {
  static const Color _bg = Color(0xFFFAFAFA);
  static const Color _card = Color(0xFFFFFFFF);
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondary = Color(0xFF666666);
  static const Color _iconBg = Color(0xFF1A1A1A);

  bool _loading = true;
  String? _formError;
  final Set<String> _saving = {};

  bool _optOutSponsored = false;
  bool _optOutCollaboration = false;
  bool _optOutBattles = false;
  bool _optOutThreads = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Hydrate from local Hive first (instant), then sync from the
  /// canonical privacy-settings document so this screen always shows
  /// the same value as Faragha → Discovery.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _formError = null;
    });
    final storage = await LocalStorageService.getInstance();
    if (mounted) {
      setState(() {
        _optOutSponsored = storage.getBool('opt_out_sponsored') ?? false;
        _optOutCollaboration = storage.getBool('opt_out_collaboration') ?? false;
        _optOutBattles = storage.getBool('opt_out_battles') ?? false;
        _optOutThreads = storage.getBool('opt_out_threads') ?? false;
      });
    }
    try {
      final token = storage.getAuthToken();
      if (token != null) {
        final r = await http.get(
          Uri.parse(
              '${ApiConfig.baseUrl}/users/${widget.currentUserId}/privacy-settings'),
          headers: ApiConfig.authHeaders(token),
        );
        if (r.statusCode == 200 && mounted) {
          final body = jsonDecode(r.body) as Map<String, dynamic>;
          final data =
              (body['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
          setState(() {
            _optOutSponsored = data['opt_out_sponsored'] == true;
            _optOutCollaboration = data['opt_out_collaboration'] == true;
            _optOutBattles = data['opt_out_battles'] == true;
            _optOutThreads = data['opt_out_threads'] == true;
          });
        }
      }
    } catch (_) {
      // Local Hive value remains shown; no inline error needed for
      // background refresh failure.
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggle(String key, bool value, void Function(bool) setLocal) async {
    final prev = !value;
    setState(() {
      _saving.add(key);
      setLocal(value);
      _formError = null;
    });
    final storage = await LocalStorageService.getInstance();
    await storage.saveBool(key, value);
    final token = storage.getAuthToken();
    bool ok = false;
    if (token != null) {
      try {
        final r = await http.put(
          Uri.parse(
              '${ApiConfig.baseUrl}/users/${widget.currentUserId}/preferences'),
          headers: {
            ...ApiConfig.authHeaders(token),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({key: value}),
        );
        ok = r.statusCode >= 200 && r.statusCode < 300;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _saving.remove(key));
    if (!ok) {
      setState(() {
        setLocal(prev);
        _formError = 'sync_failed';
      });
      await storage.saveBool(key, prev);
    } else {
      ProfileService.invalidate(widget.currentUserId);
    }
  }

  String _err(AppStrings? s) => switch (_formError) {
        'sync_failed' => s?.preferenceSyncFailed ?? 'Could not save change',
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: Text(s?.creatorSettings ?? 'Creator settings'),
          backgroundColor: _card,
          foregroundColor: _primary,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        body: SafeArea(
          child: _loading
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _primary,
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: _primary,
                  onRefresh: _load,
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    children: [
                      if (_formError != null) _inlineErrorBanner(s),
                      _section(s?.isSwahili == true
                          ? 'Ugunduzi na ulinganishi'
                          : 'Discovery & matching'),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                        child: Text(
                          s?.isSwahili == true
                              ? 'Tunatumia mipangilio hii kuamua ni mialiko gani na mapendekezo gani ya muundaji unayoona.'
                              : 'These toggles control which creator invites and matches you receive.',
                          style: const TextStyle(
                              fontSize: 12, color: _secondary),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _switchTile(
                        keyId: 'opt_out_sponsored',
                        icon: Icons.campaign_rounded,
                        title: s?.optOutSponsored ??
                            'Opt out of sponsored posts',
                        subtitle: s?.starLegendOnly ?? 'Star & Legend only',
                        value: _optOutSponsored,
                        onChanged: (v) => _toggle(
                          'opt_out_sponsored',
                          v,
                          (b) => _optOutSponsored = b,
                        ),
                      ),
                      _switchTile(
                        keyId: 'opt_out_collaboration',
                        icon: Icons.people_rounded,
                        title: s?.optOutCollaboration ??
                            'Opt out of collaboration suggestions',
                        subtitle: s?.collaborationRadar ?? 'Collaboration Radar',
                        value: _optOutCollaboration,
                        onChanged: (v) => _toggle(
                          'opt_out_collaboration',
                          v,
                          (b) => _optOutCollaboration = b,
                        ),
                      ),
                      _switchTile(
                        keyId: 'opt_out_battles',
                        icon: Icons.sports_mma_rounded,
                        title: s?.optOutBattles ?? 'Opt out of battles',
                        subtitle: s?.creatorBattles ?? 'Creator Battles',
                        value: _optOutBattles,
                        onChanged: (v) => _toggle(
                          'opt_out_battles',
                          v,
                          (b) => _optOutBattles = b,
                        ),
                      ),
                      _switchTile(
                        keyId: 'opt_out_threads',
                        icon: Icons.forum_rounded,
                        title: s?.optOutThreads ??
                            "Don't include my posts in threads",
                        subtitle: s?.trendingThreads ?? 'Trending Threads',
                        value: _optOutThreads,
                        onChanged: (v) => _toggle(
                          'opt_out_threads',
                          v,
                          (b) => _optOutThreads = b,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          s?.isSwahili == true
                              ? 'Mabadiliko yataonekana sehemu zote — Faragha, Mipangilio na hapa.'
                              : 'Changes apply everywhere — Privacy, Settings, and here.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: _secondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 0, 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: _primary,
          ),
        ),
      );

  Widget _switchTile({
    required String keyId,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isSaving = _saving.contains(keyId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        toggled: value,
        label: '$title. $subtitle',
        child: MergeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            elevation: 0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _iconBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _primary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _secondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isSaving)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _secondary,
                        ),
                      )
                    else
                      Switch(
                        value: value,
                        onChanged: onChanged,
                        activeTrackColor: _primary.withValues(alpha: 0.5),
                        activeThumbColor: _primary,
                      ),
                  ],
                ),
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }

  Widget _inlineErrorBanner(AppStrings? s) {
    const Color errBg = Color(0xFFFFEBEE);
    const Color errBorder = Color(0xFFEF9A9A);
    const Color errFg = Color(0xFFC62828);
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: errBg,
          border: Border.all(color: errBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, size: 18, color: errFg),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _err(s),
                style: const TextStyle(fontSize: 12, color: errFg),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Semantics(
              button: true,
              label: s?.close ?? 'Close',
              child: IconButton(
                icon: const Icon(Icons.close_rounded,
                    size: 18, color: errFg),
                onPressed: () => setState(() => _formError = null),
                style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
