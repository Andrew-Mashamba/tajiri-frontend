import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../services/http_retry.dart';
import '../../../config/api_config.dart';
import '../../../l10n/app_strings_scope.dart';
import '../../../services/local_storage_service.dart';
import '_security_widgets.dart';
import 'pin_change_screen.dart';
import 'security_activity_screen.dart';
import 'sessions_screen.dart';
import 'two_factor_biometric_screen.dart';

/// Usalama (Security) — sectioned home page.
///
/// Six cards. Same pattern as Faragha + Arifa. Login alerts is the only
/// inline toggle on the home page (it's a single boolean and lives on the
/// privacy-settings document — not enough to justify its own sub-page).
class SecuritySettingsScreen extends StatefulWidget {
  final int currentUserId;
  const SecuritySettingsScreen({super.key, required this.currentUserId});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _loadingAlerts = true;
  bool _loginAlertsEnabled = false;
  bool _savingAlerts = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) {
        if (mounted) setState(() => _loadingAlerts = false);
        return;
      }
      final r = await httpGetWithRetry(
        Uri.parse('${ApiConfig.baseUrl}/users/${widget.currentUserId}/privacy-settings'),
        headers: ApiConfig.authHeaders(token),
      );
      if (!mounted) return;
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body) as Map<String, dynamic>;
        final data = (body['data'] as Map<String, dynamic>?) ?? const {};
        setState(() {
          _loginAlertsEnabled = data['login_alerts_enabled'] == true;
          _loadingAlerts = false;
        });
      } else {
        setState(() => _loadingAlerts = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingAlerts = false);
    }
  }

  Future<void> _toggleAlerts(bool value) async {
    final prev = _loginAlertsEnabled;
    setState(() {
      _savingAlerts = true;
      _loginAlertsEnabled = value;
      _formError = null;
    });
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) throw Exception('not_signed_in');
      final r = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/users/${widget.currentUserId}/privacy-settings'),
        headers: {...ApiConfig.authHeaders(token), 'Content-Type': 'application/json'},
        body: jsonEncode({'login_alerts_enabled': value}),
      );
      if (!mounted) return;
      if (r.statusCode != 200) throw Exception('save_failed');
      setState(() => _savingAlerts = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _savingAlerts = false;
        _loginAlertsEnabled = prev;
        _formError = 'save_failed';
      });
    }
  }

  void _push(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: kUsalamaBg,
        appBar: AppBar(
          title: Text(s?.security ?? 'Security'),
          backgroundColor: kUsalamaCard,
          foregroundColor: kUsalamaPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        body: SafeArea(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              UsalamaInlineErrorBanner(
                message: _formError == 'save_failed'
                    ? (s?.failedToLoadSettings ?? 'Could not save change')
                    : null,
                onDismiss: () => setState(() => _formError = null),
                closeLabel: s?.close ?? 'Close',
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                child: Text(
                  s?.usalamaHomeSubtitle ?? 'Account, devices, and security activity',
                  style: const TextStyle(fontSize: 12, color: kUsalamaSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              _navCard(
                icon: Icons.verified_user_outlined,
                title: s?.usalamaCardTwoFactorBiometric ?? 'Two-factor & biometric',
                subtitle: s?.usalamaCardTwoFactorBiometricSub ??
                    'Two-factor authentication and biometric login',
                onTap: () => _push(TwoFactorBiometricScreen(currentUserId: widget.currentUserId)),
              ),
              _navCard(
                icon: Icons.pin_outlined,
                title: s?.usalamaCardChangePin ?? 'Change PIN',
                subtitle: s?.usalamaCardChangePinSub ?? 'Sign-in PIN (same as your app lock PIN)',
                onTap: () => _push(PinChangeScreen(currentUserId: widget.currentUserId)),
              ),
              _navCard(
                icon: Icons.devices_outlined,
                title: s?.usalamaCardSessions ?? 'Active sessions',
                subtitle: s?.usalamaCardSessionsSub ?? 'Devices that are currently signed in',
                onTap: () => _push(SessionsScreen(currentUserId: widget.currentUserId)),
              ),
              _navCard(
                icon: Icons.history,
                title: s?.usalamaCardActivity ?? 'Security activity',
                subtitle: s?.usalamaCardActivitySub ?? 'History of changes and sign-ins',
                onTap: () => _push(SecurityActivityScreen(currentUserId: widget.currentUserId)),
              ),

              const SizedBox(height: 8),
              // Inline login-alerts toggle (single boolean — doesn't need its
              // own sub-page). Mirrors the same flag on the privacy-settings
              // document.
              if (_loadingAlerts)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: kUsalamaPrimary),
                    ),
                  ),
                )
              else
                UsalamaSwitchTile(
                  icon: Icons.notifications_active_outlined,
                  title: s?.usalamaCardLoginAlerts ?? 'Login alerts',
                  subtitle: s?.usalamaCardLoginAlertsSub ?? 'Get notified when a new device signs in',
                  value: _loginAlertsEnabled,
                  saving: _savingAlerts,
                  onChanged: _toggleAlerts,
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: kUsalamaCard,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: kUsalamaIconBg,
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
                            color: kUsalamaPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: kUsalamaSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: kUsalamaSecondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
