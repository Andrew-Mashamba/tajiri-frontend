# EWURA (Energy and Water Utilities Regulatory Authority) — Feature Description

## Tanzania Context

EWURA is the multi-sector regulatory authority for energy and water utilities in Tanzania, established under the EWURA Act, 2001. It regulates petroleum, electricity, natural gas, and water supply services.

**What EWURA Regulates:**
- **Petroleum:** Sets monthly fuel cap prices for every region in Tanzania. Licenses petrol stations, LPG dealers, and petroleum transporters. Monitors fuel quality
- **Electricity:** Approves TANESCO tariffs, licenses independent power producers, monitors service quality
- **Natural Gas:** Regulates distribution, sets tariffs, ensures supply reliability
- **Water:** Regulates urban water supply authorities (DAWASCO, etc.), approves tariffs, monitors water quality and service delivery

**How Citizens Interact:**
- Checking the current month's fuel cap price (petrol, diesel, kerosene) for their region
- Reporting a petrol station charging above the cap price
- Filing complaints about electricity outages, billing errors, or poor service from TANESCO
- Complaining about water supply issues — low pressure, dirty water, overbilling by DAWASCO
- Checking if a petrol station or LPG dealer is licensed
- Understanding electricity/water tariff structures

**Current Pain Points:**
- **Fuel price confusion** — EWURA publishes monthly cap prices per region, but most consumers don't know the current price. Petrol stations in rural areas frequently overcharge
- **No real-time price comparison** — No way to compare fuel prices across stations near you
- **Utility complaints go nowhere** — Filing complaints about TANESCO or DAWASCO through EWURA is a long bureaucratic process. Most people suffer in silence
- **Tariff complexity** — Electricity tariffs have multiple bands (D1 domestic, T1 commercial, etc.) and water tariffs vary by authority. Consumers can't calculate expected bills
- **LPG safety** — Illegal gas refilling is common and dangerous. No easy way to verify if an LPG dealer is licensed
- **Fuel quality** — Adulterated fuel damages vehicles but consumers can't report it easily

## International Reference Apps

1. **EPRA (Kenya)** — Energy and Petroleum Regulatory Authority publishes monthly fuel prices, has a mobile app for price checking and complaint filing
2. **GasBuddy (USA/Canada)** — Crowd-sourced fuel price comparison app with station ratings, price alerts, and trip cost calculator
3. **Ofgem (UK)** — Energy regulator with online tariff comparison, complaint escalation, and energy calculator tools
4. **NERSA (South Africa)** — National Energy Regulator with fuel price publication, licence verification, and consumer complaint portal
5. **MyWater (multiple countries)** — Water utility apps that show usage, tariffs, outage maps, and allow complaint filing

## Feature List

1. **Monthly Fuel Cap Prices** — Current EWURA-approved cap prices for petrol, diesel, and kerosene by region. Updated automatically each month when EWURA publishes new prices
2. **Fuel Price by Station** — Browse fuel prices at specific stations near your location. Crowd-sourced actual prices vs EWURA cap. Flag stations charging above cap
3. **Report Overcharging** — Quick report when a petrol station charges above the EWURA cap price. Include station name, location, fuel type, price charged, and photo of pump display
4. **Fuel Price History** — Historical fuel price trends by region. Charts showing monthly changes over 12-24 months. Compare across regions
5. **Fuel Price Alerts** — Push notification when EWURA publishes new monthly fuel prices. Price change summary compared to previous month
6. **Nearest Fuel Station** — Map showing nearby petrol stations with current prices, fuel availability, and user ratings
7. **Electricity Tariff Calculator** — Enter meter type (prepaid/postpaid) and units consumed to calculate expected bill using current TANESCO tariff bands. Compares with actual bill to detect overcharging
8. **Water Tariff Reference** — Current water tariffs by utility authority (DAWASCO, MUWASA, etc.). Calculate expected water bill based on consumption
9. **File Utility Complaint** — Submit complaint against TANESCO, DAWASCO, or other regulated utility. Categories: billing error, outage, water quality, service delay, meter issues. Attach evidence
10. **Complaint Tracking** — Track complaint status with reference number. View resolution timeline, EWURA intervention, and outcome
11. **Licensed Operators Directory** — Searchable list of EWURA-licensed petrol stations, LPG dealers, gas distributors, and utility providers
12. **LPG Dealer Verification** — Check if an LPG refilling station is EWURA-licensed. Report unlicensed/unsafe operations
13. **Fuel Quality Report** — Report suspected adulterated fuel with station details, fuel type, symptoms (vehicle issues), and date of purchase
14. **Monthly Price Bulletin** — Full EWURA monthly price bulletin in readable format (original PDFs are hard to navigate on mobile)
15. **Energy Saving Tips** — Practical tips for reducing electricity and fuel consumption. Cost-saving calculations

## Key Screens

- **Home Dashboard** — Current fuel prices for your region, quick complaint button, price alerts
- **Fuel Prices** — Regional price list with search, filter by fuel type, and month selector
- **Station Map** — Map view of nearby fuel stations with prices and ratings
- **Report Overcharging** — Quick form with station, fuel type, price charged, and evidence
- **Tariff Calculator** — Electricity/water bill calculator with tariff band breakdown
- **Complaint Form** — Multi-step complaint form for utility issues
- **My Complaints** — Complaint history with status tracking
- **Price Trends** — Charts showing fuel price history by region

## TAJIRI Integration Points

