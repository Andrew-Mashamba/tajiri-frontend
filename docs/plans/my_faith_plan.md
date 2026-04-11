# My Faith (Imani Yangu) — Implementation Plan

## Overview
Central faith profile module that determines the user's religious identity (Christian or Muslim), denomination, home church/mosque, and configures which faith sub-modules are visible. Acts as the gateway for all 19 faith sub-tabs.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/my_faith/
├── my_faith_module.dart
├── models/
│   ├── faith_profile.dart
│   ├── denomination.dart
│   ├── spiritual_milestone.dart
│   └── spiritual_goal.dart
├── services/
│   └── faith_service.dart          — AuthenticatedDio.instance
├── pages/
│   ├── faith_selection_page.dart
│   ├── denomination_picker_page.dart
│   ├── faith_setup_wizard_page.dart
│   ├── faith_dashboard_page.dart
│   ├── faith_profile_view_page.dart
│   ├── spiritual_goals_page.dart
│   └── faith_settings_page.dart
└── widgets/
    ├── faith_selector_card.dart
    ├── denomination_tile.dart
    ├── faith_tab_grid.dart
    ├── milestone_card.dart
    └── goal_progress_card.dart
```

### Data Models
- **FaithProfile** — `id`, `userId`, `faith` (christian/muslim), `denominationId`, `faithBio`, `privacyLevel`, `isLeader`, `leaderTitle`, `homeChurchId`, `homeMosqueId`. Uses `_parseInt`, `_parseBool` helpers in `fromJson`.
- **Denomination** — `id`, `name`, `faith`, `iconUrl`.
- **SpiritualMilestone** — `id`, `type` (baptism/confirmation/shahada/hajj), `date`, `notes`.
- **SpiritualGoal** — `id`, `title`, `targetValue`, `currentValue`, `unit`, `startDate`, `endDate`.

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
- `getFaithProfile(int userId)` — `GET /api/faith/profile/{userId}`
- `updateFaithProfile(Map data)` — `PUT /api/faith/profile`
- `getDenominations(String faith)` — `GET /api/faith/denominations?faith={faith}`
- `setMilestone(Map data)` — `POST /api/faith/milestones`
- `getGoals()` — `GET /api/faith/goals`
- `createGoal(Map data)` — `POST /api/faith/goals`
- `updateGoalProgress(int id, double value)` — `PUT /api/faith/goals/{id}`

### Pages
- **FaithSelectionPage** — Two large cards (Christian / Muslim) with respectful iconography
- **DenominationPickerPage** — Searchable grouped list by faith category
- **FaithSetupWizardPage** — Multi-step: faith > denomination > church/mosque > bio > preferences
- **FaithDashboardPage** — Card grid of relevant faith modules based on selection
- **SpiritualGoalsPage** — Goal cards with circular progress indicators

### Widgets
- `FaithSelectorCard` — Large tappable card with icon and label
- `FaithTabGrid` — GridView of module cards filtered by faith selection
- `GoalProgressCard` — Card with title, progress bar, and streak info

---

## 2. UI Design
- #1A1A1A/#666666/#FAFAFA/#FFFFFF monochromatic
- 48dp touch, maxLines+ellipsis, _rounded icons
- Dark stat cards for hero metrics (prayer streak, goals completed)
- Cards: radius 12-16, subtle shadow

### Main Screen Wireframe
```
┌─────────────────────────────┐
│ ← Imani Yangu          ⚙️   │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │  [Avatar]  John Doe     │ │
│ │  Lutheran (ELCT)        │ │
│ │  Kanisa la Moshi        │ │
│ └─────────────────────────┘ │
│                             │
│  Faith Modules              │
│ ┌──────┐ ┌──────┐ ┌──────┐ │
│ │Biblia│ │ Sala │ │Fungu │ │
│ └──────┘ └──────┘ └──────┘ │
│ ┌──────┐ ┌──────┐ ┌──────┐ │
│ │Kanisa│ │Huduma│ │Jumui.│ │
│ └──────┘ └──────┘ └──────┘ │
│                             │
│  Spiritual Goals  [+ Add]   │
│ ┌─────────────────────────┐ │
│ │ Read Bible   ████░ 72%  │ │
│ │ Daily Prayer ██████ 90% │ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE faith_profiles(id INTEGER PRIMARY KEY, user_id INTEGER, faith TEXT, denomination_id INTEGER, json_data TEXT, synced_at TEXT);
CREATE TABLE spiritual_goals(id INTEGER PRIMARY KEY, user_id INTEGER, title TEXT, progress REAL, json_data TEXT, synced_at TEXT);
```
- Stale-while-revalidate: SQLite first, API background refresh
- TTL: 24 hours for profile, 1 hour for goals
- Offline: read YES, write via pending_queue

---

## 4. Backend Implementation

### Database
```sql
CREATE TABLE faith_profiles(id BIGSERIAL PRIMARY KEY, user_id BIGINT REFERENCES users(id), faith VARCHAR(20), denomination_id BIGINT, faith_bio TEXT, privacy_level VARCHAR(20) DEFAULT 'friends', is_leader BOOLEAN DEFAULT FALSE, leader_title VARCHAR(100), home_church_id BIGINT, home_mosque_id BIGINT, created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW());

