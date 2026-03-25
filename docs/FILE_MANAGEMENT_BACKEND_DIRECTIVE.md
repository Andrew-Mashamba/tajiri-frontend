# Backend Directive: User File Management (Dropbox-like Cloud Storage)

**Audience:** Backend developers
**Purpose:** Single source of truth for API contracts required so the **Tajiri Flutter app** can use the "My Files" (Nyaraka Zangu) feature end-to-end.
**Date:** 2026-03-05
**Related:** [BACKEND.md](BACKEND.md) | [MESSAGES_BACKEND_IMPLEMENTATION_DIRECTIVE.md](MESSAGES_BACKEND_IMPLEMENTATION_DIRECTIVE.md)

---

## 1. Overview

The "My Files" feature provides users with personal cloud storage (similar to Dropbox/Google Drive). Users can:

- Upload, download, and manage files (documents, archives)
- Create folders and organize files hierarchically
- Star/favorite important files
- Mark files for offline access
- Share files with other users or generate public links
- Search across their files
- View storage quota usage

The Flutter client expects a **REST API** backend. All file APIs MUST:

- Use **Bearer token** authentication (`Authorization: Bearer {token}`)
- Use the **base path** under which the app is configured (e.g. `https://zima-uat.site:8003/api`)
- Store files securely (e.g., S3, local storage with proper access controls)
- Enforce per-user storage quotas

---

## 2. Authentication

| Context | How the app sends auth |
|---------|-------------------------|
| REST | `Authorization: Bearer {access_token}`. Also sends `user_id` in query/body for explicit user context. |
| File Downloads | Bearer token in header OR signed URLs with expiration. |

**Security Rules:**
- Users can only access their own files unless explicitly shared
- Shared file access requires valid share link or explicit permission
- Downloaded files should use signed URLs with short expiration (e.g., 1 hour)

---

## 3. Database Schema

### 3.1 `user_files` table

```sql
CREATE TABLE user_files (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    folder_id BIGINT UNSIGNED NULL,           -- Parent folder ID (NULL = root)
    name VARCHAR(255) NOT NULL,               -- Original filename
    display_name VARCHAR(255) NULL,           -- Custom display name
    path VARCHAR(1024) NOT NULL DEFAULT '/',  -- Virtual path (e.g., '/Documents/Work/')
    parent_path VARCHAR(1024) NULL,           -- Parent folder path
    storage_path VARCHAR(1024) NOT NULL,      -- Actual storage path (S3 key or local path)
    mime_type VARCHAR(127) NOT NULL DEFAULT 'application/octet-stream',
    size BIGINT UNSIGNED NOT NULL DEFAULT 0,  -- File size in bytes
    is_folder BOOLEAN NOT NULL DEFAULT FALSE,
    is_starred BOOLEAN NOT NULL DEFAULT FALSE,
    is_offline BOOLEAN NOT NULL DEFAULT FALSE,
    is_shared BOOLEAN NOT NULL DEFAULT FALSE,
    share_token VARCHAR(64) NULL UNIQUE,      -- For public share links
    share_expires_at TIMESTAMP NULL,
    thumbnail_path VARCHAR(1024) NULL,        -- For document previews (PDFs, etc.)
    preview_path VARCHAR(1024) NULL,          -- Full preview if generated
    last_accessed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,                -- Soft delete for trash/recovery

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (folder_id) REFERENCES user_files(id) ON DELETE CASCADE,

    INDEX idx_user_files_user_id (user_id),
    INDEX idx_user_files_folder_id (folder_id),
    INDEX idx_user_files_path (user_id, path),
    INDEX idx_user_files_starred (user_id, is_starred),
    INDEX idx_user_files_mime_type (user_id, mime_type),
    INDEX idx_user_files_updated (user_id, updated_at DESC),
    INDEX idx_user_files_share_token (share_token)
);
```

### 3.2 `user_file_shares` table (for sharing with specific users)

