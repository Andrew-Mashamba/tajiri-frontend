# Service Garage — Garage Finder & Service Booking

## Tanzania Context

Vehicle servicing in Tanzania operates across a wide spectrum from informal roadside mechanics to authorized dealer service centers. The market is predominantly informal, with limited quality assurance and price transparency.

### Service Landscape

**Informal Mechanics (Mitambo/Karakana)**
- The vast majority of vehicle servicing happens at informal workshops called "mitambo" or "karakana"
- Found in every neighborhood, particularly concentrated along major roads
- Mechanics are often self-taught or trained through apprenticeship (no formal certification)
- Prices are low but quality is inconsistent
- No written records, no warranties, limited diagnostic equipment
- Parts used may be counterfeit or salvaged without disclosure

**Semi-Formal Garages**
- Small to medium workshops with basic equipment
- May specialize in specific brands (e.g., "Toyota specialist")
- Some trained mechanics, possibly VETA graduates
- More likely to provide receipts and basic warranties
- Growing in number in urban areas

**Authorized Dealers/Service Centers**
- **CFAO Motors (Toyota Tanzania)** — Official Toyota service, genuine parts, trained technicians, Dar es Salaam and major cities
- **Inchcape/CMC** — Multi-brand authorized service
- **DT Dobie** — Mercedes-Benz, Chrysler, Jeep service
- **Simba Automotive** — Multiple brand service centers
- Highest quality but most expensive, limited to major cities

**Specialized Services**
- Auto-electrical workshops (electrical systems, car alarms, sound systems)
- Panel beaters (body repair and painting)
- Tire shops (puncture repair, alignment, balancing)
- AC specialists (air conditioning service and repair)
- Upholstery shops (seat covers, interior repair)
- Towing services (limited, usually informal arrangements)

Pain points: no way to verify mechanic qualifications, price gouging is common (especially for women and non-car-savvy customers), no standardized pricing, fake parts sold as genuine, no service history portability, difficulty finding specialists for specific problems, no accountability for poor work, long wait times with no transparency, and emergency breakdown response is essentially non-existent outside calling personal contacts.

## International Reference Apps

1. **RepairPal (USA)** — Certified shop network. Fair price estimator by repair type and vehicle, shop ratings and reviews, warranty on work, price transparency (shows price range for any repair), appointment booking, service history tracking.

2. **YourMechanic (USA)** — Mobile mechanics come to you. Book online, certified mechanics, transparent pricing before booking, vehicle-specific cost estimates, all work warranted, service at home or office, parts included in quotes.

3. **AutoMD (USA)** — Repair information and shop finder. Diagnose issues with symptom checker, repair cost estimates, shop directory with reviews, DIY repair guides, ask-a-mechanic feature, recall information.

4. **Fixter (UK)** — Car service and repair marketplace. Instant quotes from local garages, collection and delivery of vehicle, real-time repair updates with photos, all work guaranteed, transparent pricing, mechanic-vetted inspection reports.

5. **WhoCanFixMyCar (UK)** — Garage comparison platform. Describe your problem, receive quotes from local garages, compare on price and reviews, book online, verified review system, cover for all makes and models.

## Feature List

### Garage Directory
1. Comprehensive garage/workshop directory for Tanzania (starting with Dar es Salaam)
2. Search by location, service type, vehicle brand specialty, and price range
3. Map view with nearby garages and distance calculation
4. Garage profiles with photos of workshop, equipment, and team
5. Operating hours, contact information, and directions
6. Service capabilities list (engine, electrical, body, AC, tires, etc.)
7. Brand specialization indicators (Toyota specialist, German cars, etc.)
8. Verified garage badge for shops that pass TAJIRI quality checks
9. Garage registration with TAJIRI — onboarding process for workshops
10. Popular/trending garages based on community activity

### Mechanic Profiles
11. Individual mechanic profiles with qualifications and experience
12. VETA or formal training certification verification
13. Specialization areas and expertise tags
14. Customer ratings and reviews per mechanic
15. Years of experience and vehicles serviced count
16. Portfolio of complex repairs with before/after photos
17. Languages spoken (Swahili, English, etc.)

