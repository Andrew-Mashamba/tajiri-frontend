# Campus News / Habari za Chuo — Implementation Plan

## Overview
Centralized campus information hub replacing notice boards and WhatsApp forwarding chains. Official announcements from administration, student union news, event listings, academic deadline reminders, emergency alerts, campus map, dining menus, and weekly digest. Verified sources only, with push notification categories and comment/react support.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/campus_news/
├── campus_news_module.dart
├── models/
│   ├── news_article.dart
│   ├── campus_event.dart
│   ├── emergency_alert.dart
│   └── news_source.dart
├── services/
│   └── campus_news_service.dart     — AuthenticatedDio.instance
├── pages/
│   ├── news_feed_page.dart
│   ├── article_detail_page.dart
│   ├── event_listing_page.dart
│   ├── events_calendar_page.dart
│   ├── campus_map_page.dart
│   ├── categories_page.dart
│   ├── saved_articles_page.dart
│   ├── dining_page.dart
│   ├── emergency_page.dart
│   └── news_settings_page.dart
└── widgets/
    ├── news_card.dart
    ├── event_card.dart
    ├── category_tab.dart
    ├── emergency_banner.dart
    ├── source_badge.dart
    ├── deadline_card.dart
    └── digest_card.dart
```

### Data Models
```dart
class NewsArticle {
  final int id;
  final String title, body, category;   // official, events, clubs, sports, health, safety
  final String sourceName;
  final bool verified, urgent;
  final List<String> imageUrls;
  final int commentCount, reactionCount;
  final DateTime publishedAt;
  factory NewsArticle.fromJson(Map<String, dynamic> j) => NewsArticle(
    id: _parseInt(j['id']),
    title: j['title'] ?? '',
    body: j['body'] ?? '',
    category: j['category'] ?? 'official',
    sourceName: j['source_name'] ?? '',
    verified: _parseBool(j['verified']),
    urgent: _parseBool(j['urgent']),
    commentCount: _parseInt(j['comment_count']),
  );
}

class CampusEvent { int id; String title, venue, organizer; DateTime date; String? description, rsvpUrl; }
class EmergencyAlert { int id; String title, body, severity; DateTime createdAt; bool active; }
class NewsSource { int id; String name, type; bool verified; }  // admin, department, student_union, club
```

### Service Layer
```dart
class CampusNewsService {
  static Future<List<NewsArticle>> getFeed(String token, {String? category, String? institution}); // GET /api/campus-news
  static Future<NewsArticle> getArticle(String token, int id);                 // GET /api/campus-news/{id}
  static Future<void> reactToArticle(String token, int id, String reaction);   // POST /api/campus-news/{id}/react
  static Future<List<Map>> getComments(String token, int id);                  // GET /api/campus-news/{id}/comments
  static Future<void> postComment(String token, int id, Map body);             // POST /api/campus-news/{id}/comments
  static Future<void> saveArticle(String token, int id);                       // POST /api/campus-news/{id}/save
  static Future<List<CampusEvent>> getEvents(String token, {DateTime? from});  // GET /api/campus-news/events
  static Future<void> rsvpEvent(String token, int eventId);                    // POST /api/campus-news/events/{id}/rsvp
  static Future<List<EmergencyAlert>> getEmergencies(String token);            // GET /api/campus-news/emergencies
  static Future<List<NewsArticle>> getSaved(String token);                     // GET /api/campus-news/saved
  static Future<Map> getDigest(String token);                                  // GET /api/campus-news/digest
}
```

### Pages & Widgets
- **NewsFeedPage**: chronological feed with category tabs (Official, Events, Clubs, Urgent), pull-to-refresh
- **ArticleDetailPage**: full article with images, comments, share, save, source badge
- **EventListingPage**: event cards with date, time, venue, RSVP button, add to calendar
- **EventsCalendarPage**: month view showing campus events and deadlines
- **CampusMapPage**: interactive map with buildings, services, search, directions
- **CategoriesPage**: filter by Academic, Administrative, Events, Sports, Health, Safety
- **EmergencyPage**: dedicated emergency info with contacts and active alerts
- **DiningPage**: today's cafeteria menu with prices and hours
- **SavedArticlesPage**: bookmarked articles for reference

---

## 2. UI Design
- Monochromatic: #1A1A1A / #666666 / #FAFAFA / #FFFFFF
- 48dp touch targets, maxLines + ellipsis, _rounded icons
- Verified source badge (checkmark icon) next to official sources
- Emergency banner: full-width red-border card at top when active alerts exist

### Main Screen Wireframe
```
┌──────────────────────────────┐
│  Campus News         [🔍 ⚙] │
├──────────────────────────────┤
│ [All][Official][Events][Club]│
├──────────────────────────────┤
│ ┌──────────────────────────┐ │
│ │ ⚠ EMERGENCY               │ │
│ │ Water outage Mlimani      │ │
│ │ campus — Est. 6hrs        │ │
│ └──────────────────────────┘ │
│                              │
│ ┌──────────────────────────┐ │
│ │ ✓ Registration Deadline   │ │
│ │   Semester 2 registration │ │
│ │   closes April 15, 2026   │ │
│ │   Registrar · 2h ago      │ │
│ ├──────────────────────────┤ │
│ │   Career Fair 2026        │ │
│ │   Apr 20 · Main Hall      │ │
│ │   DARUSO · RSVP            │ │
│ ├──────────────────────────┤ │
│ │ ✓ Fee Payment Reminder    │ │
│ │   Exam entry deadline     │ │
│ │   Finance · 1d ago        │ │
│ └──────────────────────────┘ │
└──────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE news_articles(id INTEGER PRIMARY KEY, category TEXT, institution TEXT, verified INTEGER, urgent INTEGER, published_at TEXT, json_data TEXT, synced_at TEXT);
CREATE INDEX idx_news_category ON news_articles(category);
CREATE INDEX idx_news_date ON news_articles(published_at);

