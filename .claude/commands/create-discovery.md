---
description: "Create structured discovery documentation from current context"
argument-hint: "[topic-description (optional)]"
allowed-tools: ["Bash"]
---

Create discovery documentation: ${1:-auto-detect from context}

🔍 **Smart Discovery Creation**: Creates structured documentation for issues discovered during development.

**Usage modes:**
- `/create-discovery` - Auto-detect discoveries from current conversation context
- `/create-discovery "database schema needs refactoring"` - Explicit topic

**What this command does:**
1. **Topic Detection**: Extract topic from arguments or analyze conversation context
2. **Context Analysis**: If no topic specified, recap what was discovered/discussed
3. **File Creation**: Generate `docs/discovery-<topic-slug>.md` with structured template
4. **Branch Context**: Include current branch and development context

**Auto-detection behavior (no arguments):**
When no topic is provided, I'll analyze our current conversation to identify:
- Issues or problems discussed
- Technical debt mentioned
- Architecture concerns raised
- Performance bottlenecks discovered
- Missing features identified
- Bug findings or edge cases

**File structure created:**
```markdown
# <Topic Title>

## Context
- **Discovered during:** <current-branch> development
- **Date:** <current-date>
- **Session context:** <conversation summary>

## Issue Description
<detailed description>

## Priority Assessment
- **Impact:** High/Medium/Low
- **Complexity:** Large refactor/Medium change/Small fix
- **Dependencies:** <any dependencies>

## Suggested Approach
<recommended solution>

## Next Steps
- [ ] <actionable items>
```

**Commands executed:**
1. `git branch --show-current` - Get current branch context
2. `pwd` - Verify working directory
3. Topic processing: use provided topic OR analyze conversation context
4. Generate filename slug from topic
5. Create `docs/discovery-<topic-slug>.md` with structured content
6. Display file location and next steps

**Example outputs:**
```bash
# With explicit topic
✅ Created discovery documentation: docs/discovery-database-schema-refactoring.md
📁 Location: docs/discovery-database-schema-refactoring.md
📝 Please review and complete the details, then use /stash-changes

# Auto-detection mode
✅ Auto-detected discovery: "Session timeout handling issues"
📁 Created: docs/discovery-session-timeout-handling-issues.md
📝 Based on our discussion about authentication problems
```

**File location**: Always creates files in `docs/` directory for organized documentation.

**Next steps after creation:**
1. Review and complete the generated file
2. Use `/stash-changes` to preserve it for later integration
3. Continue with current development work

**🎯 Key benefit**: Captures discoveries in structured format without losing context across Claude sessions.