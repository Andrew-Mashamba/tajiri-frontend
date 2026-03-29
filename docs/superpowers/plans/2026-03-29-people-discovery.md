# People & Object Discovery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a face intelligence system that detects and matches faces in all uploaded media against user profile photos, creating APPEARS_IN graph edges and enriching media descriptions for feed ranking and gossip relevance.

**Architecture:** Python Flask microservice (dlib face_recognition) extracts 128-dim face embeddings and matches them via pgvector cosine similarity. Laravel services orchestrate embedding storage and media enrichment integration. Frontend Google ML Kit enforces face detection during registration.

**Tech Stack:** Python 3.12 / Flask / face_recognition / gunicorn, PHP 8.3 / Laravel 12, PostgreSQL 16 / pgvector, Flutter / Dart / google_ml_kit

**Spec:** `docs/superpowers/specs/2026-03-29-people-discovery-design.md`

**Server:** `root@172.240.241.180` (password `ZimaBlueApps`), Laravel at `/var/www/tajiri.zimasystems.com`

**SSH pattern:** `sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 '<command>'`

---

## File Structure

### New Files (Backend — on server)

| File | Responsibility |
|------|---------------|
| `/opt/tajiri-face/app.py` | Flask face service: /extract-embedding, /detect-and-match, /health |
| `/opt/tajiri-face/requirements.txt` | Python dependencies (pinned versions) |
| `database/migrations/2026_03_29_500001_create_face_embeddings_table.php` | face_embeddings table + pgvector HNSW index |
| `app/Models/FaceEmbedding.php` | Eloquent model for face_embeddings |
| `app/Services/ContentEngine/FaceEmbeddingService.php` | Extract + store embeddings, match query, duplicate detection |
| `app/Services/ContentEngine/FaceDiscoveryService.php` | Orchestrate face matching during media enrichment |
| `app/Console/Commands/ExtractFaceEmbeddings.php` | `face:extract-from-profiles` backfill command |

### New Files (Frontend — local)

| File | Responsibility |
|------|---------------|
| `lib/utils/face_validator.dart` | Google ML Kit face detection wrapper |
| `lib/screens/registration/steps/profile_photo_step.dart` | Registration step: capture/pick photo with face validation |

### Modified Files (Backend — on server)

| File | Change |
|------|--------|
| `app/Services/ContentEngine/MediaEnrichmentService.php` | Call FaceDiscoveryService after media analysis |
| `app/Services/ContentEngine/GraphEdgeService.php` | Add APPEARS_IN edge type constant + creation method |
| `app/Models/ContentGraphEdge.php` | Add `EDGE_APPEARS_IN` constant |
| `/opt/tajiri-graph/content_rank.py` | Add APPEARS_IN to edge type weights |
| `app/Console/Commands/ContentHealthCheck.php` | Add face service health check |
| `/etc/supervisor/conf.d/tajiri-workers.conf` | Add tajiri-face-service program |
| `app/Http/Controllers/Api/UserProfileController.php` | Call FaceEmbeddingService after profile photo save + accept photo in register() |

### Modified Files (Frontend — local)

| File | Change |
|------|--------|
| `lib/screens/registration/registration_screen.dart` | Insert profile photo step after Bio |
| `lib/models/registration_models.dart` | Add profilePhotoPath + faceBbox fields |
| `lib/services/user_service.dart` | Modify register() for multipart photo upload |
| `lib/services/profile_service.dart` | Add faceBbox param to updateProfilePhoto() |
| `lib/screens/profile/profile_screen.dart` | Optional face detection on photo change |
| `lib/l10n/app_strings.dart` | Add face validation bilingual strings |

---

## Task 1: Python Face Discovery Microservice

**Files:**
- Create: `/opt/tajiri-face/app.py`
- Create: `/opt/tajiri-face/requirements.txt`

**Context:** This is a standalone Python Flask microservice that uses the `face_recognition` library (dlib) to extract 128-dim face embeddings from images and match detected faces against stored embeddings in PostgreSQL via pgvector. It runs via gunicorn on port 8300, bound to 127.0.0.1 only. The server already has Python 3.12, PostgreSQL 16 with pgvector, cmake, and build-essential installed.

**Important:** The DB credentials are: host=127.0.0.1, port=5432, dbname=tajiri, user=postgres, password=postgres. These come from environment variables set in Supervisor config.

- [ ] **Step 1: Install system dependencies and face_recognition on server**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'apt install -y cmake build-essential libopenblas-dev liblapack-dev && mkdir -p /opt/tajiri-face'
```

Then install Python packages (face_recognition compiles dlib from source, takes ~5-10 min):

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'pip3 install face_recognition==1.3.0 flask==3.1.0 psycopg2-binary==2.9.10 pgvector==0.3.6 "numpy>=1.26,<2.0" gunicorn==23.0.0'
```

Expected: Packages install successfully. If face_recognition compilation fails, ensure cmake is installed.

- [ ] **Step 2: Create requirements.txt**

Write to `/opt/tajiri-face/requirements.txt`:

```
face_recognition==1.3.0
flask==3.1.0
psycopg2-binary==2.9.10
pgvector==0.3.6
numpy>=1.26,<2.0
gunicorn==23.0.0
```

- [ ] **Step 3: Create the Flask app**

Write to `/opt/tajiri-face/app.py`:

