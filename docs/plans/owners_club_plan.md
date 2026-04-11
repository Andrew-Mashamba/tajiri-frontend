# Owners Club — Implementation Plan

## Overview

Owners Club brings Tanzania's vibrant but informal WhatsApp-based car enthusiast communities onto a structured platform. Users join brand-specific communities (Toyota Club, BMW Club, Subaru Club) and model-specific sub-groups, participate in community feeds with searchable knowledge bases, showcase their vehicles with modification logs, organize meetups and group drives, and access expert mechanic advice. It replaces fragmented WhatsApp groups with persistent, searchable, and moderated communities.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/owners_club/
├── owners_club_module.dart            — Entry point & route registration
├── models/
│   ├── community_models.dart          — Community, CommunityType, Role
│   ├── showcase_models.dart           — VehicleShowcase, Modification, Trip
│   ├── knowledge_models.dart          — KnowledgePost, Solution, FAQ
│   └── event_models.dart              — CommunityEvent, EventType, RSVP
├── services/
│   └── owners_club_service.dart       — API service using AuthenticatedDio
├── pages/
│   ├── community_home_page.dart       — Joined + recommended communities
│   ├── community_feed_page.dart       — Posts, discussions, photos
│   ├── vehicle_showcase_page.dart     — Member car profiles + gallery
│   ├── knowledge_base_page.dart       — Searchable tips and solutions
│   ├── community_events_page.dart     — Calendar with meetups/drives
│   ├── ask_community_page.dart        — Q&A with solution marking
│   ├── member_directory_page.dart     — Members with roles/expertise
│   └── community_marketplace_page.dart — Buy/sell within community
└── widgets/
    ├── community_card_widget.dart      — Brand logo, member count, badge
    ├── showcase_card_widget.dart       — Vehicle photo, specs, mod count
    ├── expert_badge_widget.dart        — Verified mechanic/enthusiast badge
    ├── milestone_widget.dart           — Mileage achievement celebration
    └── event_card_widget.dart          — Event with date, RSVP count
```

### Data Models
- **Community**: id, name, brand, model, type (brand/model/regional), description, memberCount, logo, rules, isJoined, role, createdAt. `factory Community.fromJson()`.
- **VehicleShowcase**: id, userId, vehicleId, photos[], specs, story, modifications[], trips[], milestones[], communityVotes. `factory VehicleShowcase.fromJson()`.
- **KnowledgePost**: id, communityId, authorId, title, content, tags[], solutionMarked, isPinned, upvotes, replies. `factory KnowledgePost.fromJson()`.
- **CommunityEvent**: id, communityId, title, type (meetup/drive/show/rally), date, location, description, rsvpCount, maxCapacity. `factory CommunityEvent.fromJson()`.

### Service Layer
- `getCommunities({String? brand})` — GET `/api/owners-club/communities`
- `getCommunity(int id)` — GET `/api/owners-club/communities/{id}`
- `joinCommunity(int id)` — POST `/api/owners-club/communities/{id}/join`
- `getCommunityFeed(int id, {int page})` — GET `/api/owners-club/communities/{id}/feed`
- `getKnowledgeBase(int id, {String? search})` — GET `/api/owners-club/communities/{id}/knowledge`
- `createShowcase(Map data)` — POST `/api/owners-club/showcases`
- `getShowcases(int communityId)` — GET `/api/owners-club/communities/{id}/showcases`
- `getCommunityEvents(int id)` — GET `/api/owners-club/communities/{id}/events`
- `rsvpEvent(int eventId)` — POST `/api/owners-club/events/{id}/rsvp`
- `askQuestion(int communityId, Map data)` — POST `/api/owners-club/communities/{id}/questions`

### Pages & Screens
- **Community Home**: "My Communities" grid + "Discover" section with recommended communities based on My Cars vehicles.
- **Community Feed**: Posts with photos, pinned posts at top, post composer, filter by type.
- **Vehicle Showcase**: Gallery grid of member vehicles, tap for detail with specs, mods, trips.
- **Knowledge Base**: Search bar + category tags, pinned solutions, Q&A threads with accepted answers.
- **Community Events**: Calendar view, upcoming events cards, RSVP buttons, past event galleries.
- **Ask Community**: Post question form, answer thread, mark solution, upvote.

### Widgets
- `CommunityCardWidget` — Brand logo, name, member count, "Joined" badge
- `ShowcaseCardWidget` — Vehicle hero photo, make/model, modification count
- `ExpertBadgeWidget` — Star icon with "Expert" or "Mechanic" label
- `MilestoneWidget` — Achievement icon (100K km, 200K km) with celebration
- `EventCardWidget` — Date, title, type icon, RSVP count, location

---

## 2. UI Design

- Community cards: 16dp radius, brand logo/color accent
- Showcase: Full-width hero photo with overlay text
- Knowledge base: Clean list with search, tag chips
- Events: Calendar at top, event cards below

### Key Screen Mockup — Community Home
```
┌─────────────────────────────┐
│  SafeArea                   │
│  My Communities              │
│  ┌──────┐ ┌──────┐ ┌────┐ │
│  │Toyota│ │ BMW  │ │Sub.│ │
│  │ Club │ │ Club │ │Club│ │
│  │1.2K  │ │ 340  │ │280 │ │
│  └──────┘ └──────┘ └────┘ │
│                             │
│  Discover                   │
│  ┌───────────────────────┐  │
│  │ Land Cruiser Owners   │  │
│  │ 890 members  [Join]   │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │ Jeep/4x4 Club TZ     │  │
│  │ 450 members  [Join]   │  │
│  └───────────────────────┘  │
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### Local-First with SQLite
```dart
// Table: communities
// Columns: id INTEGER PRIMARY KEY, name TEXT, brand TEXT, member_count INTEGER, is_joined INTEGER, json_data TEXT, synced_at TEXT
// Indexes: brand, is_joined
// Table: knowledge_posts
// Columns: id INTEGER PRIMARY KEY, community_id INTEGER, is_pinned INTEGER, json_data TEXT, synced_at TEXT
// Indexes: community_id, is_pinned
```

