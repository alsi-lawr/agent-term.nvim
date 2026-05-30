# agent-term.nvim

<p align="center">
  <img src="docs/assets/demo.gif" alt="agent-term.nvim demo" width="900" />
</p>

<p align="center">
  <strong>Neovim bridge for terminal-based coding agents.</strong>
</p>

<p align="center">
  <code>agent-term.nvim</code> keeps one persistent interactive terminal-agent session alive and lets you view it as either a centered float or a left, right, or bottom panel.
</p>

<p align="center">
  Float and panel are mutually exclusive views over the same terminal buffer, so switching layouts does not start another agent process.
</p>

<p align="center">
  <a href="#install">Install</a> ·
  <a href="#minimal-configuration">Config</a> ·
  <a href="#backend-presets">Backends</a> ·
  <a href="#context-behaviour">Context</a> ·
  <a href="#quick-reference">Quick Reference</a> ·
  <a href="#advanced-docs">Advanced Docs</a>
</p>

## At a Glance

<table>
  <tr>
    <td><strong>One session</strong><br />Keeps a single terminal-agent process alive and reuses it across views.</td>
    <td><strong>Two layouts</strong><br />Switch between float and panel without spawning a second terminal.</td>
    <td><strong>Lightweight context</strong><br />Send buffer, selection, and diagnostics metadata without dumping full contents.</td>
  </tr>
  <tr>
    <td><strong>Backend presets</strong><br />Start quickly with Codex, Gemini, Claude, Aider, Copilot, or Opencode.</td>
    <td><strong>Custom agents</strong><br />Run any compatible interactive terminal command.</td>
    <td><strong>Resume aware</strong><br />Registers resume commands only when the configured backend supports them.</td>
  </tr>
</table>

The default backend is Codex, but the plugin is backend-agnostic. Presets are best-effort defaults
for common terminal agents; any compatible interactive command can be configured directly.

## Requirements

- Neovim 0.12+
- A terminal coding agent installed and authenticated as needed

## Install

With lazy.nvim:

```lua
{
  "alsi-lawr/agent-term.nvim",
  main = "agent_term",
  keys = {
    { "<leader>co", "<cmd>AgentTermToggle<cr>", desc = "Agent terminal" },
    { "<leader>cp", "<cmd>AgentTermPanelToggle<cr>", desc = "Agent panel" },
    { "<leader>ck", "<cmd>AgentTermKill<cr>", desc = "Agent kill" },
    { "<leader>cb", "<cmd>AgentTermSendBufferContext<cr>", desc = "Agent buffer context" },
    { "<leader>cs", "<cmd>AgentTermSendSelectionContext<cr>", mode = { "n", "x" }, desc = "Agent selection context" },
  },
  opts = {},
}
```

The `keys` block above is a lazy.nvim example. Plugin-managed keymaps are disabled by default.

## Minimal Configuration

Use a preset when the default command is enough:

```lua
require("agent_term").setup({
  agent = "claude",
})
```

Or override the command while inheriting preset defaults:

```lua
require("agent_term").setup({
  agent = {
    preset = "codex",
    cmd = { "codex", "--model", "gpt-5.4-mini" },
  },
})
```

Custom commands are supported too. Plain custom commands default to paste-based context and no
resume support unless configured explicitly:

```lua
require("agent_term").setup({
  agent = {
    cmd = { "my-agent" },
  },
  context = {
    target_view = "default", -- "default" | "float" | "panel"
  },
})
```

`backend = "..."` is also accepted as an alias for `agent = "..."`.

## Backend Presets

Presets are convenience defaults, not a guarantee of feature parity across tools. Exact commands and
caveats are documented in [docs/backends.md](docs/backends.md).

| Preset | Command | Context mode | Resume summary |
| --- | --- | --- | --- |
| `codex` | `codex` | hook | default, all, last |
| `gemini` | `gemini` | paste | default, last |
| `claude` | `claude` | hook | default, last |
| `aider` | `aider` | paste | default |
| `copilot` | `copilot` | paste | default, last |
| `opencode` | `opencode` | paste | last |

