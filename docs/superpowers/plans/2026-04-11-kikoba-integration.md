# Kikoba-TAJIRI Integration — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Integrate the Kikoba/VICOBA module into the TAJIRI platform — fix critical security issues, wire financial operations to Budget/Income/Expenditure services, enable notifications, and sync meetings to calendar.

**Architecture:** Kikoba remains on its own backend (`vicoba.zimasystems.com`). Integration happens at the Flutter layer — after VICOBA API calls succeed, fire-and-forget calls to TAJIRI services (ExpenditureService, IncomeService, FCM routing, CalendarService). No VICOBA backend changes needed for Phase 1-2.

**Tech Stack:** Flutter/Dart, existing TAJIRI services, existing Kikoba HttpService

---

## Phase 1: Critical Security + Notifications

### Task 1: Clear DataStore hardcoded defaults

**Files:**
- Modify: `lib/kikoba/DataStore.dart`

**Problem:** DataStore has real production user data as default values (phone number, userId, kikobaId). If initialization fails silently, payments could be attributed to the wrong user.

- [ ] **Step 1: Read DataStore.dart and find all hardcoded defaults**

Read the file. Look for lines like:
```dart
static String userNumber = "255692410353";
static String? currentUserId = "b05b4efef01c4ae89ca7284193ba21c2";
static String? currentKikobaId = "c267341695e...";
static String currentUserName = "...";
```

- [ ] **Step 2: Replace all hardcoded values with safe defaults**

Change every hardcoded real value to empty/null:
```dart
static String userNumber = "";
static String? currentUserId;
static String? currentKikobaId;
static String? currentKikobaName;
static String currentUserName = "";
```

Keep non-sensitive defaults (booleans, empty lists, etc.) as-is.

- [ ] **Step 3: Add guards in HttpService for critical fields**

In `lib/kikoba/HttpService.dart`, find methods that use `DataStore.currentUserId` or `DataStore.userNumber` for payments. Add null/empty checks at the top:

```dart
// In payment methods, add guard:
if (DataStore.currentUserId == null || DataStore.currentUserId!.isEmpty) {
  debugPrint('[HttpService] ERROR: currentUserId is empty, aborting payment');
  return null;
}
```

Add this guard to: `createPaymentIntentMNO`, `closeloanPaymentIntentMNO`, `rejeshoPaymentIntentMNO`, `topuploanPaymentIntentMNO`, `submitLoanApplication`.

- [ ] **Step 4: Verify no regression**

Run `flutter analyze lib/kikoba/DataStore.dart lib/kikoba/HttpService.dart`

---

### Task 2: Wire Kikoba FCM notifications to TAJIRI

**Files:**
- Modify: `lib/kikoba/kikoba_module.dart`
- Modify: `lib/services/fcm_service.dart`

**Problem:** Kikoba's `FCMService` class exists but is never called. Voting notifications are silently dropped.

- [ ] **Step 1: Add voting notification routing to TAJIRI's FcmService**

In `lib/services/fcm_service.dart`, find the notification tap handler / payload routing logic. Add kikoba-specific action types:

```dart
case 'vote':
case 'kikoba_vote':
case 'kikoba_loan_request':
case 'kikoba_membership':
case 'kikoba_meeting':
  // Navigate to kikoba tab in profile
  navigatorKey.currentState?.pushNamed('/profile/${userId}');
  break;
```

Read the file first to find the exact routing pattern and add these cases following the same style.

- [ ] **Step 2: Add FCM channel for kikoba**

In the FCM initialization (where Android notification channels are created), add a `kikoba` channel:

```dart
const AndroidNotificationChannel kikobaChannel = AndroidNotificationChannel(
  'kikoba',
  'Kikoba',
  description: 'Vikoba savings group notifications',
  importance: Importance.high,
);
```

Add `'kikoba'` to the channel type mapping.

- [ ] **Step 3: Verify**

Run `flutter analyze lib/services/fcm_service.dart lib/kikoba/kikoba_module.dart`

---

## Phase 2: Financial Integration

### Task 3: Record Kikoba payments as expenditures

**Files:**
- Modify: `lib/kikoba/selectPaymentMethod.dart`

**Problem:** When a user pays Ada, Hisa, Akiba, or repays a loan inside Kikoba, TAJIRI's Budget/Expenditure system never knows.

- [ ] **Step 1: Add imports**

At the top of `lib/kikoba/selectPaymentMethod.dart`, add:
```dart
import '../services/expenditure_service.dart';
import '../services/local_storage_service.dart';
```

- [ ] **Step 2: Create a helper method to record expenditure**

