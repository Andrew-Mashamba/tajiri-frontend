import 'package:flutter/material.dart';
import '../../../models/registration_models.dart';
import '../../../models/school_models.dart';
import '../../../services/school_service.dart';
import '../../../widgets/school_picker.dart';

/// Step 3: Primary School (Shule ya Msingi).
/// Navigation: Splash → Login → RegistrationScreen → PrimarySchoolStep.
/// Design: DOCS/DESIGN.md — 48dp touch targets, monochrome palette.
class PrimarySchoolStep extends StatefulWidget {
  final RegistrationState state;
  final SchoolService schoolService;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback? onSkip;

  const PrimarySchoolStep({
    super.key,
    required this.state,
    required this.schoolService,
    required this.onNext,
    required this.onBack,
    this.onSkip,
  });

  @override
  State<PrimarySchoolStep> createState() => _PrimarySchoolStepState();
}

class _PrimarySchoolStepState extends State<PrimarySchoolStep> {
  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);

  SelectedSchool _selection = SelectedSchool();
  int? _startYear;
  int? _graduationYear;

  static final List<int> _yearOptions = List.generate(
    50,
    (i) => DateTime.now().year - i,
  );

  bool get _isComplete =>
      _selection.school != null && _graduationYear != null;

  @override
  void initState() {
    super.initState();
    _applySavedPrimarySchool();
  }

  @override
  void didUpdateWidget(PrimarySchoolStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.primarySchool != widget.state.primarySchool) {
      _applySavedPrimarySchool();
    }
  }

  void _applySavedPrimarySchool() {
    final entry = widget.state.primarySchool;
    if (entry == null || entry.schoolId == null) return;
    final school = School(
      id: entry.schoolId!,
      code: entry.schoolCode ?? '',
      name: entry.schoolName ?? '',
      type: entry.schoolType ?? 'unknown',
      region: entry.regionName,
      district: entry.districtName,
    );
    setState(() {
      _selection = SelectedSchool(school: school);
      _startYear = entry.startYear;
      _graduationYear = entry.graduationYear;
    });
  }

  void _onSchoolChanged(SelectedSchool value) {
    setState(() => _selection = value);
  }

  void _submit() {
    if (!_isComplete) return;
    final school = _selection.school!;
    widget.state.primarySchool = EducationEntry(
      schoolId: school.id,
      schoolCode: school.code,
      schoolName: school.name,
      schoolType: school.type,
      startYear: _startYear,
      graduationYear: _graduationYear,
      regionName: _selection.region?.region ?? school.region,
      districtName: _selection.district?.district ?? school.district,
    );
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Icon(
            Icons.school_rounded,
            size: 64,
            color: _primaryText,
          ),
          const SizedBox(height: 24),
          const Text(
            'Shule ya Msingi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Ulisoma shule gani ya msingi?',
            style: TextStyle(
              fontSize: 14,
              color: _secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          SchoolPicker(
            schoolService: widget.schoolService,
            onSchoolChanged: _onSchoolChanged,
            initialSelection: _selection.school != null ? _selection : null,
          ),

          const SizedBox(height: 24),

          _buildYearDropdown(
            label: 'Mwaka wa Kuanza',
            value: _startYear,
            onChanged: (y) => setState(() => _startYear = y),
          ),
          const SizedBox(height: 16),
          _buildGraduationYearDropdown(),

          const SizedBox(height: 32),

          Row(
            children: [
              if (widget.onSkip != null) ...[
                Expanded(
                  child: _buildButton(
                    label: 'Ruka',
                    outlined: true,
                    onPressed: widget.onSkip!,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: widget.onSkip != null ? 2 : 1,
                child: _buildButton(
                  label: 'Endelea',
                  outlined: false,
                  onPressed: _isComplete ? _submit : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYearDropdown({
    required String label,
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _primaryText,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF999999)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Chagua mwaka',
                  style: TextStyle(color: _secondaryText),
                ),
              ),
              isExpanded: true,
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              dropdownColor: Colors.white,
              menuMaxHeight: 300,
              items: _yearOptions
                  .map((y) => DropdownMenuItem<int>(
                        value: y,
                        child: Text(
                          y.toString(),
                          style: const TextStyle(
                            color: _primaryText,
                            fontSize: 14,
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGraduationYearDropdown() {
    return _buildYearDropdown(
      label: 'Mwaka wa Kuhitimu',
      value: _graduationYear,
      onChanged: (year) => setState(() => _graduationYear = year),
    );
  }

  Widget _buildButton({
    required String label,
    required bool outlined,
    required VoidCallback? onPressed,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48, maxHeight: 80),
      width: double.infinity,
      child: Material(
        color: outlined ? Colors.transparent : Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: outlined ? 0 : 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: outlined
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF999999)),
                  )
                : null,
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: onPressed != null
                    ? _primaryText
                    : _secondaryText,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }
}
