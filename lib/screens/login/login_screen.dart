import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_auth_service.dart';
import '../onboarding/onboarding_screen.dart';
import '../home/home_screen.dart';

/// Login screen: phone-based sign in or navigate to registration.
/// DESIGN.md: SafeArea, 48dp touch targets, monochrome #1A1A1A / #FAFAFA.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _background = Color(0xFFFAFAFA);
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);

  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _bioLoading = false;
  bool _bioAvailable = false;
  BiometricKind _bioKind = BiometricKind.generic;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  /// Detect whether the user has armed biometric quick-login on this
  /// device. If yes, surface the shortcut button above the PIN entry.
  Future<void> _checkBiometricAvailability() async {
    final enrolled = await AuthService.instance.hasBiometricLogin();
    if (!enrolled) return;
    final kind = await BiometricAuthService.instance.kind();
    if (!mounted) return;
    setState(() {
      _bioAvailable = true;
      _bioKind = kind;
    });
  }

  Future<void> _signInWithBiometric() async {
    setState(() {
      _bioLoading = true;
      _error = null;
    });
    final result = await AuthService.instance.loginWithBiometric();
    if (!mounted) return;
    if (result.success && result.userId != null && result.userId! > 0) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => HomeScreen(currentUserId: result.userId!),
        ),
        (route) => false,
      );
      return;
    }
    setState(() {
      _bioLoading = false;
      _error = result.error;
      // If the saved token was rejected the service has already wiped
      // it; reflect that in the UI so the button disappears.
    });
    final stillEnrolled = await AuthService.instance.hasBiometricLogin();
    if (!mounted) return;
    if (!stillEnrolled) {
      setState(() => _bioAvailable = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Tafadhali ingiza nambari ya simu');
      return;
    }

    final pin = _pinController.text.trim();
    if (pin.length != 4) {
      setState(() => _error = 'Tafadhali ingiza PIN ya nambari 4');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await AuthService.instance.login(phone, pin);

    if (!mounted) return;

    if (result.success && result.userId != null && result.userId! > 0) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => HomeScreen(currentUserId: result.userId!),
        ),
        (route) => false,
      );
    } else {
      setState(() {
        _isLoading = false;
        _error = result.error ?? 'Imeshindwa kuingia';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromRGBO(0, 0, 0, 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'T',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: _primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      s?.welcome ?? 'Karibu',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s?.welcomeSubtitle ?? 'Jifunze. Kukua. Tajiri.',
                      style: const TextStyle(fontSize: 14, color: _secondaryText),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Biometric quick-login (only when armed on this device)
                      if (_bioAvailable) ...[
                        SizedBox(
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: _bioLoading ? null : _signInWithBiometric,
                            icon: _bioLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _primary,
                                    ),
                                  )
                                : Icon(_bioKind == BiometricKind.face
                                    ? Icons.face_outlined
                                    : Icons.fingerprint_rounded,
                                    color: _primary),
                            label: Text(
                              _bioKind == BiometricKind.face
                                  ? (s?.isSwahili == true
                                      ? 'Ingia kwa Face ID'
                                      : 'Sign in with Face ID')
                                  : _bioKind == BiometricKind.fingerprint
                                      ? (s?.isSwahili == true
                                          ? 'Ingia kwa alama ya kidole'
                                          : 'Sign in with fingerprint')
                                      : (s?.isSwahili == true
                                          ? 'Ingia kwa biometriki'
                                          : 'Sign in with biometrics'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _primary,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: _primary, width: 1.5),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: _secondaryText.withValues(alpha: 0.2),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                s?.isSwahili == true ? 'au' : 'or',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _secondaryText,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: _secondaryText.withValues(alpha: 0.2),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Phone input
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontSize: 16, color: _primary),
                        decoration: InputDecoration(
                          hintText: '0712 345 678',
                          hintStyle: const TextStyle(color: _secondaryText),
                          labelText: s?.phoneNumber ?? 'Nambari ya Simu',
                          labelStyle: const TextStyle(color: _secondaryText),
                          prefixIcon: const Icon(Icons.phone_outlined, color: _primary),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        onSubmitted: (_) => _login(),
                      ),

                      const SizedBox(height: 12),

                      // PIN input
                      TextField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 4,
                        textAlign: TextAlign.center,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                          fontSize: 24,
                          letterSpacing: 8,
                          color: _primary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'PIN',
                          labelStyle: const TextStyle(color: _secondaryText),
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        onSubmitted: (_) => _login(),
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Sign In button
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  s?.signIn ?? 'Ingia',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'au',
                              style: const TextStyle(color: _secondaryText, fontSize: 13),
                            ),
                          ),
                          const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Create Account button
                      SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const OnboardingScreen(),
                                    ),
                                  );
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primary,
                            side: const BorderSide(color: _primary, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            s?.createAccount ?? 'Fungua Akaunti',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
