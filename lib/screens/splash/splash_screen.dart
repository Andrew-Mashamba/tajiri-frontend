import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/local_storage_service.dart';
import '../../l10n/app_strings_scope.dart';
import '../home/home_screen.dart';
import '../login/login_screen.dart';

/// Splash screen shown on app launch. Checks Hive for stored user and
/// redirects to [RegistrationScreen] if no user, or [HomeScreen] if user exists.
/// Follows DOCS/DESIGN.md (layout, colors, 600ms fade, SafeArea).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  // DESIGN.md: Single fade animation 600ms, CurvedAnimation
  static const Duration _splashFadeDuration = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: _splashFadeDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _checkUserAndNavigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkUserAndNavigate() async {
    // Let splash fade-in complete before navigating
    await Future.delayed(_splashFadeDuration);

    if (!mounted) return;

    try {
      // Initialize AuthService (loads tokens from secure storage, fetches pin config)
      await AuthService.instance.init();

      // One-time Hive → secure storage migration
      final migration = await AuthService.instance.migrateFromHive();

      if (!mounted) return;

      // Migration found expired token — must re-login
      if (migration == MigrationResult.tokenExpired) {
        _navigateToRegistration();
        return;
      }

      // Check if authenticated
      final isAuth = await AuthService.instance.isAuthenticated();

      if (!mounted) return;

      if (isAuth) {
        final storage = await LocalStorageService.getInstance();
        final user = storage.getUser();
        if (user != null && user.userId != null && user.userId! > 0) {
          _navigateToHome(user.userId!);
        } else {
          _navigateToRegistration();
        }
      } else {
        _navigateToRegistration();
      }
    } catch (_) {
      if (!mounted) return;
      _navigateToRegistration();
    }
  }

  /// Smooth transition to HomeScreen (DOCS: smooth transition animation;
  /// DESIGN.md: single fade 600ms).
  void _navigateToHome(int userId) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            HomeScreen(currentUserId: userId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: _splashFadeDuration,
      ),
    );
  }

  /// Smooth transition to LoginScreen (DESIGN.md: 600ms fade).
  void _navigateToRegistration() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: _splashFadeDuration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // DESIGN.md: Primary Background #FAFAFA, SafeArea, screen reader support
    return Semantics(
      label: 'TAJIRI splash screen, loading',
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: SafeArea(
          child: Center(
            child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // DESIGN.md: Simplified Logo max 80x80, white bg, rounded, shadow
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
                      child: Center(
                        child: Text(
                          'T',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Primary text: DESIGN.md #1A1A1A
                    Text(
                      (AppStringsScope.of(context))?.appName ?? 'TAJIRI',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Secondary text: DESIGN.md #666666
                    Text(
                      (AppStringsScope.of(context))?.appTagline ?? 'Learn. Grow. Get rich.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color.fromRGBO(26, 26, 26, 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ));
  }
}
