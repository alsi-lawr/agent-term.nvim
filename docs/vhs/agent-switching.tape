Output docs/assets/agent-switching-demo.gif

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
Type `export AGENT_TERM_NVIM_REPO="$PWD"`
Enter
Type "rm -rf /tmp/agent-term-nvim-vhs-switch-demo && mkdir -p /tmp/agent-term-nvim-vhs-switch-demo"
Enter
Type "cd /tmp/agent-term-nvim-vhs-switch-demo"
Enter
Type `printf '%s\n' '# agent switching demo' '' 'This file is only here to make the editor state visible.' > README.md`
Enter
Type `printf '%s\n' '{"workspace":{"ignoreDir":["**"],"checkThirdParty":false}}' > .luarc.json`
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
Type@90ms ":AgentTermSwitch codex"
Enter
Sleep 4s
Show

Type@90ms ":AgentTermFloatOpen"
Enter
Sleep 4s
Ctrl+\
Ctrl+n
Sleep 1s

Type@90ms ":AgentTermSwitch"
Enter
Sleep 1.2s

Type@90ms ":AgentTermSwitch agy"
Enter
Sleep 4s
Ctrl+\
Ctrl+n
Sleep 1s

Type@90ms ":AgentTermSwitch"
Enter
Sleep 1.2s

Type@90ms ":AgentTermSwitch codex"
Enter
Sleep 4s
Ctrl+\
Ctrl+n
Sleep 1s

Type@90ms ":AgentTermSwitch"
Enter
Sleep 1.2s

Type@90ms ":AgentTermClose"
Enter
Sleep 800ms

Type@90ms ":qa!"
Enter
Sleep 500ms
