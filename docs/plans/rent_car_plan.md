# Rent Car — Implementation Plan

## Overview

Rent Car provides vehicle rental services for Tanzania covering traditional rental companies, peer-to-peer car sharing (owners list personal vehicles), and chauffeur-driven services. It serves tourists, business travelers, locals needing temporary vehicles, and corporate fleets. Features include rich vehicle browsing with filters, transparent pricing with insurance options, digital pickup/return with condition inspection, P2P host earnings dashboard, chauffeur booking with driver profiles, fleet management for corporate accounts, and 24/7 roadside assistance.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/rent_car/
├── rent_car_module.dart               — Entry point & route registration
├── models/
│   ├── rental_vehicle_models.dart     — RentalVehicle, VehicleCategory
│   ├── booking_models.dart            — RentalBooking, BookingStatus
│   ├── pricing_models.dart            — RentalPricing, Insurance, Extra
│   ├── host_models.dart               — P2PHost, HostEarnings, HostVehicle
│   └── chauffeur_models.dart          — Chauffeur, ChauffeurBooking
├── services/
│   └── rent_car_service.dart          — API service using AuthenticatedDio
├── pages/
│   ├── browse_vehicles_page.dart      — Grid with filters and map
│   ├── vehicle_detail_page.dart       — Photos, specs, pricing, reviews
│   ├── booking_flow_page.dart         — Dates, insurance, extras, payment
│   ├── my_bookings_page.dart          — Active and past rentals
│   ├── pickup_return_page.dart        — Check-in, inspection, agreement
│   ├── list_your_car_page.dart        — P2P host listing creation
│   ├── owner_dashboard_page.dart      — Host earnings and bookings
│   ├── chauffeur_selection_page.dart   — Driver profiles and booking
│   ├── corporate_dashboard_page.dart   — Fleet bookings, billing
│   ├── roadside_assistance_page.dart   — Emergency help request
│   └── rental_agreement_page.dart      — Digital contract
└── widgets/
    ├── vehicle_rental_card_widget.dart  — Photo, price/day, rating
    ├── date_range_picker_widget.dart    — Pickup/return date selector
    ├── insurance_option_widget.dart     — Protection tier cards
    ├── condition_inspector_widget.dart  — Photo checklist for vehicle state
    └── chauffeur_card_widget.dart       — Driver photo, languages, rating
```

### Data Models
- **RentalVehicle**: id, hostId, make, model, year, category (sedan/SUV/4x4/van/luxury/bus), seats, transmission, fuelType, photos[], dailyRate, weeklyRate, monthlyRate, mileagePolicy, fuelPolicy, rating, reviewCount, availability[], location. `factory RentalVehicle.fromJson()`.
- **RentalBooking**: id, vehicleId, renterId, pickupDate, returnDate, pickupLocation, returnLocation, insurance, extras[], totalCost, deposit, status (pending/confirmed/active/returned/completed), agreement. `factory RentalBooking.fromJson()`.
- **P2PHost**: id, userId, vehicles[], earnings, payouts[], rating, isSuperhost. `factory P2PHost.fromJson()`.
- **Chauffeur**: id, name, photo, experience, languages[], rating, safariGuide, availability. `factory Chauffeur.fromJson()`.

### Service Layer
- `searchVehicles(Map filters)` — GET `/api/rent-car/vehicles`
- `getVehicle(int id)` — GET `/api/rent-car/vehicles/{id}`
- `createBooking(Map bookingData)` — POST `/api/rent-car/bookings`
- `getMyBookings()` — GET `/api/rent-car/bookings`
- `getBooking(int id)` — GET `/api/rent-car/bookings/{id}`
- `submitInspection(int bookingId, Map inspection)` — POST `/api/rent-car/bookings/{id}/inspection`
- `listCarForRent(Map vehicleData)` — POST `/api/rent-car/host/vehicles`
- `getHostDashboard()` — GET `/api/rent-car/host/dashboard`
- `getChauffeurs(Map filters)` — GET `/api/rent-car/chauffeurs`
- `requestRoadsideAssistance(int bookingId)` — POST `/api/rent-car/roadside`

### Pages & Screens
- **Browse Vehicles**: Photo grid with category tabs (All/Sedan/SUV/4x4/Luxury/Safari), date picker, location filter.
- **Vehicle Detail**: Photo carousel, specs, daily/weekly/monthly rates, reviews, availability calendar, book button.
- **Booking Flow**: Date/time selection, insurance tier picker, extras checkboxes, price breakdown, payment.
- **Pickup/Return**: Photo checklist (6 angles + interior), damage annotation, digital agreement signature.
- **Owner Dashboard**: Earnings chart, booking calendar, vehicle utilization rate, payout history.

### Widgets
- `VehicleRentalCardWidget` — Photo, make/model, price/day, rating, seats icon
- `DateRangePickerWidget` — Dual calendar with pickup/return selection
- `InsuranceOptionWidget` — Tier cards (Basic/Comprehensive/Zero-Excess) with coverage details
- `ConditionInspectorWidget` — Photo slots with angle labels and damage annotation
- `ChauffeurCardWidget` — Photo, name, languages flags, rating, safari badge

---

## 2. UI Design

- Browse: Category tabs scrollable, 2-column grid below
- Booking flow: Single scrollable page with sections
- Insurance tiers: Card stack with recommended highlighted
- Inspection: Camera viewfinder with overlay guide

### Key Screen Mockup — Browse Vehicles
```
┌─────────────────────────────┐
│  SafeArea                   │
│  [Dar es Salaam ▼] [Dates] │
│  [All][Sedan][SUV][4x4][+] │
│  ┌──────┐ ┌──────┐         │
│  │[Photo]│ │[Photo]│         │
│  │Prado  │ │Rav4  │         │
│  │7 seats│ │5seat │         │
│  │$80/day│ │$45/d │         │
│  │★ 4.7  │ │★ 4.3 │         │
│  └──────┘ └──────┘         │
│  ── Safari Vehicles ─────   │
│  [Land Cruiser Pop-top]     │
│  $200/day with guide        │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### Local-First with SQLite
```dart
// Table: rental_vehicles
// Columns: id INTEGER PRIMARY KEY, category TEXT, daily_rate REAL, location TEXT, json_data TEXT, synced_at TEXT
// Indexes: category, daily_rate
// Table: rental_bookings
// Columns: id INTEGER PRIMARY KEY, status TEXT, pickup_date TEXT, json_data TEXT, synced_at TEXT
// Indexes: status, pickup_date
```

