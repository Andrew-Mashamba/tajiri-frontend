import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/registration_models.dart';
import '../../services/auth_service.dart';
import '../../services/graphql/graphql_onboarding_service.dart';
import '../home/home_screen.dart';

/// Final onboarding screen: celebration animation, profile preview, and
/// registration API call. On success, saves credentials and navigates to
/// HomeScreen, replacing the entire navigation stack.
class CompletionScreen extends StatefulWidget {
  final RegistrationState state;

  const CompletionScreen({super.key, required this.state});

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _checkController;
  late final Animation<double> _checkScale;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _checkScale = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );
    _checkController.forward();
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns the name of the highest education institution the user entered.
  String? get _highestSchoolName {
    final s = widget.state;
    if (s.universityEducation?.universityName != null) {
      return s.universityEducation!.universityName;
    }
    if (s.postsecondaryEducation?.schoolName != null) {
      return s.postsecondaryEducation!.schoolName;
    }
    if (s.alevelEducation?.schoolName != null) {
      return s.alevelEducation!.schoolName;
    }
    if (s.secondarySchool?.schoolName != null) {
      return s.secondarySchool!.schoolName;
    }
    if (s.primarySchool?.schoolName != null) {
      return s.primarySchool!.schoolName;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Registration
  // ---------------------------------------------------------------------------

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _registerViaGraphql();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Hitilafu ya mtandao. Angalia muunganiko wako.';
      });
    }
  }

  /// GraphQL registerAccount: creates the account for a phone that passed OTP
  /// (signup token from the phone step) and auto-logs in.
  Future<void> _registerViaGraphql() async {
    final s = widget.state;
    final deviceId = await AuthService.instance.getDeviceId();
    final input = <String, dynamic>{
      'signupToken': s.signupToken,
      'pin': s.pin,
      'deviceId': deviceId,
      'fullName': s.fullName,
      // TODO: profilePhotoPath via media upload; granular education/employer
      // once those pickers write structured selections into state.
      if (s.location?.regionName != null) 'location': s.location!.regionName,
    };

    final res = await GraphqlOnboardingService.registerAccount(input);
    if (!mounted) return;

    if (!res.success || res.payload == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = res.error ?? 'Usajili umeshindwa. Jaribu tena.';
      });
      return;
    }

    final payload = res.payload!;
    final user = (payload['user'] as Map<String, dynamic>?) ?? const {};
    await AuthService.instance.saveSession(
      accessToken: payload['accessToken'] as String,
      refreshToken: payload['refreshToken'] as String?,
      accessExpiresIn: payload['accessExpiresIn'] as int? ?? 86400,
      refreshExpiresIn: payload['refreshExpiresIn'] as int? ?? 7776000,
      user: s,
    );
    if (!mounted) return;

    final userId = int.tryParse('${user['id']}') ?? s.userId ?? 0;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomeScreen(currentUserId: userId)),
      (_) => false,
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              _buildCheckmark(),
              const SizedBox(height: 32),
              const Text(
                'Hongera! Uko tayari!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Akaunti yako iko tayari kuanzishwa.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B6B6B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 40),
              _buildProfileCard(),
              const Spacer(),
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFB00020),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _buildRegisterButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckmark() {
    return ScaleTransition(
      scale: _checkScale,
      child: Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final s = widget.state;
    final photoPath = s.profilePhotoPath;
    final schoolName = _highestSchoolName;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          _buildAvatar(photoPath),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.fullName.isNotEmpty ? s.fullName : '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                if (schoolName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    schoolName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B6B6B),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? photoPath) {
    ImageProvider? imageProvider;
    if (photoPath != null) {
      imageProvider = FileImage(File(photoPath));
    }

    return CircleAvatar(
      radius: 30,
      backgroundColor: const Color(0xFFE0E0E0),
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? const Icon(Icons.person_rounded, size: 30, color: Color(0xFF9E9E9E))
          : null,
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF9E9E9E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Anza TAJIRI →',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }
}
