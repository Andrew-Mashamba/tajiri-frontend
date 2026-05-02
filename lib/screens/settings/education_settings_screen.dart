import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/profile_models.dart';
import '../../services/profile_service.dart';
import 'education/edit_alevel_screen.dart';
import 'education/edit_postsecondary_screen.dart';
import 'education/edit_primary_school_screen.dart';
import 'education/edit_secondary_school_screen.dart';
import 'education/edit_university_screen.dart';

/// Hub screen for editing the user's 5 education levels. Each tile opens
/// a dedicated sub-screen that reuses the same picker widgets the
/// registration flow uses (SchoolPicker, SecondarySchoolPicker,
/// AlevelSchoolPicker, UniversityProgrammePicker, plus an inline
/// postsecondary category+search picker), so saved data preserves the
/// full structured fields (school_id, code, type, region, combination,
/// programme_id, etc.) instead of degrading to plain text strings.
class EducationSettingsScreen extends StatefulWidget {
  final int currentUserId;

  const EducationSettingsScreen({super.key, required this.currentUserId});

  @override
  State<EducationSettingsScreen> createState() => _EducationSettingsScreenState();
}

class _EducationSettingsScreenState extends State<EducationSettingsScreen> {
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _bg = Color(0xFFFAFAFA);

  final ProfileService _profileService = ProfileService();

  bool _loading = true;
  String? _loadError;
  FullProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final result = await _profileService.getProfile(
      userId: widget.currentUserId,
      currentUserId: widget.currentUserId,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success && result.profile != null) {
        _profile = result.profile;
      } else {
        _loadError = result.message ??
            (AppStringsScope.of(context)?.failedToLoadProfile ??
                'Failed to load profile');
      }
    });
  }

  Future<void> _openEdit(Widget Function() builder) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => builder()),
    );
    if (updated == true && mounted) {
      _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(s?.editEducationTitle ?? 'Edit education'),
        backgroundColor: Colors.white,
        foregroundColor: _primary,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : _loadError != null
                ? _buildErrorState(s)
                : _buildHub(s),
      ),
    );
  }

  Widget _buildErrorState(dynamic s) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_loadError ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF666666))),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: TextButton(
                onPressed: _loadProfile,
                child: Text(s?.retry ?? 'Retry'),
              ),
            ),
          ],
        ),
      );

  Widget _buildHub(dynamic s) {
    final p = _profile;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
          child: Text(
            s?.educationHubSubtitle ?? 'Edit each level of education',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ),
        _LevelTile(
          icon: Icons.child_care_outlined,
          title: s?.primarySchoolLabel ?? 'Primary',
          subtitle: _summary(p?.primarySchool, s),
          onTap: () => _openEdit(() => EditPrimarySchoolScreen(
                currentUserId: widget.currentUserId,
              )),
        ),
        _LevelTile(
          icon: Icons.menu_book_outlined,
          title: s?.secondarySchoolLabel ?? 'O-Level',
          subtitle: _summary(p?.secondarySchool, s),
          onTap: () => _openEdit(() => EditSecondarySchoolScreen(
                currentUserId: widget.currentUserId,
              )),
        ),
        _LevelTile(
          icon: Icons.science_outlined,
          title: s?.alevelLabel ?? 'A-Level',
          subtitle: _alevelSummary(p?.alevelEducation, s),
          onTap: () => _openEdit(() => EditAlevelScreen(
                currentUserId: widget.currentUserId,
              )),
        ),
        _LevelTile(
          icon: Icons.business_center_outlined,
          title: s?.postsecondaryLabel ?? 'College',
          subtitle: _summary(p?.postsecondaryEducation, s),
          onTap: () => _openEdit(() => EditPostsecondaryScreen(
                currentUserId: widget.currentUserId,
              )),
        ),
        _LevelTile(
          icon: Icons.school_outlined,
          title: s?.universityLabel ?? 'University',
          subtitle: _universitySummary(p?.universityEducation, s),
          onTap: () => _openEdit(() => EditUniversityScreen(
                currentUserId: widget.currentUserId,
              )),
        ),
      ],
    );
  }

  String _summary(ProfileEducation? e, dynamic s) {
    if (e == null || (e.schoolName ?? '').isEmpty) {
      return s?.notSet ?? 'Not set';
    }
    final year = e.graduationYear != null
        ? ' · ${s?.classOfYear(e.graduationYear!) ?? "Class of ${e.graduationYear}"}'
        : '';
    return '${e.schoolName}$year';
  }

  String _alevelSummary(ProfileEducation? e, dynamic s) {
    if (e == null || (e.schoolName ?? '').isEmpty) {
      return s?.notSet ?? 'Not set';
    }
    final parts = <String>[e.schoolName!];
    final combo = e.combinationName ?? e.combinationCode;
    if (combo != null && combo.isNotEmpty) parts.add(combo);
    if (e.graduationYear != null) {
      parts.add(s?.classOfYear(e.graduationYear!) ?? 'Class of ${e.graduationYear}');
    }
    return parts.join(' · ');
  }

  String _universitySummary(ProfileUniversityEducation? u, dynamic s) {
    if (u == null || (u.universityName ?? '').isEmpty) {
      return s?.notSet ?? 'Not set';
    }
    final parts = <String>[u.universityName!];
    if (u.programmeName != null && u.programmeName!.isNotEmpty) {
      parts.add(u.programmeName!);
    }
    if (u.isCurrentStudent) {
      parts.add(s?.currentlyStudying ?? 'Currently studying');
    } else if (u.graduationYear != null) {
      parts.add(s?.classOfYear(u.graduationYear!) ?? 'Class of ${u.graduationYear}');
    }
    return parts.join(' · ');
  }
}

class _LevelTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LevelTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 22, color: Colors.grey.shade700),
                  ),
                  const SizedBox(width: 14),
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
                            color: Color(0xFF1A1A1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
