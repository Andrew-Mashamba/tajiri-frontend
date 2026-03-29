# Media Intelligence Pipeline — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a post-upload pipeline that extracts searchable text from images (Claude CLI vision), audio (Whisper + Claude cleanup), and video (FFmpeg + Whisper + Claude keyframe analysis), storing results on `content_documents` for Typesense indexing and embedding generation.

**Architecture:** `ContentIngestionJob` dispatches `MediaEnrichmentJob` on the `media-enrichment` queue. The job calls `MediaEnrichmentService` which routes each PostMedia to type-specific services (ImageAnalysisService, AudioTranscriptionService, VideoAnalysisService). Results stored in `media_descriptions` JSONB + `media_text` TEXT columns, then re-indexed via existing Typesense and embedding pipelines.

**Tech Stack:** PHP 8.3, Laravel 12, PostgreSQL 16, Typesense 27.1, Claude CLI (haiku model), OpenAI Whisper (small model), FFmpeg, Redis queues, Supervisor

**Spec:** `docs/superpowers/specs/2026-03-29-media-intelligence-pipeline-design.md`

**Server:** `root@172.240.241.180` (connect: `sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180`)
**Project path:** `/var/www/tajiri.zimasystems.com`

---

## File Structure

### New Files
| File | Responsibility |
|------|---------------|
| `database/migrations/2026_03_29_400001_add_media_descriptions_to_content_documents.php` | Add `media_descriptions` JSONB + `media_text` TEXT columns |
| `app/Services/ContentEngine/ImageAnalysisService.php` | Claude CLI vision for single image → description string |
| `app/Services/ContentEngine/AudioTranscriptionService.php` | Whisper transcription + Claude Haiku cleanup → structured array |
| `app/Services/ContentEngine/VideoAnalysisService.php` | FFmpeg audio/keyframe extraction + Whisper + Claude → structured array |
| `app/Services/ContentEngine/MediaEnrichmentService.php` | Orchestrator — routes PostMedia to type-specific services, assembles results |
| `app/Jobs/ContentEngine/MediaEnrichmentJob.php` | Queue job wrapping MediaEnrichmentService::enrich() |
| `app/Console/Commands/EnrichMedia.php` | `content:enrich-media` backfill command |

### Modified Files
| File | Change |
|------|--------|
| `app/Models/ContentDocument.php` | Add `media_descriptions`, `media_text` to `$casts` and `$fillable` |
| `app/Jobs/ContentEngine/ContentIngestionJob.php` | Dispatch `MediaEnrichmentJob` after existing 4 jobs |
| `app/Jobs/ContentEngine/SyncToTypesenseJob.php` | Include `media_text` in Typesense document payload |
| `app/Console/Commands/ContentHealthCheck.php` | Add FFmpeg/Whisper/enrichment worker/enrichment count checks |
| `/etc/supervisor/conf.d/tajiri-workers.conf` | Add `tajiri-media-enrichment` worker program |

### Typesense Schema
Add `media_text` as searchable field via Typesense API call (done in Task 2).

---

## Task 1: Install Infrastructure Dependencies

**Context:** FFmpeg, Python 3, and Whisper must be available on the server before any service code can work. This task has no Laravel code — it's pure server setup.

**Server:** `root@172.240.241.180`

- [ ] **Step 1: Install FFmpeg**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "apt update && apt install -y ffmpeg && ffmpeg -version | head -1"
```

Expected: `ffmpeg version X.Y.Z ...`

- [ ] **Step 2: Verify Python 3 + pip**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "python3 --version && pip3 --version || (apt install -y python3 python3-pip && python3 --version)"
```

Expected: `Python 3.x.x` and `pip X.Y.Z`

- [ ] **Step 3: Install Whisper and pre-download small model**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "pip3 install openai-whisper && python3 -c \"import whisper; whisper.load_model('small'); print('Whisper small model ready')\" && which whisper"
```

Expected: `Whisper small model ready` and path like `/usr/local/bin/whisper`

- [ ] **Step 4: Verify ffprobe is available**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "which ffprobe && ffprobe -version | head -1"
```

Expected: `ffprobe version X.Y.Z ...` (installed with ffmpeg)

- [ ] **Step 5: Verify Claude CLI is available**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "which claude && claude --version"
```

Expected: Claude CLI version output (already installed from Phase 5)

---

## Task 2: Database Migration + Typesense Schema + Model Update

**Files:**
- Create: `database/migrations/2026_03_29_400001_add_media_descriptions_to_content_documents.php`
- Modify: `app/Models/ContentDocument.php`

- [ ] **Step 1: Create the migration file**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "cat > /var/www/tajiri.zimasystems.com/database/migrations/2026_03_29_400001_add_media_descriptions_to_content_documents.php << 'MIGRATION'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('content_documents', function (Blueprint \$table) {
            \$table->jsonb('media_descriptions')->nullable()->after('category');
            \$table->text('media_text')->nullable()->after('media_descriptions');
        });
    }

    public function down(): void
    {
        Schema::table('content_documents', function (Blueprint \$table) {
            \$table->dropColumn(['media_descriptions', 'media_text']);
        });
    }
};
MIGRATION"
```

- [ ] **Step 2: Run the migration**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "cd /var/www/tajiri.zimasystems.com && php8.3 artisan migrate --force"
```

Expected: `Migrating: 2026_03_29_400001_add_media_descriptions_to_content_documents` / `Migrated`

- [ ] **Step 3: Verify columns exist**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "PGPASSWORD=postgres psql -U postgres -d tajiri -c \"SELECT column_name, data_type FROM information_schema.columns WHERE table_name='content_documents' AND column_name IN ('media_descriptions','media_text');\""
```

Expected: Two rows — `media_descriptions | jsonb` and `media_text | text`

- [ ] **Step 4: Add media_text to Typesense collection schema**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "curl -s -X PATCH 'http://localhost:8108/collections/content_documents' \
    -H 'X-TYPESENSE-API-KEY: tajiri-typesense-key-2026' \
    -H 'Content-Type: application/json' \
    -d '{\"fields\": [{\"name\": \"media_text\", \"type\": \"string\", \"optional\": true}]}'"
