// A-Level registration step (Step 6, conditional).
// Uses AlevelSchoolPicker from lib/widgets/; design per DOCS/DESIGN.md.

import 'package:flutter/material.dart';
import '../../../models/registration_models.dart';
import '../../../models/secondary_models.dart';
import '../../../services/secondary_service.dart';
import '../../../widgets/alevel_school_picker.dart';

// Design tokens per DOCS/DESIGN.md
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);

class AlevelStep extends StatefulWidget {
  final RegistrationState state;
  final AlevelSchoolService alevelService;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback? onSkip;

  const AlevelStep({
    super.key,
    required this.state,
    required this.alevelService,
    required this.onNext,
    required this.onBack,
    this.onSkip,
  });

  @override
  State<AlevelStep> createState() => _AlevelStepState();
}

class _AlevelStepState extends State<AlevelStep> {
  AlevelSelection _selection = const AlevelSelection();

  void _onSelectionChanged(AlevelSelection selection) {
    setState(() => _selection = selection);
  }

  AlevelSchool? _initialSchoolFromState() {
    final e = widget.state.alevelEducation;
    if (e == null ||
        e.schoolId == null ||
        e.schoolCode == null ||
        e.schoolName == null) {
      return null;
    }
    return AlevelSchool(
      id: e.schoolId!,
      code: e.schoolCode!,
      name: e.schoolName!,
      type: e.schoolType ?? 'unknown',
      region: e.regionName,
      district: e.districtName,
    );
  }

  AlevelCombination? _initialCombinationFromState() {
    final e = widget.state.alevelEducation;
    if (e == null ||
        e.combinationCode == null ||
        e.combinationName == null) {
      return null;
    }
    return AlevelCombination(
      id: 0,
      code: e.combinationCode!,
      name: e.combinationName!,
      category: '',
      popularity: 'medium',
      subjects: e.subjects ?? [],
    );
  }

  void _submit() {
    if (!_selection.isComplete) return;
    widget.state.alevelEducation = AlevelEducation(
      schoolId: _selection.school!.id,
      schoolCode: _selection.school!.code,
      schoolName: _selection.school!.name,
      schoolType: _selection.school!.type,
      startYear: _selection.startYear,
      graduationYear: _selection.graduationYear,
      combinationCode: _selection.combination!.code,
      combinationName: _selection.combination!.name,
      subjects: _selection.combination!.subjects,
      regionName: _selection.school!.region,
      districtName: _selection.school!.district,
    );
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          // Header icon — monochrome per DESIGN.md
          Center(
            child: Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.school_outlined,
                size: 48,
                color: _kPrimaryText,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'A-Level',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _kPrimaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Kidato cha 5-6',
            style: TextStyle(
              fontSize: 14,
              color: _kSecondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AlevelSchoolPicker(
            alevelService: widget.alevelService,
            onSelectionChanged: _onSelectionChanged,
            initialSchool: _initialSchoolFromState(),
            initialCombination: _initialCombinationFromState(),
            initialStartYear: widget.state.alevelEducation?.startYear,
            initialGraduationYear:
                widget.state.alevelEducation?.graduationYear,
          ),
          const SizedBox(height: 32),
          // Buttons per DESIGN.md: min height 72-80, full width, white with shadow
          Row(
            children: [
              if (widget.onSkip != null) ...[
                Expanded(
                  child: _buildOutlinedButton(
                    label: 'Ruka',
                    onPressed: widget.onSkip!,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                flex: widget.onSkip != null ? 2 : 1,
                child: _buildPrimaryButton(
                  label: 'Endelea',
                  onPressed: _selection.isComplete ? _submit : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOutlinedButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72, maxHeight: 80),
      child: Material(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _kPrimaryText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    VoidCallback? onPressed,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72, maxHeight: 80),
      child: Material(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: onPressed != null ? _kPrimaryText : _kBackground,
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: onPressed != null ? _kSurface : _kSecondaryText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
