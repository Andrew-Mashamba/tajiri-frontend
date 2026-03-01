---
name: session-memory
description: Automatically restore session context from persistent memory at session start. Use IMMEDIATELY when starting work to recall previous checkpoints, active plans, and git context. MANDATORY for context restoration.
triggers:
  - session start
  - restore context
  - checkpoint
  - remember
  - previous session
  - what was I doing
  - continue work
  - session state
role: utility
scope: session-management
output-format: text
---

# Session Memory

Restore full working context from persistent memory automatically at session start. Prevents loss of context from previous sessions, crashes, or context window resets.

## When to Use

- **Session Start**: ALWAYS invoke at the beginning of every coding session
- **After /clear**: Restore context after clearing conversation
- **After Crash**: Recover from unexpected termination
- **Context Reset**: When context window fills up

## Memory Storage

Store session state in `.claude/memory/`:

```
.claude/memory/
├── session-state.md      # Current session checkpoint
├── active-todos.md       # In-progress tasks
├── recent-decisions.md   # Recent architectural decisions
└── git-context.md        # Branch, recent commits, staged changes
```

## Session State Format

When saving session state, use this format:

```markdown
# Session Checkpoint
**Timestamp**: [ISO timestamp]
**Branch**: [current git branch]
**Working Directory**: [cwd]

## Active Task
[What was being worked on]

## Progress
- [x] Completed steps
- [ ] Remaining steps

## Key Decisions Made
- [Decision 1]: [Rationale]
- [Decision 2]: [Rationale]

## Files Modified
- `path/to/file.dart` - [what changed]

## Blockers/Notes
[Any issues or important context]

## Next Steps
1. [Immediate next action]
2. [Following action]
```

## Restoration Process

On session start:

1. **Read session state**: Load `.claude/memory/session-state.md`
2. **Check git context**: Compare saved branch with current branch
3. **Load active todos**: Restore in-progress task list
4. **Summarize for user**: Brief recap of where we left off

## Auto-Save Triggers

Save session state automatically when:

- User says "save session", "checkpoint", or "save progress"
- Before executing destructive operations
- After completing major milestones
- Every 10-15 significant interactions

## Commands

| Trigger | Action |
|---------|--------|
| `--save-session` | Save current session state |
| `--restore-session` | Restore from last checkpoint |
| `--clear-memory` | Clear all session memory |
| `--show-memory` | Display current memory state |

## Integration

Works with:
- Git context (branch, status, recent commits)
- TodoWrite tool (active tasks)
- Project-specific CLAUDE.md files

## Example Restoration Message

```
📍 Session Restored

Last session: 2 hours ago
Branch: feature/voting-system
Task: Implementing vote counting logic

Progress:
✅ Created VotingService class
✅ Added Firestore listeners
⏳ Testing vote threshold calculations

Next: Complete unit tests for vote counting
```
