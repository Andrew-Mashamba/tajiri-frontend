# People Search Engine — Design & Implementation

**Exact backend contract:** see **[BACKEND_REQUIREMENTS_PEOPLE_SEARCH.md](./BACKEND_REQUIREMENTS_PEOPLE_SEARCH.md)** for required endpoints, query parameters, response shape, field names, and improvement suggestions.

## Goal

Build the most advanced modern people search experience in the Flutter app at **People → People**, using the existing Laravel + PostgreSQL backend and optional additional software. The backend can return rich profile data (name, location hierarchy, education, employer, presence, counts); search should be instant, typo-tolerant, and filterable.

---

## Backend Options (Laravel + Ubuntu)

### Option A: PostgreSQL full-text search (no extra services)

- **Laravel Scout** with `SCOUT_DRIVER=database` uses PostgreSQL full-text indexes.
- Add a **GIN** or **GiST** index on a `tsvector` column (e.g. `search_vector`) built from: `name`, `username`, `bio`, `location_string`, `primary_school`, `secondary_school`, `university`, `employer`.
- **Pros**: No new services, uses existing Postgres. **Cons**: Less typo tolerance, no true “instant” search as-you-type without extra caching.

### Option B: Meilisearch (recommended for “most advanced”)

- **Meilisearch**: open-source, typo-tolerant, instant search, faceted filters, sortable attributes.
- Install on Ubuntu: `curl -L https://install.meilisearch.com | sh` or Docker.
- **Laravel Scout** with `SCOUT_DRIVER=meilisearch` and `meilisearch/meilisearch-php`.
- Index the User (profile) model with `toSearchableArray()` including: `id`, `first_name`, `last_name`, `username`, `bio`, `location_string`, `primary_school`, `secondary_school`, `university`, `employer`, `gender`, `region`, `district`, `is_online`, `last_seen`, `friends_count`, `posts_count`, etc.
- Configure **filterableAttributes**: `region`, `district`, `gender`, `employer` (or normalized), education level.
- Configure **sortableAttributes**: `last_seen`, `friends_count`, `posts_count`, `created_at`.
- **API**: Keep or add a dedicated people search endpoint that uses Scout and returns the rich profile payload below.

### Option C: Typesense

- Similar to Meilisearch: typo-tolerant, fast, supports filters and sorting.
- Scout supports Typesense; good alternative if you prefer it.

---

## Recommended Backend API Contract

### Endpoint

- **GET** `/api/people/search` (or extend existing `GET /api/users/search`)

### Query parameters

| Parameter   | Type   | Description |
|------------|--------|-------------|
| `q`        | string | Search query (name, username, bio, school, employer, location). |
| `page`     | int    | Page number (default 1). |
| `per_page` | int    | Items per page (default 20, max e.g. 50). |
| `location` | string | Filter by region or district (e.g. `Kinondoni`, `Dar-es-salaam`). |
| `employer` | string | Filter by employer name. |
| `school`   | string | Filter by primary/secondary/university name. |
| `online`   | bool   | When true, only users currently online. |
| `sort`     | string | `relevance` (default), `last_seen`, `friends_count`, `newest`. |

### Response shape (each item)

Return the same structure you already have for User #2, as JSON, e.g.:

```json
{
  "success": true,
  "data": [
    {
      "id": 2,
      "first_name": "Andrew",
      "last_name": "Mashamba",
      "username": "andrewm",
      "bio": "...",
      "profile_photo_path": "profile-photos/...",
      "cover_photo_path": "cover-photos/...",
      "gender": "male",
      "date_of_birth": "2008-01-31",
      "location_string": "Dar-es-salaam → Kinondoni → Mbezi juu",
      "region_name": "Dar-es-salaam",
      "district_name": "Kinondoni",
      "primary_school": "SARUJI PRIMARY SCHOOL",
      "secondary_school": "ST. MARY'S SEMINARY MBALIZI",
      "university": "Aga Khan University — Postgraduate Diploma in Education",
      "employer": "Zima Ltd",
      "is_online": true,
      "last_seen_at": "2026-02-16T16:16:17.000000Z",
      "friends_count": 0,
      "posts_count": 8,
      "photos_count": 6,
      "mutual_friends_count": 3,
      "created_at": "2026-01-10T00:00:00.000000Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "per_page": 20,
    "total": 42
  }
}
```

- Respect **privacy**: only return fields the user has set to “everyone” (or equivalent). The backend already has privacy; apply it in the search index and response.
- **Presence**: `is_online` and `last_seen_at` can be updated via WebSocket or polling and included in the search index/document.

---

## Flutter Side (People → People tab)

### UX Principles (modern “people search engine”)

1. **Instant search** — Debounced (300–400 ms) request as the user types; no “Search” button required.
2. **Rich result cards** — Avatar, full name, @username, location (e.g. `Dar-es-salaam → Kinondoni`), one line of context (e.g. education or employer), online indicator, mutual friends count, “Add friend” / “Message” actions.
3. **Filters** — Chips or dropdowns: Location, Employer, School, “Online now”. Sent as query params to the API when the backend supports them.
4. **Sort** — Relevance (default), Recently active, Most friends, Newest. Optional dropdown or segmented control.
5. **Empty / no query** — Show “Discover people” and optionally a “Suggested for you” list (current suggestions API) so the tab never feels empty.
6. **Pagination** — Infinite scroll or “Load more” for paginated results.

### Implementation

- **Model**: Extend `UserProfile` (or add a DTO) with optional fields: `locationString`, `primarySchool`, `secondarySchool`, `university`, `employer`, `isOnline`, `lastSeenAt`, so that when the backend sends them, the app displays them.
- **Service**: `PeopleSearchService` (or extend `FriendService`) calling `GET /people/search` (or `/users/search`) with `q`, `page`, `per_page`, and optional `location`, `employer`, `school`, `online`, `sort`.
- **Tab**: Replace the first tab content in People with a dedicated **PeopleSearchTab** widget:
  - Search bar at top (or reuse app bar search that opens full-screen search).
  - Filter chips row (location, employer, school, online) — enable when API supports.
  - Sort control.
  - List of rich cards; each card: avatar, name, @handle, location string, education/employer snippet, green dot if online, mutual friends, action buttons.
  - When `q` is empty: show “Suggested for you” (current suggestions) or placeholder CTA.
- **Debouncing**: Use a short delay (e.g. 300 ms) so every keystroke doesn’t hit the API; cancel previous request when query changes.

### Accessibility & Performance

- Semantic labels for search and filters.
- Avoid excessive rebuilds: separate the search field and result list, use list view with lazy loading.
- Cache recent search results per query string (optional) to avoid duplicate requests when user goes back.

---

## Summary

| Layer    | Recommendation |
|---------|----------------|
| Backend | Add Laravel Scout with **Meilisearch** (or PostgreSQL database driver) for typo-tolerant, filterable, sortable people search. Expose `GET /api/people/search` (or extend `/users/search`) with query + filters + sort and return rich profile JSON. |
| Flutter | Extend profile model for rich fields; add `PeopleSearchService`; replace People tab content with **PeopleSearchTab** (debounced search, filter chips, sort, rich cards, suggestions when empty). |

Once the backend implements the search endpoint and optional filters/sort, the Flutter app can pass those params and display the full profile data (location hierarchy, education, employer, presence) on each card.
