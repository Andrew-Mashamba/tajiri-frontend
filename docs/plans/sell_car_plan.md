# Sell Car — Implementation Plan

## Overview

Sell Car enables Tanzanian vehicle owners to list, manage, and sell their cars through a structured marketplace. It features a guided listing wizard with photo quality validation, AI-powered price suggestions with market comparison, listing performance analytics, in-app buyer communication with offer management, TAJIRI-certified pre-sale inspections, escrow-protected transactions through TAJIRI Wallet, and complete document transfer guidance including TRA registration steps.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/sell_car/
├── sell_car_module.dart               — Entry point & route registration
├── models/
│   ├── listing_models.dart            — SellListing, ListingStatus, Condition
│   ├── valuation_models.dart          — PriceSuggestion, MarketComparison
│   ├── offer_models.dart              — Offer, OfferStatus, Negotiation
│   └── transaction_models.dart        — SaleTransaction, EscrowStatus
├── services/
│   └── sell_car_service.dart          — API service using AuthenticatedDio
├── pages/
│   ├── create_listing_page.dart       — Multi-step wizard
│   ├── price_suggestion_page.dart     — AI valuation with market data
│   ├── my_listings_page.dart          — Active/paused/sold listings
│   ├── listing_detail_page.dart       — Public view preview
│   ├── inquiries_page.dart            — Buyer messages by listing
│   ├── offer_management_page.dart     — Accept/counter/decline offers
│   ├── inspection_request_page.dart   — Book inspection, view reports
│   ├── transaction_page.dart          — Escrow, docs, transfer guide
│   ├── listing_analytics_page.dart    — Views, saves, inquiries charts
│   └── boost_listing_page.dart        — Premium placement options
└── widgets/
    ├── listing_card_widget.dart        — Listing with stats overlay
    ├── price_range_widget.dart         — Quick/fair/optimistic price bar
    ├── offer_card_widget.dart          — Offer with accept/counter/decline
    ├── photo_guide_widget.dart         — Guided angle indicators
    └── inspection_badge_widget.dart    — Verified condition seal
```

### Data Models
- **SellListing**: id, vehicleId, make, model, year, mileage, price, condition, features[], photos[], videoUrl, description, serviceHistory, inspectionReportId, status (draft/active/paused/sold), views, saves, inquiries, createdAt. `factory SellListing.fromJson()`.
- **PriceSuggestion**: quickSalePrice, fairPrice, optimisticPrice, marketComparisons[], trend, importComparison. `factory PriceSuggestion.fromJson()`.
- **Offer**: id, listingId, buyerId, buyerName, buyerVerified, amount, message, status (pending/accepted/countered/declined), counterAmount, createdAt. `factory Offer.fromJson()`.
- **SaleTransaction**: id, listingId, buyerId, sellerId, amount, escrowStatus, documentChecklist[], transferGuide, createdAt. `factory SaleTransaction.fromJson()`.

### Service Layer
- `createListing(Map data)` — POST `/api/sell-car/listings`
- `updateListing(int id, Map data)` — PUT `/api/sell-car/listings/{id}`
- `getMyListings()` — GET `/api/sell-car/listings`
- `getListing(int id)` — GET `/api/sell-car/listings/{id}`
- `getPriceSuggestion(Map vehicleData)` — POST `/api/sell-car/valuation`
- `getOffers(int listingId)` — GET `/api/sell-car/listings/{id}/offers`
- `respondToOffer(int offerId, Map response)` — PUT `/api/sell-car/offers/{id}`
- `requestInspection(int listingId)` — POST `/api/sell-car/inspections`
- `getListingAnalytics(int id)` — GET `/api/sell-car/listings/{id}/analytics`
- `boostListing(int id, Map boostData)` — POST `/api/sell-car/listings/{id}/boost`
- `initTransaction(int listingId, int buyerId)` — POST `/api/sell-car/transactions`

### Pages & Screens
- **Create Listing**: Multi-step: details (auto-fill from My Cars), photos (guided angles), condition assessment, pricing (with AI suggestion), preview, publish.
- **Price Suggestion**: Three-tier price bar (quick/fair/optimistic), similar listings carousel, price trend chart.
- **My Listings**: Tab bar (Active/Paused/Sold), performance stats per listing.
- **Offer Management**: Offer cards with buyer info, amount, accept/counter/decline buttons, negotiation history.
- **Transaction**: Escrow status, document upload checklist, TRA transfer step-by-step guide.

### Widgets
- `ListingCardWidget` — Photo, make/model, price, views/saves/inquiries badges
- `PriceRangeWidget` — Horizontal bar with three zones and marker
- `OfferCardWidget` — Buyer avatar, amount, verification status, action buttons
- `PhotoGuideWidget` — Camera viewfinder with angle overlay (front/rear/side/interior)
- `InspectionBadgeWidget` — Green seal with "TAJIRI Verified" text

---

## 2. UI Design

- Listing wizard: Step indicator at top, one section per step
- Photo upload: Grid of 8 slots with guided angle labels
- Offer cards: White with accent border for new offers
- Analytics: Line chart for views, bar chart for inquiries by day

### Key Screen Mockup — My Listings
```
┌─────────────────────────────┐
│  SafeArea                   │
│  [Active] [Paused] [Sold]   │
│  ┌───────────────────────┐  │
│  │[Photo] Toyota Prado   │  │
│  │ TZS 45,000,000        │  │
│  │ 👁 342  ♡ 28  💬 12  │  │
│  │ Listed 5 days ago      │  │
│  │ [Edit] [Boost] [Pause]│  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │[Photo] Honda Fit      │  │
│  │ TZS 12,500,000        │  │
│  │ 👁 89   ♡ 5   💬 3   │  │
│  │ Listed 12 days ago     │  │
│  │ [Edit] [Boost] [Pause]│  │
│  └───────────────────────┘  │
│  [+ Create New Listing]     │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### Local-First with SQLite
```dart
// Table: sell_listings
// Columns: id INTEGER PRIMARY KEY, status TEXT, make TEXT, model TEXT, price REAL, json_data TEXT, synced_at TEXT
// Indexes: status
// Table: listing_offers
// Columns: id INTEGER PRIMARY KEY, listing_id INTEGER, status TEXT, json_data TEXT, synced_at TEXT
// Indexes: listing_id, status
```

