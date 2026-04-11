# Buy Car — Implementation Plan

## Overview

Buy Car is a comprehensive car marketplace for Tanzania covering local dealer listings, private seller listings, and Japan/Dubai import vehicles. Features include advanced search with 15+ filters, detailed vehicle listings with multi-photo galleries, a full import cost calculator (CIF + TRA duties), dealer directory with ratings, pre-purchase inspection booking, financing with bank loan comparison, escrow payments through TAJIRI Wallet, import shipment tracking, and market intelligence with price trends.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/buy_car/
├── buy_car_module.dart                — Entry point & route registration
├── models/
│   ├── listing_models.dart            — CarListing, ListingSource, Condition
│   ├── dealer_models.dart             — Dealer, DealerType, ImportAgent
│   ├── import_calc_models.dart        — ImportCalculation, DutyBreakdown
│   └── financing_models.dart          — LoanOption, BankOffer, PreQual
├── services/
│   └── buy_car_service.dart           — API service using AuthenticatedDio
├── pages/
│   ├── browse_page.dart               — Search + filter + vehicle grid
│   ├── vehicle_detail_page.dart       — Full listing with photos/specs
│   ├── import_calculator_page.dart    — Duty/cost calculator
│   ├── compare_vehicles_page.dart     — Side-by-side comparison
│   ├── dealer_directory_page.dart     — Map + list of dealers
│   ├── dealer_profile_page.dart       — Dealer info, inventory, reviews
│   ├── financing_page.dart            — Loan calculator, bank comparison
│   ├── saved_vehicles_page.dart       — Favorites with alerts
│   ├── negotiations_page.dart         — Active offer threads
│   ├── purchase_tracker_page.dart     — Import tracking, escrow status
│   └── market_insights_page.dart      — Price trends, recommendations
└── widgets/
    ├── vehicle_grid_card_widget.dart   — Compact listing card
    ├── import_cost_widget.dart         — Duty breakdown display
    ├── dealer_badge_widget.dart        — Verified dealer indicator
    └── price_trend_widget.dart         — Price history mini chart
```

### Data Models
- **CarListing**: id, sellerId, sellerType, make, model, year, mileage, price, engineSize, fuelType, transmission, bodyType, color, driveType, condition, auctionGrade, photos[], description, location, source (local/japan/dubai), isFeatured, createdAt. `factory CarListing.fromJson()` with `_parseInt`/`_parseDouble`.
- **Dealer**: id, name, type (dealer/private/agent), location, rating, reviewCount, responseTime, inventory[], verified, photos[]. `factory Dealer.fromJson()`.
- **ImportCalculation**: cifPrice, insuranceCost, freightCost, importDuty, exciseDuty, vat, latraFee, portHandling, clearingFee, totalLandedCost, currency, exchangeRate. `factory ImportCalculation.fromJson()`.
- **LoanOption**: bankName, interestRate, term, downPayment, monthlyPayment, totalCost. `factory LoanOption.fromJson()`.

### Service Layer
- `searchListings(Map filters)` — GET `/api/buy-car/listings`
- `getListing(int id)` — GET `/api/buy-car/listings/{id}`
- `calculateImportCost(Map vehicleData)` — POST `/api/buy-car/import-calculator`
- `getDealers({String? location, String? type})` — GET `/api/buy-car/dealers`
- `getDealer(int id)` — GET `/api/buy-car/dealers/{id}`
- `makeOffer(int listingId, Map offer)` — POST `/api/buy-car/listings/{id}/offers`
- `getFinancingOptions(Map params)` — POST `/api/buy-car/financing`
- `saveListing(int listingId)` — POST `/api/buy-car/saved/{id}`
- `getSavedListings()` — GET `/api/buy-car/saved`
- `getMarketInsights({String? make, String? model})` — GET `/api/buy-car/insights`
- `getPurchaseTracker()` — GET `/api/buy-car/purchases`

### Pages & Screens
- **Browse**: Search bar + filter chips (make, price, year, source), grid/list toggle, sort options.
- **Vehicle Detail**: Photo carousel with zoom, specs table, seller info, action buttons (contact, offer, save, share).
- **Import Calculator**: Interactive form with CIF input, duty breakdown table, total in TZS/USD, save/compare.
- **Compare Vehicles**: 2-3 column spec comparison with highlight differences.
- **Financing**: Loan slider (term, down payment), bank comparison cards, pre-qualification CTA.

### Widgets
- `VehicleGridCardWidget` — Photo, make/model/year, price, mileage, location badge
- `ImportCostWidget` — Stacked bar showing cost components
- `DealerBadgeWidget` — Verified checkmark with response time
- `PriceTrendWidget` — Sparkline showing 6-month price trend

---

## 2. UI Design

- Vehicle grid: 2-column layout, 12dp card radius, photo aspect ratio 16:9
- Price display: Bold, large font, TZS with comma formatting
- Filter chips: Horizontal scrollable, outlined style, dark when active
- Import calculator: Step-by-step accordion sections

### Key Screen Mockup — Browse
```
┌─────────────────────────────┐
│  SafeArea                   │
│  [Search: Toyota Prado...] │
│  [All] [Local] [Japan] [UAE]│
│  Sort: Price ▼  Filters ⊕  │
│  ┌──────┐ ┌──────┐         │
│  │[Photo]│ │[Photo]│         │
│  │Prado  │ │Hilux │         │
│  │2018   │ │2020  │         │
│  │45M TZS│ │38M   │         │
│  │32K km │ │18K km│         │
│  └──────┘ └──────┘         │
│  ┌──────┐ ┌──────┐         │
│  │[Photo]│ │[Photo]│         │
│  │...    │ │...   │         │
│  └──────┘ └──────┘         │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### Local-First with SQLite
```dart
// Table: car_listings
// Columns: id INTEGER PRIMARY KEY, make TEXT, model TEXT, year INTEGER, price INTEGER, source TEXT, json_data TEXT, synced_at TEXT
// Indexes: make, model, year, price, source
// Table: saved_listings
// Columns: id INTEGER PRIMARY KEY, listing_id INTEGER, json_data TEXT, synced_at TEXT
```

