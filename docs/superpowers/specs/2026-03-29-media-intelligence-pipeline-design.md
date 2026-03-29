# Media Intelligence Pipeline — Design Spec

**Date:** 2026-03-29
**Status:** Draft
**Scope:** Backend (Laravel) + Infrastructure (FFmpeg, Whisper)

## 1. Problem

Posts with media (images, audio, video) are indexed in the Content Engine using only the user-written caption text. A post with a photo of Kariakoo market and caption "Soko langu 🥕" is invisible to searches for "vegetables", "market", "Kariakoo", or "biashara". The Content Engine cannot see inside media files.

## 2. Goal

Build a post-upload pipeline that automatically extracts searchable text from all media types:
- **Images** → visual description via Claude CLI vision
- **Audio** → speech-to-text via Whisper, cleaned by Claude Haiku
- **Video** → audio track transcription + keyframe visual analysis + combined summary

All extracted text is stored on `content_documents` and indexed in Typesense + embedded in pgvector, making media-rich posts fully searchable.

## 3. Architecture

### Trigger

`ContentIngestionJob` (existing) dispatches a new `MediaEnrichmentJob` on the `media-enrichment` queue after creating/updating the content_document. The enrichment job runs asynchronously — it does not block post creation or the existing scoring/embedding jobs.

### Pipeline Per Media Type

**Images:**
1. Resolve storage path: `storage/app/public/{file_path}`
2. Send to Claude CLI with vision prompt
3. Receive 2-3 sentence English description
4. Store in `media_descriptions.images[]`

**Audio Posts (standalone audio or PostMedia with `media_type = 'audio'`):**
1. Resolve audio file from `posts.audio_path` or `post_media.file_path`
2. Whisper transcription (model: `small`, language: auto-detect)
3. Claude Haiku cleanup: fix spelling/grammar, generate English summary
4. Store raw transcript, clean transcript, summary, detected language

**Video Posts:**
1. FFmpeg extracts audio track → WAV (16kHz, mono)
2. Whisper transcribes extracted audio
3. Claude Haiku cleans transcript
4. FFmpeg extracts keyframes: 1 per 10 seconds, max 6 frames
5. Claude CLI vision analyzes each keyframe
6. Claude Haiku combines transcript + frame descriptions → final rich summary with topic, visual content, suggested category
7. Temp files cleaned up in `finally` block

### Processing Order

Within a single post: images first (fastest), then audio, then video (slowest). Each media item is independent — if one fails, the rest continue.

## 4. Storage

### New Columns

Two new columns on `content_documents`:

1. `media_descriptions` — JSONB, nullable. Stores structured output per media item.
2. `media_text` — TEXT, nullable. Combined human-readable summary text for search indexing. Kept separate from `body` so re-enrichment is idempotent (overwrite `media_text`, never mutate `body`).

Structured output per media item:

```json
{
  "images": [
    {"media_id": 6, "description": "A woman selling vegetables at Kariakoo market in Dar es Salaam, colorful produce arranged on wooden tables"}
  ],
  "audio": [
    {
      "media_id": null,
      "source": "post.audio_path",
      "raw_transcript": "Habari za leo nataka kuongea kuhusu...",
      "clean_transcript": "Habari za leo, nataka kuongea kuhusu biashara ndogo...",
      "summary": "Discussion about small business challenges in Dar es Salaam",
      "detected_language": "sw"
    }
  ],
  "video": [
    {
      "media_id": 12,
      "transcript": "Karibuni kwenye duka langu jipya...",
      "frame_descriptions": [
        {"timestamp": "0:05", "description": "Man standing in front of a shop with sign reading 'Duka la Juma'"},
        {"timestamp": "0:15", "description": "Close-up of produce display with tomatoes, onions, and peppers"}
      ],
      "summary": "Video tour of a new duka in Mwananyamala showing products and prices"
    }
  ],
  "enriched_at": "2026-03-29T14:00:00Z"
}
```

### Integration With Search

1. `MediaEnrichmentJob` stores `media_descriptions` JSON on content_document
2. Writes combined summary text to `content_documents.media_text` (separate column, never appended to `body`)
3. Dispatches `SyncToTypesenseJob` (media_text changed → Typesense re-index)
4. Dispatches `GenerateEmbeddingTextJob` (richer text → better semantic embedding)
5. If Claude's summary suggests a category and user didn't set one, auto-fills `content_documents.category`

