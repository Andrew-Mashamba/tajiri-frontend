# Buy Car — Car Marketplace

## Tanzania Context

Buying a car in Tanzania follows several distinct pathways, each with its own ecosystem:

### Importing from Japan (Kuagiza)
The dominant method for acquiring vehicles. Tanzania imports approximately 80% of its vehicles used from Japan. The process involves:
- **Auction houses** — USS (Used Car System Solutions), TAA (Toyota Auto Auction), HAA Kobe, JAA
- **Export agents** — BE FORWARD (largest, Dar es Salaam office), SBT Japan, CardealPage, JapanUsedCars, Autorec
- Buyers select vehicles online, pay CIF (Cost + Insurance + Freight) to Dar es Salaam port
- **Customs clearance** — TRA calculates duty based on: CIF value, age of vehicle, engine capacity. Import duty is 25%, excise duty 0-10%, VAT 18%, plus additional levies
- **Age restriction** — Maximum vehicle age for import is 10 years from manufacture date
- Total landed cost typically = CIF price + 60-80% in taxes and fees
- Process takes 4-8 weeks from purchase to delivery at port

### Importing from Dubai/UAE
Growing alternative for luxury and specialty vehicles. Similar process but shipping is faster (2-3 weeks). Dubai-sourced vehicles are popular for their lower mileage and desert climate (less rust).

### Local Dealers
- **CFAO Motors** — Official Toyota, Suzuki dealer. New vehicles at premium prices
- **Inchcape Tanzania (previously CMC)** — Multiple brands
- **Simba Automotive** — Various brands
- Numerous small used car dealers (showrooms) along Bagamoyo Road, Nyerere Road in Dar es Salaam

### Peer-to-Peer
- Social media groups (Facebook: "Cars for Sale in Tanzania", WhatsApp groups)
- **DukaRaha.com** — Tanzanian classifieds site with vehicle listings
- **ZoomTanzania.com** — Classifieds platform
- **Kupatana** — Mobile classifieds marketplace
- Word of mouth through madalali (vehicle brokers)

Pain points: difficulty verifying vehicle condition before import, hidden costs in the import process, unreliable mileage/condition claims, no standardized inspection for local sales, broker (dalali) fees are opaque, customs duty calculation is complex, fraud risk with online dealers, no financing options for most buyers, and no after-purchase support.

## International Reference Apps

1. **BE FORWARD (Japan/Global)** — Largest used car exporter to Africa. 40,000+ vehicle inventory, detailed photos and specs, CIF pricing to destination port, inspection reports, shipping tracking, office in Dar es Salaam for local support.

2. **AutoTrader (USA/UK/SA)** — Leading car marketplace. New and used inventory, advanced search filters, dealer and private listings, price analysis tools, vehicle history reports, financing calculator, trade-in valuation.

3. **Cars.com (USA)** — Comprehensive car buying platform. New/used/certified listings, editorial reviews, owner reviews, price comparison, dealer ratings, service records, 360-degree photos, video walkarounds.

4. **Carvana (USA)** — Online-only car buying. 360-degree virtual tours, home delivery, 7-day return policy, financing built in, no-haggle pricing, vehicle history included, entirely digital purchase process.

5. **Cheki (Kenya/Nigeria)** — African car marketplace. Local dealer listings, import listings, price guides, dealer verification, loan calculator, insurance quotes, vehicle specifications database.

## Feature List

### Vehicle Search & Discovery
1. Search by make, model, year, price range, body type, fuel type, transmission
2. Advanced filters: engine size, mileage, color, number of seats, drive type (2WD/4WD)
3. Source filter: local dealers, private sellers, Japan import, Dubai import
4. Location-based search with distance radius
5. Saved searches with new listing alerts
6. Recently viewed vehicles history
7. Featured/sponsored listings from verified dealers
8. Price drop alerts for saved/favorited vehicles
9. Similar vehicle suggestions based on browsing history
10. "Most Popular in Tanzania" trending vehicles section

### Vehicle Listings
11. Detailed vehicle information: specs, features, condition description
12. Multi-photo galleries (20+ photos per listing) with zoom capability
13. 360-degree exterior photo view for import vehicles
14. Video walkaround support
15. Vehicle condition rating system (Excellent/Good/Fair/Poor)
16. Mileage verification status indicator
17. Seller verification badge (ID-verified dealers and private sellers)
18. Auction grade display for Japan imports (4, 4.5, 5, R, etc.)
19. Inspection report viewer for import vehicles
20. Vehicle specification comparison — compare 2-3 vehicles side by side