Add a private method in the State class:
```dart
Future<void> _recordBudgetExpenditure(String category, double amount, String description) async {
  try {
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    final userId = storage.getUser()?.userId;
    if (token == null || userId == null) return;
    
    ExpenditureService.recordExpenditure(
      token: token,
      amount: amount,
      category: category,
      description: description,
      referenceId: 'kikoba_${DataStore.paymentService}_${DateTime.now().millisecondsSinceEpoch}',
      sourceModule: 'kikoba',
    ).catchError((_) => null);
  } catch (_) {}
}
```

- [ ] **Step 3: Call it after successful payment**

Find `_processPayment()` or the payment success handler. After the payment succeeds (the snackbar/navigation on success), add:

```dart
// Map payment service to budget category
final budgetCategory = switch (DataStore.paymentService) {
  'ada' => 'michango',
  'hisa' => 'michango',
  'akiba' => 'akiba',
  'rejesho' || 'closeloan' || 'topuploan' => 'deni',
  'mchango' => 'michango',
  _ => 'michango',
};

final description = switch (DataStore.paymentService) {
  'ada' => 'Kikoba Ada: ${DataStore.currentKikobaName ?? ""}',
  'hisa' => 'Kikoba Hisa: ${DataStore.currentKikobaName ?? ""}',
  'akiba' => 'Kikoba Akiba: ${DataStore.currentKikobaName ?? ""}',
  'rejesho' => 'Kikoba Loan Repayment: ${DataStore.currentKikobaName ?? ""}',
  'closeloan' => 'Kikoba Loan Close: ${DataStore.currentKikobaName ?? ""}',
  'topuploan' => 'Kikoba Loan Top-Up: ${DataStore.currentKikobaName ?? ""}',
  'mchango' => 'Kikoba Mchango: ${DataStore.currentKikobaName ?? ""}',
  _ => 'Kikoba: ${DataStore.currentKikobaName ?? ""}',
};

_recordBudgetExpenditure(budgetCategory, DataStore.paymentAmount, description);
```

Read the actual payment flow to find where success is determined and place this call there. It must be fire-and-forget — never block the kikoba payment flow.

- [ ] **Step 4: Verify**

Run `flutter analyze lib/kikoba/selectPaymentMethod.dart`

---

### Task 4: Record Kikoba income (loan disbursement)

**Files:**
- Modify: `lib/kikoba/pages/LoanDetailPage.dart` or wherever loan disbursement is confirmed
- Modify: `lib/kikoba/dashboard_screen.dart` (if payout display exists)

**Problem:** When a loan is disbursed to the user, TAJIRI doesn't know — income is not recorded.

- [ ] **Step 1: Find where loan disbursement is shown/confirmed**

Search for disbursement status display:
```
grep -rn "disbursed\|approved\|loan.*accept\|mkopo.*pokea" lib/kikoba/ --include="*.dart" | head -20
```

- [ ] **Step 2: Add income recording on loan disbursement view**

When the user views a loan with status `disbursed` or `active` for the first time, record income:

```dart
import '../../services/income_service.dart';
import '../../services/local_storage_service.dart';

// After confirming loan is disbursed:
Future<void> _recordLoanIncome(double amount, String loanId) async {
  try {
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    final userId = storage.getUser()?.userId;
    if (token == null || userId == null) return;
    
    IncomeService.recordIncome(
      token: token,
      amount: amount,
      source: 'kikoba_loan',
      description: 'Mkopo: ${DataStore.currentKikobaName ?? "Kikoba"}',
      referenceId: 'kikoba_loan_$loanId',
      sourceModule: 'kikoba',
    ).catchError((_) => null);
  } catch (_) {}
}
```

Use `referenceId` with the loan ID for deduplication — this prevents double-recording if the user views the loan detail multiple times.

- [ ] **Step 3: Verify**

Run `flutter analyze` on the modified file.

---

### Task 5: Add Kikoba budget categories to BudgetContextBanner

**Files:**
- Modify: `lib/widgets/budget_context_banner.dart`

**Problem:** The banner's `_categoryLabel()` method doesn't have labels for `hisa`, `deni`, `akiba` — all kikoba-relevant categories.

- [ ] **Step 1: Add missing labels**

Find `_categoryLabel()` in `budget_context_banner.dart` and add:

```dart
'hisa': ['Shares', 'Hisa'],
'ada_kikoba': ['Membership Fee', 'Ada ya Kikoba'],
'deni': ['Debt/Loans', 'Deni/Mikopo'],
'akiba': ['Savings', 'Akiba'],
'kikoba': ['Kikoba', 'Kikoba'],
```

- [ ] **Step 2: Update the banner category in selectPaymentMethod.dart**