```

Expected: JSON response with updated collection schema

- [ ] **Step 5: Update ContentDocument model — add to $casts and $fillable**

Read the current model first to find the exact `$casts` and `$fillable` arrays, then add the two new fields.

In `app/Models/ContentDocument.php`:
- Add `'media_descriptions'` and `'media_text'` to the `$fillable` array
- Add `'media_descriptions' => 'array'` to the `$casts` array (media_text is plain text, no cast needed)

- [ ] **Step 6: Commit**

```bash
cd /var/www/tajiri.zimasystems.com && \
git add database/migrations/2026_03_29_400001_add_media_descriptions_to_content_documents.php app/Models/ContentDocument.php && \
git commit -m "feat(media-enrichment): add media_descriptions JSONB + media_text TEXT columns"
```

---

## Task 3: ImageAnalysisService

**Files:**
- Create: `app/Services/ContentEngine/ImageAnalysisService.php`

**Pattern reference:** Follow `EmbeddingTextService.php` — static-method class, shell out to `claude` CLI, sanitize inputs, try/catch with logging.

- [ ] **Step 1: Create ImageAnalysisService**

Create `app/Services/ContentEngine/ImageAnalysisService.php`:

```php
<?php

namespace App\Services\ContentEngine;

use Illuminate\Support\Facades\Log;

class ImageAnalysisService
{
    private const MAX_FILE_SIZE = 20 * 1024 * 1024; // 20MB

    private const PROMPT = 'Describe this image from a Tanzanian social media post. What do you see? Include people, objects, locations, text visible in the image, and cultural context. Write 2-3 sentences in English.';

    /**
     * Describe an image using Claude CLI vision.
     *
     * @param string $imagePath Absolute path to image file
     * @return string|null Description or null on failure
     */
    public static function describe(string $imagePath): ?string
    {
        try {
            if (!file_exists($imagePath)) {
                Log::warning('ImageAnalysis: File not found', ['path' => $imagePath]);
                return null;
            }

            $fileSize = filesize($imagePath);
            if ($fileSize > self::MAX_FILE_SIZE) {
                Log::warning('ImageAnalysis: File too large, skipping', [
                    'path' => $imagePath,
                    'size_mb' => round($fileSize / 1024 / 1024, 1),
                ]);
                return null;
            }

            // Validate it's actually an image
            $mime = mime_content_type($imagePath);
            if (!$mime || !str_starts_with($mime, 'image/')) {
                Log::warning('ImageAnalysis: Not an image file', ['path' => $imagePath, 'mime' => $mime]);
                return null;
            }

            $safePath = escapeshellarg(str_replace("\0", '', $imagePath));
            $safePrompt = escapeshellarg(self::PROMPT);

            $command = "timeout 30 claude -p {$safePrompt} --files {$safePath} --model haiku --output-format text 2>&1";

            $output = shell_exec($command);

            if ($output === null || trim($output) === '') {
                Log::warning('ImageAnalysis: Claude CLI returned empty output', ['path' => $imagePath]);
                return null;
            }

            $description = trim($output);

            // Sanity check — Claude sometimes returns error messages
            if (str_starts_with($description, 'Error') || str_starts_with($description, 'Usage:')) {
                Log::warning('ImageAnalysis: Claude CLI error', ['output' => substr($description, 0, 200)]);
                return null;
            }

            return $description;

        } catch (\Throwable $e) {
            Log::error('ImageAnalysis: Exception', [
                'path' => $imagePath,
                'error' => $e->getMessage(),
            ]);
            return null;
        }
    }
}
```

- [ ] **Step 2: Smoke test with a real image on the server**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "cd /var/www/tajiri.zimasystems.com && php8.3 artisan tinker --execute=\"
    \\\$path = storage_path('app/public');
    \\\$files = glob(\\\$path . '/**/*.{jpg,jpeg,png}', GLOB_BRACE);
    if (empty(\\\$files)) { echo 'No images found'; exit; }
    \\\$img = \\\$files[array_rand(\\\$files)];
    echo 'Testing: ' . \\\$img . PHP_EOL;
    \\\$result = \App\Services\ContentEngine\ImageAnalysisService::describe(\\\$img);
    echo 'Result: ' . (\\\$result ?? 'NULL') . PHP_EOL;
  \""
```

Expected: A 2-3 sentence English description of the image.

- [ ] **Step 3: Commit**

```bash
cd /var/www/tajiri.zimasystems.com && \
git add app/Services/ContentEngine/ImageAnalysisService.php && \
git commit -m "feat(media-enrichment): add ImageAnalysisService — Claude CLI vision"
```

---

## Task 4: AudioTranscriptionService

**Files:**
- Create: `app/Services/ContentEngine/AudioTranscriptionService.php`

**Dependencies:** Whisper CLI + Claude CLI (installed in Task 1)

- [ ] **Step 1: Create AudioTranscriptionService**

Create `app/Services/ContentEngine/AudioTranscriptionService.php`:

