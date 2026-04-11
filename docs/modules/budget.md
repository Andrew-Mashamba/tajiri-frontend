# Budget — Wallet-Based Spending Planner

## Tanzania Context

Most Tanzanians manage money mentally — salary comes in, bills get paid ad-hoc, and by month-end the money is gone with no clear picture of where it went. Formal budgeting tools like YNAB or Goodbudget don't work here because they rely on manual transaction logging, which nobody does consistently.

TAJIRI solves this by making the budget **automatic**. Because all commerce happens inside the platform (rent, food, transport, school fees, bills, health, entertainment), every shilling spent is tracked by design. The budget isn't a logging tool — it's a **spending planner backed by real wallet transactions**.

## International Reference Apps

1. **YNAB (You Need a Budget)** — Zero-based budgeting pioneer. Four rules: give every dollar a job, embrace true expenses, roll with the punches, age your money. Key insight we adopt: **every shilling gets a job** (the unallocated funds concept). Also: rollover between months, goal tracking, and the idea that overspending in one category means moving money from another.

2. **PocketGuard** — "In My Pocket" feature shows **safe-to-spend amount** after bills, goals, and budgets are deducted. Key insight we adopt: **a single number showing what's truly available to spend freely**. Also: pace alerts warning when you're spending too fast relative to days left in the month.

3. **Monarch Money** — Best-in-class cash flow forecasting. Projects future balance based on upcoming income and recurring expenses. Key insight we adopt: **forward-looking balance projection** so users can see if they'll run short before month end. Also: flexible vs fixed expense categorization, collaborative budgets.

4. **Cleo AI** — Conversational AI budgeting assistant with personality. "Roast me" and "Hype me" modes for motivation. Auto-save feature that automatically moves money to savings. Key insight we adopt: **Shangazi (our AI) can give budget insights in chat** — spending warnings, savings encouragement, budget roasts in Swahili.

5. **Goodbudget** — Digital envelope system closest to our model. Manual philosophy — users consciously allocate money to envelopes. Key insight we adopt: **the envelope metaphor itself** — visual, intuitive, works across cultures.

6. **Wavvy Wallet (Kenya)** — M-Pesa expense tracker built for East Africa. Auto-categorizes M-Pesa transactions using AI trained on local business names. Key insight we adopt: **auto-categorization trained on Tanzanian transaction patterns** — recognizing TANESCO, DAWASCO, Vodacom, local merchants.

7. **Rocket Money** — Subscription tracking and bill negotiation. Identifies recurring charges and helps cancel unwanted subscriptions. Key insight we adopt: **recurring expense detection** — automatically identify and track monthly bills.

## How It Works

### The Money Flow

```
┌─────────────────────────────────────────────┐
│         User's TAJIRI Wallet                │
│                                             │
│  Balance = Allocated + Unallocated          │
│                                             │
│  ┌────────────────────────────────┐         │
│  │ Budget Envelopes (Allocated)   │         │
│  │ Kodi:     150,000              │         │
│  │ Chakula:   80,000              │         │
│  │ Usafiri:   30,000              │         │
│  │ ...                            │         │
│  └────────────────────────────────┘         │
│  ┌────────────────────────────────┐         │
│  │ Unallocated                    │         │
│  │ 85,000                         │         │
│  └────────────────────────────────┘         │
└─────────────────────────────────────────────┘
```

### Sources of Funds (Into Wallet)

| Source | How |
|---|---|
| **Top-up** | User deposits via M-Pesa, Tigo Pesa, Airtel Money, or bank transfer |
| **Salary deposit** | Employer pays directly into wallet (for gig/informal workers) |
| **Creator earnings** | Subscriptions, tips, gifts from content creation |
| **Shop sales** | Revenue from selling products on TAJIRI marketplace |
| **Tajirika partner earnings** | Income from providing services across TAJIRI modules |
| **Michango received** | Crowdfunding campaign donations |
| **Kikoba payouts** | Savings group distributions |

### Spending (Out of Wallet, Tracked by Budget)

Every payment made through a TAJIRI module is automatically categorized against the corresponding budget envelope. Default envelopes cover the full reality of Tanzanian spending:

#### Essential Living (auto-created for all users)

| Budget Envelope | TAJIRI Module | What Gets Paid |
|---|---|---|
| **Kodi** (Rent/Housing) | Housing | Rent to landlord, house maintenance, furniture, household items |
| **Chakula** (Food & Groceries) | Food | Restaurant orders, grocery delivery, market shopping, cooking gas, drinking water |
| **Usafiri** (Transport) | Transport / Fuel Delivery | Daladala fare, bodaboda, taxi, fuel, parking, car maintenance |
| **Umeme na Maji** (Electricity & Water) | Bills / TANESCO / DAWASCO | LUKU electricity tokens, DAWASCO water bills |
| **Simu na Intaneti** (Phone & Internet) | Bills | Airtime, data bundles, WiFi subscription, Vodacom/Tigo/Airtel/Halotel |
| **Afya** (Health) | Doctor / Pharmacy / Insurance | Doctor consultations, medicine, lab tests, NHIF premium, health insurance |

#### Family & Education

| Budget Envelope | TAJIRI Module | What Gets Paid |
|---|---|---|
| **Ada/Shule** (School & Education) | Fee Status / Education | Tuition, exam fees, textbooks, school uniforms, stationery, HESLB repayment |
| **Watoto** (Children) | My Baby / Family | Diapers, baby food, daycare/childcare, toys, children's clothing, medical checkups |
| **Familia** (Family Support) | Wallet transfers | Money sent to parents/relatives, harusi (wedding) contributions, misiba (funeral/condolence) contributions, family emergencies |

#### Lifestyle & Personal

| Budget Envelope | TAJIRI Module | What Gets Paid |
|---|---|---|
| **Mavazi** (Clothing & Shoes) | Shop | Clothes, shoes, school uniforms, tailoring, dry cleaning |
| **Urembo** (Personal Care & Grooming) | Hair & Nails / Skin Care | Salon, kinyozi (barber), cosmetics, skincare products, spa, nails |
| **Burudani** (Entertainment & Leisure) | Nightlife / Events / Games | DSTV/Azam TV subscription, cinema, clubs, concerts, betting/gaming, streaming |

