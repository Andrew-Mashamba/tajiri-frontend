§# Deep Crawl & Fix: [ENTRY_SCREEN] — 10 Levels Deep

You are auditing and fixing the TAJIRI Flutter app at `/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND`. Starting from `[ENTRY_FILE_PATH]`, crawl every interactive element and navigation link, follow each to its destination, then repeat on the destination — at least 10 levels deep. At each level, identify and fix all issues.

## What to Look For (at every level)

1. **Empty handlers** — `onTap: () {}`, `onPressed: () {}`, callbacks that do nothing
2. **Stubs & placeholders** — Methods showing "coming soon" snackbars, bodies with only `// TODO` comments, placeholder text instead of real content
3. **Broken navigation routes** — Routes not registered in `lib/main.dart` `onGenerateRoute`, wrong path patterns (e.g. `/profile` instead of `/profile/{id}`), arguments passed via `arguments:` instead of path segments when the route expects path segments
4. **Missing callbacks on child widgets** — Widg ets like `PostCard`, `PostGridCell`, `CommentTile` rendered without required callbacks (`onLike`, `onComment`, `onShare`, `onSave`, `onUserTap`, `onHashtagTap`, `onMentionTap`, `onSubscribe`, `onMenuTap`, `onThreadTap`, `onReaction`) — any nullable callback left as `null` that should be wired up
5. **Compile errors** — `widget.x` used inside `StatelessWidget` (should use class field directly), wrong variable names, missing imports, type mismatches, ambiguous imports
6. **Logic bugs** — Guards preventing initialization (e.g. `bool _loading = true` + `if (_loading) return;` in the load method called from `initState`), wrong variable assignment order, state not updating after API calls
7. **Misleading UX** — Showing success feedback ("Done!", "Sent!", "Blocked!") without making any API call, confirmation dialogs that confirm but take no action
8. **Dead pages** — Screens showing empty/loading state forever because load method never fires, or calls a service method that doesn't exist
9. **Unimplemented features** — Visible UI buttons/icons/tabs that are rendered but do nothing when interacted with
10. **Missing error handling** — API calls with no try/catch, no loading states, no error feedback to user
11. **Double titles / Double AppBars** — Pages rendered inside `_ProfileTabPage` (via profile tab grid) already have a parent `AppBar` with the tab title and back button. If the page ALSO has its own `Scaffold` with `appBar:`, the user sees TWO titles and TWO back buttons stacked. **FIX:** When a page is used as tab content inside `_ProfileTabPage`, it must NOT have its own `AppBar`. Remove `appBar:` from the `Scaffold`, or replace `Scaffold` with just the body widget. This applies to ALL module home pages rendered from profile tabs: business pages, doctor, pharmacy, insurance, fitness, my_circle, my_baby, my_family, skincare, hair_nails, investments, loans, wallet, tenders, and any page opened via `_openTabPage()` in `profile_screen.dart`.
12. **Swahili-only text** — Any hardcoded Swahili string without an English alternative. English is the DEFAULT language. All user-facing text must be bilingual: `isSwahili ? 'Swahili text' : 'English text'` or use `AppStringsScope.of(context)?.getter ?? 'English fallback'`. Check: page titles, section headers, button labels, snackbar messages, empty states, error messages, form labels, placeholders.

## Crawl Method

**Level 1:** Read the entry screen file completely. Map every interactive element:
- Every `onTap`, `onPressed`, `onLongPress`, `GestureDetector`, `InkWell`, `IconButton`, `TextButton`, `ElevatedButton`, `OutlinedButton`, `PopupMenuButton`
- Every `Navigator.push`, `Navigator.pushNamed`, `showModalBottomSheet`, `showDialog`, `showMenu`
- Every API/service call (`_service.methodName()`)
- Every callback passed to child widgets

For each, record: what it does, where it navigates, what file/widget it opens, what service method it calls.

**Level 2:** Read each destination file/widget from Level 1. Repeat the same full analysis. Verify every handler is real (not empty/stub), every route exists in `main.dart`, every service method exists with correct parameter signature and return type.

