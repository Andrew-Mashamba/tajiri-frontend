# Fuel Delivery — Implementation Plan

## Overview

Fuel Delivery brings on-demand fuel to parked vehicles, generators, and fleet depots across Tanzania. Users select fuel type and quantity, choose delivery location via GPS, track the delivery driver in real-time, and pay through TAJIRI Wallet. The module supports personal one-off orders, recurring scheduled deliveries, fleet management for businesses, generator/industrial fuel supply, and EWURA-compliant pricing with transparent fee breakdowns.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/fuel_delivery/
├── fuel_delivery_module.dart          — Entry point & route registration
├── models/
│   ├── fuel_order_models.dart         — FuelOrder, FuelType, OrderStatus
│   ├── delivery_models.dart           — DeliveryDriver, DeliveryTracking
│   ├── pricing_models.dart            — FuelPrice, PriceBreakdown
│   └── fleet_models.dart              — FleetAccount, FleetVehicle, Report
├── services/
│   └── fuel_delivery_service.dart     — API service using AuthenticatedDio
├── pages/
│   ├── order_fuel_page.dart           — Map location, fuel type, quantity
│   ├── delivery_tracking_page.dart    — Real-time driver map + ETA
│   ├── price_display_page.dart        — EWURA prices, comparison
│   ├── fleet_dashboard_page.dart      — Multi-vehicle fuel management
│   ├── delivery_history_page.dart     — Past deliveries with receipts
│   ├── schedule_delivery_page.dart    — Calendar-based planning
│   ├── fuel_reports_page.dart         — Consumption analytics
│   └── business_account_page.dart     — Company profile, billing
└── widgets/
    ├── fuel_type_selector_widget.dart  — Petrol/Diesel toggle
    ├── quantity_slider_widget.dart     — Liters or TZS amount picker
    ├── driver_card_widget.dart         — Driver photo, rating, cert
    ├── price_breakdown_widget.dart     — Fuel + delivery + service fees
    └── delivery_status_widget.dart     — Order progress stepper
```

### Data Models
- **FuelOrder**: id, userId, vehicleId, fuelType, quantity, totalCost, deliveryFee, location, scheduledAt, status (pending/confirmed/en_route/delivering/completed), driverId, createdAt. `factory FuelOrder.fromJson()` with `_parseDouble`.
- **DeliveryDriver**: id, name, photo, rating, certification, vehiclePlate, location, eta. `factory DeliveryDriver.fromJson()`.
- **FuelPrice**: fuelType, regionId, regionName, capPrice, deliveryFee, effectiveDate. `factory FuelPrice.fromJson()`.
- **FleetAccount**: id, companyName, vehicles[], authorizedUsers[], monthlyBudget, spent. `factory FleetAccount.fromJson()`.

### Service Layer
- `orderFuel(Map orderData)` — POST `/api/fuel-delivery/orders`
- `getOrderStatus(int orderId)` — GET `/api/fuel-delivery/orders/{id}`
- `getCurrentPrices({String? region})` — GET `/api/fuel-delivery/prices`
- `getPriceHistory({String fuelType, String region})` — GET `/api/fuel-delivery/prices/history`
- `scheduleDelivery(Map scheduleData)` — POST `/api/fuel-delivery/schedule`
- `getDeliveryHistory({String? period})` — GET `/api/fuel-delivery/history`
- `getFleetDashboard()` — GET `/api/fuel-delivery/fleet`
- `getFuelReports({String period, int? vehicleId})` — GET `/api/fuel-delivery/reports`

### Pages & Screens
- **Order Fuel**: Map with draggable pin, fuel type toggle (Petrol/Diesel), quantity slider, vehicle picker from My Cars, schedule or deliver now, price breakdown.
- **Delivery Tracking**: Full-screen map with driver marker, animated route, ETA countdown, driver card, call/chat buttons.
- **Price Display**: Regional prices table, EWURA cap comparison, monthly trend chart.
- **Fleet Dashboard**: Vehicle grid with last fuel date, consumption bars, spending summary.
- **Fuel Reports**: Bar charts for consumption by vehicle, line chart for spending over time.

### Widgets
- `FuelTypeSelectorWidget` — Toggle button: Petrol Regular / Petrol Premium / Diesel
- `QuantitySliderWidget` — Slider with liters display, cost preview
- `DriverCardWidget` — Photo, name, rating stars, certification badge
- `PriceBreakdownWidget` — Itemized: fuel TZS x liters + delivery + service = total

---

## 2. UI Design

- Order screen: Map takes top 60%, controls bottom 40% in bottom sheet
- Fuel type: Dark filled toggle for selected, outlined for others
- Price display: Large bold price, EWURA cap badge
- Tracking: Full bleed map with floating ETA card

### Key Screen Mockup — Order Fuel
```
┌─────────────────────────────┐
│  [Google Map with Pin]      │
│                             │
│                             │
│  ─── Drag to set location   │
├─────────────────────────────┤
│  ┌─────────────────────┐    │
│  │[Petrol] [Diesel]    │    │
│  └─────────────────────┘    │
│  Quantity: ◀── 30L ──▶     │
│  Vehicle: Toyota Prado ▼   │
│  ┌─────────────────────┐    │
│  │ Fuel:    TZS 93,000 │    │
│  │ Delivery: TZS 5,000 │    │
│  │ Total:  TZS 98,000  │    │
│  └─────────────────────┘    │
│  [   Order Now   ]          │
│  [Schedule for Later]       │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### Local-First with SQLite
```dart
// Table: fuel_orders
// Columns: id INTEGER PRIMARY KEY, status TEXT, fuel_type TEXT, json_data TEXT, synced_at TEXT
// Indexes: status
// Table: fuel_prices
// Columns: id INTEGER PRIMARY KEY, region TEXT, fuel_type TEXT, cap_price REAL, effective_date TEXT, json_data TEXT
// Indexes: region, fuel_type
```

