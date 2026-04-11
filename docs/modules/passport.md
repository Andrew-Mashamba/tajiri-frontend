# Passport (Pasipoti) — Feature Description

## Tanzania Context

Passport services in Tanzania are managed by the Immigration Department (Idara ya Uhamiaji) under the Ministry of Home Affairs. Tanzania issues e-Passports compliant with ICAO standards since 2018, replacing the older machine-readable passports.

**Passport types:**
- Ordinary Passport (Pasipoti ya Kawaida) — 32 or 64 pages, valid 5 or 10 years
- Diplomatic Passport (Pasipoti ya Kidiplomasia)
- Service/Official Passport (Pasipoti ya Utumishi)
- Emergency Travel Document (for Tanzanians stranded abroad)
- East African Passport (for travel within EAC member states)

**Current process:**
1. Fill application form online at immigration website or collect physical form
2. Gather documents: NIDA card, birth certificate, filled form, passport photos, recommendation letter from employer/ward
3. Submit at Immigration offices (Dar es Salaam HQ, regional offices, or embassies)
4. Pay fee: TZS 150,000 (32 pages/5 years), TZS 250,000 (64 pages/10 years), TZS 300,000 (express)
5. Biometric capture at office (fingerprints, photo)
6. Wait for processing: officially 10-14 working days, often 3-8 weeks
7. Collect from submission office

**Pain points:**
- Online application form frequently inaccessible or broken
- Physical submission still required — long queues at immigration offices, especially Dar es Salaam
- Processing delays of 1-3 months common, especially during peak travel seasons
- No reliable way to track application status — must call or visit
- Express processing advertised but not consistently available
- Passport photos rejected frequently for minor issues (background shade, head position)
- Renewal requires completely new application — no simplified process
- Children's passports require both parents' consent, problematic for single parents
- Regional offices have limited processing capacity
- Lost passport replacement process lengthy and requires police report, affidavit

## International Reference Apps

1. **UK Passport App** — Check photo suitability using AI, track application, receive push notifications, renew online end-to-end. UK gold standard.
2. **US Travel.gov / myTravelGov** — Application status tracking, appointment scheduling, photo tool, fee calculator, nearest office finder.
3. **India Passport Seva App** — Track application, appointment booking, fee calculator, document advisor, find nearest Passport Seva Kendra.
4. **Australia myGov Passport** — Online renewal, photo upload, status tracking, digital identity verification.
5. **iVisa (Global)** — Visa and passport services marketplace: application assistance, photo tool, requirements checker by destination.

## Feature List

1. **Application Guide** — Step-by-step guide for first-time applicants, renewals, and child passports with visual instructions
2. **Document Checklist** — Interactive checklist: NIDA card, birth certificate, photos, recommendation letter, police report (for lost), marriage certificate (for name change)
3. **Photo Tool** — Take passport photos in-app with AI guide for compliance: head position, background check, expression, glasses, hijab guidelines
4. **Application Form Pre-Fill** — Fill out passport application form digitally, generate printable version for submission
5. **Track Application** — Enter application number to check processing status with stage indicators
6. **Fee Calculator** — Calculate exact fees based on passport type, page count, validity, and processing speed
7. **Office Finder** — Map of immigration offices and regional passport offices with hours, contacts, and services
8. **Appointment Booking** — Reserve submission time slot at preferred immigration office
9. **Queue Status** — Live or crowdsourced wait time estimates at each office
10. **Renewal Reminder** — Push notifications when passport expires within 6 months, 3 months, 1 month
11. **Child Passport Guide** — Special guide for children's passports: both parent consent, guardianship documents, age-specific requirements
12. **Lost Passport Guide** — Steps for reporting lost/stolen passport: police report, affidavit, emergency travel document
13. **Visa Requirements Checker** — Select destination country to see visa requirements for Tanzanian passport holders (visa-free, visa on arrival, visa required)
14. **Travel Advisory** — Safety and health advisories for destination countries
15. **Emergency Contacts Abroad** — Tanzania embassy and consulate directory worldwide with contact info
16. **Processing Time Estimator** — Estimated processing time based on office, season, and application type
17. **Payment** — Pay passport fees via M-Pesa with reference number for submission
18. **Application History** — Track all family passports: issue dates, expiry dates, renewal status
19. **EAC Travel Card** — Information about East African Community travel provisions and cross-border requirements
20. **FAQ** — Common questions about e-passport features, biometrics, validity, dual citizenship

## Key Screens

- **Home** — Application status card, renewal countdown, quick actions
- **Application Guide** — Illustrated step-by-step process with estimated timeline
- **Document Checklist** — Interactive checklist with item descriptions and where to obtain each
- **Photo Tool** — Camera interface with face detection overlay and compliance checker
- **Track Application** — Status timeline: Submitted > Processing > Printing > Ready for Collection
- **Office Finder** — Map with immigration offices, distances, wait times, directions
- **Fee Calculator** — Select options, see itemized fees, proceed to payment
- **Visa Checker** — Country selector with visa status indicator and requirements
- **Family Passports** — All family members' passport cards with expiry indicators
- **Embassy Directory** — Searchable list of Tanzania diplomatic missions worldwide

## TAJIRI Integration Points

- **WalletService** — `deposit(amount, provider:'mpesa')` for passport fees (TZS 150,000-300,000 depending on type and processing speed); `getTransactions()` for payment receipts with reference numbers for submission
- **NotificationService + FCMService** — Push alerts for passport expiry reminders (6 months, 3 months, 1 month before), application status updates, appointment confirmations, collection readiness
- **CalendarService** — `createEvent()` for passport expiry countdown reminders, appointment booking dates, estimated collection dates
- **PhotoService** — `uploadPhoto()` for passport photo capture with AI compliance check (head position, background, expression); document uploads (NIDA card, birth certificate scans)
- **ProfileService** — `getProfile()` for passport verification boosting identity confidence on TAJIRI platform; personal data pre-fill from `RegistrationState`
- **LocationService** — `getRegions()`, `getDistricts()` for GPS-based nearest immigration office finder
- **LocalStorageService** — Offline caching of document checklists, photo requirements guide, embassy directory, visa requirements by country
- **MediaCacheService** — Cache passport scans, application copies, and supporting documents for reference
- **LiveUpdateService** — Real-time application status tracking via Firestore (Submitted > Processing > Printing > Ready for Collection)
- **FriendService** — `getFriends()` for family passport tracking — manage expiry dates for all family members
- **EventTrackingService** — Analytics on processing time estimates by office and season
- **Cross-module: nida** — NIDA verification required before passport application; link to check NIDA status and card readiness
- **Cross-module: rita** — Birth certificate required; cross-check RITA certificate availability before starting passport process
- **Cross-module: travel/** — Passport validity check integrated with travel booking; visa requirements checker by destination country
- **Cross-module: driving_licence** — International Driving Permit information linked alongside passport for travelers
