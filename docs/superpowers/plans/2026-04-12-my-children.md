# My Children -- Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the My Children module covering ages 0-18 with 4 adaptive stages, integrating deeply with TAJIRI's education, health, financial, and social modules. Replace `lib/my_baby/` (16 files, infant-only) with `lib/my_children/` that embeds infant as one of four stages.

**Architecture:** Age-adaptive Flutter module. Single `Child` model (extends existing `Baby`) with computed `stage` property. Existing My Baby pages become the infant stage views. New dashboards for toddler (2-5), school-age (5-12), and teen (12-18). Backend extends existing `/my-baby/` endpoints under new `/my-children/` prefix.

**Tech Stack:** Flutter/Dart, Laravel backend, PostgreSQL, SQLite (sqflite), FCM

**Spec:** `docs/modules/my_children.md`

**Existing Code:** `lib/my_baby/` -- 16 files (module, models, service, 10 pages, 1 widget)

**Design:** Monochromatic palette per `docs/DESIGN.md` -- #1A1A1A primary, #FAFAFA background, #FFFFFF surface. No colorful buttons. SafeArea mandatory. 48dp touch targets. maxLines + ellipsis on all dynamic text.

---

## Existing My Baby Files (becomes infant stage)

```
lib/my_baby/
  my_baby_module.dart              -> becomes InfantDashboard wrapper
  models/my_baby_models.dart       -> extends into Child + new models
  services/my_baby_service.dart    -> extends into MyChildrenService
  widgets/vaccination_card.dart    -> reused as-is
  pages/
    my_baby_home_page.dart         -> replaced by MyChildrenHomePage
    baby_dashboard_page.dart       -> becomes InfantDashboard
    feeding_tracker_page.dart      -> reused (infant stage)
    sleep_tracker_page.dart        -> reused (infant stage)
    diaper_tracker_page.dart       -> reused (infant stage)
    growth_charts_page.dart        -> extended (WHO 0-5, CDC 5-18)
    vaccination_page.dart          -> extended (EPI + boosters + teen)
    milestones_page.dart           -> extended (all 4 stages)
    health_log_page.dart           -> reused (all stages)
    summary_page.dart              -> reused (infant), new summaries per stage
    caregiver_sharing_page.dart    -> reused, becomes co-parent sharing
    photo_journal_page.dart        -> reused (all stages)
```

## Cross-References to Update

- `lib/models/profile_tab_config.dart` -- line 112: `my_baby` tab ID, label "My Children"
- `lib/screens/profile/profile_screen.dart` -- line 2137: `case 'my_baby'` routes to `MyBabyModule`
- `lib/my_pregnancy/pages/pregnancy_home_page.dart` -- imports `my_baby_module.dart` and `my_baby_service.dart`
- `lib/my_pregnancy/services/my_pregnancy_service.dart` -- may reference baby handoff
- `lib/services/fcm_service.dart` -- references my_baby for push notification routing
- `lib/l10n/app_strings.dart` -- my_baby related strings

---

## Task 1: Rename + Refactor Foundation

**Goal:** Move `lib/my_baby/` to `lib/my_children/`, rename `Baby` to `Child`, extend the model, create age-adaptive routing.

### Files to Create

- `lib/my_children/my_children_module.dart` -- new entry point with age-adaptive routing
- `lib/my_children/models/child_model.dart` -- extended `Child` model (was `Baby`)
- `lib/my_children/models/my_children_models.dart` -- barrel file re-exporting all models
- `lib/my_children/services/my_children_service.dart` -- extended service (was `MyBabyService`)
- `lib/my_children/pages/my_children_home_page.dart` -- child list with stage badges (was `my_baby_home_page.dart`)
- `lib/my_children/pages/child_dashboard_page.dart` -- age-adaptive wrapper that delegates to stage dashboards

### Files to Copy (infant stage -- minimal changes)

Copy all existing pages from `lib/my_baby/pages/` to `lib/my_children/pages/infant/`:
- `feeding_tracker_page.dart`
- `sleep_tracker_page.dart`
- `diaper_tracker_page.dart`
- `growth_charts_page.dart`
- `vaccination_page.dart`
- `milestones_page.dart`
- `health_log_page.dart`
- `summary_page.dart`
- `caregiver_sharing_page.dart`
- `photo_journal_page.dart`

Copy widget: `lib/my_baby/widgets/vaccination_card.dart` to `lib/my_children/widgets/vaccination_card.dart`

### Files to Modify

- `lib/models/profile_tab_config.dart` -- change tab ID from `my_baby` to `my_children`, keep label "My Children"
- `lib/screens/profile/profile_screen.dart` -- change `case 'my_baby'` to `case 'my_children'`, import `MyChildrenModule`
- `lib/my_pregnancy/pages/pregnancy_home_page.dart` -- update import from `my_baby` to `my_children`
- `lib/services/fcm_service.dart` -- update my_baby references to my_children
- `lib/l10n/app_strings.dart` -- add/update strings for "My Children" / "Watoto Wangu"

### Steps

- [ ] Create `lib/my_children/` directory structure: `models/`, `services/`, `pages/`, `pages/infant/`, `widgets/`
- [ ] Create `Child` model in `lib/my_children/models/child_model.dart`:
  - Copy all fields from `Baby` class
  - Add new fields: `bloodType` (String?), `photoUrl` (String?), `schoolId` (int?), `schoolName` (String?), `grade` (String?), `insuranceNumber` (String?), `nhifStatus` (String?), `emergencyContacts` (List<Map<String, String>>), `allergies` (List<String>)
  - Add computed getters:
    - `int get ageInYears => (ageInDays / 365.25).floor()`
    - `ChildStage get stage` -- returns `infant` (0-2), `toddler` (2-5), `schoolAge` (5-12), `teen` (12-18)
  - Add `ChildStage` enum: `infant, toddler, schoolAge, teen` with bilingual labels and icons
  - Keep backward compatibility: `Baby` model still works, `Child.fromBaby(Baby b)` factory
  - Parse new fields from JSON with null-safe helpers, fall back gracefully for old data
- [ ] Create `lib/my_children/models/my_children_models.dart` -- re-export `child_model.dart` plus all existing model classes (Vaccination, BabyMilestone, FeedingLog, SleepSession, DiaperLog, GrowthMeasurement, HealthLog, BabyPhoto, CaregiverShare, DailySummary). Keep parsing helpers.
- [ ] Create `MyChildrenService` in `lib/my_children/services/my_children_service.dart`:
  - Copy all methods from `MyBabyService`
  - Change endpoint prefix from `/my-baby/` to `/my-children/` (backend will alias both)
  - Change `Baby` return types to `Child`
  - Add `registerChild()` method (supports age 0-18, not just infants)
  - Keep all existing infant methods (feeding, sleep, diaper, etc.)
  - Add placeholder methods for new stages (will implement in later tasks)
