Output docs/assets/context-retrieval-demo.gif

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
Type "rm -rf /tmp/agent-term-nvim-vhs-context-demo && mkdir -p /tmp/agent-term-nvim-vhs-context-demo"
Enter
Type "cd /tmp/agent-term-nvim-vhs-context-demo"
Enter
Type `printf '%s\n' 'local function greet(name)' '  return "Hello, " .. (name or "stranger")' 'end' '' 'print(greet("Agent Term"))' > demo.lua`
Enter
Sleep 2s

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
Type `  agent = "gemini",`
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

Type@90ms "nvim -u init.lua"
Enter
Sleep 2s

# Install Gemini hooks first so context updates are automatic.
Type@90ms ":AgentTermInstallHooks"
Enter
Sleep 3s

# Start agent window to start tracking context.
Hide
Type ":AgentTermPanelOpen"
Enter
Sleep 5s
Escape
Sleep 1s
Type ":AgentTermPanelClose"
Enter
Sleep 2s
Show

# Open a real editor buffer. The hook should publish the active file context.
Type@90ms ":edit demo.lua"
Enter
Sleep 1s

Type@90ms ":AgentTermPanelOpen"
Enter
Sleep 1s
Hide
Sleep 4s
Show

Type@110ms "What editor context have you received? Mention the active file name and summarize the visible buffer if present. Do not edit files."
Enter
Sleep 1s
Hide
Sleep 15s
Show
Sleep 5s

Escape
Sleep 700ms

# Close the editor buffer. The hook should clear active editor context.
Type@90ms ":bd!"
Enter
Sleep 1.5s

Type@90ms ":AgentTermPanelOpen"
Enter
Sleep 1s
Hide
Sleep 4s
Show
Sleep 1s

Type@110ms "Do you currently have any editor context? If the active file context is empty, say that plainly. Do not edit files."
Enter
Sleep 1s
Hide
Sleep 15s
Show
Sleep 5s

Escape
Sleep 700ms

# Reopen the buffer, then select a subset of text. The hook should publish buffer + selection context.
Type@90ms ":AgentTermPanelClose"
Enter
Sleep 700ms

Type@90ms ":edit demo.lua"
Enter
Sleep 1s

Type@90ms "ggVj"
Sleep 1s
Escape
Sleep 1.5s

Type@90ms ":AgentTermPanelOpen"
Enter
Sleep 2s

Type@110ms "What editor context can you see now? Include the active file and any selected text or selection range if provided. Do not edit files."
Enter
Sleep 1s
Hide
Sleep 15s
Show
Sleep 5s

Escape
Sleep 700ms

Type@90ms ":AgentTermClose"
Enter
Sleep 800ms

Type@90ms ":qa!"
Enter
Sleep 500ms
