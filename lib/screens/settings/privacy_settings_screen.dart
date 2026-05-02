import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import 'privacy/_privacy_widgets.dart';
import 'privacy/profile_privacy_screen.dart';
import 'privacy/connections_privacy_screen.dart';
import 'privacy/activity_privacy_screen.dart';
import 'privacy/discovery_privacy_screen.dart';
import 'privacy/sensitive_privacy_screen.dart';
import 'privacy/security_data_screen.dart';
import 'security/sessions_screen.dart';

/// Faragha (Privacy) — sectioned home page.
///
/// Six top-level cards. Each opens a sub-page that owns a slice of the
/// privacy surface; the home page itself never writes — it only navigates.
class PrivacySettingsScreen extends StatelessWidget {
  final int currentUserId;
  const PrivacySettingsScreen({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: kFaraghaBg,
        appBar: AppBar(
          title: Text(s?.privacy ?? 'Privacy'),
          backgroundColor: kFaraghaCard,
          foregroundColor: kFaraghaPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        body: SafeArea(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              _card(
                context,
                icon: Icons.person_outline,
                title: s?.faraghaCardProfile ?? 'Profile',
                subtitle: s?.faraghaCardProfileSub ?? 'Who sees each part of your profile',
                onTap: () => _go(context, ProfilePrivacyScreen(currentUserId: currentUserId)),
              ),
              _card(
                context,
                icon: Icons.connect_without_contact_outlined,
                title: s?.faraghaCardConnections ?? 'Connections',
                subtitle: s?.faraghaCardConnectionsSub ?? 'Who can message, call, add you',
                onTap: () => _go(context, ConnectionsPrivacyScreen(currentUserId: currentUserId)),
              ),
              _card(
                context,
                icon: Icons.access_time_outlined,
                title: s?.faraghaCardActivity ?? 'Activity & presence',
                subtitle: s?.faraghaCardActivitySub ?? 'Last seen, online status, read receipts',
                onTap: () => _go(context, ActivityPrivacyScreen(currentUserId: currentUserId)),
              ),
              _card(
                context,
                icon: Icons.search_outlined,
                title: s?.faraghaCardDiscovery ?? 'Discovery',
                subtitle: s?.faraghaCardDiscoverySub ?? 'How people find you',
                onTap: () => _go(context, DiscoveryPrivacyScreen(currentUserId: currentUserId)),
              ),
              _card(
                context,
                icon: Icons.fingerprint_outlined,
                title: s?.faraghaCardSensitive ?? 'Sensitive data',
                subtitle: s?.faraghaCardSensitiveSub ?? 'Face data, biometrics, marketing',
                onTap: () => _go(context, SensitivePrivacyScreen(currentUserId: currentUserId)),
              ),
              _card(
                context,
                icon: Icons.shield_outlined,
                title: s?.faraghaCardSecurity ?? 'Security & data',
                subtitle: s?.faraghaCardSecuritySub ?? 'Sessions, 2FA, data export, delete account',
                onTap: () => _go(context, SecurityDataScreen(currentUserId: currentUserId)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _go(context, SessionsScreen(currentUserId: currentUserId)),
                child: Text(
                  s?.faraghaSessions ?? 'Active sessions',
                  style: const TextStyle(color: kFaraghaSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget _card(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: kFaraghaCard,
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
                      color: kFaraghaIconBg,
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
                            color: kFaraghaPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: kFaraghaSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: kFaraghaSecondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
