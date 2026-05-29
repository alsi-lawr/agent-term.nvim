# codex.nvim

Neovim integration for the Codex CLI.

`codex.nvim` keeps one persistent Codex terminal session alive and lets you view it as either a centered float or a left, right, or bottom panel. Float and panel are mutually exclusive views over the same terminal buffer, so switching layouts does not start a second Codex process.

## Requirements

- Neovim 0.12+
- Codex CLI installed, authenticated, and available in `PATH`

## Install

With lazy.nvim:

```lua
{
  "alsi-lawr/codex.nvim",
  keys = {
    { "<leader>co", "<cmd>CodexFloatToggle<cr>", desc = "Codex float" },
    { "<leader>cp", "<cmd>CodexPanelToggle<cr>", desc = "Codex panel" },
    { "<leader>cX", "<cmd>CodexClose<cr>", desc = "Codex close" },
    { "<leader>ck", "<cmd>CodexKill<cr>", desc = "Codex kill" },
    { "<leader>cb", "<cmd>CodexSendBufferContext<cr>", desc = "Codex buffer context" },
    { "<leader>cs", "<cmd>CodexSendSelectionContext<cr>", mode = { "n", "x" }, desc = "Codex selection context" },
  },
  opts = {},
}
```

Keymaps are optional. The example above shows suggested lazy.nvim mappings; remove or change any of them to fit your config.

For eager loading, use plugin-managed keymaps:

```lua
require("codex").setup({
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

## Configuration

Defaults:

```lua
require("codex").setup({
  codex = {
    cmd = { "codex" },
    resume = { "codex", "resume" },
    resume_all = { "codex", "resume", "--all" },
    resume_last = { "codex", "resume", "--last" },
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

The lazy.nvim `keys` field belongs to lazy.nvim and controls lazy-loading mappings. The plugin `keymaps` option controls mappings created by `require("codex").setup()`. By default, plugin-managed mappings are disabled.

To let the plugin create mappings instead:

```lua
require("codex").setup({
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

## How It Works

`codex.nvim` manages one Codex terminal job by default. Opening a float or panel creates a view onto the same terminal buffer and closes the other view. Repeated open and toggle calls reuse the existing session.

If the Codex process exits, stale job, buffer, and window state is cleared. If a resume command is run while Codex is already running, the plugin asks you to run `:CodexKill` first.

## Context

Context commands send lightweight editor metadata with `nvim_chan_send`. They do not send full buffer contents.

- Buffer context sends file path, filetype, cursor, and visible range.
- Selection context sends file path, filetype, and selected line range.
- Diagnostics context sends compact diagnostics for the current buffer.

Injected context is explicitly marked as ambient editor state. Codex is told to use it only when relevant to the user's next prompt.

If Codex is not running, `context.target_view` controls where it opens. `"default"` reuses an open panel if one exists, otherwise it opens a float.

## Lua API

```lua
local codex = require("codex")

codex.setup(opts)

codex.float_open()
codex.float_close()
codex.float_toggle()
codex.float_focus()

codex.panel_open()
codex.panel_close()
codex.panel_toggle()
codex.panel_focus()

codex.close()
codex.kill()

codex.send_buffer_context()
codex.send_selection_context()
codex.send_diagnostics_context()

codex.resume()
codex.resume_all()
codex.resume_last()
```

## Troubleshooting

- `Codex command not found`: check `:echo executable('codex')` or configure `codex.cmd`.
- No selection context: reselect text or run `:'<,'>CodexSendSelectionContext`.
- Resume refused: a Codex session is already running; run `:CodexKill` first.

## Command Reference

Float commands:

- `:CodexFloatOpen` opens or focuses the floating Codex view.
- `:CodexFloatClose` closes only the floating view.
- `:CodexFloatToggle` opens the float if closed, otherwise closes it.
- `:CodexFloatFocus` focuses the float, opening it first if needed.

Panel commands:

- `:CodexPanelOpen` opens or focuses the configured panel view.
- `:CodexPanelClose` closes only the panel view.
- `:CodexPanelToggle` opens the panel if closed, otherwise closes it.
- `:CodexPanelFocus` focuses the panel, opening it first if needed.

Session commands:

- `:CodexClose` closes all Codex windows while keeping the Codex process alive.
- `:CodexKill` stops the Codex process, closes all Codex windows, deletes the terminal buffer, and clears state.

Context commands:

- `:CodexSendBufferContext` sends lightweight metadata for the current buffer.
- `:CodexSendSelectionContext` sends lightweight metadata for the selected line range. It supports visual ranges, for example `:'<,'>CodexSendSelectionContext`.
- `:CodexSendDiagnosticsContext` sends diagnostics for the current buffer. If there are no diagnostics, it sends nothing.

Resume commands:

- `:CodexResume` starts `codex resume`.
- `:CodexResumeAll` starts `codex resume --all`.
- `:CodexResumeLast` starts `codex resume --last`.
