# TAJIRI Travel Module — Design Spec

**Date:** 2026-04-07
**Status:** Approved
**Scope:** Complete replacement of `lib/travel/` with transport-first travel platform

## Overview

A unified transport search and booking platform for Tanzania (buses, flights, trains, ferries) and international travel (flights globally, cross-border East Africa buses). Users type where they want to go, see all transport options across modes, and book + pay entirely within TAJIRI.

## Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Direction | Full replacement of current module | Current module is tourism-destination focused; new module is transport-first |
| Primary user | Everyday Tanzanian + international traveler | Serve local inter-regional transport AND outbound international travel |
| Booking model | Full booking through TAJIRI backend | Backend aggregates providers, users book and pay within TAJIRI |
| Search UX | Single "Where to?" search, all modes | One search returns buses, flights, trains, ferries — sorted by price |
| Trip planning | Booking-focused only (no itinerary planner) | Search, book, get e-ticket. My Bookings shows your trips |
| International scope | Flights globally + cross-border East Africa buses | Amadeus for flights, BuuPass for regional buses |
| Payment | TAJIRI Wallet + M-Pesa + Tigo Pesa + Airtel Money | Wallet-first keeps money in ecosystem, mobile money as universal fallback |

---

## 1. Data Architecture

### Core Model: TransportOption

Universal transport result that works across all modes:

```
TransportOption
  id: int
  mode: TransportMode (bus/flight/train/ferry)
  operator: { name, logo, code }
  origin: { city, station/airport, code }
  destination: { city, station/airport, code }
  departure: DateTime
  arrival: DateTime
  duration: int (minutes)
  price: { amount, currency }
  class/tier: String (economy/business/vip)
  seatsAvailable: int
  
  Mode-specific (optional):
    flight: { flightNumber, airline, stops, baggageKg }
    bus: { busType, amenities [wifi/ac/toilet], plateNumber }
    train: { trainNumber, trainType (SGR/metre-gauge), coachClass }
    ferry: { vesselName, vesselClass (economy/vip/royal) }
  
  provider: String (otapp/amadeus/internal/buupass)
```

### Supporting Models

- **Route** — origin + destination pair with available modes and typical prices
- **Booking** — user's confirmed booking with status, payment info, passenger list
- **Ticket** — e-ticket with QR code data, boarding info, booking reference
- **Passenger** — name, phone, ID type (Kitambulisho/Passport), ID number
- **PopularRoute** — trending routes for home screen (route + cheapest price + mode icons)
- **City** — name, code, region, country (searchable directory)

### Enums

- **TransportMode** — bus, flight, train, ferry
- **BookingStatus** — pending, confirmed, cancelled, completed
- **PaymentMethod** — wallet, mpesa, tigopesa, airtelmoney
- **PaymentStatus** — pending, paid, refunded

### Backend Database Tables

| Table | Purpose |
|---|---|
| `transport_providers` | Provider registry (Otapp, Amadeus, internal, BuuPass) |
| `transport_cities` | City/station directory with codes, regions, countries |
| `transport_schedules` | Internal schedules for SGR trains and ferries (no API) |
| `transport_inventory` | Seat availability per schedule per date |
| `transport_bookings` | All user bookings with status tracking |
| `transport_passengers` | Passenger manifest per booking |
| `transport_tickets` | Issued e-tickets with QR data |
| `transport_search_cache` | Search result cache (backup to Redis) |

---

## 2. Backend API Design

All endpoints under `/api/travel/`. Backend handles provider aggregation.

### Search & Discovery

```
POST /api/travel/search
  Body: { origin, destination, date, passengers, preferred_mode? }
  Returns: [ TransportOption, ... ] sorted by price
  Behavior: Fans out to all providers in parallel (Http::pool()),
            10s timeout per provider, results cached 15min in Redis
            per {origin}:{destination}:{date} key

GET /api/travel/popular-routes
  Returns: [ PopularRoute, ... ] based on search/booking volume

GET /api/travel/option/{id}
  Returns: TransportOption with full details (baggage, cancellation policy)
```

### Booking Flow

