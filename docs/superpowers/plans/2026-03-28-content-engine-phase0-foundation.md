# Content Engine Phase 0: Foundation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install all infrastructure (Typesense, pgvector, embedding service), create all database tables, switch queue driver to Redis, and verify every subsystem is operational — before any application code is written.

**Architecture:** This phase sets up the foundation that all subsequent phases depend on. Nothing user-facing changes. All work is on the backend server (`root@zima-uat.site`). After this phase: PostgreSQL has the new tables, Typesense is running with the collection schema, pgvector is enabled, Python environments exist for embedding and ContentRank, Redis is confirmed as queue driver, and a health check command verifies everything.

**Tech Stack:** PostgreSQL + pgvector, Typesense 27.x, Redis, Python 3 + Flask + sentence-transformers + NetworkX, Laravel 12 queue on Redis, Supervisor

**Server access:** `sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@zima-uat.site`

**Spec reference:** `docs/superpowers/specs/2026-03-28-tajiri-content-engine-design.md`

---

## File Map

### Backend (on server: /var/www/html/tajiri/)

| Action | File | Purpose |
|---|---|---|
| Create | `database/migrations/2026_03_28_000001_create_content_documents_table.php` | Unified document model |
| Create | `database/migrations/2026_03_28_000002_create_content_graph_edges_table.php` | Content graph edges |
| Create | `database/migrations/2026_03_28_000003_create_scoring_config_table.php` | Tunable scoring weights |
| Create | `database/migrations/2026_03_28_000004_create_content_categories_table.php` | Category controlled vocabulary |
| Create | `database/migrations/2026_03_28_000005_create_user_events_table.php` | Engagement event storage |
| Create | `database/migrations/2026_03_28_000006_create_trending_digests_table.php` | AI trending digests |
| Create | `database/migrations/2026_03_28_000007_create_creator_coaching_table.php` | AI creator coaching |
| Create | `database/migrations/2026_03_28_000008_create_feature_flags_table.php` | Feature flag system |
| Create | `database/migrations/2026_03_28_000009_create_content_tier_history_table.php` | Tier change audit log |
| Create | `app/Models/ContentDocument.php` | Eloquent model for content_documents |
| Create | `app/Models/ContentGraphEdge.php` | Eloquent model for content_graph_edges |
| Create | `app/Models/ScoringConfig.php` | Eloquent model for scoring_config |
| Create | `app/Models/ContentCategory.php` | Eloquent model for content_categories |
| Create | `app/Models/UserEvent.php` | Eloquent model for user_events |
| Create | `app/Models/TrendingDigest.php` | Eloquent model for trending_digests |
| Create | `app/Models/CreatorCoaching.php` | Eloquent model for creator_coaching |
| Create | `app/Models/FeatureFlag.php` | Eloquent model for feature_flags |
| Create | `app/Models/ContentTierHistory.php` | Eloquent model for content_tier_history |
| Create | `config/content-engine.php` | Central config for Typesense, embedding service, scoring |
| Create | `app/Console/Commands/ContentHealthCheck.php` | Artisan command: content:health-check |
| Modify | `config/queue.php` | Switch default driver to 'redis' |

### Infrastructure (on server)

| Action | Path | Purpose |
|---|---|---|
| Install | `/opt/typesense/` | Typesense binary + data dir |
| Create | `/etc/systemd/system/typesense.service` | Typesense systemd service |
| Install | pgvector extension | `CREATE EXTENSION vector` |
| Create | `/opt/tajiri-embedding/` | Embedding microservice |
| Create | `/opt/tajiri-embedding/server.py` | Flask embedding API |
| Create | `/opt/tajiri-embedding/requirements.txt` | Python dependencies |
| Create | `/etc/systemd/system/tajiri-embedding.service` | Embedding systemd service |
| Create | `/opt/tajiri-graph/` | ContentRank environment |
| Create | `/opt/tajiri-graph/content_rank.py` | PageRank computation script |
| Create | `/opt/tajiri-graph/requirements.txt` | Python dependencies |
| Create | `/opt/tajiri-graph/.env` | Database credentials |

---

## Task 1: Install and Start Typesense

**Files:**
- Create: `/opt/typesense/` directory
- Create: `/etc/systemd/system/typesense.service`

- [ ] **Step 1: Download and install Typesense**

```bash
ssh root@zima-uat.site
mkdir -p /opt/typesense /var/data/typesense
chown -R www-data:www-data /var/data/typesense
cd /opt/typesense
curl -O https://dl.typesense.org/releases/27.1/typesense-server-27.1-linux-amd64.tar.gz
tar -xzf typesense-server-27.1-linux-amd64.tar.gz
chmod +x typesense-server
```

- [ ] **Step 2: Create systemd service**

Write `/etc/systemd/system/typesense.service`:

```ini
[Unit]
Description=Typesense Search Engine
After=network.target

[Service]
Type=simple
ExecStart=/opt/typesense/typesense-server \
  --data-dir=/var/data/typesense \
  --api-key=tajiri-typesense-key-2026 \
  --listen-port=8108 \
  --enable-cors
Restart=always
MemoryMax=2G
User=www-data

[Install]
WantedBy=multi-user.target
```

- [ ] **Step 3: Start Typesense and verify**

```bash
systemctl daemon-reload
systemctl enable typesense
systemctl start typesense
curl http://localhost:8108/health -H "X-TYPESENSE-API-KEY: tajiri-typesense-key-2026"
```

Expected: `{"ok":true}`

- [ ] **Step 4: Create the content_documents collection**