```python
import os
import json
import logging
from flask import Flask, request, jsonify
import face_recognition
import numpy as np
import psycopg2
from pgvector.psycopg2 import register_vector

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger('tajiri-face')

STORAGE_PREFIX = '/var/www/tajiri.zimasystems.com/storage/'
SIMILARITY_THRESHOLD = 0.6

DB_CONFIG = {
    'host': os.environ.get('DB_HOST', '127.0.0.1'),
    'port': os.environ.get('DB_PORT', '5432'),
    'dbname': os.environ.get('DB_NAME', 'tajiri'),
    'user': os.environ.get('DB_USER', 'tajiri'),
    'password': os.environ.get('DB_PASSWORD'),
}


def get_db():
    conn = psycopg2.connect(**DB_CONFIG)
    register_vector(conn)
    return conn


def validate_path(image_path):
    """Validate image_path starts with allowed storage prefix."""
    if not image_path or not image_path.startswith(STORAGE_PREFIX):
        return False
    # Prevent path traversal
    real = os.path.realpath(image_path)
    return real.startswith(STORAGE_PREFIX)


@app.route('/extract-embedding', methods=['POST'])
def extract_embedding():
    """Extract face embedding from a profile photo."""
    data = request.get_json()
    if not data or 'image_path' not in data:
        return jsonify({'error': 'image_path required'}), 400

    image_path = data['image_path']
    if not validate_path(image_path):
        return jsonify({'error': 'forbidden_path'}), 403

    if not os.path.exists(image_path):
        return jsonify({'error': 'file_not_found'}), 404

    try:
        image = face_recognition.load_image_file(image_path)

        bbox = data.get('bbox')
        if bbox:
            # Crop to face region if ML Kit bbox provided
            x, y, w, h = int(bbox['x']), int(bbox['y']), int(bbox['width']), int(bbox['height'])
            # Add padding (20%) for better embedding
            pad_x, pad_y = int(w * 0.2), int(h * 0.2)
            y1 = max(0, y - pad_y)
            y2 = min(image.shape[0], y + h + pad_y)
            x1 = max(0, x - pad_x)
            x2 = min(image.shape[1], x + w + pad_x)
            image = image[y1:y2, x1:x2]

        # Detect faces
        face_locations = face_recognition.face_locations(image, model='hog')
        if not face_locations:
            return jsonify({'error': 'no_face_detected'}), 422

        # Use the largest face
        largest = max(face_locations, key=lambda loc: (loc[2] - loc[0]) * (loc[1] - loc[3]))
        encodings = face_recognition.face_encodings(image, [largest])

        if not encodings:
            return jsonify({'error': 'no_face_detected'}), 422

        embedding = encodings[0].tolist()
        # Confidence based on face area relative to image area
        face_area = (largest[2] - largest[0]) * (largest[1] - largest[3])
        image_area = image.shape[0] * image.shape[1]
        confidence = min(1.0, (face_area / image_area) * 4)  # Scale up, cap at 1.0

        return jsonify({
            'embedding': embedding,
            'confidence': round(confidence, 4),
            'face_count': len(face_locations),
        })

    except Exception as e:
        logger.error(f'extract-embedding error: {e}')
        return jsonify({'error': str(e)}), 500


@app.route('/detect-and-match', methods=['POST'])
def detect_and_match():
    """Detect faces in an image and match against stored embeddings."""
    data = request.get_json()
    if not data or 'image_path' not in data:
        return jsonify({'error': 'image_path required'}), 400

    image_path = data['image_path']
    # Allow both storage paths and /tmp paths (for video keyframes)
    if not validate_path(image_path):
        # Check /tmp/tajiri_video_ paths with realpath traversal protection
        real = os.path.realpath(image_path)
        if not real.startswith('/tmp/tajiri_video_'):
            return jsonify({'error': 'forbidden_path'}), 403

    if not os.path.exists(image_path):
        return jsonify({'error': 'file_not_found'}), 404

    try:
        image = face_recognition.load_image_file(image_path)
        face_locations = face_recognition.face_locations(image, model='hog')

        if not face_locations:
            return jsonify({'faces': [], 'face_count': 0, 'matched_count': 0})

        encodings = face_recognition.face_encodings(image, face_locations)
        faces = []
        matched_count = 0

        conn = get_db()
        try:
            cur = conn.cursor()
            for i, (encoding, location) in enumerate(zip(encodings, face_locations)):
                top, right, bottom, left = location
                bbox_out = {
                    'x': int(left),
                    'y': int(top),
                    'width': int(right - left),
                    'height': int(bottom - top),
                }

                # Query pgvector for closest match
                embedding_list = encoding.tolist()
                cur.execute(
                    """
                    SELECT user_id, 1 - (embedding <=> %s::vector) AS similarity
                    FROM face_embeddings
                    WHERE is_primary = true
                    ORDER BY embedding <=> %s::vector
                    LIMIT 1
                    """,
                    (embedding_list, embedding_list)
                )
                row = cur.fetchone()

                user_id = None
                similarity = 0.0
                if row and row[1] >= SIMILARITY_THRESHOLD:
                    user_id = row[0]
                    similarity = round(row[1], 4)
                    matched_count += 1

                faces.append({
                    'bbox': bbox_out,
                    'user_id': user_id,
                    'similarity': similarity,
                })
        finally:
            conn.close()

        return jsonify({
            'faces': faces,
            'face_count': len(faces),
            'matched_count': matched_count,
        })

    except Exception as e:
        logger.error(f'detect-and-match error: {e}')
        return jsonify({'error': str(e)}), 500


@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint."""
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("SELECT COUNT(*) FROM face_embeddings WHERE is_primary = true")
        count = cur.fetchone()[0]
        conn.close()
        return jsonify({
            'status': 'ok',
            'embeddings_count': count,
            'model': 'dlib_128d',
        })
    except Exception as e:
        return jsonify({'status': 'error', 'error': str(e)}), 503


if __name__ == '__main__':
    app.run(host='127.0.0.1', port=8300, debug=False)
```

- [ ] **Step 4: Test the Flask app starts without errors**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'cd /opt/tajiri-face && timeout 5 python3 -c "import face_recognition; import flask; import psycopg2; from pgvector.psycopg2 import register_vector; print(\"All imports OK\")"'
```

Expected: `All imports OK`

- [ ] **Step 5: Commit**

```bash
# Commit on server (the Python service lives on the server, not in the Flutter repo)
# No git commit needed — this is deployed directly to /opt/tajiri-face/
```

---

## Task 2: Database Migration — face_embeddings Table

**Files:**
- Create: `database/migrations/2026_03_29_500001_create_face_embeddings_table.php` (on server)

**Context:** The server already has pgvector enabled (used by the media intelligence pipeline). The face_embeddings table stores 128-dim dlib face embeddings with HNSW cosine index for fast similarity search. The matching query selects primary embeddings ordered by cosine distance.

- [ ] **Step 1: Create the migration file**

Write to `/var/www/tajiri.zimasystems.com/database/migrations/2026_03_29_500001_create_face_embeddings_table.php`:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // pgvector extension already enabled — just create table
        DB::statement("
            CREATE TABLE face_embeddings (
                id BIGSERIAL PRIMARY KEY,
                user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                embedding vector(128) NOT NULL,
                source VARCHAR(20) NOT NULL DEFAULT 'registration',
                confidence FLOAT NOT NULL DEFAULT 0.0,
                is_primary BOOLEAN NOT NULL DEFAULT false,
                created_at TIMESTAMP DEFAULT NOW()
            )
        ");

        // HNSW index for fast cosine similarity search
        DB::statement("
            CREATE INDEX face_embeddings_embedding_hnsw_idx
            ON face_embeddings
            USING hnsw (embedding vector_cosine_ops)
            WITH (m = 16, ef_construction = 64)
        ");

        // Only one primary embedding per user
        DB::statement("
            CREATE UNIQUE INDEX face_embeddings_user_primary_idx
            ON face_embeddings (user_id)
            WHERE is_primary = true
        ");

        // Fast lookup by user_id
        DB::statement("
            CREATE INDEX face_embeddings_user_id_idx
            ON face_embeddings (user_id)
        ");
    }

    public function down(): void
    {
        Schema::dropIfExists('face_embeddings');
    }
};
```

- [ ] **Step 2: Run the migration**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'cd /var/www/tajiri.zimasystems.com && php8.3 artisan migrate --force'
```

Expected: `Migrating: 2026_03_29_500001_create_face_embeddings_table` / `Migrated`

- [ ] **Step 3: Verify the table exists with correct structure**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 "cd /var/www/tajiri.zimasystems.com && php8.3 artisan tinker --execute=\"DB::select('SELECT column_name, data_type FROM information_schema.columns WHERE table_name = \\\"face_embeddings\\\" ORDER BY ordinal_position')\" 2>/dev/null | head -20"
```

Expected: Columns id, user_id, embedding, source, confidence, is_primary, created_at

- [ ] **Step 4: Commit**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'cd /var/www/tajiri.zimasystems.com && git add database/migrations/2026_03_29_500001_create_face_embeddings_table.php && git commit -m "feat(face): add face_embeddings table with pgvector HNSW index"'
```

---

## Task 3: FaceEmbedding Eloquent Model

**Files:**
- Create: `app/Models/FaceEmbedding.php` (on server)

**Context:** Follow the existing `ContentDocument` model pattern — no timestamps (we have manual `created_at`), array casts where needed, fillable fields. The model is simple — it's primarily used by FaceEmbeddingService for DB operations.

- [ ] **Step 1: Create the model**

Write to `/var/www/tajiri.zimasystems.com/app/Models/FaceEmbedding.php`:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FaceEmbedding extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'user_id',
        'embedding',
        'source',
        'confidence',
        'is_primary',
        'created_at',
    ];

    protected $casts = [
        'confidence' => 'float',
        'is_primary' => 'boolean',
        'created_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
```