### What Typesense Indexes

Typesense indexes both `body` and `media_text` as searchable fields. A search for "Kariakoo market vegetables" matches the `media_text` field:

```
[Image: A woman selling vegetables at Kariakoo market in Dar es Salaam, colorful produce arranged on wooden tables]
```

The original `body` ("Soko langu 🥕") remains untouched. Re-enrichment simply overwrites `media_text`.

### Typesense Schema Change

Add `media_text` as a searchable string field to the existing `content_documents` Typesense collection:

```json
{"name": "media_text", "type": "string", "optional": true}
```

`SyncToTypesenseJob` must include `media_text` in the document payload.

Someone searching "Kariakoo market vegetables" now finds this post.

### Idempotency

`MediaEnrichmentJob` checks `media_descriptions IS NOT NULL` and `enriched_at` timestamp. Skips already-enriched documents unless dispatched with `force=true` (for backfill).

## 5. Services

### File Structure

| File | Purpose |
|------|---------|
| `database/migrations/2026_03_29_400001_add_media_descriptions_to_content_documents.php` | Add `media_descriptions` JSONB + `media_text` TEXT columns |
| `app/Services/ContentEngine/MediaEnrichmentService.php` | Orchestrator — routes each media type to the right processor |
| `app/Services/ContentEngine/ImageAnalysisService.php` | Claude CLI vision for single image |
| `app/Services/ContentEngine/AudioTranscriptionService.php` | Whisper + Claude cleanup |
| `app/Services/ContentEngine/VideoAnalysisService.php` | FFmpeg + Whisper + Claude for video |
| `app/Jobs/ContentEngine/MediaEnrichmentJob.php` | Queue job dispatched after ingestion |
| `app/Console/Commands/EnrichMedia.php` | Backfill command `content:enrich-media` |

### Modified Files

| File | Change |
|------|--------|
| `app/Jobs/ContentEngine/ContentIngestionJob.php` | Dispatch `MediaEnrichmentJob` after existing jobs |
| `app/Jobs/ContentEngine/SyncToTypesenseJob.php` | Include `media_text` in Typesense document payload |
| `app/Console/Commands/ContentHealthCheck.php` | Add FFmpeg/Whisper/enrichment checks |
| `/etc/supervisor/conf.d/tajiri-workers.conf` | Add `tajiri-media-enrichment` worker |

### Service Boundaries

```
MediaEnrichmentJob (queue job, timeout: 600s)
  └── MediaEnrichmentService::enrich(contentDocumentId): bool
        ├── per PostMedia:
        │     ├── media_type='image' → ImageAnalysisService::describe(imagePath): ?string
        │     ├── media_type='audio' → AudioTranscriptionService::transcribe(audioPath): ?array
        │     └── media_type='video' → VideoAnalysisService::analyze(videoPath, duration): ?array
        │           ├── uses AudioTranscriptionService internally (extracted audio)
        │           └── uses ImageAnalysisService internally (each keyframe)
        └── standalone audio_path → AudioTranscriptionService::transcribe(audioPath): ?array
```

Each service is a focused static-method class following TAJIRI's existing service patterns.

### ImageAnalysisService

```
describe(string $imagePath): ?string
```

- Validates file exists and is an image
- Sanitizes path for shell
- Calls: `timeout 30 claude -p "{prompt}" --files {image_path} --model haiku --output-format text`
- Prompt: "Describe this image from a Tanzanian social media post. What do you see? Include people, objects, locations, text visible in the image, and cultural context. Write 2-3 sentences in English."
- Note: Claude CLI uses `--files` flag for image input, not stdin piping
- Returns description string or null on failure

### AudioTranscriptionService

```
transcribe(string $audioPath): ?array
```

- Validates file exists
- Runs: `whisper {audio_path} --model small --output_format txt --output_dir /tmp/whisper_{id}/`
- Note: Uses `small` model (~2GB RAM) instead of `medium` (~5GB) for safety on 16GB server with other services. No `--language` flag — Whisper auto-detects language, supporting Swahili, English, and mixed content.
- Reads raw transcript from output .txt file (Whisper names output after input basename, e.g., `audio.txt` for `audio.wav` — service globs `/tmp/whisper_{id}/*.txt` to find it)
- Sends to Claude Haiku for cleanup:
  ```
  timeout 30 claude -p "{prompt_with_transcript}" --model haiku --output-format text
  ```
  Prompt: "Fix spelling/grammar errors in this transcript. Clean up sentence boundaries. Write a 1-2 sentence English summary. Detect the language. Respond ONLY as valid JSON with no markdown wrapping: {\"clean_transcript\": \"...\", \"summary\": \"...\", \"detected_language\": \"sw|en|mixed\"}"