```bash
curl -X POST 'http://localhost:8108/collections' \
  -H 'Content-Type: application/json' \
  -H 'X-TYPESENSE-API-KEY: tajiri-typesense-key-2026' \
  -d '{
    "name": "content_documents",
    "fields": [
      {"name": "id", "type": "string"},
      {"name": "source_type", "type": "string", "facet": true},
      {"name": "source_id", "type": "int64"},
      {"name": "title", "type": "string", "optional": true},
      {"name": "body", "type": "string", "optional": true},
      {"name": "hashtags", "type": "string[]", "facet": true},
      {"name": "mentions", "type": "string[]"},
      {"name": "language", "type": "string", "facet": true, "optional": true},
      {"name": "creator_id", "type": "int64"},
      {"name": "creator_tier", "type": "string", "facet": true, "optional": true},
      {"name": "category", "type": "string", "facet": true, "optional": true},
      {"name": "content_tier", "type": "string", "facet": true},
      {"name": "media_types", "type": "string[]", "facet": true},
      {"name": "region_name", "type": "string", "facet": true, "optional": true},
      {"name": "district_name", "type": "string", "facet": true, "optional": true},
      {"name": "privacy", "type": "string"},
      {"name": "composite_score", "type": "float", "sort": true},
      {"name": "engagement_score", "type": "float", "sort": true},
      {"name": "freshness_score", "type": "float", "sort": true},
      {"name": "trending_score", "type": "float", "sort": true},
      {"name": "quality_score", "type": "float"},
      {"name": "content_rank", "type": "float"},
      {"name": "creator_authority", "type": "float"},
      {"name": "published_at", "type": "int64", "sort": true},
      {"name": "indexed_at", "type": "int64"}
    ],
    "default_sorting_field": "composite_score",
    "token_separators": ["#", "@"]
  }'
```

Expected: 201 Created with collection schema returned.

- [ ] **Step 5: Verify collection exists**

```bash
curl http://localhost:8108/collections/content_documents -H "X-TYPESENSE-API-KEY: tajiri-typesense-key-2026"
```

Expected: Collection schema JSON with 25 fields.

---

## Task 2: Install pgvector Extension

- [ ] **Step 1: Install pgvector package**

```bash
ssh root@zima-uat.site
apt-get update && apt-get install -y postgresql-16-pgvector
```

Note: Check PostgreSQL version first with `psql --version`. If PostgreSQL 15, use `postgresql-15-pgvector`.

- [ ] **Step 2: Enable extension in tajiri database**

```bash
sudo -u postgres psql -d tajiri -c "CREATE EXTENSION IF NOT EXISTS vector;"
```

- [ ] **Step 3: Verify pgvector works**

```bash
sudo -u postgres psql -d tajiri -c "SELECT '[1,2,3]'::vector;"
```

Expected: Returns `[1,2,3]` without error.

---

## Task 3: Set Up Python Embedding Service

**Files:**
- Create: `/opt/tajiri-embedding/server.py`
- Create: `/opt/tajiri-embedding/requirements.txt`
- Create: `/etc/systemd/system/tajiri-embedding.service`

- [ ] **Step 1: Create directory and virtual environment**

```bash
ssh root@zima-uat.site
mkdir -p /opt/tajiri-embedding
python3 -m venv /opt/tajiri-embedding/venv
chown -R www-data:www-data /opt/tajiri-embedding
```

- [ ] **Step 2: Write requirements.txt**

Write `/opt/tajiri-embedding/requirements.txt`:

```
flask==3.1.0
sentence-transformers==3.3.1
gunicorn==23.0.0
```

- [ ] **Step 3: Install dependencies**

```bash
source /opt/tajiri-embedding/venv/bin/activate
pip install -r /opt/tajiri-embedding/requirements.txt
```

Note: This downloads the model (~560MB) on first run. May take several minutes.

- [ ] **Step 4: Write the embedding server**

Write `/opt/tajiri-embedding/server.py`:

```python
#!/usr/bin/env python3
"""TAJIRI Embedding Microservice — generates 768-dim text embeddings."""

import os
from flask import Flask, request, jsonify
from sentence_transformers import SentenceTransformer

app = Flask(__name__)

MODEL_NAME = os.environ.get("MODEL_NAME", "intfloat/multilingual-e5-base")
model = None

def get_model():
    global model
    if model is None:
        model = SentenceTransformer(MODEL_NAME)
    return model

@app.route("/health", methods=["GET"])
def health():
    m = get_model()
    dim = m.get_sentence_embedding_dimension()
    return jsonify({"status": "ok", "model": MODEL_NAME, "dimensions": dim})

@app.route("/embed", methods=["POST"])
def embed():
    data = request.get_json()
    if not data or "text" not in data:
        return jsonify({"error": "Missing 'text' field"}), 400

    m = get_model()
    text = data["text"]
    # multilingual-e5 expects "query: " or "passage: " prefix
    prefixed = f"passage: {text}"
    embedding = m.encode(prefixed).tolist()
    return jsonify({"embedding": embedding, "dimensions": len(embedding)})

@app.route("/embed/batch", methods=["POST"])
def embed_batch():
    data = request.get_json()
    if not data or "texts" not in data:
        return jsonify({"error": "Missing 'texts' field"}), 400

    texts = data["texts"][:50]  # Max 50 per batch
    m = get_model()
    prefixed = [f"passage: {t}" for t in texts]
    embeddings = m.encode(prefixed).tolist()
    return jsonify({"embeddings": embeddings, "dimensions": len(embeddings[0]) if embeddings else 0})

if __name__ == "__main__":
    get_model()  # Pre-load model
    app.run(host="127.0.0.1", port=8200)
```

- [ ] **Step 5: Create systemd service**

Write `/etc/systemd/system/tajiri-embedding.service`:

```ini
[Unit]
Description=TAJIRI Embedding Service
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/tajiri-embedding
ExecStart=/opt/tajiri-embedding/venv/bin/gunicorn -w 2 -b 127.0.0.1:8200 --timeout 60 --preload server:app
Restart=always
Environment=MODEL_NAME=intfloat/multilingual-e5-base

[Install]
WantedBy=multi-user.target
```

- [ ] **Step 6: Start and verify**

```bash
systemctl daemon-reload
systemctl enable tajiri-embedding
systemctl start tajiri-embedding

# Wait ~30s for model to load, then:
curl -X POST http://localhost:8200/embed \
  -H "Content-Type: application/json" \
  -d '{"text": "Bongo Flava mpya ya Diamond Platnumz"}'
```

Expected: JSON with `"embedding": [0.02, -0.03, ...]` array of 768 floats.

- [ ] **Step 7: Verify health endpoint**

```bash
curl http://localhost:8200/health
```

Expected: `{"status": "ok", "model": "intfloat/multilingual-e5-base", "dimensions": 768}`

---

## Task 4: Set Up Python ContentRank Environment

**Files:**
- Create: `/opt/tajiri-graph/content_rank.py`
- Create: `/opt/tajiri-graph/requirements.txt`
- Create: `/opt/tajiri-graph/.env`

- [ ] **Step 1: Create directory and virtual environment**

```bash
ssh root@zima-uat.site
mkdir -p /opt/tajiri-graph /var/log/tajiri
python3 -m venv /opt/tajiri-graph/venv
```

