# Travel Module Research Summary

## International Travel APIs (Best for Startup)

| Category | API | Free Tier | Notes |
|---|---|---|---|
| Flights | Amadeus Self-Service | 2,000 calls/mo | Best documented, covers African airlines |
| Flights (booking) | Kiwi.com Tequila | Free search, affiliate | Virtual interlining unique feature |
| Flights (booking) | Duffel | Free search, ~1% per booking | Modern, NDC direct |
| Multi-modal | Rome2Rio | 100 req/day | Fly/train/bus/ferry/drive comparison |
| Hotels | Booking.com (RapidAPI) | ~50 req/mo | Largest inventory |
| POI/Content | Foursquare | 100K calls/mo | Best free tier for places data |
| Weather | WeatherAPI.com | 1M calls/mo | Effectively unlimited |
| Maps | Mapbox | 50K map loads/mo | Beautiful, full Flutter SDK |
| Currency | FreeCurrencyAPI | 5,000 req/mo | Good for TZS conversions |
| Translation | DeepL | 500K chars/mo | Superior quality |
| Aggregator | Travelpayouts | Unlimited (affiliate) | 728 airlines, 250+ hotel agencies |

---

## Tanzania Local Transport

### Buses (Inter-regional)

**Major operators with online booking:** Shabiby, Dar Express, Kilimanjaro Express, Maning Nice, ABC Upper Class, Asante Rabi, Loliondo Coach, Blue Star, Kimbinyiko

**Key aggregator platforms:**

| Platform | API Available? | Notes |
|---|---|---|
| Otapp (otapp.co.tz) | YES - explicitly offered | Bus, flights, events, cargo. Best integration candidate |
| Busbora (busbora.co.tz) | B2B (contact them) | 100+ operators, won Best E-Ticketing 2024/25 award |
| BuuPass (buupass.com) | Partner API | East Africa (16 countries), acquired QuickBus 2024 |
| Katarama (katarama.co.tz) | Unknown | Pure aggregator |

### Trains

| Service | Online Booking | API |
|---|---|---|
| SGR (Dar-Morogoro-Dodoma) | sgrticket.trc.co.tz | No API |
| TRC Metre Gauge | eticketing.trc.co.tz | No API |
| TAZARA (Dar-Zambia) | Phone/email only | No API |

### Airlines

| Airline | GDS Connected | Integration Path |
|---|---|---|
| Air Tanzania (TC) | Yes (Hitit Crane) | Amadeus API (free tier) |
| Precision Air (PW) | Yes (Hitit Crane) | Amadeus API (free tier) |
| Coastal Aviation (CQ) | Limited | Direct partnership |
| Auric Air (UI) | Yes (via Hahnair) | GDS or direct |
| ~~Fastjet~~ | Ceased 2019 | - |

### Ferries

- Azam Marine (Dar-Zanzibar-Pemba) — online booking, no API, bookable via 12go.asia/Bookaway affiliates

### Ride-hailing

- Bolt (most popular), Uber, InDrive, Paisha (local) — no APIs, use deep links

---

## Recommended Integration Strategy

### Phase 1 — API Integration (available now):
1. Otapp API — Tanzania buses, flights, events (they explicitly offer API)
2. Amadeus — Air Tanzania + Precision Air flights (free dev tier)
3. WeatherAPI.com — destination weather
4. Foursquare — POI/attractions at destinations

### Phase 2 — Partnerships (outreach needed):
5. Busbora — Tanzania's biggest bus platform
6. BuuPass — Regional East Africa bus/train
7. Azam Marine via Bookaway/12go affiliate programs

### Phase 3 — Deep Links (no API needed):
8. SGR train booking → sgrticket.trc.co.tz
9. Ride-hailing → launch Bolt/Uber apps
10. Individual bus company websites

---

## Top Features to Build (Prioritized for Tanzania)

### Tier 1 (MVP):
- Bus search & booking (via Otapp API)
- Flight search (Amadeus + local airlines)
- Trip itinerary builder (day-by-day planner)
- Destination weather
- Booking confirmations & e-tickets

### Tier 2:
- Ferry booking (Dar-Zanzibar)
- SGR train info + deep link
- Price comparison across providers
- Map-based route visualization
- Ride-hailing deep links

### Tier 3:
- Collaborative trip planning (share with friends)
- Price alerts
- Reviews & ratings for destinations
- Travel social feed (integrates with TAJIRI feed)
- Wallet integration for payments
- Offline itinerary access
