# Frontend–Backend Assistant Communication: Analysis & Improvement Ideas

## Problems and bottlenecks (frontend perspective)

1. **Timeouts and long latency**
   - Responses often take 60–120+ seconds; one request hit 125s and was backgrounded.
   - Backend allows up to 300s; frontend scripts typically use 90–120s. Long waits block the assistant and the user.
   - Complex or multi-part prompts increase the chance of timeout (504).

2. **No structured request/response**
   - All communication is free-text prompt → markdown answer. No standard envelope (e.g. request type, context, version).
   - Hard to optimize backend by request type or to parse answers programmatically when needed.
   - No explicit "Status" (done / partial / blocked) or "Next step" from backend.

3. **No shared context or session**
   - Each prompt is independent. Cannot say "following up on profile stats" or "same endpoint as before."
   - Backend has no notion of "current task" or "recent changes," so it may repeat context or miss continuity.

4. **Prompt length limit (4000 chars)**
   - Large specs or pasted payloads can hit the limit; no way to chunk or attach references (e.g. "see doc X").

5. **Unclear backend capabilities**
   - No discovery: frontend doesn't know what the backend can do (read code only? suggest code? apply changes? run queries?).
   - Unclear whether "implement" means "return code to paste" vs "actually change the repo."

6. **No feedback loop**
   - When frontend implements something based on the answer, there's no way to tell the backend "done; here’s what we did" so it could update internal state or docs.

7. **Response format variability**
   - Sometimes backend returns tables, sometimes code blocks, sometimes prose. For "give me JSON schema" we need consistent structure (e.g. always use a fenced code block for JSON).

8. **Single endpoint, no prioritization**
   - All requests go to the same endpoint; no way to mark "quick read" vs "heavy implementation" so the backend could prioritize or scale.

---

## Improvement ideas (frontend proposes)

### A. Lightweight protocol (both sides)

- **Request:** Optional structured header in the prompt so backend can route or optimize:
  - `[Type: <request_type>]` — e.g. `schema`, `implement`, `query`, `read`, `confirm`
  - `[Context: <short context>]` — e.g. `Tajiri Flutter app, profile stats`
  - Then the rest: the actual question or directive.
- **Response:** Backend optionally starts with:
  - `Status: done | partial | blocked`
  - For schema/contract answers: put JSON or code in a fenced code block so the frontend can parse or copy reliably.

### B. Keep prompts short and single-topic

- One main ask per prompt to reduce timeout risk.
- For multi-part work: sequence of prompts (e.g. "1) Add field X" → then "2) Add validation for X").

### C. Discovery and capability doc

- Backend exposes (via a doc or a fixed prompt) what it can do: read code, suggest code, run DB queries, etc., and whether it can mutate the repo. Frontend skill doc links to this so the assistant knows when to ask and what to expect.

### D. Frontend improvements (we can do now)

- **Prompt templates:** Standard templates for "schema request," "implement endpoint," "list fields," etc., with placeholders. Use `[Type: ...]` and `[Context: ...]` in each.
- **Script:** Optional `--timeout` and `--type` so we can send a shorter timeout for "quick" requests and set the type in the prompt.
- **Contract doc:** A short `BACKEND_ASSISTANT_PROTOCOL.md` (or same doc on both repos) that both sides follow: request format, response conventions, and examples.

### E. Backend improvements (for backend to consider)

- Prefer shorter answers when possible to reduce latency.
- For "list fields" / "schema" requests, reply with a consistent format (e.g. table + code block).
- If possible, support a `request_type` or `context` in the API body in the future (optional) so the backend can prioritize or cache.

---

## What we need from the backend

1. Acknowledge or correct this analysis (any other bottlenecks on your side?).
2. Agree or adapt the lightweight protocol (request type + context; response status + code blocks).
3. Tell us what you can do (read only / suggest code / apply changes / run queries) and any limits.
4. Suggest any improvements you’d like the frontend to make when calling you.

Once we agree, the frontend will implement: prompt templates, script updates, and a shared protocol doc.
