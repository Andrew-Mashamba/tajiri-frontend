import 'package:flutter/material.dart';
import '../../../models/education_models.dart';
import '../../../widgets/employer_picker.dart';

/// Registration Step 8: Employer (Mwajiri).
/// Path: Splash → Login → RegistrationScreen → EmployerStep.
/// Uses [EmployerPicker] for DSE/Parastatals/Corporates and search by sector, category, ownership.
class EmployerStep extends StatelessWidget {
  final Function(Business?) onComplete;
  final VoidCallback onSkip;

  const EmployerStep({
    super.key,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return EmployerPicker(
      onComplete: onComplete,
      onSkip: onSkip,
    );
  }
}
