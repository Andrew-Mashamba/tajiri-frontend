import 'package:flutter/material.dart';
import '../../../l10n/app_strings_scope.dart';
import '../../../models/education_models.dart';
import '../../../models/profile_models.dart';
import '../../../services/education_service.dart';
import '../../../services/profile_service.dart';
import '../../../services/user_service.dart';
import 'shared/edit_education_chrome.dart';

/// Edit a user's postsecondary (College/Diploma/VETA) institution.
/// Replicates the inline picker pattern from the registration step:
/// category chips + free-text search → institution list → year picker.
/// Saves with `postsecondary_id`, `postsecondary_name`, and start/grad
/// years so the structured fields the registration step captured aren't
/// silently downgraded to a name-only string.
class EditPostsecondaryScreen extends StatefulWidget {
  final int currentUserId;
  const EditPostsecondaryScreen({super.key, required this.currentUserId});

  @override
  State<EditPostsecondaryScreen> createState() => _EditPostsecondaryScreenState();
}

class _EditPostsecondaryScreenState extends State<EditPostsecondaryScreen> {
  final PostsecondaryService _service = PostsecondaryService();
  final ProfileService _profileService = ProfileService();
  final UserService _userService = UserService();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _loadingInstitutions = false;
  bool _searching = false;
  String? _phone;
  String? _loadError;
  ProfileEducation? _initial;

  Map<String, String> _categories = {};
  String? _selectedCategory;
  List<PostsecondaryInstitution> _institutions = [];
  PostsecondaryInstitution? _selected;
  int? _startYear;
  int? _gradYear;

  @override
  void initState() {
    super.initState();
    _loadProfileAndCategories();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfileAndCategories() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        _profileService.getProfile(
          userId: widget.currentUserId,
          currentUserId: widget.currentUserId,
        ),
        _service.getCategories(),
      ]);
      if (!mounted) return;
      final profileResult = results[0] as ProfileResult;
      final cats = results[1] as Map<String, String>;
      setState(() {
        _loading = false;
        _categories = cats;
        if (profileResult.success && profileResult.profile != null) {
          _phone = profileResult.profile!.phoneNumber;
          _initial = profileResult.profile!.postsecondaryEducation;
          _gradYear = _initial?.graduationYear;
        } else {
          _loadError = profileResult.message ??
              (AppStringsScope.of(context)?.failedToLoadProfile ?? 'Failed to load profile');
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = AppStringsScope.of(context)?.failedToLoadProfile ?? 'Failed to load profile';
      });
    }
  }

  Future<void> _loadByCategory(String category) async {
    setState(() {
      _loadingInstitutions = true;
      _selected = null;
    });
    try {
      final list = await _service.getByCategory(category);
      if (!mounted) return;
      setState(() {
        _institutions = list;
        _loadingInstitutions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingInstitutions = false);
    }
  }

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() {
        _institutions = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    try {
      final list = await _service.search(query);
      if (!mounted) return;
      setState(() {
        _institutions = list;
        _searching = false;
        _selectedCategory = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _searching = false);
    }
  }

  Future<void> _save() async {
    final s = AppStringsScope.of(context);
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.pleaseSelectInstitution ?? 'Please pick an institution first')),
      );
      return;
    }
    if (_phone == null) return;
    setState(() => _saving = true);
    final result = await _userService.updateProfileByPhone(_phone!, {
      'postsecondary_id': _selected!.id,
      'postsecondary_name': _selected!.name,
      'postsecondary_start_year': _startYear,
      'postsecondary_graduation_year': _gradYear,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.success) {
      ProfileService.invalidate(widget.currentUserId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.profileSaved ?? 'Profile saved')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? (s?.saveFailed ?? 'Failed to save'))),
      );
    }
  }

  Future<void> _clear() async {
    final s = AppStringsScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(s?.clearSectionConfirm ?? 'Remove all data for this level?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s?.cancel ?? 'Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s?.delete ?? 'Delete', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted || _phone == null) return;
    setState(() => _saving = true);
    final result = await _userService.updateProfileByPhone(_phone!, {
      'postsecondary_id': null,
      'postsecondary_name': null,
      'postsecondary_start_year': null,
      'postsecondary_graduation_year': null,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.success) {
      ProfileService.invalidate(widget.currentUserId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.cleared ?? 'Cleared')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? (s?.saveFailed ?? 'Failed to save'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return EditEducationChrome(
      title: s?.editPostsecondaryTitle ?? 'Edit College / Diploma',
      loading: _loading,
      loadError: _loadError,
      onRetry: _loadProfileAndCategories,
      saving: _saving,
      onSave: _save,
      hasExisting: (_initial?.schoolName ?? '').isNotEmpty,
      onClear: _clear,
      currentSummary: _summary(s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Once an institution is picked, hide the search + category +
          // list and show only the selected card. Tapping its X starts
          // over (the chrome's Clear button is the destructive "remove
          // saved data" path; X here just changes the picker selection).
          if (_selected != null) ...[
            _buildSelectedInstitutionCard(s),
            const SizedBox(height: 16),
            YearRow(
              startYear: _startYear,
              gradYear: _gradYear,
              onStartChanged: (v) => setState(() => _startYear = v),
              onGradChanged: (v) => setState(() => _gradYear = v),
            ),
          ] else ...[
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: '${s?.search ?? 'Search'}...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {
                              _institutions = [];
                              _selected = null;
                            });
                          },
                        )
                      : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: _search,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.entries.map((e) {
              final isSelected = _selectedCategory == e.key;
              return ChoiceChip(
                label: Text(e.value),
                selected: isSelected,
                onSelected: (sel) {
                  if (sel) {
                    setState(() {
                      _selectedCategory = e.key;
                      _searchCtrl.clear();
                    });
                    _loadByCategory(e.key);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          if (_loadingInstitutions)
            const Center(child: CircularProgressIndicator())
          else if (_institutions.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 280),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _institutions.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (ctx, i) {
                  final inst = _institutions[i];
                  final isSelected = _selected?.id == inst.id;
                  return ListTile(
                    title: Text(
                      inst.displayName,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      inst.categoryLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFF1A1A1A))
                        : null,
                    onTap: () => setState(() => _selected = inst),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedInstitutionCard(dynamic s) {
    final inst = _selected!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: Color(0xFF1A1A1A), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  inst.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  inst.categoryLabel,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Semantics(
            label: s?.pickerClearSelection ?? 'Clear selection',
            child: IconButton(
              icon: const Icon(Icons.close,
                  size: 20, color: Color(0xFF1A1A1A)),
              onPressed: () => setState(() => _selected = null),
              style: IconButton.styleFrom(
                minimumSize: const Size(48, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _summary(dynamic s) {
    if (_initial == null || (_initial!.schoolName ?? '').isEmpty) return null;
    final year = _initial!.graduationYear != null
        ? ' · ${s?.classOfYear(_initial!.graduationYear!) ?? "Class of ${_initial!.graduationYear}"}'
        : '';
    return '${_initial!.schoolName}$year';
  }
}