Supported enum values are available at `require("agent_term.enums").agent`.

## Quick Reference

<table>
  <tr>
    <th>Need</th>
    <th>Use</th>
    <th>More detail</th>
  </tr>
  <tr>
    <td>Open the default agent view</td>
    <td><code>:AgentTermToggle</code></td>
    <td><a href="#common-commands">Common commands</a></td>
  </tr>
  <tr>
    <td>Use a side or bottom panel</td>
    <td><code>:AgentTermPanelToggle</code></td>
    <td><a href="#common-commands">Common commands</a></td>
  </tr>
  <tr>
    <td>Send editor context</td>
    <td><code>:AgentTermSendBufferContext</code>, <code>:AgentTermSendSelectionContext</code>, or <code>:AgentTermSendDiagnosticsContext</code></td>
    <td><a href="#context-behaviour">Context behaviour</a></td>
  </tr>
  <tr>
    <td>Switch backend preset</td>
    <td><code>agent = "claude"</code></td>
    <td><a href="docs/backends.md">Backend presets</a></td>
  </tr>
  <tr>
    <td>Override backend flags</td>
    <td><code>agent = { preset = "...", cmd = { ... } }</code></td>
    <td><a href="docs/backends.md">Backend presets</a></td>
  </tr>
  <tr>
    <td>Run checks locally</td>
    <td><code>./run_tests.sh</code>, <code>stylua --check lua tests</code>, <code>luacheck lua tests</code></td>
    <td><a href="CONTRIBUTING.md">Contribution Guide</a></td>
  </tr>
</table>

## Context Behaviour

Context commands send lightweight editor metadata, not full buffer contents.

- Buffer context sends file path, filetype, cursor, and visible range.
- Selection context sends file path, filetype, and selected line range.
- Diagnostics context sends compact diagnostics for the current buffer.

Paste mode sends context to the running terminal job. Hook mode is an advanced backend capability:
it emits a Neovim `User` autocmd and requires a receiver to acknowledge delivery. If hook delivery
is not acknowledged, agent-term.nvim falls back to paste mode.

If the agent is not running, context commands open the configured `context.target_view`. The default
target reuses an open panel when one exists, otherwise it opens a float.

## Common Commands

- `:AgentTermToggle`: open or hide the default floating view.
- `:AgentTermPanelToggle`: open or hide the panel view.
- `:AgentTermClose`: close agent windows while keeping the process alive.
- `:AgentTermKill`: stop the process, close windows, delete the terminal buffer, and clear state.
- `:AgentTermSendBufferContext`: send lightweight metadata for the current buffer.
- `:AgentTermSendSelectionContext`: send lightweight metadata for the selected range.
- `:AgentTermSendDiagnosticsContext`: send compact diagnostics for the current buffer.
- `:AgentTermResume`, `:AgentTermResumeAll`, `:AgentTermResumeLast`: registered only when the
  configured backend supports that resume capability.

Float-specific commands are also available as `:AgentTermFloatOpen`, `:AgentTermFloatClose`,
`:AgentTermFloatToggle`, and `:AgentTermFloatFocus`. Panel-specific commands use the same pattern
with `Panel`.

## Troubleshooting

- `Agent command not found`: check `:echo executable('your-agent-command')` or configure
  `agent.cmd`.
- No selection context: reselect text or run `:'<,'>AgentTermSendSelectionContext`.
- Resume command missing: the preset or custom config does not support that resume capability.
- Resume refused: a session is already running; run `:AgentTermKill` first.
- Context appears in the terminal: the backend is using paste mode, or hook delivery was not
  acknowledged.

## Advanced Docs

- [Backend presets](docs/backends.md): exact preset commands, resume capabilities, context modes,
  and backend caveats.
- [Contribution guide](CONTRIBUTING.md): development setup, project layout, backend-change
  expectations, testing commands, coverage notes, and PR guidance.
