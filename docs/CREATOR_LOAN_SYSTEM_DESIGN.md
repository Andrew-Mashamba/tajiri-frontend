# TAJIRI Creator Loan System Design

## Executive Summary

A platform-integrated lending system where TAJIRI creators can access micro-loans and advances based on their on-platform earnings history and performance metrics, with automatic repayment through earnings deductions. This is modeled after global creator advance platforms (Karat Financial, Creative Juice, Braavo Capital) but adapted for the Tanzanian market, mobile money infrastructure, and Bank of Tanzania regulatory requirements.

---

## 1. Research Findings

### 1.1 Global Creator Advance/Loan Models

**Karat Financial** (raised $70M, backed by YC)
- Underwrites creators based on income sources, income predictability (e.g., Twitch subscriptions are "SaaS-like" and score higher than TikTok ad revenue), and social stats (follower count, growth rate, engagement)
- Average cardholder: 2M followers, $300K/year revenue
- Credit lines rather than one-off loans
- No traditional credit score required

**Creative Juice**
- Offers "Juice Boost" advances against future earnings from YouTube, Instagram, TikTok
- Fee: 3%-7% of advance amount (no origination or prepayment penalties)
- Revenue-sharing repayment over a defined period
- Also provides FDIC-insured banking, payment splitting, and client payment management

**Braavo Capital**
- Focuses on subscription app developers
- Analyzes Apple App Store / Google Play data (earned-but-not-yet-paid revenue)
- Advances against verifiable pending revenue
- Over $1B in financing facilitated since 2015

**Clearco (formerly Clearbanc)**
- Revenue-based financing: repayment = 1%-20% of monthly revenue
- Flat fee of 6%-12.5% depending on term (4-6 months)
- Repayment cap: typically 1.2x-1.6x the original amount
- Portfolio success rate exceeds 90%
- Average repayment: 6-18 months

**Willa**
- Invoice factoring for creators: pays immediately, charges 2.9% per invoice
- Addresses the 30-90 day payment delay from brands/agencies
- Not a loan -- more like instant payment processing

**Sound Royalties / Music Advances**
- Advances $3K-$20M+ against future royalty streams
- Repayment only from royalty income, not personal funds
- No personal guarantees, non-credit-based underwriting
- Minimum threshold: $3K/month in streaming/AdSense revenue

**Key Takeaway:** The best creator lending models use platform-native data (earnings history, engagement, subscriber stability) rather than traditional credit scores, and repayment is tied to the revenue stream itself.

### 1.2 Tanzanian Digital Lending Landscape

**Mobile Money Lending Products:**
- **M-Pawa** (Vodacom/CBA Tanzania): 30-day loans, 9% monthly interest, typical amounts TZS 2,000-50,000 ($0.80-$20). Scoring based on mobile money usage, savings behavior, and transaction patterns
- **M-Shwari** (Safaricom/CBA Kenya, similar model): 30-day loans, 7.5% monthly interest. Uses telecom data for credit scoring
- **Timiza** (Airtel Money): Similar micro-loan structure
- **Songesha** (Halotel): Airtime advance model

**Scoring Methodology:**
- Transaction history (frequency, volume, consistency)
- Savings behavior (deposits, maintenance of balance)
- Phone usage patterns (data, calls, duration of SIM ownership)
- Repayment history on previous loans
- Users actively "train" their scores by making regular deposits/withdrawals

**Market Statistics (2024-2025):**
- 60.75M active mobile money accounts (17.5% growth)
- Digital loan accounts: 193.33M (doubled year-over-year)
- Total digital loan value: TZS 226.7B
- Women hold 61.9% of digital loan accounts
- MFI default rates: 49% of MFIs report 5-10% default rates; 27% report >10%
- Banking sector NPL ratio improved to 4.3% (end-2023)
- Average bank lending rate: ~16%

**Regulatory Framework:**
- Bank of Tanzania (BoT) regulates digital lenders under Microfinance Act 2018 (amended)
- All digital lenders must hold a Tier 2 Microfinance Service Provider license
- Minimum capital requirement: TZS 20M for individual lender
- Maximum acceptable interest rate: 4% per month (BoT guidance, though not a hard statutory cap)
- Mandatory requirements: transparent pricing, fair debt collection, data protection, customer privacy
- Non-compliance penalties: sanctions, suspension, license revocation
- BoT Guidance Note issued August 27, 2024 specifically targets digital lending oversight

