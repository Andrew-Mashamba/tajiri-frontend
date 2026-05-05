# Cover-Photo Upload Flow — Design Spec

**Date:** 2026-05-02
**Owner:** Andrew Mashamba
**Status:** Approved (ready for implementation)
**Companion:** `docs/ENGINEERING_PLAYBOOK.md`

---

## 1. Goal

Replace the current "tap → blind pick → silent upload → SnackBar" cover-photo flow on the profile screen with an industry-standard pick → crop → live-preview → upload pipeline. Cover canvas on the profile is full-width × 280dp.

## 2. Design principles

1. **Native crop UI** — use `image_cropper` (uCrop on Android, TOCropViewController on iOS) for muscle-memory parity with Photos.app.
2. **Single-step crop, locked aspect** — 16:9 lock, no free crop, no filters/adjustments. Pinch-zoom + drag-to-position inside a fixed-aspect viewport.
3. **Live preview before commit** — render the actual profile chrome (avatar circle, name overlay, gradient) on top of the cropped image so the user sees the real result. Industry pattern (LinkedIn, Facebook).
4. **Inline feedback only** — no SnackBars. Upload progress and errors render as overlays directly on the cover canvas.
5. **Tajiri Pay rail context** — N/A here (this is a profile asset, not a money flow), but Tajiri Pay default rail rule continues to apply elsewhere.
6. **Monochrome `#1A1A1A` / `#FAFAFA` chrome** on the cropper, matching the playbook palette.
7. **Bilingual default** — Swahili first user-facing, English as the `isSwahili ? sw : en` fallback per playbook.

## 3. The flow (3 user-facing screens)

```
[Profile screen]
  tap camera icon (bottom-right of cover canvas)
       │
       ▼
[CoverPhotoActionsSheet — modal bottom sheet]
  • Take photo (rear camera default)
  • Choose from gallery
  • Remove cover photo (only if a cover already exists)
       │ (gallery or camera selected)
       ▼
[image_picker]
  picks/captures source XFile (no maxWidth/maxHeight; full resolution)
       │
       ▼
[CoverCropScreen]
  image_cropper native UI
  • lockAspectRatio = true, ratio 16:9
  • monochrome chrome: #1A1A1A toolbar + status bar, #FAFAFA controls
  • rotate available, aspect-toggle hidden, reset hidden
  • title: "Hariri picha ya jalada" / "Edit cover photo"
       │
       ▼
[CoverPreviewScreen]
  Flutter screen rendering the actual profile chrome:
  • Cropped image at 16:9 → clipped to 280dp canvas height
  • Gradient overlay (matches profile cover overlay)
  • Avatar circle + name + @username overlay (uses current _profile)
  • Camera icon at bottom-right (matches profile screen position)
  • Bottom action row:
    [Sahihi / Save] (primary, dark, 48dp)
    [Hariri tena / Crop again] (secondary, outlined, 48dp)
    [Ghairi / Cancel] (text button)
       │ (Save tapped)
       ▼
[flutter_image_compress]
  format: jpeg, quality: 82, minWidth: 2048, minHeight: 1152,
  autoCorrectionAngle: true, keepExif: false
  output ~250-400 KB
       │
       ▼
[Dio PUT /api/users/{id}/cover-photo]
  multipart, onSendProgress callback, CancelToken
  display CoverUploadOverlay on cover canvas:
  • black 60% scrim
  • centered linear progress bar
  • "Inapakia..." / "Uploading..." label
  • [Ghairi / Cancel] button
       │
       ├─ on success
       │   • optimistic update of _profile.coverPhotoUrl
       │   • refresh _loadProfile()
       │   • dismiss overlay
       │
       └─ on failure
           • inline red banner on cover canvas
           • [Jaribu tena / Retry] action keeps cropped file in memory
```

## 4. Files plan

### 4.1 New (frontend)

| Path | Purpose |
|---|---|
| `lib/screens/profile/cover_photo/cover_photo_actions_sheet.dart` | Modal bottom sheet: Gallery / Camera / Remove. Drag handle 40×4 grey.shade300, 16dp padding, `BorderRadius.vertical(top: 16)`, 56dp tile rows. |
| `lib/screens/profile/cover_photo/cover_crop_screen.dart` | Thin wrapper around `ImageCropper.cropImage()` with TAJIRI's monochrome theme injected via `AndroidUiSettings` and `IOSUiSettings`. Exposed as `Future<File?> cropForCover(BuildContext, File source)`. |
| `lib/screens/profile/cover_photo/cover_preview_screen.dart` | Flutter screen — replicates profile chrome over the cropped image. Returns `bool` (true = save, false = re-crop). |
| `lib/screens/profile/cover_photo/cover_upload_overlay.dart` | StatefulWidget overlay rendered over the cover canvas during upload. Renders progress bar from a `ValueListenable<double>` plus cancel/retry. |
| `lib/screens/profile/cover_photo/cover_photo_orchestrator.dart` | Pure-logic class that drives the flow end-to-end: `CoverPhotoOrchestrator(profileService).run(BuildContext, userId, currentCoverUrl)`. Returns the new cover URL on success. Keeps `profile_screen.dart` clean. |

### 4.2 Modified (frontend)

