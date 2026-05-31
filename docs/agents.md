# Agent Presets

agent-term.nvim is agent-agnostic. Presets are best-effort defaults for common terminal agents; they
do not guarantee identical capabilities across tools.

Configure agents by name:

```lua
require("agent_term").setup({
  agents = {
    "claude",
    "codex",
    gemini = {
      preset = "gemini",
      cmd = { "gemini" },
    },
    custom = {
      cmd = { "my-agent" },
    },
  },
})
```

String list entries are shorthand for preset-only agents. The example above creates named `claude`
and `codex` agents from their presets, while `gemini` and `custom` use explicit configuration.

Switch agents at runtime with `:AgentTermSwitch <agent>`. Each configured agent can keep its own
persistent terminal session. Normal switching does not kill existing sessions; `:AgentTermSwitch!
<agent>` kills and recreates only the target agent session.

## Preset Table

| Preset | Command | Hook installer support | Auto-resume picker | Auto-resume last |
| --- | --- | --- | --- | --- |
| `codex` | `{ "codex" }` | paste; native hook install supported | `{ "codex", "resume" }` | `{ "codex", "resume", "--last" }` |
| `gemini` | `{ "gemini" }` | paste; native hook install supported | `{ "gemini", "-r" }` | `{ "gemini", "-r", "latest" }` |
| `claude` | `{ "claude" }` | paste; native hook install supported | `{ "claude", "--resume" }` | `{ "claude", "--continue" }` |
| `aider` | `{ "aider" }` | paste | unavailable | `{ "aider", "--restore-chat-history" }` |
| `copilot` | `{ "copilot" }` | paste | `{ "copilot", "--resume" }` | `{ "copilot", "--continue" }` |
| `opencode` | `{ "opencode" }` | paste | unavailable | `{ "opencode", "--continue" }` |

`agents.<name>.auto_resume` accepts `"picker"`, `"last"`, `false`, or `nil` and defaults to unset.
When a mode is configured for a preset, new terminal sessions start with the matching command shown
above. Existing running sessions are reused unchanged. If `agents.<name>.cmd` is overridden, the
preset's auto-resume arguments are appended to that command.

Plain custom commands do not inherit preset auto-resume behavior. For example, `custom = { cmd = {
"my-agent" } }` starts normally and uses paste-based context unless you configure hook behavior for
that agent.

## Context Behavior

Manual context commands always send context text to the running terminal channel with
`nvim_chan_send`.

Optional hook integration writes the latest context command payload to
`agents.<name>.context.file_path` (default: `.agent-term/context.json`) for native hook consumers.

When `agents.<name>.context.hook.enabled = true`, `agent-term.nvim` automatically updates the
context file in the background as you work:

- **On Buffer Switch**: Updates context for the new file.
- **On Diagnostics Change**: Updates when LSP or linter diagnostics arrive.
- **On Mode Change**: Updates after you finish a visual/select mode selection.

The automatic updates follow a priority order: **Diagnostics > Selection > File Metadata**. This
ensures the agent always sees what is most relevant to your current cursor position and editor
state.

Codex, Claude, and Gemini can use automatic hook updates after you install native hooks. Aider,
Copilot, and Opencode use paste mode unless a verified native context-injection hook installer is
added.

## Native Hook Installation

Run `:AgentTermInstallHooks` with a supported active agent. Installation is explicit; normal
`setup()` never writes agent hook files.

The install command enables `agents.<name>.context.hook.enabled = true` for the current Neovim
session after it writes the hook files. To persist automatic hook updates across restarts, install
hooks once and configure the active agent with hook updates enabled:

```lua
require("agent_term").setup({
  agents = {
    codex = {
      preset = "codex",
      context = { hook = { enabled = true } },
    },
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
`~/.codex/hooks.json`, `~/.claude/settings.json`, or `~/.gemini/settings.json`, then delete the
generated `~/.codex/hooks/agent_term_context.py`, `~/.claude/hooks/agent_term_context.py`, or
`~/.gemini/hooks/agent_term_context.py` script. You can also delete `.agent-term/context.json`; it
will be recreated when hook-mode context is sent again.

## Auto Resume

Auto resume is a per-agent startup mode:

```lua
require("agent_term").setup({
  agents = {
    codex = {
      preset = "codex",
      auto_resume = "last", -- false | nil | "picker" | "last"
    },
  },
})
```

The mode uses the preset command table above. Custom commands start with `agents.<name>.cmd`, even
when `auto_resume` is set, because there is no reliable agent-neutral auto-resume flag to infer.
