# Profile-Photo (Avatar) Upload Flow — Design Spec

**Date:** 2026-05-02
**Owner:** Andrew Mashamba
**Status:** Approved (ready for implementation)
**Companion:** `docs/superpowers/specs/2026-05-02-cover-photo-upload-design.md`,
`docs/ENGINEERING_PLAYBOOK.md`

---

## 1. Goal

Bring the profile-photo (avatar) upload up to the same standard as the cover-photo flow shipped in `2026-05-02-cover-photo-upload-design.md`. Replaces the current "tap → blind pick → silent upload → SnackBar" pattern with pick → crop (1:1 with circular preview) → live profile-chrome preview → compress → upload-with-inline-progress.

## 2. Design principles

1. **Same orchestrator pattern as cover** — bottom sheet → pick/capture → crop → live preview → compress → Dio upload with inline progress + retry. Sister files, parallel structure.
2. **1:1 square output, circular crop preview** — `image_cropper` with `cropStyle: CropStyle.circle` (Android) and `IOSUiSettings.aspectRatioPickerButtonHidden` + locked 1:1 aspect (iOS). Stored as a square JPEG; rendered as a circle everywhere via `ClipOval`.
3. **Reuse `CoverCanvas`** for the live preview — show the user's *current* cover with the *new* avatar file overlaid, so they see how it'll look in real profile chrome. Extends `CoverCanvas` with an optional `avatarFile: File?` parameter (preferred over `avatarUrl` when both are present).
4. **Soft face hint, never block** — `FaceValidator.detectLargestFace()` runs in the preview screen. If no face or >1 face is detected, show a small inline note (*"Tip: a clear single-face photo reads best"*); upload still proceeds. Matches the existing non-blocking philosophy.
5. **`face_bbox` continues to be sent** to the backend for the existing face-embedding pipeline.
6. **Inline progress on the avatar circle** — reuse the `isUploadingAvatar` flag already wired into `CoverCanvas` (renders a black scrim + small spinner inside the avatar circle while upload is in flight). No SnackBars.
7. **Cache invalidation** on success (frontend `ProfileService` + frontend `CachedNetworkImage` cache for the previous avatar URL).
8. **EXIF stripped** via `flutter_image_compress` re-encode.

## 3. The flow

```
[Profile screen]
  tap avatar (own profile, no upload in flight)
       │
       ▼
[ProfilePhotoActionsSheet — modal bottom sheet]
  • Piga picha (rear camera, no — front-facing default for selfies)
  • Chagua kutoka kwenye picha
  • Ondoa picha ya profaili (only when one exists)
       │ (gallery or camera)
       ▼
[image_picker]
  preferredCameraDevice: front  (avatars are usually selfies)
       │
       ▼
[ProfilePhotoCropScreen]
  image_cropper 1:1 + circular preview
  • Android: cropStyle: CropStyle.circle, aspectRatio 1:1
  • iOS: aspectRatioLockEnabled: true, square frame, hide picker
  • monochrome chrome: #1A1A1A toolbar, #FAFAFA controls
  • title: "Hariri picha ya profaili" / "Edit profile photo"
       │
       ▼
[ProfilePhotoPreviewScreen]
  CoverCanvas wrapped in 16:9 AspectRatio:
    • cover = current coverPhotoUrl (or empty fallback)
    • avatarFile = new local file (so user sees their new avatar in chrome)
    • showStaticCameraIcon = true
  + soft face-validation hint banner above the canvas
  + Save / Crop again / Cancel actions
       │ (Save)
       ▼
[flutter_image_compress]
  format: jpeg, quality: 88, minWidth: 1024, minHeight: 1024,
  autoCorrectionAngle: true, keepExif: false
  output ~80–150 KB
       │
       ▼
[Dio POST /api/users/{id}/profile-photo]
  multipart with photo + face_bbox; onSendProgress + CancelToken
  CoverCanvas.isUploadingAvatar = true → black scrim + 28dp spinner
  inside the avatar circle on the cover canvas (no full-screen overlay)
       │
       ├─ on success
       │   • Hive user record updated with new profile_photo_url
       │   • CachedNetworkImage.evictFromCache(previousAvatarUrl)
       │   • _loadProfile() silently refetches (no _isLoading flip)
       │   • CoverCanvas.isUploadingAvatar = false
       │
       └─ on failure
           • inline red banner over the avatar circle area with Retry
           • cancelled vs failed handled distinctly (cancelled = silent dismiss)
```

## 4. Files plan

### 4.1 New (frontend)