```sql
CREATE TABLE user_file_shares (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    file_id BIGINT UNSIGNED NOT NULL,
    shared_by_user_id BIGINT UNSIGNED NOT NULL,
    shared_with_user_id BIGINT UNSIGNED NOT NULL,
    permission ENUM('view', 'edit') NOT NULL DEFAULT 'view',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (file_id) REFERENCES user_files(id) ON DELETE CASCADE,
    FOREIGN KEY (shared_by_user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (shared_with_user_id) REFERENCES users(id) ON DELETE CASCADE,

    UNIQUE KEY unique_file_share (file_id, shared_with_user_id)
);
```

### 3.3 `user_storage_quotas` table

```sql
CREATE TABLE user_storage_quotas (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL UNIQUE,
    used_bytes BIGINT UNSIGNED NOT NULL DEFAULT 0,
    total_bytes BIGINT UNSIGNED NOT NULL DEFAULT 5368709120,  -- 5GB default
    file_count INT UNSIGNED NOT NULL DEFAULT 0,
    folder_count INT UNSIGNED NOT NULL DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

---

## 4. REST API Endpoints

Base URL = app's API base (e.g. `https://zima-uat.site:8003/api`). Paths are relative to that.

### 4.1 File Listing and Search

| Method | Path | Purpose | Query Parameters | Response |
|--------|------|---------|------------------|----------|
| `GET` | `/files` | List user's files | `user_id` (required), `folder_id`, `path`, `category`, `starred`, `offline`, `shared`, `search`, `sort_by`, `sort_order`, `page`, `per_page` | `200`: See response format below |
| `GET` | `/files/recent` | Get recently accessed files | `user_id` (required), `limit` (default 20) | `200`: `{ "success": true, "data": [...] }` |
| `GET` | `/files/quota` | Get storage quota | `user_id` (required) | `200`: See quota response below |
| `GET` | `/files/{id}` | Get single file details | — | `200`: `{ "success": true, "data": {...} }` |

**List Files Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "user_id": 4,
      "name": "document.pdf",
      "display_name": "My Important Document",
      "path": "/Documents/",
      "parent_path": "/",
      "folder_id": 5,
      "mime_type": "application/pdf",
      "size": 1048576,
      "thumbnail_url": "https://storage.example.com/thumbs/1.jpg",
      "preview_url": "https://storage.example.com/previews/1.pdf",
      "download_url": "https://storage.example.com/files/1/download?token=xxx",
      "is_folder": false,
      "is_starred": true,
      "is_offline": false,
      "is_shared": false,
      "shared_with_count": 0,
      "created_at": "2026-03-01T10:00:00Z",
      "updated_at": "2026-03-05T14:30:00Z",
      "last_accessed_at": "2026-03-05T14:30:00Z"
    }
  ],
  "quota": {
    "used": 104857600,
    "total": 5368709120,
    "file_count": 45,
    "folder_count": 12
  },
  "meta": {
    "current_page": 1,
    "per_page": 50,
    "total": 45
  }
}
```

**Quota Response:**
```json
{
  "success": true,
  "data": {
    "used": 104857600,
    "total": 5368709120,
    "file_count": 45,
    "folder_count": 12
  }
}
```

**Query Parameter Details:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `user_id` | int | required | User whose files to list |
| `folder_id` | int | null | Filter by parent folder ID |
| `path` | string | "/" | Filter by virtual path |
| `category` | string | null | Filter by category: `document`, `archive`, `other` |
| `starred` | bool | null | If `1`, return only starred files |
| `offline` | bool | null | If `1`, return only offline-marked files |
| `shared` | bool | null | If `1`, return only shared files |
| `search` | string | null | Full-text search in file names |
| `sort_by` | string | "updated_at" | Sort field: `name`, `size`, `created_at`, `updated_at` |
| `sort_order` | string | "desc" | Sort direction: `asc`, `desc` |
| `page` | int | 1 | Page number |
| `per_page` | int | 50 | Items per page (max 100) |

### 4.2 File Upload

| Method | Path | Purpose | Request | Response |
|--------|------|---------|---------|----------|
| `POST` | `/files` | Upload single file | Multipart: `file`, `user_id`, `folder_id`?, `path`?, `display_name`? | `201`: `{ "success": true, "data": {...}, "message": "File uploaded" }` |
| `POST` | `/files/batch` | Upload multiple files | Multipart: `files[]`, `user_id`, `folder_id`?, `path`? | `201`: `{ "success": true, "data": [...], "message": "X files uploaded" }` |

**Upload Validation:**
- Check storage quota before accepting upload
- Validate MIME types (allow: documents, archives; block: executables, scripts)
- Maximum file size: 100MB per file (configurable)
- Maximum batch size: 10 files

**Allowed MIME Types:**
```
# Documents
application/pdf
application/msword
application/vnd.openxmlformats-officedocument.wordprocessingml.document
application/vnd.ms-excel
application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
application/vnd.ms-powerpoint
application/vnd.openxmlformats-officedocument.presentationml.presentation
text/plain
text/csv
text/rtf