- [ ] Copy infant pages to `lib/my_children/pages/infant/` -- update imports to use `../models/` and `../services/`
  - Each page: update `Baby` references to `Child`, update `MyBabyService` to `MyChildrenService`
  - Keep all existing UI and logic intact
- [ ] Copy `vaccination_card.dart` widget to `lib/my_children/widgets/`
- [ ] Create `MyChildrenHomePage` (`lib/my_children/pages/my_children_home_page.dart`):
  - Based on existing `MyBabyHomePage` layout
  - Child cards show: name, age label, **stage badge** (color-coded chip: Infant/Toddler/School/Teen)
  - Register child dialog: same fields as register baby + allow DOB up to 18 years ago (was 5 years)
  - Empty state: "My Children" / "Watoto Wangu" with child_friendly icon
- [ ] Create `ChildDashboardPage` (`lib/my_children/pages/child_dashboard_page.dart`):
  - Receives `Child` and `userId`
  - Age-adaptive routing:
    ```
    if (child.stage == ChildStage.infant) return InfantDashboardView(child)
    if (child.stage == ChildStage.toddler) return ToddlerDashboardView(child)  // placeholder
    if (child.stage == ChildStage.schoolAge) return SchoolAgeDashboardView(child)  // placeholder
    return TeenDashboardView(child)  // placeholder
    ```
  - InfantDashboardView = existing `BabyDashboardPage` content, refactored into a widget
  - Toddler/SchoolAge/Teen dashboards = placeholder "Coming Soon" with stage icon + label
  - AppBar shows child name, subtitle shows age label + stage
  - Floating action button with speed-dial (from existing baby_dashboard_page)
- [ ] Create `MyChildrenModule` (`lib/my_children/my_children_module.dart`):
  - Receives `userId`
  - Returns `MyChildrenHomePage(userId: userId)`
- [ ] Update `lib/models/profile_tab_config.dart`: change `id: 'my_baby'` to `id: 'my_children'`
- [ ] Update `lib/screens/profile/profile_screen.dart`:
  - Change import from `my_baby_module.dart` to `my_children_module.dart`
  - Change `case 'my_baby':` to `case 'my_children':`
  - Change `MyBabyModule(userId: userId)` to `MyChildrenModule(userId: userId)`
- [ ] Update `lib/my_pregnancy/pages/pregnancy_home_page.dart`:
  - Change imports from `my_baby/` to `my_children/`
  - Update any `Baby` references to `Child`
  - Update any `MyBabyService` references to `MyChildrenService`
- [ ] Update `lib/services/fcm_service.dart` -- update any `my_baby` route references to `my_children`
- [ ] Update category in `profile_tab_config.dart` `tabIds` list: `my_baby` -> `my_children`

### Verification

```bash
# Ensure no remaining imports of my_baby from outside the old directory
grep -r "my_baby" lib/ --include="*.dart" | grep -v "lib/my_baby/" | grep -v "lib/my_children/"
# Should return empty (all references updated)

flutter analyze
# Should pass with 0 errors

# Old my_baby/ directory can be kept temporarily for reference, deleted in final cleanup
```

---

## Task 2: Backend -- New Tables + Endpoints

**Goal:** Ask backend to extend the babies table and create new tables/endpoints for all four stages.

### Backend Changes (via `./scripts/ask_backend.sh`)

- [ ] Prompt 1 -- Extend babies table + alias endpoints:
  ```
  Extend the babies table with new nullable columns: blood_type (string), photo_url (string),
  school_id (integer, nullable FK to schools), school_name (string), grade (string),
  insurance_number (string), nhif_status (string, default 'unknown'),
  emergency_contacts (json, default []), allergies (json, default []).
  Create route aliases: all /my-baby/* endpoints also respond at /my-children/*.
  The /my-children/children endpoint returns babies with the new fields.
  Add computed 'stage' field in API response based on age: infant (0-2), toddler (2-5), school_age (5-12), teen (12-18).
  ```

- [ ] Prompt 2 -- Chore assignments table + CRUD:
  ```
  Create chore_assignments table: id, child_id (FK babies), title, title_swahili,
  frequency (enum: daily/weekly/monthly), reward_amount (decimal, TZS), 
  is_completed (boolean, default false), completed_at (datetime, nullable),
  assigned_by (FK users), created_at, updated_at.
  CRUD endpoints at /my-children/chores: index (by child_id), store, update, delete.
  POST /my-children/chores/{id}/complete to mark done with completed_at timestamp.
  POST /my-children/chores/{id}/reset to unmark (for recurring chores).
  ```

- [ ] Prompt 3 -- Allowance transactions table + CRUD:
  ```
  Create allowance_transactions table: id, child_id (FK babies), amount (decimal),
  type (enum: earned/spent/saved/given), description, source (enum: chore/gift/other),
  chore_assignment_id (nullable FK), date (date), created_at.
  Endpoints at /my-children/allowance: index (by child_id, filterable by type/date range),
  store, GET /my-children/allowance/balance/{childId} returns {earned, spent, saved, given, balance}.
  Auto-create 'earned' transaction when a chore with reward_amount is completed.
  ```

- [ ] Prompt 4 -- Academic records table + CRUD:
  ```
  Create academic_records table: id, child_id (FK babies), term (string),
  year (integer), subject (string), grade (string), score (decimal, nullable),
  teacher_notes (text, nullable), school_id (nullable FK), created_at, updated_at.
  CRUD endpoints at /my-children/academics: index (by child_id, filterable by year/term),
  store, update, delete.
  GET /my-children/academics/summary/{childId} returns average score per term, best/worst subjects.
  ```

- [ ] Prompt 5 -- Activity enrollments + potty/speech logs:
  ```
  Create activity_enrollments table: id, child_id (FK babies), activity_name, category
  (enum: sports/arts/academic/religious/other), schedule (json), fee_amount (decimal, nullable),
  fee_frequency (enum: monthly/termly/yearly/once), start_date (date), end_date (date, nullable),
  created_at, updated_at.
  CRUD endpoints at /my-children/activities.

  Create potty_logs table: id, child_id (FK babies), type (enum: success/accident),
  location (string, nullable), notes (text, nullable), logged_at (datetime), created_at.
  Endpoints at /my-children/potty: index (by child_id + date), store.
  GET /my-children/potty/stats/{childId} returns {total_successes, total_accidents, streak_days, success_rate}.

  Create speech_milestones table: id, child_id (FK babies), word (string), 
  category (enum: first_word/noun/verb/phrase/sentence), logged_at (datetime),
  notes (text, nullable), created_at.
  Endpoints at /my-children/speech: index (by child_id), store.
  GET /my-children/speech/stats/{childId} returns {total_words, first_word, categories_breakdown}.
  ```

