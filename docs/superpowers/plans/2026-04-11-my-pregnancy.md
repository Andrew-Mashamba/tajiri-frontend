# My Pregnancy — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Complete the My Pregnancy prenatal tracker with all 56 features from the design spec.

**Architecture:** Flutter module with backend API, SQLite local cache for offline-first. Follows TAJIRI patterns: setState, monochrome Material 3, bilingual, SafeArea, 48dp touch targets.

**Tech Stack:** Flutter/Dart, Laravel backend, PostgreSQL, SQLite (sqflite), FCM

**Spec:** `docs/modules/my_pregnancy.md`

---

## Current State Analysis

### Existing Files (10 files)
| File | Features Covered | Issues Found |
|------|-----------------|--------------|
| `my_pregnancy_module.dart` | Entry point | Minimal wrapper, works fine |
| `models/my_pregnancy_models.dart` | Pregnancy, WeekInfo, AncVisit, KickCount, DangerSign, PregnancySymptom | `trimesterLabel` is Swahili-only (no bilingual). Missing models: Contraction, WeightEntry, MoodEntry, BirthPlan, NutritionItem, SymptomLog |
| `services/my_pregnancy_service.dart` | CRUD pregnancy, week info, ANC visits, kick counter | **No auth token** sent on ANY request (headers lack `Authorization`). Error messages Swahili-only. No contraction/weight/mood/symptom-save endpoints |
| `pages/pregnancy_home_page.dart` | Home screen, week card, quick actions, ANC reminder, baby-is-born, cross-module links | All text Swahili-only (no `AppStrings`). ANC reminder card not tappable (no `onTap` to navigate to ANC page). "Baby is Born" button uses green color (violates monochrome). Missing quick actions: Contraction Timer, Weight, Mood |
| `pages/pregnancy_week_page.dart` | Weekly detail, baby size, development, checklist, symptom logger | **Symptom logger never saves** — `_loggedSymptoms` is in-memory only, no API call. All text Swahili-only. Default content fallbacks are good but also Swahili-only |
| `pages/anc_schedule_page.dart` | 8-visit timeline, mark complete, progress bar, danger signs link, doctor link | `_markVisitDone` doesn't send facility/notes (dialog for entering them is missing). All text Swahili-only |
| `pages/kick_counter_page.dart` | Real-time session, timer, goal indicator, history | **Goal snackbar fires on EVERY kick after 10** (line 75: `if (_kickCount >= 10)` should be `== 10`). All text Swahili-only. No auth token |
| `pages/danger_signs_page.dart` | 8 danger signs, emergency call, hospital finder, emergency numbers | All text Swahili-only. `_openMaps` silently fails — should show snackbar. Emergency number touch targets may be too small |
| `widgets/week_progress_card.dart` | Week display, fruit comparison, progress bar, baby name | Works well. Text Swahili-only |
| `widgets/kick_counter_widget.dart` | Animated tap circle | Works well. Text Swahili-only. No haptic feedback on tap |

### Feature Coverage (from 56-feature spec)

**Implemented (24 features):**
1, 2, 3, 4, 5, 6 (partial — journal missing), 8, 9, 10, 11, 12, 13 (partial — no save), 14 (partial), 15, 16, 17, 18 (partial — no facility/notes dialog), 19, 23, 24, 25, 26, 28, 29, 30, 51, 52, 53, 54, 55

**Not implemented (22 features):**
7 (pregnancy journal), 20 (link to Doctor for ANC booking), 21 (sync ANC to Calendar), 22 (push notifications for ANC), 27 (kick decrease alert), 31 (nearest facility GPS), 32-35 (contraction timer), 36-38 (weight tracker), 39-42 (nutrition guide), 43-46 (birth plan), 47-50 (mental health/mood), 56 (transfer data to baby)

**Partially implemented / Needs fixing (10 features):**
6 (baby name entry exists but no journal), 13 (symptom chips exist but never persist), 14 (danger symptoms flag but no persistence), 18 (mark-done exists but no facility/notes input), 25 (kick counter widget exists but no haptic), 29 (call button exists but 114 duplicate entry for fire/ambulance)

