# BRELA (Business Registration) — Feature Description

## Tanzania Context

BRELA (Business Registrations and Licensing Agency / Wakala wa Usajili wa Biashara na Leseni) is the government agency responsible for business and company registration, industrial licensing, trademarks, patents, and issuing certificates of compliance. It operates under the Ministry of Industry and Trade.

**Services provided:**
- Company registration (private limited, public limited, companies limited by guarantee)
- Business name registration (sole proprietorship, partnership)
- Industrial and commercial licenses
- Trademark and service mark registration
- Patent registration
- Company annual returns filing
- Certificate of Compliance issuance
- Company name search and reservation

**Current digital services (ORS - Online Registration System):**
- Company and business name search available online
- Online registration for companies and business names (launched 2018)
- e-Payment integration for registration fees
- Digital certificates of incorporation downloadable
- Annual returns filing online

**Registration types and fees (approximate):**
- Business Name: TZS 30,000 registration + TZS 10,000 name reservation
- Private Company: TZS 200,000-500,000 depending on share capital
- Company Name Reservation: TZS 20,000 (valid 30 days)
- Annual Returns: TZS 50,000 (company), TZS 15,000 (business name)
- Trademark Registration: TZS 180,000+ per class

**Pain points:**
- ORS system frequently down or extremely slow
- Company registration takes 1-7 days online but can take weeks if issues arise
- Name availability search sometimes gives false positives — names approved then rejected
- Annual returns compliance poorly enforced but suddenly demanded for bank/tender requirements
- Many businesses operate unregistered due to perceived complexity and cost
- Trademark registration process takes 12-24 months (among slowest in East Africa)
- Limited customer support — phone lines rarely answered, emails take weeks
- Certificate of Compliance needed for tenders but processing time unpredictable
- Foreign company registration (branch office) process highly manual
- Digital certificates sometimes not accepted by other agencies that want physical copies

## International Reference Apps

1. **Companies House (UK)** — Search companies, check directors, file accounts and returns, register new companies. Gold standard for transparency. All company data publicly available and searchable.
2. **Stripe Atlas (US/Global)** — Incorporate a Delaware company in days. Guided process, bank account, tax ID, legal templates included. End-to-end.
3. **Bizfile (Singapore/ACRA)** — Register companies, file annual returns, search business profiles. Fully digital, same-day registration.
4. **eCitizen (Kenya)** — Kenya business registration: name search, registration, payment. Regional benchmark.
5. **Zenbusiness (US)** — LLC/Corp formation with compliance calendar, registered agent, annual report filing, trademark filing.

## Feature List

1. **Company Name Search** — Real-time search of registered company and business names to check availability before registration
2. **Name Reservation** — Reserve an available company or business name for 30 days with online payment
3. **Business Name Registration** — Guided registration for sole proprietorships and partnerships with form pre-fill and document upload
4. **Company Registration** — Full private limited company registration: articles of association, memorandum, directors, shareholders, registered office
5. **Registration Status Tracker** — Track application through stages: Submitted > Under Review > Approved > Certificate Ready
6. **Certificate Download** — Download Certificate of Incorporation, Certificate of Registration, and Certificate of Compliance digitally
7. **Annual Returns Filing** — File annual returns with guided form, financial summary, director/shareholder updates
8. **Compliance Calendar** — Track filing deadlines for annual returns, license renewals with push notifications
9. **Company Profile** — View registered company details: directors, shareholders, registered office, filing history
10. **Director/Shareholder Changes** — Submit changes to company officers and shareholders with required resolutions and documents
11. **Registered Office Change** — Update company registered office address with supporting documents
12. **Trademark Search** — Search existing trademarks by name, class, or owner
13. **Trademark Application** — File trademark application with logo upload, class selection, and payment
14. **Trademark Status** — Track trademark application through examination, publication, and registration phases
15. **Business License Search** — Check if a business holds valid industrial or commercial licenses
16. **Fee Calculator** — Calculate registration and filing fees based on business type, share capital, and service needed
17. **Document Templates** — Downloadable templates: memorandum and articles of association, board resolutions, shareholder agreements
18. **Foreign Company Registration** — Guide and application for registering foreign company branch office in Tanzania
19. **Business Deregistration** — Process for voluntarily deregistering or dissolving a business
20. **BRELA Office Finder** — Locations, hours, and contacts for BRELA offices and authorized agents

## Key Screens

- **Home** — Quick actions (name search, register, file returns), my businesses list, compliance alerts
- **Name Search** — Search input with real-time results, availability indicator, reserve button
- **Registration Wizard** — Multi-step guided form with document uploads, review, and payment
- **My Businesses** — List of all registered businesses/companies with compliance status badges
- **Business Detail** — Company profile with directors, shareholders, filings, certificates
- **File Annual Returns** — Guided return form with financial data entry and payment
- **Compliance Calendar** — Timeline of upcoming deadlines with status indicators
- **Trademark Center** — Search, apply, and track trademarks
- **Certificate Viewer** — View and download/share digital certificates
- **Fee Calculator** — Interactive fee estimator for all BRELA services

## TAJIRI Integration Points

- **WalletService** — `deposit(amount, provider:'mpesa')` for registration fees, annual returns (TZS 50,000 company / TZS 15,000 business name), name reservation (TZS 20,000), and trademark fees; `getTransactions()` for payment receipts and compliance records
- **NotificationService + FCMService** — Push reminders for annual returns deadlines, compliance certificate expiry, trademark application milestones (examination > publication > registration), name reservation 30-day expiry
- **CalendarService** — `createEvent()` for filing deadlines synced to TAJIRI calendar; recurring annual returns reminders
- **ProfileService** — `getProfile()` for business verification badge on TAJIRI marketplace; director/shareholder identity data from `RegistrationState`
- **PhotoService** — `uploadPhoto()` for trademark logo uploads, articles of association scans, board resolution documents
- **LocalStorageService** — Offline caching of fee calculators, document templates (memorandum, articles, resolutions), registration guides
- **MediaCacheService** — Cache digital certificates of incorporation, registration, and compliance for quick access
- **LiveUpdateService** — Real-time registration status tracking via Firestore (Submitted > Under Review > Approved > Certificate Ready)
- **GroupService** — `createGroup()` for entrepreneur communities with registration guidance discussions; `joinGroup()` for sector-specific business groups
- **PostService** — `createPost()` for sharing business registration tips, compliance updates in TAJIRI feed
- **ShopService** — Verified business badge for TAJIRI marketplace sellers using BRELA registration status; products linked to registered businesses
- **EventTrackingService** — Analytics on registration completion rates, compliance status across TAJIRI business users
- **Cross-module: business/** — BRELA registration integrated with TAJIRI business/entrepreneur tools; company profile (biz_profile) linked to BRELA registration data
- **Cross-module: tra** — Auto-prompt TIN registration after company registration; link TIN to company for corporate tax obligations
- **Cross-module: nida** — Director/shareholder NIDA verification during company registration
- **Cross-module: legal_gpt** — Legal guidance on company types (private vs public limited), compliance obligations, director liabilities, trademark law
- **Cross-module: land_office** — Company land ownership verification linked to BRELA registration