- [ ] **Step 2: Verify model loads**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'cd /var/www/tajiri.zimasystems.com && php8.3 artisan tinker --execute="new \App\Models\FaceEmbedding(); echo \"FaceEmbedding model OK\";"'
```

Expected: `FaceEmbedding model OK`

- [ ] **Step 3: Commit**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'cd /var/www/tajiri.zimasystems.com && git add app/Models/FaceEmbedding.php && git commit -m "feat(face): add FaceEmbedding Eloquent model"'
```

---

## Task 4: FaceEmbeddingService

**Files:**
- Create: `app/Services/ContentEngine/FaceEmbeddingService.php` (on server)

**Context:** Static-method service following the existing pattern (like `ImageAnalysisService`). Communicates with the Python face service at `http://127.0.0.1:8300`. Two public methods: `extractAndStore()` for profile photo uploads, `getMatchesForImage()` for media enrichment. Includes duplicate detection (similarity >= 0.8 against different user).

- [ ] **Step 1: Create FaceEmbeddingService**

Write to `/var/www/tajiri.zimasystems.com/app/Services/ContentEngine/FaceEmbeddingService.php`:

```php
<?php

namespace App\Services\ContentEngine;

use App\Models\FaceEmbedding;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FaceEmbeddingService
{
    private const FACE_SERVICE_URL = 'http://127.0.0.1:8300';
    private const DUPLICATE_THRESHOLD = 0.8;

    /**
     * Extract face embedding from an image and store it for a user.
     *
     * @param int $userId
     * @param string $imagePath Absolute path to image file on server
     * @param array|null $bbox Face bounding box from ML Kit {x, y, width, height}
     * @param string $source 'registration' or 'profile_update'
     * @return bool True on success, false on failure
     */
    public static function extractAndStore(int $userId, string $imagePath, ?array $bbox = null, string $source = 'registration'): bool
    {
        try {
            $payload = ['image_path' => $imagePath];
            if ($bbox) {
                $payload['bbox'] = $bbox;
            }

            $response = Http::timeout(30)->post(self::FACE_SERVICE_URL . '/extract-embedding', $payload);

            if (!$response->successful()) {
                $error = $response->json('error') ?? 'unknown';
                Log::info('FaceEmbedding: No face extracted', [
                    'user_id' => $userId,
                    'error' => $error,
                    'path' => $imagePath,
                ]);
                return false;
            }

            $data = $response->json();
            $embedding = $data['embedding'] ?? null;
            $confidence = $data['confidence'] ?? 0.0;

            if (!$embedding || !is_array($embedding) || count($embedding) !== 128) {
                Log::warning('FaceEmbedding: Invalid embedding returned', ['user_id' => $userId]);
                return false;
            }

            // Duplicate detection: check if this face matches another user
            self::checkDuplicate($userId, $embedding);

            // Demote old primary embedding
            FaceEmbedding::where('user_id', $userId)
                ->where('is_primary', true)
                ->update(['is_primary' => false]);

            // Insert new primary embedding using raw SQL for vector type
            $embeddingStr = '[' . implode(',', $embedding) . ']';
            DB::statement(
                "INSERT INTO face_embeddings (user_id, embedding, source, confidence, is_primary, created_at)
                 VALUES (?, ?::vector, ?, ?, true, NOW())",
                [$userId, $embeddingStr, $source, $confidence]
            );

            Log::info('FaceEmbedding: Stored', [
                'user_id' => $userId,
                'source' => $source,
                'confidence' => $confidence,
            ]);

            return true;

        } catch (\Exception $e) {
            Log::error('FaceEmbedding: extractAndStore failed', [
                'user_id' => $userId,
                'error' => $e->getMessage(),
            ]);
            return false;
        }
    }

    /**
     * Get face matches for an image from the face service.
     *
     * @param string $imagePath Absolute path to image file
     * @return array Array of matches: [{user_id, similarity, bbox}]
     */
    public static function getMatchesForImage(string $imagePath): array
    {
        try {
            $response = Http::timeout(30)->post(self::FACE_SERVICE_URL . '/detect-and-match', [
                'image_path' => $imagePath,
            ]);

            if (!$response->successful()) {
                return [];
            }

            return $response->json('faces') ?? [];

        } catch (\Exception $e) {
            Log::warning('FaceEmbedding: getMatchesForImage failed', [
                'path' => $imagePath,
                'error' => $e->getMessage(),
            ]);
            return [];
        }
    }

    /**
     * Check for duplicate face embeddings belonging to different users.
     */
    private static function checkDuplicate(int $userId, array $embedding): void
    {
        try {
            $embeddingStr = '[' . implode(',', $embedding) . ']';
            $results = DB::select(
                "SELECT user_id, 1 - (embedding <=> ?::vector) AS similarity
                 FROM face_embeddings
                 WHERE is_primary = true AND user_id != ?
                 ORDER BY embedding <=> ?::vector
                 LIMIT 1",
                [$embeddingStr, $userId, $embeddingStr]
            );

            if (!empty($results) && $results[0]->similarity >= self::DUPLICATE_THRESHOLD) {
                Log::warning('face_embedding_duplicate', [
                    'new_user' => $userId,
                    'existing_user' => $results[0]->user_id,
                    'similarity' => round($results[0]->similarity, 4),
                ]);
            }
        } catch (\Exception $e) {
            // Non-blocking — just log
            Log::error('FaceEmbedding: duplicate check failed', ['error' => $e->getMessage()]);
        }
    }
}
```

- [ ] **Step 2: Verify service loads**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'cd /var/www/tajiri.zimasystems.com && php8.3 artisan tinker --execute="echo class_exists(\App\Services\ContentEngine\FaceEmbeddingService::class) ? \"OK\" : \"FAIL\";"'
```

Expected: `OK`

- [ ] **Step 3: Commit**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'cd /var/www/tajiri.zimasystems.com && git add app/Services/ContentEngine/FaceEmbeddingService.php && git commit -m "feat(face): add FaceEmbeddingService — extract, store, match, duplicate detection"'
```

---

## Task 5: FaceDiscoveryService + MediaEnrichmentService Integration + GraphEdgeService APPEARS_IN

**Files:**
- Create: `app/Services/ContentEngine/FaceDiscoveryService.php` (on server)
- Modify: `app/Services/ContentEngine/MediaEnrichmentService.php` (on server)
- Modify: `app/Services/ContentEngine/GraphEdgeService.php` (on server)
- Modify: `app/Models/ContentGraphEdge.php` (on server — add EDGE_APPEARS_IN constant)
- Modify: `/opt/tajiri-graph/content_rank.py` (on server)

**Context:** FaceDiscoveryService reads `media_descriptions` from the enrichment pipeline to find image paths and video keyframe paths, calls FaceEmbeddingService::getMatchesForImage() on each, deduplicates across video frames, creates APPEARS_IN graph edges, and returns a `people` array. MediaEnrichmentService calls it after existing analysis, before saving. GraphEdgeService needs a new APPEARS_IN edge type.

**Important patterns:**
- Image paths in media_descriptions: `$mediaDescriptions['images'][*]['path']` — these are storage paths like `/var/www/tajiri.zimasystems.com/storage/app/public/...`
- Video keyframe paths: `$mediaDescriptions['video']['keyframes']` — array of `/tmp/tajiri_video_{hash}/frame_*.jpg` paths (temporary, only available during the same job run)
- GraphEdgeService uses `ContentGraphEdge` model constants and `self::upsertEdge()` method
- Edge pattern: source_type, source_id, target_type, target_id, edge_type, weight