### Service Booking
18. Browse available services by category (routine maintenance, repair, diagnostic, body work)
19. Select specific service needed from standardized menu
20. Vehicle-specific service recommendations based on make/model/year/mileage
21. Appointment scheduling with available time slots
22. Emergency/walk-in availability indicator
23. Service duration estimate for planned work
24. Drop-off and pick-up time coordination
25. Mobile mechanic option — mechanic comes to your location
26. Queue position and wait time for walk-in services
27. Cancellation and rescheduling with policy display

### Cost Estimates
28. Standardized cost estimates for common services by vehicle type
29. Labor cost transparency — hourly rate or flat rate per service
30. Parts cost breakdown — genuine vs aftermarket options with prices
31. Quote request from multiple garages for comparison
32. Fair price range indicator — shows if quoted price is above/below market
33. Itemized pre-service estimate requiring customer approval
34. No-surprise guarantee — final bill cannot exceed estimate by more than 10% without approval
35. Price history for same service at same garage

### Service Tracking
36. Real-time service progress updates from garage
37. Photo updates showing work being performed
38. Parts replacement photos (showing old and new parts)
39. Mechanic notes and findings during service
40. Additional work discovery notification with cost estimate and approval request
41. Estimated completion time with updates
42. Vehicle ready for pickup notification
43. Digital job card with all work performed

### Service History
44. Complete vehicle service history stored in app
45. Timeline view of all maintenance and repairs
46. Service records linked to specific vehicles in My Cars
47. Downloadable service history report (PDF) for resale
48. Manufacturer recommended service schedule comparison
49. Overdue service alerts based on time or mileage
50. Service cost analytics — spend by category, garage, time period

### Ratings & Reviews
51. 5-star rating system with category breakdown (quality, price, timeliness, communication)
52. Written reviews with photo attachments
53. Garage response to reviews
54. Verified review badge (only from actual customers)
55. Rating-based search ranking
56. Top-rated garages leaderboard by area
57. Report fraudulent reviews mechanism

### Pickup & Delivery
58. Vehicle collection from your location to garage
59. Vehicle delivery after service completion
60. Flatbed towing service for non-drivable vehicles
61. Courtesy car/loaner vehicle availability (premium garages)
62. Pickup/delivery driver tracking on map
63. Vehicle handover checklist with photo documentation

### DIY Support
64. Common problem diagnostic tool — describe symptoms, get possible causes
65. Maintenance guides for basic tasks (oil check, tire pressure, coolant)
66. Warning light decoder — what each dashboard light means
67. Video tutorials for simple DIY repairs
68. Parts identification tool — take a photo to identify the part
69. Ask-a-mechanic feature for quick advice (paid consultation)

## Key Screens

1. **Garage Finder** — Map and list view with search, filters, and nearby recommendations
2. **Garage Profile** — Details, photos, services offered, reviews, booking button
3. **Mechanic Profile** — Individual mechanic info, ratings, specializations
4. **Book Service** — Service selection, vehicle pick, date/time, cost estimate
5. **Get Quotes** — Multi-garage quote comparison for a specific service
6. **Service Tracker** — Real-time progress, photos, notes from active service
7. **Service History** — Timeline of all past services across all vehicles
8. **Cost Estimator** — Look up fair prices for any service by vehicle type
9. **Diagnostic Tool** — Symptom-based problem identifier
10. **Pickup/Delivery** — Schedule vehicle collection or return with tracking
11. **Reviews** — Write, read, and manage reviews for garages and mechanics

## TAJIRI Integration Points

