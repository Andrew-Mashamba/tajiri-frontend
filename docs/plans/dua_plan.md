# Dua (Supplications) — Implementation Plan

## Overview
Digital supplication library replacing physical "Hisn al-Muslim" booklets. Arabic text with Swahili translation, transliteration, audio pronunciation, categorized by occasion, digital tasbeeh counter, morning/evening adhkar tracker, and full offline support.

---

## 1. Frontend Architecture

### Directory Structure
```
lib/dua/
├── dua_module.dart
├── models/
│   ├── dua.dart
│   ├── dua_category.dart
│   ├── adhkar_set.dart
│   └── tasbeeh_preset.dart
├── services/
│   └── dua_service.dart             — AuthenticatedDio.instance
├── pages/
│   ├── dua_home_page.dart
│   ├── category_browser_page.dart
│   ├── dua_list_page.dart
│   ├── dua_detail_page.dart
│   ├── adhkar_counter_page.dart
│   ├── tasbeeh_page.dart
│   ├── favorites_page.dart
│   ├── search_results_page.dart
│   └── dua_card_creator_page.dart
└── widgets/
    ├── dua_preview_card.dart
    ├── arabic_text_display.dart
    ├── category_icon_card.dart
    ├── adhkar_progress.dart
    ├── tasbeeh_button.dart
    └── dua_share_card.dart
```

### Data Models
- **Dua** — `id`, `titleSwahili`, `titleEnglish`, `arabicText`, `swahiliTranslation`, `englishTranslation`, `transliteration`, `audioUrl`, `source` (quran/hadith), `sourceRef`, `categoryId`, `repeatCount`, `isFavorite`. `_parseInt`, `_parseBool`.
- **DuaCategory** — `id`, `name`, `nameSwahili`, `iconName`, `duaCount`. `_parseInt`.
- **AdhkarSet** — `type` (morning/evening), `items` (List of Dua with repeat counts), `completedCount`. `_parseInt`.
- **TasbeehPreset** — `id`, `phrase`, `phraseArabic`, `targetCount`, `currentCount`. `_parseInt`.

### Service Layer
```dart
Dio get _dio => AuthenticatedDio.instance;
```
- `getCategories()` — `GET /api/dua/categories`
- `getDuasByCategory(int categoryId)` — `GET /api/dua/categories/{id}/duas`
- `getDua(int id)` — `GET /api/dua/{id}`
- `searchDuas(String query)` — `GET /api/dua/search?q={query}`
- `getMorningAdhkar()` — `GET /api/dua/adhkar/morning`
- `getEveningAdhkar()` — `GET /api/dua/adhkar/evening`
- `getDailyDua()` — `GET /api/dua/daily`
- `toggleFavorite(int duaId)` — `POST /api/dua/{id}/favorite`
- `getFavorites()` — `GET /api/dua/favorites`

### Pages
- **DuaHomePage** — Morning/evening adhkar status, daily featured dua, category quick links
- **CategoryBrowserPage** — Illustrated category cards (travel, food, sleep, health, etc.)
- **DuaListPage** — Duas within a category with Arabic preview and label
- **DuaDetailPage** — Full Arabic, transliteration, Swahili translation, audio, source
- **AdhkarCounterPage** — Morning/evening checklist with repetition counter per item
- **TasbeehPage** — Large counter button with preset dhikr phrases and targets
- **FavoritesPage** — Saved duas for quick access
- **DuaCardCreatorPage** — Styled dua image for sharing

### Widgets
- `TasbeehButton` — Large circular tap counter with haptic feedback
- `ArabicTextDisplay` — Properly rendered Arabic with tashkeel, adjustable size

---

## 2. UI Design
- #1A1A1A/#666666/#FAFAFA/#FFFFFF monochromatic
- 48dp touch, maxLines+ellipsis, _rounded icons
- Dark stat cards for adhkar completion and tasbeeh count
- Cards: radius 12-16, subtle shadow

### Main Screen Wireframe
```
┌─────────────────────────────┐
│ ← Dua                  🔍   │
├─────────────────────────────┤
│ ┌───────────┐ ┌───────────┐ │
│ │ Morning   │ │ Evening   │ │
│ │ Adhkar    │ │ Adhkar    │ │
│ │ ██████░ 8 │ │ ○○○○○ 0  │ │
│ │   /12     │ │   /10     │ │
│ └───────────┘ └───────────┘ │
│                             │
│  Daily Dua                  │
│ ┌─────────────────────────┐ │
│ │ بِسْمِ ٱللَّهِ            │ │
│ │ "Kwa jina la Mwenyezi"  │ │
│ │ Before eating     [▶]   │ │
│ └─────────────────────────┘ │
│                             │
│  Categories                 │
│ ┌──────┐┌──────┐┌──────┐   │
│ │Travel││ Food ││Sleep │   │
│ └──────┘└──────┘└──────┘   │
│ ┌──────┐┌──────┐┌──────┐   │
│ │Health││Mosque││Home  │   │
│ └──────┘└──────┘└──────┘   │
│                             │
│  [📿 Tasbeeh] [⭐ Favorites]│
└─────────────────────────────┘
```

---

## 3. Performance Strategy