### Import Calculator
21. Full import cost calculator for Japan and Dubai vehicles
22. CIF price breakdown: vehicle price + insurance + freight
23. TRA duty calculation: import duty (25%), excise duty, VAT (18%), withholding tax
24. LATRA inspection fees
25. Port handling and clearing agent fees estimate
26. Total landed cost estimate in TZS and USD
27. Duty comparison by engine size and vehicle age
28. Timeline estimator — expected weeks from purchase to delivery
29. Currency converter with live exchange rates
30. Save and compare import cost calculations

### Dealer Directory
31. Verified dealer profiles with showroom photos, location, contact
32. Dealer inventory browsing
33. Dealer rating and review system
34. Showroom visit scheduling
35. Dealer response time and reliability indicators
36. Import agent profiles (BE FORWARD, SBT, etc.) with local offices
37. Clearing agent directory for import assistance

### Inspection & Verification
38. Book pre-purchase vehicle inspection (for local vehicles)
39. Independent mechanic inspection service integration
40. Import vehicle condition verification against auction sheet
41. Mileage tampering risk indicator based on service history
42. Accident history check where available
43. Stolen vehicle check (via police database integration)
44. Document authenticity verification

### Financing
45. Loan calculator with configurable down payment, term, and interest rate
46. Bank auto loan comparison (CRDB, NMB, NBC, Stanbic, Equity)
47. Pre-qualification check — see if you qualify before applying
48. Loan application submission through the app
49. Monthly payment estimator based on vehicle price
50. Leasing options comparison for businesses

### Purchase Process
51. Make offer / negotiate through in-app messaging
52. Price negotiation tools with market value reference
53. Purchase agreement template generation
54. Escrow payment through TAJIRI Wallet for secure transactions
55. Vehicle transfer document checklist
56. TRA registration transfer guide
57. Import tracking — monitor shipping status for imported vehicles
58. Delivery scheduling for local purchases
59. Post-purchase satisfaction survey

### Market Intelligence
60. Price guide by make/model/year — what vehicles are actually selling for
61. Market trends — which vehicles are gaining/losing value
62. Best value picks — AI recommendations based on budget and needs
63. Import vs local price comparison for same vehicle
64. Seasonal pricing trends (prices typically drop in January-February)
65. Total cost of ownership estimator (fuel, insurance, maintenance, depreciation)

## Key Screens

1. **Browse/Search** — Search bar with filters, vehicle grid/list, sort options
2. **Vehicle Detail** — Full listing with photos, specs, price, seller info, action buttons
3. **Import Calculator** — Interactive duty/cost calculator with saved scenarios
4. **Compare Vehicles** — Side-by-side spec and price comparison
5. **Dealer Directory** — Map and list view of dealers with profiles
6. **Dealer Profile** — Dealer info, inventory, ratings, reviews
7. **Financing** — Loan calculator, bank comparison, pre-qualification
8. **Saved/Favorites** — Saved vehicles and searches with alerts
9. **Negotiations** — Active offer/counter-offer threads
10. **Purchase Tracker** — Status of ongoing purchases, imports in transit
11. **Market Insights** — Price trends, popular vehicles, recommendations

## TAJIRI Integration Points

