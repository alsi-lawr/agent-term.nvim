# agent-term.nvim

<p align="center">
  <img src="assets/demo.gif" alt="agent-term.nvim demo" width="900" />
</p>

<p align="center">
  <strong>Neovim bridge for terminal-based coding agents.</strong>
</p>

`agent-term.nvim` keeps one persistent interactive terminal-agent session alive and lets you
view it as either a centered float or a left, right, or bottom panel. Float and panel are
mutually exclusive views over the same terminal buffer, so switching layouts does not start
a second agent process.

Codex remains the default backend, but the plugin is not Codex-specific. Any compatible
terminal program can be configured if it behaves like an interactive TUI process.

## Requirements

- Neovim 0.12+
- A terminal coding agent installed and authenticated as needed

Supported backend examples:

- OpenAI Codex CLI: `codex`
- Google Gemini CLI: `gemini`
- Claude Code: `claude`
- Aider: `aider`
- Any compatible command configured by the user

## Install

With lazy.nvim:

```lua
{
  "alsi-lawr/agent-term.nvim",
  keys = {
    { "<leader>co", "<cmd>AgentTermToggle<cr>", desc = "Agent terminal" },
    { "<leader>cp", "<cmd>AgentTermPanelToggle<cr>", desc = "Agent panel" },
    { "<leader>cX", "<cmd>AgentTermClose<cr>", desc = "Agent close" },
    { "<leader>ck", "<cmd>AgentTermKill<cr>", desc = "Agent kill" },
    { "<leader>cb", "<cmd>AgentTermSendBufferContext<cr>", desc = "Agent buffer context" },
    { "<leader>cs", "<cmd>AgentTermSendSelectionContext<cr>", mode = { "n", "x" }, desc = "Agent selection context" },
  },
  opts = {},
}
```

For eager loading, use plugin-managed keymaps:

```lua
require("agent_term").setup({
  keymaps = {
    float_toggle = "<leader>ct",
    panel_toggle = "<leader>cp",
    close_all = "<leader>cX",
    kill = "<leader>ck",
    send_buffer_context = "<leader>cb",
    send_selection_context = "<leader>cs",
  },
})
```

`require("agent-term")` and `require("agent_term")` both load the plugin.

## Configuration

Default backend:

```lua
require("agent_term").setup({
  agent = {
    cmd = { "codex" },
    resume = {
      default = { "codex", "resume" },
      all = { "codex", "resume", "--all" },
      last = { "codex", "resume", "--last" },
    },
  },
  float = {
    width = 0.85,
    height = 0.8,
    border = "rounded",
  },
  panel = {
    position = "right", -- "left" | "right" | "bottom"
    width = 0.35,
    height = 0.35,
  },
  context = {
    target_view = "default", -- "default" | "float" | "panel"
    include_file_path = true,
    include_filetype = true,
    include_cursor = true,
    include_selection_range = true,
    include_diagnostics = true,
  },
  keymaps = false,
})
```

Gemini CLI, with no resume support:

```lua
require("agent_term").setup({
  agent = {
    cmd = { "gemini" },
    resume = false,
  },
})
```

Claude Code:

```lua
require("agent_term").setup({
  agent = {
    cmd = { "claude" },
    resume = false,
  },
})
```

Aider:

```lua
require("agent_term").setup({
  agent = {
    cmd = { "aider" },
    resume = false,
  },
})
```

Partial resume support:

```lua
require("agent_term").setup({
  agent = {
    cmd = { "some-agent" },
    resume = {
      default = { "some-agent", "resume" },
      all = false,
      last = false,
    },
  },
})
```

When `resume = false` or a specific capability is `false`, the matching resume command is
not registered.

## How It Works

The plugin manages one terminal job. Opening a float or panel creates a view onto the same
terminal buffer and closes the other view. If the process exits, stale job, buffer, and
window state is cleared.

Context commands send lightweight editor metadata with `nvim_chan_send`. They do not send
full buffer contents.

- Buffer context sends file path, filetype, cursor, and visible range.
- Selection context sends file path, filetype, and selected line range.
- Diagnostics context sends compact diagnostics for the current buffer.

If the agent is not running, `context.target_view` controls where it opens. `"default"`
reuses an open panel if one exists, otherwise it opens a float.

## Lua API

```lua
local agent_term = require("agent_term")

agent_term.setup(opts)

agent_term.open()
agent_term.close()
agent_term.toggle()
agent_term.focus()
agent_term.kill()

agent_term.float_open()
agent_term.float_close()
agent_term.float_toggle()
agent_term.float_focus()

agent_term.panel_open()
agent_term.panel_close()
agent_term.panel_toggle()
agent_term.panel_focus()

agent_term.send_buffer_context()
agent_term.send_selection_context()
agent_term.send_diagnostics_context()

agent_term.resume()
agent_term.resume_all()
agent_term.resume_last()
```

## Testing

This repo uses Plenary's Busted-style Neovim test harness.

Prerequisites:

- [`nvim-lua/plenary.nvim`](https://github.com/nvim-lua/plenary.nvim)
- `stylua`
- `luacheck`

Run the full suite:

```sh
./run_tests.sh
```

If Plenary is not in a standard runtime path:

```sh
PLENARY_PATH=/path/to/plenary.nvim ./run_tests.sh
```

Formatting and linting:

```sh
stylua --check lua tests
luacheck lua tests
```

## Troubleshooting

- `Agent command not found`: check `:echo executable('codex')` or configure `agent.cmd`.
- No selection context: reselect text or run `:'<,'>AgentTermSendSelectionContext`.
- Resume command missing: the backend has `resume = false` or that capability is disabled.
- Resume refused: a session is already running; run `:AgentTermKill` first.

## Command Reference

General commands:

- `:AgentTermOpen` opens or focuses the default floating agent view.
- `:AgentTermClose` closes all agent windows while keeping the process alive.
- `:AgentTermToggle` toggles the default floating agent view.
- `:AgentTermFocus` focuses the default floating agent view.
- `:AgentTermKill` stops the process, closes all agent windows, deletes the terminal buffer, and clears state.

Float commands:

- `:AgentTermFloatOpen`
- `:AgentTermFloatClose`
- `:AgentTermFloatToggle`
- `:AgentTermFloatFocus`

Panel commands:

- `:AgentTermPanelOpen`
- `:AgentTermPanelClose`
- `:AgentTermPanelToggle`
- `:AgentTermPanelFocus`

Context commands:

- `:AgentTermSendBufferContext`
- `:AgentTermSendSelectionContext`
- `:AgentTermSendDiagnosticsContext`

Resume commands, registered only when supported:

- `:AgentTermResume`
- `:AgentTermResumeAll`
- `:AgentTermResumeLast`
