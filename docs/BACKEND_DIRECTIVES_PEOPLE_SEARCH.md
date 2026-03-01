# Backend directives: People search

**Purpose:** Implement the backend so the Flutter People screen works as shipped. Follow these directives exactly.

**Reference:** Flutter calls `GET /api/people/search` and parses the response with the field names below. Any mismatch will break the app.

---

## 1. Endpoint

| Directive | Detail |
|-----------|--------|
| **MUST** | Expose `GET /api/people/search`. |
| **MUST** | Require authentication (e.g. Bearer token). Use the authenticated user as the “viewer” for friendship status, mutual counts, and privacy. |
| **MUST** | Return JSON with the exact structure in §4 and §5. |

**Base URL:** Same as the rest of the API (e.g. `https://api.example.com/api/people/search`).

---

## 2. Query parameters (exact names the app sends)

The Flutter app sends these as query parameters. Support all of them; unknown params may be ignored.

| Parameter | Type | Required | Values / meaning |
|-----------|------|----------|------------------|
| `user_id` | int | **Yes** | Authenticated user ID (viewer). Used to compute `friendship_status`, `mutual_friends_count`, and `in_common` for each result. |
| `q` | string | No | Search text (min 2 characters when provided). **Empty `q` with no filters** = **discovery mode**: return a discovery feed using composite scoring (e.g. friends-of-friends, same district/school/employer/region, recent activity, profile quality; day-seeded randomness for variety). |
| `page` | int | No | Page number; default `1`. |
| `per_page` | int | No | Items per page; default `20`, max `50`. |
| `sort` | string | No | Single sort key, or **comma-separated** list (e.g. `relevance,last_seen,verified`). First value is primary sort; others are tie-breakers or filters. Default `relevance`. See §3. |
| `gender` | string | No | Filter: `male` \| `female`. Omit or empty = all. |
| `relationship_status` | string | No | Filter: `single`, `in_relationship`, `engaged`, `married`, `complicated`, `divorced`, `widowed`. |
| `online` | string | No | When `"1"`, only users who are currently online. |
| `location` | string | No | Filter by region/district/location (substring or normalized). |
| `employer` | string | No | Filter by employer name (substring or normalized). |
| `school` | string | No | Filter by primary/secondary/university name (substring or normalized). |
| `sector` | string | No | Filter by sector/industry (e.g. Tech, Education, Health). |
| `has_photo` | string | No | When `"1"`, only users who have a profile photo. |
| `age_min` | int | No | Minimum age (inclusive). |
| `age_max` | int | No | Maximum age (inclusive). |
| `student` | string | No | When `"1"`, only users who are students (e.g. has education, no employer; or your own flag). |
| `has_interests` | string | No | When `"1"`, only users with at least one interest set. |
| `profile_complete` | string | No | When `"1"`, only users with complete profile (e.g. photo + bio + key details). |
| `friends_of_friends_only` | string | No | When `"1"`, only 2nd-degree connections (friends of friends of `user_id`). |
| `verified` | string | No | When `"1"`, only verified users (or boost verified in sort). |
| `possible_business_connection` | string | No | When `"1"`, filter or boost users who are possible business connections (e.g. has employer/business, or your own heuristic). |
| `possible_employer` | string | No | When `"1"`, filter or boost users who are possible employers (your heuristic). |

**Note:** The app does **not** send `has_business`; that was removed from filters in favor of Relevance “Possible Business Connection”.

**Discovery mode (empty `q`, no filters):** When the client sends no `q` and no filter params (or only `user_id`, `page`, `per_page`, `sort`), return a **discovery feed** instead of 400. Backend should use a composite scoring function (e.g. `applyDiscoverySort`) that balances signals such as: friends-of-friends (2nd degree), same district/region, same school/employer, recent activity (e.g. last 7 days), has profile photo, verified, has bio. Optionally add day-seeded randomness (e.g. 0–15 pts via hashtext of current date) so results vary by day but stay stable within the same day for pagination.

