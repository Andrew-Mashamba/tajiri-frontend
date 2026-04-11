# Sell Car — Feature Description

## Tanzania Context

Selling a car in Tanzania is a fragmented, trust-deficit process. There is no dominant online marketplace with buyer protections, vehicle verification, or price standardization. The process is heavily intermediary-dependent and rife with friction.

### How Tanzanians Currently Sell Cars

**Through Madalali (Brokers)**
- The most common method. Vehicle brokers operate near car showroom areas (Bagamoyo Road, Nyerere Road in Dar es Salaam)
- Dalali charges 2-5% commission from seller, sometimes also from buyer
- Dalali handles showing the vehicle to prospects but has no accountability for misrepresentation
- Multiple madalali may show the same car, creating confusion
- No written agreements in most cases

**Social Media**
- Facebook groups ("Cars for Sale Tanzania", "Magari bei nafuu Dar es Salaam") are widely used
- WhatsApp status updates and group posts
- Instagram for premium/luxury vehicles
- No buyer protection, frequent scams, photos may not match actual vehicle
- Price negotiation happens in DMs with no structure

**Classifieds Platforms**
- **DukaRaha.com** — General classifieds with vehicle section, basic listings
- **ZoomTanzania.com** — Classifieds platform, moderate traffic
- **Kupatana** — Mobile-first classifieds, basic features
- All platforms offer simple listing functionality without verification, inspection, or transaction support

**Showroom Consignment**
- Some dealers accept cars on consignment — display and sell for a fee
- Dealer takes a significant cut (10-15%)
- Vehicle may sit for months with no updates to owner

**Direct Sale**
- "For Sale" signs on windshield while driving or parked
- Word of mouth through personal network
- Selling to other dealers at wholesale prices (quickest but lowest return)

Pain points: no reliable vehicle valuation tools (pricing is guesswork), no verification of vehicle condition leads to buyer distrust, no secure payment mechanism (cash transactions carry robbery risk), title transfer process is confusing, scam buyers who test drive and disappear, time wasted on non-serious inquiries, no way to showcase service history or vehicle quality, and women sellers face additional safety concerns meeting unknown buyers.

## International Reference Apps

1. **Carvana (USA)** — Sell car online instantly. Enter vehicle details, get instant offer, schedule pickup, get paid same day. No negotiation, no dealership visit, transparent pricing based on market data.

2. **Vroom (USA)** — Online car selling. Instant cash offer, free vehicle pickup, payment within days, no haggling, appraisal based on photos and description, mileage verification.

3. **AutoTrader (UK/USA/SA)** — Self-service listing platform. Create detailed listings with photos, pricing guidance, buyer inquiries managed in-app, dealer offers, premium listing options, market valuation tools.

4. **Motorway (UK)** — Online car auction to dealers. List car with photos and details, verified dealers bid, sell to highest bidder, free collection, fast payment, no haggling with individual buyers.

5. **OLX Autos (Global)** — Emerging market car selling. Instant valuation, inspection at your location, instant offer, same-day payment, handle all paperwork, operating across Africa, Asia, and Latin America.

## Feature List

### Vehicle Listing Creation
1. Step-by-step listing wizard with guided prompts
2. Vehicle details auto-populated from TAJIRI My Cars (if registered)
3. Make, model, year, mileage, fuel type, transmission, engine size entry
4. Condition assessment questionnaire (exterior, interior, mechanical, electrical)
5. Feature checklist: AC, power steering, sunroof, leather seats, alloys, etc.
6. Multi-photo upload with guided angles (front, rear, both sides, interior, engine, dashboard, tires)
7. Photo quality checker — reject blurry or too-dark images
8. Video walkaround upload option (30-60 second tour)
9. Damage/defect photo and description section with honesty incentive
10. Service history upload from TAJIRI My Cars or manual entry
11. Modification and upgrade disclosure section
12. Ownership history — number of previous owners
13. Reason for selling (optional, builds buyer trust)
14. Listing preview before publishing

### Price Suggestion & Valuation
15. AI-powered price suggestion based on make, model, year, mileage, condition, and market data
16. Market comparison — show similar vehicles currently listed and recently sold
17. Price range indicator: quick sale price, fair price, optimistic price
18. Regional price adjustment (Dar es Salaam vs upcountry pricing)
19. Price trend for specific model — is value going up or down
20. Import value comparison — what does this car cost to import fresh from Japan
21. Depreciation calculator based on age and mileage
22. Price revision suggestions if listing has no inquiries after set period

