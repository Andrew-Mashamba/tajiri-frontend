import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/privacy_settings_model.dart';
import '../../services/privacy_service.dart';

String _presenceLabel(String v) => privacyPresenceLabel(v);

/// Story 70: Privacy Settings — Profile visibility, who can message,
/// who can see posts, last seen visibility.
/// Navigation: Home → Profile → Settings → Faragha (Privacy).
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

  final PrivacyService _privacyService = PrivacyService();
  PrivacySettings _settings = const PrivacySettings();
  bool _isLoading = true;
  bool _isSaving = false;
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
        // Keep defaults so user can still try saving
      }
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    final result = await _privacyService.updatePrivacySettings(
      widget.currentUserId,
      _settings,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.success) {
      if (result.settings != null) {
        setState(() => _settings = result.settings!);
      }
      final s = AppStringsScope.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s?.privacySaved ?? 'Privacy settings saved'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final s = AppStringsScope.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? (s?.saveFailed ?? 'Failed to save')),
          backgroundColor: Colors.red,
        ),
      );
    }
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
      onSelect: (value) => setState(() => _settings = _settings.copyWith(profileVisibility: value)),
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
      onSelect: (value) => setState(() => _settings = _settings.copyWith(whoCanMessage: value)),
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
      onSelect: (value) => setState(() => _settings = _settings.copyWith(whoCanSeePosts: value)),
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
      onSelect: (value) => setState(() => _settings = _settings.copyWith(lastSeenVisibility: value)),
    );
  }

  void _showPresencePicker(String title, String current, ValueChanged<String> onSelect) {
    _showOptionSheet(
      title: title,
      options: [
        _Option('everyone', 'Kila mtu', ''),
        _Option('friends', 'Marafiki tu', ''),
        _Option('nobody', 'Usionyeshe', ''),
      ],
      current: current,
      onSelect: onSelect,
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
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorWithRetry()
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_error != null) _buildErrorBanner(),
                        _buildSection(
                          title: 'Uonekano wa Wasifu',
                          child: _buildSettingTile(
                            icon: Icons.person_outline,
                            title: 'Nani anaweza kuona wasifu',
                            value: privacyProfileVisibilityLabel(_settings.profileVisibility),
                            onTap: _showProfileVisibilityPicker,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          title: 'Ujumbe',
                          child: _buildSettingTile(
                            icon: Icons.message_outlined,
                            title: 'Nani anaweza kukutumia ujumbe',
                            value: privacyWhoCanMessageLabel(_settings.whoCanMessage),
                            onTap: _showWhoCanMessagePicker,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          title: 'Machapisho',
                          child: _buildSettingTile(
                            icon: Icons.article_outlined,
                            title: 'Nani anaweza kuona machapisho',
                            value: privacyWhoCanSeePostsLabel(_settings.whoCanSeePosts),
                            onTap: _showWhoCanSeePostsPicker,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          title: 'Alionekana Mwisho',
                          child: _buildSettingTile(
                            icon: Icons.schedule_outlined,
                            title: 'Onyesha "alionekana mwisho"',
                            value: privacyLastSeenLabel(_settings.lastSeenVisibility),
                            onTap: _showLastSeenPicker,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          title: 'Uonekano wa Uwepo na Hali',
                          child: Column(
                            children: [
                              _buildSettingTile(
                                icon: Icons.done_all_outlined,
                                title: 'Onyesha vilioandikiwa',
                                value: _presenceLabel(_settings.readReceiptsVisibility),
                                onTap: () => _showPresencePicker(
                                  'Onyesha vilioandikiwa',
                                  _settings.readReceiptsVisibility,
                                  (v) => setState(() => _settings = _settings.copyWith(readReceiptsVisibility: v)),
                                ),
                              ),
                              _buildSettingTile(
                                icon: Icons.circle_outlined,
                                title: 'Hali ya mtandaoni',
                                value: _presenceLabel(_settings.onlineStatusVisibility),
                                onTap: () => _showPresencePicker(
                                  'Hali ya mtandaoni',
                                  _settings.onlineStatusVisibility,
                                  (v) => setState(() => _settings = _settings.copyWith(onlineStatusVisibility: v)),
                                ),
                              ),
                              _buildSettingTile(
                                icon: Icons.photo_camera_outlined,
                                title: 'Picha ya wasifu',
                                value: _presenceLabel(_settings.profilePhotoVisibility),
                                onTap: () => _showPresencePicker(
                                  'Picha ya wasifu',
                                  _settings.profilePhotoVisibility,
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
                                  (v) => setState(() => _settings = _settings.copyWith(statusVisibility: v)),
                                ),
                              ),
                              _buildSettingTile(
                                icon: Icons.forward_outlined,
                                title: 'Nani anaweza kuwasilisha hali yako',
                                value: _presenceLabel(_settings.whoCanResendStatus),
                                onTap: () => _showPresencePicker(
                                  'Nani anaweza kuwasilisha hali yako',
                                  _settings.whoCanResendStatus,
                                  (v) => setState(() => _settings = _settings.copyWith(whoCanResendStatus: v)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: FilledButton.icon(
                              onPressed: _isSaving ? null : _saveSettings,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(_isSaving ? 'Inahifadhi...' : 'Hifadhi Mipangilio'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: const Color(0xFF1A1A1A),
                              ),
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

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _primaryText,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A).withOpacity(0.08),
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
    );
  }
}

class _Option {
  final String value;
  final String title;
  final String subtitle;

  _Option(this.value, this.title, this.subtitle);
}
