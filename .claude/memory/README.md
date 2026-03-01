# TAJIRI Memory System

This directory contains persistent memory for Claude to maintain context across sessions.

## Structure

```
.claude/memory/
├── README.md              # This file
├── session-state.md       # Current session checkpoint
└── project/               # Permanent project knowledge
    ├── architecture.md    # System architecture & design
    ├── domain-knowledge.md # TAJIRI platform concepts
    ├── patterns.md        # Code patterns & best practices
    └── troubleshooting.md # Common issues & solutions
```

## File Purposes

### session-state.md
**Type**: Temporary (updated each session)
**Purpose**: Track current work, progress, decisions, and next steps
**Format**: Checkpoint with timestamp, active task, progress checklist, recent changes

### project/domain-knowledge.md
**Type**: Permanent
**Purpose**: Core TAJIRI concepts, features, terminology, models
**Format**: Dated entries with tags (#domain, #terminology, #features)

### project/patterns.md
**Type**: Permanent
**Purpose**: Architectural patterns, code conventions, successful approaches
**Format**: Dated entries with code examples and tags (#pattern, #success)

### project/architecture.md
**Type**: Permanent
**Purpose**: System design, data flow, layers, scaling strategies
**Format**: Comprehensive architecture documentation with diagrams

### project/troubleshooting.md
**Type**: Permanent
**Purpose**: Common problems and their solutions
**Format**: Issue-solution pairs with prevention tips

## Usage Guidelines

### Adding New Knowledge
When you discover something important:
1. Identify the category (domain, pattern, architecture, issue)
2. Add to appropriate file
3. Use compact format (3-5 sentences)
4. Tag appropriately
5. Reference file paths when relevant

### Updating Session State
At key milestones:
1. Update active task
2. Check off completed items
3. Add new blockers/notes
4. Update next steps
5. Add timestamp

### Tags Reference
- `#domain` - Business/platform concepts
- `#pattern` - Code patterns
- `#success` - Proven solutions
- `#architecture` - System design
- `#issue` - Problem to avoid
- `#error` - Common errors
- `#performance` - Optimization
- `#security` - Security practices
- `#swahili` - Terminology

## Best Practices

1. **Be Concise**: 3-5 sentences per entry
2. **Date Everything**: Include date for all entries
3. **Tag Appropriately**: Use consistent tags
4. **Reference Files**: Link to relevant code files
5. **Update Regularly**: Keep session-state current
6. **Learn from Failures**: Document issues and solutions
7. **Capture Decisions**: Record why choices were made

## Benefits

- **Context Preservation**: Remember project details across sessions
- **Pattern Recognition**: Build library of successful approaches
- **Onboarding**: New contributors learn quickly
- **Debugging**: Quick reference for common issues
- **Decision History**: Understand why things are the way they are

## Maintenance

- Review and consolidate similar entries monthly
- Archive outdated information
- Update patterns as architecture evolves
- Keep session-state focused on current work
- Remove or update obsolete information

---

Last Updated: 2026-01-28
TAJIRI Platform - Social Media App for Tanzania