Output docs/assets/agent-switching-demo.gif

Set Shell "bash"
Set FontSize 14
Set Width 1200
Set Height 720
Set Padding 20
Set Framerate 15
Set PlaybackSpeed 1.0
Set TypingSpeed 5ms
Set Theme "Catppuccin Mocha"

Hide
Type `export AGENT_TERM_NVIM_REPO="$PWD"`
Enter
Type "rm -rf /tmp/agent-term-nvim-vhs-switch-demo && mkdir -p /tmp/agent-term-nvim-vhs-switch-demo"
Enter
Type "cd /tmp/agent-term-nvim-vhs-switch-demo"
Enter
Type `printf '%s\n' '# agent switching demo' '' 'This file is only here to make the editor state visible.' > README.md`
Enter
Sleep 1s

# Pre-accept Codex trust prompt for this disposable demo directory.
Type `codex --model gpt-5.4-mini -c 'model_reasoning_effort="low"'`
Enter
Sleep 3s
Type "y"
Enter
Sleep 1.5s
Type@90ms "/quit"
Enter
Sleep 1.5s

# Pre-accept Gemini trust prompt for this disposable demo directory.
Type "gemini"
Enter
Sleep 9s
Enter
Sleep 5s
Type@90ms "/quit"
Enter
Sleep 500ms

# Setup neovim for the demo.
Type "cat > init.lua <<'EOF'"
Enter
Type `vim.opt.runtimepath:prepend(os.getenv("AGENT_TERM_NVIM_REPO"))`
Enter
Type `require("agent_term").setup({`
Enter
Type `  agents = {`
Enter
Type `    codex = {`
Enter
Type `      cmd = { "codex", "--model", "gpt-5.4-mini", "-c", [[model_reasoning_effort="low"]] },`
Enter
Type `    },`
Enter
Type `    gemini = { preset = "gemini" },`
Enter
Type `  },`
Enter
Type `})`
Enter
Type `vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { silent = true })`
Enter
Type "EOF"
Enter
Type "clear"
Enter
Sleep 2s
Show

Type@90ms "nvim -u init.lua README.md"
Enter
Sleep 2s

Type@90ms ":AgentTermPanelOpen"
Enter
Sleep 4s
Escape
Sleep 700ms

Type@90ms ":AgentTermSwitch"
Enter
Sleep 1.2s

Type@90ms ":AgentTermSwitch gemini"
Enter
Sleep 4s
Escape
Sleep 700ms

Type@90ms ":AgentTermSwitch"
Enter
Sleep 1.2s

Type@90ms ":AgentTermSwitch codex"
Enter
Sleep 4s
Escape
Sleep 700ms

Type@90ms ":AgentTermSwitch"
Enter
Sleep 1.2s

Type@90ms ":AgentTermClose"
Enter
Sleep 800ms

Type@90ms ":qa!"
Enter
Sleep 500ms
