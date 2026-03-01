import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/registration_models.dart';
import '../../../services/user_service.dart';
import '../../../l10n/app_strings_scope.dart';

/// Story 74: Phone step (Thibitisha Simu). DESIGN.md: 48dp touch targets, #1A1A1A primary.
class PhoneStep extends StatefulWidget {
  final RegistrationState state;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const PhoneStep({
    super.key,
    required this.state,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<PhoneStep> createState() => _PhoneStepState();
}

class _PhoneStepState extends State<PhoneStep> {
  final _phoneController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _userService = UserService();

  bool _isOtpSent = false;
  bool _isVerifying = false;
  bool _isResending = false;
  bool _isCheckingPhone = false;
  int _resendCountdown = 0;
  String? _phoneError;

  static const double _minTouchTargetDp = 48.0;
  static const double _primaryButtonMinHeight = 72.0;
  static const Color _primary = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    if (widget.state.phoneNumber != null) {
      _phoneController.text = widget.state.phoneNumber!.replaceFirst('+255', '');
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  bool get _isPhoneValid {
    final phone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return phone.length >= 9;
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  bool get _isOtpComplete => _otpCode.length == 6;

  String get _fullPhone =>
      '+255${_phoneController.text.replaceAll(RegExp(r'\D'), '')}';

  void _sendOtp() async {
    final s = AppStringsScope.of(context);
    if (!_isPhoneValid) {
      setState(() {
        _phoneError = s?.phoneRequired ?? 'Phone number is required';
      });
      return;
    }
    setState(() {
      _phoneError = null;
      _isCheckingPhone = true;
    });

    final result = await _userService.checkPhoneAvailability(_fullPhone);

    if (!mounted) return;
    setState(() {
      _isCheckingPhone = false;
    });

    if (!result.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ?? (s?.phoneAlreadyRegistered ?? 'This phone number is already registered'),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s?.phoneAvailable ?? 'Number is available. Sending code.'),
        backgroundColor: const Color(0xFF1A1A1A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    setState(() {
      _isResending = true;
    });

    // Simulate sending OTP
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() {
      _isOtpSent = true;
      _isResending = false;
      _resendCountdown = 60;
    });

    // Start countdown
    _startResendCountdown();

    // Focus first OTP field
    _otpFocusNodes[0].requestFocus();
  }

  void _startResendCountdown() async {
    while (_resendCountdown > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendCountdown--;
        });
      }
    }
  }

  void _verifyOtp() async {
    if (!_isOtpComplete) return;

    setState(() {
      _isVerifying = true;
    });

    // Simulate verification delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Fixed OTP for testing: 111111
    if (_otpCode != '111111') {
      setState(() {
        _isVerifying = false;
      });
      if (mounted) {
        final s2 = AppStringsScope.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s2?.codeIncorrect ?? 'Code is incorrect. Try 111111'),
            backgroundColor: const Color(0xFF1A1A1A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    widget.state.phoneNumber = _fullPhone;
    widget.state.isPhoneVerified = true;

    setState(() {
      _isVerifying = false;
    });

    widget.onNext();
  }

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  void _editPhoneNumber() {
    setState(() {
      _isOtpSent = false;
      for (final controller in _otpControllers) {
        controller.clear();
      }
    });
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
          Icon(
            Icons.phone_android,
            size: 64,
            color: const Color(0xFF1A1A1A),
          ),
          const SizedBox(height: 24),
          Text(
            _isOtpSent ? s.enterCode : s.phoneNumber,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _isOtpSent ? s.weSentSms : s.weWillSendSms,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          if (!_isOtpSent) ...[
            if (_phoneError != null) ...[
              Text(
                _phoneError!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Phone Input
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _phoneError != null
                      ? Colors.grey.shade600
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(11),
                      ),
                    ),
                    child: Row(
                      children: [
                        Image.network(
                          'https://flagcdn.com/w40/tz.png',
                          width: 24,
                          height: 16,
                          errorBuilder: (_, _, _) => const Text('🇹🇿'),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '+255',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: const InputDecoration(
                        hintText: '712 345 678',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                      onChanged: (_) => setState(() {
                        if (_phoneError != null) _phoneError = null;
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: _primaryButtonMinHeight,
              child: FilledButton(
                onPressed: _isPhoneValid && !_isResending && !_isCheckingPhone
                    ? _sendOtp
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  minimumSize: const Size(_minTouchTargetDp, _minTouchTargetDp),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isCheckingPhone || _isResending
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        s.sendCode,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ] else ...[
            // Show phone number being verified
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '+255 ${_phoneController.text}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _editPhoneNumber,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: _minTouchTargetDp,
                          minHeight: _minTouchTargetDp,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          s.change,
                          style: const TextStyle(
                            color: _primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // OTP Input
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 48,
                  height: 56,
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _otpFocusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
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
                        borderSide: const BorderSide(
                          color: _primary,
                          width: 2,
                        ),
                      ),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) => _onOtpChanged(index, value),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Resend
            Center(
              child: _resendCountdown > 0
                  ? Text(
                      s.resendInSeconds(_resendCountdown),
                      style: TextStyle(color: Colors.grey.shade600),
                    )
                  : Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _sendOtp,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: _minTouchTargetDp,
                            minHeight: _minTouchTargetDp,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            s.resendCode,
                            style: const TextStyle(
                              color: _primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: _primaryButtonMinHeight,
              child: FilledButton(
                onPressed: _isOtpComplete && !_isVerifying ? _verifyOtp : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  minimumSize: const Size(_minTouchTargetDp, _minTouchTargetDp),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isVerifying
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        s.verify,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
