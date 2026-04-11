# EWURA (Energy and Water Utilities Regulatory Authority) — Implementation Plan

## Overview

The EWURA module gives Tanzanian consumers mobile access to energy and water regulatory information. Its primary value is displaying monthly EWURA-approved fuel cap prices by region so users can detect overcharging at petrol stations. It also covers fuel station mapping with crowd-sourced prices, electricity and water tariff calculators (TANESCO/DAWASCO), utility complaint filing, licensed operator directories for petrol stations and LPG dealers, fuel quality reporting, and energy saving tips. The module makes opaque utility regulation transparent and actionable.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/ewura/
├── ewura_module.dart                  — Entry point & route registration
├── models/
│   ├── fuel_price_models.dart         — FuelPrice, RegionalPrice, PriceTrend
│   ├── station_models.dart            — FuelStation, StationRating, LPGDealer
│   ├── tariff_models.dart             — ElectricityTariff, WaterTariff, Band
│   ├── complaint_models.dart          — UtilityComplaint, ComplaintType
│   └── operator_models.dart           — LicensedOperator, OperatorType
├── services/
│   └── ewura_service.dart             — API service using AuthenticatedDio
├── pages/
│   ├── ewura_home_page.dart           — Fuel prices, quick complaint, alerts
│   ├── fuel_prices_page.dart          — Regional prices with month selector
│   ├── station_map_page.dart          — Nearby stations with prices/ratings
│   ├── report_overcharging_page.dart  — Quick report with evidence
│   ├── tariff_calculator_page.dart    — Electricity/water bill calculator
│   ├── complaint_form_page.dart       — Utility complaint wizard
│   ├── my_complaints_page.dart        — Complaint tracking
│   └── price_trends_page.dart         — Historical fuel price charts
└── widgets/
    ├── fuel_price_card_widget.dart     — Petrol/Diesel/Kerosene prices
    ├── station_pin_widget.dart         — Map marker with price label
    ├── tariff_band_widget.dart         — Tariff band breakdown display
    ├── overcharge_alert_widget.dart    — Red alert when price exceeds cap
    └── price_trend_chart_widget.dart   — Monthly price line chart
