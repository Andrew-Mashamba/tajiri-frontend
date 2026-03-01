---
name: project-memory-store
description: Store project-specific insights (episodic/procedural/semantic) into file-based memory. Use when discovering patterns, completing tasks, or learning from failures. Triggers on "--learn" or "--project-store".
triggers:
  - learn
  - remember this
  - save pattern
  - store insight
  - project-store
  - lesson learned
  - important pattern
  - remember pattern
  - save knowledge
role: utility
scope: knowledge-management
output-format: text
---

# Project Memory Store

Extract and store project-specific insights into persistent file-based memory. Learns from both successes and failures.

## When to Invoke

- User says `--learn` or `--project-store`
- After completing tasks revealing important domain logic
- After discovering project-specific patterns
- After debugging sessions (especially failures)
- When user expresses frustration (critical learning signal)

## Memory Storage Structure

```
.claude/memory/project/
├── patterns.md           # Recurring code patterns
├── decisions.md          # Architectural decisions & rationale
├── failures.md           # What didn't work and why
├── domain-knowledge.md   # Business logic insights
├── debugging-tips.md     # Project-specific debugging knowledge
└── file-map.md           # Key files and their purposes
```

## Memory Format (COMPACT)

**Critical**: Use COMPACT format to prevent memory bloat. Each memory should be 3-5 sentences MAX.

```markdown
## [Title] #success/#failure
**Date**: [YYYY-MM-DD]
**Context**: [One sentence summary]

**What happened**: [2-3 sentences: what was tried, what worked/failed]
**Key lesson**: [One sentence takeaway]
**Files**: `path/to/relevant/files.dart`
**Tags**: #category #subcategory
```

## Memory Categories

### Episodic (What Happened)
- Debugging sessions
- Feature implementations
- Bug fixes
- Refactoring efforts

### Procedural (How To)
- Build/deploy procedures
- Testing workflows
- Common operations
- Tool usage patterns

### Semantic (Domain Knowledge)
- Business rules (VICOBA: Ada, Hisa, Mikopo, etc.)
- Data relationships
- API contracts
- User workflows

## Example Memories

### Success Pattern
```markdown
## Firestore Voting Listener #success
**Date**: 2025-01-24
**Context**: Real-time vote counting implementation

**What happened**: Used Firestore snapshots with version field for change detection.
Listener triggers on any vote change, updates UI immediately. Works offline with queue.
**Key lesson**: Always include version field for efficient change detection.
**Files**: `lib/voting_firestore_service.dart`, `lib/services/offline_vote_queue.dart`
**Tags**: #firebase #realtime #voting
```

### Failure Pattern
```markdown
## StatefulWidget in TabBar #failure
**Date**: 2025-01-24
**Context**: State lost when switching tabs

**What happened**: Used StatefulWidget without AutomaticKeepAliveClientMixin.
State reset every tab switch. Added mixin with `wantKeepAlive => true`.
**Key lesson**: Always use AutomaticKeepAliveClientMixin for TabBar children.
**Files**: `lib/pages/*.dart`
**Tags**: #flutter #state #tabs
```

## Retrieval

When working on related tasks, search memories:

1. **Keyword search**: Grep through memory files
2. **Tag filtering**: Find by #category
3. **Recency**: Prioritize recent learnings
4. **Relevance**: Match current file/feature context

## Auto-Learn Triggers

Store memory automatically when:

| Trigger | Memory Type |
|---------|-------------|
| Bug fixed after multiple attempts | #failure → #success |
| New pattern discovered | #pattern |
| User explains domain concept | #domain |
| Build/deploy succeeds after fix | #procedural |
| User frustration resolved | #failure (valuable!) |

## VICOBA-Specific Categories

For this project, prioritize storing:

- **Swahili terminology** mappings
- **Voting system** rules and thresholds
- **Financial calculations** (Ada, Hisa, Riba)
- **Firestore schema** patterns
- **Offline sync** strategies
- **API endpoint** behaviors

## Commands

| Trigger | Action |
|---------|--------|
| `--learn` | Store current context as memory |
| `--project-store` | Explicitly save project insight |
| `--recall [topic]` | Search memories for topic |
| `--show-memories` | List all stored memories |
| `--forget [id]` | Remove outdated memory |