### Stale-While-Revalidate
- My listings: cache TTL 15 minutes
- Offers: cache TTL 5 minutes (time-sensitive)
- Analytics: cache TTL 1 hour
- Valuation data: cache TTL 24 hours

### Offline Support
- Read: My listings, offer history, analytics
- Write: Listing drafts saved locally, listing edits queued
- Sync: Offer responses are priority sync

### Media Caching
- Listing photos: cached locally after upload
- Buyer avatars: MediaCacheService (7-day TTL)
- BlurHash for listing card thumbnails

---

## 4. Backend Implementation

### Database Tables
```sql
CREATE TABLE sell_listings (
    id BIGSERIAL PRIMARY KEY,
    seller_id BIGINT REFERENCES users(id),
    vehicle_id BIGINT REFERENCES vehicles(id),
    make VARCHAR(100),
    model VARCHAR(100),
    year INTEGER,
    mileage INTEGER,
    price DECIMAL(15,2),
    condition_rating VARCHAR(20),
    features JSONB DEFAULT '[]',
    photos JSONB DEFAULT '[]',
    video_url TEXT,
    description TEXT,
    inspection_id BIGINT,
    status VARCHAR(20) DEFAULT 'draft',
    views INTEGER DEFAULT 0,
    saves INTEGER DEFAULT 0,
    is_boosted BOOLEAN DEFAULT FALSE,
    boost_expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE sell_offers (
    id BIGSERIAL PRIMARY KEY,
    listing_id BIGINT REFERENCES sell_listings(id),
    buyer_id BIGINT REFERENCES users(id),
    amount DECIMAL(15,2),
    counter_amount DECIMAL(15,2),
    message TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE sale_transactions (
    id BIGSERIAL PRIMARY KEY,
    listing_id BIGINT REFERENCES sell_listings(id),
    buyer_id BIGINT REFERENCES users(id),
    seller_id BIGINT REFERENCES users(id),
    amount DECIMAL(15,2),
    escrow_status VARCHAR(20) DEFAULT 'pending',
    documents JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | /api/sell-car/listings | Create listing | Yes |
| PUT | /api/sell-car/listings/{id} | Update listing | Yes |
| GET | /api/sell-car/listings | My listings | Yes |
| GET | /api/sell-car/listings/{id} | Listing detail | Yes |
| POST | /api/sell-car/valuation | Get price suggestion | Yes |
| GET | /api/sell-car/listings/{id}/offers | List offers | Yes |
| PUT | /api/sell-car/offers/{id} | Respond to offer | Yes |
| POST | /api/sell-car/inspections | Request inspection | Yes |
| GET | /api/sell-car/listings/{id}/analytics | Performance stats | Yes |
| POST | /api/sell-car/listings/{id}/boost | Boost listing | Yes |
| POST | /api/sell-car/transactions | Initiate transaction | Yes |

### Controller
- File: `app/Http/Controllers/Api/SellCarController.php`
- Pattern: DB facade, try/catch, `{"success": true, "data": ...}` responses

### Background Jobs
- View count aggregation (hourly)
- Listing expiry check (daily)
- Price revision suggestion for stale listings (after 7 days with no inquiries)
- Boost expiry and demotion (hourly)

---

## 5. Integration Wiring

- **Wallet**: Escrow payments, listing boost charges, sale proceeds deposit.
- **My Cars**: Auto-populate listing from garage. Remove vehicle after sale.
- **Buy Car**: Listings appear in Buy Car marketplace.
- **Car Insurance**: Insurance transfer guidance, pro-rata refund calculation.
- **Service Garage**: Pre-sale inspection booking, minor repair for value maximization.
- **Messaging**: Buyer-seller communication, offer negotiation.
- **Notifications**: New inquiries, offers, listing milestones, escrow events.
- **Tajirika**: Professional brokers assist with listing and buyer vetting.
- **Owners Club**: Announce sale to brand community first.

---

## 6. Implementation Phases

### Phase 1: Foundation (Week 1)
- [ ] Create directory structure and sell_car_module.dart
- [ ] Listing, PriceSuggestion, Offer, Transaction models
- [ ] SellCarService with AuthenticatedDio
- [ ] Backend: migrations + listings CRUD + valuation endpoint
- [ ] SQLite tables for listings and offers

### Phase 2: Core UI (Week 2)
- [ ] Create Listing wizard (5 steps)
- [ ] Price Suggestion with market comparison
- [ ] My Listings with tabs and stats
- [ ] Offer Management with actions
- [ ] Listing Detail preview

### Phase 3: Integration (Week 3)
- [ ] Wire to WalletService for escrow
- [ ] Wire to My Cars for auto-populate and removal
- [ ] Wire to MessageService for buyer chat
- [ ] Wire to NotificationService for offer alerts
- [ ] Cross-publish to Buy Car marketplace

### Phase 4: Polish (Week 4)
- [ ] Listing Analytics with charts
- [ ] Boost Listing feature
- [ ] Photo quality validation
- [ ] Transaction page with doc checklist
- [ ] Offline listing drafts
- [ ] Multi-platform sharing (WhatsApp, Facebook)

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| [Vehicle Databases Market Value API](https://vehicledatabases.com/api/vehicle-market-value) | Vehicle Databases | Market value estimation (retail, private, trade-in) | Paid (subscription) | Valuation by VIN or make/model/year. State/city-level pricing |
| [Auto.dev Vehicle Listings API](https://www.auto.dev/listings) | Auto.dev | Vehicle listing creation + syndication | Freemium (1,000 free/month) | List vehicles for sale. 1,000 free API calls/month |
| [CarAPI](https://carapi.app/) | CarAPI | Vehicle specs database (90K+ vehicles) | Freemium | REST + JSON. Specs from 1900-present. Free tier available |
| [Auto-Data.net API](https://api.auto-data.net/) | Auto-Data.net | Vehicle technical specifications (54K+ entries) | Paid (tiered) | 14 languages. Detailed specs for pricing context |
| [NHTSA vPIC API](https://vpic.nhtsa.dot.gov/api/) | US Dept. of Transportation | VIN decode for listing accuracy | Free | Verify vehicle details before listing. REST/JSON |
| [M-Pesa Open API](https://openapiportal.m-pesa.com) | Vodacom Tanzania | Vehicle sale payments, deposits | Transaction fees | Dart SDK: `mpesa_sdk` on pub.dev |
| [AzamPay API](https://developers.azampay.co.tz/) | AzamPay (Bakhresa Group) | Payment gateway for vehicle transactions | Transaction fees | Flutter SDK: `azampaytanzania` on pub.dev |
| [ClickPesa API](https://docs.clickpesa.com/) | ClickPesa | Unified payment collection | Transaction fees | Aggregates M-Pesa, Tigo Pesa, Airtel Money, HaloPesa |
| [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging) | Google | Buyer inquiry notifications, offer alerts | Free | Already integrated in TAJIRI app |
