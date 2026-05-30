# Repository Guidelines

## Project Structure & Module Organization

- Core plugin code lives in `lua/agent_term/`.
- Entry point: `lua/agent_term/init.lua`.
- Functional areas are split by concern:
  - `lua/agent_term/runtime/`: terminal session lifecycle and shared state.
  - `lua/agent_term/ui/`: float and panel window behavior.
  - `lua/agent_term/context/`: ambient editor context and diagnostics formatting.
  - `lua/agent_term/setup/`: config defaults, schema checks, and keymap validation.
- Tests live under `tests/`:
  - `tests/spec/`: Plenary/Busted specs.
  - `tests/helpers/`: test utilities.
- Docs/media: `README.md`, `docs/`, `assets/`.

## Build, Test, and Development Commands

- `./run_tests.sh`: run the full headless Neovim test suite.
- `PLENARY_PATH=/path/to/plenary.nvim ./run_tests.sh`: run tests when Plenary is outside standard runtime paths.
- `stylua --check lua tests`: formatting check.
- `luacheck lua tests`: lint Lua source and specs.
- Optional direct test invocation:
  - `nvim --headless -u tests/minimal_init.lua -i NONE -c "PlenaryBustedDirectory tests/spec { minimal_init = 'tests/minimal_init.lua' }" -c "qa"`

## Coding Style & Naming Conventions

- Language: Lua (Neovim API).
- Formatting is defined by `.stylua.toml`:
  - tabs, width 2, max column 100, Unix line endings.
- Linting is defined by `.luacheckrc`.
- Module/file names use lowercase and grouped paths (example: `runtime/session.lua`).
- Use `agent`, `backend`, `session`, or `terminal` naming for new code; keep `codex` only when referring to the default backend command.
- Prefer clear, small modules with explicit `require(...)` boundaries.

## Testing Guidelines

- Framework: Plenary test harness with Busted-style specs.
- Add new tests in `tests/spec/*_spec.lua`.
- Keep test descriptions behavior-oriented (`Given/When/Then` style is preferred).
- Cover both happy paths and state/error transitions (for example, missing executable, stale windows, invalid config keys).

## Commit & Pull Request Guidelines

- Follow Angular-style conventional commits seen in history:
  - `feat(config): ...`, `refactor(lua): ...`, `test(nvim): ...`, `docs(readme): ...`, `chore(lua): ...`.
- Keep commits atomic and scoped to one logical change.
- PRs should include:
  - concise summary,
  - rationale and behavior impact,
  - test evidence (command + result),
  - screenshots/gifs for UI-visible changes (float/panel behavior).
