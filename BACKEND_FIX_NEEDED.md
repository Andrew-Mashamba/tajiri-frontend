# 🔧 Backend Fix Required for Immediate Livestreaming

## Issue: "Cannot start stream from 'scheduled' status"

### Problem Description
When a user selects **"Sasa" (Go Live Now)** in the app:
1. App creates stream with `scheduled_at = null` (indicating immediate livestream)
2. Backend creates stream with `status = 'scheduled'`
3. App navigates to backstage screen
4. User clicks "Enda Live"
5. App calls `POST /streams/{id}/start`
6. **❌ Backend rejects with: "Cannot start stream from 'scheduled' status"**

### Current Backend Behavior
According to BACKEND_REQUIREMENTS.md, the backend enforces this state flow:
```
scheduled → pre_live → live → ending → ended
```

The backend doesn't allow direct `scheduled → live` transition.

### Expected Backend Behavior

The backend should differentiate between two types of streams:

#### Type 1: Immediate Streams (`scheduled_at = null`)
- **Creation**: When `scheduled_at` is `null`, create stream with `status = 'pre_live'` instead of `'scheduled'`
- **Rationale**: Stream is meant to start immediately, not at a scheduled time
- **Flow**: `pre_live → live` ✅

#### Type 2: Scheduled Streams (`scheduled_at != null`)
- **Creation**: Create with `status = 'scheduled'` (current behavior)
- **Rationale**: Stream has a future start time, should show countdown to followers
- **Flow**: `scheduled → pre_live → live` ✅

### Recommended Backend Fix

**File**: `app/Http/Controllers/Api/StreamController.php`

```php
public function store(Request $request)
{
    $validated = $request->validate([
        'user_id' => 'required|exists:users,id',
        'title' => 'required|string|max:255',
        'scheduled_at' => 'nullable|date',
        // ... other fields
    ]);

    // Determine initial status based on scheduling
    $initialStatus = $validated['scheduled_at'] ? 'scheduled' : 'pre_live';

    $stream = LiveStream::create([
        'stream_key' => Str::random(32),
        'status' => $initialStatus,  // ← CHANGE HERE
        // ... other fields
    ]);

    return response()->json([
        'success' => true,
        'message' => 'Stream created',
        'data' => $stream->load('user'),
    ], 201);
}
```

### Alternative Fix (if initial status can't be changed)

Allow `POST /streams/{id}/start` to accept `scheduled → live` transition when `scheduled_at` is `null`:

```php
public function start(LiveStream $stream)
{
    // Allow direct scheduled → live transition for immediate streams
    if ($stream->status === 'scheduled' && $stream->scheduled_at === null) {
        $stream->update([
            'status' => 'live',
            'live_started_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Stream started',
            'data' => $stream->load('user'),
        ]);
    }

    // Existing validation for scheduled streams
    if ($stream->status !== 'pre_live') {
        return response()->json([
            'success' => false,
            'message' => "Cannot start stream from '{$stream->status}' status",
        ], 422);
    }

    // ... existing logic
}
```

### Test Cases

After implementing the fix, test these scenarios:

#### Test 1: Immediate Stream (Now)
```http
POST /api/streams
{
  "user_id": 6,
  "title": "Test Stream",
  "scheduled_at": null
}

Response: {
  "status": "pre_live"  // ← Should be pre_live, not scheduled
}
```

```http
POST /api/streams/{id}/start

Response: {
  "status": "live"  // ← Should succeed
}
```

#### Test 2: Scheduled Stream (Future)
```http
POST /api/streams
{
  "user_id": 6,
  "title": "Test Stream",
  "scheduled_at": "2026-01-29T18:00:00Z"
}

Response: {
  "status": "scheduled"  // ← Correct
}
```

```http
POST /api/streams/{id}/start

Response: {
  "success": false,
  "message": "Cannot start stream from 'scheduled' status"  // ← Correct (should fail)
}
```

### Impact

**Before Fix:**
- Users selecting "Sasa" (Now) get error when trying to go live
- They must use workaround: go to Profile > Live > Scheduled > Click "Anza Sasa"
- Poor user experience

**After Fix:**
- Users selecting "Sasa" (Now) can immediately go live from backstage ✅
- Smooth user flow as designed
- Better UX

### Priority
🔴 **HIGH** - Blocks immediate livestreaming feature

### Related Files
- Frontend: `/lib/screens/streams/go_live_screen.dart`
- Frontend: `/lib/services/livestream_service.dart`
- Backend: `/app/Http/Controllers/Api/StreamController.php`
- Backend: `/app/Models/LiveStream.php`
