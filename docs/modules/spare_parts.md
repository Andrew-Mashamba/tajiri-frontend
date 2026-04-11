# Spare Parts — Feature Description

## Tanzania Context

The spare parts market in Tanzania is enormous and largely informal. Most parts enter through:
- **Japan/Dubai imports** — Used parts from scrapped vehicles (known as "cut" parts)
- **China/India imports** — New aftermarket parts, varying quality
- **Local recycling** — Parts stripped from accident vehicles at "boneyards"

Key market characteristics:
- **Kariakoo Market (Dar es Salaam)** — Massive spare parts area with hundreds of shops
- **No standardized pricing** — Same part can vary 300% between shops
- **Counterfeit parts epidemic** — Fake brake pads, oil filters, bearings are common and dangerous
- **No compatibility verification** — Buyers often purchase wrong parts
- Each major city has its own spare parts area (Arusha Central Market, Mwanza, Dodoma)
- Most transactions are cash-based with no receipts or warranties
- Finding rare parts requires calling multiple dealers — time-consuming process

## International Reference Apps

1. **RockAuto** — Comprehensive online parts catalog with vehicle compatibility, diagrams, competitive pricing
2. **AutoZone** — Parts lookup by VIN/registration, DIY guides, store inventory check
3. **Pelican Parts** — OEM and aftermarket, technical articles, community forums
4. **PartSouq** — Middle East/Africa focused, genuine parts, multi-brand
5. **Jiji/Kupatana** — Local classifieds used for parts but with zero verification

## Feature List

1. Search parts by vehicle make/model/year
2. VIN-based compatibility checker
3. Part number cross-reference (OEM to aftermarket)
4. Photo-based part identification (snap a photo → AI identifies the part)
5. Price comparison across multiple dealers
6. Dealer/shop directory with location, specialization, ratings
7. New vs used parts filter
8. Genuine vs aftermarket vs refurbished labels
9. Part condition grading (A/B/C for used parts)
10. Delivery options (pickup, boda delivery, courier)
11. Order tracking
12. Warranty information per part
13. Return/exchange policy display
14. Seller verification badges (verified dealer vs individual)
15. Request a part (post what you need → dealers respond with quotes)
16. Bulk ordering for garages/mechanics
17. Installation guide links (video/text)
18. Part diagram viewer (exploded view of car systems)
19. Price history (track if prices are rising/falling)
20. Saved vehicles (quick lookup for your cars)
21. Favourite parts/dealers
22. Chat with seller before buying
23. M-Pesa payment integration
24. Review and rate parts quality after purchase
25. Report counterfeit/fake parts
26. Integration with Service & Garage module (mechanic orders parts for your car)

## Key Screens

1. **Search** — Make/model/year selector + text search + photo search
2. **Part Detail** — Photos, compatibility list, price comparison, seller info, reviews
3. **Dealers Directory** — Map view, filter by specialization (Toyota, BMW, etc.)
4. **Request a Part** — Post your need, get quotes from dealers
5. **My Orders** — Order tracking, delivery status
6. **My Vehicles** — Saved cars for quick part lookup
7. **Cart & Checkout** — M-Pesa/wallet payment

## TAJIRI Integration Points

