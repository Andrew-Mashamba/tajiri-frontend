# Onboarding Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the 11-step registration stepper with a conversational, chapter-based onboarding flow that collects the same data but feels fun and low-friction.

**Architecture:** New `lib/screens/onboarding/` directory with a main controller (OnboardingScreen) managing 4 chapters via PageController. Each step is a standalone StatefulWidget receiving RegistrationState by reference. Reusable widgets (YearChipSelector, TapChipSelector, ChapterProgressBar) are shared across steps. Existing services (LocationService, SchoolService, SecondarySchoolService, AlevelSchoolService, UserService) are reused unchanged.

**Tech Stack:** Flutter 3 / Dart ^3.10.1, google_ml_kit (already in pubspec), existing Hive persistence via LocalStorageService

**Spec:** `docs/superpowers/specs/2026-03-29-onboarding-redesign-design.md`

---

## File Structure

### New Files

| File | Responsibility |
|------|---------------|
| `lib/widgets/year_chip_selector.dart` | Reusable horizontal scrollable year chip picker with smart default |
| `lib/widgets/tap_chip_selector.dart` | Reusable single-select vertical/horizontal chip picker |
| `lib/screens/onboarding/chapter_progress_bar.dart` | 4-bar chapter indicator widget |
| `lib/screens/onboarding/chapter_celebration.dart` | Between-chapter celebration overlay |
| `lib/screens/onboarding/steps/name_step.dart` | Chapter 1: Name + DOB + Gender |
| `lib/screens/onboarding/steps/photo_step.dart` | Chapter 1: Profile photo with ML Kit face detection |
| `lib/screens/onboarding/steps/phone_step.dart` | Chapter 2: Phone number input + availability check |
| `lib/screens/onboarding/steps/location_step.dart` | Chapter 2: Cascading region→district→ward→street |
| `lib/screens/onboarding/steps/education_level_step.dart` | Chapter 3: Education path choice (5 tap chips) |
| `lib/screens/onboarding/steps/school_step.dart` | Chapter 3: Reusable school search + year chips |
| `lib/screens/onboarding/steps/university_step.dart` | Chapter 3: University + programme + degree |
| `lib/screens/onboarding/steps/employer_step.dart` | Chapter 4: Employer search |
| `lib/screens/onboarding/completion_screen.dart` | Final celebration + profile preview + register API call |
| `lib/screens/onboarding/onboarding_screen.dart` | Main controller: chapter navigation, state, step sequencing |

### Modified Files

| File | Change |
|------|--------|
| `lib/models/registration_models.dart` | Add `EducationPath` enum, add `educationPath` field to `RegistrationState` |
| `lib/screens/login/login_screen.dart` | Change "Fungua Akaunti" navigation target from `RegistrationScreen` to `OnboardingScreen` |
| `lib/main.dart` | Add `/onboarding` route case |

---

## Existing Patterns to Follow

**Step widget pattern** (from existing `lib/screens/registration/steps/`):
```dart
class SomeStep extends StatefulWidget {
  final RegistrationState state;   // Shared state by reference
  final VoidCallback onNext;       // Signal completion
  final VoidCallback? onBack;      // Go back (null on first step)
  const SomeStep({super.key, required this.state, required this.onNext, this.onBack});
}
```
Steps modify `widget.state` directly, then call `widget.onNext()`.

**Service instantiation** (from existing RegistrationScreen):
```dart
final _locationService = LocationService(baseUrl: ApiConfig.baseUrl);
final _schoolService = SchoolService(baseUrl: ApiConfig.baseUrl);
final _secondaryService = SecondarySchoolService(baseUrl: ApiConfig.baseUrl);
final _alevelService = AlevelSchoolService(baseUrl: ApiConfig.baseUrl);
```

**Color constants** used throughout:
```dart
static const Color _background = Color(0xFFFAFAFA);
static const Color _primary = Color(0xFF1A1A1A);
static const Color _secondaryText = Color(0xFF666666);
```

**Localization access**: `final s = AppStringsScope.of(context);` with fallback: `s?.fieldName ?? 'Default'`

---

## Tasks

### Task 1: Add EducationPath Enum to Registration Models

**Files:**
- Modify: `lib/models/registration_models.dart`

- [ ] **Step 1: Add EducationPath enum after the Gender enum**

Add after the existing `Gender` enum (around line 170):

```dart
/// Education level for onboarding branching logic
enum EducationPath {
  primary,       // Shule ya Msingi
  secondary,     // Sekondari (O-Level)
  alevel,        // Kidato cha 5-6
  postSecondary, // Chuo
  university,    // Chuo Kikuu
}
```

- [ ] **Step 2: Add educationPath field to RegistrationState**

Add `EducationPath? educationPath;` field to the RegistrationState class fields section (after `didAttendAlevel`).

- [ ] **Step 3: Add educationPath to RegistrationState constructor**

Add `this.educationPath` to the constructor parameters.

- [ ] **Step 4: Add educationPath to toJson()**

In the `toJson()` method, add:
```dart
'education_path': educationPath?.name,
```

- [ ] **Step 5: Add educationPath to fromJson()**

In the `fromJson()` factory, add:
```dart
educationPath: json['education_path'] != null
    ? EducationPath.values.firstWhere(
        (e) => e.name == json['education_path'],
        orElse: () => EducationPath.primary,
      )
    : null,
```

- [ ] **Step 6: Verify no analysis errors**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/models/registration_models.dart
```
Expected: No errors.

- [ ] **Step 7: Commit**

```bash
git add lib/models/registration_models.dart
git commit -m "feat(onboarding): add EducationPath enum to registration models"
```

---

### Task 2: Create YearChipSelector Widget

**Files:**
- Create: `lib/widgets/year_chip_selector.dart`

- [ ] **Step 1: Create the widget**

```dart
import 'package:flutter/material.dart';

/// Horizontal scrollable year chip picker with smart default selection.
/// Used in education steps to quickly pick graduation years.
class YearChipSelector extends StatefulWidget {
  /// Center year for the chip range (typically calculated from DOB).
  final int defaultYear;

  /// Number of years to show on each side of defaultYear. Range = ±[yearRange].
  final int yearRange;

  /// Currently selected year (null = none selected).
  final int? selectedYear;

  /// Called when user taps a year chip.
  final ValueChanged<int> onYearSelected;

