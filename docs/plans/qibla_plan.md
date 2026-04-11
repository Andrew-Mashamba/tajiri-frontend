# Qibla (Qibla Compass) — Implementation Plan

## Overview
Reliable offline Qibla direction compass for Tanzanian Muslims using GPS and magnetometer. Features digital compass, AR overlay, map view, calibration guide, and vibration feedback when aligned with Makkah.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/qibla/
├── qibla_module.dart
├── models/
│   ├── qibla_direction.dart
│   └── compass_calibration.dart
├── services/
│   └── qibla_service.dart           — local calculation (no API needed)
├── pages/
│   ├── compass_page.dart
│   ├── ar_view_page.dart
│   ├── map_view_page.dart
│   ├── calibration_page.dart
│   └── qibla_settings_page.dart
└── widgets/
    ├── compass_needle.dart
    ├── accuracy_indicator.dart
    ├── degree_display.dart
    ├── distance_display.dart
    └── lock_direction_button.dart
```

### Data Models
- **QiblaDirection** — `bearing`, `distance` (km to Makkah), `currentLat`, `currentLng`, `magneticDeclination`, `accuracy` (high/medium/low). `_parseDouble`.
- **CompassCalibration** — `isCalibrated`, `accuracy`, `lastCalibrated`. `_parseBool`.

### Service Layer
```dart
// Local calculation — no AuthenticatedDio needed
```
- `calculateQibla(double lat, double lng)` — Great circle bearing calculation (local, offline)
- `getDistance(double lat, double lng)` — Haversine distance to Kaaba (21.4225, 39.8262)
- `getMagneticDeclination(double lat, double lng)` — WMM model for true north correction
- Compass data from `flutter_compass` package stream

### Pages
- **CompassPage** — Large compass with Qibla needle, accuracy indicator, degree readout
- **ARViewPage** — Camera feed with Qibla direction arrow and distance overlay
- **MapViewPage** — Map showing current position, Kaaba, and great circle line
- **CalibrationPage** — Animated figure-8 calibration instructions
- **QiblaSettingsPage** — Calculation method, vibration toggle, sound toggle, manual location

### Widgets
- `CompassNeedle` — Animated rotating needle pointing to Qibla
- `AccuracyIndicator` — Green/yellow/red dot showing calibration quality
- `LockDirectionButton` — Freeze compass for placing prayer mat

---

## 2. UI Design
- #1A1A1A/#666666/#FAFAFA/#FFFFFF monochromatic
- 48dp touch, maxLines+ellipsis, _rounded icons
- Dark stat card for bearing angle and distance
- Cards: radius 12-16, subtle shadow

### Main Screen Wireframe
```
┌─────────────────────────────┐
│ ← Qibla                ⚙️   │
├─────────────────────────────┤
│                             │
│         N                   │
│       ╱   ╲                 │
│     ╱  🕋   ╲  ← Qibla     │
│   W ┤       ├ E             │
│     ╲       ╱               │
│       ╲   ╱                 │
│         S                   │
│                             │
│     Bearing: 7.3° NNE       │
│     Distance: 5,842 km      │
│     Accuracy: 🟢 High       │
│                             │
│  [🔒 Lock] [📷 AR] [🗺 Map] │
│                             │
│  [Calibrate Compass]        │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE qibla_cache(id INTEGER PRIMARY KEY, lat REAL, lng REAL, bearing REAL, distance REAL, declination REAL, calculated_at TEXT);
```
- No API dependency — all calculations are local
- TTL: cached calculations — 24 hours per location
- Offline: full functionality (GPS + magnetometer only)

---

## 4. Backend Implementation

### Database
```sql
CREATE TABLE qibla_usage_stats(id BIGSERIAL PRIMARY KEY, user_id BIGINT, lat DOUBLE PRECISION, lng DOUBLE PRECISION, bearing DOUBLE PRECISION, used_at TIMESTAMP DEFAULT NOW());
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | /api/qibla/log-usage | Log usage analytics | Bearer |
| GET | /api/qibla/declination | Magnetic declination | Public |

### Controller
`app/Http/Controllers/Api/QiblaController.php` — Minimal; most logic is client-side. Only analytics logging.

---

## 5. Integration Wiring
- **LocationService** — GPS for current position; auto-recalculate on location change
- **Wakati wa Sala** — mini compass widget on prayer times screen
- **Tafuta Msikiti** — Qibla direction relative to nearest mosques
- **Ramadan** — quick access during Taraweeh prayers
- **travel** — auto-recalculate when traveling within Tanzania
- Full offline capability — critical for rural Tanzania

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Great circle bearing calculation algorithm
- Magnetometer stream integration (flutter_compass)
- Compass UI with animated needle

### Phase 2: Core UI (Week 2)
- Accuracy indicator and calibration page
- Degree display and distance to Makkah
- Lock direction feature

### Phase 3: Integration (Week 3)
- AR camera overlay with direction arrow
- Map view with great circle line
- Vibration feedback on alignment

### Phase 4: Polish (Week 4)
- Night mode, sound notification
- Manual location entry fallback
- Magnetic declination compensation

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Aladhan Qibla API | Islamic Network | Qibla direction from any coordinates | Free, no auth | GET /v1/qibla/{lat}/{lng}; returns direction in degrees |
| Device Compass API | Flutter | Device compass heading for Qibla overlay | Free (Flutter plugin) | `flutter_compass` package on pub.dev |
| Custom Calculation | Local | Calculate Qibla from coordinates using great circle | Free | Formula: atan2(sin(dLng), cos(lat)*tan(Kaaba_lat) - sin(lat)*cos(dLng)) |

### Flutter Packages
- `flutter_compass` — Device compass heading for Qibla overlay
- `aladhan_prayer_times` — Includes Qibla direction endpoint

### Integration Priority
1. **Immediate** — Free APIs (Aladhan Qibla API -- no auth, single endpoint, instant integration)
2. **Short-term** — Flutter packages (flutter_compass for device compass overlay)
3. **Partnership** — None needed; Qibla is fully served by free APIs + local calculation
