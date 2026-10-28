---
name: rami-record-decision
description: Use when the user or the code establishes a standing decision about the repository that future Rami reviews should respect, such as "we decided X", "this is required by ADR-140", "this module intentionally does Y", or "record that for Rami". Explains when to call the Rami MCP record_decision tool instead of rebut, how to phrase and anchor the decision, and what happens to it afterwards.
---

# Rami Record Decision

Use the Rami MCP `record_decision` tool to tell Rami about a decision this repository has made, so future reviews stop flagging code that follows it.

## Decide first: record_decision or rebut

| Situation | Tool |
|-----------|------|
| Rami flagged code that is correct because of a deliberate choice | `rebut` the finding. An accepted rebuttal already teaches Rami the decision. |
| The user states a durable decision, or you just made one together, and no finding is involved | `record_decision` |
| A design document or ADR in the repository settles how something must work | `record_decision`, citing the document |
| You want a finding to go away | Not `record_decision`. Fix it, `rebut` it, or `defer` it. |

Never record a decision to silence a finding you have not rebutted. Rami treats recorded decisions as the team's own rules; a decision that exists only to clear a blocker is a false rule every later review inherits.

## How to record

1. Find the pull request with `get_current_branch_pr`. Rami must already have reviewed it; if not, run `get_review_results` first.
2. Call `record_decision`:
   ```
   record_decision(
     pr_url="<pr_url>",
     statement="<one self-contained sentence: the decision and, when known, why>",
     anchors=["<file path>", "<directory/>"],
     category="<optional: error-handling, security, design, ...>"
   )
   ```

Keep the statement to one sentence of at most 400 characters, and use at most 16 anchors.

Write the statement so a reviewer who never saw this conversation could apply it: "Record non-OK provider responses as evidence; ADR-140 requires it." is good. "This is fine." is not a decision.

Anchor the decision to the files or directories it governs whenever you can. A directory anchor ends in `/`. Leave anchors out only when the decision really holds across the whole repository; repository-wide decisions compete for a small prompt budget.

## What happens next

- The decision is recorded for the organization or account the pull request is billed to. Only members of that organization, or that account's owner, can record one.
- It starts **unverified** and does not shape reviews yet. It becomes **active** when another pull request records the same decision, or a teammate confirms it on the repository's Self-tuning page in the Rami console.
- Active decisions shape reviews only on plans that apply learned context (Pro+ for personal accounts, Team+ for organizations). On other plans the decision is kept and starts applying after an upgrade.
- Recording the same decision again from the same pull request changes nothing.
- If a teammate dismissed the same decision before, it stays dismissed.
- Tell the user what you recorded and that a teammate can confirm or dismiss it in the console.
