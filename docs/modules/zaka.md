# Zaka (Zakat Calculator) — Feature Description

## Tanzania Context

"Zaka" is the Swahili word for Zakat, the obligatory annual charity that is one of the five pillars of Islam. Every Muslim whose wealth exceeds the Nisab threshold (minimum amount, traditionally measured in gold or silver) must pay 2.5% of their qualifying wealth annually. In Tanzania, Zakat is managed informally — most Muslims calculate and distribute Zakat themselves or through their local mosque.

BAKWATA (Baraza Kuu la Waislamu Tanzania) and some mosques collect and distribute Zakat, but there is limited transparency and tracking. Many Tanzanian Muslims are uncertain about how to correctly calculate Zakat — which assets qualify (cash, gold, livestock, business inventory, agricultural produce), what debts can be deducted, and how to determine Nisab in Tanzanian Shillings. Agricultural Zakat (ushr) is relevant for farming communities. M-Pesa has created an opportunity for digital Zakat distribution, but no local platform connects Zakat payers with verified eligible recipients.

## International Reference Apps

1. **National Zakat Foundation** — Zakat calculator and distribution platform (UK/US/Canada)
2. **IslamicFinder Zakat Calculator** — Comprehensive web-based Zakat calculation tool
3. **Zakat Calculator (Islamic Relief)** — Simple calculator with asset categories
4. **Muslim Pro** — Basic Zakat calculator within broader Islamic app
5. **LaunchGood** — Muslim crowdfunding that facilitates Zakat-eligible campaigns

## Feature List

1. Zakat calculator — guided calculation with asset categories and deductions
2. Asset categories — cash/bank savings, gold/silver, business inventory, investments, livestock, agricultural produce, rental income
3. Debt deductions — subtract qualifying debts from total zakatable wealth
4. Nisab threshold — current Nisab in TZS (updated based on gold/silver prices)
5. Gold/silver price feed — live or regularly updated precious metal prices in TZS
6. Livestock Zakat — specific calculations for cattle, goats, sheep (relevant for pastoralist communities)
7. Agricultural Zakat (ushr) — 5% or 10% on agricultural produce depending on irrigation
8. Payment via M-Pesa — pay Zakat directly to mosques, organizations, or individuals
9. Sadaqah tracking — log voluntary charity separately from obligatory Zakat
10. Find eligible recipients — directory of verified Zakat-eligible individuals/organizations
11. Zakat distribution categories — show the 8 categories of eligible recipients (asnaf)
12. Annual summary — total Zakat paid, distribution breakdown, year-over-year comparison
13. Payment history — full record of all Zakat and Sadaqah payments
14. Reminders — annual Zakat due date reminder (based on personal Hijri anniversary)
15. Zakat al-Fitr — separate calculation for Ramadan obligatory charity per family member
16. Educational content — articles explaining Zakat rules, common questions, scholarly opinions
17. Receipt generation — payment receipts for personal records

## Key Screens

- **Zakat Home** — Nisab status, estimated Zakat due, last payment, due date countdown
- **Calculator** — step-by-step wizard: cash > gold > business > investments > livestock > debts > result
- **Asset Entry** — input forms for each asset category with helpful descriptions
- **Calculation Result** — total wealth, deductions, Nisab comparison, Zakat amount due
- **Pay Zakat** — select recipient (mosque, organization, individual), M-Pesa payment flow
- **Payment History** — timeline of all payments with recipient, amount, date
- **Find Recipients** — verified individuals/organizations by category and location
- **Zakat al-Fitr Calculator** — family member count, local food price, amount per person
- **Educational Section** — FAQs, articles, video explanations of Zakat rules

## TAJIRI Integration Points

- **WalletService.deposit(amount, provider:'mpesa')** — primary payment channel for Zakat distribution via M-Pesa; pay to mosques, organizations, or individuals; Zakat al-Fitr per family member
- **ContributionService.createCampaign(), donate()** — Zakat-eligible crowdfunding campaigns marked for Zakat distribution; community-organized Zakat collection campaigns; transparent distribution tracking
- **NotificationService + FCMService** — annual Zakat due date reminders (based on personal Hijri anniversary), Zakat al-Fitr reminders before Eid, payment confirmation alerts
- **ProfileService.getProfile()** — Zakat payment history on faith profile (private by default); giving milestones
- **EventTrackingService** — personal giving trends and charitable impact over time; year-over-year Zakat analytics
- **LiveUpdateService** — real-time Zakat collection totals for community campaigns; distribution progress updates
- **Cross-module: Ramadan** — Zakat al-Fitr calculator linked during Ramadan; family member count and local food price calculation
- **Cross-module: Kalenda Hijri** — annual Zakat due date tracking on Islamic calendar via CalendarService
- **Cross-module: Tafuta Msikiti** — mosques that accept Zakat payments identified in mosque listings via LocationService
