import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../widgets/tajiri_app_bar.dart';
import '../../services/local_storage_service.dart';
import '../../services/theme_notifier.dart';
import '../../services/language_notifier.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/app_strings_scope.dart';
import '../splash/splash_screen.dart';
import '../profile/edit_profile_screen.dart';
import 'profile_tabs_settings_screen.dart';
import 'username_settings_screen.dart';
import 'privacy_settings_screen.dart';
import '../../services/user_service.dart';

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

  bool _notificationsEnabled = true;
  bool _isLoadingTheme = true;
  late bool _darkMode;
  late bool _isSwahili;

  // Creator opt-out toggles
  bool _optOutSponsored = false;
  bool _optOutCollaboration = false;
  bool _optOutBattles = false;
  bool _optOutThreads = false;

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
        _optOutSponsored = storage.getBool('opt_out_sponsored') ?? false;
        _optOutCollaboration = storage.getBool('opt_out_collaboration') ?? false;
        _optOutBattles = storage.getBool('opt_out_battles') ?? false;
        _optOutThreads = storage.getBool('opt_out_threads') ?? false;
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

  Future<void> _syncPreference(String key, bool value) async {
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    if (token == null) return;
    try {
      await http.put(
        Uri.parse('${ApiConfig.baseUrl}/users/${widget.currentUserId}/preferences'),
        headers: {...ApiConfig.authHeaders(token), 'Content-Type': 'application/json'},
        body: jsonEncode({key: value}),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    if (s == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final languageLabel = _isSwahili ? s.languageSwahili : s.languageEnglish;
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: TajiriAppBar(
        title: s.settings,
        backgroundColor: _cardBackground,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(s.account),
              _buildSettingsTile(
                icon: Icons.person,
                title: s.profile,
                subtitle: s.editProfileSubtitle,
                onTap: () => _navigateToEditProfile(),
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
              _buildSwitchTile(
                icon: Icons.notifications,
                title: s.pushNotifications,
                subtitle: s.pushNotificationsSubtitle,
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
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
                subtitle: s.securitySubtitle,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mipangilio ya usalama - Inakuja hivi karibuni')),
                  );
                },
              ),

              _buildSectionHeader(s.creatorSettings),
              _buildSwitchTile(
                icon: Icons.campaign_rounded,
                title: s.optOutSponsored,
                subtitle: s.starLegendOnly,
                value: _optOutSponsored,
                onChanged: (value) async {
                  setState(() => _optOutSponsored = value);
                  final storage = await LocalStorageService.getInstance();
                  await storage.saveBool('opt_out_sponsored', value);
                  _syncPreference('opt_out_sponsored', value);
                },
              ),
              _buildSwitchTile(
                icon: Icons.people_rounded,
                title: s.optOutCollaboration,
                subtitle: s.collaborationRadar,
                value: _optOutCollaboration,
                onChanged: (value) async {
                  setState(() => _optOutCollaboration = value);
                  final storage = await LocalStorageService.getInstance();
                  await storage.saveBool('opt_out_collaboration', value);
                  _syncPreference('opt_out_collaboration', value);
                },
              ),
              _buildSwitchTile(
                icon: Icons.sports_mma_rounded,
                title: s.optOutBattles,
                subtitle: s.creatorBattles,
                value: _optOutBattles,
                onChanged: (value) async {
                  setState(() => _optOutBattles = value);
                  final storage = await LocalStorageService.getInstance();
                  await storage.saveBool('opt_out_battles', value);
                  _syncPreference('opt_out_battles', value);
                },
              ),
              _buildSwitchTile(
                icon: Icons.forum_rounded,
                title: s.optOutThreads,
                subtitle: s.trendingThreads,
                value: _optOutThreads,
                onChanged: (value) async {
                  setState(() => _optOutThreads = value);
                  final storage = await LocalStorageService.getInstance();
                  await storage.saveBool('opt_out_threads', value);
                  _syncPreference('opt_out_threads', value);
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
    final storage = await LocalStorageService.getInstance();
    await storage.logout();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    }
  }

  void _showDeleteAccountDialog(AppStrings s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteAccountConfirmTitle),
        content: Text(s.deleteAccountConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.no),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await UserService().deleteAccount(widget.currentUserId);
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.deleteAccountRequestSent)),
                );
                await _logout();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Imeshindwa kufuta akaunti')),
                );
              }
            },
            child: Text(s.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
