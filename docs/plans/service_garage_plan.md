# Service Garage — Implementation Plan

## Overview

Service Garage is a garage finder and service booking platform that connects Tanzanian vehicle owners with workshops ranging from informal mitambo to authorized dealer service centers. It features a comprehensive garage directory with verified profiles, mechanic ratings, standardized service menus with cost estimates, appointment booking, real-time service progress tracking with photo updates, complete service history, pickup/delivery service, and DIY diagnostic tools.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/service_garage/
├── service_garage_module.dart         — Entry point & route registration
├── models/
│   ├── garage_models.dart             — Garage, GarageService, Capability
│   ├── mechanic_models.dart           — Mechanic, Qualification, Portfolio
│   ├── booking_models.dart            — ServiceBooking, BookingStatus, Quote
│   └── service_history_models.dart    — ServiceRecord, JobCard
├── services/
│   └── service_garage_service.dart    — API service using AuthenticatedDio
├── pages/
│   ├── garage_finder_page.dart        — Map + list with search/filters
│   ├── garage_profile_page.dart       — Details, services, reviews
│   ├── mechanic_profile_page.dart     — Qualifications, ratings
│   ├── book_service_page.dart         — Service selection, scheduling
│   ├── get_quotes_page.dart           — Multi-garage quote comparison
│   ├── service_tracker_page.dart      — Real-time progress + photos
│   ├── service_history_page.dart      — Timeline of all services
│   ├── cost_estimator_page.dart       — Fair price lookup
│   ├── diagnostic_tool_page.dart      — Symptom-based problem finder
│   ├── pickup_delivery_page.dart      — Vehicle collection/return
│   └── reviews_page.dart              — Write and manage reviews
└── widgets/
    ├── garage_card_widget.dart         — Garage thumbnail with rating
    ├── service_progress_widget.dart    — Step tracker with photos
    ├── quote_comparison_widget.dart    — Multi-garage price table
    ├── fair_price_widget.dart          — Price range indicator bar
    └── mechanic_badge_widget.dart      — Qualification/specialty badges
```

### Data Models
- **Garage**: id, name, type (informal/semi-formal/authorized), location, photos[], services[], capabilities[], brands[], rating, reviewCount, verified, operatingHours, phone. `factory Garage.fromJson()` with `_parseDouble`.
- **Mechanic**: id, garageId, name, photo, qualifications[], specializations[], rating, yearsExperience, vehiclesServiced, languages[], portfolio[]. `factory Mechanic.fromJson()`.
- **ServiceBooking**: id, garageId, vehicleId, services[], mechanicId, scheduledDate, estimatedDuration, estimatedCost, status (booked/in_progress/additional_work/ready/completed), notes[]. `factory ServiceBooking.fromJson()`.
- **Quote**: id, garageId, garageName, services[], laborCost, partsCost, totalCost, isGenuineParts. `factory Quote.fromJson()`.

### Service Layer
- `searchGarages(Map filters)` — GET `/api/service-garage/garages`
- `getGarage(int id)` — GET `/api/service-garage/garages/{id}`
- `getMechanic(int id)` — GET `/api/service-garage/mechanics/{id}`
- `bookService(Map bookingData)` — POST `/api/service-garage/bookings`
- `getBookingStatus(int id)` — GET `/api/service-garage/bookings/{id}`
- `requestQuotes(Map serviceRequest)` — POST `/api/service-garage/quotes`
- `getServiceHistory(int vehicleId)` — GET `/api/service-garage/history/{vehicleId}`
- `getCostEstimate(Map params)` — GET `/api/service-garage/estimates`
- `submitReview(int garageId, Map review)` — POST `/api/service-garage/reviews`
- `requestPickup(Map pickupData)` — POST `/api/service-garage/pickup`

### Pages & Screens
- **Garage Finder**: Map with garage markers + list below. Filters: service type, brand specialty, price range, distance, verified only.
- **Garage Profile**: Photo gallery, services menu, mechanic list, reviews, book button.
- **Book Service**: Vehicle picker (from My Cars), service category selector, date/time slots, cost estimate display.
- **Service Tracker**: Step progress (received, diagnosed, working, quality check, ready), photo updates per step, additional work approval dialog.
- **Cost Estimator**: Select vehicle + service type, see fair price range with market position indicator.

### Widgets
- `GarageCardWidget` — Photo, name, rating stars, distance, verified badge, specialties
- `ServiceProgressWidget` — Horizontal stepper with photo thumbnails per step
- `QuoteComparisonWidget` — Table with garage rows, labor/parts/total columns
- `FairPriceWidget` — Horizontal bar with low/fair/high zones, current price marker

---

## 2. UI Design

- Map view: Takes top 50% on Garage Finder, list view below
- Garage cards: 12dp radius, photo left, info right
- Service tracker: Dark step indicators, photo carousel per step
- Reviews: Star rating with category bars (quality, price, timeliness, communication)

### Key Screen Mockup — Garage Finder
```
┌─────────────────────────────┐
│  SafeArea                   │
│  [Search garage or service] │
│  [Map with garage pins]     │
│  [   ...map area...    ]   │
│  ┌───────────────────────┐  │
│  │[Photo] Toyota Special │  │
│  │ ★ 4.6 (234)  2.1km  │  │
│  │ ✓ Verified  Engine,AC│  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │[Photo] Mikocheni Auto │  │
│  │ ★ 4.2 (89)   3.4km  │  │
│  │ Body, Electrical      │  │
│  └───────────────────────┘  │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### Local-First with SQLite
```dart
// Table: garages
// Columns: id INTEGER PRIMARY KEY, name TEXT, lat REAL, lng REAL, rating REAL, verified INTEGER, json_data TEXT, synced_at TEXT
// Indexes: name, rating, verified
// Table: service_bookings
// Columns: id INTEGER PRIMARY KEY, garage_id INTEGER, vehicle_id INTEGER, status TEXT, json_data TEXT, synced_at TEXT
// Indexes: status, vehicle_id
```