```php
<?php

namespace App\Services\ContentEngine;

use Illuminate\Support\Facades\Log;

class AudioTranscriptionService
{
    private const MAX_DURATION_SECONDS = 300; // 5 minutes
    private const WHISPER_MODEL = 'small';

    private const CLEANUP_PROMPT = 'Fix spelling/grammar errors in this transcript. Clean up sentence boundaries. Write a 1-2 sentence English summary. Detect the language. Respond ONLY as valid JSON with no markdown wrapping: {"clean_transcript": "...", "summary": "...", "detected_language": "sw|en|mixed"}';

    /**
     * Transcribe audio using Whisper, clean with Claude Haiku.
     *
     * @param string $audioPath Absolute path to audio file
     * @param string|null $identifier Unique ID for temp directory naming
     * @return array|null ['raw_transcript', 'clean_transcript', 'summary', 'detected_language'] or null
     */
    public static function transcribe(string $audioPath, ?string $identifier = null): ?array
    {
        $tmpDir = null;

        try {
            if (!file_exists($audioPath)) {
                Log::warning('AudioTranscription: File not found', ['path' => $audioPath]);
                return null;
            }

            // Check duration via ffprobe
            $duration = self::getAudioDuration($audioPath);
            if ($duration !== null && $duration > self::MAX_DURATION_SECONDS) {
                Log::warning('AudioTranscription: Audio too long, skipping', [
                    'path' => $audioPath,
                    'duration' => $duration,
                ]);
                return null;
            }

            $id = $identifier ?? uniqid('audio_');
            $tmpDir = "/tmp/whisper_{$id}";
            @mkdir($tmpDir, 0755, true);

            $safePath = escapeshellarg(str_replace("\0", '', $audioPath));
            $safeTmpDir = escapeshellarg($tmpDir);

            // Run Whisper (auto-detect language, small model)
            $whisperCmd = "timeout 120 whisper {$safePath} --model " . self::WHISPER_MODEL
                . " --output_format txt --output_dir {$safeTmpDir} 2>&1";

            $whisperOutput = shell_exec($whisperCmd);

            // Find the output .txt file (Whisper names it after input basename)
            $txtFiles = glob("{$tmpDir}/*.txt");
            if (empty($txtFiles)) {
                Log::warning('AudioTranscription: Whisper produced no output', [
                    'path' => $audioPath,
                    'whisper_output' => substr($whisperOutput ?? '', 0, 500),
                ]);
                return null;
            }

            $rawTranscript = trim(file_get_contents($txtFiles[0]));
            if ($rawTranscript === '') {
                Log::warning('AudioTranscription: Empty transcript', ['path' => $audioPath]);
                return null;
            }

            // Send to Claude Haiku for cleanup
            $cleanupResult = self::claudeCleanup($rawTranscript);

            return [
                'raw_transcript' => $rawTranscript,
                'clean_transcript' => $cleanupResult['clean_transcript'] ?? $rawTranscript,
                'summary' => $cleanupResult['summary'] ?? '',
                'detected_language' => $cleanupResult['detected_language'] ?? 'unknown',
            ];

        } catch (\Throwable $e) {
            Log::error('AudioTranscription: Exception', [
                'path' => $audioPath,
                'error' => $e->getMessage(),
            ]);
            return null;
        } finally {
            // Always clean up temp directory
            if ($tmpDir && is_dir($tmpDir)) {
                self::removeDir($tmpDir);
            }
        }
    }

    /**
     * Get audio duration in seconds via ffprobe.
     */
    public static function getAudioDuration(string $filePath): ?float
    {
        $safePath = escapeshellarg(str_replace("\0", '', $filePath));
        $cmd = "ffprobe -v quiet -print_format json -show_format {$safePath} 2>/dev/null";
        $output = shell_exec($cmd);

        if (!$output) return null;

        $data = json_decode($output, true);
        $duration = $data['format']['duration'] ?? null;

        return $duration !== null ? (float) $duration : null;
    }

    /**
     * Send transcript to Claude Haiku for cleanup and summarization.
     */
    private static function claudeCleanup(string $rawTranscript): array
    {
        try {
            // Truncate very long transcripts to avoid token limits
            $truncated = mb_substr($rawTranscript, 0, 3000);

            $prompt = self::CLEANUP_PROMPT . "\n\nTranscript:\n" . $truncated;
            $safePrompt = escapeshellarg(str_replace("\0", '', $prompt));

            $cmd = "timeout 30 claude -p {$safePrompt} --model haiku --output-format text 2>&1";
            $output = shell_exec($cmd);

            if (!$output || trim($output) === '') {
                return ['clean_transcript' => $rawTranscript, 'summary' => '', 'detected_language' => 'unknown'];
            }

            return self::parseJsonResponse(trim($output), $rawTranscript);

        } catch (\Throwable $e) {
            Log::warning('AudioTranscription: Claude cleanup failed', ['error' => $e->getMessage()]);
            return ['clean_transcript' => $rawTranscript, 'summary' => '', 'detected_language' => 'unknown'];
        }
    }

    /**
     * Parse JSON from Claude response, stripping markdown fences if present.
     * Falls back to raw transcript on parse failure.
     */
    public static function parseJsonResponse(string $response, string $fallbackTranscript = ''): array
    {
        // Strip markdown code fences: ```json ... ``` or ``` ... ```
        $cleaned = preg_replace('/^```(?:json)?\s*\n?/i', '', $response);
        $cleaned = preg_replace('/\n?```\s*$/', '', $cleaned);
        $cleaned = trim($cleaned);

        $data = json_decode($cleaned, true);

        if (json_last_error() === JSON_ERROR_NONE && is_array($data)) {
            return [
                'clean_transcript' => $data['clean_transcript'] ?? $fallbackTranscript,
                'summary' => $data['summary'] ?? '',
                'detected_language' => $data['detected_language'] ?? 'unknown',
            ];
        }

        Log::warning('AudioTranscription: JSON parse failed, using raw transcript', [
            'response_preview' => substr($response, 0, 200),
        ]);

        return ['clean_transcript' => $fallbackTranscript, 'summary' => '', 'detected_language' => 'unknown'];
    }

    /**
     * Recursively remove a directory. Public so VideoAnalysisService can reuse.
     */
    public static function removeDir(string $dir): void
    {
        if (!is_dir($dir)) return;
        $items = scandir($dir);
        foreach ($items as $item) {
            if ($item === '.' || $item === '..') continue;
            $path = $dir . '/' . $item;
            is_dir($path) ? self::removeDir($path) : @unlink($path);
        }
        @rmdir($dir);
    }
}
```

- [ ] **Step 2: Smoke test with a real audio file (or generate a test WAV)**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "cd /var/www/tajiri.zimasystems.com && php8.3 artisan tinker --execute=\"
    // Find an audio file in storage
    \\\$path = storage_path('app/public');
    \\\$files = array_merge(
        glob(\\\$path . '/**/*.mp3', GLOB_BRACE) ?: [],
        glob(\\\$path . '/**/*.wav', GLOB_BRACE) ?: [],
        glob(\\\$path . '/**/*.m4a', GLOB_BRACE) ?: []
    );
    if (empty(\\\$files)) {
        echo 'No audio files found. Testing with a generated WAV...' . PHP_EOL;
        shell_exec('ffmpeg -f lavfi -i sine=frequency=440:duration=3 -ar 16000 /tmp/test_audio.wav -y 2>/dev/null');
        \\\$files = ['/tmp/test_audio.wav'];
    }
    \\\$audio = \\\$files[0];
    echo 'Testing: ' . \\\$audio . PHP_EOL;
    \\\$result = \App\Services\ContentEngine\AudioTranscriptionService::transcribe(\\\$audio, 'test');
    print_r(\\\$result);
  \""
```