### Listing Management
23. Edit listing details, photos, and price at any time
24. Pause/unpause listing without losing data
25. Boost listing for increased visibility (paid feature)
26. Featured listing placement on browse page
27. Listing performance analytics (views, saves, inquiries, share count)
28. Auto-relist after expiry with option to update price
29. Duplicate listing detection and prevention
30. Multi-platform sharing — share listing to WhatsApp, Facebook, Instagram with one tap

### Buyer Communication
31. In-app messaging with interested buyers
32. Inquiry management dashboard — all conversations in one place
33. Quick reply templates for common questions
34. Buyer profile visibility — see buyer's TAJIRI profile and verification status
35. Serious buyer indicators (verified identity, pre-approved financing)
36. Schedule test drive with calendar integration
37. Test drive safety features — share location with emergency contact during test drive
38. Block/report suspicious buyers
39. Offer management — receive, counter, accept, or decline offers

### Inspection & Verification
40. Request TAJIRI-certified inspection before listing (builds buyer confidence)
41. Inspection report attached to listing with quality seal
42. Mileage verification certificate
43. Mechanical condition report from certified mechanic
44. Body condition report with damage mapping
45. Inspection badges on listing (drives 3x more inquiries)
46. Verified seller badge for completed identity check

### Transaction Support
47. Secure payment through TAJIRI Wallet escrow
48. Payment milestone option: deposit to hold, balance on transfer
49. Title transfer document checklist and guidance
50. TRA registration transfer step-by-step guide
51. Bill of sale template generation (pre-filled with transaction details)
52. Both parties confirm transaction completion
53. Funds released from escrow only after buyer confirms receipt
54. Transaction dispute resolution process

### Documentation
55. Document checklist: what papers you need to sell (logbook, insurance, road license, ID)
56. Document upload and verification
57. Outstanding loan/lien disclosure requirement
58. Insurance transfer or cancellation guidance
59. Road license status verification
60. Digital transaction record for both parties

### After-Sale
61. Mark vehicle as sold — auto-update/remove listing
62. Buyer rating — rate the buyer experience
63. Transaction summary with all details for records
64. Remove vehicle from My Cars garage after sale
65. Referral bonus for recommending Sell Car to other sellers

## Key Screens

1. **Create Listing** — Multi-step wizard: details, photos, condition, pricing
2. **Price Suggestion** — AI valuation with market comparison data
3. **My Listings** — All active, paused, and sold listings with performance stats
4. **Listing Detail** — Full public view of listing as buyers see it
5. **Inquiries** — All buyer messages and offers organized by listing
6. **Offer Management** — Received offers with accept/counter/decline actions
7. **Inspection Request** — Book vehicle inspection and view reports
8. **Transaction** — Escrow payment, document checklist, transfer guide
9. **Listing Analytics** — Views, saves, inquiries, clicks over time
10. **Boost Listing** — Premium placement options and pricing

## TAJIRI Integration Points

