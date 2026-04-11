# TRA (Tax Services) — Feature Description

## Tanzania Context

TRA (Tanzania Revenue Authority / Mamlaka ya Mapato Tanzania) is the agency responsible for tax collection, administering both domestic taxes and customs. TRA collects approximately TZS 20+ trillion annually and is critical to national development funding.

**Tax types administered:**
- **Income Tax (PAYE)** — Pay As You Earn for employed individuals, deducted by employers monthly
- **Corporate Income Tax** — 30% standard rate for companies
- **VAT** — 18% on goods and services above TZS 200M annual turnover
- **Withholding Tax** — Various rates on rent, dividends, interest, professional fees
- **Excise Duty** — On specific goods (alcohol, tobacco, petroleum, mobile money transactions)
- **Skills and Development Levy (SDL)** — 4.5% of gross payroll
- **Presumptive Tax** — Simplified tax for small businesses with turnover under TZS 100M
- **Capital Gains Tax** — On sale of assets
- **Stamp Duty** — On property transfers and legal documents
- **Customs Duty** — Import/export duties under EAC Common External Tariff

**Current digital services:**
- TIN (Taxpayer Identification Number) registration online via TRA portal
- e-Filing system for returns submission
- EFD (Electronic Fiscal Device) receipts for VAT-registered businesses
- M-Pesa payment integration for some tax types
- TRA mobile app exists but limited functionality

**Pain points:**
- TIN registration online often fails — citizens resort to visiting TRA offices
- e-Filing system complex and frequently down during peak periods (filing deadlines)
- Small business owners confused by tax obligations — don't know what applies to them
- Tax calculation for freelancers and gig workers poorly understood
- M-Pesa tax payment limits and reconciliation issues
- EFD machines expensive (TZS 500,000+) and malfunction regularly
- Tax audits and assessments opaque — citizens don't understand basis for additional assessments
- Penalties and interest accumulate silently — taxpayers discover massive debts years later
- Tax clearance certificates (TCC) take weeks to process despite being needed urgently for tenders

## International Reference Apps

1. **TurboTax (US)** — Guided tax filing with interview-style questions, automatic calculations, refund tracking, audit support. Industry leader.
2. **IRS2Go (US)** — Check refund status, make payments, find free tax help. Simple government tax app.
3. **HMRC App (UK)** — Check tax code, National Insurance record, claim expenses, manage Self Assessment, make payments.
4. **ClearTax (India)** — File income tax returns, GST returns, tax calculator, investment planning, e-verification.
5. **iTax (Kenya/KRA)** — Kenya Revenue Authority portal: TIN registration, returns filing, payment, compliance certificate. Regional benchmark.

## Feature List

1. **TIN Registration** — Register for Taxpayer Identification Number with guided form, document upload, and instant TIN generation
2. **TIN Lookup** — Retrieve your TIN using NIDA number, passport number, or business registration number
3. **Tax Calculator** — Calculate tax liability by type: PAYE calculator, corporate tax, VAT, presumptive tax, capital gains, withholding tax
4. **File Returns** — Submit annual and periodic tax returns with guided wizard: income declaration, deductions, exemptions, final calculation
5. **Tax Payment** — Pay taxes via M-Pesa, bank transfer, or TAJIRI wallet with instant confirmation and receipt
6. **Payment History** — Complete record of all tax payments with dates, amounts, tax types, and reference numbers
7. **Compliance Status** — Real-time view of your tax compliance: filed returns, outstanding obligations, penalties, TCC eligibility
8. **Tax Clearance Certificate** — Apply for and track TCC application status; download digital TCC
9. **Deadline Calendar** — Tax filing and payment deadlines with push notification reminders (monthly VAT, annual income tax, quarterly installments)
10. **Tax Guide for Small Business** — Plain-language guide: which taxes apply based on business type and turnover, registration thresholds, record-keeping requirements
11. **PAYE Tracker** — Employees can verify their employer is remitting PAYE correctly by checking TRA records against pay slips
12. **EFD Receipt Verification** — Scan EFD receipt QR code to verify authenticity with TRA
13. **Tax Assessment Review** — View TRA tax assessments and lodge objections with supporting documents
14. **Withholding Tax Certificates** — View and download withholding tax certificates issued against your TIN
15. **Import Duty Calculator** — Calculate import duties and taxes for goods using HS codes and EAC tariff schedule
16. **Tax Exemption Guide** — List of exemptions available (agricultural inputs, medical supplies, education materials) with eligibility criteria
17. **Penalties Calculator** — Calculate late filing and late payment penalties and interest before they hit
18. **Tax Agent Directory** — Find registered tax consultants and agents by location and specialization
19. **Tax News** — TRA announcements, new regulations, rate changes, filing deadline extensions
20. **Dispute Resolution** — Guide to Tax Revenue Appeals Board (TRAB) process for disputing TRA assessments

