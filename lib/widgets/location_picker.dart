import 'package:flutter/material.dart';
import '../models/location_models.dart';
import '../services/location_service.dart';

class LocationPicker extends StatefulWidget {
  final LocationService locationService;
  final ValueChanged<UserLocation>? onLocationChanged;
  final UserLocation? initialLocation;

  const LocationPicker({
    super.key,
    required this.locationService,
    this.onLocationChanged,
    this.initialLocation,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  // Data lists
  List<Region> _regions = [];
  List<District> _districts = [];
  List<Ward> _wards = [];
  List<Street> _streets = [];

  // Selected values
  Region? _selectedRegion;
  District? _selectedDistrict;
  Ward? _selectedWard;
  Street? _selectedStreet;

  // Loading states
  bool _loadingRegions = true;
  bool _loadingDistricts = false;
  bool _loadingWards = false;
  bool _loadingStreets = false;

  // Error message
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  Future<void> _loadRegions() async {
    setState(() {
      _loadingRegions = true;
      _error = null;
    });

    try {
      final regions = await widget.locationService.getRegions();
      if (!mounted) return;
      setState(() {
        _regions = regions;
        _loadingRegions = false;
      });

      // If initial location is provided and we have regions, set it
      if (widget.initialLocation?.region != null && regions.isNotEmpty) {
        final initialRegion = regions.firstWhere(
          (r) => r.id == widget.initialLocation!.region!.id,
          orElse: () => regions.first,
        );
        _onRegionChanged(initialRegion);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Imeshindwa kupakia mikoa: ${e.toString()}';
        _loadingRegions = false;
      });
    }
  }

  Future<void> _onRegionChanged(Region? region) async {
    setState(() {
      _selectedRegion = region;
      _selectedDistrict = null;
      _selectedWard = null;
      _selectedStreet = null;
      _districts = [];
      _wards = [];
      _streets = [];
    });

    _notifyChange();

    if (region == null) return;

    setState(() => _loadingDistricts = true);

    try {
      final districts = await widget.locationService.getDistricts(region.id);
      if (!mounted) return;
      setState(() {
        _districts = districts;
        _loadingDistricts = false;
      });

      // If initial location is provided, set district
      if (widget.initialLocation?.district != null) {
        final initialDistrict = districts.firstWhere(
          (d) => d.id == widget.initialLocation!.district!.id,
          orElse: () => districts.first,
        );
        _onDistrictChanged(initialDistrict);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Imeshindwa kupakia wilaya';
        _loadingDistricts = false;
      });
    }
  }

  Future<void> _onDistrictChanged(District? district) async {
    setState(() {
      _selectedDistrict = district;
      _selectedWard = null;
      _selectedStreet = null;
      _wards = [];
      _streets = [];
    });

    _notifyChange();

    if (district == null) return;

    setState(() => _loadingWards = true);

    try {
      final wards = await widget.locationService.getWards(district.id);
      if (!mounted) return;
      setState(() {
        _wards = wards;
        _loadingWards = false;
      });

      // If initial location is provided, set ward
      if (widget.initialLocation?.ward != null) {
        final initialWard = wards.firstWhere(
          (w) => w.id == widget.initialLocation!.ward!.id,
          orElse: () => wards.first,
        );
        _onWardChanged(initialWard);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Imeshindwa kupakia kata';
        _loadingWards = false;
      });
    }
  }

  Future<void> _onWardChanged(Ward? ward) async {
    setState(() {
      _selectedWard = ward;
      _selectedStreet = null;
      _streets = [];
    });

    _notifyChange();

    if (ward == null) return;

    setState(() => _loadingStreets = true);

    try {
      final streets = await widget.locationService.getStreets(ward.id);
      if (!mounted) return;
      setState(() {
        _streets = streets;
        _loadingStreets = false;
      });

      // If initial location is provided, set street
      if (widget.initialLocation?.street != null) {
        final initialStreet = streets.firstWhere(
          (s) => s.id == widget.initialLocation!.street!.id,
          orElse: () => streets.first,
        );
        _onStreetChanged(initialStreet);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Imeshindwa kupakia mitaa';
        _loadingStreets = false;
      });
    }
  }

  void _onStreetChanged(Street? street) {
    setState(() => _selectedStreet = street);
    _notifyChange();
  }

  void _notifyChange() {
    widget.onLocationChanged?.call(
      UserLocation(
        region: _selectedRegion,
        district: _selectedDistrict,
        ward: _selectedWard,
        street: _selectedStreet,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Error message (monochrome per DESIGN.md)
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF999999).withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: _primaryText, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: _primaryText,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _loadRegions,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.refresh, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Region dropdown
        _buildDropdown<Region>(
          label: 'Mkoa (Region)',
          hint: 'Chagua Mkoa',
          value: _selectedRegion,
          items: _regions,
          isLoading: _loadingRegions,
          onChanged: _onRegionChanged,
          itemLabel: (r) => r.name,
        ),

        const SizedBox(height: 16),

        // District dropdown
        _buildDropdown<District>(
          label: 'Wilaya (District)',
          hint: 'Chagua Wilaya',
          value: _selectedDistrict,
          items: _districts,
          isLoading: _loadingDistricts,
          enabled: _selectedRegion != null,
          onChanged: _onDistrictChanged,
          itemLabel: (d) => d.name,
        ),

        const SizedBox(height: 16),

        // Ward dropdown
        _buildDropdown<Ward>(
          label: 'Kata (Ward)',
          hint: 'Chagua Kata',
          value: _selectedWard,
          items: _wards,
          isLoading: _loadingWards,
          enabled: _selectedDistrict != null,
          onChanged: _onWardChanged,
          itemLabel: (w) => w.name,
        ),

        const SizedBox(height: 16),

        // Street dropdown
        _buildDropdown<Street>(
          label: 'Mtaa (Street)',
          hint: 'Chagua Mtaa',
          value: _selectedStreet,
          items: _streets,
          isLoading: _loadingStreets,
          enabled: _selectedWard != null,
          onChanged: _onStreetChanged,
          itemLabel: (s) => s.name,
        ),

        // Selected location summary (DESIGN.md: monochrome, no green)
        if (_selectedStreet != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF999999).withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: _primaryText, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Mahali Ulipochagua',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _primaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  UserLocation(
                    region: _selectedRegion,
                    district: _selectedDistrict,
                    ward: _selectedWard,
                    street: _selectedStreet,
                  ).fullAddress,
                  style: const TextStyle(fontSize: 14, color: _primaryText),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 4,
                ),
                if (_selectedWard?.postCode != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Post Code: ${_selectedWard!.postCode}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _secondaryText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);

  Widget _buildDropdown<T>({
    required String label,
    required String hint,
    required T? value,
    required List<T> items,
    required bool isLoading,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemLabel,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: _primaryText,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled ? const Color(0xFF999999).withOpacity(0.3) : const Color(0xFF999999).withOpacity(0.2),
            ),
            color: enabled ? Colors.white : const Color(0xFFFAFAFA),
          ),
          child: isLoading
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text('Inapakia...', style: const TextStyle(color: _secondaryText)),
                    ],
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: value,
                    hint: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        hint,
                        style: const TextStyle(color: _secondaryText, fontSize: 14),
                      ),
                    ),
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    borderRadius: BorderRadius.circular(12),
                    items: items.map((item) {
                      return DropdownMenuItem<T>(
                        value: item,
                        child: Text(
                          itemLabel(item),
                          style: const TextStyle(color: _primaryText, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                    onChanged: enabled ? onChanged : null,
                  ),
                ),
        ),
      ],
    );
  }
}
