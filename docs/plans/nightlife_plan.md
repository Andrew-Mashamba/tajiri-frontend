# Nightlife (Burudani ya Usiku) — Implementation Plan

## Overview

Nightlife is a discovery and booking platform for Tanzania's club, bar, and lounge scene. It covers venue discovery with profiles and reviews, tonight's events with DJ lineups, table reservations with minimum spend info, guest list signups, group planning with friends, drink menus and happy hour listings, and safety features including live location sharing and ride-hailing integration. The module targets Dar es Salaam, Arusha, and Zanzibar's vibrant nightlife culture driven by bongo flava and amapiano.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/nightlife/
├── nightlife_module.dart              — Entry point & route registration
├── models/
│   ├── venue_models.dart              — Venue, VenueType, OperatingHours
│   ├── event_models.dart              — NightEvent, DJLineup, GuestList
│   ├── reservation_models.dart        — TableReservation, TableType
│   └── group_plan_models.dart         — GroupPlan, PlanMember, VenueVote
├── services/
│   └── nightlife_service.dart         — API service using AuthenticatedDio
├── pages/
│   ├── tonight_page.dart              — Curated tonight events
│   ├── venue_directory_page.dart      — Map + list with filters
│   ├── venue_profile_page.dart        — Gallery, events, reviews, reserve
│   ├── event_detail_page.dart         — Lineup, cover, dress code, RSVP
│   ├── dj_profile_page.dart           — Bio, gigs, music links
│   ├── group_plan_page.dart           — Plan tonight, invite, vote
│   ├── table_reservation_page.dart    — Date, table type, party size
│   ├── reviews_page.dart              — Venue reviews with breakdown
│   ├── my_nightlife_page.dart         — Saved venues, reservations
│   └── safety_hub_page.dart           — Share location, ride home
└── widgets/
    ├── venue_card_widget.dart          — Photo, name, genre, tonight's event
    ├── tonight_event_widget.dart       — DJ photo, time, venue, cover charge
    ├── group_plan_widget.dart          — Friends avatars, venue vote results
    ├── genre_chip_widget.dart          — Bongo flava, amapiano, etc.
    └── safety_status_widget.dart       — Location sharing indicator
```

### Data Models
- **Venue**: id, name, type (club/bar/lounge/rooftop/beach_bar), location, photos[], genres[], dressCode, operatingHours, coverCharge, rating, reviewCount, capacity, drinkMenu[], happyHour. `factory Venue.fromJson()`.
- **NightEvent**: id, venueId, title, date, time, djLineup[], coverCharge, guestListOpen, dressCode, description, photos[]. `factory NightEvent.fromJson()`.
- **TableReservation**: id, venueId, date, tableType, partySize, minimumSpend, status, confirmationCode. `factory TableReservation.fromJson()`.
- **GroupPlan**: id, creatorId, title, date, members[], venueVotes[], selectedVenueId, status. `factory GroupPlan.fromJson()`.

### Service Layer
- `getTonightEvents({String? city})` — GET `/api/nightlife/tonight`
- `searchVenues(Map filters)` — GET `/api/nightlife/venues`
- `getVenue(int id)` — GET `/api/nightlife/venues/{id}`
- `getEvent(int id)` — GET `/api/nightlife/events/{id}`
- `joinGuestList(int eventId)` — POST `/api/nightlife/events/{id}/guestlist`
- `reserveTable(int venueId, Map data)` — POST `/api/nightlife/reservations`
- `createGroupPlan(Map data)` — POST `/api/nightlife/group-plans`
- `voteVenue(int planId, int venueId)` — POST `/api/nightlife/group-plans/{id}/vote`
- `submitReview(int venueId, Map review)` — POST `/api/nightlife/reviews`
- `getDJProfile(int id)` — GET `/api/nightlife/djs/{id}`

### Pages & Screens
- **Tonight**: Curated event cards sorted by proximity/popularity, "Happening Now" section, genre filter tabs.
- **Venue Directory**: Map with venue pins + list. Filter by type, genre, happy hour, cover charge.
- **Venue Profile**: Photo gallery header, tonight's event, upcoming events, reviews, reserve/guest list buttons.
- **Group Plan**: Create plan, invite friends, venue suggestions, voting, final selection, share status.
- **Safety Hub**: Share location toggle, emergency contacts, "Request Ride Home" button.

### Widgets
- `VenueCardWidget` — Photo, name, genre chips, tonight's event teaser
- `TonightEventWidget` — DJ photo, event name, venue, time, cover charge
- `GroupPlanWidget` — Friend avatars, venue vote progress bars
- `GenreChipWidget` — Colored chip: bongo flava, amapiano, afrobeats, live band
- `SafetyStatusWidget` — Shield icon with "Sharing location with 3 contacts"

---

## 2. UI Design

- Tonight screen: Dark theme accent for nightlife vibe
- Venue cards: Photo-forward with gradient text overlay
- Genre chips: Each genre has a subtle color accent
- Safety: Green indicator when location sharing is active

### Key Screen Mockup — Tonight
```
┌─────────────────────────────┐
│  SafeArea                   │
│  Tonight in Dar es Salaam   │
│  [All][BongoFlava][Amapiano]│
│  ── Happening Now ────────  │
│  ┌───────────────────────┐  │
│  │[Photo: Slow Leopard]  │  │
│  │ DJ Spinall Live       │  │
│  │ 10pm - 4am  Free entry│  │
│  └───────────────────────┘  │
│  ── Tonight ──────────────  │
│  ┌───────────────────────┐  │
│  │[Photo: Elements]      │  │
│  │ Amapiano Saturdays    │  │
│  │ 9pm  Cover: 20K TZS   │  │
│  └───────────────────────┘  │
│  ── Happy Hour ───────────  │
│  [Venue] 5-8pm 2-for-1     │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### Local-First with SQLite
```dart
// Table: nightlife_venues
// Columns: id INTEGER PRIMARY KEY, name TEXT, type TEXT, lat REAL, lng REAL, json_data TEXT, synced_at TEXT
// Indexes: type, name
// Table: nightlife_events
// Columns: id INTEGER PRIMARY KEY, venue_id INTEGER, event_date TEXT, json_data TEXT, synced_at TEXT
// Indexes: event_date, venue_id
```