Expected: Array with `raw_transcript`, `clean_transcript`, `summary`, `detected_language`.

- [ ] **Step 3: Commit**

```bash
cd /var/www/tajiri.zimasystems.com && \
git add app/Services/ContentEngine/AudioTranscriptionService.php && \
git commit -m "feat(media-enrichment): add AudioTranscriptionService — Whisper + Claude cleanup"
```

---

## Task 5: VideoAnalysisService

**Files:**
- Create: `app/Services/ContentEngine/VideoAnalysisService.php`

**Dependencies:** FFmpeg, ImageAnalysisService (Task 3), AudioTranscriptionService (Task 4)

- [ ] **Step 1: Create VideoAnalysisService**

Create `app/Services/ContentEngine/VideoAnalysisService.php`:

```php
<?php

namespace App\Services\ContentEngine;

use Illuminate\Support\Facades\Log;

class VideoAnalysisService
{
    private const MAX_DURATION = 300; // 5 minutes
    private const MAX_KEYFRAMES = 6;

    private const SUMMARY_PROMPT = 'Given this video transcript and frame descriptions, write a rich 2-3 sentence summary covering the topic, visual content, and context. Suggest a content category from: entertainment, news, sports, business, technology, education, lifestyle, music, comedy, fashion, food, travel, health, politics, religion, culture, agriculture, other. Respond ONLY as valid JSON with no markdown wrapping: {"summary": "...", "suggested_category": "..."}';

    /**
     * Analyze a video: extract audio transcript + keyframe descriptions + combined summary.
     *
     * @param string $videoPath Absolute path to video file
     * @param float|null $duration Video duration in seconds (probed if null)
     * @param int|null $contentDocId For temp directory naming
     * @return array|null ['transcript', 'frame_descriptions', 'summary', 'suggested_category'] or null
     */
    public static function analyze(string $videoPath, ?float $duration = null, ?int $contentDocId = null): ?array
    {
        $tmpDir = null;

        try {
            if (!file_exists($videoPath)) {
                Log::warning('VideoAnalysis: File not found', ['path' => $videoPath]);
                return null;
            }

            // Probe duration if unknown
            if ($duration === null) {
                $duration = AudioTranscriptionService::getAudioDuration($videoPath);
            }

            // Duration guard
            if ($duration === null || $duration <= 0) {
                Log::warning('VideoAnalysis: Could not determine duration, skipping', ['path' => $videoPath]);
                return null;
            }

            if ($duration > self::MAX_DURATION) {
                Log::warning('VideoAnalysis: Video too long, skipping', [
                    'path' => $videoPath,
                    'duration' => $duration,
                ]);
                return null;
            }

            // Create unique temp directory
            $id = ($contentDocId ?? 0) . '_' . uniqid();
            $tmpDir = "/tmp/tajiri_enrich_{$id}";
            @mkdir($tmpDir, 0755, true);

            $safePath = escapeshellarg(str_replace("\0", '', $videoPath));

            // --- Step 1: Extract audio and transcribe ---
            $audioPath = "{$tmpDir}/audio.wav";
            $safeAudioPath = escapeshellarg($audioPath);

            $extractCmd = "timeout 30 ffmpeg -i {$safePath} -vn -acodec pcm_s16le -ar 16000 -ac 1 {$safeAudioPath} -y 2>/dev/null";
            shell_exec($extractCmd);

            $transcriptData = null;
            if (file_exists($audioPath) && filesize($audioPath) > 0) {
                $transcriptData = AudioTranscriptionService::transcribe($audioPath, "video_{$id}");
            } else {
                Log::info('VideoAnalysis: No audio track or extraction failed', ['path' => $videoPath]);
            }

            // --- Step 2: Extract keyframes ---
            $maxFrames = min(self::MAX_KEYFRAMES, (int) ceil($duration / 10));
            $maxFrames = max(1, $maxFrames);
            $interval = max(5, $duration / $maxFrames);

            $framePattern = "{$tmpDir}/frame_%02d.jpg";
            $safeFramePattern = escapeshellarg($framePattern);

            $frameCmd = "timeout 15 ffmpeg -i {$safePath} -vf \"fps=1/{$interval}\" -frames:v {$maxFrames} -q:v 2 {$safeFramePattern} -y 2>/dev/null";
            shell_exec($frameCmd);

            $frameFiles = glob("{$tmpDir}/frame_*.jpg");
            sort($frameFiles); // Ensure order

            $frameDescriptions = [];
            foreach ($frameFiles as $i => $framePath) {
                $timestamp = gmdate('i:s', (int) ($i * $interval));
                $description = ImageAnalysisService::describe($framePath);

                if ($description) {
                    $frameDescriptions[] = [
                        'timestamp' => $timestamp,
                        'description' => $description,
                    ];
                }

                // Rate limit: 1s between Claude CLI calls
                if ($i < count($frameFiles) - 1) {
                    sleep(1);
                }
            }

            // --- Step 3: Combined summary ---
            $summary = null;
            $suggestedCategory = null;

            $hasSomething = $transcriptData || !empty($frameDescriptions);
            if ($hasSomething) {
                $summaryResult = self::generateSummary(
                    $transcriptData['clean_transcript'] ?? '',
                    $frameDescriptions
                );
                $summary = $summaryResult['summary'] ?? null;
                $suggestedCategory = $summaryResult['suggested_category'] ?? null;
            }

            if (!$transcriptData && empty($frameDescriptions)) {
                Log::warning('VideoAnalysis: No transcript or frames extracted', ['path' => $videoPath]);
                return null;
            }

            return [
                'transcript' => $transcriptData['clean_transcript'] ?? null,
                'raw_transcript' => $transcriptData['raw_transcript'] ?? null,
                'detected_language' => $transcriptData['detected_language'] ?? null,
                'frame_descriptions' => $frameDescriptions,
                'summary' => $summary,
                'suggested_category' => $suggestedCategory,
            ];

        } catch (\Throwable $e) {
            Log::error('VideoAnalysis: Exception', [
                'path' => $videoPath,
                'error' => $e->getMessage(),
            ]);
            return null;
        } finally {
            if ($tmpDir && is_dir($tmpDir)) {
                AudioTranscriptionService::removeDir($tmpDir);
            }
        }
    }

    /**
     * Generate a combined summary from transcript + frame descriptions.
     */
    private static function generateSummary(string $transcript, array $frameDescriptions): array
    {
        try {
            $parts = [];
            if ($transcript) {
                $parts[] = "Transcript: " . mb_substr($transcript, 0, 1500);
            }
            if (!empty($frameDescriptions)) {
                $frameParts = [];
                foreach ($frameDescriptions as $fd) {
                    $frameParts[] = "[{$fd['timestamp']}] {$fd['description']}";
                }
                $parts[] = "Frame descriptions:\n" . implode("\n", $frameParts);
            }

            $context = implode("\n\n", $parts);
            $prompt = self::SUMMARY_PROMPT . "\n\n" . $context;
            $safePrompt = escapeshellarg(str_replace("\0", '', $prompt));

            $cmd = "timeout 30 claude -p {$safePrompt} --model haiku --output-format text 2>&1";
            $output = shell_exec($cmd);

            if (!$output || trim($output) === '') {
                return [];
            }

            // Reuse the JSON parsing from AudioTranscriptionService
            $cleaned = preg_replace('/^```(?:json)?\s*\n?/i', '', trim($output));
            $cleaned = preg_replace('/\n?```\s*$/', '', $cleaned);
            $data = json_decode(trim($cleaned), true);

            if (json_last_error() === JSON_ERROR_NONE && is_array($data)) {
                return [
                    'summary' => $data['summary'] ?? null,
                    'suggested_category' => $data['suggested_category'] ?? null,
                ];
            }

            // Fallback: use raw output as summary
            return ['summary' => trim($output), 'suggested_category' => null];

        } catch (\Throwable $e) {
            Log::warning('VideoAnalysis: Summary generation failed', ['error' => $e->getMessage()]);
            return [];
        }
    }
}
```

- [ ] **Step 2: Smoke test with a real video file**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "cd /var/www/tajiri.zimasystems.com && php8.3 artisan tinker --execute=\"
    \\\$path = storage_path('app/public');
    \\\$files = array_merge(
        glob(\\\$path . '/**/*.mp4', GLOB_BRACE) ?: [],
        glob(\\\$path . '/**/*.mov', GLOB_BRACE) ?: []
    );
    if (empty(\\\$files)) {
        echo 'No video files found. Generating a test video...' . PHP_EOL;
        shell_exec('ffmpeg -f lavfi -i testsrc=duration=10:size=320x240:rate=1 -f lavfi -i sine=frequency=440:duration=10 -shortest /tmp/test_video.mp4 -y 2>/dev/null');
        \\\$files = ['/tmp/test_video.mp4'];
    }
    \\\$video = \\\$files[0];
    echo 'Testing: ' . \\\$video . PHP_EOL;
    \\\$result = \App\Services\ContentEngine\VideoAnalysisService::analyze(\\\$video);
    echo json_encode(\\\$result, JSON_PRETTY_PRINT) . PHP_EOL;
  \""
```

