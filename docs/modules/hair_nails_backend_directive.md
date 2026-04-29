# Hair & Nails API — Backend implementation directive

**Audience:** Laravel (or compatible) API engineers  
**Source of truth for behaviour:** Flutter `lib/hair_nails/services/hair_nails_service.dart`, `lib/hair_nails/services/hair_nails_cache_service.dart` (offline queue keys only — still posts to this API), and `lib/hair_nails/models/hair_nails_models.dart`.  
**Base path:** All routes below are under the existing API prefix, e.g. `https://<host>/api/hair-nails/...` (`ApiConfig.baseUrl` ends with `/api`).

**Related:** Product context — `docs/modules/hair_nails.md`; journeys — `docs/modules/hair_nails_user_journeys.md`.

**Cross-module (not under `/hair-nails/`):** The app also calls **Events** (`POST /api/events` — multipart), **Expenditures** (`POST /api/expenditures`), **Shop** (marketplace screens), **Doctor** (`FindDoctorPage` with dermatology), **Tea/Shangazi** (`TeaChatScreen`), and **Tajirika** (`GET /api/tajirika/partners?...`). Those contracts live in their own directives; §10 summarizes what Hair & Nails triggers.

---

## 1. Authentication and authorization

- **Mechanism:** Laravel Sanctum — `Authorization: Bearer <access_token>` on **every** endpoint below. The mobile client sends this on all requests (`HairNailsService`).
- **User scoping:** For any request that includes `user_id` (query or JSON body), **reject** if `(int) $request->input('user_id') !== (int) $request->user()->id` with **403** or **422** and a clear `message`. Bookings, profile, saved styles, and growth logs must never leak or mutate another user’s rows.
- **Unauthenticated:** Return **401** with `{"message":"Unauthenticated."}` when the token is missing or invalid.

---

## 2. Response envelope (required)

The Flutter client checks `success` and parses `data` or shows `message` on failure.

**Success (single object):**

```json
{
  "success": true,
  "data": { }
}
```

**Success (list):**

```json
{
  "success": true,
  "data": [ ]
}
```

**Error:**

```json
{
  "success": false,
  "message": "Human-readable message"
}
```

Use **HTTP 200** for successful JSON where `success: true` matches current app behaviour; **422** is acceptable for validation if the same JSON shape is returned. The app primarily keys off `success`, not only HTTP status.

---

## 3. Enumerations (must match `.name` / JSON strings from Flutter)

Strings are **case-sensitive** as produced by Dart enums (`camelCase` where noted).

### 3.1 `hair_type`

`straight1` | `wavy2` | `curly3a` | `curly3b` | `curly3c` | `coily4a` | `coily4b` | `coily4c`

### 3.2 `porosity`

`low` | `normal` | `high`

### 3.3 `density`

`thin` | `medium` | `thick`

### 3.4 `current_state`

`natural` | `relaxed` | `transitioning` | `colorTreated` | `locced`

### 3.5 `goals` (array of strings)

Free-form list from client (Swahili phrases in UI). Store as JSON array of strings; optional max length per item.

### 3.6 Service / style `category` (salon services & style gallery)

`hair` | `nails` | `skin` — **ServiceCategory** (salon line items).

Style inspiration uses **StyleCategory**:

`braids` | `twists` | `locs` | `weaves` | `natural` | `updos` | `nails`

### 3.7 `booking.status`

`pending` | `confirmed` | `completed` | `cancelled`

### 3.8 `payment_status`

`unpaid` | `deposit` | `paid`

### 3.9 Booking rating (rate endpoint)

Integer **1–5** (validate server-side).

---

## 4. Endpoints

### 4.1 Hair profile

| Method | Path | Description |
|--------|------|-------------|
| **GET** | `/hair-nails/profile` | Query: `user_id` (required) |
| **POST** | `/hair-nails/profile` | Create/update (upsert) |

**POST JSON:**

```json
{
  "user_id": 31,
  "hair_type": "coily4a",
  "porosity": "normal",
  "density": "medium",
  "length_cm": 12.5,
  "current_state": "natural",
  "scalp_condition": "Nzuri",
  "goals": ["Ukuaji wa nywele", "Unyevu zaidi"]
}
```

`length_cm`, `scalp_condition` optional. Omit `length_cm` if unknown.

**`data` object (GET/POST success):**

| Field | Type |
|-------|------|
| `id` | int |
| `user_id` | int |
| `hair_type` | string (§3.1) |
| `porosity` | string (§3.2) |
| `density` | string (§3.3) |
| `length_cm` | number or null |
| `current_state` | string (§3.4) |
| `scalp_condition` | string or null |
| `goals` | string[] |