- [ ] **Step 2: Write requirements.txt**

Write `/opt/tajiri-graph/requirements.txt`:

```
networkx==3.3
psycopg2-binary==2.9.9
numpy==1.26.4
python-dotenv==1.0.1
```

- [ ] **Step 3: Install dependencies**

```bash
source /opt/tajiri-graph/venv/bin/activate
pip install -r /opt/tajiri-graph/requirements.txt
```

- [ ] **Step 4: Create dedicated PostgreSQL user for graph script**

```bash
sudo -u postgres psql -d tajiri -c "
CREATE USER tajiri_graph WITH PASSWORD 'tajiri_graph_2026';
GRANT SELECT ON content_documents, content_graph_edges TO tajiri_graph;
GRANT UPDATE (content_rank, creator_authority) ON content_documents TO tajiri_graph;
"
```

- [ ] **Step 5: Create database credentials file**

Write `/opt/tajiri-graph/.env`:

```
DB_HOST=127.0.0.1
DB_PORT=5432
DB_NAME=tajiri
DB_USER=tajiri_graph
DB_PASSWORD=tajiri_graph_2026
```

- [ ] **Step 6: Write the ContentRank script**

Write `/opt/tajiri-graph/content_rank.py`:

```python
#!/usr/bin/env python3
"""content_rank.py — TAJIRI's PageRank computation. Run hourly via cron."""

import os
import sys
import logging
from datetime import datetime
from dotenv import load_dotenv
import networkx as nx
import psycopg2

load_dotenv(os.path.join(os.path.dirname(__file__), '.env'))

logging.basicConfig(
    filename='/var/log/tajiri/content_rank.log',
    level=logging.INFO,
    format='%(asctime)s %(levelname)s %(message)s'
)

def get_connection():
    return psycopg2.connect(
        host=os.getenv('DB_HOST', '127.0.0.1'),
        port=os.getenv('DB_PORT', '5432'),
        dbname=os.getenv('DB_NAME', 'tajiri'),
        user=os.getenv('DB_USER', 'tajiri_graph'),
        password=os.getenv('DB_PASSWORD', 'tajiri_graph_2026'),
    )

def compute_content_rank():
    start = datetime.now()
    logging.info("ContentRank computation started")

    try:
        conn = get_connection()
    except Exception as e:
        logging.error(f"Database connection failed: {e}")
        sys.exit(1)

    cur = conn.cursor()
    G = nx.DiGraph()

    # Load document nodes
    cur.execute("""
        SELECT id, source_type, creator_id
        FROM content_documents
        WHERE content_tier != 'blackhole'
    """)
    doc_rows = cur.fetchall()
    for doc_id, source_type, creator_id in doc_rows:
        G.add_node(f"doc:{doc_id}", type='document', creator=creator_id)

    # Load creator nodes
    cur.execute("SELECT DISTINCT creator_id FROM content_documents WHERE content_tier != 'blackhole'")
    for (creator_id,) in cur.fetchall():
        G.add_node(f"creator:{creator_id}", type='creator')

    # Load edges
    cur.execute("SELECT source_type, source_id, target_type, target_id, weight FROM content_graph_edges")
    edge_rows = cur.fetchall()
    for src_type, src_id, tgt_type, tgt_id, weight in edge_rows:
        src_key = f"{src_type}:{src_id}"
        tgt_key = f"{tgt_type}:{tgt_id}"
        if G.has_node(src_key) and G.has_node(tgt_key):
            G.add_edge(src_key, tgt_key, weight=weight)

    logging.info(f"Graph built: {G.number_of_nodes()} nodes, {G.number_of_edges()} edges")

    if G.number_of_nodes() == 0:
        logging.info("Empty graph, skipping PageRank")
        cur.close()
        conn.close()
        return

    # Compute PageRank
    try:
        pagerank = nx.pagerank(G, alpha=0.85, weight='weight', max_iter=100)
    except Exception as e:
        logging.error(f"PageRank computation failed: {e}")
        cur.close()
        conn.close()
        sys.exit(1)

    # Normalize scores to 0-100
    max_score = max(pagerank.values()) if pagerank else 1

    # Separate document and creator scores
    doc_scores = []
    creator_scores = []
    for node, score in pagerank.items():
        normalized = (score / max_score) * 100
        if node.startswith("doc:"):
            doc_id = int(node.split(":")[1])
            doc_scores.append((normalized, doc_id))
        elif node.startswith("creator:"):
            creator_id = int(node.split(":")[1])
            creator_scores.append((normalized, creator_id))

    # Batch update documents (retry 3x with 10s backoff per spec)
    import time
    for attempt in range(3):
        try:
            cur.executemany(
                "UPDATE content_documents SET content_rank = %s WHERE id = %s",
                doc_scores
            )
            for authority, creator_id in creator_scores:
                cur.execute(
                    "UPDATE content_documents SET creator_authority = %s WHERE creator_id = %s",
                    (authority, creator_id)
                )
            conn.commit()
            break
        except Exception as e:
            conn.rollback()
            if attempt < 2:
                logging.warning(f"Write-back attempt {attempt+1} failed, retrying in 10s: {e}")
                time.sleep(10)
            else:
                logging.error(f"Write-back failed after 3 attempts: {e}")
                cur.close()
                conn.close()
                sys.exit(1)

    cur.close()
    conn.close()

    elapsed = (datetime.now() - start).total_seconds()
    logging.info(f"ContentRank done: {len(doc_scores)} docs, {len(creator_scores)} creators, {elapsed:.1f}s")

    if elapsed > 600:
        logging.warning(f"ContentRank took {elapsed:.0f}s (>10min). Consider graph pruning.")

if __name__ == "__main__":
    compute_content_rank()
```

- [ ] **Step 7: Test the script runs (will log empty graph)**

```bash
source /opt/tajiri-graph/venv/bin/activate
python /opt/tajiri-graph/content_rank.py
cat /var/log/tajiri/content_rank.log
```

Expected: Log shows "ContentRank computation started" and "Empty graph, skipping PageRank".

---

## Task 5: Create Database Migrations

All migrations on the backend server at `/var/www/html/tajiri/`.

- [ ] **Step 1: Create content_documents migration**

