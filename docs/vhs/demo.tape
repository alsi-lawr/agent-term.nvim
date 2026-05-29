Output assets/demo.gif

Set Shell "bash"
Set FontSize 14
Set Width 1200
Set Height 720
Set Padding 20
Set Framerate 30
Set PlaybackSpeed 1.0
Set TypingSpeed 75ms
Set Theme "Catppuccin Mocha"

Hide
Type "clear"
Enter

Type `export CODEX_NVIM_REPO="$PWD"`
Enter
Type "rm -rf /tmp/codex-nvim-vhs-demo && mkdir -p /tmp/codex-nvim-vhs-demo"
Enter
Type "cd /tmp/codex-nvim-vhs-demo"
Enter
Type `printf '%s\n' 'local function greet(name)' '  return "Hello, " .. (name or "stranger")' 'end' '' 'print(greet("Codex"))' > demo.lua`
Enter
Type "cat > init.lua <<'EOF'"
Enter
Type `vim.opt.runtimepath:prepend(os.getenv("CODEX_NVIM_REPO"))`
Enter
Type `require("codex").setup({`
Enter
Type `  codex = {`
Enter
Type `    cmd = { "codex", "--model", "gpt-5.4-mini", "-c", [[model_reasoning_effort="low"]] },`
Enter
Type `  },`
Enter
Type `})`
Enter
Type `vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { silent = true })`
Enter
Type "EOF"
Enter

# Pre-accept Codex trust prompt for this disposable demo directory.
Type `codex --model gpt-5.4-mini -c 'model_reasoning_effort=\"low\"'`
Enter
Sleep 3s
Type "y"
Enter
Sleep 1.5s
Type "/quit"
Enter
Sleep 1.5s

Type "clear"
Enter
Sleep 1.5s
Show

Type@90ms "nvim -u init.lua demo.lua"
Enter
Sleep 2s

Type@90ms ":CodexFloatOpen"
Enter
Sleep 4s

Type@110ms "Briefly explain what this Lua file does. Do not edit files."
Enter
Sleep 8s

Escape
Sleep 700ms

Type@90ms ":CodexFloatClose"
Enter
Sleep 1s

Type@90ms ":CodexPanelOpen"
Enter
Sleep 3s

Escape
Sleep 700ms

Type@90ms ":CodexSendBufferContext"
Enter
Sleep 1.5s

Type@90ms ":CodexPanelToggle"
Enter
Sleep 1s

Type@90ms ":CodexFloatOpen"
Enter
Sleep 3s

Escape
Sleep 700ms

Type@90ms ":CodexClose"
Enter
Sleep 800ms

Type@90ms ":qa!"
Enter
Sleep 500ms
