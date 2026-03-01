# TAJIRI Backend Requirements

This file collects all backend API requirements from each implemented story. Each story that needs backend data or sends data to the backend appends its requirements here.

## Format per story

```
## Story {id}: {title}
- Endpoints: [list]
- Request/response: [formats]
- Expectations: [what the frontend expects from backend]
```

---

## Story 4: Location Hierarchy Selection

- **Endpoints:**
  - `GET /api/locations/regions` – returns list of regions
  - `GET /api/locations/regions/{id}/districts` – returns districts for region
  - `GET /api/locations/districts/{id}/wards` – returns wards for district
  - `GET /api/locations/wards/{id}/streets` – returns streets for ward

- **Request/response:**
  - All are GET, no request body. Path parameter `{id}` is the integer ID of the parent entity.
  - Expected response shape (frontend parses `success` and `data`):
    ```json
    { "success": true, "data": [ ... ] }
    ```
  - **Regions:** each item `{ "id": int, "name": string, "post_code": string? }`
  - **Districts:** each item `{ "id": int, "region_id": int, "name": string, "post_code": string? }`
  - **Wards:** each item `{ "id": int, "district_id": int, "name": string, "post_code": string? }`
  - **Streets:** each item `{ "id": int, "ward_id": int, "name": string }`

- **Registration payload (location):**  
  When the user completes registration, the frontend sends the selected location in the registration payload as part of `POST /api/users/register` (or equivalent). The `location` object is:
  ```json
  {
    "region_id": int,
    "region_name": string,
    "district_id": int,
    "district_name": string,
    "ward_id": int,
    "ward_name": string,
    "street_id": int,
    "street_name": string
  }
  ```
  It may be `null` if the user skipped the location step.

- **Expectations:**
  - Endpoints return 200 with JSON body; frontend expects `success === true` and `data` as array of objects with the fields above.
  - On non-200 or `success !== true`, frontend treats as failure and shows an error (e.g. "Imeshindwa kupakia mikoa" for regions).
  - Backend should accept and persist the `location` object in the registration payload when present.

---

## Story 6: Secondary School Picker

- **Endpoints**
  - `GET /api/secondary-schools/regions` — list regions with O-Level school counts.
  - `GET /api/secondary-schools/regions/{regionCode}/districts` — list districts in a region with school counts.
  - `GET /api/secondary-schools/districts/{districtCode}/schools` — list schools in a district. Optional query: `region_code` when `districtCode` is `OTHER`.
  - `GET /api/secondary-schools/search?q=...&limit=...` — search schools by name (and optionally by region/district). Optional query params: `region_code`, `district_code` to filter results.

- **Request/response**
  - All GET; no request body.
  - Response envelope: `{ "success": true, "data": [...] }`.
  - Region item: `{ "region": string, "region_code": string, "school_count": number }`.
  - District item: `{ "district": string, "district_code": string, "school_count": number }`.
  - School item: `{ "id": number, "code": string, "name": string, "type": "government"|"private", "region_code"?: string, "district_code"?: string, "region"?: string, "district"?: string }`.

- **Expectations**
  - Backend must expose 5,500+ O-Level secondary schools.
  - Search must support finding schools by **region**, **district**, and **name** (e.g. `q` may match name, region name, or district name; and/or `region_code`/`district_code` filter the result set).

---

## Story 5: Primary School Picker

- **Endpoints:**
  - `GET /api/schools/regions` – list regions with primary school counts
  - `GET /api/schools/regions/{region_code}/districts` – list districts in a region
  - `GET /api/schools/districts/{district_code}/schools` – list primary schools in a district
  - `GET /api/schools/search?q=...&limit=...&region_code=...&district_code=...` – search primary schools (16,000+ in Tanzania DB)

- **Request/response:**
  - **Regions:** `GET /api/schools/regions` → `{ "success": true, "data": [ { "region": string, "region_code": string, "school_count": number } ] }`
  - **Districts:** `GET /api/schools/regions/{region_code}/districts` → `{ "success": true, "data": [ { "district": string, "district_code": string, "school_count": number } ] }`
  - **Schools in district:** `GET /api/schools/districts/{district_code}/schools` → `{ "success": true, "data": [ { "id": number, "code": string, "name": string, "type": "government"|"private", "region": string?, "district": string? } ] }`
  - **Search:** `GET /api/schools/search?q=<query>&limit=30&region_code=<opt>&district_code=<opt>` → same school array as above; `region_code` and `district_code` optional filters.

- **Expectations:**
  - Frontend uses these for registration Step 3 (Primary School). SchoolPicker supports browse (region → district → school) and search with optional region/district filters.
  - Response must include `success: true` and `data` array. Empty array when no results. Errors: frontend treats non-200 or missing `success` as failure and shows retry/empty state.

---

## Story 8: University & Programme Picker

- **Endpoints:**
  - `GET /api/universities-detailed` – List all universities (optional query: `type` for filtering by type).
  - `GET /api/universities-detailed?type={type}` – List universities filtered by type.
  - `GET /api/universities-detailed/search?q={query}` – Search universities by name/code (query encoded).
  - `GET /api/universities-detailed/types` – List university types (e.g. public_university, private_university).
  - `GET /api/universities-detailed/{universityId}/colleges` – Colleges/schools/faculties for a university.
  - `GET /api/universities-detailed/colleges/{collegeId}/departments` – Departments for a college.
  - `GET /api/universities-detailed/departments/{departmentId}/programmes` – Programmes for a department.
  - `GET /api/universities-detailed/{universityId}/programmes` – All programmes for a university.
  - `GET /api/universities-detailed/programmes/search?q={query}` – Search programmes by name (optional: `&level={level}`).

- **Request/response:**
  - All GET; no request body.
  - Response envelope: `{ "success": true, "data": ... }`. On failure frontend expects non-200 or `success: false`.
  - **Universities list** (`data`): array of `{ id, code, name, acronym?, type, region?, established?, website? }`.
  - **Types** (`data`): map or array of type code → label.
  - **Colleges** (`data`): array of `{ id, code, name, type?, university_id }`.
  - **Departments** (`data`): array of `{ id, code, name, college_id }`.
  - **Programmes** (`data`): array of `{ id, code, name, level_code|degree_level, duration, college_id?, department_id?, university_id, department?, college?, university? }` (duration in years; optional display names for department, college, university).

- **Expectations:**
  - At least **50+ universities** with full hierarchy (colleges → departments → programmes).
  - TCU-aligned or equivalent reference data; types as in DOCS/design (e.g. public_university, private_university, public_college, private_college).
  - Search endpoints return results consistent with the same model shapes; programme search should include university (and optionally department/college) for display.

---

## Story 7: A-Level School & Combination Picker

- **Endpoints:**
  - `GET /api/alevel-schools/regions` – List regions with A-Level school counts.
  - `GET /api/alevel-schools/regions/{regionCode}/districts` – List districts in a region with school counts.
  - `GET /api/alevel-schools/districts/{districtCode}/schools` – List A-Level schools in a district (query param `region_code` when `districtCode` is `OTHER`). Backend must support 900+ schools across all regions/districts.
  - `GET /api/alevel-schools/search?q={query}&limit={limit}` – Search A-Level schools by name (frontend uses limit 30–50).
  - `GET /api/alevel-schools/combinations` – List all combinations (e.g. PCB, HGL) with code, name, category, subjects.
  - `GET /api/alevel-schools/{id}/combinations` – List combinations offered by a specific school (combination per school).

- **Request/response:**
  - All GET; no request body.
  - Response shape: `{ "success": true, "data": [...] }`. On error, frontend tolerates empty arrays or non-200.
  - **Regions:** `data` = list of `{ "region": string, "region_code": string, "school_count": number }`.
  - **Districts:** `data` = list of `{ "district": string, "district_code": string, "school_count": number }`.
  - **Schools:** `data` = list of `{ "id": number, "code": string, "name": string, "type": "government"|"private", "region_code"?: string, "district_code"?: string, "region"?: string, "district"?: string, "combinations"?: string[] }`.
  - **Combinations:** `data` = list of `{ "id": number, "code": string, "name": string, "category": string (e.g. "science","arts","business","language","religious"), "popularity"?: "high"|"medium"|"low", "subjects": string[], "careers"?: string[] }`.

- **Expectations:**
  - Backend provides 900+ A-Level schools via regions/districts and/or search.
  - When a school is selected, frontend calls `GET /api/alevel-schools/{id}/combinations` to show combinations for that school; if empty, it falls back to global combinations list.
  - Registration sends selected school id, combination code/name, and graduation year (stored in registration state and submitted with registration payload; see user/profile APIs for persistence).

---

## Story 2: Check Phone Availability

- **Endpoints:** `POST /api/users/check-phone`
- **Request:** JSON body `{ "phone_number": "<E.164 or +255XXXXXXXXX>" }`
- **Response (200):** JSON with availability status, e.g.:
  - `{ "available": true, "message": "optional" }` when the number is not yet registered, or
  - `{ "available": false, "message": "optional" }` when the number is already registered.
  - Backend may alternatively use `"exists": true/false`; frontend treats `exists: true` as unavailable.
- **Expectations:** Endpoint validates phone uniqueness. Frontend calls this from RegistrationScreen → PhoneStep before sending OTP. If unavailable, user sees an error and cannot proceed; if available, user sees confirmation and OTP flow continues.

---

## Story 9: Employer Picker (Business Database)

- **Endpoints**
  - `GET /api/businesses` — List all businesses (paginated or full). Frontend expects 750+ businesses (DSE, Parastatals, Corporates and others).
  - `GET /api/businesses/sectors` — List sectors (e.g. agriculture, mining). Response: `{ "success": true, "data": [ { "code": string, "label": string, "count"?: number } ] }`.
  - `GET /api/businesses/ownership-types` — List ownership types (e.g. government, private, public_listed, foreign). Response: `{ "success": true, "data": { <code>: <label> } }` or array of `{ "code", "label" }`.
  - `GET /api/businesses/sector/{sector}` — List businesses in a sector.
  - `GET /api/businesses/ownership/{ownership}` — List businesses by ownership type.
  - `GET /api/businesses/search?q={query}` — Search businesses by name/code (query encoded). Optional: filter by sector, category, ownership via query params.
  - `GET /api/businesses/parastatals` — List parastatal employers.
  - `GET /api/businesses/dse` — List DSE (Dar es Salaam Stock Exchange) listed companies.
  - `GET /api/businesses/{identifier}` — Get single business by id or code.

- **Request/response**
  - All GET; no request body.
  - Response envelope: `{ "success": true, "data": ... }`. List endpoints: `data` is array of business objects or `{ "data": [...] }` for paginated.
  - Business item: `{ "id": number, "code": string, "name": string, "acronym"?: string, "sector"?: string, "ownership"?: string, "category"?: string, "region"?: string }`. `ownership` values: e.g. government, private, public_listed, foreign.

- **Expectations**
  - Backend provides 750+ businesses. Search supports filtering by **sector**, **category** (DSE / Parastatal / Corporate or equivalent), and **ownership**.
  - Registration Step 8 (EmployerStep) uses these for employer selection; user can pick from DSE, Parastatals, Corporates (private) or search/filter by sector and ownership. Custom employer (free text) is supported client-side without backend.

---

## Story 1: Phone-Based Registration

- **Endpoints:**
  - `POST /api/users/register` — create UserProfile (phone as primary identifier).
  - `POST /api/users/check-phone` — validate phone number uniqueness against user_profiles (see Story 2).

- **Request (POST /api/users/register):**
  - JSON body from registration form (snake_case). Required: `first_name`, `last_name`, `phone_number`. Optional: `date_of_birth` (ISO 8601), `gender` (e.g. `male`/`female`), `is_phone_verified`, `location`, `primary_school`, `secondary_school`, `did_attend_alevel` (boolean; STORY-075 Education Path step — whether user attended A-Level), `alevel_education`, `postsecondary_education`, `university_education`, `current_employer`.
  - Example minimal: `{ "first_name": "Juma", "last_name": "Mohamed", "phone_number": "+255712345678", "date_of_birth": "2000-01-15", "gender": "male", "is_phone_verified": true }`. Nested objects for `location`, `primary_school`, etc. follow the same snake_case shape as in frontend `RegistrationState.toJson()`.

- **Response (201 success):**
  - `{ "success": true, "message": "optional", "data": { "id": <user_id>, "profile_photo_url": null, ... } }`. Frontend expects `data.id` as the created user ID and may apply `data` (e.g. `profile_photo_url`) to local state via `applyServerProfile`.

- **Response (422 validation / phone taken):**
  - `{ "success": false, "message": "...", "errors": { "phone_number": ["..."] } }`. Frontend shows message or `phone_number` error (e.g. phone already registered).

- **Expectations:**
  - Backend creates UserProfile; phone number must be unique (validated via check-phone and/or register).
  - Return success with user id and profile data so the app can store the user in Hive and navigate to profile.

---

## Story 11: Update Profile

- **Endpoints:** `PUT /api/users/phone/{phone}` – update profile for the user identified by phone.

- **Request:** Path parameter `{phone}` is the user’s phone number (E.164 or +255XXXXXXXXX). URL-encode the phone value.  
  JSON body (snake_case, all fields optional except those you wish to update):  
  `first_name`, `last_name`, `date_of_birth` (ISO 8601 date string, e.g. `YYYY-MM-DD`), `gender` (`male`|`female`), `bio`, `username`, `relationship_status` (`single`|`married`|`engaged`|`complicated`), `interests` (array of strings).  
  Example:  
  `{ "first_name": "Juma", "last_name": "Mohamed", "date_of_birth": "2000-01-15", "gender": "male", "bio": "...", "username": "juma_m", "relationship_status": "single", "interests": ["muziki", "michezo"] }`

- **Response (200 success):**  
  `{ "success": true, "message": "optional", "data": { ... } }`  
  Frontend expects `success === true`. `data` may contain the updated profile (same shape as GET profile or registration) so the app can refresh local state.

- **Response (4xx / validation):**  
  `{ "success": false, "message": "...", "errors": { "field": ["..."] } }`  
  Frontend shows `message` or field errors to the user.

- **Expectations:**
  - Backend identifies the user by `phone` and updates only the provided fields.
  - After a successful PUT, the app syncs updated name, DOB, and gender to local storage (RegistrationState) and refreshes the profile view.

---

## Story 10: View User Profile (Wasifu)

- **Endpoints:**
  - `GET /api/users/{id}` – returns full profile for the given user id.

- **Request:**
  - GET, no body. Path parameter `{id}` is the integer user ID.
  - Optional query: `current_user_id=<id>` so the backend can return friendship status and visibility rules for the requesting user.

- **Response (200 success):**
  - Envelope: `{ "success": true, "data": { ... }, "message": "optional" }`.
  - `data` must include at least:
    - `id`, `first_name`, `last_name`, `created_at` (ISO 8601)
    - Optional: `username`, `phone_number`, `date_of_birth`, `gender`, `bio`, `interests` (array of strings), `relationship_status`
    - `profile_photo_url`, `cover_photo_url` (absolute URLs or paths the frontend can resolve)
    - `stats`: `{ "posts_count", "friends_count", "photos_count" }` (integers)
    - `location`: optional `{ "region_name", "district_name", "ward_name" }`
    - `education`: optional object with `primary_school`, `secondary_school`, `alevel`, `postsecondary`, `university` (each with `school_name`/`university_name`, `graduation_year`, etc. as used in registration)
    - `employer`: optional `{ "employer_name", "sector", "job_title", "ownership" }`
    - `friendship_status`: when `current_user_id` is sent, one of `"self"`, `"request_sent"`, `"request_received"`, `"accepted"` (or equivalent for “friends”)
    - `mutual_friends_count`: optional integer when viewing another user

- **Response (non-200 or success: false):**
  - Frontend shows error message and “Jaribu tena” (retry) button.

- **Expectations:**
  - ProfileScreen (Wasifu) uses this to show name, photo, cover, bio, education, employer, and tabs (About, Posts, Photos, etc.). Backend must return full profile so the app can display all sections without extra round-trips for basic info.

---

## Story 12: Profile Photo Upload

- **Endpoints:** `POST /api/users/{id}/profile-photo`
- **Request:** `multipart/form-data` with a single file field. Field name: `photo`. Accepted: image file (e.g. JPEG, PNG). Frontend sends a compressed image (max width/height 800px, quality 85).
- **Response (200 success):**
  - `{ "success": true, "data": { "profile_photo_url": "<absolute URL or path>" }, "message": "optional" }`. Frontend expects `data.profile_photo_url` to update the profile and local user so the new photo is shown in profile and across the app (e.g. CreatePostScreen, conversations).
- **Response (non-200 or success: false):**
  - `{ "success": false, "message": "..." }`. Frontend shows the message in a SnackBar (e.g. "Imeshindwa kubadilisha picha").
- **Expectations:**
  - Only the authenticated user may upload for their own `id`. Backend stores the image and returns a URL (or path) that the frontend uses for display. Profile photo is displayed in a circular crop (ClipOval) in the profile header and anywhere the user avatar is shown.

---

## Story 13: Cover Photo Upload

- **Endpoints:** `POST /api/users/{id}/cover-photo`
- **Request:** `multipart/form-data` with a single file field. Field name: `photo`. Accepted: image file (e.g. JPEG, PNG). Frontend sends a compressed image (max width 1920, max height 1080, quality 85).
- **Response (200 success):**
  - `{ "success": true, "data": { "cover_photo_url": "<absolute URL or path>" }, "message": "optional" }`. Frontend expects `data.cover_photo_url` to refresh the profile and display the new cover at the top of the profile (banner).
- **Response (non-200 or success: false):**
  - `{ "success": false, "message": "..." }`. Frontend shows the message in a SnackBar (e.g. "Imeshindwa kubadilisha picha").
- **Expectations:**
  - Only the authenticated user may upload for their own `id`. Backend stores the image and returns a URL (or path). The cover photo is displayed as a banner at the top of the profile (FlexibleSpaceBar / header). Navigation: Home → Profile (Mimi) → tap cover edit icon (camera) → image picker (gallery) → upload.

---

## Story 15: Create Post (Text)

- **Endpoints:** `POST /api/posts`
- **Request:**
  - JSON body (Content-Type: application/json). Required: `content` (string, max 5000 characters), `post_type` (string, value `"text"`), `user_id` (integer), `privacy` (string, e.g. `public`, `friends`, `private`). Optional: `background_color` (string, hex e.g. `#FF5733`) for text post background.
  - Example: `{ "user_id": 1, "content": "Hello world", "post_type": "text", "privacy": "public", "background_color": "#3498DB" }`.
- **Response (201 success):**
  - `{ "success": true, "message": "optional", "data": { ... } }`. Frontend expects `data` to be the created post object (same shape as in feed: id, user_id, content, post_type, privacy, background_color, created_at, user, etc.) so the feed can refresh and show the new post.
- **Response (4xx / validation):**
  - `{ "success": false, "message": "...", "errors": { "content": ["..."] } }`. Frontend shows message or field errors in a SnackBar.
- **Expectations:**
  - Backend creates a text post; stores `content`, `post_type=text`, `privacy`, and optional `background_color`. Navigation: Home → Feed → FAB (+) → CreatePostScreen → Text option → CreateTextPostScreen. After success, frontend pops with result true so feed/profile can refresh.

---

## Story 16: Create Post (Photo)

- **Endpoints:** `POST /api/posts`
- **Request:**
  - `multipart/form-data` when media is present. Required fields: `user_id` (integer), `post_type` (string, value `"photo"`), `privacy` (string, e.g. `public`, `friends`, `private`). Optional: `content` (string, caption). Media: one or more image files under field name `media[]` (array of files). Frontend sends up to 10 images, compressed (max width 1920, max height 1080, quality 85).
  - Example form fields: `user_id=1`, `post_type=photo`, `privacy=public`, `content=Optional caption`, `media[]=file1`, `media[]=file2`, ...
- **Response (201 success):**
  - `{ "success": true, "message": "optional", "data": { ... } }`. Frontend expects `data` to be the created post object (id, user_id, content, post_type, privacy, media URLs, created_at, user, etc.) so the feed can refresh and show the new post.
- **Response (4xx / 413 / validation):**
  - `{ "success": false, "message": "...", "errors": { ... } }`. Frontend shows message or field errors in a SnackBar. On 413 (file too large), frontend shows a user-friendly message.
- **Expectations:**
  - Backend creates a photo post; stores `content` (optional caption), `post_type=photo`, `privacy`, and one or more media files (images). Navigation: Home → Feed → FAB (+) → CreatePostScreen → Photo option → CreateImagePostScreen. Image picker allows multi-select up to 10 photos. After success, frontend pops with result true so feed/profile can refresh.

---

## Story 14: Username (@handle) Management

- **Endpoints:** `PUT /api/users/{id}/username`
- **Request:**
  - Path parameter `{id}` is the integer user ID.
  - JSON body: `{ "username": "<handle>" }`. Handle is a string: letters, numbers, and underscore only; frontend validates length 3–30 characters.
- **Response (200 success):**
  - `{ "success": true, "message": "optional", "data": { "username": "<updated_handle>" } }`. Frontend expects `data.username` to confirm the saved handle and displays it in profile and posts (e.g. `@handle`).
- **Response (4xx / validation / uniqueness):**
  - When the handle is already taken or invalid: `{ "success": false, "message": "..." }` or `{ "success": false, "errors": { "username": ["..."] } }`. Frontend shows the message in a SnackBar (e.g. "Jina tayari limetumika").
