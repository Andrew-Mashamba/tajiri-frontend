import 'package:flutter/material.dart';
import '../../models/registration_models.dart';
import 'steps/phone_step.dart';
import '../../l10n/app_strings_scope.dart';

/// Story 74: Registration Phone Step (Thibitisha Simu).
/// Navigation: Splash → Login → RegistrationScreen → PhoneStep (Step 1).
/// DESIGN.md: SafeArea, #FAFAFA background, 48dp touch targets, #1A1A1A primary.
class PhonestepScreen extends StatelessWidget {
  const PhonestepScreen({
    super.key,
    required this.state,
    required this.onNext,
    required this.onBack,
  });

  final RegistrationState state;
  final VoidCallback onNext;
  final VoidCallback onBack;

  static const Color _background = Color(0xFFFAFAFA);
  static const Color _primary = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final String title = s?.stepPhone ?? 'Verify phone';

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.2,
                child: _buildHeader(context, title),
              ),
              Flexible(
                child: PhoneStep(
                  state: state,
                  onNext: onNext,
                  onBack: onBack,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, size: 24, color: _primary),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _primary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
