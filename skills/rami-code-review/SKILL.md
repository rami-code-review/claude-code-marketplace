---
name: rami-code-review
description: Run the Rami review loop on a PR — fetch findings, fix or rebut each by severity, push, repeat until ready_for_review is true. Invoked by /rami:review and auto-triggered when the user asks for "rami review", "review my PR", "fix all rami issues", or similar.
context: fork
---

# Rami Code Review — Loop Algorithm

This skill is the single source of truth for the Rami review-fix-rebut loop. Slash commands (`/rami:review`) delegate here.

On Claude Code this skill runs in a forked subagent (`context: fork`): review payloads and fix prompts stay out of the main conversation, and your final message is the only thing returned to it. The final message must therefore carry the complete Phase 3 report. Wherever these instructions say to stop for a user decision, that means: stop the loop and end the run with the report's **Needs user decision** section filled in — the caller relays it and may re-invoke this skill with the decision.

## Rami owns Rami review state

Every Rami review thread is part of Rami's state machine. Resolution must come through Rami's MCP tools (`rebut`, `defer`, `dismiss`) — never through any other GitHub channel.

Forbidden GitHub-side actions on Rami threads — across **all channels** (GitHub web UI, REST/GraphQL API, `gh` CLI, and any GitHub MCP server tool):

- Clicking "Resolve conversation" on a Rami thread, or the equivalent `gh api` / GraphQL `resolveReviewThread` / GitHub MCP call.
- Replying to a Rami thread via the GitHub review-thread reply box, the REST API (`POST /pulls/:n/comments` with `in_reply_to`), `gh pr review` / `gh api`, or a GitHub MCP `add_pull_request_review_comment_reply` tool.
- Editing, deleting, or hiding a Rami review comment by any means.
- Dismissing the Rami review on the PR.
- Approving and merging while `ready_for_review` is `false`.

Rami does not ingest signals from these channels. A thread that looks resolved or replied-to via `gh` or a GitHub MCP will still block `ready_for_review`, and the loop will keep reporting it as outstanding. **Do not invoke `gh` or GitHub MCP tools against Rami threads during the loop.** They are fine for unrelated PR work (reading diffs, opening PRs, checking CI), but never for resolving, replying to, or dismissing Rami findings.

The authoritative done signal is `ready_for_review == true` from `get_review_results`. Trust that field over what GitHub's UI, `gh`, or any GitHub MCP reports about thread state.

## Inputs

The caller (typically a slash command) provides:

- `pr_url` — the PR to review (already validated by the caller's prerequisite check).
- `user_decision` (optional) — the user's answer to a previous run's **Needs user decision** report. Apply it first (fix by hand as instructed, `defer`, `dismiss`, or rebut with the new evidence), then resume the loop.

If the caller did not supply `pr_url`, run Phase 1 to detect it from the current branch, then continue.

## Phase 1: PR detection (only if not already provided)

1. Get the remote URL and current branch:
   ```bash
   git remote get-url origin
   git branch --show-current
   ```
2. Call `get_current_branch_pr(remote_url, branch)` on the Rami MCP server.

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
2. Call `get_review_results(pr_url)` on the Rami MCP server.
3. **Exit condition.** Stop the loop when `ready_for_review == true` OR `iteration > max_iterations`.
   - `ready_for_review` is true only when `blocking_issue_count == 0` AND `pending_history_count == 0` AND `github_unresolved_count == 0`.
   - Do **not** exit on `issue_count == 0` alone. New-pass `issue_count` ignores carryover findings tracked in `pending_history_count` and human/bot threads in `github_unresolved_count`. A PR can have `issue_count: 0` and still be unmergeable.
4. Record: `history.push({iteration, issues, pending_history_count, github_unresolved_count})`.
5. **Triage each issue.** Walk issues in priority order — Blocking → High → Medium → Low — and include `pending_history_issues` (carryover from previous passes), not just the new-pass `issues`.

   For each issue, decide between **Fix** and **Rebut**:

   - **Fix.** Call `get_fix_prompt(pr_url, issue_index)` on the Rami MCP server for instructions, then apply the change with the Edit tool.
   - **Rebut.** Only when you have one of the four valid reasons: false positive, framework guarantee, intentional design, duplicate. Call `rebut(pr_url, issue_index, author_reply="<one paragraph: reason + evidence>")` on the Rami MCP server.
     - `verdict: valid` → finding dismissed by Rami; move on.
     - `verdict: invalid` or `partial` → **must fix.** Push a code change that addresses Rami's specific concern, or stop the loop and report it under **Needs user decision**. Do **not** fall back to a GitHub thread reply, "Resolve conversation" click, `gh` command, or GitHub MCP call — Rami doesn't ingest any of those, so the thread will keep blocking `ready_for_review`.

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

Files changed:
- <path> — <one line: which issue this fixed>

Per-iteration:
- Iteration N: found X, fixed Y, rebutted Z, remaining R

Rebuttals:
- Issue #N: [verdict] one-line evidence summary

Needs user decision (omit when none):
- <issue>: <what was tried and why the loop stopped> — options: fix by hand | rebut with new evidence | defer | dismiss
```

List every file the loop edited under **Files changed** — in a forked run the user never sees the edits happen, so this list is their only record.

## Constraints

- Rebut only with evidence: false positive, framework guarantee, intentional design, duplicate.
- Never rebut to avoid work or for style preferences.
- Stop if the same issue persists across 2+ iterations (likely unfixable by AI); report it under **Needs user decision**.
- Follow the host project's commit and push policy. If commits/pushes are gated by additional project rules (pre-commit hooks, branch protections, manual review), respect them — do not bypass.

## Failure modes

| Symptom | Likely cause | What to do |
|---------|--------------|------------|
| Rami MCP tools not available | Plugin not authenticated | Stop. Tell the user to authenticate via `/mcp` (Claude Code) or the equivalent for their client. |
| `status: auth_required` from any tool | OAuth not completed for this user | Stop. Report the auth message. |
| `status: not_found` from `get_current_branch_pr` | No PR exists for this branch | Stop. Report the branch name. |
| Same issue persists 2+ iterations | AI cannot fix it; might be a real false positive Rami won't accept | Stop. Report it under **Needs user decision**. |
| Rate limited | Quota exceeded | Wait `interval` seconds from the response, retry once, then abort. |