**Level 3-10:** Read each new destination from the previous level. Same full analysis. Continue until you reach terminal pages (no further navigation) or Level 10, whichever comes first.

**Deduplication:** If a destination was already crawled at a previous level (e.g. ProfileScreen appears at both Level 2 and Level 3), skip it on subsequent encounters — don't re-crawl the same file.

## How to Fix Each Issue Type

1. **Empty handlers → Implement them.** Find a working example of the same callback in another screen and replicate the pattern. If it needs a service method, verify it exists in `lib/services/`. If the service method doesn't exist, check the backend (`ssh root@zima-uat.site`, password `ZimaBlueApps`, Laravel at `/var/www/html/tajiri`) — run `php artisan route:list --path=relevant_path` to check if the API endpoint exists. If it exists, add the Flutter service method and wire it up. If the endpoint doesn't exist either, create it on the backend following existing controller patterns.
2. **Missing callbacks → Wire them.** Search codebase for other places where the same widget is used with callbacks wired up. Copy that pattern.
3. **Broken routes → Fix the path.** Read `lib/main.dart` `onGenerateRoute` to find the correct route pattern and fix the caller.
4. **Compile errors → Fix directly.** Add missing imports (with `hide` for name collisions), fix `widget.x` → field access in StatelessWidget, correct types.
5. **Logic bugs → Fix root cause.** Don't add workarounds — fix the actual initialization, variable order, or state update.
6. **Stubs → Build the feature.** Use existing services and backend APIs. Follow codebase patterns: `setState` for state, `LocalStorageService` for auth tokens, `AppStringsScope.of(context)` for i18n strings, Swahili as primary language.
7. **Dead pages → Make them load.** Fix the load method, add the missing service call, wire up the data flow.

## Codebase Conventions (follow these)