- **Wallet (WalletService)** — Escrow payments via `WalletService.deposit()` with M-Pesa/Tigo/Airtel STK push — buyer funds locked until both parties confirm vehicle handover. Listing boost payments (featured/premium placement) charged to wallet. Sale proceeds deposited to seller wallet via `WalletService.transfer()` upon escrow release. Milestone payments supported: deposit to hold, balance on transfer. Transaction history via `WalletService.getTransactions()` shows complete sale financial trail. PIN verification via `WalletService.setPin()` for escrow release authorization
- **My Cars Module (my_cars/)** — Auto-populate listing with all vehicle details (make, model, year, mileage, specs, photos) from registered vehicle in My Cars garage. Complete service history synced to listing — verified maintenance record builds buyer confidence and commands higher price. Vehicle removed from garage after confirmed sale. Expense history available as total cost of ownership disclosure
- **Buy Car Module (buy_car/)** — Listings from Sell Car appear directly in Buy Car marketplace for buyer discovery. Cross-linked vehicle details ensure consistency. Trade-in workflow: seller can browse Buy Car while listing current vehicle. Price comparison with similar vehicles in marketplace
- **Car Insurance Module (car_insurance/)** — Insurance transfer guidance during sale process — step-by-step instructions for policy transfer to new owner. Pro-rata premium refund calculation for cancelled policies. Insurance status verified and displayed on listing. Active comprehensive insurance shown as seller trust indicator
- **Service Garage Module (service_garage/)** — Pre-sale inspection booking at verified garages to generate inspection report for listing. Minor repair booking to maximize vehicle value before listing. Inspection badges on listing (verified condition drives 3x more inquiries). Mechanic report attached to listing with quality seal
- **Messaging (MessageService)** — Buyer-seller communication channel via `MessageService.sendMessage()` with all conversations organized by listing. Quick reply templates for common buyer questions. Offer/counter-offer messaging with structured price negotiation. Schedule test drives through chat. Auto-created conversation per inquiry. Block/report suspicious buyers. `MessageService.createGroup()` for multi-party deals involving dalali
- **Notifications (FCMService + NotificationService)** — Push notifications via `FCMService` for: new inquiry received, new offer/counter-offer, listing views milestone (50, 100, 500 views), listing expiry warning, escrow payment received, buyer confirmed receipt, listing boost performance updates, price suggestion if listing has no inquiries after 7 days
- **Profile (ProfileService)** — Seller verification badge (NIDA ID verified) displayed on listings via `ProfileService.getProfile()`. Seller rating from previous sales shown. Transaction history count ("Seller has completed 5 sales on TAJIRI"). Profile photo and name linked for accountability
- **Groups (GroupService)** — Car selling tips groups via `GroupService.createGroup()`. Model-specific communities for targeted listing promotion. Regional seller groups (Dar es Salaam, Arusha, Mwanza). Group posts via `GroupService.getGroupPosts()` for pricing advice and market insights
- **Posts & Stories (PostService + StoryService)** — Share vehicle listing as post via `PostService.createPost()` to reach wider audience beyond marketplace. "Just sold!" celebration posts. Share listing to stories via `StoryService.createStory()` for time-limited promotion. Multi-platform sharing to WhatsApp, Facebook, Instagram from listing
- **Tajirika Module (tajirika/)** — Professional vehicle brokers (madalali) assist with listing optimization, vehicle showing, and buyer vetting. Dalali commission transparent and fixed — displayed upfront. Broker handles in-person showings and test drives. Verified dalali badge on listings assisted by brokers
- **Owners Club (owners_club/)** — Announce sale to brand community members first via community post — reaches motivated buyers who know the model. Community members can vouch for vehicle condition. Model-specific pricing advice from experienced owners
- **Location (LocationService)** — Listing location tagged via `LocationService.searchLocations()` using Tanzania hierarchy. Buyer distance filter shows listings nearest to them. Test drive location coordination. Regional price adjustment based on location (Dar es Salaam vs upcountry)
- **Calendar (CalendarService)** — Test drive appointments synced to calendar via `CalendarService.createEvent()`. Listing expiry dates tracked. Vehicle handover scheduling. TRA transfer appointment booking
- **Media (PhotoService + VideoUploadService)** — Multi-photo gallery uploaded via `PhotoService.uploadPhoto()` with guided angles (front, rear, sides, interior, engine, dashboard, tires). Video walkaround via `VideoUploadService` (30-60 second tour). Photo quality validation — reject blurry or dark images. Damage/defect photos in separate section for transparency
- **People Search (PeopleSearchService)** — Buyer profile visibility via `PeopleSearchService.search()` — see buyer's TAJIRI verification status. Mutual friends shown for trust building during test drives. Serious buyer indicators (verified identity, pre-approved financing)
- **Real-time Updates (LiveUpdateService)** — Firestore listeners for real-time offer notifications. Escrow payment confirmation events. Listing view count updates. Buyer interest signals in real-time
- **Presence (PresenceService)** — Show seller online status via `PresenceService` — buyers see when seller is active for quick responses. Response time tracking displayed on listing
- **Analytics (EventTrackingService)** — Listing performance analytics: views, saves, inquiries, shares over time. Price competitiveness analysis compared to similar listings. Best time to list based on marketplace activity patterns
- **Friends (FriendService)** — Share listing with friends via `FriendService.getFriends()` for referral-based selling. Mutual friends between buyer and seller displayed for trust. Friend referral bonus for recommending Sell Car to others
- **Content Discovery (ContentEngineService + HashtagService)** — Listing visibility boosted through content recommendations. Vehicle-specific hashtags (#ToyotaPrado, #MagariDar) for discoverability. Trending models highlighted in marketplace