### Backend Endpoints (existing, using `/my-baby/` prefix)
- `POST /my-baby/pregnancy` — create pregnancy
- `GET /my-baby/pregnancy?user_id=` — get active pregnancy
- `PUT /my-baby/pregnancy/{id}` — update pregnancy
- `GET /my-baby/week-info/{weekNumber}` — get week content
- `GET /my-baby/anc-visits?pregnancy_id=` — list ANC visits
- `POST /my-baby/anc-visits/{id}/complete` — mark ANC done
- `POST /my-baby/kick-counts` — save kick session
- `GET /my-baby/kick-counts?pregnancy_id=` — kick history

---

## Task 1: Backend — New Tables & Endpoints

**Ask backend via:** `./scripts/ask_backend.sh`

### New Database Tables
- [ ] `pregnancy_symptoms` — id, pregnancy_id, user_id, week_number, symptoms (JSON array), notes, logged_at
- [ ] `pregnancy_contractions` — id, pregnancy_id, start_time, end_time, duration_seconds, interval_seconds, session_id
- [ ] `pregnancy_weight_logs` — id, pregnancy_id, weight_kg, week_number, bmi, logged_at
- [ ] `pregnancy_mood_logs` — id, pregnancy_id, mood (1-5), notes, logged_at
- [ ] `pregnancy_birth_plans` — id, pregnancy_id, delivery_preference, hospital_name, hospital_bag_checklist (JSON), emergency_contacts (JSON), birth_partner, pain_relief_preference, notes, updated_at
- [ ] `pregnancy_journal_entries` — id, pregnancy_id, content, photo_url, week_number, created_at

### New Endpoints
- [ ] `POST /my-baby/symptoms` — save symptom log (pregnancy_id, week, symptoms[], notes)
- [ ] `GET /my-baby/symptoms?pregnancy_id=` — get symptom history
- [ ] `POST /my-baby/contractions` — save contraction entry (pregnancy_id, start_time, end_time, session_id)
- [ ] `GET /my-baby/contractions?pregnancy_id=&session_id=` — get contraction history
- [ ] `POST /my-baby/weight-logs` — save weight entry (pregnancy_id, weight_kg, week)
- [ ] `GET /my-baby/weight-logs?pregnancy_id=` — get weight history
- [ ] `POST /my-baby/mood-logs` — save mood entry (pregnancy_id, mood, notes)
- [ ] `GET /my-baby/mood-logs?pregnancy_id=` — get mood history
- [ ] `GET /my-baby/birth-plan?pregnancy_id=` — get birth plan
- [ ] `PUT /my-baby/birth-plan` — save/update birth plan
- [ ] `POST /my-baby/journal` — save journal entry
- [ ] `GET /my-baby/journal?pregnancy_id=` — list journal entries
- [ ] `GET /my-baby/nutrition-guide` — get safe/unsafe foods list (static content, cacheable)
- [ ] Modify existing `POST /my-baby/anc-visits/{id}/complete` to accept `facility` and `notes` fields

### Backend Prompt Template
```
./scripts/ask_backend.sh "For the My Pregnancy module (prefix /my-baby/), create these new tables and endpoints: [paste tables and endpoints above]. All endpoints should require auth (Bearer token). Use existing pregnancy model relationships. Return JSON with {success: bool, data: ..., message: string}."
```

### Verification
- [ ] `curl` each new endpoint to confirm 200/401 responses
- [ ] Confirm auth middleware is on all pregnancy endpoints

---

## Task 2: Fix Existing Pages — Auth, Bilingual, Bugs

**Files to modify:**
- `lib/my_pregnancy/services/my_pregnancy_service.dart`
- `lib/my_pregnancy/models/my_pregnancy_models.dart`
- `lib/my_pregnancy/pages/pregnancy_home_page.dart`
- `lib/my_pregnancy/pages/pregnancy_week_page.dart`
- `lib/my_pregnancy/pages/anc_schedule_page.dart`
- `lib/my_pregnancy/pages/kick_counter_page.dart`
- `lib/my_pregnancy/pages/danger_signs_page.dart`
- `lib/my_pregnancy/widgets/week_progress_card.dart`
- `lib/my_pregnancy/widgets/kick_counter_widget.dart`