Write `database/migrations/2026_03_28_000001_create_content_documents_table.php`:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('content_documents', function (Blueprint $table) {
            $table->id();

            // Source identity
            $table->string('source_type', 20);
            $table->bigInteger('source_id');

            // Denormalized content
            $table->text('title')->nullable();
            $table->text('body')->nullable();
            // media_types, hashtags, mentions added as VARCHAR[] via raw SQL below
            $table->string('language', 5)->nullable();

            // Creator context
            $table->bigInteger('creator_id');
            $table->string('creator_tier', 20)->nullable();
            $table->float('creator_authority')->default(0);

            // Pre-computed scores
            $table->float('quality_score')->default(0);
            $table->float('engagement_score')->default(0);
            $table->float('freshness_score')->default(0);
            $table->float('content_rank')->default(0);
            $table->float('trending_score')->default(0);
            $table->float('spam_score')->default(0);
            $table->float('composite_score')->default(0);

            // Content tier
            $table->string('content_tier', 20)->default('medium');

            // Metadata
            $table->string('privacy', 20)->default('public');
            $table->string('region_name', 100)->nullable();
            $table->string('district_name', 100)->nullable();
            $table->string('category', 50)->nullable();

            // Timestamps
            $table->timestamp('published_at');
            $table->timestamp('indexed_at')->useCurrent();
            $table->timestamp('scores_updated_at')->nullable();

            $table->unique(['source_type', 'source_id']);
        });

        // Add columns not supported by Laravel Schema builder
        DB::statement("ALTER TABLE content_documents ADD COLUMN media_types VARCHAR[] DEFAULT '{}'");
        DB::statement("ALTER TABLE content_documents ADD COLUMN hashtags VARCHAR[] DEFAULT '{}'");
        DB::statement("ALTER TABLE content_documents ADD COLUMN mentions VARCHAR[] DEFAULT '{}'");
        DB::statement('ALTER TABLE content_documents ADD COLUMN embedding vector(768)');

        // Indexes
        DB::statement('CREATE INDEX idx_cd_composite ON content_documents(content_tier, composite_score DESC)');
        DB::statement('CREATE INDEX idx_cd_creator ON content_documents(creator_id)');
        DB::statement('CREATE INDEX idx_cd_region ON content_documents(region_name)');
        DB::statement('CREATE INDEX idx_cd_published ON content_documents(published_at DESC)');
        DB::statement('CREATE INDEX idx_cd_trending ON content_documents(trending_score DESC) WHERE trending_score > 0');
        DB::statement('CREATE INDEX idx_cd_embedding ON content_documents USING hnsw (embedding vector_cosine_ops)');
        DB::statement('CREATE INDEX idx_cd_hashtags ON content_documents USING gin (hashtags)');
        DB::statement('CREATE INDEX idx_cd_source ON content_documents(source_type, source_id)');
    }

    public function down(): void
    {
        Schema::dropIfExists('content_documents');
    }
};
```

- [ ] **Step 2: Create content_graph_edges migration**

Write `database/migrations/2026_03_28_000002_create_content_graph_edges_table.php`:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('content_graph_edges', function (Blueprint $table) {
            $table->id();
            $table->string('source_type', 20);
            $table->bigInteger('source_id');
            $table->string('target_type', 20);
            $table->bigInteger('target_id');
            $table->string('edge_type', 30);
            $table->float('weight')->default(1.0);
            $table->timestamp('created_at')->useCurrent();

            $table->unique(['source_type', 'source_id', 'target_type', 'target_id', 'edge_type'], 'cge_unique');

            $table->index(['source_type', 'source_id'], 'idx_cge_source');
            $table->index(['target_type', 'target_id'], 'idx_cge_target');
            $table->index('edge_type', 'idx_cge_type');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('content_graph_edges');
    }
};
```

- [ ] **Step 3: Create scoring_config migration**

Write `database/migrations/2026_03_28_000003_create_scoring_config_table.php`:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('scoring_config', function (Blueprint $table) {
            $table->string('key', 50)->primary();
            $table->float('value');
            $table->text('description')->nullable();
            $table->timestamp('updated_at')->useCurrent();
        });

        // Seed default weights
        DB::table('scoring_config')->insert([
            ['key' => 'w_freshness', 'value' => 0.25, 'description' => 'Weight for time-decay freshness'],
            ['key' => 'w_engagement', 'value' => 0.30, 'description' => 'Weight for real-time engagement signals'],
            ['key' => 'w_quality', 'value' => 0.15, 'description' => 'Weight for AI quality assessment'],
            ['key' => 'w_content_rank', 'value' => 0.15, 'description' => 'Weight for graph authority'],
            ['key' => 'w_creator_auth', 'value' => 0.10, 'description' => 'Weight for creator influence'],
            ['key' => 'w_trending', 'value' => 0.05, 'description' => 'Weight for trending spike bonus'],
        ]);
    }

    public function down(): void
    {
        Schema::dropIfExists('scoring_config');
    }
};
```

- [ ] **Step 4: Create content_categories migration**

Write `database/migrations/2026_03_28_000004_create_content_categories_table.php`:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('content_categories', function (Blueprint $table) {
            $table->string('slug', 50)->primary();
            $table->string('name_en', 100);
            $table->string('name_sw', 100);
        });

        DB::table('content_categories')->insert([
            ['slug' => 'entertainment', 'name_en' => 'Entertainment', 'name_sw' => 'Burudani'],
            ['slug' => 'music', 'name_en' => 'Music', 'name_sw' => 'Muziki'],
            ['slug' => 'sports', 'name_en' => 'Sports', 'name_sw' => 'Michezo'],
            ['slug' => 'news', 'name_en' => 'News', 'name_sw' => 'Habari'],
            ['slug' => 'business', 'name_en' => 'Business', 'name_sw' => 'Biashara'],
            ['slug' => 'education', 'name_en' => 'Education', 'name_sw' => 'Elimu'],
            ['slug' => 'lifestyle', 'name_en' => 'Lifestyle', 'name_sw' => 'Mtindo wa Maisha'],
            ['slug' => 'technology', 'name_en' => 'Technology', 'name_sw' => 'Teknolojia'],
            ['slug' => 'politics', 'name_en' => 'Politics', 'name_sw' => 'Siasa'],
            ['slug' => 'religion', 'name_en' => 'Religion', 'name_sw' => 'Dini'],
            ['slug' => 'food', 'name_en' => 'Food', 'name_sw' => 'Chakula'],
            ['slug' => 'travel', 'name_en' => 'Travel', 'name_sw' => 'Safari'],
            ['slug' => 'fashion', 'name_en' => 'Fashion', 'name_sw' => 'Mitindo'],
            ['slug' => 'health', 'name_en' => 'Health', 'name_sw' => 'Afya'],
            ['slug' => 'comedy', 'name_en' => 'Comedy', 'name_sw' => 'Vichekesho'],
            ['slug' => 'other', 'name_en' => 'Other', 'name_sw' => 'Nyingine'],
        ]);
    }

    public function down(): void
    {
        Schema::dropIfExists('content_categories');
    }
};
```

