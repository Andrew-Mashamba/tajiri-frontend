# My Cars — Vehicle Registration & Management

## Tanzania Context

Vehicle ownership in Tanzania is growing rapidly, particularly in Dar es Salaam, Arusha, Mwanza, and Dodoma. Most vehicles are imported used cars from Japan (via auction houses like USS, TAA) and Dubai, with Toyota dominating the market (Land Cruiser, Hilux, Vitz, IST, Premio are ubiquitous).

Vehicle registration and management in Tanzania involves multiple government agencies:
- **TRA (Tanzania Revenue Authority)** — Import duty calculation, registration fees, annual road license renewal
- **SUMATRA (Surface and Marine Transport Regulatory Authority)** — Vehicle inspection and roadworthiness certification
- **LATRA (Land Transport Regulatory Authority)** — Replaced SUMATRA for land transport regulation
- **BRELA** — Vehicle used in business registration contexts
- **Traffic Police** — Enforcement of documentation compliance

Key documents every vehicle owner must maintain:
- Vehicle registration card (logbook)
- Annual road license (sticker) — renewed at TRA, costs vary by engine size
- Insurance certificate (third-party minimum, comprehensive optional)
- LATRA inspection certificate (roadworthiness)
- Driving license of operator

Pain points for Tanzanian car owners: keeping track of renewal dates for multiple documents, long queues at TRA offices, difficulty finding service history when selling a car, no centralized digital record of vehicle maintenance, fuel expense tracking is manual, spare parts authenticity concerns, and no easy way to compare service costs across garages.

Currently, most Tanzanians rely on physical documents, calendar reminders, and asking friends on WhatsApp about car maintenance schedules. There is no dominant digital solution for personal vehicle management in the East African market.

## International Reference Apps

1. **Drivvo (Global)** — Vehicle expense management app. Fuel log with cost-per-km calculations, service reminders, expense categorization, multiple vehicle support, reports and charts, gas station price comparison, cloud backup.

2. **Jerry (USA)** — Car ownership super app. Insurance comparison, maintenance tracking, service reminders, document storage, expense reports, roadside assistance, car wash booking.

3. **Carfax Car Care (USA)** — Service history tracking. VIN-based history reports, maintenance schedule based on make/model, service reminders, recall alerts, dealer service records integration.

4. **Fuelio (Global)** — Fuel log and cost tracker. Fill-up tracking, fuel economy calculations, service log, cost summaries, trip log, CSV export, multi-vehicle support, gas station finder.

5. **AUTOsist (USA)** — Fleet and personal vehicle management. Maintenance tracking, expense management, document storage, reminder notifications, vehicle inspection checklists, multi-user access for fleet managers.

## Feature List

### Vehicle Registration
1. Add vehicle by registration number (TZ format: T-XXX-XXXX)
2. Manual vehicle details entry (make, model, year, engine size, color, VIN/chassis number)
3. Multiple vehicle support — manage an entire household fleet
4. Vehicle photo gallery — upload photos of the car from multiple angles
5. VIN/chassis number scanner using camera
6. Vehicle specification lookup by make/model/year (pre-populated data)
7. Ownership history tracking for resale value

### Document Management
8. Digital storage for vehicle registration card (logbook scan/photo)
9. Insurance certificate upload with policy details extraction
10. Road license (sticker) status tracking with renewal countdown
11. LATRA inspection certificate storage and expiry tracking
12. Driving license storage for all authorized drivers
13. Import documents storage (bill of lading, customs declaration, duty receipt)
14. Document expiry notifications — 30, 14, 7, and 1 day before expiry
15. Share documents digitally with insurance or authorities when needed

### Insurance Tracking
16. Insurance policy details — provider, policy number, coverage type, premium amount
17. Insurance expiry countdown and renewal reminders
18. Quick link to TAJIRI Car Insurance module for renewal/comparison
19. Claims history log
20. Insurance provider contact information

### Service & Maintenance
21. Service schedule based on manufacturer recommendations (by make/model)
22. Custom service reminders (oil change, tire rotation, brake inspection, etc.)
23. Mileage-based service alerts (e.g., oil change every 5,000 km)
24. Time-based service alerts (e.g., brake fluid every 2 years)
25. Complete service history log with date, mileage, garage, cost, and work done
26. Service receipt photo upload and storage
27. Link to TAJIRI Service Garage module for booking
28. Maintenance cost analytics — monthly, yearly, per-category breakdowns

### Fuel Management
29. Fuel fill-up logging — date, station, fuel type, liters, cost
30. Fuel economy calculation (km per liter) with trend charts
31. Fuel expense tracking — daily, weekly, monthly summaries
32. Fuel price comparison from nearby stations
33. Tank capacity tracking and range estimation
34. Link to TAJIRI Fuel Delivery module for ordering fuel

### Mileage & Trip Tracking
35. Odometer reading log with date stamps
36. Trip logging — start/end location, distance, purpose
37. Business vs personal trip categorization
38. Monthly mileage reports for expense claims
39. GPS-based automatic trip detection (optional)

### Expense Management
40. Comprehensive vehicle expense categories (fuel, service, insurance, parking, tolls, washing, accessories)
41. Expense entry with receipt photo attachment
42. Monthly and annual expense reports with charts
43. Cost per kilometer calculation
44. Budget setting and alerts when approaching limits
45. Export expense reports as PDF or CSV
46. Multi-vehicle expense comparison

### Vehicle Health
47. Dashboard warning light guide — what each light means and urgency level
48. Tire condition tracker (tread depth, rotation schedule, replacement date)
49. Battery health tracker with replacement reminders
50. Recall alerts for known manufacturer recalls (where data available)
51. Pre-trip vehicle inspection checklist