### 2a. Add auth token to ALL service calls
- [ ] Change `MyPregnancyService` from instance-based to follow TAJIRI convention: accept `String token` parameter on every method
- [ ] Add `ApiConfig.authHeaders(token)` to all HTTP requests
- [ ] Update all call sites in pages to pass token from `LocalStorageService`

### 2b. Make all text bilingual
- [ ] Add pregnancy strings to `lib/l10n/app_strings.dart` (or use `AppStringsScope.of(context)` ternary pattern directly in widgets)
- [ ] In `Pregnancy.trimesterLabel` — accept `bool isSwahili` parameter or make two getter variants
- [ ] In `PregnancySymptom` — add `englishName` getter alongside `swahiliName`
- [ ] In `DangerSign.all()` — add English versions of title, description, action
- [ ] In every page: replace all hardcoded Swahili strings with bilingual ternary pattern: `sw ? 'Swahili' : 'English'`
- [ ] Key strings to translate: "Hesabu Mateke" -> "Kick Counter", "Dalili za Hatari" -> "Danger Signs", "Kliniki (ANC)" -> "ANC Clinic", "Wiki" -> "Week", "Anza Kufuatilia" -> "Start Tracking", "Mtoto Amezaliwa" -> "Baby is Born", "Ushauri wa Wiki Hii" -> "This Week's Tip", "Huduma Zinazohusiana" -> "Related Services", etc.

### 2c. Fix bugs
- [ ] **kick_counter_page.dart line 75**: Change `if (_kickCount >= 10)` to `if (_kickCount == 10)` so goal snackbar fires once
- [ ] **pregnancy_week_page.dart**: Symptom logger `_loggedSymptoms` must call service to save. Add `_saveSymptoms()` method that calls `POST /my-baby/symptoms`. Add a "Save" button below the symptom chips
- [ ] **pregnancy_home_page.dart**: ANC reminder card — wrap in `GestureDetector` with `onTap` that navigates to `AncSchedulePage`
- [ ] **pregnancy_home_page.dart**: "Baby is Born" button — change green `Color(0xFF4CAF50)` to `_kPrimary` (monochrome compliance). Use outlined style to differentiate
- [ ] **anc_schedule_page.dart**: `_markVisitDone` — show a dialog first that collects facility name and notes before calling service
- [ ] **danger_signs_page.dart**: `_openMaps` — show snackbar on failure instead of silently failing
- [ ] **danger_signs_page.dart**: Fix emergency numbers — "Zimamoto" should be 115 (fire), not 114 (duplicate of ambulance)
- [ ] **kick_counter_widget.dart**: Add `HapticFeedback.mediumImpact()` on tap for physical feedback
- [ ] **pregnancy_home_page.dart**: The `SnackBar` in `_completeBabyIsBorn` uses green — change to monochrome

### Verification
```bash
flutter analyze lib/my_pregnancy/
# Check no hardcoded Swahili-only strings remain (grep for common Swahili words without ternary)
grep -rn "const Text(" lib/my_pregnancy/ | grep -v "sw \?" | head -20
```

---

## Task 3: New Page — Contraction Timer

**Spec features:** 32, 33, 34, 35

**New files:**
- `lib/my_pregnancy/pages/contraction_timer_page.dart`
- `lib/my_pregnancy/models/my_pregnancy_models.dart` (add Contraction model)

### What to build
- [ ] **Contraction model**: `id, pregnancyId, startTime, endTime, durationSeconds, intervalSeconds, sessionId`
- [ ] **Service methods**: `saveContraction()`, `getContractionHistory()` in `my_pregnancy_service.dart`
- [ ] **UI — Timer screen**:
  - Large "Start/Stop" toggle button (center of screen, 48dp+ touch target)
  - When contraction starts: tap to start timer (shows elapsed time)
  - When contraction ends: tap to stop (records duration)
  - Between contractions: shows interval timer (time since last contraction ended)
  - List below showing session history: each contraction with duration + interval
