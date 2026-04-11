# TAJIRI Business Module — Comprehensive Research Report

**Date:** 2026-04-04
**Purpose:** Feature analysis and prioritization for a mobile business management module integrated into the TAJIRI social platform, targeting Tanzanian SMEs.

---

## Table of Contents

1. [Tanzania Business Environment Overview](#1-tanzania-business-environment-overview)
2. [Business Registration in Tanzania](#2-business-registration-in-tanzania)
3. [Tanzania Tax Rates & Compliance (2025/2026)](#3-tanzania-tax-rates--compliance-20252026)
4. [Competitive Landscape Analysis](#4-competitive-landscape-analysis)
5. [Tanzania-Specific Business Needs](#5-tanzania-specific-business-needs)
6. [Prioritized Feature List for TAJIRI Business Module](#6-prioritized-feature-list-for-tajiri-business-module)
7. [Cross-Module Integration Opportunities](#7-cross-module-integration-opportunities)
8. [Implementation Phases](#8-implementation-phases)
9. [Technical Architecture Notes](#9-technical-architecture-notes)

---

## 1. Tanzania Business Environment Overview

### The SME Landscape
- SMEs account for ~95% of businesses in Tanzania
- Only ~20% of SMEs access formal financial services
- Internet penetration is ~31.9% but mobile money penetration is much higher (~60%+)
- Most common businesses: retail shops ("duka la rejareja"), food vendors ("mama lishe"), artisans ("fundi"), agricultural traders
- Vast majority use paper ledgers, exercise books, or nothing at all for bookkeeping
- Tanzania ranks 141st on World Bank's Ease of Doing Business Index

### Key Pain Points for Tanzanian SMEs
1. **Cash flow visibility** — No idea how much they actually make vs. spend daily
2. **Debt tracking ("deni")** — Customer credit is extremely common; tracking who owes what is done in exercise books or memory
3. **Mobile money reconciliation** — M-Pesa/Tigo Pesa transactions scattered across different platforms with no consolidated view
4. **Tax compliance** — Complex tax structure, fear of TRA, poor understanding of obligations
5. **Business formalization** — Registration perceived as expensive, complex, and unnecessary
6. **Access to capital** — No formal financial records means no loan eligibility
7. **Inventory management** — Stock-outs or over-ordering due to no tracking
8. **Digital literacy** — Limited technical skills, Swahili-first requirement

### Adoption Barriers
- **Cost sensitivity** — Must be free or very low cost
- **Language** — Must be Swahili-first
- **Simplicity** — Must not feel like "accounting software"
- **Offline capability** — Unreliable connectivity in many areas
- **Data cost** — Must be lightweight on mobile data
- **Trust** — Resistance to sharing financial data digitally

---

## 2. Business Registration in Tanzania

### Registration Types & Process

#### A. Sole Proprietorship (Biashara ya Mtu Binafsi)
**Process:**
1. Register on BRELA ORS (ors.brela.go.tz)
2. Create ORS account (requires NIN from NIDA)
3. Search and reserve business name — TZS ~50,000
4. Submit registration application
5. Pay fees via GePG (Government e-Payment Gateway)
6. Receive Business Registration Certificate

**Requirements:**
- National ID (NIN from NIDA)
- TIN from TRA
- Proposed business name (2-3 alternatives)

**Cost:** TZS 50,000 - 100,000 total
**Timeline:** 1-3 business days (online)

#### B. Limited Liability Company (Kampuni ya Dhima Ndogo)
**Process:**
1. Register on BRELA ORS
2. Reserve company name — TZS ~50,000
3. Prepare Memorandum and Articles of Association
4. Submit incorporation documents
5. Pay registration fees + filing fees + stamp duty
6. Receive Certificate of Incorporation

**Requirements:**
- All directors must have NIN + TIN
- Minimum 2 shareholders (private company)
- Memorandum and Articles of Association
- Registered office address in Tanzania
- Filing fee: TZS 22,000 per document

**Cost:** TZS 95,000 - 440,000 (depends on share capital)
- Without share capital: TZS 300,000
- With share capital: varies based on amount
**Timeline:** 3-7 business days

#### C. Partnership (Ubia)
**Process:** Similar to sole proprietorship but requires Partnership Deed
**Cost:** TZS 50,000 - 150,000
**Requirements:** Partnership Deed, all partners' NIN + TIN

### Post-Registration Requirements

1. **TIN Registration (TRA)**
   - Register within 30 days of commencing business
   - Done through TRA's iTax system or district office
   - Requires: Business certificate, ID, passport photo
   - Cost: Free
   - Timeline: 1-2 days

2. **VAT Registration (TRA)**
   - Mandatory if annual turnover exceeds TZS 200 million
   - Voluntary registration available below threshold
   - Done through TRA iTax system

3. **Business License (Local Government)**
   - Applied at Municipal/District Council
   - Class A: From Ministry of Industry, Trade & Investment
   - Class B: From Local Government Authority
   - Cost: TZS 50,000 - 300,000 (varies by municipality and business type)
   - Service levy: up to 0.3% of turnover
   - Timeline: 1-4 weeks

4. **Sector-Specific Licenses**
   - Food/restaurant: TFDA (Tanzania Food and Drug Authority) permit
   - Health services: Ministry of Health license
   - Transport: SUMATRA license
   - Mining: Mining Commission license
   - Financial services: Bank of Tanzania license

5. **Employer Registrations (if hiring)**
   - NSSF/PSSSF registration
   - WCF registration
   - OSHA compliance

### How TAJIRI Can Facilitate Registration
- Step-by-step guided wizard in Swahili
- Pre-fill forms with user's existing TAJIRI profile data (name, NIN, TIN)
- Direct links to BRELA ORS, TRA iTax
- Document checklist with progress tracking
- Cost calculator for each business type
- Push notification reminders for renewal dates (business license is annual)
- Store registration documents digitally (certificates, TIN)

---

## 3. Tanzania Tax Rates & Compliance (2025/2026)

### Corporate Income Tax
- **Standard rate:** 30%
- **DSE-listed companies (25%+ public shares):** 25% for first 3 years
- **Newly listed on DSE:** Reduced rate for initial period

### Value Added Tax (VAT)
- **Standard rate:** 18%
- **Reduced rate (from Sep 2025):** 16% when payment is through bank/electronic system to non-VAT-registered buyer
- **VAT registration threshold:** TZS 200 million annual turnover
- **VAT withholding (from Jul 2025):** 3% for goods, 6% for services

### PAYE (Pay As You Earn) — Monthly Brackets for Resident Individuals
| Monthly Income (TZS)  | Tax Rate |
|------------------------|----------|
| 0 - 270,000           | 0%       |
| 270,001 - 520,000     | 9%       |
| 520,001 - 760,000     | 20%      |
| 760,001 - 1,000,000   | 25%      |
| Above 1,000,000       | 30%      |

**Non-residents:** Flat 15%

### Employer Statutory Contributions
| Contribution | Rate     | Who Pays        | Notes                    |
|-------------|----------|-----------------|--------------------------|
| NSSF        | 20%      | 10% employer + 10% employee | Of gross monthly salary |
| SDL         | 3.5%     | Employer        | Employers with 10+ staff |
| WCF         | 0.5%     | Employer        | Of monthly wage bill     |

**Total employer burden:** ~14% on top of gross salary

### Withholding Tax Rates
- Dividends: 5% (resident), 10% (non-resident)
- Interest: 10%
- Royalties: 15%
- Service fees to non-residents: 15%
- Rent: 10%

### Electronic Fiscal Device (EFD) Requirements
- **Mandatory** for all VAT-registered businesses
- **VFD (Virtual Fiscal Device)** available as software alternative
- All businesses invoicing >TZS 14 million must use EFD/VFD
- EFD sends real-time transaction data to TRA's EFDMS
- TRA provides API for VFD integration (token-based auth, XML envelope format)
- VFD returns QR code for each receipt

### Key Tax Dates
- VAT returns: 20th of following month
- PAYE: 7th of following month
- Corporate tax: Provisional quarterly installments
- Annual return: Within 6 months of financial year end

---

## 4. Competitive Landscape Analysis

### Global Business Management Tools

#### Wave Accounting (Free)
- **Strengths:** Free invoicing, accounting, receipt scanning, financial reports
- **Weakness for TZ:** No mobile money support, no TZS, no Swahili, no EFD integration
- **Takeaway:** Prove that free model works; copy invoice and expense tracking UX

#### QuickBooks Online / Self-Employed
- **Strengths:** Comprehensive bookkeeping, bank feeds, tax reporting, mobile app
- **Weakness for TZ:** Expensive ($15-30/mo), no M-Pesa, English-only, overkill for micro businesses
- **Takeaway:** Good P&L and cash flow report formats to reference

#### Zoho Books / Invoice
- **Strengths:** Inventory management, multi-currency, good API, affordable
- **Weakness for TZ:** Still complex UI, no local payment integration
- **Takeaway:** Inventory + invoicing integration is a strong pattern

#### FreshBooks
- **Strengths:** Best-in-class invoicing UX, time tracking
- **Weakness for TZ:** Priced for Western market, no local relevance
- **Takeaway:** Invoice design and payment reminder patterns

#### Square
- **Strengths:** POS + invoicing + payments in one, inventory tracking
- **Weakness for TZ:** Not available in Tanzania
- **Takeaway:** The POS + everything model is exactly what TAJIRI should aim for

#### Shopify
- **Strengths:** E-commerce, inventory, orders, analytics
- **Weakness for TZ:** Expensive, designed for online-first (TZ is offline-first)
- **Takeaway:** Product catalog and order management patterns

### Africa/Tanzania Payment Platforms

#### Selcom (Tanzania) — TOP PRIORITY INTEGRATION
- **What:** Tanzania's largest payment aggregator
- **Features:** QR codes, till numbers, TanQR compatibility, all mobile networks, card payments
- **API:** Available at developers.selcommobile.com
- **2025 Update:** Launched "Pay by Link" with Visa — merchant sends payment link/QR
- **Integration value:** Accept M-Pesa, Tigo Pesa, Airtel Money, bank cards through single API
- **Status:** Widely adopted by Tanzanian merchants

#### Pesapal (East Africa)
- **What:** Regional payment gateway (Kenya, TZ, UG, RW, MW)
- **Features:** 10+ payment methods, M-Pesa, Tigo Pesa, Airtel Money, Visa/MC, USSD
- **API:** Well-documented, easy to integrate
- **Extras:** Sabi POS terminal, merchant dashboard
- **Integration value:** Regional expansion-ready, comprehensive payment methods

#### Lipa Na M-Pesa (Vodacom Tanzania)
- **What:** Vodacom's merchant payment solution (since 2016)
- **Setup:** Contact m-pesabusiness@vodacom.co.tz, KYC, get till number
- **Features:** M-Pesa Business app for tracking sales, balance, transactions, multi-store management
- **Integration value:** Most used payment method in TZ; TAJIRI could reconcile M-Pesa statements

#### DPO Group / Network International
- **What:** Pan-African payment gateway
- **Features:** 250+ payment methods across Africa, strong card processing
- **Integration value:** Good for cross-border if TAJIRI expands regionally

#### Tanda (Cellulant)
- **What:** Digital payments infrastructure across Africa
- **Features:** Merchant payments, disbursements, collections
- **Integration value:** Bulk payment disbursements (e.g., for payroll)

### Key Insight: No Single Tool Dominates
There is NO dominant "all-in-one" business management app for Tanzanian SMEs. The market is fragmented:
- M-Pesa Business app for payment tracking
- Paper ledgers for bookkeeping
- WhatsApp for customer communication
- Nothing for inventory or tax compliance

**This is TAJIRI's opportunity** — be the first Swahili-first, mobile-money-native, all-in-one business management platform integrated into a social network.

---

## 5. Tanzania-Specific Business Needs

### "Duka la Rejareja" (Retail Shop) — Most Common Business
- Track daily sales ("mauzo ya leo")
- Know which products sell best
- Track stock levels and know when to reorder
- Manage customer credit ("deni")
- Reconcile M-Pesa collections with cash
- Calculate daily profit

### "Mama Lishe" (Food Vendor)
- Track daily ingredients cost vs. revenue
- Manage repeat customers and credit
- Simple daily cash tracking
- No need for complex inventory (perishables)

### "Fundi" (Artisan/Handyman)
- Job/project tracking
- Quote/invoice generation
- Material cost tracking per job
- Customer contact management
- Schedule management

### Universal Needs Across All Types
1. **"Mauzo ya Leo" (Today's Sales)** — Simple daily sales entry screen
2. **"Deni" (Debt/Credit Tracking)** — Who owes me, how much, since when
3. **"Faida" (Profit)** — Daily/weekly/monthly profit calculation
4. **"Bidhaa" (Stock)** — What do I have, what's running low
5. **"Wateja" (Customers)** — Contact list with purchase history
6. **"Risiti" (Receipt)** — Digital receipt generation (bilingual)
7. **"Ripoti" (Reports)** — Simple visual charts of business performance
8. **"M-Pesa Yangu" (My Mobile Money)** — Consolidated view of all mobile money transactions

### The "Deni" Problem — Deserves Special Attention
Credit sales are a fundamental part of Tanzanian business culture:
- Shopkeepers routinely sell on credit to regular customers
- Tracking is done in exercise books that get lost, damaged, or disputed
- A digital debt tracker with customer confirmation (via SMS/TAJIRI message) would be revolutionary
- Features needed: Record debt, set due date, send reminder, customer confirms receipt, payment tracking, partial payment support

---

## 6. Prioritized Feature List for TAJIRI Business Module

### TIER 1 — MVP (Must Have First) — "Mauzo Yangu" (My Sales)

These features solve the most urgent pain points with minimal complexity.

#### 1.1 Daily Sales Tracker ("Mauzo ya Leo")
- One-tap sale entry: amount + optional item name
- Cash vs. M-Pesa toggle
- Running daily total displayed prominently
- Daily, weekly, monthly summaries
- **Why first:** This is what every shopkeeper needs NOW

#### 1.2 Debt Tracker ("Deni Zangu")
- Record: Customer name, amount, date, items
- Customer linked to phone contact or TAJIRI profile
- Send payment reminder via TAJIRI message or SMS
- Customer can confirm debt (digital "kusaini")
- Track partial payments
- Overdue alerts
- Debt aging report
- **Why first:** This solves the #1 business dispute in Tanzania

#### 1.3 Simple Expense Tracker ("Matumizi")
- Quick expense entry with category
- Categories: Stock purchase, rent, transport, salary, mobile money fees, other
- Receipt photo capture (optional)
- **Why first:** Without expenses, you can't show profit

#### 1.4 Daily Profit Calculator ("Faida ya Leo")
- Auto-calculated: Total sales - Total expenses = Profit
- Visual daily/weekly/monthly chart
- Trend arrow (up/down vs. previous period)
- **Why first:** This is the "aha moment" — many business owners have NEVER known their actual profit

#### 1.5 Business Profile Setup
- Business name, type, location
- Business registration status (registered/unregistered)
- Upload business documents (TIN, license)
- Business phone number, operating hours
- **Why first:** Foundation for everything else

### TIER 2 — Core Business Tools

#### 2.1 Product/Service Catalog ("Bidhaa Zangu")
- Add products with name, price, cost, photo
- Categories/groups
- Barcode scanning (camera-based)
- Link products to sales entries
- **Value:** Enables inventory and better reporting

#### 2.2 Inventory Management ("Stoki")
- Stock levels per product
- Low stock alerts (customizable threshold)
- Stock-in (purchases) and stock-out (sales) tracking
- COGS calculation
- Stock valuation summary
- **Value:** Prevents stockouts, the #2 business problem

#### 2.3 Invoice & Receipt Generation ("Risiti")
- Create professional invoices in Swahili or English
- QR code for mobile money payment
- Share via WhatsApp, TAJIRI message, or SMS
- Payment status tracking (paid/unpaid/partial)
- Auto-numbering
- Business logo/branding
- **Value:** Formalization step, enables digital payment collection

#### 2.4 Customer Database ("Wateja Wangu")
- Customer name, phone, location
- Purchase history
- Credit history
- Last purchase date
- Customer notes
- Import from phone contacts
- **Value:** Foundation for CRM and debt tracking

#### 2.5 Mobile Money Reconciliation
- Manual entry of M-Pesa/Tigo Pesa transactions
- (Future: API integration with Selcom for automatic reconciliation)
- Match mobile money receipts to sales
- Cash vs. mobile money daily split
- **Value:** Answers "how much came through M-Pesa today?"

### TIER 3 — Business Growth Tools

#### 3.1 Business Registration Assistant ("Sajili Biashara")
- Step-by-step registration wizard
- Business type selector with cost estimates
- Direct links to BRELA ORS, TRA iTax
- Document checklist (NIN, TIN, Articles of Association)
- Registration status tracker
- Annual renewal reminders
- **Value:** Lowers barrier to formalization

#### 3.2 Tax Calculator & Compliance ("Kodi Zangu")
- Auto-calculate VAT on sales (18%/16%)
- PAYE calculator for employees
- Employer contribution calculator (NSSF 10%, SDL 3.5%, WCF 0.5%)
- Tax calendar with reminders
- Estimated quarterly tax payments
- Export data for tax filing
- **Value:** Demystifies tax, reduces TRA anxiety

#### 3.3 Simple Payroll ("Mishahara")
- Employee list with salary amounts
- Auto-calculate: PAYE + NSSF (employee) + NSSF (employer) + SDL + WCF
- Net pay calculation
- Pay slip generation (bilingual)
- Payment tracking (paid/unpaid per month)
- **Value:** Critical for businesses with 1-10 employees

#### 3.4 Financial Reports ("Ripoti")
- Profit & Loss statement (monthly/quarterly/annual)
- Cash flow summary
- Revenue by product/service
- Expense breakdown by category
- Tax summary
- Export to PDF
- **Value:** Unlocks loan eligibility + business insights

#### 3.5 Business Analytics Dashboard
- Revenue trends (line chart)
- Best-selling products (bar chart)
- Customer insights (top customers, frequency)
- Expense breakdown (pie chart)
- Debt outstanding summary
- Cash vs. mobile money split
- **Value:** Data-driven decision making

### TIER 4 — Advanced / Differentiators

#### 4.1 POS Mode ("Sehemu ya Mauzo")
- Quick-sell grid with product photos
- Cart with running total
- Accept cash or mobile money
- Auto-deduct from inventory
- Auto-generate receipt
- Works offline with sync
- **Value:** Full point-of-sale replacement

#### 4.2 EFD/VFD Integration
- Connect to TRA EFDMS via VFD API
- Auto-generate EFD receipts with QR code
- Real-time reporting to TRA
- **Value:** Legal compliance, premium feature for formal businesses

#### 4.3 Supplier Management
- Supplier database
- Purchase order creation
- Payment tracking to suppliers
- Supplier credit management ("deni kwa msambazaji")
- **Value:** Complete supply chain visibility

#### 4.4 Multi-Branch/Employee Access
- Assign employees to business with roles
- Employee can enter sales, view stock
- Owner gets consolidated view
- Branch-level reporting
- **Value:** Scales with growing businesses

#### 4.5 Business Loans Readiness Score
- Analyze business data to show "loan readiness"
- Connect to TAJIRI Boost loans
- Generate financial summary for loan application
- **Value:** Direct monetization + financial inclusion

---

## 7. Cross-Module Integration Opportunities

### Existing TAJIRI Modules and Integration Points

#### TAJIRI Shop (Marketplace) <-> Business Module
- **Current state:** Shop has products, cart, orders, seller analytics (`lib/screens/shop/`)
- **Integration:** 
  - Products listed in Shop auto-sync to Business inventory
  - Sales from Shop auto-appear in daily sales tracker
  - Stock deducted from inventory on Shop sale
  - Shop seller analytics enhanced with Business financial data
  - Business invoices can be sent for Shop orders

#### TAJIRI Wallet <-> Business Module
- **Current state:** Wallet with balance, transactions, PIN (`lib/services/wallet_service.dart`)
- **Integration:**
  - Wallet transactions auto-categorized as business income/expense
  - Pay invoices directly from wallet
  - Receive invoice payments into wallet
  - Business balance vs. personal balance separation
  - Payroll disbursement from wallet

#### TAJIRI Loans (Boost) <-> Business Module
- **Current state:** Credit score, loan application, loan tiers (`lib/loans/`)
- **Integration:**
  - Business financial data feeds credit score calculation
  - Consistent sales history = higher loan tier
  - Loan proceeds deposited to business wallet
  - Loan repayments tracked in business expenses
  - Business P&L auto-attached to loan application
  - "Loan Readiness Score" widget in Business dashboard

#### TAJIRI Insurance <-> Business Module
- **Current state:** Insurance products, policies, claims (`lib/insurance/`)
- **Integration:**
  - Recommend business insurance based on business type
  - Stock insurance based on inventory value
  - Employee insurance products
  - Claims linked to business events
  - Insurance premiums tracked as business expense

#### TAJIRI Biashara (Ads) <-> Business Module
- **Current state:** Ad campaigns, balance, targeting (`lib/screens/biashara/`)
- **Integration:**
  - Promote business directly from business profile
  - Ad spending tracked as business marketing expense
  - Campaign performance linked to sales uptick
  - Quick "Boost this product" from inventory

#### TAJIRI Feed <-> Business Module
- **Integration:**
  - Post products/services to feed from business catalog
  - Business profile card in posts
  - "Shop from this business" CTA on business posts
  - Customer reviews/testimonials in feed

#### TAJIRI Messages <-> Business Module
- **Integration:**
  - Send invoices via message
  - Debt reminders via message
  - Customer inquiry auto-linked to customer record
  - Order updates via message
  - Business chat mode with quick-reply templates

#### TAJIRI Kikoba (VICOBA) <-> Business Module
- **Current state:** Savings groups, contributions, loans (`lib/kikoba/`)
- **Integration:**
  - Kikoba savings linked to business capital
  - Kikoba loan repayment in business expenses
  - Business performance data for Kikoba loan decisions

---

## 8. Implementation Phases

### Phase 1: Foundation (4-6 weeks)
**Goal:** "Every Tanzanian shopkeeper can track daily sales and debts"

- Business profile setup screen
- Daily sales entry (cash + M-Pesa toggle)
- Debt tracker (add debt, mark paid, send reminder)
- Simple expense entry
- Daily profit display
- Swahili-first UI
- Offline storage with Hive (sync when online)

**Backend endpoints needed:**
- POST/GET /api/business/profile
- POST/GET /api/business/sales
- POST/GET/PUT /api/business/debts
- POST/GET /api/business/expenses
- GET /api/business/summary (daily/weekly/monthly)

### Phase 2: Product & Inventory (3-4 weeks)
**Goal:** "Know what you sell, how much you have"

- Product catalog CRUD
- Barcode scanner integration
- Stock tracking (in/out)
- Low stock alerts
- Link products to sales
- Customer database

**Backend endpoints needed:**
- CRUD /api/business/products
- POST/GET /api/business/stock-movements
- GET /api/business/stock-alerts
- CRUD /api/business/customers

### Phase 3: Invoicing & Payments (3-4 weeks)
**Goal:** "Get paid faster, look professional"

- Invoice generation (Swahili/English)
- QR code for payment
- Payment tracking
- Share via WhatsApp/Message
- Selcom/Pesapal payment integration
- Mobile money reconciliation

**Backend endpoints needed:**
- CRUD /api/business/invoices
- POST /api/business/invoices/{id}/send
- POST /api/business/payments/reconcile
- Selcom webhook integration

### Phase 4: Tax & Compliance (2-3 weeks)
**Goal:** "Never be surprised by TRA"

- Tax calculator (VAT, PAYE, NSSF, SDL, WCF)
- Tax calendar with push notifications
- Business registration wizard
- P&L and cash flow reports
- Export to PDF

### Phase 5: Advanced Features (4-6 weeks)
**Goal:** "Run your entire business from TAJIRI"

- POS mode
- Simple payroll
- EFD/VFD integration
- Multi-branch support
- Business analytics dashboard
- Loan readiness score
- Cross-module integrations

---

## 9. Technical Architecture Notes

### Module Structure (following existing patterns)
```
lib/
  business/
    business_module.dart          # Entry point (like InsuranceModule)
    models/
      business_models.dart        # Business, Sale, Debt, Expense, Product, etc.
    services/
      business_service.dart       # API service (static methods, token param)
      business_database.dart      # Hive offline storage
    pages/
      business_home_page.dart     # Dashboard
      daily_sales_page.dart       # Mauzo ya Leo
      debt_tracker_page.dart      # Deni Zangu
      expenses_page.dart          # Matumizi
      products_page.dart          # Bidhaa Zangu
      inventory_page.dart         # Stoki
      invoices_page.dart          # Risiti
      customers_page.dart         # Wateja
      tax_calculator_page.dart    # Kodi
      reports_page.dart           # Ripoti
      registration_wizard_page.dart # Sajili Biashara
      payroll_page.dart           # Mishahara
      pos_page.dart               # POS Mode
    widgets/
      sale_entry_card.dart
      debt_card.dart
      product_card.dart
      daily_summary_card.dart
      profit_chart.dart
```

### State Management
- Follow existing pattern: `setState()` in StatefulWidgets
- Business data cached in Hive via `business_database.dart`
- Offline-first: write to Hive immediately, sync to server when online
- `ValueNotifier<BusinessSyncStatus>` for sync state

### Offline-First Strategy (Critical for Tanzania)
- All Tier 1 features MUST work offline
- Hive boxes for: sales, expenses, debts, products, stock
- Sync queue for pending uploads
- Conflict resolution: last-write-wins with server timestamp
- Sync indicator in UI (green dot = synced, orange = pending, red = failed)

### Localization
- All strings through `AppStrings` with `isSwahili` ternary pattern
- Invoices/receipts support language toggle
- Number formatting: TZS with comma thousands separator
- Date formatting: Swahili month names option

### Payment Integration Priority
1. **Selcom** — Primary (covers all mobile money + cards in TZ)
2. **Pesapal** — Secondary (regional expansion)
3. **Direct M-Pesa API** — For Lipa Na M-Pesa till reconciliation
4. **TRA VFD API** — For EFD receipt generation

---

## Key Recommendations

### Start With "Mauzo ya Leo" (Today's Sales)
The single most impactful first feature is a dead-simple daily sales tracker. If a shopkeeper opens TAJIRI at the end of the day and sees "Today you made TZS 450,000 in sales, TZS 120,000 in expenses, profit TZS 330,000" — that alone is transformative. Most have never seen that number.

### Make Debt Tracking Social
The debt tracker should leverage TAJIRI's social features. When a customer acknowledges a debt through the app, it creates a verifiable record. Payment reminders through TAJIRI Messages are less confrontational than phone calls. This turns a painful social interaction into a smooth digital one.

### Free Forever for Core Features
Tier 1 and Tier 2 features must be completely free. Monetize through:
- Payment processing fees (Selcom/Pesapal markup)
- EFD/VFD integration (premium)
- Business loans (interest)
- Business insurance commissions
- Promoted business listings
- Business analytics premium tier

### Build for the Exercise Book
Design every screen as if replacing one page of an exercise book. The daily sales page replaces the "mauzo" page. The debt page replaces the "deni" page. The stock page replaces the "bidhaa" page. Users should recognize the digital equivalent instantly.

---

## Sources

- [BRELA ORS — Online Registration System](https://ors.brela.go.tz/)
- [BRELA ORS Registration Steps (Miamia)](https://miamia.co.tz/en/start-business/register-business/brela-online-registration-system-ors-register-business-in-tanzania/)
- [Register a Local Company via BRELA ORS](https://miamia.co.tz/en/start-business/register-business/register-local-company-ors-brela-tanzania/)
- [Company Registration Fees in Tanzania 2026](https://gerpatsolutions.co.tz/company-registration-fees-in-tanzania/)
- [How to Register a Limited Company in Tanzania 2026](https://www.bieastafrica.com/tanzania-company-registration.html)
- [BRELA Company Registration Fees — Local Company](https://miamia.co.tz/en/start-business/register-business/brela-company-registration-fees-local-company/)
- [Tanzania Tax System 2026 Guide (Zatra)](https://www.zatra.co/post/tax-system-in-tanzania-for-foreign-investors-corporate-tax-vat-investment-incentives-2026-guide)
- [Tanzania Corporate Tax — PwC](https://taxsummaries.pwc.com/tanzania/corporate/taxes-on-corporate-income)
- [Tanzania Other Taxes — PwC](https://taxsummaries.pwc.com/tanzania/corporate/other-taxes)
- [VAT in Tanzania Guide (TanzaniaInvest)](https://www.tanzaniainvest.com/vat)
- [Tanzania Finance Act 2025 Highlights (Afriwise)](https://www.afriwise.com/blog/tanzania-tax-update-finance-act-2025-highlights)
- [Tanzania Tax Rates & Payroll Compliance 2026 (Zatra)](https://www.zatra.co/post/tanzania-tax-rates-payroll-compliance-2026-complete-guide-for-businesses-investors-employers)
- [Tanzania Employment Law 2026](http://employerofrecordtanzania.com/employment-law.html)
- [How to Calculate PAYE in Tanzania 2026](https://www.jaynevytours.com/how-to-calculate-paye-in-tanzania.html)
- [Tanzania Individual Taxes — PwC](https://taxsummaries.pwc.com/tanzania/individual/taxes-on-personal-income)
- [KAZI BOX Employment Tax Rates](https://kazibox.co.tz/employment-tax-rates/)
- [Tanzania PAYE Calculator](https://rtoccheck.com/paye)
- [Selcom Tanzania](https://www.selcom.net/)
- [Selcom Developer API](https://developers.selcommobile.com/)
- [Selcom Lipa — Merchant Payments](https://www.selcom.net/selcom-pay-)
- [Selcom + Visa Pay by Link](https://www.selcom.net/selcomdigest/2025/12/11/selcom-and-visa-launch-pay-by-link-to-simplify-digital-payments-in-tanzania)
- [Pesapal API Integrations](https://www.pesapal.com/business/online/api-plugins)
- [Tanzania Payment Gateway Guide 2025 (ClickPesa)](https://clickpesa.com/ultimate-tanzania-payment-gateway-guide-in-2025/)
- [M-Pesa Business Tanzania Onboarding](https://business.m-pesa.com/vodacom-tanzania/business-onboarding-tanzania/)
- [Lipa Kwa Simu M-Pesa](https://vodacom.co.tz/lipa-kwa-simu)
- [TRA Electronic Fiscal Devices](https://www.tra.go.tz/page/know-about-e-fiscal-devices-efd)
- [TRA VFD API Documentation](https://tra-docs.netlify.app/guide/api/)
- [VFD Tanzania](https://www.vfd.co.tz/)
- [Electronic Invoice in Tanzania (EDICOM)](https://edicomgroup.com/blog/the-electronic-invoice-in-tanzania)
- [Fueling SME Growth in Tanzania's Digital Era](https://www.smartafrica.group/read/fueling-sme-growth-in-tanzanias-digital-era)
- [Tanzania SME Market Landscape (TICGL)](https://ticgl.com/unpacking-tanzanias-sme-market-landscape/)
- [Tanzania Business Registration Guide (TanzaniaInvest)](https://www.tanzaniainvest.com/economy/trade/company-registration-guide)
- [Obtain a Business License — TNBP](https://business.go.tz/obtain-a-business-license)
- [Business Licenses in Tanzania (Fablig)](https://www.fabligconsulting.co.tz/business-licenses-in-tanzania/)
