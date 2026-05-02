import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/notification_preferences_service.dart';
import 'notifications/_arifa_widgets.dart';
import 'notifications/category_cluster_screen.dart';
import 'notifications/quiet_hours_screen.dart';
import 'notifications/sound_vibration_screen.dart';

/// Arifa (Notifications) — sectioned home page.
///
/// Replaces the 900-line monolith. Each card opens a focused sub-page:
///   • 5 cluster screens (Communication, Business, Creator, Sensitive, System)
///     each rendering its categories with the 4 channel toggles per category.
///   • Sound & vibration sub-page for the device-level audio prefs.
///   • Quiet hours sub-page for the time-window opt-out.
///   • Reset-to-defaults action at the bottom — calls the atomic reset
///     endpoint and pops back so any open sub-page reloads on its own.
class NotificationSettingsScreen extends StatefulWidget {
  final int currentUserId;
  const NotificationSettingsScreen({super.key, required this.currentUserId});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late final NotificationPreferencesService _service;
  bool _resetting = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _service = NotificationPreferencesService(widget.currentUserId);
  }

  Future<void> _reset(AppStrings s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Semantics(liveRegion: true, child: Text(s.notifResetConfirm)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              s.notifResetDefaults,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _resetting = true;
      _formError = null;
    });
    final updated = await _service.resetToDefaults();
    if (!mounted) return;
    setState(() {
      _resetting = false;
      if (updated == null) _formError = 'save_failed';
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
          title: Text(s?.notifications ?? 'Notifications'),
          backgroundColor: kArifaCard,
          foregroundColor: kArifaPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        body: SafeArea(
          child: ListView(
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
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                child: Text(
                  s?.arifaHomeChannelsHint ?? 'Configure each category per delivery channel',
                  style: const TextStyle(fontSize: 12, color: kArifaSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              _clusterCard(
                context,
                icon: Icons.chat_bubble_outline,
                title: s?.arifaClusterCommunication ?? 'Communication',
                subtitle: s?.arifaClusterCommunicationSub ?? 'Messages, groups, calls, social',
                cluster: ArifaCluster.communication,
              ),
              _clusterCard(
                context,
                icon: Icons.storefront_outlined,
                title: s?.arifaClusterBusiness ?? 'Business',
                subtitle: s?.arifaClusterBusinessSub ?? 'Marketplace, bookings, clients',
                cluster: ArifaCluster.business,
              ),
              _clusterCard(
                context,
                icon: Icons.auto_awesome_outlined,
                title: s?.arifaClusterCreator ?? 'Creator',
                subtitle: s?.arifaClusterCreatorSub ?? 'Milestones, live streams',
                cluster: ArifaCluster.creator,
              ),
              _clusterCard(
                context,
                icon: Icons.health_and_safety_outlined,
                title: s?.arifaClusterSensitive ?? 'Sensitive',
                subtitle: s?.arifaClusterSensitiveSub ?? 'Health and money',
                cluster: ArifaCluster.sensitive,
              ),
              _clusterCard(
                context,
                icon: Icons.shield_outlined,
                title: s?.arifaClusterSystem ?? 'System',
                subtitle: s?.arifaClusterSystemSub ?? 'Security and account',
                cluster: ArifaCluster.system,
              ),

              const SizedBox(height: 8),
              _navCard(
                context,
                icon: Icons.music_note_outlined,
                title: s?.arifaCardSound ?? 'Sound & vibration',
                subtitle: s?.arifaCardSoundSub ?? 'Notification sound and vibration',
                onTap: () => _push(SoundVibrationScreen(currentUserId: widget.currentUserId)),
              ),
              _navCard(
                context,
                icon: Icons.bedtime_outlined,
                title: s?.arifaCardQuiet ?? 'Quiet hours',
                subtitle: s?.arifaCardQuietSub ?? 'Suppress notifications during a window',
                onTap: () => _push(QuietHoursScreen(currentUserId: widget.currentUserId)),
              ),

              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: TextButton.icon(
                  onPressed: (_resetting || s == null) ? null : () => _reset(s),
                  icon: _resetting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                        )
                      : const Icon(Icons.restart_alt_rounded, color: Colors.red),
                  label: Text(
                    s?.notifResetDefaults ?? 'Reset to defaults',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _push(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget _clusterCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required ArifaCluster cluster,
  }) {
    return _navCard(
      context,
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: () => _push(CategoryClusterScreen(
        currentUserId: widget.currentUserId,
        cluster: cluster,
        title: title,
      )),
    );
  }

  Widget _navCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: kArifaCard,
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
                      color: kArifaIconBg,
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
                            color: kArifaPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
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
                  const Icon(Icons.chevron_right, color: kArifaSecondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
