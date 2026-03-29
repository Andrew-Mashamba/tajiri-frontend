# TAJIRI Onboarding Redesign — Design Spec

## Goal

Replace the current 11-step registration stepper (which feels like an exam) with a conversational, chapter-based onboarding flow that collects the same data but feels fun, low-friction, and motivating. Profile photo with face detection is mandatory for the People Discovery system.

## Authentication Model

Phone number is the sole login credential. No email or password. The existing `POST /api/users/login-by-phone` endpoint authenticates by phone number and returns a Sanctum token. Registration creates the user + profile and returns an `access_token`. This matches the existing `LoginScreen` flow.

## Architecture

Flutter-only frontend change. All backend endpoints already exist — `POST /api/users/register` (multipart, accepts all fields), `POST /api/users/check-phone` (phone uniqueness), school/location/employer search APIs. The current `RegistrationScreen` and its 11 step widgets are replaced by a new chapter-based flow with smart branching. Google ML Kit enforces face detection on profile photos (required by `docs/superpowers/specs/2026-03-29-people-discovery-design.md`).

## Design System

- Monochrome palette: `#1A1A1A` primary, `#FAFAFA` background, `#666666` secondary text
- Material 3 components, `useMaterial3: true`
- 12px border radius on all rounded elements
- 48dp minimum touch targets
- Swahili-first UI text, smart guide tone
- SafeArea mandatory on all screens

---

## Chapter Structure

4 chapters replace the flat 11-step stepper:

| Chapter | Swahili Name | Meaning | Screens | Required? |
|---------|-------------|---------|---------|-----------|
| 1 | Kufahamiana | Getting to know you | Name+DOB+Gender, Profile Photo | All required |
| 2 | Mahali | Your place | Phone, Location | Phone required, Location optional |
| 3 | Masomo | Education | Education level choice, then dynamic per choice | Level choice required, individual schools optional |
| 4 | Maisha | Life now | Current employer | Optional |

### Chapter Progress Indicator

4 horizontal bars at the top of every screen. Current chapter's bar animates fill. Completed chapters are fully filled. Below the bars: chapter name in small uppercase (`letter-spacing: 1px`, `font-size: 11px`, `color: #666666`).

```
[████████] [████░░░░] [░░░░░░░░] [░░░░░░░░]
MAHALI
```

No step numbers. No "X of Y". The user sees chapters, not a countdown.

### Chapter Transitions

Between chapters, a brief celebration overlay:
- Duration: 400ms fade-in, auto-dismiss after 1.5s (or tap to dismiss)
- Content: Animated checkmark + "Sehemu ya N imekamilika! Twende sehemu ya N+1..."
- Example: "Kufahamiana ✓ — Umefanya vizuri! Twende Mahali..."

---

## Screen-by-Screen Design

### Universal Patterns

1. **One question per screen** — Large conversational question as title (`fontSize: 20`, `fontWeight: w600`, `color: #1A1A1A`)
2. **Supporting text** below question (`fontSize: 13`, `color: #666666`)
3. **Bottom-anchored CTA** — "Endelea →" button always visible without scrolling (`height: 52`, `background: #1A1A1A`, `borderRadius: 12`, `color: white`)
4. **Contextual skip** — Left-aligned text button with specific skip reason, not generic "Ruka"
5. **Smooth transitions** — Screens slide horizontally (300ms, `Curves.easeInOut`)

---

### Chapter 1: Kufahamiana (Getting to Know You)

#### Screen 1.1: Name + DOB + Gender

**Question:** "Jina lako ni nani?"
**Supporting:** "Tuambie jina lako na tarehe ya kuzaliwa"

**Inputs:**
- First name text field (white background, 12px radius, 16px padding, shadow `0 1px 3px rgba(0,0,0,0.08)`)
- Last name text field (same style)
- Date of birth: date picker button showing selected date or placeholder "Chagua tarehe"
- Gender: two tap chips side by side — "Me" (Male) / "Ke" (Female), selected chip: `background: #1A1A1A, color: white`, unselected: `background: white, border: 1px solid #E0E0E0`

**Validation:** All fields required. First/last name minimum 2 characters. DOB must make user 13+ years old.

**CTA:** "Endelea →" (enabled when all fields filled)

#### Screen 1.2: Profile Photo

**Question:** "Tupige picha!"
**Supporting:** "Picha yako husaidia marafiki kukutambua"

