Output docs/assets/context-retrieval-demo.gif

Set Shell "zsh"

Set Theme { "name": "Tomorrow Night Framed", "black": "#000000", "red": "#cc6666", "green": "#b5bd68", "yellow": "#f0c674", "blue": "#81a2be", "magenta": "#b294bb", "cyan": "#8abeb7", "white": "#c5c8c6", "brightBlack": "#666666", "brightRed": "#d54e53", "brightGreen": "#b9ca4a", "brightYellow": "#e7c547", "brightBlue": "#7aa6da", "brightMagenta": "#c397d8", "brightCyan": "#70c0b1", "brightWhite": "#eaeaea", "background": "#34363c", "foreground": "#c5c8c6", "selection": "#51545c", "cursor": "#c5c8c6" }
Set WindowBar ColorfulRight
Set WindowBarSize 16

Set FontFamily "MesloLGS Nerd Font"
Set FontSize 12

Set Width 1600
Set Height 900
Set BorderRadius 9
Set Padding 0

Set Framerate 15
Set PlaybackSpeed 1.5
Set TypingSpeed 5ms
Set CursorBlink false

Hide
Type "rm -rf /tmp/agent-term-nvim-vhs-context-demo && mkdir -p /tmp/agent-term-nvim-vhs-context-demo"
Enter
Type "cd /tmp/agent-term-nvim-vhs-context-demo"
Enter
Type `printf '%s\n' 'local function greet(name)' '  return "Hello, " .. (name or "stranger")' 'end' '' 'print(greet("Agent Term"))' > demo.lua`
Enter
Type `printf '%s\n' '{"workspace":{"ignoreDir":["**"],"checkThirdParty":false}}' > .luarc.json`
Enter
Sleep 2s

# Pre-accept agy trust prompt for this disposable demo directory.
Type "agy"
Enter
Sleep 9s
Enter
Sleep 5s
Type@90ms "/quit"
Enter
Sleep 500ms

Type@90ms "nvim -u ~/.config/nvim/init.lua"
Enter
Sleep 2s
 
Type@90ms ":AgentTermSwitch agy"
Enter
Sleep 3s
Show

# agy supports native hook-context integration in this demo setup.
Type@45ms ":AgentTermInstallHooks"
Enter
Sleep 3s

# Start agent window to start tracking context.
Hide
Type@45ms ":AgentTermFloatOpen"
Enter
Sleep 5s
Type "/clear"
Enter
Sleep 1s
Ctrl+\
Ctrl+n
Sleep 1s
Type@45ms ":AgentTermFloatClose"
Enter
Sleep 2s
Show

# Open a real editor buffer. Send context updates from the current session.
Type@45ms ":edit demo.lua"
Enter
Sleep 1s
Type@45ms ":AgentTermFloatOpen"
Enter
Sleep 1s
Hide
Sleep 4s
Show
Sleep 1s

Type@80ms "What editor context have you received? Mention the active file name and summarize the visible buffer if present. Do not edit files."
Enter
Sleep 1s
Hide
Sleep 20s
Show
Sleep 5s

Type "/clear"
Enter
Sleep 1s
Ctrl+\
Ctrl+n
Sleep 1s
Type@45ms ":AgentTermFloatClose"
Enter
Sleep 700ms

# Close the editor buffer. This should clear active editor context.
Type@90ms ":bd!"
Enter
Sleep 1.5s

Type@45ms ":AgentTermFloatOpen"
Enter
Sleep 2s

Type@80ms "Do you currently have any editor context? If the active file context is empty, say that plainly. Do not edit files."
Enter
Sleep 1s
Hide
Sleep 20s
Show
Sleep 5s

Type "/clear"
Enter
Sleep 1s
Ctrl+\
Ctrl+n
Sleep 1s

# Reopen the buffer, then select a subset of text. This should update buffer/selection context.
Type@45ms ":AgentTermFloatClose"
Enter
Sleep 700ms

Type@90ms ":edit demo.lua"
Enter
Sleep 1s

Type@90ms "ggVj"
Sleep 1s
Escape
Sleep 1.5s

Type@90ms ":AgentTermFloatOpen"
Enter
Sleep 2s

Type@80ms "What editor context can you see now? Include the active file and any selected text or selection range if provided. Do not edit files."
Enter
Sleep 1s
Hide
Sleep 20s
Show
Sleep 5s

Escape
Ctrl+\
Ctrl+n
Sleep 1s

Type@45ms ":AgentTermClose"
Enter
Sleep 800ms

Type@90ms ":qa!"
Enter
Sleep 500ms
