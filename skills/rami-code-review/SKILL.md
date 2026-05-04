---
name: rami-code-review
description: Run the full Rami review loop on a PR. Invoked by /rami:review and auto-triggered when the user asks for "rami review", "review my PR", "fix all rami issues", or similar. Fetches review results, walks issues by severity, fixes or rebuts each, pushes, and re-evaluates until ready_for_review is true.
---

# Rami Code Review — Loop Algorithm

This skill is the single source of truth for the Rami review-fix-rebut loop. Slash commands (`/rami:review`) delegate here.

## Rami owns Rami review state

Every Rami review thread is part of Rami's state machine. Resolution must come through Rami's MCP tools (`rebut`, `defer`, `dismiss`) — never through the GitHub UI.

Forbidden GitHub-side actions on Rami threads:

- Clicking "Resolve conversation" on a Rami thread.
- Replying to a Rami thread via the GitHub review-thread reply box (or the equivalent REST API).
- Editing, deleting, or hiding a Rami review comment.
- Dismissing the Rami review on the PR.
- Approving and merging while `ready_for_review` is `false`.

The authoritative done signal is `ready_for_review == true` from `get_review_results`. Trust that field over GitHub's UI state.

## Inputs

The caller (typically a slash command) provides:

- `pr_url` — the PR to review (already validated by the caller's prerequisite check).

If the caller did not supply `pr_url`, run Phase 1 to detect it from the current branch, then continue.

## Phase 1: PR detection (only if not already provided)

1. Get the remote URL and current branch:
   ```bash
   git remote get-url origin
   git branch --show-current
   ```
2. Call `mcp__plugin_rami-code-review_rami__get_current_branch_pr(remote_url, branch)`.

   | Result | Action |
   |--------|--------|
   | `status: success` | Use `pr_url`, proceed to Phase 2 |
   | `status: not_found` | Stop. Report: "No PR found for branch `<branch>`" |
   | Any error | Stop. Report the error. |

## Phase 2: Review loop

**Initialize:**

- `iteration = 0`
- `max_iterations = 5`
- `history = []`

**Loop:**

1. `iteration++`
2. Call `mcp__plugin_rami-code-review_rami__get_review_results(pr_url)`.
3. **Exit condition.** Stop the loop when `ready_for_review == true` OR `iteration > max_iterations`.
   - `ready_for_review` is true only when `blocking_issue_count == 0` AND `pending_history_count == 0` AND `github_unresolved_count == 0`.
   - Do **not** exit on `issue_count == 0` alone. New-pass `issue_count` ignores carryover findings tracked in `pending_history_count` and human/bot threads in `github_unresolved_count`. A PR can have `issue_count: 0` and still be unmergeable.
4. Record: `history.push({iteration, issues, pending_history_count, github_unresolved_count})`.
5. **Triage each issue.** Walk issues in priority order — Blocking → High → Medium → Low — and include `pending_history_issues` (carryover from previous passes), not just the new-pass `issues`.

   For each issue, decide between **Fix** and **Rebut**:

   - **Fix.** Call `mcp__plugin_rami-code-review_rami__get_fix_prompt(pr_url, issue_index)` for instructions, then apply the change with the Edit tool.
   - **Rebut.** Only when you have one of the four valid reasons: false positive, framework guarantee, intentional design, duplicate. Call `mcp__plugin_rami-code-review_rami__rebut(pr_url, issue_index, author_reply="<one paragraph: reason + evidence>")`.
     - `verdict: valid` → finding dismissed by Rami; move on.
     - `verdict: invalid` or `partial` → **must fix.** Push a code change that addresses Rami's specific concern, or stop and ask the user. Do **not** fall back to a plain GitHub thread reply or click "Resolve conversation"; Rami doesn't ingest those, so the thread will keep blocking `ready_for_review`.

   See the `rami-rebut-finding` skill for the full rebuttal protocol.

6. **Push.** After triaging the iteration's issues:
   ```bash
   git add -A && git commit -m "fix: address rami review feedback" && git push
   ```
7. Continue the loop (back to step 1).

## Phase 3: Report

When the loop exits, summarize:

```text
## Rami Review Summary

PR: <pr_url>
Iterations: <count>
Status: <Clean | N issues remaining>

Per-iteration:
- Iteration N: found X, fixed Y, rebutted Z, remaining R

Rebuttals:
- Issue #N: [verdict] one-line evidence summary
```

## Constraints

- Rebut only with evidence: false positive, framework guarantee, intentional design, duplicate.
- Never rebut to avoid work or for style preferences.
- Stop if the same issue persists across 2+ iterations (likely unfixable by AI; ask the user).
- Follow the host project's commit and push policy. If commits/pushes are gated by additional project rules (pre-commit hooks, branch protections, manual review), respect them — do not bypass.

## Failure modes

| Symptom | Likely cause | What to do |
|---------|--------------|------------|
| Rami MCP tools not available | Plugin not authenticated | Stop. Tell the user to authenticate via `/mcp` (Claude Code) or the equivalent for their client. |
| `status: auth_required` from any tool | OAuth not completed for this user | Stop. Report the auth message. |
| `status: not_found` from `get_current_branch_pr` | No PR exists for this branch | Stop. Report the branch name. |
| Same issue persists 2+ iterations | AI cannot fix it; might be a real false positive Rami won't accept | Stop. Surface the issue and ask the user. |
| Rate limited | Quota exceeded | Wait `interval` seconds from the response, retry once, then abort. |