CREATE TABLE campus_events(id INTEGER PRIMARY KEY, event_date TEXT, json_data TEXT, synced_at TEXT);
CREATE TABLE saved_articles(id INTEGER PRIMARY KEY, article_id INTEGER, saved_at TEXT);
```
- SQLite first, API background refresh (stale-while-revalidate)
- Offline read: YES — cached news feed and saved articles
- Offline write: pending_queue for comments, reactions, RSVP

---

## 4. Backend Implementation

### Database (PostgreSQL)
```sql
CREATE TABLE campus_news(
  id SERIAL PRIMARY KEY, source_id INT REFERENCES news_sources(id),
  title VARCHAR(255), body TEXT, category VARCHAR(50),
  institution VARCHAR(255), verified BOOLEAN DEFAULT FALSE,
  urgent BOOLEAN DEFAULT FALSE, image_urls JSONB,
  comment_count INT DEFAULT 0, reaction_count INT DEFAULT 0,
  published_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE news_sources(
  id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id),
  name VARCHAR(255), type VARCHAR(50),  -- admin, department, student_union, club
  institution VARCHAR(255), verified BOOLEAN DEFAULT FALSE
);
CREATE TABLE news_comments(
  id SERIAL PRIMARY KEY, article_id INT REFERENCES campus_news(id),
  user_id INT REFERENCES users(id), body TEXT, created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE news_reactions(
  id SERIAL PRIMARY KEY, article_id INT REFERENCES campus_news(id),
  user_id INT REFERENCES users(id), reaction VARCHAR(20),
  UNIQUE(article_id, user_id)
);
CREATE TABLE campus_events(
  id SERIAL PRIMARY KEY, title VARCHAR(255), description TEXT,
  venue VARCHAR(255), organizer VARCHAR(255),
  event_date TIMESTAMP, institution VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE event_rsvps(
  id SERIAL PRIMARY KEY, event_id INT REFERENCES campus_events(id),
  user_id INT REFERENCES users(id), UNIQUE(event_id, user_id)
);
CREATE TABLE emergency_alerts(
  id SERIAL PRIMARY KEY, title VARCHAR(255), body TEXT,
  severity VARCHAR(20), institution VARCHAR(255),
  active BOOLEAN DEFAULT TRUE, created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE saved_news(
  id SERIAL PRIMARY KEY, article_id INT REFERENCES campus_news(id),
  user_id INT REFERENCES users(id), UNIQUE(article_id, user_id)
);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/campus-news | News feed with filters | Bearer |
| GET | /api/campus-news/{id} | Article detail | Bearer |
| POST | /api/campus-news/{id}/react | React to article | Bearer |
| GET | /api/campus-news/{id}/comments | Article comments | Bearer |
| POST | /api/campus-news/{id}/comments | Post comment | Bearer |
| POST | /api/campus-news/{id}/save | Save/bookmark | Bearer |
| GET | /api/campus-news/events | Campus events | Bearer |
| POST | /api/campus-news/events/{id}/rsvp | RSVP to event | Bearer |
| GET | /api/campus-news/emergencies | Active emergencies | Bearer |
| GET | /api/campus-news/saved | Saved articles | Bearer |
| GET | /api/campus-news/digest | Weekly digest | Bearer |

### Controller
`app/Http/Controllers/Api/CampusNewsController.php`

---

## 5. Integration Wiring
- NotificationService + FCM — priority push for emergencies (bypass mute), category-based notifications
- CalendarService — campus events and deadlines sync to personal calendar
- PostService — share news to TAJIRI feed
- MessageService — share articles in chats
- LiveUpdateService — real-time emergency broadcasts
- events/ module — campus events link to TAJIRI events for RSVP and tracking
- my_class module — class-specific announcements (room changes, cancellations)
- timetable module — exam dates and schedule changes update timetable
- fee_status module — fee deadline announcements link to fee payment
- study_groups module — workshop/seminar announcements shared with groups

---

## 6. Implementation Phases

### Phase 1 — News Feed (Week 1-2)
- [ ] NewsArticle model, service, SQLite cache
- [ ] News feed page with category tabs
- [ ] Article detail with images and source badge
- [ ] Pull-to-refresh and pagination

### Phase 2 — Events & Interaction (Week 3)
- [ ] Campus event listings with RSVP
- [ ] Events calendar view
- [ ] Comment and react on articles
- [ ] Save/bookmark articles

### Phase 3 — Emergency & Map (Week 4)
- [ ] Emergency alert system with bypass-mute notifications
- [ ] Campus map with buildings and services
- [ ] Dining menu page
- [ ] Push notification category preferences

### Phase 4 — Advanced (Week 5)
- [ ] Weekly digest compilation
- [ ] Verified source management
- [ ] Lost and found section
- [ ] Search archive by keyword/date
- [ ] Institution-specific feed filtering

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| RSS/Atom Feeds | Various universities | University news, announcements | Free | Most university websites publish RSS feeds. Flutter packages: `webfeed ^0.7.0`, `xml ^6.0.0` for parsing. Scrape from UDSM, SUA, UDOM, Ardhi, MUHAS, DIT, etc. |
| NewsAPI | NewsAPI.org | News articles by keyword, source | Free: 100 req/day (dev); Paid from $449/mo | Search by keyword (e.g., "UDSM", "university Tanzania"). 150K+ sources. |
| GNews API | GNews | Google News aggregation | Free: 100 req/day; Paid from $84/mo | Filter by country (Tanzania), category (education). Good for supplementing campus-specific news. |
| Bing News Search API | Microsoft | News search with filters | Free: 1K calls/mo; Paid from $1/1K | Part of Azure Cognitive Services. Filter by market, category. |
| TCU Website | TCU (tcu.go.tz) | University accreditation news, admissions | Free (web scraping) | No API. Scrape public notices and admission guidebooks. |

**Tanzania context:** Scrape RSS feeds from UDSM, SUA, UDOM, Ardhi, MUHAS, DIT, etc. TCU publishes admission cycles and accreditation updates. Build custom backend scraper for Tanzania university news aggregation.

### Integration Priority
1. **Immediate** -- RSS/Atom feed parsing (free, use `webfeed` package on pub.dev to scrape university news), GNews API (free tier, 100 req/day for Tanzania education news)
2. **Short-term** -- NewsAPI (free dev tier, broader news search), Bing News Search API (1K free calls/mo)
3. **Partnership** -- TCU official data feed (formal partnership for admission and accreditation updates), university communication offices (direct news feed access)
