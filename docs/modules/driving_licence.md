# Leseni (Driving Licence) — Feature Description

## Tanzania Context

Driving licences in Tanzania are managed by LATRA (Land Transport Regulatory Authority), which took over from SUMATRA in 2019. The driving licence system has been digitized with smart card licences replacing older paper versions.

**Licence classes:**
- Class A — Motorcycles (Pikipiki)
- Class B — Light vehicles up to 3,500 kg (most common)
- Class C — Vehicles 3,500-15,000 kg
- Class D — Vehicles over 15,000 kg (trucks, buses)
- Class E — Articulated vehicles (trailers)
- Class F — Special vehicles (forklifts, tractors)
- Each class can be provisional (Learner) or full

**Current process for new licence:**
1. Enroll at a registered driving school (6-8 weeks typical, TZS 200,000-500,000)
2. Obtain medical fitness certificate from registered doctor
3. Apply at LATRA office with: driving school certificate, medical certificate, NIDA card, passport photos
4. Take theory test (road signs, traffic rules) at LATRA
5. Take practical driving test at designated route
6. Pay licence fee (TZS 40,000 for 2-year provisional, TZS 60,000 for 5-year full)
7. Receive smart card licence

**Pain points:**
- Driving schools vary wildly in quality — some issue certificates without proper training
- Theory test has limited study materials in Swahili
- Practical test prone to corruption — "passing fee" (bribes) common
- Licence renewal requires visiting LATRA office in person
- International driving permits hard to obtain
- Traffic fines and points system poorly communicated to drivers
- No online renewal or status check despite smart card technology
- Motorcycle (bodaboda) riders often operate without licences due to process complexity
- Road safety education severely lacking — Tanzania has one of Africa's highest road fatality rates
- Foreign licence conversion process unclear and inconsistent

## International Reference Apps

1. **DVLA App (UK)** — Check driving licence details, view penalty points, check MOT status, tax vehicle. Simple, effective government app.
2. **Parivahan (India)** — RTO services: licence application, renewal, status tracking, driving school directory, fee payment. Serves 1B+ people.
3. **mLearner (South Africa)** — Learner's licence test preparation with practice questions, road signs, and mock exams.
4. **ServiceNSW Driving (Australia)** — Book driving tests, renew licence, check demerit points, log learner hours, find driving instructors.
5. **Zutobi (Global)** — Theory test preparation with gamified learning, practice tests, road sign flashcards. Available in multiple countries.

## Feature List

1. **Licence Application Guide** — Step-by-step process for each licence class with timeline, costs, and requirements
2. **Driving School Directory** — Find LATRA-registered driving schools by location with ratings, prices, class offerings, and contact info
3. **Theory Test Preparation** — Practice questions in Swahili and English covering road signs, traffic rules, right-of-way, safety procedures
4. **Road Signs Flashcards** — All Tanzania road signs with meanings, categories (warning, regulatory, informational), and quiz mode
5. **Mock Theory Exam** — Timed practice exams simulating actual LATRA theory test format and difficulty
6. **Required Documents Checklist** — Interactive checklist for each licence class: medical certificate, driving school certificate, NIDA, photos
7. **Application Status Tracker** — Track licence application from submission through testing to card issuance
8. **Licence Renewal** — Initiate renewal process, check expiry, upload updated documents, pay fees
9. **Renewal Reminders** — Push notifications at 3 months, 1 month, and 2 weeks before expiry
10. **Fines & Points Check** — View outstanding traffic violations, fines, and penalty points against your licence
11. **Fine Payment** — Pay traffic fines via M-Pesa / TAJIRI wallet with receipt
12. **Medical Certificate Guide** — Requirements for driving medical exam, list of approved doctors/hospitals
13. **Licence Class Upgrade** — Process and requirements for adding a new vehicle class to existing licence
14. **International Driving Permit** — Application guide and process for obtaining IDP for driving abroad
15. **Foreign Licence Conversion** — Guide for converting foreign driving licences to Tanzanian licence
16. **Road Safety Tips** — Defensive driving tips, night driving safety, rainy season driving, bodaboda safety
17. **Traffic Rules Reference** — Complete traffic law reference: speed limits, overtaking rules, parking, signals, penalties
18. **Practical Test Tips** — What to expect during practical driving test: route types, common mistakes, scoring criteria
19. **Driving Log** — Learner drivers can log practice hours, routes, and conditions for tracking progress
20. **LATRA Office Finder** — Map of LATRA offices with services, hours, test schedules, and contacts
21. **Insurance Reminder** — Check vehicle insurance status, renewal reminders (cross-module with insurance)

## Key Screens

- **Home** — Licence card display, expiry countdown, fine alerts, quick actions
- **Application Guide** — Visual step-by-step process with class selection
- **Driving Schools** — Map/list view with filters (location, price, class, rating)
- **Theory Prep** — Topic browser, practice questions, mock exams, progress tracker
- **Road Signs** — Categorized sign gallery with quiz mode
- **Track Application** — Status timeline with estimated dates
- **Fines & Points** — Outstanding violations list with payment action
- **Renewal** — Expiry check, document update, fee payment flow
- **Traffic Rules** — Browseable reference with search
- **Office Finder** — Map with LATRA locations, test schedules, queue info

## TAJIRI Integration Points

- **WalletService** — `deposit(amount, provider:'mpesa')` for licence fees (TZS 40,000-60,000), traffic fine payments, renewal fees, and driving school payments; `getTransactions()` for payment history and fine receipts
- **NotificationService + FCMService** — Push alerts for licence expiry reminders (3 months, 1 month, 2 weeks), outstanding fine alerts, application status updates, test date reminders
- **CalendarService** — `createEvent()` for theory/practical test dates, renewal deadlines, driving school schedule
- **LocationService** — `getRegions()`, `getDistricts()` for GPS-based nearest LATRA office and driving school finder
- **ProfileService** — `getProfile()` for verified driver status on TAJIRI platform; user data from `RegistrationState` for application pre-fill
- **PhotoService** — `uploadPhoto()` for passport photos, medical certificate scans, driving school certificate uploads
- **LocalStorageService** — Offline caching of road signs flashcards, traffic rules reference, theory test practice questions, error code guides
- **MediaCacheService** — Cache digital licence copy, certificates, and test results
- **LiveUpdateService** — Real-time application status tracking via Firestore (Submitted > Theory Test > Practical Test > Card Issuance)
- **GroupService** — `createGroup()` for driving learner communities, road safety discussion groups; `joinGroup()` for motorcycle safety forums
- **PostService** — `createPost()` for sharing road safety tips, traffic rule updates, driving school reviews
- **EventTrackingService** — Analytics on theory test pass rates, practical test booking patterns
- **Cross-module: nida** — NIDA card required for licence application; verification link to check NIDA readiness
- **Cross-module: my_cars/** — Driving licence linked to vehicle ownership tabs; licence class matched to registered vehicles
- **Cross-module: transport/** — Driving licence verification for ride-sharing and delivery features
- **Cross-module: insurance/** — Cross-reference vehicle insurance status with licence; insurance reminder integration
- **Cross-module: tira** — Vehicle insurance (third-party mandatory) linked to licence and vehicle registration
- **Cross-module: latra** — LATRA regulatory compliance for commercial drivers; PSV licence requirements
- **Cross-module: legal_gpt** — Traffic law questions, fine dispute guidance, accident liability explanations
