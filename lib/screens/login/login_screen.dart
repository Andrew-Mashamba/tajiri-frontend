import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../registration/registration_screen.dart';

/// Login screen: Splash → Login → RegistrationScreen.
/// DOCS/NAVIGATION.md: No user path. DESIGN.md: SafeArea, 48dp touch targets, monochrome.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  static const Color _background = Color(0xFFFAFAFA);
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);
  static const double _minTouchTargetDp = 48.0;
  static const double _buttonMinHeight = 72.0;

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    if (s == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
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
                            color: Colors.black.withOpacity(0.1),
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
                      s.welcome,
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
                      s.welcomeSubtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _secondaryText,
                      ),
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
                    children: [
                      const SizedBox(height: 24),
                      _buildButton(
                        context: context,
                        label: s.createAccount,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const RegistrationScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildButton(
                        context: context,
                        label: s.signIn,
                        onPressed: () {
                          // For now, same as create account (phone-based login TBD).
                          // When adding login API: on success call LocalStorageService().saveAuthToken(accessToken)
                          // so FCM and call flows use the new API.
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const RegistrationScreen(),
                            ),
                          );
                        },
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

  Widget _buildButton({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: _buttonMinHeight,
        maxHeight: 80,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: _minTouchTargetDp,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _primary,
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