```
POST /api/travel/bookings
  Body: { option_id, passengers: [{name, phone, id_type, id_number}],
          payment_method, payment_phone? }
  Returns: Booking with status=pending
  Behavior: Calls provider booking API, initiates payment,
            on payment confirmation: status→confirmed, generate ticket

GET /api/travel/bookings?user_id={id}
  Returns: [ Booking, ... ] user's bookings (upcoming + past)

POST /api/travel/bookings/{id}/cancel
  Returns: Booking with status=cancelled
  Behavior: Triggers refund per provider's cancellation policy
```

### Tickets

```
GET /api/travel/tickets/{booking_id}
  Returns: Ticket with QR code data, boarding info, reference

GET /api/travel/tickets/{id}/qr
  Returns: QR code image for gate scanning
```

### Supporting

```
GET /api/travel/cities
  Returns: [ City, ... ] searchable city/station list

GET /api/travel/cities/{code}/weather
  Returns: weather at destination (proxied from WeatherAPI.com)
```

**9 endpoints total.**

---

## 3. Backend Architecture

### Provider Aggregation

```
TravelSearchController
  └── TravelSearchService
       ├── OtappProvider      — buses (Tanzania + East Africa)
       ├── AmadeusProvider    — flights (local + international)
       ├── InternalProvider   — SGR trains, ferries (our DB)
       └── BuuPassProvider    — cross-border buses
```

Each provider implements `TransportProviderInterface`:

```php
interface TransportProviderInterface {
    public function search(SearchRequest $request): Collection;
    public function book(BookingRequest $request): BookingResult;
    public function cancel(int $bookingId): CancelResult;
    public function getTicket(int $bookingId): TicketResult;
}
```

### Search Fan-out

`TravelSearchService::search()` fires all providers in parallel via `Http::pool()`. Each provider has 10-second timeout. Results normalized into `TransportOption` DTO format. Cached in Redis for 15 minutes.

### Internal Provider (SGR + Ferries)

SGR and ferries have no APIs. We maintain schedules in `transport_schedules` table:
- route_id, mode, operator, departure_time, arrival_time, days_of_week, class, price, seats_total, active

`transport_inventory` tracks per-date seat availability. Booking against internal provider creates tickets directly — no external API call.

### Payment Flow

1. Reserve option (hold 10 min)
2. Initiate payment: TAJIRI Wallet (instant debit) or Mobile Money (push USSD)
3. Payment webhook confirms → booking confirmed → ticket generated
4. Payment timeout → release reservation

### Environment Variables

```
OTAPP_API_KEY, OTAPP_API_URL
AMADEUS_CLIENT_ID, AMADEUS_CLIENT_SECRET
BUUPASS_API_KEY, BUUPASS_API_URL
WEATHER_API_KEY
```

---

## 4. Frontend Screen Architecture

### Pages (8)

#### Home — `travel_home_page.dart`
- Search bar: "Unataka kwenda wapi?" (Where do you want to go?)
- Recent searches as tappable chips
- Popular routes — cards showing route, cheapest price, mode icons
- My upcoming trips — next 2-3 bookings with countdown

#### Search Results — `search_results_page.dart`
- Header: Origin → Destination, date, passengers (editable)
- Filter chips: All | Bus | Flight | Train | Ferry
- Sort: Price (default) | Duration | Departure time
- Results list of TransportOptionCard
- "Fastest" and "Cheapest" badges on relevant results
- No results: suggest nearby dates, alternative routes, deep links

#### Option Detail — `transport_detail_page.dart`
- Operator info with logo
- Full schedule: departure → arrival with duration
- Class/tier options if multiple
- Amenities (baggage, wifi, AC, toilet, meals)
- Cancellation policy
- "Book Now" button with price

#### Passenger Info — `passenger_info_page.dart`
- Form per passenger: name, phone, ID type (Kitambulisho/Passport), ID number
- Lead passenger auto-filled from TAJIRI profile
- Validation before checkout

#### Checkout — `checkout_page.dart`
- Booking summary (route, time, passengers)
- Price breakdown (fare x passengers + fees)
- Payment: TAJIRI Wallet | M-Pesa | Tigo Pesa | Airtel Money
- Phone number input for mobile money
- "Confirm & Pay" button

#### Booking Confirmation — `booking_confirmation_page.dart`
- Success animation
- Booking reference number
- Summary
- "View Ticket" and "Back to Home" buttons

#### My Bookings — `my_bookings_page.dart`
- Tabs: Upcoming | Past
- Booking cards with status badges
- Tap to view ticket or cancel

