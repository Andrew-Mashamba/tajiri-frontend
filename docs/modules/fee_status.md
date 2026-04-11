# Fee Status / Ada — Feature Description

## Tanzania Context

School fees are the single biggest source of stress for Tanzanian students and their families. The financial dynamics of education in Tanzania are complex and emotionally charged:

- **HESLB loans** — The Higher Education Students' Loans Board provides loans to qualifying students, but the process is bureaucratic. Loan disbursement is frequently delayed (sometimes by months), leaving students unable to register, access exams, or eat in campus cafeterias
- **Fee balance anxiety** — Students check their fee balance obsessively. A negative balance means no exam entry, no transcript, no graduation clearance. The registrar's office queue for balance checking can take hours
- **M-Pesa payments** — Parents increasingly pay fees via M-Pesa (mobile money), but the process involves multiple steps: get the institution's paybill number, enter the student's registration number as reference, confirm the amount. Errors in the reference number mean payment goes to the wrong account
- **Partial payments** — Many families can't pay the full amount at once. They make multiple partial payments throughout the semester. Tracking these payments and knowing the remaining balance is critical
- **Fee structure complexity** — Fees include tuition, accommodation, examination fees, student union fees, medical fees, ID card fees, and more. Students often don't understand the breakdown
- **Payment receipts** — Getting a payment receipt requires visiting the finance office. Students need receipts for HESLB reporting and parent records
- **Clearance process** — Before exams and graduation, students must get "clearance" confirming all fees are paid. This involves visiting multiple offices (finance, library, accommodation, student affairs)
- **Sponsor coordination** — Some students have multiple funding sources: HESLB + family + bursary + part-time work. Coordinating who pays what portion is complex
- **Fee increases** — Institutions sometimes increase fees mid-program, causing financial crises for families who budgeted based on original amounts

## International Reference Apps

1. **Flywire** — International education payments with currency conversion, payment plans, tracking, receipts. Used by 2,800+ institutions globally.
2. **PayMyTuition** — Fee payment with multiple payment methods, real-time tracking, confirmation receipts, exchange rate lock. Student-focused.
3. **CashNet by Higher One** — Tuition billing, online payments, payment plans, refund management. US university standard.
4. **FACTS Tuition Management** — Payment plans, automatic payments, payment reminders, financial aid integration. K-12 and higher ed.
5. **Nelnet** — Student loan servicing, tuition payment plans, enrollment management. Large-scale education finance.

## Feature List

1. Fee balance display: current total balance with breakdown by category (tuition, accommodation, exam, union, etc.)
2. Payment history: chronological list of all payments with date, amount, method, and reference number
3. Pay via M-Pesa: integrated M-Pesa payment with auto-filled institution paybill and student reference number
4. Pay via bank transfer: display institution bank details with copy-to-clipboard for account number
5. HESLB loan status: display loan amount allocated, amount disbursed, disbursement date, remaining balance
6. HESLB disbursement tracker: notification when loan funds are released to institution
7. Fee breakdown by semester: detailed table showing each fee component and amount
8. Payment receipt download: generate PDF receipt for each payment
9. Fee deadline reminders: push notifications before payment deadlines (registration, exam entry, etc.)
10. Partial payment tracking: visual progress bar showing paid vs. remaining balance
11. Payment plan calculator: divide remaining balance into installments with suggested dates
12. Clearance status: checklist showing clearance from finance, library, accommodation, student affairs
13. Fee comparison: see fee structure for different programs at your institution
14. Sponsor management: track contributions from multiple sources (HESLB, family, bursary, self)
15. Fee statement generator: comprehensive fee statement PDF for sponsor/parent reporting
16. Currency converter: for international students or those with sponsors abroad
17. Historical fee records: view fee status from all previous semesters
18. Fee increase alerts: notification when institution changes fee structure
19. Auto-payment setup: scheduled M-Pesa deductions for regular installments
20. Emergency fee alerts: urgent notification when balance blocks exam entry or registration
21. Financial aid information: links to bursary and scholarship opportunities
22. Parent/sponsor view: share fee status with parents via secure link (read-only)

## Key Screens

- **Fee Dashboard** — Total balance, next deadline, recent payments, clearance status, quick pay button
- **Balance Breakdown** — Detailed table of fee components with paid/unpaid status per category
- **Payment History** — Scrollable list of all transactions with receipt download button
- **Make Payment** — Payment method selection (M-Pesa, bank), amount input, confirmation screen
- **HESLB Status** — Loan allocation details, disbursement history, remaining entitlement
- **Payment Plan** — Installment calculator with suggested dates and amounts
- **Clearance Checklist** — Status from each department with completion indicators
- **Fee Statement** — Formatted statement preview with download/share options
- **Sponsor Management** — List of funding sources with contribution amounts and percentages
- **Reminders** — Upcoming fee deadlines with countdown and payment suggestions

## TAJIRI Integration Points

- **WalletService.deposit(amount, provider:'mpesa')** — M-Pesa fee payments flow through TAJIRI wallet; auto-fill institution paybill and student reference number
- **NotificationService + FCMService** — Fee deadline reminders, HESLB disbursement alerts, and emergency balance warnings via push notifications
- **CalendarService.createEvent()** — Fee payment deadlines (registration, exam entry, clearance) synced to personal TAJIRI calendar
- **MessageService.sendMessage()** — Share fee statement with parents/sponsors via TAJIRI chat; payment confirmation messages
- **ProfileService.getProfile()** — Clearance status badge on profile; education data links fee status to enrollment
- **LiveUpdateService** — Real-time updates when HESLB loan funds are disbursed to institution
- **my_wallet/ module** — Fee payments and budget tracking; M-Pesa payment integration
- **results module** — GPA linked to HESLB eligibility; low GPA triggers fee funding risk alert (heslb tab)
- **my_class module** — Fee clearance status affects class registration visibility
- **campus_news module** — Fee-related announcements (increases, deadline extensions) linked here
- **career module** — Graduation clearance status linked to career module for job applications
