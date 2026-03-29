import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/registration_models.dart';

/// Chapter 1 (Mahali), after PhoneStep: 4-digit PIN setup.
///
/// Receives [state] by reference and mutates [state.pin] on success.
class PinStep extends StatefulWidget {
  final RegistrationState state;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const PinStep({
    super.key,
    required this.state,
    required this.onNext,
    this.onBack,
  });

  @override
  State<PinStep> createState() => _PinStepState();
}

class _PinStepState extends State<PinStep> {
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondary = Color(0xFF666666);
  static const Color _fieldBg = Colors.white;
  static const Color _border = Color(0xFFE0E0E0);

  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  final _confirmFocus = FocusNode();

  String? _error;

  @override
  void initState() {
    super.initState();
    // Pre-fill if user navigated back.
    if (widget.state.pin != null) {
      _pinController.text = widget.state.pin!;
      _confirmController.text = widget.state.pin!;
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  bool get _isPinValid => _pinController.text.length == 4;
  bool get _isConfirmValid => _confirmController.text.length == 4;
  bool get _bothFilled => _isPinValid && _isConfirmValid;

  void _handleNext() {
    final pin = _pinController.text;
    final confirm = _confirmController.text;

    if (pin.length < 4) {
      setState(() => _error = 'PIN lazima iwe nambari 4');
      return;
    }

    if (pin != confirm) {
      setState(() => _error = 'PIN hazifanani');
      return;
    }

    setState(() => _error = null);
    widget.state.pin = pin;
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
              'Weka PIN yako',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: _primary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'PIN ya nambari 4 kwa usalama wa akaunti yako',
              style: TextStyle(
                fontSize: 15,
                color: _secondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // PIN field
            _buildPinField(
              controller: _pinController,
              label: 'PIN',
              autofocus: widget.state.pin == null,
              onSubmitted: (_) => _confirmFocus.requestFocus(),
            ),
            const SizedBox(height: 16),

            // Confirm PIN field
            _buildPinField(
              controller: _confirmController,
              label: 'Thibitisha PIN',
              focusNode: _confirmFocus,
              onSubmitted: (_) => _handleNext(),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(fontSize: 13, color: Colors.red),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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

  Widget _buildPinField({
    required TextEditingController controller,
    required String label,
    FocusNode? focusNode,
    bool autofocus = false,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _secondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: _fieldBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _error != null ? Colors.red.shade300 : _border),
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
            focusNode: focusNode,
            autofocus: autofocus,
            obscureText: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: 8,
              color: _primary,
            ),
            decoration: const InputDecoration(
              hintText: '----',
              hintStyle: TextStyle(
                color: Color(0xFFBBBBBB),
                fontSize: 24,
                letterSpacing: 8,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: onSubmitted,
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    final enabled = _bothFilled;
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
              Text(
                '\u2192',
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