- [ ] **Step 1: Add EDGE_APPEARS_IN constant to ContentGraphEdge model**

Read the current ContentGraphEdge model to find existing constants:

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'grep -n "EDGE_" /var/www/tajiri.zimasystems.com/app/Models/ContentGraphEdge.php | head -20'
```

Then add the new constant after the last existing one:

```php
public const EDGE_APPEARS_IN = 'APPEARS_IN';
```

- [ ] **Step 2: Add APPEARS_IN edge creation to GraphEdgeService**

Read the current GraphEdgeService to find the `upsertEdge` method signature:

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'grep -n "function upsertEdge\|function buildCreator\|public static function" /var/www/tajiri.zimasystems.com/app/Services/ContentEngine/GraphEdgeService.php'
```

Add a new public static method at the end of the class (before the closing `}`):

```php
/**
 * Create APPEARS_IN edges for users detected in content.
 *
 * @param int $contentDocumentId
 * @param array $people Array of detected people [{user_id, similarity, ...}]
 * @return int Number of edges created
 */
public static function buildAppearsInEdges(int $contentDocumentId, array $people): int
{
    $count = 0;
    foreach ($people as $person) {
        if (!empty($person['user_id'])) {
            self::upsertEdge(
                'user',
                $person['user_id'],
                'doc',
                $contentDocumentId,
                ContentGraphEdge::EDGE_APPEARS_IN,
                $person['similarity'] ?? 0.7
            );
            $count++;
        }
    }
    return $count;
}
```

- [ ] **Step 3: Create FaceDiscoveryService**

Write to `/var/www/tajiri.zimasystems.com/app/Services/ContentEngine/FaceDiscoveryService.php`:

```php
<?php

namespace App\Services\ContentEngine;

use Illuminate\Support\Facades\Log;

class FaceDiscoveryService
{
    /**
     * Discover faces in media and create graph edges.
     *
     * @param int $contentDocumentId
     * @param array $mediaDescriptions The existing media_descriptions from enrichment
     * @return array People array for inclusion in media_descriptions
     */
    public static function discoverInMedia(int $contentDocumentId, array $mediaDescriptions): array
    {
        $people = [];
        $seenUsers = []; // user_id => highest similarity (for deduplication across frames)

        try {
            // Process images
            $images = $mediaDescriptions['images'] ?? [];
            foreach ($images as $image) {
                $path = $image['path'] ?? null;
                if (!$path || !file_exists($path)) {
                    continue;
                }

                $matches = FaceEmbeddingService::getMatchesForImage($path);
                foreach ($matches as $match) {
                    $userId = $match['user_id'] ?? null;
                    $similarity = $match['similarity'] ?? 0.0;

                    if ($userId && (!isset($seenUsers[$userId]) || $similarity > $seenUsers[$userId])) {
                        $seenUsers[$userId] = $similarity;
                    }

                    $people[] = [
                        'user_id' => $userId,
                        'source' => 'image',
                        'media_id' => $image['media_id'] ?? null,
                        'similarity' => $similarity,
                        'bbox' => $match['bbox'] ?? null,
                    ];
                }
            }

            // Process video keyframes
            $keyframes = $mediaDescriptions['video']['keyframes'] ?? [];
            foreach ($keyframes as $framePath) {
                if (!$framePath || !file_exists($framePath)) {
                    continue;
                }

                $matches = FaceEmbeddingService::getMatchesForImage($framePath);
                foreach ($matches as $match) {
                    $userId = $match['user_id'] ?? null;
                    $similarity = $match['similarity'] ?? 0.0;

                    if ($userId) {
                        if (isset($seenUsers[$userId]) && $seenUsers[$userId] >= $similarity) {
                            // Already seen this user with higher or equal similarity — skip
                            continue;
                        }
                        $seenUsers[$userId] = $similarity;
                    }

                    $people[] = [
                        'user_id' => $userId,
                        'source' => 'video_frame',
                        'media_id' => $mediaDescriptions['video']['media_id'] ?? null,
                        'similarity' => $similarity,
                        'bbox' => $match['bbox'] ?? null,
                    ];
                }
            }

            // Create APPEARS_IN graph edges for matched users
            if (!empty($people)) {
                // Deduplicate: only create edges for unique users with highest similarity
                $uniquePeople = [];
                foreach ($seenUsers as $userId => $similarity) {
                    $uniquePeople[] = ['user_id' => $userId, 'similarity' => $similarity];
                }

                $edgeCount = GraphEdgeService::buildAppearsInEdges($contentDocumentId, $uniquePeople);
                Log::info('FaceDiscovery: completed', [
                    'doc_id' => $contentDocumentId,
                    'faces_detected' => count($people),
                    'users_matched' => count($seenUsers),
                    'edges_created' => $edgeCount,
                ]);
            }

        } catch (\Exception $e) {
            Log::warning('FaceDiscovery: discoverInMedia failed', [
                'doc_id' => $contentDocumentId,
                'error' => $e->getMessage(),
            ]);
            // Non-blocking — return whatever we found
        }

        return $people;
    }
}
```

- [ ] **Step 4: Integrate into MediaEnrichmentService**

Read the current `enrich()` method to find the exact insertion point (after image/video/audio analysis, before the final save):

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'grep -n "SyncToTypesense\|GenerateEmbedding\|media_descriptions\|media_text\|mediaTextParts\|update\(\[" /var/www/tajiri.zimasystems.com/app/Services/ContentEngine/MediaEnrichmentService.php'
```

Insert the face discovery call **after** all media analysis and **before** the `$contentDocument->update()` call. The exact code to insert:

```php
// --- Face Discovery ---
try {
    $people = FaceDiscoveryService::discoverInMedia($contentDocument->id, $mediaDescriptions);
    if (!empty($people)) {
        $mediaDescriptions['people'] = $people;
        foreach ($people as $person) {
            if (!empty($person['user_id'])) {
                $mediaTextParts[] = "[Person: user#{$person['user_id']} appears in this content]";
            }
        }
    }
} catch (\Exception $e) {
    Log::warning('MediaEnrichment: Face discovery failed (non-blocking)', [
        'doc_id' => $contentDocument->id,
        'error' => $e->getMessage(),
    ]);
}
```

Also add the import at the top of the file:

```php
use App\Services\ContentEngine\FaceDiscoveryService;
```

- [ ] **Step 5: Add APPEARS_IN to content_rank.py**

Read the current edge type weights in content_rank.py:

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'grep -n "EDGE_\|edge_type\|weight" /opt/tajiri-graph/content_rank.py | head -20'
```

Add `APPEARS_IN` to the edge type weight dictionary with weight 1.5. The exact location depends on how the weights are structured in the file.

