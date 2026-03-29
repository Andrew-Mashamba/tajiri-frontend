import 'package:flutter/material.dart';

import '../../models/registration_models.dart';
import 'chapter_celebration.dart';
import 'chapter_progress_bar.dart';
import 'completion_screen.dart';
import 'steps/education_level_step.dart';
import 'steps/employer_step.dart';
import 'steps/location_step.dart';
import 'steps/name_step.dart';
import 'steps/phone_step.dart';
import 'steps/photo_step.dart';
import 'steps/pin_step.dart';
import 'steps/school_step.dart';
import 'steps/university_step.dart';

/// Main controller that orchestrates the entire onboarding flow.
///
/// Manages page transitions, chapter celebrations, and dynamic education
/// branching based on the user's selected [EducationPath].
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final RegistrationState _state = RegistrationState();
  final PageController _pageController = PageController();

  int _currentStepIndex = 0;
  bool _showCelebration = false;
  int _celebrationChapter = 0;

  late List<_StepConfig> _steps;

  @override
  void initState() {
    super.initState();
    _steps = _buildSteps();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Step list construction
  // ---------------------------------------------------------------------------

  List<_StepConfig> _buildSteps() {
    return [
      // Chapter 0: Kufahamiana
      _StepConfig(
        chapter: 0,
        builder: () => NameStep(
          state: _state,
          onNext: _next,
        ),
      ),
      _StepConfig(
        chapter: 0,
        builder: () => PhotoStep(
          state: _state,
          onNext: _next,
          onBack: _back,
        ),
      ),

      // Chapter 1: Mahali
      _StepConfig(
        chapter: 1,
        builder: () => PhoneStep(
          state: _state,
          onNext: _next,
          onBack: _back,
        ),
      ),
      _StepConfig(
        chapter: 1,
        builder: () => PinStep(
          state: _state,
          onNext: _next,
          onBack: _back,
        ),
      ),
      _StepConfig(
        chapter: 1,
        builder: () => LocationStep(
          state: _state,
          onNext: _next,
          onBack: _back,
          onSkip: _next,
        ),
      ),

      // Chapter 2: Masomo
      _StepConfig(
        chapter: 2,
        builder: () => EducationLevelStep(
          state: _state,
          onNext: _onEducationLevelNext,
          onBack: _back,
        ),
      ),
      ..._educationSteps(),

      // Chapter 3: Maisha
      _StepConfig(
        chapter: 3,
        builder: () => EmployerStep(
          state: _state,
          onNext: _complete,
          onBack: _back,
          onSkip: _complete,
        ),
      ),
    ];
  }

  /// Returns dynamic education steps based on [_state.educationPath].
  List<_StepConfig> _educationSteps() {
    final path = _state.educationPath;
    if (path == null) return [];

    final dobYear = _state.dateOfBirth?.year ?? (DateTime.now().year - 18);

    switch (path) {
      case EducationPath.primary:
        return [
          _StepConfig(
            chapter: 2,
            builder: () => SchoolStep(
              schoolType: 'primary',
              question: 'Ulisoma shule gani ya msingi?',
              skipText: 'Ruka',
              defaultGradYear: dobYear + 13,
              state: _state,
              onNext: _next,
              onBack: _back,
            ),
          ),
        ];

      case EducationPath.secondary:
        return [
          _StepConfig(
            chapter: 2,
            builder: () => SchoolStep(
              schoolType: 'primary',
              question: 'Ulisoma shule gani ya msingi?',
              skipText: 'Ruka',
              defaultGradYear: dobYear + 13,
              state: _state,
              onNext: _next,
              onBack: _back,
            ),
          ),
          _StepConfig(
            chapter: 2,
            builder: () => SchoolStep(
              schoolType: 'secondary',
              question: 'Ulisoma sekondari gani?',
              skipText: 'Ruka',
              defaultGradYear: dobYear + 17,
              state: _state,
              onNext: _next,
              onBack: _back,
            ),
          ),
        ];

      case EducationPath.alevel:
        return [
          _StepConfig(
            chapter: 2,
            builder: () => SchoolStep(
              schoolType: 'primary',
              question: 'Ulisoma shule gani ya msingi?',
              skipText: 'Ruka',
              defaultGradYear: dobYear + 13,
              state: _state,
              onNext: _next,
              onBack: _back,
            ),
          ),
          _StepConfig(
            chapter: 2,
            builder: () => SchoolStep(
              schoolType: 'secondary',
              question: 'Ulisoma sekondari gani?',
              skipText: 'Ruka',
              defaultGradYear: dobYear + 17,
              state: _state,
              onNext: _next,
              onBack: _back,
            ),
          ),
          _StepConfig(
            chapter: 2,
            builder: () => SchoolStep(
              schoolType: 'alevel',
              question: 'Kidato cha 5-6 ulisoma wapi?',
              skipText: 'Ruka',
              defaultGradYear: dobYear + 19,
              showCombination: true,
              state: _state,
              onNext: _next,
              onBack: _back,
            ),
          ),
        ];

      case EducationPath.postSecondary:
        return [
          _StepConfig(
            chapter: 2,
            builder: () => SchoolStep(
              schoolType: 'primary',
              question: 'Ulisoma shule gani ya msingi?',
              skipText: 'Ruka',
              defaultGradYear: dobYear + 13,
              state: _state,
              onNext: _next,
              onBack: _back,
            ),
          ),
          _StepConfig(
            chapter: 2,
            builder: () => SchoolStep(
              schoolType: 'secondary',
              question: 'Ulisoma sekondari gani?',
              skipText: 'Ruka',
              defaultGradYear: dobYear + 17,
              state: _state,
              onNext: _next,
              onBack: _back,
            ),
          ),
          _StepConfig(
            chapter: 2,
            builder: () => SchoolStep(
              schoolType: 'postsecondary',
              question: 'Ulisoma chuo gani?',
              skipText: 'Ruka',
              defaultGradYear: dobYear + 19,
              state: _state,
              onNext: _next,
              onBack: _back,
            ),
          ),
        ];

      case EducationPath.university:
        return [
          _StepConfig(
            chapter: 2,
            builder: () => SchoolStep(
              schoolType: 'primary',
              question: 'Ulisoma shule gani ya msingi?',
              skipText: 'Ruka',
              defaultGradYear: dobYear + 13,
              state: _state,
              onNext: _next,
              onBack: _back,
            ),
          ),
          _StepConfig(
            chapter: 2,
            builder: () => SchoolStep(
              schoolType: 'secondary',
              question: 'Ulisoma sekondari gani?',
              skipText: 'Ruka',
              defaultGradYear: dobYear + 17,
              state: _state,
              onNext: _next,
              onBack: _back,
            ),
          ),
          _StepConfig(
            chapter: 2,
            builder: () => UniversityStep(
              state: _state,
              onNext: _next,
              onBack: _back,
              onSkip: _next,
              defaultGradYear: dobYear + 22,
            ),
          ),
        ];
    }
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void _next() {
    final nextIndex = _currentStepIndex + 1;
    if (nextIndex >= _steps.length) {
      _complete();
      return;
    }

    final currentChapter = _steps[_currentStepIndex].chapter;
    final nextChapter = _steps[nextIndex].chapter;

    if (nextChapter > currentChapter) {
      // Chapter boundary crossed — show celebration.
      setState(() {
        _showCelebration = true;
        _celebrationChapter = currentChapter;
      });
    } else {
      _goToStep(nextIndex);
    }
  }

  void _back() {
    if (_currentStepIndex <= 0) return;
    _goToStep(_currentStepIndex - 1);
  }

  void _onEducationLevelNext() {
    setState(() {
      _steps = _buildSteps();
    });
    _next();
  }

  void _complete() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CompletionScreen(state: _state),
      ),
    );
  }

  void _dismissCelebration() {
    final nextIndex = _currentStepIndex + 1;
    setState(() {
      _showCelebration = false;
    });
    if (nextIndex < _steps.length) {
      _goToStep(nextIndex);
    }
  }

  void _goToStep(int index) {
    setState(() {
      _currentStepIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // ---------------------------------------------------------------------------
  // Chapter progress
  // ---------------------------------------------------------------------------

  int get _currentChapter => _steps[_currentStepIndex].chapter;

  double get _chapterProgress {
    final chapter = _currentChapter;
    final stepsInChapter =
        _steps.where((s) => s.chapter == chapter).toList();
    final indexInChapter = stepsInChapter.indexWhere(
      (s) => _steps.indexOf(s) == _currentStepIndex,
    );
    if (stepsInChapter.isEmpty) return 0.0;
    return (indexInChapter + 1) / stepsInChapter.length;
  }

  // ---------------------------------------------------------------------------
  // Exit confirmation
  // ---------------------------------------------------------------------------

  void _showExitConfirmation() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFFFAFAFA),
        title: const Text(
          'Unataka kuondoka?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        content: const Text(
          'Taarifa zako hazitahifadhiwa.',
          style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Hapana',
              style: TextStyle(color: Color(0xFF666666)),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Ndiyo'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentStepIndex == 0) {
          _showExitConfirmation();
        } else {
          _back();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: ChapterProgressBar(
                      currentChapter: _currentChapter,
                      chapterProgress: _chapterProgress,
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _steps.length,
                      itemBuilder: (_, i) => _steps[i].builder(),
                    ),
                  ),
                ],
              ),
              if (_showCelebration)
                Positioned.fill(
                  child: ChapterCelebration(
                    completedChapter: _celebrationChapter,
                    onDismiss: _dismissCelebration,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step configuration helper
// ---------------------------------------------------------------------------

class _StepConfig {
  /// Chapter index: 0=Kufahamiana, 1=Mahali, 2=Masomo, 3=Maisha.
  final int chapter;

  /// Builder to create the step widget. Not pre-built because steps reference
  /// mutable [RegistrationState].
  final Widget Function() builder;

  const _StepConfig({required this.chapter, required this.builder});
}