- [ ] Prompt 6 -- Seed milestone data for all stages:
  ```
  Extend the baby_milestones seeder to include milestones for all ages:
  - Toddler (24-60 months): running, jumping, climbing stairs, 2-word sentences, 
    pretend play, sharing, counting to 10, knows colors, draws circles, potty trained
  - School Age (60-144 months): reads independently, writes paragraphs, multiplication,
    tells time, ties shoes, rides bicycle, team sports, best friend, responsibility for chores
  - Teen (144-216 months): abstract thinking, career interests, financial planning basics,
    cooking meals, time management, ID documents, driving eligibility
  Each milestone has: title, title_swahili, description, age_months, category (motor/language/social/cognitive/life_skill/academic/financial)
  ```

- [ ] Prompt 7 -- Emergency card + co-parent sharing:
  ```
  Create emergency_cards table: id, child_id (FK babies), card_data (json -- cached snapshot of
  name, dob, blood_type, allergies, emergency_contacts, insurance_number, photo_url),
  share_token (unique string for URL sharing), is_active (boolean, default true),
  created_at, updated_at.
  POST /my-children/emergency-card/{childId} -- generates/updates card with current child data.
  GET /my-children/emergency-card/view/{shareToken} -- public endpoint, returns card_data (no auth).

  Extend caregiver_shares table: add role options 'co_parent' (full equal access) and 'school' (view health/attendance only).
  ```

### Verification

```bash
# After each prompt, verify endpoint works:
curl -s -H "Authorization: Bearer $TOKEN" https://zima-uat.site:8003/api/my-children/children?user_id=1 | jq .
# Should return children list with new fields + stage

curl -s -H "Authorization: Bearer $TOKEN" https://zima-uat.site:8003/api/my-children/chores?child_id=1 | jq .
# Should return chores list (empty initially)
```

---

## Task 3: MyChildrenModule + Age-Adaptive Routing + Profile Tab

**Goal:** Wire the module into the app so it's accessible from the profile tab. Age-adaptive dashboard works for all stages (with placeholders for unbuilt stages).

### Files to Create/Modify

This task builds on Task 1. All files from Task 1 must exist.

### Steps

- [ ] Finalize `ChildDashboardPage` with proper age-adaptive routing:
  - Shared AppBar: child photo (CircleAvatar), name, age + stage chip
  - Shared bottom section: "History" tab showing all previous-stage data
  - Stage-specific body: delegates to InfantDashboard / ToddlerDashboard / SchoolAgeDashboard / TeenDashboard
- [ ] Create `lib/my_children/pages/infant/infant_dashboard_view.dart`:
  - Extract the body content from existing `BabyDashboardPage` into a reusable widget
  - Receives `Child`, `token`, service instance
  - Shows: daily summary stats, quick actions (feed, sleep, diaper, growth), vaccination status, milestone progress, photo journal
  - Speed-dial FAB with same actions as current baby dashboard
- [ ] Create placeholder dashboards:
  - `lib/my_children/pages/toddler/toddler_dashboard_view.dart` -- shows stage icon + "Toddler features coming soon" + list of planned features with icons
  - `lib/my_children/pages/school_age/school_age_dashboard_view.dart` -- same pattern
  - `lib/my_children/pages/teen/teen_dashboard_view.dart` -- same pattern
- [ ] Wire register child form in `MyChildrenHomePage`:
  - Allow DOB up to 18 years ago (change `firstDate` from 5y to 18y subtraction)
  - Add optional blood type dropdown (A+, A-, B+, B-, AB+, AB-, O+, O-)
  - Add optional allergies text field (comma-separated)
- [ ] Add route in `lib/main.dart` (if needed): `/my-children` route pointing to `MyChildrenModule`
- [ ] Ensure profile tab wiring works end-to-end:
  - Profile screen -> My Children tab -> MyChildrenModule -> MyChildrenHomePage -> tap child -> ChildDashboardPage -> stage-specific view

### Verification

```bash
flutter analyze
# 0 errors

# Manual test: 
# 1. Open profile -> My Children tab visible
# 2. Register a child (any age) -> card appears with stage badge
# 3. Tap child -> dashboard shows age-appropriate view
# 4. Infant child -> shows feeding/sleep/diaper actions (existing functionality)
# 5. Older child -> shows placeholder with planned features
```

---

## Task 4: Toddler Dashboard + Pages (Ages 2-5)

**Goal:** Build the toddler stage with potty training, speech development, behavior chart, and learning activities.

### Files to Create

- `lib/my_children/pages/toddler/toddler_dashboard_view.dart` -- replace placeholder
- `lib/my_children/pages/toddler/potty_training_page.dart`
- `lib/my_children/pages/toddler/speech_development_page.dart`
- `lib/my_children/pages/toddler/behavior_chart_page.dart`
- `lib/my_children/pages/toddler/learning_activities_page.dart`
- `lib/my_children/models/toddler_models.dart` -- PottyLog, SpeechMilestone, BehaviorEntry, LearningActivity

### Steps

- [ ] Create toddler models in `lib/my_children/models/toddler_models.dart`:
  - `PottyLog` -- id, childId, type (success/accident), location, notes, loggedAt. `fromJson`, `toJson`.
  - `SpeechMilestone` -- id, childId, word, category (first_word/noun/verb/phrase/sentence), loggedAt, notes. `fromJson`.
  - `BehaviorEntry` -- id, childId, type (positive/negative), description, stickers (int), date. `fromJson`, `toJson`.
  - `LearningActivity` -- id, title, titleSwahili, description, category (colors/shapes/counting/letters), ageMonthsMin, ageMonthsMax, isCompleted. `fromJson`.

- [ ] Add toddler methods to `MyChildrenService`:
  - `logPotty(token, childId, type, ...)` -- POST /my-children/potty
  - `getPottyHistory(token, childId, date)` -- GET /my-children/potty
  - `getPottyStats(token, childId)` -- GET /my-children/potty/stats/{childId}
  - `logSpeechWord(token, childId, word, category)` -- POST /my-children/speech
  - `getSpeechMilestones(token, childId)` -- GET /my-children/speech
  - `getSpeechStats(token, childId)` -- GET /my-children/speech/stats/{childId}

- [ ] Build `PottyTrainingPage`:
  - Top stats row: streak days, success rate %, total successes today
  - Quick log buttons: "Success" (checkmark icon) and "Accident" (water_drop icon) -- one-tap logging
  - Calendar heatmap: days color-coded by success rate (grey=no data, light=few, dark=good)
  - History list below calendar, grouped by date
  - Bilingual: "Mafunzo ya Choo" / "Potty Training"
  - Sticker reward display: every 5 successes = star sticker animation (simple confetti)