- [ ] **Step 5: Create remaining 5 migrations**

Write `database/migrations/2026_03_28_000005_create_user_events_table.php`:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_events', function (Blueprint $table) {
            $table->id();
            $table->bigInteger('user_id');
            $table->string('event_type', 30);
            $table->bigInteger('post_id')->nullable();
            $table->bigInteger('creator_id')->nullable();
            $table->integer('duration_ms')->default(0);
            $table->uuid('session_id')->nullable();
            $table->jsonb('metadata')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['user_id', 'created_at'], 'idx_ue_user');
            $table->index(['event_type', 'created_at'], 'idx_ue_type');
        });

        // Partial index — only index rows where post_id is not null
        DB::statement('CREATE INDEX idx_ue_post ON user_events(post_id) WHERE post_id IS NOT NULL');
    }

    public function down(): void
    {
        Schema::dropIfExists('user_events');
    }
};
```

Write `database/migrations/2026_03_28_000006_create_trending_digests_table.php`:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('trending_digests', function (Blueprint $table) {
            $table->id();
            $table->text('headline_sw');
            $table->text('headline_en');
            $table->jsonb('stories');
            $table->string('mood', 30)->nullable();
            $table->timestamp('generated_at')->useCurrent();
            $table->timestamp('valid_until')->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('trending_digests');
    }
};
```

