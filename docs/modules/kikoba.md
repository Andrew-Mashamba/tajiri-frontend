# Kikoba — VICOBA Digital Savings Groups

## Tanzania Context

VICOBA (Village Community Banking) is Tanzania's most widespread grassroots financial system. Millions of Tanzanians participate in kikoba (savings groups) — member-owned cooperatives of 10-30 people, typically from the same neighbourhood, church, or workplace. Members contribute fixed shares (Hisa) and fees (Ada) on a regular schedule, pool the capital, and lend it back to members at an interest rate defined in the group's constitution (Katiba). At the end of a term (typically one year), profits are shared proportionally based on shares held.

Currently, most vikoba operate with paper ledgers and WhatsApp coordination — leading to disputes, lost records, and limited transparency. TAJIRI's Kikoba module digitizes the entire VICOBA workflow: group creation, member management, contributions, loans, governance via democratic voting, and financial reporting.

### Key Swahili Terms

| Term | Meaning |
|---|---|
| **Kikoba** (pl. Vikoba) | Savings group |
| **Hisa** | Share/stake contribution (monthly buy-in) |
| **Ada** | Membership subscription fee |
| **Kiingilio** | Joining/registration fee |
| **Akiba** | Savings deposit |
| **Riba** | Interest rate on loans |
| **Faini** | Penalty/fine |
| **Katiba** | Group constitution (rules) |
| **Vikao** | Meetings |
| **Mchango** (pl. Michango) | Special contribution/collection |
| **Mkopo** (pl. Mikopo) | Loan(s) |
| **Mdhamini** | Guarantor |
| **Mwanachama** | Member |
| **Baraza** | Assembly/discussion forum |
| **Majukumu** | Roles/responsibilities |
| **Mahesabu** | Accounts/financial records |
| **Uongozi** | Leadership |
| **Wajibu** | Duties/voting obligations |
| **Cheo** | Role/rank within group |

## How It Works

```
┌─────────────────────────────────────────────┐
│              VICOBA GROUP                    │
│                                             │
│  Members (10-30)                            │
│  ├── Chairman, Secretary, Treasurer         │
│  ├── Regular members                        │
│  └── Each has: Hisa, Ada, Akiba balances    │
│                                             │
│  Monthly Cycle:                             │
│  1. Members pay Ada (fees) + buy Hisa       │
│  2. Capital pool grows                      │
│  3. Members can borrow (Mkopo)              │
│  4. Loans repaid with Riba (interest)       │
│  5. Interest grows the pool further         │
│  6. Year-end: profits shared per Hisa       │
│                                             │
│  Governance:                                │
│  Every decision requires democratic vote    │
│  - Loan approval                            │
│  - New member admission                     │
│  - Member removal                           │
│  - Constitution changes                     │
│  - Expense approvals                        │
│  - Fine impositions                         │
└─────────────────────────────────────────────┘
```

## Architecture

