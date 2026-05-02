import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/education_models.dart';   // Business model + BusinessService
import '../../services/education_service.dart';
import '../../services/profile_service.dart';
import '../../services/user_service.dart';

/// Edit a user's employer / work info.
///
/// Two modes (toggle):
///   • Pick — bottom-sheet picker of registered businesses with sector
///     filter chips + search. Selecting one fills employer_id, name,
///     sector, and ownership atomically.
///   • Custom — text field for name + sector dropdown + ownership
///     dropdown. Saves with `is_custom_employer: true`.
///
/// Save → `ProfileService.invalidate(currentUserId)` → `Navigator.pop(true)`.
/// Backend's `AssignUserToDefaultGroups` job triggers on `employer_id` /
/// `employer_name` change, so the user's employer group memberships
/// update automatically (see ENGINEERING_PLAYBOOK Part VI →
/// Save→pop→refresh chain).
class WorkSettingsScreen extends StatefulWidget {
  final int currentUserId;
  const WorkSettingsScreen({super.key, required this.currentUserId});

  @override
  State<WorkSettingsScreen> createState() => _WorkSettingsScreenState();
}

enum _WorkMode { pick, custom }

class _WorkSettingsScreenState extends State<WorkSettingsScreen> {
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondary = Color(0xFF666666);

  final ProfileService _profileService = ProfileService();
  final UserService _userService = UserService();
  final BusinessService _businessService = BusinessService();
  final TextEditingController _customNameCtrl = TextEditingController();

  // ── Picker data (loaded lazily on first sheet open) ────────────────────────
  List<Business>? _allBusinesses;
  Map<String, String>? _sectorOptions;
  Map<String, String>? _ownershipOptions;

  // ── Selections ─────────────────────────────────────────────────────────────
  Business? _picked;          // when in `pick` mode
  String? _customSector;      // sector code, in `custom` mode
  String? _customOwnership;   // ownership code, in `custom` mode

