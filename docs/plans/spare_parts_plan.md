# Spare Parts — Implementation Plan

## Overview

Spare Parts is a marketplace for automotive parts in Tanzania, addressing the fragmented, counterfeit-ridden informal market centered around Kariakoo and similar markets. It enables searching parts by vehicle make/model/year or VIN, comparing prices across multiple dealers, verifying part authenticity, ordering with delivery or pickup, and accessing installation guides. The module tackles counterfeit parts through community flagging and dealer verification, and integrates with My Cars for compatibility checking and Service Garage for professional installation.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/spare_parts/
├── spare_parts_module.dart            — Entry point & route registration
├── models/
│   ├── part_models.dart               — SparePart, PartCondition, Compatibility
│   ├── seller_models.dart             — PartsSeller, SellerType, Shop
│   ├── order_models.dart              — PartsOrder, OrderItem, OrderStatus
│   └── request_models.dart            — PartRequest, QuoteResponse
├── services/
│   └── spare_parts_service.dart       — API service using AuthenticatedDio
├── pages/
│   ├── parts_search_page.dart         — Vehicle selector + keyword + photo
│   ├── parts_catalog_page.dart        — Exploded diagrams with clickable parts
│   ├── part_detail_page.dart          — Specs, sellers, prices, reviews
│   ├── seller_profile_page.dart       — Shop info, inventory, ratings
│   ├── request_part_page.dart         — Post need, receive quotes
│   ├── my_orders_page.dart            — Order tracking and history
│   ├── marketplace_page.dart          — Browse all seller listings
│   ├── cart_checkout_page.dart        — Multi-seller cart with payment
│   └── shop_directory_page.dart       — Map + list of parts shops
└── widgets/
    ├── part_card_widget.dart           — Part photo, price, condition badge
    ├── compatibility_widget.dart       — Green check/red X for vehicle fit
    ├── seller_rating_widget.dart       — Stars, response time, sales count
    ├── condition_badge_widget.dart     — New/Used-A/Used-B/Used-C labels
    └── counterfeit_alert_widget.dart   — Warning banner for flagged items
```

### Data Models
- **SparePart**: id, name, partNumber, category, make, model, yearRange, condition (new_genuine/new_aftermarket/used_a/used_b/used_c), price, sellerId, photos[], compatibility[], warranty, description. `factory SparePart.fromJson()`.
- **PartsSeller**: id, name, type (dealer/importer/individual), location, rating, reviewCount, responseTime, salesCount, verified, specializations[], returnPolicy. `factory PartsSeller.fromJson()`.
- **PartsOrder**: id, items[], sellerId, totalCost, deliveryOption (pickup/boda/courier), deliveryFee, status (confirmed/shipped/delivered), trackingInfo, createdAt. `factory PartsOrder.fromJson()`.
- **PartRequest**: id, userId, vehicleInfo, partDescription, photos[], urgency, responses[]. `factory PartRequest.fromJson()`.

### Service Layer
- `searchParts(Map filters)` — GET `/api/spare-parts/search`
- `getPart(int id)` — GET `/api/spare-parts/parts/{id}`
- `getSeller(int id)` — GET `/api/spare-parts/sellers/{id}`
- `requestPart(Map data)` — POST `/api/spare-parts/requests`
- `getMyRequests()` — GET `/api/spare-parts/requests`
- `createOrder(Map orderData)` — POST `/api/spare-parts/orders`
- `getMyOrders()` — GET `/api/spare-parts/orders`
- `getOrderStatus(int id)` — GET `/api/spare-parts/orders/{id}`
- `checkCompatibility(int partId, int vehicleId)` — GET `/api/spare-parts/compatibility`
- `reportCounterfeit(int partId, Map evidence)` — POST `/api/spare-parts/report`
- `getShopDirectory({double? lat, double? lng})` — GET `/api/spare-parts/shops`

### Pages & Screens
- **Parts Search**: Three search modes -- vehicle selector (make/model/year), keyword text, photo snap (AI part identification). Category browse below.
- **Part Detail**: Photos, specs, compatibility list, price comparison across sellers, reviews, installation guide link.
- **Seller Profile**: Shop photos, inventory categories, ratings breakdown, return policy, location map.
- **Request a Part**: Describe what you need with vehicle info and photos, receive dealer quotes.
- **Cart & Checkout**: Items grouped by seller, delivery option per seller, total with wallet payment.

### Widgets
- `PartCardWidget` — Photo, name, price, condition badge, compatibility indicator
- `CompatibilityWidget` — Green checkmark "Fits your Toyota Prado 2018" or red X "Not compatible"
- `SellerRatingWidget` — Stars, "Responds in 2h", "450 sales"
- `ConditionBadgeWidget` — Color-coded: Green=New Genuine, Blue=New Aftermarket, Orange=Used A/B/C
- `CounterfeitAlertWidget` — Red warning banner with community reports count

---

## 2. UI Design

- Search: Large search bar with mode toggle (text/vehicle/photo)
- Parts grid: 2-column with condition badge overlay
- Compatibility: Prominent green/red indicator on every part card
- Seller cards: Trust indicators prominent (verified, rating, sales count)

### Key Screen Mockup — Parts Search
```
┌─────────────────────────────┐
│  SafeArea                   │
│  [Search parts...] [📷]    │
│  My Vehicle: Prado 2018 ▼  │
│  ── Categories ──────────   │
│  [Engine] [Brakes] [Body]  │
│  [Electric] [Suspension]   │
│  ── Results ─────────────   │
│  ┌──────┐ ┌──────┐         │
│  │[Photo]│ │[Photo]│         │
│  │BrakePd│ │OilFlt│         │
│  │New OEM│ │Afterm│         │
│  │45K TZS│ │12K   │         │
│  │✓ Fits │ │✓ Fits│         │
│  └──────┘ └──────┘         │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### Local-First with SQLite
```dart
// Table: spare_parts_cache
// Columns: id INTEGER PRIMARY KEY, name TEXT, category TEXT, make TEXT, model TEXT, json_data TEXT, synced_at TEXT
// Indexes: category, make, model
// Table: parts_orders
// Columns: id INTEGER PRIMARY KEY, status TEXT, json_data TEXT, synced_at TEXT
// Indexes: status
```