- [ ] Build `SpeechDevelopmentPage`:
  - Word count stat at top with milestone indicator ("100 maneno!" / "100 words!")
  - "Add Word" FAB -- bottom sheet with word text field + category dropdown
  - Word cloud display: all recorded words in a wrapped chip layout
  - Milestones checklist: expected speech milestones for age (2y: 50 words, 3y: 200 words, etc.)
  - Timeline: first word, first phrase, first sentence with dates
  - Bilingual labels

- [ ] Build `BehaviorChartPage`:
  - Weekly sticker chart grid: 7 columns (Mon-Sun), rows for each tracked behavior
  - Add behavior button: name + positive/negative toggle
  - Sticker count per week with reward threshold ("10 stickers = reward!")
  - Reward suggestions list (age-appropriate, bilingual)
  - History: past weeks scrollable

- [ ] Build `LearningActivitiesPage`:
  - Categories: Colors, Shapes, Counting, Letters (tabs or chips)
  - Activity cards: title (bilingual), description, age range, completion checkbox
  - Activities are age-filtered (2-3y, 3-4y, 4-5y suggestions)
  - Completion progress bar per category
  - Content is local (no API needed) -- hardcoded list of ~40 activities with Swahili translations

- [ ] Build `ToddlerDashboardView` (replace placeholder):
  - Quick stats row: potty streak, words learned, stickers this week, activities completed
  - Quick action grid (2x2): Potty Training, Speech, Behavior Chart, Learning
  - Each action navigates to its full page
  - Continued from infant: growth charts, vaccination (boosters), health log, milestones, photo journal
  - "Infant History" collapsible section with links to feeding/sleep/diaper history
  - Speed-dial FAB: Log Potty, Add Word, Add Sticker, Log Health

### Verification

```bash
flutter analyze

# Manual test:
# 1. Register child aged 3 -> toddler stage badge shows
# 2. Dashboard shows toddler actions (potty, speech, behavior, learning)
# 3. Tap potty -> can log success/accident, see stats
# 4. Tap speech -> can add words, see word count
# 5. Behavior chart shows weekly grid
# 6. Learning activities show age-appropriate suggestions
# 7. Can still access vaccination, growth, health log from toddler dashboard
```

---

## Task 5: School-Age Dashboard + Pages (Ages 5-12)

**Goal:** Build the school-age stage with academic tracking, homework, chores, allowance, and activities.

### Files to Create

- `lib/my_children/pages/school_age/school_age_dashboard_view.dart`
- `lib/my_children/pages/school_age/school_enrollment_page.dart`
- `lib/my_children/pages/school_age/academic_tracking_page.dart`
- `lib/my_children/pages/school_age/homework_tracker_page.dart`
- `lib/my_children/pages/school_age/chore_chart_page.dart`
- `lib/my_children/pages/school_age/allowance_page.dart`
- `lib/my_children/pages/school_age/activity_manager_page.dart`
- `lib/my_children/pages/school_age/reading_log_page.dart`
- `lib/my_children/models/school_age_models.dart`

### Steps

- [ ] Create school-age models in `lib/my_children/models/school_age_models.dart`:
  - `AcademicRecord` -- id, childId, term, year, subject, grade, score, teacherNotes, schoolId. `fromJson`, `toJson`.
  - `HomeworkAssignment` -- id, childId, subject, title, description, dueDate, isCompleted, completedAt. `fromJson`, `toJson`.
  - `ChoreAssignment` -- id, childId, title, titleSwahili, frequency (daily/weekly/monthly), rewardAmount, isCompleted, completedAt, assignedBy. `fromJson`, `toJson`.
  - `AllowanceTransaction` -- id, childId, amount, type (earned/spent/saved/given), description, source (chore/gift/other), date. `fromJson`.
  - `ActivityEnrollment` -- id, childId, activityName, category (sports/arts/academic/religious/other), schedule, feeAmount, feeFrequency, startDate, endDate. `fromJson`, `toJson`.
  - `ReadingLogEntry` -- id, childId, bookTitle, author, pagesRead, totalPages, startDate, finishDate, rating, notes. `fromJson`, `toJson`.

- [ ] Add school-age methods to `MyChildrenService`:
  - Chores: CRUD + complete/reset
  - Allowance: list, add, get balance
  - Academics: CRUD + summary
  - Activities: CRUD
  - Homework: CRUD + complete (can be stored locally first, synced later)
  - Reading log: CRUD (can be local-first)

- [ ] Build `SchoolEnrollmentPage`:
  - Search/link child to school (search schools API or manual entry)
  - Display: school name, grade, enrollment date
  - Quick links to TAJIRI Education modules (My Class, Timetable, Fee Status) if school is linked
  - If no school linked: prompt to add school info manually (school name + grade text fields)
  - Bilingual: "Shule" / "School"

- [ ] Build `AcademicTrackingPage`:
  - Term selector (Term 1/2/3 + year picker)
  - Subject cards: subject name, grade/score, teacher notes
  - Add grade button -> bottom sheet form (subject, grade, score, notes)
  - Summary stats: average score, best subject, trend arrow (improving/declining)
  - Chart: scores per subject as horizontal bar chart (simple Container-based, no chart library)
  - Bilingual labels for common subjects (Hisabati/Math, Kiswahili, English, Sayansi/Science, etc.)

- [ ] Build `HomeworkTrackerPage`:
  - List of assignments grouped by: Overdue, Due Today, Upcoming, Completed
  - Add homework FAB -> bottom sheet: subject, title, due date
  - Tap to mark complete (optimistic UI with checkbox)
  - Color indicators: red = overdue, orange = due today, grey = upcoming, green = done
  - Bilingual: "Kazi za Nyumbani" / "Homework"

- [ ] Build `ChoreChartPage`:
  - Weekly view grid: days as columns, chores as rows, checkmark cells
  - Add chore button -> bottom sheet: title (bilingual), frequency, reward amount (TZS)
  - Tap cell to mark done -> triggers allowance earned transaction if reward > 0
  - Stats: chores completed this week, total earned this week
  - Rotation indicator: which chores rotate to which child (for multi-child families)
  - Template chores: pre-populated list (Make Bed/Tandika Kitanda, Wash Dishes/Osha Vyombo, Sweep/Fagia, etc.)