- **JSON parsing**: Strip any markdown code fences (` ```json ... ``` `) before `json_decode()`. If `json_decode()` fails, fall back to using raw transcript as `clean_transcript`, empty `summary`, and `detected_language = 'unknown'`.
- Returns `['raw_transcript' => ..., 'clean_transcript' => ..., 'summary' => ..., 'detected_language' => ...]`
- Cleans up temp directory in `finally` block

### VideoAnalysisService

```
analyze(string $videoPath, ?float $duration = null): ?array
```

- Validates file exists
- If duration unknown, probes with: `ffprobe -v quiet -print_format json -show_format {video_path}`
- **Duration guard**: If duration is null, 0, or > 300s (5 minutes), skip enrichment for this video. Log warning with reason. Videos over 5 minutes would exceed the job timeout budget.
- Creates temp directory: `/tmp/tajiri_enrich_{contentDocId}_{uniqid}/` (unique per run to avoid stale file reuse on retry)
- Extracts audio: `ffmpeg -i {video_path} -vn -acodec pcm_s16le -ar 16000 -ac 1 {tmpDir}/audio.wav`
- Calls `AudioTranscriptionService::transcribe()` on extracted audio
- Calculates keyframe interval: `max(5, duration / max_frames)` where `max_frames = min(6, ceil(duration / 10))` (for a 3s video: 1 frame at 0s; for 60s: 6 frames every 10s)
- Extracts frames: `ffmpeg -i {video_path} -vf "fps=1/{interval}" -frames:v {max_frames} -q:v 2 {tmpDir}/frame_%02d.jpg`
- Calls `ImageAnalysisService::describe()` on each frame (with 1s sleep between calls)
- Final Claude Haiku call combining transcript + all frame descriptions:
  ```
  timeout 30 claude -p "{prompt_with_transcript_and_frames}" --model haiku --output-format text
  ```
  Prompt: "Given this video transcript and frame descriptions, write a rich 2-3 sentence summary covering the topic, visual content, and context. Suggest a content category. Respond as JSON: {\"summary\": \"...\", \"suggested_category\": \"...\"}"
- Same JSON parsing strategy as AudioTranscriptionService (strip markdown fences, fallback on parse failure)
- Returns `['transcript' => ..., 'frame_descriptions' => [...], 'summary' => ...]`
- Cleans up entire temp directory in `finally` block

### MediaEnrichmentService

```
enrich(int $contentDocumentId, bool $force = false): bool
```

- Loads content_document with its source Post + PostMedia
- Checks idempotency: skips if `media_descriptions` is not null and `force` is false
- Processes each PostMedia by type:
  - `media_type = 'image'` → `ImageAnalysisService::describe()`
  - `media_type = 'video'` → `VideoAnalysisService::analyze()`
  - `media_type = 'audio'` → `AudioTranscriptionService::transcribe()`
- If post has `audio_path` (standalone audio post, no PostMedia) → `AudioTranscriptionService::transcribe()`
- If post has `document_path` → logged as unsupported, skipped (future: PDF text extraction)
- Assembles `media_descriptions` JSON structure
- Updates content_document: sets `media_descriptions` and `media_text` (separate column, never mutates `body`)
- Auto-fills `category` if null and Claude suggested one
- Dispatches `SyncToTypesenseJob` and `GenerateEmbeddingTextJob`
- Returns true on success (even partial), false if nothing processed

## 6. Infrastructure

### Dependencies to Install

```bash
# FFmpeg — media extraction
apt install -y ffmpeg

# Python 3 + pip (if not present)
apt install -y python3 python3-pip

# Whisper — speech-to-text (small model: ~500MB download, ~2GB RAM at runtime)
pip3 install openai-whisper
# Pre-download model to avoid first-run delay:
python3 -c "import whisper; whisper.load_model('small')"
```

### Supervisor Worker

Add to `/etc/supervisor/conf.d/tajiri-workers.conf`:

