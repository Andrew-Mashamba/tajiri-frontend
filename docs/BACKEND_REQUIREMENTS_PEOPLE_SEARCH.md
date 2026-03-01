# Backend Requirements: People Search Engine

This document states **exactly** what the Laravel backend must provide so the Flutter People → People tab works as designed. It also lists optional improvements.

---

## 1. What the backend MUST provide

### 1.1 Endpoint (choose one)

**Option A (preferred):** Add a dedicated people-search endpoint.

- **Method:** `GET`
- **Path:** `/api/people/search`
- **Auth:** Same as rest of app (e.g. Bearer token or session). Requester must be authenticated; results respect privacy relative to the requester.

**Option B:** Extend the existing users search.

- **Method:** `GET`
- **Path:** `/api/users/search` (existing)
- **Behaviour:** Support the same query parameters and response shape below. The Flutter app already falls back to this when `/api/people/search` returns 404 or 501.

---

### 1.2 Query parameters (exact names the app sends)

| Parameter  | Type   | Required | Values / meaning |
|-----------|--------|----------|------------------|
| `q`       | string | No*      | Search text (name, username, bio, school, employer, location). *Required for text search; when empty, backend may return discover/suggestions or empty list. |
| `page`    | int    | No       | Page number; default `1`. |
| `per_page`| int    | No       | Items per page; default `20`, max `50`. |
| `sort`    | string | No       | One of: `relevance`, `newest`, `last_seen`, `most_active`, `friends_count`, `least_connected`, `most_mutual_friends`, `similar_to_me`, `single_first`, `same_area_first`, `most_shared_interests`, `least_male_friends`, `least_female_friends`. Default `relevance`. See Sort options below. |
| `online`  | string | No       | When `"1"`, filter to users that are currently online only. |
| `location`| string | No       | Filter by region or district name (e.g. `Kinondoni`, `Dar-es-salaam`). |
| `employer`| string | No       | Filter by employer name (substring or exact, your choice). |
| `school`  | string | No       | Filter by primary / secondary / university name (substring or exact). |
| `has_business` | string | No | When `"1"`, only users who have employer / business set. |
| `student` | string | No | When `"1"`, only users who are students (e.g. has education, no employer; or use a dedicated flag if you have one). |
| `relationship_status` | string | No | Filter by status: `single`, `in_relationship`, `engaged`, `married`, `complicated`, `divorced`, `widowed`. |
| `sector` | string | No | Filter by employer sector/industry (e.g. Tech, Education, Health). |
| `has_interests` | string | No | When `"1"`, only users who have at least one interest set. |
| `profile_complete` | string | No | When `"1"`, only users with complete profile (e.g. has photo + bio + key details). |
| `friends_of_friends_only` | string | No | When `"1"`, only 2nd-degree connections (friends of friends). |

Flutter sends these as standard query params (e.g. `?q=andrew&page=1&per_page=20&sort=last_seen&online=1`).

**Sort options (backend behavior):**

| `sort` value             | Suggested behavior |
|---------------------------|--------------------|
| `relevance`               | Friends-of-friends first, then name/username match, then popularity. |
| `newest`                  | Order by `created_at` desc. |
| `last_seen`               | Order by `last_seen_at` or `last_active_at` desc (recently active first). |
| `most_active`             | Order by activity (e.g. `posts_count` desc, or combined activity score). |
| `friends_count`           | Order by `friends_count` desc (most friends first). |
| `least_connected`         | Order by `friends_count` asc (fewest friends first). |
| `most_mutual_friends`     | Order by `mutual_friends_count` desc (most mutual friends with searcher first). |
| `similar_to_me`           | Score by in_common / shared interests / same location/school/employer; order by that score desc. |
| `single_first`            | Put `relationship_status = single` first (for dating relevance), then by relevance or recency. |
| `same_area_first`         | Put same region/district as searcher first, then others. |
| `most_shared_interests`   | Order by number of shared interests with searcher desc (requires interests comparison). |
| `least_male_friends`      | Order by male friends count asc. Requires male/female friend counts per user. |
| `least_female_friends`    | Order by female friends count asc. Same as above. |

---

### 1.3 Response format (exact structure)

**HTTP:** `200 OK` for success (even when there are zero results).

**Body:** JSON object with this structure:

```json
{
  "success": true,
  "data": [ /* array of user objects */ ],
  "meta": {
    "current_page": 1,
    "per_page": 20,
    "total": 42,
    "last_page": 3
  }
}
```

- `success` (boolean): must be `true` for a successful search.
- `data` (array): list of user objects (see below). Empty array when no results.
- `meta` (object): required for pagination. Flutter uses:
  - `current_page` (int)
  - `per_page` (int)
  - `total` (int) — total number of matching users
  - `last_page` (int) — so the app knows when to stop “load more”