- [ ] **Pattern recognition (5-1-1 rule)**:
  - Track last 6+ contractions
  - If average interval <= 5 minutes AND average duration >= 60 seconds AND pattern has held for >= 1 hour: show alert banner
  - Banner text: "Contractions are regular. Consider going to the hospital." / Swahili equivalent
- [ ] **Session management**: Generate UUID `sessionId` per counting session. Group history by session
- [ ] **Local state**: Track contractions in-memory during session, save to API when session ends or periodically

### Design
- Monochrome palette. Large circular button similar to KickCounterWidget
- Timer font: 36px, lightweight (w300)
- Contraction list: white cards with duration/interval columns
- Alert banner: use red emergency styling (same as danger signs)

### Verification
```bash
flutter analyze lib/my_pregnancy/pages/contraction_timer_page.dart
# Manual: start/stop 5+ contractions, verify durations and intervals display correctly
```

---

## Task 4: New Page — Weight Tracker

**Spec features:** 36, 37, 38

**New files:**
- `lib/my_pregnancy/pages/weight_tracker_page.dart`
- `lib/my_pregnancy/models/my_pregnancy_models.dart` (add WeightEntry model)

### What to build
- [ ] **WeightEntry model**: `id, pregnancyId, weightKg, weekNumber, bmi, loggedAt`
- [ ] **Service methods**: `saveWeightLog()`, `getWeightHistory()` in `my_pregnancy_service.dart`
- [ ] **UI — Weight log + chart**:
  - "Log Weight" button at top — opens bottom sheet with weight input (kg, numeric keyboard)
  - Auto-fills current week number
  - Weight chart: `CustomPaint` or simple bar representation showing weight over weeks
  - Recommended weight gain range overlay (based on pre-pregnancy BMI):
    - Underweight (BMI < 18.5): 12.5-18 kg total
    - Normal (18.5-24.9): 11.5-16 kg total
    - Overweight (25-29.9): 7-11.5 kg total
    - Obese (30+): 5-9 kg total
  - Current total gain displayed prominently
  - History list below chart showing each logged entry

### BMI Logic
- [ ] Ask for pre-pregnancy weight during pregnancy setup (optional field)
- [ ] Calculate BMI from height (add height field to pregnancy model if not present — or ask once in setup)
- [ ] If no pre-pregnancy data, show chart without recommended range overlay

### Design
- Weight input: large number display, +/- 0.1kg buttons for fine adjustment
- Chart: simple line with dots at each data point. Grey recommended range band behind it
- Monochrome. No colored indicators for "over/under" — just show the range

### Verification
```bash
flutter analyze lib/my_pregnancy/pages/weight_tracker_page.dart
# Manual: log 3 weights, verify chart renders, verify recommended range shows
```

---

## Task 5: New Page — Nutrition Guide

**Spec features:** 39, 40, 41, 42

**New files:**
- `lib/my_pregnancy/pages/nutrition_guide_page.dart`

### What to build
- [ ] **Static content page** (no model needed — content is hardcoded or fetched once from API and cached)
- [ ] **Safe foods section**: List of recommended foods during pregnancy, Tanzania-specific:
  - Dagaa (small dried fish — iron + calcium)
  - Mchicha (amaranth greens — iron + folic acid)
  - Maharage (beans — protein + iron)
  - Viazi vitamu (sweet potatoes — vitamin A)
  - Ndizi za kupika (cooking bananas — potassium)
  - Mayai (eggs — protein + choline)
  - Maziwa (milk — calcium)
  - Matunda (fruits — vitamins)
- [ ] **Unsafe foods section**: Foods to avoid:
  - Nyama mbichi (raw meat — toxoplasmosis risk)
  - Samaki wenye zebaki (mercury-containing fish)
  - Muhogo mbichi (raw cassava — cyanide risk)
  - Pombe (alcohol — fetal alcohol syndrome)
  - Kahawa kupita kiasi (excess caffeine — limit to 200mg/day)
  - Mimea fulani (certain traditional herbs — may cause contractions)
- [ ] **Daily nutrients section**: Recommended daily intake:
  - Iron: 27mg (explain: take with vitamin C, not with tea)
  - Folic acid: 600mcg (especially T1)
  - Calcium: 1000mg
  - Vitamin D: 600 IU
  - Iodine: 220mcg
