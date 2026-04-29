# Skin Care API — Backend implementation directive

**Audience:** Laravel (or compatible) API engineers  
**Source of truth for behaviour:** Flutter client `lib/skincare/services/skincare_service.dart` and `lib/skincare/models/skincare_models.dart`  
**Base path:** All routes below are mounted under the existing API prefix, e.g. `https://<host>/api/skincare/...` (production uses `/api` from `ApiConfig.baseUrl`).

---

## 1. Authentication and authorization

- **Mechanism:** Laravel Sanctum — `Authorization: Bearer <access_token>` on every endpoint listed (same as the rest of the authenticated app).
- **User scoping:** For any request that includes `user_id` (query or body), **reject** if `user_id !== (int) $request->user()->id` with **403** (or **422** with a clear message). Do not allow reading or writing another user’s skincare data.
- **Unauthenticated requests** must return Laravel’s standard `401` with `{"message":"Unauthenticated."}` when the token is missing or invalid.

---

## 2. Response envelope (required)

The mobile client checks `success` and parses `data` or shows `message` on failure.

**Success (single resource):**

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
  "message": "Human-readable validation or error message"
}
```

Use **HTTP 200** for successful JSON responses where the client already checks `success` (this matches current Flutter usage). Validation errors should still return **`message`** in the body; **422** is acceptable if the JSON shape above is preserved.

---

## 3. Enumerations (must match exactly)

Strings are **case-sensitive** as sent by the app (snake_case / lowercase as listed).

### 3.1 `skin_type`

`oily` | `dry` | `combination` | `sensitive` | `normal`

### 3.2 `concerns` (array of strings)

`acne` | `darkSpots` | `wrinkles` | `unevenTone` | `dryness` | `oiliness` | `largePores` | `darkCircles` | `keloids`

### 3.3 `climate_zone`

`pwani` | `bara` | `ziwa`

### 3.4 `budget` (stored and validated in API — not Swahili)

The app **only sends** these three values after mapping UI bands:

| API value | Meaning (UI) |
|-----------|----------------|
| `low` | Chini |
| `medium` | Wastani (default if missing) |
| `high` | Juu |

Validate with `Rule::in(['low','medium','high'])`. **Do not** accept `chini` / `wastani` / `juu` on the API unless you explicitly add a mapping layer.

### 3.5 Routine `type`

`morning` | `evening`

### 3.6 Routine step `step_type`

`cleanser` | `toner` | `serum` | `moisturizer` | `sunscreen` | `treatment` | `mask`

### 3.7 Diary `mood`

Integer **1–5** (1 worst, 5 best).

### 3.8 Dangerous ingredient `level`

`danger` | `caution` | `safe`

---

## 4. Endpoints

### 4.1 Skin profile

| Method | Path | Query / body |
|--------|------|----------------|
| **GET** | `/skincare/profile` | `user_id` (required) |
| **POST** | `/skincare/profile` | JSON body |

**POST JSON:**

```json
{
  "user_id": 31,
  "skin_type": "combination",
  "skin_tone": "optional string or null",
  "concerns": ["acne", "darkSpots"],
  "climate_zone": "pwani",
  "budget": "medium"
}
```

**`data` object (GET/POST success)** — fields the client reads:

| Field | Type | Notes |
|-------|------|--------|
| `id` | int | Profile row id |
| `user_id` | int | |
| `skin_type` | string | Enum §3.1 |
| `skin_tone` | string or null | |
| `concerns` | string[] | Enum §3.2 |
| `score` | int | App defaults to 0 if omitted |
| `climate_zone` | string | Enum §3.3 |
| `budget` | string | `low` \| `medium` \| `high` |
| `last_analysis_date` | ISO8601 string or null | Optional |

---

### 4.2 Routines

| Method | Path | Notes |
|--------|------|--------|
| **GET** | `/skincare/routines` | Query: `user_id` |
| **POST** | `/skincare/routines` | Create or update (see below) |
| **DELETE** | `/skincare/routines/{id}` | |

**POST JSON (create):**

```json
{
  "user_id": 31,
  "name": "Asubuhi",
  "type": "morning",
  "is_active": true,
  "steps": [
    {
      "order": 1,
      "step_type": "cleanser",
      "product_name": "optional",
      "instructions": "optional",
      "wait_time_seconds": 0
    }
  ]
}
```

**POST JSON (update):** include existing routine id:

```json
{
  "id": 12,
  "user_id": 31,
  "name": "...",
  "type": "morning",
  "is_active": true,
  "steps": [ ]
}
```

**`data` for one routine:**

| Field | Type |
|-------|------|
| `id` | int |
| `user_id` | int |
| `name` | string |
| `type` | `morning` \| `evening` |
| `is_active` | bool |
| `steps` | array of step objects (snake_case keys as in POST) |

**GET success:** `data` is an **array** of routine objects.

---

### 4.3 Diary

| Method | Path | Notes |
|--------|------|--------|
| **GET** | `/skincare/diary` | Query: `user_id`, optional `month` (1–12), `year` (e.g. 2026) — filter entries for that calendar month |
| **POST** | `/skincare/diary` | JSON **or** `multipart/form-data` (photo) |
| **PUT** | `/skincare/diary/{id}` | JSON body only (no photo update required in v1) |
| **DELETE** | `/skincare/diary/{id}` | |

**POST JSON:**

```json
{
  "user_id": 31,
  "date": "2026-04-12",
  "mood": 3,
  "tags": ["tag1"],
  "products_used": ["Product A"],
  "notes": "optional"
}
```

**POST multipart** (`Content-Type: multipart/form-data` — client **removes** `Content-Type` so the boundary is set automatically):

| Part | Name | Content |
|------|------|---------|
| field | `user_id` | string digits |
| field | `date` | `Y-m-d` |
| field | `mood` | string digits |
| field | `tags` | **JSON-encoded array string**, e.g. `["a","b"]` |
| field | `products_used` | **JSON-encoded array string** |
| field | `notes` | optional |
| file | `photo` | image/jpeg, image/png, or image/webp |

On success, persist the file (e.g. `storage/app/public/...`) and expose a **`photo_url`** that the app can load (absolute URL or path resolvable under your `APP_URL` + `/storage/...`).

**PUT JSON** (`/skincare/diary/{id}`):

```json
{
  "user_id": 31,
  "date": "2026-04-12",
  "mood": 4,
  "tags": [],
  "products_used": [],
  "notes": null
}
```

Accept **200** or **201** for PUT (client accepts both).

**Diary `data` object:**

| Field | Type |
|-------|------|
| `id` | int |
| `user_id` | int |
| `date` | string `Y-m-d` (client parses with `DateTime.parse`) |
| `mood` | int 1–5 |
| `tags` | string[] |
| `products_used` | string[] |
| `notes` | string or null |
| `photo_url` | string or null |

**DELETE:** On success, remove stored photo file if present. Return `{ "success": true }`.

---

### 4.4 Products (catalog)

| Method | Path | Query |
|--------|------|--------|
| **GET** | `/skincare/products` | `page` (default 1), optional `category`, `skin_type`, `concern`, `search` |
| **GET** | `/skincare/products/{id}` | — |

**GET list success:** `data` MUST be a **JSON array** of product objects (the client does `data['data'] as List`, not nested pagination wrapper). If you use Laravel pagination internally, **map** the collection into `data` and optionally add `meta` in a separate key only if the client is updated later.

**Product object fields:**

| Field | Type |
|-------|------|
| `id` | int |
| `name` | string |
| `brand` | string or null |
| `category` | string |
| `skin_types` | string[] (enum §3.1 names) |
| `concerns` | string[] (enum §3.2 names) |
| `price` | number |
| `rating` | number |
| `image_url` | string or null |
| `ingredients` | string[] |
| `is_tmda_approved` | bool |
| `description` | string or null |

---

### 4.5 Dangerous ingredients (reference list)

| Method | Path |
|--------|------|
| **GET** | `/skincare/dangerous-ingredients` |

**Success:** `data` = array of:

```json
{
  "name": "string",
  "level": "danger|caution|safe",
  "reason": "string"
}
```

---

### 4.6 Recommendations

| Method | Path | Query |
|--------|------|--------|
| **GET** | `/skincare/recommendations` | `user_id` |

**Success:** `data` = array of **product** objects (same shape as §4.4). Implementation may use profile + rules, scoring, or future ML — contract is list of products only.

---

## 5. Suggested persistence (Laravel)

- **`skincare_profiles`** — `user_id` unique, columns for enums above, `concerns` JSON array, `budget` string.
- **`skincare_routines`** — `user_id`, `name`, `type`, `is_active`, `steps` JSON.
- **`skincare_diary_entries`** — `user_id`, `date` (date), `mood`, `tags` JSON, `products_used` JSON, `notes` text nullable, `photo_path` or `photo_url` nullable.
- **`skincare_products`** — catalog; seed minimal rows for QA.
- **`skincare_dangerous_ingredients`** — `name`, `level`, `reason`; seed reference rows.

Add foreign keys to `users` where appropriate. Index `diary` by `(user_id, date)` and filter by month/year in queries.

---

## 6. Registration in `routes/api.php`

Example:

```php
Route::middleware('auth:sanctum')->prefix('skincare')->group(function () {
    // profile, routines, diary, products, dangerous-ingredients, recommendations
});
```

---

## 7. QA checklist (curl / Postman)

1. Login via existing `POST /api/users/login-by-phone`, copy `access_token`.
2. `GET /api/skincare/dangerous-ingredients` with `Authorization: Bearer …` → **200**, `success: true`, `data` array.
3. `POST /api/skincare/profile` with body from §4.1, `budget: "medium"` → **200**, `success: true`.
4. `POST /api/skincare/diary` with multipart `photo` → entry has `photo_url`.
5. `PUT` and `DELETE` diary entry for same user.
6. Call any endpoint with **wrong** `user_id` → **403/422**, not another user’s data.
7. Call without `Authorization` → **401** `Unauthenticated`.

---

## 8. Changelog reference

| Item | Detail |
|------|--------|
| Client implementation | `lib/skincare/services/skincare_service.dart` |
| Models / enums | `lib/skincare/models/skincare_models.dart` |
| Budget API values | `low` / `medium` / `high` only (see `SkincareBudgetMapping`) |

---

*Document generated for backend parity with TAJIRI Flutter Skin Care module.*