---

## 3. Sort (`sort` parameter)

`sort` may be a **single value** or **comma-separated** values (e.g. `relevance,last_seen,verified`). Interpret as:

- **First value:** Primary sort order.
- **Remaining values:** Tie-breakers (secondary sort), or treat as filters/boosts when they are `verified`, `possible_business_connection`, `possible_employer`.

**Allowed sort keys and behaviour:**

| `sort` value | Behaviour |
|--------------|-----------|
| `relevance` | Default. E.g. friends-of-friends first, then text match score, then popularity. |
| `newest` | Order by `created_at` DESC. |
| `last_seen` | Order by `last_seen_at` or `last_active_at` DESC (recently active first). |
| `most_active` | Order by activity (e.g. posts_count or combined activity score) DESC. |
| `friends_count` | Order by `friends_count` DESC. |
| `least_connected` | Order by `friends_count` ASC. |
| `most_mutual_friends` | Order by `mutual_friends_count` DESC (relative to `user_id`). |
| `similar_to_me` | Score by shared attributes (in_common, location, school, employer, interests); order by score DESC. |
| `single_first` | Put `relationship_status = single` first, then by relevance/recency. |
| `same_area_first` | Same region/district as viewer first, then others. |
| `most_shared_interests` | Order by number of shared interests with viewer DESC. |
| `least_male_friends` | Order by male friends count ASC (requires gender breakdown of friends). |
| `least_female_friends` | Order by female friends count ASC. |
| `verified` | When in the list: filter to verified only and/or boost verified in ranking. |
| `possible_business_connection` | When in the list: filter or boost possible business connections. |
| `possible_employer` | When in the list: filter or boost possible employers. |

---

## 4. Response format (exact structure)

**HTTP:** `200 OK` for success (including zero results and discovery feed). Use **400** only for other validation failures (e.g. invalid param value). Empty `q` with no filters is **not** an error; treat as discovery mode.

**Body:** JSON object:

```json
{
  "success": true,
  "data": [ /* array of person objects, see §5 */ ],
  "meta": {
    "current_page": 1,
    "per_page": 20,
    "total": 42,
    "last_page": 3
  }
}
```

- `success` (boolean): MUST be `true` for a successful search.
- `data` (array): List of person objects. Empty array when no results.
- `meta` (object): Pagination. MUST include:
  - `current_page` (int)
  - `per_page` (int)
  - `total` (int)
  - `last_page` (int)

On error (e.g. 400): return a body with `"success": false` and `"message": "..."` (string). Flutter shows `message` to the user.

---

## 5. Person object in `data[]` (exact field names)

Use **snake_case** keys. Flutter maps them to `PersonSearchResult` and displays cards accordingly. Omit optional keys if not available; use `null` where allowed.

### Required (minimal for a card)

| Key | Type | Notes |
|-----|------|--------|
| `id` | int | User ID. |
| `first_name` | string | Required. |
| `last_name` | string | Required. |
| `friends_count` | int | Default 0 if missing. |
| `posts_count` | int | Default 0 if missing. |
| `photos_count` | int | Default 0 if missing. |
| `mutual_friends_count` | int | Count of mutual friends with `user_id`; 0 if not computed. |
| `friendship_status` | string | One of: `none`, `friends`, `pending_sent`, `pending_received`. |
| `in_common` | array of strings | List of short labels (e.g. "Same district", "Same school", "3 mutual friends"). Can be empty `[]`. |
| `is_online` | boolean | Whether the user is currently online. |

### Optional but recommended (rich cards and filters)

