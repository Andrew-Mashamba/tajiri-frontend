import 'package:flutter/material.dart';
import '../../widgets/tajiri_app_bar.dart';
import '../../services/local_storage_service.dart';
import '../../services/theme_notifier.dart';
import '../../services/language_notifier.dart';
import '../../l10n/app_strings_scope.dart';
import '../profile/edit_profile_screen.dart';
import 'profile_tabs_settings_screen.dart';
import 'username_settings_screen.dart';
import 'email_settings_screen.dart';
import 'location_settings_screen.dart';
import 'education_settings_screen.dart';
import 'work_settings_screen.dart';
import 'phone_settings_screen.dart';
import 'nida_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'security/security_settings_screen.dart';
import 'notification_settings_screen.dart';
import '../../creator/screens/settings_screen.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';

/// Settings screen. Navigation: Home → Profile → ⚙ Settings → SettingsScreen (STORY-69).
/// Sections: Account, Notifications, Privacy, Display (with theme toggle Light/Dark).
class SettingsScreen extends StatefulWidget {
  final int currentUserId;

  const SettingsScreen({super.key, required this.currentUserId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _minTouchTargetHeight = 48.0;
  static const _primaryText = Color(0xFF1A1A1A);
  static const _secondaryText = Color(0xFF666666);
  static const _backgroundColor = Color(0xFFFAFAFA);
  static const _cardBackground = Color(0xFFFFFFFF);
  static const _iconBackground = Color(0xFF1A1A1A);

  bool _isLoadingTheme = true;
  bool _darkMode = false;
  bool _isSwahili = true;
  bool _isDeleting = false;
  // Sentinel error key — mapped to bilingual text in `_localizedError`.
  // Replaces all SnackBars per ENGINEERING_PLAYBOOK.md → Inline feedback.
  String? _formError;

  // Creator opt-out toggles moved to lib/screens/profile/creator_settings_screen.dart
  // (single canonical home; this Settings screen now links to it via a tile).

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final storage = await LocalStorageService.getInstance();
    if (mounted) {
      setState(() {
        _darkMode = storage.getThemeMode() == ThemeMode.dark;
        _isSwahili = storage.getLanguageCode() == 'sw';
        _isLoadingTheme = false;
      });
    }
  }

  Future<void> _onThemeToggle(bool value) async {
    setState(() => _darkMode = value);
    final mode = value ? ThemeMode.dark : ThemeMode.light;
    final storage = await LocalStorageService.getInstance();
    await storage.saveThemeMode(mode);
    ThemeNotifier.setThemeMode(mode);
  }

  String _localizedError(String? key, AppStrings s) {
    switch (key) {
      case 'sync_failed':
        return s.preferenceSyncFailed;
      case 'biometric_failed':
        return s.biometricFailure;
      case 'delete_failed':
        return s.deleteAccountFailure;
      default:
        return key ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    if (s == null || _isLoadingTheme) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final languageLabel = _isSwahili ? s.languageSwahili : s.languageEnglish;
    return GestureDetector(
      // Tap outside the inline banner / lists dismisses any focused field
      // (defence-in-depth — Settings has no TextField today, but this
      // matches the playbook page-chrome rule for every screen).
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      backgroundColor: _backgroundColor,
      appBar: TajiriAppBar(
        title: s.settings,
        backgroundColor: _cardBackground,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_formError != null) _buildInlineErrorBanner(s),
              _buildSectionHeader(s.account),
              _buildSettingsTile(
                icon: Icons.person,
                title: s.profile,
                subtitle: s.editProfileSubtitle,
                onTap: () => _navigateToEditProfile(),
              ),
              _buildSettingsTile(
                icon: Icons.phone_outlined,
                title: s.phoneNumber,
                subtitle: _isSwahili
                    ? 'Tazama namba ya akaunti yako'
                    : 'View your account phone number',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PhoneSettingsScreen(
                        currentUserId: widget.currentUserId,
                      ),
                    ),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.badge_outlined,
                title: 'NIDA',
                subtitle: _isSwahili
                    ? 'Hifadhi namba yako ya kitambulisho'
                    : 'Save your National ID number',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NidaSettingsScreen(
                        currentUserId: widget.currentUserId,
                      ),
                    ),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.email_outlined,
                title: s.email,
                subtitle: s.editEmailTitle,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmailSettingsScreen(currentUserId: widget.currentUserId),
                    ),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.location_on_outlined,
                title: s.location,
                subtitle: s.editLocationTitle,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LocationSettingsScreen(currentUserId: widget.currentUserId),
                    ),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.school_outlined,
                title: s.aboutEducationSection,
                subtitle: s.editEducationTitle,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EducationSettingsScreen(currentUserId: widget.currentUserId),
                    ),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.work_outline,
                title: s.aboutWorkSection,
                subtitle: s.editWorkTitle,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkSettingsScreen(currentUserId: widget.currentUserId),
                    ),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.alternate_email,
                title: s.username,
                subtitle: s.usernameSubtitle,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UsernameSettingsScreen(
                        currentUserId: widget.currentUserId,
                      ),
                    ),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.tab,
                title: s.profileTabs,
                subtitle: s.profileTabsSubtitle,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileTabsSettingsScreen(),
                    ),
                  );
                },
              ),
              _buildSectionHeader(s.notifications),
              _buildSettingsTile(
                icon: Icons.notifications_outlined,
                title: s.notifications,
                subtitle: s.notificationsSubtitle,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NotificationSettingsScreen(
                        currentUserId: widget.currentUserId,
                      ),
                    ),
                  );
                },
              ),

              _buildSectionHeader(s.privacy),
              _buildSettingsTile(
                icon: Icons.lock,
                title: s.privacy,
                subtitle: s.privacySubtitle,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PrivacySettingsScreen(currentUserId: widget.currentUserId),
                    ),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.security,
                title: s.security,
                subtitle: s.usalamaHomeSubtitle,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SecuritySettingsScreen(
                        currentUserId: widget.currentUserId,
                      ),
                    ),
                  );
                },
              ),
              _buildSectionHeader(s.creatorSettings),
              _buildSettingsTile(
                icon: Icons.auto_awesome_rounded,
                title: s.creatorSettings,
                subtitle: s.isSwahili
                    ? 'Mialiko, mashindano, ushirikiano, na ulinganishi'
                    : 'Invites, battles, collaboration, and matching',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreatorSettingsScreen(
                        currentUserId: widget.currentUserId,
                      ),
                    ),
                  );
                },
              ),

              _buildSectionHeader(s.display),
              _buildThemeToggleTile(s),
              _buildSettingsTile(
                icon: Icons.language,
                title: s.language,
                subtitle: languageLabel,
                onTap: () => _showLanguageDialog(),
              ),

              const SizedBox(height: 24),
              _buildActionButton(
                icon: Icons.devices,
                label: s.logoutAllDevices,
                isDestructive: true,
                onPressed: () => _showLogoutAllDevicesDialog(s),
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                icon: Icons.logout,
                label: s.logout,
                isDestructive: true,
                onPressed: () => _showLogoutDialog(s),
              ),
              const SizedBox(height: 8),
              _buildTextButton(
                label: s.deleteAccount,
                onPressed: () => _showDeleteAccountDialog(s),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  s.appVersion,
                  style: const TextStyle(
                    color: _secondaryText,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildInlineErrorBanner(AppStrings s) {
    final message = _localizedError(_formError, s);
    if (message.isEmpty) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 20, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13, color: Colors.red),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Semantics(
              label: s.close,
              button: true,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.red),
                onPressed: () => setState(() => _formError = null),
                style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: _primaryText,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        label: '$title. $subtitle',
        child: MergeSemantics(
          child: Material(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
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
                      color: _iconBackground,
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
                            color: _primaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _secondaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: _secondaryText),
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

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        toggled: value,
        label: '$title. $subtitle',
        child: MergeSemantics(
          child: Material(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
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
                    color: _iconBackground,
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
                          color: _primaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: _primaryText.withOpacity(0.5),
                  activeThumbColor: _primaryText,
                ),
              ],
            ),
          ),
        ),
      ),
        ),
      ),
    );
  }

  Widget _buildThemeToggleTile(AppStrings s) {
    if (_isLoadingTheme) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: _cardBackground,
          borderRadius: BorderRadius.circular(16),
          elevation: 2,
          child: const SizedBox(
            height: 72,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }
    return _buildSwitchTile(
      icon: Icons.dark_mode,
      title: s.darkMode,
      subtitle: _darkMode ? s.darkModeSubtitleDark : s.darkModeSubtitleLight,
      value: _darkMode,
      onChanged: _onThemeToggle,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : _primaryText;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: _minTouchTargetHeight),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(color: Colors.red, fontSize: 14),
        ),
      ),
    );
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          currentUserId: widget.currentUserId,
          initialProfile: null,
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    final s = AppStringsScope.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.chooseLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(s.languageEnglish),
              value: 'en',
              groupValue: _isSwahili ? 'sw' : 'en',
              onChanged: (value) async {
                if (value == 'en') {
                  final storage = await LocalStorageService.getInstance();
                  await storage.saveLanguageCode('en');
                  LanguageNotifier.setLanguage('en');
                  if (mounted) setState(() => _isSwahili = false);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: Text(s.languageSwahili),
              value: 'sw',
              groupValue: _isSwahili ? 'sw' : 'en',
              onChanged: (value) async {
                if (value == 'sw') {
                  final storage = await LocalStorageService.getInstance();
                  await storage.saveLanguageCode('sw');
                  LanguageNotifier.setLanguage('sw');
                  if (mounted) setState(() => _isSwahili = true);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutAllDevicesDialog(AppStrings s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.logoutConfirmTitle),
        content: Text(s.logoutAllDevicesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.no),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (mounted) {
                await AuthService.instance.logoutAllDevices(context);
              }
            },
            child: Text(
              s.yesLogout,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(AppStrings s) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.logoutConfirmTitle),
        content: Text(s.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.no),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _logout();
            },
            child: Text(s.yes, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    if (mounted) {
      await AuthService.instance.logout(context);
    }
  }

  Future<void> _showDeleteAccountDialog(AppStrings s) async {
    final authorized = await BiometricService.authenticate(
      reason: 'Thibitisha ni wewe kubadilisha mipangilio ya akaunti',
    );
    if (!authorized) {
      // Per ENGINEERING_PLAYBOOK: no SnackBars. Surface inline at the
      // top of the page so the user has time to read it.
      if (mounted) setState(() => _formError = 'biometric_failed');
      return;
    }

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(s.deleteAccountConfirmTitle),
          content: Text(s.deleteAccountConfirmMessage),
          actions: [
            TextButton(
              onPressed: _isDeleting ? null : () => Navigator.pop(ctx),
              child: Text(s.no),
            ),
            TextButton(
              onPressed: _isDeleting
                  ? null
                  : () async {
                      setDialogState(() {});
                      setState(() => _isDeleting = true);
                      final success = await UserService().deleteAccount(widget.currentUserId);
                      if (!mounted) return;
                      setState(() => _isDeleting = false);
                      if (success) {
                        // Pop dialog, then navigation away (logout to login
                        // screen) IS the confirmation. No SnackBar.
                        if (Navigator.canPop(ctx)) Navigator.pop(ctx);
                        await _logout();
                      } else {
                        // Pop dialog, surface inline error on the Settings page.
                        if (Navigator.canPop(ctx)) Navigator.pop(ctx);
                        if (mounted) setState(() => _formError = 'delete_failed');
                      }
                    },
              child: _isDeleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.red,
                      ),
                    )
                  : Text(s.delete, style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
