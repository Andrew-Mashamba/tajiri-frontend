# Backend advice: POST /api/posts — allow_comments validation (422)

## What happened

- **Frontend** sends create-post as **multipart/form-data** when there are media files.
- Multipart form fields are always **strings**. We were sending `allow_comments: "true"` (string).
- **Backend** responded **422**: `"The allow comments field must be true or false."`

## Frontend change (done)

- In `lib/services/post_service.dart`, for **multipart** requests we now send `allow_comments` as **`"1"`** or **`"0"`** (same as livestream/clip services), so Laravel’s usual boolean validation accepts it.
- JSON body (no files) still sends boolean `allow_comments: true/false`.

## Backend recommendation

So that both string and boolean forms work and 422 is avoided:

1. **POST /api/posts** (and any other multipart endpoint that has `allow_comments`):
   - Accept `allow_comments` as:
     - string `"1"` / `"0"` → treat as true/false, or
     - string `"true"` / `"false"` → treat as true/false, or
     - boolean `true` / `false` (when body is JSON).
   - Validate with a rule that accepts these (e.g. Laravel: `in:true,false,1,0,'1','0','true','false'` or cast from string then validate boolean).
   - Cast to boolean before storing (e.g. `filter_var($value, FILTER_VALIDATE_BOOLEAN)` or Laravel’s cast).

2. **Consistency**: Apply the same rule for `allow_comments` on livestream, clips, and any other multipart create/update that uses this field.

---

## Prompt to send to Backend Assistant

Use this with `./scripts/ask_backend.sh` (see [ASSISTANT_ENDPOINT_SKILL.md](ASSISTANT_ENDPOINT_SKILL.md)):

```bash
./scripts/ask_backend.sh --type implement --context "POST /api/posts validation" \
  "POST /api/posts receives multipart form data when the app uploads media. Form fields are strings. We send allow_comments as \"1\" or \"0\". The API currently returns 422: 'The allow comments field must be true or false.' Please update the validation for allow_comments so it accepts string \"1\"/\"0\" (and optionally \"true\"/\"false\") and cast to boolean before storing. Apply the same rule anywhere else we use allow_comments in multipart (e.g. livestream, clips) so validation is consistent."
```