| Path | Change |
|---|---|
| `pubspec.yaml` | Add `image_cropper: ^12.2.1`, `flutter_image_compress: ^2.4.0`. |
| `lib/services/profile_service.dart` | Add `removeCoverPhoto(int userId)` (DELETE). Replace `updateCoverPhoto` body with Dio variant exposing `onSendProgress` + `CancelToken`. |
| `lib/screens/profile/profile_screen.dart` | `_updateCoverPhoto()` becomes a one-liner: `CoverPhotoOrchestrator(_profileService).run(...)`. Old body deleted. Camera button position unchanged (already at bottom-right of canvas). |

### 4.3 Backend (SSH on `tajiri.zimasystems.com`)

| Path | Change |
|---|---|
| `routes/api.php` | Add `Route::delete('/users/{id}/cover-photo', [UserProfileController::class, 'removeCoverPhoto']);` |
| `app/Http/Controllers/Api/UserProfileController.php` | (a) Add `removeCoverPhoto(int $id)` method: find profile, delete storage file via `Storage::disk('public')->delete($profile->cover_photo_path)`, null `cover_photo_path`, save, fire `firebaseLiveUpdate->notifyUser($id, 'profile_updated')`, return 200 with `{success: true, data: {cover_photo_url: null}}`. (b) Extend `updateCoverPhoto` mimes validation: `jpeg,png,jpg,gif` → `jpeg,png,jpg,gif,webp`. |

## 5. Compression targets

| Concern | Value |
|---|---|
| Output format | JPEG (universal, no backend conversion needed) |
| Quality | 82 |
| Min width | 2048 px (covers 2× retina on phones up to ~1024 dp logical) |
| Min height | 1152 px |
| `autoCorrectionAngle` | true (handles iOS portrait orientation) |
| `keepExif` | **false** (strip EXIF, including GPS — privacy) |
| Typical output size | 250–400 KB |
| Max accepted by backend | 10 MB (existing `max:10240` rule) |

## 6. Bilingual strings

Inline `isSw ? "Swahili" : "English"` per playbook convention. Strings used:

| English | Swahili |
|---|---|
| Edit cover photo | Hariri picha ya jalada |
| Take photo | Piga picha |
| Choose from gallery | Chagua kutoka kwenye picha |
| Remove cover photo | Ondoa picha ya jalada |
| Save | Sahihi |
| Crop again | Hariri tena |
| Cancel | Ghairi |
| Uploading... | Inapakia... |
| Retry | Jaribu tena |
| Cover photo updated | Picha ya jalada imesasishwa |
| Failed to update cover photo | Imeshindwa kusasisha picha ya jalada |
| Cover photo removed | Picha ya jalada imeondolewa |

## 7. Engineering Playbook compliance

- [x] Monochrome `#1A1A1A` / `#FAFAFA` only; no colored buttons or icons (semantic-only colors for status badges).
- [x] 48dp minimum touch target on every action button.
- [x] `maxLines` + `TextOverflow.ellipsis` on every dynamic text widget.
- [x] No SnackBars — inline feedback overlay on the cover canvas.
- [x] No FAB.
- [x] Bottom sheet with drag handle 40×4 `grey.shade300`, `BorderRadius.vertical(top: 16)`, 16dp padding.
- [x] `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag` on any scrollable.
- [x] All async work guarded with `if (!mounted) return` after `await`.
- [x] All controllers (`AnimationController` for the optional progress shimmer) disposed.
- [x] Bilingual via inline `isSw` ternary; English is the default per playbook.
- [x] Optimistic-with-revert: cover URL updates locally on success, reverts on failure.
- [x] EXIF stripped before upload (privacy).
- [x] CancelToken on Dio request — user can abort mid-upload.

## 8. Out of scope (v2+)

- Focal-point picker (Twitter pulled theirs in 2021 over saliency bias — defer to v2 with manual override only).
- Auto-suggest crop via face/saliency detection.
- Animated/video covers.
- Theme-adaptive covers (separate light/dark crops).
- WebP server-side conversion via `intervention/image` (server already supports WebP; conversion is a v1.5 perf win).
- Live preview of the new cover on the *desktop/web* profile chrome (no web profile yet).

## 9. Acceptance criteria

1. Tapping the camera icon on cover canvas opens the bottom sheet, not the bare picker.
2. "Remove cover" only appears when a cover already exists; tapping it nulls the cover both client-side and server-side.
3. After picking/capturing, the cropper opens with a locked 16:9 viewport in monochrome chrome.
4. After cropping, the user sees a preview screen showing the cropped image with the actual profile chrome layered on top.
5. From preview, "Crop again" returns to the cropper with the original source image.
6. From preview, "Save" kicks off compression + Dio upload with a visible inline progress bar on the cover canvas.
7. Cancel button on the upload overlay aborts the request via `CancelToken`.
8. On failure, an inline red banner appears with a Retry action; tapping Retry re-uploads the same cropped+compressed file (no re-crop).
9. On success, the cover updates immediately without a page reload.
10. EXIF data is stripped from uploaded images (verifiable via `exiftool` on the resulting file in `storage/app/public/cover-photos/`).
11. `flutter analyze lib/` reports no new errors or warnings introduced by these changes.
