---
description: "Merge PR and cleanup branch in one shot - auto-detect or specify PR number"
argument-hint: "[pr-number (optional)]"
allowed-tools: ["Bash"]
---

Merge pull request and cleanup branch: ${1:-auto-detect}

🚀 **One-Shot Workflow**: Merge PR + cleanup worktree/branch in a single command.

**MANDATORY Sanity Checks (performed first):**
1. `pwd` - Show current working directory
2. `git branch --show-current` - Show current branch (should be base branch)
3. `git remote -v` - Extract repository name for gh CLI
4. `git status` - Check repository state

**Smart Logic:**
- **If PR number provided**: Merge that specific PR and cleanup
- **If no PR number**: Check how many open PRs exist
  - **1 PR**: Auto-merge and cleanup
  - **2+ PRs**: Show all PRs and ask which one to merge
  - **0 PRs**: Show message that no PRs are available

**What this command does:**
1. **Sanity Checks**: Verify current directory and repository state
2. **Repository Detection**: Extract repo name from remote for gh CLI
3. **PR Discovery**: List open PRs to determine count
4. **Smart Decision**:
   - If specific PR: Merge it
   - If 1 PR: Auto-merge it
   - If multiple: Show all PRs and prompt for selection
5. **Merge Operation**: Use gh CLI to merge the selected PR
6. **Extract Branch Info**: Get the head branch name from merged PR
7. **Automatic Cleanup**:
   - Remove worktree directory
   - Delete local branch
   - Delete remote branch
8. **Base Branch Update**: Pull latest changes to current branch
9. **Confirmation**: Show final state

**Usage**:
- `/merge-and-cleanup` - Auto-detect and merge+cleanup (smart mode)
- `/merge-and-cleanup 123` - Merge specific PR and cleanup

**Commands executed:**
1. Sanity checks (pwd, current branch, remote, status)
2. Verify we're in a git repository with GitHub remote
3. `gh pr list --state open` - Get open PRs
4. **Smart branching logic:**
   - **If 0 PRs**: Show "No open PRs found"
   - **If 1 PR**:
     - `gh pr view <pr-number>` - Show PR details
     - `gh pr merge <pr-number> --merge` - Merge PR
   - **If 2+ PRs**:
     - Display formatted PR list with: index, title, author, updated
     - Ask user: "Multiple PRs found. Which PR number to merge?"
   - **If specific PR**:
     - `gh pr view $1` - Show PR details
     - `gh pr merge $1 --merge` - Merge PR
5. **Extract branch name**: `gh pr view <pr-number> --json headRefName -q .headRefName`
6. **Cleanup sequence**:
   - `git worktree remove ../$(echo "<head-branch>" | sed 's/\//-/g')` - Remove worktree
   - `git branch -D <head-branch>` - Delete local branch
   - `git push origin --delete <head-branch>` - Delete remote branch
7. `git pull origin $(git branch --show-current)` - Update base branch
8. `git log --oneline -3` - Show recent commits to confirm merge
9. `git branch -va` - Show final branch state
10. `git worktree list` - Show remaining worktrees

**GitHub CLI auto-detection:**
- Automatically detects repository from git remote

**Example outputs:**
```bash
# No parameters, 1 PR found:
"Found 1 open PR - #42: feat: add user authentication
Author: chuwenpan, Updated: 2 hours ago
Merging and cleaning up..."

# No parameters, multiple PRs:
"Found 3 open PRs:
#42: feat: add user authentication (chuwenpan, 2h ago)
#45: fix: login validation bug (chuwenpan, 1d ago)
#47: docs: update API guide (contributor, 3d ago)
Which PR number to merge?"

# No PRs:
"No open pull requests found in this repository."
```

**🛑 STOP CONDITIONS**:
- If not on a valid git repository
- If gh CLI fails or not authenticated
- If PR is not mergeable
- If cleanup steps fail (will show error but PR is still merged)

**🔍 IMPORTANT NAMING DIFFERENCE:**
- **Branch name**: Uses slashes (e.g., `feat/keyboard-shortcuts`)
- **Worktree directory**: Uses dashes (e.g., `feat-keyboard-shortcuts`)
- Cleanup automatically converts branch name to directory name

**Next steps**: Continue development or use `/new-branch` for next feature