#### Ticket View — `ticket_page.dart`
- E-ticket: large QR code, booking reference
- Route, date/time, passenger names, seat/class
- Operator info
- "Share Ticket" button
- Works offline (cached locally)

### Widgets (5)

- **TransportOptionCard** — search result card (mode icon, operator, times, duration, price, seats)
- **RouteCard** — popular route card for home page
- **BookingCard** — my bookings list card
- **ModeIcon** — bus/plane/train/ferry icon helper widget
- **CitySearchField** — autocomplete city/station picker with debounced search

---

## 5. City Search UX

### Flow

1. User taps search bar → opens CitySearchField (bottom sheet)
2. Text input with 300ms debounce → hits `GET /api/travel/cities?q=...`
3. Results grouped: Tanzania cities first → East Africa → International
4. Recent selections pinned at top
5. After selecting origin + destination + date + passengers → fires `POST /search`

### Date & Passenger Selection

- Date picker: single date (one-way only for MVP)
- Passenger counter: 1-9, simple +/- stepper
- Both inline on search form

### Search Form State

Collapsed view on home: "Dar es Salaam → Arusha" with date and count. Tapping reopens full form with values pre-filled.

### Result Sorting Logic

- Default: cheapest first
- If flight exists under 2x cheapest bus price, promote it (value badge)
- "Fastest" and "Cheapest" badges on relevant results
- If only one mode has results, hide mode filter chips

---

## 6. File Structure

### Frontend

```
lib/travel/
├── travel_module.dart
├── models/
│   └── travel_models.dart
├── services/
│   └── travel_service.dart
├── pages/
│   ├── travel_home_page.dart
│   ├── search_results_page.dart
│   ├── transport_detail_page.dart
│   ├── passenger_info_page.dart
│   ├── checkout_page.dart
│   ├── booking_confirmation_page.dart
│   ├── my_bookings_page.dart
│   └── ticket_page.dart
└── widgets/
    ├── transport_option_card.dart
    ├── route_card.dart
    ├── booking_card.dart
    ├── mode_icon.dart
    └── city_search_field.dart
```

**17 frontend files.**

### Backend

```
app/Http/Controllers/Travel/
  ├── TravelSearchController.php
  ├── TravelBookingController.php
  └── TravelTicketController.php

app/Services/Travel/
  ├── TravelSearchService.php
  ├── Providers/
  │   ├── TransportProviderInterface.php
  │   ├── OtappProvider.php
  │   ├── AmadeusProvider.php
  │   ├── InternalProvider.php
  │   └── BuuPassProvider.php
  ├── TravelBookingService.php
  └── TravelTicketService.php

app/Models/Travel/
  ├── TransportProvider.php
  ├── TransportCity.php
  ├── TransportSchedule.php
  ├── TransportInventory.php
  ├── TransportBooking.php
  ├── TransportPassenger.php
  └── TransportTicket.php

app/DTOs/Travel/
  ├── SearchRequest.php
  ├── TransportOptionDTO.php
  └── BookingRequest.php

database/migrations/
  ├── create_transport_providers_table.php
  ├── create_transport_cities_table.php
  ├── create_transport_schedules_table.php
  ├── create_transport_inventory_table.php
  ├── create_transport_bookings_table.php
  ├── create_transport_passengers_table.php
  ├── create_transport_tickets_table.php
  └── create_transport_search_cache_table.php

routes/api.php — travel route group added
```

---

## 7. Integration with TAJIRI

### Profile Tab

Already registered in `profile_tab_config.dart` as `id: 'travel'`. The `_ProfileTabPage._buildContent()` switch case already returns `TravelModule(userId: userId)`. No changes needed — just replace the module internals.

### Wallet Integration

Checkout page calls existing TAJIRI Wallet APIs for balance check and debit. Mobile money flows through existing payment infrastructure.

### Design System

Follows `docs/DESIGN.md`: monochromatic palette (#1A1A1A/#FAFAFA), Material 3, no colorful buttons, SafeArea, 48dp touch targets, `_rounded` icon variants.

---

## Non-Goals (Explicitly Out of Scope)

- Round-trip booking (MVP is one-way only)
- Trip itinerary / day-by-day planner
- Hotel booking
- Reviews and ratings
- Price alerts / price prediction
- Collaborative trip planning
- Offline maps
- Tourism destination features (replaced entirely)