| Key | Type | Notes |
|-----|------|--------|
| `username` | string \| null | Shown as @username. |
| `gender` | string \| null | e.g. `male`, `female`. |
| `age` | int \| null | Derived from date_of_birth if available. |
| `profile_photo_path` | string \| null | Relative path; app prepends storage URL. |
| `cover_photo_path` | string \| null | Same. |
| `bio` | string \| null | Searchable; can be used in relevance. |
| `region_name` | string \| null | e.g. Dar-es-salaam. |
| `district_name` | string \| null | e.g. Kinondoni. |
| `location_string` | string \| null | Full hierarchy for display. |
| `relationship_status` | string \| null | single, in_relationship, married, etc. |
| `primary_school` | string \| null | Searchable + context line. |
| `secondary_school` | string \| null | Searchable + context line. |
| `university` | string \| null | Searchable + context line. |
| `employer` | string \| null | Searchable + context line. |
| `last_seen_at` | string \| null | ISO 8601 datetime. |
| `last_active_at` | string \| null | ISO 8601 datetime. |
| `created_at` | string \| null | ISO 8601 datetime. |

**Privacy:** Only include fields the profile owner allows the viewer (`user_id`) to see. Exclude blocked users and users who blocked the viewer. Exclude users who opted out of discoverability if applicable.

**Do not expose:** Phone, email, or other sensitive data in this endpoint.

---

## 6. Validation and errors

| Case | HTTP | Body |
|------|------|------|
| Success (with or without results) | 200 | `{ "success": true, "data": [...], "meta": {...} }` |
| Empty `q` and no filters (discovery) | 200 | Same as success; return discovery feed (composite scoring, day-seeded variety). **Do not** return 400. |
| Unauthorized | 401 | Standard auth error. |
| Invalid params (e.g. invalid sort) | 422 | Optional; `{ "success": false, "message": "...", "errors": {...} }` |
| Server error | 500 | Flutter shows generic error and retry. |

---

## 7. Behaviour summary

- **Search (`q`):** Match at least first name, last name, username. Ideally also bio, location_string, schools, employer. Typo tolerance (e.g. Meilisearch or PostgreSQL FTS) is recommended.
- **Filters:** Apply all provided query params (gender, relationship_status, online, location, employer, school, sector, has_photo, age_min, age_max, student, has_interests, profile_complete, friends_of_friends_only, verified, possible_business_connection, possible_employer) as AND conditions.
- **Sort:** Apply primary sort from first value in `sort`; use remaining values as tie-breakers or filters/boosts as described in §3.
- **Pagination:** Use `page` and `per_page`; return `meta.current_page`, `meta.per_page`, `meta.total`, `meta.last_page` so the app can show “Load more” and know when to stop.

---

## 8. Checklist for backend implementation

- [ ] `GET /api/people/search` with auth.
- [ ] Accept `user_id`, `q`, `page`, `per_page`, `sort` (single or comma-separated), and all filter params in §2.
- [ ] Treat empty `q` with no filters as **discovery mode** (200 + discovery feed); do **not** return 400 for that case.
- [ ] Response: `{ "success": true, "data": [...], "meta": { "current_page", "per_page", "total", "last_page" } }`.
- [ ] Each item in `data`: at least `id`, `first_name`, `last_name`, `friends_count`, `posts_count`, `photos_count`, `mutual_friends_count`, `friendship_status`, `in_common`, `is_online`; plus optional fields in §5.
- [ ] Compute `friendship_status` and `mutual_friends_count` relative to `user_id`.
- [ ] Populate `in_common` with short labels (e.g. same district, same school, mutual friends count).
- [ ] Respect privacy and blocking; exclude non-discoverable users.
- [ ] Support all sort keys in §3; support comma-separated `sort` with first as primary and rest as tie-breakers/filters.

---

## 9. Optional improvements

- **Typo-tolerant search:** e.g. Laravel Scout + Meilisearch (or PostgreSQL FTS with stemmer).
- **Rate limiting:** e.g. 60 requests/min per user on `/api/people/search`.
- **Caching:** Short TTL cache for repeated or popular queries.
- **Facets endpoint:** `GET /api/people/search/facets` returning suggested values for location, employer, school (for future filter chips/autocomplete).

Once the backend implements the above, the Flutter People screen will work without further client changes.
