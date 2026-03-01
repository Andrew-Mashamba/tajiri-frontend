import 'package:flutter/material.dart';

import '../../models/registration_models.dart';
import '../../models/location_models.dart';
import '../../services/location_service.dart';
import '../../widgets/location_picker.dart';

/// Location hierarchy selection screen for registration (Step 2).
/// Tanzania: Region > District > Ward > Street.
/// Reached via: Splash → Login → RegistrationScreen → LocationStep.
class LocationPickerScreen extends StatefulWidget {
  final RegistrationState state;
  final LocationService locationService;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback? onSkip;

  const LocationPickerScreen({
    super.key,
    required this.state,
    required this.locationService,
    required this.onNext,
    required this.onBack,
    this.onSkip,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);
  static const Color _iconBg = Color(0xFF1A1A1A);

  UserLocation? _getInitialLocation() {
    final loc = widget.state.location;
    if (loc == null || !loc.isComplete) return null;
    return UserLocation(
      region: Region(id: loc.regionId!, name: loc.regionName ?? ''),
      district: District(
        id: loc.districtId!,
        regionId: loc.regionId!,
        name: loc.districtName ?? '',
      ),
      ward: Ward(
        id: loc.wardId!,
        districtId: loc.districtId!,
        name: loc.wardName ?? '',
      ),
      street: Street(
        id: loc.streetId!,
        wardId: loc.wardId!,
        name: loc.streetName ?? '',
      ),
    );
  }

  void _onLocationChanged(UserLocation userLoc) {
    if (!userLoc.isComplete) {
      widget.state.location = null;
    } else {
      widget.state.location = LocationSelection(
        regionId: userLoc.region!.id,
        regionName: userLoc.region!.name,
        districtId: userLoc.district!.id,
        districtName: userLoc.district!.name,
        wardId: userLoc.ward!.id,
        wardName: userLoc.ward!.name,
        streetId: userLoc.street!.id,
        streetName: userLoc.street!.name,
      );
    }
    if (mounted) setState(() {});
  }

  bool get _isComplete =>
      widget.state.location != null && widget.state.location!.isComplete;

  void _submit() {
    if (_isComplete) widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          // Icon: 48dp min touch target area
          Semantics(
            label: 'Mahali Unapoishi',
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.location_on,
                  size: 48,
                  color: _iconBg,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Unaishi Wapi?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _primaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Chagua mahali unapoishi kwa sasa',
            style: TextStyle(
              fontSize: 12,
              color: _secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Cascading dropdowns via LocationPicker widget
          LocationPicker(
            locationService: widget.locationService,
            initialLocation: _getInitialLocation(),
            onLocationChanged: _onLocationChanged,
          ),

          const SizedBox(height: 24),

          // Buttons: DESIGN.md min height 72–80, full width, white, elevation 2
          Row(
            children: [
              if (widget.onSkip != null) ...[
                Expanded(
                  child: _buildSecondaryButton(
                    label: 'Ruka',
                    onPressed: widget.onSkip!,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: widget.onSkip != null ? 2 : 1,
                child: _buildPrimaryButton(
                  label: 'Endelea',
                  onPressed: _isComplete ? _submit : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    VoidCallback? onPressed,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 72, maxHeight: 80),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: onPressed != null ? _primaryText : _secondaryText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 72, maxHeight: 80),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _secondaryText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
