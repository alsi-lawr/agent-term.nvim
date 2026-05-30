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
| `codex` | `{ "codex" }` | hook | `{ "codex", "resume" }` | `{ "codex", "resume", "--all" }` | `{ "codex", "resume", "--last" }` |
| `gemini` | `{ "gemini" }` | paste | `{ "gemini", "-r" }` | `false` | `{ "gemini", "-r", "latest" }` |
| `claude` | `{ "claude" }` | hook | `{ "claude", "--resume" }` | `false` | `{ "claude", "--continue" }` |
| `aider` | `{ "aider" }` | paste | `{ "aider", "--restore-chat-history" }` | `false` | `false` |
| `copilot` | `{ "copilot" }` | paste | `{ "copilot", "--resume" }` | `false` | `{ "copilot", "--continue" }` |
| `opencode` | `{ "opencode" }` | paste | `false` | `false` | `{ "opencode", "--continue" }` |

When `resume = false` or a specific resume capability is `false`, the matching resume command is not
registered.

## Context Modes

Paste mode sends context text to the running terminal channel with `nvim_chan_send`.

Hook mode emits a Neovim `User` autocmd and provides the context as
`args.data.hookSpecificOutput.additionalContext`. A receiver must call `args.data.ack()` to
acknowledge delivery. If no receiver acknowledges the payload, agent-term.nvim falls back to paste
mode.

Codex and Claude use hook mode by default because they support this context-injection path. Copilot
and Opencode use paste mode even when they expose their own hook concepts, because those hooks are
not compatible with this context-injection path.

Hook mode is backend-driven, not view-driven. It applies from float, panel, and source-window
context commands when configured.

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
