# Backend Assistant Protocol (Frontend ↔ Backend)

Agreed format for communication between the **frontend assistant** (Flutter app / Cursor) and the **backend Assistant Endpoint** (`POST /api/ai/ask`). Following this reduces timeouts and ambiguity.

*(Discussion that led to this protocol: [assistant_comms_analysis.md](assistant_comms_analysis.md).)*

---

## 1. Request format (frontend → backend)

Prefix the prompt with optional headers, then the actual ask:

```
[Type: schema|implement|query|read|confirm|report]
[Context: one-line summary of current feature/screen]
[Ref: previous related prompt summary, if any]

<the actual ask — one main task>
```

### Types

| Type | Use for |
|------|--------|
| **schema** | "What tables/fields exist for X?" or "Design the schema for Y" |
| **implement** | "Create endpoint / migration / model for X" |
| **query** | "How many users signed up today?" / "Count posts by type" |
| **read** | "Show me the code in controller X" / "What routes exist for Y?" |
| **confirm** | "We implemented your response; here's what we did / issues we hit" |
| **report** | "Generate a stats report for X" |

Types are optional — backend infers if missing — but using them improves speed and precision.

### Context and Ref

- **Context:** Screen or feature name; include **file path** when known (e.g. `ProfileScreen → app/Http/Controllers/Api/UserProfileController.php`) to reduce backend exploration time.
- **Ref:** Short reference to a previous prompt (e.g. "profile stats we added") so the backend can maintain continuity.

### Rules

- **One main ask per prompt** to avoid timeouts. For complex work: use two-prompt pattern (schema → implement) or sequence small prompts.
- **Be specific:** e.g. "Add typing indicator endpoint to ConversationController" not "Make the chat better."
- **Max 4000 characters** per prompt.

---

## 2. Response format (backend → frontend)

Backend replies with:

```
Status: done | partial | blocked
Reason: (only if partial or blocked)

<markdown explanation>

<fenced code blocks for any JSON, SQL, PHP, or endpoint specs>
```

- **done** — Request fulfilled.
- **partial** — Partially done; Reason explains what’s left or what’s needed.
- **blocked** — Cannot proceed; Reason explains why.

For endpoint specs, backend uses a consistent block shape, e.g.:

```json
{
  "method": "POST",
  "path": "/api/v1/example",
  "body": {"field": "type|required"},
  "response": {"success": true, "data": {}, "message": "string"}
}
```

---

## 3. Backend capabilities and limits

| Capability | Allowed |
|------------|---------|
| Read any file in the codebase | Yes |
| Write/edit controllers, models, migrations, routes, services, events, jobs | Yes |
| Run migrations, query DB via tinker, syntax-check PHP, verify routes | Yes |
| Create broadcasting events, run existing tests | Yes |
| Modify `.env`, `composer.json`, core framework | **No** |
| Install packages | **No** |
| Access external APIs / internet | Limited |

**Single-prompt capacity:** One controller + one model + one migration + routes per prompt. Multiple unrelated endpoints in one prompt risk timeouts. Backend proxy allows **600s** (10 min); frontend script uses the same — be patient for heavy implement requests.

---

## 4. Frontend do's and don'ts

### Do

- Use `[Type:]` and `[Context:]` (and `[Ref:]` when relevant).
- One main task per prompt.
- Include backend file paths in Context when you know them.
- For big features: first `[Type: schema]` (design/plan), then `[Type: implement]` (code).
- Send `[Type: confirm]` after implementing the backend’s response (brief summary + any issues) to close the loop.

### Don't

- Ask for 3+ unrelated endpoints in one prompt.
- Use vague asks; be specific about endpoint, controller, and behavior.
- Omit Context when you have a known file (e.g. controller) — it saves 10–20s.

---

## 5. Prompt templates (copy and fill)

### New endpoint

```
[Type: implement]
[Context: {screen_name} → {backend_file_if_known}]

Create a {METHOD} /api/v1/{resource} endpoint that {does_what}.
Request: {fields}
Response: {expected shape}
```

### Database / stats query

```
[Type: query]
[Context: {dashboard_section}]

{Question in plain language, e.g. "How many users registered this week?"}
```

### Read code / routes

```
[Type: read]
[Context: {feature_area}]

Show me {what — e.g. "all routes for livestreaming" or "the Post model relationships"}.
```

### Confirm implementation

```
[Type: confirm]
[Context: {feature}]

Implemented your {what}. Working correctly.
{Any issue: "We need the response to also include the user's display name."}
```

### Schema / design only

```
[Type: schema]
[Context: {feature}]

Design the schema/plan for {what}. No code yet — just the plan.
```

---

## 6. How to invoke

Use the script with optional `--type` and `--context` (see [ASSISTANT_ENDPOINT_SKILL.md](ASSISTANT_ENDPOINT_SKILL.md)):

```bash
./scripts/ask_backend.sh --type implement --context "Profile stats" "Add followers_count to GET /api/users/:id response at root level."
./scripts/ask_backend.sh "[Type: read]\n[Context: User profile]\n\nWhat fields does GET /api/users/:id return in the data object?"
```

The protocol is shared with the backend; both sides use it for all Assistant-based communication.