```ini
[program:tajiri-media-enrichment]
process_name=%(program_name)s_%(process_num)02d
command=php8.3 /var/www/tajiri.zimasystems.com/artisan queue:work redis --queue=media-enrichment --sleep=10 --tries=2 --timeout=600 --max-jobs=100
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
numprocs=1
redirect_stderr=true
stdout_logfile=/var/log/tajiri/worker-media-enrichment.log
stopwaitsecs=3600
```

Only 1 worker — Whisper is CPU-heavy. Running 2+ would thrash the 6-CPU server.

### Timeout Budget

| Step | Max Time |
|------|----------|
| Image → Claude CLI | 30s per image |
| Audio → Whisper (up to 60s audio) | 60s |
| Audio → Claude Haiku cleanup | 10s |
| Video → FFmpeg extract audio | 10s |
| Video → Whisper transcribe | 60s |
| Video → FFmpeg keyframes | 5s |
| Video → Claude CLI per frame (×6) | 180s |
| Video → Claude Haiku final summary | 10s |
| **Worst case (video + 5 images + audio)** | ~420s |

**Job timeout: 600s** (10 minutes). A post with video + multiple images + audio can exceed 300s. The supervisor `stopwaitsecs` is set to 3600 to allow graceful completion.

### Cost Estimate

| Media Type | Cost Per Item |
|------------|--------------|
| Image (Claude Haiku vision) | ~$0.002 |
| Audio (Whisper free + Haiku cleanup) | ~$0.001 |
| Video (Whisper + keyframes + Haiku) | ~$0.005-0.015 |
| **Average post with 2 images** | ~$0.005 |
| **Post with video** | ~$0.010-0.020 |

At 1,000 posts/day: ~$5-20/day. At 10,000 posts/day: ~$50-200/day.

## 7. Error Handling

- **Whisper fails** (corrupt audio, unsupported codec): Log warning, skip transcript, continue with visual analysis
- **Claude CLI fails** (timeout, rate limit): Log warning, store null for that description, continue with other media
- **FFmpeg fails** (corrupt video, missing codec): Log error, skip entire video enrichment, other media items still processed
- **Partial success**: If 3/5 images succeed and 2 fail, store the 3 descriptions. Never discard good work due to partial failure
- **Retry**: Job retries once (`tries=2`). Job class defines `public $backoff = 60;` for 60s delay between attempts. Transient failures self-heal
- **Temp file cleanup**: All temp directories (`/tmp/tajiri_enrich_{id}_*/`, `/tmp/whisper_{id}/`) deleted in `finally` block regardless of outcome
- **Null byte sanitization**: All user-derived text sanitized before `escapeshellarg()` (consistent with Phase 5 pattern)
- **Rate limiting**: 1-second `sleep(1)` between consecutive Claude CLI calls within a single job to avoid rate-limit errors when processing posts with many images/frames
- **Size/duration limits**: Images > 20MB skipped. Audio > 5 minutes skipped (Whisper processing time scales linearly). Video > 5 minutes skipped (would exceed timeout budget). Limits logged as warnings, not errors.

## 8. Backfill Command

`content:enrich-media` artisan command:

```bash
# Process posts with media but no enrichment (default batch: 20)
php8.3 artisan content:enrich-media --batch-size=20

# Re-process a specific post
php8.3 artisan content:enrich-media --post-id=123 --force

# Only process images (skip audio/video)
php8.3 artisan content:enrich-media --types=image

# Only process posts of a specific type
php8.3 artisan content:enrich-media --source-type=post
```

Dispatches `MediaEnrichmentJob` per document, rate-limited (2s between dispatches to avoid overwhelming Claude).

## 9. Health Check Addition

Add to existing `content:health-check`:
- FFmpeg accessible (`which ffmpeg`)
- Whisper accessible (`which whisper`)
- Media enrichment worker running (Supervisor status)
- Recent enrichment count (documents enriched in last 24h)

## 10. Future Considerations (Out of Scope)

- **Facial recognition** — auto-tagging people in photos/video. Deferred due to privacy/legal complexity. Requires user opt-in consent system.
- **Video scene-change detection** — smarter keyframe extraction using FFmpeg `scene` filter. Can replace duration-based approach later.
- **Real-time transcription** — for live streams. Different architecture needed.
- **Whisper model upgrade** — `small` model used for RAM safety. If server RAM increases, upgrade to `medium` for better accuracy on Swahili content.
