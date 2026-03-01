# Zima Looper System – Study Summary

## What It Is

**Zima Looper** is an autonomous project builder that turns a PRD (Product Requirements Document) into implemented code. It uses **Claude CLI** to implement stories, runs them in parallel with a worker pool, and supports retries, checkpoints, quality gates, and a web dashboard.

Originally aimed at **Laravel** (README says “Laravel Project Builder”), the core loop is framework-agnostic: it loads stories from a JSON PRD, assigns them to workers, and runs a **plan → implement → test → commit** flow per story via Claude.

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│  zima.sh (CLI)                                                           │
│  Commands: generate-prd | execute | status | add-workers | dashboard …   │
└─────────────────────────────────────────────────────────────────────────┘
         │
         ├── generate-prd  →  prd/generator.py (README → prd.json)
         │
         └── execute       →  core/main.py (ZimaOrchestrator)
                                    │
                                    ▼
              ┌─────────────────────────────────────────────┐
              │  ZimaOrchestrator                            │
              │  - Loads project from DB or prd.json on disk │
              │  - Starts WorkerPool or single Worker        │
              │  - Shows final summary                       │
              └─────────────────────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    │  WorkerPool (N processes)     │
                    │  - Spawns N Worker processes   │
                    │  - Monitors health, restarts   │
                    │  - Stops when all stories done │
                    └───────────────┴───────────────┘
                                    │
                    Each Worker runs execution/worker.py
                                    │
              ┌─────────────────────┴─────────────────────┐
              │  Worker loop (run)                         │
              │  1. story = db.get_next_pending_story()   │
              │  2. executor.execute_story(story_id)      │
              │  3. On failure: retry / Claude fix / fail │
              │  4. Repeat until no pending stories       │
              └─────────────────────┴─────────────────────┘
