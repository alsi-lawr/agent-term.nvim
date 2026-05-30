# agent-term.nvim

<p align="center">
  <img src="assets/demo.gif" alt="agent-term.nvim demo" width="900" />
</p>

<p align="center">
  <strong>Neovim bridge for terminal-based coding agents.</strong>
</p>

<p align="center">
  <code>agent-term.nvim</code> keeps one persistent interactive terminal-agent session alive and lets you view it as either a centered float or a left, right, or bottom panel.
</p>

<p align="center">
  Float and panel are mutually exclusive views over the same terminal buffer, so switching layouts does not start a second agent process.
</p>

<p align="center">
  <a href="#install">Install</a> ·
  <a href="#configuration">Configuration</a> ·
  <a href="#how-it-works">How It Works</a> ·
  <a href="#lua-api">Lua API</a> ·
  <a href="#command-reference">Command Reference</a>
</p>

## At a Glance

<table>
  <tr>
    <td><strong>One session</strong><br />Keeps a single terminal-agent process alive and reuses it across views.</td>
    <td><strong>Multiple layouts</strong><br />Switch between float and panel without spawning a second terminal.</td>
    <td><strong>Lightweight context</strong><br />Send buffer, selection, and diagnostics metadata without dumping full contents.</td>
  </tr>
</table>

Codex remains the default backend, but the plugin is backend-agnostic. Compatibility depends on the configured command behaving like an interactive terminal program.

Supported backend examples:

- OpenAI Codex CLI: `codex`
- Google Gemini CLI: `gemini`
- Claude Code: `claude`
- Aider: `aider`
- Any compatible command configured by the user

## Requirements

- Neovim 0.12+
- A terminal coding agent installed and authenticated as needed

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

Keymaps are optional. The example above shows suggested lazy.nvim mappings; remove or change any of them to fit your config.

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

## Quick Agent Switch

Use the supported agent enum (or equivalent string) when you do not need full backend details:

```lua
local enums = require("agent_term.enums")

require("agent_term").setup({
  agent = enums.agent.GEMINI, -- also accepts "gemini"
})
```

Supported enum values:

- `enums.agent.CODEX`
- `enums.agent.GEMINI`
- `enums.agent.CLAUDE`
- `enums.agent.AIDER`

Presets map to sane defaults:

- `codex`: `cmd = { "codex" }` with resume commands enabled.
- `gemini`: `cmd = { "gemini" }` with resume defaults:
  - `default = { "gemini", "-r" }`
  - `last = { "gemini", "-r", "latest" }`
  - `all = false`
- `claude`: `cmd = { "claude" }` with resume defaults:
  - `default = { "claude", "--resume" }`
  - `last = { "claude", "--continue" }`
  - `all = false`
- `aider`: `cmd = { "aider" }` with resume defaults:
  - `default = { "aider", "--restore-chat-history" }`
  - `last = false`
  - `all = false`

You can also start from a preset and override fields:

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

`backend = "..."` is also accepted as an alias of `agent = "..."`.

## Configuration

Defaults:

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

The lazy.nvim `keys` field belongs to lazy.nvim and controls lazy-loading mappings. The plugin `keymaps` option controls mappings created by `require("agent_term").setup()`. By default, plugin-managed mappings are disabled.

To let the plugin create mappings instead:

```lua
require("agent_term").setup({
  keymaps = {
    float_open = "<leader>co",
    float_close = "<leader>cx",
    float_toggle = "<leader>ct",
    panel_open = "<leader>cpo",
    panel_close = "<leader>cpx",
    panel_toggle = "<leader>cpt",
    close_all = "<leader>cX",
    kill = "<leader>ck",
    send_buffer_context = "<leader>cb",
    send_selection_context = "<leader>cs",
    send_diagnostics_context = "<leader>cd",
    resume = "<leader>cr",
  },
})
```

Set any plugin-managed keymap to `false` or `nil` to disable it.

Backend-specific examples:

Gemini CLI:

```lua
require("agent_term").setup({
  agent = {
    cmd = { "gemini" },
    resume = {
      default = { "gemini", "-r" },
      all = false,
      last = { "gemini", "-r", "latest" },
    },
  },
})
```

Claude Code:

```lua
require("agent_term").setup({
  agent = {
    cmd = { "claude" },
    resume = {
      default = { "claude", "--resume" },
      all = false,
      last = { "claude", "--continue" },
    },
  },
})
```

Aider:

```lua
require("agent_term").setup({
  agent = {
    cmd = { "aider" },
    resume = {
      default = { "aider", "--restore-chat-history" },
      all = false,
      last = false,
    },
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

When `resume = false` or a specific capability is `false`, the matching resume command is not registered.

## How It Works

`agent-term.nvim` manages one terminal job by default. Opening a float or panel creates a view onto the same terminal buffer and closes the other view. Repeated open and toggle calls reuse the existing session.

If the agent process exits, stale job, buffer, and window state is cleared. If a resume command is run while an agent is already running, the plugin asks you to run `:AgentTermKill` first.

## Context

Context commands send lightweight editor metadata with `nvim_chan_send`. They do not send full buffer contents.

- Buffer context sends file path, filetype, cursor, and visible range.
- Selection context sends file path, filetype, and selected line range.
- Diagnostics context sends compact diagnostics for the current buffer.

Injected context is explicitly marked as ambient editor state. The agent is told to use it only when relevant to the user's next prompt.

If the agent is not running, `context.target_view` controls where it opens. `"default"` reuses an open panel if one exists, otherwise it opens a float.

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

This repo uses Plenary's busted-style Neovim test harness.

Why Plenary (and not `mini.test`):

- The plugin tests need real Neovim API/state (`vim.api`, windows, buffers, diagnostics, user commands).
- Plenary's `PlenaryBustedDirectory` is the most common Neovim plugin convention for this and keeps setup small.
- `mini.test` is good for pure-Lua/unit-style suites, but it does not simplify this plugin's Neovim-hosted integration cases enough to justify a migration right now.

Prerequisite:

- [`nvim-lua/plenary.nvim`](https://github.com/nvim-lua/plenary.nvim) installed (for example via lazy.nvim).
- `stylua` installed for formatting.
- `luacheck` installed for linting.

Run the full suite:

```sh
./run_tests.sh
```

Raw Neovim command (no wrapper):

```sh
nvim --headless -u tests/minimal_init.lua -i NONE \
  -c "PlenaryBustedDirectory tests/spec { minimal_init = 'tests/minimal_init.lua' }" \
  -c "qa"
```

If Plenary is not in a standard path, point the harness at it:

```sh
PLENARY_PATH=/path/to/plenary.nvim ./run_tests.sh
```

Formatting and linting:

```sh
stylua --check lua tests
luacheck lua tests
```

Editor diagnostics:

- `.luarc.json` provides project-level LuaLS settings for Neovim and Busted/Plenary globals.
- `tests/types/busted.lua` declares test globals in-repo so language tooling does not rely on local editor assumptions.

Optional coverage for pure Lua modules only:

- Keep Neovim-hosted tests as the default path.
- If you add pure Lua specs (for example under `tests/pure`), you can run coverage separately:

```sh
LUA_INIT='require("luacov")' busted tests/pure
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
