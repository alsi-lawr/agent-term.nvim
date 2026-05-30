# Backend Presets

agent-term.nvim is backend-agnostic. Presets are best-effort defaults for common terminal agents;
they do not guarantee identical capabilities across tools.

You can select a preset with either spelling:

```lua
require("agent_term").setup({
  agent = "codex",
})

require("agent_term").setup({
  backend = "codex",
})
```

You can also start from a preset and override individual fields:

```lua
require("agent_term").setup({
  agent = {
    preset = "codex",
    cmd = { "codex", "--model", "gpt-5.4-mini" },
    resume = {
      all = false,
    },
  },
})
```

Plain custom commands do not inherit preset resume or hook-context behavior. For example,
`agent = { cmd = { "my-agent" } }` defaults to `resume = false` and paste-based context.

## Preset Table

| Preset | Command | Hook installer support | Resume default | Resume all | Resume last |
| --- | --- | --- | --- | --- | --- |
| `codex` | `{ "codex" }` | paste; native hook install supported | `{ "codex", "resume" }` | `{ "codex", "resume", "--all" }` | `{ "codex", "resume", "--last" }` |
| `gemini` | `{ "gemini" }` | paste; native hook install supported | `{ "gemini", "-r" }` | `false` | `{ "gemini", "-r", "latest" }` |
| `claude` | `{ "claude" }` | paste; native hook install supported | `{ "claude", "--resume" }` | `false` | `{ "claude", "--continue" }` |
| `aider` | `{ "aider" }` | paste | `{ "aider", "--restore-chat-history" }` | `false` | `false` |
| `copilot` | `{ "copilot" }` | paste | `{ "copilot", "--resume" }` | `false` | `{ "copilot", "--continue" }` |
| `opencode` | `{ "opencode" }` | paste | `false` | `false` | `{ "opencode", "--continue" }` |

When `resume = false` or a specific resume capability is `false`, the matching resume command is not
registered.

## Context Behavior

Manual context commands always send context text to the running terminal channel with
`nvim_chan_send`.

Optional hook integration writes the latest context command payload to `context.file_path` (default:
`.agent-term/context.json`) for native hook consumers.

When `context.hook.enabled = true`, `agent-term.nvim` automatically updates the context file in the
background as you work:
- **On Buffer Switch**: Updates context for the new file.
- **On Diagnostics Change**: Updates when LSP or linter diagnostics arrive.
- **On Mode Change**: Updates after you finish a visual/select mode selection.

The automatic updates follow a priority order: **Diagnostics > Selection > File Metadata**. This ensures the agent always sees what is most relevant to your current cursor position and editor state.

Codex, Claude, and Gemini can use automatic hook updates after you install native hooks. Aider,
Copilot, and Opencode use paste mode unless a verified native context-injection hook installer is
added.

## Native Hook Installation

Run `:AgentTermInstallHooks` after selecting a supported agent. Installation is explicit; normal
`setup()` never writes agent hook files.

The install command enables `context.hook.enabled = true` for the current Neovim session after it
writes the hook files. To persist automatic hook updates across restarts, install hooks once and
configure:

```lua
require("agent_term").setup({
  agent = {
    preset = "codex", -- or "claude"
  },
  context = {
    hook = { enabled = true },
  },
})
```

Codex merges into:

- `~/.codex/hooks.json`
- `~/.codex/hooks/agent_term_context.py`

The Codex hook is registered for `UserPromptSubmit`. It reads `.agent-term/context.json` and emits:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "..."
  }
}
```

Claude merges into:

- `~/.claude/settings.json`
- `~/.claude/hooks/agent_term_context.py`

The Claude Code hook uses the same `UserPromptSubmit` `hookSpecificOutput.additionalContext` shape
required by Claude Code hooks.

Gemini merges into:

- `~/.gemini/settings.json`
- `~/.gemini/hooks/agent_term_context.py`

The Gemini hook is registered for `BeforeModel`. It reads `.agent-term/context.json` and injects its
content into the `content` field of the `llm_request` before returning it to the CLI.

Installer behavior is idempotent: if the exact hook entry already exists, install leaves config
files unchanged.

To remove installed hooks, delete the matching `UserPromptSubmit` or `BeforeModel` entry from
`~/.codex/hooks.json`, `~/.claude/settings.json`, or `~/.gemini/settings.json`, then delete the generated
`~/.codex/hooks/agent_term_context.py`, `~/.claude/hooks/agent_term_context.py`, or `~/.gemini/hooks/agent_term_context.py` script. You can
also delete `.agent-term/context.json`; it will be recreated when hook-mode context is sent again.

## Custom Resume Support

Custom agents can opt into any resume capability:

```lua
require("agent_term").setup({
  agent = {
    cmd = { "some-agent" },
    resume = {
      default = { "some-agent", "resume" },
      all = false,
      last = { "some-agent", "continue" },
    },
  },
})
```

Preset resume commands are wrappers around each backend's CLI flags. If a backend changes its CLI,
override the preset command locally.
