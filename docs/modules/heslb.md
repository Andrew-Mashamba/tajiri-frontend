# HESLB (Higher Education Students' Loans Board) — Feature Description

## Tanzania Context

HESLB is the government body responsible for providing loans to Tanzanian students pursuing higher education. Established under the Higher Education Students' Loans Board Act, 2004, it is one of the most heavily used government services in Tanzania — every university student interacts with HESLB.

**What HESLB Does:**
- Provides means-tested loans to undergraduate students at accredited universities and colleges
- Covers tuition fees, books/stationery, field/practical training, and living allowances
- Manages loan repayment collection from graduates through employers and self-employment
- Operates the Online Loan Application System (OLAS) — olas.heslb.go.tz
- Issues loan clearance letters to graduates who complete repayment

**How Students Interact:**
- **Application (Form 6 leavers):** Apply through OLAS portal after ACSEE results. Requires extensive documentation — birth certificate, parents' income proof, school head letter, ward executive officer letter
- **Allocation:** Check if loan approved, amount allocated per component (tuition, meals, accommodation, books)
- **Disbursement:** Track when funds are sent to university and personal account (living allowance via bank/mobile money)
- **Repayment (graduates):** Monthly deductions from salary (15% of gross salary) or self-assessment for self-employed. Must repay until loan + 6% interest is cleared
- **Clearance:** Request clearance letter after full repayment

**Current Pain Points:**
- **OLAS crashes constantly** — During application windows (typically February-April), the portal buckles under millions of simultaneous users. Students spend days refreshing
- **Disbursement delays** — Funds often arrive weeks or months late. Students go without meals or get sent home for unpaid fees while waiting
- **Balance opacity** — Graduates can't easily check their remaining loan balance. Statements require physical visits or unreliable email requests
- **Repayment confusion** — Many graduates don't know how much they owe, current interest accrued, or expected payoff date
- **No mobile experience** — OLAS is desktop-only and painful on mobile. No app exists
- **Appeal process is unclear** — Students denied loans or given insufficient amounts struggle to navigate the appeals system
- **Employer deduction errors** — Employers sometimes deduct wrong amounts or fail to remit to HESLB. No easy way for graduates to verify

## International Reference Apps

1. **HELB (Kenya)** — Higher Education Loans Board mobile app with loan application, balance check, M-Pesa repayment, and statement download
2. **Federal Student Aid (USA)** — studentaid.gov with loan dashboard, repayment plans, income-driven repayment calculator, and PSLF tracking
3. **Student Loans Company (UK)** — Online account with balance, repayment history, threshold calculations, and overseas repayment management
4. **NSFAS (South Africa)** — National Student Financial Aid Scheme with myNSFAS portal for application tracking, allowance status, and appeals
5. **StudyLink (New Zealand)** — Student finance portal with application tracking, payment schedule, and living cost support management

## Feature List

1. **Loan Application Status** — Real-time tracking of OLAS application progress: submitted, under review, means-testing, approved, denied. View allocation breakdown by component
2. **Disbursement Tracker** — Track loan disbursement schedule and actual payment dates. See when tuition was paid to university and when living allowance was sent to bank/mobile money. Push notification when disbursement is processed
3. **Loan Balance** — Current outstanding loan balance including principal and accrued interest. Updated after each payment received
4. **Repayment Calculator** — Enter salary to calculate monthly deduction (15% of gross). Show projected payoff date, total interest, and remaining payments
5. **Repayment via M-Pesa** — Make loan repayment directly through M-Pesa, Tigo Pesa, or Airtel Money. Integration with TAJIRI wallet for scheduled payments
6. **Payment History** — Complete history of all repayments made — employer deductions, self-payments, and M-Pesa payments. Downloadable statement
7. **Clearance Letter Request** — Submit request for loan clearance letter after full repayment. Track request status and download digital clearance certificate
8. **OLAS Portal Shortcut** — Deep link to OLAS portal with auto-filled credentials. Show OLAS system status (up/down) before user attempts to access
9. **Application Guide** — Step-by-step guide for new applicants: required documents checklist, means-testing criteria, eligible institutions, application timeline
10. **Eligibility Checker** — Answer questions about family income, orphan status, disability, and academic performance to estimate loan eligibility and likely allocation amount
11. **Appeal Process** — Guide for appealing loan denial or insufficient allocation. Appeal letter templates. Track appeal status
12. **Contact HESLB** — Direct contact channels — phone, email, regional office locations. In-app chat if available. Queue position tracking for phone calls
13. **Repayment Schedule** — Personalized repayment schedule showing expected monthly payments, projected balance reduction, and interest accumulation over time
14. **Employer Verification** — For graduates: verify that employer is correctly deducting and remitting HESLB repayments. Flag discrepancies between payslip deduction and HESLB-received amount
15. **Loan Summary Dashboard** — At-a-glance view: total borrowed, total repaid, remaining balance, interest paid, expected clearance date, repayment streak
16. **University Fee Status** — Check if HESLB has paid tuition/fees to your university for current semester. Critical for avoiding "sent home" situations

## Key Screens

- **Dashboard** — Loan summary with balance, next payment, disbursement status
- **Application Status** — Multi-step progress tracker for new applications
- **Disbursement Timeline** — Visual timeline of expected and actual disbursement dates
- **Balance & Repayment** — Current balance, monthly amount, payoff projection chart
- **Pay Now** — M-Pesa/mobile money payment screen with amount options
- **Payment History** — Chronological list of all payments with downloadable statement
- **Application Guide** — Document checklist and step-by-step walkthrough
- **Clearance Request** — Request form and status tracker