  const YearChipSelector({
    super.key,
    required this.defaultYear,
    this.yearRange = 3,
    this.selectedYear,
    required this.onYearSelected,
  });

  @override
  State<YearChipSelector> createState() => _YearChipSelectorState();
}

class _YearChipSelectorState extends State<YearChipSelector> {
  static const Color _primary = Color(0xFF1A1A1A);
  late final ScrollController _scrollController;

  List<int> get _years {
    final start = widget.defaultYear - widget.yearRange;
    final end = widget.defaultYear + widget.yearRange;
    return List.generate(end - start + 1, (i) => start + i);
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Scroll to center the default year after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected();
    });
  }

  void _scrollToSelected() {
    final targetYear = widget.selectedYear ?? widget.defaultYear;
    final index = _years.indexOf(targetYear);
    if (index >= 0 && _scrollController.hasClients) {
      // Each chip is roughly 72px wide (56 + 16 gap)
      final offset = (index * 72.0) - (MediaQuery.of(context).size.width / 2) + 36;
      _scrollController.animateTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: _years.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final year = _years[index];
          final isSelected = year == widget.selectedYear;
          return GestureDetector(
            onTap: () => widget.onYearSelected(year),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? _primary : Colors.white,
                border: Border.all(
                  color: isSelected ? _primary : const Color(0xFFE0E0E0),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$year',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : _primary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/widgets/year_chip_selector.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/year_chip_selector.dart
git commit -m "feat(onboarding): add YearChipSelector reusable widget"
```

---

### Task 3: Create TapChipSelector Widget

**Files:**
- Create: `lib/widgets/tap_chip_selector.dart`

- [ ] **Step 1: Create the widget**

```dart
import 'package:flutter/material.dart';

/// Single-select chip picker. Vertical by default, horizontal optional.
/// Used for gender, education level, degree level, and other enumerated choices.
class TapChipSelector<T> extends StatelessWidget {
  final List<T> options;
  final T? selectedOption;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onSelected;
  final bool horizontal;

  const TapChipSelector({
    super.key,
    required this.options,
    this.selectedOption,
    required this.labelBuilder,
    required this.onSelected,
    this.horizontal = false,
  });

  static const Color _primary = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    if (horizontal) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((option) => _buildChip(option)).toList(),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: options
          .map((option) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildChip(option),
              ))
          .toList(),
    );
  }

  Widget _buildChip(T option) {
    final isSelected = option == selectedOption;
    return GestureDetector(
      onTap: () => onSelected(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? _primary : Colors.white,
          border: Border.all(
            color: isSelected ? _primary : const Color(0xFFE0E0E0),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          labelBuilder(option),
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : _primary,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/widgets/tap_chip_selector.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/tap_chip_selector.dart
git commit -m "feat(onboarding): add TapChipSelector reusable widget"
```

---

### Task 4: Create ChapterProgressBar Widget

**Files:**
- Create: `lib/screens/onboarding/chapter_progress_bar.dart`

- [ ] **Step 1: Create the widget**

```dart
import 'package:flutter/material.dart';

/// 4-bar chapter progress indicator for onboarding.
/// Shows current chapter name and animated fill progress.
class ChapterProgressBar extends StatelessWidget {
  /// Current chapter index (0-3).
  final int currentChapter;

  /// Progress within current chapter (0.0 to 1.0).
  final double chapterProgress;

  /// Chapter names displayed below the bars.
  static const List<String> chapterNames = [
    'KUFAHAMIANA',
    'MAHALI',
    'MASOMO',
    'MAISHA',
  ];

  const ChapterProgressBar({
    super.key,
    required this.currentChapter,
    required this.chapterProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (index) {
            final double fill;
            if (index < currentChapter) {
              fill = 1.0; // Completed chapter
            } else if (index == currentChapter) {
              fill = chapterProgress; // Current chapter
            } else {
              fill = 0.0; // Future chapter
            }
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < 3 ? 8 : 0),
                child: _AnimatedBar(fill: fill),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          currentChapter < chapterNames.length
              ? chapterNames[currentChapter]
              : '',
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1,
            color: Color(0xFF666666),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _AnimatedBar extends StatelessWidget {
  final double fill;

  const _AnimatedBar({required this.fill});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: fill.clamp(0.0, 1.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/screens/onboarding/chapter_progress_bar.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/screens/onboarding/chapter_progress_bar.dart
git commit -m "feat(onboarding): add ChapterProgressBar widget"
```

---

### Task 5: Create ChapterCelebration Overlay

**Files:**
- Create: `lib/screens/onboarding/chapter_celebration.dart`

- [ ] **Step 1: Create the widget**

```dart
import 'package:flutter/material.dart';

/// Brief celebration overlay shown between chapters.
/// Fades in over 400ms, auto-dismisses after 1.5s or on tap.
class ChapterCelebration extends StatefulWidget {
  /// Completed chapter index (0-3).
  final int completedChapter;

  /// Called when celebration dismisses (auto or tap).
  final VoidCallback onDismiss;

  static const List<String> _chapterNames = [
    'Kufahamiana',
    'Mahali',
    'Masomo',
    'Maisha',
  ];

  const ChapterCelebration({
    super.key,
    required this.completedChapter,
    required this.onDismiss,
  });

  @override
  State<ChapterCelebration> createState() => _ChapterCelebrationState();
}

class _ChapterCelebrationState extends State<ChapterCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();

    // Auto-dismiss after 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1900), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _message {
    final name = ChapterCelebration._chapterNames[widget.completedChapter];
    final next = widget.completedChapter + 1;
    if (next < ChapterCelebration._chapterNames.length) {
      final nextName = ChapterCelebration._chapterNames[next];
      return '$name ✓ — Umefanya vizuri!\nTwende $nextName...';
    }
    return '$name ✓ — Umefanya vizuri!';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          color: const Color(0xFFFAFAFA),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated checkmark
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.5 + (value * 0.5),
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1A1A1A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/screens/onboarding/chapter_celebration.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/screens/onboarding/chapter_celebration.dart
git commit -m "feat(onboarding): add ChapterCelebration overlay"
```

---

### Task 6: Create NameStep (Chapter 1, Screen 1)

**Files:**
- Create: `lib/screens/onboarding/steps/name_step.dart`

**Context:** This is the first screen. Collects firstName, lastName, dateOfBirth, gender. Uses TapChipSelector for gender. All fields required. DOB must make user 13+ years old.

- [ ] **Step 1: Create the step widget**

```dart
import 'package:flutter/material.dart';
import '../../../models/registration_models.dart';
import '../../../widgets/tap_chip_selector.dart';
import '../../../l10n/app_strings_scope.dart';

/// Chapter 1, Screen 1: Name + Date of Birth + Gender
class NameStep extends StatefulWidget {
  final RegistrationState state;
  final VoidCallback onNext;

  const NameStep({
    super.key,
    required this.state,
    required this.onNext,
  });

  @override
  State<NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<NameStep> {
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);
  static const Color _background = Color(0xFFFAFAFA);

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  DateTime? _selectedDate;
  Gender? _selectedGender;
  String? _error;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.state.firstName ?? '');
    _lastNameController = TextEditingController(text: widget.state.lastName ?? '');
    _selectedDate = widget.state.dateOfBirth;
    _selectedGender = widget.state.gender;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    return first.length >= 2 &&
        last.length >= 2 &&
        _selectedDate != null &&
        _selectedGender != null;
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _error = null;
      });
    }
  }

  void _submit() {
    if (!_isValid) {
      setState(() => _error = 'Tafadhali jaza taarifa zote');
      return;
    }

    // Check age >= 13
    final age = DateTime.now().difference(_selectedDate!).inDays ~/ 365;
    if (age < 13) {
      setState(() => _error = 'Lazima uwe na miaka 13 au zaidi');
      return;
    }

    widget.state.firstName = _firstNameController.text.trim();
    widget.state.lastName = _lastNameController.text.trim();
    widget.state.dateOfBirth = _selectedDate;
    widget.state.gender = _selectedGender;
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Jina lako ni nani?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _primary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tuambie jina lako na tarehe ya kuzaliwa',
            style: TextStyle(fontSize: 13, color: _secondaryText),
          ),
          const SizedBox(height: 24),

          // First name
          _buildTextField(
            controller: _firstNameController,
            hint: 'Jina la kwanza',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),

          // Last name
          _buildTextField(
            controller: _lastNameController,
            hint: 'Jina la mwisho',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),

          // Date of birth
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, color: _primary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'Chagua tarehe ya kuzaliwa',
                    style: TextStyle(
                      fontSize: 15,
                      color: _selectedDate != null ? _primary : _secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Gender
          const Text(
            'Jinsia',
            style: TextStyle(fontSize: 13, color: _secondaryText),
          ),
          const SizedBox(height: 8),
          TapChipSelector<Gender>(
            options: Gender.values,
            selectedOption: _selectedGender,
            labelBuilder: (g) => g == Gender.male ? 'Me' : 'Ke',
            onSelected: (g) => setState(() {
              _selectedGender = g;
              _error = null;
            }),
            horizontal: true,
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],

          const SizedBox(height: 24),

          // Continue button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isValid ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE0E0E0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Endelea →',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: (_) => setState(() => _error = null),
        style: const TextStyle(fontSize: 15, color: _primary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _secondaryText),
          prefixIcon: Icon(icon, color: _primary, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/screens/onboarding/steps/name_step.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/screens/onboarding/steps/name_step.dart
git commit -m "feat(onboarding): add NameStep — Chapter 1 Screen 1"
```

---

### Task 7: Create PhotoStep (Chapter 1, Screen 2)

**Files:**
- Create: `lib/screens/onboarding/steps/photo_step.dart`

**Context:** Uses existing `google_ml_kit` (already in pubspec) and `image_picker`. Must detect exactly 1 face, store faceBbox. Uses existing FaceValidator pattern from `lib/utils/face_validator.dart` if it exists, otherwise inline. Camera permission handling required.

- [ ] **Step 1: Check if face_validator.dart exists**

```bash
find /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib -name "face_validator*" -o -name "face_detect*" 2>/dev/null
```

If it exists, import and use it. If not, implement face detection inline using `google_ml_kit`.

- [ ] **Step 2: Create the step widget**

Build `photo_step.dart` following the existing `lib/screens/registration/steps/profile_photo_step.dart` pattern closely. Key elements:
- Camera preview with oval face guide overlay
- `ImagePicker` for camera capture and gallery selection
- `google_ml_kit` `FaceDetector` for validation
- Real-time feedback text: "Sogeza uso katikati", "Karibia zaidi", "Poa! Uso unaonekana vizuri"
- Store validated photo path in `widget.state.profilePhotoPath`
- Store face bounding box as `[x, y, width, height]` in `widget.state.faceBbox`
- Handle camera permission denied: show "Tunahitaji ruhusa ya kamera. Fungua Mipangilio." with `openAppSettings()` from `permission_handler`
- "Piga Picha" primary button, "Chagua kutoka Galeri" text button
- "Endelea →" enabled only when photo with valid face captured

**Important:** Read the existing `lib/screens/registration/steps/profile_photo_step.dart` first and reuse as much logic as possible. The new step should have the same face detection logic but with the new conversational UI pattern (question title, supporting text, bottom CTA).

- [ ] **Step 3: Verify no analysis errors**

```bash
flutter analyze lib/screens/onboarding/steps/photo_step.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/screens/onboarding/steps/photo_step.dart
git commit -m "feat(onboarding): add PhotoStep with ML Kit face detection — Chapter 1 Screen 2"
```

---

### Task 8: Create PhoneStep (Chapter 2, Screen 1)

**Files:**
- Create: `lib/screens/onboarding/steps/phone_step.dart`

**Context:** Phone input with +255 prefix. On submit, checks availability via `UserService().checkPhoneAvailability(normalized)`. If taken, shows message with link to LoginScreen. Sets `isPhoneVerified = true` after format validation.

- [ ] **Step 1: Create the step widget**

```dart
import 'package:flutter/material.dart';
import '../../../models/registration_models.dart';
import '../../../services/user_service.dart';
import '../../login/login_screen.dart';

/// Chapter 2, Screen 1: Phone number with availability check
class PhoneStep extends StatefulWidget {
  final RegistrationState state;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const PhoneStep({
    super.key,
    required this.state,
    required this.onNext,
    this.onBack,
  });

  @override
  State<PhoneStep> createState() => _PhoneStepState();
}

class _PhoneStepState extends State<PhoneStep> {
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);

  final _phoneController = TextEditingController();
  final _userService = UserService();
  bool _isChecking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pre-fill if user navigated back
    final existing = widget.state.phoneNumber;
    if (existing != null && existing.startsWith('+255')) {
      _phoneController.text = existing.substring(4); // Remove +255
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String get _normalized {
    final raw = _phoneController.text.replaceAll(RegExp(r'\s+'), '');
    if (raw.startsWith('0') && raw.length == 10) {
      return '+255${raw.substring(1)}';
    }
    return '+255$raw';
  }

  bool get _isValidFormat {
    final raw = _phoneController.text.replaceAll(RegExp(r'\s+'), '');
    // Accept 9 digits (without leading 0) or 10 digits (with leading 0)
    return (raw.length == 9 && !raw.startsWith('0')) ||
        (raw.length == 10 && raw.startsWith('0'));
  }

  Future<void> _submit() async {
    if (!_isValidFormat) {
      setState(() => _error = 'Nambari ya simu si sahihi');
      return;
    }

    setState(() {
      _isChecking = true;
      _error = null;
    });

    try {
      final result = await _userService.checkPhoneAvailability(_normalized);

      if (!mounted) return;

      if (!result.available) {
        setState(() {
          _isChecking = false;
          _error = null;
        });
        // Show taken dialog
        _showPhoneTakenDialog();
        return;
      }

      // Phone is available
      widget.state.phoneNumber = _normalized;
      widget.state.isPhoneVerified = true; // Format-validated, no OTP
      widget.onNext();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isChecking = false;
        _error = 'Imeshindwa kuwasiliana na seva. Jaribu tena.';
      });
    }
  }

  void _showPhoneTakenDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Nambari imeshasajiliwa',
          style: TextStyle(color: _primary, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Nambari hii imeshasajiliwa. Ingia badala yake?',
          style: TextStyle(color: _secondaryText, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hapana', style: TextStyle(color: _secondaryText)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Ingia', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Nambari yako ya simu?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _primary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tutatumia hii kukuunganisha na marafiki',
            style: TextStyle(fontSize: 13, color: _secondaryText),
          ),
          const SizedBox(height: 24),

          // Phone input with +255 prefix
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: Color(0xFFE0E0E0))),
                  ),
                  child: const Text(
                    '+255',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _primary),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    onChanged: (_) => setState(() => _error = null),
                    onSubmitted: (_) => _submit(),
                    style: const TextStyle(fontSize: 15, color: _primary),
                    decoration: InputDecoration(
                      hintText: '712 345 678',
                      hintStyle: const TextStyle(color: _secondaryText),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isChecking ? null : (_isValidFormat ? _submit : null),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE0E0E0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isChecking
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Endelea →',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/screens/onboarding/steps/phone_step.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/screens/onboarding/steps/phone_step.dart
git commit -m "feat(onboarding): add PhoneStep with availability check — Chapter 2 Screen 1"
```

---

### Task 9: Create LocationStep (Chapter 2, Screen 2)

**Files:**
- Create: `lib/screens/onboarding/steps/location_step.dart`

**Context:** Cascading search: Region → District → Ward → Street. Uses existing `LocationService` with methods `getRegions()`, `getDistricts(regionId)`, `getWards(districtId)`, `getStreets(wardId)`. Ward and Street are optional. Skip text: "Sitaki kusema". Stores result in `widget.state.location` as `LocationSelection`.

- [ ] **Step 1: Create the step widget**

Build the location step with:
- Conversational question: "Unaishi wapi?" / "Hii husaidia kupata watu wa karibu nawe"
- Region search text field with type-ahead dropdown
- After region selected, show district search
- After district, optionally show ward search
- After ward, optionally show street search
- Each level slides in smoothly after previous selection
- Skip button: "Sitaki kusema"
- "Endelea →" button (enabled after at least region + district selected, or on skip)
- Uses `LocationService(baseUrl: ApiConfig.baseUrl)` for API calls
- Stores in `widget.state.location = LocationSelection(regionId: ..., regionName: ..., ...)`

Read the existing `lib/screens/registration/steps/location_step.dart` for reference on how cascading search is implemented, and adapt to the new conversational UI pattern.

- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/screens/onboarding/steps/location_step.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/screens/onboarding/steps/location_step.dart
git commit -m "feat(onboarding): add LocationStep with cascading search — Chapter 2 Screen 2"
```

---

### Task 10: Create EducationLevelStep (Chapter 3, Screen 1)

**Files:**
- Create: `lib/screens/onboarding/steps/education_level_step.dart`

- [ ] **Step 1: Create the step widget**

```dart
import 'package:flutter/material.dart';
import '../../../models/registration_models.dart';
import '../../../widgets/tap_chip_selector.dart';

/// Chapter 3, Screen 1: Education level choice.
/// Determines which subsequent education screens appear.
class EducationLevelStep extends StatefulWidget {
  final RegistrationState state;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const EducationLevelStep({
    super.key,
    required this.state,
    required this.onNext,
    this.onBack,
  });

  @override
  State<EducationLevelStep> createState() => _EducationLevelStepState();
}

class _EducationLevelStepState extends State<EducationLevelStep> {
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);

  EducationPath? _selected;

  static const _labels = {
    EducationPath.primary: 'Shule ya Msingi',
    EducationPath.secondary: 'Sekondari',
    EducationPath.alevel: 'Kidato cha 5-6',
    EducationPath.postSecondary: 'Chuo',
    EducationPath.university: 'Chuo Kikuu',
  };

  @override
  void initState() {
    super.initState();
    _selected = widget.state.educationPath;
  }

  void _submit() {
    if (_selected == null) return;

    widget.state.educationPath = _selected;
    // Set didAttendAlevel based on education path
    widget.state.didAttendAlevel = _selected == EducationPath.alevel;

    // Clear downstream education data if path changed
    // (user went back and changed their choice)
    _clearDownstreamEducation();

    widget.onNext();
  }

  void _clearDownstreamEducation() {
    switch (_selected!) {
      case EducationPath.primary:
        widget.state.secondarySchool = null;
        widget.state.alevelEducation = null;
        widget.state.postsecondaryEducation = null;
        widget.state.universityEducation = null;
        break;
      case EducationPath.secondary:
        widget.state.alevelEducation = null;
        widget.state.postsecondaryEducation = null;
        widget.state.universityEducation = null;
        break;
      case EducationPath.alevel:
        widget.state.postsecondaryEducation = null;
        widget.state.universityEducation = null;
        break;
      case EducationPath.postSecondary:
        widget.state.alevelEducation = null;
        widget.state.universityEducation = null;
        break;
      case EducationPath.university:
        widget.state.alevelEducation = null;
        widget.state.postsecondaryEducation = null;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Umesoma hadi wapi?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _primary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Chagua kiwango chako cha juu cha elimu',
            style: TextStyle(fontSize: 13, color: _secondaryText),
          ),
          const SizedBox(height: 24),

          TapChipSelector<EducationPath>(
            options: EducationPath.values,
            selectedOption: _selected,
            labelBuilder: (path) => _labels[path] ?? path.name,
            onSelected: (path) => setState(() => _selected = path),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selected != null ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE0E0E0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'Endelea →',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/screens/onboarding/steps/education_level_step.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/screens/onboarding/steps/education_level_step.dart
git commit -m "feat(onboarding): add EducationLevelStep with branching — Chapter 3 Screen 1"
```

---

### Task 11: Create SchoolStep (Reusable for Primary, Secondary, A-Level, Post-Secondary)

**Files:**
- Create: `lib/screens/onboarding/steps/school_step.dart`

**Context:** Reusable step that accepts configuration via constructor. Used for 4 different education levels. Constructor:
```dart
SchoolStep({
  required String schoolType,      // 'primary', 'secondary', 'alevel', 'postsecondary'
  required String question,        // e.g. "Ulisoma msingi wapi?"
  required String skipText,        // e.g. "Sijasoma msingi"
  required int defaultGradYear,    // Calculated from DOB
  int yearRange = 3,
  bool showCombination = false,    // true only for A-Level
  required RegistrationState state,
  required VoidCallback onNext,
  VoidCallback? onBack,
  VoidCallback? onSkip,
})
```

- [ ] **Step 1: Create the step widget**

Build `school_step.dart` with:
- Conversational question title from `question` parameter
- School search field using:
  - `SchoolService` for `schoolType == 'primary'`
  - `SecondarySchoolService` for `schoolType == 'secondary'`
  - `AlevelSchoolService` for `schoolType == 'alevel'`
  - For `schoolType == 'postsecondary'`: use a generic institution search (check existing services)
- Type-ahead dropdown showing search results
- `YearChipSelector` with `defaultYear` from constructor, `yearRange` from constructor
- If `showCombination == true`: additional combination search field using `AlevelSchoolService.getCombinations()` or `getSchoolCombinations(schoolId)`
- Skip button with `skipText` label, calls `onSkip` callback
- "Endelea →" button enabled when school selected + year selected (+ combination if A-Level)
- On submit: create appropriate model (`EducationEntry` or `AlevelEducation`) and store in `widget.state`

Read the existing step files for reference:
- `lib/screens/registration/steps/primary_school_step.dart` — school search pattern
- `lib/screens/registration/steps/alevel_step.dart` — combination search pattern

Store results in the correct state field based on `schoolType`:
- `'primary'` → `widget.state.primarySchool = EducationEntry(...)`
- `'secondary'` → `widget.state.secondarySchool = EducationEntry(...)`
- `'alevel'` → `widget.state.alevelEducation = AlevelEducation(...)`
- `'postsecondary'` → `widget.state.postsecondaryEducation = EducationEntry(...)`

- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/screens/onboarding/steps/school_step.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/screens/onboarding/steps/school_step.dart
git commit -m "feat(onboarding): add reusable SchoolStep for all education levels"
```

---

### Task 12: Create UniversityStep (Chapter 3)

**Files:**
- Create: `lib/screens/onboarding/steps/university_step.dart`

**Context:** University search + programme search + degree level chips + "Bado nasoma" toggle + year chips. Uses existing patterns but is a dedicated step because it has more fields than SchoolStep.

- [ ] **Step 1: Create the step widget**

Build `university_step.dart` with:
- Question: "Chuo Kikuu gani?" / "Na programme yako"
- University search (check existing services for university lookup — may be in a general school service or dedicated endpoint)
- Programme search filtered by selected university
- Degree level: `TapChipSelector` with options "Shahada" (Bachelor) / "Uzamili" (Masters) / "Uzamivu" (PhD), horizontal layout
- "Bado nasoma" toggle (Switch or Checkbox)
- Year chips for graduation/expected graduation
- Skip: "Sijaenda chuo kikuu"
- Store in `widget.state.universityEducation = UniversityEducation(...)`

Read `lib/screens/registration/steps/university_step.dart` for the existing implementation pattern and service usage.

- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/screens/onboarding/steps/university_step.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/screens/onboarding/steps/university_step.dart
git commit -m "feat(onboarding): add UniversityStep — Chapter 3"
```

---

### Task 13: Create EmployerStep (Chapter 4)

**Files:**
- Create: `lib/screens/onboarding/steps/employer_step.dart`

- [ ] **Step 1: Create the step widget**

```dart
import 'package:flutter/material.dart';
import '../../../models/registration_models.dart';
import '../../../config/api_config.dart';
import '../../../widgets/tap_chip_selector.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Chapter 4, Screen 1: Current employer search
class EmployerStep extends StatefulWidget {
  final RegistrationState state;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  const EmployerStep({
    super.key,
    required this.state,
    required this.onNext,
    this.onBack,
    this.onSkip,
  });

  @override
  State<EmployerStep> createState() => _EmployerStepState();
}

class _EmployerStepState extends State<EmployerStep> {
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);

  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  Map<String, dynamic>? _selectedEmployer;
  bool _isCustom = false;
  String? _customSector;
  bool _isSearching = false;

  static const _sectors = [
    'Teknolojia', 'Elimu', 'Afya', 'Biashara', 'Serikali', 'Nyingine',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill if user navigated back
    if (widget.state.currentEmployer != null) {
      _searchController.text = widget.state.currentEmployer!.employerName ?? '';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/employers?q=${Uri.encodeComponent(query)}&limit=10'),
        headers: ApiConfig.headers,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data is List ? data : (data['data'] is List ? data['data'] : []);
        setState(() {
          _results = List<Map<String, dynamic>>.from(list);
          _isSearching = false;
        });
      } else {
        setState(() {
          _results = [];
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectEmployer(Map<String, dynamic> employer) {
    setState(() {
      _selectedEmployer = employer;
      _searchController.text = employer['name'] ?? employer['employer_name'] ?? '';
      _results = [];
      _isCustom = false;
    });
  }

  void _enableCustom() {
    setState(() {
      _isCustom = true;
      _selectedEmployer = null;
      _results = [];
    });
  }

  void _submit() {
    if (_isCustom) {
      final name = _searchController.text.trim();
      if (name.isEmpty) return;
      widget.state.currentEmployer = EmployerEntry(
        employerName: name,
        sector: _customSector,
        isCustomEmployer: true,
      );
    } else if (_selectedEmployer != null) {
      widget.state.currentEmployer = EmployerEntry(
        employerId: _selectedEmployer!['id'],
        employerCode: _selectedEmployer!['code'],
        employerName: _selectedEmployer!['name'] ?? _selectedEmployer!['employer_name'],
        sector: _selectedEmployer!['sector'],
        ownership: _selectedEmployer!['ownership'],
        isCustomEmployer: false,
      );
    } else {
      return;
    }
    widget.onNext();
  }

  bool get _canSubmit {
    if (_isCustom) return _searchController.text.trim().isNotEmpty;
    return _selectedEmployer != null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Unafanya kazi wapi sasa?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _primary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Kampuni au biashara yako',
            style: TextStyle(fontSize: 13, color: _secondaryText),
          ),
          const SizedBox(height: 24),

          // Employer search
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (q) {
                _search(q);
                setState(() {
                  _selectedEmployer = null;
                  _isCustom = false;
                });
              },
              style: const TextStyle(fontSize: 15, color: _primary),
              decoration: InputDecoration(
                hintText: 'Tafuta kampuni...',
                hintStyle: const TextStyle(color: _secondaryText),
                prefixIcon: const Icon(Icons.search, color: _primary, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),

          // Search results
          if (_results.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _results.length + 1, // +1 for "add custom"
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index == _results.length) {
                    return ListTile(
                      leading: const Icon(Icons.add, color: _primary),
                      title: const Text(
                        'Ongeza kampuni',
                        style: TextStyle(color: _primary, fontWeight: FontWeight.w500),
                      ),
                      onTap: _enableCustom,
                    );
                  }
                  final emp = _results[index];
                  return ListTile(
                    title: Text(
                      emp['name'] ?? emp['employer_name'] ?? '',
                      style: const TextStyle(color: _primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: emp['sector'] != null
                        ? Text(emp['sector'], style: const TextStyle(color: _secondaryText, fontSize: 12))
                        : null,
                    onTap: () => _selectEmployer(emp),
                  );
                },
              ),
            ),

          // Custom employer sector
          if (_isCustom) ...[
            const SizedBox(height: 16),
            const Text('Sekta', style: TextStyle(fontSize: 13, color: _secondaryText)),
            const SizedBox(height: 8),
            TapChipSelector<String>(
              options: _sectors,
              selectedOption: _customSector,
              labelBuilder: (s) => s,
              onSelected: (s) => setState(() => _customSector = s),
              horizontal: true,
            ),
          ],

          const SizedBox(height: 24),

          // Bottom actions
          Row(
            children: [
              // Skip
              TextButton(
                onPressed: () {
                  widget.state.currentEmployer = null;
                  widget.onSkip?.call() ?? widget.onNext();
                },
                child: const Text(
                  'Sina kazi kwa sasa',
                  style: TextStyle(fontSize: 13, color: _secondaryText),
                ),
              ),
              const Spacer(),
              // Continue
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE0E0E0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                  ),
                  child: const Text(
                    'Endelea →',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/screens/onboarding/steps/employer_step.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/screens/onboarding/steps/employer_step.dart
git commit -m "feat(onboarding): add EmployerStep — Chapter 4"
```

---

### Task 14: Create CompletionScreen

**Files:**
- Create: `lib/screens/onboarding/completion_screen.dart`

- [ ] **Step 1: Create the completion screen**

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/registration_models.dart';
import '../../services/user_service.dart';
import '../../services/local_storage_service.dart';
import '../home/home_screen.dart';

/// Final onboarding screen: celebration + profile preview + register API call.
class CompletionScreen extends StatefulWidget {
  final RegistrationState state;

  const CompletionScreen({super.key, required this.state});

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isRegistering = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _isRegistering = true;
      _error = null;
    });

    try {
      final result = await UserService().register(widget.state);

      if (!mounted) return;

      if (result.success && result.accessToken != null) {
        final storage = await LocalStorageService.getInstance();
        await storage.saveAuthToken(result.accessToken!);

        // Apply server-returned data (userId, profile photo URL)
        if (result.profileData != null) {
          widget.state.applyServerProfile(result.profileData!);
        }
        if (result.userId != null) {
          widget.state.userId = result.userId;
        }

        await storage.saveUser(widget.state);

        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => HomeScreen(currentUserId: widget.state.userId!),
          ),
          (route) => false,
        );
      } else {
        setState(() {
          _isRegistering = false;
          _error = result.message ?? 'Imeshindwa kuwasiliana na seva. Jaribu tena.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRegistering = false;
        _error = 'Imeshindwa kuwasiliana na seva. Jaribu tena.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated checkmark
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: _primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Hongera! Uko tayari!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
                const SizedBox(height: 32),

                // Profile preview card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Photo
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFFE0E0E0),
                        backgroundImage: widget.state.profilePhotoPath != null
                            ? FileImage(File(widget.state.profilePhotoPath!))
                            : null,
                        child: widget.state.profilePhotoPath == null
                            ? const Icon(Icons.person, size: 40, color: _secondaryText)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      // Name
                      Text(
                        '${widget.state.firstName ?? ''} ${widget.state.lastName ?? ''}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Highest school
                      Text(
                        _highestSchoolName,
                        style: const TextStyle(fontSize: 13, color: _secondaryText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 32),

                // Register button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isRegistering ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE0E0E0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isRegistering
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Anza TAJIRI →',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _highestSchoolName {
    if (widget.state.universityEducation?.universityName != null) {
      return widget.state.universityEducation!.universityName!;
    }
    if (widget.state.postsecondaryEducation?.schoolName != null) {
      return widget.state.postsecondaryEducation!.schoolName!;
    }
    if (widget.state.alevelEducation?.schoolName != null) {
      return widget.state.alevelEducation!.schoolName!;
    }
    if (widget.state.secondarySchool?.schoolName != null) {
      return widget.state.secondarySchool!.schoolName!;
    }
    if (widget.state.primarySchool?.schoolName != null) {
      return widget.state.primarySchool!.schoolName!;
    }
    return '';
  }
}
```

- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/screens/onboarding/completion_screen.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/screens/onboarding/completion_screen.dart
git commit -m "feat(onboarding): add CompletionScreen with registration + profile preview"
```

---

### Task 15: Create OnboardingScreen (Main Controller)

**Files:**
- Create: `lib/screens/onboarding/onboarding_screen.dart`

**Context:** This is the main orchestrator. Manages:
1. A `RegistrationState` instance
2. A `PageController` for smooth transitions between steps
3. Chapter tracking (which chapter, which step within chapter)
4. Dynamic step list based on education path choice
5. Chapter celebration overlays between chapters
6. Back navigation (within chapter and across chapters)

- [ ] **Step 1: Create the controller screen**

Key implementation details:

```dart
import 'package:flutter/material.dart';
import '../../models/registration_models.dart';
import 'chapter_progress_bar.dart';
import 'chapter_celebration.dart';
import 'completion_screen.dart';
import 'steps/name_step.dart';
import 'steps/photo_step.dart';
import 'steps/phone_step.dart';
import 'steps/location_step.dart';
import 'steps/education_level_step.dart';
import 'steps/school_step.dart';
import 'steps/university_step.dart';
import 'steps/employer_step.dart';
```

**State structure:**
- `RegistrationState _state = RegistrationState()` — shared mutable state
- `PageController _pageController` — manages transitions
- `int _currentStepIndex = 0` — index into the dynamic step list
- `bool _showCelebration = false` — controls celebration overlay
- `int _celebrationChapter = 0` — which chapter just completed

**Dynamic step list:** Built as a method that returns `List<Widget>` based on `_state.educationPath`:

```dart
List<_StepConfig> get _steps {
  final dobYear = _state.dateOfBirth?.year ?? DateTime.now().year - 18;
  return [
    // Chapter 0: Kufahamiana
    _StepConfig(chapter: 0, widget: NameStep(state: _state, onNext: _next)),
    _StepConfig(chapter: 0, widget: PhotoStep(state: _state, onNext: _next, onBack: _back)),
    // Chapter 1: Mahali
    _StepConfig(chapter: 1, widget: PhoneStep(state: _state, onNext: _next, onBack: _back)),
    _StepConfig(chapter: 1, widget: LocationStep(state: _state, onNext: _next, onBack: _back, onSkip: _next)),
    // Chapter 2: Masomo
    _StepConfig(chapter: 2, widget: EducationLevelStep(state: _state, onNext: _next, onBack: _back)),
    // Dynamic education steps based on path...
    ..._educationSteps(dobYear),
    // Chapter 3: Maisha
    _StepConfig(chapter: 3, widget: EmployerStep(state: _state, onNext: _complete, onBack: _back, onSkip: _complete)),
  ];
}
```

**Education steps builder:**
```dart
List<_StepConfig> _educationSteps(int dobYear) {
  final path = _state.educationPath;
  if (path == null) return [];

  final steps = <_StepConfig>[];

  // Always show primary
  steps.add(_StepConfig(chapter: 2, widget: SchoolStep(
    schoolType: 'primary', question: 'Ulisoma msingi wapi?',
    skipText: 'Sijasoma msingi', defaultGradYear: dobYear + 13,
    state: _state, onNext: _next, onBack: _back, onSkip: _next,
  )));

  // Secondary for secondary+
  if ([EducationPath.secondary, EducationPath.alevel, EducationPath.postSecondary, EducationPath.university].contains(path)) {
    steps.add(_StepConfig(chapter: 2, widget: SchoolStep(
      schoolType: 'secondary', question: 'Ulisoma sekondari wapi?',
      skipText: 'Sijasoma sekondari', defaultGradYear: dobYear + 17,
      state: _state, onNext: _next, onBack: _back, onSkip: _next,
    )));
  }

  // A-Level
  if (path == EducationPath.alevel) {
    steps.add(_StepConfig(chapter: 2, widget: SchoolStep(
      schoolType: 'alevel', question: 'Ulisoma kidato cha 5-6 wapi?',
      skipText: 'Sijaenda kidato cha 5-6', defaultGradYear: dobYear + 19,
      showCombination: true,
      state: _state, onNext: _next, onBack: _back, onSkip: _next,
    )));
  }

  // Post-secondary
  if (path == EducationPath.postSecondary) {
    steps.add(_StepConfig(chapter: 2, widget: SchoolStep(
      schoolType: 'postsecondary', question: 'Ulisoma chuo gani?',
      skipText: 'Sijaenda chuo', defaultGradYear: dobYear + 19,
      state: _state, onNext: _next, onBack: _back, onSkip: _next,
    )));
  }

  // University
  if (path == EducationPath.university) {
    steps.add(_StepConfig(chapter: 2, widget: UniversityStep(
      state: _state, onNext: _next, onBack: _back, onSkip: _next,
      defaultGradYear: dobYear + 22,
    )));
  }

  return steps;
}
```

**Navigation methods:**
- `_next()` — increment step, check if crossing chapter boundary → show celebration. Use `_pageController.animateToPage(index, duration: Duration(milliseconds: 300), curve: Curves.easeInOut)`
- `_back()` — decrement step, if at first step show exit confirmation dialog: "Unataka kuondoka?" with "Hapana" / "Ndiyo" buttons
- `_complete()` — navigate to `CompletionScreen`
- Chapter boundary detection: compare `_steps[current].chapter` with `_steps[next].chapter`

**Critical: Dynamic step list index management when education path changes:**

The step list is dynamic — it changes when the user selects an education path in `EducationLevelStep`. Do NOT rebuild steps as a getter. Instead:

1. Build initial steps (chapters 0, 1, and the education level step only) in `initState`
2. When `EducationLevelStep.onNext` is called, rebuild the full step list with the correct education sub-steps appended
3. Store steps in a `List<_StepConfig> _steps` field (not a getter)
4. When user goes back to education level and changes their choice: clear downstream data via `_clearDownstreamEducation()`, rebuild `_steps` with new education sub-steps, set `_currentStepIndex` to the education level step index + 1, and call `_pageController.jumpToPage(_currentStepIndex)`
5. The `_next()` callback from `EducationLevelStep` should trigger `setState(() { _steps = _buildSteps(); })` before advancing

```dart
// In OnboardingScreen state:
late List<_StepConfig> _steps;

@override
void initState() {
  super.initState();
  _steps = _buildSteps();
}

void _onEducationLevelNext() {
  // Rebuild steps with new education sub-steps
  setState(() {
    _steps = _buildSteps();
  });
  _next(); // Advance to first education sub-step
}
```

**Exit confirmation on first step** (wrap Scaffold in PopScope):
```dart
PopScope(
  canPop: _currentStepIndex == 0 ? false : true,
  onPopInvokedWithResult: (didPop, _) {
    if (didPop) return;
    if (_currentStepIndex == 0) {
      _showExitConfirmation();
    } else {
      _back();
    }
  },
  child: Scaffold(...),
)
```

```dart
void _showExitConfirmation() {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('Unataka kuondoka?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: const Text('Taarifa zako hazitahifadhiwa.', style: TextStyle(color: Color(0xFF666666))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hapana')),
        ElevatedButton(
          onPressed: () { Navigator.pop(ctx); Navigator.of(context).pop(); },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A)),
          child: const Text('Ndiyo', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
```

**Chapter progress calculation:**
- `currentChapter` = `_steps[_currentStepIndex].chapter`
- `chapterProgress` = (steps completed in current chapter) / (total steps in current chapter)

**Back button / Android back gesture:**
- Override `WillPopScope` (or `PopScope` in newer Flutter)
- On first step: show "Unataka kuondoka?" confirmation dialog
- Otherwise: call `_back()`

**Build method structure:**
```dart
Scaffold(
  backgroundColor: _background,
  body: SafeArea(
    child: Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: ChapterProgressBar(currentChapter: ..., chapterProgress: ...),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _steps.length,
                itemBuilder: (_, i) => _steps[i].widget,
              ),
            ),
          ],
        ),
        if (_showCelebration)
          ChapterCelebration(
            completedChapter: _celebrationChapter,
            onDismiss: _dismissCelebration,
          ),
      ],
    ),
  ),
)
```

**Helper class:**
```dart
class _StepConfig {
  final int chapter;
  final Widget widget;
  const _StepConfig({required this.chapter, required this.widget});
}
```

- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/screens/onboarding/onboarding_screen.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/screens/onboarding/onboarding_screen.dart
git commit -m "feat(onboarding): add OnboardingScreen main controller with chapter navigation"
```

---

### Task 16: Wire Up Routes and Navigation

**Files:**
- Modify: `lib/screens/login/login_screen.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Update LoginScreen navigation**

In `lib/screens/login/login_screen.dart`:

1. Add import: `import '../onboarding/onboarding_screen.dart';`
2. Find the "Fungua Akaunti" `OutlinedButton` `onPressed` callback (around line 232-237)
3. Change `RegistrationScreen()` to `const OnboardingScreen()`

Before:
```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => const RegistrationScreen(),
  ),
);
```

After:
```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => const OnboardingScreen(),
  ),
);
```

4. Update import: change `import '../registration/registration_screen.dart';` to `import '../onboarding/onboarding_screen.dart';` (remove old import if RegistrationScreen is no longer referenced).

- [ ] **Step 2: Add /onboarding route to main.dart**

In `lib/main.dart`, find the `onGenerateRoute` switch statement. Add a new case near the other screen routes:

```dart
case 'onboarding':
  return MaterialPageRoute(
    builder: (_) => const OnboardingScreen(),
  );
```

Add the import at the top of the file:
```dart
import 'screens/onboarding/onboarding_screen.dart';
```

- [ ] **Step 3: Verify no analysis errors on all modified files**

```bash
flutter analyze lib/screens/login/login_screen.dart lib/main.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/screens/login/login_screen.dart lib/main.dart
git commit -m "feat(onboarding): wire up OnboardingScreen in login and routes"
```

---

### Task 17: Full Integration Verification

**Files:** All new and modified files

- [ ] **Step 1: Run flutter analyze on all onboarding files**

```bash
flutter analyze lib/screens/onboarding/ lib/widgets/year_chip_selector.dart lib/widgets/tap_chip_selector.dart lib/models/registration_models.dart lib/screens/login/login_screen.dart lib/main.dart
```

Expected: Zero errors. Info-level warnings from pre-existing code are acceptable.

- [ ] **Step 2: Run full project analyze**

```bash
flutter analyze
```

Expected: No new errors introduced.

- [ ] **Step 3: Verify the app builds**

```bash
flutter build apk --debug 2>&1 | tail -20
```

Expected: BUILD SUCCESSFUL

- [ ] **Step 4: Commit any fixes if needed**

```bash
git add -A && git commit -m "fix(onboarding): resolve any analysis issues from integration"
```

---

## Dependency Graph

```
Task 1 (EducationPath enum) ← Task 10 (EducationLevelStep), Task 15 (OnboardingScreen)
Task 2 (YearChipSelector) ← Task 11 (SchoolStep), Task 12 (UniversityStep)
Task 3 (TapChipSelector) ← Task 6 (NameStep), Task 10 (EducationLevelStep), Task 13 (EmployerStep)
Task 4 (ChapterProgressBar) ← Task 15 (OnboardingScreen)
Task 5 (ChapterCelebration) ← Task 15 (OnboardingScreen)
Tasks 6-13 (all steps) ← Task 15 (OnboardingScreen)
Task 14 (CompletionScreen) ← Task 15 (OnboardingScreen)
Task 15 (OnboardingScreen) ← Task 16 (Routes)
Task 16 (Routes) ← Task 17 (Verification)
```

**Parallelizable groups:**
- Tasks 1, 2, 3, 4, 5 — all independent, can run in parallel
- Tasks 6, 7, 8, 9, 10, 11, 12, 13, 14 — independent of each other (all depend on Tasks 1-3 being done)
- Task 15 — depends on all steps being done
- Task 16 — depends on Task 15
- Task 17 — depends on Task 16
