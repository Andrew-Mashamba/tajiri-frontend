# My Cars — Implementation Plan

## Overview

My Cars is a comprehensive vehicle registration and management module for Tanzanian car owners. It supports multiple vehicles, digital document storage (logbook, insurance, road license, LATRA inspection), service and maintenance tracking with manufacturer schedules, fuel logging with economy calculations, mileage/trip tracking, expense management with reports, and vehicle health monitoring. It integrates deeply with other automotive modules (insurance, garage, fuel, sell/buy).

---

## 1. Frontend Architecture

### Directory Structure
```
lib/my_cars/
├── my_cars_module.dart                — Entry point & route registration
├── models/
│   ├── vehicle_models.dart            — Vehicle, VehicleSpec, OwnershipHistory
│   ├── document_models.dart           — VehicleDocument, DocumentType
│   ├── service_models.dart            — ServiceRecord, ServiceSchedule
│   ├── fuel_models.dart               — FuelEntry, FuelEconomy
│   └── expense_models.dart            — VehicleExpense, ExpenseCategory
├── services/
│   └── my_cars_service.dart           — API service using AuthenticatedDio
├── pages/
│   ├── my_garage_page.dart            — Grid/list of all vehicles
│   ├── vehicle_dashboard_page.dart    — Single vehicle overview
│   ├── add_vehicle_page.dart          — Registration flow
│   ├── documents_page.dart            — Document storage by type
│   ├── service_history_page.dart      — Maintenance timeline
│   ├── add_service_record_page.dart   — Log service details
│   ├── fuel_log_page.dart             — Fill-up history + charts
│   ├── expense_report_page.dart       — Cost breakdowns
│   ├── reminders_page.dart            — Upcoming renewals/services
│   └── vehicle_profile_page.dart      — Full specs and ownership history
└── widgets/
    ├── vehicle_card_widget.dart        — Vehicle thumbnail with status
    ├── document_status_widget.dart     — Expiry countdown indicator
    ├── fuel_economy_chart_widget.dart  — Km/L trend chart
    └── expense_pie_chart_widget.dart   — Category breakdown pie
```

### Data Models
- **Vehicle**: id, userId, registrationNumber, make, model, year, engineSize, color, vin, fuelType, transmission, photos[], mileage, createdAt. `factory Vehicle.fromJson()` with `_parseInt` for year/mileage.
- **VehicleDocument**: id, vehicleId, type (logbook/insurance/road_license/latra/license), fileUrl, expiryDate, isExpired, daysUntilExpiry. `factory VehicleDocument.fromJson()`.
- **ServiceRecord**: id, vehicleId, date, mileage, garageName, workDone, cost, receiptUrl, notes. `factory ServiceRecord.fromJson()` with `_parseDouble` for cost.
- **FuelEntry**: id, vehicleId, date, station, fuelType, liters, cost, mileage, kmPerLiter. `factory FuelEntry.fromJson()`.
- **VehicleExpense**: id, vehicleId, category, amount, date, description, receiptUrl. `factory VehicleExpense.fromJson()`.

### Service Layer
- `getVehicles()` — GET `/api/my-cars/vehicles`
- `addVehicle(Map data)` — POST `/api/my-cars/vehicles`
- `getVehicle(int id)` — GET `/api/my-cars/vehicles/{id}`
- `updateVehicle(int id, Map data)` — PUT `/api/my-cars/vehicles/{id}`
- `getDocuments(int vehicleId)` — GET `/api/my-cars/vehicles/{id}/documents`
- `uploadDocument(int vehicleId, File file, Map meta)` — POST `/api/my-cars/vehicles/{id}/documents`
- `getServiceHistory(int vehicleId)` — GET `/api/my-cars/vehicles/{id}/services`
- `addServiceRecord(int vehicleId, Map data)` — POST `/api/my-cars/vehicles/{id}/services`
- `getFuelLog(int vehicleId)` — GET `/api/my-cars/vehicles/{id}/fuel`
- `addFuelEntry(int vehicleId, Map data)` — POST `/api/my-cars/vehicles/{id}/fuel`
- `getExpenses(int vehicleId, {String? period})` — GET `/api/my-cars/vehicles/{id}/expenses`
- `getReminders()` — GET `/api/my-cars/reminders`

### Pages & Screens
- **My Garage**: Grid of vehicle cards with status badges (green=all OK, yellow=expiring, red=expired). Add vehicle FAB.
- **Vehicle Dashboard**: Next service alert, insurance countdown, fuel economy trend, recent expenses chart.
- **Add Vehicle**: Step wizard — reg number, details, photos, document uploads.
- **Documents**: Grouped by type with expiry status (green/yellow/red). Share button per document.
- **Service History**: Timeline view with cost, garage, work done per entry.
- **Fuel Log**: List of fill-ups with km/L chart, expense summaries by period.

