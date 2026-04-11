# Tajirika Module — Full Rebuild Implementation Spec

**Date:** 2026-04-08
**Scope:** Scrap and rebuild `lib/tajirika/` as TAJIRI's partner program hub
**Design Doc:** `docs/modules/tajirika.md`

## Business Logic

Tajirika is TAJIRI's partner program — the supply-side system where skilled professionals register, get verified, and become available across consumer-facing domain modules (Mafundi, Skin Care, Hair & Nails, Lawyer, Housing, Doctor, Service Garage, Fitness, Food, Events, Travel, Nightlife, Career, Business). Tajirika does NOT handle job matching, booking, payments, or reviews — those belong to each domain module.

## File Structure

```
lib/tajirika/
├── tajirika_module.dart              # Entry point widget
├── models/
│   └── tajirika_models.dart          # All models
├── services/
│   └── tajirika_service.dart         # All API methods (static-method class)
├── pages/
│   ├── tajirika_home_page.dart       # 1. Partner Dashboard
│   ├── registration_page.dart        # 2. Multi-step registration flow
│   ├── verification_status_page.dart # 3. Verification progress
│   ├── partner_profile_page.dart     # 4. Public partner profile
│   ├── portfolio_manager_page.dart   # 5. Portfolio upload/organize
│   ├── training_hub_page.dart        # 6. Courses & mentorship
│   ├── earnings_overview_page.dart   # 7. Aggregated earnings
│   ├── referral_center_page.dart     # 8. Referrals & bonuses
│   ├── skill_certification_page.dart # 9. Skills, tiers, badges
│   └── partner_settings_page.dart    # 10. Service area, availability, prefs
└── widgets/
    ├── tier_badge.dart               # Mwanafunzi/Mtaalamu/Bingwa badge
    ├── verification_step_card.dart   # Verification item with status indicator
    ├── skill_category_chip.dart      # Skill tag with icon
    ├── partner_stat_card.dart        # Metric card (jobs, rating, earnings)
    ├── training_course_card.dart     # Course card with progress
    ├── referral_card.dart            # Referral entry with status
    ├── portfolio_item_card.dart      # Photo/video portfolio entry
    ├── tier_progress_bar.dart        # Progress toward next tier
    ├── earnings_module_breakdown.dart # Earnings per domain module
    └── badge_chip.dart               # Specialization badge display
```

## Models (`tajirika_models.dart`)

Single file. All models use `factory Model.fromJson(Map<String, dynamic> json)` with null-safe parsing helpers (`_parseInt`, `_parseDouble`, `_parseBool`, `_parseDateTime`). Enums have bilingual labels.

### TajirikaPartner
```dart
class TajirikaPartner {
  final int id;
  final int userId;
  final String name;
  final String? photo;
  final String? phone;
  final List<SkillCategory> skills;
  final List<SkillSpecialization> specializations;
  final PartnerTier tier;
  final VerificationStatus verifications;
  final PartnerServiceArea serviceArea;
  final List<PortfolioItem> portfolio;
  final double aggregateRating;
  final int jobsCompleted;
  final int responseTimeMinutes;
  final String? referralCode;
  final String? payoutAccount;
  final String? payoutMethod; // mpesa, tigopesa, airtelmoney, bank
  final bool isActive;
  final DateTime? createdAt;
}
```

### PartnerTier (enum)
```dart
enum PartnerTier {
  mwanafunzi,  // Apprentice — registered, ID verified
  mtaalamu,    // Verified Professional — skills verified, 10+ jobs
  bingwa;      // Expert/Master — 50+ jobs, 4.5+ rating, training done

  String get label => ...;       // English
  String get labelSwahili => ...; // Swahili
  IconData get icon => ...;
  Color get color => ...;
}
```

### SkillCategory (enum)
```dart
enum SkillCategory {
  // Mafundi trades
  plumbing, electrical, carpentry, painting, welding, masonry, roofing, tiling, solarInstallation,
  // Auto
  autoMechanic, autoElectrician, panelBeating, sprayPainting,
  // Beauty & Wellness
  hairstyling, barbering, nailTechnician, skincare, makeup,
  // Professional
  legal, medical, nursing, pharmacy, accounting, taxAdvisory,
  // Property
  realEstate, propertyManagement, homeInspection, interiorDesign,
  // Fitness & Food
  personalTraining, nutrition, cooking, catering, baking,
  // Events & Creative
  eventPlanning, photography, videography, djing, mc,
  // Travel & Transport
  tourGuide, travelAgent, safariOperator,
  // Business
  businessConsulting, hrConsulting, careerCoaching;

  String get label => ...;
  String get labelSwahili => ...;
  IconData get icon => ...;
  String get domainModule => ...; // Maps to consumer module: "mafundi", "lawyer", etc.
}
```

