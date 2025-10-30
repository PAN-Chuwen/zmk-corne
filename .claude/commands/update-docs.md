---
description: "Update documentation to match current codebase state"
argument-hint: ""
allowed-tools: ["Bash", "Read", "Edit", "Glob", "Grep"]
---

Update documentation to match current codebase state.

📚 **Documentation Sync**: Updates docs with current database schema, completed todos, and file structure.

**MANDATORY Sanity Checks (performed first):**
1. `pwd` - Show current working directory
2. `git branch --show-current` - Show current branch
3. `git status` - Check repository state
4. `docker ps | grep postgres` - Verify database is running

**What this command does:**
1. Check git commits vs docs/development.md todos
2. Compare current codebase implementation with documentation descriptions
3. Sync docs/database-design.md with current database schema
4. Update CLAUDE.md project structure if files changed
5. Validate documented setup instructions match actual implementation

**CRITICAL: docs/development.md Philosophy**
- **ONLY active todos and current problems** - no completed tasks
- **REMOVE completed items entirely** - don't mark as "RESOLVED ✅"
- **Keep focused on current work** - completed tasks belong in git history
- **Clean, actionable document** - developers should see only what needs doing

**Commands executed:**
1. Sanity checks (pwd, current branch, git status, docker status)
2. `git log --oneline -50` - Check extensive recent commit history
3. Read current code and verify documentation accurately reflects implementation
4. `docker exec pantyhose_postgres psql -U gallery_user -d image_gallery -c "\\d+ images"` - Get current schema
5. `docker exec pantyhose_postgres psql -U gallery_user -d image_gallery -c "\\d+ tag_catalog"` - Get tag system schema
6. **REMOVE completed sections** from docs/development.md entirely (don't mark as resolved)
7. Update database-design.md if schema differs from docs
8. Update CLAUDE.md if project structure changed

**When to use:**
- Before creating PR
- After database schema changes
- When docs seem outdated