# Archives
application/zip
application/x-rar-compressed
application/x-7z-compressed
application/x-tar
application/gzip
```

### 4.3 Folder Operations

| Method | Path | Purpose | Request Body | Response |
|--------|------|---------|--------------|----------|
| `POST` | `/files/folders` | Create folder | `{ "user_id", "name", "parent_folder_id"?, "path"? }` | `201`: `{ "success": true, "data": {...}, "message": "Folder created" }` |

**Folder Response:**
```json
{
  "success": true,
  "data": {
    "id": 10,
    "user_id": 4,
    "name": "Work Documents",
    "display_name": null,
    "path": "/Documents/Work Documents/",
    "parent_path": "/Documents/",
    "folder_id": 5,
    "mime_type": "folder",
    "size": 0,
    "is_folder": true,
    "is_starred": false,
    "is_shared": false,
    "item_count": 0,
    "total_size": 0,
    "created_at": "2026-03-05T15:00:00Z",
    "updated_at": "2026-03-05T15:00:00Z"
  },
  "message": "Folder created"
}
```

### 4.4 File Actions

| Method | Path | Purpose | Request Body | Response |
|--------|------|---------|--------------|----------|
| `PATCH` | `/files/{id}/rename` | Rename file/folder | `{ "name": "new_name" }` | `200`: Updated file object |
| `PATCH` | `/files/{id}/move` | Move file/folder | `{ "target_folder_id"?: int, "target_path"?: string }` | `200`: Updated file object |
| `POST` | `/files/{id}/copy` | Copy file | `{ "target_folder_id"?, "target_path"? }` | `201`: New file object |
| `DELETE` | `/files/{id}` | Delete file/folder | — | `200`: `{ "success": true }` |
| `DELETE` | `/files/batch` | Delete multiple | `{ "file_ids": [1, 2, 3] }` | `200`: `{ "success": true }` |
| `PATCH` | `/files/{id}/star` | Toggle star | — | `200`: Updated file object |
| `PATCH` | `/files/{id}/offline` | Toggle offline | — | `200`: Updated file object |

### 4.5 File Sharing

| Method | Path | Purpose | Request Body | Response |
|--------|------|---------|--------------|----------|
| `POST` | `/files/{id}/share` | Share file | `{ "user_ids"?: [int], "public_link"?: bool }` | `200`: `{ "success": true, "share_link"?: "https://..." }` |
| `DELETE` | `/files/{id}/share` | Revoke sharing | `{ "user_ids"?: [int], "revoke_public"?: bool }` | `200`: `{ "success": true }` |
| `GET` | `/files/shared/{token}` | Access shared file (public) | — | `200`: File data with download URL |

**Share Link Format:**
```
https://zima-uat.site/files/shared/{share_token}
```

### 4.6 File Download

| Method | Path | Purpose | Response |
|--------|------|---------|----------|
| `GET` | `/files/{id}/download` | Download file | `302` redirect to signed URL OR `200` with file stream |

**Signed URL Generation:**
- Generate temporary signed URLs valid for 1 hour
- Include in `download_url` field of file response
- For S3: Use pre-signed URLs
- For local storage: Generate token-based temporary URLs

---

## 5. Business Logic

### 5.1 Storage Quota Management

- **Default quota:** 5GB per user
- **Premium quota:** Configurable per user tier
- **On upload:** Check if `current_used + file_size <= total_quota`
- **On delete:** Subtract file size from used quota
- **Recalculate:** Provide admin endpoint to recalculate quota from actual files

### 5.2 Path Management

- Paths are virtual, not filesystem paths
- Always start with `/` and end with `/` for folders
- Examples:
  - Root: `/`
  - Folder: `/Documents/`
  - Nested: `/Documents/Work/2026/`

### 5.3 Folder Deletion

- Deleting a folder recursively deletes all contents
- Update storage quota accordingly
- Consider soft-delete with 30-day recovery period

### 5.4 File Type Categories

The app filters by category based on MIME type:

```php
function getCategory(string $mimeType): string {
    if (str_contains($mimeType, 'zip') ||
        str_contains($mimeType, 'rar') ||
        str_contains($mimeType, 'tar') ||
        str_contains($mimeType, '7z')) {
        return 'archive';
    }

    if (str_contains($mimeType, 'pdf') ||
        str_contains($mimeType, 'document') ||
        str_contains($mimeType, 'text') ||
        str_contains($mimeType, 'sheet') ||
        str_contains($mimeType, 'presentation') ||
        str_contains($mimeType, 'msword') ||
        str_contains($mimeType, 'officedocument')) {
        return 'document';
    }

    return 'other';
}
```

### 5.5 Search

- Full-text search on `name` and `display_name` fields
- Case-insensitive
- Support partial matching (LIKE '%query%')
- Consider adding full-text index for performance

---

## 6. Thumbnail/Preview Generation (Optional)

For documents, generate thumbnails/previews:

- **PDF:** First page as image thumbnail
- **Office documents:** Convert first page to image
- Use queued jobs for async processing
- Store in separate storage path (e.g., `thumbnails/`, `previews/`)

---

## 7. Rate Limiting

| Action | Limit | Scope |
|--------|-------|-------|
| List files | 60/min | per user |
| Upload file | 30/min | per user |
| Download file | 100/min | per user |
| Create folder | 20/min | per user |
| Delete files | 30/min | per user |
| Share file | 20/min | per user |

Return **429** with clear message when exceeded.

---

## 8. Error Responses

All error responses should follow this format:

```json
{
  "success": false,
  "message": "Human-readable error message",
  "error_code": "QUOTA_EXCEEDED"
}
```

**Error Codes:**

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `QUOTA_EXCEEDED` | 403 | User storage quota exceeded |
| `FILE_NOT_FOUND` | 404 | File/folder not found |
| `FOLDER_NOT_EMPTY` | 400 | Cannot delete non-empty folder (if not recursive) |
| `INVALID_FILE_TYPE` | 400 | File type not allowed |
| `FILE_TOO_LARGE` | 400 | File exceeds size limit |
| `INVALID_PATH` | 400 | Invalid path format |
| `NAME_EXISTS` | 400 | File/folder with same name exists in location |
| `SHARE_EXPIRED` | 410 | Share link has expired |
| `ACCESS_DENIED` | 403 | User doesn't have access to this file |

---

## 9. Laravel Implementation Notes

### 9.1 Routes (api.php)

```php
Route::middleware('auth:sanctum')->group(function () {
    // File listing
    Route::get('/files', [FileController::class, 'index']);
    Route::get('/files/recent', [FileController::class, 'recent']);
    Route::get('/files/quota', [FileController::class, 'quota']);
    Route::get('/files/{id}', [FileController::class, 'show']);

    // Upload
    Route::post('/files', [FileController::class, 'store']);
    Route::post('/files/batch', [FileController::class, 'storeBatch']);

    // Folders
    Route::post('/files/folders', [FileController::class, 'createFolder']);

    // Actions
    Route::patch('/files/{id}/rename', [FileController::class, 'rename']);
    Route::patch('/files/{id}/move', [FileController::class, 'move']);
    Route::post('/files/{id}/copy', [FileController::class, 'copy']);
    Route::delete('/files/{id}', [FileController::class, 'destroy']);
    Route::delete('/files/batch', [FileController::class, 'destroyBatch']);
    Route::patch('/files/{id}/star', [FileController::class, 'toggleStar']);
    Route::patch('/files/{id}/offline', [FileController::class, 'toggleOffline']);

    // Sharing
    Route::post('/files/{id}/share', [FileController::class, 'share']);
    Route::delete('/files/{id}/share', [FileController::class, 'revokeShare']);

    // Download
    Route::get('/files/{id}/download', [FileController::class, 'download']);
});