  // ── State ──────────────────────────────────────────────────────────────────
  _WorkMode _mode = _WorkMode.pick;
  bool _loading = true;
  bool _saving = false;
  String? _phone;
  String? _initialName;
  String? _loadError;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _customNameCtrl.dispose();
    super.dispose();
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
        final p = result.profile!;
        _phone = p.phoneNumber;
        _initialName = p.currentEmployer?.employerName;
        _customSector = p.currentEmployer?.sector;
        _customOwnership = p.currentEmployer?.ownership;
        // We can't restore `_picked` without an id round-trip; default to
        // `pick` mode so the user re-selects, OR `custom` if there's a
        // custom name with no resolvable id (mirrors existing convention).
        if (_initialName != null && _initialName!.isNotEmpty) {
          _customNameCtrl.text = _initialName!;
        }
      } else {
        _loadError = result.message ??
            (AppStringsScope.of(context)?.failedToLoadProfile ?? 'Failed to load profile');
      }
    });
  }

  // ── Lazy loaders ───────────────────────────────────────────────────────────

  Future<List<Business>> _ensureBusinesses() async {
    if (_allBusinesses != null) return _allBusinesses!;
    _allBusinesses = await _businessService.getAll();
    return _allBusinesses!;
  }

  Future<Map<String, String>> _ensureSectors() async {
    if (_sectorOptions != null) return _sectorOptions!;
    _sectorOptions = await _businessService.getSectors();
    return _sectorOptions!;
  }

  Future<Map<String, String>> _ensureOwnership() async {
    if (_ownershipOptions != null) return _ownershipOptions!;
    _ownershipOptions = await _businessService.getOwnershipTypes();
    return _ownershipOptions!;
  }

  // ── Pickers ────────────────────────────────────────────────────────────────

  Future<void> _pickEmployer() async {
    final s = AppStringsScope.of(context);
    Map<String, String> sectors;
    List<Business> businesses;
    try {
      // Load both lazily; the picker sheet handles search/filtering.
      final results = await Future.wait([_ensureBusinesses(), _ensureSectors()]);
      businesses = results[0] as List<Business>;
      sectors = results[1] as Map<String, String>;
    } catch (_) {
      if (!mounted) return;
      setState(() => _formError = 'load_businesses');
      return;
    }
    if (!mounted) return;
    final picked = await _EmployerPickerSheet.show(
      context: context,
      title: s?.workSelectEmployer ?? 'Select employer',
      items: businesses,
      sectors: sectors,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _picked = picked;
      _customSector = picked.sector;
      _customOwnership = picked.ownership;
      _formError = null;
    });
  }

  Future<void> _pickSector() async {
    final s = AppStringsScope.of(context);
    Map<String, String> sectors;
    try {
      sectors = await _ensureSectors();
    } catch (_) {
      if (!mounted) return;
      setState(() => _formError = 'load_sectors');
      return;
    }
    if (!mounted) return;
    final code = await _StringMapPickerSheet.show(
      context: context,
      title: s?.workSelectSector ?? 'Select sector',
      options: sectors,
      gridLayout: true,
    );
    if (code != null && mounted) setState(() => _customSector = code);
  }

  Future<void> _pickOwnership() async {
    final s = AppStringsScope.of(context);
    Map<String, String> ownership;
    try {
      ownership = await _ensureOwnership();
    } catch (_) {
      if (!mounted) return;
      setState(() => _formError = 'load_ownership');
      return;
    }
    if (!mounted) return;
    final code = await _StringMapPickerSheet.show(
      context: context,
      title: s?.workSelectOwnership ?? 'Select ownership',
      options: ownership,
      gridLayout: true,
    );
    if (code != null && mounted) setState(() => _customOwnership = code);
  }

  // ── Save / clear ───────────────────────────────────────────────────────────

  Future<void> _save() async {
    final phone = _phone;
    if (phone == null || phone.isEmpty) {
      setState(() => _formError = 'phone_unknown');
      return;
    }
    Map<String, dynamic> payload;
    if (_mode == _WorkMode.pick) {
      if (_picked == null) {
        setState(() => _formError = 'employer_required');
        return;
      }
      payload = {
        'employer_id': _picked!.id,
        'employer_name': _picked!.name,
        'employer_sector': _picked!.sector,
        'employer_ownership': _picked!.ownership,
        'is_custom_employer': false,
      };
    } else {
      final name = _customNameCtrl.text.trim();
      if (name.isEmpty) {
        setState(() => _formError = 'employer_required');
        return;
      }
      payload = {
        'employer_id': null,
        'employer_name': name,
        'employer_sector': _customSector,
        'employer_ownership': _customOwnership,
        'is_custom_employer': true,
      };
    }

    setState(() {
      _saving = true;
      _formError = null;
    });
    final result = await _userService.updateProfileByPhone(phone, payload);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.success) {
      ProfileService.invalidate(widget.currentUserId);
      // No SnackBar — navigation IS the confirmation (ENGINEERING_PLAYBOOK).
      Navigator.pop(context, true);
    } else {
      setState(() => _formError = result.message ?? 'save_failed');
    }
  }

  Future<void> _clear() async {
    final s = AppStringsScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(s?.clearSectionConfirm ?? 'Remove all data for this level?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s?.cancel ?? 'Cancel'),
          ),
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
      'employer_id': null,
      'employer_name': null,
      'employer_sector': null,
      'employer_ownership': null,
      'is_custom_employer': false,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.success) {
      ProfileService.invalidate(widget.currentUserId);
      Navigator.pop(context, true);
    } else {
      setState(() => _formError = result.message ?? 'save_failed');
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          title: Text(s?.editWorkTitle ?? 'Edit work'),
          backgroundColor: Colors.white,
          foregroundColor: _primary,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _primary))
              : _loadError != null
                  ? _buildErrorState(s)
                  : _buildForm(s),
        ),
      ),
    );
  }

  /// Maps a sentinel error key to its bilingual message.
  String _localizedError(String? key, dynamic s) {
    switch (key) {
      case 'load_businesses':
        return s?.workFailedLoadBusinesses ?? 'Could not load employers. Tap to try again.';
      case 'load_sectors':
        return s?.workFailedLoadSectors ?? 'Could not load sectors. Tap to try again.';
      case 'load_ownership':
        return s?.workFailedLoadOwnership ?? 'Could not load ownership types.';
      case 'employer_required':
        return s?.workEmployerRequired ?? 'Please pick an employer or type a name';
      case 'phone_unknown':
        return s?.phoneUnknown ?? 'Phone number unknown';
      case 'save_failed':
        return s?.saveFailed ?? 'Could not save — try again.';
      default:
        return key ?? '';
    }
  }

  Widget _buildErrorState(dynamic s) => Padding(
        padding: const EdgeInsets.all(24),
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_localizedError(_loadError, s),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _secondary)),
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
        ),
      );

  Widget _buildInlineErrorBanner(dynamic s) {
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
              label: s?.close ?? 'Close',
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

  Widget _buildForm(dynamic s) {
    final hasExisting = (_initialName ?? '').isNotEmpty;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_formError != null) _buildInlineErrorBanner(s),

          // Mode toggle
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    label: s?.workPickFromList ?? 'Pick from list',
                    selected: _mode == _WorkMode.pick,
                    onTap: () => setState(() => _mode = _WorkMode.pick),
                  ),
                ),
                Expanded(
                  child: _ModeButton(
                    label: s?.workCustomEmployerToggle ?? 'Type employer name',
                    selected: _mode == _WorkMode.custom,
                    onTap: () => setState(() => _mode = _WorkMode.custom),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Mode body
          if (_mode == _WorkMode.pick) ...[
            _Label(text: s?.workEmployerLabel ?? 'Employer'),
            const SizedBox(height: 6),
            _PickerField(
              icon: Icons.business_rounded,
              hint: s?.workSelectEmployer ?? 'Select employer',
              selectedLabel: _picked?.name,
              onTap: _pickEmployer,
              onClear: () => setState(() {
                _picked = null;
                _customSector = null;
                _customOwnership = null;
              }),
            ),
            if (_picked != null) ...[
              const SizedBox(height: 12),
              _BadgeRow(
                sector: _customSector,
                sectorLabel: _sectorOptions?[_customSector ?? ''] ?? _customSector,
                ownership: _customOwnership,
                ownershipLabel: _ownershipOptions?[_customOwnership ?? ''] ?? _customOwnership,
              ),
            ],
          ] else ...[
            _Label(text: s?.employerName ?? 'Employer name'),
            const SizedBox(height: 6),
            TextField(
              controller: _customNameCtrl,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              enabled: !_saving,
              decoration: InputDecoration(
                hintText: s?.workEnterEmployerName ?? 'Type employer name',
                prefixIcon: const Icon(Icons.business_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _Label(text: s?.sectorLabel ?? 'Sector'),
            const SizedBox(height: 6),
            _PickerField(
              icon: Icons.category_rounded,
              hint: s?.workSelectSector ?? 'Select sector',
              selectedLabel: _customSector == null
                  ? null
                  : (_sectorOptions?[_customSector!] ?? _customSector),
              onTap: _pickSector,
              onClear: () => setState(() => _customSector = null),
            ),
            const SizedBox(height: 16),
            _Label(text: s?.ownershipLabel ?? 'Ownership'),
            const SizedBox(height: 6),
            _PickerField(
              icon: Icons.account_balance_rounded,
              hint: s?.workSelectOwnership ?? 'Select ownership',
              selectedLabel: _customOwnership == null
                  ? null
                  : (_ownershipOptions?[_customOwnership!] ?? _customOwnership),
              onTap: _pickOwnership,
              onClear: () => setState(() => _customOwnership = null),
            ),
          ],

          const SizedBox(height: 32),
          _SaveButton(
            saving: _saving,
            onPressed: _save,
            label: s?.save ?? 'Save',
          ),
          if (hasExisting) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: TextButton.icon(
                onPressed: _saving ? null : _clear,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: Text(
                  s?.clearSection ?? 'Clear this level',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Small UI helpers ────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF666666),
          letterSpacing: 0.3,
        ),
      );
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      )
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? const Color(0xFF1A1A1A) : const Color(0xFF666666),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
}

class _PickerField extends StatelessWidget {
  final IconData icon;
  final String hint;
  final String? selectedLabel;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  const _PickerField({
    required this.icon,
    required this.hint,
    required this.selectedLabel,
    this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final hasValue = selectedLabel != null && selectedLabel!.isNotEmpty;

    return Semantics(
      button: true,
      label: hasValue ? '$hint: $selectedLabel' : hint,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasValue
                    ? const Color(0xFF1A1A1A).withValues(alpha: 0.35)
                    : const Color(0xFFE0E0E0),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF666666)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasValue ? selectedLabel! : hint,
                    style: TextStyle(
                      fontSize: 15,
                      color: hasValue
                          ? const Color(0xFF1A1A1A)
                          : const Color(0xFFBBBBBB),
                      fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasValue && onClear != null)
                  Semantics(
                    label: s?.locClearSelectionSemantics ?? 'Clear selection',
                    button: true,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF666666)),
                      onPressed: onClear,
                      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
                    ),
                  )
                else
                  const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF666666)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  final String? sector;
  final String? sectorLabel;
  final String? ownership;
  final String? ownershipLabel;

  const _BadgeRow({
    this.sector,
    this.sectorLabel,
    this.ownership,
    this.ownershipLabel,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final hasSector = (sectorLabel ?? sector) != null;
    final hasOwn = (ownershipLabel ?? ownership) != null;
    if (!hasSector && !hasOwn) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (hasSector)
          _Badge(
            label: '${s?.workSectorBadge ?? 'Sector'}: ${sectorLabel ?? sector}',
            icon: Icons.category_outlined,
          ),
        if (hasOwn)
          _Badge(
            label: '${s?.workOwnershipBadge ?? 'Ownership'}: ${ownershipLabel ?? ownership}',
            icon: Icons.account_balance_outlined,
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Badge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE6E6E6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF666666)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
}

class _SaveButton extends StatelessWidget {
  final bool saving;
  final VoidCallback? onPressed;
  final String label;
  const _SaveButton({required this.saving, this.onPressed, required this.label});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: saving ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A1A1A),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: saving
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(label),
        ),
      );
}

