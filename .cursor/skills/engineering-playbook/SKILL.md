---
name: engineering-playbook
description: Execute TAJIRI’s engineering playbook workflows (deep crawl, backend verification, testing, performance/storage checklists).
triggers:
  - playbook
  - engineering playbook
  - deep crawl
  - audit
  - fix methodology
  - verification protocol
  - performance roadmap
  - storage decision tree
role: utility
scope: implementation
output-format: text
---

# TAJIRI Engineering Playbook (Workflow Skill)

**Canonical reference:** `docs/ENGINEERING_PLAYBOOK.md`

This skill turns the playbook into an executable workflow. It does **not** replace the playbook; it helps apply it consistently.

## 1) Deep Crawl Protocol (use for any screen audit/fix)

Starting from an entry screen file:

- **Inventory interactions**: list every `onTap`/`onPressed`/`onLongPress`, every navigation (`Navigator.push*`, `showDialog`, `showModalBottomSheet`), and every service/API call.
- **Trace the chain** (for each service call):
  - Screen → Service method → HTTP call → Endpoint path → Expected response shape → Model parsing
- **Identify issue types** using the playbook’s “12 issue types” section.
- **Make minimal fixes**: one concern per change set; avoid opportunistic refactors.

## 2) Backend Verification Protocol (when touching services/endpoints)

Before wiring a new call or changing an existing one:

- Confirm the endpoint exists and matches:
  - **method** (GET/POST/PUT/DELETE)
  - **path** (relative to `ApiConfig.baseUrl`)
  - **required params/body**
  - **success + error shape** (`{ success, data, message }`)
- Ensure the Flutter service uses `ApiConfig.baseUrl` and correct auth headers.

## 3) Testing / Verification (before “done”)

- Run `flutter analyze` after any substantive `lib/` changes.
- If changes touch shared models/services or lots of callsites, prefer full-project analyze.
- If behavior is user-facing, do a quick manual flow check (navigate → load → empty/error → retry).

## 4) Performance / Storage quick checks (when relevant)

- For list/grid pages: prefer cache-first for first paint + refresh network on entry (SWR-style) where the repo already does it.
- For storage decisions: use the playbook’s storage decision tree (Hive vs SQLite) and stick to repo patterns.

## Output format (when reporting work)

Use a short structured report:
- **What you traced**
- **What you changed**
- **Why**
- **How it’s verified** (commands run, screens checked)