---

### 4.2 Salons

| Method | Path | Description |
|--------|------|-------------|
| **GET** | `/hair-nails/salons` | List + filters |
| **GET** | `/hair-nails/salons/{id}` | Detail |
| **GET** | `/hair-nails/salons/{id}/reviews` | Paginated reviews — query **`page`** (required for “load more”) |

**Reviews list (`GET .../reviews`):**

- Query: **`page`** (default **1**). Return a **flat array** in `data` (same envelope as §2).
- The Flutter client loads **page 1** on salon open, then **page 2+** when the user taps “Onyesha tathmini zaidi”. It assumes **~15 reviews per page**: if `data.length < 15`, **no further pages** are requested.
- Order: **newest first** recommended (matches user expectations).

**GET list query parameters:**

| Param | Meaning |
|-------|---------|
| `page` | Page number (default 1). Client treats **~15 items per page** as “maybe more”: if a page returns **fewer than 15** salons, infinite scroll stops. |
| `search` | Free text |
| `category` | Service category filter — `hair` \| `nails` \| `skin` (string name) |
| `min_rating` | Minimum average rating (float) |
| `home_based` | `1` = filter home-based salons |
| `mobile` | `1` = mobile service |
| `walk_in` | `1` = walk-in accepted |
| `latitude` / `longitude` | Optional — for distance sort / `distance_km` in response |

**`data`:** JSON **array** of salon objects (client maps `data` as a list).

**Salon object (list or detail):**

| Field | Type |
|-------|------|
| `id` | int |
| `name` | string |
| `address` | string or null |
| `phone` | string or null |
| `latitude` | number or null |
| `longitude` | number or null |
| `distance_km` | number or null |
| `rating` | number |
| `total_reviews` | int |
| `image_url` | string or null |
| `photos` | string[] (URLs) |
| `is_home_based` | bool |
| `is_mobile` | bool |
| `is_verified` | bool |
| `is_walk_in` | bool |
| `opening_hours` | string or null |
| `description` | string or null |
| `services` | array of **SalonService** |
| `staff` | array of **SalonStaff** |

**SalonService:**

| Field | Type |
|-------|------|
| `id` | int |
| `salon_id` | int |
| `category` | `hair` \| `nails` \| `skin` |
| `name` | string |
| `price` | number (TZS or app currency) |
| `duration_minutes` | int |
| `description` | string or null |

**SalonStaff:**

| Field | Type |
|-------|------|
| `id` | int |
| `name` | string |
| `photo_url` | string or null |
| `specialty` | string or null |
| `experience_years` | int |

**Review object (`GET .../reviews`):**

| Field | Type |
|-------|------|
| `id` | int |
| `user_id` | int |
| `user_name` | string |
| `user_photo_url` | string or null |
| `salon_id` | int |
| `rating` | int (1–5) |
| `comment` | string or null |
| `created_at` | ISO8601 string |

---

### 4.3 Bookings

| Method | Path | Description |
|--------|------|-------------|
| **POST** | `/hair-nails/bookings` | Create booking |
| **GET** | `/hair-nails/bookings` | Query: `user_id` — list user’s bookings |
| **POST** | `/hair-nails/bookings/{id}/cancel` | Cancel (no body required; auth user must own booking) |
| **POST** | `/hair-nails/bookings/{id}/rate` | Rate after completion |

**POST create JSON:**

```json
{
  "user_id": 31,
  "salon_id": 5,
  "service_id": 102,
  "date_time": "2026-04-15T10:00:00.000Z",
  "notes": "optional",
  "payment_method": "mpesa",
  "phone_number": "+2557..."
}
```

`notes`, `payment_method`, `phone_number` optional.

**`payment_method` (string, optional)** — values the **current** app sends:

| Value | Meaning |
|-------|---------|
| `mpesa` | M-Pesa; **`phone_number` required** (normalized `+255…`) when this method is selected |
| `wallet` | TAJIRI Wallet |
| `card` | Card / online checkout (implementation may still complete via wallet or PSP — store intent on booking) |
| `cash` | Pay at salon |

Validate and persist whichever fields your payment integration needs; reject **`mpesa`** without a valid `phone_number` with **422** and `success: false`.

**`data` (booking object):**