```

---

## Entry Points

| Entry | Role |
|-------|------|
| **`zima.sh`** | Shell CLI; sets `PYTHONPATH`, routes to Python commands. |
| **`core/main.py`** | Orchestrator: `ZimaOrchestrator(project_name, num_workers).start()`. |
| **`core/worker_pool.py`** | Spawns N processes each running `execution.worker.run_worker(worker_id, project_id, project_dir)`. |
| **`execution/worker.py`** | Per-worker loop: poll for next story → execute → handle failure/retry. |

---

## The “Looper” (Worker Loop)

Each worker runs an infinite loop until the project is done or shutdown:

1. **Get work**  
   `story = db.get_next_pending_story(project_id, worker_id)`  
   - Uses **DependencyDetector**: only stories whose dependencies (by story number in acceptance criteria) are completed are “ready”.  
   - Among ready stories, one is **atomically** claimed (UPDATE … WHERE status = 'pending') and assigned to this worker.

2. **Execute**  
   `executor.execute_story(story_id)`  
   - State: `in_progress` → `implementing` → (optional) `testing` → `completed`.  
   - Planning phase exists in code but is **skipped** (token optimization).  
   - Implementation: build prompt from story, call Claude CLI, create checkpoint.  
   - Optional quality gate (e.g. PHPUnit), then commit phase (git commit).

3. **On failure**  
   - Error is analyzed (`recovery/error_analyzer`).  
   - **RetryManager** decides: retry (with backoff) or not.  
   - If retry: rollback to last checkpoint, set story back to `pending`, wait, then this or another worker will pick it up.  
   - If not retry (or max retries): optionally **Claude fixer**; else mark story `failed` and continue.

4. **Idle**  
   If `get_next_pending_story` returns `None`:  
   - If no pending and none in progress → worker exits (“all stories complete”).  
   - Else sleep `config.poll_interval_seconds` and poll again.

So the “looper” is literally: **poll → claim story → execute → (success or fail/retry) → repeat**.

---

## State Machine (Stories)

**`core/state_machine.py`** – `StoryStatus` and allowed transitions:

| State | Allowed next |
|-------|----------------|
| `pending` | `in_progress`, `skipped` |
| `in_progress` | `planning`, `failed` |
| `planning` | `implementing`, `failed` |
| `implementing` | `testing`, `failed` |
| `testing` | `completed`, `failed` |
| `failed` | `in_progress` (retry), `skipped` |
| `completed` | — (terminal) |
| `skipped` | — (terminal) |

Transitions are validated in `StoryStateMachine.transition()`; timestamps and retry counts are updated there.

---

## Dependency and “Next Pending” Story

**`core/dependency.py`** – `DependencyDetector`:

- Parses **acceptance criteria** (text) for patterns like “requires story 23”, “depends on story 5”, “after story 10”.
- Builds a dependency graph and can topological sort.
- **`get_ready_stories(stories)`**: among `pending` stories, returns those whose prerequisite story numbers are all `completed`.

**`core/database.py`** – `get_next_pending_story(project_id, worker_id, check_dependencies=True)`:

- If `check_dependencies`: get all project stories → `DependencyDetector.get_ready_stories()` → try to **atomically** claim one of them (UPDATE … WHERE id = ? AND status = 'pending').
- If no dependency check: claim single pending story with lowest priority, then story_number.

So the “looper” only gets stories that are **pending** and **dependency-ready**, and claims them under a single DB transaction to avoid two workers taking the same story.

---

## Executor (Single-Story Run)

**`execution/executor.py`** – `StoryExecutor.execute_story(story_id)`:

1. **Transition** to `in_progress`; create **start** checkpoint.
2. **Implementation phase** (no planning in practice):  
   Build prompt from story (title, description, acceptance), call **ClaudeWrapper** from `project_dir`, create **implementation** checkpoint (with modified files / git SHA).
3. **Testing phase** (if config):  
   Run quality gate (e.g. PHPUnit, syntax, env); on failure optionally rollback to last “plan”/“start” checkpoint.
4. **Commit phase**:  
   Create commit checkpoint (git commit with message from story).
5. **Transition** to `completed`; or on any failure call `_handle_failure` (update story, transition to `failed`).

**`execution/claude_wrapper.py`** – subprocess to `claude` CLI with `--print`, `--output-format`, `--model`, from `project_dir`; stdin = prompt, timeout and response parsing.

**`execution/checkpoint.py`** – **CheckpointManager**:  
Creates checkpoints (type, data, files_modified, git_sha); can **restore_checkpoint** (git checkout, etc.) and **rollback_to_last_checkpoint** for a story. Used for recovery and rollback after failure.

---

## Database (SQLite)

**`core/database.py`** – path default: `../zima.db` relative to the `core/` package (i.e. next to the `zima/` folder).

- **projects**: name, directory, readme_path, prd_path, status, total/completed/failed stories, timestamps.
- **stories**: project_id, story_number, title, description, acceptance_criteria (JSON), priority, estimate_hours, status, worker_id, retry_count, max_retries, error_message, error_logs, started_at, completed_at.
- **checkpoints**: story_id, checkpoint_type, data, files_modified, git_sha.
- **executions**: activity log (story_id, execution_type, command, output, exit_code, duration).
- **metrics**: project_id, metric_name, metric_value, timestamp.

**Loading a PRD from disk** (when project not in DB):  
`ZimaOrchestrator` looks for `{project_name}/prd.json` (or the path passed). It then:

- Creates a **project** row (name = dir basename, directory = project path, readme_path from PRD or default, prd_path).
- For each `prd.stories[]` calls **create_story(project_id, story_data)**.  
  Story fields: `id`/`story_number`, `title`, `description`, **`acceptance`** (stored as acceptance_criteria), `priority`, `estimate_hours`/`estimate`.

So the “source of truth” for the loop can be either the DB (after a previous `generate-prd` or import) or a one-time load from an existing **prd.json** in the project folder.

---

## Configuration

**`config.yaml`** (and **`core/config.py`**): workers (count, poll_interval), Claude (cli_path, timeout, model), retry (max_attempts, backoff, enable_claude_fix), checkpoints, git (auto_commit, branch template), quality (run_tests_before_complete, require_passing_tests), monitoring (dashboard port, log level), large_project options.

---

## Recovery and Quality

- **Retry**: `recovery/retry.py` – backoff, max attempts, decision whether to retry based on error type.
- **Error analysis**: `recovery/error_analyzer.py` – categorizes errors, recoverable or not.
- **Claude fixer**: `recovery/claude_fixer.py` – on failure, can attempt a fix with Claude and re-run the story.
- **Quality gate**: `quality/quality_gate.py` – runs tests/linter; can trigger rollback and failure.

---

## Summary: “Looper” in One Sentence

**Zima Looper** is a multi-worker loop that repeatedly asks the DB for the next dependency-ready pending story, **claims it**, runs a single-story pipeline (implement with Claude → test → commit) with checkpoints and retries, then repeats until there are no pending stories left.

To use it with ENTERPRISESACCOS: ensure a **prd.json** exists (e.g. under `docs/prd.json` or project root) and that the **project name** passed to `execute` matches the directory name (or the path where that PRD lives), so the orchestrator can either find the project in the DB or load the PRD from disk into the DB and then run the same loop.