### 1.3 Revenue-Based Financing Mechanics

**How Automatic Deductions Work:**
- A fixed percentage of gross earnings is withheld at the source (before payout to creator)
- Typical deduction range: 5%-25% of gross revenue
- Payments fluctuate with earnings -- higher earnings = faster repayment
- Total repayment cap: 1.2x-1.6x original loan amount (this is the "factor rate")
- Schedule: daily, weekly, or monthly deductions depending on revenue frequency

**Safe Deduction Percentages:**
- Conservative: 5%-10% (preserves creator cash flow, slower repayment)
- Standard: 10%-15% (balanced approach)
- Aggressive: 15%-25% (faster repayment, may strain creator finances)
- Industry consensus: never exceed 20% for sustainable lending

**Grace Periods and Flexibility:**
- Most RBF products have no fixed term -- repayment continues until cap is reached
- If earnings drop to zero, payments pause (no default trigger)
- Some products offer 30-60 day grace periods before deductions begin
- Minimum payment thresholds: deductions only apply when earnings exceed a floor

**Default Handling When Earnings Drop:**
- Revenue-based models inherently reduce default risk (no payment when no revenue)
- True default only occurs if creator leaves the platform entirely
- Mitigation: withhold final wallet balance, extend repayment period, reduce deduction %
- Clearco reports 90%+ portfolio success rate with this model

---

## 2. Recommended Loan Scheme Design for TAJIRI

### 2.1 Product Name

**"TAJIRI Boost"** (Swahili: "Kichocheo cha TAJIRI")

The name connotes empowerment and acceleration, aligned with TAJIRI's brand meaning ("wealthy/prosperous").

### 2.2 Core Concept

TAJIRI Boost is a **revenue advance** product, not a traditional loan. Creators receive an advance against their verified future earnings, repaid automatically through a percentage deduction from ongoing platform earnings. This is legally and operationally distinct from a consumer loan in important ways, though Tanzanian regulatory compliance is still required (see Section 7).

### 2.3 Eligibility Requirements

A creator must meet ALL of the following to qualify:

| Requirement | Minimum Threshold |
|---|---|
| Account age | 90 days (3 months) |
| Verified identity (KYC) | Full KYC complete (national ID + phone verified) |
| Connected mobile money | At least 1 verified M-Pesa/Tigo Pesa/Airtel Money account |
| Active earnings history | At least 3 months of consecutive earnings |
| Minimum monthly earnings | TZS 50,000/month average over last 3 months (~$20) |
| Creator Score | Minimum 40/100 (see scoring below) |
| No outstanding TAJIRI Boost | Must repay existing advance before taking another |
| Account in good standing | No active violations, suspensions, or content strikes |

### 2.4 Loan Products (3 Tiers)

All amounts in TZS. Exchange rate reference: 1 USD ~ 2,500 TZS.

#### Tier 1: "Chanzo" (Source) -- Micro Advance

| Parameter | Value |
|---|---|
| Target | New/small creators just starting to earn |
| Advance amount | TZS 25,000 - 200,000 ($10-$80) |
| Maximum | 1x average monthly earnings (last 3 months) |
| Fee | 5% flat fee (e.g., borrow 100K, repay 105K) |
| Effective monthly rate | ~1.67% over 3 months |
| Repayment period | Up to 90 days (3 months) |
| Earnings deduction | 10% of all platform earnings |
| Minimum Creator Score | 40/100 |
| Grace period | 7 days before deductions begin |
| Minimum monthly earnings | TZS 50,000 |

#### Tier 2: "Msaada" (Support) -- Growth Advance

| Parameter | Value |
|---|---|
| Target | Established creators with consistent earnings |
| Advance amount | TZS 200,000 - 1,000,000 ($80-$400) |
| Maximum | 2x average monthly earnings (last 6 months) |
| Fee | 7% flat fee |
| Effective monthly rate | ~1.17% over 6 months |
| Repayment period | Up to 180 days (6 months) |
| Earnings deduction | 12% of all platform earnings |
| Minimum Creator Score | 60/100 |
| Grace period | 14 days |
| Minimum monthly earnings | TZS 150,000 |
| Minimum account age | 6 months |
| Minimum earnings history | 6 consecutive months |

#### Tier 3: "Nguvu" (Power) -- Premium Advance

