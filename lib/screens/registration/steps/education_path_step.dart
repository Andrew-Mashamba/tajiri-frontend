import 'package:flutter/material.dart';
import '../../../models/registration_models.dart';
import '../../../l10n/app_strings_scope.dart';

/// Step 5: Education Path — user indicates if they attended A-Level.
/// STORY-075. Navigation: Splash → Login → RegistrationScreen → EducationPathStep.
/// Design: DOCS/DESIGN.md — monochrome, touch targets 48dp min, no colorful elements.
class EducationPathStep extends StatelessWidget {
  final RegistrationState state;
  final Function(bool didAttendAlevel) onPathSelected;
  final VoidCallback onBack;

  const EducationPathStep({
    super.key,
    required this.state,
    required this.onPathSelected,
    required this.onBack,
  });

  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);
  static const Color _accent = Color(0xFF999999);
  static const Color _white = Color(0xFFFFFFFF);
  static const double _minTouchTargetDp = 48.0;
  static const double _buttonMinHeight = 72.0;
  static const double _buttonMaxHeight = 80.0;

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    if (s == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Icon(
              Icons.route,
              size: 64,
              color: _primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            s.educationPathTitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _primary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            s.educationPathSubtitle,
            style: const TextStyle(
              fontSize: 12,
              color: _secondaryText,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 32),

          // Option: Did A-Level — DESIGN.md button template, min 48dp touch target
          _buildPathOption(
            context: context,
            semanticsLabel: s.stepAlevel,
            icon: Icons.school_outlined,
            title: s.optionAlevel,
            subtitle: s.isSwahili ? 'Kidato cha 5 na 6' : 'Form 5 and 6',
            onTap: () => onPathSelected(true),
          ),

          const SizedBox(height: 12),

          // Option: Did not do A-Level
          _buildPathOption(
            context: context,
            semanticsLabel: s.optionNoAlevel,
            icon: Icons.work_outline,
            title: s.optionNoAlevel,
            subtitle: s.isSwahili
                ? 'Nilikwenda VETA, College, au Kazi'
                : 'I went to VETA, college, or work',
            onTap: () => onPathSelected(false),
          ),

          const SizedBox(height: 32),

          // Info note — monochrome accent (no blue)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: _secondaryText, size: 24),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(
                    s.isSwahili
                        ? 'Hii itatusaidia kukuunganisha na watu waliofanana nawe'
                        : 'This helps us connect you with similar people',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _secondaryText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathOption({
    required BuildContext context,
    required String semanticsLabel,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          minHeight: _buttonMinHeight,
          maxHeight: _buttonMaxHeight,
        ),
        child: Material(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Icon container: 48x48dp, dark background, white icon (DESIGN.md)
                  Container(
                    width: _minTouchTargetDp,
                    height: _minTouchTargetDp,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: _primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: _white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _secondaryText,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: _accent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
