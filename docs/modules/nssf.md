# NSSF (Social Security) — Feature Description

## Tanzania Context

NSSF (National Social Security Fund / Mfuko wa Taifa wa Hifadhi ya Jamii) is Tanzania's largest social security scheme, covering private sector employees. Established under the NSSF Act 1997, it operates alongside other schemes: PSSSF (Public Service), LAPF (Local Authority), GEPF (Government Employees), PPF (Parastatal), and NHIF (Health).

**Note:** In 2018, NSSF merged with PPF (Parastatal Pension Fund) and subsequently a broader merger consolidated PSSSF, LAPF, GEPF, and NSSF into two main funds. The landscape remains complex for citizens to navigate.

**Contribution structure:**
- Employee: 10% of gross salary
- Employer: 10% of gross salary
- Total: 20% of gross salary
- Self-employed/informal sector: voluntary contributions (minimum TZS 20,000/month)
- Registration mandatory for all employers with 1+ employees

**Benefits provided:**
- **Old Age Pension** — Monthly pension from age 60 (or 55 with reduced benefits). Minimum 180 months (15 years) contributions
- **Invalidity Pension** — For members who become permanently disabled before retirement age
- **Survivors' Pension** — For dependents of deceased members (spouse, children, parents)
- **Maternity Benefit** — 12 weeks paid leave for female members (84 days)
- **Health Insurance Benefit** — Medical coverage for members (some overlap with NHIF)
- **Funeral Grant** — Lump sum payment upon death of member or dependent
- **Unemployment Benefit** — Limited benefit for involuntarily terminated members
- **Withdrawal Benefit** — Lump sum for members emigrating permanently or reaching retirement with less than 15 years

**Pain points:**
- Many employers register employees but don't remit contributions — massive compliance gap
- Members have no easy way to verify employer is actually paying contributions
- Benefit claims take 3-12 months to process, causing severe hardship for retirees
- Pension amounts often shockingly low — members unaware of projected benefits until retirement
- Self-employed and informal sector workers (majority of workforce) largely uncovered
- Employer changes not properly tracked — contribution records have gaps
- NSSF offices crowded with long processing times for routine inquiries
- Fund investment performance opaque to members
- Multiple social security funds confuse members who've worked in both public and private sectors
- No digital self-service for most transactions — everything requires office visit

## International Reference Apps

1. **SSA Mobile (US)** — Social Security Administration app: check benefits, get Social Security statements, find nearest office, replacement card. Serves 70M+ beneficiaries.
2. **MyGov Pension (India/EPFO)** — Check provident fund balance, download statements, track claims, transfer accounts between employers, UAN-based.
3. **CPF App (Singapore)** — Central Provident Fund: view balances across accounts (retirement, healthcare, housing), project retirement income, manage nominations.
4. **KiwiSaver (New Zealand)** — Retirement savings: check balance, change contribution rate, project retirement income, choose fund type.
5. **Pension Bee (UK)** — Consolidate pension pots, track performance, retirement calculator, easy-to-understand dashboard.

## Feature List

1. **Contribution Statement** — View complete contribution history: monthly amounts, employer names, dates, running balance
2. **Employer Verification** — Check if your employer is registered with NSSF and remitting contributions on your behalf
3. **Contribution Calculator** — Calculate monthly contribution based on salary; show employee and employer portions
4. **Projected Pension** — Retirement calculator: based on current contributions, age, and salary trajectory, estimate monthly pension at retirement
5. **Benefits Overview** — Clear explanation of all available benefits: eligibility criteria, calculation formulas, required documents, processing time
6. **Apply for Benefits** — Submit benefit claims digitally: pension, withdrawal, maternity, survivors, invalidity with document uploads
7. **Claim Status Tracking** — Track benefit claims through stages: Submitted > Verification > Approval > Payment
8. **Digital Member Card** — Display NSSF membership number and details with QR code
9. **Employer Registration Check** — Verify any employer's NSSF registration status and compliance
10. **Nomination Management** — Set or update beneficiary nominations (who receives benefits if member dies)
11. **Self-Employment Registration** — Register as voluntary contributor for informal/self-employed workers
12. **Payment for Self-Employed** — Pay voluntary contributions via M-Pesa with flexible amounts and frequency
13. **Multi-Fund View** — For members with contributions across multiple funds (NSSF, PSSSF, LAPF), see consolidated view
14. **Transfer Between Funds** — Guide for transferring pension credits when moving between private and public sector
15. **Retirement Readiness Score** — Assessment of retirement preparedness based on current trajectory, with actionable recommendations
16. **Investment Performance** — View how NSSF invests member funds: asset allocation, returns, major investments
17. **Maternity Benefit Guide** — Step-by-step guide for claiming maternity benefits: when to apply, documents, timeline
18. **Survivor Benefit Guide** — Guide for dependents to claim benefits after member's death: who qualifies, process, documents
19. **Complaint System** — Report employer non-compliance, delayed benefits, incorrect statements
20. **NSSF Office Finder** — Map of NSSF regional and district offices with services, hours, and contacts

