---
name: rami-rebut-finding
description: Use when the user wants to challenge, rebut, or dispute a Rami code review finding — phrases like "rebut this", "this is a false positive", "Rami is wrong about X", "tell Rami this is intentional". Walks through the right MCP tool to use, the four valid rebut reasons, and what to do when Rami rejects the rebuttal.
---

# Rami Rebut Finding

Use the Rami MCP `rebut` tool to challenge a finding. This is the only sanctioned channel for disagreement. Nothing posted to the GitHub review thread itself — whether via the web UI, the REST/GraphQL API, the `gh` CLI, or any GitHub MCP server — flows into Rami's state machine.

## Decide first: rebut, fix, defer, or dismiss

| Situation | Tool |
|-----------|------|
| The finding is wrong (false positive, framework guarantee, intentional design, duplicate) | `rebut` |
| The finding is correct but you want to fix it | normal Edit + commit + push, then re-run `get_review_results` |
| The finding is correct and valid but out of scope for this PR | `defer` (acknowledges and stops re-raising) |
| The user has explicitly told you to discard the finding without evaluation | `dismiss` (user-asked-only escape hatch) |
| You don't have evidence for any of the four rebut reasons | Fix it. Do not rebut to avoid work. |

## Valid rebut reasons

A rebuttal must rest on one of these four:

1. **False positive** — the code does not exhibit the behavior Rami claims. Cite the specific line that disproves the claim.
2. **Framework guarantee** — the surrounding framework, runtime, or library handles the case Rami is worried about. Name the framework and the guarantee.
3. **Intentional design** — the code is deliberate, and the trade-off is documented or otherwise defensible. Cite the rationale.
4. **Duplicate** — the same finding has already been raised and addressed elsewhere on this PR or in a recent earlier pass. Cite the other finding.

If your reason doesn't fit one of these, you don't have a rebuttal — fix the issue.

## How to rebut

1. Get the finding's `content_hash` (preferred) or `comment_id` from the most recent `get_review_results(pr_url)` response.
2. Call:
   ```
   mcp__plugin_rami-code-review_rami__rebut(
     pr_url="<pr_url>",
     content_hash="<hash from get_review_results>",
     author_reply="<one paragraph: which of the four reasons + the specific evidence>"
   )
   ```
   Use `comment_id` only if the finding came from GitHub directly and has no `content_hash`.

3. Read the verdict:
   - `valid` — finding dismissed, thread closed by Rami. Move to the next issue.
   - `partial` — Rami partially agrees but still believes part of the finding stands. Push a code fix that addresses the remaining concern, or escalate to the user. Do NOT reply or resolve via GitHub UI, `gh`, or any GitHub MCP.
   - `invalid` — Rami stands by the finding. Either push a code fix that addresses Rami's specific concern, or stop and ask the user. Do NOT reply or resolve via GitHub UI, `gh`, or any GitHub MCP.

## Forbidden actions when a rebuttal fails

If Rami returns `partial` or `invalid`, **do not** attempt to work around it via any GitHub-side channel. None of the following change Rami's state, regardless of whether they are issued through the web UI, the REST/GraphQL API, the `gh` CLI, or a GitHub MCP server:

- Posting a plain reply to the GitHub review thread (web UI reply box, `POST /pulls/:n/comments` with `in_reply_to`, `gh pr review` / `gh api`, or a GitHub MCP `add_pull_request_review_comment_reply` tool).
- Clicking "Resolve conversation" on the thread, or the equivalent `gh api` / GraphQL `resolveReviewThread` / GitHub MCP call.
- Editing, deleting, or hiding the Rami review comment by any means.
- Dismissing the Rami review on GitHub.
- Approving and merging while `ready_for_review` is `false`.

A thread that looks resolved on GitHub — by any of those channels — but is `invalid` to Rami will keep blocking `ready_for_review` and any merge gate that consults it. **Do not reach for `gh` or a GitHub MCP as a shortcut around Rami's state machine.**

## Escalation

If you have rebutted the same finding twice with different evidence and Rami still returns `invalid`, stop and ask the user. The user decides whether the finding is genuinely wrong (in which case they may use `dismiss`) or whether your evidence is missing something.

Never escalate by editing, hiding, or merging around a Rami thread — and do not invoke `gh` or any GitHub MCP server to do it for you.

## Reporting back

When you're done, summarize for the user:

```
## Rami Rebuttal

Issue: <one-line description>
Reason cited: <false positive | framework guarantee | intentional design | duplicate>
Verdict: <valid | partial | invalid>
Outcome: <Dismissed | Pushed fix | Escalated to user>
```
