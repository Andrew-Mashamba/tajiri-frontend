# Ambulance Services — Implementation Plan

## Overview

The Ambulance module provides emergency medical services for Tanzania, featuring a one-tap SOS button, aggregated ambulance dispatch from multiple providers (MoH, AAR, St. John, private), real-time GPS tracking of dispatched ambulances, medical profile storage, hospital directory, first aid guides, and insurance integration. It addresses the critical lack of a unified emergency response system in Tanzania.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/ambulance/
├── ambulance_module.dart              — Entry point & route registration
├── models/
│   ├── emergency_models.dart          — Emergency, AmbulanceUnit, Dispatch
│   ├── medical_profile_models.dart    — MedicalProfile, EmergencyContact
│   └── hospital_models.dart           — Hospital, HospitalCapability
├── services/
│   └── ambulance_service.dart         — API service using AuthenticatedDio
├── pages/
│   ├── emergency_home_page.dart       — SOS button, quick access
│   ├── ambulance_tracking_page.dart   — Real-time map tracking
│   ├── medical_profile_page.dart      — Blood type, allergies, conditions
│   ├── hospital_directory_page.dart   — Searchable hospital list + map
│   ├── first_aid_guide_page.dart      — Category-based instructions
│   ├── insurance_manager_page.dart    — Policy storage, verification
│   ├── emergency_history_page.dart    — Past emergency calls
│   ├── family_profiles_page.dart      — Household medical profiles
│   └── community_responders_page.dart — Volunteer registration
└── widgets/
    ├── sos_button_widget.dart         — Large animated SOS button
    ├── ambulance_map_widget.dart      — Map with ambulance tracking
    ├── medical_id_card_widget.dart    — QR code medical ID
    └── eta_indicator_widget.dart      — ETA with live updates
```

### Data Models
- **Emergency**: id, userId, location, status (dispatched/en_route/arrived/completed), ambulanceId, hospitalId, createdAt. `factory Emergency.fromJson()`.
- **MedicalProfile**: id, userId, bloodType, allergies[], conditions[], medications[], emergencyContacts[], insuranceInfo, qrCode. `factory MedicalProfile.fromJson()`.
- **Hospital**: id, name, type, capabilities[], location, bedAvailability, rating, phone, distance. `factory Hospital.fromJson()` with `_parseDouble` for rating/distance.
- **AmbulanceUnit**: id, provider, driverName, driverPhoto, qualifications, location, eta. `factory AmbulanceUnit.fromJson()`.

### Service Layer
- `triggerSOS(Map locationData)` — POST `/api/ambulance/sos`
- `getDispatchStatus(int emergencyId)` — GET `/api/ambulance/dispatch/{id}`
- `getMedicalProfile()` — GET `/api/ambulance/medical-profile`
- `updateMedicalProfile(Map data)` — PUT `/api/ambulance/medical-profile`
- `getHospitals({double lat, double lng, String? capability})` — GET `/api/ambulance/hospitals`
- `getFirstAidGuides({String? category})` — GET `/api/ambulance/first-aid`
- `getEmergencyHistory()` — GET `/api/ambulance/history`
- `registerResponder(Map data)` — POST `/api/ambulance/responders`

### Pages & Screens
- **Emergency Home**: Dominant SOS button (largest UI element), medical profile quick access, emergency contacts strip.
- **Ambulance Tracking**: Full-screen map with ambulance GPS marker, ETA overlay, driver info card, call/chat buttons.
- **Medical Profile Editor**: Form with blood type picker, allergies tags, conditions list, medications, emergency contacts.
- **Hospital Directory**: List/map toggle, filter by capability, distance sort, bed availability indicators.
- **First Aid Guide**: Category grid (CPR, choking, bleeding, burns, snakebite), step-by-step with illustrations, offline-accessible.

### Widgets
- `SOSButtonWidget` — 120dp circular red button with pulse animation, haptic feedback
- `AmbulanceMapWidget` — Google Maps with ambulance marker, route polyline, ETA
- `MedicalIDCardWidget` — QR code with name, blood type, allergies summary
- `ETAIndicatorWidget` — Countdown with live recalculation

---

## 2. UI Design

- SOS button: 120dp diameter, Color(0xFFCC0000), pulsing animation, center of Emergency Home
- Cards: BorderRadius.circular(16), white background, subtle shadow
- Emergency state: Red accent theme when dispatch is active
- Touch targets: 48dp minimum, SOS button is 120dp
- Icons: emergency_rounded, local_hospital_rounded, medical_services_rounded

### Key Screen Mockup — Emergency Home
```
┌─────────────────────────────┐
│  SafeArea                   │
│  ┌───────────────────────┐  │
│  │ 🩸 A+  │ Allergies: 2 │  │
│  │ Medical Profile ────> │  │
│  └───────────────────────┘  │
│                             │
│       ┌───────────┐         │
│       │           │         │
│       │    SOS    │         │
│       │  120dp    │         │
│       │           │         │
│       └───────────┘         │
│    Tap for Emergency        │
│                             │
│  ── Emergency Contacts ──   │
│  [Avatar] [Avatar] [Avatar] │
│  ── Nearby Hospitals ────   │
│  [Hospital Card] 2.3 km    │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### Local-First with SQLite
```dart
// Table: medical_profiles
// Columns: id INTEGER PRIMARY KEY, user_id INTEGER, blood_type TEXT, json_data TEXT, synced_at TEXT
// Indexes: user_id
// Table: hospitals
// Columns: id INTEGER PRIMARY KEY, name TEXT, lat REAL, lng REAL, json_data TEXT, synced_at TEXT
// Indexes: name
```