- **Expectations:**
  - Backend must validate uniqueness of `username` across users and return an error if the handle is taken.
  - Only the authenticated user may update their own `id`. The updated `username` is returned in `GET /api/users/{id}` (Story 10) and in post/comment user objects so the frontend can display `@username` in profile and in posts.

---

## Story 24: Share/Repost (Share to Wall)

- **Endpoints:** `POST /api/posts/{id}/share` – Create a shared post (repost) on the current user's wall.
- **Request:**
  - Path parameter `{id}` is the **original** post ID (integer).
  - JSON body: `{ "user_id": <int>, "content": "<optional comment>", "privacy": "public"|"friends"|"private" }`. `user_id` is the sharer; `content` is optional share comment; `privacy` defaults to `public`.
- **Response (201 success):**
  - `{ "success": true, "message": "optional", "data": { ... } }`. Frontend expects `data` to be the **created shared post** object with: `id`, `user_id` (sharer), `original_post_id` (linkage to the original post), `content` (optional share comment), `post_type` (e.g. `shared`), `privacy`, `created_at`, `user` (sharer), `original_post` (nested full original post or at least `id`, `user_id`, `content`, `media`, `user`, `created_at`) so the feed can display it as a shared post (Story 24: display as shared post in feed).
- **Response (4xx / success: false):**
  - `{ "success": false, "message": "..." }`. Frontend shows "Imeshindwa kushiriki" in a SnackBar.
- **Expectations:**
  - Backend creates a new post record with `original_post_id` set to the requested post ID; the new post appears on the sharer's wall and in feed. Shared posts must include `original_post_id` and preferably nested `original_post` so the app can render the embedded original (PostCard `_buildSharedPost`). Navigation: Home → Feed/Profile → Post → Share icon → Share to wall (or Share with comment).

---

## Story 25: Save/Bookmark Post

- **Endpoints:**
  - `POST /api/posts/{id}/save` – Save (bookmark) a post for the current user.
  - `DELETE /api/posts/{id}/save` – Remove a saved post for the current user.
  - `GET /api/posts/saved` – List saved (bookmarked) posts for the current user.
- **Request (POST save):**
  - Path parameter `{id}` is the post ID.
  - JSON body: `{ "user_id": int }`. Optional: backend may derive user from auth.
- **Request (DELETE save):**
  - Path parameter `{id}` is the post ID.
  - JSON body: `{ "user_id": int }` (optional if auth provides user).
- **Request (GET saved):**
  - Query parameters: `user_id` (integer, required), `page` (integer, default 1), `per_page` (integer, default 20).
  - Example: `GET /api/posts/saved?user_id=1&page=1&per_page=20`
- **Response (POST/DELETE save, 200 success):**
  - `{ "success": true, "data": { "saves_count": int } }`. Frontend uses `saves_count` to update the post’s save count; it also toggles `is_saved` locally.
- **Response (GET saved, 200 success):**
  - `{ "success": true, "data": [ ... ], "meta": { "current_page", "last_page", "per_page", "total" } }`. Each item in `data` is a post object (same shape as feed/post detail: id, user_id, content, media, user, is_saved: true, saves_count, etc.).
- **Expectations:**
  - Save/unsave is idempotent: saving an already-saved post remains saved; unsaving an unsaved post remains unsaved.
  - Single post response (e.g. `GET /api/posts/{id}`) and feed responses should include `is_saved` (boolean) and `saves_count` (int) so the feed and post detail can show bookmark state.
  - Navigation: Home → Feed/Profile → Post → Bookmark icon toggles save; Feed app bar → Saved opens the saved posts list (SavedPostsScreen).

---

## Story 26: For You Feed

- **Endpoints:** `GET /api/posts/feed/for-you`
- **Request:**
  - Query parameters: `user_id` (integer, required), `page` (integer, default 1), `per_page` (integer, default 20).
  - Example: `GET /api/posts/feed/for-you?user_id=1&page=1&per_page=20`
- **Response (200 success):**
  - `{ "success": true, "data": [ ... ], "meta": { "current_page": int, "last_page": int, "per_page": int, "total": int } }`. Each item in `data` is a post object (id, user_id, content, post_type, privacy, media, user, likes_count, comments_count, engagement_score, etc.) as defined for other post endpoints.
- **Expectations:**
  - Backend returns **personalized** posts for the given user (algorithm-curated).
  - Posts are ordered by **engagement-based ranking** (e.g. likes, comments, shares, watch time, recency).
  - Pagination is cursor/page-based; frontend uses infinite scroll and sends `page` for next page. `meta.hasMore` is derived from `current_page < last_page`.
  - Navigation: Splash → Home → Bottom Nav [Nyumbani] → FeedScreen tab 0 (Kwa Wewe / For You). Same post model and actions (like, comment, share) as other feed tabs.

---

## Story 22: Like/Unlike Post

- **Endpoints:**
  - `POST /api/posts/{id}/like` – like a post (or set reaction type).
  - `DELETE /api/posts/{id}/like` – remove like from a post.

- **Request (POST /api/posts/{id}/like):**
  - Path parameter `{id}` is the post ID (integer).
  - JSON body: `{ "user_id": <int>, "reaction_type": "like" }`. Frontend sends `user_id` and optional `reaction_type` (default `"like"`).

- **Request (DELETE /api/posts/{id}/like):**
  - Path parameter `{id}` is the post ID (integer).
  - JSON body: `{ "user_id": <int> }`.

- **Response (200 success for both):**
  - `{ "success": true, "data": { "likes_count": <int> }, "message": "optional" }`. Frontend expects `data.likes_count` to update the displayed likes count on the PostCard and to keep UI in sync with the server.

- **Response (non-200 or success: false):**
  - Frontend reverts optimistic like/unlike and may show a SnackBar (e.g. "Imeshindwa kusasisha pendo").

- **Expectations:**
  - Backend updates the like state for the given user and post; returns the updated `likes_count` so the client can display it. PostCard shows the like reaction (heart/thumb icon and count) in the feed, post detail, profile, and hashtag screens. Navigation: Home → Feed/Profile → Post → Heart/Like button.

---

## Story 17: Create Post (Audio)

- **Endpoints:** `POST /api/posts`
- **Request:**
  - `multipart/form-data` when audio (and/or cover image) is present. Required fields: `user_id` (integer), `post_type` (string, value `"audio"`), `privacy` (string, e.g. `public`, `friends`, `private`). Optional: `content` (string, caption). Audio: file under field name `audio`. Optional: `audio_duration` (integer, duration in seconds). Optional cover image: field name `cover_image`.
  - Frontend sends: `user_id`, `post_type=audio`, `privacy`, optional `content`, `audio` (file), `audio_duration` (when known, from recording or from file metadata), optional `cover_image` (file).
  - Backend may set `audio_path` (or equivalent) server-side after storing the uploaded audio file; frontend does not send `audio_path` (only the audio file and optional `audio_duration`).
- **Response (201 success):**
  - `{ "success": true, "message": "optional", "data": { ... } }`. Frontend expects `data` to be the created post object with `id`, `user_id`, `content`, `post_type`, `privacy`, `audio_path` (or `audio_url`), `audio_duration` (seconds), `created_at`, `user`, etc., so the feed can refresh and show the new audio post.
- **Response (4xx / 413 / validation):**
  - `{ "success": false, "message": "...", "errors": { ... } }`. Frontend shows message or field errors in a SnackBar.
- **Expectations:**
  - Backend creates an audio post; stores the uploaded audio file and returns a URL or path (`audio_path` / `audio_url`) in the post; stores optional `audio_duration` (seconds) and optional caption and cover image. Navigation: Home → Feed → FAB (+) → CreatePostScreen → Audio option → CreateAudioPostScreen (with waveform). After success, frontend pops with result true so feed can refresh.

---

## Story 18: Create Short Video Post

- **Endpoints:** `POST /api/posts`
- **Request:**
  - `multipart/form-data` for short-form video upload. Required fields: `user_id` (integer), `post_type` (string, value `"short_video"`), `privacy` (string, e.g. `public`, `friends`, `private`), `is_short_video` (string, value `"true"`). Required media: one video file under field name `media[]` (video, up to 60 seconds). Optional: `content` (string, caption), `cover_image` (image file, thumbnail/cover for the video), `video_filter` (string, e.g. `normal`, `vivid`, `warm`, `cool`, `black_white`, `vintage`, `fade`, `dramatic`, `noir`), `video_speed` (double, e.g. 0.5, 0.75, 1.0, 1.5, 2.0), `music_track_id` (integer, ID of music overlay track), `music_start_time` (integer, start position in track in seconds), `original_audio_volume` (double, 0.0–1.0; 0 = mute original audio), `music_volume` (double, 0.0–1.0).
  - Example form fields: `user_id=1`, `post_type=short_video`, `privacy=public`, `is_short_video=true`, `media[]=video.mp4`, optional `cover_image=cover.jpg`, `content=Caption`, `video_filter=vivid`, `video_speed=1.0`, `music_track_id=5`, `original_audio_volume=0`, `music_volume=0.5`.
- **Response (201 success):**
  - `{ "success": true, "message": "optional", "data": { ... } }`. Frontend expects `data` to be the created post object with `id`, `user_id`, `content`, `post_type`, `privacy`, `is_short_video: true`, media (video URL), `cover_image_path` (or equivalent for thumbnail), `video_filter`, `video_speed`, `music_track_id`, `original_audio_volume`, `music_volume`, `created_at`, `user`, etc., so the feed/shorts can refresh and show the new short video.
- **Response (4xx / 413 / validation):**
  - `{ "success": false, "message": "...", "errors": { ... } }`. Frontend shows message or field errors in a SnackBar. On 413 (file too large), frontend shows a user-friendly message.
- **Expectations:**
  - Backend creates a short video post; stores the uploaded video (max duration 60 seconds), optional cover image (thumbnail), optional caption, and optional music overlay (via `music_track_id` and volume/start time). Backend should accept and persist `is_short_video=true` and all optional fields. Navigation: Home → Feed → FAB (+) → CreatePostScreen → Short Video option → CreateShortVideoScreen. User can record or pick video from gallery, add cover image, apply filter/speed, add music overlay, mute original audio, set privacy and schedule. After success, frontend pops with result true so feed can refresh.

---

## Story 19: View Post

- **Endpoints:**
  - `GET /api/posts/{id}` – returns a single post with full details (user, media, likes count, comments count, etc.). Optional query: `current_user_id=<id>` so the backend can return `is_liked`, `user_reaction`, and visibility for the requesting user.
  - `GET /api/posts/{id}/comments?page=1&per_page=20` – returns paginated comments for the post (lazy-loaded). Each comment includes `id`, `post_id`, `user_id`, `parent_id` (optional), `content`, `likes_count`, `created_at`, `updated_at`, `user` (with `id`, `first_name`, `last_name`, `username`, `profile_photo_path` or `profile_photo_url`), `replies` (optional array of nested comments).
  - `POST /api/posts/{id}/comments` – add a comment. Body: `{ "user_id": number, "content": string, "parent_id": number? }`. Response (201): `{ "success": true, "data": { ...comment } }`.

- **Request/response (GET /api/posts/{id}):**
  - GET, no body. Path parameter `{id}` is the integer post ID.
  - Response (200 success): `{ "success": true, "data": { ... } }`. `data` must include: `id`, `user_id`, `content`, `post_type`, `privacy`, `created_at`, `likes_count`, `comments_count`, `shares_count`, `views_count`, `is_liked` (boolean for current user), `user_reaction` (optional), `user` (object with `id`, `first_name`, `last_name`, `username`, `profile_photo_path` or `profile_photo_url`), `media` (array of media objects with `media_type`, `file_path`/`file_url`, `thumbnail_path`/`thumbnail_url`, `width`, `height`, etc.). For shared posts, `original_post` or `original_post_id` with full nested post when applicable.
  - Response (404 or success: false): frontend shows "Chapisho haikupatikana" and retry.

- **Expectations:**
  - Post detail screen (Story 19) loads a single post by ID to show full content, expanded media, like/comment/share actions, and comments list. PostCard displays content, likes, and comments; video auto-plays when in view (TikTok-style). Comments are lazy-loaded (pagination). Backend must return post with user and media so the full post view can render without extra round-trips.

---

## Story 20: Edit Post

- **Endpoints:** `PUT /api/posts/{id}`
- **Request:**
  - Path parameter `{id}` is the integer post ID.
  - JSON body (Content-Type: application/json). All fields optional; send only what is being updated: `content` (string, max 5000 characters), `privacy` (string: `public`, `friends`, `private`), `location_name` (string, optional), `is_pinned` (boolean, optional).
  - Example: `{ "content": "Updated text", "privacy": "friends" }`.
- **Response (200 success):**
  - `{ "success": true, "message": "optional", "data": { ... } }`. Frontend expects `data` to be the updated post object (same shape as in feed: `id`, `user_id`, `content`, `post_type`, `privacy`, `created_at`, `updated_at`, `user`, `media`, etc.). Backend should set `updated_at` to the current time so the frontend can show an "edited" indicator when `updated_at` is significantly after `created_at`.
- **Response (4xx / validation / time limit):**
  - When edit is not allowed (e.g. outside time limit): `{ "success": false, "message": "..." }`. Frontend shows a user-friendly message (e.g. "Muda wa kuhariri chapisho umekwisha.") when the message contains time/limit/expired-related wording.
  - Validation errors: `{ "success": false, "message": "...", "errors": { "content": ["..."] } }`.
- **Expectations:**
  - Only the post author may update the post. Backend may enforce an edit time limit (e.g. 15–60 minutes after creation); if so, return 403 or 400 with a clear message so the frontend can show "Muda wa kuhariri chapisho umekwisha." Navigation: Home → Feed/Profile → Post → ⋮ menu → Edit → EditPostScreen. After success, frontend pops with the updated post so feed/profile/post-detail can refresh and show the "Iliyohaririwa" (edited) indicator.

---

## Story 27: Following Feed

- **Endpoints:** `GET /api/posts/feed/following`
- **Request:**
  - GET, no body. Query parameters: `user_id` (integer, required), `page` (integer, default 1), `per_page` (integer, default 20).
  - Example: `GET /api/posts/feed/following?user_id=1&page=1&per_page=20`
- **Response (200 success):**
  - `{ "success": true, "data": [ ... ], "meta": { "current_page", "per_page", "total", "has_more", ... }, "message": "optional" }`. `data` is an array of post objects (same shape as other feed endpoints: `id`, `user_id`, `content`, `post_type`, `privacy`, `created_at`, `user`, `media`, `likes_count`, `comments_count`, etc.).
- **Response (non-200 or success: false):**
  - Frontend shows error and "Jaribu tena" (retry) on the Marafiki tab.
- **Expectations:**
  - Backend returns only posts from users that the requesting user follows (following relationship). Posts must be in **chronological order** (newest first by `created_at`). Used for the Feed screen → Marafiki (Friends) tab. Navigation: Home → Feed → Tab [Marafiki].

---

## Story 21: Delete Post

- **Endpoints:** `DELETE /api/posts/{id}`
- **Request:**
  - DELETE, no body. Path parameter `{id}` is the integer post ID. Only the post author (authenticated user) may delete their own post.
- **Response (200 success):**
  - Backend **soft-deletes** the post (e.g. sets `deleted_at` or equivalent). Post is no longer returned in feed, profile, or GET single post. Response body may be `{ "success": true, "message": "optional" }` or minimal 200 OK. Frontend treats 200 as success.
- **Response (403 / 404 / success: false):**
  - 403 if the user is not the author; 404 if post does not exist or already deleted. Frontend shows "Imeshindwa kufuta chapisho" in a SnackBar.
- **Expectations:**
  - Delete is **soft-delete**: record is marked deleted, not physically removed, so comments/analytics can be retained. After success, frontend removes the post from the feed/profile list and shows "Chapisho limefutwa". Navigation: Home → Feed/Profile → Post → ⋮ menu → Delete → confirm dialog (Futa Chapisho / Ndio) → post removed from list.

---

## Story 23: Comment on Post

- **Endpoints:**
  - `GET /api/posts/{id}/comments` – list comments for a post (paginated).
  - `POST /api/posts/{id}/comments` – add a comment (or threaded reply) to a post.

- **Request (GET /api/posts/{id}/comments):**
  - GET, no body. Path parameter `{id}` is the integer post ID.
  - Query parameters: `page` (integer, default 1), `per_page` (integer, default 20).
  - Example: `GET /api/posts/123/comments?page=1&per_page=20`

- **Response (200 success for GET):**
  - `{ "success": true, "data": [ ... ], "meta": { "current_page", "last_page", "per_page", "total", "has_more" (optional) } }`.
  - Each comment in `data`: `{ "id", "post_id", "user_id", "parent_id" (null for top-level, integer for reply), "content", "likes_count", "created_at", "updated_at", "user": { "id", "first_name", "last_name", "profile_photo_path" or "profile_photo_url" }, "replies": [ ... ] (optional, nested replies) }`.
  - Backend may return a **flat** list (all comments with `parent_id` set for replies) or a **nested** list (top-level comments with `replies` array). Frontend supports both.

- **Request (POST /api/posts/{id}/comments):**
  - POST, JSON body. Path parameter `{id}` is the integer post ID.
  - Required: `user_id` (integer), `content` (string, non-empty).
  - Optional: `parent_id` (integer) – when set, the comment is a reply to that comment (threaded reply).
  - Example: `{ "user_id": 1, "content": "Nice post!" }` for top-level; `{ "user_id": 1, "content": "Thanks!", "parent_id": 42 }` for reply.

- **Response (201 success for POST):**
  - `{ "success": true, "message": "optional", "data": { ... } }`. `data` is the created comment object (same shape as above: `id`, `post_id`, `user_id`, `parent_id`, `content`, `likes_count`, `created_at`, `updated_at`, `user`, `replies`: []).

- **Response (4xx / validation):**
  - `{ "success": false, "message": "...", "errors": { "content": ["..."] } }`. Frontend shows message or field errors in a SnackBar (e.g. "Imeshindwa kuongeza maoni").

- **Expectations:**
  - **Threaded replies:** Backend must support `parent_id` on POST so comments can be replies to another comment. GET may return either flat list (all comments with `parent_id` set where applicable) or nested (top-level comments with `replies` array). Frontend displays top-level comments and indented replies (Comment bottom sheet: Home → Feed/Profile → Post → Comment icon).
  - After a successful POST, frontend appends the new comment to the list and increments the post’s `comments_count`; optional callback updates the post card count on Feed/Profile.
  - Navigation path: Home → Feed/Profile → Post → Comment icon → Comment sheet (modal bottom sheet with list + input and Reply action per comment).

---

## Story 29: Discover Feed

- **Endpoints:**
  - `GET /api/feed/discover` – recommended/discovery feed (public posts from non-friends, algorithm-curated).
  - `GET /api/feed/trending` – trending posts (by engagement/trending score).
  - `GET /api/feed/nearby` – posts from the user’s region/nearby area.

- **Request (all three):**
  - GET, no body. Query parameters: `page` (integer, default 1), `per_page` (integer, default 20). Optional: `user_id` (integer) so the backend can return `is_liked`, `is_saved`, and user-specific state.
  - Examples:
    - `GET /api/feed/discover?page=1&per_page=20&user_id=1`
    - `GET /api/feed/trending?page=1&per_page=20&user_id=1`
    - `GET /api/feed/nearby?page=1&per_page=20&user_id=1`
  - For nearby, optional: `region_id` (integer) to filter by region.

- **Response (200 success):**
  - `{ "success": true, "data": [ ... ], "meta": { "current_page", "per_page", "total", "last_page", "has_more" (optional) }, "message": "optional" }`.
  - `data` is an array of post objects (same shape as other feed endpoints): `id`, `user_id`, `content`, `post_type`, `privacy`, `created_at`, `user`, `media`, `likes_count`, `comments_count`, `shares_count`, `views_count`, `saves_count`, `is_liked`, `is_saved`, `trending_score` (optional for trending), etc.

- **Response (non-200 or success: false):**
  - Frontend shows section error and "Jaribu tena" (retry) for that section.

- **Expectations:**
  - **Discover:** Backend returns recommended/public posts (e.g. from non-friends, or algorithm-based). Used in Feed → Tab [Gundua] under section "Gundua".
  - **Trending:** Backend returns posts ordered by trending/engagement score (e.g. `trending_score`, likes, comments, recency). Used in section "Vinavyoongezeka".
  - **Nearby:** Backend returns posts from the same region (or nearby) as the current user; may use user’s stored `region_id` or location. Used in section "Karibu nawe".
  - Navigation: Home → Feed → Tab [Discover] (Gundua). All three endpoints are called on load; pull-to-refresh reloads all three.

---

## Story 30: Post Drafts

- **Endpoints:**
  - `POST /api/drafts` – Create or update a draft (multipart when media present).
  - `GET /api/drafts` – List drafts for the current user (paginated).
  - `POST /api/drafts/{id}/publish` – Publish a draft as a post.