- **Wallet (WalletService)** — Pay utility bills (TANESCO, DAWASCO) directly via `WalletService.deposit()` with M-Pesa/Tigo/Airtel STK push. Fuel station payments through wallet at participating stations. Complaint filing fees (if applicable) processed through wallet. Prepaid electricity token purchase via wallet. Transaction history via `WalletService.getTransactions()` shows all utility payments with meter/account references
- **Transport Module (transport/)** — Show EWURA fuel cap prices relevant to trip planning — fuel cost estimation for routes. Boda-boda, bajaji, and ride-hailing fare analysis linked to fuel cost structure. Fuel price impact on transport costs displayed during booking. Route-based fuel station recommendations
- **My Cars Module (my_cars/)** — Track fuel expenses and link to current EWURA prices at stations visited. Fuel fill-up logging cross-referenced with regional cap prices to detect overcharging. Fuel economy calculations using EWURA price data. Regional fuel cost comparison when planning trips. Fuel expense analytics with EWURA price trend overlay
- **Fuel Delivery Module (fuel_delivery/)** — EWURA-regulated cap prices displayed on fuel delivery ordering screen. Delivery price compliance verification — delivery cost cannot exceed cap plus delivery fee. Monthly price updates automatically reflected in delivery pricing. Fuel quality guarantee referenced from EWURA standards. Regional price variations applied to delivery orders
- **Notifications (FCMService + NotificationService)** — Push notifications via `FCMService` for: monthly EWURA fuel price publication alerts with price change summary, complaint status changes, utility outage alerts (TANESCO power cuts, DAWASCO water disruptions), LPG safety advisories, fuel quality warning alerts, tariff change notifications, overcharging reports in your area
- **Groups (GroupService)** — Energy/utility consumer groups via `GroupService.createGroup()` — share fuel station reviews, report overcharging, discuss tariff changes. LPG safety awareness groups. TANESCO/DAWASCO customer groups by region. Group posts via `GroupService.getGroupPosts()` for station reviews, outage reports, and energy saving tips
- **Location (LocationService)** — Fuel station locations on map via `LocationService.searchLocations()` using Tanzania hierarchy. Nearest fuel station finder with current prices and ratings. LPG dealer locations with licensing status. EWURA office locations. Regional fuel price zone mapping
- **Bills Module (bills/)** — Integration with utility bill tracking and payment — electricity (TANESCO) and water (DAWASCO) bills tracked with due dates. Tariff calculator results compared with actual bills to detect overcharging. Bill payment reminders. Historical bill comparison with tariff changes. Auto-bill payment scheduling through wallet
- **Posts & Stories (PostService + StoryService)** — Share fuel price alerts via `PostService.createPost()` when EWURA publishes new monthly prices. Station review posts with overcharging reports. Energy saving tips shared to feed. Utility complaint stories via `StoryService.createStory()`
- **Messaging (MessageService)** — Receive complaint resolution updates via `MessageService.sendMessage()`. EWURA officer communication for escalated complaints. Auto-created conversation per complaint for tracking correspondence. Utility provider communication channel
- **Profile (ProfileService)** — Licensed petrol station operator badge via `ProfileService.getProfile()`. LPG dealer verification status. Fuel station operator compliance history displayed. Consumer energy literacy badges
- **Calendar (CalendarService)** — Monthly EWURA price publication dates synced to calendar via `CalendarService.createEvent()`. Utility bill due dates. Complaint follow-up deadlines. LPG cylinder inspection dates
- **Media (PhotoService)** — Overcharging evidence photos uploaded via `PhotoService.uploadPhoto()` — pump display, receipt, price board. Fuel quality complaint evidence. LPG safety violation documentation. Station review photos
- **Real-time Updates (LiveUpdateService)** — Firestore listeners for real-time complaint status changes. Fuel price publication broadcasts. Utility outage alerts pushed in real-time. Station price crowd-sourced updates
- **LATRA Module (latra/)** — Cross-reference fuel prices with transport fare structures. Fuel cost impact on approved LATRA route fares. Transport operator fuel expense analysis
- **Business Module (business/)** — Commercial electricity and water tariff management for businesses. Energy cost analytics for business operations. Generator fuel expense tracking. Industrial water usage monitoring
- **Housing Module (housing/)** — Utility cost estimation for property listings. Water and electricity availability information by area. Tariff comparison between residential zones
- **Budget (BudgetService)** — Utility expenses tracked via `BudgetService`. Monthly electricity, water, and fuel budgets. Cost reduction recommendations based on tariff analysis. Energy spending trends over time
- **Analytics (EventTrackingService)** — Fuel price trend analytics. Complaint resolution rate tracking. Station rating aggregation. Utility cost comparison analytics across regions. Consumer savings calculations from overcharging prevention
- **People Search (PeopleSearchService)** — Find licensed fuel station operators and LPG dealers via `PeopleSearchService.search()`. Verify operator licensing status. Find EWURA compliance officers by region
- **Content Discovery (ContentEngineService)** — Energy saving tips personalized based on user's utility consumption via `ContentEngineService`. Fuel price alerts pushed through content engine. Tariff education content for consumers

## Available APIs

- **EWURA Website** — ewura.go.tz publishes monthly fuel price orders as PDFs (parseable with automation)
- **EPRA Kenya API** — Reference implementation for fuel price publication endpoints
- **GasBuddy API** — Reference for crowd-sourced fuel price comparison architecture
- **Google Places API** — Fuel station locations and basic info for Tanzania
- **TANESCO** — No public API; TAJIRI backend would need to build scraping or partnership
- TAJIRI backend will parse EWURA monthly PDF bulletins and serve structured fuel price data via REST API
