#!/usr/bin/env bash
# Test comments API (list + add) against the backend.
# Usage:
#   ./scripts/test_comments_api.sh [BASE_URL] [POST_ID] [USER_ID]
# Example:
#   ./scripts/test_comments_api.sh https://zima-uat.site:8003/api 42 1
# Optional: set BEARER_TOKEN for authenticated requests (e.g. add comment).

set -e
BASE_URL="${1:-https://zima-uat.site:8003/api}"
POST_ID="${2:-1}"
USER_ID="${3:-1}"
echo "Base URL: $BASE_URL"
echo "Post ID:  $POST_ID"
echo "User ID:  $USER_ID"
echo ""

# 1) List comments (GET) – no auth required if backend allows public read
echo "=== GET /posts/$POST_ID/comments?page=1&per_page=20 ==="
CURL_OPTS=(-s -w "\nHTTP %{http_code}" "$BASE_URL/posts/$POST_ID/comments?page=1&per_page=20")
if [ -n "${BEARER_TOKEN:-}" ]; then
  curl "${CURL_OPTS[@]}" -H "Accept: application/json" -H "Authorization: Bearer $BEARER_TOKEN" | tail -20
else
  curl "${CURL_OPTS[@]}" -H "Accept: application/json" | tail -20
fi
echo ""
echo ""

# 2) Add comment (POST) – usually requires auth
echo "=== POST /posts/$POST_ID/comments (add comment) ==="
CURL_OPTS=(-s -w "\nHTTP %{http_code}" -X POST "$BASE_URL/posts/$POST_ID/comments" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{\"user_id\": $USER_ID, \"content\": \"Test comment from script at $(date +%Y-%m-%dT%H:%M:%S)\"}")
if [ -n "${BEARER_TOKEN:-}" ]; then
  curl "${CURL_OPTS[@]}" -H "Authorization: Bearer $BEARER_TOKEN" | tail -20
else
  curl "${CURL_OPTS[@]}" | tail -20
fi
echo ""

# Expected list response shape (so backend can be checked):
# {
#   "success": true,
#   "data": [
#     {
#       "id": 1,
#       "post_id": 5,
#       "user_id": 10,
#       "parent_id": null,
#       "content": "Nice post!",
#       "likes_count": 0,
#       "created_at": "2025-02-14T12:00:00.000000Z",
#       "updated_at": "2025-02-14T12:00:00.000000Z",
#       "user": { "id": 10, "first_name": "...", "last_name": "...", "profile_photo_path": null },
#       "replies": []
#     }
#   ],
#   "meta": { "current_page": 1, "per_page": 20, "total": 50 }
# }