- [ ] **Hydration reminder**: Target 8-10 glasses/day. Simple display, not a full tracker
- [ ] **Meal suggestions**: 3 sample daily meal plans using Tanzanian foods (breakfast/lunch/dinner)

### Design
- Tab or section-based layout: Safe Foods | Unsafe Foods | Nutrients | Meals
- Each food item: icon/emoji + name + brief reason (bilingual)
- Green checkmark for safe, red X for unsafe
- Wait — monochrome: use filled/outlined circle indicators instead of green/red

### Verification
```bash
flutter analyze lib/my_pregnancy/pages/nutrition_guide_page.dart
# Manual: scroll through all sections, verify bilingual text
```

---

## Task 6: New Page — Birth Plan

**Spec features:** 43, 44, 45, 46

**New files:**
- `lib/my_pregnancy/pages/birth_plan_page.dart`
- `lib/my_pregnancy/models/my_pregnancy_models.dart` (add BirthPlan model)

### What to build
- [ ] **BirthPlan model**: `id, pregnancyId, deliveryPreference, hospitalName, hospitalBagChecklist (Map<String, bool>), emergencyContacts (List<EmergencyContact>), birthPartner, painReliefPreference, notes`
- [ ] **EmergencyContact model**: `name, phone, relationship`
- [ ] **Service methods**: `getBirthPlan()`, `saveBirthPlan()` in `my_pregnancy_service.dart`
- [ ] **UI — Tabbed or sectioned page**:

  **Section 1: Hospital Bag Checklist**
  - Pre-populated checklist of items (bilingual), user can check/uncheck:
    - Mother items: Kitambulisho (ID), Kadi ya kliniki (ANC card), Nguo za kulalia (nightgown), Taulo (towel), Sabuni (soap), Pedi (sanitary pads), Slippers, Vyakula vidogo (snacks), Maji (water), Simu + charger
    - Baby items: Nguo za mtoto (baby clothes x4), Blanketi (blanket), Nepi (diapers), Kofia (hat), Soksi (socks)
  - Progress indicator: "8/15 items packed"
  - User can add custom items

  **Section 2: Delivery Preferences**
  - Delivery type preference: Natural / Caesarean / No preference
  - Pain relief: None / Gas & Air / Epidural / Other
  - Birth partner: text field for name
  - Additional notes: free text

  **Section 3: Hospital/Facility**
  - Text field for hospital name
  - Optional: phone number field

  **Section 4: Emergency Contacts**
  - List of contacts with name + phone + relationship
  - Add/remove contacts
  - "Call" button next to each (launch phone dialer)

- [ ] Auto-save on changes (debounced, save after 2 seconds of no changes)

### Design
- Expandable sections or vertical scroll
- Checklist items: checkbox + text, 48dp row height
- Monochrome throughout

### Verification
```bash
flutter analyze lib/my_pregnancy/pages/birth_plan_page.dart
# Manual: check/uncheck items, add emergency contact, verify persistence after leaving and returning
```

---

## Task 7: New Page — Mood Tracker

**Spec features:** 47, 48, 49, 50

**New files:**
- `lib/my_pregnancy/pages/mood_tracker_page.dart`
- `lib/my_pregnancy/models/my_pregnancy_models.dart` (add MoodEntry model)

### What to build
- [ ] **MoodEntry model**: `id, pregnancyId, mood (1-5), notes, loggedAt`
- [ ] **Service methods**: `saveMoodLog()`, `getMoodHistory()` in `my_pregnancy_service.dart`
- [ ] **UI — Mood logging**:
  - 5 emoji-based mood options (same pattern as My Circle if it has one):
    - 1: Very sad (struggling)
    - 2: Sad (low)
    - 3: Neutral (okay)
    - 4: Happy (good)
    - 5: Very happy (great)
  - Use text-based mood icons from Material Icons (not emoji) to stay monochrome: `sentiment_very_dissatisfied`, `sentiment_dissatisfied`, `sentiment_neutral`, `sentiment_satisfied`, `sentiment_very_satisfied`
  - Optional notes text field
  - "Save" button
  - History: simple list of past entries with date + mood icon