In `lib/kikoba/selectPaymentMethod.dart`, find where `BudgetContextBanner` is rendered. Update the `category` to be dynamic based on `DataStore.paymentService`:

```dart
BudgetContextBanner(
  category: switch (DataStore.paymentService) {
    'ada' => 'michango',
    'hisa' => 'michango',
    'akiba' => 'akiba',
    'rejesho' || 'closeloan' || 'topuploan' => 'deni',
    'mchango' => 'michango',
    _ => 'michango',
  },
  paymentAmount: DataStore.paymentAmount,
  isSwahili: true, // TODO: get from context
),
```

- [ ] **Step 3: Verify**

Run `flutter analyze lib/widgets/budget_context_banner.dart lib/kikoba/selectPaymentMethod.dart`

---

### Task 6: Sync Vikao (meetings) to TAJIRI calendar

**Files:**
- Modify: `lib/kikoba/HttpService.dart` (find meeting creation method)
- Or modify the screen that creates meetings

**Problem:** Kikoba meetings are invisible in TAJIRI's calendar.

- [ ] **Step 1: Find the meeting creation flow**

```
grep -rn "meeting\|vikao\|mkutano" lib/kikoba/ --include="*.dart" | grep -i "create\|schedule\|save" | head -10
```

- [ ] **Step 2: After meeting is created, add to TAJIRI calendar**

```dart
import '../../services/event_service.dart';
import '../../services/local_storage_service.dart';

// After successful meeting creation:
Future<void> _syncMeetingToCalendar(String title, DateTime date, String? location, String? description) async {
  try {
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    final userId = storage.getUser()?.userId;
    if (token == null || userId == null) return;
    
    final eventService = EventService();
    await eventService.createEvent(
      userId,
      '${DataStore.currentKikobaName ?? "Kikoba"}: $title',
      date,
      description: description,
      locationName: location,
    );
  } catch (_) {}
}
```

Fire-and-forget — never block the meeting creation flow. If calendar sync fails, the meeting still exists in VICOBA.

- [ ] **Step 3: Verify**

Run `flutter analyze` on the modified file.

---

## Phase 2b: Improve Kikoba UX within TAJIRI

### Task 7: Better error messages on bridge login failure

**Files:**
- Modify: `lib/kikoba/kikoba_module.dart`

**Problem:** All bridge login failures show the same generic message.

- [ ] **Step 1: Differentiate error types**

Replace the single catch block in `_initializeModule()` with specific error handling:

```dart
} on SocketException catch (_) {
  // No internet
  if (mounted) setState(() {
    _hasError = true;
    _errorMessage = 'No internet connection. Check your network and try again.';
    _isInitializing = false;
  });
} catch (e) {
  final msg = e.toString();
  String userMessage;
  if (msg.contains('phone') || msg.contains('simu')) {
    userMessage = 'Phone number not found. Please update your profile.';
  } else if (msg.contains('bridge') || msg.contains('unganisha')) {
    userMessage = 'Could not connect to Kikoba. Please try again.';
  } else {
    userMessage = 'Something went wrong. Please try again.';
  }
  if (mounted) setState(() {
    _hasError = true;
    _errorMessage = userMessage;
    _isInitializing = false;
  });
}
```

Make all messages bilingual with `isSwahili` check.

- [ ] **Step 2: Add bilingual text to loading and error states**

Replace Swahili-only text:
- "Inapakia Kikoba..." → `isSwahili ? 'Inapakia Kikoba...' : 'Loading Kikoba...'`
- "Jaribu Tena" → `isSwahili ? 'Jaribu Tena' : 'Try Again'`

Get `isSwahili` from `AppStringsScope` or `LocalStorageService.instanceSync?.getLanguageCode() == 'sw'`.

- [ ] **Step 3: Verify**

Run `flutter analyze lib/kikoba/kikoba_module.dart`

---

### Task 8: Final verification

- [ ] **Step 1: Run full analyze on all modified files**

```bash
flutter analyze lib/kikoba/DataStore.dart lib/kikoba/HttpService.dart lib/kikoba/selectPaymentMethod.dart lib/kikoba/kikoba_module.dart lib/services/fcm_service.dart lib/widgets/budget_context_banner.dart
```

- [ ] **Step 2: Verify no broken imports**

```bash
grep -r "import.*kikoba" lib/services/ lib/screens/ lib/widgets/ lib/budget/ --include="*.dart"
```

Ensure no circular dependencies.

- [ ] **Step 3: Check all fire-and-forget calls have .catchError**

```bash
grep -n "IncomeService\|ExpenditureService" lib/kikoba/ --include="*.dart" -A 2
```

Every call must have `.catchError((_) => null)` — never block the kikoba flow.
