import 'package:flutter/material.dart';
import '../../models/registration_models.dart';
import '../../services/location_service.dart';
import '../../services/school_service.dart';
import '../../services/secondary_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/user_service.dart';
import '../../config/api_config.dart';
import '../../l10n/app_strings_scope.dart';
import '../profile/profile_screen.dart';
import 'steps/bio_step.dart';
import 'steps/phone_step.dart';
import 'steps/location_step.dart';
import 'steps/primary_school_step.dart';
import 'steps/secondary_school_step.dart';
import 'steps/alevel_step.dart';
import 'steps/education_path_step.dart';
import 'steps/postsecondary_step.dart';
import 'steps/university_step.dart';
import 'steps/employer_step.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final PageController _pageController = PageController();
  final RegistrationState _registrationState = RegistrationState();

  int _currentStep = 0;
  bool _didAttendAlevel = false;

  // Services
  late final LocationService _locationService;
  late final SchoolService _schoolService;
  late final SecondarySchoolService _secondaryService;
  late final AlevelSchoolService _alevelService;

  // Step indices - dynamically calculated based on user choices
  // Base steps:
  // 0: Bio
  // 1: Phone
  // 2: Location (skippable)
  // 3: Primary School (skippable)
  // 4: Secondary School (skippable)
  // 5: Education Path
  // 6: A-Level (conditional, skippable)
  // 7: Post-secondary (skippable)
  // 8: University (skippable)
  // 9: Employer (skippable)

  @override
  void initState() {
    super.initState();
    _didAttendAlevel = _registrationState.didAttendAlevel ?? false;
    final baseUrl = ApiConfig.baseUrl.replaceAll('/api', '');
    _locationService = LocationService(baseUrl: baseUrl);
    _schoolService = SchoolService(baseUrl: baseUrl);
    _secondaryService = SecondarySchoolService(baseUrl: baseUrl);
    _alevelService = AlevelSchoolService(baseUrl: baseUrl);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> _stepTitles(BuildContext context) {
    final s = AppStringsScope.of(context);
    if (s == null) return [];
    final titles = [
      s.stepBio,
      s.stepPhone,
      s.stepLocation,
      s.stepPrimary,
      s.stepSecondary,
      s.stepEducation,
    ];
    if (_didAttendAlevel) titles.add(s.stepAlevel);
    titles.addAll([s.stepPostSecondary, s.stepUniversity, s.stepEmployer]);
    return titles;
  }

  int _totalSteps(BuildContext context) => _stepTitles(context).length;

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
    });
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _nextStep() async {
    if (_currentStep < _totalSteps(context) - 1) {
      await _saveDraftLocally();
      _goToStep(_currentStep + 1);
    } else {
      _completeRegistration();
    }
  }

  /// Offline-first: save current registration state to Hive so user can resume.
  Future<void> _saveDraftLocally() async {
    try {
      final storage = await LocalStorageService.getInstance();
      await storage.saveUser(_registrationState);
    } catch (e) {
      debugPrint('Draft save failed: $e');
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  void _onEducationPathSelected(bool didAttendAlevel) {
    setState(() {
      _didAttendAlevel = didAttendAlevel;
      _registrationState.didAttendAlevel = didAttendAlevel;
    });
    _nextStep();
  }

  void _completeRegistration() async {
    // Log the registration data
    debugPrint('Registration complete: ${_registrationState.toJson()}');

    final s = AppStringsScope.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(s?.saving ?? 'Saving...'),
              ],
            ),
          ),
        ),
      ),
    );

    String? errorMessage;

    // Save remotely first
    try {
      final userService = UserService();
      final result = await userService.register(_registrationState);

      if (!result.success) {
        errorMessage = result.message;
        debugPrint('Remote save failed: ${result.message}');
      } else {
        _registrationState.userId = result.userId;
        if (result.profileData != null) {
          _registrationState.applyServerProfile(result.profileData!);
        }
        if (result.accessToken != null && result.accessToken!.isNotEmpty) {
          final storage = await LocalStorageService.getInstance();
          await storage.saveAuthToken(result.accessToken);
          debugPrint('Auth token saved for calls/FCM');
        }
        debugPrint('User data saved remotely, ID: ${result.userId}');
      }
    } catch (e) {
      final s = AppStringsScope.of(context);
      errorMessage = '${s?.saveFailed ?? 'Failed to save'}: $e';
      debugPrint('Error saving remotely: $e');
    }

    // Save locally regardless of remote result
    try {
      final storage = await LocalStorageService.getInstance();
      await storage.saveUser(_registrationState);
      debugPrint('User data saved locally');
    } catch (e) {
      debugPrint('Error saving locally: $e');
    }

    if (!mounted) return;

    // Close loading dialog
    Navigator.of(context).pop();

    final l10n = AppStringsScope.of(context);
    if (!mounted) return;
    // DESIGN.md: monochrome palette; no orange/green
    const Color primary = Color(0xFF1A1A1A);
    const Color secondaryText = Color(0xFF666666);
    const Color accentGray = Color(0xFF999999);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: errorMessage != null
                    ? accentGray.withOpacity(0.2)
                    : primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                errorMessage != null ? Icons.warning : Icons.check,
                color: errorMessage != null ? secondaryText : primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n?.congratulations ?? 'Congratulations!',
              style: const TextStyle(color: primary, fontSize: 15),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.registrationComplete ?? 'Your registration is complete. Welcome to Tajiri!',
              style: const TextStyle(fontSize: 14, color: primary),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentGray.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20, color: secondaryText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: const TextStyle(
                          fontSize: 12,
                          color: primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(
                      userId: _registrationState.userId ?? 0,
                      currentUserId: _registrationState.userId,
                    ),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                minimumSize: const Size(48, 48),
              ),
              child: Text(l10n?.viewProfile ?? 'View profile'),
            ),
          ),
        ],
      ),
    );
  }

  // Build all pages for the PageView
  List<Widget> _buildPages() {
    final pages = <Widget>[
      // Step 0: Bio
      BioStep(
        state: _registrationState,
        onNext: _nextStep,
      ),

      // Step 1: Phone
      PhoneStep(
        state: _registrationState,
        onNext: _nextStep,
        onBack: _previousStep,
      ),

      // Step 2: Location (skippable)
      LocationStep(
        state: _registrationState,
        locationService: _locationService,
        onNext: _nextStep,
        onBack: _previousStep,
        onSkip: _nextStep,
      ),

      // Step 3: Primary School (skippable)
      PrimarySchoolStep(
        state: _registrationState,
        schoolService: _schoolService,
        onNext: _nextStep,
        onBack: _previousStep,
        onSkip: _nextStep,
      ),

      // Step 4: Secondary School (skippable)
      SecondarySchoolStep(
        state: _registrationState,
        secondaryService: _secondaryService,
        onNext: _nextStep,
        onBack: _previousStep,
        onSkip: _nextStep,
      ),

      // Step 5: Education Path
      EducationPathStep(
        state: _registrationState,
        onPathSelected: _onEducationPathSelected,
        onBack: _previousStep,
      ),
    ];

    // Step 6: A-Level (conditional, skippable)
    if (_didAttendAlevel) {
      pages.add(
        AlevelStep(
          state: _registrationState,
          alevelService: _alevelService,
          onNext: _nextStep,
          onBack: _previousStep,
          onSkip: _nextStep,
        ),
      );
    }

    // Step 7: Post-secondary (skippable)
    pages.add(
      PostsecondaryStep(
        onComplete: (institution, gradYear, startYear) {
          if (institution != null) {
            _registrationState.postsecondaryEducation = EducationEntry(
              schoolId: institution.id,
              schoolCode: institution.code,
              schoolName: institution.name,
              schoolType: institution.type,
              startYear: startYear,
              graduationYear: gradYear,
            );
          }
          _nextStep();
        },
        onSkip: _nextStep,
      ),
    );

    // Step 8: University (skippable)
    pages.add(
      UniversityStep(
        onComplete: (university, programme, gradYear, startYear) {
          if (university != null || programme != null) {
            _registrationState.universityEducation = UniversityEducation(
              universityId: university?.id ?? programme?.universityId,
              universityCode: university?.code,
              universityName: university?.name ?? programme?.university,
              programmeId: programme?.id,
              programmeName: programme?.name,
              degreeLevel: programme?.levelCode,
              startYear: startYear,
              graduationYear: gradYear,
            );
          }
          _nextStep();
        },
        onSkip: _nextStep,
      ),
    );

    // Step 9: Employer (skippable)
    pages.add(
      EmployerStep(
        onComplete: (business) {
          if (business != null) {
            _registrationState.currentEmployer = EmployerEntry(
              employerId: business.id != 0 ? business.id : null,
              employerCode: business.code != 'CUSTOM' ? business.code : null,
              employerName: business.name,
              sector: business.sector,
              ownership: business.ownership,
              isCustomEmployer: business.code == 'CUSTOM',
            );
          }
          _completeRegistration();
        },
        onSkip: _completeRegistration,
      ),
    );

    return pages;
  }

  static const Color _background = Color(0xFFFAFAFA);
  static const Color _primary = Color(0xFF1A1A);
  static const double _minTouchTargetDp = 48.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.25,
                child: _buildProgressHeader(context),
              ),
              Flexible(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _buildPages(),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader(BuildContext context) {
    final s = AppStringsScope.of(context);
    final titles = _stepTitles(context);
    final total = titles.length;
    final stepLabel = s != null
        ? s.stepLabelFormat(_currentStep + 1, total)
        : 'Step ${_currentStep + 1} of $total';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (_currentStep > 0)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _previousStep,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: _minTouchTargetDp,
                        minHeight: _minTouchTargetDp,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, size: 24),
                    ),
                  ),
                )
              else
                const SizedBox(width: 48, height: 48),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      stepLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      titles[_currentStep],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? (_currentStep + 1) / total : 0,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: const AlwaysStoppedAnimation<Color>(_primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