- **Request (POST /api/drafts):**
  - `multipart/form-data` when media/audio/cover are present; otherwise form or JSON.
  - Optional: `draft_id` (integer) – when present, updates existing draft.
  - Required: `post_type` (string: `text`, `photo`, `short_video`, `audio`).
  - Optional: `content`, `background_color`, `privacy` (`public`|`friends`|`private`), `location_name`, `location_lat`, `location_lng`, `tagged_users[]`, `scheduled_at` (ISO 8601), `title`, `music_track_id`, `music_start_time`, `original_audio_volume`, `music_volume`, `video_speed`, `video_filter`, `text_overlays` (JSON).
  - Media: `media[]` (files), `audio` (file), `cover_image` (file).
  - Frontend sends these from DraftService.saveDraft() when user taps "Save as draft" in CreateTextPostScreen, CreateImagePostScreen, CreateAudioPostScreen, CreateShortVideoScreen.

- **Response (200/201 success for POST /api/drafts):**
  - `{ "success": true, "message": "optional", "data": { ... } }`. `data` is the draft object: `id`, `user_id`, `post_type`, `content`, `background_color`, `privacy`, `media_files`, `audio_path`, `cover_image_path`, `scheduled_at`, `last_edited_at`, `created_at`, `updated_at`, etc. Frontend expects `data.id` to update local draft id and to call publish later.

- **Request (GET /api/drafts):**
  - Query: `user_id` (integer, required for scoping), `page` (default 1), `per_page` (default 20). Optional: `type` (post_type filter), `scheduled_only` (1 for scheduled drafts only).
  - Example: `GET /api/drafts?user_id=1&page=1&per_page=20`

- **Response (200 success for GET /api/drafts):**
  - `{ "success": true, "data": [ ... ] }`. `data` is array of draft objects (same shape as above). Frontend uses this on CreatePostScreen to show "Continue Editing" and in "All Drafts" screen.

- **Request (POST /api/drafts/{id}/publish):**
  - Path parameter `{id}` is the draft ID (integer). No body required (or optional JSON for overrides).
  - Frontend calls this when user taps "Post" on a draft (publish flow).

- **Response (200 success for POST /api/drafts/{id}/publish):**
  - `{ "success": true, "message": "optional" }`. Backend creates the post from the draft and may remove or mark the draft as published. Frontend pops the create screen and refreshes feed.

- **Expectations:**
  - DraftService in Flutter uses POST /api/drafts (save/update), GET /api/drafts (list), POST /api/drafts/{id}/publish (publish). Navigation: Home → Feed → FAB → Create Post → (Text/Photo/Audio/Short Video) → Save as draft. Drafts are listed on CreatePostScreen and in "All Drafts"; user can open a draft to edit and then post or save again.

---

## Story 28: Shorts Feed

- **Endpoints:**
  - `GET /api/posts/feed/shorts` – vertical shorts feed (short-form video posts only).

- **Request:**
  - GET, no body. Query parameters: `user_id` (integer, required), `page` (integer, default 1), `per_page` (integer, default 20).
  - Example: `GET /api/posts/feed/shorts?user_id=1&page=1&per_page=20`

- **Response (200 success):**
  - `{ "success": true, "data": [ ... ], "meta": { "current_page", "per_page", "total", "last_page", "has_more" (optional) }, "message": "optional" }`.
  - `data` is an array of post objects that are short-form videos (e.g. `is_short_video: true` or posts with video media). Same post shape as other feeds: `id`, `user_id`, `content`, `post_type`, `privacy`, `created_at`, `user`, `media` (with video `file_url`, `thumbnail_url`, `duration`), `likes_count`, `comments_count`, `shares_count`, `saves_count`, `is_liked`, `is_saved`, etc.

- **Response (non-200 or success: false):**
  - Frontend shows error and "Jaribu tena" (retry).

- **Expectations:**
  - Backend returns only short-form video posts suitable for full-screen vertical swipe (TikTok/Reels-style). Used in Feed → Tab [Shorts]. Frontend displays them in `ShortsVideoFeed` with vertical PageView, one video per page, swipe up/down to navigate. Pagination via `page`/`per_page`; frontend loads more when user scrolls near the end.

---

## Story 31: Upload Photo (to Albums)

- **Endpoints:**
  - `POST /api/photos` – Upload one or more photos (frontend sends one request per photo; optional batch endpoint not required).
  - `GET /api/users/{userId}/albums` – List albums for album picker when assigning photos.
  - `POST /api/albums` – Create a new album (used when user chooses "Create new album" during upload).

- **Request (POST /api/photos):**
  - `multipart/form-data`. Required: `user_id` (integer), `photo` (file, image). Optional: `album_id` (integer), `caption` (string), `location_name` (string).
  - Example: `user_id=1`, `photo=<file>`, `album_id=5`, `caption=Optional caption`.
  - Frontend uses multi-select image picker and uploads each selected image in sequence with the same `album_id` and optional `caption` (one caption applied to all in the batch).

- **Response (201 success for POST /api/photos):**
  - `{ "success": true, "message": "optional", "data": { ... } }`. `data` is the created photo object: `id`, `user_id`, `album_id`, `file_path`, `thumbnail_path`, `caption`, `location_name`, `likes_count`, `comments_count`, `created_at`, `updated_at`, `user`, `album` (optional). Frontend expects `file_path` (or full URL) and `thumbnail_path` for display.

- **Response (4xx / 413 / validation):**
  - `{ "success": false, "message": "..." }`. Frontend shows message in SnackBar and stops batch on first failure.

- **Request (GET /api/users/{userId}/albums):**
  - GET, no body. Path parameter `userId` is the integer user ID.
  - Response (200): `{ "success": true, "data": [ ... ] }`. Each album: `id`, `user_id`, `name`, `description`, `privacy`, `cover_photo_id`, `photos_count`, `created_at`, `updated_at`, optional `cover_photo`. Frontend uses this for the album dropdown when uploading.

- **Request (POST /api/albums):**
  - JSON body: `user_id` (integer), `name` (string, required), `description` (string, optional), `privacy` (string: `public`|`friends`|`private`, default `public`).
  - Response (201): `{ "success": true, "message": "optional", "data": { ... } }`. `data` is the created album with `id`, `name`, `privacy`, etc. Frontend then uses `data.id` as `album_id` for subsequent POST /api/photos calls in the same upload flow.

- **Expectations:**
  - User reaches upload via Home → Bottom Nav [Picha] → PhotosScreen → Upload (FAB). Image picker allows multi-select; user can assign all selected photos to an existing album or create a new album (name required). Optional caption applies to all photos in the batch. Backend must accept POST /api/photos with `user_id`, `photo` (file), and optional `album_id` and `caption`; return 201 with photo object so the app can refresh the photos grid and albums.

---

## Story 32: Create & Manage Albums

- **Endpoints:**
  - `POST /api/albums` – Create a new album.
  - `GET /api/albums` – List albums (current user’s albums when authenticated). Backend may alternatively expose `GET /api/users/{userId}/albums` for a specific user; frontend uses the latter for the Photos tab album list.
  - `GET /api/albums/{id}` – Get a single album with its photos (paginated).
  - `PUT /api/albums/{id}` – Update an album (name, description, privacy, cover_photo_id).
  - `DELETE /api/albums/{id}` – Delete an album (only the owner may delete).

- **Request (POST /api/albums):**
  - JSON body: `user_id` (integer), `name` (string, required), `description` (string, optional), `privacy` (string: `public`|`friends`|`private`, default `public`).
  - Example: `{ "user_id": 1, "name": "Mapumziko", "description": "Picha za likizo", "privacy": "friends" }`.
  - Response (201): `{ "success": true, "message": "optional", "data": { ... } }`. `data` is the created album: `id`, `user_id`, `name`, `description`, `privacy`, `cover_photo_id`, `photos_count`, `created_at`, `updated_at`, optional `cover_photo`, `cover_photo_url` or equivalent for display.

- **Request (GET /api/albums or GET /api/users/{userId}/albums):**
  - GET, no body. For `GET /api/albums`, backend returns current user’s albums when authenticated. For `GET /api/users/{userId}/albums`, path parameter is the user ID.
  - Response (200): `{ "success": true, "data": [ ... ] }`. Each album: `id`, `user_id`, `name`, `description`, `privacy`, `cover_photo_id`, `photos_count`, `created_at`, `updated_at`, optional `cover_photo` or `cover_photo_url` for list thumbnails.

- **Request (GET /api/albums/{id}):**
  - GET, no body. Query params: `page` (integer, default 1), `per_page` (integer, default 20) for paginated photos.
  - Example: `GET /api/albums/5?page=1&per_page=20`
  - Response (200): `{ "success": true, "data": { "album": { ... }, "photos": [ ... ] }, "meta": { "current_page", "last_page", "per_page", "total" } }`. `album` is the full album object; `photos` is the page of photos in the album. Frontend uses this for AlbumDetailScreen (view photos, edit/delete album).

- **Request (PUT /api/albums/{id}):**
  - JSON body: all fields optional; send only what is updated: `name` (string), `description` (string), `privacy` (`public`|`friends`|`private`), `cover_photo_id` (integer).
  - Example: `{ "name": "Jina Jipya", "privacy": "private" }`.
  - Response (200): `{ "success": true, "message": "optional", "data": { ... } }`. `data` is the updated album object. Only the album owner may update.

- **Request (DELETE /api/albums/{id}):**
  - DELETE, no body. Only the album owner may delete.
  - Response (200): success (body optional). Frontend treats 200 as success and removes the album from the list; photos may remain in the system without album assignment or be handled by backend policy.

- **Privacy per album:**
  - Each album has a `privacy` field: `public` (everyone), `friends` (friends only), `private` (only owner). Backend must enforce visibility when returning albums and album photos (e.g. GET /api/albums/{id} returns 403 or empty for non-visible albums).

- **Expectations:**
  - Navigation: Home → Photos (Picha) → Albamu tab → Create album (Unda Albamu Mpya) or tap an album to open AlbumDetailScreen. Owner can edit (name, description, privacy) and delete album from the detail screen. Create and edit dialogs include privacy dropdown (Hadharani / Marafiki tu / Binafsi). Frontend uses POST /api/albums for create, GET /api/users/{userId}/albums for list, GET /api/albums/{id} for detail, PUT /api/albums/{id} for edit, DELETE /api/albums/{id} for delete.

---

## Story 33: View Photo Gallery

- **Endpoints (same as Story 31 and 32):**
  - `GET /api/users/{userId}/photos?page=1&per_page=20` – List user's photos (paginated). Used by PhotosScreen (Picha tab) grid and by PhotoGalleryWidget on profile (Picha tab).
  - `GET /api/users/{userId}/albums` – List user's albums. Used by PhotosScreen (Albamu tab) and album list.
  - `GET /api/albums/{albumId}?page=1&per_page=20` – Get album with its photos (paginated). Used by AlbumDetailScreen (album view with photo grid).
  - `GET /api/photos/{photoId}` – Get single photo (optional; full-screen viewer uses list/album data).
  - `DELETE /api/photos/{photoId}` – Delete photo (owner only). Used from PhotoViewerScreen when user deletes a photo.

- **Request/response:**
  - Photos list: `{ "success": true, "data": [ ... ], "meta": { "current_page", "last_page", "per_page", "total" } }`. Each photo: `id`, `user_id`, `album_id`, `file_path`, `thumbnail_path`, `caption`, `likes_count`, `comments_count`, `created_at`, etc. Full URLs built from `ApiConfig.storageUrl` + path.
  - Albums list: `{ "success": true, "data": [ ... ] }`. Each album: `id`, `name`, `description`, `privacy`, `cover_photo_id`, `photos_count`, optional `cover_photo` or cover URL for grid thumbnails.
  - Album detail: `{ "success": true, "data": { "album": { ... }, "photos": [ ... ] }, "meta": { ... } }`.

- **Expectations:**
  - Navigation: Splash → Home → Bottom Nav [Picha] → PhotosScreen. PhotosScreen shows grid view (Picha tab) and album list (Albamu tab). Tapping a photo opens PhotoViewerScreen (full view, swipe between photos, optional edit/delete for owner). AlbumDetailScreen shows album photos in a grid; tapping a photo opens PhotoViewerScreen with that album's photos. Profile tab "Picha" uses PhotoGalleryWidget (Pinterest-style staggered grid). All photo thumbnails and full images use cached loading (CachedMediaImage). Backend must return `file_path` and optionally `thumbnail_path` (or frontend uses `file_path` for both).

---

## Story 34: Send Friend Request

- **Endpoints:** `POST /api/friends/request`
- **Request:**
  - JSON body: `{ "user_id": <int>, "friend_id": <int> }`. `user_id` is the sender (current user); `friend_id` is the user to whom the request is sent.
  - Example: `{ "user_id": 1, "friend_id": 42 }`
- **Response (201 success):**
  - `{ "success": true, "message": "optional", "data": { ... } }`. Frontend expects `success === true` to show "Ombi la urafiki limetumwa" and refresh profile (friendship_status becomes `request_sent`).
- **Response (4xx / success: false):**
  - `{ "success": false, "message": "..." }`. Frontend shows "Imeshindwa kutuma ombi la urafiki. Jaribu tena." in a SnackBar.
- **Friend status:**
  - Backend friend/friendship status values used by the app: **pending** (request sent, awaiting response), **accepted** (friends), **declined** (request was declined). Profile endpoint `GET /api/users/{id}` with `current_user_id` returns `friendship_status`: `self`, `request_sent`, `request_received`, or `accepted` (or equivalent) so the profile screen can show Add Friend / Ombi Limetumwa / Kubali Ombi / Marafiki.
- **Expectations:**
  - Only authenticated user may send a request; cannot send to self; backend may reject duplicate pending requests. Navigation: Home → Profile (other user) → Add Friend button (Ongeza Rafiki). After success, profile is reloaded and button shows "Ombi Limetumwa" until the other user accepts or declines.

---

## Story 35: Accept/Decline Friend Request

- **Endpoints:**
  - `GET /api/friends/requests` – list pending friend requests (received and sent) for the current user.
  - `POST /api/friends/accept/{id}` – accept a friend request. `{id}` is the **requester’s user ID** (the user who sent the request).
  - `POST /api/friends/decline/{id}` – decline a friend request. `{id}` is the **requester’s user ID**.

- **Request (GET /api/friends/requests):**
  - GET, no body. Query parameter: `user_id` (integer, required).
  - Example: `GET /api/friends/requests?user_id=1`

- **Response (200 success for GET):**
  - `{ "success": true, "data": { "received": [ ... ], "sent": [ ... ] } }`.
  - `data.received`: array of requests **received by** the current user (others want to be friends). Each item: `{ "id": int, "type": "received", "user": { "id", "first_name", "last_name", "username", "profile_photo_path" or "profile_photo_url", ... }, "created_at": "ISO 8601" }`.
  - `data.sent`: array of requests **sent by** the current user (pending their response). Same shape with `"type": "sent"`.
  - Frontend uses this on Friends screen → Maombi (Requests) tab. Received items show Accept/Decline actions; sent items show Cancel.

- **Request (POST /api/friends/accept/{id}):**
  - Path parameter `{id}` is the **requester’s user ID** (the user who sent the request to the current user).
  - JSON body: `{ "user_id": <int> }`. `user_id` is the current user (accepter).
  - Example: `POST /api/friends/accept/42` with body `{ "user_id": 1 }` means user 1 accepts the request from user 42.

- **Response (200 success for POST accept):**
  - `{ "success": true, "message": "optional", "data": { ... } }`. Frontend expects `success === true`; removes the request from the received list and shows "X ni rafiki yako sasa".

- **Request (POST /api/friends/decline/{id}):**
  - Path parameter `{id}` is the **requester’s user ID**.
  - JSON body: `{ "user_id": <int> }` (current user).

- **Response (200 success for POST decline):**
  - `{ "success": true, "message": "optional" }`. Frontend expects `success === true`; removes the request from the received list and shows "Ombi limekataliwa".

- **Response (4xx / success: false):**
  - Frontend shows SnackBar: "Imeshindwa kukubali ombi. Jaribu tena." or "Imeshindwa kukataa ombi. Jaribu tena." and leaves the request in the list.

- **Expectations:**
  - Only the recipient of a request may accept or decline. After accept, the two users are friends; after decline, the request is removed. Navigation: Home → Bottom Nav [Marafiki] → Maombi (Requests) tab. User sees received requests with Accept (check) and Decline (close) buttons; 48dp touch targets; loading and error states; pull-to-refresh to reload requests.

---

## Story 37: Friend Suggestions

- **Endpoints:** `GET /api/friends/suggestions`
- **Request:**
  - GET, no body. Query parameters: `user_id` (integer, required), `limit` (integer, optional, default 20).
  - Example: `GET /api/friends/suggestions?user_id=1&limit=20`
- **Response (200 success):**
  - `{ "success": true, "data": [ ... ], "message": "optional" }`. `data` is an array of user profile objects (non-friends suggested based on mutual friends, school, location). Each item must include at least: `id`, `first_name`, `last_name`, `username` (optional), `profile_photo_path` or `profile_photo_url`, `mutual_friends_count` (optional, integer), `region_name` (optional), `district_name` (optional). Backend may optionally include `suggestion_reason` (e.g. `mutual_friends`, `same_school`, `same_region`) for display.
- **Response (non-200 or success: false):**
  - Frontend shows error message and "Jaribu tena" (retry) in the Suggestions section.
- **Expectations:**
  - Suggestions are users who are not already friends and have not received a pending request from the current user. Backend should rank suggestions by mutual friends, shared school (primary/secondary/university), and shared location (region/district). Frontend displays suggestion cards with avatar, name, subtitle (mutual friends count and/or location), and an Add button that sends a friend request via `POST /api/friends/request`. Navigation: Home → Friends (Marafiki) → Suggestions section (Pendekezo tab).

---

## Story 36: Friends List

- **Endpoints:**
  - `GET /api/friends` – list the current user's friends (paginated).
  - `DELETE /api/friends/{id}` – remove a friend (unfriend).

- **Request (GET /api/friends):**
  - GET, no body. Query parameters: `user_id` (integer, required), `page` (integer, default 1), `per_page` (integer, default 20).
  - Example: `GET /api/friends?user_id=1&page=1&per_page=20`
- **Response (200 success):**
  - `{ "success": true, "data": [ ... ], "meta": { "current_page", "last_page", "per_page", "total" }, "message": "optional" }`. `data` is an array of user profile objects, one per friend. Each item must include at least: `id`, `first_name`, `last_name`, `username` (optional), `profile_photo_path` or `profile_photo_url`, and optionally `region_name`, `district_name`, `friends_count`, `posts_count`, `photos_count`, `last_active_at`.
- **Response (non-200 or success: false):**
  - Frontend shows error message and "Jaribu tena" (retry) on the Friends list tab.

- **Request (DELETE /api/friends/{id}):**
  - DELETE, optional JSON body: `{ "user_id": <int> }`. Path parameter `{id}` is the **friend's user ID** to remove. The authenticated user (or the user identified by `user_id`) must be one side of the friendship.
- **Response (200 success):**
  - `{ "success": true, "message": "optional" }`. Frontend removes the friend from the list and shows "Rafiki ameondolewa".
- **Response (403 / 404 / success: false):**
  - Frontend shows "Imeshindwa kumondoa rafiki. Jaribu tena." in a SnackBar.

- **Expectations:**
  - **GET /api/friends:** Returns only users with an accepted friendship with the given `user_id`. Used by FriendsScreen (Marafiki tab) to display the friends list with avatar, name, @username, and a menu with "Tuma ujumbe", "Tazama wasifu", and "Ondoa rafiki". Navigation: Splash → Home → Bottom Nav [Marafiki] → FriendsScreen.
  - **Remove friend:** Only the two users in the friendship may unfriend; backend removes the friendship (or marks it inactive) so both users no longer see each other in friends list. After success, frontend removes the friend from the list optimistically.

---

## Story 38: Conversations List

- **Endpoints:** `GET /api/conversations`
- **Request:**
  - GET, no body. Query parameters: `user_id` (integer, required), `page` (integer, default 1), `per_page` (integer, default 20).
  - Example: `GET /api/conversations?user_id=1&page=1&per_page=20`
  - Optional **type**: `group` (groups only), `private` (DMs only). Omit for both. The app may send `type=group` when loading the Groups tab. `include_groups=1` is accepted (no-op; groups included by default).
- **Response (200 success):**
  - `{ "success": true, "data": [ ... ], "meta": { "current_page", "last_page", "per_page", "total" }, "message": "optional" }`.
  - `data` is an array of conversation objects. Each item must include at least: `id`, `type` (`"private"` or `"group"`), `name` (optional, for groups), `avatar_path` or `display_photo` (optional), `created_by`, `last_message_id` (optional), `last_message_at` (ISO 8601, optional), `created_at`, `updated_at`, `unread_count` (integer, for the current user), `participants` (array of participant objects with `user_id`, `user` with `first_name`, `last_name`, `profile_photo_path` or `profile_photo_url`), `last_message` (optional object with `id`, `content`, `message_type` (`text`|`image`|`video`|`audio`|`document`), `created_at`, `sender_id`).
  - Conversations must be ordered by **last_message_at** descending (most recent first). Frontend may re-sort client-side if needed.
- **Response (non-200 or success: false):**
  - Frontend shows error message and "Jaribu tena" (retry) on ConversationsScreen.
- **Expectations:**
  - Backend returns all conversations for the authenticated user (or for the given `user_id`). Each conversation includes a **last message preview** (via `last_message`) and **unread_count** for the current user so the app can show unread badges on list items and on the Ujumbe tab. Order by `last_message_at` descending so the most recent conversation appears first. Navigation: Splash → Home → Bottom Nav [Ujumbe] → ConversationsScreen.

---

