# NHIF (Health Insurance) — Feature Description

## Tanzania Context

NHIF (National Health Insurance Fund / Mfuko wa Taifa wa Bima ya Afya) is Tanzania's mandatory health insurance scheme for public sector employees and voluntary scheme for private sector and informal workers. NHIF was established in 1999 and began operations in 2001.

**Coverage and membership:**
- Mandatory for all public sector employees (central and local government)
- Voluntary enrollment for private sector employees, self-employed, farmers, informal workers
- Members contribute 3% of salary (employer matches 3%) = 6% total for formal sector
- Informal sector: fixed monthly contributions (TZS 30,000-150,000 depending on package)
- Covers member, spouse, and up to 4 dependents (children under 21, or 25 if students)
- Approximately 4 million members covering ~9 million beneficiaries (out of 65M population)
- iNHIF: improved voluntary package launched for informal sector

**Benefits covered:**
- Outpatient consultations and treatment
- Inpatient hospitalization
- Surgery and surgical procedures
- Maternity services (antenatal, delivery, postnatal)
- Diagnostic tests (lab, X-ray, ultrasound, CT scan)
- Prescribed medications (from NHIF drug list)
- Optical services (eye tests, basic glasses)
- Dental services (basic)
- Physiotherapy and rehabilitation
- Chronic disease management (diabetes, hypertension, HIV)

**Pain points:**
- Only ~14% of population covered — vast majority have no insurance
- NHIF-accredited facilities often out of stock on medications, forcing members to buy privately
- Claim process for referral hospitals bureaucratic and slow
- Many private hospitals refuse NHIF or charge top-up fees (officially not allowed)
- Membership verification at hospitals is manual and slow
- Contribution payments for informal sector hard to maintain consistently
- Benefit package limitations confuse members — what's covered vs not covered unclear
- NHIF card replacement takes weeks
- Rural health facilities have limited NHIF services
- Dependents management (adding/removing) requires office visits

**Recent developments:**
- Universal Health Insurance (UHI) bill under discussion to expand coverage
- NHIF digital card under development
- Integration with mobile money for premium payments
- Expansion of accredited facility network

## International Reference Apps

1. **Oscar Health (US)** — Digital-first health insurance: find doctors, telemedicine, claims tracking, cost estimates, digital ID card. Consumer-friendly design.
2. **MyChart (US/Global)** — Patient portal: view coverage, find in-network providers, see claims, manage family members, schedule appointments.
3. **Livi/Kry (Europe)** — Digital health insurance with telemedicine, doctor booking, prescription management, insurance card.
4. **mTiba (Kenya)** — Mobile health wallet: save for health expenses, NHIF payments, find facilities, digital health records.
5. **Aarogya Setu (India)** — Government health app with insurance integration, facility finder, health records, vaccination tracking.

## Feature List

1. **Membership Verification** — Check NHIF membership status using member number or NIDA number, view validity period
2. **Digital Member Card** — Display NHIF membership details with QR code for facility verification (member + dependents)
3. **Find Accredited Facilities** — Map and list of NHIF-accredited hospitals, clinics, pharmacies, and labs with services offered
4. **Facility Ratings** — Community ratings of accredited facilities on NHIF service quality, drug availability, wait times
5. **Benefits Guide** — Complete list of covered services, medications, procedures with clear limits and exclusions
6. **Claims History** — View all claims made against your membership: dates, facilities, services, amounts
7. **Premium Payment** — Pay monthly NHIF contributions via M-Pesa with payment history and receipt
8. **Contribution History** — View all premium payments: dates, amounts, employer contributions, gaps in coverage
9. **Dependents Management** — Add, remove, or update dependents (spouse, children) with required documents
10. **Benefits Calculator** — Estimate coverage for specific procedures or conditions based on your plan
11. **Pre-Authorization Check** — Check if a planned procedure requires pre-authorization and initiate request
12. **Referral Tracking** — Track hospital referral chain: primary > district > regional > referral hospital
13. **Drug List** — Searchable NHIF formulary: which medications are covered and at what level
14. **Complaint System** — Report facilities refusing NHIF, charging top-up fees, or providing poor service
15. **iNHIF Enrollment** — Sign up for voluntary NHIF coverage for informal sector workers with package comparison
16. **Coverage Gap Alert** — Notification when contributions are late or coverage about to lapse
17. **Family Health Dashboard** — Overview of all covered family members with usage summary
18. **Nearest Pharmacy** — Find NHIF-accredited pharmacies with medication availability indicators
19. **Health Tips** — Preventive health content: nutrition, exercise, disease prevention, maternal health
20. **NHIF Office Finder** — NHIF regional offices with contacts, hours, and services

## Key Screens

- **Home** — Digital member card, coverage status, quick find facility, payment due alert
- **Member Card** — Full-screen QR-enabled digital card with member and dependents details
- **Facility Finder** — Map view with accredited facilities, filters (type, specialty, distance), directions
- **Benefits** — Categorized coverage guide with search and common questions
- **Claims History** — Chronological claims list with facility, service, and amount details
- **Pay Premium** — Current balance, amount due, M-Pesa payment flow, receipt
- **Dependents** — Family member cards with add/edit/remove actions
- **Drug List** — Searchable medication formulary with coverage level indicators
- **Complaints** — Structured complaint form with facility selection and issue categories
- **Enrollment** — Package comparison, contribution calculator, sign-up flow for new members

## TAJIRI Integration Points

- **WalletService** — `deposit(amount, provider:'mpesa')` for monthly NHIF premium payments (TZS 30,000-150,000 informal sector); `getTransactions()` for contribution history and payment receipts; auto-pay setup for recurring premiums
- **MessageService** — `sendMessage()` for contacting NHIF support or accredited facilities; `getConversations()` for tracking claim-related communications
- **NotificationService + FCMService** — Push alerts for payment due dates, coverage expiry warnings, claim status updates, coverage gap alerts when contributions are late
- **CalendarService** — `createEvent()` for premium payment reminders, appointment dates at accredited facilities, referral follow-up dates
- **LocationService** — `getRegions()`, `getDistricts()` for GPS-based nearest accredited facility finder (hospitals, clinics, pharmacies, labs)
- **ProfileService** — `getProfile()` for health insurance status badge on TAJIRI profile; membership verification display; user data from `RegistrationState` for enrollment
- **PhotoService** — `uploadPhoto()` for claim documents, referral letters, medical reports, prescription uploads
- **LocalStorageService** — Offline caching of NHIF drug formulary, benefits guide, accredited facility list, emergency contacts
- **MediaCacheService** — Cache digital member card, claim documents, and referral letters for hospital visits without connectivity
- **LiveUpdateService** — Real-time claim status tracking via Firestore and pre-authorization request updates
- **FriendService** — `getFriends()` for family dependents management — track coverage for spouse and up to 4 children
- **EventTrackingService** — Analytics on facility usage, claim patterns, drug availability reports
- **Cross-module: doctor/** — NHIF-accredited doctors listed in TAJIRI doctor finder; check if hospital/clinic is accredited before booking
- **Cross-module: pharmacy/** — NHIF-accredited pharmacies with medication availability; drug formulary cross-reference
- **Cross-module: insurance/** — NHIF as part of comprehensive insurance overview; gap analysis for supplementary private insurance
- **Cross-module: nida** — NIDA number for membership verification and enrollment
- **Cross-module: nssf** — Both social protection schemes viewable together for comprehensive coverage picture (health + pension)
- **Cross-module: my_family/** — Family dependents synced with TAJIRI family module; dependent add/remove management