#### Faith & Community

| Budget Envelope | TAJIRI Module | What Gets Paid |
|---|---|---|
| **Dini** (Faith & Giving) | Fungu la Kumi / Zaka / Church | Church tithe (fungu la kumi), zaka, sadaka, mosque contributions, church offerings, religious events |
| **Michango** (Community Contributions) | Michango (Crowdfunding) | Fundraising contributions, harambee, social group contributions, charity |

#### Financial

| Budget Envelope | TAJIRI Module | What Gets Paid |
|---|---|---|
| **Akiba** (Savings) | — | Funds set aside, not spent (remains in wallet, protected from spending) |
| **Deni** (Debt & Loan Repayment) | Loans / HESLB | Loan repayments, microfinance installments, HESLB student loan, credit card, kikoba loan repayment |
| **Bima** (Insurance) | Insurance / Car Insurance | Car insurance, health insurance (beyond NHIF), life insurance, property insurance |
| **Dharura** (Emergency Fund) | Any | Reserved for unexpected expenses — medical emergencies, job loss, urgent family needs |

#### Business (shown only for users with business activity)

| Budget Envelope | TAJIRI Module | What Gets Paid |
|---|---|---|
| **Biashara** (Business Expenses) | Business / Ad Service / Shop | Inventory, supplies, rent for shop, employee wages, advertising, business licenses, TRA taxes |

**Total: 18 default envelopes** (Biashara only shown if user has shop/business activity). Users can hide envelopes they don't need and add custom ones.

#### Envelope Source: Backend Database (NOT Hardcoded)

Default envelopes are **seeded in the backend database** and fetched via API — never hardcoded in the Flutter app.

**Why:**
- Add/rename/reorder envelopes without an app update
- Localize labels server-side (Swahili + English stored per envelope)
- Roll out new categories to all users instantly
- Different defaults for different user segments (e.g., students get Ada/Shule prioritized, parents get Watoto)

**Backend table: `budget_envelope_defaults`**

```
id | name_en           | name_sw          | icon                      | color   | sort_order | group          | module_tag     | is_active
1  | Rent/Housing      | Kodi             | home_rounded              | 1A1A1A  | 0          | essential      | housing        | true
2  | Food & Groceries  | Chakula          | restaurant_rounded        | 4CAF50  | 1          | essential      | food           | true
3  | Transport         | Usafiri          | directions_car_rounded    | 2196F3  | 2          | essential      | transport      | true
4  | Electricity & Water| Umeme na Maji   | bolt_rounded              | FF9800  | 3          | essential      | utilities      | true
5  | Phone & Internet  | Simu na Intaneti | phone_android_rounded     | 607D8B  | 4          | essential      | telecom        | true
6  | Health            | Afya             | medical_services_rounded  | E53935  | 5          | essential      | health         | true
7  | School & Education| Ada/Shule        | school_rounded            | FF9800  | 6          | family         | education      | true
8  | Children          | Watoto           | child_care_rounded        | EC407A  | 7          | family         | children       | true
9  | Family Support    | Familia          | family_restroom_rounded   | 8D6E63  | 8          | family         | family         | true
10 | Clothing & Shoes  | Mavazi           | checkroom_rounded         | 9C27B0  | 9          | lifestyle      | clothing       | true
11 | Personal Care     | Urembo           | spa_rounded               | F06292  | 10         | lifestyle      | beauty         | true
12 | Entertainment     | Burudani         | sports_esports_rounded    | 795548  | 11         | lifestyle      | entertainment  | true
13 | Faith & Giving    | Dini             | volunteer_activism_rounded| 5C6BC0  | 12         | community      | faith          | true
14 | Contributions     | Michango         | handshake_rounded         | 26A69A  | 13         | community      | michango       | true
15 | Savings           | Akiba            | savings_rounded           | 009688  | 14         | financial      | savings        | true
16 | Debt & Loans      | Deni             | account_balance_wallet_rounded | F44336 | 15    | financial      | debt           | true
17 | Insurance         | Bima             | health_and_safety_rounded | 1565C0  | 16         | financial      | insurance      | true
18 | Emergency Fund    | Dharura          | warning_rounded           | FF5722  | 17         | financial      | emergency      | true
19 | Business Expenses | Biashara         | business_center_rounded   | 455A64  | 18         | business       | business       | true
```

**API endpoints:**

```
GET  /budget/envelope-defaults              → returns all default envelopes (cached on device)
GET  /budget/users/{userId}/envelopes       → returns user's envelopes (customized from defaults)
POST /budget/users/{userId}/envelopes       → create custom envelope
PUT  /budget/users/{userId}/envelopes/{id}  → update allocation, visibility, order
```

**Flutter flow:**
1. On first budget open → `GET /budget/envelope-defaults` → seed user's local envelopes from defaults
2. User customizes (hide, reorder, add) → saved to backend via `PUT`/`POST`
3. On subsequent opens → `GET /budget/users/{userId}/envelopes` → returns personalized set
4. Cache locally in SQLite for offline access
5. Periodic sync to pick up any new defaults added server-side

**Note:** The existing hardcoded `BudgetDefaults.defaultEnvelopes` in `lib/models/budget_models.dart` must be removed and replaced with this API-driven approach.

**Key design decisions:**
- Split the old "Bili" (bills) into **Umeme na Maji** (utilities) and **Simu na Intaneti** (phone/internet) — these are very different expense types and frequencies
- Added **Dini** (faith) — in Tanzania, religious giving (tithe, zaka, sadaka) is a major household expense, not optional for most families. Excluding it makes the budget incomplete
- Added **Familia** (family support) — sending money to extended family is a cultural norm, not an edge case. Almost every working Tanzanian supports relatives
- Added **Mavazi** (clothing) — school uniforms alone are a significant expense; adult clothing is regular spending
- Added **Urembo** (personal care) — salon/kinyozi visits are weekly/biweekly for most Tanzanians
- Added **Watoto** (children) — separate from school fees because diapers, food, and childcare are ongoing daily costs
- Added **Deni** (debt) — loan repayment is reality for most Tanzanians (HESLB, microfinance, kikoba loans)
- Added **Bima** (insurance) — car insurance is mandatory, health insurance increasingly common
- Added **Michango** (contributions) — harambee/social contributions are constant in Tanzanian social life
- **Biashara** (business) only appears for users who sell on TAJIRI Shop or have registered businesses — keeps the budget clean for non-business users

