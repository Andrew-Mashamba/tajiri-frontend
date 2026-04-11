# DAWASCO (Water Services) — Feature Description

## Tanzania Context

DAWASCO (Dar es Salaam Water and Sewerage Corporation) manages water supply and sewerage services in Dar es Salaam, Tanzania's largest city (~6 million people). DAWASA (Dar es Salaam Water and Sewerage Authority) owns the infrastructure while DAWASCO operates it. Outside Dar, water is managed by regional water utilities (e.g., MWAUWASA in Mwanza, AUWSA in Arusha, MUWASA in Moshi).

**Water supply reality:**
- DAWASCO serves approximately 1.5 million connections but demand far exceeds supply
- Water supply is intermittent — most areas receive water 8-16 hours per day, some only 2-4 hours
- Only ~65% of Dar es Salaam has piped water access; remainder uses boreholes, water vendors, or natural sources
- Non-Revenue Water (NRW) estimated at 50%+ due to leaks, theft, and unmetered connections
- Water quality concerns in some areas — many residents boil or treat water
- Sewerage coverage is extremely low (<10% of Dar connected to sewer network); most use pit latrines or septic tanks

**Billing system:**
- Metered billing: TZS 862/m3 for first 5 m3 (domestic), increasing in tiers
- Minimum monthly charge applies even with zero consumption
- Bills issued monthly, payment due within 14 days
- Payment via M-Pesa, banks, DAWASCO offices, or water kiosks
- Postpaid metering dominant; prepaid water meters being piloted
- Standing charge + consumption charge structure

**Pain points:**
- Water supply extremely unreliable — residents never know when water will come
- Bills arrive for periods when no water was supplied — citizens expected to pay minimum charge
- Meter reading inconsistent — estimated bills common and often inflated
- Leaks reported but take weeks or months to fix, wasting thousands of liters
- New connection applications take 3-12 months despite full payment
- Illegal connections rampant, reducing pressure for legal customers
- Bill payment channels unreliable — M-Pesa often fails for DAWASCO payments
- Customer service virtually non-existent — complaints go unresolved
- Sewerage blockages cause health hazards but response is slow
- Water tanker (bowser) service for dry areas is expensive and unregulated

## International Reference Apps

1. **Thames Water App (UK)** — Report leaks, check service status, view/pay bills, submit meter readings, track jobs, water-saving tips.
2. **Sydney Water App (Australia)** — Pay bills, submit meter readings, report problems, water usage tracker, outage notifications, water efficiency tools.
3. **Philly311 Water (US)** — Report water main breaks, hydrant issues, flooding, sewer problems with GPS location and photo.
4. **KIWASCO App (Kenya)** — Kisumu Water: pay bills, report leaks, check supply schedule, new connection application. Regional comparison.
5. **WaterSmart (US)** — Water utility customer engagement: usage analytics, leak detection alerts, neighbor comparison, conservation tips.

## Feature List

