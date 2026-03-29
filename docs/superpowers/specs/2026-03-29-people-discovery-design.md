# People & Object Discovery — Design Spec

**Date:** 2026-03-29
**Status:** Draft
**Scope:** Backend (Laravel + Python microservice) + Frontend (Flutter + Google ML Kit)

## 1. Problem

The Media Intelligence Pipeline extracts text descriptions from images/audio/video, but it cannot identify WHO appears in media. A photo of three friends at a restaurant generates "Three people sitting at a table in a restaurant" — but the platform doesn't know that User #42, #17, and #85 are in the photo. This means:
- No "appears together" signals for the content graph
- Gossip threads can't surface content featuring people being discussed
- Feed ranking can't boost content featuring people you follow
- No searchability by person across media

## 2. Goal

Build a platform-owned face intelligence system that:
1. Captures face embeddings from every user's profile photo (enforced during registration)
2. Automatically detects and matches faces in all uploaded media (photos, video keyframes, stories, products)
3. Creates `APPEARS_IN` graph edges between identified users and content
4. Enriches `media_descriptions` and `media_text` with person data for search indexing

All detection and matching is invisible to users — no tagging UI, no notifications. Purely algorithmic intelligence powering feed ranking, gossip relevance, and graph relationships.

## 3. Architecture

### Components

1. **Frontend (Flutter + Google ML Kit)** — During registration, enforce exactly 1 face in profile photo. Send face bounding box coordinates with the upload. On later profile photo changes, detect opportunistically.

2. **Face Discovery Service (Python)** — Microservice at `/opt/tajiri-face/` on port 8300. Uses `face_recognition` library (dlib) to extract 128-dim face embeddings and detect faces in images. Flask app with 3 endpoints.

3. **Laravel Integration** — `FaceEmbeddingService` handles embedding storage. `FaceDiscoveryService` handles matching during media enrichment. Both are static-method classes following existing patterns.

### Data Flow

```
REGISTRATION:
  User takes photo → ML Kit enforces 1 face → Upload with face_bbox
    → ProfileController saves photo
    → FaceEmbeddingService::extractAndStore() → POST /extract-embedding
    → face_embeddings table (pgvector, 128-dim, is_primary=true)

MEDIA UPLOAD (any type):
  Upload → ContentIngestionJob → MediaEnrichmentJob
    → existing image/video/audio analysis (unchanged)
    → NEW: FaceDiscoveryService::discoverInMedia()
      → for each image/keyframe: POST /detect-and-match
      → returns matched user_ids with similarity scores
    → creates APPEARS_IN graph edges
    → enriches media_descriptions.people[]
    → appends person names to media_text
```

## 4. Face Embedding Storage

### New Table: `face_embeddings`

| Column | Type | Purpose |
|--------|------|---------|
| `id` | bigserial PK | |
| `user_id` | bigint FK (users) | The user this face belongs to |
| `embedding` | vector(128) | dlib 128-dim face embedding |
| `source` | varchar(20) | `registration`, `profile_update` |
| `confidence` | float | Face detection confidence (0-1) |
| `is_primary` | boolean default false | Best embedding for this user |
| `created_at` | timestamp | |

**Indexes:**
- HNSW on `embedding` using cosine distance: `CREATE INDEX ... USING hnsw (embedding vector_cosine_ops) WITH (m = 16, ef_construction = 64)` (pgvector defaults, sufficient for <100K embeddings)
- Unique partial index: one `is_primary = true` per `user_id`
- Index on `user_id`

**Matching query:**
```sql
SELECT user_id, 1 - (embedding <=> $input_embedding) AS similarity
FROM face_embeddings
WHERE is_primary = true
ORDER BY embedding <=> $input_embedding
LIMIT 5
```