If you already return Laravel’s default pagination meta, ensure it includes at least these keys (Laravel often uses `current_page`, `per_page`, `total`, `last_page`).

---

### 1.4 Each user object in `data[]` (exact field names)

Flutter parses with `UserProfile.fromJson()`. Use these **snake_case** keys so the app can display rich cards and filters.

**Required (minimal for a useful card):**

| Key                   | Type    | Notes |
|-----------------------|---------|--------|
| `id`                  | int     | User ID. |
| `first_name`          | string  | Required. |
| `last_name`           | string  | Required. |
| `username`            | string? | Nullable; shown as @username. |
| `profile_photo_path`   | string? | Relative to storage (e.g. `profile-photos/xxx.jpg`). App prepends `storageUrl`. |
| `region_name`         | string? | e.g. Dar-es-salaam. |
| `district_name`       | string? | e.g. Kinondoni. |
| `friends_count`       | int     | Default 0 if missing. |
| `posts_count`         | int     | Default 0 if missing. |
| `photos_count`        | int     | Default 0 if missing. |
| `mutual_friends_count`| int?    | Count of mutual friends with the **requester**; null if not computed. |

**Optional but recommended (for “advanced” people search):**

| Key                  | Type    | Notes |
|----------------------|---------|--------|
| `bio`                | string? | Shown in profile; can be used for search. |
| `cover_photo_path`   | string? | Same as profile_photo_path. |
| `location_string`    | string? | Full hierarchy, e.g. `Dar-es-salaam → Kinondoni → Mbezi juu`. Overrides region_name + district_name for display when present. |
| `primary_school`     | string? | Searchable + shown as context line. |
| `secondary_school`   | string? | Searchable + shown as context line. |
| `university`         | string? | Searchable + shown as context line. |
| `employer`           | string? | Searchable + shown as context line. |
| `is_online`          | boolean | `true` if user is currently online. |
| `last_seen_at`       | string? | ISO 8601 datetime, e.g. `2026-02-16T16:16:17.000000Z`. Used for “recently active” and display. |
| `last_active_at`     | string? | ISO 8601; if you use this instead of `last_seen_at`, Flutter uses it for “last active” as well. |
| `created_at`         | string? | ISO 8601; for “newest” sort. |

**Privacy:** Only include fields the **profile owner** has allowed to be visible to “everyone” (or to the requester). If your system has per-field privacy (e.g. “employer visible to friends only”), omit or null out that field for requesters who are not allowed to see it. The app will simply not show those fields.

**Do not expose:** Phone, email, or other sensitive data in this list endpoint unless your product explicitly requires it and it’s allowed by privacy.

---

### 1.5 Pagination meta (exact keys)

Flutter expects `meta` in the root of the JSON response (same level as `success` and `data`). Each key can be number (int):

| Key           | Type | Notes |
|---------------|------|--------|
| `current_page`| int  | Current page (1-based). |
| `per_page`    | int  | Page size. |
| `total`       | int  | Total number of results. |
| `last_page`   | int  | Last page number (so we know when to stop loading more). |

Example: `"meta": { "current_page": 1, "per_page": 20, "total": 42, "last_page": 3 }`.

---

### 1.6 Search and filter behaviour

- **`q`:** Search over at least: first name, last name, username. Ideally also: bio, location_string, primary_school, secondary_school, university, employer. Matching can be “contains” or full-text; typo tolerance is an improvement (see below).
- **`sort`:**
  - `relevance` — default; use your search engine’s relevance or order by match score.
  - `last_seen` — order by `last_seen_at` or `last_active_at` desc (most recently active first).
  - `friends_count` — order by `friends_count` desc.
  - `newest` — order by `created_at` desc.
- **`online=1`:** Restrict to users where `is_online === true` (or your equivalent).
- **`location`:** Filter by region or district (e.g. where `region_name` or `district_name` or `location_string` contains/matches the value).
- **`employer`:** Filter where employer name matches (substring or normalized).
- **`school`:** Filter where primary_school / secondary_school / university matches (substring or normalized).

Exclude from results: blocked users, users who blocked the requester, and (if applicable) users who have opted out of “being discoverable” in search.

---

### 1.7 Error responses

- **401 Unauthorized** — Requester not authenticated; Flutter will handle re-login.
- **422 Unprocessable Entity** — Optional; e.g. invalid `sort` or `per_page`; body can include a `message` or `errors` object.
- **500** — Flutter will show a generic “search failed” and retry option.

For “no results,” return **200** with `success: true`, `data: []`, and `meta` with `total: 0` and `last_page: 1` (or 0, as long as the app can stop loading more).