Expected: JSON with `transcript`, `frame_descriptions` array, `summary`, `suggested_category`.

- [ ] **Step 3: Commit**

```bash
cd /var/www/tajiri.zimasystems.com && \
git add app/Services/ContentEngine/VideoAnalysisService.php app/Services/ContentEngine/AudioTranscriptionService.php && \
git commit -m "feat(media-enrichment): add VideoAnalysisService — FFmpeg + Whisper + Claude keyframes"
```

---

## Task 6: MediaEnrichmentService + MediaEnrichmentJob

**Files:**
- Create: `app/Services/ContentEngine/MediaEnrichmentService.php`
- Create: `app/Jobs/ContentEngine/MediaEnrichmentJob.php`

**Dependencies:** ImageAnalysisService, AudioTranscriptionService, VideoAnalysisService (Tasks 3-5)

**Context:** The orchestrator loads a ContentDocument, finds its source Post + PostMedia, routes each media item to the right service, assembles the `media_descriptions` JSON, writes `media_text`, and dispatches downstream jobs.

- [ ] **Step 1: Create MediaEnrichmentService**

Create `app/Services/ContentEngine/MediaEnrichmentService.php`:

```php
<?php

namespace App\Services\ContentEngine;

use App\Models\ContentDocument;
use App\Jobs\ContentEngine\SyncToTypesenseJob;
use App\Jobs\ContentEngine\GenerateEmbeddingTextJob;
use Illuminate\Support\Facades\Log;

class MediaEnrichmentService
{
    /**
     * Enrich a content document with media descriptions.
     *
     * @param int $contentDocumentId
     * @param bool $force Re-process even if already enriched
     * @return bool True if any enrichment was done
     */
    public static function enrich(int $contentDocumentId, bool $force = false): bool
    {
        try {
            $doc = ContentDocument::find($contentDocumentId);
            if (!$doc) {
                Log::warning('MediaEnrichment: Document not found', ['id' => $contentDocumentId]);
                return false;
            }

            // Idempotency check
            if (!$force && $doc->media_descriptions !== null) {
                Log::info('MediaEnrichment: Already enriched, skipping', ['id' => $contentDocumentId]);
                return false;
            }

            // Only process posts and clips (they have media)
            if (!in_array($doc->source_type, ['post', 'clip'])) {
                return false;
            }

            // Load the source model with its media
            $sourceClass = $doc->source_type === 'post'
                ? \App\Models\Post::class
                : \App\Models\Clip::class;

            $source = $sourceClass::with('postMedia')->find($doc->source_id);
            if (!$source) {
                Log::warning('MediaEnrichment: Source not found', [
                    'type' => $doc->source_type,
                    'id' => $doc->source_id,
                ]);
                return false;
            }

            $storagePath = storage_path('app/public');
            $images = [];
            $audioItems = [];
            $videoItems = [];
            $mediaTextParts = [];

            // --- Process PostMedia items (images first, then audio, then video per spec) ---
            $postMedia = $source->postMedia ?? collect();

            // Images first (fastest)
            foreach ($postMedia->where('media_type', 'image') as $media) {
                $filePath = $storagePath . '/' . ltrim($media->file_path ?? '', '/');
                $description = ImageAnalysisService::describe($filePath);
                if ($description) {
                    $images[] = [
                        'media_id' => $media->id,
                        'description' => $description,
                    ];
                    $mediaTextParts[] = "[Image: {$description}]";
                }
                sleep(1); // Rate limit between Claude calls
            }

            // Audio second
            foreach ($postMedia->where('media_type', 'audio') as $media) {
                $filePath = $storagePath . '/' . ltrim($media->file_path ?? '', '/');
                $result = AudioTranscriptionService::transcribe($filePath, "media_{$media->id}");
                if ($result) {
                    $audioItems[] = array_merge(['media_id' => $media->id, 'source' => 'post_media'], $result);
                    if ($result['summary']) {
                        $mediaTextParts[] = "[Audio: {$result['summary']}]";
                    }
                    if ($result['clean_transcript']) {
                        $mediaTextParts[] = "[Transcript: " . mb_substr($result['clean_transcript'], 0, 500) . "]";
                    }
                }
            }

            // Video last (slowest)
            foreach ($postMedia->where('media_type', 'video') as $media) {
                $filePath = $storagePath . '/' . ltrim($media->file_path ?? '', '/');
                $result = VideoAnalysisService::analyze($filePath, null, $contentDocumentId);
                if ($result) {
                    $videoItems[] = [
                        'media_id' => $media->id,
                        'transcript' => $result['transcript'],
                        'frame_descriptions' => $result['frame_descriptions'],
                        'summary' => $result['summary'],
                    ];
                    if ($result['summary']) {
                        $mediaTextParts[] = "[Video: {$result['summary']}]";
                    }
                    // Auto-fill category from video analysis
                    if (empty($doc->category) && !empty($result['suggested_category'])) {
                        $doc->category = $result['suggested_category'];
                    }
                }
            }

            // Log unsupported media types
            foreach ($postMedia->whereNotIn('media_type', ['image', 'audio', 'video']) as $media) {
                Log::info('MediaEnrichment: Unsupported media type', [
                    'type' => $media->media_type,
                    'media_id' => $media->id,
                ]);
            }

            // --- Log unsupported document_path (future: PDF text extraction) ---
            if (!empty($source->document_path)) {
                Log::info('MediaEnrichment: Document media type not yet supported', [
                    'post_id' => $source->id,
                    'document_path' => $source->document_path,
                ]);
            }

            // --- Process standalone audio_path (audio posts without PostMedia) ---
            if (empty($audioItems) && !empty($source->audio_path)) {
                $audioFilePath = $storagePath . '/' . ltrim($source->audio_path, '/');
                $result = AudioTranscriptionService::transcribe($audioFilePath, "post_{$source->id}");
                if ($result) {
                    $audioItems[] = array_merge([
                        'media_id' => null,
                        'source' => 'post.audio_path',
                    ], $result);
                    if ($result['summary']) {
                        $mediaTextParts[] = "[Audio: {$result['summary']}]";
                    }
                    if ($result['clean_transcript']) {
                        $mediaTextParts[] = "[Transcript: " . mb_substr($result['clean_transcript'], 0, 500) . "]";
                    }
                }
            }

            // --- Check if we got anything ---
            if (empty($images) && empty($audioItems) && empty($videoItems)) {
                Log::info('MediaEnrichment: No media processed successfully', ['id' => $contentDocumentId]);
                return false;
            }

            // --- Assemble and save ---
            $mediaDescriptions = [
                'images' => $images,
                'audio' => $audioItems,
                'video' => $videoItems,
                'enriched_at' => now()->toIso8601String(),
            ];

            $mediaText = !empty($mediaTextParts) ? implode("\n", $mediaTextParts) : null;

            $doc->media_descriptions = $mediaDescriptions;
            $doc->media_text = $mediaText;
            $doc->save();

            // Dispatch downstream jobs for re-indexing
            SyncToTypesenseJob::dispatch($contentDocumentId)
                ->onQueue('typesense-sync');

            GenerateEmbeddingTextJob::dispatch($contentDocumentId)
                ->onQueue('content-embedding');

            Log::info('MediaEnrichment: Complete', [
                'id' => $contentDocumentId,
                'images' => count($images),
                'audio' => count($audioItems),
                'video' => count($videoItems),
            ]);

            return true;

        } catch (\Throwable $e) {
            Log::error('MediaEnrichment: Exception', [
                'id' => $contentDocumentId,
                'error' => $e->getMessage(),
            ]);
            return false;
        }
    }
}
```