// Public share access (no auth required)
Route::get('/files/shared/{token}', [FileController::class, 'accessSharedFile']);
```

### 9.2 Model (UserFile.php)

```php
class UserFile extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'user_id', 'folder_id', 'name', 'display_name', 'path',
        'parent_path', 'storage_path', 'mime_type', 'size',
        'is_folder', 'is_starred', 'is_offline', 'is_shared',
        'share_token', 'share_expires_at', 'thumbnail_path',
        'preview_path', 'last_accessed_at'
    ];

    protected $casts = [
        'is_folder' => 'boolean',
        'is_starred' => 'boolean',
        'is_offline' => 'boolean',
        'is_shared' => 'boolean',
        'share_expires_at' => 'datetime',
        'last_accessed_at' => 'datetime',
    ];

    protected $appends = ['download_url', 'thumbnail_url', 'preview_url'];

    public function user() {
        return $this->belongsTo(User::class);
    }

    public function parent() {
        return $this->belongsTo(UserFile::class, 'folder_id');
    }

    public function children() {
        return $this->hasMany(UserFile::class, 'folder_id');
    }

    public function getDownloadUrlAttribute() {
        if ($this->is_folder) return null;
        // Generate signed URL
        return URL::signedRoute('files.download', ['id' => $this->id], now()->addHour());
    }

    public function getThumbnailUrlAttribute() {
        if (!$this->thumbnail_path) return null;
        return Storage::disk('s3')->temporaryUrl($this->thumbnail_path, now()->addHour());
    }
}
```

---

## 10. Implementation Checklist

- [ ] **Database:** Create `user_files`, `user_file_shares`, `user_storage_quotas` tables with migrations
- [ ] **GET /files:** List files with filtering, sorting, pagination, and quota in response
- [ ] **GET /files/recent:** Return recently accessed files (order by `last_accessed_at`)
- [ ] **GET /files/quota:** Return storage quota for user
- [ ] **POST /files:** Single file upload with quota check and MIME validation
- [ ] **POST /files/batch:** Multiple file upload
- [ ] **POST /files/folders:** Create folder with path management
- [ ] **PATCH /files/{id}/rename:** Rename with duplicate name check
- [ ] **PATCH /files/{id}/move:** Move with path updates for nested items
- [ ] **POST /files/{id}/copy:** Copy file with new storage path
- [ ] **DELETE /files/{id}:** Delete with recursive folder handling and quota update
- [ ] **DELETE /files/batch:** Batch delete
- [ ] **PATCH /files/{id}/star:** Toggle starred status
- [ ] **PATCH /files/{id}/offline:** Toggle offline status
- [ ] **POST /files/{id}/share:** Generate share link or share with users
- [ ] **GET /files/{id}/download:** Serve file with signed URL
- [ ] **GET /files/shared/{token}:** Public access to shared files
- [ ] **Storage:** Configure S3 or local disk for file storage
- [ ] **Quota:** Implement quota tracking on upload/delete
- [ ] **Security:** Ensure users can only access own files or shared files
- [ ] **Rate limiting:** Apply rate limits per endpoint

---

## 11. Testing Checklist

- [ ] Upload file within quota - should succeed
- [ ] Upload file exceeding quota - should return 403 with QUOTA_EXCEEDED
- [ ] Upload disallowed file type (e.g., .exe) - should return 400
- [ ] Create nested folders and verify path construction
- [ ] Delete folder with contents - should delete recursively
- [ ] Star/unstar file and verify filtering works
- [ ] Search files by name - partial match should work
- [ ] Share file and access via public link
- [ ] Share file with another user and verify access
- [ ] Move file to different folder and verify path updates
- [ ] Verify quota recalculates correctly after operations

---

*Back to [README.md](README.md) | [BACKEND.md](BACKEND.md)*