| Field | Type |
|-------|------|
| `id` | int |
| `user_id` | int |
| `salon_id` | int |
| `salon_name` | string |
| `service_id` | int |
| `service_name` | string |
| `date_time` | ISO8601 string |
| `status` | string (§3.7) |
| `total_amount` | number |
| `payment_status` | string (§3.8) |
| `notes` | string or null |
| `salon_image_url` | string or null — **recommended** on list/detail responses (full URL or storage path resolvable by app); used on **booking cards** in the UI |

**POST `/bookings/{id}/rate` JSON:**

```json
{
  "rating": 5,
  "comment": "optional"
}
```

Success: `{ "success": true }` (no `data` required for cancel/rate if client only checks `success`).

---

### 4.4 Style gallery

| Method | Path | Description |
|--------|------|-------------|
| **GET** | `/hair-nails/styles` | Query: `page`, optional `category` (StyleCategory §3.6) |
| **GET** | `/hair-nails/styles/saved` | Query: `user_id` |
| **POST** | `/hair-nails/styles/{id}/save` | Save style for user |
| **DELETE** | `/hair-nails/styles/{id}/save` | **Unsave** — see below |

**POST save JSON:**

```json
{
  "user_id": 31
}
```

**DELETE unsave (required for parity with Flutter):**

- **URL:** `DELETE /hair-nails/styles/{id}/save?user_id=31`
- **Auth:** Bearer (same as other routes).
- **Query:** `user_id` — must match authenticated user (**403/422** if not).
- **Success:** `{ "success": true }` with HTTP **200** (same envelope as §2).
- **Failure:** `{ "success": false, "message": "…" }` if not saved or invalid id.

The client calls **DELETE** when the user removes a bookmark from **saved styles** or toggles save off in the gallery (`HairNailsService.unsaveStyle`). If your API preferred `POST .../unsave`, update the client instead — **DELETE + query** is what ships today.

**Style object (`data` array items):**

| Field | Type |
|-------|------|
| `id` | int |
| `title` | string |
| `category` | string (StyleCategory §3.6) |
| `image_url` | string or null |
| `description` | string or null |
| `estimated_price` | number or null |
| `estimated_duration_minutes` | int or null |
| `hair_type_recommended` | string[] (hair_type enum names) |
| `is_saved` | bool (true when listing saved or context implies saved) |

---

### 4.5 Growth tracking

| Method | Path | Description |
|--------|------|-------------|
| **POST** | `/hair-nails/growth` | Log measurement |
| **GET** | `/hair-nails/growth` | Query: `user_id` — history |

**POST JSON:**

```json
{
  "user_id": 31,
  "length_cm": 18.0,
  "photo_url": "https://...",
  "notes": "optional"
}
```

`photo_url` optional — may be filled after file upload via your file pipeline; client may send URL returned from another upload endpoint.

**`data` (single log):**

| Field | Type |
|-------|------|
| `id` | int |
| `user_id` | int |
| `date` | ISO8601 or `Y-m-d` (client parses with `DateTime.parse`) |
| `length_cm` | number |
| `photo_url` | string or null |
| `notes` | string or null |

**GET success:** `data` = array of growth log objects, newest first recommended.

**Privacy (client-only):** “Hide growth photos on device” is stored in **Hive** (`HairNailsCacheService` — `growth_privacy` flag). It **does not** change API payloads; photos are still stored if `photo_url` was sent on **POST**. A future enhancement could add `photo_visible` or signed URLs per user — not required for current app behaviour.

---

## 5. Offline hair profile queue (client behaviour; same API)

When **`POST /hair-nails/profile`** fails (network/server), the app **persists the last POST body** in Hive and retries on next module open via **`POST /hair-nails/profile`** (`HairNailsService.trySyncPendingProfile`). Backend should:

- Treat **POST profile** as **idempotent** for the same `user_id` (upsert by `user_id`).
- Return the same **§4.1** `data` shape on success so the client can clear the queue.

No extra endpoints are required.

---

## 6. Pagination (optional enhancement)

The Flutter list endpoints expect `data` as a **flat array**. If you use Laravel pagination, either:

- Return `{ "success": true, "data": [ ...items ], "meta": { "current_page", "last_page", ... } }` and ensure **`data` remains the array of items** (client does not read `meta` today), or  
- Flatten items into `data` only for v1.

---

## 7. Suggested persistence (Laravel)