### Widgets
- `VehicleCardWidget` — Photo, make/model, reg number, status dots for doc expiry
- `DocumentStatusWidget` — Circular countdown with days remaining, color-coded
- `FuelEconomyChartWidget` — Line chart of km/L over time
- `ExpensePieChartWidget` — Category breakdown (fuel, service, insurance, etc.)

---

## 2. UI Design

- Palette: #1A1A1A primary, #FAFAFA background
- Vehicle cards: 16dp border radius, vehicle photo as background with gradient overlay
- Status indicators: Green (#4CAF50) OK, Yellow (#FFC107) expiring, Red (#F44336) expired
- Touch targets: 48dp minimum
- Charts: Monochromatic with #1A1A1A and grey shades

### Key Screen Mockup — Vehicle Dashboard
```
┌─────────────────────────────┐
│  SafeArea                   │
│  ┌───────────────────────┐  │
│  │ [Vehicle Photo]       │  │
│  │ Toyota Land Cruiser   │  │
│  │ T-123-ABC  2019       │  │
│  └───────────────────────┘  │
│  ┌─────┐ ┌─────┐ ┌─────┐  │
│  │Insur│ │Road │ │LATRA│  │
│  │ 42d │ │ 8d! │ │ OK  │  │
│  └─────┘ └─────┘ └─────┘  │
│  ── Next Service ────────   │
│  Oil change in 1,200 km    │
│  ── Fuel Economy ────────   │
│  [LineChart 8.2 km/L]      │
│  ── Recent Expenses ─────   │
│  [PieChart breakdown]       │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### Local-First with SQLite
```dart
// Table: vehicles
// Columns: id INTEGER PRIMARY KEY, registration TEXT, make TEXT, model TEXT, json_data TEXT, synced_at TEXT
// Indexes: registration, make
// Table: vehicle_documents
// Columns: id INTEGER PRIMARY KEY, vehicle_id INTEGER, type TEXT, expiry_date TEXT, json_data TEXT, synced_at TEXT
// Indexes: vehicle_id, expiry_date
```

### Stale-While-Revalidate
- Vehicles and documents: cache TTL 1 hour
- Service history: cache TTL 24 hours
- Fuel log: cache TTL 1 hour
- Reminders: cache TTL 6 hours

### Offline Support
- Read: All vehicle data, documents, service history, fuel log
- Write: Add fuel entry, add service record, add expense queued in pending_queue
- Sync: Delta sync by updated_at timestamp

### Media Caching
- Vehicle photos: MediaCacheService (30-day TTL)
- Document scans: cached locally after first download
- BlurHash for vehicle card thumbnails

---

## 4. Backend Implementation

### Database Tables
```sql
CREATE TABLE vehicles (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    registration_number VARCHAR(20),
    make VARCHAR(100),
    model VARCHAR(100),
    year INTEGER,
    engine_size INTEGER,
    color VARCHAR(50),
    vin VARCHAR(50),
    fuel_type VARCHAR(20),
    transmission VARCHAR(20),
    mileage INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE vehicle_documents (
    id BIGSERIAL PRIMARY KEY,
    vehicle_id BIGINT REFERENCES vehicles(id),
    type VARCHAR(30),
    file_url TEXT,
    expiry_date DATE,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE service_records (
    id BIGSERIAL PRIMARY KEY,
    vehicle_id BIGINT REFERENCES vehicles(id),
    service_date DATE,
    mileage INTEGER,
    garage_name VARCHAR(255),
    work_done TEXT,
    cost DECIMAL(12,2),
    receipt_url TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE fuel_entries (
    id BIGSERIAL PRIMARY KEY,
    vehicle_id BIGINT REFERENCES vehicles(id),
    entry_date DATE,
    station VARCHAR(255),
    fuel_type VARCHAR(20),
    liters DECIMAL(8,2),
    cost DECIMAL(12,2),
    mileage INTEGER,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/my-cars/vehicles | List user vehicles | Yes |
| POST | /api/my-cars/vehicles | Register vehicle | Yes |
| GET | /api/my-cars/vehicles/{id} | Get vehicle detail | Yes |
| PUT | /api/my-cars/vehicles/{id} | Update vehicle | Yes |
| GET | /api/my-cars/vehicles/{id}/documents | List documents | Yes |
| POST | /api/my-cars/vehicles/{id}/documents | Upload document | Yes |
| GET | /api/my-cars/vehicles/{id}/services | Service history | Yes |
| POST | /api/my-cars/vehicles/{id}/services | Add service record | Yes |
| GET | /api/my-cars/vehicles/{id}/fuel | Fuel log | Yes |
| POST | /api/my-cars/vehicles/{id}/fuel | Add fuel entry | Yes |
| GET | /api/my-cars/reminders | All upcoming reminders | Yes |

### Controller
- File: `app/Http/Controllers/Api/MyCarsController.php`
- Pattern: DB facade, try/catch, `{"success": true, "data": ...}` responses

### Background Jobs
- Document expiry notification scheduler (daily check at 8am)
- Service due reminder based on mileage/time intervals
- Fuel economy recalculation after new entry

---

## 5. Integration Wiring

- **Wallet**: Vehicle expense payments, quick pay for services/insurance/fuel.
- **Car Insurance**: Insurance status on dashboard, one-tap renewal, policy docs synced.
- **Service Garage**: Book service with make/model/mileage pre-filled. Bi-directional sync.
- **Fuel Delivery**: Vehicle selection for fuel orders, auto fuel log update.
- **Sell Car**: Pre-populate listing with all vehicle data and service history.
- **Buy Car**: Auto-register purchased vehicle in garage.
- **Owners Club**: Auto-join brand community based on registered vehicles.
- **Spare Parts**: VIN-based part matching from stored chassis number.
- **LATRA**: Inspection certificate storage and expiry tracking.
- **Notifications**: Document expiry reminders at 30/14/7/1 days.

---

## 6. Implementation Phases

### Phase 1: Foundation (Week 1)
- [ ] Create directory structure and my_cars_module.dart
- [ ] Vehicle, Document, Service, Fuel, Expense models
- [ ] MyCarsService with AuthenticatedDio
- [ ] Backend: migrations + vehicle CRUD endpoints
- [ ] SQLite tables for vehicles and documents

### Phase 2: Core UI (Week 2)
- [ ] My Garage grid/list view
- [ ] Vehicle Dashboard with status indicators
- [ ] Add Vehicle wizard
- [ ] Documents page with expiry indicators
- [ ] Service History timeline

### Phase 3: Integration (Week 3)
- [ ] Wire to car_insurance for status display
- [ ] Wire to service_garage for booking
- [ ] Wire to NotificationService for expiry alerts
- [ ] Wire to LocationService for parking saver

### Phase 4: Polish (Week 4)
- [ ] Offline support for all vehicle data
- [ ] BlurHash for vehicle photos
- [ ] Pull-to-refresh, empty states
- [ ] Fuel economy charts
- [ ] Expense report PDF export
- [ ] Document sharing functionality

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| [TRA Motor Vehicle Registration](https://www.tra.go.tz/index.php/motor-vehicles-registration) | Tanzania Revenue Authority | Vehicle registration lookup | Government portal | No public API. May need partnership agreement |
| [LATRA VTS](https://vts.latra.go.tz/) | Land Transport Regulatory Authority | Commercial vehicle tracking, compliance | Government system | GPS-based tracking for intercity buses. Contact LATRA for integration |
| [NHTSA vPIC API](https://vpic.nhtsa.dot.gov/api/) | US Dept. of Transportation | VIN decoding (make, model, year, specs) | Free | Best free VIN decoder. REST/JSON. Works for vehicles manufactured for any market |
| [Vincario](https://vincario.com/vin-decoder/) | Vincario | Global VIN decoding + vehicle history | Paid (per-query) | Supports European, Asian, African market vehicles. Bulk VIN decode |
| [CarMD API](https://www.carmd.com/api/) | CarMD | OBD-II diagnostics, repair estimates, maintenance schedules | Paid (tiered plans) | Diagnostic code interpretation, repair cost estimates. 1996+ vehicles |
| [Smartcar API](https://smartcar.com/docs/api/) | Smartcar | Connected car data (fuel, odometer, location, lock/unlock) | Freemium (tiered) | OAuth 2.0 vehicle auth. 40+ automakers, 177M cars. No OBD hardware needed |
| [M-Pesa Open API](https://openapiportal.m-pesa.com) | Vodacom Tanzania | Vehicle expense payments | Transaction fees | Dart SDK: `mpesa_sdk` on pub.dev |
| [AzamPay API](https://developers.azampay.co.tz/) | AzamPay (Bakhresa Group) | Payment gateway for vehicle services | Transaction fees | Flutter SDK: `azampaytanzania` on pub.dev |
| [Google Maps Platform](https://developers.google.com/maps) | Google | Parking saver location, vehicle tracking | Freemium (10K free/month) | Already partially integrated in TAJIRI |
| [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging) | Google | Service reminders, insurance renewal alerts | Free | Already integrated in TAJIRI app |