### The Golden Rule

**Wallet Balance = Allocated + Unallocated**

This must always be true. When money comes into the wallet, it starts as unallocated. The user assigns it to envelopes. When money is spent through a TAJIRI module, it deducts from the corresponding envelope's spent amount. The budget is always accurate because payments happen in-platform.

## Feature List

### Wallet Overview (Top of Budget Screen)
1. Display current TAJIRI wallet balance prominently (hero number, dark card)
2. "Top Up" button — deposit via M-Pesa/Tigo/Airtel/bank transfer
3. "Withdraw" button — move money out of wallet to mobile money or bank
4. Last sync timestamp showing when balance was last refreshed

### "Safe to Spend" Card (inspired by PocketGuard)
5. Single prominent number: wallet balance minus all allocations minus upcoming recurring bills
6. Label: "Unajeza kutumia" / "Safe to spend" — the amount available for discretionary spending
7. Updates in real-time as transactions happen
8. Color-coded: green (healthy), amber (getting low), red (danger zone)

### Unallocated Funds
9. Unallocated amount card — wallet balance minus sum of all envelope allocations
10. Visual warning when unallocated amount is large (nudge to allocate)
11. Quick "Tenga Sasa" / "Allocate Now" button opening allocation editor
12. When new income arrives, unallocated increases automatically — push notification: "TZS 50,000 imeingia, tenga pesa zako" / "TZS 50,000 received, allocate your funds"

### Budget Envelopes
13. Monthly budget period (resets each month)
14. Default envelopes created on first use — 18 envelopes covering all Tanzanian spending: Kodi, Chakula, Usafiri, Umeme na Maji, Simu na Intaneti, Afya, Ada/Shule, Watoto, Familia, Mavazi, Urembo, Burudani, Dini, Michango, Akiba, Deni, Bima, Dharura (+ Biashara for business users)
15. Each envelope shows: name, icon, allocated amount, spent amount, remaining amount, progress bar
16. Tap envelope → detail view with transactions for that category
17. Edit allocation amount per envelope
18. Add custom envelopes beyond the defaults
19. Delete/hide envelopes not needed
20. Reorder envelopes by drag handle or priority setting
21. Envelope status badges: "On Track", "Caution", "Over Budget" based on spending pace

### Spending Pace Alert (inspired by PocketGuard)
22. For each envelope: calculate spending rate vs days remaining in month
23. If spending pace will exhaust the envelope before month end → amber warning
24. If already over budget → red warning with amount over
25. Pace indicator: "Kasi ya matumizi" / "Spending pace" — shows projected end-of-month balance per envelope
26. Daily allowance calculation: remaining ÷ days left = "TZS X kwa siku" / "TZS X per day"

### Auto-Tracking from TAJIRI Modules
27. Wallet transactions tagged with module source are auto-categorized to matching envelope
28. Housing payments → Kodi
29. Food orders → Chakula
30. Transport/fuel payments → Usafiri
31. TANESCO/DAWASCO → Umeme na Maji
32. Airtime/data/WiFi → Simu na Intaneti
33. Doctor/pharmacy/NHIF → Afya
34. School fees/HESLB → Ada/Shule
35. Baby/childcare products → Watoto
36. Wallet transfers to family → Familia (user confirms)
37. Shop clothing purchases → Mavazi
38. Salon/kinyozi/skincare → Urembo
39. DSTV/events/nightlife/games → Burudani
40. Church/mosque/tithe/zaka → Dini
41. Michango donations → Michango
42. Loan repayments → Deni
43. Insurance premiums → Bima
44. Business expenses (for sellers) → Biashara
45. Uncategorized transactions → "Nyingine" / "Other" — user taps to assign to correct envelope
46. AI auto-categorization learns from user corrections over time (local pattern matching)

### Recurring Expense Detection (inspired by Rocket Money)
37. Automatically detect recurring wallet transactions (same amount, same recipient, monthly pattern)
38. Show list of detected recurring expenses: rent, subscriptions, bills
39. Predict upcoming recurring expenses and pre-deduct from "safe to spend"
40. Alert when a new recurring charge is detected: "Tumeona malipo mapya ya kila mwezi" / "We detected a new monthly charge"
41. Mark recurring expenses as "confirmed" or "one-time" to improve detection

### Manual Transaction Entry
42. Add manual expense (for cash spending outside platform)
43. Add manual income (for cash received outside platform)
44. Each manual entry: amount, description, date, envelope category
45. Manual entries clearly labeled with "Taslimu" / "Cash" badge vs auto-tracked "Wallet" badge
46. Quick-add shortcut: swipe on an envelope to add a cash expense directly

### Income Tracking
47. All wallet deposits shown as income with source label and icon
48. Income breakdown: top-up, creator earnings, shop sales, Tajirika earnings, michango, mobile money
49. Monthly income total displayed with trend arrow (↑↓ vs last month)
50. Income calendar: which days money came in, visualized as a heat map

### Move Between Envelopes (inspired by YNAB "Roll with the Punches")
51. Overspent in Chakula? Move money from Burudani to cover it
52. Drag-and-drop or "Move" button between envelopes
53. Shows impact: "Burudani: TZS 30,000 → 20,000 (-10,000)" to make trade-offs visible
54. No judgement — just flexibility. Budgets should adapt to life

### Savings Goals
55. Set named goals with target amounts and deadlines (e.g., "Laptop — TZS 800,000 by December")
56. Track progress toward each goal with visual progress ring
57. Monthly target calculation: "Hifadhi TZS 133,000 kwa mwezi" / "Save TZS 133,000 per month"
58. "Add to Goal" quick action moves funds from unallocated to goal
59. Celebration animation when goal is reached
60. Multiple active goals supported

### Cash Flow Forecast (inspired by Monarch Money)
61. Forward-looking 30-day projection graph
62. Shows: current balance → predicted income (recurring salary/earnings) → predicted expenses (recurring bills) → projected end-of-month balance
63. Warning if projection shows balance going below zero before month end
64. "What if" scenarios: "What if I spend TZS 50,000 on X?" — shows impact on end-of-month projection