| Table / area | Notes |
|--------------|--------|
| `hair_profiles` | `user_id` unique; JSON `goals`; enums as string columns |
| `salons`, `salon_services`, `salon_staff` | Services belong to salon; category enum |
| `bookings` | FK user, salon, service; `date_time`; status; payment_status; amounts |
| `salon_reviews` | Optional: created via `rate` on completed booking |
| `style_inspirations` | Seed catalog; M:N `user_saved_styles` (unique `(user_id, style_id)`; **DELETE** removes row) |
| `hair_growth_logs` | `user_id`, `date`, `length_cm`, `photo_url`, `notes` |

Add indexes on `bookings(user_id, date_time)`, `hair_growth_logs(user_id, date)`.

---

## 8. Registration in `routes/api.php`

Example:

```php
Route::middleware('auth:sanctum')->prefix('hair-nails')->group(function () {
    // profile, salons, bookings, styles (POST save + DELETE save), growth
});
```

Use **kebab-case** URL segment `hair-nails` to match the client exactly.

---

## 9. QA checklist

1. Login: `POST /api/users/login-by-phone` → `access_token`.
2. `GET /api/hair-nails/profile?user_id=<auth_id>` with `Authorization: Bearer …` → **200**, `success: true`.
3. `POST /api/hair-nails/profile` with valid enum strings → profile returned.
4. `GET /api/hair-nails/salons?page=1` → array in `data`.
5. Create booking → appears in `GET .../bookings?user_id=`.
6. `POST .../bookings/{id}/cancel` and `.../rate` as owning user.
7. `POST .../styles/{id}/save` then `GET .../styles/saved?user_id=` shows the style; **`DELETE .../styles/{id}/save?user_id=`** removes it from saved (`success: true`).
8. `POST .../growth` → `GET .../growth?user_id=` includes new row.
9. **`GET .../salons/{id}/reviews?page=1`** then **`?page=2`** returns additional reviews when enough exist; page size consistent with **§4.2** (~15).
10. **`POST .../bookings`** with `payment_method`: `mpesa` \| `wallet` \| `cash` \| `card` — reject `mpesa` without valid `phone_number`.
11. Booking responses include **`salon_image_url`** when available (cards in UI).
12. Request with `user_id` ≠ auth user → **403/422**.
13. No `Authorization` header → **401**.

---

## 10. Cross-module hooks (Hair & Nails UI → other APIs)

These are **not** `/hair-nails/*` routes but are invoked from **`lib/hair_nails/services/hair_nails_integrations.dart`** and related screens so product behaviour is end-to-end testable.

| Flow | API / screen | Notes |
|------|----------------|------|
| After booking — “Zaidi” sheet | **`POST /api/events`** (multipart `EventService.createEvent`) | Creates a **personal** calendar-style event (salon name, datetime, optional lat/lng). **Auth:** event pipeline may need to align with your `events` controller (creator_id = user). |
| After booking — budget | **`POST /api/expenditures`** | `ExpenditureService.recordExpenditure`: `category` e.g. `beauty`, `source_module`: `hair_nails`, `reference_id`: `hair_booking_{id}`. |
| Shop | **`ShopScreen`** | `initialSearchQuery` e.g. hair-care keywords — marketplace API unchanged. |
| Dermatologist | **`FindDoctorPage`** | **`initialSpecialty`** = dermatology — uses **Doctor** module API. |
| Tajirika partners | **`GET /api/tajirika/partners`** | Query includes **`skills`** (comma-separated). Client uses **`hair_nails`** as a **domain/skill filter** for the Hair & Nails partner list (`HairNailsPartnersPage`). Backend must accept this filter and return partners tagged for beauty/hair/nails **or** document the canonical skill keys your API expects so the client can be adjusted. |
| Shangazi / Tea | **`TeaChatScreen(initialMessage: …)`** | No Hair & Nails REST endpoint; sends contextual prompt with optional **hair profile** summary. |

---

## 11. Changelog reference (client)

| Item | Path |
|------|------|
| HTTP client | `lib/hair_nails/services/hair_nails_service.dart` |
| Integrations (events, expenditure, navigation) | `lib/hair_nails/services/hair_nails_integrations.dart` |
| Hive cache (home snapshot, growth prefs, **pending profile** queue) | `lib/hair_nails/services/hair_nails_cache_service.dart` |
| Tajirika discovery UI | `lib/hair_nails/pages/hair_nails_partners_page.dart` |
| Models | `lib/hair_nails/models/hair_nails_models.dart` |

**Note:** `NailLog` exists in models but **has no API methods** in `HairNailsService` yet — future nails-specific logging.

---

*Document aligned with TAJIRI Flutter Hair & Nails module (2026-04-12) — hand to backend for Laravel implementation.*
