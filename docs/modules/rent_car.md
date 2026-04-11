# Rent Car — Car Rental

## Tanzania Context

Car rental in Tanzania serves several distinct customer segments: tourists visiting national parks and beaches, business travelers, locals needing temporary vehicles (weddings, moving, emergencies), diaspora Tanzanians visiting home, and businesses needing fleet vehicles without ownership.

### Current Rental Landscape

**International Chains (Limited Presence)**
- **Europcar** — Partner offices in Dar es Salaam and Arusha, standard international booking
- **Avis** — Small presence, primarily airport locations
- **Hertz** — Via local franchise partners
- These serve mainly international tourists and corporate accounts; expensive by local standards

**Local Rental Companies**
- Numerous small operators, particularly in Dar es Salaam, Arusha (safari gateway), and Zanzibar
- **Green Car Rental**, **Tanzania Rent A Car**, **Zara Tours Rentals**, **Coastal Car Rentals**
- Quality varies enormously — from well-maintained Land Cruisers to barely roadworthy sedans
- Most operate via phone calls and WhatsApp; minimal online presence
- Self-drive and chauffeur-driven options available
- 4x4 vehicles in high demand for safari and rural travel (Dar-Dodoma road etc.)

**Peer-to-Peer (Informal)**
- Car owners rent out vehicles informally through personal networks
- No insurance coverage for rental use in most cases
- Common for weddings, funerals, special occasions
- Trust-based with no formal contracts
- Significant risk for both parties

**Specialized Rental**
- Safari vehicles (Land Cruiser pop-top) with driver/guide — $150-300/day
- Wedding cars (Mercedes, BMW, luxury sedans) — premium daily rates
- Buses/coasters for group travel and events
- Trucks for moving and cargo

Pain points: no reliable online booking for local companies, vehicle condition unknown until pickup, hidden charges (fuel policy, mileage limits, insurance excess), no standardized contracts, insurance coverage unclear, breakdown support unreliable, deposit requirements are high and refund is slow, no ratings system for rental companies, price opacity (tourists pay more), and peer-to-peer rental has zero protections.

## International Reference Apps

1. **Turo (USA/Global)** — Peer-to-peer car sharing marketplace. Car owners list their vehicles, renters browse and book, built-in insurance, host and guest ratings, delivery option, unique and luxury vehicles, flexible cancellation, identity verification.

2. **Getaround (USA/Europe)** — Instant car sharing. Keyless access via phone (no key handoff), hourly/daily rental, insurance included, fuel included in price, damage protection, trip tracking, urban-focused short-term rentals.

3. **Europcar / Enterprise (Global)** — Traditional rental with digital booking. Wide fleet selection, airport pickup/dropoff, one-way rental, loyalty programs, corporate accounts, add-on insurance options, roadside assistance, mobile check-in.

4. **Uber Rent (USA)** — Car rental aggregator within Uber app. Compare rental companies, book in-app, pickup at various locations, seamless payment, no additional apps needed, rates from multiple providers.

5. **Virtuo (Europe)** — Premium digital car rental. Entirely app-based (no counter), delivered to your location, premium vehicles only, all-inclusive pricing, 24/7 concierge, damage handled in-app with photos.

## Feature List

### Vehicle Browsing
1. Browse available rental vehicles with rich photo galleries
2. Filter by: vehicle type (sedan, SUV, 4x4, van, luxury, bus), make, seats, transmission, fuel type
3. Filter by: rental type (self-drive, chauffeur-driven, with guide)
4. Filter by: price range (daily rate), pickup location, availability dates
5. Sort by price, rating, distance, or popularity
6. Vehicle detail pages with full specifications, features, and photos
7. Vehicle condition report with inspection photos
8. Renter reviews and ratings for each specific vehicle
9. Availability calendar showing booked and open dates
10. Similar vehicle suggestions when preferred option unavailable
11. Special category sections: Safari vehicles, Wedding cars, Moving trucks

### Booking & Pricing
12. Date and time selection for pickup and return
13. Clear pricing breakdown: daily rate, insurance, delivery fee, extras
14. Daily, weekly, and monthly rate tiers with automatic best-price selection
15. Mileage policy display: unlimited vs limited km per day
16. Fuel policy clarity: full-to-full, prepaid, or included
17. Extra driver fee and policy
18. Child seat, GPS, roof rack, and other accessory add-ons
19. One-way rental option (pickup Dar, return Arusha) with surcharge
20. Instant booking for available vehicles
21. Request-to-book for premium/specialty vehicles
22. Booking modification and cancellation with clear refund policy
23. Promo codes and seasonal discount application