- [ ] Build `AllowancePage`:
  - Balance card at top: total earned, spent, saved, available
  - Earn-Save-Spend-Give breakdown as 4 colored bars (use subtle greys, not colors per design)
  - Transaction history list: icon per type, amount, description, date
  - Add transaction button: amount, type, description
  - Savings goal card: target amount, progress bar, days remaining
  - Connect to Wallet integration placeholder: "Link to TAJIRI Wallet" button (wired in Task 8)
  - Bilingual: "Posho" / "Allowance"

- [ ] Build `ActivityManagerPage`:
  - Activity cards: name, category chip, schedule summary, monthly fee
  - Add activity -> form: name, category dropdown, schedule (day + time), fee, start date
  - Calendar view: week's activity schedule as timeline
  - Total monthly cost stat at top
  - Categories: Sports/Michezo, Arts/Sanaa, Academic/Masomo, Religious/Dini, Other/Nyingine

- [ ] Build `ReadingLogPage`:
  - Currently reading card: book title, pages progress bar, started date
  - Add book -> form: title, author, total pages
  - Log pages button: quick entry for pages read today
  - Reading streak counter (consecutive days with logged pages)
  - Completed books list with star ratings
  - Stats: books this month, pages this month, longest streak
  - Bilingual: "Kusoma" / "Reading"

- [ ] Build `SchoolAgeDashboardView`:
  - Quick stats row: GPA/average, chores done this week, allowance balance, reading streak
  - Quick action grid (2x3):
    - School (graduation_cap icon) -> SchoolEnrollmentPage
    - Grades (assessment icon) -> AcademicTrackingPage
    - Homework (assignment icon) -> HomeworkTrackerPage
    - Chores (cleaning_services icon) -> ChoreChartPage
    - Allowance (savings icon) -> AllowancePage
    - Activities (sports icon) -> ActivityManagerPage
  - Reading streak card (tappable -> ReadingLogPage)
  - Next upcoming: homework due, activity scheduled, vaccination due
  - "Earlier Stages" collapsible: links to toddler history, infant history
  - Speed-dial FAB: Log Grade, Add Homework, Complete Chore, Log Reading

### Verification

```bash
flutter analyze

# Manual test:
# 1. Register child aged 8 -> school-age stage badge
# 2. Dashboard shows school-age actions
# 3. Add school enrollment -> appears on dashboard
# 4. Add grades -> academic tracking shows scores
# 5. Add chore -> appears on chart, mark done -> allowance earned
# 6. Allowance page shows balance
# 7. Activities and reading log functional
```

---

## Task 6: Teen Dashboard + Pages (Ages 12-18)

**Goal:** Build the teen stage with academic dashboard, career guidance, financial literacy, and life skills.

### Files to Create

- `lib/my_children/pages/teen/teen_dashboard_view.dart`
- `lib/my_children/pages/teen/teen_academic_page.dart`
- `lib/my_children/pages/teen/career_guidance_page.dart`
- `lib/my_children/pages/teen/financial_literacy_page.dart`
- `lib/my_children/pages/teen/life_skills_page.dart`
- `lib/my_children/pages/teen/independence_milestones_page.dart`
- `lib/my_children/models/teen_models.dart`

### Steps

- [ ] Create teen models in `lib/my_children/models/teen_models.dart`:
  - `CareerInterest` -- id, childId, interestArea, relatedSubjects, careerPaths, assessmentDate. `fromJson`.
  - `LifeSkillItem` -- id, title, titleSwahili, category (cooking/cleaning/finance/time_mgmt/study), isCompleted, completedAt. `fromJson`, `toJson`.
  - `IndependenceMilestone` -- id, childId, title, titleSwahili, ageYears, isAchieved, achievedAt, description. `fromJson`.

- [ ] Add teen methods to `MyChildrenService`:
  - Life skills: get checklist by childId, mark complete/undo
  - Independence milestones: get by childId, mark achieved
  - Career interests: get suggestions based on academic strengths (can be local logic initially)

- [ ] Build `TeenAcademicPage`:
  - Extends academic tracking with NECTA awareness
  - GPA card with trend chart (term-over-term)
  - Subject strength/weakness analysis: best 3 and worst 3 subjects
  - NECTA results section (if Form 4/6): link to TAJIRI NECTA module or manual entry
  - University/college readiness indicator based on grades
  - Study tips per weak subject (local content, bilingual)
  - Bilingual: "Masomo" / "Academics"

- [ ] Build `CareerGuidancePage`:
  - Interest assessment: 10-question survey with career-area mapping
  - Questions like "Do you enjoy solving math problems?" -> STEM indicator
  - Results: top 3 career areas with descriptions
  - Career-subject mapping: "To become an engineer, focus on: Math, Physics, Chemistry"
  - Career cards: title, description, required subjects, salary range in TZS
  - Links to TAJIRI Career module (placeholder)
  - Bilingual: "Mwongozo wa Kazi" / "Career Guidance"
  - Assessment data stored locally, results shown immediately

- [ ] Build `FinancialLiteracyPage`:
  - Budget basics lesson cards (expandable): Income, Expenses, Savings, Giving
  - Interactive budget exercise: given TZS 50,000 pocket money, allocate to categories
  - Savings goal tracker (same as school-age but with bigger goals)
  - Earn-Save-Spend-Give framework visualization
  - "My First Budget" template
  - Links to TAJIRI Budget module (placeholder)
  - Bilingual: "Elimu ya Fedha" / "Financial Literacy"

- [ ] Build `LifeSkillsPage`:
  - Checklist grouped by category:
    - Cooking/Kupika: boil water, make tea, cook rice, fry eggs, prepare full meal
    - Cleaning/Usafi: laundry by hand, ironing, room cleaning, bathroom cleaning
    - Finance/Fedha: count money, use M-Pesa, save in bank, budget monthly
    - Time Management/Usimamizi wa Muda: wake up alarm, homework schedule, weekly plan
    - Study Skills/Mbinu za Kusoma: note-taking, revision timetable, exam preparation
  - Progress bar per category
  - Overall readiness score: X/30 skills mastered
  - Mark skill as learned with date
  - Bilingual descriptions for each skill

- [ ] Build `IndependenceMilestonesPage`:
  - Timeline of major milestones with target ages:
    - Age 13: First phone / Simu ya kwanza
    - Age 14: First bank account / Akaunti ya kwanza
    - Age 15: Community service / Huduma ya jamii
    - Age 16: Part-time work / Kazi ya muda
    - Age 17: Driving theory / Nadharia ya udereva
    - Age 18: NIDA registration, Driving licence, Voting registration, HESLB application
  - Each milestone: target age, actual achievement date, status (upcoming/ready/achieved)
  - At age 18 prompts: link to TAJIRI NIDA module, Driving Licence module, HESLB module
  - Visual timeline (vertical line with dots, achieved = filled, upcoming = outline)