### Stale-While-Revalidate
- Medical profile: cached locally, synced on edit (critical data always fresh)
- Hospital directory: cache TTL 24 hours, background refresh
- First aid guides: cached indefinitely (offline-first)
- Emergency dispatch: real-time only, no caching

### Offline Support
- Read: Medical profile, first aid guides, hospital directory, emergency contacts
- Write: Medical profile edits queued if offline
- Sync: Medical profile is priority sync on reconnect

### Media Caching
- First aid illustrations: pre-cached on module first open
- Hospital photos: MediaCacheService (30-day TTL)
- BlurHash for hospital directory images

---

## 4. Backend Implementation

### Database Tables
```sql
CREATE TABLE medical_profiles (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) UNIQUE,
    blood_type VARCHAR(5),
    allergies JSONB DEFAULT '[]',
    conditions JSONB DEFAULT '[]',
    medications JSONB DEFAULT '[]',
    emergency_contacts JSONB DEFAULT '[]',
    insurance_info JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE emergencies (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    address TEXT,
    status VARCHAR(20) DEFAULT 'dispatched',
    ambulance_provider VARCHAR(100),
    hospital_id BIGINT,
    created_at TIMESTAMP DEFAULT NOW(),
    resolved_at TIMESTAMP
);

CREATE TABLE hospitals (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255),
    type VARCHAR(50),
    capabilities TEXT[],
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    phone VARCHAR(20),
    bed_count INTEGER,
    rating DECIMAL(3,2),
    created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | /api/ambulance/sos | Trigger emergency dispatch | Yes |
| GET | /api/ambulance/dispatch/{id} | Get dispatch status | Yes |
| GET | /api/ambulance/medical-profile | Get user medical profile | Yes |
| PUT | /api/ambulance/medical-profile | Update medical profile | Yes |
| GET | /api/ambulance/hospitals | List hospitals with filters | Yes |
| GET | /api/ambulance/first-aid | Get first aid guides | No |
| GET | /api/ambulance/history | Get emergency history | Yes |
| POST | /api/ambulance/responders | Register as responder | Yes |

### Controller
- File: `app/Http/Controllers/Api/AmbulanceController.php`
- Pattern: DB facade, try/catch, `{"success": true, "data": ...}` responses
- SOS endpoint must be fastest response — minimal validation, async dispatch

### Background Jobs
- Ambulance provider availability polling (every 60 seconds)
- Emergency contact SMS notification on SOS trigger
- Hospital bed availability sync (daily)

---

## 5. Integration Wiring

- **Wallet**: Ambulance service payments, subscription plans, post-service billing.
- **Messaging**: Two-way communication with ambulance crew during dispatch.
- **Profile**: Medical profile linked to TAJIRI profile with privacy controls.
- **Family**: Emergency contact auto-notification, family medical profiles.
- **Insurance**: NHIF verification, private insurance coverage check before dispatch.
- **Notifications**: Dispatch confirmation, ETA updates, arrival alerts, community responder alerts.
- **Location**: Core GPS for emergency location, hospital proximity, ambulance tracking.
- **Doctor**: Telemedicine while waiting for ambulance, first aid guidance.
- **Transport**: Non-emergency medical transport, post-discharge rides.

---

## 6. Implementation Phases

### Phase 1: Foundation (Week 1)
- [ ] Create directory structure and ambulance_module.dart
- [ ] Emergency, MedicalProfile, Hospital models with fromJson/toJson
- [ ] AmbulanceService with AuthenticatedDio
- [ ] Backend: migrations + SOS, medical profile, hospitals endpoints
- [ ] SQLite tables for medical profile and hospital cache

### Phase 2: Core UI (Week 2)
- [ ] Emergency Home with SOS button and medical profile summary
- [ ] Medical Profile Editor with all fields
- [ ] Hospital Directory with map/list views
- [ ] First Aid Guide with offline content
- [ ] Emergency History list

### Phase 3: Integration (Week 3)
- [ ] Wire to WalletService for payments
- [ ] Wire to MessageService for ambulance crew chat
- [ ] Wire to FCMService for dispatch notifications
- [ ] Wire to LocationService for GPS tracking
- [ ] Firestore listeners for real-time ambulance position

### Phase 4: Polish (Week 4)
- [ ] Offline first aid guide caching
- [ ] BlurHash for hospital photos
- [ ] Pull-to-refresh on hospital directory
- [ ] Empty states and error handling
- [ ] QR code medical ID generation
- [ ] Community responder registration

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| [Rescue.co / Flare](https://www.rescue.co/) | Rescue.co (Trek Medics) | Ambulance dispatch, GPS fleet tracking, clinical triage | Partnership / B2B | Operates in Kenya, Uganda, Tanzania. 800+ ambulance providers. Contact for API partnership |
| [Emergency Dispatch Africa](https://www.emergencydispatchafrica.com/) | Emergency Dispatch Africa | CAD (Computer-Aided Dispatch) for emergency services | B2B | Dispatch software with GPS tracking and priority-based routing |
| [Tanzania Health Facility Registry](https://hfrs.moh.go.tz/) | Tanzania Ministry of Health | Hospital/clinic database, facility locations, GPS coordinates | Free (government) | Master Facility List for all TZ health facilities. No REST API — may need scraping |
| [Google Maps Platform](https://developers.google.com/maps) | Google | Route optimization, ETA calculation, hospital search | Freemium (10K free/month) | Places API for nearby hospitals. Routes API for ambulance routing |
| [OpenRouteService](https://openrouteservice.org/) | HeiGIT | Isochrone maps (reachability areas), routing | Free / open source | Shows which areas an ambulance can reach in X minutes. Self-hostable via Docker |
| [Mapbox](https://docs.mapbox.com/) | Mapbox | Maps, directions, navigation SDK | Freemium (100K free directions/month) | Mobile Navigation SDK available. $2/1K directions after free tier |
| [M-Pesa Open API](https://openapiportal.m-pesa.com) | Vodacom Tanzania | Emergency service payments | Transaction fees | Dart SDK: `mpesa_sdk` on pub.dev |
| [AzamPay API](https://developers.azampay.co.tz/) | AzamPay (Bakhresa Group) | Payment gateway for ambulance fees | Transaction fees | Flutter SDK: `azampaytanzania` on pub.dev |
| [Africa's Talking](https://developers.africastalking.com/) | Africa's Talking | SMS/USSD for emergency dispatch alerts | Pay-as-you-go | Better TZ carrier coverage than Twilio. Supports all 3 major TZ telcos |
| [Twilio SMS/WhatsApp](https://www.twilio.com/en-us/sms/pricing/tz) | Twilio | SMS and WhatsApp emergency notifications | Pay-as-you-go | Tanzania SMS supported. WhatsApp 24hr service window free of Meta charges |
| [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging) | Google | Push notifications for emergency alerts | Free | Already integrated in TAJIRI app. Extend for ambulance alerts |
