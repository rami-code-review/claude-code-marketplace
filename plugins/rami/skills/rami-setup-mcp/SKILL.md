---
name: rami-setup-mcp
description: Use when the user wants to set up, install, or configure Rami — phrases like "install Rami", "set up Rami MCP", "how do I add Rami to Claude Code / Cursor / Codex", "connect Rami". Walks the user through the GitHub App install, MCP server registration, OAuth, and a verification call. Mirrors the public guidance at https://rami.reviews/llms.txt.
---

# Set Up Rami MCP

Three things have to be in place before Rami can review and the autofix loop can run:

1. **The Rami GitHub App** is installed on the target repository (so Rami can read PRs and post review comments).
2. **The Rami MCP server** is registered with the user's MCP client (Claude Code, Cursor, Codex, or another).
3. **OAuth** has been completed (so the MCP server knows who the user is and can scope access to their repos).

Do these in order. Skipping ahead causes confusing errors — e.g., the MCP server returns `auth_required` if OAuth isn't done, or `not_found` if the GitHub App isn't installed on the repo.

## Step 1: Install the GitHub App

You cannot do this programmatically. Ask the user to open this URL and authorize the app on at least one repository:

```
https://github.com/apps/rami-code-remeow
```

This enables automatic PR reviews on every push. After install, the user should see Rami appear as a reviewer on new PRs in the chosen repos.

## Step 2: Register the MCP Server

Pick the right snippet based on the user's MCP client.

### Claude Code (recommended: plugin marketplace)

```bash
claude plugin marketplace add rami-code-review/claude-code-marketplace
claude plugin install rami@rami-code-review
```

This installs the MCP server, the slash commands (`/rami:review`, `/rami:review-status`, `/rami:usage`, `/rami:setup`, `/rami:doctor`, `/rami:upgrade`), and handles OAuth.

### Claude Code (direct MCP, no plugin)

```bash
claude mcp add rami --transport http https://rami.reviews/mcp
```

### Cursor

Add to `.cursor/mcp.json` in the project root:

```json
{
  "mcpServers": {
    "rami": {
      "url": "https://rami.reviews/mcp"
    }
  }
}
```

### Codex (recommended: plugin marketplace)

```bash
codex plugin marketplace add rami-code-review/claude-code-marketplace
codex plugin add rami@rami-code-review
```

Start a new task after installation. This installs the Rami MCP server and the review, status, setup, doctor, upgrade, and rebuttal skills together.

### Codex (direct MCP, no plugin)

```bash
codex mcp add rami --url https://rami.reviews/mcp
```

Codex detects OAuth support and completes the login inside this one command — there is no separate authentication step. Verify with `codex mcp list`, which should report rami as enabled with OAuth auth. The equivalent entry in `~/.codex/config.toml` is:

```toml
[mcp_servers.rami]
url = "https://rami.reviews/mcp"
```

Installing the Rami plugin from the marketplace additionally gives Codex the review, status, setup, doctor, upgrade, and rebuttal skills.

**Stop Codex's per-call approval prompts.** Codex asks for approval on every Rami tool call because the calls reach an external service. The client sends only the PR URL — Rami reads the PR through its GitHub App installation — so the read-only tools are safe to pre-approve. Note that `get_review_results` starts a review when none exists yet; that is the loop working as intended, and re-reviewing the same PR does not consume additional quota. It also blocks while a review runs, reporting each stage as the review reaches it, so leaving it unapproved stalls the loop behind a prompt on every status update. Offer to add these entries to `~/.codex/config.toml`, and apply them only with the user's consent (this must be user-level config; Codex ignores approval settings shipped inside a plugin):

```toml
[mcp_servers.rami.tools.get_review_results]
approval_mode = "approve"

[mcp_servers.rami.tools.get_review_status]
approval_mode = "approve"

[mcp_servers.rami.tools.get_fix_prompt]
approval_mode = "approve"

[mcp_servers.rami.tools.get_current_branch_pr]
approval_mode = "approve"

[mcp_servers.rami.tools.get_usage]
approval_mode = "approve"
```

Leave `rebut`, `defer`, and `dismiss` unlisted — they mutate review state, and Codex should keep asking before each of those.

### Other MCP clients

Hosted MCP server URL:

```
https://rami.reviews/mcp
```

Use the standard `mcpServers` config shape your client expects, with `transport: http` and that URL.

## Step 3: Authenticate (OAuth)

On first use, the MCP server prompts for OAuth. The exact UX depends on the client.

For Claude Code:

1. Run `/mcp` in Claude Code.
2. Select `plugin:rami:rami` (or the equivalent for direct-MCP install).
3. Press Enter to log in.
4. Complete GitHub authentication in the browser tab that opens.
5. Return to Claude Code.