Write `database/migrations/2026_03_28_000007_create_creator_coaching_table.php`:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('creator_coaching', function (Blueprint $table) {
            $table->id();
            $table->bigInteger('creator_id');
            $table->jsonb('advice');
            $table->date('week_start');
            $table->timestamp('generated_at')->useCurrent();

            $table->unique(['creator_id', 'week_start']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('creator_coaching');
    }
};
```

Write `database/migrations/2026_03_28_000008_create_feature_flags_table.php`:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('feature_flags', function (Blueprint $table) {
            $table->string('key', 50)->primary();
            $table->boolean('enabled')->default(false);
            $table->integer('rollout_pct')->default(0);
            $table->text('description')->nullable();
            $table->timestamp('updated_at')->useCurrent();
        });

        DB::table('feature_flags')->insert([
            ['key' => 'content_engine_search', 'enabled' => false, 'rollout_pct' => 0, 'description' => 'Use v2 search endpoint'],
            ['key' => 'content_engine_feed_for_you', 'enabled' => false, 'rollout_pct' => 0, 'description' => 'Use v2 feed for For You tab'],
            ['key' => 'content_engine_feed_discover', 'enabled' => false, 'rollout_pct' => 0, 'description' => 'Use v2 feed for Discover tab'],
            ['key' => 'content_engine_feed_trending', 'enabled' => false, 'rollout_pct' => 0, 'description' => 'Use v2 feed for Trending tab'],
            ['key' => 'content_engine_feed_nearby', 'enabled' => false, 'rollout_pct' => 0, 'description' => 'Use v2 feed for Nearby tab'],
            ['key' => 'content_engine_ai_digest', 'enabled' => false, 'rollout_pct' => 0, 'description' => 'Show AI trending digest'],
            ['key' => 'content_engine_ai_coaching', 'enabled' => false, 'rollout_pct' => 0, 'description' => 'Generate creator coaching'],
            ['key' => 'content_engine_ai_moderation', 'enabled' => false, 'rollout_pct' => 0, 'description' => 'AI content moderation'],
            ['key' => 'content_engine_query_expansion', 'enabled' => false, 'rollout_pct' => 0, 'description' => 'Claude query expansion on search'],
            ['key' => 'content_engine_dwell_tracking', 'enabled' => false, 'rollout_pct' => 0, 'description' => 'Track dwell time on frontend'],
            ['key' => 'content_engine_more_like_this', 'enabled' => false, 'rollout_pct' => 0, 'description' => 'Show similar content recommendations'],
        ]);
    }

    public function down(): void
    {
        Schema::dropIfExists('feature_flags');
    }
};
```

Write `database/migrations/2026_03_28_000009_create_content_tier_history_table.php`:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('content_tier_history', function (Blueprint $table) {
            $table->id();
            $table->bigInteger('document_id');
            $table->string('old_tier', 20)->nullable();
            $table->string('new_tier', 20);
            $table->float('composite_score');
            $table->timestamp('changed_at')->useCurrent();

            $table->index('document_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('content_tier_history');
    }
};
```

- [ ] **Step 6: Run all migrations**

```bash
cd /var/www/html/tajiri
php artisan migrate
```

Expected: 9 migrations run successfully.

- [ ] **Step 7: Verify tables exist**

```bash
php artisan tinker --execute="
echo 'content_documents: ' . \DB::select(\"SELECT COUNT(*) as c FROM information_schema.tables WHERE table_name = 'content_documents'\")[0]->c . PHP_EOL;
echo 'content_graph_edges: ' . \DB::select(\"SELECT COUNT(*) as c FROM information_schema.tables WHERE table_name = 'content_graph_edges'\")[0]->c . PHP_EOL;
echo 'scoring_config: ' . \DB::table('scoring_config')->count() . ' rows' . PHP_EOL;
echo 'content_categories: ' . \DB::table('content_categories')->count() . ' rows' . PHP_EOL;
echo 'feature_flags: ' . \DB::table('feature_flags')->count() . ' rows' . PHP_EOL;
"
```

Expected:
```
content_documents: 1
content_graph_edges: 1
scoring_config: 6 rows
content_categories: 16 rows
feature_flags: 11 rows
```

- [ ] **Step 8: Syntax check all migration files**

```bash
cd /var/www/html/tajiri
for f in database/migrations/2026_03_28_*.php; do php -l "$f"; done
```

Expected: All files report "No syntax errors detected".

- [ ] **Step 9: Commit migrations**

```bash
cd /var/www/html/tajiri
git add database/migrations/2026_03_28_*.php
git commit -m "feat(content-engine): add Phase 0 database migrations — content documents, graph edges, scoring config, categories, events, digests, coaching, feature flags, tier history"
```

---

## Task 6: Create Eloquent Models

- [ ] **Step 1: Create ContentDocument model**

Write `app/Models/ContentDocument.php`:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ContentDocument extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'source_type', 'source_id', 'title', 'body',
        'media_types', 'hashtags', 'mentions', 'language',
        'creator_id', 'creator_tier', 'creator_authority',
        'quality_score', 'engagement_score', 'freshness_score',
        'content_rank', 'trending_score', 'spam_score', 'composite_score',
        'content_tier', 'privacy', 'region_name', 'district_name', 'category',
        'published_at', 'indexed_at', 'scores_updated_at',
    ];

    protected $casts = [
        'media_types' => 'array',
        'hashtags' => 'array',
        'mentions' => 'array',
        'quality_score' => 'float',
        'engagement_score' => 'float',
        'freshness_score' => 'float',
        'content_rank' => 'float',
        'trending_score' => 'float',
        'spam_score' => 'float',
        'composite_score' => 'float',
        'creator_authority' => 'float',
        'published_at' => 'datetime',
        'indexed_at' => 'datetime',
        'scores_updated_at' => 'datetime',
    ];

    // Source type enum values
    public const TYPE_POST = 'post';
    public const TYPE_CLIP = 'clip';
    public const TYPE_STORY = 'story';
    public const TYPE_MUSIC = 'music';
    public const TYPE_STREAM = 'stream';
    public const TYPE_EVENT = 'event';
    public const TYPE_CAMPAIGN = 'campaign';
    public const TYPE_PRODUCT = 'product';
    public const TYPE_GROUP = 'group';
    public const TYPE_PAGE = 'page';
    public const TYPE_USER_PROFILE = 'user_profile';
    public const TYPE_GOSSIP_THREAD = 'gossip_thread';

    // Content tiers
    public const TIER_VIRAL = 'viral';
    public const TIER_HIGH = 'high';
    public const TIER_MEDIUM = 'medium';
    public const TIER_LOW = 'low';
    public const TIER_BLACKHOLE = 'blackhole';

    public function creator()
    {
        return $this->belongsTo(UserProfile::class, 'creator_id');
    }

    public function graphEdgesAsSource()
    {
        return $this->hasMany(ContentGraphEdge::class, 'source_id')
            ->where('source_type', 'document');
    }

    public function graphEdgesAsTarget()
    {
        return $this->hasMany(ContentGraphEdge::class, 'target_id')
            ->where('target_type', 'document');
    }

    /**
     * Find document by source.
     */
    public static function findBySource(string $type, int $id): ?self
    {
        return static::where('source_type', $type)
            ->where('source_id', $id)
            ->first();
    }
}
```

- [ ] **Step 2: Create remaining 8 models**

Write `app/Models/ContentGraphEdge.php`:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ContentGraphEdge extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'source_type', 'source_id', 'target_type', 'target_id',
        'edge_type', 'weight', 'created_at',
    ];

    protected $casts = [
        'weight' => 'float',
        'created_at' => 'datetime',
    ];

    public const EDGE_SHARED = 'SHARED';
    public const EDGE_REPLIED_TO = 'REPLIED_TO';
    public const EDGE_STITCHED = 'STITCHED';
    public const EDGE_MENTIONED_CREATOR = 'MENTIONED_CREATOR';
    public const EDGE_HASHTAG_CO_OCCURRENCE = 'HASHTAG_CO_OCCURRENCE';
    public const EDGE_SAME_THREAD = 'SAME_THREAD';
    public const EDGE_CREATOR_OF = 'CREATOR_OF';
    public const EDGE_FOLLOWED_THEN_CREATED = 'FOLLOWED_THEN_CREATED';
}
```

Write `app/Models/ScoringConfig.php`:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;

class ScoringConfig extends Model
{
    protected $table = 'scoring_config';
    protected $primaryKey = 'key';
    public $incrementing = false;
    protected $keyType = 'string';
    public $timestamps = false;

    protected $fillable = ['key', 'value', 'description', 'updated_at'];

    protected $casts = ['value' => 'float'];

    /**
     * Get a scoring weight, cached for 5 minutes.
     */
    public static function weight(string $key, float $default = 0): float
    {
        return Cache::remember("scoring_config:{$key}", 300, function () use ($key, $default) {
            $row = static::find($key);
            return $row ? $row->value : $default;
        });
    }

    /**
     * Get all weights as associative array, cached.
     */
    public static function allWeights(): array
    {
        return Cache::remember('scoring_config:all', 300, function () {
            return static::pluck('value', 'key')->toArray();
        });
    }
}
```

Write `app/Models/ContentCategory.php`:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ContentCategory extends Model
{
    protected $table = 'content_categories';
    protected $primaryKey = 'slug';
    public $incrementing = false;
    protected $keyType = 'string';
    public $timestamps = false;

    protected $fillable = ['slug', 'name_en', 'name_sw'];
}
```

Write `app/Models/UserEvent.php`:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserEvent extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'user_id', 'event_type', 'post_id', 'creator_id',
        'duration_ms', 'session_id', 'metadata', 'created_at',
    ];

    protected $casts = [
        'metadata' => 'array',
        'created_at' => 'datetime',
    ];
}
```

Write `app/Models/TrendingDigest.php`:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TrendingDigest extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'headline_sw', 'headline_en', 'stories', 'mood',
        'generated_at', 'valid_until',
    ];

    protected $casts = [
        'stories' => 'array',
        'generated_at' => 'datetime',
        'valid_until' => 'datetime',
    ];

    public static function current(): ?self
    {
        return static::where('valid_until', '>', now())
            ->orderBy('generated_at', 'desc')
            ->first();
    }
}
```

Write `app/Models/CreatorCoaching.php`:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CreatorCoaching extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'creator_id', 'advice', 'week_start', 'generated_at',
    ];

    protected $casts = [
        'advice' => 'array',
        'week_start' => 'date',
        'generated_at' => 'datetime',
    ];
}
```

Write `app/Models/FeatureFlag.php`:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;

class FeatureFlag extends Model
{
    protected $table = 'feature_flags';
    protected $primaryKey = 'key';
    public $incrementing = false;
    protected $keyType = 'string';
    public $timestamps = false;

