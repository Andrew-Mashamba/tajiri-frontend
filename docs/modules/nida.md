# NIDA (National ID) — Feature Description

## Tanzania Context

NIDA (National Identification Authority / Mamlaka ya Vitambulisho vya Taifa) is the government agency responsible for registering all Tanzanian citizens and residents aged 18+ and issuing National ID cards (Kitambulisho cha Taifa). The national ID number (NIDA number) has become the primary identification for government services, banking, SIM registration, and more.

**Current system:**
- Registration requires visiting a NIDA office in person for biometric capture (fingerprints, photo, iris)
- NIDA number format: 8-digit number preceded by birth year (e.g., 19900101-12345-67890-12)
- ID cards are printed centrally and distributed through regional/district offices
- As of 2024, approximately 30+ million Tanzanians registered out of 40+ million eligible
- NIDA verification API used by banks, telecoms (SIM registration), and government agencies
- NIDA number required for: voter registration, SIM cards, bank accounts, government employment, passports, driving licenses, land registration

**Pain points:**
- Severe delays in ID card production and distribution — some wait 6-12+ months after registration
- NIDA offices overcrowded with 4-8 hour wait times common
- No way to check application status online — must visit office repeatedly
- Registration centers limited in rural areas — citizens travel 50+ km to register
- Biometric capture equipment frequently malfunctions, causing wasted trips
- Lost or damaged cards require full re-application process
- Name/data correction process extremely slow and bureaucratic
- Elderly and disabled face physical hardship at registration centers
- No appointment system — pure walk-in chaos
- Replacement cards can take even longer than first-time registration

**Recent developments:**
- Digital NIDA verification via USSD (*152*00#) for basic number validation
- Banks and telecoms use NIDA API for real-time identity verification
- Discussion of mobile NIDA registration units for rural areas
- Integration with TRA, BRELA, Immigration for cross-referencing

## International Reference Apps

1. **Aadhaar / mAadhaar (India)** — Digital national ID with biometrics for 1.3B people. App features: digital ID card, update demographics, check enrollment status, verify identity, locate enrollment centers. Gold standard for national digital ID.
2. **SingPass (Singapore)** — National digital identity platform. Login to 2,000+ government services, digital IC, verified identity for private services, face verification.
3. **MyKad (Malaysia)** — Smart national ID. Online status check, replacement application, address update, digital copy access.
4. **ID.me (US)** — Digital identity verification platform used by government agencies. Selfie + document verification, secure identity wallet.
5. **BankID (Sweden/Norway)** — National digital ID for authentication. Used for banking, government services, signing documents electronically.

## Feature List

1. **Application Status Check** — Enter registration receipt number or NIDA number to check card production and distribution status
2. **Find NIDA Office** — Map of all NIDA registration centers with addresses, hours, phone numbers, and services available
3. **Queue Estimate** — Crowdsourced or live wait time estimates at each NIDA office
4. **Required Documents Checklist** — Interactive checklist for first registration: birth certificate, Mtaa letter, passport photos, parent ID. Separate checklists for replacement, correction, and foreign resident registration
5. **Pre-Registration Form** — Fill personal details in advance to speed up in-office registration (name, DOB, parents, address, tribe, marital status)
6. **Appointment Booking** — Reserve a time slot at preferred NIDA office to avoid long queues
7. **Digital ID Preview** — View your NIDA registration details (not a replacement for physical card, but useful reference)
8. **NIDA Number Lookup** — Retrieve your NIDA number using birth certificate number or other identifying info
9. **Verification Service** — Verify someone's NIDA number (for employers, landlords, business partners) with consent
10. **Data Correction Request** — Submit requests for name spelling, date of birth, or other data corrections with supporting documents
11. **Lost/Damaged Card Report** — Report lost or stolen ID and initiate replacement application
12. **Photo Requirements Guide** — Photo specifications (size, background, format) with in-app photo capture that meets NIDA standards
13. **Registration Eligibility Check** — Determine if you're eligible (age 18+, citizenship status) and which documents you need
14. **Notification Alerts** — Push notifications when card is ready for collection, when offices have low wait times, or when mobile units visit your area
15. **Mobile Registration Unit Tracker** — Track locations and schedules of mobile NIDA registration units visiting rural areas
16. **FAQ & Help** — Common questions about NIDA process, timelines, requirements in Swahili and English
17. **Complaint Submission** — Report issues with NIDA services (corruption, delays, equipment failure) to oversight body
18. **Family Registration** — Track NIDA registration status for family members (parents, spouse, children approaching 18)

## Key Screens

- **Home** — Status check input, nearest office card, quick actions (report lost, check status)
- **Status Tracker** — Visual timeline: Registered > Biometrics Captured > Card Printing > Card at Office > Collected
- **Office Finder** — Map view with NIDA offices, distance, wait times, and operating hours
- **Document Checklist** — Interactive checklist with document descriptions and where to get each
- **Pre-Registration** — Multi-step form matching NIDA registration fields
- **Appointment** — Calendar with available slots at selected office
- **Digital ID View** — Card-style display of registered details (for reference only)
- **Correction Request** — Form for data corrections with document upload
- **Complaint Form** — Structured complaint submission with tracking
- **Help Center** — FAQ, process guides, contact information

## TAJIRI Integration Points

- **WalletService** — `deposit(amount, provider:'mpesa')` for NIDA fees (replacement card, express processing); `getTransactions()` for payment receipts
- **NotificationService + FCMService** — Push alerts for card production status updates, office queue alerts, mobile registration unit schedules in your area
- **LocationService** — `getRegions()`, `getDistricts()`, `getWards()` for nearest NIDA office finder; GPS tracking for mobile registration unit locations
- **PhotoService** — `uploadPhoto()` for in-app photo capture meeting NIDA specifications (size, background, format); document upload for supporting materials
- **ProfileService** — `getProfile()` for NIDA verification badge as part of TAJIRI identity verification; verified ID status displayed on user profile
- **CalendarService** — `createEvent()` for appointment reminders at NIDA offices, mobile unit visit schedules
- **LocalStorageService** — Offline caching of document checklists, FAQ content, photo requirements guide, and office locations
- **MediaCacheService** — Cache registration receipt copies and supporting document scans
- **EventTrackingService** — Analytics on registration completion rates, average wait times, mobile unit coverage
- **FriendService** — `getFriends()` for family registration tracking — monitor NIDA status of family members approaching age 18
- **Cross-module: rita** — Birth certificate required for NIDA registration; cross-check RITA certificate status before NIDA application
- **Cross-module: passport** — NIDA number required for passport application; verify NIDA status before passport process
- **Cross-module: tra** — NIDA number linked to TIN for tax services; auto-suggest TIN registration after NIDA completion
- **Cross-module: brela** — NIDA required for business registration as director/shareholder; verification during company formation
- **Cross-module: driving_licence** — NIDA card required for driving licence application at LATRA
- **Cross-module: land_office** — NIDA verification for land ownership checks and property transfer processes
- **Cross-module: nhif** — NIDA number for NHIF membership enrollment and verification
- **Cross-module: nssf** — NIDA verification for NSSF member identity and benefit claims
