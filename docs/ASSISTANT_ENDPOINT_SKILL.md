# Skill: Talking to the Backend via the Assistant Endpoint

**Assistant reminder:** When you need backend support (new endpoint, fields, validation, response shape, etc.), **call this endpoint** using the **Backend Assistant Protocol** so responses are faster and unambiguous. Use `./scripts/ask_backend.sh --type <type> --context <context> "your ask"` when possible. See [BACKEND_ASSISTANT_PROTOCOL.md](BACKEND_ASSISTANT_PROTOCOL.md) for request/response format, types, and templates.

**When to use:** Whenever you (the assistant) need something done or clarified on the **backend** to support frontend work—new endpoints, field changes, validation rules, data shape, reports—**ask the backend AI** via this endpoint instead of guessing or asking the user to relay.

---

## Endpoint

| | |
|--|--|
| **URL** | `POST https://zima-uat.site:8003/api/ai/ask` |
| **Header** | `Content-Type: application/json` |
| **Body** | `{ "prompt": "Your question or directive here" }` |
| **Limit** | Prompt max **4000 characters** |
| **Timeout** | Backend proxy allows **600s** (10 min); script default 600s — be patient for heavy requests. |

---

## Request / Response

**Request:**
```json
{
  "prompt": "Your question or directive here (max 4000 chars)"
}
```

**Success (200):**
```json
{
  "success": true,
  "data": {
    "answer": "The AI's response in markdown format..."
  }
}
```

**Errors:**
- **400** — Missing/invalid prompt: `"prompt is required."`
- **400** — Too long: `"prompt exceeds 4000 characters."`
- **504** — Timeout: `"Request timed out. Please try a simpler question."`
- **503** — Unavailable: `"AI assistant is temporarily unavailable."`

---

## How the assistant should use this

1. **Use the protocol** (see [BACKEND_ASSISTANT_PROTOCOL.md](BACKEND_ASSISTANT_PROTOCOL.md)):
   - Prefer **structured prompts** with `[Type: ...]` and `[Context: ...]` so the backend can respond more predictably. Allow up to **10 minutes** (600s) for heavy implement requests; the script timeout matches the backend proxy.
   - **One main ask per prompt** to avoid timeouts. For complex features: first `[Type: schema]` (plan), then `[Type: implement]` (code).
   - After implementing the backend’s response, send `[Type: confirm]` with a short summary and any issues.

2. **Script usage:**
   - `./scripts/ask_backend.sh --type read --context "Profile API" "What fields does GET /api/users/:id return?"`
   - `./scripts/ask_backend.sh --type implement --context "Chat" "Add typing indicator endpoint to ConversationController."`
   - For quick read-only questions you can pass `--timeout 120`; for implement/schema requests let the default (600s) run and be patient.

3. **Prompt tips:**
   - Be specific: endpoint path, method, and what you need. Include backend file paths in Context when you know them.
   - Do not ask for 3+ unrelated endpoints in one prompt.

4. **Do not** store API keys or secrets in the skill; the endpoint is described as not requiring auth in this doc. If the real endpoint later requires auth, update this doc and the script.

---

## Example prompts (use as templates)

| Use case | Example prompt |
|----------|-----------------|
| **Sync fields** | "What fields does POST /api/posts expect? Show request and response format" |
| **Build endpoint** | "Create a GET /api/notifications endpoint that returns paginated notifications for user_id" |
| **Query data** | "How many users registered this week? Break down by gender" |
| **Read code** | "Show me the validation rules for the ConversationController store method" |
| **Report** | "Generate a platform stats report: total users, posts, streams, wallet transactions" |
| **Profile stats** | "What user counts does the profile/user API return (e.g. posts_count, friends_count)? List all stats we can show on the user profile and the exact JSON field names" |

---

## How to invoke from the project

Use the script (recommended; requires `python3`). Prefer structured calls per the [protocol](BACKEND_ASSISTANT_PROTOCOL.md):

```bash
./scripts/ask_backend.sh --type read --context "Profile" "What fields does GET /api/users/:id return?"
./scripts/ask_backend.sh --type implement --context "Profile stats" "Add followers_count to user profile response."
./scripts/ask_backend.sh "Your prompt here"   # plain prompt still works
```

Or with `curl`:

```bash
curl -s -X POST "https://zima-uat.site:8003/api/ai/ask" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Your question or directive here"}' | jq .
```

If you don't have `jq`, omit `| jq .` to see raw JSON.

---

## Health / availability

- **GET** `https://zima-uat.site:8003/api/ai/ask` → 404 (expected; only POST is supported).
- Internal health check only: `http://127.0.0.1:8100/health` → `{"status": "ok"}` (not proxied publicly).

Use this skill whenever the task requires backend changes or backend knowledge; call the endpoint, then continue with the frontend work using the answer.
