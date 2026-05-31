Output docs/assets/demo.gif

Set Shell "bash"
Set FontSize 14
Set Width 1200
Set Height 720
Set Padding 20
Set Framerate 10 
Set PlaybackSpeed 1.0
Set TypingSpeed 5ms
Set Theme "Catppuccin Mocha"

Hide
Type "clear"
Enter

Type `export AGENT_TERM_NVIM_REPO="$PWD"`
Enter
Type "rm -rf /tmp/agent-term-nvim-vhs-demo && mkdir -p /tmp/agent-term-nvim-vhs-demo"
Enter
Type "cd /tmp/agent-term-nvim-vhs-demo"
Enter
Type `printf '%s\n' 'local function greet(name)' '  return "Hello, " .. (name or "stranger")' 'end' '' 'print(greet("Agent Term"))' > demo.lua`
Enter
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
Type@90ms "/quit"
Enter
Sleep 1.5s

Type "clear"
Enter
Sleep 1.5s
Show

Type@90ms "nvim -u init.lua demo.lua"
Enter
Sleep 2s

Type@90ms ":AgentTermFloatOpen"
Enter
Sleep 4s

Type@110ms "Briefly explain what this project does. Do not edit files."
Enter
Sleep 1s
Hide
Sleep 5s
Show
Sleep 5s

Escape
Sleep 700ms

Type@90ms ":AgentTermFloatClose"
Enter
Sleep 1s

Type@90ms ":AgentTermPanelOpen"
Enter
Sleep 3s

Escape
Sleep 700ms

Type@90ms ":AgentTermSendBufferContext"
Enter
Sleep 1.5s

Type@90ms ":AgentTermPanelToggle"
Enter
Sleep 1s

Type@90ms ":AgentTermFloatOpen"
Enter
Sleep 3s

Escape
Sleep 700ms

Type@90ms ":AgentTermClose"
Enter
Sleep 800ms

Type@90ms ":qa!"
Enter
Sleep 500ms
