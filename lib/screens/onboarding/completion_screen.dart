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

  /// Maps the collected education ladder into the GraphQL `EducationHistoryInput`
  /// list (camelCase keys). Only complete entries are sent.
  List<Map<String, dynamic>> _buildEducation() {
    final s = widget.state;
    final out = <Map<String, dynamic>>[];

    void addBasic(String level, EducationEntry? e) {
      if (e == null || !e.isComplete) return;
      out.add({
        'level': level,
        if (e.schoolId != null) 'institutionId': e.schoolId,
        if (e.schoolCode != null) 'institutionCode': e.schoolCode,
        if (e.schoolName != null) 'institutionName': e.schoolName,
        if (e.schoolType != null) 'institutionType': e.schoolType,
        if (e.startYear != null) 'startYear': e.startYear,
        if (e.graduationYear != null) 'graduationYear': e.graduationYear,
        if (e.regionName != null) 'regionName': e.regionName,
        if (e.districtName != null) 'districtName': e.districtName,
      });
    }

    addBasic('primary', s.primarySchool);
    addBasic('secondary', s.secondarySchool);

    final a = s.alevelEducation;
    if (a != null && a.isComplete) {
      out.add({
        'level': 'alevel',
        if (a.schoolId != null) 'institutionId': a.schoolId,
        if (a.schoolCode != null) 'institutionCode': a.schoolCode,
        if (a.schoolName != null) 'institutionName': a.schoolName,
        if (a.schoolType != null) 'institutionType': a.schoolType,
        if (a.startYear != null) 'startYear': a.startYear,
        if (a.graduationYear != null) 'graduationYear': a.graduationYear,
        if (a.combinationCode != null) 'combinationCode': a.combinationCode,
        if (a.combinationName != null) 'combinationName': a.combinationName,
        if (a.subjects != null) 'subjects': a.subjects,
        if (a.regionName != null) 'regionName': a.regionName,
        if (a.districtName != null) 'districtName': a.districtName,
      });
    }

    addBasic('postsecondary', s.postsecondaryEducation);

    final u = s.universityEducation;
    if (u != null && u.isComplete) {
      out.add({
        'level': 'university',
        if (u.universityId != null) 'institutionId': u.universityId,
        if (u.universityCode != null) 'institutionCode': u.universityCode,
        if (u.universityName != null) 'institutionName': u.universityName,
        if (u.collegeId != null) 'collegeId': u.collegeId,
        if (u.collegeName != null) 'collegeName': u.collegeName,
        if (u.departmentId != null) 'departmentId': u.departmentId,
        if (u.departmentName != null) 'departmentName': u.departmentName,
        if (u.programmeId != null) 'programmeId': u.programmeId,
        if (u.programmeName != null) 'programmeName': u.programmeName,
        if (u.degreeLevel != null) 'degreeLevel': u.degreeLevel,
        if (u.startYear != null) 'startYear': u.startYear,
        if (u.graduationYear != null) 'graduationYear': u.graduationYear,
        'isCurrentStudent': u.isCurrentStudent,
      });
    }
    return out;
  }

  /// Maps the current employer into the GraphQL `EmploymentHistoryInput` list.
  List<Map<String, dynamic>> _buildEmployment() {
    final e = widget.state.currentEmployer;
    if (e == null || !e.isComplete) return const [];
    return [
      {
        if (e.employerId != null) 'employerId': e.employerId,
        if (e.employerCode != null) 'employerCode': e.employerCode,
        if (e.employerName != null) 'employerName': e.employerName,
        if (e.sector != null) 'sector': e.sector,
        if (e.ownership != null) 'ownership': e.ownership,
        'isCustomEmployer': e.isCustomEmployer,
        'isCurrent': true,
      }
    ];
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
    final education = _buildEducation();
    final employment = _buildEmployment();
    final dob = s.dateOfBirth?.toIso8601String().split('T').first;
    final address =
        s.location?.displayAddress.isNotEmpty == true ? s.location!.displayAddress : null;
    final input = <String, dynamic>{
      'signupToken': s.signupToken,
      'pin': s.pin,
      'deviceId': deviceId,
      'fullName': s.fullName,
      // Photo is uploaded after register (media upload needs the new token).
      if (s.gender != null) 'gender': s.gender!.name,
      if (dob != null) 'dateOfBirth': dob,
      if (address != null) 'location': address,
      if (education.isNotEmpty) 'education': education,
      if (employment.isNotEmpty) 'employment': employment,
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

    // Upload the avatar now that we have an auth token, then attach it.
    final photo = s.profilePhotoPath;
    if (photo != null && photo.isNotEmpty) {
      final filePath = await GraphqlOnboardingService.uploadAvatar(
        photo,
        payload['accessToken'] as String,
      );
      if (filePath != null) {
        await GraphqlOnboardingService.setProfilePhoto(filePath);
      }
    }
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
