# Contributing

Thanks for helping improve agent-term.nvim. This project favors small, focused changes with clear
behavioral intent and tests where the change affects user-visible behavior or shared internals.

## Development Setup

Prerequisites:

- Neovim 0.12+
- [`nvim-lua/plenary.nvim`](https://github.com/nvim-lua/plenary.nvim)
- `stylua`
- `luacheck`
- Any terminal-agent commands needed for manual testing

If Plenary is not installed in a standard runtime path, set `PLENARY_PATH` when running tests.

## Project Layout

- `lua/agent_term/`: plugin source.
- `lua/agent_term/init.lua`: public entry point.
- `lua/agent_term/runtime/`: terminal session lifecycle, resume behavior, and shared state.
- `lua/agent_term/ui/`: float, panel, and view-controller behavior.
- `lua/agent_term/context/`: editor context capture, message building, hook submission, and
  diagnostics formatting.
- `lua/agent_term/setup/`: defaults, preset expansion, schema helpers, commands, and keymaps.
- `tests/spec/`: Plenary/Busted specs.
- `tests/helpers/`: test utilities.
- `docs/`: detailed user and contributor documentation.

## Making Changes

- Keep changes scoped to one logical behavior or documentation update.
- Prefer agent-neutral names such as `agent`, `session`, and `terminal`.
- Keep `codex` naming limited to the Codex preset/default command or examples that explicitly refer
  to Codex.
- Do not add root-level re-export shim modules in `lua/agent_term/`; require the real module path.
- Prefer explicit module boundaries over broad compatibility surfaces.
- Avoid speculative abstractions. Add helpers when they remove real duplication or clarify a shared
  behavior.
- For config, validate the existing supported surfaces, but do not build defensive guards around
  every invalid Lua shape unless there is a concrete user-facing reason.

## Agent Preset Changes

Agent presets are best-effort defaults, not a guarantee of feature parity between tools. When
adding or changing a preset:

- Add or update the preset in `lua/agent_term/setup/config.lua`.
- Add enum and annotation updates when a new preset is user-selectable.
- Document exact commands and caveats in `docs/agents.md`.
- Keep the README summary compact.
- Add config specs for command, context mode, and resume capability behavior.

Do not infer hook context support from an agent having hooks generally. Hook mode is only for
agents that support this context-injection path.

## Testing

Run the full headless Neovim suite:

```sh
./run_tests.sh
```

If Plenary is outside the standard runtime path:

```sh
PLENARY_PATH=/path/to/plenary.nvim ./run_tests.sh
```

Raw Neovim invocation:

```sh
nvim --headless -u tests/minimal_init.lua -i NONE \
  -c "PlenaryBustedDirectory tests/spec { minimal_init = 'tests/minimal_init.lua' }" \
  -c "qa"
```

Formatting and linting:

```sh
stylua --check lua tests
luacheck lua tests
```

Before opening a PR, run:

```sh
stylua --check lua tests
luacheck lua tests
./run_tests.sh
```

## Test Guidelines

- Add tests in `tests/spec/*_spec.lua`.
- Keep descriptions behavior-oriented; `Given/When/Then` style is preferred.
- Cover happy paths and meaningful state/error transitions.
- For UI behavior, cover stale windows, closed buffers, focus changes, and view reuse where relevant.
- For context behavior, cover panel-focused captured context, source-window context, hook
  acknowledgement, and hook fallback where relevant.
- For agent/config behavior, cover presets, custom commands, resume capability gating, and invalid
  supported config values.

This repo uses Plenary because the tests need Neovim-hosted integration coverage for windows,
buffers, diagnostics, terminal jobs, and user commands. `mini.test` is useful for pure-Lua suites,
but it does not simplify these integration cases enough to justify a migration right now.

## Optional Coverage

Keep Neovim-hosted tests as the default path. If pure Lua specs are added separately, coverage can
be run for that subset:

```sh
LUA_INIT='require("luacov")' busted tests/pure
```

## Pull Requests

PRs should include:

- concise summary,
- rationale and behavior impact,
- test evidence with command and result,
- screenshots or gifs for UI-visible float or panel changes.

Use conventional commit style for commits where practical, for example:

- `feat(config): add agent preset`
- `fix(context): preserve source buffer context`
- `test(nvim): cover panel focus behavior`
- `docs(readme): simplify agent summary`