### Insurance & Protection
24. Basic insurance included in all rentals (third-party)
25. Comprehensive damage protection upgrade option
26. Excess/deductible amount clearly displayed
27. Personal accident insurance add-on
28. Tire and windscreen coverage option
29. Zero-excess premium protection tier
30. Insurance document provided digitally before pickup
31. What's covered / what's not covered — clear visual guide
32. Existing personal insurance policy integration check

### Pickup & Return
33. Pickup location selection: rental office, airport, hotel, custom address
34. Vehicle delivery to your location option with tracking
35. Digital check-in: ID verification, license check before arrival
36. Vehicle condition inspection at pickup with photo documentation
37. Digital rental agreement signing
38. Key handoff or smart lock access (future phase)
39. Return location options including different-from-pickup
40. Return condition inspection with damage comparison
41. Express return with photo self-inspection
42. Late return notification and fee transparency
43. After-hours return drop-box (where available)

### Peer-to-Peer Rental
44. Vehicle owner listing: list your personal car for rental
45. Owner sets availability, daily rate, pickup location, and rules
46. Owner approval or instant-book toggle
47. Owner earnings dashboard with payout tracking
48. Platform-provided rental insurance for P2P listings
49. Vehicle eligibility check (age, condition, insurance status)
50. Owner-renter messaging for coordination
51. Earnings estimator — how much your car could earn
52. Vehicle monitoring: GPS tracking during rental period (owner visibility)
53. Mileage and usage reports after each rental

### Chauffeur Services
54. Book car with professional driver
55. Driver profiles with experience, languages, and ratings
56. Safari guide-drivers with tourism knowledge
57. Multi-day chauffeur booking for tours and business trips
58. Driver gratuity through app
59. Female driver request option for women travelers
60. Corporate chauffeur accounts

### Fleet for Businesses
61. Corporate account with fleet management dashboard
62. Multiple employee booking with approval workflows
63. Monthly invoicing and consolidated billing
64. Preferred vehicle allocation for executives
65. Usage reports by employee, department, or project
66. Long-term lease options (3, 6, 12 months)
67. Dedicated account manager for corporate clients

### During Rental
68. 24/7 roadside assistance hotline
69. In-app breakdown reporting with location sharing
70. Emergency vehicle replacement service
71. Extend rental duration from within the app
72. Fuel station finder along route
73. Traffic and road condition alerts
74. Rental period countdown and return reminders

## Key Screens

1. **Browse Vehicles** — Grid view with filters, search, and map of pickup locations
2. **Vehicle Detail** — Photos, specs, pricing, reviews, availability, book button
3. **Booking Flow** — Dates, insurance, extras, payment, confirmation
4. **My Bookings** — Active and past rentals with status and quick actions
5. **Pickup/Return** — Check-in process, condition inspection, agreement signing
6. **List Your Car** — Owner listing creation flow for P2P rental
7. **Owner Dashboard** — Earnings, bookings, vehicle management for P2P hosts
8. **Chauffeur Selection** — Driver profiles, availability, booking
9. **Corporate Dashboard** — Fleet bookings, employee management, billing
10. **Roadside Assistance** — Emergency help request with location and status
11. **Rental Agreement** — Digital contract view and signature

## TAJIRI Integration Points

