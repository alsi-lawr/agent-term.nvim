# Repository Guidelines

## Project Direction

- Prefer clean, direct design with explicit module boundaries. Add compatibility layers only when
  there is a concrete supported-compatibility requirement.
- Keep the plugin agent-neutral. Use `agent`, `session`, `terminal`, or capability-oriented names
  for new code.
- Use `codex` only for the Codex preset/default command, demo material, or user-facing examples
  that explicitly refer to Codex.
- Do not add root-level shim modules in `lua/agent_term/` just to re-export deeper modules. Require
  the real module path directly.
- Favor clear module boundaries over broad compatibility surfaces. If an API is internal, keep it
  internal and update call sites when it moves.

## Project Structure

- Core plugin code lives in `lua/agent_term/`.
- Entry point: `lua/agent_term/init.lua`.
- Functional areas are split by concern:
  - `lua/agent_term/runtime/`: terminal session lifecycle, resume behavior, and shared state.
  - `lua/agent_term/ui/`: float, panel, and view-controller behavior.
  - `lua/agent_term/context/`: editor context capture, message building, hook submission, and
    diagnostics formatting.
  - `lua/agent_term/setup/`: defaults, preset expansion, schema helpers, commands, and keymaps.
- Tests live under `tests/`:
  - `tests/spec/`: Plenary/Busted specs.
  - `tests/helpers/`: test utilities.
- Docs/media live in `README.md`, `docs/`, and `assets/`.

## Agent And Context Semantics

- Agent behavior should be expressed as capabilities on `agent`, not as hard-coded agent names.
- Presets may provide defaults, but explicit user config should override preset behavior.
- Context submission supports agent modes:
  - `paste`: send context visibly to the running terminal job.
  - `hook`: emit the configured `User` autocmd hook and fall back to paste if no receiver handles it.
- Hook mode is agent-driven, not view-driven. It must work from panel mode, float mode, and source
  windows while a panel exists.
- Do not infer hook context support from an agent having hooks generally. For example, Copilot and
  Opencode use paste mode because their hooks are not compatible with this context-injection path.
- Panel focus only affects which editor context is used. When the panel is focused, use the last
  captured source context instead of reading context from the terminal buffer.

## Config And Validation

- Validate unknown config keys and unknown keymap names where the existing setup helpers already do
  so.
- Do not try to manually guard every invalid Lua shape. It is acceptable for clearly invalid config
  types to bubble up as errors instead of building defensive validation around everything.
- Keep default config, preset expansion, and resume capability gating centralized in
  `lua/agent_term/setup/`.
- Keymaps are user-facing config. Preserve `false`/`nil` as disable semantics where supported.

## Coding Style

- Language: Lua using Neovim APIs.
- Formatting is defined by `.stylua.toml`:
  - tabs, width 2, max column 100, Unix line endings.
- Linting is defined by `.luacheckrc`.
- Module/file names use lowercase grouped paths, for example `runtime/session.lua`.
- Prefer small modules with explicit `require(...)` boundaries.
- Avoid compatibility wrappers, alias modules, and speculative abstractions.
- Keep comments sparse and useful. Add them only where the code's intent is not obvious from names
  and structure.

## Testing Guidelines

- Framework: Plenary test harness with Busted-style specs.
- Add new tests in `tests/spec/*_spec.lua`.
- Keep test descriptions behavior-oriented; `Given/When/Then` style is preferred.
- Cover happy paths and meaningful state/error transitions, especially:
  - missing executables or failed jobs,
  - stale windows and closed buffers,
  - preset/config behavior,
  - context capture from panel versus source windows,
  - hook mode fallback and acknowledgement behavior.
- For behavior changes, add focused regression tests near the module's existing spec coverage.

## Build, Test, And Development Commands

- `./run_tests.sh`: run the full headless Neovim test suite.
- `PLENARY_PATH=/path/to/plenary.nvim ./run_tests.sh`: run tests when Plenary is outside standard
  runtime paths.
- `stylua --check lua tests`: formatting check.
- `luacheck lua tests`: lint Lua source and specs.
- Optional direct test invocation:
  - `nvim --headless -u tests/minimal_init.lua -i NONE -c "PlenaryBustedDirectory tests/spec { minimal_init = 'tests/minimal_init.lua' }" -c "qa"`

## Commit And Pull Request Guidelines

- Follow Angular-style conventional commits seen in history:
  - `feat(config): ...`, `refactor(lua): ...`, `test(nvim): ...`, `docs(readme): ...`,
    `chore(lua): ...`.
- Keep commits atomic and scoped to one logical change.
- PRs should include:
  - concise summary,
  - rationale and behavior impact,
  - test evidence with command and result,
  - screenshots/gifs for UI-visible float or panel changes.