- **State management:** `setState()` in StatefulWidgets, no Provider/Bloc/Riverpod
- **Services:** Instance-based classes in `lib/services/`, methods take auth token or userId as parameter
- **Auth:** Token from `LocalStorageService.getInstance().getAuthToken()`
- **Strings:** Via `AppStringsScope.of(context)` — bilingual English/Swahili
- **Design:** Monochromatic palette (#1A1A1A dark, #FAFAFA light), 48dp min touch targets, `maxLines` + `TextOverflow.ellipsis` on dynamic text
- **Models:** `factory Model.fromJson()` with null-safe parsing helpers
- **API config:** Base URL from `ApiConfig.baseUrl`, storage URLs from `ApiConfig.storageUrl`
- **Routing:** Named routes via `Navigator.pushNamed(context, '/feature/$id')`, defined in `lib/main.dart`

## Backend Verification & Implementation Directives

Every service call in the Flutter app MUST have a working backend endpoint. When you encounter a service method, verify the full chain: Flutter service → HTTP call → Laravel route → Controller method → Database table.

### How to Verify Backend Endpoints

**1. SSH into the production server:**
```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180
```

**2. Check if the route exists:**
```bash
cd /var/www/tajiri.zimasystems.com
php artisan route:list --path=business     # or whatever path prefix
```

**3. Test the endpoint with curl:**
```bash
curl -s "https://tajiri.zimasystems.com/api/business?user_id=38" | python3 -m json.tool
```

**4. Check the database table exists:**
```bash
php artisan tinker --execute="echo json_encode(Schema::getColumnListing('table_name'));"
```

### When a Backend Endpoint is MISSING

If the Flutter service calls an endpoint that doesn't exist (returns 404), you MUST create it:

**Step 1 — Create the database table (if needed):**
```bash
php artisan tinker --execute="
Schema::create('table_name', function (\$t) {
    \$t->id();
    \$t->foreignId('user_business_id')->constrained()->cascadeOnDelete();
    // ... columns
    \$t->timestamps();
});
echo 'Table created';
"
```

**Step 2 — Add controller method to `MyBusinessController.php`:**
```bash
# Location: /var/www/tajiri.zimasystems.com/app/Http/Controllers/Api/MyBusinessController.php
# Pattern: Use DB facade, not Eloquent. Match existing method patterns.
```

**Step 3 — Add route to `routes/api.php`:**
```bash
# Location: /var/www/tajiri.zimasystems.com/routes/api.php
# Pattern: Route::prefix("business")->controller(MyBusinessController::class)->group(...)
```

**Step 4 — Test the new endpoint:**
```bash
curl -s "https://tajiri.zimasystems.com/api/new-endpoint" | python3 -m json.tool
```

### Backend Patterns (MUST follow)

- **Controller:** `App\Http\Controllers\Api\MyBusinessController` — all business endpoints in one controller
- **Database queries:** Use `DB::table('table_name')` facade, NOT Eloquent models (keeps it simple)
- **Response format:** Always return `{"success": true/false, "data": ..., "message": "..."}` 
- **List endpoints:** Return `{"success": true, "data": [...]}` 
- **Create endpoints:** Return `{"success": true, "data": {"id": N}}` 
- **Error handling:** Try/catch, return `{"success": false, "message": "error description"}`
- **Validation:** Use `$r->validate([...])` at the start of POST/PUT methods
- **Auto-numbering:** For invoices `INV-YYYY-NNNN`, quotes `QT-YYYY-NNNN`, POs `PO-YYYY-NNNN` — count existing records + 1, pad to 4 digits

### URL Consistency Check

The Flutter service at `lib/business/services/business_service.dart` uses `ApiConfig.baseUrl` which is `https://tajiri.zimasystems.com/api`. All business endpoints MUST use the prefix `/business/` (singular, NOT `/businesses/` plural). Verify every URL in the service matches what's registered in Laravel routes.

### Backend Server Details

| Item | Value |
|------|-------|
| Server | `172.240.241.180` |
| SSH | `root@172.240.241.180`, password `ZimaBlueApps` |
| Project path | `/var/www/tajiri.zimasystems.com` |
| Framework | Laravel 12, PHP 8.3 |
| Database | PostgreSQL 16 (user: postgres, password: postgres, db: tajiri) |
| Controller | `app/Http/Controllers/Api/MyBusinessController.php` |
| Routes | `routes/api.php` |
| Domain | `tajiri.zimasystems.com` |

### External APIs

| Service | Server | Details |
|---------|--------|---------|
| Tenders API | `tenders.zimaservices.com` | FastAPI on port 8010, PostgreSQL, JWT auth |
| Email (future) | Mailcow (planned) | Not yet deployed |

---

## Testing Directives

After fixing any feature, verify it actually works end-to-end — not just that it compiles.

### Frontend Testing

**1. Static analysis (MANDATORY):**
```bash
flutter analyze [every_modified_file]
```
Zero errors required. Only pre-existing `info`-level warnings are acceptable.

**2. Widget structure check:**
- Every `Scaffold` should have `backgroundColor: Color(0xFFFAFAFA)` or equivalent
- Every `AppBar` should have `elevation: 0, scrolledUnderElevation: 1`
- Every list should have `RefreshIndicator` with `color: Color(0xFF1A1A1A)`
- Every form should have `_formKey` with validation
- Every async button should show loading spinner and be disabled during operation

**3. State management check:**
- `setState()` only called when `mounted` is true (check after every async gap)
- Controllers disposed in `dispose()`
- Listeners removed in `dispose()`
- No memory leaks from un-cancelled subscriptions

### Backend Testing

**1. Test each endpoint with curl after creation:**
```bash
# List endpoint
curl -s "https://tajiri.zimasystems.com/api/business/{businessId}/{feature}" | python3 -m json.tool

# Create endpoint
curl -s -X POST "https://tajiri.zimasystems.com/api/business/{feature}" \
  -H "Content-Type: application/json" \
  -d '{"field": "value"}' | python3 -m json.tool

# Verify response has {"success": true, "data": ...}
```

**2. Test error cases:**
```bash
# Missing required field
curl -s -X POST "https://tajiri.zimasystems.com/api/business/{feature}" \
  -H "Content-Type: application/json" \
  -d '{}' | python3 -m json.tool
# Should return {"success": false, "message": "..."}

# Non-existent resource
curl -s "https://tajiri.zimasystems.com/api/business/99999/{feature}" | python3 -m json.tool
# Should return {"success": false} or 404
```

**3. Test data integrity:**
```bash
# Create → Read → Verify data matches
# Update → Read → Verify update applied
# Delete → Read → Verify gone
```

### Integration Testing

For cross-module features, verify the full chain:

| Integration | Test |
|-------------|------|
| Invoice → Email | Create invoice → tap email button → verify compose screen pre-fills correctly |
| Debt → Reminder | Create debt → tap remind → verify SMS/WhatsApp URI opens with correct message |
| Quote → Invoice | Create quote → convert to invoice → verify invoice created with matching data |
| Tender → Documents | Apply to tender → verify document attachment sheet shows business docs |
| Payroll → Tax | Run payroll → go to tax page → verify PAYE/NSSF totals match payroll data |
| Expense → Budget | Add expense → verify it appears in expense list with correct category/amount |

### Performance Check

- Screens should load within 2 seconds on a stable connection
- Lists with 50+ items should use `ListView.builder` (not `Column` with `children`)
- Images should use `CachedMediaImage` (not raw `Image.network`)
- Large datasets should have pagination (infinite scroll with 70% prefetch)

## Output Format

For each level, produce:

```
## Level N: [ScreenName] ([file_path])

### Interactive Elements
1. [Element] → [Destination/Action] — [Status: OK / ISSUE]
2. ...

### Issues Found & Fixed
| # | Line | Type | Description | Fix Applied |
|---|------|------|-------------|-------------|
| 1 | 142  | Empty handler | onComment: () {} does nothing | Implemented: opens CommentBottomSheet |
| 2 | 305  | Missing callback | PostCard missing onHashtagTap | Added: navigates to HashtagScreen |

### Navigation Links → Level N+1
- [Element] → [DestinationScreen] ([file_path])
```

At the end, produce a final summary:

```
## Summary

### Files Modified
- [file_path] — [brief description of changes]

### Backend Changes (if any)
- [endpoint created/modified]

### Total Issues: [X] found, [Y] fixed
| Severity | Count |
|----------|-------|
| Blocking | N     |
| Moderate | N     |
| Minor    | N     |
```

---

## Design Improvement & Beautification Directives

When fixing or building screens, actively research and apply best-in-class UI/UX patterns. Every screen should look professional and feel native to a premium app.

### Design System (MANDATORY — see `docs/DESIGN.md`)

- **Palette:** Monochromatic — `#1A1A1A` (primary dark), `#666666` (secondary text), `#999999` (tertiary/muted), `#FAFAFA` (background), `#FFFFFF` (card surfaces). NO colorful buttons. Only use color for semantic meaning: green = success, red = error/danger, orange = warning, blue = info.
- **Typography:** System font. Weights: `w700` for headings, `w600` for section titles, `w500` for body emphasis, `w400` for body. Sizes: 24-32 for hero numbers, 18-20 for page titles, 15-16 for section headings, 13-14 for body, 11-12 for captions.
- **Spacing:** Use multiples of 4: `4, 8, 12, 16, 20, 24, 32`. Padding: 16 horizontal standard, 12-14 inside cards. Section spacing: 16-24.
- **Cards:** `BorderRadius.circular(12-16)`, `color: #FFFFFF`, subtle shadow (`color: Colors.black.withValues(alpha: 0.04-0.08), blurRadius: 10-12`). NO heavy borders — use shadow or very light border (`Colors.grey.shade100`).
- **Touch targets:** Minimum 48dp height for all interactive elements (buttons, list tiles, chips). This is an accessibility requirement.
- **Text overflow:** ALWAYS use `maxLines` + `TextOverflow.ellipsis` on ANY dynamic text (usernames, titles, descriptions). Never allow text to push layout.
- **Icons:** Use Material `_rounded` variants (e.g., `Icons.home_rounded`, not `Icons.home`). Icon size: 18-24 for inline, 28-32 for feature tiles, 48-64 for empty states.
- **Loading states:** Always show `CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A1A))`. Never show a blank screen during loading.
- **Empty states:** Icon (64px, `Colors.grey.shade300`) + title (16px, `grey.shade500`) + subtitle (13px, `grey.shade400`). Centered vertically.
- **Error states:** Icon + message + retry button. Never show raw error strings to users.

### UI/UX Research Directive

Before building or significantly modifying any screen:

1. **Research the best apps** in that domain (e.g., for invoicing → study QuickBooks, FreshBooks; for email → study Outlook, Gmail; for health → study Flo, BabyCenter; for fitness → study Apple Fitness+, Strava).
2. **Identify 3 UI patterns** from those apps that we can adopt. Focus on: information hierarchy, action placement, empty states, loading transitions, micro-interactions.
3. **Apply patterns** within our monochromatic design system — adapt colors to our palette, but keep the layout patterns.
4. **Prioritize scannability:** Users should understand a screen's purpose and find primary actions within 2 seconds. Put the most important info and the primary CTA above the fold.
5. **Progressive disclosure:** Don't overwhelm. Show summary first, details on tap. Use expandable sections, bottom sheets, and drill-down navigation rather than cramming everything on one screen.

### Specific Beautification Rules

- **List items:** Always have an icon/avatar on the left (40-48px container with rounded corners and tinted background), text block in the middle (title + subtitle), value/action on the right. Consistent `14px` vertical padding.
- **Stat cards:** Use the dark card pattern (`Color(0xFF1A1A1A)` background, white text) for hero metrics. Supporting stats below in light cards.
- **Action buttons:** Primary = `FilledButton` with `backgroundColor: Color(0xFF1A1A1A)`, `borderRadius: 12-14`. Secondary = `OutlinedButton` with `foregroundColor: Color(0xFF1A1A1A)`. No colorful buttons except semantic (red for delete, green for confirm).
- **Forms:** Labels above fields (not floating). `filled: true, fillColor: Colors.white`. Rounded borders `BorderRadius.circular(12)`. Group related fields with section headers.
- **Bottom sheets:** Drag handle (40x4, `Colors.grey.shade300`, centered), 16px padding, rounded top corners (`BorderRadius.vertical(top: Radius.circular(16))`).
- **Pill buttons:** For compact actions in toolbars: `BorderRadius.circular(20)`, `padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8)`, dark background, white text, 12px font.
- **Status badges:** Small pill containers: `padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3)`, `borderRadius: 6-8`, background = status color at 10% opacity, text = status color at full.

---

## Business Logic Improvement Directives

When fixing or building features, don't just make them work — make them work WELL.

### Cross-Module Wiring

Every feature should be aware of related TAJIRI modules. Before marking a screen as complete, check:

1. **Can this data be useful elsewhere?** (e.g., business expenses → personal budget, doctor prescriptions → pharmacy orders, invoice data → tax calculations)
2. **Can the user take action from here?** (e.g., from customer page → call/message/view profile, from invoice → send via email, from debt → send reminder via WhatsApp)
3. **Are there contextual upsells?** (e.g., after doctor visit → suggest health insurance, after loan approval → suggest credit life insurance, after business registration → suggest business email)

### Data Integrity

- **Validate inputs** at the UI level before API calls. Show inline errors, not just snackbar after submission.
- **Optimistic updates** for non-critical actions (like/unlike, mark read, toggle). Revert on failure.
- **Confirm destructive actions** with `AlertDialog` before: delete, cancel, unfriend, unfollow, logout.
- **Show loading on buttons** during API calls — disable the button and show a small spinner inside it. Never let users double-tap submit.
- **Handle pagination** — use infinite scroll with 70% prefetch threshold. Show bottom loading indicator.

### Tanzanian Business Logic

- **Currency:** Always TZS. Format with comma separators: `1,500,000`. Use K/M abbreviations in stats: `1.5M`, `450K`.
- **Phone numbers:** Tanzania format `0712 345 678` or `+255 712 345 678`. Support both in input fields.
- **Dates:** Display as `dd/MM/yyyy` (Tanzania standard). Use relative dates for recent items: "Leo" (today), "Jana" (yesterday), "Siku 3 zilizopita".
- **Tax calculations:** Use accurate Tanzania rates (see business module PAYE table). These MUST be correct — businesses rely on them.
- **M-Pesa integration:** Every payment touchpoint should support M-Pesa. This is the primary payment method for 95% of Tanzanians.

---

## Language Directives

**English is the default language.** Swahili is the secondary language, toggled via `LanguageNotifier`.

### How It Works

- `AppStrings` class in `lib/l10n/app_strings.dart` uses ternary getters:
  ```dart
  String get save => isSwahili ? 'Hifadhi' : 'Save';
  ```
- Access via `AppStringsScope.of(context)` from any widget.
- Language toggle: `LanguageNotifier` singleton (same pattern as `ThemeNotifier`).

### Rules for All New Code

1. **Default text must be English.** When `AppStrings` doesn't have a getter for a string, use the English fallback directly:
   ```dart
   Text(s?.save ?? 'Save')  // English fallback
   ```

2. **Tab labels and category headers** in `profile_tab_config.dart` are in English. Swahili translations come from `AppStrings.profileTabLabel(id)` and `AppStrings.profileTabLabelOwn(id)`.

3. **Never hardcode Swahili-only text** in new screens. Always provide English as the default with Swahili as the bilingual option:
   ```dart
   // WRONG:
   Text('Hifadhi')
   
   // CORRECT:
   Text(isSwahili ? 'Hifadhi' : 'Save')
   
   // BEST (using AppStrings):
   Text(AppStringsScope.of(context)?.save ?? 'Save')
   ```

4. **For pages inside modules** (business, doctor, pharmacy, etc.) that were built with Swahili-first UI, gradually update to bilingual as they are touched. Don't do mass find-replace — update strings when you're already editing the file for other reasons.

5. **Button labels, section titles, and error messages** are the highest priority for bilingual support. Placeholder hints and long descriptions are lower priority.

6. **Product names and proper nouns** stay as-is: "TAJIRI Boost", "Duka la Dawa Tajiri", "Doctor Tajiri", "Kikoba", "Michango". These are brand names, not translatable text.

7. **The `profileTabLabelOwn` method** should NOT prefix "My" on service tabs (business, health, etc.). Only social tabs (posts, photos, videos) get "My" prefix. All other tabs use the same label as `profileTabLabel`.

---

## Usage

Replace `[ENTRY_FILE_PATH]` with any screen file path, e.g.:
- `lib/screens/feed/feed_screen.dart`
- `lib/screens/feed/full_screen_post_viewer_screen.dart`
- `lib/screens/messages/conversations_screen.dart`
- `lib/screens/shop/shop_screen.dart`
- `lib/screens/wallet/wallet_screen.dart`
- `lib/screens/settings/settings_screen.dart`
- `lib/screens/profile/profile_screen.dart`
- `lib/screens/clips/clips_screen.dart`
- `lib/screens/groups/groups_screen.dart`
- `lib/screens/music/music_player_sheet.dart`
- `lib/business/pages/business_home_page.dart`
- `lib/doctor/pages/doctor_home_page.dart`
- `lib/pharmacy/pages/pharmacy_home_page.dart`
- `lib/insurance/pages/insurance_home_page.dart`
- `lib/fitness/pages/fitness_home_page.dart`
- `lib/my_circle/pages/my_circle_home_page.dart`
- `lib/my_baby/pages/my_baby_home_page.dart`
- `lib/my_family/pages/family_home_page.dart`
- `lib/skincare/pages/skincare_home_page.dart`
- `lib/hair_nails/pages/hair_nails_home_page.dart`
- `lib/investments/pages/investments_home_page.dart`
- `lib/loans/pages/loans_home_page.dart`
- `lib/my_wallet/pages/wallet_home_page.dart`
- `lib/tenders/pages/tenders_home_page.dart`
