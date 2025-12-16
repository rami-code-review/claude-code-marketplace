---
description: Check Rami review status without triggering new review
---

# Rami Status Check

Check current review status for the PR on this branch.

## Execution

1. **Get PR URL**
   ```bash
   REMOTE=$(git remote get-url origin)
   BRANCH=$(git branch --show-current)
   ```
   ```
   mcp__plugin_rami-code-review_rami__get_current_branch_pr(remote_url=$REMOTE, branch=$BRANCH)
   ```

2. **Check Status**
   ```
   mcp__plugin_rami-code-review_rami__get_review_status(pr_url)
   ```

3. **Report**
   - `status: pending` → "Review in progress..."
   - `status: completed` → Report issue count and summary
   - `status: not_found` → "No review found for this PR"
   - `status: error` → Report error message
