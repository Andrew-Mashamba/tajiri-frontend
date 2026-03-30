import 'package:flutter/material.dart';

import '../../../models/registration_models.dart';
import '../../../widgets/tap_chip_selector.dart';

/// Chapter 3, Screen 1: Education path choice.
///
/// Asks "Umesoma hadi wapi?" and lets the user pick their highest education
/// level from [EducationPath]. On submit the selection is written back to
/// [state] and downstream education data that no longer applies is cleared.
class EducationLevelStep extends StatefulWidget {
  final RegistrationState state;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const EducationLevelStep({
    super.key,
    required this.state,
    required this.onNext,
    this.onBack,
  });

  @override
  State<EducationLevelStep> createState() => _EducationLevelStepState();
}

class _EducationLevelStepState extends State<EducationLevelStep> {
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondary = Color(0xFF666666);

  EducationPath? _selectedPath;

  @override
  void initState() {
    super.initState();
    // Pre-fill from state in case user navigated back.
    _selectedPath = widget.state.educationPath;
  }

  // ---------------------------------------------------------------------------
  // Label mapping
  // ---------------------------------------------------------------------------

  String _labelFor(EducationPath path) {
    switch (path) {
      case EducationPath.primary:
        return 'Shule ya Msingi (Darasa 1-7)';
      case EducationPath.secondary:
        return 'Sekondari O-Level (Kidato 1-4)';
      case EducationPath.alevel:
        return 'Sekondari A-Level (Kidato 5-6)';
      case EducationPath.postSecondary:
        return 'Chuo cha Ufundi / Ualimu / Afya';
      case EducationPath.university:
        return 'Chuo Kikuu';
    }
  }

  // ---------------------------------------------------------------------------
  // Interactions
  // ---------------------------------------------------------------------------

  void _onPathSelected(EducationPath path) {
    setState(() => _selectedPath = path);
  }

  void _handleNext() {
    final selected = _selectedPath;
    if (selected == null) return;

    // Write chosen path.
    widget.state.educationPath = selected;

    // Set the A-Level flag: A-Level and University paths both imply A-Level attendance.
    widget.state.didAttendAlevel =
        selected == EducationPath.alevel || selected == EducationPath.university;

    // Clear downstream education data that no longer applies.
    _clearDownstream(selected);

    widget.onNext();
  }

  /// Clears education sub-fields that are above [selected].
  ///
  /// Tanzania education cascade:
  ///   Primary → O-Level → A-Level → University
  ///                     → Post-Secondary (VETA/TTC/Health after O-Level)
  ///
  /// Rules:
  ///   primary        → clear secondary, alevel, postsecondary, university
  ///   secondary      → clear alevel, postsecondary, university
  ///   alevel         → clear postsecondary, university
  ///   postSecondary  → clear alevel, university (post-sec branches after O-Level)
  ///   university     → clear postsecondary (university implies O-Level + A-Level)
  void _clearDownstream(EducationPath selected) {
    switch (selected) {
      case EducationPath.primary:
        widget.state.secondarySchool = null;
        widget.state.alevelEducation = null;
        widget.state.postsecondaryEducation = null;
        widget.state.universityEducation = null;
      case EducationPath.secondary:
        widget.state.alevelEducation = null;
        widget.state.postsecondaryEducation = null;
        widget.state.universityEducation = null;
      case EducationPath.alevel:
        widget.state.postsecondaryEducation = null;
        widget.state.universityEducation = null;
      case EducationPath.postSecondary:
        widget.state.alevelEducation = null;
        widget.state.universityEducation = null;
      case EducationPath.university:
        widget.state.postsecondaryEducation = null;
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Conversational heading
            const Text(
              'Umesoma hadi wapi?',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: _primary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chagua kiwango chako cha juu cha elimu',
              style: TextStyle(
                fontSize: 15,
                color: _secondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // Education path chips (vertical) — scrollable to avoid overflow
            Expanded(
              child: SingleChildScrollView(
                child: TapChipSelector<EducationPath>(
                  options: EducationPath.values,
                  selectedOption: _selectedPath,
                  labelBuilder: _labelFor,
                  onSelected: _onPathSelected,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Continue button
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sub-builders
  // ---------------------------------------------------------------------------

  Widget _buildNextButton() {
    final enabled = _selectedPath != null;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.45,
        child: FilledButton(
          onPressed: enabled ? _handleNext : null,
          style: FilledButton.styleFrom(
            backgroundColor: _primary,
            disabledBackgroundColor: _primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Endelea',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.arrow_forward, size: 18, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
