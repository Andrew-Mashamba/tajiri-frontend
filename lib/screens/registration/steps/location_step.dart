import 'package:flutter/material.dart';

import '../../../models/registration_models.dart';
import '../../../services/location_service.dart';
import '../locationpicker_screen.dart';

/// Registration Step 2: Location (Mahali Unapoishi).
/// Delegates to LocationPickerScreen for Region > District > Ward > Street.
class LocationStep extends StatelessWidget {
  final RegistrationState state;
  final LocationService locationService;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback? onSkip;

  const LocationStep({
    super.key,
    required this.state,
    required this.locationService,
    required this.onNext,
    required this.onBack,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return LocationPickerScreen(
      state: state,
      locationService: locationService,
      onNext: onNext,
      onBack: onBack,
      onSkip: onSkip,
    );
  }
}
