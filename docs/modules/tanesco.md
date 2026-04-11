# TANESCO (Electricity Services) — Feature Description

## Tanzania Context

TANESCO (Tanzania Electric Supply Company Limited / Shirika la Umeme Tanzania) is the state-owned electric utility responsible for generation, transmission, and distribution of electricity across mainland Tanzania. Zanzibar has its own utility (ZECO).

**Electricity system overview:**
- National electrification rate: approximately 40% (78% urban, 24% rural), rapidly expanding under REA (Rural Energy Agency)
- Generation mix: hydropower (~35%), natural gas (~50%), liquid fuels, solar, wind
- Two billing systems: Prepaid (LUKU) and Postpaid
- LUKU (Lipa Umeme Kabla ya Kutumia) — prepaid metering system, most common for residential
- Tariff categories: Domestic (D1), General Use (T1-T3), Industrial (T4), Agriculture, etc.
- Domestic tariff: approximately TZS 100-350 per kWh depending on consumption tier
- REA rural electrification has dramatically expanded grid access in recent years
- Mini-grids and solar home systems filling gaps in remote areas

**LUKU prepaid system:**
- Purchase tokens via M-Pesa, Tigo Pesa, Airtel Money, or TANESCO offices
- Token entered on meter keypad to load units (kWh)
- Meter number is the unique identifier (typically 11-13 digits)
- Minimum purchase: TZS 1,000
- Tokens delivered via SMS after mobile money payment
- Token recharge: *150*00# (Vodacom M-Pesa), USSD varies by network

**Pain points:**
- Power outages (Kukatika umeme) are frequent and often unannounced — massive economic impact
- LUKU tokens sometimes fail to load on meters — error codes confusing
- Postpaid billing errors common — disputed bills hard to resolve
- New connection applications take months despite payment
- Meter tampering crackdowns sometimes affect legitimate customers
- Emergency disconnections for infrastructure work not communicated in advance
- Customer service lines perpetually busy; TANESCO offices have long queues
- Estimated bills for postpaid when meter readers don't visit
- Power surges damage appliances — no compensation mechanism
- Token purchase via USSD often fails during peak hours

## International Reference Apps

1. **Octopus Energy (UK)** — Smart energy app: real-time consumption, cost tracking, tariff comparison, smart meter integration, green energy options. Best-in-class utility UX.
2. **OhmConnect (US)** — Energy monitoring, usage alerts, demand response rewards, consumption analytics, smart device integration.
3. **Eskom Se Push (South Africa)** — Load shedding schedules, push notifications for power outages, area-based alerts. Massively popular due to reliability issues.
4. **KPLC MyPower (Kenya)** — Kenya Power app: buy tokens, report outages, check balance, view consumption, new connections. Regional benchmark.
5. **Prepaid24 (South Africa)** — Buy prepaid electricity tokens online/in-app, transaction history, meter management, multiple meters.

## Feature List

1. **Buy LUKU Tokens** — Purchase prepaid electricity tokens via M-Pesa, Tigo Pesa, Airtel Money, or TAJIRI wallet with instant token delivery
2. **Multiple Meters** — Save and manage multiple meter numbers (home, office, rental properties, family members)
3. **Token History** — Complete purchase history: dates, amounts, units (kWh), meter numbers, payment method
4. **Balance Check** — Check remaining LUKU units/balance on meter (where supported by meter type)
5. **Consumption Analytics** — Track electricity usage over time: daily, weekly, monthly charts with cost breakdown
6. **Usage Alerts** — Push notification when units drop below customizable threshold (e.g., below 10 kWh)
7. **Auto-Recharge** — Set up automatic LUKU purchase when balance drops below threshold
8. **Report Power Outage** — Report electricity outage with location, time, and affected area; see if others in area have reported
9. **Outage Map** — Real-time map of reported outages in your area with TANESCO status updates
10. **Planned Maintenance** — View scheduled power outages for your area with dates, times, and affected zones
11. **Postpaid Bill View** — View current and historical postpaid electricity bills with payment status
12. **Postpaid Payment** — Pay postpaid bills via mobile money or TAJIRI wallet
13. **Bill Dispute** — Submit disputes for incorrect postpaid bills with meter reading photo evidence
14. **New Connection Application** — Apply for new electricity connection with document upload, fee payment, and status tracking
15. **Connection Status Tracker** — Track new connection application: Applied > Surveyed > Approved > Materials > Connected
16. **Meter Reading Submission** — Submit your own meter reading with photo for postpaid accounts
17. **Tariff Calculator** — Estimate monthly cost based on appliances and usage hours
18. **Appliance Calculator** — See how much each appliance costs to run per hour/day/month
19. **Energy Saving Tips** — Practical tips to reduce electricity consumption and costs
20. **TANESCO Office Finder** — Map of TANESCO regional and district offices with services and contacts
21. **Emergency Contacts** — Report fallen power lines, electrical fires, electrocution risks
22. **Token Error Help** — Troubleshooting guide for common LUKU meter error codes

