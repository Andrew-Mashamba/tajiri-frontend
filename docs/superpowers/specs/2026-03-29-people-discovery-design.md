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
- HNSW on `embedding` using cosine distance (same pattern as content embeddings)
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

Accept matches where `similarity >= 0.6` (dlib's recommended threshold). If multiple users match above threshold, take the highest similarity only to avoid false positives.

### Embedding Lifecycle

- **Registration:** Always create with `is_primary = true`, `source = 'registration'`
- **Profile photo change with 1 face detected:** Set old primary to `is_primary = false`, insert new with `is_primary = true`, `source = 'profile_update'`
- **Profile photo change without clear face:** Keep existing primary embedding, upload photo normally

## 5. Face Discovery Microservice

### Location & Stack

- Path: `/opt/tajiri-face/`
- Python 3.12, Flask, `face_recognition` library (dlib), `psycopg2` for pgvector queries
- Port: 8300
- Supervisor-managed process

### Dependencies

```bash
apt install -y cmake build-essential libopenblas-dev liblapack-dev
pip3 install face_recognition flask psycopg2-binary pgvector numpy
```

Note: `face_recognition` compiles dlib from source (~5-10 min install). Requires cmake + build tools.

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

### Supervisor Config

```ini
[program:tajiri-face-service]
command=python3 /opt/tajiri-face/app.py
autostart=true
autorestart=true
numprocs=1
redirect_stderr=true
stdout_logfile=/var/log/tajiri/face-service.log
environment=FLASK_ENV=production
```

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

`google_mlkit_face_detection` added to `pubspec.yaml`.

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
- 0 faces → error: "Picha yako haionyeshi uso. Tafadhali piga picha inayoonyesha uso wako vizuri"
- 2+ faces → error: "Picha ina watu wengi. Tafadhali piga picha yako peke yako"
- 1 face → success with bounding box

**`detectLargestFace()`** — Lenient mode for profile updates:
- Returns the largest face bounding box if any face found, null otherwise
- Never blocks the upload

### Registration Screen Changes

In the registration profile photo step:
1. User picks/captures photo
2. Call `FaceValidator.validate(photo)`
3. If invalid: show Swahili error message, don't proceed
4. If valid: show photo preview with green checkmark, proceed to next step
5. On upload: include `face_bbox` parameter (`{x, y, width, height}` from `faceBounds`)

### Profile Photo Update Changes

In profile screen photo change flow:
1. User picks new photo
2. Call `FaceValidator.detectLargestFace(photo)` (non-blocking)
3. Upload photo with `face_bbox` if face found, without if not
4. Never block the upload regardless of face detection result

### Modified Flutter Files

| File | Change |
|------|--------|
| `pubspec.yaml` | Add `google_mlkit_face_detection` dependency |
| `lib/utils/face_validator.dart` | New — ML Kit wrapper |
| Registration screen (profile photo step) | Add validation gate |
| `lib/services/profile_service.dart` | Add `faceBbox` parameter to `updateProfilePhoto()` |
| `lib/screens/profile/profile_screen.dart` | Optional face detection on photo change |

### Modified Backend Files

| File | Change |
|------|--------|
| Profile photo controller | Call `FaceEmbeddingService::extractAndStore()` after save |

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
| `database/migrations/..._create_face_embeddings_table.php` | face_embeddings table + pgvector index |
| `app/Models/FaceEmbedding.php` | Eloquent model |
| `app/Services/ContentEngine/FaceEmbeddingService.php` | Extract + store embeddings, match query |
| `app/Services/ContentEngine/FaceDiscoveryService.php` | Orchestrate face matching during enrichment |
| `lib/utils/face_validator.dart` | Flutter ML Kit face validation wrapper |

### Modified Files

| File | Change |
|------|--------|
| `app/Services/ContentEngine/MediaEnrichmentService.php` | Call FaceDiscoveryService after media analysis |
| `app/Services/ContentEngine/GraphEdgeService.php` | Add APPEARS_IN edge type |
| `/opt/tajiri-graph/content_rank.py` | Add APPEARS_IN to edge types (weight 1.5) |
| `app/Console/Commands/ContentHealthCheck.php` | Add face service health check |
| `/etc/supervisor/conf.d/tajiri-workers.conf` | Add face service program (not a queue worker — a Flask process) |
| Profile photo controller (backend) | Call FaceEmbeddingService after photo save |
| Registration screen (frontend) | ML Kit face validation gate |
| `lib/services/profile_service.dart` | Add face_bbox parameter |
| `lib/screens/profile/profile_screen.dart` | Optional face detection on photo change |
| `pubspec.yaml` | Add google_mlkit_face_detection |

## 10. Backfill Strategy

**Phase 1: Build embedding database**
```bash
php8.3 artisan face:extract-from-profiles --batch-size=50
```
Scans all users with `profile_photo_path`, sends each to face service, stores embeddings. Only users with detectable faces get embeddings.

**Phase 2: Scan existing media**
```bash
php8.3 artisan content:enrich-media --force --batch-size=20
```
Re-runs media enrichment on existing content. Now includes face discovery. Creates APPEARS_IN edges for historical content.

## 11. Future Considerations (Out of Scope)

- **Multiple embeddings per user** — extract from album photos for better matching accuracy across angles/lighting. Would improve recall but adds complexity.
- **Face clustering** — group unmatched faces that appear together across posts. Could suggest "who is this?" to the uploader.
- **User opt-out** — allow users to opt out of face detection. Required if expanding to markets with stricter privacy laws.
- **GPU acceleration** — dlib can use CUDA for 10x faster detection. Not needed at current scale.
- **Object/product recognition** — Claude vision already describes objects in images. Structured object extraction (linking to Product models) deferred to a future phase.