| Parameter | Value |
|---|---|
| Target | Top creators with strong, predictable earnings |
| Advance amount | TZS 1,000,000 - 5,000,000 ($400-$2,000) |
| Maximum | 3x average monthly earnings (last 12 months) |
| Fee | 10% flat fee |
| Effective monthly rate | ~0.83% over 12 months |
| Repayment period | Up to 365 days (12 months) |
| Earnings deduction | 15% of all platform earnings |
| Minimum Creator Score | 75/100 |
| Grace period | 14 days |
| Minimum monthly earnings | TZS 500,000 |
| Minimum account age | 12 months |
| Minimum earnings history | 12 consecutive months |
| Additional requirement | Must have at least 2 revenue sources (e.g., subscriptions + tips) |

**Why flat fees instead of monthly interest:**
- Simpler for creators to understand (no compounding confusion)
- Aligns with BoT transparency requirements
- Effective rates are well below the 4%/month BoT maximum
- Follows the Clearco/Creative Juice model proven in creator economies

### 2.5 Revenue Sources Eligible for Deduction

Based on TAJIRI's existing wallet/earnings infrastructure:

| Revenue Source | Deduction Applies | Weight in Scoring |
|---|---|---|
| Subscription earnings | Yes | High (most predictable, SaaS-like) |
| Tips (Tuzo) | Yes | Medium (voluntary, variable) |
| Gifts (Zawadi) | Yes | Medium (event-driven) |
| Shop sales | Yes | Medium-High (product-based, somewhat predictable) |
| Creator Fund payouts | Yes | High (algorithmically determined, consistent) |
| Live stream earnings | Yes | Low-Medium (session-dependent) |
| Tea Warmup tips | Yes | Low (small amounts, occasional) |
| Ad revenue share | Yes | Medium-High (scales with views) |
| Campaign/sponsored content | Yes (if paid through platform) | Medium |

**Deduction is applied at the wallet level** -- before any withdrawal to mobile money. This is the key risk mitigation: TAJIRI controls the payment pipeline.

---

## 3. Creator Credit Score ("TAJIRI Score")

### 3.1 Score Range

0-100 points, mapped to the existing CreatorScore model (which already has community, quality, and consistency sub-scores).

### 3.2 Scoring Components

| Component | Weight | Description | Data Source |
|---|---|---|---|
| **Earnings Stability** | 30% | Coefficient of variation of monthly earnings. Lower variance = higher score. Measures predictability. | Wallet transaction history |
| **Earnings Growth** | 10% | Month-over-month earnings trend. Positive growth scores higher. | Wallet transaction history |
| **Revenue Diversification** | 10% | Number of distinct revenue sources (subscriptions, tips, shop, fund). More sources = less risk. | Earnings breakdown by type |
| **Platform Tenure** | 10% | Months since account creation, weighted by active months. Longer = more reliable. | Account creation date, activity log |
| **Content Consistency** | 15% | Posting streak, posting frequency, content calendar adherence. Maps to existing CreatorStreak model. | CreatorStreak.currentStreakDays, postsThisWeek |
| **Engagement Quality** | 10% | Engagement rate (likes + comments + shares / views). Higher engagement = more sustainable audience. | Post analytics |
| **Community Score** | 10% | Existing CreatorScore.communityScore -- subscriber retention, follower-to-subscriber ratio. | CreatorScore model |
| **Repayment History** | 5% | Track record on previous TAJIRI Boost advances. Perfect repayment = max score. New borrowers get neutral (2.5/5). | Loan history (new data) |

### 3.3 Score Calculation

```
tajiri_loan_score = (
  earnings_stability * 0.30 +
  earnings_growth * 0.10 +
  revenue_diversification * 0.10 +
  platform_tenure * 0.10 +
  content_consistency * 0.15 +
  engagement_quality * 0.10 +
  community_score * 0.10 +
  repayment_history * 0.05
)
```

Each component is normalized to 0-100 before weighting.

### 3.4 Scoring Details

**Earnings Stability (30%):**
- Calculate coefficient of variation (CV) = standard_deviation / mean of monthly earnings
- CV < 0.2 (very stable) = 100 points
- CV 0.2-0.4 = 80 points
- CV 0.4-0.6 = 60 points
- CV 0.6-0.8 = 40 points
- CV > 0.8 (highly volatile) = 20 points