### SkillSpecialization
```dart
class SkillSpecialization {
  final int id;
  final String categoryKey;
  final String name;
  final String nameSwahili;
}
```

### VerificationStatus
```dart
class VerificationStatus {
  final VerificationItem nida;
  final VerificationItem tin;
  final VerificationItem professional;
  final VerificationItem background;
  String get overall => ...; // pending/partial/verified/expired
}
```

### VerificationItem
```dart
class VerificationItem {
  final String type;        // nida, tin, professional, background
  final String status;      // pending, submitted, verified, failed, expired
  final String? number;     // NIDA number, TIN number, etc.
  final String? documentUrl;
  final DateTime? submittedAt;
  final DateTime? verifiedAt;
  final DateTime? expiresAt;
  final String? rejectionReason;
}
```

### PartnerServiceArea
```dart
class PartnerServiceArea {
  final List<int> regionIds;
  final List<int> districtIds;
  final List<int> wardIds;
  final List<String> regionNames;
  final List<String> districtNames;
  final List<String> wardNames;
}
```

### TrainingCourse
```dart
class TrainingCourse {
  final int id;
  final String title;
  final String titleSwahili;
  final String description;
  final String descriptionSwahili;
  final SkillCategory? category;
  final int durationMinutes;
  final String? videoUrl;
  final String? thumbnailUrl;
  final bool isRequired;
  final double progress;      // 0.0 - 1.0
  final bool isCompleted;
  final DateTime? completedAt;
  final String? certificateUrl;
}
```

### Referral
```dart
class Referral {
  final int id;
  final int referrerId;
  final int referredId;
  final String referredName;
  final String? referredPhoto;
  final List<SkillCategory> referredSkills;
  final String status;  // pending, registered, verified
  final double bonus;
  final DateTime createdAt;
}
```

### PortfolioItem
```dart
class PortfolioItem {
  final int id;
  final String type;     // photo, video
  final String url;
  final String? thumbnailUrl;
  final String? caption;
  final SkillCategory? skillCategory;
  final DateTime createdAt;
}
```

### TierProgress
```dart
class TierProgress {
  final PartnerTier currentTier;
  final PartnerTier? nextTier;
  final int jobsCompleted;
  final int jobsNeeded;
  final double currentRating;
  final double ratingNeeded;
  final int trainingCompleted;
  final int trainingNeeded;
  final List<String> verificationsPending;
  double get progress => ...; // 0.0 - 1.0 overall progress
}
```

### PartnerEarnings
```dart
class PartnerEarnings {
  final double totalEarnings;
  final double weeklyEarnings;
  final double monthlyEarnings;
  final double pendingPayout;
  final Map<String, double> byModule; // {"mafundi": 150000, "lawyer": 80000}
  final List<Payout> recentPayouts;
}
```

### Payout
```dart
class Payout {
  final int id;
  final double amount;
  final String status;    // pending, processing, completed, failed
  final String method;    // mpesa, tigopesa, airtelmoney, bank
  final DateTime? paidAt;
  final DateTime createdAt;
}
```

### PartnerStats
```dart
class PartnerStats {
  final int jobsCompleted;
  final double averageRating;
  final int responseTimeMinutes;
  final double repeatCustomerRate;
  final List<String> activeModules;
}
```

### MentorshipMatch
```dart
class MentorshipMatch {
  final int id;
  final int mentorId;
  final String mentorName;
  final String? mentorPhoto;
  final PartnerTier mentorTier;
  final int menteeId;
  final String menteeName;
  final String? menteePhoto;
  final String status; // active, completed, cancelled
  final DateTime createdAt;
}
```

### AvailabilitySchedule
```dart
class AvailabilitySchedule {
  final List<AvailabilitySlot> slots;
}

class AvailabilitySlot {
  final int dayOfWeek;    // 1=Monday, 7=Sunday
  final String startTime; // "08:00"
  final String endTime;   // "17:00"
  final bool isAvailable;
}
```

