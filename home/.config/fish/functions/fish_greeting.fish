# Runs after config.fish. Reset colors to kitty.conf's blue/purple palette
# (config.fish replays end-4's old terminal colors), then show fastfetch
function fish_greeting
    if test "$TERM" = "xterm-kitty"
        printf '\e]104\a\e]110\a\e]111\a\e]112\a\e]117\a\e]119\a'
    end
    ~/.config/fastfetch/fetch.sh
end
