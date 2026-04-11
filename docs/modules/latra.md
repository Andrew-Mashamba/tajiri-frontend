# LATRA (Land Transport Regulatory Authority) — Feature Description

## Tanzania Context

LATRA is the primary regulator of all land transport in Tanzania, established under the Land Transport Regulatory Authority Act, 2019. It replaced SUMATRA's land transport functions and regulates:

- **Public Service Vehicles (PSV):** Daladala (minibuses), buses, coasters operating on urban and intercity routes
- **Commercial vehicles:** Trucks, cargo carriers, tankers
- **Para-transit:** Boda-boda (motorcycle taxis), bajaji (three-wheelers/tuk-tuks)
- **Ride-hailing:** Uber, Bolt, InDriver — LATRA sets fare caps and licensing requirements

**How Citizens Interact:**
- Applying for PSV route licences (operators must get LATRA approval for specific routes)
- Registering as a boda-boda or bajaji operator
- Checking government-approved fare limits for specific routes
- Filing complaints against reckless/abusive drivers or conductors
- Reporting overcharging on regulated routes
- Checking if a transport operator is properly licensed

**Current Pain Points:**
- Application processes are paper-heavy and require physical visits to LATRA offices
- Fare regulations exist but most passengers don't know the approved fare for their route
- Complaint filing is bureaucratic — most passengers give up
- Boda-boda registration backlog is enormous (millions of operators, limited capacity)
- No real-time mechanism to report dangerous driving or harassment
- Intercity bus safety concerns (speeding, night travel accidents) with no easy reporting channel
- Ride-hailing fare caps are published but riders can't verify in real-time

## International Reference Apps

1. **NTSA (Kenya)** — Kenya's National Transport and Safety Authority app lets users check vehicle/driver details, report accidents, verify PSV compliance, and file complaints
2. **Transport for London (TfL)** — Journey planner, fare checker, real-time service status, complaint filing, operator licensing info
3. **LTA (Singapore)** — Land Transport Authority app with fare calculator, route planner, taxi fare estimator, public transport feedback
4. **DVLA (UK)** — Driver and Vehicle Licensing Agency — check vehicle tax, MOT status, driving licence validity online
5. **Grab (SE Asia)** — Ride-hailing with regulated fare display, driver ratings, in-app complaints, trip safety features

## Feature List

1. **Approved Routes & Fares** — Browse all LATRA-approved routes with official fare caps. Search by origin/destination. Covers daladala, bus, boda-boda, bajaji
2. **Fare Checker** — Enter pickup and dropoff to see the maximum approved fare. Alerts if being overcharged
3. **File Complaint** — Report a driver/conductor with vehicle plate number, route, incident type (overcharging, reckless driving, harassment, refusal of service). Attach photo/video evidence
4. **Complaint Tracking** — Track complaint status with reference number. View resolution timeline and outcome
5. **Operator Verification** — Check if a transport operator/company is licensed by LATRA. Verify vehicle registration status
6. **PSV Licence Status** — Track PSV licence application progress. View licence conditions and expiry
7. **Boda-Boda/Bajaji Registration** — Registration status check for motorcycle and three-wheeler operators. View registration requirements and documents needed
8. **Report Accident** — Quick accident reporting with location, vehicles involved, and severity. Auto-shares location via GPS
9. **Safety Alerts** — Push notifications for dangerous road conditions, suspended routes, or safety advisories
10. **Transport Safety Tips** — Educational content on passenger rights, safe travel practices, what to do in an accident
11. **Ride-Hailing Fare Caps** — Current LATRA-approved fare caps for Uber/Bolt/InDriver by city. Compare actual charged fare vs cap
12. **Intercity Bus Schedule** — Approved intercity bus operators, routes, and schedules. Safety ratings based on compliance history
13. **Driver/Conductor Rating** — Rate drivers and conductors after a trip. Aggregated ratings visible to other passengers
14. **Road Safety Statistics** — Accident statistics by route, region, and time period. Data visualizations and trends
15. **Nearest LATRA Office** — Find closest LATRA office with address, hours, contact, and services available

## Key Screens

- **Home Dashboard** — Quick access to fare checker, file complaint, and safety alerts
- **Route & Fare Browser** — Searchable list of all approved routes with fare caps
- **Fare Checker** — Origin/destination input with fare result and overcharge alert
- **Complaint Form** — Multi-step form with plate number, incident type, evidence upload
- **My Complaints** — List of filed complaints with status tracking
- **Operator Search** — Search and verify transport operators/vehicles
- **Safety Hub** — Tips, statistics, and emergency contacts
- **Bus Schedule** — Intercity bus timetable with operator details