- [ ] **Pregnancy affirmations** (bilingual):
  - Display one random affirmation per day
  - Examples: "You are strong and capable" / "Wewe ni hodari na una uwezo", "Your body knows what to do" / "Mwili wako unajua la kufanya"
  - Store 20+ affirmations, rotate daily

- [ ] **Weekly stress check** (simple):
  - 5 questions (WHO-5 Wellbeing Index adapted):
    1. "I have felt cheerful and in good spirits" / "Nimejisikia furaha na moyo mzuri"
    2. "I have felt calm and relaxed" / "Nimejisikia utulivu"
    3. "I have felt active and energetic" / "Nimejisikia nguvu na bidii"
    4. "I woke up feeling fresh and rested" / "Nimeamka nikiwa mpya na nimepumzika"
    5. "My daily life has been filled with things that interest me" / "Maisha yangu ya kila siku yamejaa mambo yanayonifurahisha"
  - Each scored 0-5 (All the time → At no time)
  - Score < 13/25: suggest "Talk to a professional" with link to Doctor module
  - Show weekly, not daily

- [ ] **Link to Doctor module**: "Talk to a Counselor" button at bottom → `/doctor` route

### Design
- Mood icons: 48dp minimum, spaced evenly in a row
- Selected mood: slightly larger with subtle border
- Affirmation: card with quotation mark icon, centered text
- Monochrome throughout

### Verification
```bash
flutter analyze lib/my_pregnancy/pages/mood_tracker_page.dart
# Manual: select mood, save, verify in history. Check stress questionnaire scoring
```

---

## Task 8: Notifications + Calendar Integration

**Spec features:** 21, 22, 27

**Files to modify:**
- `lib/my_pregnancy/services/my_pregnancy_service.dart`
- `lib/services/fcm_service.dart` (or new notification scheduling)
- Backend: notification scheduling

### What to build

### 8a. ANC Push Notification Reminders
- [ ] **Backend**: When ANC visits are created, schedule FCM notifications for 2 days before each visit date
- [ ] **Backend prompt**: `./scripts/ask_backend.sh "When creating ANC visits for pregnancy, schedule push notifications via FCM 2 days before each scheduled_date. Notification payload: {type: 'anc_reminder', pregnancy_id, visit_number, scheduled_date}. Title: 'ANC Visit Reminder'. Body: 'Your ANC visit #{visit_number} is in 2 days.'"`
- [ ] **Frontend**: Handle `anc_reminder` notification type in FCM service to navigate to ANC schedule page

### 8b. Calendar Sync
- [ ] Add method `syncToCalendar()` in pregnancy service that creates calendar events for:
  - All 8 ANC visit dates
  - Due date
- [ ] Use TAJIRI Calendar module API if it exists, or device calendar via `device_calendar` package
- [ ] Add "Sync to Calendar" button on ANC Schedule page

### 8c. Kick Decrease Alert
- [ ] In kick counter history, compare last 3 sessions
- [ ] If kick count decreases by more than 30% from average of previous sessions, show warning
- [ ] Warning text: "Kick count has decreased. Monitor closely and contact your doctor if concerned."

### Verification
- [ ] Trigger test notification, verify routing
- [ ] Manual: check kick decrease alert by simulating declining counts

---

## Task 9: SQLite Offline Cache

**Pattern:** Follow `lib/services/message_database.dart` singleton pattern

**New file:**
- `lib/my_pregnancy/services/pregnancy_database.dart`

### What to build
- [ ] **Singleton SQLite database** with tables:
  ```
  pregnancy (id, user_id, json_data TEXT, updated_at)
  anc_visits (id, pregnancy_id, visit_number, json_data TEXT, updated_at)
  kick_counts (id, pregnancy_id, json_data TEXT, date)
  week_info (week_number PRIMARY KEY, json_data TEXT, cached_at)
  contraction_sessions (id, pregnancy_id, json_data TEXT, session_id, created_at)
  weight_logs (id, pregnancy_id, json_data TEXT, logged_at)
  mood_logs (id, pregnancy_id, json_data TEXT, logged_at)
  birth_plan (id, pregnancy_id, json_data TEXT, updated_at)
  pending_mutations (id, entity_type, entity_id, action, json_data TEXT, retry_count, created_at)
  sync_state (entity_type PRIMARY KEY, last_synced_id, last_sync_timestamp)
  ```

