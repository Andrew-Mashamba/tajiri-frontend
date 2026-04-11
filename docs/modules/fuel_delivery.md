# Fuel Delivery — Feature Description

## Tanzania Context

Fuel delivery as a consumer service is an emerging concept in Tanzania. Currently, the vast majority of Tanzanians refuel at traditional petrol stations. The fuel market is regulated by EWURA (Energy and Water Utilities Regulatory Authority), which sets maximum pump prices monthly based on international crude oil prices, exchange rates, and local taxes.

Current fuel landscape in Tanzania:
- **Major fuel companies** — PUMA Energy (formerly BP), Total Energies, Oilcom, Oryx Energies, Hashi Energy, Lake Oil, Camel Oil, MRG
- **Fuel prices** — Set by EWURA with regional variations (Dar es Salaam cheapest, prices increase with distance from port)
- **Fuel types** — Petrol (benzini), Diesel (dizeli), Kerosene (mafuta ya taa)
- **Payment** — Cash dominant at stations, mobile money acceptance growing
- **Distribution** — Fuel imported through Dar es Salaam port, distributed via pipeline (to Dodoma) and road tankers

Fuel delivery does not exist as a mainstream consumer service in Tanzania yet, but the conditions are favorable:
- Traffic congestion in Dar es Salaam wastes hours that could be saved with delivery
- Fleet operators (trucks, buses, taxis) lose productive time refueling
- Construction sites and generators in remote areas need fuel brought to them
- Agriculture sector (tractors, irrigation pumps) in rural areas requires fuel transport
- Emergency fuel needs (ran out on the road) have no solution beyond calling friends

The concept would need EWURA compliance for pricing, safety certifications for mobile fueling equipment, and insurance for fuel transport. Tanzania's existing fuel distribution network (tanker trucks serving stations) provides infrastructure that could be adapted.

## International Reference Apps

1. **Booster Fuels (USA)** — On-demand mobile fueling. Order fuel to your parked car at office/home, fleet services for businesses, no markup over station prices, certified fuel technicians, tracking via app, recurring delivery scheduling.

2. **CAFU (UAE)** — Middle East fuel delivery pioneer. Fuel delivered to your car anywhere, real-time tracking, scheduled deliveries, multiple fuel types, car wash add-on, fleet management, operating in UAE and expanding.

3. **Yoshi (USA)** — Full-service car care delivery. Fuel delivery, tire pressure check, car wash, windshield washer refill, oil change at your location, membership model, fleet programs.

4. **FuelBuddy (India)** — Doorstep diesel delivery. Bulk diesel for businesses, generators, and construction sites, digital invoicing, real-time delivery tracking, fuel quality assurance, GST-compliant billing.

5. **Filld (Canada)** — Overnight fuel delivery. Park car with fuel door open, fuel delivered overnight, subscription model, fleet services, no interaction needed, full insurance coverage.

## Feature List

### Fuel Ordering
1. One-tap fuel order from current GPS location
2. Manual address entry or saved location selection
3. Fuel type selection: Petrol (Regular, Premium), Diesel
4. Quantity selection: fill-up estimate, specific liters, or specific amount (TZS)
5. Vehicle selection from TAJIRI My Cars registered vehicles
6. Schedule delivery: now, specific time today, or future date/time
7. Recurring delivery setup (daily, weekly for fleets/generators)
8. Add-ons: tire pressure check, windshield washer top-up, basic car check
9. Special instructions field (parking location, gate code, vehicle position)
10. Group ordering — order fuel for multiple vehicles at same location

### Pricing & Transparency
11. Real-time EWURA-regulated fuel prices displayed
12. Price breakdown: fuel cost + delivery fee + service charge
13. Price comparison with nearby petrol stations
14. Delivery fee calculator based on distance and quantity
15. No surge pricing — consistent delivery fees
16. Price lock for scheduled deliveries (guaranteed price at time of booking)
17. Monthly fuel price trend charts
18. Savings calculator: time saved vs delivery fee comparison
19. Bulk order discounts for large quantities (100+ liters)
20. Corporate/fleet pricing tiers