- [ ] **Step 2: Create MediaEnrichmentJob**

Create `app/Jobs/ContentEngine/MediaEnrichmentJob.php`:

```php
<?php

namespace App\Jobs\ContentEngine;

use App\Services\ContentEngine\MediaEnrichmentService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class MediaEnrichmentJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public $tries = 2;
    public $backoff = 60;
    public $timeout = 600;

    public function __construct(
        public int $contentDocumentId,
        public bool $force = false,
    ) {}

    public function handle(): void
    {
        Log::info('MediaEnrichmentJob: Starting', [
            'content_document_id' => $this->contentDocumentId,
            'force' => $this->force,
        ]);

        $result = MediaEnrichmentService::enrich($this->contentDocumentId, $this->force);

        Log::info('MediaEnrichmentJob: Done', [
            'content_document_id' => $this->contentDocumentId,
            'enriched' => $result,
        ]);
    }
}
```

- [ ] **Step 3: Verify the job dispatches correctly via tinker**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "cd /var/www/tajiri.zimasystems.com && php8.3 artisan tinker --execute=\"
    // Find a content_document with media
    \\\$doc = \App\Models\ContentDocument::where('source_type', 'post')
        ->whereNull('media_descriptions')
        ->first();
    if (!\\\$doc) { echo 'No unenriched documents found'; exit; }
    echo 'Document ID: ' . \\\$doc->id . ', Source: post #' . \\\$doc->source_id . PHP_EOL;
    echo 'Dispatching MediaEnrichmentJob...' . PHP_EOL;
    \App\Jobs\ContentEngine\MediaEnrichmentJob::dispatch(\\\$doc->id, true)->onQueue('media-enrichment');
    echo 'Dispatched to media-enrichment queue' . PHP_EOL;
  \""