- [ ] **Step 6: Verify all files load without errors**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'cd /var/www/tajiri.zimasystems.com && php8.3 artisan tinker --execute="
echo class_exists(\App\Services\ContentEngine\FaceDiscoveryService::class) ? \"FaceDiscoveryService OK\" : \"FAIL\";
echo class_exists(\App\Services\ContentEngine\FaceEmbeddingService::class) ? \"FaceEmbeddingService OK\" : \"FAIL\";
echo defined(\"\App\Models\ContentGraphEdge::EDGE_APPEARS_IN\") ? \"APPEARS_IN const OK\" : \"FAIL\";
"'
```

Expected: All OK

- [ ] **Step 7: Commit**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'cd /var/www/tajiri.zimasystems.com && git add app/Services/ContentEngine/FaceDiscoveryService.php app/Services/ContentEngine/GraphEdgeService.php app/Services/ContentEngine/MediaEnrichmentService.php app/Models/ContentGraphEdge.php && git commit -m "feat(face): add FaceDiscoveryService, APPEARS_IN edges, integrate into media enrichment"'
```

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'cd /opt/tajiri-graph && git add content_rank.py && git commit -m "feat: add APPEARS_IN edge type weight 1.5"'
```

---

## Task 6: Backend Controller Integration + Supervisor + Health Check

**Files:**
- Modify: `app/Http/Controllers/Api/UserProfileController.php` (on server)
- Modify: `app/Console/Commands/ContentHealthCheck.php` (on server)
- Modify: `/etc/supervisor/conf.d/tajiri-workers.conf` (on server)

**Context:** The profile photo update and registration both live in `UserProfileController` (NOT separate files). The `updateProfilePhoto()` method stores the photo and returns the URL — we add a non-blocking call to `FaceEmbeddingService::extractAndStore()` after the photo is saved. The `register()` method needs to accept an optional `profile_photo` file in the multipart request. Health check follows the existing `$this->check('Name', fn)` pattern. The face service runs as a gunicorn process (not a queue worker).

**Important:** The `register()` method currently uses `application/json` content type. To support file upload, it needs to also handle `multipart/form-data`. The simplest approach: check if `$request->hasFile('profile_photo')` and process it after user creation.

- [ ] **Step 1: Add FaceEmbeddingService call to updateProfilePhoto()**

Read the current method:

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'grep -n "function updateProfilePhoto" -A 40 /var/www/tajiri.zimasystems.com/app/Http/Controllers/Api/UserProfileController.php'
```

After the line that updates the profile photo path (something like `$profile->update(['profile_photo_path' => $path])`), add:

```php
// Extract face embedding (non-blocking)
try {
    $fullPath = storage_path('app/public/' . $path);
    $bbox = $request->input('face_bbox') ? json_decode($request->input('face_bbox'), true) : null;
    FaceEmbeddingService::extractAndStore($id, $fullPath, $bbox, 'profile_update');
} catch (\Exception $e) {
    Log::warning('Profile photo: face embedding extraction failed', ['user_id' => $id, 'error' => $e->getMessage()]);
}
```

Add the import at the top:

```php
use App\Services\ContentEngine\FaceEmbeddingService;
```

- [ ] **Step 2: Add profile photo handling to register()**

Read the current register method:

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'grep -n "function register" -A 80 /var/www/tajiri.zimasystems.com/app/Http/Controllers/Api/UserProfileController.php'
```

After the user/profile is created and before the response, add:

```php
// Handle profile photo if provided (from registration with face validation)
if ($request->hasFile('profile_photo')) {
    $photoPath = $request->file('profile_photo')->store('profile-photos', 'public');
    $profile->update(['profile_photo_path' => $photoPath]);

    // Extract face embedding
    try {
        $fullPath = storage_path('app/public/' . $photoPath);
        $bbox = $request->input('face_bbox') ? json_decode($request->input('face_bbox'), true) : null;
        FaceEmbeddingService::extractAndStore($user->id, $fullPath, $bbox, 'registration');
    } catch (\Exception $e) {
        Log::warning('Registration: face embedding extraction failed', ['user_id' => $user->id, 'error' => $e->getMessage()]);
    }
}
```

- [ ] **Step 3: Add face service health check**

Read the current health check to find where to add:

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'grep -n "check(" /var/www/tajiri.zimasystems.com/app/Console/Commands/ContentHealthCheck.php | tail -5'
```

Add after the last `$this->check(...)` call:

```php
$allOk &= $this->check('Face Discovery Service', function () {
    $response = Http::timeout(5)->get('http://127.0.0.1:8300/health');
    if (!$response->successful()) {
        throw new \Exception('Face service not responding');
    }
    $data = $response->json();
    $count = $data['embeddings_count'] ?? 0;
    return "OK ({$count} embeddings, model: {$data['model']})";
});
```

Add import if not present:

```php
use Illuminate\Support\Facades\Http;
```

- [ ] **Step 4: Add face service to Supervisor config**

Append to `/etc/supervisor/conf.d/tajiri-workers.conf`:

```ini

[program:tajiri-face-service]
command=gunicorn --bind 127.0.0.1:8300 --workers 2 --timeout 120 app:app
directory=/opt/tajiri-face
autostart=true
autorestart=true
numprocs=1
redirect_stderr=true
stdout_logfile=/var/log/tajiri/face-service.log
environment=FLASK_ENV=production,DB_HOST=127.0.0.1,DB_PORT=5432,DB_NAME=tajiri,DB_USER=postgres,DB_PASSWORD=%(ENV_TAJIRI_DB_PASSWORD)s
```

Set the DB password in supervisor's environment so `%(ENV_TAJIRI_DB_PASSWORD)s` resolves:

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'grep -q TAJIRI_DB_PASSWORD /etc/default/supervisor || echo "TAJIRI_DB_PASSWORD=postgres" >> /etc/default/supervisor'
```

Then reload supervisor:

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'systemctl restart supervisor && sleep 3 && supervisorctl status tajiri-face-service'
```

Expected: `tajiri-face-service RUNNING`

- [ ] **Step 5: Test face service health endpoint**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'curl -s http://127.0.0.1:8300/health'
```

Expected: `{"status": "ok", "embeddings_count": 0, "model": "dlib_128d"}`

Note: The health endpoint will fail with a database error until the migration (Task 2) is run. If running tasks out of order, ensure Task 2 completes first.

- [ ] **Step 6: Test face embedding extraction with a real profile photo**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'curl -s -X POST http://127.0.0.1:8300/extract-embedding -H "Content-Type: application/json" -d "{\"image_path\": \"$(ls /var/www/tajiri.zimasystems.com/storage/app/public/profile-photos/*.jpg 2>/dev/null | head -1)\"}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f\"face_count={d.get(\"face_count\")}, confidence={d.get(\"confidence\")}, embedding_len={len(d.get(\"embedding\",[]))}\")"'
```

Expected: `face_count=1, confidence=0.XXXX, embedding_len=128`

- [ ] **Step 7: Commit**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'cd /var/www/tajiri.zimasystems.com && git add app/Http/Controllers/Api/UserProfileController.php app/Console/Commands/ContentHealthCheck.php && git commit -m "feat(face): integrate FaceEmbeddingService into ProfileController + register + health check"'
```

---

## Task 7: Backfill Command — Extract Face Embeddings from Existing Profiles

**Files:**
- Create: `app/Console/Commands/ExtractFaceEmbeddings.php` (on server)

**Context:** Artisan command `face:extract-from-profiles` scans all users with `profile_photo_path`, sends each to the face service, and stores embeddings. Supports `--batch-size`, `--delay` (ms between requests), and `--user-id` (single user). Follow the existing `EnrichMedia` command pattern for options/progress output.

- [ ] **Step 1: Create the backfill command**

Write to `/var/www/tajiri.zimasystems.com/app/Console/Commands/ExtractFaceEmbeddings.php`:

```php
<?php

namespace App\Console\Commands;

use App\Models\UserProfile;
use App\Services\ContentEngine\FaceEmbeddingService;
use Illuminate\Console\Command;

class ExtractFaceEmbeddings extends Command
{
    protected $signature = 'face:extract-from-profiles
        {--batch-size=50 : Number of profiles to process per batch}
        {--delay=200 : Delay in ms between requests}
        {--user-id= : Process a single user}';

    protected $description = 'Extract face embeddings from existing user profile photos';

    public function handle(): int
    {
        $batchSize = (int) $this->option('batch-size');
        $delay = (int) $this->option('delay');
        $userId = $this->option('user-id');

        if ($userId) {
            $this->processSingleUser((int) $userId);
            return 0;
        }

        $query = UserProfile::whereNotNull('profile_photo_path')
            ->where('profile_photo_path', '!=', '')
            ->whereDoesntHave('faceEmbeddings', function ($q) {
                $q->where('is_primary', true);
            });

        $total = $query->count();
        $this->info("Found {$total} profiles without face embeddings");

        if ($total === 0) {
            return 0;
        }

        $bar = $this->output->createProgressBar($total);
        $bar->start();

        $success = 0;
        $failed = 0;
        $noFace = 0;

        $query->orderBy('id')->chunk($batchSize, function ($profiles) use (&$success, &$failed, &$noFace, $delay, $bar) {
            foreach ($profiles as $profile) {
                $path = storage_path('app/public/' . $profile->profile_photo_path);

                if (!file_exists($path)) {
                    $failed++;
                    $bar->advance();
                    continue;
                }

                $result = FaceEmbeddingService::extractAndStore(
                    $profile->user_id ?? $profile->id,
                    $path,
                    null,
                    'registration'
                );

                if ($result) {
                    $success++;
                } else {
                    $noFace++;
                }

                $bar->advance();

                if ($delay > 0) {
                    usleep($delay * 1000);
                }
            }
        });

        $bar->finish();
        $this->newLine(2);
        $this->info("Done: {$success} embeddings stored, {$noFace} no face detected, {$failed} file errors");

        return 0;
    }

    private function processSingleUser(int $userId): void
    {
        $profile = UserProfile::find($userId);
        if (!$profile || !$profile->profile_photo_path) {
            $this->error("User {$userId} not found or has no profile photo");
            return;
        }

        $path = storage_path('app/public/' . $profile->profile_photo_path);
        $this->info("Processing user {$userId}: {$path}");

        $result = FaceEmbeddingService::extractAndStore($userId, $path, null, 'registration');
        $this->info($result ? 'Embedding stored successfully' : 'No face detected or extraction failed');
    }
}
```

**Note:** The `whereDoesntHave('faceEmbeddings')` call requires a `faceEmbeddings` relationship on `UserProfile`. Add it:

```php
// In app/Models/UserProfile.php, add:
public function faceEmbeddings()
{
    return $this->hasMany(\App\Models\FaceEmbedding::class, 'user_id');
}
```

- [ ] **Step 2: Add faceEmbeddings relationship to UserProfile model**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'grep -n "function " /var/www/tajiri.zimasystems.com/app/Models/UserProfile.php | tail -5'
```

Add the relationship method before the closing `}` of the class.

- [ ] **Step 3: Test the backfill command with a single user**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'cd /var/www/tajiri.zimasystems.com && php8.3 artisan face:extract-from-profiles --user-id=1'
```

Expected: `Processing user 1: /var/www/.../storage/app/public/profile-photos/xxx.jpg` then `Embedding stored successfully` or `No face detected`

- [ ] **Step 4: Verify embedding was stored**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'cd /var/www/tajiri.zimasystems.com && php8.3 artisan tinker --execute="echo \App\Models\FaceEmbedding::where(\"is_primary\", true)->count() . \" primary embeddings stored\";"'
```

Expected: `1 primary embeddings stored` (or more if run on multiple users)

- [ ] **Step 5: Commit**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'cd /var/www/tajiri.zimasystems.com && git add app/Console/Commands/ExtractFaceEmbeddings.php app/Models/UserProfile.php && git commit -m "feat(face): add face:extract-from-profiles backfill command"'
```

---

## Task 8: End-to-End Backend Test

**Files:** None (testing only)

**Context:** Before moving to frontend, verify the full backend pipeline works: face service extracts embeddings, stores them, and detect-and-match identifies faces in photos. Run the backfill on all existing profiles, then test matching against a post photo.

- [ ] **Step 1: Run full health check**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'cd /var/www/tajiri.zimasystems.com && php8.3 artisan content:health-check'
```

Expected: Face Discovery Service shows OK with embedding count.

- [ ] **Step 2: Run backfill on all profiles**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'cd /var/www/tajiri.zimasystems.com && php8.3 artisan face:extract-from-profiles --batch-size=20 --delay=200'
```

Expected: Progress bar, then summary of embeddings stored / no face / errors.

- [ ] **Step 3: Test detect-and-match on a post photo**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'curl -s -X POST http://127.0.0.1:8300/detect-and-match -H "Content-Type: application/json" -d "{\"image_path\": \"$(ls /var/www/tajiri.zimasystems.com/storage/app/public/post-media/*.jpg 2>/dev/null | head -1)\"}" | python3 -m json.tool'
```

Expected: JSON with `faces` array, `face_count`, `matched_count`. If the photo contains faces of registered users who had embeddings extracted, `user_id` will be non-null.

- [ ] **Step 4: Test media enrichment with face discovery on a single post**

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'cd /var/www/tajiri.zimasystems.com && php8.3 artisan content:enrich-media --post-id=$(php8.3 artisan tinker --execute="echo \App\Models\Post::whereHas(\"media\")->latest(\"id\")->value(\"id\");" 2>/dev/null) --force'
```

Expected: Post enriched. Check if `people` key appears in media_descriptions:

```bash
sshpass -p 'ZimaBlueApps' ssh -o StrictHostKeyChecking=no root@172.240.241.180 'cd /var/www/tajiri.zimasystems.com && php8.3 artisan tinker --execute="
\$doc = \App\Models\ContentDocument::where(\"source_type\", \"post\")->whereNotNull(\"media_descriptions\")->latest(\"id\")->first();
echo \"people: \" . json_encode(\$doc->media_descriptions[\"people\"] ?? \"none\");
"'
```

---

## Task 9: Frontend — FaceValidator + AppStrings + Registration Photo Step + Profile Screen

**Files:**
- Create: `lib/utils/face_validator.dart` (local)
- Create: `lib/screens/registration/steps/profile_photo_step.dart` (local)
- Modify: `lib/l10n/app_strings.dart` (local)
- Modify: `lib/screens/registration/registration_screen.dart` (local)
- Modify: `lib/models/registration_models.dart` (local)
- Modify: `lib/services/user_service.dart` (local)
- Modify: `lib/services/profile_service.dart` (local)
- Modify: `lib/screens/profile/profile_screen.dart` (local)

**Context:** This is all Flutter/Dart work on the local machine at `/Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND`. The project already has `google_ml_kit: ^0.20.1` installed. The registration screen uses a `PageController` with step widgets. Each step receives `state` (RegistrationState), `onNext`, `onBack` callbacks. Follow the `BioStep` pattern exactly.

**Design patterns:**
- Static color constants: `_primary = Color(0xFF1A1A1A)`, `_secondaryText = Color(0xFF666666)`
- `SingleChildScrollView` for content
- `FilledButton` for CTA
- Error states as nullable Strings, shown below relevant widget
- All UI text via `AppStringsScope.of(context)` bilingual getters
- `image_picker` for camera/gallery (already in pubspec)

- [ ] **Step 1: Add bilingual strings to AppStrings**

Read the current app_strings.dart to find the right place to add (near photo/registration strings):

```bash
grep -n "stepBio\|stepPhone\|photoUpdated" /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/l10n/app_strings.dart
```

Add these getters to the `AppStrings` class (after the existing step-related strings):

```dart
String get stepPhoto => isSwahili ? 'Picha ya Uso' : 'Face Photo';
String get takeYourPhoto => isSwahili ? 'Piga picha yako' : 'Take your photo';
String get takeYourPhotoDesc => isSwahili
    ? 'Tunahitaji picha inayoonyesha uso wako vizuri'
    : 'We need a photo that clearly shows your face';
String get faceNotDetected => isSwahili
    ? 'Picha yako haionyeshi uso. Tafadhali piga picha inayoonyesha uso wako vizuri'
    : 'Your photo doesn\'t show a face. Please take a photo that clearly shows your face';
String get multipleFacesDetected => isSwahili
    ? 'Picha ina watu wengi. Tafadhali piga picha yako peke yako'
    : 'Photo has multiple people. Please take a photo of just yourself';
String get takePhotoBtn => isSwahili ? 'Piga Picha' : 'Take Photo';
String get chooseFromGallery => isSwahili ? 'Chagua kutoka Picha' : 'Choose from Gallery';
String get faceDetected => isSwahili ? 'Uso umegunduliwa!' : 'Face detected!';
```

- [ ] **Step 2: Create FaceValidator utility**

Write to `lib/utils/face_validator.dart`:

```dart
import 'dart:io';
import 'dart:ui';
import 'package:google_ml_kit/google_ml_kit.dart';

class FaceValidationResult {
  final bool isValid;
  final String? errorKey; // 'no_face' or 'multiple_faces'
  final Rect? faceBounds;
  final int faceCount;

  const FaceValidationResult({
    required this.isValid,
    this.errorKey,
    this.faceBounds,
    required this.faceCount,
  });
}

class FaceValidator {
  /// Strict validation for registration — exactly 1 face required.
  static Future<FaceValidationResult> validate(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final faceDetector = GoogleMlKit.vision.faceDetector(
        FaceDetectorOptions(
          enableLandmarks: false,
          enableContours: false,
          enableClassification: false,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );

      final faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      if (faces.isEmpty) {
        return const FaceValidationResult(
          isValid: false,
          errorKey: 'no_face',
          faceCount: 0,
        );
      }

      if (faces.length > 1) {
        return FaceValidationResult(
          isValid: false,
          errorKey: 'multiple_faces',
          faceCount: faces.length,
        );
      }

      final face = faces.first;
      return FaceValidationResult(
        isValid: true,
        faceBounds: face.boundingBox,
        faceCount: 1,
      );
    } catch (e) {
      // ML Kit unavailable — allow upload without face data
      return const FaceValidationResult(
        isValid: true,
        errorKey: null,
        faceCount: 0,
      );
    }
  }

  /// Lenient detection for profile updates — returns largest face bbox or null.
  static Future<Rect?> detectLargestFace(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final faceDetector = GoogleMlKit.vision.faceDetector(
        FaceDetectorOptions(
          enableLandmarks: false,
          enableContours: false,
          enableClassification: false,
          performanceMode: FaceDetectorMode.fast,
        ),
      );

      final faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      if (faces.isEmpty) return null;

      // Find largest face by bounding box area
      Face largest = faces.first;
      double maxArea = largest.boundingBox.width * largest.boundingBox.height;
      for (final face in faces.skip(1)) {
        final area = face.boundingBox.width * face.boundingBox.height;
        if (area > maxArea) {
          maxArea = area;
          largest = face;
        }
      }

      return largest.boundingBox;
    } catch (e) {
      return null;
    }
  }
}
```

- [ ] **Step 3: Add profilePhotoPath and faceBbox to RegistrationState**

Read `lib/models/registration_models.dart` and add to the `RegistrationState` class:

```dart
// Face photo (after Bio step)
String? profilePhotoPath; // File path — survives Hive persistence
Map<String, int>? faceBbox; // {x, y, width, height} from ML Kit
```

Also add to `toJson()`:

```dart
if (profilePhotoPath != null) 'profile_photo_path': profilePhotoPath,
if (faceBbox != null) 'face_bbox': faceBbox,
```

And to `fromJson()`:

```dart
profilePhotoPath = json['profile_photo_path'] as String?;
faceBbox = json['face_bbox'] != null ? Map<String, int>.from(json['face_bbox']) : null;
```

Add an `isPhotoComplete` getter:

```dart
bool get isPhotoComplete => profilePhotoPath != null;
```

- [ ] **Step 4: Create ProfilePhotoStep widget**

Write to `lib/screens/registration/steps/profile_photo_step.dart`:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../l10n/app_strings_scope.dart';
import '../../../models/registration_models.dart';
import '../../../utils/face_validator.dart';

class ProfilePhotoStep extends StatefulWidget {
  final RegistrationState state;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const ProfilePhotoStep({
    super.key,
    required this.state,
    required this.onNext,
    this.onBack,
  });

  @override
  State<ProfilePhotoStep> createState() => _ProfilePhotoStepState();
}

class _ProfilePhotoStepState extends State<ProfilePhotoStep> {
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);
  static const Color _successGreen = Color(0xFF4CAF50);

  final ImagePicker _picker = ImagePicker();

  File? _selectedPhoto;
  bool _isValidating = false;
  bool _faceDetected = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Restore from state if resuming
    if (widget.state.profilePhotoPath != null) {
      final file = File(widget.state.profilePhotoPath!);
      if (file.existsSync()) {
        _selectedPhoto = file;
        _faceDetected = true;
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );
      if (image == null) return;

      setState(() {
        _isValidating = true;
        _errorMessage = null;
        _faceDetected = false;
      });

      final file = File(image.path);
      final result = await FaceValidator.validate(file);

      if (!mounted) return;

      if (result.isValid) {
        setState(() {
          _selectedPhoto = file;
          _faceDetected = true;
          _isValidating = false;
        });

        // Save to state
        widget.state.profilePhotoPath = file.path;
        if (result.faceBounds != null) {
          widget.state.faceBbox = {
            'x': result.faceBounds!.left.round(),
            'y': result.faceBounds!.top.round(),
            'width': result.faceBounds!.width.round(),
            'height': result.faceBounds!.height.round(),
          };
        }
      } else {
        final s = AppStringsScope.of(context);
        setState(() {
          _selectedPhoto = file;
          _faceDetected = false;
          _isValidating = false;
          _errorMessage = result.errorKey == 'no_face'
              ? (s?.faceNotDetected ?? 'No face detected')
              : (s?.multipleFacesDetected ?? 'Multiple faces detected');
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isValidating = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  void _validateAndProceed() {
    if (_faceDetected && _selectedPhoto != null) {
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),

          // Title
          Text(
            s?.takeYourPhoto ?? 'Take your photo',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            s?.takeYourPhotoDesc ?? 'We need a photo that clearly shows your face',
            style: const TextStyle(fontSize: 14, color: _secondaryText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Photo preview area
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                  border: Border.all(
                    color: _faceDetected ? _successGreen : Colors.grey[300]!,
                    width: _faceDetected ? 3 : 1,
                  ),
                  image: _selectedPhoto != null
                      ? DecorationImage(
                          image: FileImage(_selectedPhoto!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _selectedPhoto == null
                    ? const Icon(Icons.person_rounded, size: 80, color: Colors.grey)
                    : null,
              ),
              if (_isValidating)
                const CircularProgressIndicator(),
              if (_faceDetected)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: _successGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 20),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Face detected success message
          if (_faceDetected)
            Text(
              s?.faceDetected ?? 'Face detected!',
              style: const TextStyle(color: _successGreen, fontWeight: FontWeight.w600),
            ),

          // Error message
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: 32),

          // Camera button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _isValidating ? null : () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_rounded),
              label: Text(s?.takePhotoBtn ?? 'Take Photo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: _primary),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Gallery button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _isValidating ? null : () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_rounded),
              label: Text(s?.chooseFromGallery ?? 'Choose from Gallery'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _secondaryText,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: Colors.grey[400]!),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Continue button (only enabled when face detected)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _faceDetected ? _validateAndProceed : null,
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                s?.continueBtn ?? 'Continue',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Insert ProfilePhotoStep into registration flow**

Read `lib/screens/registration/registration_screen.dart` and modify:

1. Add import at top:
```dart
import 'steps/profile_photo_step.dart';
```

2. In `_stepTitles()`, add after the Bio title:
```dart
s.stepPhoto, // index 1
```

3. In `_buildPages()`, add after BioStep widget:
```dart
ProfilePhotoStep(
  state: _registrationState,
  onNext: _nextStep,
  onBack: _previousStep,
),
```

All other steps shift down by 1 index. The conditional A-Level logic indices will need updating — wherever a step index is referenced (e.g., `_currentStep == 5` for education path), increment by 1.

- [ ] **Step 6: Modify UserService.register() for multipart photo upload**

Read the current `register()` method in `lib/services/user_service.dart`. Currently it sends JSON. Modify to use multipart if a photo is provided:

Replace the entire `register()` method body with:

```dart
Future<UserRegistrationResult> register(RegistrationState profile) async {
  try {
    late final http.Response response;

    if (profile.profilePhotoPath != null) {
      // Multipart request when photo is provided
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/users/register'),
      );

      final jsonData = profile.toJson();
      jsonData.forEach((key, value) {
        if (value != null && key != 'profile_photo_path' && key != 'face_bbox') {
          request.fields[key] = value is String ? value : jsonEncode(value);
        }
      });

      request.files.add(await http.MultipartFile.fromPath(
        'profile_photo',
        profile.profilePhotoPath!,
      ));

      if (profile.faceBbox != null) {
        request.fields['face_bbox'] = jsonEncode(profile.faceBbox);
      }

      final streamedResponse = await request.send();
      response = await http.Response.fromStream(streamedResponse);
    } else {
      // Original JSON request (no photo)
      response = await http.post(
        Uri.parse('$_baseUrl/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(profile.toJson()),
      );
    }

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 && data['success'] == true) {
      final responseData = data['data'];
      final id = responseData is Map ? responseData['id'] : null;
      final userId = id is int ? id : (id is num ? id.toInt() : null);
      final Map<String, dynamic>? profileMap = responseData is Map<String, dynamic>
          ? Map<String, dynamic>.from(responseData)
          : null;
      final accessToken = profileMap?['access_token'] ?? profileMap?['token'] ?? data['access_token'] ?? data['token'];
      return UserRegistrationResult(
        success: true,
        userId: userId,
        message: data['message'] as String?,
        profileData: profileMap,
        accessToken: accessToken is String ? accessToken : accessToken?.toString(),
      );
    } else if (response.statusCode == 422) {
      final errors = data['errors'] as Map<String, dynamic>?;
      String errorMessage = data['message'] ?? 'Validation failed';
      if (errors != null && errors.containsKey('phone_number')) {
        errorMessage = 'Nambari hii ya simu imeshasajiliwa';
      }
      return UserRegistrationResult(
        success: false,
        message: errorMessage,
        errors: errors,
      );
    } else {
      return UserRegistrationResult(
        success: false,
        message: data['message'] ?? 'Registration failed',
      );
    }
  } catch (e) {
    return UserRegistrationResult(
      success: false,
      message: 'Imeshindwa kuwasiliana na seva: $e',
    );
  }
}
```

- [ ] **Step 7: Add faceBbox param to ProfileService.updateProfilePhoto()**

Modify `lib/services/profile_service.dart`:

Replace the entire `updateProfilePhoto()` method with:

```dart
Future<PhotoUpdateResult> updateProfilePhoto({
  required int userId,
  required File photo,
  Map<String, int>? faceBbox,
}) async {
  try {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/users/$userId/profile-photo'),
    );

    request.files.add(await http.MultipartFile.fromPath('photo', photo.path));

    if (faceBbox != null) {
      request.fields['face_bbox'] = jsonEncode(faceBbox);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return PhotoUpdateResult(
        success: true,
        photoUrl: data['data']['profile_photo_url'],
        message: data['message'],
      );
    }
    return PhotoUpdateResult(success: false, message: data['message'] ?? 'Failed to update photo');
  } catch (e) {
    return PhotoUpdateResult(success: false, message: 'Error: $e');
  }
}
```

Note: `profile_service.dart` already imports `dart:convert` (for `jsonDecode`), so `jsonEncode` is available.

- [ ] **Step 8: Add optional face detection to profile_screen.dart photo update**

In `lib/screens/profile/profile_screen.dart`, modify `_updateProfilePhoto()`:

After the image picker returns and before the upload, add face detection:

```dart
final XFile? image = await _imagePicker.pickImage(...);
if (image == null) return;