### Stale-While-Revalidate
- Tonight events: cache TTL 30 minutes (dynamic)
- Venue directory: cache TTL 24 hours
- Venue details: cache TTL 1 hour
- Group plans: real-time (Firestore)

### Offline Support
- Read: Venue directory, saved venues, past reservations
- Write: Reviews queued offline, group plan votes queued
- Sync: Tonight events require connectivity

### Media Caching
- Venue photos: MediaCacheService (14-day TTL)
- DJ photos: 14-day TTL
- Event flyer images: 3-day TTL (short-lived)

---

## 4. Backend Implementation

### Database Tables
```sql
CREATE TABLE nightlife_venues (
    id BIGSERIAL PRIMARY KEY,
    owner_user_id BIGINT REFERENCES users(id),
    name VARCHAR(255),
    type VARCHAR(30),
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    address TEXT,
    city VARCHAR(100),
    genres TEXT[],
    dress_code TEXT,
    operating_hours JSONB,
    cover_charge DECIMAL(10,2),
    capacity INTEGER,
    photos JSONB DEFAULT '[]',
    drink_menu JSONB DEFAULT '[]',
    happy_hour JSONB,
    rating DECIMAL(3,2) DEFAULT 0,
    review_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE nightlife_events (
    id BIGSERIAL PRIMARY KEY,
    venue_id BIGINT REFERENCES nightlife_venues(id),
    title VARCHAR(255),
    event_date DATE,
    start_time TIME,
    end_time TIME,
    dj_lineup JSONB DEFAULT '[]',
    cover_charge DECIMAL(10,2),
    guest_list_open BOOLEAN DEFAULT FALSE,
    dress_code TEXT,
    description TEXT,
    photos JSONB DEFAULT '[]',
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE table_reservations (
    id BIGSERIAL PRIMARY KEY,
    venue_id BIGINT REFERENCES nightlife_venues(id),
    user_id BIGINT REFERENCES users(id),
    reservation_date DATE,
    table_type VARCHAR(30),
    party_size INTEGER,
    minimum_spend DECIMAL(12,2),
    status VARCHAR(20) DEFAULT 'pending',
    confirmation_code VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE group_plans (
    id BIGSERIAL PRIMARY KEY,
    creator_id BIGINT REFERENCES users(id),
    title VARCHAR(255),
    plan_date DATE,
    members JSONB DEFAULT '[]',
    venue_votes JSONB DEFAULT '{}',
    selected_venue_id BIGINT,
    status VARCHAR(20) DEFAULT 'planning',
    created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/nightlife/tonight | Tonight's events | Yes |
| GET | /api/nightlife/venues | Search venues | Yes |
| GET | /api/nightlife/venues/{id} | Venue profile | Yes |
| GET | /api/nightlife/events/{id} | Event detail | Yes |
| POST | /api/nightlife/events/{id}/guestlist | Join guest list | Yes |
| POST | /api/nightlife/reservations | Reserve table | Yes |
| POST | /api/nightlife/group-plans | Create group plan | Yes |
| POST | /api/nightlife/group-plans/{id}/vote | Vote for venue | Yes |
| POST | /api/nightlife/reviews | Submit review | Yes |
| GET | /api/nightlife/djs/{id} | DJ profile | Yes |

### Controller
- File: `app/Http/Controllers/Api/NightlifeController.php`
- Pattern: DB facade, try/catch, `{"success": true, "data": ...}` responses

### Background Jobs
- Tonight events curation (daily at 4pm)
- Happy hour status toggle (based on operating hours)
- Reservation confirmation notification
- "Are you home safe?" check-in notification (3am)

---

## 5. Integration Wiring

- **Wallet**: Cover charges, table deposits, drink tabs, event tickets.
- **Events**: Nightlife events appear in TAJIRI events calendar.
- **Posts & Stories**: Going out posts, venue check-ins, event reviews.
- **Messaging**: Group plan coordination chats.
- **Transport**: "Request ride home" integrates with transport module.
- **Music**: DJ playlists and music samples linked from artist profiles.
- **My Circle**: See which friends are going out tonight.
- **Notifications**: Event reminders, guest list confirmations, safety check-ins.
- **Location**: Venue map, GPS check-in, live location sharing.
- **Clips**: Short event atmosphere clips shared to feed.

---

## 6. Implementation Phases

### Phase 1: Foundation (Week 1)
- [ ] Create directory structure and nightlife_module.dart
- [ ] Venue, NightEvent, TableReservation, GroupPlan models
- [ ] NightlifeService with AuthenticatedDio
- [ ] Backend: migrations + venues CRUD + events endpoints
- [ ] SQLite tables for venues and events

### Phase 2: Core UI (Week 2)
- [ ] Tonight page with curated events
- [ ] Venue Directory with map + list
- [ ] Venue Profile with gallery and events
- [ ] Event Detail with lineup and RSVP
- [ ] Table Reservation flow

### Phase 3: Integration (Week 3)
- [ ] Wire to WalletService for payments
- [ ] Wire to Events module for calendar
- [ ] Wire to MessageService for group plans
- [ ] Wire to NotificationService for reminders
- [ ] Wire to LocationService for venue finder

### Phase 4: Polish (Week 4)
- [ ] Group Plan with venue voting
- [ ] Safety Hub with location sharing
- [ ] DJ/Artist profiles
- [ ] Reviews with atmosphere/music/service breakdown
- [ ] Happy hour listings
- [ ] Offline venue directory

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| [Google Maps Platform](https://developers.google.com/maps) | Google | Venue discovery, directions, place details | Freemium (10K free/month) | Places API for finding nearby clubs/bars. Routes API for directions |
| [Mapbox](https://docs.mapbox.com/) | Mapbox | Maps, venue location display | Freemium (100K free directions/month) | Good alternative to Google Maps with generous free tier |
| [M-Pesa Open API](https://openapiportal.m-pesa.com) | Vodacom Tanzania | Ticket purchases, table reservations | Transaction fees | Dart SDK: `mpesa_sdk` on pub.dev |
| [AzamPay API](https://developers.azampay.co.tz/) | AzamPay (Bakhresa Group) | Payment gateway for event tickets | Transaction fees | Flutter SDK: `azampaytanzania` on pub.dev |
| [ClickPesa API](https://docs.clickpesa.com/) | ClickPesa | Unified payment collection | Transaction fees | Aggregates M-Pesa, Tigo Pesa, Airtel Money, HaloPesa |
| [Africa's Talking](https://developers.africastalking.com/) | Africa's Talking | SMS event invites, venue promotions | Pay-as-you-go | Supports Vodacom, Tigo, Airtel in TZ |
| [Twilio SMS/WhatsApp](https://www.twilio.com/en-us/sms/pricing/tz) | Twilio | WhatsApp group plan coordination | Pay-as-you-go | WhatsApp 24hr service window free of Meta charges |
| [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging) | Google | Event notifications, happy hour alerts | Free | Already integrated in TAJIRI app |
