---
description: Run full AI code review cycle on current PR branch
---

# Rami Code Review

Run the full review-fix-rebut loop on the PR for the current branch. Max 5 iterations.

## Prerequisites

1. **MCP server available.** If Rami MCP tools are not available, stop and display:
   ```
   Rami MCP server needs authentication.

   To authenticate:
   1. Run /mcp in Claude Code
   2. Select "plugin:rami:rami"
   3. Press Enter to login
   4. Complete GitHub authentication in browser
   5. Return here and run /rami:review again
   ```

2. **PR detection.** Get the remote and branch, then call the Rami MCP tool:
   ```bash
   REMOTE=$(git remote get-url origin)
   BRANCH=$(git branch --show-current)
   ```
   ```
   get_current_branch_pr(remote_url=$REMOTE, branch=$BRANCH)
   ```

   | Result | Action |
   |--------|--------|
   | `status: success` | Use `pr_url`, proceed |
   | `status: not_found` | **Stop**: "No PR found for branch `$BRANCH`" |
   | Any error | **Stop**: Report the error |

$ARGUMENTS

## Run the loop

Use the Task tool to launch the **`rami-review-loop`** agent with the detected `pr_url` and any user-supplied decision from `$ARGUMENTS`. The agent reads `${CLAUDE_PLUGIN_ROOT}/workflows/rami-code-review/SKILL.md`, which is the single source of truth for the loop algorithm:

- Phase 1: PR detection (skipped — already done above).
- Phase 2: Iterate up to 5 times. Each iteration calls `get_review_results`, exits when `ready_for_review == true`, otherwise acts on every entry in the `blockers` array — finding blockers by severity (Blocking → High → Medium → Low), fixed or rebutted via `content_hash`, and unresolved-thread blockers handled on GitHub. Pushes after each iteration.
- Phase 3: Report a summary, including every file the loop changed.

The workflow enforces the rules that make the loop correct: exit only when `blockers` is empty (`ready_for_review == true`); fix or rebut findings via the MCP tool by `content_hash`, never via a GitHub thread reply or "Resolve conversation" click.

The agent keeps review payloads and fix prompts out of this conversation — only its final report returns. Relay that report to the user in full, including the **Files changed** list. If it contains a **Needs user decision** section, present the options to the user and, once they answer, re-run `/rami:review` with the same `pr_url` and their decision as `user_decision`.

## Error handling

| Error | Action |
|-------|--------|
| MCP tools unavailable | Display the auth instructions above |
| `status: auth_required` from any tool | Display the message from the response (GitHub App install needed) |
| Rate limited | Wait `interval` seconds from the response, retry once, then abort |