## Story 39: Private Chat

- **Endpoints:**
  - `GET /api/conversations/private/{userId}` – get or create a private conversation with the user identified by `{userId}` (the other participant). The current user is identified by query `user_id`.
  - `POST /api/conversations/{id}/messages` – send a message (text, image, video, or audio) in the conversation.

- **Request (GET /api/conversations/private/{userId}):**
  - GET, no body. Path parameter `{userId}` is the **other** participant’s user ID (integer). Query parameter: `user_id` (integer, required) – the current user.
  - Example: `GET /api/conversations/private/42?user_id=1` (user 1 wants the private conversation with user 42).

- **Response (200 success):**
  - `{ "success": true, "data": { ... } }`. `data` is a single conversation object (same shape as in Story 38: `id`, `type: "private"`, `participants`, `last_message`, `unread_count`, etc.). If no conversation exists, backend may create one and return it.

- **Request (POST /api/conversations/{id}/messages):**
  - **Text:** `Content-Type: application/json`. Body: `{ "user_id": <int>, "content": "<text>", "message_type": "text", "reply_to_id": <int?> }`.
  - **Image / Video / Audio:** `multipart/form-data`. Fields: `user_id` (integer), `message_type` (`"image"` | `"video"` | `"audio"`), `media` (file). Optional: `content` (caption), `reply_to_id` (integer).
  - Example (text): `POST /api/conversations/5/messages` with body `{ "user_id": 1, "content": "Hello", "message_type": "text" }`.
  - Example (image): `POST /api/conversations/5/messages` with form fields `user_id=1`, `message_type=image`, `media=<file>` (frontend sends compressed image, max 800px, quality 85 for low bandwidth).

- **Response (201 success for POST messages):**
  - `{ "success": true, "data": { ... } }`. `data` is the created message object: `id`, `conversation_id`, `sender_id`, `content`, `message_type`, `media_path` (or `media_url`), `reply_to_id`, `is_read`, `read_at`, `created_at`, `updated_at`, `sender` (user object with `id`, `first_name`, `last_name`, `profile_photo_path` or `profile_photo_url`), `reply_to` (optional nested message).

- **Response (non-200 or success: false):**
  - Frontend shows error in SnackBar and does not add the message to the list.

- **Expectations:**
  - **ChatScreen** (Story 39) displays message bubbles: sender on the right (blue), receiver on the left (gray). Read receipts (e.g. done/done_all) and timestamps are shown. Supported message types: text, image, video, voice (audio). Frontend compresses images before upload and uses cached/lazy-loaded media for display. Navigation: Home → Messages (Ujumbe) → Tap conversation → ChatScreen.

---

## Story 40: Typing Indicator

- **Endpoints:**
  - `POST /api/conversations/{id}/typing/start` – notify that the current user started typing in the conversation.
  - `POST /api/conversations/{id}/typing/stop` – notify that the current user stopped typing.
  - `GET /api/conversations/{id}/typing?user_id={userId}` – get list of users currently typing in the conversation (used by frontend to display "X anaandika...").

- **Request (POST typing/start):**
  - Path parameter `{id}` is the conversation ID (integer).
  - JSON body: `{ "user_id": <int> }`. `user_id` is the current user who is typing.
  - Example: `POST /api/conversations/5/typing/start` with body `{ "user_id": 1 }`.

- **Response (200 success for POST typing/start):**
  - `{ "success": true, "message": "optional" }`. Frontend calls this when the user types in the message input; backend should record that this user is typing and optionally expire the state after a short period (e.g. 5–10 seconds) if no stop is received.

- **Request (POST typing/stop):**
  - Path parameter `{id}` is the conversation ID (integer).
  - JSON body: `{ "user_id": <int> }`.
  - Example: `POST /api/conversations/5/typing/stop` with body `{ "user_id": 1 }`.

- **Response (200 success for POST typing/stop):**
  - `{ "success": true, "message": "optional" }`. Frontend calls this when the user stops typing (e.g. after 3 seconds of no input) or when the user sends a message.

- **Request (GET typing):**
  - GET, no body. Path parameter `{id}` is the conversation ID. Query parameter `user_id` (integer, required) is the current user requesting the status.
  - Example: `GET /api/conversations/5/typing?user_id=1`

- **Response (200 success for GET typing):**
  - `{ "success": true, "data": { "typing_users": [ ... ] } }`. `typing_users` is an array of user objects. Each item must include at least: `id` (user ID), `first_name`, `last_name`. Backend should return only other participants currently typing (or all typing users; frontend filters out the current user for display).

- **Expectations:**
  - When a user types in ChatScreen, the frontend calls POST typing/start; after 3 seconds without input (or on send), it calls POST typing/stop. The frontend polls GET typing every 2 seconds to show "X anaandika..." (or "X na Y wanaandika...") with animated dots. Typing state should be short-lived on the backend (e.g. expire after 5–10 seconds without a refresh or stop). Navigation: Home → Messages (Ujumbe) → Chat → typing indicator is shown automatically when the other participant(s) are typing.

---

## Story 42: Join/Leave Group

- **Endpoints:**
  - `POST /api/groups/{id}/join` – current user requests to join the group (or joins immediately for public groups).
  - `POST /api/groups/{id}/leave` – current user leaves the group.

- **Request (POST join):**
  - Path parameter `{id}` is the group ID (integer).
  - JSON body: `{ "user_id": <int> }`. `user_id` is the current user requesting to join.
  - Example: `POST /api/groups/5/join` with body `{ "user_id": 1 }`.

- **Response (200 success for POST join):**
  - `{ "success": true, "message": "optional", "data": { "status": "<approved|pending>" } }`.
  - For **public** groups (or groups without approval): `status` is `"approved"`; user is added as member immediately. Frontend shows "Umejiunga" and refreshes group (Join button becomes Leave).
  - For **private** groups with approval: `status` is `"pending"`; user's request is queued for admin/mod approval. Frontend shows "Ombi limesafirishwa. Unasubiri idhini ya msimamizi." and displays "Ombi Linasubiri" on the button until approved or rejected. Backend must support listing/handling pending requests (e.g. `GET /api/groups/{id}/members?status=pending`, `POST /api/groups/{id}/members/{userId}/handle` with `action: approve|reject`).

- **Response (non-200 or success: false for POST join):**
  - Frontend shows `data.message` or "Imeshindwa kujiunga. Jaribu tena." in a SnackBar.

- **Request (POST leave):**
  - Path parameter `{id}` is the group ID (integer).
  - JSON body: `{ "user_id": <int> }`. `user_id` is the current user leaving.

- **Response (200 success for POST leave):**
  - `{ "success": true, "message": "optional" }`. Frontend shows "Umeondoka kwenye kikundi", refreshes group (Leave button becomes Join), and may pop back or refresh lists.

- **Response (non-200 or success: false for POST leave):**
  - Frontend shows "Imeshindwa kuondoka. Jaribu tena." in a SnackBar.

- **Approval flow for private groups:**
  - When a group has `requires_approval: true` (or equivalent) and/or `privacy: "private"`, POST join may return `data.status: "pending"`. The group detail response (`GET /api/groups/{id}?current_user_id=...`) must include `membership_status: "pending"` and `is_member: false` until the request is approved. After approval, subsequent GET group returns `membership_status: "approved"`, `is_member: true`. Frontend uses this to show "Ombi Linasubiri" and disable a second join request.

- **Expectations:**
  - Navigation: Home → Profile (Mimi) → Tab Vikundi → Tafuta Vikundi → GroupsScreen → Tap group → GroupDetailScreen → Join/Leave. Join and Leave use the above endpoints; approval flow is supported for private groups via `status: "pending"` and group `membership_status`.

---

## Story 41: Create Group

- **Endpoints:** `POST /api/groups`
- **Request:**
  - Multipart/form-data (to allow optional cover photo). Fields:
    - `creator_id` (required, integer): ID of the user creating the group.
    - `name` (required, string): Group name.
    - `description` (optional, string): Group description.
    - `privacy` (required, string): One of `public`, `private`, or `secret`.
      - `public`: Everyone can see and join.
      - `private`: Everyone can see; join requires approval.
      - `secret`: Only members can see the group.
    - `requires_approval` (optional, string): `"true"` or `"false"`; admins must approve new members when true.
    - `cover_photo` (optional, file): Image file for group cover.
  - Example: `POST /api/groups` with form fields as above.
- **Response (201 success):**
  - `{ "success": true, "message": "optional", "data": { ... } }`. `data` is the created group object with at least: `id`, `name`, `slug`, `description`, `cover_photo_path` or `cover_photo_url`, `privacy`, `creator_id`, `members_count` (or `approved_members_count`), `posts_count`, `requires_approval`, `created_at`, and optionally `creator` (with `id`, `first_name`, `last_name`, `username`, `profile_photo_path`).
- **Response (4xx / success: false):**
  - Frontend shows SnackBar with `message` or "Imeshindikana kuunda kikundi" and leaves the user on CreateGroupScreen.
- **Expectations:**
  - Backend creates the group and assigns the creator as admin. Creator is automatically a member. Frontend uses CreateGroupScreen (Story 41); navigation: Home → Profile → Groups tab → Unda Kikundi, or Groups discover (GroupsScreen) → FAB Create. After success, frontend pops with `true` and caller may refresh lists.

---

## Story 44: Create Page

- **Endpoints:**
  - `POST /api/pages` – Create a new page (business/brand page).
  - `GET /api/pages/categories` – List page categories for the create form (optional; frontend uses this to populate category dropdown).

- **Request (POST /api/pages):**
  - `multipart/form-data` or JSON. Required fields: `creator_id` (integer), `name` (string), `category` (string). Optional: `description` (string). Frontend CreatePageScreen (lib/screens/groups/createpage_screen.dart) sends at minimum: `creator_id`, `name`, `category`, and optionally `description`.
  - Example (form): `creator_id=1`, `name=Jina la Ukurasa`, `category=brand`, `description=Maelezo...`.
  - Example (JSON): `{ "creator_id": 1, "name": "Jina la Ukurasa", "category": "brand", "description": "Maelezo..." }`.

- **Response (201 success):**
  - `{ "success": true, "message": "optional", "data": { ... } }`. `data` is the created page object with at least: `id`, `name`, `slug`, `category`, `description`, `creator_id`, `created_at`, and optionally `profile_photo_url`, `cover_photo_url`, etc., as in PageModel.

- **Response (4xx / validation / success: false):**
  - `{ "success": false, "message": "..." }` or `{ "success": false, "errors": { "name": ["..."], "category": ["..."] } }`. Frontend shows message or field errors in a SnackBar (e.g. "Imeshindikana kuunda ukurasa").

- **Request (GET /api/pages/categories):**
  - GET, no body. Used to populate the category dropdown on CreatePageScreen.
  - Response (200): `{ "success": true, "data": [ { "value": "brand", "label": "Brand" }, ... ] }`. Each item has `value` (string) and `label` (string).

- **Expectations:**
  - Backend creates a page with the given name, category, and optional description; the creator is the page owner. Navigation: Discover/Profile → Create Page flow (e.g. Profile → Vikundi/Pages → Create Page, or Discover → Pages → Create). After success, frontend shows "Ukurasa umeundwa" and pops with `true` so the pages list can refresh.

---

## Story 90: Events Screen (Browse Events)

- **Endpoints:**
  - `GET /api/events` – list events (used for **Yanayokuja** tab).
  - `GET /api/events/user` – list events for a user by filter (used for **Matukio Yangu** tab).

- **Request (GET /api/events):**
  - GET, no body. Query parameters: `page` (integer, default 1), `per_page` (integer, default 20), `type` (string: `upcoming`, `past`, or `all`; frontend uses `upcoming`), optional `category`, optional `current_user_id` (integer) to include `user_response` per event.
  - Example: `GET /api/events?page=1&per_page=20&type=upcoming&current_user_id=1`

- **Response (200 success for GET /api/events):**
  - `{ "success": true, "data": [ ... ] }`. `data` is an array of event objects. Each event must include at least: `id`, `name`, `slug`, `start_date`, `end_date`, `start_time`, `end_time`, `is_all_day`, `location_name`, `location_address`, `is_online`, `online_link`, `creator_id`, `going_count`, `interested_count`, `not_going_count`, `created_at`. Optional: `description`, `cover_photo_url`, `creator`, `group`, `page`, `user_response` (when `current_user_id` is sent). Frontend parses with EventModel.fromJson.

- **Request (GET /api/events/user):**
  - GET, no body. Query parameters: `user_id` (integer), `filter` (string: `going`, `interested`, or `not_going`; frontend uses `going` for Matukio Yangu).
  - Example: `GET /api/events/user?user_id=1&filter=going`

- **Response (200 success for GET /api/events/user):**
  - Same as GET /api/events: `{ "success": true, "data": [ ... ] }`. `data` is the list of events the user is going to (or interested in / not going, depending on filter).

- **Expectations:**
  - **Yanayokuja:** Events list shows upcoming events; backend returns events with `start_date` in the future, ordered by start date. Each item may include `user_response` when `current_user_id` is provided so the card can show "Unaenda" / "Unavutiwa" badge.
  - **Matukio Yangu:** Events list shows events the current user responded "going" to. Backend returns only events where the user has RSVP'd going for the given `user_id`.
  - Navigation: Discover/Home → Events → EventsScreen (tabs: Yanayokuja, Matukio Yangu). FAB opens Create Event (Story 46). Tapping an event opens EventDetailScreen (Story 47).

---

## Story 46: Create Event

- **Endpoints:** `POST /api/events`
- **Request:**
  - Multipart/form-data (to allow optional cover photo). Required fields: `creator_id` (integer), `name` (string, event title), `start_date` (ISO date string, e.g. `YYYY-MM-DD`). Optional: `description` (string), `end_date`, `start_time`, `end_time` (time strings e.g. `HH:mm`), `is_all_day` (string `"true"`/`"false"`), `location_name`, `location_address`, `latitude`, `longitude`, `is_online` (`"true"`/`"false"`), `online_link`, `privacy`, `category`, `group_id`, `page_id`, `ticket_price`, `ticket_currency`, `ticket_link`, `cover_photo` (file).
  - Example: `POST /api/events` with form fields: `creator_id=1`, `name=Tukio la Mwaka`, `start_date=2025-03-15`, `description=Maelezo...`, `location_name=Dar es Salaam`, `location_address=...`, `start_time=10:00`, `is_all_day=false`, `is_online=false`, etc.
- **Response (201 success):**
  - `{ "success": true, "message": "optional", "data": { ... } }`. `data` is the created event object with at least: `id`, `name`, `slug`, `description`, `start_date`, `end_date`, `start_time`, `end_time`, `is_all_day`, `location_name`, `location_address`, `is_online`, `online_link`, `privacy`, `creator_id`, `going_count`, `interested_count`, `not_going_count`, `created_at`, and optionally `cover_photo_url`, `creator`, etc., as in EventModel.
- **Response (4xx / success: false):**
  - `{ "success": false, "message": "..." }`. Frontend shows SnackBar with message or "Imeshindikana kuunda tukio" and leaves the user on CreateEventScreen.
- **Expectations:**
  - Backend creates the event with title, date, location, and description as provided. Creator is the host. Navigation: Home → Events discover OR Profile → Events → Create (FAB on EventsScreen opens CreateEventScreen). After success, frontend shows "Tukio limeundwa" and pops with `true` so the events list can refresh.

---

## Story 45: Follow/Like Page

- **Endpoints:**
  - `POST /api/pages/{id}/follow` – Follow a page (current user follows the page).
  - `DELETE /api/pages/{id}/follow` – Unfollow a page (current user stops following).
  - `POST /api/pages/{id}/like` – Like a page (current user likes the page).

- **Request (POST /api/pages/{id}/follow):**
  - Path parameter `{id}` is the integer page ID.
  - JSON body: `{ "user_id": <int> }`. `user_id` is the current user performing the action.
  - Example: `POST /api/pages/5/follow` with body `{ "user_id": 1 }`.

- **Response (200 success for POST follow):**
  - `{ "success": true, "message": "optional", "data": { "followers_count": <int> } }`. Frontend expects `data.followers_count` to update the displayed followers count on the page detail screen. Page detail should also reflect `is_following: true` when fetched with `current_user_id`.

- **Request (DELETE /api/pages/{id}/follow):**
  - Path parameter `{id}` is the integer page ID.
  - JSON body (optional): `{ "user_id": <int> }`. Backend may derive user from auth.

- **Response (200 success for DELETE follow):**
  - `{ "success": true, "message": "optional", "data": { "followers_count": <int> } }`. Frontend updates the followers count and sets `is_following: false` locally.

- **Request (POST /api/pages/{id}/like):**
  - Path parameter `{id}` is the integer page ID.
  - JSON body: `{ "user_id": <int> }`. `user_id` is the current user performing the like.

- **Response (200 success for POST like):**
  - `{ "success": true, "message": "optional", "data": { "likes_count": <int> } }`. Frontend expects `data.likes_count` to update the displayed likes count. Page detail should reflect `is_liked: true` when fetched with `current_user_id`.

- **Response (non-200 or success: false for any of the above):**
  - Frontend shows SnackBar with `message` or a generic "Jaribu tena" and does not change follow/like state.

- **Expectations:**
  - **Follow:** One user can follow a page once; following again is idempotent. Unfollow removes the follow relationship. Single page response `GET /api/pages/{id}?current_user_id=...` must include `is_following` (boolean) and `followers_count` (integer) so the page detail screen can show the Follow/Unfollow button and count.
  - **Like:** One user can like a page once; liking again may be idempotent or toggle. Page response must include `is_liked` (boolean) and `likes_count` (integer). If backend supports unlike, frontend uses `DELETE /api/pages/{id}/like` (optional; Story 45 specifies POST like only; frontend already implements unlike for UX).
  - Navigation: Page detail (PageDetailScreen) → Follow button (Fuatilia/Unafuatilia) and Like button (Penda/Umependia). Touch targets are at least 48dp per DESIGN.md. Implemented in `lib/screens/pages/page_detail_screen.dart` and `lib/services/page_service.dart`.

---

## Story 43: Group Posts

- **Endpoints:**
  - `GET /api/groups/{id}/posts` – list posts for a group (paginated).
  - `POST /api/groups/{id}/posts` – create a post in a group.

- **Request (GET /api/groups/{id}/posts):**
  - GET, no body. Path parameter `{id}` is the integer group ID.
  - Query parameters: `page` (integer, default 1), `per_page` (integer, default 20).
  - Example: `GET /api/groups/5/posts?page=1&per_page=20`

- **Response (200 success for GET):**
  - `{ "success": true, "data": [ ... ], "meta": { "current_page", "last_page", "per_page", "total" (optional) }, "message": "optional" }`.
  - Each item in `data` is a post object (same shape as other post endpoints): `id`, `user_id`, `content`, `post_type`, `privacy`, `created_at`, `user` (with `id`, `first_name`, `last_name`, `username`, `profile_photo_path` or `profile_photo_url`), `media` (array of media objects), `likes_count`, `comments_count`, `is_liked` (optional for current user), etc. Only posts that belong to the group (e.g. `group_id` or association) are returned. Visibility may be restricted to group members depending on group privacy.

- **Request (POST /api/groups/{id}/posts):**
  - `multipart/form-data` when media is present. Path parameter `{id}` is the integer group ID.
  - Required: `user_id` (integer, author). Optional: `content` (string, caption/text). Optional: `media[]` (array of image files). At least one of `content` or `media[]` must be provided.
  - Example (text only): `user_id=1`, `content=Hello group`.
  - Example (with photo): `user_id=1`, `content=Caption`, `media[]=file1.jpg`, `media[]=file2.jpg`.

- **Response (201 success for POST):**
  - `{ "success": true, "message": "optional", "data": { ... } }`. `data` is the created post object (same shape as in GET list) so the group feed can append the new post and refresh counts.

- **Response (4xx / validation / success: false):**
  - When user is not a member or not allowed to post: `{ "success": false, "message": "..." }`. Frontend shows message in SnackBar (e.g. "Imeshindwa kuchapisha. Jaribu tena.").
  - Validation: `{ "success": false, "message": "...", "errors": { ... } }`.

- **Expectations:**
  - Only group members (approved membership) may create posts in the group. Backend must associate the post with the group (e.g. `group_id` on the post or group_posts join table). GET returns posts in reverse chronological order (newest first). Navigation: Home → Profile → Vikundi → Group detail → Posts tab (Machapisho). Members see a FAB to create a post; CreateGroupPostScreen sends POST with text and/or images; after success the group detail refreshes the posts list and post count.

---

## Story 47: Event RSVP

- **Endpoints:**
  - `POST /api/events/{id}/respond` – set or update the current user’s RSVP (Going / Interested / Not Going).
  - `DELETE /api/events/{id}/respond` – remove the current user’s response (optional; frontend may use "Not Going" as the way to clear interest).
  - `GET /api/events/{id}/attendees?type={type}` – list attendees by response type for **View attendees**.

- **Request (POST /api/events/{id}/respond):**
  - Path parameter `{id}` is the event ID (integer).
  - JSON body: `{ "user_id": <int>, "response": "<going|interested|not_going>" }`. `user_id` is the current user; `response` is one of `going`, `interested`, `not_going`.
  - Example: `POST /api/events/5/respond` with body `{ "user_id": 1, "response": "going" }`.