```

Expected: Job dispatched. (It won't process until the worker is started in Task 8.)

- [ ] **Step 4: Commit**

```bash
cd /var/www/tajiri.zimasystems.com && \
git add app/Services/ContentEngine/MediaEnrichmentService.php app/Jobs/ContentEngine/MediaEnrichmentJob.php && \
git commit -m "feat(media-enrichment): add MediaEnrichmentService orchestrator + queue job"
```

---

## Task 7: Modify Existing Files — ContentIngestionJob + SyncToTypesenseJob

**Files:**
- Modify: `app/Jobs/ContentEngine/ContentIngestionJob.php`
- Modify: `app/Jobs/ContentEngine/SyncToTypesenseJob.php`

**Context:** ContentIngestionJob currently dispatches 4 downstream jobs. We add a 5th: `MediaEnrichmentJob`. SyncToTypesenseJob needs to include `media_text` in the payload sent to Typesense.

- [ ] **Step 1: Read ContentIngestionJob to find the dispatch block**

Read `app/Jobs/ContentEngine/ContentIngestionJob.php` on the server. Find the section where it dispatches `SyncToTypesenseJob`, `GenerateEmbeddingJob`, `ClaudeScoreContentJob`, and `GenerateEmbeddingTextJob`. The new `MediaEnrichmentJob` dispatch goes after those 4.

- [ ] **Step 2: Add MediaEnrichmentJob dispatch to ContentIngestionJob**

After the existing 4 `dispatch()` calls, add:

```php
// Media enrichment — extract text from images/audio/video
MediaEnrichmentJob::dispatch($document->id)
    ->onQueue('media-enrichment');
```

Also add the `use` import at the top:
```php
use App\Jobs\ContentEngine\MediaEnrichmentJob;
```

- [ ] **Step 3: Read SyncToTypesenseJob to find the Typesense document payload**

Read `app/Jobs/ContentEngine/SyncToTypesenseJob.php`. Find where it builds the array/object sent to `TypesenseService::upsert()`. Add `'media_text' => $doc->media_text ?? ''` to that payload.

- [ ] **Step 4: Add media_text to SyncToTypesenseJob payload**

In the payload array, add:

```php
'media_text' => $doc->media_text ?? '',
```

- [ ] **Step 5: Verify by running a quick syntax check**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "cd /var/www/tajiri.zimasystems.com && \
   php8.3 -l app/Jobs/ContentEngine/ContentIngestionJob.php && \
   php8.3 -l app/Jobs/ContentEngine/SyncToTypesenseJob.php"
```

Expected: `No syntax errors detected` for both files.

- [ ] **Step 6: Commit**

```bash
cd /var/www/tajiri.zimasystems.com && \
git add app/Jobs/ContentEngine/ContentIngestionJob.php app/Jobs/ContentEngine/SyncToTypesenseJob.php && \
git commit -m "feat(media-enrichment): wire up MediaEnrichmentJob in ingestion pipeline + media_text in Typesense"
```

---

## Task 8: Backfill Command + Health Check Updates

**Files:**
- Create: `app/Console/Commands/EnrichMedia.php`
- Modify: `app/Console/Commands/ContentHealthCheck.php`

- [ ] **Step 1: Create EnrichMedia artisan command**

Create `app/Console/Commands/EnrichMedia.php`:

```php
<?php

namespace App\Console\Commands;

use App\Jobs\ContentEngine\MediaEnrichmentJob;
use App\Models\ContentDocument;
use Illuminate\Console\Command;

class EnrichMedia extends Command
{
    protected $signature = 'content:enrich-media
        {--batch-size=20 : Number of documents to process}
        {--post-id= : Process a specific post ID}
        {--force : Re-process already enriched documents}
        {--types= : Comma-separated media types to process (image,audio,video)}
        {--source-type= : Only process this source type (post, clip)}';

    protected $description = 'Backfill media enrichment for content documents with media';

    public function handle(): int
    {
        if ($postId = $this->option('post-id')) {
            $doc = ContentDocument::where('source_type', 'post')
                ->where('source_id', $postId)
                ->first();

            if (!$doc) {
                $this->error("No content document found for post #{$postId}");
                return 1;
            }

            $force = $this->option('force');
            $this->info("Dispatching enrichment for document #{$doc->id} (post #{$postId})" . ($force ? ' [force]' : ''));
            MediaEnrichmentJob::dispatch($doc->id, $force)->onQueue('media-enrichment');
            $this->info('Dispatched.');
            return 0;
        }

        $batchSize = (int) $this->option('batch-size');
        $force = $this->option('force');

        $query = ContentDocument::whereIn('source_type', ['post', 'clip'])
            ->where('content_tier', '!=', 'blackhole');

        if ($this->option('source-type')) {
            $query->where('source_type', $this->option('source-type'));
        }

        if (!$force) {
            $query->whereNull('media_descriptions');
        }

        // Only documents that have media (check via media_types array column)
        $query->whereRaw("media_types IS NOT NULL AND array_length(media_types, 1) > 0");

        // Filter by specific media types if requested
        if ($types = $this->option('types')) {
            $typeList = array_map('trim', explode(',', $types));
            foreach ($typeList as $type) {
                $query->orWhereRaw("? = ANY(media_types)", [$type]);
            }
        }

        $documents = $query->orderBy('published_at', 'desc')
            ->limit($batchSize)
            ->get();

        if ($documents->isEmpty()) {
            $this->info('No documents to enrich.');
            return 0;
        }

        $this->info("Dispatching enrichment for {$documents->count()} documents...");

        $dispatched = 0;
        foreach ($documents as $doc) {
            MediaEnrichmentJob::dispatch($doc->id, $force)->onQueue('media-enrichment');
            $dispatched++;
            $this->line("  Dispatched #{$doc->id} ({$doc->source_type} #{$doc->source_id})");

            // Rate limit: 2s between dispatches
            if ($dispatched < $documents->count()) {
                usleep(2_000_000);
            }
        }

        $this->info("Done. Dispatched {$dispatched} jobs to media-enrichment queue.");
        return 0;
    }
}
```

