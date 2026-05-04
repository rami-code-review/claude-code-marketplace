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

This installs the MCP server, the slash commands (`/rami:review`, `/rami:status`, `/rami:usage`), and handles OAuth.

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

### Codex CLI

Install the Rami plugin from this marketplace's Codex metadata. The Codex plugin exposes the same MCP server as the Claude plugin and gives Codex sessions the same `/rami:review`, `/rami:status`, and `/rami:usage` workflows.

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

For Cursor, Codex, and others, the client typically opens an OAuth window the first time you call any Rami tool. Follow its prompt.

## Step 4: Verify

Run a cheap, side-effect-free call to confirm everything is wired up:

```
mcp__plugin_rami-code-review_rami__get_usage()
```

A successful response includes `remaining_reviews`, `quota_limit`, `credit_balance`, and a dashboard URL. If you see `auth_required`, OAuth didn't complete — go back to Step 3. If the call returns successfully but says you have zero reviews, the user may need to upgrade plans, but the wiring is fine.

You can also probe the auth resource directly:

```
ReadMcpResource(uri="rami://auth/status")
```

This returns auth state without consuming any quota.

## Step 5: First Review (optional)

If the user has an open PR on a repo where the GitHub App is installed, run:

```
mcp__plugin_rami-code-review_rami__get_current_branch_pr(remote_url=$REMOTE, branch=$BRANCH)
mcp__plugin_rami-code-review_rami__get_review_results(pr_url=<from above>)
```

If `get_review_results` blocks for a while and then returns `status: completed`, Rami is fully set up and the autofix loop is available.

## What "set up" means downstream

Once these three steps are done, the user has access to:

- **Automatic reviews on push** — the GitHub App posts inline review comments on every PR.
- **The autofix loop via MCP** — agents call `get_review_results` after every push, fix or rebut findings via `get_fix_prompt` / `rebut`, and re-run until `ready_for_review: true`.
- **Slash commands** (Claude Code / Codex with plugin) — `/rami:review`, `/rami:status`, `/rami:usage`.
- **Web console** — usage and credit balance at https://rami.reviews.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `auth_required` from any tool | OAuth not completed | Run Step 3 |
| `not_found` from `get_review_results` for a real PR URL | GitHub App not installed on this repo | Step 1, scope the install to include this repo |
| `get_current_branch_pr` returns `status: not_found` | No PR exists for this branch yet | Push the branch and open a PR first |
| Rate-limited responses | Quota exceeded for current period | Check `get_usage`; may need a paid plan or credits |

## Authoritative reference

The public-facing version of this guide lives at:

```
https://rami.reviews/llms.txt
```

If anything in this skill drifts from llms.txt, llms.txt wins — it is what every other LLM client fetches and is what users see.
