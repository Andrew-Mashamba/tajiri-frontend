import 'package:flutter/material.dart';
import '../../../models/registration_models.dart';
import '../../../models/secondary_models.dart';
import '../../../services/secondary_service.dart';
import '../../../widgets/secondary_school_picker.dart';

/// Step 4: O-Level secondary school selection.
/// Navigation: Splash → Login → RegistrationScreen → SecondarySchoolStep.
/// Design: DOCS/DESIGN.md — monochrome, 48dp touch targets.
class SecondarySchoolStep extends StatefulWidget {
  final RegistrationState state;
  final SecondarySchoolService secondaryService;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback? onSkip;

  const SecondarySchoolStep({
    super.key,
    required this.state,
    required this.secondaryService,
    required this.onNext,
    required this.onBack,
    this.onSkip,
  });

  @override
  State<SecondarySchoolStep> createState() => _SecondarySchoolStepState();
}

class _SecondarySchoolStepState extends State<SecondarySchoolStep> {
  SecondarySchool? _selectedSchool;
  SecondaryRegion? _selectedRegion;
  SecondaryDistrict? _selectedDistrict;
  int? _startYear;
  int? _graduationYear;

  final List<int> _yearOptions =
      List.generate(50, (i) => DateTime.now().year - i);

  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);
  static const Color _white = Color(0xFFFFFFFF);

  bool get _isComplete => _selectedSchool != null && _graduationYear != null;

  void _submit() {
    if (!_isComplete) return;
    widget.state.secondarySchool = EducationEntry(
      schoolId: _selectedSchool!.id,
      schoolCode: _selectedSchool!.code,
      schoolName: _selectedSchool!.name,
      schoolType: _selectedSchool!.type,
      startYear: _startYear,
      graduationYear: _graduationYear,
      regionName: _selectedRegion?.region ?? _selectedSchool!.region,
      districtName: _selectedDistrict?.district ?? _selectedSchool!.district,
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
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.22,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.school_outlined,
                  size: 48,
                  color: _primaryText,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sekondari (O-Level)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Kidato cha 1–4. Chagua shule yako ya sekondari.',
            style: TextStyle(
              fontSize: 12,
              color: _secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          SecondarySchoolPicker(
            secondaryService: widget.secondaryService,
            initialSchool: _selectedSchool,
            onSelectionChanged: (selection) {
              setState(() {
                if (selection == null) {
                  _selectedSchool = null;
                  _selectedRegion = null;
                  _selectedDistrict = null;
                } else {
                  _selectedSchool = selection.school;
                  _selectedRegion = selection.region;
                  _selectedDistrict = selection.district;
                }
              });
            },
          ),

          const SizedBox(height: 24),

          _buildYearDropdown(
            'Mwaka wa Kuanza',
            _startYear,
            (y) => setState(() => _startYear = y),
          ),
          const SizedBox(height: 16),
          _buildGraduationDropdown(),

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
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildYearDropdown(String label, int? value, ValueChanged<int?> onChanged) {
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
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF999999)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'Chagua mwaka',
                  style: TextStyle(color: _secondaryText, fontSize: 14),
                ),
              ),
              isExpanded: true,
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget _buildGraduationDropdown() {
    return _buildYearDropdown(
      'Mwaka wa Kumaliza Form 4',
      _graduationYear,
      (year) => setState(() => _graduationYear = year),
    );
  }

  Widget _buildButton({
    required String label,
    required bool outlined,
    required VoidCallback? onPressed,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72, maxHeight: 80),
      child: Material(
        color: outlined ? Colors.transparent : _white,
        borderRadius: BorderRadius.circular(16),
        elevation: outlined ? 0 : 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            decoration: outlined
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _primaryText),
                  )
                : null,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: onPressed == null
                    ? _secondaryText
                    : (outlined ? _primaryText : _primaryText),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