**Earnings Growth (10%):**
- 3-month rolling average vs 6-month rolling average
- Growing (>10% increase) = 100 points
- Stable (-10% to +10%) = 70 points
- Declining (10-30% decrease) = 40 points
- Sharply declining (>30% decrease) = 10 points

**Revenue Diversification (10%):**
- 1 source = 20 points
- 2 sources = 50 points
- 3 sources = 75 points
- 4+ sources = 100 points

**Platform Tenure (10%):**
- 3-6 months = 30 points
- 6-12 months = 60 points
- 12-24 months = 80 points
- 24+ months = 100 points

**Content Consistency (15%):**
- Maps from CreatorStreak: currentStreakDays and posting frequency
- Active streak 30+ days = 100 points
- Active streak 14-29 days = 75 points
- Active streak 7-13 days = 50 points
- Active streak 1-6 days = 25 points
- No streak / frozen = 10 points

**Engagement Quality (10%):**
- Engagement rate > 8% = 100 points
- 5-8% = 80 points
- 3-5% = 60 points
- 1-3% = 40 points
- < 1% = 20 points

**Community Score (10%):**
- Directly maps from existing CreatorScore.communityScore (already 0-100)

**Repayment History (5%):**
- No previous loans = 50 points (neutral)
- All loans repaid on time = 100 points
- Late repayment (completed) = 60 points
- Currently delinquent = 0 points

### 3.5 Score Tiers and Loan Access

| Score Range | Tier Name | Access |
|---|---|---|
| 0-39 | Mwanzo (Beginning) | No loan access. Build your score. |
| 40-59 | Chanzo (Source) | Tier 1 only. Up to 1x monthly earnings. |
| 60-74 | Msaada (Support) | Tier 1 + Tier 2. Up to 2x monthly earnings. |
| 75-100 | Nguvu (Power) | All tiers. Up to 3x monthly earnings. |

---

## 4. Repayment Mechanism

### 4.1 Automatic Earnings Deduction

```
On every earning event (subscription payment, tip, gift, shop sale, fund payout):
  1. Calculate gross_earning amount
  2. If creator has active TAJIRI Boost:
     a. deduction = gross_earning * deduction_percentage (10/12/15%)
     b. Apply deduction to loan balance
     c. Net earning = gross_earning - deduction
     d. Credit net_earning to creator's wallet
  3. If no active advance:
     a. Credit full gross_earning to creator's wallet
```

### 4.2 Repayment Rules

- **Deductions apply to ALL platform earnings** (not just one revenue type)
- **Minimum deduction threshold**: Skip deduction if earning event < TZS 500 (to avoid micro-penny deductions)
- **Accelerated repayment**: Creator can voluntarily pay down from wallet balance at any time (no penalty)
- **Grace period**: 7-14 days after disbursement before first deduction (tier-dependent)
- **Monthly earnings floor**: If total monthly earnings fall below TZS 10,000, deduction percentage drops to 5% (hardship protection)
- **Repayment cap**: Total repayment never exceeds advance amount + flat fee (no hidden interest accumulation)
- **Full repayment**: Once total deductions = advance + fee, the advance is marked complete, deductions stop immediately

### 4.3 What Happens When Earnings Drop

| Scenario | Response |
|---|---|
| Earnings decrease 20-50% | Automatic: reduce deduction to 5%. Send notification encouraging content creation. |
| Earnings near zero for 30+ days | Pause deductions. Send gentle nudge. Extend repayment period by equivalent pause duration. |
| No earnings for 60+ days | Flag for manual review. Attempt outreach (push notification, SMS). Keep advance open but paused. |
| No earnings for 90+ days | Mark as "at risk." Deduct from remaining wallet balance if any. If creator returns, resume deductions at reduced rate. |
| Creator deletes account / permanent departure | Deduct remaining balance from final wallet withdrawal. If wallet insufficient, write off remainder (cost of doing business). Report to internal risk database. |

### 4.4 Disbursement

- Advance amount credited directly to creator's TAJIRI wallet
- Creator can withdraw to their verified mobile money account
- Disbursement within 1-24 hours after approval (instant for Tier 1, manual review for Tier 3)

---

## 5. Risk Management

### 5.1 Portfolio Risk Controls

| Control | Detail |
|---|---|
| **Maximum portfolio exposure** | Never lend more than 20% of total creator earnings pool for the past quarter |
| **Individual cap** | No advance exceeds 3x average monthly earnings regardless of score |
| **Concentration limit** | No single creator holds more than 2% of total outstanding advances |
| **Reserve fund** | Maintain 15% of outstanding advances as loss reserve (funded from platform fees) |
| **Default write-off budget** | Expect 5-8% default rate (aligned with Tanzanian MFI benchmarks) |

