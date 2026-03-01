# Optimizing token usage with 15 workers: sharing information

With many workers, the same project context can be sent repeatedly and workers can re-implement or re-discover the same things. These ideas reduce token usage by letting workers share information.

---

## Implemented: shared “already done” summary

**What it does:** Before each implementation prompt, Zima builds a short summary of **recently completed stories** and the **files they modified** (from checkpoints). That string is injected at the top of the prompt.

**Effect:** The LLM sees “Already done (reuse, do not re-implement): Story 1 (Login): AuthController.php; Story 2 (Dashboard): …” so it:
- Reuses existing code instead of re-implementing
- Avoids editing the same files in conflicting ways
- Needs less exploration of the repo (saves tokens)

**Config** (`config.yaml` → `shared_context`):
- `enabled: true`
- `max_recent_stories: 15` – how many completed stories to include
- `max_summary_chars: 1500` – cap so the summary doesn’t dominate the prompt
- `recent_changes_limit: 20` – max lines in the “recent changes” log (idea 2)
- `recent_changes_max_chars: 500` – cap for that log
- `avoid_files_max: 30` – max files in the “avoid these files” line (idea 4)

**Code:** `Database.get_recent_completions_summary()`, used in `StoryExecutor._build_implementation_prompt()`. On story completion, `append_recent_change()` is called; the prompt also gets `get_recent_changes()` and `get_recently_touched_files()` (ideas 2 and 4).

---

## Implemented: recent changes log (idea 2)

When a worker completes a story, a one-liner is appended to the `recent_changes` table (story number, title, files modified). The next worker’s implementation prompt includes “Recent changes by other workers: …” (last N lines, bounded by `recent_changes_max_chars`). **Code:** `Database.append_recent_change()`, `Database.get_recent_changes()`; executor calls them on success and in `_build_implementation_prompt()`.

---

## Implemented: “avoid these files” (idea 4)

The prompt gets a line: “Avoid modifying these files unless your story requires it: file1, file2, …” built from recent completed stories’ checkpoints (deduplicated, up to `avoid_files_max`). **Code:** `Database.get_recently_touched_files()`; executor injects it when shared context is enabled.

---

## Other ideas (not yet implemented)

### 1. Per-run “project briefing” (one LLM call)

- **Idea:** At the start of a run, one optional LLM call (or a static template): “Project is X. Stack: Y. Existing layout: Z.” Store in DB or a small file. Every worker’s prompt gets this 1–2 paragraph summary instead of each worker inferring from the repo.
- **Saves:** Repeated “what exists” discovery; smaller, consistent context per story.
- **Cost:** One extra call per run; could be skipped for projects that already have a short README or you could use a non-LLM summary (e.g. list of top-level dirs and key files).

### 2. ~~Append-only “recent changes” log~~ ✅ Implemented (see above)

### 3. Module/domain tags and “implemented domains”

- **Idea:** Tag stories with a domain (e.g. auth, contracts, reports) from the PRD or title. Keep a shared “Implemented domains: auth (Story 1–3), contracts (Story 5–7).” Workers on a new domain get “Auth and contracts already done; focus on reports.”
- **Saves:** Prevents the model from re-explaining or re-implementing whole domains; keeps prompts focused.
- **Implementation:** Optional `module` or `domain` on stories (many PRDs already have this). Aggregate completed story domains in DB or in the same “already done” summary.

### 4. ~~“Files touched” registry and “avoid unless needed”~~ ✅ Implemented (see above)

### 5. Lightweight “handoff” note per story

- **Idea:** When a worker finishes a story, it writes a one-liner: “Added ContractController, migration contracts table, route POST /contracts.” Stored in DB (e.g. `stories.handoff_note` or a small `story_handoffs` table). Future workers building a prompt for a *related* story (same module or dependency) get that note in context.
- **Saves:** Other workers don’t re-probe the same area; can reuse or extend the same files.
- **Implementation:** Executor (or a post-success hook) sets `handoff_note` from a short summary of what was added (could be from checkpoint `files_modified` + story title). Prompt builder includes handoff notes for “related” stories (e.g. same module or previous story number).

### 6. Semantic “similar story” hint (advanced)

- **Idea:** Cache “Story N implemented X using files A, B, C.” For a new story, if it’s semantically similar (e.g. “export to CSV” vs “export to Excel”), inject: “Similar: Story 42 added export in ExportController; consider reusing.”
- **Saves:** Strong reduction in duplicate implementation and re-exploration.
- **Implementation:** Would need embeddings or keyword matching; likely a later phase.

### 7. Cap “already done” by domain

- **Idea:** When building the shared summary, group by module/domain and cap each domain (e.g. “Auth: Story 1, 2, 3; Contracts: Story 5, 6”) so the summary doesn’t grow unbounded with 15 workers.
- **Saves:** Keeps shared context under the token budget while still informing the model.
- **Implementation:** `get_recent_completions_summary` groups by `story.module` (or similar) and limits lines per domain; total still bounded by `max_summary_chars`.

### 8. Single shared “project state” document (file or DB)

- **Idea:** One mutable “project state” blob per run: “Features: login (done), dashboard (done), contracts (in progress). Files created: …”. Workers read it before building the prompt and can append when they complete (with locking or last-write-wins for small updates).
- **Saves:** One place for “what’s done”; all workers get the same picture; fewer tokens than each re-scanning the repo.
- **Implementation:** Table `project_run_state(project_id, run_id, state_json, updated_at)` or a file in the project dir; workers read and optionally append short updates.

---

## Recommended next steps

1. **Keep** the current “already done” summary and the new recent-changes log + “avoid these files” (all implemented); tune limits in `config.yaml` per project size.
2. **Consider** handoff notes (idea 5) if you have many workers and overlapping domains.
3. **Consider** module/domain tags (idea 3) and cap “already done” by domain (idea 7) for very large runs.