    protected $fillable = ['key', 'enabled', 'rollout_pct', 'description', 'updated_at'];

    protected $casts = ['enabled' => 'boolean', 'rollout_pct' => 'integer'];

    /**
     * Check if a feature is enabled for a given user.
     * Uses deterministic assignment: user_id % 100 < rollout_pct.
     */
    public static function isEnabled(string $key, ?int $userId = null): bool
    {
        $flag = Cache::remember("feature_flag:{$key}", 60, function () use ($key) {
            return static::find($key);
        });

        if (!$flag || !$flag->enabled) {
            return false;
        }

        if ($userId === null || $flag->rollout_pct >= 100) {
            return true;
        }

        return ($userId % 100) < $flag->rollout_pct;
    }

    /**
     * Get all flags for a user (for frontend feature-flag endpoint).
     */
    public static function allForUser(?int $userId = null): array
    {
        $flags = Cache::remember('feature_flags:all', 60, function () {
            return static::all();
        });

        $result = [];
        foreach ($flags as $flag) {
            $result[$flag->key] = static::isEnabled($flag->key, $userId);
        }
        return $result;
    }
}
```

Write `app/Models/ContentTierHistory.php`:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ContentTierHistory extends Model
{
    public $timestamps = false;

    protected $table = 'content_tier_history';

    protected $fillable = [
        'document_id', 'old_tier', 'new_tier', 'composite_score', 'changed_at',
    ];

    protected $casts = [
        'composite_score' => 'float',
        'changed_at' => 'datetime',
    ];
}
```

- [ ] **Step 3: Syntax check all models**

```bash
cd /var/www/html/tajiri
for f in app/Models/Content*.php app/Models/ScoringConfig.php app/Models/UserEvent.php app/Models/TrendingDigest.php app/Models/CreatorCoaching.php app/Models/FeatureFlag.php; do php -l "$f"; done
```

Expected: All "No syntax errors detected".

- [ ] **Step 4: Commit models**

```bash
cd /var/www/html/tajiri
git add app/Models/ContentDocument.php app/Models/ContentGraphEdge.php app/Models/ScoringConfig.php app/Models/ContentCategory.php app/Models/UserEvent.php app/Models/TrendingDigest.php app/Models/CreatorCoaching.php app/Models/FeatureFlag.php app/Models/ContentTierHistory.php
git commit -m "feat(content-engine): add Phase 0 Eloquent models — ContentDocument, GraphEdge, ScoringConfig, FeatureFlag, UserEvent, TrendingDigest, CreatorCoaching, ContentTierHistory"
```

---

## Task 7: Create Config and Switch Queue to Redis

- [ ] **Step 1: Create content-engine config**

Write `config/content-engine.php`:

```php
<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Typesense Configuration
    |--------------------------------------------------------------------------
    */
    'typesense' => [
        'host' => env('TYPESENSE_HOST', 'localhost'),
        'port' => env('TYPESENSE_PORT', '8108'),
        'protocol' => env('TYPESENSE_PROTOCOL', 'http'),
        'api_key' => env('TYPESENSE_API_KEY', 'tajiri-typesense-key-2026'),
        'collection' => env('TYPESENSE_COLLECTION', 'content_documents'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Embedding Service Configuration
    |--------------------------------------------------------------------------
    */
    'embedding' => [
        'url' => env('EMBEDDING_SERVICE_URL', 'http://localhost:8200'),
        'timeout' => env('EMBEDDING_TIMEOUT', 10),
        'batch_size' => 50,
    ],

    /*
    |--------------------------------------------------------------------------
    | Claude AI Configuration
    |--------------------------------------------------------------------------
    */
    'claude' => [
        'cli_path' => env('CLAUDE_CLI_PATH', 'claude'),
        'scoring_model' => env('CLAUDE_SCORING_MODEL', 'haiku'),
        'query_model' => env('CLAUDE_QUERY_MODEL', 'haiku'),
        'digest_model' => env('CLAUDE_DIGEST_MODEL', 'sonnet'),
        'coaching_model' => env('CLAUDE_COACHING_MODEL', 'sonnet'),
        'moderation_model' => env('CLAUDE_MODERATION_MODEL', 'sonnet'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Scoring Configuration
    |--------------------------------------------------------------------------
    */
    'scoring' => [
        'freshness_half_lives' => [
            'post' => 24,
            'clip' => 48,
            'music' => 168,
            'stream' => 12,
            'event' => 72,
            'product' => 336,
            'gossip_thread' => 24,
            'campaign' => 168,
            'group' => 720,
            'page' => 720,
            'user_profile' => 720,
            'story' => 6,
        ],
        'engagement_normalization_k' => 50,
        'trending_velocity_multiplier' => 20,
        'trending_rising_threshold' => 3,
        'trending_breaking_threshold' => 10,
    ],

    /*
    |--------------------------------------------------------------------------
    | Content Tier Thresholds
    |--------------------------------------------------------------------------
    */
    'tiers' => [
        'viral' => 85,
        'high' => 60,
        'medium' => 30,
        'low' => 10,
        // Below 10 = blackhole (or spam_score > 7)
    ],
];
```

- [ ] **Step 2: Add environment variables to .env**

Append to `/var/www/html/tajiri/.env`:

```
# Content Engine
TYPESENSE_API_KEY=tajiri-typesense-key-2026
TYPESENSE_HOST=localhost
TYPESENSE_PORT=8108
EMBEDDING_SERVICE_URL=http://localhost:8200
QUEUE_CONNECTION=redis
```

- [ ] **Step 3: Verify queue config uses redis**

```bash
cd /var/www/html/tajiri
php artisan tinker --execute="echo config('queue.default');"
```

Expected: `redis`

- [ ] **Step 4: Commit config**

```bash
cd /var/www/html/tajiri
git add config/content-engine.php
git commit -m "feat(content-engine): add content-engine config — Typesense, embedding, Claude, scoring, tier thresholds"
```

---

## Task 8: Create Health Check Command

- [ ] **Step 1: Write the health check command**

Write `app/Console/Commands/ContentHealthCheck.php`:

