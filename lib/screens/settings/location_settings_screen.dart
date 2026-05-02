import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/location_models.dart';
import '../../services/location_service.dart';
import '../../services/profile_service.dart';
import '../../services/user_service.dart';

/// Edit a user's location (region → district → ward → street).
///
/// Uses bottom-sheet pickers (grid layout for region+district, search list
/// for ward+street). Save → invalidate ProfileService cache → pop(true).
/// Inline error banner instead of SnackBars per ENGINEERING_PLAYBOOK.md.
class LocationSettingsScreen extends StatefulWidget {
  final int currentUserId;

  const LocationSettingsScreen({super.key, required this.currentUserId});

  @override
  State<LocationSettingsScreen> createState() => _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends State<LocationSettingsScreen> {
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondary = Color(0xFF666666);

  final ProfileService _profileService = ProfileService();
  final UserService _userService = UserService();
  late final LocationService _locationService;

  // ── Data lists ──────────────────────────────────────────────────────────────
  List<Region> _regions = [];
  List<District> _districts = [];
  List<Ward> _wards = [];
  List<Street> _streets = [];

  // ── Selected values ─────────────────────────────────────────────────────────
  Region? _region;
  District? _district;
  Ward? _ward;
  Street? _street;

  // ── Loading states ──────────────────────────────────────────────────────────
  bool _loading = true;
  bool _loadingDistricts = false;
  bool _loadingWards = false;
  bool _loadingStreets = false;
  bool _saving = false;

  // ── Errors ──────────────────────────────────────────────────────────────────
  // Sentinel keys → mapped to localized text in `_localizedError`. Storing
  // a key (not a baked string) lets the UI re-render in the user's current
  // language if they toggle it while the error is showing.
  String? _loadError;     // top-of-screen, blocks the form
  String? _formError;     // inline banner above the first field
  String? _phone;

  @override
  void initState() {
    super.initState();
    _locationService = LocationService(baseUrl: ApiConfig.baseUrl);
    _loadProfileAndRegions();
  }

  // ── Profile + regions loading ───────────────────────────────────────────────

  Future<void> _loadProfileAndRegions() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    ProfileLocationLite? loc;
    try {
      final profileResult = await _profileService.getProfile(
        userId: widget.currentUserId,
        currentUserId: widget.currentUserId,
      );
      if (profileResult.success && profileResult.profile != null) {
        final p = profileResult.profile!;
        _phone = p.phoneNumber;
        if (p.location != null) {
          loc = ProfileLocationLite(
            regionName: p.location!.regionName,
            districtName: p.location!.districtName,
            wardName: p.location!.wardName,
            streetName: p.location!.streetName,
          );
        }
      } else {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _loadError = 'profile';
        });
        return;
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'profile';
      });
      return;
    }

    try {
      final regions = await _locationService.getRegions();
      if (!mounted) return;
      setState(() => _regions = regions);

      // Restore prior selection by name match.
      if (loc?.regionName != null) {
        final r = _findByName<Region>(regions, loc!.regionName!, (x) => x.name);
        if (r != null) {
          _region = r;
          await _loadDistricts(r.id, restore: loc);
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'regions');
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadDistricts(int regionId, {ProfileLocationLite? restore}) async {
    setState(() {
      _loadingDistricts = true;
      _formError = null;
    });
    try {
      final list = await _locationService.getDistricts(regionId);
      if (!mounted) return;
      setState(() {
        _districts = list;
        _loadingDistricts = false;
      });
      if (restore?.districtName != null) {
        final d = _findByName<District>(list, restore!.districtName!, (x) => x.name);
        if (d != null) {
          _district = d;
          await _loadWards(d.id, restore: restore);
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _formError = 'districts';
        _loadingDistricts = false;
      });
    }
  }

  Future<void> _loadWards(int districtId, {ProfileLocationLite? restore}) async {
    setState(() {
      _loadingWards = true;
      _formError = null;
    });
    try {
      final list = await _locationService.getWards(districtId);
      if (!mounted) return;
      setState(() {
        _wards = list;
        _loadingWards = false;
      });
      if (restore?.wardName != null) {
        final w = _findByName<Ward>(list, restore!.wardName!, (x) => x.name);
        if (w != null) {
          _ward = w;
          await _loadStreets(w.id, restore: restore);
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _formError = 'wards';
        _loadingWards = false;
      });
    }
  }

  Future<void> _loadStreets(int wardId, {ProfileLocationLite? restore}) async {
    setState(() {
      _loadingStreets = true;
      _formError = null;
    });
    try {
      final list = await _locationService.getStreets(wardId);
      if (!mounted) return;
      setState(() {
        _streets = list;
        _loadingStreets = false;
      });
      if (restore?.streetName != null) {
        final s = _findByName<Street>(list, restore!.streetName!, (x) => x.name);
        if (s != null) setState(() => _street = s);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _formError = 'streets';
        _loadingStreets = false;
      });
    }
  }

  T? _findByName<T>(List<T> list, String name, String Function(T) labelOf) {
    for (final item in list) {
      if (labelOf(item).toLowerCase() == name.toLowerCase()) return item;
    }
    return null;
  }

  // ── Pickers (bottom sheets) ─────────────────────────────────────────────────

  Future<void> _pickRegion() async {
    final s = AppStringsScope.of(context);
    final picked = await _LocationPickerSheet.show<Region>(
      context: context,
      title: s?.selectRegion ?? 'Select region',
      items: _regions,
      labelOf: (r) => r.name,
      gridLayout: true,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _region = picked;
      _district = null;
      _ward = null;
      _street = null;
      _districts = [];
      _wards = [];
      _streets = [];
      _formError = null;
    });
    await _loadDistricts(picked.id);
  }

  Future<void> _pickDistrict() async {
    final s = AppStringsScope.of(context);
    if (_districts.isEmpty || _loadingDistricts) return;
    final picked = await _LocationPickerSheet.show<District>(
      context: context,
      title: s?.selectDistrict ?? 'Select district',
      items: _districts,
      labelOf: (d) => d.name,
      gridLayout: true,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _district = picked;
      _ward = null;
      _street = null;
      _wards = [];
      _streets = [];
      _formError = null;
    });
    await _loadWards(picked.id);
  }

  Future<void> _pickWard() async {
    final s = AppStringsScope.of(context);
    if (_wards.isEmpty || _loadingWards) return;
    final picked = await _LocationPickerSheet.show<Ward>(
      context: context,
      title: s?.selectWard ?? 'Select ward',
      items: _wards,
      labelOf: (w) => w.name,
      gridLayout: false,           // ward lists can be long → use search list
      withSearch: true,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _ward = picked;
      _street = null;
      _streets = [];
      _formError = null;
    });
    await _loadStreets(picked.id);
  }

  Future<void> _pickStreet() async {
    final s = AppStringsScope.of(context);
    if (_streets.isEmpty || _loadingStreets) return;
    final picked = await _LocationPickerSheet.show<Street>(
      context: context,
      title: s?.selectStreet ?? 'Select street',
      items: _streets,
      labelOf: (st) => st.name,
      gridLayout: false,           // streets often long → use search list
      withSearch: true,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _street = picked;
      _formError = null;
    });
  }

  // ── Save ────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_region == null || _district == null) {
      setState(() => _formError = 'select_region_district');
      return;
    }
    final phone = _phone;
    if (phone == null || phone.isEmpty) {
      setState(() => _formError = 'phone_unknown');
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });
    final result = await _userService.updateProfileByPhone(phone, {
      'region_name': _region?.name,
      'district_name': _district?.name,
      'ward_name': _ward?.name,
      'street_name': _street?.name,
      'region_id': _region?.id,
      'district_id': _district?.id,
      'ward_id': _ward?.id,
      'street_id': _street?.id,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.success) {
      ProfileService.invalidate(widget.currentUserId);
      // No SnackBar. Navigation IS the confirmation (ENGINEERING_PLAYBOOK Part VI).
      Navigator.pop(context, true);
    } else {
      setState(() => _formError = result.message ?? 'save_failed');
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return GestureDetector(
      // Tap-outside dismisses the keyboard. Required HitTestBehavior.opaque
      // so the gesture fires on transparent regions (playbook Part VI).
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          title: Text(s?.editLocationTitle ?? 'Edit location'),
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
      case 'regions':
        return s?.locFailedLoadRegions ?? 'Could not load regions. Tap to try again.';
      case 'districts':
        return s?.locFailedLoadDistricts ?? 'Could not load districts. Tap to try again.';
      case 'wards':
        return s?.locFailedLoadWards ?? 'Could not load wards. Tap to try again.';
      case 'streets':
        return s?.locFailedLoadStreets ?? 'Could not load streets. Tap to try again.';
      case 'profile':
        return s?.failedToLoadProfile ?? 'Failed to load profile';
      case 'select_region_district':
        return s?.selectRegionAndDistrict ?? 'Please select a region and district';
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
                  onPressed: _loadProfileAndRegions,
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

  Widget _buildForm(dynamic s) => SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_formError != null) _buildInlineErrorBanner(s),

            // Region
            _Label(text: s?.regionLabel ?? 'Region'),
            const SizedBox(height: 6),
            _PickerField(
              icon: Icons.public_rounded,
              hint: s?.selectRegion ?? 'Select region',
              selectedLabel: _region?.name,
              loading: false,
              onTap: _pickRegion,
              onClear: () => setState(() {
                _region = null;
                _district = null;
                _ward = null;
                _street = null;
                _districts = [];
                _wards = [];
                _streets = [];
              }),
            ),

            // District
            if (_region != null) ...[
              const SizedBox(height: 16),
              _Label(text: s?.districtLabel ?? 'District'),
              const SizedBox(height: 6),
              _PickerField(
                icon: Icons.location_city_rounded,
                hint: s?.selectDistrict ?? 'Select district',
                selectedLabel: _district?.name,
                loading: _loadingDistricts,
                onTap: _districts.isEmpty ? null : _pickDistrict,
                onClear: () => setState(() {
                  _district = null;
                  _ward = null;
                  _street = null;
                  _wards = [];
                  _streets = [];
                }),
              ),
            ],

            // Ward (optional)
            if (_district != null) ...[
              const SizedBox(height: 16),
              _OptionalLabel(text: s?.wardLabel ?? 'Ward', badge: s?.optional ?? 'Optional'),
              const SizedBox(height: 6),
              _PickerField(
                icon: Icons.maps_home_work_rounded,
                hint: s?.selectWard ?? 'Select ward',
                selectedLabel: _ward?.name,
                loading: _loadingWards,
                onTap: _wards.isEmpty ? null : _pickWard,
                onClear: () => setState(() {
                  _ward = null;
                  _street = null;
                  _streets = [];
                }),
              ),
            ],

            // Street (optional)
            if (_ward != null) ...[
              const SizedBox(height: 16),
              _OptionalLabel(text: s?.streetLabel ?? 'Street', badge: s?.optional ?? 'Optional'),
              const SizedBox(height: 6),
              _PickerField(
                icon: Icons.signpost_rounded,
                hint: s?.selectStreet ?? 'Select street',
                selectedLabel: _street?.name,
                loading: _loadingStreets,
                onTap: _streets.isEmpty ? null : _pickStreet,
                onClear: () => setState(() => _street = null),
              ),
            ],

            // Summary chip
            if (_region != null && _district != null) ...[
              const SizedBox(height: 20),
              _SummaryChip(
                region: _region,
                district: _district,
                ward: _ward,
                street: _street,
              ),
            ],

            const SizedBox(height: 32),
            _SaveButton(
              saving: _saving,
              onPressed: (_region != null && _district != null) ? _save : null,
              label: s?.save ?? 'Save',
            ),
          ],
        ),
      );
}

