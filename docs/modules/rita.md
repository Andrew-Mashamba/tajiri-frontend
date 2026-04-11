# RITA (Birth/Death/Marriage Certificates) — Feature Description

## Tanzania Context

RITA (Registration Insolvency and Trusteeship Agency / Wakala wa Usajili, Ufilisi na Udhamini) is responsible for civil registration in Tanzania: births, deaths, marriages, divorces, adoptions, and business insolvency. Birth registration is constitutionally mandated but historically underperformed.

**Services provided:**
- Birth certificate registration and issuance (Cheti cha Kuzaliwa)
- Death certificate registration (Cheti cha Kifo)
- Marriage certificate registration (Cheti cha Ndoa)
- Divorce registration
- Adoption registration
- Late birth registration (for those not registered at birth)
- Name change registration
- Business names and trusteeship (separate from BRELA for certain types)

**Current reality:**
- Birth registration rate has improved but remains around 26% for children under 5 (one of the lowest in East Africa)
- Late birth registration is common — many adults register for the first time when they need NIDA, passport, or school enrollment
- Registration done at district level through District Registrars, but certificates printed centrally in Dar es Salaam
- Processing time for birth certificates: officially 14-30 days, actually 2-6 months common
- Fees: Birth certificate TZS 3,500 (within 90 days), TZS 4,000 (late registration), replacement TZS 5,000
- Death certificates required for inheritance, insurance claims, pension access — delays cause severe hardship for bereaved families
- Marriage registration: two systems — civil marriage (Marriage Act) and customary/religious marriage (often unregistered)
- RITA offices limited — mainly in regional capitals and some district HQs

**Pain points:**
- Centralized printing in Dar causes months of delays for certificates
- Tracking application status requires physical visits or phone calls to RITA
- Rural citizens travel hundreds of kilometers to regional offices
- Birth certificate errors (wrong name spelling, date) extremely common and costly to fix
- Late registration requires witnesses, Mtaa letters, and multiple visits
- Death certificates for deaths that occurred years ago require complex documentation
- Many marriages (especially customary and Islamic) never registered — causes inheritance problems
- No integration between RITA and hospitals for automatic birth registration

## International Reference Apps

1. **VitalChek (US)** — Online ordering of birth, death, marriage, and divorce certificates from any US state. Track orders, identity verification, express shipping.
2. **ServiceNSW (Australia)** — Request birth/death/marriage certificates online, track applications, update records, receive digital certificates.
3. **GOV.UK Register (UK)** — Online birth, death, marriage registration with appointment booking, certificate ordering, and digital verification.
4. **DigiLocker (India)** — Government document wallet with verified digital certificates (birth, education, driving license) accepted as legal originals.
5. **SmartCitizen (Estonia)** — Digital-first vital records: birth auto-registered from hospital, digital certificates, online name changes.

## Feature List

1. **Certificate Application** — Apply for birth, death, or marriage certificates online with form pre-fill and document upload
2. **Application Tracking** — Track certificate application status: Submitted > Processing > Printing > Ready for Collection / Shipped
3. **Required Documents Checklist** — For each certificate type, interactive checklist of needed documents with explanations
4. **Late Birth Registration Guide** — Step-by-step process for adults registering birth for the first time, including witness requirements
5. **Hospital Birth Notification** — For new parents: guide to ensuring hospital notifies RITA within 90 days of birth
6. **Find RITA Office** — Map of all RITA offices and District Registrar locations with hours, contacts, and services
7. **Fee Calculator** — Calculate exact fees based on certificate type, registration timing (within/after 90 days), and express options
8. **Appointment Booking** — Book appointment at RITA office for registration or collection
9. **Certificate Verification** — Verify authenticity of a certificate using certificate number or QR code
10. **Name Correction Request** — Submit requests for corrections to registered information with supporting documents
11. **Replacement Certificate** — Apply for replacement of lost, damaged, or destroyed certificates
12. **Marriage Registration Guide** — Explain civil vs customary vs religious marriage registration, required documents, fees, and procedures
13. **Death Registration Guide** — Process for registering a death: hospital deaths vs home deaths, required documents, timeline
14. **Name Change Registration** — Process for legally changing name after marriage, divorce, or personal choice
15. **Digital Certificate Preview** — View your registered vital records details (reference, not legal replacement)
16. **Family Records** — Track certificates for all family members (children's births, parent's records) in one place
17. **Notification Alerts** — Push notifications for status updates, collection readiness, expiring deadlines
18. **Complaint System** — Report delays, errors, or corruption in RITA services with tracking
19. **Document Templates** — Downloadable affidavit templates for late registration, correction, and witness statements

## Key Screens

- **Home** — Quick actions (apply, track, find office), recent applications, family records summary
- **Apply for Certificate** — Multi-step form: select type > enter details > upload documents > pay fee > confirm
- **Track Application** — Status timeline with estimated dates and collection location
- **Document Checklist** — Interactive checklist with descriptions of each required document
- **Office Finder** — Map with RITA offices and District Registrar locations
- **Fee Calculator** — Input parameters, see itemized fees, proceed to payment
- **Family Records** — Cards for each family member with certificate statuses
- **Guides** — Step-by-step guides for each registration type with illustrations
- **Corrections** — Form for submitting data correction requests
- **Complaints** — Structured complaint form with tracking number

## TAJIRI Integration Points

- **WalletService** — `deposit(amount, provider:'mpesa')` for RITA certificate fees (TZS 3,500-5,000); `getTransactions()` for digital payment receipts
- **NotificationService + FCMService** — Push alerts for application status updates (Submitted > Processing > Printing > Ready), 90-day birth registration deadline reminders, collection readiness
- **LocationService** — `getRegions()`, `getDistricts()` for GPS-based nearest RITA office and District Registrar finder
- **PhotoService** — `uploadPhoto()` for supporting document uploads (affidavits, witness statements, existing certificates)
- **ProfileService** — `getProfile()` for birth certificate verification as identity proof on TAJIRI; user education and personal data from `RegistrationState`
- **CalendarService** — `createEvent()` for 90-day birth registration deadline reminders, appointment booking, collection dates
- **LocalStorageService** — Offline caching of document checklists, fee schedules, registration guides, and office locations
- **MediaCacheService** — Cache digital copies of certificates and registration receipts for reuse
- **LiveUpdateService** — Real-time application status tracking via Firestore
- **FriendService** — `getFriends()` for family record tracking — certificates for spouse, children, parents in one view
- **Cross-module: nida** — Birth certificate required for NIDA registration; cross-module status check ensures birth cert is ready before NIDA application
- **Cross-module: passport** — Birth certificate required for passport application; verify RITA certificate availability before passport process
- **Cross-module: legal_gpt** — Legal guidance on registration requirements, inheritance implications of death certificates, marriage registration under different legal systems
- **Cross-module: my_family/** — Family member records linked to TAJIRI family features; track all family certificates
- **Cross-module: land_office** — Death certificates needed for inheritance-based land transfers