### 5.2 Fraud Prevention

- **Identity verification**: Full KYC (national ID) required before any advance
- **Earnings verification**: Only platform-verified earnings count (not self-reported)
- **Cooling period**: 30-day waiting period after first successful advance before second is available
- **Velocity checks**: Flag creators whose earnings spike abnormally before loan application (possible manipulation via fake purchases)
- **Connected account verification**: Mobile money account must be in the creator's own name
- **Device fingerprinting**: Flag if multiple loan applications come from same device for different accounts

### 5.3 Early Warning System

Monitor these signals and reduce loan limits / pause new advances:

- Creator's posting frequency drops below 50% of their average
- Engagement rate drops more than 40% month-over-month
- Subscriber count declining for 2+ consecutive months
- Creator hasn't logged in for 7+ days
- Wallet withdrawal of >80% of balance immediately after advance disbursement (cash-and-run signal)

### 5.4 Collections Escalation

Since this is revenue-based, traditional "collections" is largely replaced by automatic deduction. However:

1. **Day 0-90 past repayment deadline**: Continue automatic deduction at agreed rate
2. **Day 90+ with minimal progress**: Reduce future advance eligibility. Send formal notice via SMS and in-app
3. **Day 180+ with <25% repaid**: Creator flagged as "default." Block future advances permanently. Deduct any remaining wallet balance. Report to internal risk database
4. **No aggressive collections**: No third-party collectors, no public shaming, no account lockout (the creator needs the platform to earn money to repay)

---

## 6. Integration with Existing TAJIRI Infrastructure

### 6.1 Models to Leverage (Already Exist)

| Model | Usage |
|---|---|
| `CreatorScore` (flywheel_models.dart) | Base for TAJIRI loan score. Already has community, quality, consistency sub-scores and tier system |
| `CreatorStreak` (flywheel_models.dart) | Content consistency scoring. `currentStreakDays`, `streakMultiplier` |
| `CreatorFundPayout` (payment_models.dart) | Earnings history for creator fund payouts. Has `payoutAmount`, `status` |
| `WeeklyReport` (payment_models.dart) | `totalEarnings`, `earningsChangePercent`, `engagementTrend` for scoring |
| `EarningsSummary` (subscription_models.dart) | Subscription/tip/gift earnings breakdown |
| `Wallet` (wallet_models.dart) | `balance`, `pendingBalance` for disbursement |
| `WalletTransaction` (wallet_models.dart) | Transaction history for earnings verification |
| `MobileMoneyAccount` (wallet_models.dart) | Verified payout accounts for disbursement |
| `FundPayoutProjection` (flywheel_models.dart) | Projected future earnings for advance sizing |

### 6.2 New Models Needed

```dart
// lib/models/loan_models.dart

class CreatorLoan {
  final int id;
  final int userId;
  final String tier;              // 'chanzo', 'msaada', 'nguvu'
  final double advanceAmount;     // Original advance amount
  final double feeAmount;         // Flat fee
  final double totalRepayable;    // advanceAmount + feeAmount
  final double amountRepaid;      // How much has been repaid so far
  final double deductionPercent;  // 10, 12, or 15
  final String status;            // 'pending', 'active', 'repaid', 'defaulted', 'paused'
  final DateTime appliedAt;
  final DateTime? approvedAt;
  final DateTime? disbursedAt;
  final DateTime? completedAt;
  final DateTime? gracePeriodEndsAt;
  final DateTime repaymentDeadline;
  final double creatorScoreAtApplication;
  final double avgMonthlyEarningsAtApplication;
}

class LoanApplication {
  final int id;
  final int userId;
  final String tier;
  final double requestedAmount;
  final String status;            // 'pending', 'approved', 'rejected', 'expired'
  final String? rejectionReason;
  final double creatorScore;
  final double avgMonthlyEarnings;
  final DateTime createdAt;
}

class LoanRepayment {
  final int id;
  final int loanId;
  final double amount;
  final String source;            // 'subscription', 'tip', 'gift', 'shop_sale', 'creator_fund', 'voluntary'
  final int? sourceTransactionId;
  final DateTime createdAt;
}

class LoanEligibility {
  final bool isEligible;
  final String? ineligibleReason;
  final double creatorScore;
  final String maxTier;           // 'chanzo', 'msaada', 'nguvu'
  final double maxAdvanceAmount;
  final double avgMonthlyEarnings;
  final int monthsOfEarnings;
  final Map<String, double> scoreBreakdown;
}
```

