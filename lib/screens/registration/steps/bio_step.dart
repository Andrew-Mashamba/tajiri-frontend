import 'package:flutter/material.dart';
import '../../../models/registration_models.dart';
import '../../../l10n/app_strings_scope.dart';

/// Registration Step 0: Taarifa Binafsi (Personal info).
/// DESIGN.md: touch targets 48dp min; primary #1A1A1A; background #FAFAFA.
class BioStep extends StatefulWidget {
  final RegistrationState state;
  final VoidCallback onNext;

  const BioStep({
    super.key,
    required this.state,
    required this.onNext,
  });

  @override
  State<BioStep> createState() => _BioStepState();
}

class _BioStepState extends State<BioStep> {
  static const Color _primary = Color(0xFF1A1A);
  static const Color _secondaryText = Color(0xFF666666);
  static const double _minTouchTargetDp = 48.0;
  static const double _primaryButtonMinHeight = 72.0;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  DateTime? _selectedDate;
  Gender? _selectedGender;
  String? _firstNameError;
  String? _lastNameError;
  String? _dateError;
  String? _genderError;

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.state.firstName ?? '';
    _lastNameController.text = widget.state.lastName ?? '';
    _selectedDate = widget.state.dateOfBirth;
    _selectedGender = widget.state.gender;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _selectDate() async {
    final s = AppStringsScope.of(context);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(now.year - 18),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 10),
      helpText: s?.selectDateOfBirth ?? 'Select date of birth',
      cancelText: s?.cancel ?? 'Cancel',
      confirmText: s?.choose ?? 'Choose',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateError = null;
      });
    }
  }

  void _validateAndSubmit() {
    final s = AppStringsScope.of(context);
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();

    setState(() {
      _firstNameError = first.isEmpty ? (s?.firstNameRequired ?? 'First name is required') : null;
      _lastNameError = last.isEmpty ? (s?.lastNameRequired ?? 'Last name is required') : null;
      _dateError = _selectedDate == null ? (s?.dateOfBirthRequired ?? 'Date of birth is required') : null;
      _genderError = _selectedGender == null ? (s?.genderRequired ?? 'Please select gender') : null;
    });

    if (first.isEmpty || last.isEmpty || _selectedDate == null || _selectedGender == null) {
      return;
    }

    widget.state.firstName = first;
    widget.state.lastName = last;
    widget.state.dateOfBirth = _selectedDate;
    widget.state.gender = _selectedGender;
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    if (s == null) return const SizedBox.shrink();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            s.stepBio,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _primary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          Text(
            s.welcomeToTajiri,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _primary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          Text(
            s.tellUsAboutYou,
            style: const TextStyle(
              fontSize: 14,
              color: _secondaryText,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          const SizedBox(height: 32),

          _buildLabel(s.firstName),
          const SizedBox(height: 8),
          TextField(
            controller: _firstNameController,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration(
              hint: s.firstNameHint,
              icon: Icons.person_outline,
              errorText: _firstNameError,
            ),
            onChanged: (_) => setState(() {
              if (_firstNameError != null) _firstNameError = null;
            }),
          ),
          const SizedBox(height: 20),

          _buildLabel(s.lastName),
          const SizedBox(height: 8),
          TextField(
            controller: _lastNameController,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration(
              hint: s.lastNameHint,
              icon: Icons.person_outline,
              errorText: _lastNameError,
            ),
            onChanged: (_) => setState(() {
              if (_lastNameError != null) _lastNameError = null;
            }),
          ),
          const SizedBox(height: 20),

          _buildLabel(s.dateOfBirth),
          if (_dateError != null) ...[
            const SizedBox(height: 4),
            Text(
              _dateError!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: _minTouchTargetDp,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _dateError != null
                        ? Colors.red
                        : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: _secondaryText),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedDate != null
                            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                            : s.selectDate,
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedDate != null
                              ? _primary
                              : Colors.grey.shade500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: _secondaryText),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          _buildLabel(s.gender),
          if (_genderError != null) ...[
            const SizedBox(height: 4),
            Text(
              _genderError!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildGenderOption(
                  gender: Gender.male,
                  icon: Icons.male,
                  label: s.male,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGenderOption(
                  gender: Gender.female,
                  icon: Icons.female,
                  label: s.female,
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            height: _primaryButtonMinHeight,
            child: FilledButton(
              onPressed: _validateAndSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                minimumSize: const Size(_minTouchTargetDp, _minTouchTargetDp),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                s.continueBtn,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _primary,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      prefixIcon: Icon(icon, color: Colors.grey.shade600),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _buildGenderOption({
    required Gender gender,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedGender == gender;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedGender = gender;
            _genderError = null;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: _minTouchTargetDp),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? _primary.withOpacity(0.1) : Colors.white,
            border: Border.all(
              color: isSelected ? _primary : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected ? _primary : Colors.grey.shade600,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? _primary : Colors.grey.shade700,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