### Stale-While-Revalidate
- Fuel prices: cache TTL 24 hours (update monthly)
- Order history: cache TTL 1 hour
- Fleet data: cache TTL 30 minutes
- Active delivery: real-time only, no caching

### Offline Support
- Read: Price list, delivery history, fleet reports
- Write: Scheduled deliveries queued if offline (confirmed on reconnect)
- Sync: Order status synced on reconnect

### Media Caching
- Driver photos: MediaCacheService (7-day TTL)
- Delivery completion photos: cached locally

---

## 4. Backend Implementation

### Database Tables
```sql
CREATE TABLE fuel_orders (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    vehicle_id BIGINT REFERENCES vehicles(id),
    fuel_type VARCHAR(20),
    quantity DECIMAL(8,2),
    unit_price DECIMAL(10,2),
    delivery_fee DECIMAL(10,2),
    total_cost DECIMAL(12,2),
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    address TEXT,
    scheduled_at TIMESTAMP,
    driver_id BIGINT,
    status VARCHAR(20) DEFAULT 'pending',
    completion_photo TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE fuel_prices (
    id BIGSERIAL PRIMARY KEY,
    region VARCHAR(100),
    fuel_type VARCHAR(20),
    cap_price DECIMAL(10,2),
    effective_date DATE,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE fleet_accounts (
    id BIGSERIAL PRIMARY KEY,
    company_name VARCHAR(255),
    owner_user_id BIGINT REFERENCES users(id),
    monthly_budget DECIMAL(15,2),
    created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | /api/fuel-delivery/orders | Place fuel order | Yes |
| GET | /api/fuel-delivery/orders/{id} | Order status | Yes |
| GET | /api/fuel-delivery/prices | Current fuel prices | Yes |
| GET | /api/fuel-delivery/prices/history | Price trends | Yes |
| POST | /api/fuel-delivery/schedule | Schedule delivery | Yes |
| GET | /api/fuel-delivery/history | Delivery history | Yes |
| GET | /api/fuel-delivery/fleet | Fleet dashboard | Yes |
| GET | /api/fuel-delivery/reports | Fuel reports | Yes |

### Controller
- File: `app/Http/Controllers/Api/FuelDeliveryController.php`
- Pattern: DB facade, try/catch, `{"success": true, "data": ...}` responses

### Background Jobs
- Monthly EWURA price bulletin parsing and price update
- Recurring delivery scheduling (cron: check scheduled deliveries)
- Fleet budget threshold alerts
- Driver assignment optimization

---

## 5. Integration Wiring

- **Wallet**: Primary payment, prepaid fuel credits, fleet invoicing.
- **My Cars**: Vehicle selection, fuel log auto-update after delivery.
- **Service Garage**: Add-on checks during delivery (tire pressure, oil level).
- **EWURA**: Real-time EWURA cap prices on ordering screen. Compliance verification.
- **Notifications**: Order confirmed, driver en route, delivery complete, price change alerts.
- **Location**: GPS delivery location, driver tracking, delivery zone validation.
- **Tajirika**: Delivery drivers as TAJIRI partners with earnings dashboard.
- **Business**: Corporate fuel management, employee fuel cards, department budgets.
- **Budget**: Fuel expense tracking, monthly spending alerts.

---

## 6. Implementation Phases

### Phase 1: Foundation (Week 1)
- [ ] Create directory structure and fuel_delivery_module.dart
- [ ] FuelOrder, DeliveryDriver, FuelPrice, FleetAccount models
- [ ] FuelDeliveryService with AuthenticatedDio
- [ ] Backend: migrations + orders + prices endpoints
- [ ] SQLite tables for orders and prices

### Phase 2: Core UI (Week 2)
- [ ] Order Fuel page with map and controls
- [ ] Delivery Tracking with real-time map
- [ ] Price Display with EWURA prices
- [ ] Delivery History with receipts
- [ ] Schedule Delivery calendar

### Phase 3: Integration (Week 3)
- [ ] Wire to WalletService for payments
- [ ] Wire to My Cars for vehicle selection and fuel log
- [ ] Wire to EWURA for price compliance
- [ ] Wire to NotificationService for delivery alerts
- [ ] Firestore listeners for driver location

### Phase 4: Polish (Week 4)
- [ ] Offline price viewing
- [ ] Fleet Dashboard for businesses
- [ ] Fuel Reports with charts
- [ ] Delivery completion photo verification
- [ ] Pull-to-refresh, empty states
- [ ] Error handling with retry

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| [EWURA Cap Prices](https://www.ewura.go.tz/publications/petroleum-price) | EWURA (Tanzania) | Official fuel cap prices for 190+ TZ locations | Free (government) | Monthly PDF publications. No REST API — need scraping or scheduled data extraction |
| [GlobalPetrolPrices API](https://www.globalpetrolprices.com/data_access.php) | GlobalPetrolPrices.com | Fuel prices for 135 countries including Tanzania | Paid (subscription, 2-week free trial) | XML data feed. Historical data + forecasts. Includes Brent/WTI crude prices |
| [HERE Fuel Prices API](https://developer.here.com/documentation/fuel-prices/dev_guide/topics/overview.html) | HERE Technologies | Fuel station locations + real-time prices | Freemium | REST API with JSON/XML. Station search by location |
| [TomTom Fuel Prices API](https://developer.tomtom.com/fuel-prices-api/documentation/product-information/introduction) | TomTom | Fuel station prices and locations | Freemium | Part of TomTom's location services suite |
| [Google Maps Places API](https://developers.google.com/maps/documentation/places) | Google | Find nearby fuel stations | Freemium | Search for gas stations by location. Returns ratings, hours, contact info |
| [Easy Track Africa](https://easytrackafrica.com/) | Easy Track | GPS fleet tracking for fuel delivery vehicles | B2B subscription | LATRA-approved VTS provider in Tanzania. Real-time vehicle tracking |
| [Google Maps Platform](https://developers.google.com/maps) | Google | Delivery route optimization, ETA calculation | Freemium (10K free/month) | Routes API for delivery vehicle routing |
| [Mapbox](https://docs.mapbox.com/) | Mapbox | Maps, directions for delivery tracking | Freemium (100K free directions/month) | Mobile Navigation SDK available |
| [OpenRouteService](https://openrouteservice.org/) | HeiGIT | Routing, distance matrix for delivery optimization | Free (open source, self-hostable) | Uses OpenStreetMap data. Can self-host via Docker |
| [M-Pesa Open API](https://openapiportal.m-pesa.com) | Vodacom Tanzania | Fuel delivery payments | Transaction fees | Dart SDK: `mpesa_sdk` on pub.dev |
| [AzamPay API](https://developers.azampay.co.tz/) | AzamPay (Bakhresa Group) | Payment gateway for fuel orders | Transaction fees | Flutter SDK: `azampaytanzania` on pub.dev |
| [ClickPesa API](https://docs.clickpesa.com/) | ClickPesa | Unified payment collection | Transaction fees | Aggregates M-Pesa, Tigo Pesa, Airtel Money, HaloPesa |
| [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging) | Google | Delivery status notifications | Free | Already integrated in TAJIRI app |