## Key Screens

- **Home** — Meter card(s) with balance, quick buy button, outage alert banner, recent purchases
- **Buy Tokens** — Meter selection, amount input, payment method, confirmation, token display
- **Consumption Dashboard** — Usage charts (daily/weekly/monthly), cost trends, comparison to previous periods
- **My Meters** — List of saved meters with balances, quick actions (buy, history, report)
- **Outage Center** — Map of outages, report form, planned maintenance schedule, status updates
- **Bills** — Postpaid bill list with amounts, due dates, payment status, pay button
- **New Connection** — Application form with document checklist, fee calculator, submit and track
- **Tariff Calculator** — Appliance picker with hours/day sliders, showing estimated monthly cost
- **Energy Tips** — Illustrated energy-saving recommendations organized by room/appliance
- **Help** — Error code troubleshooting, FAQ, TANESCO contacts, emergency numbers

## TAJIRI Integration Points

- **WalletService** — `deposit(amount, provider:'mpesa')` as primary payment channel for LUKU token purchases and postpaid bill payments; `getTransactions()` for complete token purchase history with meter numbers and kWh amounts; auto-recharge triggers `deposit()` when balance drops below threshold
- **MessageService** — `sendMessage()` for sending LUKU tokens to family members via TAJIRI messaging; forwarding token codes
- **NotificationService + FCMService** — Push alerts for low LUKU balance (customizable threshold), area outage notifications, planned maintenance schedules, token purchase confirmations, postpaid bill due dates
- **CalendarService** — `createEvent()` for planned maintenance dates, postpaid bill due dates synced to TAJIRI calendar
- **LocationService** — `getRegions()`, `getDistricts()`, `getWards()` for GPS-based outage reporting, nearest TANESCO office finder, area-based maintenance alerts
- **GroupService** — `createGroup()` for neighborhood groups for outage reporting and community power status sharing; `getMembers()` for area-based alert distribution
- **PhotoService** — `uploadPhoto()` for meter reading photos (postpaid), bill dispute evidence, new connection application documents
- **LocalStorageService** — Offline caching of LUKU error code troubleshooting guide, energy saving tips, tariff calculator, emergency contacts
- **MediaCacheService** — Cache bills, receipts, and connection documents
- **LiveUpdateService** — Real-time outage status updates via Firestore; connection application progress tracking
- **FriendService** — `getFriends()` for managing family members' meters and topping up their electricity
- **EventTrackingService** — Analytics on consumption patterns, token purchase frequency, outage duration tracking
- **PostService** — `createPost()` for sharing outage reports and area-wide power status in community feed
- **Cross-module: dawasco** — Combined utility dashboard: electricity + water services and payments in one view
- **Cross-module: bills/** — TANESCO payments tracked in TAJIRI bills management; consolidated utility bill view
- **Cross-module: housing/** — Meter management linked to property records; meter numbers associated with property profiles
- **Cross-module: ewura** — EWURA energy regulation information; tariff change notifications from energy regulator
- **Cross-module: my_family/** — Manage family members' meters across multiple properties