// ── Bottom-sheet pickers ─────────────────────────────────────────────────────

/// Picker sheet for `Business` items with sector filter chips and search.
class _EmployerPickerSheet extends StatefulWidget {
  final String title;
  final List<Business> items;
  final Map<String, String> sectors;

  const _EmployerPickerSheet({
    required this.title,
    required this.items,
    required this.sectors,
  });

  static Future<Business?> show({
    required BuildContext context,
    required String title,
    required List<Business> items,
    required Map<String, String> sectors,
  }) {
    return showModalBottomSheet<Business>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EmployerPickerSheet(title: title, items: items, sectors: sectors),
    );
  }

  @override
  State<_EmployerPickerSheet> createState() => _EmployerPickerSheetState();
}

class _EmployerPickerSheetState extends State<_EmployerPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String? _filterSector;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Business> get _filtered {
    Iterable<Business> stream = widget.items;
    if (_filterSector != null) {
      stream = stream.where((b) => b.sector == _filterSector);
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      stream = stream.where((b) {
        final hay = '${b.name} ${b.acronym ?? ''}'.toLowerCase();
        return hay.contains(q);
      });
    }
    return stream.toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      snap: true,
      snapSizes: const [0.8, 0.95],
      builder: (_, scroll) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                Semantics(
                  label: s?.close ?? 'Close',
                  button: true,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF666666)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: TextField(
              controller: _searchCtrl,
              autofocus: false,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: '${s?.search ?? 'Search'}…',
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF666666)),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
              ),
            ),
          ),
          // Sector filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ChoiceChip(
                  label: Text(s?.viewAll ?? 'All'),
                  selected: _filterSector == null,
                  onSelected: (sel) {
                    if (sel) setState(() => _filterSector = null);
                  },
                ),
                const SizedBox(width: 6),
                ...widget.sectors.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(e.value),
                        selected: _filterSector == e.key,
                        onSelected: (sel) {
                          setState(() => _filterSector = sel ? e.key : null);
                        },
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        s?.pickerNoData ?? 'No data',
                        style: const TextStyle(color: Color(0xFF999999)),
                      ),
                    ),
                  )
                : ListView.separated(
                    controller: scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    itemBuilder: (_, i) {
                      final b = _filtered[i];
                      return InkWell(
                        onTap: () => Navigator.pop(context, b),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.acronym != null && b.acronym!.isNotEmpty
                                    ? '${b.name} (${b.acronym})'
                                    : b.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF1A1A1A),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _subtitle(b, widget.sectors),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF666666),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _subtitle(Business b, Map<String, String> sectors) {
    final parts = <String>[];
    final sectorLabel = b.sector == null ? null : (sectors[b.sector] ?? b.sector);
    if (sectorLabel != null) parts.add(sectorLabel);
    if (b.ownership != null && b.ownership!.isNotEmpty) parts.add(b.ownership!);
    if (b.region != null && b.region!.isNotEmpty) parts.add(b.region!);
    return parts.join(' · ');
  }
}