CREATE TABLE denominations(id BIGSERIAL PRIMARY KEY, name VARCHAR(100), faith VARCHAR(20), icon_url VARCHAR(255));

CREATE TABLE spiritual_milestones(id BIGSERIAL PRIMARY KEY, user_id BIGINT, type VARCHAR(50), milestone_date DATE, notes TEXT, created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE spiritual_goals(id BIGSERIAL PRIMARY KEY, user_id BIGINT, title VARCHAR(200), target_value DOUBLE PRECISION, current_value DOUBLE PRECISION DEFAULT 0, unit VARCHAR(50), start_date DATE, end_date DATE, created_at TIMESTAMP DEFAULT NOW());
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/faith/profile/{userId} | Get faith profile | Bearer |
| PUT | /api/faith/profile | Update faith profile | Bearer |
| GET | /api/faith/denominations | List denominations | Bearer |
| POST | /api/faith/milestones | Record milestone | Bearer |
| GET | /api/faith/goals | List user goals | Bearer |
| POST | /api/faith/goals | Create goal | Bearer |
| PUT | /api/faith/goals/{id} | Update goal progress | Bearer |

### Controller
`app/Http/Controllers/Api/FaithController.php` — DB facade pattern with `faith_profiles`, `denominations`, `spiritual_milestones`, `spiritual_goals` tables.

---

## 5. Integration Wiring
- **ProfileService** — faith field drives tab visibility (Christian: 9 tabs, Muslim: 10 tabs)
- **GroupService** — auto-suggest faith groups based on denomination
- **WalletService** — enables Fungu la Kumi / Zaka payment flows
- **NotificationService** — prayer reminders, devotional alerts based on faith selection
- **MusicService** — worship/gospel or nasheed/qaswida filtered by faith

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema
- Faith selection and denomination picker pages
- Backend tables and CRUD endpoints

### Phase 2: Core UI (Week 2)
- Faith setup wizard (multi-step flow)
- Faith dashboard with module grid
- Spiritual goals CRUD

### Phase 3: Integration (Week 3)
- Tab visibility based on faith selection
- Profile integration (faith bio section)
- Group and notification wiring

### Phase 4: Polish (Week 4)
- Privacy controls, leader designation
- Milestone tracking, goal streaks
- Offline support, caching, analytics

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Joshua Project API | Joshua Project | People group, country, language, and religion data worldwide | Free (API key required) | REST API with JSON; covers religions by country; request key at joshuaproject.net |
| ARDA Data Archives | Penn State | 200+ surveys on religion, denomination data, congregational stats | Free (data downloads) | Bulk CSV/SPSS downloads; no REST API; good for reference data |
| Pew Religious Landscape Study | Pew Research Center | Religious affiliation, beliefs, practices, demographics | Free (data downloads) | Downloadable datasets; 2007, 2014, 2023-24 waves |

### Integration Priority
1. **Immediate** — Free APIs (Joshua Project API for demographic data)
2. **Short-term** — Data downloads (ARDA, Pew) for reference content
3. **Partnership** — World Religion Database (paid academic subscription)