## Key Screens

- **Home** — TIN card, compliance status badge, upcoming deadlines, quick pay action
- **Tax Calculator** — Select tax type, input parameters, see detailed breakdown with rates applied
- **File Return** — Multi-step wizard: select period > enter income > deductions > review > submit
- **Payment** — Amount, tax type, payment method selection, M-Pesa STK push, confirmation
- **Payment History** — Filterable transaction list with receipts and reference numbers
- **Compliance Dashboard** — Traffic light status for each tax type, outstanding items, TCC status
- **Deadline Calendar** — Month view with due dates, filed/unfiled status, reminder settings
- **Small Business Guide** — Decision tree: answer questions about your business to see applicable taxes
- **Tax News** — Feed of TRA updates and regulatory changes
- **Help** — FAQ, tax agent finder, TRA office contacts

## TAJIRI Integration Points

- **WalletService** — `deposit(amount, provider:'mpesa')` as primary payment channel for tax payments (PAYE, VAT, presumptive tax, stamp duty); `getTransactions()` for complete payment history with TRA reference numbers; `withdraw()` for tax refund processing
- **NotificationService + FCMService** — Push reminders for filing deadlines (monthly VAT, annual income tax, quarterly installments), payment confirmations, compliance alerts, TCC readiness
- **CalendarService** — `createEvent()` for tax filing and payment deadlines synced to TAJIRI calendar; recurring reminders for periodic returns
- **ProfileService** — `getProfile()` for tax compliance badge on verified businesses in TAJIRI marketplace; employer data from `RegistrationState` for PAYE verification
- **PhotoService** — `uploadPhoto()` for EFD receipt photos, assessment objection supporting documents
- **LocalStorageService** — Offline caching of tax calculators, small business tax guides, tariff schedules, and fee structures
- **MediaCacheService** — Cache tax receipts, returns, assessments, and TCC documents
- **LiveUpdateService** — Real-time TCC application status tracking via Firestore
- **EventTrackingService** — Analytics on compliance rates, payment patterns, filing timeliness
- **PostService** — `createPost()` for sharing TRA announcements, new regulations, rate changes in TAJIRI feed
- **Cross-module: business/** — Tax guides integrated with TAJIRI business/entrepreneur features; TIN registration prompted after BRELA company registration; presumptive tax calculator for small businesses
- **Cross-module: brela** — Business registration linked to TIN for corporate tax obligations; auto-prompt TIN after company formation
- **Cross-module: nida** — NIDA number used for TIN registration and verification
- **Cross-module: legal_gpt** — Tax dispute guidance, assessment objection assistance, TRAB appeal process explanation
- **Cross-module: nssf** — Tax implications of pension withdrawals and benefits; SDL (Skills Development Levy) tracking alongside NSSF
- **Cross-module: land_office** — Stamp duty calculation for property transfers (1% buyer, 1% seller); capital gains tax on land sales
- **Cross-module: my_wallet/** — Tax payment integration with personal wallet; TIN linked to M-Pesa for seamless payment