## TAJIRI Integration Points

- **Wallet (WalletService)** — Loan repayment via `WalletService.deposit()` with M-Pesa/Tigo/Airtel STK push. Scheduled auto-payments for monthly loan repayments deducted from wallet balance. One-time extra payments to accelerate loan payoff. Repayment amount calculated at 15% of gross salary and pre-filled. Transaction history via `WalletService.getTransactions()` shows all HESLB repayments with reference numbers and remaining balance. PIN verification via `WalletService.setPin()` for payment authorization. GePG (Government Electronic Payment Gateway) integration for official HESLB payment processing
- **Notifications (FCMService + NotificationService)** — Push notifications via `FCMService` for: loan disbursement processed (tuition paid to university, living allowance sent), repayment confirmation receipts, OLAS application status changes (submitted, under review, approved, denied), monthly repayment reminders with amount due, loan balance milestone updates, OLAS system status alerts (up/down) before application attempts, appeal window opening/closing dates, clearance letter ready for download, employer deduction discrepancy alerts
- **Groups (GroupService)** — University student groups via `GroupService.createGroup()` — campus-specific HESLB discussion forums (UDSM, UDOM, SUA, MUST). Alumni groups organized by graduation year. HESLB tips and advice communities. Group posts via `GroupService.getGroupPosts()` for sharing application tips, disbursement status updates, repayment strategies, and employer deduction experiences. Study groups for HESLB-funded students
- **Messaging (MessageService)** — Receive HESLB updates and correspondence via `MessageService.sendMessage()`. University financial office communication. Student-to-student HESLB advice. Appeal process guidance conversations. Auto-created conversation for HESLB inquiry tracking. `MessageService.createGroup()` for class-level HESLB coordination
- **Calendar (CalendarService)** — OLAS application deadlines synced to calendar via `CalendarService.createEvent()`. Monthly repayment due dates as recurring events. Appeal window dates. Disbursement expected dates. Clearance request follow-up dates. Academic semester start dates (when tuition payment should arrive). Form 6 results release dates (application trigger)
- **Profile (ProfileService)** — Student verification badge on TAJIRI profile via `ProfileService.getProfile()`. University enrollment status. Graduation status and year. HESLB loan clearance badge for fully repaid graduates. Education history section showing institution, program, and graduation year
- **Bills Module (bills/)** — Loan repayment tracked as a recurring bill with due dates, amount due, and payment history. Remaining balance displayed as outstanding bill. Repayment progress bar (total repaid vs total owed). Auto-payment scheduling. Bill reminders synced with notification system. Employer deduction verification — compare payslip deduction with HESLB-received amount
- **Posts & Stories (PostService + StoryService)** — Share HESLB application tips via `PostService.createPost()`. Loan clearance celebrations posted to feed. Application guide content shared to help new applicants. Disbursement status updates shared in university groups. Story posts via `StoryService.createStory()` for academic milestone celebrations
- **My Family Module (my_family/)** — Parents track children's HESLB application and disbursement status. Family loan repayment coordination — parents can contribute to graduate's loan repayment. Multiple children's HESLB statuses managed in one view. Family HESLB expense planning
- **NECTA Module (necta/)** — ACSEE results verification linked to HESLB eligibility — Form 6 results determine loan application timing. Academic performance from NECTA feeds into means-testing process. Results history supports appeal documentation
- **Location (LocationService)** — Nearest HESLB office finder via `LocationService.searchLocations()` using Tanzania hierarchy. Regional office locations with contact details and services available. University office locations for fee status inquiries
- **Media (PhotoService)** — Application document photo uploads via `PhotoService.uploadPhoto()` — birth certificate, parents' income proof, school head letter, ward executive officer letter. Clearance certificate photo storage. Payment receipt documentation
- **Real-time Updates (LiveUpdateService)** — Firestore listeners for real-time application status changes during processing period. Disbursement processing alerts. OLAS system availability status updates
- **Budget (BudgetService)** — Student budget tracking via `BudgetService` — living allowance management. Monthly expense planning based on HESLB disbursement amounts. Loan repayment budgeting for graduates. Total loan cost projection with interest calculation
- **Content Discovery (ContentEngineService)** — HESLB application guide content personalized by student's application stage via `ContentEngineService`. Repayment strategy articles for graduates. Eligibility criteria explanations. Financial literacy content for students
- **People Search (PeopleSearchService)** — Find fellow HESLB applicants at same university via `PeopleSearchService.search()`. Connect with alumni who navigated the same process. Find students in same program for study group formation
- **Analytics (AnalyticsService)** — Personal loan analytics: total borrowed, total repaid, interest paid, projected clearance date, repayment streak. Monthly payment trends. Employer deduction tracking accuracy

## Available APIs

- **HESLB OLAS Portal** — olas.heslb.go.tz (web portal, no documented public API; would need MOU for integration)
- **HESLB Repayment Portal** — Separate system for loan repayment and balance queries
- **HELB Kenya API** — Reference implementation for student loan mobile integration
- **M-Pesa API (Vodacom Tanzania)** — For direct mobile money repayment integration
- **GePG (Government Electronic Payment Gateway)** — Tanzania government payment system used by HESLB
- TAJIRI backend will need formal partnership with HESLB for data access — student loan data is highly sensitive and regulated