### ReferralStats
```dart
class ReferralStats {
  final String referralCode;
  final int totalReferred;
  final int registered;
  final int verified;
  final double totalBonusEarned;
}
```

### Badge
```dart
class Badge {
  final int id;
  final String name;
  final String nameSwahili;
  final String? iconUrl;
  final String description;
  final DateTime earnedAt;
}
```

## Service Layer (`tajirika_service.dart`)

Static-method class. All methods take `String token` as first parameter. Uses `ApiConfig.authHeaders(token)` for auth. Returns typed results using pattern: `Future<Map<String, dynamic>>` parsed into models at call site, or `Future<TajirikaPartner?>`, etc.

### Registration & Profile
| Method | HTTP | Endpoint |
|--------|------|----------|
| `registerPartner(token, Map data)` | POST | `/tajirika/partners` |
| `getPartnerProfile(token, int partnerId)` | GET | `/tajirika/partners/{id}` |
| `getMyPartnerProfile(token)` | GET | `/tajirika/partners/me` |
| `updatePartnerProfile(token, Map data)` | PUT | `/tajirika/partners/me` |
| `updateServiceArea(token, List regionIds, List districtIds, List wardIds)` | PUT | `/tajirika/partners/me/service-area` |
| `updateAvailability(token, List<AvailabilitySlot> schedule)` | PUT | `/tajirika/partners/me/availability` |
| `updatePayoutAccount(token, Map data)` | PUT | `/tajirika/partners/me/payout-account` |

### Verification
| Method | HTTP | Endpoint |
|--------|------|----------|
| `submitNidaVerification(token, String nidaNumber)` | POST | `/tajirika/verifications/nida` |
| `submitTinVerification(token, String tinNumber)` | POST | `/tajirika/verifications/tin` |
| `submitProfessionalLicense(token, String licenseType, File file)` | POST | `/tajirika/verifications/professional` (multipart) |
| `submitBackgroundCheck(token)` | POST | `/tajirika/verifications/background` |
| `getVerificationStatus(token)` | GET | `/tajirika/verifications` |
| `submitPeerVouch(token, int partnerId)` | POST | `/tajirika/partners/{id}/vouch` |

### Skills & Certification
| Method | HTTP | Endpoint |
|--------|------|----------|
| `getSkillCategories(token)` | GET | `/tajirika/skills/categories` |
| `updateSkills(token, List skills)` | PUT | `/tajirika/partners/me/skills` |
| `submitSkillTest(token, String categoryKey, File file)` | POST | `/tajirika/skills/test` (multipart) |
| `getTierProgress(token)` | GET | `/tajirika/partners/me/tier-progress` |
| `getBadges(token)` | GET | `/tajirika/partners/me/badges` |

### Portfolio
| Method | HTTP | Endpoint |
|--------|------|----------|
| `getPortfolio(token, int partnerId)` | GET | `/tajirika/partners/{id}/portfolio` |
| `uploadPortfolioItem(token, File file, String? caption, String? skillCategory)` | POST | `/tajirika/portfolio` (multipart) |
| `deletePortfolioItem(token, int itemId)` | DELETE | `/tajirika/portfolio/{id}` |

### Training
| Method | HTTP | Endpoint |
|--------|------|----------|
| `getTrainingCourses(token, {String? category, int page = 1})` | GET | `/tajirika/training` |
| `getCourseDetail(token, int courseId)` | GET | `/tajirika/training/{id}` |
| `updateCourseProgress(token, int courseId, double progress)` | PUT | `/tajirika/training/{id}/progress` |
| `getMentorshipMatches(token)` | GET | `/tajirika/mentorship` |

### Referrals
| Method | HTTP | Endpoint |
|--------|------|----------|
| `getReferrals(token, {int page = 1})` | GET | `/tajirika/referrals` |
| `getReferralStats(token)` | GET | `/tajirika/referrals/stats` |