setState(() => _isUploadingPhoto = true);

// Optional face detection (non-blocking)
Map<String, int>? faceBbox;
try {
  final bounds = await FaceValidator.detectLargestFace(File(image.path));
  if (bounds != null) {
    faceBbox = {
      'x': bounds.left.round(),
      'y': bounds.top.round(),
      'width': bounds.width.round(),
      'height': bounds.height.round(),
    };
  }
} catch (_) {}

final result = await _profileService.updateProfilePhoto(
  userId: widget.userId,
  photo: File(image.path),
  faceBbox: faceBbox,
);
```

Add import at top:
```dart
import '../../utils/face_validator.dart';
```

- [ ] **Step 9: Run flutter analyze on all modified files**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/utils/face_validator.dart lib/screens/registration/steps/profile_photo_step.dart lib/screens/registration/registration_screen.dart lib/models/registration_models.dart lib/services/user_service.dart lib/services/profile_service.dart lib/screens/profile/profile_screen.dart lib/l10n/app_strings.dart
```

Expected: Zero errors. Info-level warnings are acceptable.

- [ ] **Step 10: Commit**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && git add lib/utils/face_validator.dart lib/screens/registration/steps/profile_photo_step.dart lib/screens/registration/registration_screen.dart lib/models/registration_models.dart lib/services/user_service.dart lib/services/profile_service.dart lib/screens/profile/profile_screen.dart lib/l10n/app_strings.dart && git commit -m "feat(face): add FaceValidator, registration photo step, profile face detection"
```

---

## Verification Checklist

After all tasks complete:

- [ ] Face service running: `curl http://127.0.0.1:8300/health` returns OK with embedding count
- [ ] Health check passes: `php8.3 artisan content:health-check` — all green
- [ ] Backfill works: `php8.3 artisan face:extract-from-profiles --user-id=1` stores embedding
- [ ] Face matching works: detect-and-match returns `user_id` for known faces
- [ ] Media enrichment includes faces: `people` key in `media_descriptions` after enrichment
- [ ] APPEARS_IN graph edges: `SELECT COUNT(*) FROM content_graph_edges WHERE edge_type = 'APPEARS_IN'`
- [ ] Frontend compiles: `flutter analyze` — zero errors
- [ ] Registration flow: Photo step appears after Bio, enforces exactly 1 face
- [ ] Profile photo update: Sends face_bbox when face detected