- **Wallet (WalletService)** — Service payment via `WalletService.deposit()` with M-Pesa/Tigo/Airtel STK push. Escrow for large repairs — payment held via wallet until customer confirms satisfactory completion. Tip for mechanics via `WalletService.transfer()`. Milestone payments for multi-day repairs (deposit, parts, labor, final). Transaction history via `WalletService.getTransactions()` shows all service expenses categorized by vehicle. Garage receives payout minus platform commission
- **My Cars Module (my_cars/)** — Vehicle data (make, model, year, engine size, mileage) auto-populated for service booking from registered garage. Service history synced bi-directionally — completed services appear in My Cars timeline with cost, garage, mechanic, and work details. Manufacturer-recommended service schedule generated from vehicle specs. Overdue service alerts triggered from My Cars mileage/date tracking. Service cost analytics linked to vehicle expense reports
- **Car Insurance Module (car_insurance/)** — Insurance-covered repairs routed to authorized/approved garages from claim filing flow. Garage authorization for insurance repairs with direct billing to insurer. Repair cost estimates attached to insurance claim submissions. Panel beater directory filtered by insurance partnerships. Accident repair workflow integrated with claim status tracking
- **Spare Parts Module (spare_parts/)** — Parts sourcing linked to service needs — mechanic selects required parts from spare parts marketplace with vehicle compatibility pre-verified. Part price comparison across sellers before ordering. Parts ordered through spare parts module delivered to garage. Genuine vs aftermarket part choice presented to customer with price difference. Part warranty tracked and linked to service record
- **Buy Car Module (buy_car/)** — Pre-purchase inspection service bookable at trusted garages. Inspection report generated and attached to vehicle listing in Buy Car marketplace. Verified inspection badge drives buyer confidence. Mechanic findings shared directly with buyer via messaging
- **Sell Car Module (sell_car/)** — Pre-sale inspection and minor repair booking to maximize vehicle value. Service history exported as PDF for buyer confidence. Garage recommendations for pre-sale cosmetic repairs
- **Messaging (MessageService)** — Direct communication with garage and assigned mechanic via `MessageService.sendMessage()`. Photo updates of work in progress shared through chat. Additional work discovery discussed with customer before proceeding. Auto-created conversation per booking via `MessageService.createGroup()` linking customer, garage manager, and assigned mechanic. Post-service follow-up messages
- **Notifications (FCMService + NotificationService)** — Push notifications via `FCMService` for: booking confirmation, mechanic assigned, service started, progress updates with photos, additional work needed (requires approval), estimated completion time updates, vehicle ready for pickup, payment receipt, post-service rating reminder, warranty expiry on previous repairs
- **Tajirika Module (tajirika/)** — Mechanics and garage owners registered as TAJIRI partners with verification (VETA certification, business registration). Partner dashboard with earnings, booking management, and rating analytics. Skill verification badges (engine specialist, auto-electrical, panel beating). Commission structure and payout management
- **Fuel Delivery Module (fuel_delivery/)** — Fuel top-up ordered during service if vehicle was near empty — delivered to garage. Fuel expense added to service invoice
- **Profile (ProfileService)** — Garage and mechanic profiles linked to TAJIRI identity via `ProfileService.getProfile()`. Mechanic qualifications, VETA certification, specializations, and years of experience displayed. Customer service history on profile shows verified garage visits. "Trusted Mechanic" badge for top-rated mechanics
- **Groups (GroupService)** — Garage owner community via `GroupService.createGroup()` for industry networking. Mechanic trade groups by specialization (auto-electrical, diesel engines, body work). Customer groups for garage reviews and recommendations. Group posts via `GroupService.getGroupPosts()` for technical discussions and parts sourcing
- **Posts & Stories (PostService + StoryService)** — Share completed repair before/after photos as posts via `PostService.createPost()`. Garage showcases featured repairs. Customer reviews posted to feed. Mechanic shares work portfolio via stories via `StoryService.createStory()`
- **Location (LocationService)** — GPS-based garage finder via `LocationService.searchLocations()` using Tanzania hierarchy. Distance and travel time calculation to garages. Vehicle pickup/delivery route tracking on map. Nearest garage for emergency breakdowns
- **Calendar (CalendarService)** — Service appointments synced to calendar via `CalendarService.createEvent()`. Recurring maintenance reminders. Vehicle pickup/delivery time slots. Warranty follow-up dates
- **Real-time Updates (LiveUpdateService)** — Firestore listeners for real-time service progress updates from garage. Vehicle ready notification in real-time. Quote approval/rejection events. Pickup driver location tracking
- **Media (PhotoService + VideoUploadService)** — Service progress photos uploaded via `PhotoService.uploadPhoto()` — old parts, new parts, work stages. Before/after comparison photos. Vehicle condition inspection photos at drop-off and pickup. Diagnostic video recordings
- **People Search (PeopleSearchService)** — Find trusted mechanics via `PeopleSearchService.search()` by specialization and location. Mutual friends who used same garage shown for trust building
- **Presence (PresenceService)** — Show garage and mechanic availability status via `PresenceService` batch check. Emergency availability indicator for breakdown response
- **Owners Club (owners_club/)** — Mechanic recommendations from brand-specific communities. Model-specific repair advice from owner groups. Community-verified garage ratings
- **Analytics (EventTrackingService)** — Track service spending patterns, garage visit frequency, repair category analytics. Cost comparison between garages over time. Vehicle maintenance cost predictions
