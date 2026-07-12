Output docs/assets/demo.gif

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
Type "clear"
Enter

Type "rm -rf /tmp/agent-term-nvim-vhs-demo && mkdir -p /tmp/agent-term-nvim-vhs-demo"
Enter
Type "cd /tmp/agent-term-nvim-vhs-demo"
Enter
Type `printf '%s\n' 'local function greet(name)' '  return "Hello, " .. (name or "stranger")' 'end' '' 'print(greet("Agent Term"))' > demo.lua`
Enter
Type `printf '%s\n' '{"workspace":{"ignoreDir":["**"],"checkThirdParty":false}}' > .luarc.json`
Enter
# Pre-accept agy trust prompt for this disposable demo directory.
Type "agy"
Enter
Sleep 9s
Enter
Sleep 5s
Type@90ms "/quit"
Enter
Sleep 500ms

Type "clear"
Enter
Sleep 2s

Type@90ms "nvim -u ~/.config/nvim/init.lua demo.lua"
Enter
Sleep 8s
Show

Type@90ms ":AgentTermSwitch agy"
Enter
Sleep 2s

Type@90ms ":AgentTermFloatOpen"
Enter
Sleep 4s

Type@80ms "Briefly explain what this project does. Do not edit files."
Enter
Sleep 1s
Hide
Sleep 5s
Show
Sleep 5s

Ctrl+\
Ctrl+n
Sleep 1s

Type@90ms ":AgentTermFloatClose"
Enter
Sleep 1s

Type@90ms ":AgentTermPanelOpen"
Enter
Sleep 3s

Ctrl+\
Ctrl+n
Sleep 1s

Type@90ms ":AgentTermSendBufferContext"
Enter
Sleep 1.5s

Type@90ms ":AgentTermPanelToggle"
Enter
Sleep 1s

Type@90ms ":AgentTermFloatOpen"
Enter
Sleep 3s

Ctrl+\
Ctrl+n
Sleep 1s

Type@90ms ":AgentTermClose"
Enter
Sleep 800ms

Type@90ms ":qa!"
Enter
Sleep 500ms
