<p align="center">
  <h1 align="center">temporal-debug-skill</h1>
  <p align="center">
    <strong>AI agents debug the present. Production bugs live in the past.</strong>
  </p>
</p>

<p align="center">
  <a href="https://github.com/MeherBhaskar/temporal-debug-skill/stargazers"><img src="https://img.shields.io/github/stars/MeherBhaskar/temporal-debug-skill?style=flat&color=f5a623" alt="GitHub Stars"></a>
  <a href="https://www.python.org/"><img src="https://img.shields.io/badge/python-3.9%2B-3776ab" alt="Python 3.9+"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/github/license/MeherBhaskar/temporal-debug-skill?color=blue" alt="License"></a>
  <a href="https://github.com/MeherBhaskar/temporal-debug-skill/pulls"><img src="https://img.shields.io/badge/PRs-welcome-brightgreen" alt="PRs Welcome"></a>
</p>

<br>

An **agentic skill** that teaches your AI agent to time-travel through git history when debugging. No tools, no setup — just drop the skill in and it activates automatically when it detects temporal bug context.

---

## The Problem

You paste an error trace into your AI agent. It scans the current code, confidently points to a line — but that line was rewritten *after* the crash. The actual bug was a missing null check that existed before yesterday's merge.

**You just spent 45 minutes debugging code that didn't cause the failure.**

Every agent today analyzes `HEAD`. But `HEAD` is not where the bug happened. The code that crashed in production at 3am is buried under 14 commits of hotfixes, refactors, and feature work that landed since.

Temporal Debug fixes this by giving your agent the ability to step back in time.

---

## How It Works

The skill activates automatically when your agent detects a time-anchored bug:

> **You:** "We have a crash in production from 3 hours ago. The trace says `NullPointerException in PaymentService.java`."
>
> **Agent (with this skill):**
> 1. Runs `git log --before="3 hours ago" -1 --format="%H"` → gets commit `a1b2c3d`
> 2. Runs `git worktree add /tmp/temporal-debug-a1b2c3d a1b2c3d` → isolated snapshot
> 3. Reads `PaymentService.java` from the worktree, analyzes the historical code
> 4. Runs `git worktree remove --force /tmp/temporal-debug-a1b2c3d` → cleanup
> 5. Reports: "In commit `a1b2c3d` (3 hours ago), `PaymentService.java:42` accesses `user.getEmail()` without a null check. `user` is null for guest checkouts. Introduced in commit `f8e9d0a`."

---

## Quick Start

### Claude Code (recommended)

```bash
# Clone directly into your project's skills directory
git clone https://github.com/MeherBhaskar/temporal-debug-skill.git skills/temporal-debug-skill
```

The skill activates automatically — no configuration needed.

### Generic Agent

```bash
# Copy the skill definition to your agent's skill directory
cp -r temporal-debug-skill/skills/temporal-debug/ /path/to/your/skills/
```

---

## What the Skill Does (and Doesn't Do)

| ✅ Does | ❌ Doesn't |
|--------|-----------|
| Detects temporal context in user messages | Need you to invoke a CLI tool |
| Resolves "3 hours ago", "v2.4.1", "last night" to commits | Require external scripts |
| Creates isolated `git worktree` snapshots | Touch your working directory |
| Guides analysis inside the historical snapshot | Analyze code for you (you already do that) |
| Cleans up worktrees automatically | Install dependencies (you already know how) |
| Works with any git repo, any language | Require Python, Node, or any runtime |

---

## Core Idea

**Agents already know how to:**
- Read files, grep, `git log`, `git diff`, `git show`
- Trace execution paths, analyze code
- Install dependencies (`npm install`, `pip install`, etc.)

**Agents struggle with:**
- Fuzzy time → commit resolution ("last night's deploy" → `a1b2c3d`)
- Clean `git worktree` lifecycle (create, track, guarantee cleanup)

**This skill bridges only that gap.** It gives the agent the git commands to resolve time and manage worktrees. The agent does the rest.

---

## Example Interactions

### Production Crash with Timestamp

> **You:** "Crash from 3 hours ago: `NullPointerException in PaymentService.java`"
> **Agent:** *Resolves commit → creates worktree → analyzes historical `PaymentService.java` → finds missing null check → cleans up → reports root cause with commit reference*

### Version-Pinned Bug

> **You:** "Users on v2.4.1 report auth failures" *(attaches error log)*
> **Agent:** *Resolves tag `v2.4.1` → worktree → analyzes auth middleware → finds regex bug skipping validation for `/health-records` → reports fix from v2.4.2*

### Regression Detective

> **You:** "This endpoint 200'd last week, now 500s. Changelog shows nothing."
> **Agent:** *Resolves "last week" → creates two worktrees (last week + HEAD) → diffs relevant modules → finds pool size config regression from 50 → 10*

---

## Requirements

- Git 2.17+ (for `git worktree` support)
- A git repository with commit history

That's it. No Python, no Node, no install.

---

## Roadmap

- [x] Core time-travel debugging via `git worktree`
- [x] Natural language time resolution ("3 hours ago", "last night")
- [x] Automatic worktree cleanup
- [ ] Multi-repo temporal analysis (debug across service boundaries)
- [ ] CI/CD integration (auto-trigger on failed builds)
- [ ] Diff analysis between historical and current versions
- [ ] Automated patch generation from root cause
- [ ] Observability platform integration (Sentry, Datadog, PagerDuty)
- [ ] VS Code extension for visual time-travel

---

## Contributing

```bash
git clone https://github.com/MeherBhaskar/temporal-debug-skill.git
cd temporal-debug-skill
# Edit skills/temporal-debug/SKILL.md
```

---

## License

[MIT](https://opensource.org/licenses/MIT) — use it, fork it, ship it.



<p align="center">
  <sub>Built for the agentic era. Stop debugging ghosts.</sub>
</p>