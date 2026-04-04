import 'dart:convert';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'DataStore.dart';
import 'HttpService.dart';
import 'vicobaList.dart';

// Design Guidelines Colors (Monochrome)
const _primaryBg = Color(0xFFFAFAFA);
const _darkBg = Color(0xFF1A1A1A);
const _primaryText = Color(0xFF1A1A1A);
const _secondaryText = Color(0xFF666666);
const _accentColor = Color(0xFF999999);

class start extends StatelessWidget {
  const start({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VICOBA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: _primaryBg,
        fontFamily: 'Roboto',
      ),
      home: const _SplashScreen(),
    );
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _logoController;
  late AnimationController _letterController;
  late AnimationController _taglineController;
  late AnimationController _loadingController;
  late AnimationController _pulseController;

  // Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoBounce;
  late Animation<double> _taglineOpacity;
  late Animation<Offset> _taglineSlide;
  late Animation<double> _loadingOpacity;

  // State
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _statusMessage = 'Inapakia...';
  bool _showContent = false;

  // Logo text
  final String _logoText = 'Vicoba';
  final List<Animation<double>> _letterAnimations = [];
  final List<Animation<double>> _letterBounceAnimations = [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimationSequence();
  }

  void _initAnimations() {
    // Logo icon animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _logoBounce = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.3, 1.0, curve: Curves.bounceOut),
      ),
    );

    // Letter animations (staggered)
    _letterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Create staggered animations for each letter
    for (int i = 0; i < _logoText.length; i++) {
      final startInterval = i * 0.1;
      final endInterval = math.min(startInterval + 0.4, 1.0);

      // Scale animation for each letter
      _letterAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _letterController,
            curve: Interval(startInterval, endInterval, curve: Curves.elasticOut),
          ),
        ),
      );

      // Bounce animation for each letter
      _letterBounceAnimations.add(
        Tween<double>(begin: 30.0, end: 0.0).animate(
          CurvedAnimation(
            parent: _letterController,
            curve: Interval(startInterval, endInterval, curve: Curves.bounceOut),
          ),
        ),
      );
    }

    // Tagline animation
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _taglineController,
        curve: Curves.easeOut,
      ),
    );

    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _taglineController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Loading animation
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _loadingOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loadingController,
        curve: Curves.easeOut,
      ),
    );

    // Pulse animation for loading dots
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  Future<void> _startAnimationSequence() async {
    // Start logo animation
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();

    // Start letter animations
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() => _showContent = true);
    _letterController.forward();

    // Start tagline animation
    await Future.delayed(const Duration(milliseconds: 1000));
    _taglineController.forward();

    // Start loading animation and data fetch
    await Future.delayed(const Duration(milliseconds: 400));
    _loadingController.forward();
    _initializeUser();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _letterController.dispose();
    _taglineController.dispose();
    _loadingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initializeUser() async {
    try {
      setState(() {
        _statusMessage = 'Inathibitisha akaunti...';
      });

      // Check Firebase Auth
      final firebaseUser = FirebaseAuth.instance.currentUser;
      String phoneNumber;

      if (firebaseUser != null && firebaseUser.phoneNumber != null) {
        phoneNumber = firebaseUser.phoneNumber!;
        DataStore.userNumber = phoneNumber;
      } else if (DataStore.userNumber != null &&
          DataStore.userNumber!.isNotEmpty) {
        phoneNumber = DataStore.userNumber!;
      } else {
        // No user found, navigate to vikoba list anyway
        await Future.delayed(const Duration(milliseconds: 500));
        _navigateToVikobaList();
        return;
      }

      setState(() {
        _statusMessage = 'Inapakia taarifa...';
      });

      // Fetch user data from API
      await _fetchUserData(phoneNumber);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Tatizo limetokea, jaribu tena';
      });
    }
  }

  Future<void> _fetchUserData(String phoneNumber) async {
    try {
      // Clean phone number
      final cleanNumber = phoneNumber.replaceAll("+", "");
      final url = "${HttpService.baseUrl}user?number=$cleanNumber";

      final response = await http.get(
        Uri.parse(url),
        headers: {"Accept": "application/json"},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Update DataStore with user info
        DataStore.currentUserName =
            data["name"]?.toString() ?? DataStore.currentUserName;
        DataStore.currentUserId =
            data["userId"]?.toString() ?? DataStore.currentUserId;
        DataStore.userNumber =
            data["phone"]?.toString() ?? DataStore.userNumber;
      }

      // Fetch vikoba list
      setState(() {
        _statusMessage = 'Inapakia vikoba...';
      });

      await _fetchVikobaList();

      // Navigate to main app
      _navigateToVikobaList();
    } catch (e) {
      if (!mounted) return;
      // Network error, but still try to proceed with cached data
      _navigateToVikobaList();
    }
  }

  Future<void> _fetchVikobaList() async {
    try {
      final vikobaList = await HttpService().getData2xp();
      DataStore.myVikobaList = vikobaList;
    } catch (e) {
      // If fetching fails, keep empty list
      DataStore.myVikobaList = [];
    }
  }

  void _navigateToVikobaList() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const VikobaListPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
      (route) => false,
    );
  }

  Future<void> _retry() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
    await _initializeUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryBg,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Animated Logo Icon
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScale.value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - _logoBounce.value) * -20),
                          child: _buildLogoIcon(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Animated Logo Text (Vicoba)
                  if (_showContent) _buildAnimatedLogoText(),

                  const Spacer(flex: 2),

                  // Loading Section
                  FadeTransition(
                    opacity: _loadingOpacity,
                    child: _buildLoadingSection(),
                  ),

                  const SizedBox(height: 48),

                  // Tagline at bottom
                  SlideTransition(
                    position: _taglineSlide,
                    child: FadeTransition(
                      opacity: _taglineOpacity,
                      child: _buildTagline(),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: _darkBg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _darkBg.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'V',
          style: TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogoText() {
    return AnimatedBuilder(
      animation: _letterController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_logoText.length, (index) {
            return Transform.translate(
              offset: Offset(0, _letterBounceAnimations[index].value),
              child: Transform.scale(
                scale: _letterAnimations[index].value,
                child: Text(
                  _logoText[index],
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: _primaryText,
                    letterSpacing: 2,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildLoadingSection() {
    if (_hasError) {
      return _buildErrorState();
    }

    return Column(
      children: [
        // Custom animated loading dots
        _buildLoadingDots(),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _statusMessage,
            key: ValueKey(_statusMessage),
            style: const TextStyle(
              fontSize: 14,
              color: _secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            // Staggered animation for each dot
            final delay = index * 0.2;
            final animValue = ((_pulseController.value + delay) % 1.0);
            final scale = 0.5 + (math.sin(animValue * math.pi) * 0.5);
            final opacity = 0.3 + (math.sin(animValue * math.pi) * 0.7);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _primaryText.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              size: 28,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: const TextStyle(
              fontSize: 14,
              color: _secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _retry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                color: _primaryText,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Jaribu Tena',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagline() {
    return Column(
      children: [
        // Decorative line
        Container(
          width: 40,
          height: 2,
          decoration: BoxDecoration(
            color: _accentColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'A Zima Limited Solution',
          style: TextStyle(
            fontSize: 11,
            color: _accentColor,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

/// Custom page route with fade transition
class _FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  _FadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
}
