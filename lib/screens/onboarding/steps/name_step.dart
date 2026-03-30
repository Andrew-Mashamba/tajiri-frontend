import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/registration_models.dart';
import '../../../widgets/tap_chip_selector.dart';

/// Chapter 1, Screen 1: Name + Date of Birth + Gender.
///
/// Receives [state] by reference and mutates it directly.
/// Calls [onNext] once all fields are valid and the user taps "Endelea".
class NameStep extends StatefulWidget {
  final RegistrationState state;
  final VoidCallback onNext;

  const NameStep({super.key, required this.state, required this.onNext});

  @override
  State<NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<NameStep> {
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondary = Color(0xFF666666);
  static const Color _bg = Color(0xFFFAFAFA);
  static const Color _fieldBg = Colors.white;
  static const Color _border = Color(0xFFE0E0E0);

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;

  DateTime? _selectedDob;
  Gender? _selectedGender;

  String? _firstNameError;
  String? _lastNameError;

  @override
  void initState() {
    super.initState();
    // Pre-fill from state in case user navigated back.
    _firstNameCtrl = TextEditingController(text: widget.state.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: widget.state.lastName ?? '');
    _selectedDob = widget.state.dateOfBirth;
    _selectedGender = widget.state.gender;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Validation helpers
  // ---------------------------------------------------------------------------

  bool get _isFirstNameValid =>
      _firstNameCtrl.text.trim().length >= 2;

  bool get _isLastNameValid =>
      _lastNameCtrl.text.trim().length >= 2;

  bool get _isDobValid {
    if (_selectedDob == null) return false;
    final minAge = DateTime.now().subtract(const Duration(days: 365 * 13));
    return _selectedDob!.isBefore(minAge) ||
        _selectedDob!.isAtSameMomentAs(minAge);
  }

  bool get _isFormValid =>
      _isFirstNameValid &&
      _isLastNameValid &&
      _isDobValid &&
      _selectedGender != null;

  // ---------------------------------------------------------------------------
  // Interactions
  // ---------------------------------------------------------------------------

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final maxDate = DateTime(now.year - 13, now.month, now.day);
    final initialDate = _selectedDob != null && _selectedDob!.isBefore(maxDate)
        ? _selectedDob!
        : maxDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: maxDate,
      helpText: 'Chagua tarehe ya kuzaliwa',
      cancelText: 'Ghairi',
      confirmText: 'Thibitisha',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primary,
              onPrimary: Colors.white,
              surface: _bg,
              onSurface: _primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  void _onFirstNameChanged(String value) {
    setState(() {
      _firstNameError =
          value.trim().length < 2 && value.trim().isNotEmpty
              ? 'Angalau herufi 2 zinahitajika'
              : null;
    });
  }

  void _onLastNameChanged(String value) {
    setState(() {
      _lastNameError =
          value.trim().length < 2 && value.trim().isNotEmpty
              ? 'Angalau herufi 2 zinahitajika'
              : null;
    });
  }

  void _onGenderSelected(Gender gender) {
    setState(() => _selectedGender = gender);
  }

  void _handleNext() {
    if (!_isFormValid) return;

    widget.state.firstName = _firstNameCtrl.text.trim();
    widget.state.lastName = _lastNameCtrl.text.trim();
    widget.state.dateOfBirth = _selectedDob;
    widget.state.gender = _selectedGender;

    widget.onNext();
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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Conversational heading
                    const Text(
                      'Jina lako ni nani?',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tuambie jina lako na tarehe ya kuzaliwa',
                      style: TextStyle(
                        fontSize: 15,
                        color: _secondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // First name
                    _buildLabel('Jina la kwanza'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _firstNameCtrl,
                      hint: 'Mfano: Amina',
                      errorText: _firstNameError,
                      onChanged: _onFirstNameChanged,
                      textCapitalization: TextCapitalization.words,
                      autofocus: widget.state.firstName == null,
                    ),
                    const SizedBox(height: 16),

                    // Last name
                    _buildLabel('Jina la ukoo'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _lastNameCtrl,
                      hint: 'Mfano: Hassan',
                      errorText: _lastNameError,
                      onChanged: _onLastNameChanged,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),

                    // Date of birth
                    _buildLabel('Tarehe ya kuzaliwa'),
                    const SizedBox(height: 6),
                    _buildDobPicker(),
                    const SizedBox(height: 16),

                    // Gender
                    _buildLabel('Jinsia'),
                    const SizedBox(height: 6),
                    TapChipSelector<Gender>(
                      options: Gender.values,
                      selectedOption: _selectedGender,
                      labelBuilder: (g) => g.fullLabel,
                      onSelected: _onGenderSelected,
                      horizontal: true,
                    ),
                  ],
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _secondary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? errorText,
    ValueChanged<String>? onChanged,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool autofocus = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: errorText != null ? Colors.red.shade300 : _border,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        textCapitalization: textCapitalization,
        style: const TextStyle(fontSize: 15, color: _primary),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 15),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
          errorText: errorText,
          errorStyle: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildDobPicker() {
    final hasDate = _selectedDob != null;
    final label = hasDate
        ? DateFormat('d MMMM yyyy').format(_selectedDob!)
        : 'Chagua tarehe';

    return GestureDetector(
      onTap: _pickDob,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _fieldBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: _secondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: hasDate ? _primary : const Color(0xFFBBBBBB),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: _secondary),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    final enabled = _isFormValid;
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