### Shangazi Budget Insights (inspired by Cleo AI)
65. Shangazi (TAJIRI's AI assistant) can comment on spending patterns in Tea chat
66. Weekly budget roast: "Umebuyaga chai TZS 45,000 mwezi huu — karibu sawa na kodi yako ya wiki moja!" / "You spent TZS 45,000 on tea this month — almost a week's rent!"
67. Savings encouragement: "Hongera! Umehifadhi 20% ya mapato yako mwezi huu" / "Congrats! You saved 20% of your income this month"
68. Spending alerts in chat: "Bahati mbaya Chakula imezidi bajeti yako kwa TZS 12,000" / "Oops, Food exceeded your budget by TZS 12,000"
69. Users can ask Shangazi: "Nionyeshe matumizi yangu ya wiki hii" / "Show me my spending this week"

### Monthly Report
70. End-of-month summary card: total income, total spent, total saved, remaining
71. Spending breakdown by envelope — horizontal bar chart (largest first)
72. Income breakdown by source — pie chart
73. Comparison with previous month: "Umepunguza matumizi ya Burudani kwa 15%!" / "You reduced Entertainment spending by 15%!"
74. Over-budget envelopes highlighted in red
75. Savings rate percentage: "Umehifadhi 18% ya mapato" / "You saved 18% of income"
76. Shareable monthly summary card (image) — post to TAJIRI feed or save to gallery
77. Year-over-year trends (after 2+ months of data)

### Streak & Gamification
78. Budget streak: consecutive days of staying within all envelopes — "Siku 12 ndani ya bajeti" / "12 days within budget"
79. Monthly achievement badges: "Under Budget Master", "Savings Champion", "Zero Unallocated"
80. Streak freeze: one "off day" allowed per month without breaking streak

### Rollover (inspired by YNAB)
81. At month end, remaining allocated funds can roll over or reset
82. User chooses per envelope: roll over unused amount or reset to zero
83. Unallocated funds always carry over
84. Overspent envelopes carry negative balance to next month (debt to yourself)

### Notifications & Alerts
85. Alert when an envelope is 80% spent
86. Alert when an envelope is over budget
87. Spending pace warning: "At this rate, Chakula will run out in 5 days"
88. Weekly spending summary notification (Sunday evening)
89. Reminder to allocate unallocated funds (when balance sits unallocated for 3+ days)
90. Monthly report ready notification (1st of each month)
91. New income detected — nudge to allocate
92. Recurring expense upcoming reminder (2 days before)
93. Goal milestone: "50% ya lengo lako limefikiwa!" / "50% of your goal reached!"

### Family/Household Budget (inspired by Monarch & YNAB Together)
94. Share budget with spouse or family member
95. Both see the same envelopes, same spending, same balance
96. Each person's spending is tagged with their name
97. Joint allocation decisions — both can move money between envelopes
98. Individual spending summaries within the shared budget

## Key Screens

1. **Budget Home** — Wallet balance hero card, safe-to-spend number, unallocated funds warning, budget envelopes list with progress bars and pace indicators, quick actions
2. **Envelope Detail** — Transaction list for one envelope, spending chart (daily/weekly), edit allocation, move money to/from other envelopes, daily allowance
3. **Add Transaction** — Manual cash expense/income entry with envelope picker, amount, description, date
4. **Allocate Funds** — Distribute unallocated funds across envelopes, slider or amount input per envelope, shows impact on safe-to-spend
5. **Monthly Report** — Income vs spending summary, charts, envelope breakdown, month comparison, shareable card
6. **Savings Goals** — Goal list with progress rings, add/edit goals, contribute to goals, monthly target
7. **Income Breakdown** — All income sources with amounts, trends, calendar heat map
8. **Cash Flow Forecast** — 30-day projection graph, upcoming income/expenses, "what if" scenarios
9. **Recurring Expenses** — Auto-detected recurring charges, confirm/dismiss, upcoming schedule

## TAJIRI Integration Points

The budget is not a standalone feature — it's a lens across the entire TAJIRI platform. Instead of the budget module talking to 10+ services directly, two dedicated services act as the central hub for all money movement:

### Architecture: IncomeService + ExpenditureService

```
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│  Shop    │ │Subscript.│ │ Tajirika │ │ Michango │ │ Wallet   │ ...
│ (sale)   │ │ (tip)    │ │ (job)    │ │(donation)│ │(deposit) │
└────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘
     │            │            │            │            │
     ▼            ▼            ▼            ▼            ▼
┌─────────────────────────────────────────────────────────────────┐
│  IncomeService              │  ExpenditureService               │
│  (all money in)             │  (all money out)                  │
│                             │                                   │
│  Records, categorizes,      │  Records, categorizes,            │
│  notifies on every inflow   │  notifies on every outflow        │
└──────┬──────────────────────┴──────────┬────────────────────────┘
       │                                 │
  ┌────▼──┐ ┌────────┐ ┌────────┐ ┌────▼─────┐ ┌──────────┐
  │Budget │ │Shangazi│ │Reports │ │Analytics │ │Any module│
  └───────┘ └────────┘ └────────┘ └──────────┘ └──────────┘
```

**Why two dedicated services instead of direct integration:**
- Any module that needs income or spending data queries ONE service, not 10+
- New money sources (e.g., a future Loans module) only need to report to IncomeService/ExpenditureService — budget, Shangazi, reports all get it automatically
- Consistent categorization, deduplication, and notification logic lives in one place
- Budget screen doesn't need to know about ShopService, SubscriptionService, etc. — it only talks to IncomeService and ExpenditureService

### IncomeService (`lib/services/income_service.dart`) — All Money In

Central service that records and serves all income events across the platform.

**Who reports income to IncomeService:**

| Source Module | When | What Gets Recorded |
|---|---|---|
| **WalletService** | `deposit()` completes | Top-up from M-Pesa/Tigo/Airtel/bank. Source: `top_up`, provider name, amount |
| **WalletService** | `transfer()` received | Wallet-to-wallet transfer in. Source: `transfer_in`, sender name, amount |
| **WalletService** | `payRequest()` received | Payment request fulfilled. Source: `payment_received`, payer name, amount |
| **SubscriptionService** | Subscription payment received | Creator subscription revenue. Source: `creator_subscription`, subscriber name, tier, amount |
| **SubscriptionService** | `sendTip()` received | Tip income. Source: `creator_tip`, tipper name, amount |
| **SubscriptionService** | `requestPayout()` completes | Creator earnings payout. Source: `creator_payout`, amount |
| **PaymentService** | Creator fund distribution | Monthly fund payout. Source: `creator_fund`, amount, multipliers |
| **ShopService** | Order delivered/confirmed | Seller revenue. Source: `shop_sale`, order ID, product title, amount |
| **TajirikaService** | `reportJobCompleted()` | Partner job earnings. Source: `tajirika_job`, module name, job ID, amount |
| **TajirikaService** | `requestPayout()` completes | Partner earnings payout. Source: `tajirika_payout`, amount |
| **ContributionService** | `requestWithdrawal()` completes | Campaign funds withdrawn. Source: `michango_withdrawal`, campaign title, amount |
| **AdService** | `reportAdMobRevenue()` | Ad impression revenue. Source: `ad_revenue`, placement, amount |
| **LiveStreamService** | Gift received during stream | Stream gift. Source: `stream_gift`, sender name, gift name, amount |
| **EventService** | Ticket sold | Event ticket revenue. Source: `event_ticket`, event name, amount |
| **KikobaService** | Payout received | Savings group distribution. Source: `kikoba_payout`, group name, amount |

**IncomeService API:**

```dart
class IncomeService {
  // Called by source modules when income occurs
  static Future<void> recordIncome({
    required int userId,
    required double amount,
    required String source,       // top_up, creator_subscription, shop_sale, etc.
    required String description,  // human-readable: "Mauzo: Simu ya Samsung"
    String? referenceId,          // dedup key: "shop_sale_123", "tip_456"
    String? sourceModule,         // "shop", "subscription", "tajirika", etc.
    Map<String, dynamic>? metadata, // extra data (product name, campaign title, etc.)
  }) async { ... }

  // Called by consumers (budget, reports, Shangazi, etc.)
  static Future<IncomeListResult> getIncome({
    required int userId,
    String? source,               // filter by source type
    String? sourceModule,         // filter by module
    DateTime? from,
    DateTime? to,
    int page = 1,
    int perPage = 50,
  }) async { ... }

  static Future<IncomeSummary> getIncomeSummary({
    required int userId,
    required String period,       // "daily", "weekly", "monthly"
  }) async { ... }

  static Future<Map<String, double>> getIncomeBySource({
    required int userId,
    required int year,
    required int month,
  }) async { ... }

  // Recurring income detection
  static Future<List<RecurringIncome>> getRecurringIncome(int userId) async { ... }
}
```

**IncomeRecord model:**

```
IncomeRecord {
  id              → backend ID
  userId          → user who received income
  amount          → TZS amount
  source          → top_up | creator_subscription | creator_tip | creator_fund |
                    shop_sale | tajirika_job | tajirika_payout | michango_withdrawal |
                    ad_revenue | stream_gift | event_ticket | kikoba_payout |
                    transfer_in | payment_received | manual
  sourceModule    → wallet | shop | subscription | tajirika | michango | ad |
                    livestream | events | kikoba | manual
  description     → bilingual human-readable description
  referenceId     → unique dedup key (e.g., "wallet_txn_789", "shop_sale_123")
  metadata        → { productName, campaignTitle, senderName, etc. }
  date            → when income occurred
  isRecurring     → detected as recurring income (salary, regular earnings)
  createdAt       → record creation timestamp
}

IncomeSummary {
  totalIncome     → total for period
  bySource        → { "top_up": 200000, "shop_sale": 150000, ... }
  byModule        → { "wallet": 200000, "shop": 150000, ... }
  transactionCount → number of income events
  trend           → percentage change from previous period
}
```

### ExpenditureService (`lib/services/expenditure_service.dart`) — All Money Out

Central service that records and serves all spending events across the platform.

**Who reports spending to ExpenditureService:**

| Source Module | When | What Gets Recorded |
|---|---|---|
| **WalletService** | `withdraw()` completes | Cash out to M-Pesa/bank. Category: `withdrawal`, provider, amount |
| **WalletService** | `transfer()` sent | Wallet-to-wallet transfer out. Category: from transaction description |
| **WalletService** | `payRequest()` sent | Payment request paid. Category: from request description |
| **Housing Module** | Rent/housing payment | Category: `kodi`, landlord name, amount |
| **Food Module** | Food order paid | Category: `chakula`, restaurant/vendor name, order amount |
| **Transport Module** | Ride fare paid | Category: `usafiri`, ride type, amount |
| **Fuel Delivery Module** | Fuel purchased | Category: `usafiri`, fuel type, amount |
| **Bills Module** | TANESCO electricity | Category: `umeme_maji`, "TANESCO", LUKU amount |
| **Bills Module** | DAWASCO water | Category: `umeme_maji`, "DAWASCO", amount |
| **Bills Module** | Airtime/data purchase | Category: `simu_intaneti`, provider name, amount |
| **Bills Module** | Internet/WiFi subscription | Category: `simu_intaneti`, ISP name, amount |
| **Bills Module** | DSTV/Azam TV subscription | Category: `burudani`, provider, amount. Recurring = true |
| **Doctor Module** | Consultation paid | Category: `afya`, doctor/facility name, amount |
| **Pharmacy Module** | Prescription paid | Category: `afya`, pharmacy name, amount |
| **NHIF Module** | NHIF premium | Category: `afya`, "NHIF", amount. Recurring = true |
| **Fee Status Module** | School fee paid | Category: `ada_shule`, school name, fee type, amount |
| **HESLB Module** | Student loan repayment | Category: `deni`, "HESLB", amount. Recurring = true |
| **My Baby Module** | Baby products/childcare | Category: `watoto`, item description, amount |
| **WalletService** | Transfer to family member | Category: `familia`, recipient name, amount (user confirms) |
| **ShopService** | Clothing/shoes purchase | Category: `mavazi`, product title, amount |
| **ShopService** | Other product purchase | Category: `other` (user assigns), product title, amount |
| **Hair & Nails Module** | Salon/kinyozi service | Category: `urembo`, service type, amount |
| **Skin Care Module** | Skincare service/product | Category: `urembo`, service/product name, amount |
| **Fungu la Kumi / Zaka** | Church tithe / Zaka | Category: `dini`, church/mosque name, amount |
| **Church/Mosque Module** | Sadaka / offerings | Category: `dini`, description, amount |
| **ContributionService** | `donateToCampaign()` | Category: `michango`, campaign title, amount |
| **Loans Module** | Loan repayment | Category: `deni`, lender name, amount. Recurring = true |
| **Kikoba Module** | Kikoba loan repayment | Category: `deni`, group name, amount |
| **Insurance Module** | Insurance premium | Category: `bima`, insurance type, amount. Recurring = true |
| **Car Insurance Module** | Car insurance premium | Category: `bima`, "Bima ya Gari", amount. Recurring = true |
| **SubscriptionService** | `subscribe()` payment | Category: `burudani`, creator name, tier, amount. Recurring = true |
| **SubscriptionService** | `sendTip()` sent | Category: `burudani`, creator name, amount |
| **AdService** | `depositAdBalance()` | Category: `biashara`, "Ad budget", amount |
| **LiveStreamService** | `sendGift()` | Category: `burudani`, streamer name, gift name, amount |
| **EventService** | Ticket purchased | Category: `burudani`, event name, ticket price |
| **Nightlife Module** | Club/bar entry/table | Category: `burudani`, venue name, amount |
| **Games Module** | Gaming credits/betting | Category: `burudani`, game name, amount |

**ExpenditureService API:**

```dart
class ExpenditureService {
  // Called by source modules when spending occurs
  static Future<void> recordExpenditure({
    required int userId,
    required double amount,
    required String category,     // kodi, chakula, usafiri, umeme_maji, simu_intaneti,
                                  // afya, ada_shule, watoto, familia, mavazi, urembo,
                                  // burudani, dini, michango, akiba, deni, bima,
                                  // dharura, biashara, other
    required String description,  // human-readable: "Kodi ya Januari — Mkwaju Apartments"
    String? referenceId,          // dedup key: "wallet_txn_789", "order_123"
    String? sourceModule,         // "housing", "food", "transport", "shop", etc.
    String? envelopeTag,          // budget envelope to auto-assign (matches category)
    bool isRecurring = false,     // known recurring expense
    Map<String, dynamic>? metadata, // { productName, vendorName, etc. }
  }) async { ... }

  // Called by consumers (budget, reports, Shangazi, etc.)
  static Future<ExpenditureListResult> getExpenditures({
    required int userId,
    String? category,             // filter by spending category
    String? sourceModule,         // filter by module
    DateTime? from,
    DateTime? to,
    int page = 1,
    int perPage = 50,
  }) async { ... }

  static Future<ExpenditureSummary> getExpenditureSummary({
    required int userId,
    required String period,       // "daily", "weekly", "monthly"
  }) async { ... }

  static Future<Map<String, double>> getExpenditureByCategory({
    required int userId,
    required int year,
    required int month,
  }) async { ... }

  // Recurring expense detection and prediction
  static Future<List<RecurringExpense>> getRecurringExpenses(int userId) async { ... }
  static Future<List<UpcomingExpense>> getUpcomingExpenses(int userId) async { ... }

  // Spending pace
  static Future<SpendingPace> getSpendingPace({
    required int userId,
    required String category,
    required int year,
    required int month,
  }) async { ... }
}
```

**ExpenditureRecord model:**

```
ExpenditureRecord {
  id              → backend ID
  userId          → user who spent
  amount          → TZS amount
  category        → kodi | chakula | usafiri | umeme_maji | simu_intaneti |
                    afya | ada_shule | watoto | familia | mavazi | urembo |
                    burudani | dini | michango | akiba | deni | bima |
                    dharura | biashara | other
  sourceModule    → housing | food | transport | education | bills |
                    doctor | pharmacy | shop | subscription | michango |
                    ad | livestream | events | insurance | wallet | manual
  description     → bilingual human-readable description
  referenceId     → unique dedup key
  envelopeTag     → budget envelope this maps to (= category by default)
  metadata        → { vendorName, productName, etc. }
  date            → when spending occurred
  isRecurring     → detected or marked as recurring
  createdAt       → record creation timestamp
}

ExpenditureSummary {
  totalSpent      → total for period
  byCategory      → { "kodi": 150000, "chakula": 80000, ... }
  byModule        → { "housing": 150000, "food": 80000, ... }
  transactionCount → number of spending events
  trend           → percentage change from previous period
}

SpendingPace {
  category        → which envelope
  allocated       → total budget for the month
  spent           → spent so far
  remaining       → allocated - spent
  daysRemaining   → days left in month
  dailyAllowance  → remaining ÷ daysRemaining
  projectedTotal  → if current pace continues, total by month end
  status          → on_track | caution | over_budget
}
```

### How Budget Consumes These Services

The budget module becomes simple — it only talks to three services:

```dart
// Budget home screen loads:
final wallet = await WalletService().getWallet(userId);           // balance
final income = await IncomeService.getIncomeSummary(userId, 'monthly');  // total income
final spending = await ExpenditureService.getExpenditureSummary(userId, 'monthly'); // total spent
final byCategory = await ExpenditureService.getExpenditureByCategory(userId, year, month); // per envelope
final recurring = await ExpenditureService.getRecurringExpenses(userId);  // recurring bills
final upcoming = await ExpenditureService.getUpcomingExpenses(userId);    // cash flow forecast

// Safe to spend:
safeToSpend = wallet.balance - totalAllocated - sumOf(upcoming.amounts)

// Envelope spending:
for (envelope in envelopes) {
  envelope.spentAmount = byCategory[envelope.moduleTag] ?? 0;
}
```

### How Other Modules Report to These Services

Each module calls `IncomeService.recordIncome()` or `ExpenditureService.recordExpenditure()` at the moment money moves. Example:

```dart
// In ShopService.createOrder() — after successful wallet payment:
await ExpenditureService.recordExpenditure(
  userId: buyerId,
  amount: order.totalAmount,
  category: 'ununuzi',
  description: 'Ununuzi: ${product.title}',
  referenceId: 'shop_order_${order.id}',
  sourceModule: 'shop',
  metadata: {'productId': product.id, 'productTitle': product.title},
);

// In ShopService — when seller's order is confirmed:
await IncomeService.recordIncome(
  userId: sellerId,
  amount: order.totalAmount,
  source: 'shop_sale',
  description: 'Mauzo: ${product.title}',
  referenceId: 'shop_sale_${order.id}',
  sourceModule: 'shop',
  metadata: {'orderId': order.id, 'productTitle': product.title},
);
```

### Who Else Consumes These Services

| Consumer | What It Reads | Why |
|---|---|---|
| **Budget module** | Both services — income summary, expenditure by category, recurring expenses, spending pace | Core consumer — envelope tracking, safe-to-spend, forecasting |
| **Shangazi (TeaService)** | Both services — recent income/spending, summaries, pace | AI budget commentary, roasts, encouragement, spending alerts in chat |
| **Monthly Report** | Both services — full month income and expenditure data | End-of-month summary generation |
| **Analytics (EventTrackingService)** | Both services — aggregated income/spending trends | Platform-level financial health metrics |
| **Wallet screen** | Both services — recent transactions with categories | Show categorized transaction history on wallet screen |
| **Profile screen** | IncomeService — earnings summary | Show creator/partner earnings on profile |
| **Any future module** | Whichever service is relevant | No integration needed with budget directly — just report to Income/Expenditure service |

### Modules That Should Show Budget Context

The budget shouldn't only live in the budget screen. Other modules query ExpenditureService to surface budget context at the moment of decision:

| Module | Budget Context Shown |
|---|---|
| **Housing** (rent payment) | `ExpenditureService.getSpendingPace(userId, 'kodi', ...)` → "Kodi: TZS 150,000 allocated, TZS 0 spent. This payment fits your budget ✓" |
| **Food** (ordering) | `ExpenditureService.getSpendingPace(userId, 'chakula', ...)` → "Chakula: TZS 38,000 remaining (TZS 1,900/day)" |
| **Transport** (paying fare) | After payment: "Usafiri: TZS 15,000 of 30,000 used (50%)" |
| **Shop** (checkout) | At checkout: "Ununuzi: TZS 25,000 purchase. Remaining: TZS 15,000" |
| **Bills** (paying utility) | Before paying: "Bili: covers this ✓" or "⚠ TZS 5,000 zaidi inahitajika" |
| **Doctor/Pharmacy** | Before paying: "Afya: TZS 50,000 available" |
| **Events** (buying ticket) | Before buying: "Burudani: TZS 10,000 remaining. Ticket TZS 15,000 — TZS 5,000 over budget" |
| **Wallet** (transfer screen) | Show category context when sending money |

This makes the budget invisible infrastructure — users see their budget at the moment of decision, not just when they open the budget screen.

### WalletService (`lib/services/wallet_service.dart`) — The Balance Source

The wallet remains the single source of truth for actual money. Budget reads wallet balance, never duplicates it.

| Method | Role |
|---|---|
| `getWallet(userId)` | Budget hero card shows wallet balance. Golden rule: allocations ≤ balance |
| `deposit()` | Triggers `IncomeService.recordIncome()` with source = `top_up` |
| `withdraw()` | Triggers `ExpenditureService.recordExpenditure()` with category = `withdrawal` |
| `transfer()` sent | Triggers `ExpenditureService.recordExpenditure()` categorized by description |
| `transfer()` received | Triggers `IncomeService.recordIncome()` with source = `transfer_in` |
| `payRequest()` | Triggers expenditure (payer) and income (payee) |
| `calculateFee()` | Fees included in expenditure amount |

### TeaService (`lib/services/tea_service.dart`) — Shangazi AI Budget Coach

Shangazi reads from IncomeService and ExpenditureService to power AI insights:

| Method | Budget Integration |
|---|---|
| `startChat(token, message, ...)` | User asks about spending → Shangazi queries `ExpenditureService.getExpenditureSummary()` and `IncomeService.getIncomeSummary()` |
| `streamResponse(streamUrl, token)` | Delivers budget roasts, encouragement, alerts in real-time |
| `confirmAction(token, actionCardId, confirmed)` | Shangazi suggests: "Punguza Burudani kwa TZS 10,000?" → user confirms → budget envelope updated |

### LiveUpdateService (`lib/services/live_update_service.dart`) — Real-Time

| Event | Response |
|---|---|
| `ProfileUpdateEvent` | Wallet balance changed → refresh budget, recalculate safe-to-spend |
| Custom `IncomeEvent` (to add) | New income recorded → budget refreshes, unallocated increases |
| Custom `ExpenditureEvent` (to add) | New spending recorded → envelope spending updates in real-time |

### FCMService (`lib/services/fcm_service.dart`) — Push Notifications

Budget notifications triggered by IncomeService and ExpenditureService events:

| Trigger | Notification |
|---|---|
| Income recorded | "TZS 50,000 imeingia — tenga pesa zako" / "TZS 50,000 received — allocate your funds" |
| Envelope 80% spent | "⚠ Chakula: umebakiza TZS 16,000 tu" / "⚠ Food: only TZS 16,000 remaining" |
| Envelope over budget | "🔴 Usafiri umezidi bajeti kwa TZS 5,000" / "🔴 Transport over budget by TZS 5,000" |
| Spending pace warning | "Kwa kasi hii, Chakula itaisha siku 5 kabla ya mwisho wa mwezi" / "At this rate, Food runs out 5 days before month end" |
| Recurring expense upcoming | "Kodi ya TZS 150,000 inatarajiwa kesho kutwa" / "Rent of TZS 150,000 expected in 2 days" |
| Weekly digest (Sunday 6pm) | "Wiki hii: ulitumia TZS 180,000, umebaki TZS 120,000" / "This week: spent TZS 180,000, TZS 120,000 remaining" |
| Monthly report ready | "Ripoti ya mwezi imekamilika" / "Monthly report ready" |
| Goal milestone | "🎯 50% ya lengo lako 'Laptop' limefikiwa!" / "🎯 50% of your goal reached!" |
| Budget streak | "🔥 Siku 14 ndani ya bajeti!" / "🔥 14 days within budget!" |
| Unallocated 3+ days | "Una TZS 85,000 haijatengwa — tenga sasa" / "TZS 85,000 unallocated — assign now" |

### LocalStorageService (Hive)

Budget preferences stored locally:
- Envelope order and visibility
- Rollover preference per envelope
- Last viewed month
- Notification preferences
- Recurring expense confirmations
- Budget streak data
- User categorization corrections (for learning)
- Cached wallet balance for offline display
- Last sync timestamps for IncomeService/ExpenditureService

### BudgetDatabase (SQLite)

Local database for offline-first operation:
- Envelope allocations per month (with rollover tracking)
- Manual transactions (cash spending outside platform — reported to ExpenditureService on sync)
- Goal progress and contributions
- Monthly snapshots for historical comparison
- Cached income/expenditure records from services (with deduplication via `referenceId`)
- Categorization rules learned from user corrections

### EventTrackingService (`lib/services/event_tracking_service.dart`) — Budget Analytics

Track user engagement with budget features:
- `trackEvent('budget_opened', ...)` — how often users check budget
- `trackEvent('envelope_edited', {envelope: 'Chakula', newAmount: 80000})` — allocation changes
- `trackEvent('manual_txn_added', ...)` — manual transaction usage
- `trackEvent('goal_created', {name: 'Laptop', target: 800000})` — goal engagement
- `trackEvent('forecast_viewed', ...)` — cash flow forecast usage
- `trackEvent('budget_context_shown', {module: 'food', action: 'order'})` — cross-module budget context impressions

### LocalStorageService (Hive)

Budget preferences stored locally:
- Envelope order and visibility
- Rollover preference per envelope
- Last viewed month
- Notification preferences
- Recurring expense confirmations
- Budget streak data
- User categorization corrections (for learning)
- Cached wallet balance for offline display
- Last transaction sync timestamp

### BudgetDatabase (SQLite)

Local database for offline-first operation:
- Envelope allocations per month (with rollover tracking)
- Manual transactions (cash spending outside platform)
- Goal progress and contributions
- Monthly snapshots for historical comparison
- Auto-tracked transactions cached from wallet API (with deduplication via `tajiri_ref_id`)
- Recurring expense patterns and predictions
- Categorization rules learned from user corrections
- Budget streak history
- Income source aggregations per month

### EventTrackingService (`lib/services/event_tracking_service.dart`) — Budget Analytics

Track user engagement with budget features for product improvement:
- `trackEvent('budget_opened', ...)` — how often users check budget
- `trackEvent('envelope_edited', {envelope: 'Chakula', newAmount: 80000})` — allocation changes
- `trackEvent('manual_txn_added', ...)` — manual transaction usage
- `trackEvent('goal_created', {name: 'Laptop', target: 800000})` — goal engagement
- `trackEvent('forecast_viewed', ...)` — cash flow forecast usage
- `trackEvent('budget_shared', ...)` — family budget adoption

## Data Model

### BudgetEnvelope
```
BudgetEnvelope {
  id              → local SQLite ID
  name            → display name (bilingual)
  icon            → Material icon name
  color           → hex color for progress bar
  allocatedAmount → amount budgeted this month
  spentAmount     → sum of wallet transactions mapped to this envelope (auto-calculated)
  order           → display sort order
  isDefault       → one of the 10 default envelopes
  moduleTag       → wallet transaction tag for auto-mapping (e.g., "housing", "food")
  rollover        → whether unused amount rolls to next month
  rolledOverAmount → amount carried from previous month
}
```

### BudgetTransaction
```
BudgetTransaction {
  id              → local SQLite ID
  envelopeId      → which envelope this belongs to (nullable for income)
  amount          → transaction amount in TZS
  type            → income | expense
  source          → manual | wallet
  description     → human-readable description
  date            → transaction date
  tajiriRefId     → wallet transaction ID for deduplication (null for manual entries)
  moduleSource    → which TAJIRI module generated this (housing, food, transport, etc.)
  isRecurring     → detected as recurring expense
}
```

### BudgetGoal
```
BudgetGoal {
  id              → local SQLite ID
  name            → goal name
  icon            → Material icon
  targetAmount    → total amount needed
  savedAmount     → amount contributed so far
  deadline        → target completion date (optional)
}
```

### BudgetPeriod
```
BudgetPeriod {
  year            → budget year
  month           → budget month
  totalIncome     → all wallet deposits + manual income
  totalAllocated  → sum of all envelope allocations
  totalSpent      → sum of all envelope spending
  walletBalance   → wallet balance snapshot at period start
  savingsRate     → percentage of income saved
}
```

### RecurringExpense
```
RecurringExpense {
  id              → local SQLite ID
  description     → expense description (e.g., "TANESCO", "Kodi Nyumba")
  amount          → typical amount (averaged)
  envelopeId      → assigned envelope
  frequency       → monthly | weekly
  lastOccurrence  → last time this charge appeared
  nextExpected    → predicted next occurrence
  isConfirmed     → user confirmed this is recurring (vs auto-detected)
}
```

## Business Rules

1. **Wallet balance is always the truth.** Budget allocations are a local planning layer. If wallet balance drops (external withdrawal), unallocated can go negative — show a warning
2. **Envelopes cannot be allocated more than wallet balance.** Total allocations ≤ wallet balance
3. **Auto-tracked spending is read-only.** Users cannot edit amounts that came from wallet transactions. They can only reassign which envelope a transaction belongs to
4. **Manual transactions are editable and deletable.** These represent cash spending outside the platform
5. **Akiba is a reservation, not a transfer.** Money allocated to Akiba stays in the wallet but is earmarked as savings. It's protected from spending — the user must deallocate it first before spending it
6. **Monthly reset.** New month starts with fresh allocations (or rolled-over amounts). Wallet balance carries over. Unallocated = wallet balance - new allocations
7. **Offline-first.** Budget works offline using local SQLite. Syncs wallet transactions when connectivity returns
8. **Move, don't judge.** When an envelope is overspent, the system encourages moving money from another envelope (YNAB's "roll with the punches") rather than shaming the user
9. **Safe-to-spend updates in real-time.** Every transaction immediately recalculates the safe-to-spend number
10. **Recurring expenses are pre-committed.** Detected recurring expenses reduce the safe-to-spend amount even before they hit, so users don't accidentally spend money earmarked for bills