- [ ] **Stale-while-revalidate pattern**:
  - On page load: show SQLite data immediately, fetch from API in background
  - On API success: update SQLite, silently refresh UI if data changed
  - On API failure: keep showing SQLite data, show subtle offline indicator

- [ ] **Offline kick counter**:
  - Save kick session to SQLite immediately on stop
  - Queue API save in `pending_mutations` table
  - On next online: flush pending mutations to API
  - Same for contraction timer sessions

- [ ] **Weekly content cache**:
  - Cache week info in SQLite with `cached_at` timestamp
  - TTL: 7 days (content rarely changes)
  - Pre-cache adjacent weeks (current-1, current, current+1)

- [ ] **Modify service layer**:
  - Each service method: try SQLite first, return cached data, fire API in background
  - New method pattern:
    ```dart
    Future<Pregnancy?> getMyPregnancy(int userId, String token) async {
      // 1. Return cached immediately
      final cached = await PregnancyDatabase.instance.getPregnancy(userId);
      if (cached != null) _notifyUI(cached); // via callback
      // 2. Fetch fresh
      final fresh = await _fetchFromApi(userId, token);
      if (fresh != null) await PregnancyDatabase.instance.savePregnancy(fresh);
      return fresh ?? cached;
    }
    ```

### Verification
```bash
flutter analyze lib/my_pregnancy/services/pregnancy_database.dart
# Manual: load pregnancy data, enable airplane mode, verify data still displays
# Manual: record kicks offline, go online, verify sync
```

---

## Task 10: Wire Navigation + Quick Actions

**Files to modify:**
- `lib/my_pregnancy/pages/pregnancy_home_page.dart`
- `lib/my_pregnancy/my_pregnancy_module.dart`

### What to build
- [ ] **Add new quick actions** to home page grid (currently 3: Kick Counter, ANC, Danger Signs):
  - Add: Contraction Timer, Weight Tracker, Nutrition Guide, Birth Plan, Mood Tracker
  - Reorganize into 2 rows of 4, or scrollable row, or grid
  - Each quick action navigates to respective new page

- [ ] **Add journal entry point** (feature 7):
  - "Add Journal Entry" button or section on home page
  - Simple bottom sheet: text field + optional photo
  - Saves to `POST /my-baby/journal`

- [ ] **Wire ANC reminder tap** on home page to navigate to ANC schedule

- [ ] **Add Nutrition Guide and Mood to "Related Services" section** or as standalone sections on home

- [ ] **Verify profile tab wiring**: Already wired in `profile_screen.dart` case `'my_pregnancy'` — confirm still works with all changes

### Home Page Layout (updated)
```
[Week Progress Card — tappable to weekly detail]

Quick Actions (2x4 grid or scrollable):
  Kick Counter | ANC Clinic | Danger Signs | Contractions
  Weight       | Nutrition  | Birth Plan   | Mood

[Next ANC Reminder — tappable]
[Weekly Tip]
[Daily Affirmation]
[Emergency Banner]
[Baby is Born button/link]
[Related Services]
```

### Verification
```bash
flutter analyze lib/my_pregnancy/
# Manual: tap every quick action, verify navigation to correct page and back
```

---

## Task 11: Final Verification & Polish

### Full module audit
- [ ] Run `flutter analyze lib/my_pregnancy/` — zero errors, zero warnings
- [ ] Every page has `SafeArea` or is wrapped by Scaffold (Scaffold provides safe area via AppBar)
- [ ] Every tappable element is at least 48dp
- [ ] Every dynamic text has `maxLines` + `TextOverflow.ellipsis`
- [ ] Every `_rounded` icon variant used (not plain icons)
- [ ] No hardcoded colors outside the monochrome palette (exception: emergency red for danger signs only)
- [ ] All text is bilingual (no Swahili-only strings except in Swahili-specific content like food names)
- [ ] All API calls send auth token
- [ ] All API calls have try/catch with mounted check
- [ ] All controllers disposed in `dispose()`
- [ ] No green/blue/orange buttons — monochrome only (exception: emergency red)
- [ ] `Navigator.pop(context)` preceded by `ScaffoldMessenger.of(context)` capture