1. **Pay Water Bill** — Pay current and outstanding water bills via M-Pesa, Tigo Pesa, Airtel Money, or TAJIRI wallet
2. **Bill History** — View all historical bills: billing period, consumption (m3), charges, payments, balance
3. **Current Balance** — Check outstanding balance and next bill estimate
4. **Meter Reading Submission** — Submit your own meter reading with photo of meter dial to ensure accurate billing
5. **Consumption Analytics** — Track water usage trends: monthly consumption in cubic meters, cost charts, comparison to previous periods
6. **Water Supply Schedule** — View your area's water supply schedule (which hours/days water is available) — community-sourced and DAWASCO-published
7. **Supply Status** — Real-time community reports of water availability/outage in your area
8. **Report Leak** — Report water pipe leaks with GPS location, photo, severity indicator, and description
9. **Report Sewerage Issue** — Report blocked sewers, overflows, or sewerage problems with location and photos
10. **Issue Tracking** — Track reported leaks and issues: Reported > Acknowledged > Crew Dispatched > Fixed
11. **New Connection Application** — Apply for new water connection: select connection type, upload documents, pay deposit, track progress
12. **Connection Types** — Compare connection options: domestic, commercial, institutional, standpipe/kiosk
13. **Reconnection Request** — Apply for reconnection after disconnection with arrears payment
14. **Account Management** — Update account details: owner name, phone number, address changes, meter number
15. **Tariff Information** — Current water tariff schedule with tier breakdowns and explanations
16. **Bill Dispute** — Submit billing disputes with meter reading evidence, previous bill comparisons
17. **Water Quality Reports** — Area-specific water quality testing results and safety advisories
18. **Water Saving Tips** — Practical tips for reducing water consumption and costs
19. **Tank Level Monitoring** — For users with smart tank sensors, track household water tank levels
20. **DAWASCO Office Finder** — Map of DAWASCO offices, customer service points, and payment centers
21. **Emergency Contacts** — Report burst mains, contamination, or other water emergencies
22. **Water Tanker Service** — Directory of registered water tanker services for areas without piped supply

## Key Screens

- **Home** — Account card with balance, supply status indicator, quick pay button, leak alert banner
- **Pay Bill** — Amount due, payment method selection, M-Pesa flow, confirmation and receipt
- **Bill History** — Monthly bills list with consumption bars, amount, payment status
- **Consumption Dashboard** — Usage charts, cost trends, month-on-month comparison
- **Supply Schedule** — Weekly calendar showing expected water supply hours for your area
- **Report Issue** — Photo + GPS + category (leak/sewerage/quality/pressure) + severity + description
- **My Reports** — List of submitted reports with status tracking
- **New Connection** — Application wizard: location > connection type > documents > payment > tracking
- **Meter Reading** — Camera-based meter photo capture with manual reading input
- **Water Tips** — Illustrated conservation tips organized by household area

## TAJIRI Integration Points

- **WalletService** — `deposit(amount, provider:'mpesa')` as primary payment channel for water bills and outstanding arrears; `getTransactions()` for bill payment history and digital receipts; reconnection fee payments after disconnection
- **MessageService** — `sendMessage()` for contacting DAWASCO support; `getConversations()` for tracking leak report and complaint communications
- **NotificationService + FCMService** — Push alerts for bill due dates (14-day payment window), supply schedule changes, leak report status updates, area water outage alerts, bill dispute resolutions
- **CalendarService** — `createEvent()` for bill due dates and water supply schedule synced to TAJIRI calendar; meter reading submission reminders
- **LocationService** — `getRegions()`, `getDistricts()`, `getWards()`, `getStreets()` for GPS-based leak reporting with precise location, nearest DAWASCO office finder, area-based supply schedules
- **GroupService** — `createGroup()` for neighborhood groups for supply status sharing and collective issue reporting; `getMembers()` for area-wide outage coordination
- **PhotoService** — `uploadPhoto()` for leak report photos with GPS metadata, meter reading photos for accurate billing, pipe burst documentation
- **LocalStorageService** — Offline caching of water saving tips, tariff schedules, emergency contacts, supply schedule for user's area
- **MediaCacheService** — Cache bills, receipts, and connection application documents
- **LiveUpdateService** — Real-time leak report status tracking via Firestore (Reported > Acknowledged > Crew Dispatched > Fixed); supply status community reports
- **FriendService** — `getFriends()` for managing family members' water accounts across properties
- **EventTrackingService** — Analytics on consumption trends, leak report resolution times, supply reliability metrics
- **PostService** — `createPost()` for sharing water supply status and outage reports in community feed
- **Cross-module: tanesco** — Combined utility dashboard: water + electricity services and payments in one view
- **Cross-module: bills/** — Water payments tracked in TAJIRI bills management; consolidated utility bill overview
- **Cross-module: housing/** — Water account linked to property records; meter numbers associated with housing profiles
- **Cross-module: my_family/** — Manage family members' water accounts across multiple locations
