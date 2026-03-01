import 'package:flutter/material.dart';
import '../../../models/education_models.dart';
import '../../../widgets/university_programme_picker.dart';

/// Registration Step 7: University & Programme (STORY-008).
/// Path: Splash → Login → RegistrationScreen → UniversityStep.
/// Uses GET /api/universities-detailed/* (colleges, departments, programmes).
class UniversityStep extends StatelessWidget {
  final void Function(UniversityDetailed?, UniversityProgramme?, int? graduationYear, int? startYear)
      onComplete;
  final VoidCallback onSkip;

  const UniversityStep({
    super.key,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return UniversityProgrammePicker(
      onComplete: onComplete,
      onSkip: onSkip,
    );
  }
}
