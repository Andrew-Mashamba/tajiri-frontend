import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vicoba/waitDialog.dart';

import 'HttpService.dart';
import 'OfflineDatabase.dart';
import 'createMwalikwaAccount.dart';
import 'DataStore.dart';
import 'loginUser.dart';
import 'start.dart';

// Design Guidelines Colors (Monochrome)
const _primaryBg = Color(0xFFFAFAFA);
const _cardBg = Color(0xFFFFFFFF);
const _primaryText = Color(0xFF1A1A1A);
const _secondaryText = Color(0xFF666666);
const _accentColor = Color(0xFF999999);

class mwalikwaLogin extends StatelessWidget {
  const mwalikwaLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VICOBA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: _primaryBg,
        fontFamily: 'Roboto',
      ),
      home: const _MwalikwaLoginPage(),
    );
  }
}

class _MwalikwaLoginPage extends StatefulWidget {
  const _MwalikwaLoginPage();

  @override
  State<_MwalikwaLoginPage> createState() => _MwalikwaLoginPageState();
}

class _MwalikwaLoginPageState extends State<_MwalikwaLoginPage>
    with SingleTickerProviderStateMixin {
  // 6 controllers for 6 OTP digits
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  bool get _isOtpComplete => _otpCode.length == 6;

  void _onDigitChanged(int index, String value) {
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });

    if (value.isNotEmpty && index < 5) {
      // Auto-advance to next field
      _focusNodes[index + 1].requestFocus();
    }

    // Auto-submit when all 6 digits are entered
    if (_isOtpComplete) {
      _submitOtp();
    }
  }

  void _onKeyPressed(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      // Move to previous field on backspace if current field is empty
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _clearOtp() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });
  }

  Future<void> _submitOtp() async {
    if (!_isOtpComplete || _isLoading) return;

    // Hide keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final result = await HttpService.login2(_otpCode.trim());

      if (!mounted) return;

      // Handle connection errors
      if (result.trim() == "Network Error") {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Hakuna mtandao, jaribu tena';
        });
        return;
      } else if (result.trim() == "Device Offline") {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Hauna internet, washa data';
        });
        return;
      } else if (result.trim() == "Server Error" || result.trim() == "error") {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Tatizo la kiufundi, jaribu baadaye';
        });
        return;
      }

      // Parse JSON response
      Map valueMap = jsonDecode(result);

      // Check for error response: {"error": 900, "message": "..."}
      if (valueMap.containsKey('error') && valueMap['error'] == 900) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = valueMap['message']?.toString() ?? 'Namba sio sahihi au imesha tumika';
        });
        _clearOtp();
        return;
      }

      // Success - parse user data
      loginUser user = loginUser.fromJson(valueMap);

      await OfflineDatabase().setCurrentUser(user);

      DataStore.userNumber = user.namba;
      DataStore.currentUserName = user.name;
      DataStore.currentUserId = user.userId;
      DataStore.invitingKikobaId = user.kikobaId;

      if (!mounted) return;

      if (user.membershipStatus == "pending") {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => createMwalikwaAccount()),
          (route) => false,
        );
      } else if (user.membershipStatus == "active") {
        await HttpService.addNewMember(user.namba, user.userId);
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const start()),
          (route) => false,
        );
      } else if (user.membershipStatus == "blocked") {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Umezuiwa kutumia mtandao huu';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Tatizo limetokea, jaribu tena';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryBg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                // Header Section
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.35,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo - V icon matching main.dart
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1A1A1A).withOpacity(0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'V',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Weka Namba ya Mwaliko',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ingiza namba 6 uliyopokea kwa SMS',
                        style: TextStyle(
                          fontSize: 14,
                          color: _secondaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // OTP Input Section
                Flexible(
                  child: Column(
                    children: [
                      // OTP Fields
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 24,
                        ),
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(6, (index) {
                            return _buildOtpField(index);
                          }),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Error Message
                      if (_hasError)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: Material(
                          color: _isOtpComplete ? _primaryText : _accentColor,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: _isOtpComplete && !_isLoading
                                ? _submitOtp
                                : null,
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'Endelea',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Clear Button
                      TextButton(
                        onPressed: _clearOtp,
                        child: const Text(
                          'Futa na uanze upya',
                          style: TextStyle(
                            color: _secondaryText,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Back Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: _secondaryText,
                      size: 20,
                    ),
                    label: const Text(
                      'Rudi Nyuma',
                      style: TextStyle(
                        color: _secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpField(int index) {
    final bool hasValue = _controllers[index].text.isNotEmpty;

    return SizedBox(
      width: 45,
      height: 56,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) => _onKeyPressed(index, event),
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _primaryText,
          ),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            filled: true,
            fillColor: hasValue ? _primaryBg : _cardBg,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _hasError
                    ? Colors.red.shade300
                    : (hasValue ? _primaryText : _accentColor),
                width: hasValue ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _hasError ? Colors.red.shade400 : _primaryText,
                width: 2,
              ),
            ),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          onChanged: (value) => _onDigitChanged(index, value),
        ),
      ),
    );
  }
}