## Key Screens

- **Home** — Member card, total contributions, projected pension, employer compliance status
- **Contribution History** — Monthly statement with employer, amount, date; filterable by year/employer
- **Retirement Calculator** — Adjustable sliders for age, salary growth, contribution rate with projected pension graph
- **Benefits Guide** — Cards for each benefit type with eligibility, amounts, and how-to-claim
- **Apply for Benefit** — Multi-step claim form with document upload and verification
- **Claim Tracker** — Status timeline with estimated processing dates
- **Employer Check** — Search employer by name/TIN, see registration and compliance status
- **Nominations** — Current nominees list with add/edit/remove and percentage allocation
- **Self-Employed Portal** — Registration, payment schedule, contribution history for voluntary members
- **Office Finder** — Map with NSSF offices, distances, services, and queue estimates

## TAJIRI Integration Points

- **WalletService** — `deposit(amount, provider:'mpesa')` for voluntary contributions (minimum TZS 20,000/month for self-employed); `getTransactions()` for contribution payment receipts and history
- **MessageService** — `sendMessage()` for contacting NSSF support; `getConversations()` for tracking benefit claim communications
- **NotificationService + FCMService** — Push alerts for contribution confirmations, claim status updates, retirement milestones (e.g., reaching 180-month threshold), employer compliance alerts, nomination reminders
- **CalendarService** — `createEvent()` for contribution due dates, retirement countdown, benefit claim processing milestones
- **ProfileService** — `getProfile()` for social security status indicator on TAJIRI profile; employer data from `RegistrationState` for contribution verification
- **PhotoService** — `uploadPhoto()` for benefit claim supporting documents (medical reports for invalidity, death certificates for survivors)
- **LocationService** — `getRegions()`, `getDistricts()` for nearest NSSF office finder with queue estimates
- **LocalStorageService** — Offline caching of contribution statements, benefit calculation guides, nomination forms, retirement planning tools
- **MediaCacheService** — Cache contribution statements, benefit letters, and nomination forms for reference
- **LiveUpdateService** — Real-time claim status tracking via Firestore (Submitted > Verification > Approval > Payment)
- **FriendService** — `getFriends()` for dependents/nominees management — track nominated beneficiaries linked to TAJIRI family module
- **EventTrackingService** — Analytics on contribution consistency, projected pension trends, employer compliance rates
- **Cross-module: my_wallet/** — Pension projection as part of overall financial planning; retirement readiness score integrated with wallet overview
- **Cross-module: loans/** — Withdrawal eligibility check; pension-backed loan options for qualifying members
- **Cross-module: nhif** — Combined social protection dashboard: health insurance + pension viewed together
- **Cross-module: nida** — NIDA verification for member identity and benefit claims
- **Cross-module: tra** — Tax implications of pension withdrawals and benefits; SDL tracking alongside NSSF contributions
- **Cross-module: investments/** — Pension as part of overall retirement/investment planning; NSSF fund performance alongside personal investments
- **Cross-module: business/** — Employer NSSF compliance tracking for TAJIRI business users; registration check for employers
- **Cross-module: my_family/** — Dependents/nominees linked to TAJIRI family module for survivors' benefit management