Accept matches where `similarity >= 0.6` (dlib's recommended threshold). Each detected face maps to at most one user — if multiple stored embeddings match a single face above threshold, take the highest similarity match only to avoid false positives. A multi-person photo will return multiple matches (one per detected face).

### Embedding Lifecycle

- **Registration:** Always create with `is_primary = true`, `source = 'registration'`
- **Duplicate detection:** Before storing a new embedding, query existing embeddings for similarity >= 0.8 belonging to a *different* `user_id`. If found, log a warning via `Log::warning('face_embedding_duplicate', ['new_user' => $userId, 'existing_user' => $matchedUserId, 'similarity' => $sim])` and still store the embedding. This log entry can be monitored for fraud review. This prevents identity confusion in the matching pipeline.
- **Profile photo change with 1 face detected:** Set old primary to `is_primary = false`, insert new with `is_primary = true`, `source = 'profile_update'`
- **Profile photo change without clear face:** Keep existing primary embedding, upload photo normally

## 5. Face Discovery Microservice

### Location & Stack

- Path: `/opt/tajiri-face/`
- Python 3.12, Flask, `face_recognition` library (dlib), `psycopg2` for pgvector queries
- Port: 8300, **bound to 127.0.0.1 only** (localhost — only Laravel on the same server can reach it)
- Supervisor-managed process

### Dependencies

```bash
apt install -y cmake build-essential libopenblas-dev liblapack-dev
pip3 install face_recognition flask psycopg2-binary pgvector numpy gunicorn
```

Note: `face_recognition` compiles dlib from source (~5-10 min install). Requires cmake + build tools.

### Configuration

Database credentials via environment variables in Supervisor config (see below). The Flask app reads these at startup:

```python
DB_CONFIG = {
    'host': os.environ.get('DB_HOST', '127.0.0.1'),
    'port': os.environ.get('DB_PORT', '5432'),
    'dbname': os.environ.get('DB_NAME', 'tajiri'),
    'user': os.environ.get('DB_USER', 'tajiri'),
    'password': os.environ.get('DB_PASSWORD'),
}
```

### Path Validation

All `image_path` parameters are validated to start with `/var/www/tajiri.zimasystems.com/storage/`. Requests with paths outside this prefix return 403 Forbidden.

### Endpoints

**`POST /extract-embedding`**

Called when user uploads a profile photo.

Request:
```json
{
  "image_path": "/var/www/tajiri.zimasystems.com/storage/app/public/profile-photos/abc.jpg",
  "bbox": {"x": 120, "y": 80, "width": 200, "height": 200}
}
```

`bbox` is optional. If provided (from ML Kit), crops to face region first for faster/more accurate extraction. If omitted, detects faces in full image and uses the largest.

Response (200):
```json
{
  "embedding": [0.0234, -0.0891, ...],
  "confidence": 0.95,
  "face_count": 1
}
```

Error (422): `{"error": "no_face_detected"}` — no face found in image.

**`POST /detect-and-match`**

Called during media enrichment for each image/keyframe.

Request:
```json
{
  "image_path": "/var/www/tajiri.zimasystems.com/storage/app/public/posts/photo123.jpg"
}
```

Response (200):
```json
{
  "faces": [
    {"bbox": {"x": 50, "y": 30, "width": 150, "height": 150}, "user_id": 42, "similarity": 0.85},
    {"bbox": {"x": 300, "y": 40, "width": 140, "height": 140}, "user_id": null, "similarity": 0.0}
  ],
  "face_count": 2,
  "matched_count": 1
}
```

Faces with `user_id: null` were detected but didn't match any stored embedding above the 0.6 threshold.

**`GET /health`**

Response: `{"status": "ok", "embeddings_count": 28, "model": "dlib_128d"}`

### Resource Budget

- RAM: ~200MB for dlib model (loaded once at startup)
- CPU: ~300ms per face detection + embedding extraction
- pgvector query: ~5ms per face match
- Total per image: ~300-400ms
- Total for post with 5 images: ~2s
- Total for video with 6 keyframes: ~2.5s

### Requirements.txt

```
face_recognition==1.3.0
flask==3.1.0
psycopg2-binary==2.9.10
pgvector==0.3.6
numpy>=1.26,<2.0
gunicorn==23.0.0
```

### Supervisor Config

```ini
[program:tajiri-face-service]
command=gunicorn --bind 127.0.0.1:8300 --workers 2 --timeout 120 app:app
directory=/opt/tajiri-face
autostart=true
autorestart=true
numprocs=1
redirect_stderr=true
stdout_logfile=/var/log/tajiri/face-service.log
environment=FLASK_ENV=production,DB_HOST=127.0.0.1,DB_PORT=5432,DB_NAME=tajiri,DB_USER=tajiri,DB_PASSWORD=%(ENV_TAJIRI_DB_PASSWORD)s
```

Note: `%(ENV_TAJIRI_DB_PASSWORD)s` requires `TAJIRI_DB_PASSWORD` to be exported in the supervisord process environment (e.g., in `/etc/default/supervisor` or the systemd unit's `Environment=`).

Note: 2 gunicorn workers. Each loads its own copy of the dlib model (~200MB each, ~400MB total). This allows concurrent request handling during backfill without starving real-time enrichment. For single-server deployment with limited RAM, reduce to 1 worker.

## 6. Laravel Services

### FaceEmbeddingService

```
App\Services\ContentEngine\FaceEmbeddingService
```

Static methods:

**`extractAndStore(int $userId, string $imagePath, ?array $bbox, string $source): bool`**
- Calls `POST /extract-embedding` on face service
- If embedding returned: upserts into `face_embeddings` (mark as primary, demote old primary)
- Returns true on success, false on failure (no face, service down)
- Called from ProfileController after profile photo save

**`getMatchesForImage(string $imagePath): array`**
- Calls `POST /detect-and-match` on face service
- Returns array of `['user_id' => int|null, 'similarity' => float, 'bbox' => array]`
- Called from FaceDiscoveryService during enrichment

### FaceDiscoveryService

```
App\Services\ContentEngine\FaceDiscoveryService
```

Static methods:

**`discoverInMedia(int $contentDocumentId, array $mediaDescriptions): array`**
- Reads existing `media_descriptions` to find image paths and video keyframe paths
- **Image paths:** From `$mediaDescriptions['images'][*]['path']` (the storage path of each uploaded image)
- **Video keyframe paths:** The existing `VideoAnalysisService` extracts keyframes to `/tmp/tajiri_video_{hash}/frame_*.jpg` during enrichment, and stores their paths in `$mediaDescriptions['video']['keyframes']` (array of file paths). `FaceDiscoveryService` reads these paths. **Important:** keyframe files are temporary — face discovery MUST run in the same job invocation as video analysis, before temp files are cleaned up.
- For each image: calls `FaceEmbeddingService::getMatchesForImage()`
- For video keyframes: calls on each extracted frame, deduplicates (same user across frames counted once, keep highest similarity)
- Creates `APPEARS_IN` graph edges via `GraphEdgeService`
- Returns `people` array for inclusion in `media_descriptions`

### Integration Point in MediaEnrichmentService

After existing image/video/audio enrichment, before saving:

```php
// --- Face Discovery ---
$people = FaceDiscoveryService::discoverInMedia($contentDocumentId, $mediaDescriptions);
if (!empty($people)) {
    $mediaDescriptions['people'] = $people;
    foreach ($people as $person) {
        if ($person['user_id']) {
            $mediaTextParts[] = "[Person: user#{$person['user_id']} appears in this content]";
        }
    }
}
```

### Graph Edge: APPEARS_IN

New edge type added to `GraphEdgeService`:

- Source: `user`, source_id: matched user_id
- Target: `doc`, target_id: content_document_id
- Edge type: `APPEARS_IN`
- Weight: similarity score (0.6-1.0)

Also add to `/opt/tajiri-graph/content_rank.py` edge type list with weight 1.5 (medium — stronger than hashtag co-occurrence, weaker than shares/replies).

### Enriched media_descriptions Structure

New `people` key added alongside existing `images`, `audio`, `video`:

```json
{
  "images": [...],
  "audio": [...],
  "video": [...],
  "people": [
    {
      "user_id": 42,
      "source": "image",
      "media_id": 6,
      "similarity": 0.85,
      "bbox": {"x": 50, "y": 30, "width": 150, "height": 150}
    },
    {
      "user_id": 17,
      "source": "video_frame",
      "media_id": 12,
      "similarity": 0.72,
      "bbox": {"x": 200, "y": 60, "width": 130, "height": 130}
    }
  ],
  "enriched_at": "2026-03-29T14:00:00Z"
}
```

## 7. Frontend — ML Kit Face Enforcement

### Package

The project already has `google_ml_kit: ^0.20.1` (umbrella package that includes face detection). Use `GoogleMlKit.vision.faceDetector()` from this existing package — no new dependency needed.

### FaceValidator Utility

New file: `lib/utils/face_validator.dart`

```dart
class FaceValidationResult {
  final bool isValid;
  final String? errorMessage;
  final Rect? faceBounds; // bounding box of detected face
  final int faceCount;
}

class FaceValidator {
  static Future<FaceValidationResult> validate(File imageFile);
  static Future<Rect?> detectLargestFace(File imageFile); // for optional detection
}
```

**`validate()`** — Strict mode for registration:
- 0 faces → error (via `AppStrings.faceNotDetected`): "Picha yako haionyeshi uso. Tafadhali piga picha inayoonyesha uso wako vizuri" / "Your photo doesn't show a face. Please take a photo that clearly shows your face"
- 2+ faces → error (via `AppStrings.multipleFacesDetected`): "Picha ina watu wengi. Tafadhali piga picha yako peke yako" / "Photo has multiple people. Please take a photo of just yourself"
- 1 face → success with bounding box

**`detectLargestFace()`** — Lenient mode for profile updates:
- Returns the largest face bounding box if any face found, null otherwise
- Never blocks the upload

### New Registration Step: Profile Photo

The current registration flow (`lib/screens/registration/registration_screen.dart`) has steps: Bio → Phone → Location → Schools → Employer. There is **no profile photo step**. A new step must be added.

**New file:** `lib/screens/registration/steps/profile_photo_step.dart`

**Position:** Insert after Bio step (index 0), shifting all subsequent steps by +1. The full current flow is: Bio(0) → Phone(1) → Location(2) → Primary School(3) → Secondary School(4) → Education Path(5) → A-Level(6, conditional) → Post-Secondary(7) → University(8) → Employer(9). The new photo step becomes index 1, and Phone shifts to index 2, etc. Bio collects name/username/email/password, then the user immediately captures their face photo. This ensures every account has a face embedding from the start.

**Step UI:**
- Camera preview (front camera, using `image_picker` which is already in pubspec)
- "Piga picha yako" ("Take your photo") heading
- Capture button → call `FaceValidator.validate(photo)`
- If invalid: show error below photo (Swahili), allow retake
- If valid: show photo with green checkmark overlay, "Endelea" (Continue) button enabled
- Also allow gallery pick (with same validation)

**Registration state change:** Add `profilePhotoPath` (String? — file path, not File object) and `faceBbox` (Map<String, int>?) to `RegistrationState` model in `lib/models/registration_models.dart`. Store the file path (not the File object) so it survives Hive draft persistence. Reconstruct `File(path)` when needed for upload.

**Registration submit change:** In the `register()` call in `UserService`, send the profile photo as a multipart upload alongside the registration JSON. The backend `RegisterController` must accept and save the photo, then call `FaceEmbeddingService::extractAndStore()`.

**Step flow:**
1. User captures/picks photo
2. Call `FaceValidator.validate(photo)`
3. If invalid: show Swahili error message, don't proceed
4. If valid: show photo preview with green checkmark, proceed to next step
5. On final registration submit: include photo file + `face_bbox` parameter (`{x, y, width, height}` from `faceBounds`)

### Profile Photo Update Changes

In profile screen photo change flow:
1. User picks new photo
2. Call `FaceValidator.detectLargestFace(photo)` (non-blocking)
3. Upload photo with `face_bbox` if face found, without if not
4. Never block the upload regardless of face detection result

### Modified Flutter Files

| File | Change |
|------|--------|
| `lib/utils/face_validator.dart` | New — ML Kit face validation wrapper (uses existing `google_ml_kit`) |
| `lib/screens/registration/steps/profile_photo_step.dart` | New — Profile photo capture step with face validation |
| `lib/screens/registration/registration_screen.dart` | Add profile photo step after Bio step |
| `lib/models/registration_models.dart` | Add `profilePhotoPath` (String?) and `faceBbox` (Map?) fields |
| `lib/services/user_service.dart` | Modify `register()` to send profile photo as multipart upload |
| `lib/services/profile_service.dart` | Add `Map<String, int>? faceBbox` param to instance method `updateProfilePhoto()` |
| `lib/l10n/app_strings.dart` | Add `faceNotDetected`, `multipleFacesDetected`, `takeYourPhoto` bilingual getters |
| `lib/screens/profile/profile_screen.dart` | Optional face detection on photo change |

### Modified Backend Files

| File | Change |
|------|--------|
| Profile photo controller | Call `FaceEmbeddingService::extractAndStore()` after save |
| Register controller | Accept profile photo multipart, save, call `FaceEmbeddingService::extractAndStore()` |

## 8. Error Handling

- **Face service down:** `FaceDiscoveryService` logs warning, skips face discovery, rest of enrichment continues normally. Face discovery is never blocking.
- **No faces in media:** Normal case for many posts (text, landscapes, food). `people` array is empty, no edges created.
- **Low confidence match:** Only matches >= 0.6 similarity accepted. Below that, face is recorded as unmatched (`user_id: null`).
- **dlib model load failure:** Face service returns 503, Laravel retries on next enrichment job run.
- **ML Kit unavailable on device:** Frontend `FaceValidator` catches exceptions, falls back to allowing upload without face data. Registration still proceeds — backend attempts face extraction without bbox hint.
- **Profile photo with no face (post-registration):** Existing embedding preserved. User can still use the platform normally.

## 9. File Structure

### New Files

| File | Purpose |
|------|---------|
| `/opt/tajiri-face/app.py` | Flask face service (extract, detect-and-match, health) |
| `/opt/tajiri-face/requirements.txt` | Python dependencies |
| `database/migrations/..._create_face_embeddings_table.php` | face_embeddings table + pgvector index (pgvector extension already enabled for the media pipeline — no `CREATE EXTENSION` needed) |
| `app/Models/FaceEmbedding.php` | Eloquent model |
| `app/Services/ContentEngine/FaceEmbeddingService.php` | Extract + store embeddings, match query |
| `app/Services/ContentEngine/FaceDiscoveryService.php` | Orchestrate face matching during enrichment |
| `lib/utils/face_validator.dart` | Flutter ML Kit face validation wrapper |
| `lib/screens/registration/steps/profile_photo_step.dart` | New registration step — camera/gallery with face validation |

### Modified Files

| File | Change |
|------|--------|
| `app/Services/ContentEngine/MediaEnrichmentService.php` | Call FaceDiscoveryService after media analysis |
| `app/Services/ContentEngine/GraphEdgeService.php` | Add APPEARS_IN edge type |
| `/opt/tajiri-graph/content_rank.py` | Add APPEARS_IN to edge types (weight 1.5) |
| `app/Console/Commands/ContentHealthCheck.php` | Add face service health check |
| `/etc/supervisor/conf.d/tajiri-workers.conf` | Add face service program (gunicorn, not a queue worker) |
| `app/Http/Controllers/ProfileController.php` | Call `FaceEmbeddingService::extractAndStore()` after photo save |
| `app/Http/Controllers/Auth/RegisterController.php` | Accept profile photo multipart, call `FaceEmbeddingService::extractAndStore()` |
| `lib/screens/registration/registration_screen.dart` | Add profile photo step after Bio |
| `lib/models/registration_models.dart` | Add profilePhoto + faceBbox fields |
| `lib/services/user_service.dart` | Modify register() for multipart photo upload |
| `lib/services/profile_service.dart` | Add faceBbox parameter to updateProfilePhoto() |
| `lib/screens/profile/profile_screen.dart` | Optional face detection on photo change |
| `lib/l10n/app_strings.dart` | Add face validation bilingual strings |

## 10. Backfill Strategy

**Phase 1: Build embedding database**
```bash
php8.3 artisan face:extract-from-profiles --batch-size=50 --delay=200
```
Scans all users with `profile_photo_path`, sends each to face service, stores embeddings. Only users with detectable faces get embeddings.

- `--delay` adds 200ms pause between requests to avoid saturating the face service
- **Estimate:** At ~300ms per extraction + 200ms delay, ~100 users = ~50s, ~1000 users = ~8min

**Phase 2: Scan existing media**
```bash
php8.3 artisan content:enrich-media --force --batch-size=20 --source-type=post,photo,clip
```
Re-runs media enrichment on existing content. Now includes face discovery. Creates APPEARS_IN edges for historical content.

- **Estimate:** At ~400ms per image, a batch of 20 posts with average 2 images each = ~16s per batch. For 1000 posts = ~800s (~13min). Videos with keyframes take longer (~2.5s each).
- Run during off-peak hours. The 2-worker gunicorn setup allows backfill and real-time enrichment to run concurrently.

## 11. Future Considerations (Out of Scope)

- **Multiple embeddings per user** — extract from album photos for better matching accuracy across angles/lighting. Would improve recall but adds complexity.
- **Face clustering** — group unmatched faces that appear together across posts. Could suggest "who is this?" to the uploader.
- **User opt-out** — allow users to opt out of face detection. Required if expanding to markets with stricter privacy laws. **Note:** The registration flow's face photo capture step establishes implicit consent for face recognition as part of the platform's terms of service. For markets with biometric data laws (GDPR, Kenya DPA 2019), explicit consent language should be added to the ToS.
- **GPU acceleration** — dlib can use CUDA for 10x faster detection. Not needed at current scale.
- **Object/product recognition** — Claude vision already describes objects in images. Structured object extraction (linking to Product models) deferred to a future phase.