- **Wallet (WalletService)** — Parts purchases via `WalletService.deposit()` with M-Pesa/Tigo/Airtel STK push. Multi-seller cart checkout processed through wallet. Escrow for high-value parts (engines, gearboxes) — payment held until buyer confirms receipt and condition. Seller payouts via `WalletService.transfer()` minus platform commission. Bulk order payments for garages and mechanics. Transaction history via `WalletService.getTransactions()` shows all parts purchases with order details. Refunds for returned/defective parts credited to wallet
- **My Cars Module (my_cars/)** — Auto-fill vehicle details (make, model, year, engine size, VIN/chassis number) when searching parts from registered vehicles in My Cars garage. VIN-based exact part matching using stored chassis number. Saved vehicles for quick repeat lookups. Parts purchase history linked to vehicle service records in My Cars. Compatibility verification against registered vehicle specs before purchase
- **Service Garage Module (service_garage/)** — Mechanic can order parts directly for your service — garage selects required parts during service booking with customer approval. Parts delivered to garage for installation. Installation cost estimate combined with part price for total job quote. Parts ordered through spare parts module linked to service record. Garage inventory management for common parts
- **Messaging (MessageService)** — Chat with dealers/sellers via `MessageService.sendMessage()` before buying — ask about condition, compatibility, availability. Negotiate price through messaging. Request-for-part responses from multiple sellers managed in conversation threads. Auto-created conversation upon inquiry. `MessageService.createGroup()` for multi-party deals (buyer, seller, mechanic)
- **Tajirika Module (tajirika/)** — Mechanics source parts through their Tajirika partnership for customer jobs. Parts dealers and importers registered as TAJIRI partners with verification badges. Partner commission tracking and earnings dashboard. Dealer onboarding with business registration verification. Import agent profiles for ordering from Japan, Dubai, China
- **Groups (GroupService)** — Owners Club members share trusted parts dealers via `GroupService.getGroupPosts()`. Model-specific parts sourcing groups. Mechanic trade groups for wholesale parts sourcing. Community counterfeit alert system — members flag fake parts. Brand-specific groups (Toyota parts, BMW parts) via `GroupService.createGroup()`
- **Notifications (FCMService + NotificationService)** — Push notifications via `FCMService` for: order status updates (confirmed, shipped, delivered), price drop alerts on watched parts, request-for-part quote responses from sellers, part availability notifications for out-of-stock items, recall alerts for registered vehicles, delivery confirmation, counterfeit warning alerts from community, review reminders after purchase
- **Profile (ProfileService)** — Seller verification badge via `ProfileService.getProfile()` — verified dealer vs individual. Parts purchase history on profile. Dealer ratings and review count displayed. Certified genuine parts dealer badge for authorized sellers
- **Posts & Stories (PostService + StoryService)** — Parts review posts with photos via `PostService.createPost()` — share quality feedback on purchased parts. Seller recommendation posts. Counterfeit alert posts shared to feed. Installation success stories via `StoryService.createStory()`
- **Shop (ShopService)** — Parts listings integrated into TAJIRI marketplace via `ShopService`. Product catalog with reviews. Cart and checkout infrastructure. Order tracking through shop system. Seller storefront management
- **Location (LocationService)** — Parts shop directory with location search via `LocationService.searchLocations()` using Tanzania hierarchy. Map view of nearby dealers (Kariakoo, Tandika). Navigation to shop location. Delivery zone calculation based on seller and buyer location
- **Media (PhotoService)** — Parts listing photos uploaded via `PhotoService.uploadPhoto()`. Condition documentation for used parts. Photo-based part identification — snap a photo, AI identifies the part. Delivery confirmation photos. Receipt photo storage
- **Owners Club (owners_club/)** — Community-recommended sellers highlighted in search results. Vehicle-specific parts advice from experienced owners. Modification parts sourcing through community knowledge base. Community-verified parts quality ratings
- **People Search (PeopleSearchService)** — Find trusted parts dealers by specialization and location via `PeopleSearchService.search()`. Mutual friends who bought from same seller shown for trust
- **Real-time Updates (LiveUpdateService)** — Firestore listeners for real-time order status updates. New quote responses for request-for-part posts. Price change alerts on watched parts
- **Calendar (CalendarService)** — Parts delivery estimates synced to calendar via `CalendarService.createEvent()`. Import arrival dates for pre-ordered parts. Warranty expiry date reminders
- **Presence (PresenceService)** — Show dealer online status via `PresenceService` for real-time inquiries. Response time indicator on dealer profiles
- **Content Discovery (ContentEngineService + HashtagService)** — Parts recommendations based on registered vehicles via `ContentEngineService`. Trending parts searches. Vehicle-specific hashtags for parts discovery. Popular aftermarket brands highlighted
- **Buy Car Module (buy_car/)** — Parts availability check for vehicles being considered for purchase — ensure spare parts are readily available before buying a car model
- **Budget (BudgetService)** — Parts spending tracked via `BudgetService` as vehicle maintenance expense. Monthly parts budget alerts. Cost comparison analytics across purchase history