| Path | Purpose |
|---|---|
| `lib/screens/profile/profile_photo/profile_photo_actions_sheet.dart` | Bottom sheet: Take photo / Choose from gallery / Remove (conditional). |
| `lib/screens/profile/profile_photo/profile_photo_crop_screen.dart` | `cropForAvatar(BuildContext, File source)` — image_cropper with 1:1 lock + circular UI + monochrome chrome. |
| `lib/screens/profile/profile_photo/profile_photo_preview_screen.dart` | Live profile-chrome preview using `CoverCanvas(cover: <existing>, avatarFile: <new>)`; soft face-validation hint banner; Save / Crop again / Cancel. |
| `lib/screens/profile/profile_photo/profile_photo_orchestrator.dart` | Pure-logic driver. Mirror of `CoverPhotoOrchestrator`. Exposes `progressListenable`, `phaseListenable`, `cancel()`, `dispose()`, `retryUpload()`, `lastCompressedFile`. |

### 4.2 Modified (frontend)

| Path | Change |
|---|---|
| `lib/services/profile_service.dart` | Add `removeProfilePhoto(int userId)` (DELETE). Replace `updateProfilePhoto` body with Dio variant exposing `onProgress` + `CancelToken` + `face_bbox` field. Invalidate cache on success. |
| `lib/screens/profile/cover_photo/cover_canvas.dart` | Add optional `avatarFile: File?` parameter; when non-null, render the avatar from that File via `Image.file` instead of from `avatarUrl`. |
| `lib/screens/profile/profile_screen.dart` | `_updateProfilePhoto()` becomes a one-liner orchestrator call; orchestrator drives the rest. Avatar tap continues to invoke this. The existing `_isUploadingPhoto` flag is wired into `CoverCanvas.isUploadingAvatar`. |

### 4.3 Backend (SSH on `tajiri.zimasystems.com`)

| Path | Change |
|---|---|
| `routes/api.php` | Add `Route::delete('/users/{id}/profile-photo', [UserProfileController::class, 'removeProfilePhoto']);` |
| `app/Http/Controllers/Api/UserProfileController.php` | (a) Add `removeProfilePhoto(int $id)` — find profile, `Storage::disk('public')->delete($profile->profile_photo_path)`, null `profile_photo_path` and `avatar_blurhash`, save, fire `firebaseLiveUpdate->notifyUserAndFriends($id, 'profile_updated')`, return 200. (b) Extend `updateProfilePhoto` mimes: `jpeg,png,jpg,gif` → `jpeg,png,jpg,gif,webp`. |

## 5. Compression targets

| Concern | Value |
|---|---|
| Output format | JPEG |
| Quality | 88 (slightly higher than cover — avatars are zoomed into more) |
| Min width | 1024 px |
| Min height | 1024 px |
| `autoCorrectionAngle` | true |
| `keepExif` | false |
| Typical output size | 80–150 KB |
| Max accepted by backend | 5 MB (existing `max:5120` rule) |

## 6. Bilingual strings (inline `isSw ? "Swahili" : "English"`)

| English | Swahili |
|---|---|
| Profile photo | Picha ya profaili |
| Edit profile photo | Hariri picha ya profaili |
| Take photo | Piga picha |
| Choose from gallery | Chagua kutoka kwenye picha |
| Remove profile photo | Ondoa picha ya profaili |
| Save | Hifadhi |
| Crop again | Hariri tena |
| Cancel | Ghairi |
| A clear single-face photo reads best | Picha yenye uso mmoja wazi inafanya vyema |
| Profile photo updated | Picha ya profaili imesasishwa |
| Failed to update profile photo | Imeshindwa kusasisha picha ya profaili |
| Profile photo removed | Picha ya profaili imeondolewa |

## 7. Out of scope (v2+)

- Animated avatars / video avatars.
- AI-generated avatars.
- Public/private avatar visibility.
- Multiple-photo galleries (a separate "photos" tab already exists).

## 8. Acceptance criteria

1. Tapping the avatar on own profile opens the bottom sheet (not the bare picker).
2. "Remove profile photo" only appears when a photo already exists; tapping nulls the avatar both client-side and server-side.
3. Cropper opens with a locked 1:1 viewport and circular preview overlay.
4. After cropping, preview screen shows the new avatar in real profile chrome (current cover + name overlay).
5. If FaceValidator detects 0 or >1 faces, a soft inline hint appears in the preview; Save still works.
6. Save → compression → Dio upload with onSendProgress; the inline overlay shows on the avatar circle only (not full page).
7. On success: avatar refetches via cache invalidation + `_loadProfile()` (silent — no full-page spinner).
8. On failure: inline red banner with Retry; CancelToken aborts a request mid-flight.
9. EXIF stripped on the resulting file in `storage/app/public/profile-photos/`.
10. `flutter analyze lib/` reports no new warnings.
