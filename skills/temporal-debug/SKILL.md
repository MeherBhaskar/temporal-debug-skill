---
name: temporal-debug
description: >
  Use this skill when the user is debugging a bug, error, crash, or issue that
  might be tied to a specific point in time (e.g., "crash from 3 hours ago",
  "bug in v2.4.1", "last night's deploy"). It guides the agent to reconstruct
  the historical code state and analyze the bug in that context.
---

# Temporal Debug Skill

## Goal

Help the user debug a bug by reconstructing the code state at the time the bug
occurred, rather than analyzing the current `HEAD`. This eliminates confusion
from recent unrelated changes.

## When to Use

- User mentions a bug with a time reference: "3 hours ago", "last night",
  "yesterday's deploy", "this morning"
- User references a specific version: "v2.4.1", "release-2024-01", tag name
- User shares an error log with a timestamp
- User suspects a recent change introduced a bug but current code looks fine

## When NOT to Use

- New feature development
- Refactoring without bug context
- Bug clearly in current code (user says "just broke after my last commit")

## Workflow

### 1. Resolve the Target Commit

Extract temporal clues from the user's message and resolve to a commit hash:

| Clue Type | Git Command |
|-----------|-------------|
| Explicit commit hash | Use directly |
| Git tag / version (e.g., `v2.4.1`) | `git rev-list -1 v2.4.1` |
| Relative time (e.g., "3 hours ago") | `git log --before="3 hours ago" -1 --format="%H"` |
| ISO date (e.g., "2024-01-15") | `git log --before="2024-01-15" -1 --format="%H"` |
| "last night" / "yesterday" | `git log --before="yesterday 23:59" -1 --format="%H"` |

If multiple conflicting clues, ask the user which to use.
If user gives explicit commit hash, use it directly — no resolution needed.

Store the resolved hash as `TARGET_COMMIT`.

### 2. Create Isolated Historical Workspace

Create a `git worktree` at the target commit. This is read-only, isolated,
and doesn't touch the user's working directory.

```bash
# Create worktree in system temp dir
WORKTREE_PATH=$(mktemp -d -t temporal-debug-XXXXXX)
git worktree add "$WORKTREE_PATH" "$TARGET_COMMIT"
```

The worktree now contains the exact code state at that commit.

### 3. Analyze in Historical Context

Work **inside the worktree path**. Use normal agent capabilities:

- Read files from `$WORKTREE_PATH/...`
- Run `git log`, `git show`, `git diff` within the worktree
- Trace the bug through the code as it existed at that commit
- If needed, install dependencies in the worktree (agent already knows how)

### 4. Report Findings

Reference the historical commit in your analysis. Show what changed since
using `git diff $TARGET_COMMIT HEAD -- <file>` if relevant.

### 5. Clean Up

```bash
git worktree remove --force "$WORKTREE_PATH"
git worktree prune
```

## Core Rules

1. **Never use `git checkout` on the user's main working directory**
2. **Always use `git worktree` for historical snapshots**
3. **Always clean up the worktree when done**
4. **If user gives explicit commit hash, skip temporal resolution**
5. **Work inside the worktree path for all file reads/analysis**

## Example

> **User:** "We have a NullPointerException in PaymentService from 3 hours ago"
>
> **Agent:**
> 1. `git log --before="3 hours ago" -1 --format="%H"` → `a1b2c3d`
> 2. `git worktree add /tmp/temporal-debug-a1b2c3d a1b2c3d`
> 3. Read `PaymentService.java` from `/tmp/temporal-debug-a1b2c3d/...`
> 4. Analyze, find root cause
> 5. `git worktree remove --force /tmp/temporal-debug-a1b2c3d`
> 6. Report: "In commit a1b2c3d (3 hours ago), PaymentService line 42 accesses user.getEmail() without null check..."