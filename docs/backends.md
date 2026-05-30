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

| Preset | Command | Context mode | Resume default | Resume all | Resume last |
| --- | --- | --- | --- | --- | --- |
| `codex` | `{ "codex" }` | paste; native hook install supported | `{ "codex", "resume" }` | `{ "codex", "resume", "--all" }` | `{ "codex", "resume", "--last" }` |
| `gemini` | `{ "gemini" }` | paste | `{ "gemini", "-r" }` | `false` | `{ "gemini", "-r", "latest" }` |
| `claude` | `{ "claude" }` | paste; native hook install supported | `{ "claude", "--resume" }` | `false` | `{ "claude", "--continue" }` |
| `aider` | `{ "aider" }` | paste | `{ "aider", "--restore-chat-history" }` | `false` | `false` |
| `copilot` | `{ "copilot" }` | paste | `{ "copilot", "--resume" }` | `false` | `{ "copilot", "--continue" }` |
| `opencode` | `{ "opencode" }` | paste | `false` | `false` | `{ "opencode", "--continue" }` |

When `resume = false` or a specific resume capability is `false`, the matching resume command is not
registered.

## Context Modes

Paste mode sends context text to the running terminal channel with `nvim_chan_send`.

Hook mode writes the latest context command payload to `context.file_path` (default:
`.agent-term/context.json`) and does not paste anything into the terminal. A native agent hook reads
that file during the agent's `UserPromptSubmit` event and returns it as `additionalContext`.

Codex and Claude can use hook mode after you install native hooks. Gemini, Aider, Copilot, and
Opencode use paste mode unless a verified native context-injection hook installer is added.

Hook mode is backend-driven, not view-driven. It applies from float, panel, and source-window
context commands when configured.

## Native Hook Installation

Run `:AgentTermInstallHooks` after selecting a supported agent. Installation is explicit; normal
`setup()` never writes agent hook files.

The install command enables `agent.context.mode = "hook"` for the current Neovim session after it
writes the hook files. To persist hook mode across restarts, install the hooks once and configure:

```lua
require("agent_term").setup({
  agent = {
    preset = "codex", -- or "claude"
    context = { mode = "hook" },
  },
})
```

Codex writes:

- `.codex/hooks.json`
- `.codex/hooks/agent_term_context.py`

The Codex hook is registered for `UserPromptSubmit`. It reads `.agent-term/context.json` and emits:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "..."
  }
}
```

Claude writes:

- `.claude/settings.json`
- `.claude/hooks/agent_term_context.py`

The Claude Code hook uses the same `UserPromptSubmit` `hookSpecificOutput.additionalContext` shape
required by Claude Code hooks.

To remove installed hooks, delete the matching `UserPromptSubmit` entry from `.codex/hooks.json` or
`.claude/settings.json`, then delete the generated `agent_term_context.py` script. You can also
delete `.agent-term/context.json`; it will be recreated when hook-mode context is sent again.

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