### Integration test
- [ ] From My Circle: tap "I'm pregnant" → verify pregnancy created → navigate to My Pregnancy tab → see home page
- [ ] Full flow: week detail → symptom log → save → verify persistence
- [ ] Full flow: kick counter → record 12 kicks → verify goal snackbar fires once at 10
- [ ] Full flow: contraction timer → record 6 contractions → verify pattern detection
- [ ] Full flow: "Baby is Born" → fill form → verify pregnancy marked delivered + baby created in My Baby → navigates to My Baby

### Performance check
- [ ] Home page loads in < 2s with SQLite cache
- [ ] Week content pre-cached — no spinner when navigating weeks
- [ ] Kick counter works offline — saves when back online

---

## File Summary

### New files to create (7)
| File | Purpose |
|------|---------|
| `lib/my_pregnancy/pages/contraction_timer_page.dart` | Contraction timer with pattern detection |
| `lib/my_pregnancy/pages/weight_tracker_page.dart` | Weight logging + chart |
| `lib/my_pregnancy/pages/nutrition_guide_page.dart` | Safe/unsafe foods, nutrients, meal plans |
| `lib/my_pregnancy/pages/birth_plan_page.dart` | Hospital bag checklist, delivery prefs, contacts |
| `lib/my_pregnancy/pages/mood_tracker_page.dart` | Mood logging, affirmations, stress check |
| `lib/my_pregnancy/services/pregnancy_database.dart` | SQLite offline cache |
| `lib/my_pregnancy/pages/pregnancy_journal_page.dart` | Daily journal entries (optional — could be bottom sheet instead) |

### Existing files to modify (10)
| File | Changes |
|------|---------|
| `lib/my_pregnancy/models/my_pregnancy_models.dart` | Add Contraction, WeightEntry, MoodEntry, BirthPlan, EmergencyContact, JournalEntry, SymptomLog models. Make existing models bilingual |
| `lib/my_pregnancy/services/my_pregnancy_service.dart` | Add auth token to all methods. Add new endpoints for contractions, weight, mood, birth plan, symptoms, journal |
| `lib/my_pregnancy/pages/pregnancy_home_page.dart` | Bilingual text, fix ANC tap, fix monochrome, add new quick actions, add affirmation section |
| `lib/my_pregnancy/pages/pregnancy_week_page.dart` | Bilingual text, wire symptom save to API |
| `lib/my_pregnancy/pages/anc_schedule_page.dart` | Bilingual text, add facility/notes dialog to mark-done |
| `lib/my_pregnancy/pages/kick_counter_page.dart` | Bilingual text, fix goal snackbar (== 10), add haptic, add decrease alert |
| `lib/my_pregnancy/pages/danger_signs_page.dart` | Bilingual text, fix emergency numbers, fix silent fail |
| `lib/my_pregnancy/widgets/week_progress_card.dart` | Bilingual text |
| `lib/my_pregnancy/widgets/kick_counter_widget.dart` | Bilingual text, add haptic feedback |
| `lib/my_pregnancy/my_pregnancy_module.dart` | Pass token if needed |

### Dependency on other files
| File | Change |
|------|--------|
| `lib/l10n/app_strings.dart` | Add pregnancy-related string getters if using centralized approach |
| `lib/services/fcm_service.dart` | Handle `anc_reminder` notification type |

---

## Execution Order

Tasks can be parallelized where noted:

1. **Task 1** (Backend) — do first, others depend on endpoints
2. **Task 2** (Fix existing) — can start immediately for non-API changes (bilingual, bug fixes)
3. **Tasks 3-7** (New pages) — can run in parallel after Task 1 backend is ready. Each page is independent
4. **Task 8** (Notifications) — after Task 1 backend
5. **Task 9** (SQLite) — after Tasks 2-7, since it wraps the service layer
6. **Task 10** (Wire navigation) — after Tasks 3-7, since it links to new pages
7. **Task 11** (Final verification) — last
