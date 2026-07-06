---
name: rami-upgrade
description: Use when the user wants to update or upgrade the Rami plugin — "upgrade rami", "update the rami plugin", "get the latest rami", or after the SessionStart nudge reports a new version. Compares installed vs latest, shows the changelog, runs the marketplace update, and explains how to activate it.
model: haiku
---

# Upgrade Rami

Update the Rami plugin to the latest published version. The single source of truth for "latest" is the `version` field in `.claude-plugin/plugin.json` on `main` in the marketplace repo — there is no backend version; do not infer the version from the MCP server.

## 1. Compare versions

- **Installed:** run `claude plugin list` (Bash) and read the version for `rami@rami-code-review`.
- **Latest:**
  ```
  WebFetch(url="https://raw.githubusercontent.com/rami-code-review/claude-code-marketplace/main/.claude-plugin/plugin.json", prompt="Return only the value of the top-level version field.")
  ```

If installed == latest, report "Rami is already up to date (vX.Y.Z)" and stop. If the fetch fails, say so and offer to run the update anyway.

## 2. Show what's changing

Fetch the changelog and show the entries between the installed and latest versions:

```
WebFetch(url="https://raw.githubusercontent.com/rami-code-review/claude-code-marketplace/main/CHANGELOG.md", prompt="List the changelog entries for versions newer than <installed> up to <latest>.")
```

## 3. Run the update (marketplace install — the common case)

```bash
claude plugin marketplace update rami-code-review
claude plugin update rami@rami-code-review
```

Then tell the user to run `/reload-plugins` to activate the new version in this session (or it takes effect on the next session). A full restart is not required.

The in-session equivalent for the catalog refresh, if the user prefers to run it: `/plugin marketplace update rami-code-review`.

## 4. Other install methods

- **Direct MCP** (`claude mcp add rami …`): there is no plugin package to update — the MCP server is hosted and updates server-side automatically. To get the slash commands and the update nudge, install via the marketplace instead.
- **Cursor / Codex:** update the Rami plugin through that client's plugin manager; the hosted MCP server needs no action.

## 5. Verify

After `/reload-plugins` (or a new session), confirm with `/rami:doctor` — the "Plugin up to date" check should now show ✓.