- **Wallet (WalletService)** — Escrow payments via `WalletService.deposit()` with M-Pesa/Tigo/Airtel STK push — funds locked until buyer confirms vehicle receipt. Deposit payments to hold vehicles during negotiation. Full purchase payments processed through wallet for transaction security. Import payments (CIF, duty, clearing fees) tracked as wallet transactions. Refunds from cancelled deals via `WalletService.transfer()`. Transaction history via `WalletService.getTransactions()` shows complete purchase financial trail. PIN verification via `WalletService.setPin()` for high-value transactions
- **My Cars Module (my_cars/)** — Purchased vehicle auto-registered in My Cars garage after sale completion with all specs, photos, and purchase documentation. Import tracking data (shipping, customs, clearance) transferred to vehicle profile. Pre-purchase inspection report attached as initial vehicle record. Vehicle details from listing flow directly into garage entry
- **Car Insurance Module (car_insurance/)** — Insurance quote generation integrated into purchase flow — get quotes from 10+ providers while browsing vehicles. Insurance cost factored into total cost of ownership calculator. One-tap insurance purchase after vehicle acquisition. TIRA policy verification for vehicles already insured
- **Loans Module (loans/ + kikoba/)** — Vehicle financing linked to TAJIRI lending partners (CRDB, NMB, NBC, Stanbic, Equity). Pre-qualification check via loan calculator before shopping. Loan application submission through the app with vehicle details pre-filled. Monthly payment estimator on every listing. Kikoba savings groups for collective vehicle purchase pools
- **Service Garage Module (service_garage/)** — Pre-purchase inspection booking at trusted garages with mechanic report attached to listing. Inspection findings shared between buyer and garage via messaging. Post-purchase initial service scheduling. Mechanic recommendations from community for vehicle-specific inspection
- **Messaging (MessageService)** — Buyer-seller communication via `MessageService.sendMessage()` for negotiations and questions. Dealer inquiry threads organized by vehicle listing. Quote/counter-offer messaging with structured offer cards. Auto-created conversation upon inquiry via `MessageService.createGroup()` for multi-party deals (buyer, seller, dalali). Import agent communication for overseas purchases
- **Profile (ProfileService)** — Seller verification badge linked to TAJIRI identity via `ProfileService.getProfile()`. Dealer profiles with verification status, response time, and sales history. Buyer identity verification for test drive safety. NIDA ID verification status displayed
- **Notifications (FCMService + NotificationService)** — Push notifications via `FCMService` for: price drop alerts on saved vehicles, new listing matches for saved searches, shipping status updates for imports (purchased, shipped, at port, cleared), offer responses from sellers, inspection report ready, financing pre-approval results, dealer responses
- **Groups (GroupService)** — Car buying advice groups via `GroupService.createGroup()` — import tips, dealer reviews, model-specific communities. Group posts via `GroupService.getGroupPosts()` for asking community about specific vehicles. Regional buyer groups (Dar es Salaam, Arusha, Mwanza)
- **Posts & Stories (PostService + StoryService)** — Share new car purchase as celebration post via `PostService.createPost()`. Dealer review posts with ratings and photos. Import journey stories via `StoryService.createStory()` documenting the buying process. Community Q&A posts about vehicle models
- **Tajirika Module (tajirika/)** — Verified vehicle brokers (madalali) offering sourcing services as TAJIRI partners. Dalali profiles with ratings, specializations (Japan imports, local deals, luxury). Commission transparency — fixed rates displayed upfront. Broker-assisted purchases with escrow protection
- **Sell Car Module (sell_car/)** — Transition from buyer to seller for trade-in scenarios. Trade-in valuation tool comparing current vehicle value against purchase price. Seller listings from Sell Car appear in Buy Car marketplace. Cross-linked vehicle history between modules
- **Location (LocationService)** — Location-based dealer and listing search via `LocationService.searchLocations()` using Tanzania hierarchy. Showroom visit navigation. Port location tracking for imports. Regional price variations based on distance from Dar es Salaam port
- **Calendar (CalendarService)** — Showroom visit appointments synced to calendar via `CalendarService.createEvent()`. Import timeline milestones (purchase date, shipping date, port arrival, clearance). Test drive scheduling
- **Media (PhotoService + VideoUploadService)** — Vehicle listing photos viewed via `PhotoService.getPhotos()`. Video walkaround playback. 360-degree exterior views. Damage/defect photo inspection. Import auction sheet photos
- **People Search (PeopleSearchService)** — Find trusted dealers and brokers via `PeopleSearchService.search()`. Mutual friends who bought from same dealer shown for trust building. Filter by location and specialization
- **Real-time Updates (LiveUpdateService)** — Firestore listeners for real-time price changes on watched vehicles. New listing alerts matching saved searches. Import shipping status updates. Offer/counter-offer real-time notifications
- **Content Discovery (ContentEngineService + HashtagService)** — Personalized vehicle recommendations based on browsing history via `ContentEngineService`. Trending vehicles and hashtags (#MagariDar, #ImportFromJapan). Market intelligence content pushed through content engine
- **Budget (BudgetService)** — Total cost of ownership projections via `BudgetService`. Purchase budget tracking including import duties and fees. Financing cost comparisons factored into budget
- **Rent Car Module (rent_car/)** — "Try before you buy" rental option — rent a similar model before committing to purchase. Test drive alternative via short-term rental