**Layout:**
- Top 60%: Camera preview or selected image
- Oval face guide overlay centered on camera preview (thin white border, semi-transparent outside)
- Real-time Google ML Kit feedback text below preview:
  - No face: "Sogeza uso katikati" (Move face to center)
  - Face too small: "Karibia zaidi" (Come closer)
  - Face detected: green checkmark animation + "Poa! Uso unaonekana vizuri"
- Two action buttons below:
  - "Piga Picha" (Take Photo) — primary button
  - "Chagua kutoka Galeri" (Choose from Gallery) — text button
- Gallery-selected photos also run through ML Kit face validation

**Face validation rules (from People Discovery spec):**
- Exactly 1 face detected
- Face bounding box stored as `faceBbox` in `RegistrationState`
- Minimum face size: 20% of image width
- If validation fails: friendly illustration + "Hatuwezi kuona uso wako vizuri. Jaribu tena na mwanga mzuri!" with retry

**Camera permission denied:** "Tunahitaji ruhusa ya kamera. Fungua Mipangilio." with button to open app settings via `openAppSettings()`.

**CTA:** "Endelea →" (enabled only when photo with valid face is captured)

**Chapter celebration after this screen.**

---

### Chapter 2: Mahali (Your Place)

#### Screen 2.1: Phone Number

**Question:** "Nambari yako ya simu?"
**Supporting:** "Tutatumia hii kukuunganisha na marafiki"

**Input:**
- Phone field with `+255` prefix shown as non-editable label
- Numeric keyboard
- Auto-format as user types: `XXX XXX XXX`
- On submit: normalize to `+255XXXXXXXXX`, check availability via `POST /api/users/check-phone` (existing endpoint in `UserService.checkPhoneAvailability()`)
- If taken: "Nambari hii imeshasajiliwa. Ingia badala yake?" with link to LoginScreen

**CTA:** "Endelea →"

#### Screen 2.2: Location

**Question:** "Unaishi wapi?"
**Supporting:** "Hii husaidia kupata watu wa karibu nawe"

**Input:** Cascading search using existing location APIs:
1. Region search: `GET /api/locations/regions?q=...` (type-ahead)
2. After region selected → District search: `GET /api/locations/districts?region_id=X&q=...`
3. After district → Ward search: `GET /api/locations/wards?district_id=X&q=...` (optional)
4. After ward → Street search: `GET /api/locations/streets?ward_id=X&q=...` (optional)

Each level appears after the previous is selected, sliding in smoothly.