/// Generic Map<String,String> picker for sector / ownership lists.
class _StringMapPickerSheet extends StatefulWidget {
  final String title;
  final Map<String, String> options;
  final bool gridLayout;

  const _StringMapPickerSheet({
    required this.title,
    required this.options,
    required this.gridLayout,
  });

  static Future<String?> show({
    required BuildContext context,
    required String title,
    required Map<String, String> options,
    required bool gridLayout,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _StringMapPickerSheet(
        title: title,
        options: options,
        gridLayout: gridLayout,
      ),
    );
  }

  @override
  State<_StringMapPickerSheet> createState() => _StringMapPickerSheetState();
}

class _StringMapPickerSheetState extends State<_StringMapPickerSheet> {
  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final entries = widget.options.entries.toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      snap: true,
      snapSizes: const [0.7, 0.95],
      builder: (_, scroll) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                Semantics(
                  label: s?.close ?? 'Close',
                  button: true,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF666666)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.gridLayout
                ? GridView.builder(
                    controller: scroll,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.6,
                    ),
                    itemCount: entries.length,
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(context, e.key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE0E0E0)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              e.value,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1A1A1A),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : ListView.separated(
                    controller: scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      return InkWell(
                        onTap: () => Navigator.pop(context, e.key),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          child: Text(
                            e.value,
                            style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
