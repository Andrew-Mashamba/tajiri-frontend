import 'package:flutter/material.dart';
import '../../models/registration_models.dart';
import 'steps/bio_step.dart';

/// Registration Step 0: Taarifa Binafsi (Personal info).
/// Navigation: Splash → Login → RegistrationScreen → BioStep (Step 0).
/// DESIGN.md: SafeArea, background #FAFAFA, touch targets 48dp min.
class BiostepScreen extends StatelessWidget {
  final RegistrationState state;
  final VoidCallback onNext;

  const BiostepScreen({
    super.key,
    required this.state,
    required this.onNext,
  });

  static const Color _background = Color(0xFFFAFAFA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: BioStep(
            state: state,
            onNext: onNext,
          ),
        ),
      ),
    );
  }
}