### Delivery Tracking
21. Real-time GPS tracking of fuel delivery vehicle
22. Estimated arrival time with live updates
23. Delivery driver profile (name, photo, certification, rating)
24. Push notifications: order confirmed, driver en route, arriving soon, delivery complete
25. Photo verification of completed delivery (fuel cap, meter reading)
26. Digital receipt with exact liters delivered and cost
27. Delivery confirmation with customer signature/PIN
28. Route optimization showing driver's path

### Fleet Management
29. Business account with multiple vehicles and authorized orderers
30. Fleet dashboard — all vehicles, fuel consumption, delivery history
31. Employee fuel cards/budgets with spending limits
32. Bulk delivery scheduling for fleet depots
33. Fuel consumption analytics per vehicle
34. Driver assignment — specify which vehicle gets what fuel
35. Monthly fuel expense reports by vehicle, department, or project
36. Integration with fleet telematics for automatic fuel level monitoring
37. Purchase order and invoice management
38. Multi-location delivery coordination

### Generator & Industrial
39. Generator fuel delivery (diesel) for businesses and homes
40. Construction site fuel delivery with site access coordination
41. Agricultural fuel delivery (tractors, irrigation pumps, harvesters)
42. Event fuel delivery for mobile generators at outdoor events
43. Scheduled refills based on consumption patterns
44. Tank level monitoring integration (IoT sensors)

### Safety & Compliance
45. EWURA-compliant pricing and fuel quality standards
46. Certified fuel delivery technicians with safety training
47. Vehicle and equipment safety certification display
48. Insurance coverage details for each delivery
49. Fuel quality guarantee — octane rating and purity
50. Emergency procedures and spill response protocols
51. Fire safety equipment on all delivery vehicles
52. Delivery restricted zones compliance (no fueling in enclosed spaces)

### Payment
53. Pay via TAJIRI Wallet (M-Pesa, Tigo Pesa, Airtel Money)
54. Post-paid/invoiced billing for business accounts
55. Split payment among multiple people (group fueling)
56. Automatic payment for recurring deliveries
57. Fuel expense categorization for tax and business purposes
58. Receipt sharing via WhatsApp, email, or SMS
59. Prepaid fuel credits — buy fuel in advance at locked prices

### Fuel Expense Reports
60. Personal fuel expense tracking integrated with My Cars
61. Monthly, quarterly, and annual fuel spend summaries
62. Cost per kilometer analysis when combined with mileage data
63. Fuel efficiency trends and recommendations
64. Export reports as PDF or CSV
65. Budget alerts — notify when approaching monthly fuel budget

## Key Screens

1. **Order Fuel** — Map-based location selection, fuel type, quantity, vehicle picker
2. **Delivery Tracking** — Real-time map with driver location, ETA, order status
3. **Price Display** — Current fuel prices, comparison, and price history
4. **Fleet Dashboard** — Multi-vehicle fuel management for businesses
5. **Delivery History** — Past deliveries with receipts, quantities, and costs
6. **Schedule Delivery** — Calendar-based delivery planning
7. **Fuel Reports** — Charts and analytics on fuel consumption and spending
8. **Business Account** — Company profile, authorized users, billing settings
9. **Driver Profile** — Delivery person details, certification, ratings
10. **Payment Methods** — Wallet, mobile money, corporate billing setup

## TAJIRI Integration Points