Codex completes OAuth inside `codex mcp add` (Step 2) — no further action needed. For Cursor and other clients, the client typically opens an OAuth window the first time you call any Rami tool; follow its prompt.

## Step 4: Verify

Run a cheap, side-effect-free call to confirm everything is wired up:

Call `get_usage()` on the Rami MCP server.

A successful response includes `remaining_reviews`, `quota_limit`, `credit_balance`, and a dashboard URL. If you see `auth_required`, OAuth didn't complete — go back to Step 3. If the call returns successfully but says you have zero reviews, the user may need to upgrade plans, but the wiring is fine.

You can also probe the auth resource directly:

```
ReadMcpResource(uri="rami://auth/status")
```

This returns auth state without consuming any quota.

## Step 5: First Review (optional)

If the user has an open PR on a repo where the GitHub App is installed, call on the Rami MCP server:

```
get_current_branch_pr(remote_url=$REMOTE, branch=$BRANCH)
get_review_results(pr_url=<from above>)
```

If `get_review_results` blocks for a while and then returns `status: completed`, Rami is fully set up and the autofix loop is available.

## Step 6: Extend project instructions (optional — ask first)

Most of Rami's workflow loads only when a Rami command or Codex skill runs, so it does **not** belong in always-on project instructions. There is one exception worth persisting: the **state-ownership rule**, so an agent working on an unrelated task never resolves a Rami thread the wrong way (via the GitHub UI or `gh`, which Rami doesn't ingest).

**Only do this with explicit consent.** Ask:

> Add a short Rami section to this repo's project instructions (`CLAUDE.md` / `AGENTS.md`)? It's one fenced block, easy to remove.

If the user declines, skip this — it is not required for Rami to work.

If they agree:

1. **Pick the target file** in the repo root: `CLAUDE.md` for Claude Code, `AGENTS.md` for Codex/other agents. If both exist, ask which (or do both). If neither exists, ask before creating one.
2. **Idempotency:** if a `<!-- rami:begin` … `rami:end -->` block already exists, replace its contents in place — never append a second copy.
3. **Append (or update in place) exactly this block, and nothing else:**

   ```markdown
   <!-- rami:begin (managed by /rami:setup) -->
   ## Rami code review
   - Use `/rami:review` to review the current PR; it is ready only when `ready_for_review` is true.
   - Rami owns its review threads. Resolve findings ONLY via Rami's MCP tools (rebut/defer/dismiss).
     Never resolve, reply to, or close a Rami thread via the GitHub UI, `gh`, or GitHub MCP — Rami
     does not ingest those actions and the thread keeps blocking `ready_for_review`.
   <!-- rami:end -->
   ```

4. **Confirm** what changed and note the block is fenced for easy removal.

**To remove it later:** delete everything from `<!-- rami:begin` through `rami:end -->` (inclusive) and leave the rest of the file untouched. If the user asks to remove the Rami section, do exactly that.

## What "set up" means downstream

Once these three steps are done, the user has access to:

- **Automatic reviews on push** — the GitHub App posts inline review comments on every PR.
- **The autofix loop via MCP** — agents call `get_review_results` after every push, fix or rebut findings via `get_fix_prompt` / `rebut`, and re-run until `ready_for_review: true`.
- **Claude Code slash commands** — `/rami:review`, `/rami:review-status`, `/rami:usage`, `/rami:setup`, `/rami:doctor`, `/rami:upgrade`.
- **Codex skills** — review, review status, setup, doctor, upgrade, and rebuttal workflows that trigger from natural-language requests.
- **Rebuttal skill** — natural-language requests such as "rebut this" or "Rami is wrong about this finding" trigger `rami-rebut-finding`, which uses Rami's MCP rebuttal protocol.
- **Web console** — usage and credit balance at https://rami.reviews.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `auth_required` from any tool | OAuth not completed | Run Step 3 |
| `not_found` from `get_review_results` for a real PR URL | GitHub App not installed on this repo | Step 1, scope the install to include this repo |
| `get_current_branch_pr` returns `status: not_found` | No PR exists for this branch yet | Push the branch and open a PR first |
| Rate-limited responses | Quota exceeded for current period | Check `get_usage`; may need a paid plan or credits |
| Codex asks for approval on every Rami call | No per-tool `approval_mode` in user config | Add the per-tool `approval_mode = "approve"` entries from Step 2 to `~/.codex/config.toml` (with user consent) |

## Authoritative reference

The public-facing version of this guide lives at:

```
https://rami.reviews/llms.txt
```

If anything in this workflow drifts from llms.txt, llms.txt wins — it is what every other LLM client fetches and is what users see.