### SQLite
```sql
CREATE TABLE duas(id INTEGER PRIMARY KEY, category_id INTEGER, arabic_text TEXT, swahili TEXT, audio_url TEXT, json_data TEXT, synced_at TEXT);
CREATE TABLE dua_categories(id INTEGER PRIMARY KEY, name TEXT, icon TEXT, dua_count INTEGER, synced_at TEXT);
CREATE TABLE dua_favorites(id INTEGER PRIMARY KEY, dua_id INTEGER, user_id INTEGER, synced_at TEXT);
CREATE INDEX idx_duas_category ON duas(category_id);
```
- Stale-while-revalidate: SQLite first, API background
- TTL: dua library — infinite (static content), favorites — 1 hour
- Offline: read YES (entire library cached), write favorites via pending_queue

---

## 4. Backend Implementation

### Database
```sql
CREATE TABLE dua_categories(id BIGSERIAL PRIMARY KEY, name VARCHAR(100), name_swahili VARCHAR(100), icon_name VARCHAR(50), dua_count INTEGER DEFAULT 0, sort_order INTEGER);

CREATE TABLE duas(id BIGSERIAL PRIMARY KEY, category_id BIGINT, title_swahili VARCHAR(200), title_english VARCHAR(200), arabic_text TEXT, swahili_translation TEXT, english_translation TEXT, transliteration TEXT, audio_url VARCHAR(500), source VARCHAR(10), source_ref VARCHAR(200), repeat_count INTEGER DEFAULT 1, sort_order INTEGER);

CREATE TABLE dua_favorites(id BIGSERIAL PRIMARY KEY, user_id BIGINT, dua_id BIGINT, created_at TIMESTAMP DEFAULT NOW(), UNIQUE(user_id, dua_id));

CREATE TABLE adhkar_logs(id BIGSERIAL PRIMARY KEY, user_id BIGINT, type VARCHAR(10), completed_count INTEGER, total_count INTEGER, logged_date DATE, created_at TIMESTAMP DEFAULT NOW());

CREATE TABLE tasbeeh_presets(id BIGSERIAL PRIMARY KEY, phrase VARCHAR(200), phrase_arabic VARCHAR(200), default_target INTEGER DEFAULT 33);
```

### API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/dua/categories | List categories | Bearer |
| GET | /api/dua/categories/{id}/duas | Duas by category | Bearer |
| GET | /api/dua/{id} | Dua detail | Bearer |
| GET | /api/dua/search | Search duas | Bearer |
| GET | /api/dua/adhkar/morning | Morning adhkar | Bearer |
| GET | /api/dua/adhkar/evening | Evening adhkar | Bearer |
| GET | /api/dua/daily | Daily featured dua | Bearer |
| POST | /api/dua/{id}/favorite | Toggle favorite | Bearer |
| GET | /api/dua/favorites | User favorites | Bearer |

### Controller
`app/Http/Controllers/Api/DuaController.php` — DB facade with full-text search across Arabic and Swahili text.

---

## 5. Integration Wiring
- **NotificationService** — morning/evening adhkar reminders, daily dua push
- **PostService** — share dua cards to social feed
- **StoryService** — daily dua as story
- **MessageService** — send duas in chat
- **Wakati wa Sala** — post-prayer duas after marking complete
- **Quran** — Quranic duas link to full ayah context
- **Hadith** — prophetic duas link to source hadith
- **Ramadan** — Ramadan-specific duas (iftar, suhoor, Laylat al-Qadr)
- **Kalenda Hijri** — occasion-specific duas for Islamic events
- Full offline support via LocalStorageService

---

## 6. Implementation Phases
### Phase 1: Foundation (Week 1)
- Data models, service layer, SQLite schema
- Dua library data import (Hisn al-Muslim)
- Backend tables and CRUD

### Phase 2: Core UI (Week 2)
- Category browser with illustrated cards
- Dua detail with Arabic, translation, audio
- Morning/evening adhkar counter

### Phase 3: Integration (Week 3)
- Digital tasbeeh with presets
- Search across all duas
- Favorites management

### Phase 4: Polish (Week 4)
- Dua card creator for sharing
- Custom duas (user-added)
- Offline download, font size adjustment

---

## 7. External APIs & Integrations

| API | Provider | Purpose | Pricing | Integration Notes |
|-----|----------|---------|---------|-------------------|
| Dua-Dhikr API | FitrahHive (GitHub) | Authentic Sunnah duas and dhikr collection | Free, open source | RESTful JSON; github.com/fitrahive/dua-dhikr |
| Sunnah.com API | Sunnah.com | Hadith collections including duas from Prophet (SAW) | Free (API key) | Request key via GitHub issue; sunnah.stoplight.io/docs/api |
| Hisnul Muslim (Fortress) | Greentech Apps | Fortress of the Muslim duas database | Free (open source) | Popular open-source app; data files on GitHub |
| Al Quran Cloud API | alquran.cloud | Quranic duas and verses | Free, no auth | 77+ editions; filter for dua-related verses |

### Integration Priority
1. **Immediate** — Free APIs (Dua-Dhikr API -- open source, RESTful, no auth needed)
2. **Short-term** — Sunnah.com API (comprehensive hadith-based duas, free API key)
3. **Partnership** — Hisnul Muslim data (open source GitHub data files for offline bundle)