```

### Data Models
- **FuelPrice**: id, region, fuelType (petrol/diesel/kerosene), capPrice, effectiveDate, previousPrice, changePercent. `factory FuelPrice.fromJson()` with `_parseDouble`.
- **FuelStation**: id, name, brand, location, fuelTypes[], reportedPrices[], rating, licensed, operatingHours. `factory FuelStation.fromJson()`.
- **ElectricityTariff**: meterType (prepaid/postpaid), bands[] (units range, rate per unit), serviceCharge, effectiveDate. `factory ElectricityTariff.fromJson()`.
- **WaterTariff**: authority, bands[] (cubic meter range, rate), minimumCharge, effectiveDate. `factory WaterTariff.fromJson()`.
- **UtilityComplaint**: id, userId, utilityType (tanesco/dawasco/fuel_station), providerName, type (billing/outage/quality/service), description, evidence[], status, referenceNumber, createdAt. `factory UtilityComplaint.fromJson()`.

### Service Layer
- `getFuelPrices({String? region, String? fuelType})` — GET `/api/ewura/fuel-prices`
- `getFuelPriceHistory({String region, String fuelType})` — GET `/api/ewura/fuel-prices/history`
- `getNearbyStations({double lat, double lng})` — GET `/api/ewura/stations`
- `reportOvercharging(Map data)` — POST `/api/ewura/reports/overcharging`
- `reportFuelQuality(Map data)` — POST `/api/ewura/reports/fuel-quality`
- `getElectricityTariffs()` — GET `/api/ewura/tariffs/electricity`
- `getWaterTariffs({String? authority})` — GET `/api/ewura/tariffs/water`
- `calculateElectricityBill(Map params)` — POST `/api/ewura/calculate/electricity`
- `calculateWaterBill(Map params)` — POST `/api/ewura/calculate/water`
- `fileComplaint(Map data)` — POST `/api/ewura/complaints`
- `getMyComplaints()` — GET `/api/ewura/complaints`
- `verifyOperator(String name)` — GET `/api/ewura/operators/verify`

### Pages & Screens
- **EWURA Home**: Current region fuel prices card (petrol/diesel/kerosene), price change indicator, quick complaint button, safety alerts.
- **Fuel Prices**: Regional dropdown + month selector, table of all fuel types with cap prices, price change arrows.
- **Station Map**: Map with station pins colored by price (green=at cap, red=above), tap for details and rating.
- **Report Overcharging**: Station name, fuel type, price charged, evidence photo of pump display, auto GPS location.
- **Tariff Calculator**: Toggle electricity/water, input units/cubic meters, result shows band breakdown and total bill.
- **Price Trends**: Line chart with 12-24 month history, region selector, fuel type toggle.

### Widgets
- `FuelPriceCardWidget` — Three columns: Petrol, Diesel, Kerosene with prices and change arrows
- `StationPinWidget` — Map marker with color and mini price label
- `TariffBandWidget` — Stacked bar showing units per band with rate
- `OverchargeAlertWidget` — Red banner "Station charging TZS 200 above EWURA cap!"
- `PriceTrendChartWidget` — Line chart with monthly data points

---

## 2. UI Design

- Fuel prices: Large bold numbers, green/red arrows for change direction
- Station map: Color-coded pins (green=compliant, yellow=near cap, red=over cap)
- Tariff calculator: Clean form with instant result
- Reports: Quick single-screen form with camera for evidence

### Key Screen Mockup — EWURA Home
```
┌─────────────────────────────┐
│  SafeArea                   │
│  Fuel Prices — Dar es Salaam│
│  Updated: April 2026        │
│  ┌───────────────────────┐  │
│  │ Petrol    TZS 3,100 ▲ │  │
│  │ Diesel    TZS 2,850 ▼ │  │
│  │ Kerosene  TZS 2,400 ─ │  │
│  └───────────────────────┘  │
│  [View All Regions]         │
│  [Find Nearest Station 📍] │
│                             │
│  ── Quick Actions ────────  │
│  [Report Overcharging]      │
│  [Calculate Electricity Bill│
│  [Calculate Water Bill]     │
│                             │
│  ── Price Trends ────────   │
│  [Sparkline 12mo petrol]   │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### Local-First with SQLite
```dart
// Table: ewura_fuel_prices
// Columns: id INTEGER PRIMARY KEY, region TEXT, fuel_type TEXT, cap_price REAL, effective_date TEXT, json_data TEXT, synced_at TEXT
// Indexes: region, fuel_type, effective_date
// Table: ewura_stations
// Columns: id INTEGER PRIMARY KEY, name TEXT, lat REAL, lng REAL, json_data TEXT, synced_at TEXT
// Indexes: name
```

### Stale-While-Revalidate
- Fuel prices: cache TTL 24 hours (update monthly)
- Station directory: cache TTL 24 hours
- Tariffs: cache TTL 30 days (update quarterly)
- Complaints: cache TTL 30 minutes
- Price history: cache TTL 7 days

### Offline Support
- Read: Fuel prices (critical for offline overcharge checking), tariff rates, station directory
- Write: Overcharging reports and complaints saved as drafts offline
- Sync: Monthly fuel price bulk sync when EWURA publishes

### Media Caching
- Overcharging evidence photos: cached locally until upload
- Station photos: MediaCacheService (30-day TTL)

---

## 4. Backend Implementation

### Database Tables
```sql
CREATE TABLE ewura_fuel_prices (
    id BIGSERIAL PRIMARY KEY,
    region VARCHAR(100),
    fuel_type VARCHAR(20),
    cap_price DECIMAL(10,2),
    effective_date DATE,
    previous_price DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE ewura_stations (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255),
    brand VARCHAR(100),
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    address TEXT,
    fuel_types TEXT[],
    licensed BOOLEAN DEFAULT TRUE,
    operating_hours JSONB,
    rating DECIMAL(3,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE ewura_complaints (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    utility_type VARCHAR(30),
    provider_name VARCHAR(255),
    complaint_type VARCHAR(30),
    description TEXT,
    evidence JSONB DEFAULT '[]',
    reference_number VARCHAR(20) UNIQUE,
    status VARCHAR(20) DEFAULT 'submitted',
    resolution TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE ewura_tariffs (
    id BIGSERIAL PRIMARY KEY,
    utility_type VARCHAR(20),
    authority VARCHAR(100),
    meter_type VARCHAR(20),
    bands JSONB,
    service_charge DECIMAL(10,2),
    effective_date DATE,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/ewura/fuel-prices | Current fuel prices | No |
| GET | /api/ewura/fuel-prices/history | Price trends | No |
| GET | /api/ewura/stations | Nearby stations | Yes |
| POST | /api/ewura/reports/overcharging | Report overcharging | Yes |
| POST | /api/ewura/reports/fuel-quality | Report fuel quality | Yes |
| GET | /api/ewura/tariffs/electricity | Electricity tariffs | No |
| GET | /api/ewura/tariffs/water | Water tariffs | No |
| POST | /api/ewura/calculate/electricity | Calculate bill | No |
| POST | /api/ewura/calculate/water | Calculate bill | No |
| POST | /api/ewura/complaints | File complaint | Yes |
| GET | /api/ewura/complaints | My complaints | Yes |
| GET | /api/ewura/operators/verify | Verify operator | Yes |

### Controller
- File: `app/Http/Controllers/Api/EwuraController.php`
- Pattern: DB facade, try/catch, `{"success": true, "data": ...}` responses
- Fuel prices: Parsed from monthly EWURA PDF bulletins

### Background Jobs
- Monthly EWURA price bulletin PDF parsing and database update
- Fuel price change notification broadcasting
- Crowd-sourced station price aggregation
- Tariff update sync (quarterly)

---

## 5. Integration Wiring

- **Fuel Delivery**: EWURA cap prices on delivery ordering screen. Compliance verification.
- **My Cars**: Fuel expense cross-reference with regional cap prices. Overcharge detection.
- **Transport**: Fuel cost impact on fare structures. Route fuel cost estimation.
- **Bills**: Electricity and water bill tracking with tariff calculator.
- **Wallet**: Utility bill payments (TANESCO, DAWASCO).
- **Notifications**: Monthly price publication alerts, complaint updates, outage alerts.
- **Location**: Station map, nearest station finder, LPG dealer locations.
- **Groups**: Consumer groups for station reviews, outage reports, energy tips.
- **LATRA**: Cross-reference fuel prices with transport fare structures.
- **Budget**: Utility expense tracking, fuel budgets.

---

## 6. Implementation Phases

### Phase 1: Foundation (Week 1)
- [ ] Create directory structure and ewura_module.dart
- [ ] FuelPrice, FuelStation, Tariff, Complaint models
- [ ] EwuraService with AuthenticatedDio
- [ ] Backend: migrations + fuel prices + tariffs endpoints
- [ ] SQLite tables for fuel prices and stations

### Phase 2: Core UI (Week 2)
- [ ] EWURA Home with fuel prices and quick actions
- [ ] Fuel Prices page with region/month selectors
- [ ] Station Map with colored pins
- [ ] Tariff Calculator for electricity and water
- [ ] Report Overcharging form

### Phase 3: Integration (Week 3)
- [ ] Wire to Fuel Delivery for price compliance
- [ ] Wire to My Cars for fuel expense reference
- [ ] Wire to NotificationService for price alerts
- [ ] Wire to LocationService for station finder

### Phase 4: Polish (Week 4)
- [ ] Price Trends historical charts
- [ ] Utility Complaint form and tracking
- [ ] LPG Dealer verification
- [ ] Offline fuel price viewing
- [ ] Energy Saving Tips content
- [ ] Empty states and error handling

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| [EWURA Cap Prices](https://www.ewura.go.tz/publications/petroleum-price) | EWURA (Tanzania) | Official fuel cap prices for 190+ TZ locations | Free (government) | Monthly PDF publications. No REST API — need scraping or scheduled data extraction |
| [GlobalPetrolPrices API](https://www.globalpetrolprices.com/data_access.php) | GlobalPetrolPrices.com | Fuel prices for 135 countries including Tanzania | Paid (subscription, 2-week free trial) | XML data feed. Historical data + forecasts |
| [HERE Fuel Prices API](https://developer.here.com/documentation/fuel-prices/dev_guide/topics/overview.html) | HERE Technologies | Fuel station locations + real-time prices | Freemium | REST API with JSON/XML. Station search by location |
| [TomTom Fuel Prices API](https://developer.tomtom.com/fuel-prices-api/documentation/product-information/introduction) | TomTom | Fuel station prices and locations | Freemium | Part of TomTom's location services suite |
| [Google Maps Places API](https://developers.google.com/maps/documentation/places) | Google | Find nearby fuel stations, utility offices | Freemium | Search by location. Returns ratings, hours, contact info |
| [M-Pesa Open API](https://openapiportal.m-pesa.com) | Vodacom Tanzania | Utility bill payments | Transaction fees | Dart SDK: `mpesa_sdk` on pub.dev |
| [AzamPay API](https://developers.azampay.co.tz/) | AzamPay (Bakhresa Group) | Payment gateway for utility services | Transaction fees | Flutter SDK: `azampaytanzania` on pub.dev |
| [Africa's Talking](https://developers.africastalking.com/) | Africa's Talking | SMS alerts for price changes, complaints | Pay-as-you-go | Supports all 3 major TZ telcos |
| [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging) | Google | Price change notifications, complaint updates | Free | Already integrated in TAJIRI app |
