# Fungu la Kumi (Tithe & Offering) — Feature Description

## Tanzania Context

"Fungu la Kumi" literally means "the tenth portion" — the Swahili term for tithe. Tithing is widely practiced across Tanzanian churches, with most denominations teaching the principle of giving 10% of income. Beyond tithes, Tanzanian churches collect various offerings: sadaka (general offering), zaka (first fruits/harvest offering), michango (special contributions for building projects, pastor support, etc.), and sadaka ya shukrani (thanksgiving offering).

Currently, most giving happens in cash during services — envelopes are common in Catholic and mainline Protestant churches. M-Pesa giving is emerging but poorly tracked. Churches struggle with transparency in financial reporting, and givers lack personal records. There is growing demand for digital giving, especially among young urban professionals who may not carry cash.

## International Reference Apps

1. **Tithe.ly** — Church giving platform with mobile payments, recurring gifts, giving statements
2. **Pushpay** — Digital giving for churches with engagement tools and donor management
3. **Givelify** — Simple mobile giving app, visual envelope system, giving history
4. **Church Center (Planning Center)** — Integrated giving with church management
5. **Faithlife Giving** — Low-fee church giving with integration to church software

## Feature List

1. Record tithe — log tithe amount, date, and destination church
2. Record offerings — categorized: sadaka, zaka, michango, sadaka ya shukrani, missions
3. M-Pesa integration — pay tithe/offering directly to church M-Pesa till/paybill number
4. Recurring giving — set up automatic weekly/monthly tithe via M-Pesa standing order
5. Giving history — full timeline of all tithes and offerings with filters
6. Annual summary — yearly giving report with totals by category and monthly breakdown
7. Tax receipts — generate giving statements for tax purposes (PDF download)
8. Pledge tracking — make pledges for building projects or special campaigns, track progress
9. Church fund transparency — view church fundraising goals and congregation progress
10. Giving reminders — weekly/monthly reminder notifications before pay day
11. Income tracking (optional) — log income to auto-calculate 10% tithe amount
12. Multiple churches — support giving to more than one church or ministry
13. Giving goals — set personal annual giving target, track progress
14. Offering envelope system — digital version of traditional envelope categories
15. Gift acknowledgment — receive confirmation from church when gift is recorded
16. Spending breakdown — see how church allocates funds (if church opts to share)

## Key Screens

- **Giving Dashboard** — total given this month/year, giving streak, next reminder
- **Give Now** — amount entry, category selector, church selector, M-Pesa payment flow
- **Giving History** — filterable list by date range, category, church
- **Annual Statement** — summary cards by category, monthly chart, download PDF
- **Pledge Manager** — active pledges with progress bars, payment schedule
- **Recurring Gifts** — manage automatic giving schedules
- **Church Giving Page** — church's public giving page with active campaigns
- **Income & Tithe Calculator** — enter income, see 10% calculation, quick give

## TAJIRI Integration Points

- **WalletService.deposit(amount, provider:'mpesa')** — primary payment channel for all tithe and offering transactions via M-Pesa; supports recurring weekly/monthly tithe, sadaka, zaka, and michango payments
- **ContributionService.createCampaign(), donate()** — church building fund crowdfunding campaigns; congregation progress tracking; michango contributions for group fundraising
- **NotificationService + FCMService** — M-Pesa payment confirmations, pledge reminders, campaign milestone updates, pay day giving reminders
- **CalendarService.createEvent()** — pay day reminders synced with giving reminders; pledge payment schedule on calendar
- **ProfileService.getProfile()** — giving statistics visible on faith profile (opt-in, private by default)
- **EventTrackingService** — personal giving trends and patterns over time; annual giving analytics
- **LiveUpdateService** — real-time offering totals during church services; campaign progress updates
- **Cross-module: Kanisa Langu** — church receives tithes and offerings; church-specific giving campaigns with acknowledgments from church admin via GroupService
- **Cross-module: kikoba/ module** — church savings groups (Vikoba vya Kanisa) for collective church financial goals