### Stale-While-Revalidate
- Garage directory: cache TTL 24 hours
- Service bookings: cache TTL 15 minutes
- Service history: cache TTL 1 hour
- Cost estimates: cache TTL 7 days

### Offline Support
- Read: Garage directory, service history, booking details
- Write: Review drafts saved locally, booking requests queued
- Sync: Booking status refreshed on reconnect

### Media Caching
- Garage photos: MediaCacheService (30-day TTL)
- Service progress photos: cached after download
- BlurHash for garage card thumbnails

---

## 4. Backend Implementation

### Database Tables
```sql
CREATE TABLE garages (
    id BIGSERIAL PRIMARY KEY,
    owner_user_id BIGINT REFERENCES users(id),
    name VARCHAR(255),
    type VARCHAR(30),
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    address TEXT,
    phone VARCHAR(20),
    operating_hours JSONB,
    capabilities TEXT[],
    brand_specialties TEXT[],
    verified BOOLEAN DEFAULT FALSE,
    rating DECIMAL(3,2) DEFAULT 0,
    review_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE service_bookings (
    id BIGSERIAL PRIMARY KEY,
    garage_id BIGINT REFERENCES garages(id),
    user_id BIGINT REFERENCES users(id),
    vehicle_id BIGINT REFERENCES vehicles(id),
    mechanic_id BIGINT,
    services JSONB,
    scheduled_date TIMESTAMP,
    estimated_cost DECIMAL(12,2),
    actual_cost DECIMAL(12,2),
    status VARCHAR(30) DEFAULT 'booked',
    progress_photos JSONB DEFAULT '[]',
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE garage_reviews (
    id BIGSERIAL PRIMARY KEY,
    garage_id BIGINT REFERENCES garages(id),
    user_id BIGINT REFERENCES users(id),
    quality_rating INTEGER,
    price_rating INTEGER,
    timeliness_rating INTEGER,
    communication_rating INTEGER,
    comment TEXT,
    photos JSONB DEFAULT '[]',
    created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/service-garage/garages | Search garages | Yes |
| GET | /api/service-garage/garages/{id} | Garage profile | Yes |
| GET | /api/service-garage/mechanics/{id} | Mechanic profile | Yes |
| POST | /api/service-garage/bookings | Book service | Yes |
| GET | /api/service-garage/bookings/{id} | Booking status | Yes |
| POST | /api/service-garage/quotes | Request quotes | Yes |
| GET | /api/service-garage/history/{vehicleId} | Service history | Yes |
| GET | /api/service-garage/estimates | Cost estimates | Yes |
| POST | /api/service-garage/reviews | Submit review | Yes |
| POST | /api/service-garage/pickup | Request pickup | Yes |

### Controller
- File: `app/Http/Controllers/Api/ServiceGarageController.php`
- Pattern: DB facade, try/catch, `{"success": true, "data": ...}` responses

### Background Jobs
- Booking reminder notifications (24h, 2h before appointment)
- Rating recalculation after new review
- Service progress photo notification push
- Overdue service alert generation

---

## 5. Integration Wiring

- **Wallet**: Service payment with escrow for large repairs. Mechanic tips.
- **My Cars**: Vehicle data pre-filled for booking. Bi-directional service history sync.
- **Car Insurance**: Insurance-covered repairs routed to approved garages.
- **Spare Parts**: Parts sourcing linked to service needs with compatibility check.
- **Buy Car**: Pre-purchase inspection booking.
- **Sell Car**: Pre-sale inspection and minor repair booking.
- **Messaging**: Direct communication with garage and mechanic.
- **Notifications**: Booking confirmation, progress updates, vehicle ready.
- **Tajirika**: Mechanics as TAJIRI partners with verification.
- **Fuel Delivery**: Fuel top-up during service.

---

## 6. Implementation Phases

### Phase 1: Foundation (Week 1)
- [ ] Create directory structure and service_garage_module.dart
- [ ] Garage, Mechanic, Booking, Quote models
- [ ] ServiceGarageService with AuthenticatedDio
- [ ] Backend: migrations + garages CRUD + bookings endpoints
- [ ] SQLite tables for garages and bookings

### Phase 2: Core UI (Week 2)
- [ ] Garage Finder with map + list
- [ ] Garage Profile with services and reviews
- [ ] Book Service flow with vehicle picker
- [ ] Service Tracker with progress photos
- [ ] Service History timeline

### Phase 3: Integration (Week 3)
- [ ] Wire to WalletService for service payments
- [ ] Wire to My Cars for vehicle data and history sync
- [ ] Wire to MessageService for garage chat
- [ ] Wire to NotificationService for booking alerts
- [ ] Firestore listeners for service progress updates

### Phase 4: Polish (Week 4)
- [ ] Offline garage directory viewing
- [ ] Cost Estimator with fair price ranges
- [ ] Diagnostic Tool (symptom-based finder)
- [ ] Pickup/Delivery tracking
- [ ] BlurHash for garage photos
- [ ] Empty states and error handling

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| [CarMD API](https://www.carmd.com/api/) | CarMD | OBD-II diagnostics, repair estimates, maintenance alerts | Paid (tiered) | Check engine light diagnosis, repair cost estimates with parts + labor breakdown |
| [TecDoc Catalog API](https://www.tecalliance.net/tecdoc-catalogue/) | TecAlliance | OEM + aftermarket parts catalog, compatibility data | Paid (enterprise, $3K-50K+) | Industry-standard parts database. 14 languages. 1,000+ subscribers |
| [Car Databases Auto Parts API](https://cardatabases.com/api/auto-parts) | Car Databases | OEM part numbers, cross-reference, fitment | Paid (subscription) | ACES/PIES standards. OEM-to-aftermarket cross-reference |
| [Vehicle Databases Services API](https://vehicledatabases.com/vehicle-services-api) | Vehicle Databases | Service schedules, recall data, repair info | Paid (subscription) | Maintenance schedules by VIN. Recall notifications |
| [Levam OEM Parts API](https://levam.net/) | Levam Automotive | OEM parts catalog with visual diagrams | Paid | VIN-based parts lookup. Embeddable widget + API. Visual parts diagrams |
| [NHTSA vPIC API](https://vpic.nhtsa.dot.gov/api/) | US Dept. of Transportation | VIN decoding for service records | Free | Verify vehicle specs for accurate service recommendations |
| [Google Maps Platform](https://developers.google.com/maps) | Google | Garage location finder, directions | Freemium (10K free/month) | Places API for finding nearby garages |
| [M-Pesa Open API](https://openapiportal.m-pesa.com) | Vodacom Tanzania | Service payments | Transaction fees | Dart SDK: `mpesa_sdk` on pub.dev |
| [AzamPay API](https://developers.azampay.co.tz/) | AzamPay (Bakhresa Group) | Payment gateway for repair services | Transaction fees | Flutter SDK: `azampaytanzania` on pub.dev |
| [ClickPesa API](https://docs.clickpesa.com/) | ClickPesa | Unified payment collection | Transaction fees | Aggregates M-Pesa, Tigo Pesa, Airtel Money, HaloPesa |
| [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging) | Google | Service completion notifications, reminders | Free | Already integrated in TAJIRI app |
