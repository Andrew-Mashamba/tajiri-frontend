import 'package:flutter/material.dart';

import '../../../l10n/app_strings_scope.dart';
import '../../../models/privacy_settings_model.dart';
import '../../../services/privacy_service.dart';
import '_privacy_widgets.dart';

/// Per-field profile visibility — every column the backend currently
/// supports for "who can see this part of my profile".
class ProfilePrivacyScreen extends StatefulWidget {
  final int currentUserId;
  const ProfilePrivacyScreen({super.key, required this.currentUserId});

  @override
  State<ProfilePrivacyScreen> createState() => _ProfilePrivacyScreenState();
}

class _ProfilePrivacyScreenState extends State<ProfilePrivacyScreen> {
  final _service = PrivacyService();
  PrivacySettings _s = const PrivacySettings();
  bool _loading = true;
  String? _loadError;
  String? _formError;
  final Set<String> _saving = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final r = await _service.getPrivacySettings(widget.currentUserId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r.success && r.settings != null) {
        _s = r.settings!;
      } else {
        _loadError = 'load_failed';
      }
    });
  }

  Future<void> _saveField(String key, String value) async {
    final prev = _s;
    setState(() {
      _saving.add(key);
      _s = _s.copyWith({key: value});
      _formError = null;
    });
    final updated = await _service.patch(widget.currentUserId, {key: value});
    if (!mounted) return;
    setState(() {
      _saving.remove(key);
      if (updated == null) {
        _s = prev;
        _formError = 'save_failed';
      } else {
        _s = updated;
      }
    });
  }

  String _err(AppStrings? s) => switch (_loadError) {
        'load_failed' => s?.failedToLoadSettings ?? 'Could not load settings',
        _ => '',
      };

  String _formErr(AppStrings? s) => switch (_formError) {
        'save_failed' => s?.privacySaved == null
            ? 'Could not save change'
            : (s!.isSwahili ? 'Imeshindwa kuhifadhi mabadiliko' : 'Could not save change'),
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: kFaraghaBg,
        appBar: AppBar(
          title: Text(s?.faraghaCardProfile ?? 'Profile'),
          backgroundColor: kFaraghaCard,
          foregroundColor: kFaraghaPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: kFaraghaPrimary))
              : _loadError != null
                  ? _buildLoadError(s)
                  : ListView(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      children: [
                        FaraghaInlineErrorBanner(
                          message: _formError == null ? null : _formErr(s),
                          onDismiss: () => setState(() => _formError = null),
                          closeLabel: s?.close ?? 'Close',
                        ),
                        FaraghaSection(title: s?.privacySectionProfile ?? 'Profile visibility'),
                        _audienceTile(
                          s,
                          icon: Icons.account_circle_outlined,
                          title: s?.privacyWhoCanSeeProfile ?? 'Who can see your profile',
                          keyId: 'profile_visibility',
                          value: _s.profileVisibility,
                          opts: const ['everyone', 'friends', 'only_me'],
                          isSw: isSw,
                        ),
                        _audienceTile(
                          s,
                          icon: Icons.image_outlined,
                          title: s?.privacySectionProfile == null
                              ? 'Profile photo'
                              : (isSw ? 'Picha ya wasifu' : 'Profile photo'),
                          keyId: 'profile_photo_visibility',
                          value: _s.profilePhotoVisibility,
                          opts: const ['everyone', 'friends', 'nobody'],
                          isSw: isSw,
                        ),
                        _audienceTile(
                          s,
                          icon: Icons.info_outline,
                          title: isSw ? 'Maelezo (about)' : 'About / bio',
                          keyId: 'about_visibility',
                          value: _s.aboutVisibility,
                          opts: const ['everyone', 'friends', 'nobody'],
                          isSw: isSw,
                        ),
                        _audienceTile(
                          s,
                          icon: Icons.flag_outlined,
                          title: isSw ? 'Hali (status)' : 'Status',
                          keyId: 'status_visibility',
                          value: _s.statusVisibility,
                          opts: const ['everyone', 'friends', 'nobody'],
                          isSw: isSw,
                        ),

                        FaraghaSection(title: s?.privacyFieldsHeader ?? 'Profile fields'),
                        _audienceTile(
                          s,
                          icon: Icons.cake_outlined,
                          title: s?.privacyDob ?? 'Date of birth',
                          keyId: 'dob_visibility',
                          value: _s.dobVisibility,
                          opts: const ['everyone', 'friends', 'only_me'],
                          isSw: isSw,
                        ),
                        _audienceTile(
                          s,
                          icon: Icons.wc_outlined,
                          title: s?.privacyGenderField ?? 'Gender',
                          keyId: 'gender_visibility',
                          value: _s.genderVisibility,
                          opts: const ['everyone', 'friends', 'only_me'],
                          isSw: isSw,
                        ),
                        _audienceTile(
                          s,
                          icon: Icons.phone_outlined,
                          title: s?.privacyPhoneField ?? 'Phone number',
                          keyId: 'phone_visibility',
                          value: _s.phoneVisibility,
                          opts: const ['everyone', 'friends', 'only_me'],
                          isSw: isSw,
                        ),
                        _audienceTile(
                          s,
                          icon: Icons.alternate_email_outlined,
                          title: s?.privacyEmailField ?? 'Email',
                          keyId: 'email_visibility',
                          value: _s.emailVisibility,
                          opts: const ['everyone', 'friends', 'only_me'],
                          isSw: isSw,
                        ),
                        _audienceTile(
                          s,
                          icon: Icons.favorite_border,
                          title: s?.privacyRelationshipField ?? 'Relationship status',
                          keyId: 'relationship_visibility',
                          value: _s.relationshipVisibility,
                          opts: const ['everyone', 'friends', 'only_me'],
                          isSw: isSw,
                        ),
                        _audienceTile(
                          s,
                          icon: Icons.location_on_outlined,
                          title: s?.privacyLocationField ?? 'Location',
                          keyId: 'location_visibility',
                          value: _s.locationVisibility,
                          opts: const ['everyone', 'friends', 'only_me'],
                          isSw: isSw,
                        ),
                        _audienceTile(
                          s,
                          icon: Icons.school_outlined,
                          title: s?.privacyEducationField ?? 'Education',
                          keyId: 'education_visibility',
                          value: _s.educationVisibility,
                          opts: const ['everyone', 'friends', 'only_me'],
                          isSw: isSw,
                        ),
                        _audienceTile(
                          s,
                          icon: Icons.work_outline,
                          title: s?.privacyEmployerField ?? 'Employer',
                          keyId: 'employer_visibility',
                          value: _s.employerVisibility,
                          opts: const ['everyone', 'friends', 'only_me'],
                          isSw: isSw,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildLoadError(AppStrings? s) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                _err(s),
                style: const TextStyle(color: kFaraghaSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                child: Text(s?.retry ?? 'Retry'),
              ),
            ],
          ),
        ),
      );

  FaraghaAudienceTile _audienceTile(
    AppStrings? s, {
    required IconData icon,
    required String title,
    required String keyId,
    required String value,
    required List<String> opts,
    required bool isSw,
  }) =>
      FaraghaAudienceTile(
        icon: icon,
        title: title,
        value: value,
        saving: _saving.contains(keyId),
        allowedOptions: opts,
        onChanged: (v) => _saveField(keyId, v),
        isSwahili: isSw,
      );
}