```php
<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Redis;

class ContentHealthCheck extends Command
{
    protected $signature = 'content:health-check';
    protected $description = 'Check all Content Engine subsystems';

    public function handle(): int
    {
        $this->info('Content Engine Health Check');
        $this->info(str_repeat('=', 50));

        $allOk = true;

        // PostgreSQL
        $allOk &= $this->check('PostgreSQL', function () {
            $count = DB::table('content_documents')->count();
            return "OK ({$count} documents)";
        });

        // pgvector
        $allOk &= $this->check('pgvector', function () {
            DB::select("SELECT '[1,2,3]'::vector");
            return 'OK (extension loaded)';
        });

        // Typesense
        $allOk &= $this->check('Typesense', function () {
            $config = config('content-engine.typesense');
            $url = "{$config['protocol']}://{$config['host']}:{$config['port']}/health";
            $response = Http::withHeaders(['X-TYPESENSE-API-KEY' => $config['api_key']])->timeout(5)->get($url);
            if (!$response->successful()) throw new \Exception('Not responding');
            return 'OK';
        });

        // Typesense Collection
        $allOk &= $this->check('Typesense Collection', function () {
            $config = config('content-engine.typesense');
            $url = "{$config['protocol']}://{$config['host']}:{$config['port']}/collections/{$config['collection']}";
            $response = Http::withHeaders(['X-TYPESENSE-API-KEY' => $config['api_key']])->timeout(5)->get($url);
            if (!$response->successful()) throw new \Exception('Collection not found');
            $data = $response->json();
            return "OK ({$data['num_documents']} docs)";
        });

        // Redis
        $allOk &= $this->check('Redis', function () {
            $pong = Redis::ping();
            return 'OK (PONG)';
        });

        // Embedding Service
        $allOk &= $this->check('Embedding Service', function () {
            $url = config('content-engine.embedding.url') . '/health';
            $response = Http::timeout(5)->get($url);
            if (!$response->successful()) throw new \Exception('Not responding');
            $data = $response->json();
            return "OK ({$data['model']}, {$data['dimensions']}d)";
        });

        // Claude CLI
        $allOk &= $this->check('Claude CLI', function () {
            $cliPath = config('content-engine.claude.cli_path', 'claude');
            $output = shell_exec("{$cliPath} --version 2>&1");
            if (empty($output)) throw new \Exception('Not found');
            return 'OK (' . trim($output) . ')';
        });

        // Scoring Config
        $allOk &= $this->check('Scoring Config', function () {
            $count = DB::table('scoring_config')->count();
            if ($count < 6) throw new \Exception("Only {$count} weights (expected 6)");
            return "OK ({$count} weights)";
        });

        // Feature Flags
        $allOk &= $this->check('Feature Flags', function () {
            $count = DB::table('feature_flags')->count();
            return "OK ({$count} flags)";
        });

        $this->newLine();
        if ($allOk) {
            $this->info('All subsystems operational.');
        } else {
            $this->error('Some subsystems failed. Fix issues above before proceeding.');
        }

        return $allOk ? 0 : 1;
    }

    private function check(string $name, callable $fn): bool
    {
        try {
            $result = $fn();
            $this->line("  ✓ {$name}: {$result}");
            return true;
        } catch (\Throwable $e) {
            $this->error("  ✗ {$name}: FAILED — {$e->getMessage()}");
            return false;
        }
    }
}
```

- [ ] **Step 2: Syntax check**

```bash
php -l /var/www/html/tajiri/app/Console/Commands/ContentHealthCheck.php
```

Expected: No syntax errors.

- [ ] **Step 3: Run health check**

```bash
cd /var/www/html/tajiri
php artisan content:health-check
```

Expected: All subsystems show ✓ (or ✗ for Claude CLI if not installed in PATH — acceptable for now).

- [ ] **Step 4: Commit**

```bash
cd /var/www/html/tajiri
git add app/Console/Commands/ContentHealthCheck.php
git commit -m "feat(content-engine): add content:health-check command — verifies all subsystems"
```

---

## Task 9: Final Verification

- [ ] **Step 1: Run full health check**

```bash
cd /var/www/html/tajiri
php artisan content:health-check
```

All subsystems should be ✓.

- [ ] **Step 2: Verify table counts**

```bash
php artisan tinker --execute="
\$tables = ['content_documents','content_graph_edges','scoring_config','content_categories','user_events','trending_digests','creator_coaching','feature_flags','content_tier_history'];
foreach(\$tables as \$t) { echo \$t . ': ' . DB::table(\$t)->count() . PHP_EOL; }
"
```

Expected:
```
content_documents: 0
content_graph_edges: 0
scoring_config: 6
content_categories: 16
user_events: 0
trending_digests: 0
creator_coaching: 0
feature_flags: 11
content_tier_history: 0
```

- [ ] **Step 3: Verify Typesense responds to search**

```bash
curl -s 'http://localhost:8108/collections/content_documents/documents/search?q=test&query_by=title,body' \
  -H "X-TYPESENSE-API-KEY: tajiri-typesense-key-2026" | python3 -m json.tool
```

Expected: `{"found": 0, "hits": [], ...}` — empty but working.

- [ ] **Step 4: Verify embedding service**

```bash
curl -s -X POST http://localhost:8200/embed \
  -H "Content-Type: application/json" \
  -d '{"text": "habari za leo Dar es Salaam"}' | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'Dimensions: {d[\"dimensions\"]}')"
```

Expected: `Dimensions: 768`

- [ ] **Step 5: Final commit with all remaining files**

```bash
cd /var/www/html/tajiri
git add -A
git status
git commit -m "feat(content-engine): Phase 0 complete — foundation infrastructure ready"
```

---

## Phase 0 Completion Criteria

After all 9 tasks:

- [ ] Typesense running on port 8108 with `content_documents` collection (25 fields)
- [ ] pgvector extension enabled in PostgreSQL
- [ ] Embedding microservice running on port 8200, returning 768-dim vectors
- [ ] NetworkX environment ready at `/opt/tajiri-graph/` with working script
- [ ] 9 new database tables created with seed data
- [ ] 9 Eloquent models with type constants and query helpers
- [ ] `content-engine.php` config with all service coordinates
- [ ] Queue driver switched to Redis
- [ ] `php artisan content:health-check` passes all checks
- [ ] All code committed

**Deferred to Phase 1:** ContentRank cron job (`0 * * * * /opt/tajiri-graph/venv/bin/python /opt/tajiri-graph/content_rank.py`) — no data to rank until ingestion pipeline exists.

**Next:** Phase 1 — Ingestion Pipeline (ContentIngestionJob, ContentDocumentFactory, event listeners, Typesense sync, backfill command)
