# Tafuta Kanisa (Church Finder) — Implementation Plan

## Overview
Map-based church discovery for Tanzania with denomination filters, service times, language preferences, reviews, directions, and the ability to join churches directly. Solves the problem of finding a church home after relocation.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/tafuta_kanisa/
├── tafuta_kanisa_module.dart
├── models/
│   ├── church_listing.dart
│   ├── church_review.dart
│   ├── service_time.dart
│   └── church_suggestion.dart
├── services/
│   └── church_finder_service.dart   — AuthenticatedDio.instance
├── pages/
│   ├── search_map_page.dart
│   ├── search_results_page.dart
│   ├── church_profile_page.dart
│   ├── filter_panel_page.dart
│   ├── directions_page.dart
│   ├── reviews_page.dart
│   ├── write_review_page.dart
│   └── suggest_church_page.dart
└── widgets/
    ├── church_map_pin.dart
    ├── church_result_card.dart
    ├── denomination_filter.dart
    ├── rating_stars.dart
    ├── service_time_chip.dart
    └── ministry_badge.dart
```

### Data Models
- **ChurchListing** — `id`, `name`, `denomination`, `address`, `lat`, `lng`, `distance`, `rating`, `reviewCount`, `photoUrl`, `serviceTimes` (List), `ministries` (List), `languages` (List), `pastorName`, `phone`. `_parseDouble`, `_parseInt`.
- **ChurchReview** — `id`, `churchId`, `userId`, `userName`, `rating`, `text`, `visitDate`, `helpfulCount`, `createdAt`. `_parseInt`, `_parseDouble`.
- **ServiceTime** — `dayOfWeek`, `startTime`, `label`, `style` (traditional/contemporary/charismatic).
- **ChurchSuggestion** — `id`, `name`, `denomination`, `lat`, `lng`, `serviceTimes`, `contact`, `submittedBy`.

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
- `searchChurches({double lat, double lng, double radius, String? denomination, String? language})` — `GET /api/church-finder/search`
- `getChurchProfile(int id)` — `GET /api/church-finder/{id}`
- `getReviews(int churchId)` — `GET /api/church-finder/{id}/reviews`
- `writeReview(int churchId, Map data)` — `POST /api/church-finder/{id}/reviews`
- `suggestChurch(Map data)` — `POST /api/church-finder/suggest`
- `saveFavorite(int churchId)` — `POST /api/church-finder/{id}/favorite`
- `getDirections(int churchId)` — `GET /api/church-finder/{id}/directions`

### Pages
- **SearchMapPage** — Map with church pins, search bar, filter chips at top
- **SearchResultsPage** — Church cards with photo, name, denomination, distance, rating
- **ChurchProfilePage** — Hero image, info tabs (about, services, events, reviews, photos)
- **FilterPanelPage** — Denomination checkboxes, service time, language, ministries
- **DirectionsPage** — Map route from current location to church
- **ReviewsPage** — Star rating breakdown, review list with helpful votes
- **WriteReviewPage** — Rating selector, text review, visit verification
- **SuggestChurchPage** — Name, denomination, location pin, service times, contact

### Widgets
- `ChurchMapPin` — Custom map marker with denomination icon
- `RatingStars` — 5-star display with half-star support

---

## 2. UI Design
- #1A1A1A/#666666/#FAFAFA/#FFFFFF monochromatic
- 48dp touch, maxLines+ellipsis, _rounded icons
- Dark stat cards for search results count
- Cards: radius 12-16, subtle shadow

### Main Screen Wireframe
```
┌─────────────────────────────┐
│  🔍 Search churches...      │
│ [Catholic][Lutheran][All ▼] │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │                         │ │
│ │      [  MAP VIEW  ]     │ │
│ │    📍  📍     📍        │ │
│ │        📍   📍          │ │
│ │                         │ │
│ └─────────────────────────┘ │
│                             │
│  Nearby Churches (12)       │
│ ┌─────────────────────────┐ │
│ │ [📷] ELCT Moshi         │ │
│ │ Lutheran • 0.5 km       │ │
│ │ ★★★★☆ (24) Sun 9AM     │ │
│ ├─────────────────────────┤ │
│ │ [📷] St. Joseph Catholic│ │
│ │ Catholic • 1.2 km       │ │
│ │ ★★★★★ (42) Sun 7,9,11  │ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE church_listings(id INTEGER PRIMARY KEY, name TEXT, denomination TEXT, lat REAL, lng REAL, rating REAL, json_data TEXT, synced_at TEXT);
CREATE TABLE church_favorites(id INTEGER PRIMARY KEY, church_id INTEGER, user_id INTEGER, synced_at TEXT);
CREATE INDEX idx_church_location ON church_listings(lat, lng);
```
- Stale-while-revalidate: SQLite first, API background
- TTL: search results — 1 hour, church profile — 6 hours
- Offline: read cached results YES, write reviews via pending_queue

---

## 4. Backend Implementation

### Database
```sql
CREATE TABLE church_listings(id BIGSERIAL PRIMARY KEY, name VARCHAR(200), denomination VARCHAR(100), address TEXT, lat DOUBLE PRECISION, lng DOUBLE PRECISION, pastor_name VARCHAR(200), phone VARCHAR(20), photo_url VARCHAR(500), rating DOUBLE PRECISION DEFAULT 0, review_count INTEGER DEFAULT 0, languages JSONB, ministries JSONB, service_style VARCHAR(30), visitor_info TEXT, created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE church_service_times_listing(id BIGSERIAL PRIMARY KEY, church_id BIGINT, day_of_week INTEGER, start_time TIME, label VARCHAR(100), style VARCHAR(30));

CREATE TABLE church_reviews(id BIGSERIAL PRIMARY KEY, church_id BIGINT, user_id BIGINT, rating DOUBLE PRECISION, text TEXT, visit_date DATE, helpful_count INTEGER DEFAULT 0, created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE church_favorites(id BIGSERIAL PRIMARY KEY, church_id BIGINT, user_id BIGINT, created_at TIMESTAMP DEFAULT NOW(), UNIQUE(church_id, user_id));

CREATE TABLE church_suggestions(id BIGSERIAL PRIMARY KEY, name VARCHAR(200), denomination VARCHAR(100), lat DOUBLE PRECISION, lng DOUBLE PRECISION, service_times TEXT, contact VARCHAR(100), submitted_by BIGINT, status VARCHAR(20) DEFAULT 'pending', created_at TIMESTAMP DEFAULT NOW());
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/church-finder/search | Search with filters | Bearer |
| GET | /api/church-finder/{id} | Church profile | Bearer |
| GET | /api/church-finder/{id}/reviews | Reviews list | Bearer |
| POST | /api/church-finder/{id}/reviews | Write review | Bearer |
| POST | /api/church-finder/suggest | Suggest new church | Bearer |
| POST | /api/church-finder/{id}/favorite | Save favorite | Bearer |
| GET | /api/church-finder/{id}/directions | Get directions | Bearer |

### Controller
`app/Http/Controllers/Api/ChurchFinderController.php` — DB facade with Haversine proximity search and rating aggregation.

---

## 5. Integration Wiring
- **LocationService** — GPS-based nearby search, region/district filtering
- **ProfileService** — denomination pre-filters from faith profile
- **GroupService** — "Join" connects to Kanisa Langu module
- **MessageService** — contact church directly
- **PostService** — check-in posts, church recommendation posts
- **Kanisa Langu** — discovery leads to full church profile
- **Fungu la Kumi** — church M-Pesa details for giving

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema
- Backend tables with Haversine search
- Map-based search page

### Phase 2: Core UI (Week 2)
- Search results with denomination filters
- Church profile with tabs
- Directions integration

### Phase 3: Integration (Week 3)
- Reviews and ratings system
- Favorite churches
- Suggest a church flow

### Phase 4: Polish (Week 4)
- Service time and language filters
- Recently added churches feed
- Offline cached results, cross-module links

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Google Places API (New) | Google | Search churches by location, details, reviews, photos | Freemium (10k free/month) | type=church; place details, hours; developers.google.com/maps |
| OpenStreetMap Overpass API | OpenStreetMap | Query churches/religious buildings from OSM | Free, open source | amenity=place_of_worship; global coverage; unlimited |
| Foursquare Places API | Foursquare | Venue discovery including churches | Freemium (10k/month free) | Category filter for religious places; foursquare.com/developer |
| MonkCMS Churches API | MonkCMS | Church directory search by zip/city with radius | Free (with account) | US-focused church directory |

### Integration Priority
1. **Immediate** — Free APIs (OpenStreetMap Overpass for church locations, no auth needed)
2. **Short-term** — Freemium APIs (Google Places for rich details/photos, Foursquare)
3. **Partnership** — MonkCMS, ChurchTools Finder (region-specific directories)
