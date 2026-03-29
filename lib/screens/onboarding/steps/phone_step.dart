import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/registration_models.dart';
import '../../../services/user_service.dart';
import '../../login/login_screen.dart';

/// Chapter 2, Screen 1: Phone number with availability check.
///
/// Receives [state] by reference and mutates it directly.
/// Normalises the input to +255XXXXXXXXX, calls [UserService.checkPhoneAvailability],
/// and on success sets [state.phoneNumber] + [state.isPhoneVerified] before
/// calling [onNext].
class PhoneStep extends StatefulWidget {
  final RegistrationState state;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const PhoneStep({
    super.key,
    required this.state,
    required this.onNext,
    this.onBack,
  });

  @override
  State<PhoneStep> createState() => _PhoneStepState();
}

class _PhoneStepState extends State<PhoneStep> {
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondary = Color(0xFF666666);
  static const Color _fieldBg = Colors.white;
  static const Color _border = Color(0xFFE0E0E0);

  final _phoneController = TextEditingController();
  final _userService = UserService();

  bool _isChecking = false;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    // Pre-fill if user navigated back.
    if (widget.state.phoneNumber != null) {
      _phoneController.text =
          widget.state.phoneNumber!.replaceFirst('+255', '');
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String get _digits =>
      _phoneController.text.replaceAll(RegExp(r'\D'), '');

  String get _normalised => '+255$_digits';

  bool get _isPhoneValid => _digits.length >= 9;

  // ---------------------------------------------------------------------------
  // Logic
  // ---------------------------------------------------------------------------

  Future<void> _handleNext() async {
    if (!_isPhoneValid) {
      setState(() {
        _phoneError = 'Weka nambari sahihi ya simu';
      });
      return;
    }

    setState(() {
      _phoneError = null;
      _isChecking = true;
    });

    final result = await _userService.checkPhoneAvailability(_normalised);

    if (!mounted) return;
    setState(() => _isChecking = false);

    if (!result.available) {
      // Phone is already taken — offer to go to login.
      final shouldLogin = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Nambari imeshasajiliwa',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _primary,
            ),
          ),
          content: const Text(
            'Nambari hii imeshasajiliwa. Ingia badala yake?',
            style: TextStyle(fontSize: 14, color: _secondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'Rudi',
                style: TextStyle(color: _secondary),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Ingia'),
            ),
          ],
        ),
      );

      if (shouldLogin == true && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
      return;
    }

    // Phone is available — persist and proceed.
    widget.state.phoneNumber = _normalised;
    widget.state.isPhoneVerified = true;
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
            // Heading
            const Text(
              'Nambari yako ya simu?',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: _primary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tutatumia hii kukuunganisha na marafiki',
              style: TextStyle(
                fontSize: 15,
                color: _secondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // Phone field
            _buildPhoneField(),

            if (_phoneError != null) ...[
              const SizedBox(height: 6),
              Text(
                _phoneError!,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ],

            const Spacer(),

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

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _phoneError != null ? Colors.red.shade300 : _border,
        ),
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
          // Non-editable +255 prefix
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(11),
              ),
            ),
            child: const Text(
              '+255',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: _primary,
              ),
            ),
          ),
          // Divider
          Container(width: 1, height: 40, color: _border),
          // Number input
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.number,
              autofocus: widget.state.phoneNumber == null,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
                color: _primary,
              ),
              decoration: const InputDecoration(
                hintText: '712 345 678',
                hintStyle: TextStyle(color: Color(0xFFBBBBBB), fontSize: 16),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (_) {
                if (_phoneError != null) setState(() => _phoneError = null);
              },
              onSubmitted: (_) => _handleNext(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    final enabled = _isPhoneValid && !_isChecking;
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
          child: _isChecking
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Row(
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
                    Text(
                      '→',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