/// Lightweight container so we can pass the previous location around the
/// initial restore chain without leaking ProfileModel imports deeper than
/// needed.
class ProfileLocationLite {
  final String? regionName;
  final String? districtName;
  final String? wardName;
  final String? streetName;
  ProfileLocationLite({this.regionName, this.districtName, this.wardName, this.streetName});
}

// ── Labels ────────────────────────────────────────────────────────────────────

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

class _OptionalLabel extends StatelessWidget {
  final String text;
  final String badge;
  const _OptionalLabel({required this.text, required this.badge});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          _Label(text: text),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
}

// ── Tappable picker field ────────────────────────────────────────────────────

class _PickerField extends StatelessWidget {
  final IconData icon;
  final String hint;
  final String? selectedLabel;
  final bool loading;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  const _PickerField({
    required this.icon,
    required this.hint,
    required this.selectedLabel,
    required this.loading,
    this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final hasValue = selectedLabel != null;
    final disabled = onTap == null && !loading;

    return Semantics(
      button: !disabled,
      label: hasValue ? '$hint: $selectedLabel' : hint,
      child: Material(
        color: disabled ? const Color(0xFFF6F6F6) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: loading || disabled ? null : onTap,
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
                  child: loading
                      ? Text(
                          s?.loading ?? 'Loading…',
                          style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
                        )
                      : Text(
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
                      style: IconButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                  )
                else if (!loading)
                  const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF666666)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Summary chip ─────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final Region? region;
  final District? district;
  final Ward? ward;
  final Street? street;
  const _SummaryChip({
    required this.region,
    required this.district,
    required this.ward,
    required this.street,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (street != null) parts.add(street!.name);
    if (ward != null) parts.add(ward!.name);
    if (district != null) parts.add(district!.name);
    if (region != null) parts.add(region!.name);
    final address = parts.join(', ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              address,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A), height: 1.4),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Save button ──────────────────────────────────────────────────────────────

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

// ── Bottom sheet picker ──────────────────────────────────────────────────────

/// Reusable picker presented as a modal bottom sheet. Grid layout for short
/// lists (regions, districts), search-then-list for longer ones (wards,
/// streets). Returns the picked item via `Navigator.pop(context, item)`.
class _LocationPickerSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) labelOf;
  final bool gridLayout;
  final bool withSearch;

  const _LocationPickerSheet({
    super.key,
    required this.title,
    required this.items,
    required this.labelOf,
    required this.gridLayout,
    this.withSearch = false,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required String Function(T) labelOf,
    required bool gridLayout,
    bool withSearch = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LocationPickerSheet<T>(
        title: title,
        items: items,
        labelOf: labelOf,
        gridLayout: gridLayout,
        withSearch: withSearch,
      ),
    );
  }

  @override
  State<_LocationPickerSheet<T>> createState() => _LocationPickerSheetState<T>();
}

class _LocationPickerSheetState<T> extends State<_LocationPickerSheet<T>> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<T> get _filtered {
    if (_query.isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items.where((i) => widget.labelOf(i).toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
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
          // Drag handle
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
          // Title row
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
          // Optional search
          if (widget.withSearch)
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
          const SizedBox(height: 4),
          // Body
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
                : widget.gridLayout
                    ? _buildGrid(scroll)
                    : _buildList(scroll),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(ScrollController scroll) {
    return GridView.builder(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.6,
      ),
      itemCount: _filtered.length,
      itemBuilder: (_, i) {
        final item = _filtered[i];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.pop(context, item),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.labelOf(item),
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
    );
  }

  Widget _buildList(ScrollController scroll) {
    return ListView.separated(
      controller: scroll,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
      itemBuilder: (_, i) {
        final item = _filtered[i];
        return InkWell(
          onTap: () => Navigator.pop(context, item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Text(
              widget.labelOf(item),
              style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}