### Stale-While-Revalidate
- Search results: cache TTL 30 minutes
- Seller profiles: cache TTL 24 hours
- Orders: cache TTL 15 minutes
- Shop directory: cache TTL 24 hours

### Offline Support
- Read: Saved parts, order history, shop directory
- Write: Part requests queued, orders require connectivity
- Sync: Order status refreshed on reconnect

### Media Caching
- Part photos: MediaCacheService (14-day TTL)
- Seller/shop photos: 30-day TTL
- BlurHash for part grid thumbnails

---

## 4. Backend Implementation

### Database Tables
```sql
CREATE TABLE spare_parts (
    id BIGSERIAL PRIMARY KEY,
    seller_id BIGINT REFERENCES users(id),
    name VARCHAR(255),
    part_number VARCHAR(100),
    category VARCHAR(100),
    make VARCHAR(100),
    model VARCHAR(100),
    year_from INTEGER,
    year_to INTEGER,
    condition VARCHAR(30),
    price DECIMAL(12,2),
    photos JSONB DEFAULT '[]',
    compatibility JSONB DEFAULT '[]',
    warranty_days INTEGER DEFAULT 0,
    description TEXT,
    stock INTEGER DEFAULT 1,
    counterfeit_reports INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE parts_sellers (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    name VARCHAR(255),
    type VARCHAR(30),
    location JSONB,
    specializations TEXT[],
    return_policy TEXT,
    verified BOOLEAN DEFAULT FALSE,
    rating DECIMAL(3,2) DEFAULT 0,
    sales_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE parts_orders (
    id BIGSERIAL PRIMARY KEY,
    buyer_id BIGINT REFERENCES users(id),
    seller_id BIGINT REFERENCES parts_sellers(id),
    items JSONB,
    total_cost DECIMAL(12,2),
    delivery_option VARCHAR(30),
    delivery_fee DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'confirmed',
    tracking_info JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE part_requests (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    vehicle_info JSONB,
    description TEXT,
    photos JSONB DEFAULT '[]',
    urgency VARCHAR(20) DEFAULT 'normal',
    status VARCHAR(20) DEFAULT 'open',
    created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/spare-parts/search | Search parts | Yes |
| GET | /api/spare-parts/parts/{id} | Part detail | Yes |
| GET | /api/spare-parts/sellers/{id} | Seller profile | Yes |
| POST | /api/spare-parts/requests | Request a part | Yes |
| GET | /api/spare-parts/requests | My requests | Yes |
| POST | /api/spare-parts/orders | Create order | Yes |
| GET | /api/spare-parts/orders | My orders | Yes |
| GET | /api/spare-parts/orders/{id} | Order status | Yes |
| GET | /api/spare-parts/compatibility | Check compatibility | Yes |
| POST | /api/spare-parts/report | Report counterfeit | Yes |
| GET | /api/spare-parts/shops | Shop directory | Yes |

### Controller
- File: `app/Http/Controllers/Api/SparePartsController.php`
- Pattern: DB facade, try/catch, `{"success": true, "data": ...}` responses

### Background Jobs
- Part request quote notification to matching sellers
- Order status update notifications
- Counterfeit report review and part flagging
- Price drop alerts for watched parts

---

## 5. Integration Wiring

- **Wallet**: Parts payments with escrow for high-value items. Seller payouts.
- **My Cars**: Auto-fill vehicle details for search. VIN-based compatibility.
- **Service Garage**: Mechanic orders parts during service. Installation booking.
- **Messaging**: Chat with sellers before buying, negotiate prices.
- **Tajirika**: Parts dealers as TAJIRI partners with verification.
- **Owners Club**: Community-recommended sellers, counterfeit alerts.
- **Shop**: Parts integrated into TAJIRI marketplace via ShopService.
- **Notifications**: Order updates, price drops, quote responses.

---

## 6. Implementation Phases

### Phase 1: Foundation (Week 1)
- [ ] Create directory structure and spare_parts_module.dart
- [ ] SparePart, PartsSeller, PartsOrder, PartRequest models
- [ ] SparePartsService with AuthenticatedDio
- [ ] Backend: migrations + parts CRUD + search endpoint
- [ ] SQLite tables for parts cache and orders

### Phase 2: Core UI (Week 2)
- [ ] Parts Search with vehicle selector
- [ ] Part Detail with seller comparison
- [ ] Seller Profile with ratings
- [ ] Cart & Checkout with wallet payment
- [ ] My Orders with tracking

### Phase 3: Integration (Week 3)
- [ ] Wire to My Cars for vehicle data and VIN matching
- [ ] Wire to WalletService for payments
- [ ] Wire to MessageService for seller chat
- [ ] Wire to NotificationService for order alerts

### Phase 4: Polish (Week 4)
- [ ] Request a Part with dealer quotes
- [ ] Shop Directory with map view
- [ ] Compatibility checker
- [ ] Counterfeit reporting
- [ ] Offline saved parts viewing
- [ ] Photo-based part identification (future AI)

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| [TecDoc Catalog API](https://www.tecalliance.net/tecdoc-catalogue/) | TecAlliance | Industry-standard parts catalog, OEM + aftermarket | Paid (enterprise) | 1,000+ companies use it. OEM-to-aftermarket cross-reference. Fitment data by vehicle |
| [Car Databases Auto Parts API](https://cardatabases.com/api/auto-parts) | Car Databases | Part numbers, cross-reference, pricing, fitment | Paid (subscription) | ACES/PIES standards. Interchange data for finding compatible parts |
| [Levam OEM Parts API](https://levam.net/) | Levam Automotive | OEM parts catalogs with visual diagrams | Paid | VIN-based lookup. Visual parts explosion diagrams. Embeddable widget |
| [7zap Parts Catalog](https://7zap.com/en/) | 7zap | OEM + aftermarket parts with AI assistant | Paid | Visual diagrams from brand/model to exact part number. AI-powered search |
| [Auto Parts Catalog (RapidAPI)](https://rapidapi.com/makingdatameaningful/api/auto-parts-catalog) | Making Data Meaningful | TecDoc alternative for parts lookup | Freemium (via RapidAPI) | Available on RapidAPI marketplace. Easier onboarding than direct TecDoc |
| [Vehicle Databases Auto Parts API](https://vehicledatabases.com/auto-parts) | Vehicle Databases | OEM parts catalogs by VIN | Paid (subscription) | Part names, numbers, and drawings by VIN |
| [NHTSA vPIC API](https://vpic.nhtsa.dot.gov/api/) | US Dept. of Transportation | VIN decoding for parts compatibility | Free | Verify vehicle specs to match correct parts |
| [M-Pesa Open API](https://openapiportal.m-pesa.com) | Vodacom Tanzania | Parts purchase payments | Transaction fees | Dart SDK: `mpesa_sdk` on pub.dev |
| [AzamPay API](https://developers.azampay.co.tz/) | AzamPay (Bakhresa Group) | Payment gateway for parts orders | Transaction fees | Flutter SDK: `azampaytanzania` on pub.dev |
| [ClickPesa API](https://docs.clickpesa.com/) | ClickPesa | Unified payment collection | Transaction fees | Aggregates M-Pesa, Tigo Pesa, Airtel Money, HaloPesa |
| [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging) | Google | Order status notifications, part availability alerts | Free | Already integrated in TAJIRI app |