- [ ] Build `TeenDashboardView`:
  - Quick stats: GPA, life skills progress, savings balance, days to 18
  - Quick action grid (2x3):
    - Academics (school icon) -> TeenAcademicPage
    - Career (work icon) -> CareerGuidancePage
    - Money (account_balance icon) -> FinancialLiteracyPage
    - Life Skills (checklist icon) -> LifeSkillsPage
    - Independence (flag icon) -> IndependenceMilestonesPage
    - Health (health_and_safety icon) -> HealthLogPage (shared)
  - "Approaching 18" card (if age >= 17): shows upcoming independence milestones
  - Chores + allowance still accessible (carried from school-age)
  - "Earlier Stages" collapsible: school-age, toddler, infant history
  - Speed-dial FAB: Log Grade, Mark Skill, Log Health

### Verification

```bash
flutter analyze

# Manual test:
# 1. Register child aged 15 -> teen stage badge
# 2. Dashboard shows teen actions
# 3. Career guidance assessment works, shows results
# 4. Financial literacy budget exercise functional
# 5. Life skills checklist -- can check off items
# 6. Independence milestones show timeline
# 7. Can still access chores, allowance, grades from earlier stages
```

---

## Task 7: Cross-Age Features

**Goal:** Build features that span all age stages: digital RCH card, co-parent sharing, unified health record, extended growth charts.

### Files to Create

- `lib/my_children/pages/shared/emergency_card_page.dart`
- `lib/my_children/pages/shared/co_parent_sharing_page.dart`
- `lib/my_children/pages/shared/unified_health_record_page.dart`
- `lib/my_children/pages/shared/growth_charts_extended_page.dart`
- `lib/my_children/widgets/emergency_card_widget.dart`
- `lib/my_children/widgets/stage_history_section.dart`

### Steps

- [ ] Build `EmergencyCardPage`:
  - Card preview: child photo, name, DOB, age, blood type, allergies list, emergency contacts (name + phone), insurance number, NHIF status
  - Card styled as a physical card (rounded corners, white background, hospital/cross icon)
  - "Share" button: generates share link via API (POST /my-children/emergency-card/{childId})
  - "Save as Image" button: render card to image using RepaintBoundary + screenshot
  - Share via standard share sheet (share_plus package)
  - Display QR code with share link
  - Bilingual: "Kadi ya Dharura" / "Emergency Card"

- [ ] Build `EmergencyCardWidget` (reusable compact version):
  - Small card shown on child dashboard
  - Shows: name, blood type, allergies count, emergency contact count
  - Tappable -> navigates to full EmergencyCardPage

- [ ] Build `CoParentSharingPage`:
  - Extends existing `CaregiverSharingPage` with new roles
  - Role options: Co-Parent (full access), Caregiver (log + view), Viewer (view only), School (health/attendance only)
  - Invite flow: generate invite code, share via clipboard/share sheet
  - Active shares list: person name, role, status (pending/accepted)
  - Revoke access button per share
  - Co-parent sees exact same dashboard (no restrictions)
  - Bilingual: "Shiriki na Mzazi Mwenza" / "Share with Co-Parent"

- [ ] Build `UnifiedHealthRecordPage`:
  - Timeline view (vertical) spanning birth to current age
  - Events on timeline: vaccinations (syringe icon), doctor visits (hospital icon), illnesses (sick icon), medications (pill icon), growth measurements (ruler icon)
  - Filter chips: All, Vaccinations, Doctor Visits, Illness, Growth
  - Each event card: date, type icon, title, description
  - WHO/CDC growth chart thumbnail at top (tappable -> full growth charts)
  - Export button: generate PDF of full health record (placeholder -- just shows intent)
  - Bilingual: "Rekodi ya Afya" / "Health Record"

- [ ] Build `GrowthChartsExtendedPage`:
  - Replace/extend existing `growth_charts_page.dart`
  - WHO charts for 0-5 years: weight-for-age, length/height-for-age, head-circumference-for-age
  - CDC charts for 5-18 years: weight-for-age, stature-for-age, BMI-for-age
  - Auto-select chart set based on child age
  - Measurement history list with add measurement button
  - Chart implementation: simple line chart using CustomPaint (plot child data points on percentile grid)
  - Percentile lines: 3rd, 15th, 50th, 85th, 97th (drawn as grey horizontal reference lines)
  - Bilingual axis labels

- [ ] Build `StageHistorySection` widget:
  - Collapsible section that appears on dashboards for children past infant stage
  - Shows navigation links to previous stage features
  - Toddler dashboard: "Infant History" -> feeding, sleep, diaper logs
  - School-age dashboard: "Toddler History" -> potty, speech logs + "Infant History"
  - Teen dashboard: all three previous stages
  - Each link shows last data point date ("Last feeding: 2024-03-15")

### Verification

```bash
flutter analyze

# Manual test:
# 1. View emergency card for any child -> shows all info
# 2. Share button generates link
# 3. Co-parent sharing: invite, accept, revoke
# 4. Health record timeline shows events from all stages
# 5. Growth chart shows appropriate WHO/CDC chart for child's age
# 6. Stage history section navigates to previous stage data
```

---

## Task 8: Financial Integration (Expenses + Fees + Wallet)

**Goal:** Connect child expenses to Budget module, school fees to Fee Status, and allowance to Wallet.

### Files to Create

- `lib/my_children/pages/shared/child_expenses_page.dart`
- `lib/my_children/pages/shared/school_fee_tracker_page.dart`
- `lib/my_children/widgets/expense_summary_card.dart`

### Steps