- **Wallet (WalletService)** — Rental payments via `WalletService.deposit()` with M-Pesa/Tigo/Airtel STK push. Security deposit held in wallet escrow — released after return inspection. P2P host payouts via `WalletService.transfer()` minus platform commission. Refunds for cancelled bookings processed to wallet. Chauffeur gratuity via wallet transfer. Corporate billing with consolidated monthly invoicing. Transaction history via `WalletService.getTransactions()` shows all rental payments, deposits, and refunds. Late return fees auto-charged. Prepaid rental credits for frequent renters
- **My Cars Module (my_cars/)** — P2P hosts link registered vehicles from My Cars garage with all specs and photos pre-populated. Vehicle condition, service history, and insurance status pulled from My Cars. Renters can add active rental to trips for mileage tracking. Host earnings per vehicle tracked alongside vehicle expenses in My Cars. Vehicle eligibility check (age, condition, insurance) validated against My Cars data
- **Car Insurance Module (car_insurance/)** — Rental insurance verification — check if vehicle has comprehensive coverage for rental use. Personal insurance policy check for renters to avoid duplicate coverage. Platform-provided rental insurance for P2P listings with coverage details displayed. Excess/deductible amounts clearly shown during booking. Accident claim filing integrated with insurance module if incident occurs during rental
- **Messaging (MessageService)** — Renter-owner communication via `MessageService.sendMessage()` for pickup coordination, vehicle questions, and return arrangements. Renter-company inquiries for fleet rentals. Auto-created conversation upon booking via `MessageService.createGroup()` linking renter, host/company, and chauffeur. Key handoff coordination. Post-rental follow-up messages
- **Notifications (FCMService + NotificationService)** — Push notifications via `FCMService` for: booking confirmation, pickup reminder (1 day, 2 hours before), vehicle delivery en route, return reminder (4 hours before), late return warning, rental extension confirmation, security deposit release, host booking request (for approval-required listings), payment receipt, rating reminder post-rental
- **Profile (ProfileService)** — Renter verification (NIDA ID, driving license on file) via `ProfileService.getProfile()`. Host verification with business registration check. Driving license photo stored and verified. Renter rating and rental history displayed. Host superhost badge for top-rated vehicle owners. Corporate account manager profiles
- **Location (LocationService)** — GPS tracking of rental vehicle during rental period (owner visibility) via `LocationService.searchLocations()`. Pickup/return location navigation. Vehicle delivery tracking on map. Geofencing alerts for P2P rentals (vehicle leaving Tanzania border). Fuel station finder along route. Tanzania hierarchy (Region, District) for location-based search
- **Travel Module (travel/)** — Car rental as part of travel planning package — bundle with hotel and flights. Safari vehicle rental integrated into travel itinerary. Airport pickup scheduling synced with flight arrival. Multi-city trip with one-way rental planning. Travel insurance bundled with rental
- **Events Module (events/)** — Event vehicle rental: wedding cars (Mercedes, BMW), group transport (coasters, buses), VIP transport. Event organizer bulk booking for attendee transport. Vehicle rental budget integrated with event michango system. Chauffeur services for event guests
- **Groups (GroupService)** — Car rental tips groups via `GroupService.createGroup()`. Travel and safari planning communities. P2P host community for best practices. Group posts via `GroupService.getGroupPosts()` for rental company reviews and destination advice. Regional rental groups
- **Posts & Stories (PostService + StoryService)** — Share road trip experiences with rental vehicle as posts via `PostService.createPost()`. Safari adventure stories via `StoryService.createStory()`. Rental company and vehicle reviews posted to feed. P2P host showcases their fleet
- **Tajirika Module (tajirika/)** — Rental company operators registered as TAJIRI partners with verification and ratings. Professional chauffeurs with driver profiles, language skills, and safari guide qualifications. Commission structure and partner earnings dashboard. Chauffeur onboarding with driving record verification
- **Buy Car Module (buy_car/)** — "Try before you buy" rental-to-purchase option — rent a model you are considering buying. Rental fee credited toward purchase price. Extended test drive via short-term rental. Dealer inventory available for rent before purchase commitment
- **Calendar (CalendarService)** — Rental booking dates synced to calendar via `CalendarService.createEvent()`. Pickup and return time reminders. Corporate fleet booking schedule. Safari/tour multi-day itinerary integration
- **Media (PhotoService)** — Vehicle condition inspection photos at pickup and return via `PhotoService.uploadPhoto()`. Damage comparison documentation. Vehicle listing gallery for P2P hosts. Rental agreement photo capture
- **Friends (FriendService)** — See which friends have rented from same company/host via `FriendService.getMutualFriends()`. Group trip coordination with friend list. Friend referral discounts for new renters
- **Presence (PresenceService)** — Show host/company online status via `PresenceService` for real-time booking inquiries. Chauffeur availability check. Roadside assistance agent availability
- **Real-time Updates (LiveUpdateService)** — Firestore listeners for real-time vehicle delivery tracking. Booking approval/rejection from hosts. Return inspection results. Security deposit release confirmation
- **Ambulance Module (ambulance/)** — Emergency response integration during rental — SOS button routes to ambulance with rental vehicle details and insurance information pre-filled
- **LATRA Module (latra/)** — Licensed transport operator verification for rental companies. Fare cap reference for chauffeur-driven rentals. Compliance status display on company profiles
- **Analytics (EventTrackingService)** — Rental frequency analytics for hosts. Revenue per vehicle tracking. Seasonal demand patterns. Utilization rate optimization recommendations
