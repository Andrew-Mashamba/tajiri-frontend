# Backend Performance Tasks

**Date:** 2026-03-31
**Context:** The frontend has shipped all 5 phases of the performance strategy. Three backend changes are required to unlock BlurHash placeholders and HTTP caching. Without these, the frontend features degrade gracefully (grey placeholders instead of blur, full responses instead of 304s).

**Server:** `172.240.241.180` — `/var/www/tajiri.zimasystems.com`

---

## Task 1: BlurHash Generation (CRITICAL — enables blur placeholders)

### 1A. Install dependency

```bash
cd /var/www/tajiri.zimasystems.com
composer require kornrunner/php-blurhash
```

### 1B. Database migrations

```bash
php artisan make:migration add_blurhash_to_post_media_table
php artisan make:migration add_avatar_blurhash_to_user_profiles_table
```

**Migration 1 — `post_media`:**
```php
public function up(): void
{
    Schema::table('post_media', function (Blueprint $table) {
        $table->string('blurhash', 50)->nullable()->after('dominant_color');
    });
}

public function down(): void
{
    Schema::table('post_media', function (Blueprint $table) {
        $table->dropColumn('blurhash');
    });
}
```

**Migration 2 — `user_profiles`:**
```php
public function up(): void
{
    Schema::table('user_profiles', function (Blueprint $table) {
        $table->string('avatar_blurhash', 50)->nullable()->after('profile_photo_path');
    });
}

public function down(): void
{
    Schema::table('user_profiles', function (Blueprint $table) {
        $table->dropColumn('avatar_blurhash');
    });
}
```

Run: `php artisan migrate`

### 1C. Compute BlurHash on image upload

**File:** `app/Services/ImageProcessingService.php`

After the existing `extractDominantColor()` call (or wherever image processing happens for uploads), add BlurHash computation:

```php
use kornrunner\Blurhash\Blurhash;

/**
 * Compute BlurHash for an image file.
 * Returns a compact string (~20-30 chars) representing a blurred preview.
 */
public function computeBlurhash(string $imagePath): ?string
{
    try {
        $image = imagecreatefromstring(file_get_contents($imagePath));
        if (!$image) return null;

        // Resize to 32x32 for fast encoding
        $small = imagecreatetruecolor(32, 32);
        imagecopyresampled($small, $image, 0, 0, 0, 0, 32, 32, imagesx($image), imagesy($image));

        $pixels = [];
        for ($y = 0; $y < 32; $y++) {
            $row = [];
            for ($x = 0; $x < 32; $x++) {
                $rgb = imagecolorat($small, $x, $y);
                $row[] = [
                    ($rgb >> 16) & 0xFF,  // R
                    ($rgb >> 8) & 0xFF,   // G
                    $rgb & 0xFF,          // B
                ];
            }
            $pixels[] = $row;
        }

        imagedestroy($image);
        imagedestroy($small);

        return Blurhash::encode($pixels, 4, 3);
    } catch (\Throwable $e) {
        \Log::warning('BlurHash computation failed: ' . $e->getMessage());
        return null;
    }
}
```

**Call it** wherever `PostMedia` records are created (typically in the upload/store controller or media processing job):

```php
$blurhash = $imageProcessingService->computeBlurhash($storedFilePath);
$media->blurhash = $blurhash;
$media->save();
```

Do the same for avatar uploads → store in `user_profiles.avatar_blurhash`.

### 1D. Include `blurhash` in API responses

Ensure the `PostMedia` model's `$appends` or `toArray()` includes `blurhash`. If using a Resource/Transformer, add it there.

**Frontend expects this JSON field name:** `"blurhash"` (exact, lowercase)

Example media object in API response:
```json
{
  "id": 123,
  "post_id": 456,
  "media_type": "image",
  "file_path": "posts/abc.jpg",
  "thumbnail_path": "posts/thumbs/abc.jpg",
  "dominant_color": "#3A7BD5",
  "blurhash": "LEHV6nWB2yk8pyo0adR*.7kCMdnj",
  "width": 1080,
  "height": 1350
}
```

### 1E. Backfill existing images

Create an artisan command to process existing `post_media` rows:

```bash
php artisan make:command BackfillBlurhash
```

```php
// app/Console/Commands/BackfillBlurhash.php
public function handle()
{
    $service = app(ImageProcessingService::class);

    PostMedia::whereNull('blurhash')
        ->where('media_type', 'image')
        ->chunkById(100, function ($media) use ($service) {
            foreach ($media as $item) {
                $path = storage_path('app/public/' . $item->file_path);
                if (!file_exists($path)) continue;

                $blurhash = $service->computeBlurhash($path);
                if ($blurhash) {
                    $item->update(['blurhash' => $blurhash]);
                }
            }
            $this->info("Processed batch...");
        });

    $this->info('Backfill complete.');
}
```