### Stale-While-Revalidate
- Listings: cache TTL 15 minutes (prices change)
- Dealer directory: cache TTL 24 hours
- Import calculator rates: cache TTL 24 hours
- Saved listings: cache TTL 5 minutes
- Market insights: cache TTL 1 hour

### Offline Support
- Read: Saved listings, dealer directory, import calculation history
- Write: Save/unsave listings queued offline
- Sync: Listing prices refreshed on reconnect

### Media Caching
- Vehicle photos: MediaCacheService (7-day TTL, high volume)
- Dealer logos: cached 30 days
- BlurHash for vehicle grid thumbnails

---

## 4. Backend Implementation

### Database Tables
```sql
CREATE TABLE car_listings (
    id BIGSERIAL PRIMARY KEY,
    seller_id BIGINT REFERENCES users(id),
    seller_type VARCHAR(20),
    make VARCHAR(100),
    model VARCHAR(100),
    year INTEGER,
    mileage INTEGER,
    price DECIMAL(15,2),
    engine_size INTEGER,
    fuel_type VARCHAR(20),
    transmission VARCHAR(20),
    body_type VARCHAR(30),
    condition VARCHAR(20),
    source VARCHAR(20),
    auction_grade VARCHAR(10),
    photos JSONB DEFAULT '[]',
    description TEXT,
    location JSONB,
    is_featured BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) DEFAULT 'active',
    views INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE car_offers (
    id BIGSERIAL PRIMARY KEY,
    listing_id BIGINT REFERENCES car_listings(id),
    buyer_id BIGINT REFERENCES users(id),
    amount DECIMAL(15,2),
    message TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE import_calculations (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    vehicle_details JSONB,
    calculation JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/buy-car/listings | Search listings | Yes |
| GET | /api/buy-car/listings/{id} | Listing detail | Yes |
| POST | /api/buy-car/listings/{id}/offers | Make offer | Yes |
| POST | /api/buy-car/import-calculator | Calculate import cost | Yes |
| GET | /api/buy-car/dealers | Dealer directory | Yes |
| GET | /api/buy-car/dealers/{id} | Dealer profile | Yes |
| POST | /api/buy-car/financing | Get financing options | Yes |
| GET | /api/buy-car/saved | Saved listings | Yes |
| POST | /api/buy-car/saved/{id} | Save listing | Yes |
| GET | /api/buy-car/insights | Market insights | Yes |
| GET | /api/buy-car/purchases | Purchase tracker | Yes |

### Controller
- File: `app/Http/Controllers/Api/BuyCarController.php`
- Pattern: DB facade, try/catch, `{"success": true, "data": ...}` responses

### Background Jobs
- Price drop notification check (hourly for saved listings)
- Exchange rate update for import calculator (daily)
- Listing expiry and auto-relist (daily)
- View count aggregation (hourly)

---

## 5. Integration Wiring

- **Wallet**: Escrow payments for vehicle purchase. Import payment tracking.
- **My Cars**: Purchased vehicle auto-registered in garage.
- **Car Insurance**: Quote generation during purchase flow.
- **Loans**: Vehicle financing, pre-qualification, monthly payment estimator.
- **Service Garage**: Pre-purchase inspection booking.
- **Sell Car**: Listings from Sell Car appear in marketplace.
- **Messaging**: Buyer-seller communication, dealer inquiries.
- **Notifications**: Price drops, new listing matches, shipping updates.
- **Tajirika**: Verified vehicle brokers (madalali) for sourcing.
- **Rent Car**: "Try before you buy" rental option.

---

## 6. Implementation Phases

### Phase 1: Foundation (Week 1)
- [ ] Create directory structure and buy_car_module.dart
- [ ] Listing, Dealer, ImportCalculation, LoanOption models
- [ ] BuyCarService with AuthenticatedDio
- [ ] Backend: migrations + listings CRUD + import calculator
- [ ] SQLite tables for listings and saved

### Phase 2: Core UI (Week 2)
- [ ] Browse page with search and filters
- [ ] Vehicle Detail with photo carousel
- [ ] Import Calculator with duty breakdown
- [ ] Dealer Directory with map view
- [ ] Saved Vehicles with price alerts

### Phase 3: Integration (Week 3)
- [ ] Wire to WalletService for escrow payments
- [ ] Wire to My Cars for auto-registration
- [ ] Wire to MessageService for buyer-seller chat
- [ ] Wire to NotificationService for alerts

### Phase 4: Polish (Week 4)
- [ ] Offline saved listings viewing
- [ ] BlurHash for vehicle grid
- [ ] Compare Vehicles feature
- [ ] Market Insights charts
- [ ] Financing calculator
- [ ] Purchase tracker with import status

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| [BE FORWARD](https://www.beforward.jp/) | BE FORWARD Co., Ltd. | Used car listings from Japan (largest exporter to Africa) | No public API | Dominant in TZ market. Would need web scraping or partnership agreement |
| [SBT Japan](https://www.sbtjapan.com/) | SBT Co., Ltd. | Used car listings from Japan, car tracking | No public API | 13,000+ vehicles/month to 200+ countries. Contact for B2B integration |
| [TRA Import Duty Calculator](https://www.tra.go.tz/index.php/90-calculators-tools) | Tanzania Revenue Authority | Vehicle import duty estimation | Free (government tool) | Calculates CIF-based duties (25-50% depending on engine/age). Web tool, no REST API |
| [MarketCheck Cars API](https://www.marketcheck.com/apis/cars/) | MarketCheck | Vehicle listings aggregation, pricing analytics | Paid (tiered) | Active + historical listings data. Pricing analytics and market trends |
| [NHTSA vPIC API](https://vpic.nhtsa.dot.gov/api/) | US Dept. of Transportation | VIN decoding for imported vehicles | Free | Decode VIN before purchase to verify vehicle specs. REST/JSON |
| [Vindecoder.eu API](https://vindecoder.eu/api/) | Vindecoder.eu | European + global VIN decoding | Paid (per-query) | Covers cars, trucks, buses, motorcycles, tractors worldwide |
| [Vehicle Databases Market Value API](https://vehicledatabases.com/api/vehicle-market-value) | Vehicle Databases | Car valuation by VIN or make/model/year | Paid (subscription) | Retail, private party, and trade-in values |
| [M-Pesa Open API](https://openapiportal.m-pesa.com) | Vodacom Tanzania | Vehicle purchase payments, deposits | Transaction fees | Dart SDK: `mpesa_sdk` on pub.dev |
| [AzamPay API](https://developers.azampay.co.tz/) | AzamPay (Bakhresa Group) | Payment gateway for car purchases | Transaction fees | Flutter SDK: `azampaytanzania` on pub.dev |
| [ClickPesa API](https://docs.clickpesa.com/) | ClickPesa | Unified payment collection | Transaction fees | Aggregates M-Pesa, Tigo Pesa, Airtel Money, HaloPesa |
| [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging) | Google | Price drop alerts, listing notifications | Free | Already integrated in TAJIRI app |