### Backend
- **API:** `https://vicoba.zimasystems.com/api/` — dedicated Laravel backend (separate from TAJIRI's main backend)
- **70+ API endpoints** covering groups, members, payments, loans, voting, constitution, chat
- **No bearer token auth** — identity carried via `currentUserId` and `KikobaId` in request bodies

### Firebase (Secondary Project)
- **Project:** `vicoba-c89a7` — separate from TAJIRI's primary Firebase
- **Firestore:** Real-time voting case notifications (collection: `{kikobaId}VotingCases`)
- **Realtime Database:** Group chat messages (path: `{path}/messages`)
- **Auth:** Anonymous sign-in only

### Local Storage
- **SQLite** (`vicoba.db`) — user session, device info, bank details
- **SharedPreferences** — cache for dashboard (10min TTL), members, baraza, katiba, mahesabu, vikoba list
- **Offline queues** — vote queue and chat message queue for offline operation

### State Management
- Global mutable `DataStore` singleton with 80+ static fields
- No Provider/Bloc/Riverpod — direct setState on state changes

### TAJIRI Integration
- **Bridge login:** `POST /api/tajiri-bridge-login` — maps TAJIRI phone + userId to VICOBA userId
- **Entry:** `KikobaModule(userId)` mounted as profile tab
- **Auth:** Gets phone/name from TAJIRI's `LocalStorageService` at init
- **Wallet:** NOT integrated — payments go through VICOBA's own payment processor (MNO, card, bank)

## Feature List

### Group Management
1. Create a new kikoba group (name, description, location, image)
2. Search for existing groups by ID or name
3. Request to join a group (requires member voting)
4. Group profile and settings
5. Upload/change group image
6. Set end-of-term date

### Member Management
7. Add members by phone number or from device contacts
8. Member roles: Chairman, Secretary, Treasurer, Regular member
9. Member removal (requires democratic vote — voluntary, disciplinary, inactive, deceased)
10. View member roster with roles and balances
11. Member passbook (individual transaction history)
12. FCM notification on member events

### Financial Operations — Contributions
13. **Hisa (Shares):** Fixed monthly share purchase, amount defined in Katiba
14. **Ada (Fees):** Monthly membership fee, amount defined in Katiba
15. **Kiingilio (Entry Fee):** One-time joining fee for new members
16. **Akiba (Savings):** Additional savings deposits beyond Hisa
17. **Akiba Withdrawal:** Request savings withdrawal (requires group voting)
18. **Mchango (Special Contributions):** Event-based collections (funeral, wedding, graduation)
19. **Proxy Mchango:** On-behalf-of contributions (requires voting)

### Financial Operations — Loans
20. **Loan Products:** Configurable via Katiba (min/max amount, interest rate, tenure, charges)
21. **Loan Application:** Multi-step wizard (product → amount → charges → guarantors → schedule → submit)
22. **Guarantor System:** Members guarantee each other's loans, approve/reject via app
23. **Loan Voting:** Group votes on loan approval after guarantors approve
24. **Loan Disbursement:** Funds sent via mobile money after approval
25. **Loan Repayment:** Pay via MNO, card, or bank; schedule tracking
26. **Loan Top-Up:** Additional borrowing on existing loan
27. **Loan Lifecycle:** draft → guarantor_pending → pending_approval → approved → disbursed → active → closed/defaulted

### Financial Operations — Fines
28. **Fine Types:** Late Ada (faini_ada), late Hisa (faini_hisa), missed meetings (faini_vikao), missed contributions (faini_michango)
29. **Fine Imposition:** Requires voting approval
30. **Fine Payment:** Pay via MNO/card/bank
31. **Fine Waiver:** Leadership can waive a fine (requires voting)
32. **Fine Calculation:** Backend auto-calculates based on Katiba rules

### Governance — Voting System
33. **10 voteable types:** membership_request, membership_removal, loan_application, akiba_withdrawal, expense_request, fine_approval, mchango, proxy_mchango, katiba_change, voting_case (general)
34. **Democratic voting:** Each member votes Yes/No/Abstain
35. **Configurable thresholds:** Approval %, rejection %, minimum votes, leadership weight (2x)
36. **Auto-processing:** When threshold met, decision auto-executes
37. **Real-time updates:** Firestore listeners push voting changes to all members instantly
38. **Offline voting:** Votes queued when offline, synced on reconnect
39. **General voting cases:** Yes/no or multiple-choice items for any group decision
40. **Katiba changes require voting:** Any change to fees, interest rates, fine rules → creates voting case

### Constitution (Katiba)
41. **Configurable rules:** Hisa amount, Ada amount, Kiingilio, Riba (interest), tenure, fine amounts
42. **Loan products:** Multiple products with different terms
43. **Direct save (admin):** Some settings can be changed without voting
44. **Change proposals:** Changes requiring vote create katiba_change voting case
45. **View constitution:** Members can read all group rules

### Dashboard & Reporting
46. **Personal dashboard:** Ada balance, Hisa balance, Akiba balance, active loans, pending contributions
47. **Quick actions:** Pay Ada, buy Hisa, deposit Akiba, request loan
48. **Financial summary cards:** Running totals with trends
49. **Full ledger (Mahesabu):** Sub-tabs for Ada, Hisa, Akiba, Mikopo, Michango transactions
50. **Group balance:** Total group capital pool
51. **Member passbook:** Individual transaction history

### Communication
52. **Group chat:** Firebase Realtime Database messaging within each group
53. **Baraza (Discussion Board):** Group notices and announcements
54. **FCM push notifications:** New loan requests, membership requests, meeting notices, voting reminders
55. **Topic-based FCM:** Members auto-subscribe to group topics on entry

### Payments
56. **MNO (Mobile Money):** M-Pesa, Airtel Money, Tigo Pesa — STK push
57. **Credit/Debit Card:** PAN entry with animated card widget
58. **Bank Transfer:** Letshego integration with TIPS/TISS routing
59. **Control Numbers:** Generated for bank counter payments
60. **Payment Status:** Real-time tracking of payment processing

### Offline Support
61. **SQLite session:** User data persists across restarts
62. **SharedPreferences caching:** 10-minute TTL for dashboard, members, accounts
63. **Offline vote queue:** Votes processed on reconnect
64. **Offline chat queue:** Messages sent on reconnect
65. **Cache-first loading:** Cached data shown instantly, API refresh in background

## Key Screens

### Navigation Structure

```
KikobaModule (init + bridge login)
└── VikobaListPage (user's groups)
    └── getKikobaData (loading → replaces self)
        └── tabshome (5-tab hub for one group)
            ├── Tab 1: Baraza (discussion board)
            ├── Tab 2: Dashboard (personal summary + quick actions)
            ├── Tab 3: Mahesabu (accounts — Ada/Hisa/Akiba/Mikopo/Michango tabs)
            ├── Tab 4: Wanachama (members roster + roles)
            └── Tab 5: Katiba (constitution viewer/editor)
            + Voting bottom sheet (Wajibu — overlays any tab)
```

### Screen List
1. **VikobaListPage** — User's groups with cached list, pull-to-refresh, search/create actions
2. **tabshome** — 5-tab shell: Baraza, Dashboard, Mahesabu, Wanachama, Katiba + voting overlay
3. **DashboardScreen** — Personal financial summary, quick action buttons, cached with Firestore invalidation
4. **Mahesabu** — Full ledger with sub-tabs per financial type
5. **Members** — Roster with roles, passbook access
6. **Katiba** — Constitution viewer, rule editor (with voting for changes)
7. **Baraza** — Discussion board / notices
8. **MikopoPage** — Multi-step loan application wizard
9. **LoanDetailPage** — Loan detail with schedule, payments, guarantors, timeline
10. **VotingListScreen** — All voting items with status
11. **VotingDetailScreen** — Single vote with cast-vote UI
12. **Chat pages** — Group chat (conversations list, chat room, new chat)
13. **Payment flow** — Method selection → phone/card/bank entry → status
14. **sajiriKikoba** — Create new group wizard
15. **searchForKikoba** — Search/join existing group
16. **addMjumbe** — Add member (phone or contacts)
17. **kikobaProfile** — Group profile and settings

## TAJIRI Integration Points

### Current Integration
- **LocalStorageService** — reads phone number and user name at init for bridge login
- **Profile Tab** — `KikobaModule(userId)` rendered as the Kikoba tab in profile grid

### Future Integration Opportunities
- **TAJIRI Wallet** — Route kikoba payments through TAJIRI Wallet instead of direct MNO (wallet-to-wallet within pool account)
- **IncomeService** — Record kikoba payouts (end-of-term profit share) as income
- **ExpenditureService** — Record Ada/Hisa contributions as expenditure (category: `michango` or dedicated `kikoba`)
- **Budget Module** — Kikoba contributions as a budget envelope (Deni for loan repayments, Michango for contributions)
- **Messaging** — Bridge kikoba chat to TAJIRI messaging
- **Groups** — Surface kikoba groups in TAJIRI's group system
- **Events** — Vikao (meetings) as TAJIRI calendar events
- **Notifications** — Unify kikoba FCM with TAJIRI notification system

## Data Models

### vicoba (Group)
```
id, kikobaid, kikobaname, creatorid, creatorname, creatorphone,
password, reg_date, maelezokuhusukikoba (description), location,
membersNo, endOfTermDate, kikobaImage, membershipStatus, requestId,
source, groupAccountNumber?, groupBankName?, groupBankCode?
```

### DataStore (Global State — 80+ fields)
```
currentUserId, currentKikobaId, currentKikobaName, userNumber,
userCheo (role), myVikobaList, membersList, hisaList, akibaList,
mikopoList, barazaList, casesList, loanProducts,
financial settings (ada, hisa, kiingilio, riba, tenure, faini rates),
payment state (paymentService, paymentChanel, paymentAmount),
control numbers (controlNumbersAda/Hisa/Akiba)
```

### LoanApplication
```
applicationId, kikobaId, userId, applicantName, applicantPhone,
loanProduct (LoanProduct), loanType (new/topup),
loanDetails (LoanDetails), calculations (LoanCalculations),
status (14 lifecycle states), guarantors (List<Guarantor>),
charges (List<LoanCharge>), voting (LoanVotingSummary),
audit trail (approvedDate, rejectedAt, disbursedDate, etc.)
```

### Voting Models (10 types)
```
VoteableType enum: membership_request, membership_removal,
  loan_application, akiba_withdrawal, expense_request,
  fine_approval, mchango, proxy_mchango, katiba_change, voting_case

VotingConfig: approvalThreshold, rejectionThreshold,
  minimumVotes, leadershipWeight, autoProcess

CastVoteResult: success, votingSummary, autoProcessed
```

## Known Issues

### Architecture
- **DataStore singleton** — 80+ mutable static fields, no reactivity, race condition risk
- **HttpService monolith** — 9,400+ lines in one file, handles all API logic
- **Mixed content-types** — some endpoints use form-encoded, others JSON
- **Duplicate endpoints** — e.g., `createPaymentIntentMNO` vs `createPaymentIntentMNOx`
- **Legacy methods** — old endpoints (`futaMtu`, `ombaMchango`) coexist with typed replacements

### Code Quality
- **`home.dart` is dead code** — legacy standalone app entry, no longer used
- **Hardcoded defaults in DataStore** — development phone numbers and IDs as initial values
- **Swahili-only text** — most UI text lacks English fallback (needs bilingual audit)
- **Missing error feedback** — some API calls silently swallow errors

### Navigation (Fixed)
- ~~pushReplacement/pushAndRemoveUntil destroyed back stack~~ — Fixed: now uses push/pop correctly
- ~~Double AppBar on VikobaListPage~~ — Fixed: removed AppBar from tab-rendered page
- ~~Loading page (getKikobaData) visible on back navigation~~ — Fixed: uses pushReplacement to skip it

## Backend Server

| Item | Value |
|------|-------|
| Server | `vicoba.zimasystems.com` |
| API Base | `https://vicoba.zimasystems.com/api/` |
| Framework | Laravel |
| Firebase Project | `vicoba-c89a7` |
| 70+ API endpoints | Groups, members, payments, loans, voting, constitution, chat |