**Skip:** "Sitaki kusema" (I don't want to say) — left-aligned text button

**CTA:** "Endelea →"

**Chapter celebration after this screen.**

---

### Chapter 3: Masomo (Education)

#### Screen 3.1: Education Level Choice

**Question:** "Umesoma hadi wapi?"
**Supporting:** "Chagua kiwango chako cha juu cha elimu"

**Input:** Vertical tap chips (full-width, 52dp height, 12px radius):
- "Shule ya Msingi" (Primary School)
- "Sekondari" (Secondary / O-Level)
- "Kidato cha 5-6" (A-Level)
- "Chuo" (Post-Secondary / College)
- "Chuo Kikuu" (University)

Selected chip: `background: #1A1A1A, color: white`. Unselected: `background: white, border: 1px solid #E0E0E0`.

**Branching logic:** Selection determines which subsequent screens appear:
- "Shule ya Msingi" → Screen 3.2 (primary) → Chapter 4
- "Sekondari" → 3.2 (primary) → 3.3 (secondary) → Chapter 4
- "Kidato cha 5-6" → 3.2 (primary) → 3.3 (secondary) → 3.4 (A-level) → Chapter 4
- "Chuo" → 3.2 (primary) → 3.3 (secondary) → 3.5 (post-secondary) → Chapter 4
- "Chuo Kikuu" → 3.2 (primary) → 3.3 (secondary) → 3.6 (university) → Chapter 4

**CTA:** "Endelea →" (enabled when a level is selected)

#### Screen 3.2: Primary School

**Question:** "Ulisoma msingi wapi?"
**Supporting:** "Tafuta jina la shule yako"

**Input:**
- School search field (type-ahead against `/api/schools?type=primary&q=...`)
- Graduation year: horizontal scrollable tap chips, centered on smart default (`dobYear + 13`)
- Show 7 chips, selected chip dark, others outlined

**Skip:** "Sijasoma msingi" — should be rare but available

#### Screen 3.3: Secondary School

**Question:** "Ulisoma sekondari wapi?"
**Supporting:** "Tafuta jina la shule yako ya sekondari"

**Input:** Same pattern as 3.2 but:
- School search queries `type=secondary`
- Year chips centered on `dobYear + 17`

**Skip:** "Sijasoma sekondari"

#### Screen 3.4: A-Level

**Question:** "Ulisoma kidato cha 5-6 wapi?"
**Supporting:** "Shule na combination yako"

**Input:**
- School search (same pattern)
- Combination: search/select from known combinations (e.g., PCM, CBG, HGL)
- Year chips centered on `dobYear + 19`

**Skip:** "Sijaenda kidato cha 5-6"

#### Screen 3.5: Post-Secondary / College

**Question:** "Ulisoma chuo gani?"
**Supporting:** "Chuo cha ufundi, ualimu, n.k."

**Input:**
- Institution search
- Year chips centered on `dobYear + 19`

**Skip:** "Sijaenda chuo"

#### Screen 3.6: University

**Question:** "Chuo Kikuu gani?"
**Supporting:** "Na programme yako"

**Input:**
- University search
- Programme search (filtered by selected university)
- Degree level: tap chips — "Shahada" (Bachelor) / "Uzamili" (Masters) / "Uzamivu" (PhD)
- "Bado nasoma" (Still studying) toggle
- Year chips for graduation (or expected graduation if still studying)

**Skip:** "Sijaenda chuo kikuu"

**Chapter celebration after last education screen.**

---

### Chapter 4: Maisha (Life Now)

#### Screen 4.1: Current Employer

**Question:** "Unafanya kazi wapi sasa?"
**Supporting:** "Kampuni au biashara yako"

**Input:**
- Employer search (type-ahead against `/api/employers?q=...`)
- If not found: "Ongeza kampuni" (Add company) — opens inline fields for custom employer name + sector
- Sector chips if custom: "Teknolojia", "Elimu", "Afya", "Biashara", "Serikali", "Nyingine"

**Skip:** "Sina kazi kwa sasa" (I don't have a job right now)

---

### Completion Screen

After the final step:

**Layout:**
- Animated celebration (confetti or checkmark burst, 600ms)
- "Hongera! Uko tayari!" (Congratulations! You're ready!) — `fontSize: 24, fontWeight: bold`
- Profile preview card: user's photo (circular, 80px), name below, highest school below that
- Single CTA: "Anza TAJIRI →" — full-width primary button

**Action:** On "Anza TAJIRI →" tap:
1. Show loading indicator on button, disable tap
2. Call `UserService().register(state)` (instance method, not static) with all collected data
3. On success: save auth token + user to `LocalStorageService`, navigate to `HomeScreen`
4. On failure: show error snackbar "Imeshindwa kuwasiliana na seva. Jaribu tena.", re-enable button for retry

---

## Smart Year Calculation

Given `dobYear` from Screen 1.1:

| Education Level | Default Graduation Year | Chip Range |
|----------------|------------------------|------------|
| Primary | `dobYear + 13` | ±3 years |
| Secondary | `dobYear + 17` | ±3 years |
| A-Level | `dobYear + 19` | ±3 years |
| Post-Secondary | `dobYear + 19` | ±3 years |
| University | `dobYear + 22` | ±4 years |

Chips are horizontally scrollable. ±3 range = 7 chips, ±4 range = 9 chips. Smart default is pre-selected but user can change.

---

## Error Handling

| Error | Message (Swahili) | Action |
|-------|-------------------|--------|
| Network failure | "Samahani, mtandao umeshindwa. Jaribu tena." | Retry button |
| Face not detected | "Hatuwezi kuona uso wako vizuri. Jaribu tena na mwanga mzuri!" | Retry with tips |
| Phone taken | "Nambari hii imeshasajiliwa. Ingia badala yake?" | Link to LoginScreen |
| Registration API failure | "Imeshindwa kuwasiliana na seva. Jaribu tena." | Retry button |
| School search empty | "Hakuna matokeo. Jaribu tena au ruka hatua hii." | Allow skip |
| Camera permission denied | "Tunahitaji ruhusa ya kamera. Fungua Mipangilio." | Button to open app settings |

---

## Data Model

One new field added to `RegistrationState`: `educationPath` enum. All other existing fields are reused.

```dart
/// New enum for education branching
enum EducationPath { primary, secondary, alevel, postSecondary, university }
```

**`educationPath` → `didAttendAlevel` mapping:**
| educationPath | didAttendAlevel |
|---------------|----------------|
| `primary` | `false` |
| `secondary` | `false` |
| `alevel` | `true` |
| `postSecondary` | `false` |
| `university` | `false` |

**`isPhoneVerified` handling:** Set `isPhoneVerified = true` after phone format validation passes. No OTP for now — matches current registration behavior.

Fields populated per chapter:
- **Kufahamiana:** firstName, lastName, dateOfBirth, gender, profilePhotoPath, faceBbox
- **Mahali:** phoneNumber, isPhoneVerified (set to `true`), location (regionId, districtId, wardId, streetId)
- **Masomo:** educationPath (new enum field), primarySchool, secondarySchool, alevelEducation, postsecondaryEducation, universityEducation (subset based on educationPath)
- **Maisha:** currentEmployer

---

## Navigation

- **Back button:** Goes to previous screen within chapter, or to last screen of previous chapter
- **Android back gesture:** Same as back button (no exit on first screen — show "Unataka kuondoka?" confirmation)
- **State preservation:** All entered data persists in `RegistrationState` in memory across navigation. If user goes back and changes education level, downstream education data is cleared.
- **Persistence on app kill:** No disk persistence of partial registration. If the user kills the app mid-flow, they restart from the beginning. This keeps the implementation simple and avoids stale partial states.
- **Entry point:** `LoginScreen` → "Fungua Akaunti" button → new onboarding flow

---

## Files to Create/Modify

### New Files
| File | Purpose |
|------|---------|
| `lib/screens/onboarding/onboarding_screen.dart` | Main controller: chapter navigation, progress tracking, state management |
| `lib/screens/onboarding/chapter_progress_bar.dart` | 4-bar chapter indicator widget |
| `lib/screens/onboarding/chapter_celebration.dart` | Between-chapter celebration overlay |
| `lib/screens/onboarding/completion_screen.dart` | Final "Hongera" screen with profile preview |
| `lib/screens/onboarding/steps/name_step.dart` | Screen 1.1: Name + DOB + Gender |
| `lib/screens/onboarding/steps/photo_step.dart` | Screen 1.2: Profile photo with face detection |
| `lib/screens/onboarding/steps/phone_step.dart` | Screen 2.1: Phone number |
| `lib/screens/onboarding/steps/location_step.dart` | Screen 2.2: Location cascading search |
| `lib/screens/onboarding/steps/education_level_step.dart` | Screen 3.1: Education level tap chips |
| `lib/screens/onboarding/steps/school_step.dart` | Reusable: `SchoolStep({required String schoolType, required String question, required String skipText, required int defaultGradYear, int yearRange = 3, bool showCombination = false})` — used for primary, secondary, A-level, post-secondary |
| `lib/screens/onboarding/steps/university_step.dart` | Screen 3.6: University + programme + degree |
| `lib/screens/onboarding/steps/employer_step.dart` | Screen 4.1: Current employer |
| `lib/widgets/year_chip_selector.dart` | Reusable horizontal scrollable year chips |
| `lib/widgets/tap_chip_selector.dart` | Reusable tap chip selector (single select) |

### Modified Files
| File | Change |
|------|--------|
| `lib/screens/login/login_screen.dart` | "Fungua Akaunti" navigates to `OnboardingScreen` instead of `RegistrationScreen` |
| `lib/main.dart` | Add `/onboarding` route |
| `lib/models/registration_models.dart` | Add `educationPath` enum field |
| `pubspec.yaml` | Add `google_ml_kit` / `google_mlkit_face_detection` dependency |

### Unchanged
| File | Note |
|------|------|
| `lib/screens/registration/` | Keep existing files — they still work for profile editing. Don't delete. |
| `lib/services/user_service.dart` | No changes — `register()` already handles multipart with photo + faceBbox |

---

## Dependencies

```yaml
# pubspec.yaml additions
google_mlkit_face_detection: ^0.12.0
```

No other new dependencies. Existing `camera` package used for photo capture.

---

## Out of Scope

- OTP/SMS verification (phone is validated format-only for now, matching current behavior)
- Backend changes (existing register endpoint handles all fields)
- Profile editing flow (keep existing registration steps for that)
- Animations beyond chapter celebrations (Lottie etc. — use simple Flutter animations)
