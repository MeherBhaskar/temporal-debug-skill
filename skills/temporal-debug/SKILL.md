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
- **Deployment errors** - user says "deploy failed" or "production is down" with
  a version/timestamp reference

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

**For deployment errors:**
- If user mentions a release version (e.g., "deploy of v2.4.1 failed"), use the tag
- If user mentions a branch (e.g., "release/v2.4 branch"), use the branch tip
- If user says "current production deploy", check if there's a `production` or `main` branch deployed

If multiple conflicting clues, **ask the user which to use**.
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

**Diff Analysis (for regression detection):**
```bash
# After finding root cause, show what changed
git diff $TARGET_COMMIT HEAD -- <relevant-files>

# Filter to focus on likely culprits:
# - Config changes: docker-compose.yml, .env, config/, *.yaml, *.toml
# - Dependencies: package.json, go.mod, pom.xml, Cargo.toml, requirements.txt
# - Refactors: large diffs in core logic files
```

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

## Deployment Error Context

When the user reports a deployment/production error, gather this context:

| Info Needed | How to Get It |
|-------------|---------------|
| **Release version/tag** | Ask: "What version was being deployed?" (e.g., `v2.4.1`) |
| **Branch** | Ask: "Which branch was deployed?" (e.g., `release/v2.4`, `main`) |
| **Timestamp** | Ask: "When did the deploy start/fail?" |
| **Environment** | Ask: "Which environment?" (staging, production, etc.) |
| **Error logs** | User provides logs, or check CI/CD system |

**If missing info:** Ask the user for the specific version/tag/branch that was deployed, then resolve to a commit using the table in Step 1.

## Multi-Repository Support

For bugs spanning multiple repositories (e.g., microservices, monorepo with submodules):

### Setup
1. **Identify all affected repos** - Ask user: "Which repositories are involved?"
2. **Create worktrees per repo** - Repeat the workflow for each repository
3. **Use consistent naming** - `WORKTREE_BASE/repo-name-timestamp`

### Example Workflow
```bash
# For each repo
cd /path/to/repo-A
WORKTREE_A=$(mktemp -d -t temporal-debug-XXXXXX)
git worktree add "$WORKTREE_A" "$TARGET_COMMIT_A"

cd /path/to/repo-B
WORKTREE_B=$(mktemp -d -t temporal-debug-XXXXXX)
git worktree add "$WORKTREE_B" "$TARGET_COMMIT_B"
```

### Cross-Repo Analysis
- Trace the request flow across service boundaries
- Check if version mismatches between services caused the bug
- Look for API contract violations between services at that commit
- Compare dependency versions (package.json, pom.xml, go.mod, Cargo.toml, etc.)

### Cleanup All Worktrees
```bash
for wt in "$WORKTREE_A" "$WORKTREE_B" ...; do
  git -C $(dirname $wt) worktree remove --force "$wt"
done
git worktree prune
```

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

## Example: Deployment Error

> **User:** "Deploy of v2.4.1 to production failed with timeout"
>
> **Agent:**
> 1. Ask: "What branch was v2.4.1 built from?" → User: "release/v2.4"
> 2. `git rev-list -1 v2.4.1` → `f8e9d0a` (or use branch tip if tag missing)
> 3. `git worktree add /tmp/temporal-debug-f8e9d0a f8e9d0a`
> 4. Analyze deployment scripts, config, health checks at that commit
> 5. Check if health check endpoint changed, resource limits, etc.
> 6. `git worktree remove --force /tmp/temporal-debug-f8e9d0a`
> 7. Report with findings tied to that specific deploy commit

## Example: Microservice Debugging

> **User:** "API gateway returns 502 from auth-service since yesterday's deploy"
>
> **Agent:**
> 1. Ask: "Which repos?" → User: "api-gateway, auth-service"
> 2. Ask: "Deploy time?" → User: "yesterday 3pm"
> 3. In api-gateway: `git log --before="yesterday 15:00" -1 --format="%H"` → `aaa111`
> 4. In auth-service: `git log --before="yesterday 15:00" -1 --format="%H"` → `bbb222`
> 5. Create worktrees for both
> 6. Check auth-service health endpoint contract at `bbb222`
> 7. Check api-gateway client call at `aaa111`
> 8. Found: auth-service changed `/health` → `/healthz` but gateway still calls old path
> 9. Cleanup both worktrees
> 10. Report: "Contract violation at commit bbb222 - auth-service renamed health endpoint"