#!/bin/bash
# Demo script for temporal-debug-skill

echo "=== Temporal Debug Skill Demo ==="
echo ""
echo "Scenario: Production crash from 3 hours ago"
echo "Error: NullPointerException in PaymentService.java"
echo ""
echo "Step 1: Resolve the target commit"
git log --before="3 hours ago" -1 --format="%H"
echo ""
echo "Step 2: Create isolated worktree at that commit"
TARGET_COMMIT=$(git log --before="3 hours ago" -1 --format="%H")
WORKTREE_PATH=$(mktemp -d -t temporal-debug-XXXXXX)
git worktree add "$WORKTREE_PATH" "$TARGET_COMMIT"
echo "Worktree created at: $WORKTREE_PATH"
echo ""
echo "Step 3: Analyze historical code"
echo "--- PaymentService.java at $TARGET_COMMIT ---"
cat "$WORKTREE_PATH/PaymentService.java" 2>/dev/null || echo "(File not in this demo repo - showing concept)"
echo ""
echo "Step 4: Find root cause"
echo "Found: Line 42 accesses user.getEmail() without null check"
echo "User is null for guest checkouts"
echo "Introduced in commit f8e9d0a"
echo ""
echo "Step 5: Cleanup"
git worktree remove --force "$WORKTREE_PATH"
git worktree prune
echo "Done! Worktree cleaned up."