### Stale-While-Revalidate
- Vehicle listings: cache TTL 30 minutes
- Bookings: cache TTL 15 minutes
- Chauffeur list: cache TTL 1 hour
- Host dashboard: cache TTL 30 minutes

### Offline Support
- Read: Vehicle listings, booking details, host earnings
- Write: Booking requests queued, inspection photos cached
- Sync: Booking status priority sync on reconnect

### Media Caching
- Vehicle photos: MediaCacheService (14-day TTL)
- Chauffeur photos: 30-day TTL
- Inspection photos: cached locally until confirmed uploaded

---

## 4. Backend Implementation

### Database Tables
```sql
CREATE TABLE rental_vehicles (
    id BIGSERIAL PRIMARY KEY,
    host_id BIGINT REFERENCES users(id),
    host_type VARCHAR(20),
    make VARCHAR(100),
    model VARCHAR(100),
    year INTEGER,
    category VARCHAR(30),
    seats INTEGER,
    transmission VARCHAR(20),
    fuel_type VARCHAR(20),
    daily_rate DECIMAL(12,2),
    weekly_rate DECIMAL(12,2),
    monthly_rate DECIMAL(12,2),
    mileage_policy VARCHAR(50),
    fuel_policy VARCHAR(50),
    photos JSONB DEFAULT '[]',
    location JSONB,
    rules TEXT,
    rating DECIMAL(3,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE rental_bookings (
    id BIGSERIAL PRIMARY KEY,
    vehicle_id BIGINT REFERENCES rental_vehicles(id),
    renter_id BIGINT REFERENCES users(id),
    chauffeur_id BIGINT,
    pickup_date TIMESTAMP,
    return_date TIMESTAMP,
    pickup_location JSONB,
    return_location JSONB,
    insurance_tier VARCHAR(30),
    extras JSONB DEFAULT '[]',
    total_cost DECIMAL(12,2),
    deposit DECIMAL(12,2),
    status VARCHAR(20) DEFAULT 'pending',
    pickup_inspection JSONB,
    return_inspection JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/rent-car/vehicles | Search vehicles | Yes |
| GET | /api/rent-car/vehicles/{id} | Vehicle detail | Yes |
| POST | /api/rent-car/bookings | Create booking | Yes |
| GET | /api/rent-car/bookings | My bookings | Yes |
| GET | /api/rent-car/bookings/{id} | Booking detail | Yes |
| POST | /api/rent-car/bookings/{id}/inspection | Submit inspection | Yes |
| POST | /api/rent-car/host/vehicles | List car for rent | Yes |
| GET | /api/rent-car/host/dashboard | Host dashboard | Yes |
| GET | /api/rent-car/chauffeurs | Search chauffeurs | Yes |
| POST | /api/rent-car/roadside | Roadside assistance | Yes |

### Controller
- File: `app/Http/Controllers/Api/RentCarController.php`
- Pattern: DB facade, try/catch, `{"success": true, "data": ...}` responses

### Background Jobs
- Return reminder notifications (4 hours before, at return time)
- Security deposit release after return inspection (24h delay)
- Host payout processing (weekly)
- Late return fee calculation

---

## 5. Integration Wiring

- **Wallet**: Rental payments, security deposit escrow, P2P host payouts, chauffeur gratuity.
- **My Cars**: P2P hosts link vehicles from garage, vehicle eligibility check.
- **Car Insurance**: Rental insurance verification, platform-provided P2P insurance.
- **Messaging**: Renter-host coordination, chauffeur communication.
- **Notifications**: Booking confirmation, pickup/return reminders, deposit release.
- **Travel**: Car rental as part of travel packages, safari vehicle bundling.
- **Events**: Wedding cars, group transport, event vehicle rental.
- **Tajirika**: Rental operators and chauffeurs as TAJIRI partners.
- **LATRA**: Licensed transport operator verification for rental companies.
- **Ambulance**: Emergency SOS during rental with vehicle details pre-filled.

---

## 6. Implementation Phases

### Phase 1: Foundation (Week 1)
- [ ] Create directory structure and rent_car_module.dart
- [ ] RentalVehicle, Booking, P2PHost, Chauffeur models
- [ ] RentCarService with AuthenticatedDio
- [ ] Backend: migrations + vehicles + bookings endpoints
- [ ] SQLite tables for vehicles and bookings

### Phase 2: Core UI (Week 2)
- [ ] Browse Vehicles with filters and categories
- [ ] Vehicle Detail with pricing and reviews
- [ ] Booking Flow with insurance and extras
- [ ] My Bookings with status cards
- [ ] Pickup/Return inspection flow

### Phase 3: Integration (Week 3)
- [ ] Wire to WalletService for payments and deposits
- [ ] Wire to MessageService for renter-host chat
- [ ] Wire to NotificationService for reminders
- [ ] Wire to LocationService for vehicle tracking

### Phase 4: Polish (Week 4)
- [ ] P2P host listing and dashboard
- [ ] Chauffeur selection and booking
- [ ] Corporate Dashboard for fleet
- [ ] Roadside Assistance feature
- [ ] Offline booking viewing
- [ ] Digital rental agreement signing

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| [Amadeus Car & Transfers API](https://developers.amadeus.com/) | Amadeus | Car rental search, booking, availability (69+ providers) | Freemium (200-10K free/month, then EUR 0.001-0.025/call) | Self-service API. 37+ car rental brands in 40K locations. Test environment included |
| [Booking.com Cars API](https://developers.booking.com/demand/docs/cars/overview) | Booking Holdings | Car rental inventory (45K locations, 200+ suppliers) | Partnership / affiliate | Requires affiliate partnership. Real-time availability + pricing |
| [Smartcar API](https://smartcar.com/docs/api/) | Smartcar | Remote fleet management (lock/unlock, location, fuel level) | Freemium (tiered) | Track rental fleet vehicles remotely. OAuth 2.0 vehicle authorization |
| [FleetON API](https://fleetonapp.com/products/api-integration/) | FleetON | Fleet management, booking engine, availability | B2B subscription | Purpose-built for car rental businesses. API integration for fleet ops |
| [Google Maps Platform](https://developers.google.com/maps) | Google | Vehicle location tracking, route display | Freemium (10K free/month) | Track rental vehicles on map. Already partially integrated |
| [Mapbox](https://docs.mapbox.com/) | Mapbox | Maps, directions, vehicle tracking | Freemium (100K free directions/month) | Mobile Navigation SDK available |
| [M-Pesa Open API](https://openapiportal.m-pesa.com) | Vodacom Tanzania | Rental payments, deposits | Transaction fees | Dart SDK: `mpesa_sdk` on pub.dev |
| [AzamPay API](https://developers.azampay.co.tz/) | AzamPay (Bakhresa Group) | Payment gateway for rental fees | Transaction fees | Flutter SDK: `azampaytanzania` on pub.dev |
| [ClickPesa API](https://docs.clickpesa.com/) | ClickPesa | Unified payment collection | Transaction fees | Aggregates M-Pesa, Tigo Pesa, Airtel Money, HaloPesa |
| [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging) | Google | Booking confirmations, return reminders | Free | Already integrated in TAJIRI app |
