# Tafuta Msikiti (Mosque Finder) — Implementation Plan

## Overview
Map-based mosque discovery for Tanzania with GPS search, Jumu'ah times, facilities filters, imam info, Islamic education listings, reviews, and directions. Helps Muslims find nearby mosques for daily prayers and Friday congregations.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/tafuta_msikiti/
├── tafuta_msikiti_module.dart
├── models/
│   ├── mosque_listing.dart
│   ├── mosque_review.dart
│   ├── mosque_facility.dart
│   ├── iqamah_time.dart
│   └── mosque_suggestion.dart
├── services/
│   └── mosque_finder_service.dart   — AuthenticatedDio.instance
├── pages/
│   ├── mosque_map_page.dart
│   ├── search_results_page.dart
│   ├── mosque_profile_page.dart
│   ├── facilities_view_page.dart
│   ├── directions_page.dart
│   ├── jumuah_finder_page.dart
│   ├── reviews_page.dart
│   ├── suggest_mosque_page.dart
│   └── favorites_page.dart
└── widgets/
    ├── mosque_map_pin.dart
    ├── mosque_result_card.dart
    ├── facility_icon_grid.dart
    ├── iqamah_time_row.dart
    ├── imam_info_card.dart
    └── rating_stars.dart
```

### Data Models
- **MosqueListing** — `id`, `name`, `address`, `lat`, `lng`, `distance`, `rating`, `reviewCount`, `photoUrl`, `imamName`, `denomination` (sunni/shia/ibadhi), `capacity`, `phone`, `facilities` (List), `hasWomenSection`, `hasParking`. `_parseDouble`, `_parseInt`, `_parseBool`.
- **MosqueReview** — `id`, `mosqueId`, `userId`, `userName`, `rating`, `text`, `createdAt`. `_parseDouble`, `_parseInt`.
- **IqamahTime** — `prayer`, `time`, `isEstimate`. `_parseBool`.
- **MosqueFacility** — `name`, `iconName`, `isAvailable`. `_parseBool`.
- **MosqueSuggestion** — `id`, `name`, `lat`, `lng`, `imamName`, `facilities`, `submittedBy`, `status`.

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
- `searchMosques({double lat, double lng, double radius, String? denomination})` — `GET /api/mosque-finder/search`
- `getMosqueProfile(int id)` — `GET /api/mosque-finder/{id}`
- `getIqamahTimes(int mosqueId)` — `GET /api/mosque-finder/{id}/iqamah`
- `getJumuahTimes({double lat, double lng})` — `GET /api/mosque-finder/jumuah`
- `getReviews(int mosqueId)` — `GET /api/mosque-finder/{id}/reviews`
- `writeReview(int mosqueId, Map data)` — `POST /api/mosque-finder/{id}/reviews`
- `suggestMosque(Map data)` — `POST /api/mosque-finder/suggest`
- `saveFavorite(int mosqueId)` — `POST /api/mosque-finder/{id}/favorite`
- `getAnnouncements(int mosqueId)` — `GET /api/mosque-finder/{id}/announcements`

### Pages
- **MosqueMapPage** — Map with mosque pins, search bar, distance radius selector
- **SearchResultsPage** — Mosque cards with photo, name, distance, next prayer
- **MosqueProfilePage** — Hero image, info sections (about, prayers, facilities, events, reviews)
- **FacilitiesViewPage** — Icon grid showing available amenities
- **DirectionsPage** — Route with estimated walking/driving time
- **JumuahFinderPage** — Specialized Friday prayer view with khutbah times
- **ReviewsPage** — Community reviews with facility ratings
- **SuggestMosquePage** — Submit unlisted mosque with details
- **FavoritesPage** — Saved mosques with quick prayer times

### Widgets
- `MosqueMapPin` — Custom marker with crescent icon
- `FacilityIconGrid` — Grid of amenity icons (wudhu, parking, women, AC, etc.)

---

## 2. UI Design
- #1A1A1A/#666666/#FAFAFA/#FFFFFF monochromatic
- 48dp touch, maxLines+ellipsis, _rounded icons
- Dark stat cards for nearby mosque count
- Cards: radius 12-16, subtle shadow

### Main Screen Wireframe
```
┌─────────────────────────────┐
│  🔍 Search mosques...       │
│ [Nearest][Jumu'ah][Filter▼] │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │                         │ │
│ │      [  MAP VIEW  ]     │ │
│ │   🕌   🕌      🕌       │ │
│ │       🕌    🕌           │ │
│ │                         │ │
│ └─────────────────────────┘ │
│                             │
│  Nearby Mosques (8)         │
│ ┌─────────────────────────┐ │
│ │ [📷] Msikiti Mbagala    │ │
│ │ Sunni • 0.3 km          │ │
│ │ ★★★★★ (18)  Next: Asr  │ │
│ ├─────────────────────────┤ │
│ │ [📷] Masjid al-Qadiriyya│ │
│ │ Sunni • 0.8 km          │ │
│ │ ★★★★☆ (31) Jumu'ah 1PM │ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE mosque_listings(id INTEGER PRIMARY KEY, name TEXT, lat REAL, lng REAL, rating REAL, denomination TEXT, json_data TEXT, synced_at TEXT);
CREATE TABLE mosque_favorites(id INTEGER PRIMARY KEY, mosque_id INTEGER, user_id INTEGER, synced_at TEXT);
CREATE INDEX idx_mosque_location ON mosque_listings(lat, lng);
```
- Stale-while-revalidate: SQLite first, API background
- TTL: search results — 1 hour, mosque profile — 6 hours
- Offline: read cached results YES, write reviews via pending_queue

---

## 4. Backend Implementation

### Database
```sql
CREATE TABLE mosque_listings(id BIGSERIAL PRIMARY KEY, name VARCHAR(200), address TEXT, lat DOUBLE PRECISION, lng DOUBLE PRECISION, imam_name VARCHAR(200), denomination VARCHAR(30) DEFAULT 'sunni', capacity INTEGER, phone VARCHAR(20), photo_url VARCHAR(500), rating DOUBLE PRECISION DEFAULT 0, review_count INTEGER DEFAULT 0, has_women_section BOOLEAN DEFAULT FALSE, has_parking BOOLEAN DEFAULT FALSE, has_wudhu BOOLEAN DEFAULT TRUE, has_ac BOOLEAN DEFAULT FALSE, has_wheelchair BOOLEAN DEFAULT FALSE, created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE mosque_iqamah_times(id BIGSERIAL PRIMARY KEY, mosque_id BIGINT, prayer VARCHAR(10), iqamah_time TIME, is_estimate BOOLEAN DEFAULT FALSE);

CREATE TABLE mosque_jumuah(id BIGSERIAL PRIMARY KEY, mosque_id BIGINT, khutbah_time TIME, prayer_time TIME, language VARCHAR(30) DEFAULT 'swahili');

CREATE TABLE mosque_reviews(id BIGSERIAL PRIMARY KEY, mosque_id BIGINT, user_id BIGINT, rating DOUBLE PRECISION, text TEXT, created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE mosque_favorites(id BIGSERIAL PRIMARY KEY, mosque_id BIGINT, user_id BIGINT, created_at TIMESTAMP DEFAULT NOW(), UNIQUE(mosque_id, user_id));

CREATE TABLE mosque_suggestions(id BIGSERIAL PRIMARY KEY, name VARCHAR(200), lat DOUBLE PRECISION, lng DOUBLE PRECISION, imam_name VARCHAR(200), facilities JSONB, submitted_by BIGINT, status VARCHAR(20) DEFAULT 'pending', created_at TIMESTAMP DEFAULT NOW());
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/mosque-finder/search | Search with GPS | Bearer |
| GET | /api/mosque-finder/{id} | Mosque profile | Bearer |
| GET | /api/mosque-finder/{id}/iqamah | Iqamah times | Bearer |
| GET | /api/mosque-finder/jumuah | Jumu'ah finder | Bearer |
| GET | /api/mosque-finder/{id}/reviews | Reviews | Bearer |
| POST | /api/mosque-finder/{id}/reviews | Write review | Bearer |
| POST | /api/mosque-finder/suggest | Suggest mosque | Bearer |
| POST | /api/mosque-finder/{id}/favorite | Save favorite | Bearer |
| GET | /api/mosque-finder/{id}/announcements | Announcements | Bearer |

### Controller
`app/Http/Controllers/Api/MosqueFinderController.php` — DB facade with Haversine proximity search and rating aggregation.

---

## 5. Integration Wiring
- **LocationService** — GPS-based search, region/district filtering
- **ProfileService** — home mosque selection, denomination matching
- **MessageService** — contact mosque directly
- **PostService** — location check-in posts
- **NotificationService** — mosque announcements, Jumu'ah reminders
- **Wakati wa Sala** — mosque iqamah times linked from prayer screen
- **Qibla** — direction relative to nearest mosques
- **Ramadan** — Taraweeh and iftar locations
- **Zaka** — mosques accepting Zakat identified
- **Maulid** — mosques hosting Maulid events

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema
- Backend tables with Haversine search
- Map-based search page

### Phase 2: Core UI (Week 2)
- Search results with facility filters
- Mosque profile with tabs
- Directions integration

### Phase 3: Integration (Week 3)
- Jumu'ah finder with khutbah times
- Iqamah times display
- Reviews and ratings

### Phase 4: Polish (Week 4)
- Suggest a mosque flow
- Favorites and announcements
- Offline cached results, cross-module links

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| MasjidNear.me API | MasjidNear.me | Search mosques by city/location | Free | REST GET; JSON; api.masjidnear.me/v1/masjids/search |
| Google Places API | Google | Search for mosques by location, details, photos | Freemium (10k free/month) | type=mosque; full place details; developers.google.com/maps |
| OpenStreetMap Overpass | OpenStreetMap | Query mosques from OSM database | Free, open source | amenity=place_of_worship + religion=muslim; global coverage |
| IslamicFinder Places | IslamicFinder | Islamic places directory including mosques | Free (limited) | islamicfinder.org/places; location-based search |
| ConnectMazjid | ConnectMazjid | Masjid locator with prayer times | Free | connectmazjid.com; global coverage |

### Integration Priority
1. **Immediate** — Free APIs (MasjidNear.me -- free, mosque-specific; OpenStreetMap for global coverage)
2. **Short-term** — Freemium APIs (Google Places for rich details, photos, reviews)
3. **Partnership** — ConnectMazjid, IslamicFinder (extended mosque data)