- **Response (200 success for POST):**
  - `{ "success": true, "message": "optional", "data": { "going_count": <int>, "interested_count": <int>, "not_going_count": <int> (optional) } }`. Frontend uses these counts to update the event detail UI without refetching the full event. If `not_going_count` is omitted, frontend keeps the previous value.

- **Response (4xx / success: false):**
  - `{ "success": false, "message": "..." }`. Frontend shows the message in a SnackBar (e.g. "Imeshindwa kusasisha jibu. Jaribu tena.").

- **Request (GET /api/events/{id}/attendees):**
  - GET, no body. Path parameter `{id}` is the event ID. Query parameter `type` is one of `going`, `interested`, `not_going` (default `going`).
  - Example: `GET /api/events/5/attendees?type=going`

- **Response (200 success for GET attendees):**
  - `{ "success": true, "data": [ ... ] }`. `data` is an array of user/attendee objects. Each item must include at least: `id`, `first_name`, `last_name`, `username` (optional), `profile_photo_path` and/or `profile_photo_url` (optional, for avatar). Frontend displays these in EventAttendeesScreen (tabs: Wanaenda / Wanavutiwa / Hawaendi). If `type=not_going` is not supported, backend may return 400 or empty array; frontend still shows the tab with an empty list.

- **Expectations:**
  - **RSVP:** User can set exactly one of Going, Interested, or Not Going per event. Submitting a new response overwrites the previous one. Single event response (`GET /api/events/{id}?current_user_id=...`) must include `user_response` (`going` | `interested` | `not_going` | null) and counts `going_count`, `interested_count`, `not_going_count` so the event detail screen can show the selected state and stats.
  - **View attendees:** Event detail shows tappable stats (Wanaenda, Wanavutiwa, Hawaendi) that open the attendees list for that type. Backend returns paginated or full list of users who responded with the given type; frontend uses the same attendee shape (EventCreator: id, first_name, last_name, username, profile_photo_path, profile_photo_url).
  - Navigation: Event detail → Going / Interested / Not Going buttons; tap on a count → EventAttendeesScreen (Washiriki) with tabs for each type.

---

## Story 48: Create Poll

- **Endpoints:** `POST /api/polls`

- **Request (POST /api/polls):**
  - JSON body (Content-Type: application/json). Required: `creator_id` (integer), `question` (string), `options` (array of strings; at least 2, frontend allows up to 10). Optional: `description` (string), `ends_at` (ISO 8601 datetime string, end date/time for the poll), `group_id` (integer), `page_id` (integer), `is_multiple_choice` (boolean, allow multiple options per user), `is_anonymous` (boolean), `show_results_before_voting` (boolean), `allow_add_options` (boolean).
  - Example: `{ "creator_id": 1, "question": "Chaguo lako?", "options": ["A", "B", "C"], "ends_at": "2025-03-01T23:59:00.000Z", "is_multiple_choice": false, "is_anonymous": false }`.

- **Response (201 success):**
  - `{ "success": true, "message": "optional", "data": { ... } }`. Frontend expects `data` to be the created poll object (e.g. `id`, `question`, `options` (array with `id`, `option_text`, `votes_count`, etc.), `creator_id`, `ends_at`, `status`, `created_at`, `creator`, etc.) so the app can show success and optionally navigate to poll detail or refresh feed.

- **Response (4xx / validation / success: false):**
  - `{ "success": false, "message": "...", "errors": { "question": ["..."], "options": ["..."] } }`. Frontend shows message or field errors in a SnackBar (e.g. "Imeshindikana kuunda kura").

- **Expectations:**
  - Backend creates a poll with the given question, options (stored as poll_options with order), and optional end date. If `ends_at` is provided, the poll closes at that time. Navigation: Home → Feed → Create Post → Poll option → CreatePollScreen (lib/screens/groups/createpoll_screen.dart). After success, frontend pops with `true` so the feed can refresh.

---

## Story 49: Vote on Poll

- **Endpoints:**
  - `POST /api/polls/{id}/vote` – submit the current user’s vote (one or more option IDs).
  - `DELETE /api/polls/{id}/vote` – remove the current user’s vote.

- **Request (POST /api/polls/{id}/vote):**
  - Path parameter `{id}` is the poll ID (integer).
  - JSON body: `{ "user_id": <int>, "option_ids": [<int>, ...] }`. For single-choice polls the frontend sends one option ID; for multiple-choice, an array of option IDs.
  - Example: `POST /api/polls/5/vote` with body `{ "user_id": 1, "option_ids": [12] }`.

- **Response (200 success for POST):**
  - `{ "success": true, "data": { ... } }`. Frontend expects `data` to be the updated poll object (same shape as GET poll: `id`, `question`, `options` with `id`, `option_text`, `votes_count`, `votes_count` / `percentage` per option, `total_votes`, `user_voted_option_id` or `user_votes`, `has_voted`, etc.) so the UI can show results after voting (counts and progress bars per option).

- **Request (DELETE /api/polls/{id}/vote):**
  - Path parameter `{id}` is the poll ID.
  - JSON body: `{ "user_id": <int>, "option_id": <int>? }`. `option_id` optional when the user has only one vote to remove.

- **Response (200 success for DELETE):**
  - `{ "success": true, "data": { ... } }`. Same as POST: updated poll object so the frontend can show the poll again in “not voted” state and refresh results.

- **Expectations:**
  - One vote per user per option (or per poll for single-choice). After voting, the frontend shows results (option counts and percentages). The feed and group post cards display poll posts with inline voting via PollVoteWidget (tap option → vote → results). Posts of type `poll` must include `poll_id` in the post payload so the client can load the poll and offer vote/unvote. Navigation path: Poll post/card → Tap option → Vote; after vote, results are shown inline.

---

## Story 50: Create Story

- **Endpoints:**
  - `POST /api/stories` – create a 24-hour story (photo or video up to 60s, with optional stickers, filters, caption).