### 6.3 New Service Needed

```dart
// lib/services/loan_service.dart

class LoanService {
  /// Check creator's loan eligibility
  Future<LoanEligibility> checkEligibility(int userId);
  
  /// Apply for a TAJIRI Boost advance
  Future<LoanApplication> applyForAdvance({
    required int userId,
    required String tier,
    required double amount,
  });
  
  /// Get active loan details
  Future<CreatorLoan?> getActiveLoan(int userId);
  
  /// Get loan history
  Future<List<CreatorLoan>> getLoanHistory(int userId);
  
  /// Get repayment history for a specific loan
  Future<List<LoanRepayment>> getRepayments(int loanId);
  
  /// Make voluntary repayment from wallet
  Future<bool> makeVoluntaryRepayment({
    required int loanId,
    required double amount,
  });
  
  /// Get loan score breakdown
  Future<Map<String, double>> getScoreBreakdown(int userId);
}
```

### 6.4 Backend API Endpoints Needed

```
POST   /api/loans/eligibility          - Check eligibility
POST   /api/loans/apply                - Submit application
GET    /api/loans/active               - Get active loan
GET    /api/loans/history              - Get loan history
GET    /api/loans/{id}                 - Get loan details
GET    /api/loans/{id}/repayments      - Get repayment history
POST   /api/loans/{id}/repay           - Voluntary repayment
GET    /api/loans/score-breakdown      - Detailed score components
```

### 6.5 Wallet Service Modification

The existing `WalletService` / backend wallet logic needs modification to intercept earnings and apply loan deductions before crediting to the creator's available balance. This is a **backend change** -- the earnings crediting pipeline must check for active loans and withhold the deduction percentage.

### 6.6 UI Screens Needed

```
lib/screens/loans/
  loan_home_screen.dart              - Overview: eligibility, active loan, CTA
  loan_application_screen.dart       - Application form with tier selection, amount slider
  loan_details_screen.dart           - Active loan progress, repayment tracker
  loan_history_screen.dart           - Past advances
  loan_score_screen.dart             - Score breakdown with improvement tips
  loan_repayment_screen.dart         - Voluntary repayment
```

---

## 7. Regulatory Considerations for Tanzania

### 7.1 Licensing

**Critical requirement**: TAJIRI must obtain a **Tier 2 Microfinance Service Provider license** from the Bank of Tanzania before launching this product. Operating without a license is a criminal offense under the Microfinance Act 2018.

**Alternative approaches to reduce regulatory burden:**

1. **Partner with a licensed bank**: Like M-Pawa (Vodacom + CBA), TAJIRI could partner with a licensed Tanzanian bank that handles the actual lending. TAJIRI provides the data/scoring, the bank bears the credit risk and holds the license. Revenue share model.

2. **Structure as merchant cash advance (MCA)**: Instead of calling it a "loan," structure it as a purchase of future receivables. This may fall outside traditional lending regulation, but BoT has shown intent to regulate broadly. Legal counsel is essential.

3. **Apply for Tier 2 license directly**: Minimum capital TZS 20M (~$8,000). More control but more regulatory overhead.

**Recommended approach**: Partner with a licensed bank (option 1). This is how M-Pawa and M-Shwari operate, and it is the proven model in East Africa.

### 7.2 Interest Rate Compliance