- [ ] **Step 2: Update ContentHealthCheck — add media enrichment checks**

Read `app/Console/Commands/ContentHealthCheck.php` on the server. Add 4 new checks after the existing checks:

```php
// --- Media Enrichment Checks ---

// Check FFmpeg
$ffmpegPath = trim(shell_exec('which ffmpeg 2>/dev/null') ?? '');
if ($ffmpegPath) {
    $this->info('✅ FFmpeg: available at ' . $ffmpegPath);
} else {
    $this->error('❌ FFmpeg: not found');
    $hasErrors = true;
}

// Check Whisper
$whisperPath = trim(shell_exec('which whisper 2>/dev/null') ?? '');
if ($whisperPath) {
    $this->info('✅ Whisper: available at ' . $whisperPath);
} else {
    $this->error('❌ Whisper: not found');
    $hasErrors = true;
}

// Check media enrichment worker
$supervisorStatus = shell_exec('supervisorctl status tajiri-media-enrichment:* 2>/dev/null') ?? '';
if (str_contains($supervisorStatus, 'RUNNING')) {
    $this->info('✅ Media enrichment worker: running');
} else {
    $this->warn('⚠️  Media enrichment worker: not running');
}

// Recent enrichment count
$enrichedCount = \App\Models\ContentDocument::whereNotNull('media_descriptions')
    ->where('updated_at', '>=', now()->subDay())
    ->count();
$this->info("📊 Media enrichments (last 24h): {$enrichedCount}");
```

- [ ] **Step 3: Verify both commands parse correctly**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "cd /var/www/tajiri.zimasystems.com && \
   php8.3 -l app/Console/Commands/EnrichMedia.php && \
   php8.3 -l app/Console/Commands/ContentHealthCheck.php && \
   php8.3 artisan content:enrich-media --help"
```

Expected: No syntax errors. Help text showing all options.

- [ ] **Step 4: Commit**

```bash
cd /var/www/tajiri.zimasystems.com && \
git add app/Console/Commands/EnrichMedia.php app/Console/Commands/ContentHealthCheck.php && \
git commit -m "feat(media-enrichment): add backfill command + health check updates"
```

---

## Task 9: Supervisor Worker + End-to-End Verification

**Files:**
- Modify: `/etc/supervisor/conf.d/tajiri-workers.conf`

- [ ] **Step 1: Add media-enrichment worker to Supervisor config**

Append to `/etc/supervisor/conf.d/tajiri-workers.conf`:

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

- [ ] **Step 2: Create log file and reload Supervisor**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "touch /var/log/tajiri/worker-media-enrichment.log && \
   supervisorctl reread && \
   supervisorctl update && \
   sleep 2 && \
   supervisorctl status"
```

Expected: All workers running, including `tajiri-media-enrichment:tajiri-media-enrichment_00 RUNNING`

- [ ] **Step 3: End-to-end test — enrich a real post**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "cd /var/www/tajiri.zimasystems.com && php8.3 artisan tinker --execute=\"
    // Find a post with images that hasn't been enriched
    \\\$doc = \App\Models\ContentDocument::where('source_type', 'post')
        ->whereNull('media_descriptions')
        ->whereRaw(\\\"media_types IS NOT NULL AND array_length(media_types, 1) > 0\\\")
        ->first();
    if (!\\\$doc) { echo 'No unenriched media posts found'; exit; }
    echo 'Enriching document #' . \\\$doc->id . ' (post #' . \\\$doc->source_id . ')' . PHP_EOL;
    echo 'Media types: ' . json_encode(\\\$doc->media_types) . PHP_EOL;

    // Dispatch and wait
    \App\Jobs\ContentEngine\MediaEnrichmentJob::dispatch(\\\$doc->id, true)->onQueue('media-enrichment');
    echo 'Job dispatched. Check worker log for progress.' . PHP_EOL;
  \""
```

- [ ] **Step 4: Wait ~30s, then verify the document was enriched**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "sleep 30 && cd /var/www/tajiri.zimasystems.com && php8.3 artisan tinker --execute=\"
    \\\$doc = \App\Models\ContentDocument::where('source_type', 'post')
        ->whereNotNull('media_descriptions')
        ->orderBy('updated_at', 'desc')
        ->first();
    if (!\\\$doc) { echo 'No enriched documents yet'; exit; }
    echo 'Document #' . \\\$doc->id . PHP_EOL;
    echo 'media_descriptions: ' . json_encode(\\\$doc->media_descriptions, JSON_PRETTY_PRINT) . PHP_EOL;
    echo PHP_EOL . 'media_text: ' . \\\$doc->media_text . PHP_EOL;
  \""
```

Expected: `media_descriptions` populated with images/audio/video arrays. `media_text` contains human-readable descriptions.

- [ ] **Step 5: Run health check to verify everything**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "cd /var/www/tajiri.zimasystems.com && php8.3 artisan content:health-check"
```

Expected: All checks passing, including FFmpeg, Whisper, media enrichment worker.

- [ ] **Step 6: Backfill a small batch**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "cd /var/www/tajiri.zimasystems.com && php8.3 artisan content:enrich-media --batch-size=5"
```

Expected: 5 jobs dispatched to `media-enrichment` queue.

- [ ] **Step 7: Commit supervisor config**

The supervisor config is outside the git repo, but commit a note or skip this step. All code is already committed from previous tasks.

---

## Verification Checklist

After all tasks complete, verify:

- [ ] `content_documents` table has `media_descriptions` (jsonb) and `media_text` (text) columns
- [ ] Typesense `content_documents` collection has `media_text` field
- [ ] `ffmpeg`, `ffprobe`, `whisper`, `claude` all accessible from CLI
- [ ] `php8.3 artisan content:health-check` — all green
- [ ] `supervisorctl status` — 5 workers running (2 default, 1 scoring, 1 embedding, 1 media-enrichment)
- [ ] At least 1 post enriched with real `media_descriptions` data
- [ ] `media_text` populated and searchable in Typesense
- [ ] `ContentIngestionJob` dispatches `MediaEnrichmentJob` for new posts
- [ ] `content:enrich-media` backfill command works with `--batch-size`, `--post-id`, `--force` options