- **Request (POST /api/stories):**
  - `multipart/form-data` when media (photo/video) is present.
  - Required: `user_id` (integer), `media_type` (string: `text`, `image`, or `video`).
  - Optional: `media` (file; required when `media_type` is `image` or `video`), `caption` (string), `duration` (integer, seconds; for video, max 60), `filter` (string; e.g. `none`, `vivid`, `warm`, `cool`, `bw`, `sepia`), `background_color` (string, hex without #; for text stories), `text_overlays` (JSON array of overlay objects), `stickers` (JSON array; e.g. `[{ "type": "emoji", "value": "❤️", "x": 0.5, "y": 0.5 }]`), `privacy` (string: `everyone`, `followers`, `close_friends`), `allow_replies` (boolean), `allow_sharing` (boolean).
  - Example (image): `user_id=1`, `media_type=image`, `media=<file>`, `caption=Hello`, `filter=warm`, `stickers=[...]`, `privacy=everyone`, `allow_replies=true`, `allow_sharing=true`.
  - Example (text): `user_id=1`, `media_type=text`, `caption=My story`, `background_color=FF1E88E5`, `privacy=everyone`.

- **Response (201 success):**
  - `{ "success": true, "message": "optional", "data": { ... } }`. `data` is the created story object (e.g. `id`, `user_id`, `media_type`, `media_path`, `thumbnail_path`, `caption`, `duration`, `filter`, `stickers`, `expires_at` (24h from creation), `created_at`, etc.) so the app can show success and refresh the stories list.

- **Response (4xx / validation / success: false):**
  - `{ "success": false, "message": "..." }`. Frontend shows message in SnackBar (e.g. "Imeshindwa kuchapisha hadithi").
  - Video duration must be ≤ 60 seconds; backend may reject or truncate longer videos.

- **Expectations:**
  - Stories expire 24 hours after creation. Backend stores media (image/video), applies filter if provided, stores stickers/overlays for playback. Navigation: Home → Feed/Profile → Stories ring → Create Story (lib/screens/clips/createstory_screen.dart). After success, frontend pops and refreshes stories.

---

## Story 51: View Stories

- **Endpoints:**
  - `GET /api/stories` – list story groups (friends’ stories, plus own) for the feed stories row. Stories expire after 24h.
  - `POST /api/stories/{id}/view` – record a view when the current user views a story (track views).

- **Request (GET /api/stories):**
  - GET, no body. Query parameter: `current_user_id` (integer, optional). Used so the backend can return `has_viewed` per story and filter/order by unviewed.
  - Example: `GET /api/stories?current_user_id=1`

- **Response (200 success):**
  - `{ "success": true, "data": [ ... ], "message": "optional" }`. `data` is an array of **story group** objects. Each group: `{ "user": { "id", "first_name", "last_name", "username", "profile_photo_path" }, "stories": [ ... ], "has_unviewed": boolean }`. Each story in `stories`: `id`, `user_id`, `media_type` (`image`|`video`|`text`), `media_path`, `thumbnail_path`, `caption`, `duration` (seconds, default 5), `background_color`, `views_count`, `reactions_count`, `expires_at` (ISO 8601), `created_at`, `has_viewed` (boolean for current user). Backend should exclude stories past 24h (`expires_at` in the past).

- **Request (POST /api/stories/{id}/view):**
  - Path parameter `{id}` is the story ID (integer).
  - JSON body: `{ "user_id": <int> }`. `user_id` is the viewer (current user).
  - Example: `POST /api/stories/42/view` with body `{ "user_id": 1 }`

- **Response (200 success for POST view):**
  - `{ "success": true, "message": "optional" }`. Backend records the view (viewer_id, story_id, viewed_at) and may increment `views_count` for the story. Idempotent: viewing again does not duplicate count.

- **Expectations:**
  - **GET /api/stories:** Returns story groups for the feed “Stories” row (Home → Feed → Stories row). Each group is one user’s stories (newest first); stories expire 24h after creation. Frontend uses this in FeedScreen for “Kwa Wewe” and “Marafiki” tabs; tap on a group opens StoryViewerScreen (tap right=next, left=previous, auto-advance ~5s, progress bar, swipe down to exit, view count for own stories).
  - **Track views:** When the user opens a story, the frontend calls POST view so the author can see view count on their own stories.

---

## Story 53: Create Clip

- **Endpoints:**
  - `POST /api/clips` – create a short-form clip (vertical video up to 60 seconds, with optional music overlay and filter).

- **Request (POST /api/clips):**
  - Content-Type: `multipart/form-data`.
  - **Required:** `video` (file), `user_id` (integer).
  - **Optional:** `caption` (string), `music_id` (integer, from music library), `music_start` (integer, start position in track in seconds), `filter` (string, e.g. `normal`, `vivid`, `warm`, `cool`, `black_white`, `vintage`, `fade`, `dramatic`, `noir`), `hashtags` (JSON array of strings), `mentions` (JSON array of user IDs), `location_name` (string), `latitude` (double), `longitude` (double), `privacy` (string: `public`|`followers`|`private`), `allow_comments` (boolean), `allow_duet` (boolean), `allow_stitch` (boolean), `allow_download` (boolean), `original_clip_id` (integer), `clip_type` (string, e.g. `original`|`duet`|`stitch`).
  - Example fields: `user_id=1`, `caption=Jambo`, `music_id=5`, `music_start=0`, `filter=vivid`, `hashtags=["bongo","tanzania"]`, `privacy=public`, `allow_comments=true`, `allow_duet=true`, `allow_stitch=true`, `allow_download=true`, `clip_type=original`.

- **Response (201 success):**
  - `{ "success": true, "data": { ... } }`. `data` is the created clip object (same shape as GET clip: `id`, `user_id`, `video_path`, `thumbnail_path`, `caption`, `duration`, `music_id`, `music_start`, `hashtags`, `privacy`, `allow_comments`, `allow_duet`, `allow_stitch`, `allow_download`, `views_count`, `likes_count`, `comments_count`, `created_at`, `user`, `music`, etc.).

- **Response (4xx/5xx or success: false):**
  - `{ "success": false, "message": "..." }`. Frontend shows the message to the user.

- **Expectations:**
  - Vertical video; max duration 60 seconds. Backend may validate duration and reject or trim if longer.
  - Music overlay: when `music_id` is sent, backend associates the clip with that track and may apply/overlay audio; `music_start` is the start offset in the track (seconds).
  - Filter: optional; backend may apply server-side processing for the given filter name or store for display.
  - Navigation path: Home → Profile → Videos tab → Upload (UploadVideoScreen) OR Clips discover → Create (CreateClipScreen). Both flows create a clip via POST /api/clips (UploadVideoScreen uses resumable upload that also targets this endpoint).

---

## Story 54: Clips Feed & Player

- **Endpoints:**
  - `GET /api/clips` – list clips for the clips feed (paginated).
  - `GET /api/clips/trending` – list trending clips (by views, likes, or trending score).

- **Request (GET /api/clips):**
  - GET, no body. Query parameters: `page` (integer, default 1), `per_page` (integer, default 20), optional `current_user_id` (integer) so the backend can return `is_liked`, `is_saved` for the requesting user.
  - Example: `GET /api/clips?page=1&per_page=20&current_user_id=1`

- **Response (200 success for GET /api/clips):**
  - `{ "success": true, "data": [ ... ], "meta": { "current_page", "last_page", "per_page", "total" (optional) }, "message": "optional" }`.
  - `data` is an array of clip objects. Each clip: `id`, `user_id`, `video_path`, `thumbnail_path`, `caption`, `duration`, `privacy`, `views_count`, `likes_count`, `comments_count`, `shares_count`, `saves_count`, `created_at`, `user` (with `id`, `first_name`, `last_name`, `username`, `profile_photo_path`), optional `music`, `is_liked` (boolean for current user), `is_saved` (boolean for current user), `hashtags` (array of strings).

- **Request (GET /api/clips/trending):**
  - GET, no body. Query parameters: optional `page`, `per_page`, `current_user_id` (same as GET /api/clips).

- **Response (200 success for GET /api/clips/trending):**
  - Same envelope and clip shape as GET /api/clips. Clips ordered by trending score (e.g. views, likes, recency).

- **Expectations:**
  - Clips feed (ClipsScreen) and ClipPlayerScreen use these endpoints for full-screen vertical swipe feed. Auto-play with sound; mute toggle is client-side. Like, comment, share overlays; infinite scroll via `page`; frontend preloads next 2 videos. Navigation: Home → Feed → Shorts tab → (Klipu action or Tazama Klipu) → ClipsScreen, or direct route `/clips`. ClipPlayerScreen is used with a list of clips for vertical swipe next/prev.

---

## Story 52: Story Highlights

- **Endpoints:**
  - `POST /api/stories/highlights` – create a new story highlight (permanent album) with title and story IDs.
  - `GET /api/stories/highlights/{userId}` – list all story highlights for a user (permanent highlight albums).
  - Optional: `POST /api/stories/highlights/{id}/stories` – add a story to an existing highlight (used by Add to highlight flow).

- **Request (POST /api/stories/highlights):**
  - `multipart/form-data`. Required: `user_id` (integer), `title` (string), `story_ids` (JSON array of integers, e.g. `"[1,2,3]"`). Optional: `cover` (image file) for cover photo.
  - Example: `user_id=1`, `title=Safari`, `story_ids=[5,6,7]`.

- **Response (201 success for POST /api/stories/highlights):**
  - `{ "success": true, "data": { ... } }`. `data` is the created highlight: `id`, `user_id`, `title`, `cover_path` (optional), `order`, optional `stories` (array of story objects). Frontend uses this to refresh the highlights list.

- **Request (GET /api/stories/highlights/{userId}):**
  - GET, no body. Path parameter `{userId}` is the profile user whose highlights to list.

- **Response (200 success for GET /api/stories/highlights/{userId}):**
  - `{ "success": true, "data": [ ... ] }`. `data` is an array of highlight objects. Each: `id`, `user_id`, `title`, `cover_path` (optional), `order`, optional `stories` (array of story objects with same shape as Story 50). Highlights are permanent (do not expire with 24h stories).

- **Request (POST /api/stories/highlights/{id}/stories) – add story to existing highlight:**
  - JSON body: `{ "story_id": <int> }`. Path parameter `{id}` is the highlight ID.
  - Example: `POST /api/stories/highlights/3/stories` with body `{ "story_id": 12 }`.

- **Response (200 or 201 success):**
  - `{ "success": true, "message": "optional" }` or include updated highlight in `data`. Frontend uses this when user taps "Add to this highlight" in AddToHighlightScreen.

- **Expectations:**
  - Story highlights are permanent albums on the profile. Users create highlights from Profile → Story highlight → Add (New), or add a story to a highlight from the story viewer (Add to highlight). GET returns highlights for the given user; each highlight may include `stories` for the viewer screen. Navigation: Profile → Story highlight (StoryHighlightsScreen) → tap highlight (HighlightViewerScreen) or Add (CreateHighlightScreen); from story viewer → Add to highlight (AddToHighlightScreen).

---

## Story 56: Upload Music

- **Endpoints:**
  - `POST /api/music/extract-metadata` – upload a single audio file; server extracts metadata and stores the file temporarily. Returns `temp_upload_id` and extracted metadata. Used when not using chunked upload (e.g. small files).
  - `POST /api/music/upload-chunk` – chunked/resumable upload. Client sends one chunk per request with fields: `user_id`, `resumableChunkNumber`, `resumableTotalChunks`, `resumableChunkSize`, `resumableTotalSize`, `resumableIdentifier`, `resumableFilename`, and file part `file`. When the final chunk is received, server assembles the file, extracts metadata, and returns `temp_upload_id`, `data` (metadata), `audio_url`, `cover_url`, and `done: true`.
  - `POST /api/music/finalize-upload` – finalize a track after upload. Required fields: `temp_upload_id`, `user_id`, `title`. Optional: `album`, `genre`, `bpm` (integer), `is_explicit` (0/1), `category_ids` (comma-separated), and optional file `cover_image` to override embedded cover.
  - `POST /api/music/cancel-upload` – cancel and clean up a pending upload. JSON body: `{ "temp_upload_id": string, "user_id": int }`.

- **Request/response:**
  - **extract-metadata:** `multipart/form-data` with `user_id` (string) and `audio_file` (audio file). Supported formats: MP3, WAV, AAC, M4A, OGG, FLAC. Response 200: `{ "success": true, "temp_upload_id": string, "audio_url": string?, "cover_url": string?, "data": { ...metadata } }`. Metadata object may include `title`, `artist`, `album`, `genre`, `duration`, `duration_formatted`, `bpm`, `bitrate`, `file_size`, `has_embedded_cover`, etc.
  - **upload-chunk:** `multipart/form-data` with fields above and `file` (chunk bytes). Response 200: `{ "done": boolean, "temp_upload_id": string?, "audio_url": string?, "cover_url": string?, "data": { ...metadata }? }`. When `done` is true, frontend uses `temp_upload_id` for finalize-upload.
  - **finalize-upload:** `multipart/form-data` with `temp_upload_id`, `user_id`, `title`, optional `album`, `genre`, `bpm`, `is_explicit`, `category_ids`, optional `cover_image` file. Response 200/201: `{ "success": true, "data": { ...track } }`. Track shape: `id`, `title`, `slug`, `artist_id`, `audio_path`, `cover_path`, `duration`, `album`, `genre`, `bpm`, `is_explicit`, `created_at`, `artist`, etc. (same as GET track).
  - **cancel-upload:** JSON body as above. Response 200: success.

- **Expectations:**
  - Chunked upload is used for large files (e.g. 2MB chunk size, multiple chunks). Frontend sends chunks in parallel batches; server must accept chunks in any order and reassemble by `resumableIdentifier`; when last chunk is received, server runs metadata extraction and returns `done: true` with `temp_upload_id`.
  - After upload (either extract-metadata or last chunk), frontend calls finalize-upload with `temp_upload_id` and title (from metadata or filename). Backend creates the music track, associates with the user’s artist profile, and returns the created track.
  - Navigation: Home → Profile → Music tab (Muziki) → Upload button → MusicUploadScreen. Max file size guidance: e.g. 50 MB; formats MP3, WAV, AAC, M4A, OGG, FLAC.

---

## Story 55: Music Library

- **Endpoints:**
  - `GET /api/music` – list music tracks (library), paginated.
  - `GET /api/music/trending` – list trending music tracks.

- **Request (GET /api/music):**
  - GET, no body. Query parameters: `page` (integer, default 1), `per_page` (integer, default 20), optional `current_user_id` (integer) so the backend can return `is_saved` for the requesting user.
  - Example: `GET /api/music?page=1&per_page=20&current_user_id=1`

- **Response (200 success for GET /api/music):**
  - `{ "success": true, "data": [ ... ], "meta": { "current_page", "last_page", "per_page", "total" (optional) }, "message": "optional" }`.
  - `data` is an array of track objects. Each track: `id`, `title`, `slug`, `artist_id`, `album`, `audio_path`, `cover_path`, `duration`, `genre`, `bpm`, `is_explicit`, `uses_count`, `plays_count`, `is_featured`, `is_trending`, `created_at`, `artist` (object with `id`, `name`, `slug`, `image_path`, etc.), `categories` (array), `is_saved` (boolean for current user when `current_user_id` provided).

- **Request (GET /api/music/trending):**
  - GET, no body. Query parameters: optional `current_user_id` (integer).

- **Response (200 success for GET /api/music/trending):**
  - Same envelope and track shape as GET /api/music. Tracks ordered by trending score (e.g. plays, recency).

- **Expectations:**
  - MusicScreen (lib/screens/music/music_screen.dart or lib/screens/clips/music_screen.dart) uses these endpoints to let users browse and play music. MusicPlayerSheet provides playback with queue, repeat, shuffle; background playback is supported via the app's audio service and notification controls. Navigation: Home → Profile → Music tab (Muziki) → Library link (Maktaba) → MusicScreen, or direct route to MusicScreen. MusicPlayerSheet provides playback with queue, repeat, shuffle; background playback is supported via the app’s audio service and notification controls. Navigation: Home → Profile → Music tab (Muziki) → Library link (Maktaba) → MusicScreen, or direct route to MusicScreen.

---

## Story 78: Profile Music Gallery Tab

- **Endpoints:**
  - `GET /api/music/user/:userId` – list music tracks uploaded by a specific user (profile music gallery). Used by MusicGalleryWidget and MusicGalleryWidgetScreen.

- **Request (GET /api/music/user/:userId):**
  - GET, no body. Path parameter `:userId` (integer). Query parameters: `page` (integer, default 1).
  - Example: `GET /api/music/user/5?page=1`

- **Response (200 success):**
  - `{ "success": true, "data": [ ... ], "meta": { "current_page", "last_page", "per_page", "total" (optional) }, "message": "optional" }`.
  - `data` is an array of track objects. Same track shape as GET /api/music: `id`, `title`, `slug`, `artist_id`, `album`, `audio_path`, `cover_path`, `duration`, `genre`, `bpm`, `is_explicit`, `uses_count`, `plays_count`, `created_at`, `artist` (object with `id`, `name`, `slug`, `image_path`, etc.), `categories` (array).

- **Expectations:**
  - MusicGalleryWidget (lib/widgets/gallery/music_gallery_widget.dart) and MusicGalleryWidgetScreen (lib/screens/feed/musicgallerywidget_screen.dart) use this endpoint to show a profile's music. Navigation: Home → Profile → Tab [Muziki] → MusicGalleryWidget; or direct route /profile/:userId/music → MusicGalleryWidgetScreen.

---

## Story 58: Watch Live Stream

- **Endpoints:**
  - `GET /api/streams` – list streams (live, scheduled, or all). Used by Feed → Live tab and Profile → Live tab to show available streams.
  - `POST /api/streams/{id}/join` – join a stream as a viewer (called when user opens StreamViewerScreen).
  - `POST /api/streams/{id}/leave` – leave stream (called when user exits viewer).
  - Optional: WebSocket for real-time viewer count, comments, gifts (e.g. `wss://.../streams/{id}?user_id=...`).
  - Optional: `GET /api/streams/{id}/comments`, `POST /api/streams/{id}/comments`, `GET /api/streams/gifts`, `POST /api/streams/{id}/gifts`, `POST /api/streams/{id}/like` for chat, like, and gifts.

- **Request (GET /api/streams):**
  - GET, no body. Query parameters: optional `status` (e.g. `live`, `scheduled`), optional `current_user_id` (integer).
  - Example: `GET /api/streams?status=live&current_user_id=1`

- **Response (200 success for GET /api/streams):**
  - `{ "success": true, "data": [ ... ] }`. `data` is an array of stream objects. Each stream: `id`, `stream_key`, `user_id`, `title`, `description`, `thumbnail_path`, `category`, `tags`, `status` (`live`|`scheduled`|`ended`), `privacy`, `stream_url`, `playback_url` (HLS or URL for playback; optional `playback_url_low` for 2G/3G adaptive bitrate), `viewers_count`, `peak_viewers`, `total_viewers`, `likes_count`, `comments_count`, `gifts_count`, `allow_comments`, `allow_gifts`, `is_recorded`, `scheduled_at`, `started_at`, `ended_at`, `duration`, `created_at`, `user` (object with `id`, `first_name`, `last_name`, `display_name`, `avatar_url`), optional `is_liked` for current user.

- **Request (POST /api/streams/{id}/join):**
  - JSON body: `{ "user_id": <int> }`. Path parameter `{id}` is the stream ID.
  - Example: `POST /api/streams/5/join` with body `{ "user_id": 1 }`

- **Response (200 success for POST /api/streams/{id}/join):**
  - `{ "success": true }` or 200 with no body. Backend increments viewer count and may push updates via WebSocket.

- **Request (POST /api/streams/{id}/leave):**
  - JSON body: `{ "user_id": <int> }`.

- **Response (200 success for POST /api/streams/{id}/leave):**
  - 200. Backend decrements viewer count.

- **Expectations:**
  - StreamViewerScreen (lib/screens/clips/streamviewer_screen.dart) provides full-screen video, overlay chat, like/hearts, gifts. Navigation: Home → Feed → Live tab → Tap stream, or Profile → Live tab → Tap. Client shows viewer count, tap-to-focus (show/hide overlay), exit confirmation before leaving. For adaptive bitrate on 2G/3G, backend may expose `playback_url_low` or multiple HLS renditions; client uses `playback_url` when provided, else builds `/live/{id}.m3u8` from base URL.

---

## Story 59: Initiate Voice/Video Call

- **Endpoints:**
  - `POST /api/calls/initiate` – initiate a voice or video call to a friend (caller).
  - `POST /api/calls/{callId}/answer` – callee answers the call.
  - `POST /api/calls/{callId}/decline` – callee declines the call.
  - `POST /api/calls/{callId}/end` – end an active or ringing call.
  - `GET /api/calls/{callId}/status?user_id={userId}` – get current call status (for polling).
  - `GET /api/calls/history?user_id={userId}&page={page}&per_page={perPage}&type={opt}&direction={opt}` – list call history (used by Call History screen).

- **Request/response**

  - **Initiate call** `POST /api/calls/initiate`
    - Body: `{ "user_id": int (caller), "callee_id": int, "type": "voice" | "video" }`
    - Response 201: `{ "success": true, "data": { ...call } }`. Call object: `id`, `call_id` (string), `caller_id`, `callee_id`, `type` ("voice"|"video"), `status` ("pending"|"ringing"|"answered"|"ended"|"missed"|"declined"), `started_at`, `answered_at`, `ended_at`, `duration`, `end_reason`, `caller` (user object), `callee` (user object). User: `id`, `first_name`, `last_name`, `username`, `profile_photo_path`.
    - On failure: 4xx/5xx or `{ "success": false, "message": string }`.

  - **Answer** `POST /api/calls/{callId}/answer`
    - Body: `{ "user_id": int }` (callee).
    - Response 200: `{ "success": true, "data": { ...call } }` with updated call (e.g. status "answered").

  - **Decline** `POST /api/calls/{callId}/decline`
    - Body: `{ "user_id": int }`.
    - Response 200: `{ "success": true, "data": { ...call } }` (status "declined").

  - **End call** `POST /api/calls/{callId}/end`
    - Body: `{ "user_id": int }`.
    - Response 200: `{ "success": true, "data": { ...call } }` (status "ended", optional `duration`, `end_reason`).

  - **Status** `GET /api/calls/{callId}/status?user_id={userId}`
    - Response 200: `{ "success": true, "data": { ...call } }` with current status.

  - **History** `GET /api/calls/history?...`
    - Query: `user_id` (required), `page`, `per_page`, optional `type` (voice|video), `direction` (incoming|outgoing).
    - Response 200: `{ "success": true, "data": [ ...callLog ], "meta": { "current_page", "last_page", "per_page", "total" } }`. CallLog: `id`, `user_id`, `other_user_id`, `type`, `direction`, `status` (answered|missed|declined), `duration`, `call_time`, `other_user` (user object).

- **Expectations:**
  - Navigation: Home → Messages → Chat → Call icon (voice or video). Profile → Simu opens Call History; from history user can initiate voice/video to a contact.
  - Voice or video mode is chosen at initiation (`type`). CallScreen (outgoing) shows "Inapiga..." and polls status until answered/declined/ended. IncomingCallScreen shows answer/decline (Story 59). All touch targets respect DESIGN.md (min 48dp).

---

## Story 87: Call History

- **Endpoints:**
  - `GET /api/calls/history?user_id={userId}&page={page}&per_page={perPage}&type={opt}&direction={opt}` – list call history for the current user (same as Story 59).

- **Request/response:**
  - GET, no body. Query: `user_id` (required), `page`, `per_page`, optional `type` (voice|video), `direction` (incoming|outgoing).
  - Response 200: `{ "success": true, "data": [ ...callLog ], "meta": { "current_page", "last_page", "per_page", "total" } }`.
  - CallLog: `id`, `user_id`, `other_user_id`, `type` ("voice"|"video"), `direction` ("incoming"|"outgoing"), `status` ("answered"|"missed"|"declined"), `duration`, `call_time` (ISO 8601), `other_user` (user object with `id`, `first_name`, `last_name`, `username`, `profile_photo_path`).

- **Expectations:**
  - Navigation: Home → Profile → ⋮ menu → Simu → CallHistoryScreen.
  - Screen shows All (Zote) and Missed (Zilizokosa) tabs; Dialer FAB opens a sheet to place a new call by user ID. Tapping a log entry opens options (voice/video call). All touch targets min 48dp per DESIGN.md.

---

## Story 57: Go Live

- **Endpoints:**
  - `POST /api/streams` – create a new stream (live or scheduled). Creator sets title, description, thumbnail, category, tags, privacy, options (record, allow comments, allow gifts), and optional `scheduled_at`.
  - `POST /api/streams/{id}/start` – transition a stream to live (start broadcasting). Called when the creator taps "Enda Live" from BackstageScreen; backend prepares ingest (e.g. RTMP URL/key) and returns updated stream with status `live`.

- **Request (POST /api/streams):**
  - `multipart/form-data`. Required: `user_id` (integer), `title` (string). Optional: `description` (string), `thumbnail` (image file), `category` (string), `tags[0]`, `tags[1]`, ... (array), `privacy` (`public` | `followers` | `private`), `is_recorded` (1/0), `allow_comments` (1/0), `allow_gifts` (1/0), `scheduled_at` (ISO 8601 string for scheduled streams).
  - Example: `user_id=1`, `title=Tangazo yangu`, `description=...`, `privacy=public`, `is_recorded=1`, `allow_comments=1`, `allow_gifts=1`.

- **Response (201 success for POST /api/streams):**
  - `{ "success": true, "data": { ... } }`. `data` is the created stream object: `id`, `user_id`, `title`, `description`, `thumbnail_path`, `category`, `tags`, `privacy`, `status` (e.g. `scheduled` or `pre_live`), `is_recorded`, `allow_comments`, `allow_gifts`, `scheduled_at`, `rtmp_url`/`stream_key` (if applicable), `user` (creator object), etc. Frontend uses this to navigate to BackstageScreen (go live now) or show scheduled confirmation.

- **Request (POST /api/streams/{id}/start):**
  - POST, no body (or empty JSON). Path parameter `{id}` is the stream ID. Auth: request must be authenticated; backend should verify the requester is the stream owner.

- **Response (200 success for POST /api/streams/{id}/start):**
  - `{ "success": true, "data": { ... } }`. `data` is the updated stream with `status: "live"`, and any ingest details (e.g. RTMP URL, stream key) needed by the app for RTMP/camera streaming. Frontend then opens LiveBroadcastScreenAdvanced and starts pushing video/audio to the given ingest URL.

- **Expectations:**
  - Go Live flow: User opens GoLiveScreen (lib/screens/clips/golive_screen.dart), fills title/thumbnail/options and either "Enda Live" (now) or "Panga" (schedule). On create success, frontend navigates to BackstageScreen (camera/mic checks, stream settings). When user taps "ENDA MOJA KWA MOJA" in backstage, frontend calls `POST /api/streams/{id}/start`; on success, navigates to LiveBroadcastScreenAdvanced for RTMP/camera streaming. StandbyScreen is used for viewers of scheduled streams (countdown until start). Navigation: Home → Profile → Live tab → Go Live, or Home → Feed → Live tab → Go Live.

---

## Story 79: Profile Live Gallery Tab

- **Endpoints:**
  - `GET /api/streams/user/{userId}` – list all streams (live, scheduled, ended) for a given user. Used by Profile → Tab [Live] → LiveGalleryWidget to show that profile’s live streams.

- **Request (GET /api/streams/user/{userId}):**
  - GET, no body. Path parameter `{userId}` is the integer ID of the profile user whose streams to list.

- **Response (200 success for GET /api/streams/user/{userId}):**
  - `{ "success": true, "data": [ ... ] }`. `data` is an array of stream objects. Same stream shape as Story 58/57: `id`, `user_id`, `title`, `description`, `thumbnail_path`, `category`, `tags`, `status` (`live`|`scheduled`|`ended`), `privacy`, `stream_url`, `playback_url`, `viewers_count`, `peak_viewers`, `total_viewers`, `likes_count`, `comments_count`, `gifts_count`, `gifts_value`, `is_recorded`, `recording_path`, `scheduled_at`, `started_at`, `ended_at`, `duration`, `created_at`, `user` (creator object). Frontend filters client-side into live now, scheduled, past, and recordings.

- **Expectations:**
  - LiveGalleryWidgetScreen (lib/screens/feed/livegallerywidget_screen.dart) shows LiveGalleryWidget with tabs: live now, scheduled, past/recordings. Navigation: Home → Profile → Tab [Live] → LiveGalleryWidget. On own profile: Go Live / Schedule buttons; stats (streams count, views, gifts, earnings); tap stream to watch or manage. On other profile: view that user’s streams only. Backend may return 404 or empty array if user has no streams.

---

## Story 62: Deposit/Withdraw (Mobile Money)

- **Endpoints:**
  - `POST /api/wallet/{userId}/deposit` – initiate deposit to wallet via mobile money.
  - `POST /api/wallet/{userId}/withdraw` – withdraw from wallet to mobile money.

- **Request (POST /api/wallet/{userId}/deposit):**
  - JSON body: `{ "amount": number, "provider": string, "phone_number": string, "pin"?: string }`.
  - Path: `{userId}` is the authenticated user's ID (integer).
  - **provider:** one of `mpesa`, `tigopesa`, `airtelmoney` (M-Pesa, Tigo Pesa, Airtel Money; integration via ClickPesa or equivalent).
  - **phone_number:** recipient mobile number (e.g. 0712345678 or E.164).
  - **amount:** in TZS; frontend enforces minimum (e.g. 1,000 TZS).
  - **pin:** optional for deposit (if required by provider).

- **Response (200 success):**
  - `{ "success": true, "data": { ...transaction } }`. Transaction object: `id`, `transaction_id`, `user_id`, `type` (e.g. `deposit`), `amount`, `fee`, `balance_before`, `balance_after`, `status` (e.g. `pending`, `completed`), `provider`, `payment_method`, `description`, `created_at`, `completed_at` (optional). Frontend shows confirmation and refreshes wallet/transactions.

- **Request (POST /api/wallet/{userId}/withdraw):**
  - JSON body: `{ "amount": number, "provider": string, "phone_number": string, "pin": string }`.
  - Path: `{userId}` is the authenticated user's ID (integer).
  - **provider:** one of `mpesa`, `tigopesa`, `airtelmoney`.
  - **phone_number:** destination mobile number.
  - **amount:** in TZS; frontend enforces minimum (e.g. 5,000 TZS) and balance check.
  - **pin:** required (wallet PIN for authorization).

- **Response (200 success):**
  - Same as deposit: `{ "success": true, "data": { ...transaction } }` with `type` e.g. `withdrawal`. On non-200 or `success: false`, frontend shows `message` to the user.

- **Expectations:**
  - Backend integrates with M-Pesa, Tigo Pesa, and Airtel Money (e.g. via ClickPesa or provider APIs) to initiate push (deposit) and pull (withdraw) flows. User receives provider USSD/push prompt to confirm; backend receives callback and updates transaction status and wallet balance.
  - Navigation: Home → Profile → Wallet (Tajiri Pay) → Deposit (Ingiza) or Withdraw (Toa). Deposit/Withdraw are presented as bottom sheets from WalletScreen (lib/screens/wallet/wallet_screen.dart). Touch targets and layout follow DOCS/DESIGN.md (min 48dp, monochrome palette).

---

## Story 61: Wallet Balance & Transactions

- **Endpoints:**
  - `GET /api/wallet/{userId}` – returns the authenticated user's wallet (balance, currency, pending, has_pin, etc.).
  - `GET /api/wallet/{userId}/transactions` – returns paginated transaction history for the wallet.

- **Request (GET /api/wallet/{userId}):**
  - GET, no body. Path parameter `{userId}` is the integer ID of the user whose wallet is requested. Backend should ensure the requester is the same user (or has permission).

- **Response (200 success for GET /api/wallet/{userId}):**
  - `{ "success": true, "data": { ... } }`. `data` is the wallet object: `balance` (number), `pending_balance` (number, optional, default 0), `currency` (string, e.g. "TZS"), `is_active` (boolean), `has_pin` (boolean). Frontend uses this to show balance on WalletScreen (Tajiri Pay), toggle visibility, and show "Weka PIN" hint when `has_pin` is false.

- **Request (GET /api/wallet/{userId}/transactions):**
  - GET, no body. Path parameter `{userId}`. Query parameters: `page` (integer, default 1), `per_page` (integer, default 20), optional `type` (e.g. deposit, withdrawal, transfer_in, transfer_out), optional `status` (e.g. pending, completed).

- **Response (200 success for GET /api/wallet/{userId}/transactions):**
  - `{ "success": true, "data": [ ... ], "meta": { "current_page", "last_page", "per_page", "total" } }`. Each transaction in `data`: `id`, `transaction_id`, `user_id`, `type`, `amount`, `fee`, `balance_before`, `balance_after`, `status`, `payment_method`, `provider`, `description`, `created_at`, `completed_at`. Frontend shows recent transactions on WalletScreen and full list on TransactionHistoryScreen; uses `type` to show credit/debit and labels (Uingizaji, Uondoaji, Upokeaji, Ulipaji, etc.).

- **Expectations:**
  - Navigation: Home → Profile → ⋮ menu → Tajiri Pay → WalletScreen (lib/screens/wallet/wallet_screen.dart). Screen shows balance (with show/hide), pending balance if any, quick actions (Ingiza, Toa, Tuma, Omba), and recent transactions; pull-to-refresh reloads wallet and transactions. If GET wallet fails, screen shows error state with "Jaribu tena". Backend must enforce that the requesting user can only access their own wallet and transactions.

---

## Story 60: Group Call

- **Endpoints:**
  - `POST /api/calls/group` – start or join a group voice/video call for a conversation (group chat).
  - `POST /api/calls/group/leave` – leave the group call (optional; frontend may treat leave as client-only if no call_id).
  - `PATCH /api/calls/group/state` – update participant state (muted, video_enabled) in the call (optional).

- **Request (POST /api/calls/group):**
  - JSON body: `{ "conversation_id": int, "user_id": int }`.
  - Example: `POST /api/calls/group` with body `{ "conversation_id": 5, "user_id": 1 }`.

- **Response (200 or 201 success for POST /api/calls/group):**
  - `{ "success": true, "call_id": string (optional), "room_token": string (optional), "participants": [ ... ] }`.
  - `participants` is an array of objects: `user_id` (int), `display_name` (string, optional), `avatar_url` (string, optional), `is_muted` (boolean, optional), `video_enabled` (boolean, optional). Frontend uses this to show who is in the call; if empty, frontend builds participant list from the conversation.

- **Request (POST /api/calls/group/leave):**
  - JSON body: `{ "call_id": string, "user_id": int }`. Used when the user taps "Ondoka" (Leave).

- **Response (200 success for POST /api/calls/group/leave):**
  - `{ "success": true, "message": "optional" }`. Backend removes the user from the call and may notify other participants.

- **Request (PATCH /api/calls/group/state):**
  - JSON body: `{ "call_id": string, "user_id": int, "muted": boolean }` or `{ "call_id": string, "user_id": int, "video_enabled": boolean }`. Used when the user toggles mute or video.

- **Response (200 success for PATCH /api/calls/group/state):**
  - `{ "success": true }`. Backend updates participant state so other clients can reflect mute/video state.

- **Expectations:**
  - Navigation: Home → Messages → Group chat → Group call (videocam icon in ChatScreen when conversation is group). GroupCallScreen (lib/screens/messages/group_call_screen.dart) shows participant grid, mute button, video toggle, and leave button (min 48dp touch targets per DESIGN.md). Join on screen open via POST /api/calls/group; leave and mute/video updates are sent to backend when endpoints exist. If backend returns success without participants, frontend builds participant list from conversation participants.

---

## Story 63: P2P Transfer

- **Endpoints:**
  - `POST /api/wallet/{userId}/transfer` – transfer money from the authenticated user's wallet to another user (P2P). Recipient is identified by user ID or phone number. Requires PIN verification.

- **Request (POST /api/wallet/{userId}/transfer):**
  - JSON body: `{ "amount": number, "pin": string, "description": string (optional), "recipient_id": int (optional), "recipient_phone": string (optional) }`.
  - Path: `{userId}` is the sender's user ID (integer). Backend must ensure the requester is the same user.
  - **Exactly one of** `recipient_id` or `recipient_phone` is required. `recipient_id` is the recipient's user ID; `recipient_phone` is the recipient's registered phone number (e.g. 07XXXXXXXX). Backend resolves phone to user and wallet when `recipient_phone` is sent.
  - **amount:** in TZS; frontend enforces minimum 100 TZS and balance check (including fee).
  - **pin:** required; 4-digit wallet PIN for verification. Backend must validate PIN before debiting.
  - **description:** optional note for the transaction.

- **Response (200 success):**
  - `{ "success": true, "data": { ...transaction } }`. Transaction object: `id`, `transaction_id`, `user_id`, `type` (e.g. `transfer_out`), `amount`, `fee`, `balance_before`, `balance_after`, `status` (e.g. `completed`), `description`, `created_at`, `completed_at` (optional). Recipient's wallet is credited with a corresponding `transfer_in` transaction.

- **Response (4xx/5xx or success: false):**
  - `{ "success": false, "message": string }`. Examples: invalid PIN, insufficient balance, recipient not found (invalid ID or phone), same user as recipient.

- **Expectations:**
  - Navigation: Home → Profile → ⋮ menu → Tajiri Pay (Wallet) → Transfer (Tuma). Transfer is opened as a bottom sheet from WalletScreen (lib/screens/wallet/wallet_screen.dart). User can choose recipient by User ID or by Phone; enters amount, optional description, and 4-digit PIN. Frontend shows fee (from GET calculate-fee) and blocks submit if balance (including fee) is insufficient. Backend must verify PIN, debit sender, credit recipient, and return the created transaction. Touch targets and layout follow DOCS/DESIGN.md (min 48dp, monochrome palette).

---

## Story 64: Creator Subscription Tiers

- **Endpoints:**
  - `POST /api/subscriptions/tiers` – create a subscription tier (creator).
  - `GET /api/subscriptions/tiers/{creatorId}` – list subscription tiers for a creator (pricing, benefits per tier).

- **Request (POST /api/subscriptions/tiers):**
  - JSON body: `{ "user_id": int, "name": string, "description": string (optional), "price": number, "billing_period": "monthly" | "yearly", "benefits": [ string ] (optional) }`.
  - **user_id:** creator's user ID (integer). Backend must ensure the requester is the same user.
  - **name:** tier name (e.g. "Mwanachama wa Kawaida").
  - **description:** optional tier description.
  - **price:** price in TZS (number); frontend validates non-negative.
  - **billing_period:** `monthly` (kwa mwezi) or `yearly` (kwa mwaka).
  - **benefits:** optional array of strings describing tier benefits.

- **Response (201 success for POST /api/subscriptions/tiers):**
  - `{ "success": true, "data": { ...tier } }`. Tier object: `id`, `creator_id`, `name`, `description`, `price`, `billing_period`, `benefits` (array of strings), `is_active` (boolean, default true), `subscriber_count` (optional, default 0).

- **Request (GET /api/subscriptions/tiers/{creatorId}):**
  - GET, no body. Path parameter `{creatorId}` is the creator's user ID (integer).

- **Response (200 success for GET /api/subscriptions/tiers/{creatorId}):**
  - `{ "success": true, "data": [ ...tier ] }`. `data` is an array of tier objects, each with: `id`, `creator_id`, `name`, `description`, `price`, `billing_period`, `benefits`, `is_active`, `subscriber_count`. Frontend uses this on SubscriptionTiersSetupScreen to list, edit, and delete tiers.

- **Expectations:**
  - Navigation: Creator profile → Tajiri Pay (Wallet) → Viwango vya Usajili (Subscription tiers setup), or Wallet → Settings → Viwango vya Usajili. Screen (lib/screens/wallet/subscription_tiers_setup_screen.dart) lists tiers with name, price, period, benefits preview, subscriber count; creator can add tier (name, description, price, billing period, benefits), edit, and delete. Touch targets and layout follow DOCS/DESIGN.md (min 48dp, monochrome palette). Backend should support update (PUT /api/subscriptions/tiers/{tierId}) and delete (DELETE /api/subscriptions/tiers/{tierId}) for full CRUD; frontend uses these for edit and delete.

---

## Story 65: Subscribe to Creator

- **Endpoints:**
  - `POST /api/subscriptions` (or `POST /api/subscriptions/subscribe`) – create a subscription to a creator (payment from wallet).
  - `GET /api/subscriptions/tiers/{creatorId}` – list subscription tiers for the creator (see Story 64).
  - `GET /api/subscriptions/check/{creatorId}?user_id={userId}` – check if the user is already subscribed to the creator.

- **Request (POST /api/subscriptions or POST /api/subscriptions/subscribe):**
  - JSON body: `{ "user_id": int, "tier_id": int, "payment_method": "wallet", "pin": string }`.
  - **user_id:** subscriber's user ID (integer). Backend must ensure the requester is the same user.
  - **tier_id:** ID of the subscription tier to subscribe to (integer).
  - **payment_method:** `wallet` for payment from Tajiri Pay wallet. Backend debits the subscriber's wallet and credits the creator (or subscription ledger).
  - **pin:** 4-digit wallet PIN for verification. Backend must validate PIN and sufficient wallet balance before creating the subscription.

- **Response (201 success):**
  - `{ "success": true, "data": { ...subscription } }`. Subscription object: `id`, `subscriber_id`, `creator_id`, `tier_id`, `status` (e.g. `active`), `amount_paid`, `started_at`, `expires_at`, `auto_renew`, optional nested `tier`, `creator`, `subscriber` for display.

- **Response (4xx/5xx or success: false):**
  - `{ "success": false, "message": string }`. Examples: invalid PIN, insufficient wallet balance, tier not found or inactive, already subscribed.

- **Request (GET /api/subscriptions/check/{creatorId}):**
  - GET, no body. Query param `user_id` is the current user's ID. Path `{creatorId}` is the creator's user ID.

- **Response (200 for GET check):**
  - `{ "success": true, "data": { "is_subscribed": boolean } }`. Frontend uses this to show "Already subscribed" or the tier list with pay-from-wallet flow.

- **Expectations:**
  - Navigation: Creator profile → Subscribe button (Jisajili) → SubscribeToCreatorScreen (lib/screens/wallet/subscribe_to_creator_screen.dart). User sees creator's active tiers; selects a tier and pays from wallet (PIN required). On success, user gets access to exclusive content. Payment is debited from the user's wallet (Tajiri Pay). Touch targets and layout follow DOCS/DESIGN.md (min 48dp, monochrome palette).

---

## Story 67: User Search

- **Endpoints:**
  - `GET /api/users/search` – search users by name or username.

- **Request:**
  - GET, no body. Query parameters:
    - `q` (string, required): search query (name or username).
    - `page` (int, optional): page number for pagination (default 1).
    - `per_page` (int, optional): results per page (default 20).

- **Response (200 success):**
  - `{ "success": true, "data": [ ...users ], "meta": { ... } }`.
  - Each user in `data`: same shape as user/profile (e.g. `id`, `first_name`, `last_name`, `username`, `profile_photo_path`, `bio`, `region_name`, `district_name`, `friends_count`, `posts_count`, `photos_count`, `last_active_at`, `mutual_friends_count`, etc.). Frontend uses `UserProfile.fromJson()` (lib/models/friend_models.dart).
  - `meta` (optional): pagination (e.g. `current_page`, `total`, `per_page`, `has_more`).

- **Expectations:**
  - Backend searches by **name** (e.g. first_name, last_name, full name) and **username** (handle). Partial/fuzzy match is acceptable.
  - Navigation: Home → Search (global) → Users tab (lib/screens/search/search_screen.dart, lib/screens/search/user_search_tab.dart). User types in search field; results listed with avatar, full name, username; tap opens profile. Touch targets and layout follow DOCS/DESIGN.md (min 48dp, monochrome palette).

---

## Story 68: Hashtag Search

- **Endpoints:**
  - `GET /api/hashtags/trending` – list trending hashtags for discovery.
  - `GET /api/hashtags/search` – search hashtags by query.
  - `GET /api/posts/hashtag/{tag}` – list posts that use the given hashtag (paginated).

- **Request (GET /api/hashtags/trending):**
  - GET, no body. Optional query: `limit` (int, default 20) – max number of hashtags to return.

- **Response (200 success):**
  - `{ "success": true, "data": [ ...hashtags ] }`.
  - Each hashtag in `data`: `{ "id": int, "name": string, "posts_count": int, "usage_count_24h": int?, "usage_count_7d": int?, "is_trending": bool?, "created_at": string? }`. Frontend uses `Hashtag.fromJson()` (lib/models/post_models.dart). `name` is the tag without the `#` prefix.

- **Request (GET /api/hashtags/search):**
  - GET, no body. Query parameters:
    - `q` (string, required): search query (e.g. partial tag name).
    - `limit` (int, optional): max results (default 20).

- **Response (200 success):**
  - Same shape as trending: `{ "success": true, "data": [ ...hashtags ] }` with same hashtag object shape.

- **Request (GET /api/posts/hashtag/{tag}):**
  - GET, no body. Path `{tag}` is the hashtag name (without `#`). Query: `page` (int), `per_page` (int), optional `current_user_id` (int) for like state.

- **Response (200 success):**
  - `{ "success": true, "data": [ ...posts ], "meta": { "current_page", "total", "per_page", "has_more" } }`. Each post in `data` has the same shape as feed/post detail (Post.fromJson). Frontend uses PostService.searchByHashtag() and displays posts in HashtagScreen (lib/screens/search/hashtag_screen.dart).

- **Expectations:**
  - Navigation: Home → Search → Hashtags tab (trending list + search field); or tap #hashtag in a post (PostCard.onHashtagTap) → HashtagScreen. Trending and search power the Hashtags tab; posts by hashtag power the HashtagScreen. Touch targets and layout follow DOCS/DESIGN.md (min 48dp, monochrome palette).

---

## Story 66: Send Tip

- **Endpoints:**
  - `POST /api/subscriptions/tips` – send a tip from the current user to a creator.

- **Request (POST /api/subscriptions/tips):**
  - JSON body (Content-Type: application/json). Required: `user_id` (integer, tipper), `creator_id` (integer, recipient), `amount` (number, tip amount in TZS), `payment_method` (string, e.g. `wallet`). Optional: `message` (string, message with the tip). For wallet payments, backend may expect `pin` (string, 4-digit wallet PIN) and optionally `phone_number`, `provider` for other methods.
  - Example: `{ "user_id": 1, "creator_id": 2, "amount": 1000, "payment_method": "wallet", "message": "Asante kwa maudhui!" }` with PIN provided as needed by backend.

- **Response (201 success):**
  - `{ "success": true, "message": "optional success message" }`. Frontend shows success snackbar (e.g. "Tuzo imetumwa!").

- **Response (4xx/5xx or success: false):**
  - `{ "success": false, "message": string }`. Examples: insufficient wallet balance, invalid PIN, creator not found.

- **Expectations:**
  - Navigation: Live stream (StreamViewerScreen) or Creator profile (ProfileScreen) → Tip button → SendTipScreen (lib/screens/wallet/send_tip_screen.dart). User selects amount (presets or custom), optionally enters a message, and pays from wallet (PIN required). Backend debits tipper's wallet and credits the creator. Optional message is sent with the tip.

---

## Story 72: Resumable Chunked Uploads

- **Endpoints:**
  - `POST /api/uploads/init` – initialize a resumable upload session (video/clip or other large file).
  - `POST /api/uploads/{id}/chunk` – upload a single chunk for the given upload id.
  - `POST /api/uploads/{id}/complete` – finalize the upload after all chunks are received.
  - Optional (for resume): `GET /api/uploads/{id}/status` – return upload progress (uploaded_chunks, missing_chunks, etc.). Optional: `GET /api/uploads/resumable?user_id=...` – list in-progress uploads for the user. Optional: `POST /api/uploads/{id}/cancel` – cancel and clean up an upload.

- **Request (POST /api/uploads/init):**
  - JSON body. Required: `user_id` (int), `filename` (string), `file_size` (int bytes), `mime_type` (string, e.g. `video/mp4`), `chunk_size` (int bytes, e.g. 5242880 for 5MB). For clip uploads, optional: `caption`, `hashtags` (array of strings), `mentions` (array of int user ids), `location_name`, `latitude`, `longitude`, `privacy` (e.g. `public`), `allow_comments`, `allow_duet`, `allow_stitch`, `allow_download`, `original_clip_id`, `clip_type`, `music_id`, `music_start`.
  - Example: `{ "user_id": 1, "filename": "video.mp4", "file_size": 15728640, "mime_type": "video/mp4", "chunk_size": 5242880, "caption": "Hello", "privacy": "public" }`.

- **Response (200/201 success for init):**
  - `{ "success": true, "data": { "upload_id": "<string>", "total_chunks": <int>, "chunk_size": <int>, "status": "pending" } }`. Frontend uses `upload_id` for subsequent chunk and complete requests.

- **Request (POST /api/uploads/{id}/chunk):**
  - Multipart form. Required: `chunk_number` (int, 0-based index), `chunk` (binary file part, Content-Type application/octet-stream). Backend stores the chunk and returns success so the client can send the next chunk or call complete.

- **Response (200 success for chunk):**
  - `{ "success": true }` (optional `data`). Frontend retries on failure (with backoff) and resumes from missing chunks using status.

- **Request (POST /api/uploads/{id}/complete):**
  - No body or empty JSON. Backend assembles chunks, creates the final resource (e.g. clip), and returns it.

- **Response (200/201 success for complete):**
  - For clip: `{ "success": true, "data": { ...clip object... } }` where `data` is the created clip (Clip.fromJson). Frontend expects the same clip shape as other clip APIs.

- **Response (GET /api/uploads/{id}/status):**
  - `{ "success": true, "data": { "upload_id": "<string>", "total_chunks": <int>, "chunk_size": <int>, "uploaded_chunks": <int>, "uploaded_bytes": <int>, "missing_chunks": [<int>, ...], "status": "pending"|"processing" } }`. Frontend uses `missing_chunks` to resume.

- **Expectations:**
  - Resumable upload is embedded in Create Clip (UploadVideoScreen), and can be used for Upload Music and Video post flows when backend supports the same or extended init/complete contract (e.g. upload_type or target). Chunk size is typically 5MB; backend must accept chunks in any order or in order and idempotently store by chunk_number. On complete, backend validates all chunks present and then assembles and persists the file. Frontend uses ResumableUploadService (lib/services/resumable_upload_service.dart) for init → chunk(s) → complete, with pause/resume and local state persistence.

---

## Story 70: Privacy Settings

- **Endpoints:**
  - `GET /api/users/{userId}/privacy-settings` – get current user's privacy settings.
  - `PUT /api/users/{userId}/privacy-settings` – update privacy settings (body: JSON object below).

- **Request (GET):**
  - No body. Path parameter `userId` is the authenticated user's ID (or current user).

- **Response (GET 200 success):**
  - `{ "success": true, "data": { "profile_visibility": string, "who_can_message": string, "who_can_see_posts": string, "last_seen_visibility": string } }`.
  - All four fields are strings. Allowed values:
    - `profile_visibility`: `everyone` | `friends` | `only_me`
    - `who_can_message`: `everyone` | `friends` | `nobody`
    - `who_can_see_posts`: `everyone` | `friends` | `only_me`
    - `last_seen_visibility`: `everyone` | `friends` | `nobody`
  - Defaults if not set: all `everyone`.

- **Request (PUT):**
  - JSON body: `{ "profile_visibility": string, "who_can_message": string, "who_can_see_posts": string, "last_seen_visibility": string }` with the same allowed values as above.

- **Response (PUT 200 success):**
  - `{ "success": true, "message": "optional", "data": { ... same shape as GET ... } }`. Frontend may use `data` to update local state.

- **Response (4xx/5xx or success: false):**
  - `{ "success": false, "message": string }`. Frontend shows error snackbar.

- **Expectations:**
  - Navigation: Home → Profile → Settings → Faragha (Privacy) → PrivacySettingsScreen (lib/screens/settings/privacy_settings_screen.dart). User can set: who can see profile, who can message, who can see posts, last seen visibility. Backend must persist and enforce these settings (e.g. when resolving profile visibility, messageability, post visibility, and "last seen" in chat).

---

## Story 77: Profile Video Gallery Tab

- **Endpoints:**
  - `GET /api/clips/user/{userId}` – list clips/videos for a user's profile video gallery.

- **Request (GET /api/clips/user/{userId}):**
  - GET, no body. Path parameter `userId` is the profile owner's user ID.

- **Response (200 success):**
  - `{ "success": true, "data": [ ... ] }`. `data` is an array of clip objects. Each clip must include at least: `id`, `user_id`, `video_url`, `thumbnail_url`, `caption` (optional), `duration` (seconds), `views_count`, `likes_count`, `comments_count`, `is_liked` (boolean for current user), `is_saved` (boolean for current user), `user` (optional: `id`, `full_name`, `display_name`, `avatar_url`), `music` (optional), `created_at`.

- **Expectations:**
  - Navigation: Home → Profile → Tab [Video] → VideoGalleryWidgetScreen (lib/screens/feed/videogallerywidget_screen.dart). The screen shows VideoGalleryWidget: grid of thumbnails, view count and duration overlay, tap to play fullscreen. Own profile shows upload/search; other profiles show "Add to my videos". Pagination or "load more" may use the same endpoint with `page`/`per_page` if supported; frontend currently uses a single page of results and loads more via the same endpoint. Backend returns clips owned by or associated with the given user for the profile video tab.

---

## Story 74: Registration Phone Step (Thibitisha Simu)

- **Endpoints:**
  - `POST /api/users/check-phone` — validate phone number before sending OTP (see Story 2 for request/response format).

- **Request (POST /api/users/check-phone):**
  - JSON body: `{ "phone_number": "<E.164 string, e.g. +255712345678>" }`.

- **Response (200):**
  - `{ "available": true, "message": "optional" }` when number is not registered; frontend then proceeds to OTP flow.
  - `{ "available": false, "message": "optional" }` or `{ "exists": true }` when number is already registered; frontend shows error (e.g. "Nambari hii ya simu imeshasajiliwa") and does not send OTP.

- **Expectations:**
  - Navigation: Splash → Login → RegistrationScreen → PhoneStep (Step 1). Screen: lib/screens/registration/phonestep_screen.dart; widget: lib/screens/registration/steps/phone_step.dart. Step label: "Thibitisha Simu" (Swahili). User enters phone, frontend calls check-phone; if available, OTP is sent (currently simulated client-side with test code 111111). Backend may later provide OTP send/verify endpoints; until then, frontend simulates OTP and sets `is_phone_verified` and `phone_number` on RegistrationState for the final register payload.

---

## Story 80: Create Campaign (Michango)

- **Endpoints:**
  - `POST /api/campaigns` – create a new fundraising campaign (draft). Used by ContributionService.createCampaign.

- **Request (POST /api/campaigns):**
  - Content-Type: `multipart/form-data`.
  - Required fields: `user_id` (int, string), `title` (string), `story` (string), `goal_amount` (number string), `category` (string: one of medical, education, emergency, funeral, wedding, business, community, religious, sports, arts, environment, other).
  - Optional fields: `short_description` (string), `deadline` (ISO 8601), `allow_anonymous_donations` (bool string), `minimum_donation` (number string, default 1000), `is_urgent` (bool string), `bank_name` (string), `account_number` (string), `mobile_money_number` (string).
  - Optional file: `cover_image` (image file). Optional files: `media[i]` for additional media.

- **Response (201 success):**
  - `{ "success": true, "data": <campaign object> }`. Campaign object must include at least: `id`, `user_id`, `title`, `story`, `short_description`, `goal_amount`, `raised_amount`, `currency`, `status` (e.g. "draft"), `category`, `is_verified`, `deadline`, `cover_image_url`, `media_urls`, `donors_count`, `shares_count`, `views_count`, `created_at`, `updated_at`, `allow_anonymous_donations`, `minimum_donation`, `is_urgent`, `bank_name`, `account_number`, `mobile_money_number`. See lib/models/contribution_models.dart for full Campaign.fromJson shape.

- **Expectations:**
  - Navigation: Home → Profile → Tab [Michango] → Create campaign → CreateCampaignScreen (lib/screens/campaigns/create_campaign_screen.dart). User submits title, story, goal amount, category, optional cover image, and at least one of bank (bank_name + account_number) or mobile_money_number for receiving contributions. Frontend validates required fields and minimum goal 1000 TSh; backend should validate and persist campaign as draft. On success, frontend pops with result true so Michango gallery can refresh.

---

## Story 81: View & Manage Campaigns (Michango)

- **Endpoints:**
  - `GET /api/users/{userId}/campaigns` – list campaigns for a user (organizer view). Optional query: `status` (e.g. active, completed, draft).
  - `GET /api/users/{userId}/campaigns/stats` – get aggregate stats for the user's campaigns (total campaigns, total donors, total raised, available balance).
  - `GET /api/campaigns/{campaignId}` – get single campaign details (used when opening campaign detail).
  - `POST /api/campaigns/{campaignId}/publish` – publish a draft campaign (activate).
  - `POST /api/campaigns/{campaignId}/pause` – pause an active campaign.
  - `POST /api/campaigns/{campaignId}/resume` – resume a paused campaign.
  - `POST /api/campaigns/{campaignId}/complete` – mark campaign as completed (stop accepting donations).
  - `DELETE /api/campaigns/{campaignId}` – delete a draft campaign.

- **Request/response:**
  - **GET users/{userId}/campaigns:** No body. Response 200: `{ "success": true, "data": [ <campaign objects> ] }`. Each campaign object shape as in Story 80; frontend filters by `status` for Active / Completed / Draft tabs.
  - **GET users/{userId}/campaigns/stats:** No body. Response 200: `{ "success": true, "data": { "total_campaigns": int, "total_donors": int, "total_raised": number, "available_balance": number } }`.
  - **GET campaigns/{campaignId}:** No body. Response 200: `{ "success": true, "data": <campaign object> }`.
  - **POST publish/pause/resume/complete:** No body. Response 200: `{ "success": true, "data": <campaign object> }` or `{ "success": false, "message": string }`.
  - **DELETE campaigns/{campaignId}:** No body. Response 200: `{ "success": true, "message": "optional" }` or `{ "success": false, "message": string }`.

- **Expectations:**
  - Navigation: Home → Profile → Tab [Michango] → MichangoGalleryWidgetScreen (lib/screens/michangogallerywidget_screen.dart), which shows MichangoGalleryWidget with tabs Active, Completed, Draft; stats summary (own profile); and per-campaign actions: edit, pause, publish (draft), resume (paused), complete, delete (draft). Backend must enforce that only the campaign organizer can call publish/pause/resume/complete/delete for their campaigns. Frontend uses ContributionService (lib/services/contribution_service.dart) and Campaign/CampaignStats from lib/models/contribution_models.dart.

---

## Story 82: Donate to Campaign

- **Endpoints:**
  - `POST /api/campaigns/{id}/donate` – donate to a campaign (wallet or mobile money).

- **Request (POST /api/campaigns/{id}/donate):**
  - Content-Type: `application/json`.
  - Body: `{ "amount": number, "payment_method": "wallet" | "mobile_money", "is_anonymous": boolean, "message"?: string, "pin"?: string }`.
  - `amount`: required; must be >= campaign's `minimum_donation`.
  - `payment_method`: required; `"wallet"` deducts from donor's Tajiri wallet; `"mobile_money"` triggers mobile money flow (e.g. M-Pesa, Tigo Pesa, Airtel Money) as per backend integration.
  - `is_anonymous`: optional, default false; when true, donor name is not shown publicly.
  - `message`: optional; short message from donor to the campaign.
  - `pin`: required when `payment_method` is `"wallet"`; 4-digit wallet PIN for authorization.

- **Response (200 or 201 success):**
  - `{ "success": true, "data": <donation object>, "message"?: string }`.
  - Donation object must include at least: `id`, `campaign_id`, `donor_id` (or null if anonymous), `amount`, `currency`, `is_anonymous`, `message`, `donor_name` (or null), `donor_avatar_url` (or null), `payment_ref`, `status`, `created_at`. See lib/models/contribution_models.dart Donation.fromJson.

- **Response (4xx/5xx or success: false):**
  - `{ "success": false, "message": string }` (e.g. insufficient balance, invalid PIN, campaign not active, amount below minimum).

- **Expectations:**
  - Navigation: Campaign detail (from Profile → Tab Michango → tap campaign) → Donate button → DonateToCampaignScreen (lib/screens/campaigns/donate_to_campaign_screen.dart). User chooses amount (preset or custom), payment method (wallet or mobile money), optional message, and optional anonymous; for wallet, user enters PIN to confirm. Frontend calls ContributionService.donateToCampaign. Backend must: (1) accept only donations for active campaigns; (2) enforce minimum_donation; (3) for wallet, verify donor's PIN and deduct from donor wallet, credit campaign; (4) for mobile_money, initiate external payment flow and record donation on success (or return instructions/link for frontend to show).

---

## Story 83: Campaign Withdrawals

- **Endpoints:**
  - `GET /api/campaigns/{campaignId}/withdrawals` – list withdrawals for a campaign (organizer view).
  - `POST /api/campaigns/{campaignId}/withdrawals` – request a withdrawal (bank or mobile money).
  - `GET /api/users/{userId}/withdrawals` – list all withdrawals for a user (across campaigns).

- **Request (GET /api/campaigns/{campaignId}/withdrawals):**
  - GET, no body. Path parameter `campaignId` is the campaign ID.

- **Response (200 success):**
  - `{ "success": true, "data": [ <withdrawal objects> ] }`. Each withdrawal object must include: `id`, `campaign_id`, `amount`, `currency`, `status` (e.g. "pending", "approved", "processing", "completed", "rejected", "failed"), `destination_type` ("bank" or "mobile_money"), `destination_details` (string: for bank may be "BankName|AccountNumber", for mobile_money the phone number), `rejection_reason` (optional), `created_at`, `processed_at` (optional). See lib/models/contribution_models.dart Withdrawal.fromJson.

- **Request (POST /api/campaigns/{campaignId}/withdrawals):**
  - Content-Type: `application/json`.
  - Body: `{ "amount": number, "destination_type": "bank" | "mobile_money", "destination_details": string }`.
  - `amount`: required; must be > 0 and not exceed campaign’s available (withdrawable) balance. Backend should compute available as raised amount minus completed (and optionally pending/processing) withdrawals.
  - `destination_type`: required; `"bank"` or `"mobile_money"`.
  - `destination_details`: required; for bank a single string (e.g. "BankName|AccountNumber" or backend-defined format); for mobile_money the recipient phone number (e.g. E.164).

- **Response (201 success):**
  - `{ "success": true, "data": <withdrawal object> }`. Same withdrawal shape as above; status typically "pending".

- **Response (4xx/5xx or success: false):**
  - `{ "success": false, "message": string }` (e.g. KYC not verified, amount exceeds available balance, invalid destination, not organizer).

- **Request (GET /api/users/{userId}/withdrawals):**
  - GET, no body. Path parameter `userId` is the organizer’s user ID.

- **Response (200 success):**
  - `{ "success": true, "data": [ <withdrawal objects> ] }`. Same withdrawal shape as above.

- **Expectations:**
  - **KYC verification:** Withdrawals must be allowed only when the campaign organizer’s KYC status is verified. Backend must reject POST withdrawal if organizer KYC is not verified; frontend shows organizer’s `kyc_status` from campaign’s `organizer` (CampaignUser) and blocks submit when not verified. Campaign object from GET /api/campaigns/{id} (and list) should include `organizer` with `kyc_status` ("not_started", "pending", "verified", "rejected").
  - Navigation: Profile → Michango → [Toa button] → CampaignWithdrawScreen (pick campaign then withdraw), or Profile → Michango → Campaign detail → Omba Kutoa Fedha → CampaignWithdrawScreen (campaign pre-selected). Screen: lib/screens/campaigns/campaign_withdraw_screen.dart. User enters amount, chooses bank or mobile money, enters destination details; frontend calls ContributionService.requestWithdrawal and ContributionService.getCampaignWithdrawals. Backend must: (1) ensure only the campaign organizer can request withdrawals; (2) enforce KYC verified; (3) enforce amount <= available balance; (4) record withdrawal request and return it with status "pending" (or trigger payout flow and return appropriate status).

---

## Story 84: Livestream Battle Mode (PK Battle)

- **Communication:** WebSocket (same connection as livestream: stream room). Client connects via `connectToStream(streamId, userId)`; battle events are pushed on that socket.

- **Outgoing WebSocket messages (client → server):**
  - `invite_battle`: `{ "opponent_stream_id": int }` – streamer invites another live stream to a PK battle.
  - `accept_battle`: `{ "battle_id": int }` – streamer accepts an incoming battle invite.
  - `decline_battle`: `{ "battle_id": int }` – streamer declines an invite.
  - `forfeit_battle`: `{ "battle_id": int }` – streamer forfeits the current battle.

- **Incoming WebSocket events (server → client):**
  - `battle_invite`: `{ "battle_id": int, "opponent_id": int, "opponent_name": string }` – received by the invited streamer when another streamer sends an invite.
  - `battle_accepted`: `{ "battle_id": int, "opponent_id": int, "opponent_name": string }` – received by both sides when invite is accepted; battle starts.
  - `battle_score_update`: `{ "battle_id": int, "my_score": int, "opponent_score": int }` – real-time scores; **gift-based scoring**: backend should add gift value (e.g. virtual gift price × quantity) to the streamer’s battle score and broadcast this event to both streams.
  - `battle_ended`: `{ "battle_id": int, "winner_id": int?, "my_score": int, "opponent_score": int }` – battle finished (time up or forfeit); `winner_id` is the winning streamer’s user ID, or null for tie.

- **Expectations:**
  - Navigation: StreamViewerScreen → PK Battle mode (when active). Screen: lib/screens/clips/battlemodeoverlay_screen.dart; overlay: lib/widgets/battle_mode_overlay.dart; service: lib/services/battle_mode_service.dart.
  - Backend must: (1) allow only the streamer of a live stream to invite/accept/decline/forfeit; (2) associate battle scores with gift sends during the battle (gift value contributes to that stream’s battle score); (3) broadcast `battle_score_update` to both stream rooms when scores change; (4) determine battle end (e.g. fixed duration or manual end) and send `battle_ended` with final scores and `winner_id`; (5) deliver `battle_invite` only to the invited stream’s room (so the invited streamer’s client receives it).

---


## Story 85: Schedule Post for Later

- **Endpoints:** Same as drafts and post creation; no new endpoints. Scheduling uses existing:
  - `POST /api/drafts` – save draft with optional `scheduled_at` (ISO 8601 string).
  - `POST /api/drafts/{draftId}/publish` – publish a draft; when the draft has `scheduled_at`, backend should treat it as a scheduled post (create post with `scheduled_at` and process at that time, or store as scheduled and publish later via cron/job).

- **Request/response:**
  - **Save draft with schedule:** `POST /api/drafts` with `scheduled_at` in form/body (ISO 8601, e.g. `2025-02-15T09:00:00.000Z`). Other fields as per existing draft API (post_type, content, privacy, etc.). Response: `{ "success": true, "data": <draft object> }`; draft object must include `scheduled_at` when set.
  - **Publish scheduled draft:** `POST /api/drafts/{draftId}/publish`. If the draft has `scheduled_at`, backend should either: (a) create the post with `scheduled_at` and ensure it is published at that time (e.g. background job), or (b) return success and document that scheduled publishing is handled server-side.

- **Expectations:**
  - Navigation: Home → Feed → Create Post → (Text/Photo/Audio/Short Video) → Schedule toggle → Date/time (inline SchedulePostWidget or full-screen SchedulePostWidgetScreen). Screen: lib/screens/feed/schedulepostwidget_screen.dart; widget: lib/widgets/schedule_post_widget.dart. User selects date/time; post is saved with `scheduled_at` and published as scheduled. Backend must accept and persist `scheduled_at` on drafts and ensure scheduled posts are published at the given time (or return scheduled post in feed with `scheduled_at` for client display).

---

## Story 88: Feed Live Tab

- **Endpoints:** Same as Story 58 (Watch Live Stream). Feed Live tab uses:
  - `GET /api/streams?status=live&current_user_id={userId}` – list currently live streams for the grid.
  - `GET /api/streams?status=scheduled&current_user_id={userId}` – list upcoming/scheduled streams for the grid.

- **Request/response:** See Story 58. Same stream object shape; `data` is an array of stream objects with `id`, `title`, `thumbnail_path`, `viewers_count`, `user` (creator), `scheduled_at` (for scheduled), `status`, etc.

- **Expectations:**
  - Navigation: Home → Feed → Tab [Live] → LiveStreamsGridScreen (lib/screens/feed/livestreamsgrid_screen.dart), which shows LiveStreamsGrid (lib/widgets/live_streams_grid.dart). User sees live streams and upcoming streams; tap a live stream to watch (StreamViewerScreen); "Enda Live" opens GoLiveScreen (Story 57). Backend must return streams filtered by `status=live` and `status=scheduled` for the feed discovery experience. Optional: WebSocket for real-time viewer count and stream status updates (same as Story 58).

---

## Story 89: Streams Screen

- **Endpoints:** Same as Story 58 and 88. StreamsScreen (lib/screens/clips/streams_screen.dart) uses:
  - `GET /api/streams?status=live&current_user_id={userId}` – list currently live streams for the "Moja kwa Moja" tab.
  - `GET /api/streams?current_user_id={userId}` – list all streams (live, scheduled, ended) for the "Yote" tab.

- **Request/response:** See Story 58. Same stream object shape; `data` is an array of stream objects.

- **Expectations:**
  - Navigation: Home → Feed → Live tab → StreamsScreen (browse live streams with Live/All tabs and Go Live FAB); or Profile → Live → "Tazama yote" (Browse) → StreamsScreen. Screen shows two tabs: "Moja kwa Moja" (live only) and "Yote" (all streams). Tap stream to watch (StreamViewerScreen); FAB "Enda Moja kwa Moja" opens GoLiveScreen (Story 57). Backend returns streams as documented in Story 58.

---

## Story 86: @Mentions and #Hashtags in Posts

- **Endpoints (used by MentionTextField for suggestions):**
  - `GET /api/friends?user_id={id}&page=1&per_page=10` – list current user's friends. Used when user types `@` with no query to show **friend suggestions**. Response: `{ "success": true, "data": [ ...users ], "meta": { ... } }`. Each user object must include `id`, `first_name`, `last_name`, `username`, `profile_photo_path` (or `profile_photo_url`) so the frontend can display avatar and insert `@username`. See Story 36.
  - `GET /api/users/search?q={query}&page=1&per_page=5` – search users by name/username. Used when user types `@` followed by text to show **user search results**. Response: same as above. See Story 67.
  - `GET /api/hashtags/trending?limit=8` – list trending hashtags. Used when user types `#` with no query to show **hashtag suggestions**. Response: `{ "success": true, "data": [ { "id", "name", "posts_count", ... } ] }`. See Story 68.
  - `GET /api/hashtags/search?q={query}&limit=8` – search hashtags. Used when user types `#` followed by text to show **hashtag search results**. Response: same shape as trending. See Story 68.

- **Post create payload (optional):**
  - When creating a post (text, photo, audio, short video), the `content` field may contain plain text with `@username` and `#tag` substrings. Backend may parse these from `content` for linking and notifications, or accept optional body fields: `mentions` (array of user IDs) and `hashtags` (array of strings) if the API supports structured mention/hashtag metadata.

- **Expectations:**
  - Navigation: Create Post (any type) → text/caption field. User types `@` to get friend suggestions (from GET /api/friends when empty) or user search (GET /api/users/search when typing). User types `#` to get hashtag suggestions (GET /api/hashtags/trending when empty, GET /api/hashtags/search when typing). Screen: lib/screens/feed/mentiontextfield_screen.dart; widget: lib/widgets/mention_text_field.dart. Used in CreateTextPostScreen, CreateImagePostScreen, CreateAudioPostScreen, CreateShortVideoScreen. Backend must support GET /api/friends and GET /api/users/search for @ suggestions, and GET /api/hashtags/trending and GET /api/hashtags/search for # suggestions, as documented in Stories 36, 67, and 68.

---

## Story 93: Clip Video Search

- **Endpoints:**
  - `GET /api/clips/search?q={query}&type={type}&page={page}&per_page={per_page}&current_user_id={userId}` – search clips by query. `type`: `all`, `clips`, `users`, `hashtags`. Response: `{ "success": true, "data": [ ...clip objects ], "users": [ ...user objects ], "hashtags": [ ...hashtag objects ], "meta": { "current_page", "last_page", "total", "per_page" } }`. Clip shape as in existing clips API (id, user_id, video_path, thumbnail_path, caption, duration, views_count, user, etc.). User objects: id, first_name, last_name, username, profile_photo_path. Hashtag objects: id, tag, clips_count, views_count, is_trending.
  - `GET /api/clips/search/suggestions?q={query}` – search suggestions (typeahead). Response: `{ "success": true, "data": [ { "text", "type": "query"|"user"|"hashtag"|"sound", "id", "image_url", "count" } ] }`.
  - `GET /api/users/{userId}/recent-searches?type=clips` – list recent clip searches for user. Response: `{ "success": true, "data": [ string, ... ] }`.
  - `POST /api/users/{userId}/recent-searches` – save search to history. Request body: `{ "query": string, "type": "clips" }`. Response: `{ "success": true }` or 204.
  - `DELETE /api/users/{userId}/recent-searches?type=clips` – clear clip search history. Response: 200 or 204.

- **Request/response:**
  - Search: GET with query params. Frontend expects `success`, `data` (clips array), optional `users`, `hashtags`, `meta` (pagination). When `type` is `clips`, backend may return only clips; when `all`, return clips plus related users and hashtags.
  - Suggestions: GET with `q` (min 2 chars). Frontend shows suggestions as user types; each item has `text`, `type`, optional `image_url`, `count`.

- **Expectations:**
  - Navigation: Create Clip → Add music (section) → Tafuta video → VideoSearchScreen (lib/screens/clips/video_search_screen.dart); also reachable from Profile → Video gallery → search. Screen supports search by query, tabs (Zote, Video, Watumiaji, Hashtag), recent searches, suggestions, pagination. Backend must support unified clip search (caption, hashtags, user name) and return clips/users/hashtags per type; persist and return recent searches per user when provided.

---

## Story 94: Music Artist Detail

- **Endpoints:**
  - `GET /api/music/search?q={query}&current_user_id={userId}` – search tracks by query. ArtistDetailScreen uses this with the artist’s name to load “Popular” tracks for the artist. Response: `{ "success": true, "data": [ ...track objects ] }`. Track shape as in Story 55 (id, title, slug, artist_id, audio_path, cover_path, duration, artist, etc.; optional `is_saved` when `current_user_id` provided).
  - `GET /api/music/artists/{artistId}?current_user_id={userId}` – get a single artist by ID (optional; used when opening artist by ID). Response: `{ "success": true, "data": <artist object> }`. Artist object: `id`, `name`, `slug`, `image_path`, `bio`, `is_verified`, `followers_count`, `monthly_listeners`, `tracks_count`, `is_following` (boolean for current user when `current_user_id` provided).
  - **Optional (follow/unfollow):** `POST /api/music/artists/{artistId}/follow` – follow artist; `DELETE /api/music/artists/{artistId}/follow` (or `POST .../unfollow`) – unfollow artist. Request: authenticated user; response: `{ "success": true }`. When implemented, frontend will call these from the “Fuata” / “Unafuata” button and persist `is_following` state.

- **Request/response:**
  - **Search:** `GET /api/music/search?q=<encoded name>&current_user_id=<id>`. Same track array and envelope as Story 55.
  - **Get artist:** `GET /api/music/artists/<id>?current_user_id=<id>`. Artist: `id`, `name`, `slug`, `image_path`, `bio`, `is_verified`, `followers_count`, `monthly_listeners`, `tracks_count`, `is_following`.

- **Expectations:**
  - Navigation: Music library / Profile music → Tap artist → ArtistDetailScreen (lib/screens/music/artist_detail_screen.dart). Screen shows artist profile (photo, name, verified badge, monthly listeners), Follow button, Shuffle/Play, popular tracks list (loaded via search by artist name), and About section (bio, stats). Backend must support track search by query so that searching by artist name returns that artist’s tracks; optionally support GET artist by ID and follow/unfollow for full parity.

---

## Story 91: Groups Screen (Browse Groups)

- **Endpoints:**
  - `GET /api/groups?page=1&per_page=20&current_user_id={userId}` – list groups for discovery (Gundua tab). Optional query: `search=` for filtering by name/description.
  - `GET /api/groups/user?user_id={userId}` – list groups the current user is a member of (Vikundi Vyangu tab).
  - `GET /api/groups/search?q={query}` – search groups by name/description (used by the search bar on GroupsScreen).

- **Request/response:**
  - **List groups:** `GET /api/groups?page=1&per_page=20&current_user_id=<id>`. Response: `{ "success": true, "data": [ <Group> ] }`. Each Group: `id`, `name`, `slug`, `description`, `cover_photo_url` (or `cover_photo_path`), `privacy` (public|private|secret), `creator_id`, `members_count`, `posts_count`, `created_at`, optional `creator`, `membership_status`, `user_role`, `is_member`, `is_admin`.
  - **User's groups:** `GET /api/groups/user?user_id=<id>`. Same response shape; `data` is the list of groups the user belongs to, with `user_role` (admin|moderator|member) when applicable. **System groups** (Primary School, Secondary, A-Level, University, Location, Employer) must be included so "Vikundi Vyangu" shows them: either (1) include system groups in `data` when `include_system_groups=1` is sent, or (2) return a separate `system_groups` array in the response; the app merges both into the list.
  - **Search:** `GET /api/groups/search?q=<encoded query>`. Response: `{ "success": true, "data": [ <Group> ] }` or `{ "success": false, "message": "..." }`.

- **Expectations:**
  - Navigation: Discover/Profile → Groups (Vikundi tab) → GroupsScreen (lib/screens/groups/groups_screen.dart). Screen has two tabs: "Gundua" (discover groups) and "Vikundi Vyangu" (my groups). FAB opens CreateGroupScreen; search icon opens in-screen search that calls GET /api/groups/search. Tap group card navigates to GroupDetailScreen. Backend must return `success: true` and `data` array for list/search; on failure frontend shows error message and retry. Cover images use `cover_photo_url` for display (CachedMediaImage).

---

## Story 95: Media Caching (Offline Viewing)

- **Endpoints:** No new endpoints. This story is client-side only.

- **Expectations:**
  - The app caches media (images, video, audio) for offline viewing using MediaCacheService, VideoCacheService, and CachedMediaImage. All media URLs returned by existing APIs (e.g. `file_path`, `thumbnail_path`, `image_path`, `cover_path`, `video_path`, `profile_photo_path`, etc.) are downloaded and stored locally by the frontend. Cached images use the same cache manager (MediaCacheManager) with a 30-day stale period; videos use a dedicated video cache with LRU eviction. Backend does not need to change; ensure media URLs are absolute and publicly accessible (or include auth headers where the app can send them) so the client can cache them.

---