### Stale-While-Revalidate
- Community list: cache TTL 1 hour
- Community feed: cache TTL 10 minutes
- Knowledge base: cache TTL 24 hours (mostly static)
- Events: cache TTL 1 hour

### Offline Support
- Read: Community list, feed, knowledge base, events
- Write: Posts, questions, RSVP queued in pending_queue
- Sync: Feed refresh on reconnect, new posts synced

### Media Caching
- Vehicle showcase photos: MediaCacheService (30-day TTL)
- Community logos: cached indefinitely
- Event photos: 14-day TTL

---

## 4. Backend Implementation

### Database Tables
```sql
CREATE TABLE car_communities (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255),
    brand VARCHAR(100),
    model VARCHAR(100),
    type VARCHAR(30),
    description TEXT,
    logo_url TEXT,
    rules TEXT,
    member_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE community_memberships (
    id BIGSERIAL PRIMARY KEY,
    community_id BIGINT REFERENCES car_communities(id),
    user_id BIGINT REFERENCES users(id),
    role VARCHAR(20) DEFAULT 'member',
    joined_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(community_id, user_id)
);

CREATE TABLE vehicle_showcases (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    community_id BIGINT REFERENCES car_communities(id),
    vehicle_id BIGINT REFERENCES vehicles(id),
    photos JSONB DEFAULT '[]',
    story TEXT,
    modifications JSONB DEFAULT '[]',
    trips JSONB DEFAULT '[]',
    votes INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE community_events (
    id BIGSERIAL PRIMARY KEY,
    community_id BIGINT REFERENCES car_communities(id),
    creator_id BIGINT REFERENCES users(id),
    title VARCHAR(255),
    type VARCHAR(30),
    event_date TIMESTAMP,
    location JSONB,
    description TEXT,
    max_capacity INTEGER,
    rsvp_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/owners-club/communities | List communities | Yes |
| GET | /api/owners-club/communities/{id} | Community detail | Yes |
| POST | /api/owners-club/communities/{id}/join | Join community | Yes |
| GET | /api/owners-club/communities/{id}/feed | Community feed | Yes |
| GET | /api/owners-club/communities/{id}/knowledge | Knowledge base | Yes |
| POST | /api/owners-club/showcases | Create showcase | Yes |
| GET | /api/owners-club/communities/{id}/showcases | List showcases | Yes |
| GET | /api/owners-club/communities/{id}/events | Community events | Yes |
| POST | /api/owners-club/events/{id}/rsvp | RSVP to event | Yes |
| POST | /api/owners-club/communities/{id}/questions | Ask question | Yes |

### Controller
- File: `app/Http/Controllers/Api/OwnersClubController.php`
- Pattern: DB facade, try/catch, `{"success": true, "data": ...}` responses

### Background Jobs
- Auto-join community recommendations based on My Cars (daily)
- Mileage milestone detection and notification
- Event reminder notifications (24h before)
- Member count recalculation (hourly)

---

## 5. Integration Wiring

- **My Cars**: Auto-join communities based on registered vehicles. Showcase pre-populated from garage.
- **Groups**: Communities built on GroupService infrastructure with extended features.
- **Messaging**: Member-to-member chat, expert advice requests.
- **Events**: Community meetups use full events system (RSVP, budget, tickets).
- **Spare Parts**: Community-recommended sellers, parts advice.
- **Service Garage**: Mechanic recommendations from community.
- **Sell Car**: Announce sale to brand community first.
- **Buy Car**: Community advice on vehicles being considered.
- **Notifications**: New posts, events, milestones, answers.
- **Posts & Stories**: Showcase posts shared to main feed.

---

## 6. Implementation Phases

### Phase 1: Foundation (Week 1)
- [ ] Create directory structure and owners_club_module.dart
- [ ] Community, VehicleShowcase, KnowledgePost, Event models
- [ ] OwnersClubService with AuthenticatedDio
- [ ] Backend: migrations + communities CRUD + membership
- [ ] SQLite tables for communities and knowledge posts

### Phase 2: Core UI (Week 2)
- [ ] Community Home with joined/discover sections
- [ ] Community Feed with post composer
- [ ] Vehicle Showcase gallery
- [ ] Knowledge Base with search
- [ ] Community Events with RSVP

### Phase 3: Integration (Week 3)
- [ ] Wire to My Cars for auto-join recommendations
- [ ] Wire to GroupService for community infrastructure
- [ ] Wire to NotificationService for alerts
- [ ] Wire to Events module for meetup creation

### Phase 4: Polish (Week 4)
- [ ] Ask Community Q&A with solution marking
- [ ] Member Directory with roles
- [ ] Mileage milestone celebrations
- [ ] Offline community feed viewing
- [ ] Community marketplace
- [ ] Empty states and moderation tools

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| [CarAPI](https://carapi.app/) | CarAPI | Vehicle specs database, make/model/trim data | Freemium | 90K+ vehicles. REST + JSON. Good for car profiles in community |
| [CarQuery API](https://www.carqueryapi.com/) | CarQuery | Vehicle year/make/model/trim specifications | Free | JSON API. Good for community car profiles and spec comparisons |
| [Auto-Data.net API](https://api.auto-data.net/) | Auto-Data.net | Detailed technical specs (54K+ vehicles, 14 languages) | Paid (tiered) | Engine, performance, dimensions data for car spec pages |
| [Car Database API](https://cardatabaseapi.com/) | Car Database API | Makes, models, generations, trims, body types, engines | Paid | Comprehensive car data for enthusiast profiles |
| [NHTSA Recalls API](https://vpic.nhtsa.dot.gov/api/) | US Dept. of Transportation | Vehicle recall notifications | Free | Alert club members about recalls affecting their vehicles |
| Firebase / Firestore | Google | Real-time community features (chat, forums, events) | Freemium | Already integrated in TAJIRI. Use for club chat and event coordination |
| [M-Pesa Open API](https://openapiportal.m-pesa.com) | Vodacom Tanzania | Club membership fees, event payments | Transaction fees | Dart SDK: `mpesa_sdk` on pub.dev |
| [AzamPay API](https://developers.azampay.co.tz/) | AzamPay (Bakhresa Group) | Payment gateway for club activities | Transaction fees | Flutter SDK: `azampaytanzania` on pub.dev |
| [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging) | Google | Event reminders, community notifications | Free | Already integrated in TAJIRI app |