- BoT maximum acceptable rate: 4% per month
- TAJIRI Boost effective rates: 0.83%-1.67% per month (well within limits)
- All fees must be disclosed upfront before the creator accepts the advance
- APR equivalent must be displayed (even though it's a flat fee, regulators want transparency)

### 7.3 Consumer Protection Requirements

Per BoT August 2024 Guidance Note:

- **Transparent pricing**: Show total cost of advance (amount + fee + any other charges) clearly before acceptance
- **Fair debt collection**: No harassment, no public shaming, no excessive contact
- **Data protection**: Creator financial data used for scoring must be handled per Tanzania's data protection requirements
- **Right to information**: Creator must be able to see their score, understand why they were approved/rejected
- **Cooling-off period**: Allow cancellation within 48 hours of disbursement (return full amount, no fee charged)
- **Complaint mechanism**: In-app complaints process with BoT escalation path

### 7.4 KYC / AML Requirements

- National ID verification (NIDA)
- Phone number verification
- Mobile money account in creator's own name
- Transaction monitoring for suspicious patterns
- Reporting obligations to Tanzania Financial Intelligence Unit (FIU) for transactions above threshold

### 7.5 Tax Implications

- Fee income from advances is taxable revenue for TAJIRI
- Creators should be informed that advance amounts are not taxable (it's their own future earnings, advanced early)
- Platform should provide annual earnings statements that distinguish between earnings and advance disbursements

---

## 8. Financial Projections and Unit Economics

### 8.1 Assumptions

- 10,000 active creators on TAJIRI earning money
- 15% of earning creators are eligible for Tier 1 (1,500)
- 5% eligible for Tier 2 (500)
- 1% eligible for Tier 3 (100)
- Take-up rate: 40% of eligible creators take an advance
- Average advance size: Tier 1 = TZS 100K, Tier 2 = TZS 500K, Tier 3 = TZS 2M

### 8.2 Revenue Model

| Metric | Tier 1 | Tier 2 | Tier 3 | Total |
|---|---|---|---|---|
| Eligible creators | 1,500 | 500 | 100 | 2,100 |
| Take-up (40%) | 600 | 200 | 40 | 840 |
| Avg advance | TZS 100K | TZS 500K | TZS 2M | -- |
| Total advances | TZS 60M | TZS 100M | TZS 80M | TZS 240M |
| Fee rate | 5% | 7% | 10% | -- |
| Fee revenue | TZS 3M | TZS 7M | TZS 8M | **TZS 18M** |
| Default rate (est.) | 8% | 5% | 3% | -- |
| Default losses | TZS 4.8M | TZS 5M | TZS 2.4M | TZS 12.2M |
| **Net revenue** | -- | -- | -- | **TZS 5.8M** |

Net revenue of ~TZS 5.8M per cycle (~$2,320) is modest initially. The real value is **creator retention** -- creators with active advances have strong incentive to keep creating content and earning on TAJIRI.

### 8.3 Capital Requirements

- Total outstanding advances at any time: ~TZS 240M (~$96,000)
- Loss reserve (15%): TZS 36M (~$14,400)
- Total capital needed: ~TZS 276M (~$110,000)
- If partnering with a bank, TAJIRI may only need to provide the scoring/technology layer, and the bank provides the capital

---

## 9. Implementation Phases

### Phase 1: Foundation (Month 1-2)
- Implement TAJIRI Loan Score calculation on backend (leveraging existing CreatorScore, CreatorStreak, earnings data)
- Build loan eligibility check API
- Create score breakdown screen in app (helps creators understand their standing even before loans launch)

### Phase 2: Tier 1 Launch (Month 3-4)
- Implement loan application flow (backend + frontend)
- Modify wallet earnings pipeline to support automatic deductions
- Build loan dashboard screen
- Launch Tier 1 ("Chanzo") to a beta group of 100 creators
- Monitor default rates and deduction mechanics

### Phase 3: Scale (Month 5-6)
- Launch Tier 1 to all eligible creators
- Launch Tier 2 ("Msaada") in beta
- Implement voluntary repayment
- Build repayment history and loan history screens

### Phase 4: Full Launch (Month 7-9)
- Launch all three tiers
- Implement early warning system
- Add loan score improvement tips/nudges
- Regulatory filing (if partnering with bank, formalize agreement)

### Phase 5: Optimization (Month 10+)
- ML-based scoring refinement using actual repayment data
- Dynamic fee pricing based on risk
- Repeat advance offers for good-standing creators
- Consider "line of credit" model for top creators (revolving facility)

---

## 10. Summary of Key Design Decisions

| Decision | Rationale |
|---|---|
| Flat fee instead of interest | Simpler, transparent, compliant with BoT, follows creator economy norms |
| Revenue-based repayment | Eliminates fixed payment stress, aligns incentives, reduces defaults |
| Platform-native scoring | Uses data TAJIRI already has, no external credit bureau dependency |
| Subscription earnings weighted highest | Most predictable/SaaS-like revenue, per Karat Financial's proven model |
| 3-tier system | Matches TAJIRI's existing creator tier structure, progressive trust |
| Maximum 3x monthly earnings | Conservative limit prevents over-leveraging (industry standard is 2-4x) |
| Bank partnership recommended | Proven model in East Africa (M-Pawa, M-Shwari), reduces regulatory risk |
| Automatic deduction at source | TAJIRI controls the payment pipeline, making this the lowest-risk lending model possible |
| No aggressive collections | Creators must stay on platform to repay -- punitive actions are counterproductive |

---

## Sources

- [Creator Banking 2025: Karat vs Creative Juice Review](https://www.influencers-time.com/creator-banking-in-2025-karat-and-creative-juice-reviews/)
- [Karat builds financial products for creators using Stripe](https://stripe.com/customers/karat)
- [Karat raises $70M (TechCrunch)](https://techcrunch.com/2023/07/19/karat-a-startup-building-financial-tools-for-content-creators-raises-70m/)
- [Creative Juice launches $50M fund (TechCrunch)](https://techcrunch.com/2022/04/20/creative-juice-investment-creators-youtube/)
- [Karat Financial (Y Combinator)](https://www.ycombinator.com/companies/karat-financial)
- [TikTok Shop Seller Loans & Financing](https://credilinq.ai/blogs/tik-tok-shop-seller-financing)
- [Clearco Review 2026](https://www.unitedcapitalsource.com/business-loans/lender-reviews/clearbanc-review/)
- [Clearco Revenue-Based Financing](https://www.clear.co/blog/revenue-based-financing)
- [Braavo Capital - On-demand funding for apps](https://www.getbraavo.com/)
- [Willa - Creator Payments](https://www.willapay.com/)
- [How Revenue-Based Repayment Works (Onramp Funds)](https://www.onrampfunds.com/resources/how-revenue-based-repayment-works)
- [Revenue-Based Financing Guide 2026 (RE-CAP)](https://www.re-cap.com/financing-instruments/revenue-based-financing)
- [Sound Royalties - YouTube Financing](https://soundroyalties.com/youtubefinancing/)
- [Digital Lending in East Africa (Tanzania Digest)](https://tanzaniadigest.com/digital-lending-in-east-africa-growth-regulation-and-the-future-of-fintech-innovation/)
- [BoT Approved Digital Lending Platforms](https://www.bot.go.tz/Other/REGISTER%20OF%20LIST%20OF%20APPROVED%20DIGITAL%20LENDING%20PLATFORMS.pdf)
- [BoT Guidance on Digital Loans for Tier 2 MSPs](https://www.tanzaniainvest.com/finance/banking/bot-2023-guidance-digital-loans-tier-2-microfinance-service-providers)
- [Tanzania Government Regulates Digital Loans](https://www.tanzaniainvest.com/finance/banking/government-to-regulates-digital-loans-and-high-interest-rates)
- [Tanzania bans unlicensed digital lenders](https://www.connectingafrica.com/fintech/tanzania-bans-unlicensed-digital-lenders)
- [BoT Guidance Note on Digital Lenders (2024 PDF)](https://bot.go.tz/Publications/Acts,%20Regulations,%20Circulars,%20Guidelines/Guidelines/en/2024082813141188.pdf)
- [Tanzania Financial Inclusion Index 2024](https://www.tanzaniainvest.com/finance/bot-financial-inclusion-report-2024)
- [Tanzania Banking Sector Report 2024](https://www.tanzaniainvest.com/finance/banking/tanzania-banking-sector-report/3)
- [Consumer Credit in Tanzania (Lendsqr)](https://blog.lendsqr.com/a-deep-overview-of-consumer-credit-in-tanzania/)
- [Digital Credit Regulation in Tanzania (AFI)](https://www.afi-global.org/sites/default/files/publications/2020-11/AFI_DFS_Tanzania_CS_AW2-digital.pdf)
- [How to get a lending license in Tanzania (Lendsqr)](https://blog.lendsqr.com/how-to-get-a-lending-license-tanzania/)
- [M-Shwari: How It Works (CGAP)](https://www.cgap.org/sites/default/files/Forum-How-M-Shwari-Works-Apr-2015.pdf)
- [M-Pawa Consumer Protection (CGAP)](https://www.cgap.org/blog/digital-credit-consumer-protection-for-m-shwari-and-m-pawa-users)
- [M-Pawa Savings Experiment (FinDev)](https://www.findevgateway.org/sites/default/files/publications/files/cgap_m-pawa_paper_may_11_2017_d_0_dis.pdf)