---

## 2. Summary checklist for backend

- [ ] **Endpoint:** `GET /api/people/search` (or extended `GET /api/users/search`) with auth.
- [ ] **Query params:** `q`, `page`, `per_page`, `sort`, `online`, `location`, `employer`, `school` (names and semantics as above).
- [ ] **Response:** `{ "success": true, "data": [ {...}, ... ], "meta": { "current_page", "per_page", "total", "last_page" } }`.
- [ ] **User object keys:** `id`, `first_name`, `last_name`, `username`, `profile_photo_path`, `region_name`, `district_name`, `friends_count`, `posts_count`, `photos_count`, `mutual_friends_count`; optional: `bio`, `cover_photo_path`, `location_string`, `primary_school`, `secondary_school`, `university`, `employer`, `is_online`, `last_seen_at` / `last_active_at`, `created_at`.
- [ ] **Privacy:** Only return fields the profile owner allows for the requester; exclude blocked / non-discoverable users.
- [ ] **Sort:** Support `relevance`, `last_seen`, `friends_count`, `newest`.
- [ ] **Filter:** Support `online=1`, `location`, `employer`, `school` when provided.

---

## 3. Improvement suggestions

### 3.1 Backend

1. **Typo-tolerant search**  
   Use **Laravel Scout** with **Meilisearch** (or PostgreSQL full-text with a good stemmer). Index at least: first_name, last_name, username, bio, location_string, primary_school, secondary_school, university, employer. This gives “Andrew” when the user types “Andew” and improves perceived quality.

2. **`mutual_friends_count`**  
   Always compute and return `mutual_friends_count` for the authenticated requester. The app uses it on each card and it significantly improves engagement.

3. **Presence (`is_online`, `last_seen_at`)**  
   Keep `is_online` and `last_seen_at` (or `last_active_at`) up to date (e.g. via WebSocket, heartbeat, or login/logout). Accurate “online” and “recently active” makes sort and “Online” filter useful.

4. **Normalized location / employer / school**  
   If you have region/district/school/employer as IDs or normalized names, filter on those for better performance and consistency (e.g. “Kinondoni” vs “kinondoni”). Flutter can send the same string the user selected from a list later.

5. **Rate limiting**  
   Apply a reasonable rate limit per user on `/api/people/search` (e.g. 60/min) to protect your search index and DB.

6. **Caching**  
   Cache popular or repeated queries (e.g. short TTL) to reduce load on the search engine or DB.

7. **Analytics**  
   Log anonymized search queries and filters (no user IDs if not needed) to tune relevance and discover missing data (e.g. underfilled employer field).

### 3.2 Flutter app

1. **Location / employer / school pickers**  
   Add dropdowns or type-ahead chips for `location`, `employer`, and `school` (e.g. from previous search facets or a small “popular” list from the backend) so users don’t have to type free text for filters.

2. **Backend-driven filter options**  
   Optional endpoint, e.g. `GET /api/people/search/facets`, returning suggested values for location, employer, school (e.g. top 20 by count). Flutter can show these as chips or autocomplete.

3. **Result caching**  
   Cache the last 1–2 search results (query + filters + page) in memory so going “back” doesn’t refetch immediately.

4. **Skeleton loaders**  
   Replace the generic spinner with card-shaped skeletons while loading for a smoother feel.

5. **Localization**  
   Move hardcoded strings (“Discover people”, “Recently active”, “Most friends”, “Online”, “Add”, “Sent”, “mutual friends”) into `AppStrings` / l10n for Swahili and English.

6. **Accessibility**  
   Ensure search field and filter chips have semantic labels and that “Add” / “Sent” and online indicator are announced correctly by screen readers.

7. **Deep link**  
   Support a deep link (e.g. `tajiri://people?q=andrew`) so shared links open the app on People search with the query prefilled.

---

## 4. Optional: facets endpoint (for filter suggestions)

If you want the app to show “suggested” filter values (e.g. top regions or employers), add:

- **Method:** `GET`
- **Path:** `/api/people/search/facets` (or `.../filters`)
- **Query:** Optional `q` (to scope facets to current search).
- **Response:** e.g.  
  `{ "success": true, "data": { "locations": ["Dar-es-salaam", "Kinondoni", ...], "employers": ["Zima Ltd", ...], "schools": [...] } }`

Flutter can then show these as chips or autocomplete. Not required for the first version.

---

Once the backend implements the required endpoint, parameters, response shape, and field names above, the existing Flutter People tab will use it without code changes (it already calls `/api/people/search` and falls back to `/api/users/search`). The improvements above will make the experience and performance even better.
