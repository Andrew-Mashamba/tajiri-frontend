# Safety Guardrails — MANDATORY

**Scope**: All work on the TAJIRI Flutter codebase.  
**Trigger**: ALWAYS active. This skill applies to every file operation, agent launch, and edit.  
**Enforcement**: Violating any rule below is a STOP condition. Do not proceed.

---

## 1. NEVER Delete Existing Files Without Explicit User Permission

- **Rule**: Do not `rm`, `git rm`, empty-out, or overwrite-to-nothing any file that already exists in the repo.
- **Exception**: Only if the user explicitly says "delete X" or "remove Y".
- **Why**: Background agents deleted `payroll_page.dart`, `credit_report_page.dart`, `employees_page.dart`, `purchase_orders_page.dart`, `suppliers_page.dart`, and gutted `tax_page.dart` to 93 bytes. This destroyed working code.
- **Safe pattern**: If a file seems unused, mark it with a comment `// DEPRECATED — candidate for removal` and ask the user.

## 2. NEVER Strip Methods / Fields / Enums from Shared Models or Services

- **Rule**: Do not remove getters, methods, enum values, or classes from files in `lib/*/models/` or `lib/*/services/` unless you are 100% certain zero callers exist.
- **Verification**: Before deleting anything from a shared file, run `grep -r "ClassName\|methodName" lib/ --include="*.dart"` to find all references.
- **Why**: Agents removed `getClientNotes`, `getClientReminders`, `addClientReminder`, `addClientNote`, etc. from `BusinessService` and fields from `Invoice`/`InvoiceItem`, breaking 209+ invoice errors and dozens more across clients, debts, CRB.
- **Safe pattern**: Add `@deprecated` comments and new methods alongside old ones. Remove only after a migration period.

## 3. NEVER Launch Unsupervised Background Agents for Code Changes

- **Rule**: Do not use `Agent(subagent_type="coder", run_in_background=true)` for any task that modifies, creates, deletes, or restructures code files.
- **Exception**: `run_in_background=true` is allowed ONLY for:
  - Read-only exploration (`subagent_type="explore"`)
  - Long-running `flutter build` or test commands via `Shell(run_in_background=true)`
  - Research tasks (web search, reading docs)
- **Why**: Three background coder agents timed out after 30 minutes. Their partial output deleted files, gutted models, and introduced 312 compile errors. No human reviewed their work before damage was done.
- **Safe pattern**: All code changes happen in the foreground session where every edit is reviewed immediately. If a task is too large, break it into smaller foreground tasks or ask the user for permission to proceed.

## 4. ALWAYS Verify with `flutter analyze` Before Declaring Done

- **Rule**: After any batch of changes to `lib/`, run `flutter analyze` on the affected files. If errors appear, fix them before moving on.
- **Full-project rule**: Run `flutter analyze` on the full project after any change to shared models or services.
- **Why**: The agents made changes without verifying, leaving a broken tree. A 30-second analyze check would have caught the missing methods immediately.

## 5. Prefer Minimal, Surgical Edits

- **Rule**: Make the smallest possible change to achieve the goal. Do not "refactor while you're in there."
- **Why**: Large sweeping changes increase the surface area for bugs and make review impossible.
- **Safe pattern**: One concern per edit. If you see unrelated cleanup needed, note it in a comment or todo and ask the user.

## 6. Shared Files Require Extra Scrutiny

- **Rule**: Any edit to a file referenced by more than 3 other files requires a reference check.
- **Checklist**:
  1. Run `grep -r "import.*filename" lib/ --include="*.dart" | wc -l` to count dependents.
  2. If >3 dependents, run `flutter analyze` on the full project after editing.
  3. Do not delete or rename public APIs without updating all callers.

## 7. Stop Conditions — Immediate Halt

Stop and ask the user if any of the following arise:
- A background agent proposes deleting files.
- `flutter analyze` shows new errors after your changes.
- You need to modify >5 files for a single feature.
- You need to change a shared model or service.
- The user says "this is unacceptable" or similar — pause, apologize, and ask for direction.

---

## Incident Reference

**Date**: 2026-04-29  
**What happened**: Three `coder` agents launched with `run_in_background=true` to implement F3/F4/F5/F7 items. They timed out after 30 minutes. Their partial work:
- Deleted 5 business pages entirely.
- Gutted `tax_page.dart` from ~16 KB to 93 bytes.
- Stripped methods from `BusinessService` and fields from `Invoice`/`InvoiceItem`/`Debt` models.
- Introduced 312 compile errors across invoices, skincare, hair_nails, vfd, clients, debts.

**Recovery**: `git checkout HEAD -- .` restored all tracked files.  
**Root cause**: Unsupervised agents with no real-time validation.  
**Prevention**: This skill. Never again.
