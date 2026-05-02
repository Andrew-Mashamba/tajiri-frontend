import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_strings_scope.dart';
import '../../../services/security_service.dart';
import '_security_widgets.dart';

class SessionsScreen extends StatefulWidget {
  final int currentUserId;
  const SessionsScreen({super.key, required this.currentUserId});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  final _service = SecurityService();
  List<SessionInfo> _sessions = const [];
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final list = await _service.sessions(widget.currentUserId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _sessions = list;
    });
  }

  Future<void> _revokeOne(SessionInfo s, AppStringsExt strings) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await _service.revokeSession(s.id);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) {
        _sessions = _sessions.where((x) => x.id != s.id).toList();
      } else {
        _error = strings.failedToLoadSettings;
      }
    });
  }

  Future<void> _revokeAll(AppStringsExt strings) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.usalamaRevokeAll),
        content: Semantics(liveRegion: true, child: Text(strings.usalamaRevokeAllConfirm)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.usalamaRevokeAll, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    final ok = await _service.revokeAllSessions(widget.currentUserId);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) {
        _sessions = _sessions.where((x) => x.isCurrent).toList();
        _info = strings.usalamaRevokeAll;
      } else {
        _error = strings.failedToLoadSettings;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final strings = AppStringsExt(s);
    final df = DateFormat('MMM d, yyyy HH:mm');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: kUsalamaBg,
        appBar: AppBar(
          title: Text(strings.usalamaCardSessions),
          backgroundColor: kUsalamaCard,
          foregroundColor: kUsalamaPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: kUsalamaPrimary))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    children: [
                      UsalamaInlineErrorBanner(
                        message: _error,
                        onDismiss: () => setState(() => _error = null),
                        closeLabel: strings.close,
                      ),
                      UsalamaInlineSuccessBanner(
                        message: _info,
                        onDismiss: () => setState(() => _info = null),
                        closeLabel: strings.close,
                      ),
                      if (_sessions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            strings.usalamaSessionsEmpty,
                            style: const TextStyle(fontSize: 12, color: kUsalamaSecondary),
                          ),
                        )
                      else
                        ..._sessions.map((sess) => _sessionTile(sess, strings, df)),
                      if (_sessions.where((s) => !s.isCurrent).isNotEmpty) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : () => _revokeAll(strings),
                            icon: const Icon(Icons.logout, color: Colors.red),
                            label: Text(
                              strings.usalamaRevokeAll,
                              style: const TextStyle(color: Colors.red),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _sessionTile(SessionInfo sess, AppStringsExt strings, DateFormat df) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: kUsalamaCard,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: sess.isCurrent
                      ? Colors.green.withValues(alpha: 0.15)
                      : kUsalamaIconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  sess.isMobile ? Icons.phone_android : Icons.computer,
                  color: sess.isCurrent ? Colors.green : Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            sess.deviceName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kUsalamaPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (sess.isCurrent) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              strings.usalamaSessionCurrent,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sess.lastActiveAt != null
                          ? df.format(sess.lastActiveAt!.toLocal())
                          : '—',
                      style: const TextStyle(fontSize: 12, color: kUsalamaSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!sess.isCurrent)
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.red, size: 20),
                  tooltip: strings.usalamaSessionRevoke,
                  onPressed: _busy ? null : () => _revokeOne(sess, strings),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tiny adapter so we can read AppStrings nullably without scattering ?? all over.
class AppStringsExt {
  final dynamic _s;
  AppStringsExt(this._s);

  String get cancel => _s?.cancel ?? 'Cancel';
  String get close => _s?.close ?? 'Close';
  String get failedToLoadSettings => _s?.failedToLoadSettings ?? 'Action failed';
  String get usalamaCardSessions => _s?.usalamaCardSessions ?? 'Active sessions';
  String get usalamaSessionCurrent => _s?.usalamaSessionCurrent ?? 'This device';
  String get usalamaSessionRevoke => _s?.usalamaSessionRevoke ?? 'Sign out';
  String get usalamaSessionsEmpty => _s?.usalamaSessionsEmpty ?? 'No other devices';
  String get usalamaRevokeAll => _s?.usalamaRevokeAll ?? 'Sign out all other devices';
  String get usalamaRevokeAllConfirm => _s?.usalamaRevokeAllConfirm ?? 'All other devices will be signed out.';
}
