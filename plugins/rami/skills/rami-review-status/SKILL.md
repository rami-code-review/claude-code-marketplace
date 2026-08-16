---
name: rami-review-status
description: Check the current Rami review status without triggering a new review. Use when the user asks whether a Rami review is finished, ready, blocked, queued, or in progress.
---

# Rami Review Status

Report the current Rami review state for the pull request on this branch without triggering a new review.

If Rami MCP tools are unavailable or unauthenticated, stop and tell the user to authenticate the Rami MCP server in their current client or run the Rami setup workflow, then retry.

## Execution

1. Get the remote and branch:

   ```bash
   REMOTE=$(git remote get-url origin)
   BRANCH=$(git branch --show-current)
   ```

   Call `get_current_branch_pr(remote_url=$REMOTE, branch=$BRANCH)` on the Rami MCP server.

2. Call `get_review_status(pr_url)` on the Rami MCP server.

3. Use `ready_for_review` as the authoritative done signal. It is true exactly when `blockers` is empty.

   | Response | Report |
   |---|---|
   | `status: pending`, `in_progress`, or `queued` | "Review in progress (stage: `<current_stage>`)" |
   | `status: completed`, `ready_for_review: true` | "Ready for review. No blockers." |
   | `status: completed`, `ready_for_review: false` | "Not ready: `<len(blockers)>` blocker(s) outstanding." Summarize findings and unresolved threads, then offer to run the Rami review workflow. |
   | `status: not_found` | "No review found for this pull request." |
   | Error | Report the error message. |

Do not infer doneness any other way. A finding must be fixed or rebutted through Rami; an unresolved untracked thread must be handled on GitHub.
