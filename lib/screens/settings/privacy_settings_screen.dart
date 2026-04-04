import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/privacy_settings_model.dart';
import '../../services/privacy_service.dart';
import '../../services/presence_service.dart';
import 'two_factor_screen.dart';
import 'account_protection_screen.dart';

String _presenceLabel(String v) => privacyPresenceLabel(v);

/// Story 70: Privacy Settings — Profile visibility, who can message,
/// who can see posts, last seen visibility, read receipts, online status,
/// profile photo, about, status, groups, security.
/// Navigation: Home -> Profile -> Settings -> Faragha (Privacy).
class PrivacySettingsScreen extends StatefulWidget {
  final int currentUserId;

  const PrivacySettingsScreen({super.key, required this.currentUserId});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  static const Color _backgroundLight = Color(0xFFFAFAFA);
  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);
  static const Color _cardBackground = Color(0xFFFFFFFF);

  final PrivacyService _privacyService = PrivacyService();
  PrivacySettings _settings = const PrivacySettings();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _privacyService.getPrivacySettings(widget.currentUserId);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success && result.settings != null) {
        _settings = result.settings!;
        _error = null;
      } else {
        _error = result.message;
        // Keep defaults so user can still try changing settings
      }
    });
  }

  /// Update a single preference on the backend (fire-and-forget, revert on failure).
  void _updatePreference(String key, String value, String previousValue, void Function(String) revert) {
    _privacyService.updateSinglePreference(widget.currentUserId, key, value).then((success) {
      if (!success && mounted) {
        revert(previousValue);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imeshindwa kuhifadhi mipangilio'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _showProfileVisibilityPicker() {
    final s = AppStringsScope.of(context)!;
    _showOptionSheet(
      title: s.privacyPickerProfileTitle,
      options: [
        _Option('everyone', s.privacyEveryone, s.privacyProfileSubEveryone),
        _Option('friends', s.privacyFriendsOnly, s.privacyProfileSubFriends),
        _Option('only_me', s.privacyOnlyMe, s.privacyProfileSubOnlyMe),
      ],
      current: _settings.profileVisibility,
      onSelect: (value) {
        final prev = _settings.profileVisibility;
        setState(() => _settings = _settings.copyWith(profileVisibility: value));
        _updatePreference('profile_visibility', value, prev,
            (v) => setState(() => _settings = _settings.copyWith(profileVisibility: v)));
      },
    );
  }

  void _showWhoCanMessagePicker() {
    final s = AppStringsScope.of(context)!;
    _showOptionSheet(
      title: s.privacyPickerMessageTitle,
      options: [
        _Option('everyone', s.privacyEveryone, s.privacyMessageSubEveryone),
        _Option('friends', s.privacyFriendsOnly, s.privacyMessageSubFriends),
        _Option('nobody', s.privacyNobody, s.privacyMessageSubNobody),
      ],
      current: _settings.whoCanMessage,
      onSelect: (value) {
        final prev = _settings.whoCanMessage;
        setState(() => _settings = _settings.copyWith(whoCanMessage: value));
        _updatePreference('who_can_message', value, prev,
            (v) => setState(() => _settings = _settings.copyWith(whoCanMessage: v)));
      },
    );
  }

  void _showWhoCanSeePostsPicker() {
    final s = AppStringsScope.of(context)!;
    _showOptionSheet(
      title: s.privacyPickerPostsTitle,
      options: [
        _Option('everyone', s.privacyEveryone, s.privacyPostsSubEveryone),
        _Option('friends', s.privacyFriendsOnly, s.privacyPostsSubFriends),
        _Option('only_me', s.privacyOnlyMe, s.privacyPostsSubOnlyMe),
      ],
      current: _settings.whoCanSeePosts,
      onSelect: (value) {
        final prev = _settings.whoCanSeePosts;
        setState(() => _settings = _settings.copyWith(whoCanSeePosts: value));
        _updatePreference('who_can_see_posts', value, prev,
            (v) => setState(() => _settings = _settings.copyWith(whoCanSeePosts: v)));
      },
    );
  }

  void _showLastSeenPicker() {
    final s = AppStringsScope.of(context)!;
    _showOptionSheet(
      title: s.privacyPickerLastSeenTitle,
      options: [
        _Option('everyone', s.privacyEveryone, s.privacyLastSeenSubEveryone),
        _Option('friends', s.privacyFriendsOnly, s.privacyLastSeenSubFriends),
        _Option('nobody', s.privacyLastSeenDontShow, s.privacyLastSeenSubDontShow),
      ],
      current: _settings.lastSeenVisibility,
      onSelect: (value) {
        final prev = _settings.lastSeenVisibility;
        setState(() => _settings = _settings.copyWith(lastSeenVisibility: value));
        _updatePreference('last_seen_visibility', value, prev,
            (v) => setState(() => _settings = _settings.copyWith(lastSeenVisibility: v)));
      },
    );
  }

  void _showWhoCanAddToGroupsPicker() {
    _showOptionSheet(
      title: 'Nani anaweza kuniongeza kwenye vikundi',
      options: [
        _Option('everyone', 'Kila mtu', 'Mtu yeyote anaweza kukuongeza kwenye vikundi'),
        _Option('friends', 'Marafiki tu', 'Marafiki wako pekee wanaweza kukuongeza'),
        _Option('nobody', 'Hakuna mtu', 'Hakuna mtu anayeweza kukuongeza kwenye vikundi'),
      ],
      current: _settings.whoCanAddToGroups,
      onSelect: (value) {
        final prev = _settings.whoCanAddToGroups;
        setState(() => _settings = _settings.copyWith(whoCanAddToGroups: value));
        _updatePreference('who_can_add_to_groups', value, prev,
            (v) => setState(() => _settings = _settings.copyWith(whoCanAddToGroups: v)));
      },
    );
  }

  void _showPresencePicker(String title, String current, String jsonKey, ValueChanged<String> onSelect) {
    _showOptionSheet(
      title: title,
      options: [
        _Option('everyone', 'Kila mtu', ''),
        _Option('friends', 'Marafiki tu', ''),
        _Option('nobody', 'Usionyeshe', ''),
      ],
      current: current,
      onSelect: (value) {
        final prev = current;
        onSelect(value);
        _updatePreference(jsonKey, value, prev, (v) => onSelect(v));
      },
    );
  }

  void _showOptionSheet({
    required String title,
    required List<_Option> options,
    required String current,
    required ValueChanged<String> onSelect,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _primaryText,
                ),
              ),
              const SizedBox(height: 16),
              ...options.map((opt) {
                final isSelected = current == opt.value;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      onSelect(opt.value);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  opt.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: _primaryText,
                                  ),
                                ),
                                if (opt.subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    opt.subtitle,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: _secondaryText,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check, color: _primaryText, size: 24),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundLight,
      appBar: AppBar(
        title: const Text('Faragha'),
        backgroundColor: Colors.white,
        foregroundColor: _primaryText,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _settings == const PrivacySettings()
                ? _buildErrorWithRetry()
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_error != null) _buildErrorBanner(),

                        // --- Mtu anayeona (Who can see) ---
                        _buildSectionHeader('Mtu anayeona'),
                        _buildSettingTile(
                          icon: Icons.person_outline,
                          title: 'Nani anaweza kuona wasifu',
                          value: privacyProfileVisibilityLabel(_settings.profileVisibility),
                          onTap: _showProfileVisibilityPicker,
                        ),
                        _buildSettingTile(
                          icon: Icons.schedule_outlined,
                          title: 'Mwisho kuonekana',
                          value: privacyLastSeenLabel(_settings.lastSeenVisibility),
                          onTap: _showLastSeenPicker,
                        ),
                        _buildSettingTile(
                          icon: Icons.photo_camera_outlined,
                          title: 'Picha ya wasifu',
                          value: _presenceLabel(_settings.profilePhotoVisibility),
                          onTap: () => _showPresencePicker(
                            'Picha ya wasifu',
                            _settings.profilePhotoVisibility,
                            'profile_photo_visibility',
                            (v) => setState(() => _settings = _settings.copyWith(profilePhotoVisibility: v)),
                          ),
                        ),
                        _buildSettingTile(
                          icon: Icons.info_outline,
                          title: 'Kuhusu',
                          value: _presenceLabel(_settings.aboutVisibility),
                          onTap: () => _showPresencePicker(
                            'Kuhusu',
                            _settings.aboutVisibility,
                            'about_visibility',
                            (v) => setState(() => _settings = _settings.copyWith(aboutVisibility: v)),
                          ),
                        ),
                        _buildSettingTile(
                          icon: Icons.text_snippet_outlined,
                          title: 'Hali (status)',
                          value: _presenceLabel(_settings.statusVisibility),
                          onTap: () => _showPresencePicker(
                            'Hali (status)',
                            _settings.statusVisibility,
                            'status_visibility',
                            (v) => setState(() => _settings = _settings.copyWith(statusVisibility: v)),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // --- Ujumbe (Messages) ---
                        _buildSectionHeader('Ujumbe'),
                        _buildSettingTile(
                          icon: Icons.message_outlined,
                          title: 'Nani anaweza kukutumia ujumbe',
                          value: privacyWhoCanMessageLabel(_settings.whoCanMessage),
                          onTap: _showWhoCanMessagePicker,
                        ),
                        _buildSwitchTile(
                          icon: Icons.done_all_outlined,
                          title: 'Risiti za kusoma',
                          subtitle: 'Wengine wanaona umesoma ujumbe wao',
                          value: _settings.readReceiptsVisibility != 'nobody',
                          onChanged: (enabled) {
                            final prev = _settings.readReceiptsVisibility;
                            final value = enabled ? 'everyone' : 'nobody';
                            setState(() => _settings = _settings.copyWith(readReceiptsVisibility: value));
                            _updatePreference('read_receipts_visibility', value, prev,
                                (v) => setState(() => _settings = _settings.copyWith(readReceiptsVisibility: v)));
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.circle_outlined,
                          title: 'Hali ya mtandaoni',
                          subtitle: 'Wengine wanaona upo mtandaoni',
                          value: _settings.onlineStatusVisibility != 'nobody',
                          onChanged: (enabled) {
                            final prev = _settings.onlineStatusVisibility;
                            final value = enabled ? 'everyone' : 'nobody';
                            setState(() => _settings = _settings.copyWith(onlineStatusVisibility: value));
                            // Cache locally so PresenceService.heartbeat() can check without network
                            PresenceService.cacheOnlineStatusVisibility(value);
                            _updatePreference('online_status_visibility', value, prev, (v) {
                              setState(() => _settings = _settings.copyWith(onlineStatusVisibility: v));
                              PresenceService.cacheOnlineStatusVisibility(v);
                            });
                          },
                        ),

                        const SizedBox(height: 24),

                        // --- Machapisho (Posts) ---
                        _buildSectionHeader('Machapisho'),
                        _buildSettingTile(
                          icon: Icons.article_outlined,
                          title: 'Nani anaweza kuona machapisho',
                          value: privacyWhoCanSeePostsLabel(_settings.whoCanSeePosts),
                          onTap: _showWhoCanSeePostsPicker,
                        ),
                        _buildSettingTile(
                          icon: Icons.forward_outlined,
                          title: 'Nani anaweza kuwasilisha hali yako',
                          value: _presenceLabel(_settings.whoCanResendStatus),
                          onTap: () => _showPresencePicker(
                            'Nani anaweza kuwasilisha hali yako',
                            _settings.whoCanResendStatus,
                            'who_can_resend_status',
                            (v) => setState(() => _settings = _settings.copyWith(whoCanResendStatus: v)),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // --- Vikundi (Groups) ---
                        _buildSectionHeader('Vikundi'),
                        _buildSettingTile(
                          icon: Icons.group_add_outlined,
                          title: 'Nani anaweza kuniongeza kwenye vikundi',
                          value: privacyWhoCanAddToGroupsLabel(_settings.whoCanAddToGroups),
                          onTap: _showWhoCanAddToGroupsPicker,
                        ),

                        const SizedBox(height: 24),

                        // --- Usalama (Security) ---
                        _buildSectionHeader('Usalama'),
                        _buildNavigationTile(
                          icon: Icons.security,
                          title: 'Uthibitishaji wa hatua mbili',
                          subtitle: 'Ongeza usalama wa akaunti yako',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TwoFactorScreen(
                                  currentUserId: widget.currentUserId,
                                ),
                              ),
                            );
                          },
                        ),
                        _buildNavigationTile(
                          icon: Icons.shield_outlined,
                          title: 'Ulinzi wa akaunti',
                          subtitle: 'Arifa za kuingia na vifaa vilivyoingia',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AccountProtectionScreen(
                                  currentUserId: widget.currentUserId,
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWithRetry() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Imeshindwa kupakia mipangilio',
              style: const TextStyle(color: _secondaryText, fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _loadSettings,
                child: const Text('Jaribu tena'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
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

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF1A1A1A), size: 24),
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
                          fontWeight: FontWeight.w500,
                          color: _primaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 13,
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
        shadowColor: Colors.black.withValues(alpha: 0.1),
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
                    color: const Color(0xFF1A1A1A).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF1A1A1A), size: 24),
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: _primaryText.withValues(alpha: 0.5),
                  activeThumbColor: _primaryText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationTile({
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
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF1A1A1A), size: 24),
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
                        maxLines: 2,
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
    );
  }
}

class _Option {
  final String value;
  final String title;
  final String subtitle;

  _Option(this.value, this.title, this.subtitle);
}
