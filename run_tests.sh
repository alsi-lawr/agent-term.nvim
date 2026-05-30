#!/usr/bin/env bash
set -euo pipefail

NVIM_BIN="${NVIM_BIN:-nvim}"
MINIMAL_INIT="${MINIMAL_INIT:-tests/minimal_init.lua}"
SPEC_DIR="${SPEC_DIR:-tests/spec}"

"$NVIM_BIN" --headless -u "$MINIMAL_INIT" -i NONE \
  -c "PlenaryBustedDirectory $SPEC_DIR { minimal_init = '$MINIMAL_INIT' }" \
  -c "qa"