## TAJIRI Integration Points

- **Wallet (WalletService)** — Pay for PSV licence application fees via `WalletService.deposit()` with M-Pesa/Tigo/Airtel STK push. Traffic fine payments processed through wallet. Boda-boda/bajaji registration fees paid via wallet. Transaction history via `WalletService.getTransactions()` shows all LATRA-related payments with reference numbers. Route licence renewal payments
- **Messaging (MessageService)** — Receive complaint resolution updates via `MessageService.sendMessage()`. LATRA officer communication for licence applications. Complaint follow-up conversations. Auto-created conversation per complaint for tracking correspondence
- **Groups (GroupService)** — Transport operator groups via `GroupService.createGroup()` — daladala operators, boda-boda associations, bajaji unions, intercity bus companies. Driver safety awareness groups. Passenger rights communities. Group posts via `GroupService.getGroupPosts()` for fare updates, route changes, and safety discussions. Regional transport groups (Dar es Salaam, Arusha, Mwanza)
- **Transport Module (transport/)** — Deep link from transport module for fare verification during trips — passengers check LATRA fare cap in real-time before or during ride. Fare checker integration with ride-hailing apps (Uber, Bolt, InDriver) to compare actual fare vs LATRA cap. Route planning with approved fare display. Licensed operator verification from transport booking screen
- **Notifications (FCMService + NotificationService)** — Push notifications via `FCMService` for: monthly fare cap updates, complaint status changes, safety warnings and advisories, suspended route alerts, licence application progress updates, intercity bus safety alerts, LATRA regulation changes, dangerous road condition warnings, boda-boda registration deadline reminders
- **Profile (ProfileService)** — Transport operator profile badge for verified LATRA-licensed operators via `ProfileService.getProfile()`. PSV licence status displayed on profile. Driver safety rating from passenger reviews linked to profile. Boda-boda/bajaji registration status badge. Compliance history visible
- **Location (LocationService)** — Route-based fare lookup using `LocationService.searchLocations()` with Tanzania hierarchy (Region, District, Ward). Nearest LATRA office finder with navigation. Accident report location capture via GPS. Route distance calculation for fare estimation. Intercity bus route mapping
- **Posts & Stories (PostService + StoryService)** — Share safety tips and passenger rights information via `PostService.createPost()`. Report road safety concerns to community. Share route fare information. Transport service reviews posted to feed. Safety campaign stories via `StoryService.createStory()`
- **My Cars Module (my_cars/)** — LATRA inspection certificate storage and expiry tracking for registered vehicles. Vehicle roadworthiness status linked to vehicle dashboard. PSV registration status for commercial vehicles. Inspection booking scheduling
- **Calendar (CalendarService)** — LATRA licence renewal dates synced to calendar via `CalendarService.createEvent()`. Vehicle inspection appointment scheduling. Fare cap publication dates (monthly). Compliance deadline reminders
- **Real-time Updates (LiveUpdateService)** — Firestore listeners for real-time complaint status updates. Route suspension alerts. Safety advisory broadcasts
- **Media (PhotoService)** — Complaint evidence photos uploaded via `PhotoService.uploadPhoto()` — plate numbers, unsafe conditions, overcharging pump/meter displays. Accident scene documentation. Vehicle inspection photos
- **Rent Car Module (rent_car/)** — Rental company LATRA licence verification. Chauffeur-driven rental fare compliance check. Licensed commercial transport operator validation
- **Ambulance Module (ambulance/)** — Emergency vehicle route clearance information. Accident reporting linked to road safety statistics. Emergency service coordination on regulated routes
- **EWURA Module (ewura/)** — Cross-reference fuel prices for transport cost analysis. Fuel cost impact on fare structures. Energy pricing linkage with transport economics
- **Analytics (EventTrackingService)** — Complaint resolution rate tracking. Route safety statistics visualization. Fare compliance monitoring data. Transport service quality metrics
- **People Search (PeopleSearchService)** — Find licensed transport operators via `PeopleSearchService.search()`. Verify driver/conductor credentials. Search by route specialization and region
- **Friends (FriendService)** — Share safe driver recommendations with friends via `FriendService.getFriends()`. Community-sourced safety ratings shared within friend networks

## Available APIs

- **LATRA Official Portal** — latra.go.tz publishes fare orders and route information (scrape-able, no public API documented)
- **NTSA Kenya API** — Reference implementation for vehicle/driver verification endpoints
- **Google Maps Platform** — Route distance calculation for fare estimation
- **OpenStreetMap** — Alternative route mapping for Tanzania road network
- TAJIRI backend will need to build proxy endpoints that cache LATRA data and handle complaint submission/tracking