- **Wallet (WalletService)** — Primary payment method via `WalletService.deposit()` with M-Pesa/Tigo/Airtel STK push. Prepaid fuel credits purchased and stored in wallet — buy fuel at locked prices via `WalletService.transfer()`. Business invoicing with post-paid billing through wallet. Split payment among multiple people for group fueling. Automatic recurring payment for scheduled deliveries. Transaction history via `WalletService.getTransactions()` shows all fuel purchases with vehicle, quantity, and station details. Corporate fleet billing with consolidated monthly statements
- **My Cars Module (my_cars/)** — Vehicle selection from registered garage when ordering fuel. Fuel log auto-updated after delivery completion with exact liters, fuel type, cost, and date. Fuel economy trends calculated by combining delivery data with odometer readings from My Cars. Tank capacity reference for fill-up estimation. Multi-vehicle fuel expense comparison across fleet
- **Service Garage Module (service_garage/)** — Add-on services during fuel delivery: tire pressure check, windshield washer top-up, basic vehicle health check. Link to garage booking for issues discovered during delivery add-on checks. Oil level check and service reminder trigger
- **Notifications (FCMService + NotificationService)** — Push notifications via `FCMService` for: order confirmed, driver en route, arriving in 5 minutes, delivery complete with receipt, monthly EWURA price change alerts, low fuel reminders based on consumption patterns, recurring delivery reminders, price lock expiry alerts, corporate budget threshold warnings
- **Location (LocationService)** — GPS-based delivery location selection via `LocationService.searchLocations()` using Tanzania hierarchy (Region, District, Ward, Street). Real-time driver tracking on map during delivery. Saved delivery locations (home, office, construction site). Delivery zone validation before order acceptance. Distance-based delivery fee calculation
- **Groups (GroupService)** — Fleet manager groups via `GroupService.createGroup()` for coordinating multi-vehicle fuel management. Fuel price discussion communities. Corporate fleet operator groups. Group posts via `GroupService.getGroupPosts()` for sharing fuel-saving tips and station reviews
- **Messaging (MessageService)** — Communication with delivery driver via `MessageService.sendMessage()` for location clarification, gate codes, and parking instructions. Fleet manager coordination messages. Delivery scheduling confirmations
- **Business Module (business/)** — Corporate fuel management integration with business accounts. Employee fuel cards with spending limits per role. Department-level fuel budgets. Purchase order generation and invoice management. Fleet fuel analytics by vehicle, department, or project. Tax-deductible fuel expense reporting
- **Events Module (events/)** — Generator fuel delivery for event organizers — schedule diesel delivery for mobile generators at outdoor events, concerts, and functions. Event fuel budget integration with event michango/budget system
- **Profile (ProfileService)** — Delivery driver ratings linked to TAJIRI profiles via `ProfileService.getProfile()`. Driver certification and safety training status displayed. Customer fuel consumption profile for personalized recommendations
- **Tajirika Module (tajirika/)** — Fuel delivery drivers as TAJIRI partners with ratings, earnings dashboard, and certification verification. Driver onboarding with safety training completion. Earnings tracking via partner dashboard. Commission structure and payout management
- **EWURA Module (ewura/)** — Real-time EWURA-regulated fuel cap prices displayed on ordering screen. Price compliance verification — delivery price cannot exceed EWURA cap plus delivery fee. Regional price variations shown. Monthly price bulletin integration for price trend charts. Report overcharging directly from delivery receipt
- **Posts & Stories (PostService + StoryService)** — Share fuel price alerts and station reviews as posts via `PostService.createPost()`. Fleet managers share fuel efficiency tips. Delivery service reviews posted to feed
- **Calendar (CalendarService)** — Recurring delivery schedule synced to calendar via `CalendarService.createEvent()`. Fuel budget review reminders. Fleet refueling schedule coordination
- **Real-time Updates (LiveUpdateService)** — Firestore listeners for real-time delivery driver location updates. Order status changes pushed in real-time. Price change notifications on order day
- **Budget (BudgetService)** — Fuel expense budgets tracked via `BudgetService`. Monthly fuel spending alerts. Cost per kilometer analysis feeding into budget reports. Fleet fuel cost projections
- **Media (PhotoService)** — Delivery completion photos via `PhotoService.uploadPhoto()` — fuel cap, meter reading, receipt. Vehicle identification photos for fleet deliveries
- **Transport Module (transport/)** — Integration with ride-hailing fleet fuel management. Boda-boda and bajaji fuel delivery for transport operators. Route-based fuel cost estimation
- **Analytics (EventTrackingService + AnalyticsService)** — Fuel consumption analytics per vehicle and fleet. Delivery frequency patterns. Cost trends over time. Seasonal consumption variations. Carbon footprint tracking
