# Tafuta Kanisa (Church Finder) — Feature Description

## Tanzania Context

"Tafuta Kanisa" means "Find a Church" in Swahili. Tanzania has tens of thousands of churches across every denomination — from grand cathedrals in Dar es Salaam to small mud-brick churches in rural villages. When Tanzanians relocate for work, education, or marriage (very common — rural-to-urban migration is significant), finding a new church home is a major priority but a difficult process. People typically ask colleagues, neighbors, or relatives for recommendations.

There is no comprehensive church directory in Tanzania. Google Maps has limited church listings with minimal detail. Denomination-specific directories exist in print form but are outdated. Key information people need: denomination, language of service (some churches offer English services), service times, location, and whether the church has specific ministries (youth, singles, couples). The search is especially challenging in Dar es Salaam, which has thousands of churches across a sprawling urban area.

## International Reference Apps

1. **Church Finder (ACNA)** — Map-based church search with denomination filters
2. **Google Maps** — General place search with reviews and directions
3. **Yelp** — Location-based search with reviews and ratings
4. **Adventist Church Find** — SDA-specific church locator with service details
5. **Catholic Mass Times (Mass Times .org)** — Find Catholic churches with Mass schedules

## Feature List

1. Map-based search — interactive map showing churches near current location or searched area
2. List view — churches sorted by distance with key info summary
3. Denomination filter — filter by Catholic, Lutheran, Anglican, Pentecostal, SDA, Baptist, etc.
4. Service times — Sunday and weekday service schedules
5. Language filter — find churches offering services in Swahili, English, tribal languages
6. Ministry filters — filter by available ministries: youth, singles, couples, children
7. Church profiles — detailed page with photos, description, denomination, pastor info
8. Directions — integrated navigation to church location
9. Reviews and ratings — community reviews (verified attendees only, respectful guidelines)
10. Contact church — call, message, or visit church website directly from listing
11. Upcoming events — see church events before visiting
12. Service style indicator — traditional, contemporary, charismatic, blended
13. Visitor welcome info — parking, dress code, what to expect, accessibility
14. Save favorites — bookmark churches of interest for later
15. Share church — recommend a church to friends via message or feed
16. Suggest a church — community members can submit unlisted churches for addition
17. Recently added — discover newly listed churches in your area

## Key Screens

- **Search/Map Screen** — map with church pins, search bar, filter chips at top
- **Search Results List** — church cards with photo, name, denomination, distance, rating
- **Church Profile** — hero image, info tabs (about, services, events, reviews, photos)
- **Filter Panel** — denomination checkboxes, service time range, language, ministries
- **Directions Screen** — map route from current location to church
- **Reviews Screen** — star rating breakdown, review list with helpful votes
- **Write Review** — rating selector, text review, visit verification
- **Suggest Church Form** — name, denomination, location pin, service times, contact

## TAJIRI Integration Points

- **LocationService.getRegions(), getDistricts()** — GPS-based nearby church search; filter by region and district; map-based discovery
- **ProfileService.getProfile()** — denomination from faith profile pre-filters church suggestions; service language preference matching
- **GroupService.joinGroup()** — tapping "Join" on a church connects to the Kanisa Langu module; church becomes a TAJIRI group
- **MessageService.sendMessage()** — contact church directly through TAJIRI messaging; inquire about services and ministries
- **PostService.createPost()** — "I'm visiting [Church Name]" check-in posts; church recommendation posts
- **NotificationService + FCMService** — alerts for new churches added in your area; new church event notifications
- **PhotoService.uploadPhoto()** — community-submitted church photos for listings
- **events/ module** — church events from Tafuta Kanisa listings appear in TAJIRI events feed
- **Cross-module: Kanisa Langu** — church discovery leads to Kanisa Langu profile for joining and full church engagement
- **Cross-module: Fungu la Kumi** — church M-Pesa till/paybill details accessible for giving after discovery via WalletService