Run: `php artisan blurhash:backfill`

---

## Task 2: Fix V2 Feed Hydration (CRITICAL — media data missing from feed)

**Problem:** The V2 feed `hydrate()` method calls `toArray()` without eager-loading the `media` relation. This means `dominant_color`, `blurhash`, `thumbnail_path`, `width`, `height` are all **missing** from V2 feed API responses.

**Where to look:** `ServingPipelineService`, `FeedController`, or wherever the V2 feed hydration pipeline runs. Search for:
```bash
grep -r "hydrate\|toArray" app/Services/Feed/ app/Http/Controllers/Api/V2/
```

**Fix:** Add `->load('media')` before `toArray()` in the hydration step:

```php
// Before (broken):
$posts->each(fn ($post) => $post->toArray());

// After (fixed):
$posts->load('media');
$posts->each(fn ($post) => $post->toArray());
```

Or if using a query builder:
```php
// Add 'media' to the eager load
$posts = Post::with(['user', 'media', 'hashtags'])->...
```

**Affected endpoint:** `GET /api/v2/feed?feed_type={type}&page={n}&per_page={n}`

**How to verify:** Call the V2 feed endpoint and check that each post in the response includes a `media` array with `dominant_color`, `blurhash`, `thumbnail_path` fields.

---

## Task 3: ETag Middleware (enables HTTP conditional caching)

**Purpose:** The frontend now sends `If-None-Match` headers with cached ETags. When content hasn't changed, the server should return `304 Not Modified` (zero body) instead of re-sending the full response. This saves bandwidth and speeds up responses.

### 3A. Create ETag middleware

```bash
php artisan make:middleware ETagMiddleware
```

```php
// app/Http/Middleware/ETagMiddleware.php
namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ETagMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        // Only apply to successful GET responses with a body
        if ($request->isMethod('GET') && $response->isSuccessful()) {
            $etag = '"' . md5($response->getContent()) . '"';
            $response->headers->set('ETag', $etag);

            $requestEtag = $request->headers->get('If-None-Match');
            if ($requestEtag && $requestEtag === $etag) {
                $response->setStatusCode(304);
                $response->setContent('');
            }
        }

        return $response;
    }
}
```

### 3B. Register the middleware

**Option A — Route group (recommended):** Apply only to cacheable endpoints.

In your API routes file (`routes/api.php` or `routes/api_v2.php`):

```php
Route::middleware(['etag'])->group(function () {
    Route::get('/v2/feed', [FeedController::class, 'index']);
    Route::get('/users/{id}', [UserController::class, 'show']);
    Route::get('/shop/categories', [ShopController::class, 'categories']);
});
```

Register the alias in `app/Http/Kernel.php`:
```php
protected $middlewareAliases = [
    // ... existing aliases
    'etag' => \App\Http\Middleware\ETagMiddleware::class,
];
```

**Option B — Global (simpler but broader):** Add to the `api` middleware group in `Kernel.php`:
```php
'api' => [
    // ... existing middleware
    \App\Http\Middleware\ETagMiddleware::class,
],
```

### 3C. Frontend header contract

The frontend sends and expects:

| Direction | Header | Example Value |
|-----------|--------|---------------|
| Request → Server | `If-None-Match` | `"a1b2c3d4e5f6..."` |
| Server → Client | `ETag` | `"a1b2c3d4e5f6..."` |
| Server → Client (cache hit) | Status `304`, empty body | — |

**Important:** The ETag value must be wrapped in double quotes per HTTP spec. The `md5()` approach above handles this correctly.

---

## Priority & Dependencies

```
┌─────────────────────────────────────┐
│ Task 2: Fix V2 Feed Hydration       │ ← Do FIRST (media data missing now)
│ Difficulty: Low (1 line change)      │
│ Impact: CRITICAL                     │
└─────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Task 1: BlurHash Generation          │ ← Do SECOND (depends on Task 2)
│ Difficulty: Medium                   │
│ Steps: migration → service → backfill│
└─────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Task 3: ETag Middleware              │ ← Do THIRD (independent)
│ Difficulty: Low                      │
│ Impact: Bandwidth savings            │
└─────────────────────────────────────┘
```

## Verification Checklist

- [ ] `GET /api/v2/feed` response includes `media` array with `blurhash` field on each media item
- [ ] Upload a new image → response includes `blurhash` value (20-30 char string like `"LEHV6nWB2yk8..."`)
- [ ] `php artisan blurhash:backfill` processes existing images without errors
- [ ] `GET /api/v2/feed` with `If-None-Match` header returns `304` when content unchanged
- [ ] `GET /api/users/{id}` with `If-None-Match` returns `304` when profile unchanged
- [ ] `GET /api/shop/categories` with `If-None-Match` returns `304` when categories unchanged