### Additional Features
52. Vehicle market value estimation based on make, model, year, mileage, and condition
53. Quick link to TAJIRI Sell Car module with pre-filled vehicle details
54. Roadside assistance quick call
55. Parking location saver with photo and GPS pin
56. Car wash schedule and nearby car wash finder

## Key Screens

1. **My Garage** — Grid/list view of all registered vehicles with status indicators
2. **Vehicle Dashboard** — Single vehicle overview: next service, insurance status, fuel economy, recent expenses
3. **Add Vehicle** — Registration flow with photo upload, details entry, document scan
4. **Documents** — All stored documents organized by type with expiry status indicators
5. **Service History** — Timeline of all maintenance and repair work
6. **Add Service Record** — Form for logging service details, cost, garage, mileage
7. **Fuel Log** — Fill-up history with economy charts and expense summaries
8. **Expense Report** — Charts and breakdowns of all vehicle costs
9. **Reminders** — List of upcoming service, insurance, and document renewals
10. **Vehicle Profile** — Complete vehicle details, specifications, and ownership history

## TAJIRI Integration Points

- **Wallet (WalletService)** — Record vehicle expenses paid via `WalletService.deposit()` with M-Pesa/Tigo/Airtel. Quick payment for services, insurance, fuel, and spare parts. Transaction history via `WalletService.getTransactions()` auto-categorized by vehicle for expense tracking. Budget alerts when approaching monthly vehicle spend limits via `WalletService.getBalance()`
- **Car Insurance Module (car_insurance/)** — Direct deep link for insurance renewal and provider comparison. Insurance policy details synced to vehicle dashboard showing coverage type, expiry countdown, and provider. One-tap renewal flow with vehicle details pre-populated. Claims history linked to specific vehicles. TIRA policy verification status displayed on vehicle documents
- **Service Garage Module (service_garage/)** — Book service appointments directly from vehicle dashboard with make/model/mileage pre-filled. Service history synced bi-directionally — garage records appear in My Cars timeline. Manufacturer-recommended service schedule alerts based on vehicle specs. Pre-populated service booking with current mileage and pending maintenance items
- **Fuel Delivery Module (fuel_delivery/)** — Order fuel delivery with vehicle selection from My Cars garage. Fuel log auto-updated after delivery completion with liters, cost, and fuel type. Fuel economy trends calculated from delivery history combined with odometer readings
- **Sell Car Module (sell_car/)** — Pre-populate listing with all vehicle details, photos, specs, and complete service history from My Cars. Verified service history badge on listing boosts buyer confidence. Remove vehicle from garage after confirmed sale. Market value estimation based on My Cars data
- **Buy Car Module (buy_car/)** — Purchased vehicle auto-registered in My Cars garage after sale completion. Import tracking data transferred to vehicle profile. Vehicle inspection report from purchase attached to vehicle record
- **Owners Club (owners_club/)** — Auto-join brand-specific community based on registered vehicles via `GroupService.joinGroup()`. Vehicle showcase profile auto-populated from My Cars data. Mileage milestones shared to community. Cross-reference community advice with your specific vehicle specs
- **Spare Parts Module (spare_parts/)** — Search compatible parts with vehicle make/model/year/engine pre-filled from My Cars. VIN-based exact part matching using stored chassis number. Parts purchase history linked to vehicle service records. Compatibility verification against registered vehicle specs
- **Notifications (FCMService + NotificationService)** — Push notifications via `FCMService` for: document expiry reminders (insurance, road license, LATRA inspection) at 30/14/7/1 days before expiry, service due alerts (mileage-based and time-based), fuel economy changes, recall alerts, road license renewal reminders
- **Messaging (MessageService)** — Share vehicle details with mechanics via `MessageService.sendMessage()` for remote diagnostics. Send vehicle specs to potential buyers. Communicate with garage during service. Share documents digitally with insurance or authorities
- **Profile (ProfileService)** — "Vehicle Owner" badge on TAJIRI social profile via `ProfileService.getProfile()`. Vehicle count displayed on profile. Car enthusiast status based on community participation
- **Posts & Stories (PostService + StoryService)** — Share vehicle milestones (new car, 100k km, mods) as posts via `PostService.createPost()`. Share road trip stories via `StoryService.createStory()`. Vehicle showcase photos shared to feed
- **Location (LocationService)** — Parking location saver with GPS pin. Trip logging with start/end locations using Tanzania hierarchy. Nearby car wash and fuel station finder. Service garage proximity search
- **Calendar (CalendarService)** — Service due dates synced to calendar via `CalendarService.createEvent()`. Insurance and road license renewal dates as calendar events. LATRA inspection scheduling
- **Media (PhotoService + VideoUploadService)** — Vehicle photo gallery uploaded via `PhotoService.uploadPhoto()`. Document scans (logbook, insurance certificate) stored as photos. Service receipt photos. Video walkaround for sell car listing
- **LATRA Module (latra/)** — Vehicle inspection certificate storage and expiry tracking. Roadworthiness status linked to vehicle dashboard. Inspection booking integration
- **EWURA Module (ewura/)** — Fuel price reference when logging fill-ups. Regional fuel price comparison linked to vehicle fuel management
- **Budget (BudgetService)** — Vehicle expense budgets tracked via `BudgetService`. Monthly/annual vehicle cost reports. Cost per kilometer calculations feeding into budget analytics
- **Analytics (EventTrackingService + AnalyticsService)** — Vehicle usage analytics: fuel economy trends, maintenance cost patterns, expense category breakdowns. Total cost of ownership calculations over time