- [ ] Build `ChildExpensesPage`:
  - Expense categories: Medical, School Fees, Activities, Clothing, Food, Other
  - Add expense: amount (TZS), category, description, date
  - Monthly summary: total per category, trend vs last month
  - Per-child expense view (each child's costs separated)
  - Integration hook: when expense is logged, trigger Budget module's `watoto` envelope update (placeholder -- log intent, actual integration when Budget module wires it)
  - Bilingual: "Matumizi ya Mtoto" / "Child Expenses"

- [ ] Build `SchoolFeeTrackerPage`:
  - Fee balance card: total fees, paid, outstanding
  - Term breakdown: Term 1/2/3 with paid/outstanding per term
  - Payment history: date, amount, receipt reference
  - Add payment button -> bottom sheet: amount, date, reference number
  - Integration hook: link to Fee Status module for linked schools
  - Budget integration: school fee payments flow into `ada_shule` envelope (placeholder)
  - Reminder section: next fee due date with countdown
  - Bilingual: "Ada ya Shule" / "School Fees"

- [ ] Build `ExpenseSummaryCard` widget:
  - Compact card for dashboard: total this month, top category, trend arrow
  - Tappable -> navigates to full ChildExpensesPage

- [ ] Add expense methods to `MyChildrenService`:
  - `logExpense(token, childId, amount, category, description, date)` -- POST /my-children/expenses
  - `getExpenses(token, childId, {month, year})` -- GET /my-children/expenses
  - `getExpenseSummary(token, childId)` -- GET /my-children/expenses/summary/{childId}
  - `logSchoolFeePayment(token, childId, amount, term, year, reference)` -- POST /my-children/school-fees
  - `getSchoolFees(token, childId)` -- GET /my-children/school-fees

- [ ] Ask backend to create expenses and school_fees tables:
  ```
  Create child_expenses table: id, child_id (FK), amount (decimal), category 
  (enum: medical/school_fees/activities/clothing/food/other), description, date, created_at.
  CRUD at /my-children/expenses. GET summary endpoint with monthly totals per category.

  Create child_school_fees table: id, child_id (FK), term, year, total_amount,
  paid_amount, payment_date, reference_number, notes, created_at.
  CRUD at /my-children/school-fees. GET balance endpoint.
  ```

### Verification

```bash
flutter analyze

# Manual test:
# 1. Log expense for child -> appears in list
# 2. Monthly summary shows correct totals
# 3. School fee payment logged -> balance updates
# 4. Dashboard expense card shows summary
```

---

## Task 9: Calendar + Notification Integration

**Goal:** Sync child events to TAJIRI Calendar and set up FCM notifications for important dates.

### Files to Modify

- `lib/my_children/services/my_children_service.dart` -- add reminder scheduling methods
- `lib/services/fcm_service.dart` -- add my_children notification handlers

### Steps

- [ ] Add reminder methods to `MyChildrenService`:
  - `scheduleVaccinationReminder(token, childId, vaccinationId, dueDate)` -- POST /my-children/reminders/vaccination
  - `scheduleSchoolFeeReminder(token, childId, dueDate, amount)` -- POST /my-children/reminders/school-fee
  - `scheduleCheckupReminder(token, childId, checkupType, dueDate)` -- POST /my-children/reminders/checkup
  - `getUpcomingReminders(token, childId)` -- GET /my-children/reminders

- [ ] Update FCM notification handling in `lib/services/fcm_service.dart`:
  - Handle payload type `my_children_vaccination` -- navigate to child's vaccination page
  - Handle payload type `my_children_school_fee` -- navigate to school fee tracker
  - Handle payload type `my_children_checkup` -- navigate to health record
  - Handle payload type `my_children_homework` -- navigate to homework tracker
  - Handle payload type `my_children_chore` -- navigate to chore chart

- [ ] Add upcoming events section to each dashboard:
  - InfantDashboard: next vaccination, next checkup
  - ToddlerDashboard: next vaccination, next checkup, potty streak goal
  - SchoolAgeDashboard: homework due, next activity, school fee due, next checkup
  - TeenDashboard: exam dates, school fee due, independence milestone approaching

- [ ] Ask backend for reminders table:
  ```
  Create child_reminders table: id, child_id (FK), type (vaccination/school_fee/checkup/homework/activity),
  title, remind_at (datetime), is_sent (boolean, default false), payload (json), created_at.
  CRUD at /my-children/reminders. Scheduler job sends FCM push at remind_at time.
  ```

### Verification

```bash
flutter analyze

# Manual test:
# 1. Schedule vaccination reminder -> notification received at scheduled time
# 2. Tap notification -> navigates to correct child's vaccination page
# 3. Dashboards show upcoming events
```

---

## Task 10: Shangazi AI Child Context

**Goal:** Pass child age and stage context to Shangazi AI so parenting questions get age-appropriate answers.

### Files to Modify

- `lib/my_children/services/my_children_service.dart` -- add context builder
- Integration point with Tea/Shangazi chat service

### Steps

- [ ] Create `ChildContext` helper in `MyChildrenService`:
  ```dart
  static Map<String, dynamic> buildChildContext(Child child) => {
    'child_name': child.name,
    'child_age_months': child.ageInMonths,
    'child_age_years': child.ageInYears,
    'child_stage': child.stage.name,
    'child_gender': child.gender,
    'child_allergies': child.allergies,
    'has_school': child.schoolId != null,
  };
  ```

- [ ] When user asks a parenting question in Shangazi Tea chat:
  - If user has children, include `children_context` in AI request payload
  - Shangazi can reference "your 3-year-old" or "for toddlers" in responses
  - Implementation: modify the Shangazi chat service to optionally include child context
  - Context is opt-in: user taps "Ask about [child name]" chip in chat

- [ ] Add "Ask Shangazi" button on each dashboard:
  - Pre-fills chat with child context
  - Example: navigates to Tea chat with context "I have a question about my 8-year-old son Juma"

### Verification

```bash
flutter analyze

# Manual test:
# 1. Open child dashboard -> "Ask Shangazi" button visible
# 2. Tap -> navigates to Tea chat with child context pre-loaded
```

---

## Task 11: SQLite Offline Cache

**Goal:** Implement offline-first storage for child data following the MessageDatabase pattern from `docs/SQLITE_ADOPTION_ROADMAP.md`.

### Files to Create

- `lib/my_children/services/my_children_database.dart`

### Steps

- [ ] Create `MyChildrenDatabase` singleton following `MessageDatabase` pattern:
  - Tables:
    - `children` -- id, user_id, json_data TEXT, stage TEXT (indexed), updated_at
    - `health_logs` -- id, child_id (indexed), type (indexed), json_data TEXT, logged_at (indexed)
    - `chore_assignments` -- id, child_id (indexed), json_data TEXT, is_completed, updated_at
    - `academic_records` -- id, child_id (indexed), term, year, json_data TEXT
    - `growth_measurements` -- id, child_id (indexed), json_data TEXT, measured_at
    - `vaccinations` -- id, child_id (indexed), json_data TEXT, is_done, due_date
    - `pending_sync` -- id, entity_type, entity_id, action (create/update/delete), json_data TEXT, retry_count, created_at
    - `sync_state` -- entity_type PRIMARY KEY, last_synced_id, last_sync_timestamp

  - Methods:
    - `upsertChild(Child)` / `getChildren(userId)` / `getChild(childId)`
    - `upsertHealthLog(HealthLog)` / `getHealthLogs(childId, {type, dateRange})`
    - `upsertChore(ChoreAssignment)` / `getChores(childId)`
    - `upsertAcademicRecord(AcademicRecord)` / `getAcademicRecords(childId, {term, year})`
    - `upsertGrowth(GrowthMeasurement)` / `getGrowthHistory(childId)`
    - `upsertVaccination(Vaccination)` / `getVaccinations(childId)`
    - `addPendingSync(entityType, entityId, action, jsonData)` / `getPendingSyncs()` / `removePendingSync(id)`
    - `updateSyncState(entityType, lastId, timestamp)` / `getSyncState(entityType)`

- [ ] Modify `MyChildrenService` to use local-first pattern:
  - On read: return SQLite data immediately, fetch from API in background, update SQLite on response
  - On write: write to SQLite + add to pending_sync queue, fire API call, on success remove from pending queue
  - On failure: keep in pending queue with incremented retry_count
  - Stale-while-revalidate: show cached data, refresh if older than 5 minutes

- [ ] Add sync worker:
  - On app open: process pending_sync queue (retry failed writes)
  - On connectivity restored: same
  - Delta sync: use `last_synced_id` to fetch only new/updated records from server

### Verification

```bash
flutter analyze

# Manual test:
# 1. Load children list -> data cached in SQLite
# 2. Kill network -> open module -> cached data appears instantly
# 3. Log a chore offline -> appears in UI
# 4. Restore network -> pending sync processes, data appears on server
# 5. On next open, cached data shows while fresh data loads in background
```

---

## Task 12: Final Wiring + Deep Crawl Audit

**Goal:** Ensure everything is connected, all navigation works, no dead pages, no compilation errors.

### Steps

- [ ] Wire all navigation paths from MyChildrenHomePage:
  - Tap child card -> ChildDashboardPage (age-adaptive)
  - Each dashboard action -> correct page
  - Each page back button -> returns to dashboard
  - Speed-dial FAB actions -> correct forms/pages

- [ ] Update My Pregnancy handoff:
  - `lib/my_pregnancy/pages/pregnancy_home_page.dart`: "Baby is Born" flow should:
    1. Register child via `MyChildrenService.registerChild()`
    2. Navigate to `ChildDashboardPage` for the new infant
  - Verify handoff works: complete pregnancy -> child appears in My Children

- [ ] Verify all cross-references:
  ```bash
  # No remaining my_baby imports outside lib/my_baby/
  grep -r "my_baby" lib/ --include="*.dart" | grep -v "lib/my_baby/"
  # Should return 0 results (or only comments)
  ```

- [ ] Run deep crawl audit on all new files:
  - Every page has bilingual text (Swahili + English) via `_isSwahili` ternary
  - Every API call wrapped in try/catch with `if (mounted)` check before setState
  - No double AppBar (pages inside dashboard don't have their own Scaffold+AppBar)
  - No dead pages (every page reachable from navigation)
  - No hardcoded data in lists that should come from API
  - Photo upload wired with actual file picker + multipart upload
  - All dialogs follow bottom sheet pattern (not AlertDialog)
  - All touch targets >= 48dp
  - All dynamic text has maxLines + TextOverflow.ellipsis
  - All text fields have proper keyboard types
  - All controllers disposed in dispose()

- [ ] Run verification:
  ```bash
  flutter analyze
  # 0 errors, 0 warnings ideally

  # Count files created
  find lib/my_children -name "*.dart" | wc -l
  # Expected: ~35-40 files

  # Verify no unused imports
  flutter analyze --no-fatal-infos 2>&1 | grep "unused_import"
  # Should be 0
  ```

- [ ] Clean up old `lib/my_baby/` directory:
  - Only delete after all references are updated and verified
  - Keep as backup until next release

### Final File Count Estimate

```
lib/my_children/
  my_children_module.dart                           (1)
  models/
    child_model.dart                                (1)
    my_children_models.dart                         (1) barrel
    toddler_models.dart                             (1)
    school_age_models.dart                          (1)
    teen_models.dart                                (1)
  services/
    my_children_service.dart                        (1)
    my_children_database.dart                       (1)
  widgets/
    vaccination_card.dart                           (1)
    emergency_card_widget.dart                      (1)
    expense_summary_card.dart                       (1)
    stage_history_section.dart                      (1)
  pages/
    my_children_home_page.dart                      (1)
    child_dashboard_page.dart                       (1)
    infant/
      infant_dashboard_view.dart                    (1)
      feeding_tracker_page.dart                     (1) copied
      sleep_tracker_page.dart                       (1) copied
      diaper_tracker_page.dart                      (1) copied
      vaccination_page.dart                         (1) copied
      milestones_page.dart                          (1) copied
      health_log_page.dart                          (1) copied
      summary_page.dart                             (1) copied
      caregiver_sharing_page.dart                   (1) copied
      photo_journal_page.dart                       (1) copied
      growth_charts_page.dart                       (1) copied
    toddler/
      toddler_dashboard_view.dart                   (1)
      potty_training_page.dart                      (1)
      speech_development_page.dart                  (1)
      behavior_chart_page.dart                      (1)
      learning_activities_page.dart                 (1)
    school_age/
      school_age_dashboard_view.dart                (1)
      school_enrollment_page.dart                   (1)
      academic_tracking_page.dart                   (1)
      homework_tracker_page.dart                    (1)
      chore_chart_page.dart                         (1)
      allowance_page.dart                           (1)
      activity_manager_page.dart                    (1)
      reading_log_page.dart                         (1)
    teen/
      teen_dashboard_view.dart                      (1)
      teen_academic_page.dart                       (1)
      career_guidance_page.dart                     (1)
      financial_literacy_page.dart                  (1)
      life_skills_page.dart                         (1)
      independence_milestones_page.dart             (1)
    shared/
      emergency_card_page.dart                      (1)
      co_parent_sharing_page.dart                   (1)
      unified_health_record_page.dart               (1)
      growth_charts_extended_page.dart              (1)
      child_expenses_page.dart                      (1)
      school_fee_tracker_page.dart                  (1)
                                                   ----
                                              Total: ~47 files
```

---

## Task Dependencies

```
Task 1 (Rename + Refactor) ─────┬── Task 3 (Module Wiring)
                                │
Task 2 (Backend) ───────────────┤
                                │
                                ├── Task 4 (Toddler) ──────┐
                                │                           │
                                ├── Task 5 (School-Age) ────┤
                                │                           │
                                ├── Task 6 (Teen) ──────────┤
                                │                           │
                                ├── Task 7 (Cross-Age) ─────┤
                                │                           │
                                └── Task 8 (Financial) ─────┤
                                                            │
                                Task 9 (Calendar/FCM) ──────┤
                                                            │
                                Task 10 (Shangazi AI) ──────┤
                                                            │
                                Task 11 (SQLite Cache) ─────┤
                                                            │
                                Task 12 (Final Audit) ──────┘
```

Tasks 1+2 must complete first. Tasks 3-11 can be parallelized (with Task 3 ideally before 4-6). Task 12 is always last.