### Earnings & Analytics
| Method | HTTP | Endpoint |
|--------|------|----------|
| `getEarnings(token, {String period = 'monthly'})` | GET | `/tajirika/earnings` |
| `getEarningsByModule(token)` | GET | `/tajirika/earnings/by-module` |
| `requestPayout(token, double amount, String method)` | POST | `/tajirika/payouts` |
| `getPayoutHistory(token, {int page = 1})` | GET | `/tajirika/payouts` |
| `getPartnerStats(token)` | GET | `/tajirika/partners/me/stats` |
| `getLeaderboard(token, {String? category, int page = 1})` | GET | `/tajirika/leaderboard` |

### Partner Discovery (for domain modules)
| Method | HTTP | Endpoint |
|--------|------|----------|
| `searchPartners(token, {List? skills, int? regionId, String? tier, double? minRating, bool? available, int page = 1})` | GET | `/tajirika/partners` |
| `reportJobCompleted(token, int partnerId, String module, String jobId, double rating, double earnings)` | POST | `/tajirika/partners/{id}/job-completed` |

## Screen Specifications

All screens follow TAJIRI conventions:
- `setState()` for state management (no Provider/Bloc/Riverpod)
- `AppStringsScope.of(context)` for bilingual strings (Swahili/English)
- Monochrome Material 3 design (#1A1A1A dark, #FAFAFA light)
- `SafeArea` wrapping mandatory
- 48dp minimum touch targets
- `maxLines` + `TextOverflow.ellipsis` on all dynamic text
- `_rounded` icon variants
- Dispose all controllers
- try/catch + `if (!mounted) return` on all async operations

### 1. Partner Dashboard (`tajirika_home_page.dart`)
- **Top:** Partner card — profile photo, name, TierBadge, rating stars, "Active" status chip
- **Stats row:** 4x PartnerStatCard — Jobs Completed, Avg Rating, Response Time, Active Modules
- **Earnings summary:** Total earnings with weekly/monthly toggle. EarningsModuleBreakdown showing per-module amounts
- **Tier progress:** TierProgressBar showing progress to next tier
- **Recent activity:** ListView of recent events (job completed, payment received, verification approved)
- **Quick actions:** Row of icon buttons — Edit Profile, Portfolio, Verifications, Training
- **Navigation:** Tapping items navigates to respective detail pages
- **Data:** Calls `getMyPartnerProfile`, `getEarnings`, `getTierProgress`, `getPartnerStats` on init

### 2. Registration Flow (`registration_page.dart`)
- **Layout:** PageView with step indicator at top (Step 1 of 8)
- **Step 1 — Personal Info:** Name, phone (pre-filled from TAJIRI profile), bio text field
- **Step 2 — Skill Selection:** Grid of SkillCategoryChips (multi-select). At least 1 required. Shows domain module mapping ("This skill appears in: Mafundi")
- **Step 3 — ID Verification:** NIDA number text field with format validation. TIN number text field (optional but recommended)
- **Step 4 — Professional License:** Camera/gallery upload for license/certificate. License type dropdown (VETA, TLS, Medical Council, BRELA, Other). Skip option for trades without formal licensing
- **Step 5 — Portfolio:** Upload up to 10 photos/videos of past work. Each with caption and skill category tag. Skip option for new professionals
- **Step 6 — Service Area:** LocationPicker widget (existing) for region → district → ward. Support multiple areas
- **Step 7 — Payout Account:** Method selector (M-Pesa, Tigo Pesa, Airtel Money, Bank). Account number/phone input
- **Step 8 — Terms & Submit:** Partnership terms text. Checkbox acceptance. Submit button
- **Back/Next:** Bottom navigation buttons. Validate current step before proceeding
- **Data:** Collects all data locally, calls `registerPartner` on final submit

### 3. Verification Status (`verification_status_page.dart`)
- **Top banner:** Overall status — "Inasubiriwa" (Pending) / "Imethibitishwa Sehemu" (Partially Verified) / "Imethibitishwa" (Fully Verified)
- **Verification list:** 4x VerificationStepCard for NIDA, TIN, Professional License, Background Check
  - Each shows: type label, status icon (pending=clock, submitted=hourglass, verified=checkmark, failed=X, expired=warning), date info
  - Action button: "Submit" if not yet submitted, "Resubmit" if failed, "Renew" if expired
- **Peer vouching section:** "Ask a verified partner to vouch for you" with share link
- **Re-verification alerts:** Banner for any verification expiring within 30 days

### 4. Partner Profile (`partner_profile_page.dart`)
- **Header:** Cover area with profile photo, name, TierBadge, verification checkmark
- **Rating:** Star rating display with job count ("4.8 ★ · 47 kazi")
- **Skills section:** Horizontal scroll of SkillCategoryChips
- **About section:** Bio text, service area tags, availability status
- **Portfolio section:** 3-column grid of portfolio thumbnails. "View All" → PortfolioManagerPage
- **Credentials section:** List of verified credentials with BadgeChips
- **Stats section:** Jobs completed, response time, repeat customer rate
- **Edit button:** FloatingActionButton (only on own profile) → navigates to edit flow
- **Data:** Calls `getPartnerProfile(partnerId)` or `getMyPartnerProfile`

### 5. Portfolio Manager (`portfolio_manager_page.dart`)
- **Grid view:** 2-column grid of PortfolioItemCards with thumbnail, caption overlay, skill tag
- **Add FAB:** Opens bottom sheet — Camera / Gallery / Video picker
- **Upload flow:** Pick media → caption text field → skill category dropdown → upload with progress indicator
- **Item actions:** Tap → full-screen viewer. Long press → delete confirmation dialog
- **Empty state:** Illustration + "Add your first work sample" CTA
- **Data:** Calls `getPortfolio`, `uploadPortfolioItem`, `deletePortfolioItem`

### 6. Training Hub (`training_hub_page.dart`)
- **Tabs:** Available / In Progress / Completed (TabBar + TabBarView)
- **Course list:** TrainingCourseCards with thumbnail, title (bilingual), duration, progress bar (for in-progress), certificate icon (for completed)
- **Required badge:** Visual indicator for required onboarding courses
- **Course detail:** Tap → detail view with video player placeholder, description, progress tracking, mark complete button
- **Mentorship section:** Below tabs — MentorshipMatch card showing mentor/mentee info, status
- **Filters:** Category filter chips at top of each tab
- **Data:** Calls `getTrainingCourses(category, page)`, `getCourseDetail`, `updateCourseProgress`, `getMentorshipMatches`

### 7. Earnings Overview (`earnings_overview_page.dart`)
- **Period toggle:** SegmentedButton — Weekly / Monthly
- **Total earnings card:** Large number with currency (TZS), trend indicator
- **Module breakdown:** EarningsModuleBreakdown — list of modules with amounts and percentage bars
- **Pending payout:** Card showing pending amount with "Withdraw" button
- **Payout history:** ListView of Payout items with amount, method icon, status, date
- **Withdraw flow:** Tap Withdraw → amount input (max = pending) → method selector → confirm dialog → `requestPayout`
- **Data:** Calls `getEarnings(period)`, `getEarningsByModule`, `getPayoutHistory`

### 8. Referral Center (`referral_center_page.dart`)
- **Referral code card:** Large display of code with Copy and Share buttons (Share via platform share sheet)
- **Stats row:** 3x PartnerStatCard — Total Referred, Verified, Total Earned
- **Referral list:** ListView of ReferralCards — referred person's photo, name, skills, status badge (pending/registered/verified), bonus amount
- **Empty state:** "Invite skilled professionals to earn bonuses" with share CTA
- **Data:** Calls `getReferralStats`, `getReferrals(page)`

### 9. Skill & Certification (`skill_certification_page.dart`)
- **Current tier card:** TierBadge (large), tier name, description of benefits
- **Tier progress:** TierProgressBar with checklist — jobs needed, rating needed, training needed, verifications pending. Each item shows current/target
- **Skills list:** Current skills as SkillCategoryChips with edit button → multi-select editor
- **Badges section:** Grid of earned BadgeChips with name and icon
- **Skill test section:** "Take a skill test" card — select category, record/upload video, submit for review
- **Data:** Calls `getTierProgress`, `getBadges`, `getSkillCategories`

### 10. Partner Settings (`partner_settings_page.dart`)
- **Service area:** Current areas displayed as tags. Edit button → LocationPicker flow for adding/removing areas
- **Availability schedule:** Day-by-day rows (Mon-Sun) with time range pickers and toggle switches
- **Payout account:** Current method and account with edit button → method selector + account input
- **Notifications:** Toggle switches for: verification updates, tier changes, referral alerts, training reminders, earnings notifications
- **Account actions:** "Deactivate Partner Account" button with confirmation dialog
- **Data:** Calls `getMyPartnerProfile` for current settings, `updateServiceArea`, `updateAvailability`, `updatePayoutAccount`

## Widget Specifications

### TierBadge
- Input: `PartnerTier tier`, `double? fontSize`
- Display: Icon + label with tier color background
- Colors: mwanafunzi=#9E9E9E (grey), mtaalamu=#616161 (dark grey), bingwa=#212121 (near black)

### VerificationStepCard
- Input: `VerificationItem item`, `VoidCallback? onAction`
- Display: Row — status icon, type label, status text, date, action button
- Status colors: pending=#9E9E9E, submitted=#757575, verified=#4CAF50, failed=#F44336, expired=#FF9800

### SkillCategoryChip
- Input: `SkillCategory category`, `bool selected`, `VoidCallback? onTap`
- Display: Chip with category icon + bilingual label, selected state styling

### PartnerStatCard
- Input: `String label`, `String value`, `IconData icon`
- Display: Card with icon, large value text, small label text

### TrainingCourseCard
- Input: `TrainingCourse course`, `VoidCallback? onTap`
- Display: Row — thumbnail, title (bilingual), duration, progress bar or certificate icon

### ReferralCard
- Input: `Referral referral`
- Display: Row — avatar, name, skills chips, status badge, bonus amount

### PortfolioItemCard
- Input: `PortfolioItem item`, `VoidCallback? onTap`, `VoidCallback? onDelete`
- Display: Thumbnail with caption overlay at bottom, skill category tag, video play icon if video

### TierProgressBar
- Input: `TierProgress progress`
- Display: Current tier → progress bar → next tier. Below: checklist of requirements with check/X icons

### EarningsModuleBreakdown
- Input: `Map<String, double> byModule`
- Display: List of module rows — module name, amount, percentage bar (proportional to total)

### BadgeChip
- Input: `Badge badge`
- Display: Small chip with badge icon + name

## Module Entry Point (`tajirika_module.dart`)

```dart
class TajirikaModule extends StatelessWidget {
  const TajirikaModule({super.key});

  @override
  Widget build(BuildContext context) {
    return const TajirikaHomePage();
  }
}
```

The module is accessed from the profile screen's configurable tabs (existing `ProfileTabConfig` system) and potentially from a home screen shortcut. The `TajirikaHomePage` checks if the user is a registered partner — if not, shows a registration CTA that navigates to `RegistrationPage`.

## Navigation Within Module

All navigation within the module uses `Navigator.push` with MaterialPageRoute (no named routes needed for internal pages). The module entry point is wired via the existing profile tab system or direct import.

```
TajirikaHomePage (dashboard)
├── → RegistrationPage (if not registered)
├── → PartnerProfilePage (own or others)
│   └── → PortfolioManagerPage
├── → VerificationStatusPage
├── → TrainingHubPage
├── → EarningsOverviewPage
├── → ReferralCenterPage
├── → SkillCertificationPage
└── → PartnerSettingsPage
```

## Integration With Existing Platform

- **Auth token:** Retrieved from `LocalStorageService` (Hive) — same pattern as all other services
- **Profile tabs:** Module registered via `ProfileTabConfig` in `lib/models/profile_tab_config.dart`
- **Location picker:** Reuse existing `LocationPicker` widget from `lib/widgets/location_picker.dart`
- **Photo upload:** Use existing `PhotoService.uploadPhoto()` for portfolio images
- **Video upload:** Use existing `VideoUploadService` with Dio chunked upload
- **Bilingual strings:** Use `AppStringsScope.of(context)` ternary pattern — add Tajirika strings to `lib/l10n/app_strings.dart`
- **Theme:** Use `Theme.of(context)` — monochrome palette already defined
- **Notifications:** FCM payloads with tajirika-specific routing handled in `fcm_service.dart`

## Bilingual String Coverage

All user-facing text must have Swahili/English variants. Key strings include:
- Screen titles (Partner Dashboard = "Dashibodi ya Mshirika")
- Tier names (Mwanafunzi, Mtaalamu, Bingwa — already Swahili)
- Skill categories (Umeme = Electrical, Bomba = Plumbing, etc.)
- Status labels (Inasubiriwa = Pending, Imethibitishwa = Verified, etc.)
- Action buttons (Jisajili = Register, Wasilisha = Submit, etc.)
- Empty states and error messages
