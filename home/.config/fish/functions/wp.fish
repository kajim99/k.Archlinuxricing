# Hyprland workspaces from the terminal (2026-11-03).
#   wp 9     go to workspace 9
#   wp -9    make 9 new workspaces after the last one (they stay even when empty)
#   wp --3   remove the last 3 workspaces, highest first, closing their apps (asks first; 1 always stays)
#   wp       list workspaces and the apps on each
#   wp -h    this section of the `tools` cheat sheet
# Extra workspaces last until Hyprland restarts (logout/reboot/shutdown), then it's back to the base 5.
# The count is kept in this session's runtime folder; custom/rules.lua re-applies it on config reload.
# Colors follow the theme: violet #8703ff/#a020ff, neon blue #0059e7.

function __wp_state
    echo $XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/wp-count
end

# Number of workspaces right now: the saved count (base 5) or the highest in use, if higher
function __wp_count
    set -l saved (cat (__wp_state) 2>/dev/null; or echo 5)
    hyprctl workspaces -j | jq --argjson c $saved '[.[].id | select(. > 0)] + [$c] | max'
end

function wp --description 'Hyprland workspaces: wp N go, wp -N make N, wp --N remove last N, wp -h help'
    set -l arg $argv[1]

    # wp -h / --help
    if contains -- "$arg" -h --help
        tools wp
        return
    end

    # wp: list
    if test -z "$arg"
        set -l active (hyprctl activeworkspace -j | jq -r '.id')
        set -l clients (hyprctl clients -j)
        echo
        for ws in (seq 1 (__wp_count))
            set -l apps (echo $clients | jq -r --argjson w $ws '[.[] | select(.workspace.id == $w) | .class] | unique | join(", ")')
            if test "$ws" = "$active"
                set_color --bold a020ff; printf '  ▶ %-4s' $ws
            else
                set_color --bold 0059e7; printf '    %-4s' $ws
            end
            set_color e0dcff; echo (test -n "$apps"; and echo $apps; or echo '(empty)')
        end
        set_color 4a3a6a; echo '  wp -h for help'; set_color normal
        echo
        return
    end

    # wp --N: remove the last N
    if set -l m (string match -r '^--([1-9][0-9]*)$' -- $arg)
        set -l count (__wp_count)
        set -l keep (math "max(1, $count - $m[2])")
        if test $keep -eq $count
            echo "Only workspace 1 is left, and it always stays."
            return 1
        end
        set -l doomed (seq $count -1 (math $keep + 1))
        set -l wins (hyprctl clients -j | jq -c --argjson k $keep '[.[] | select(.workspace.id > $k) | {address, class, title, ws: .workspace.id}] | sort_by(-.ws) | .[]')

        if set -q wins[1]
            set_color --bold a020ff; echo "Removing workspaces "(string join ' ' $doomed)" will close:"; set_color normal
            for w in $wins
                set_color --bold 0059e7; printf '    %-4s' (echo $w | jq -r .ws)
                set_color e0dcff; echo (echo $w | jq -r '.class + "  —  " + .title' | string shorten -m 70)
            end
            set_color normal
            read -l -P 'Close them? [Y/n] ' answer
            if not string match -qi -r '^(y|yes|)$' -- $answer
                echo 'Cancelled, nothing changed.'
                return 1
            end
            for w in $wins
                hyprctl dispatch "hl.dsp.window.close({ window = \"address:"(echo $w | jq -r .address)"\" })" >/dev/null
            end
        end

        # Leave a removed workspace before it goes away
        if test (hyprctl activeworkspace -j | jq -r '.id') -gt $keep
            hyprctl dispatch "hl.dsp.focus({ workspace = $keep })" >/dev/null
        end
        for ws in $doomed
            hyprctl eval "hl.workspace_rule({ workspace = \"$ws\", persistent = false })" >/dev/null
        end
        echo $keep > (__wp_state)

        set_color --bold a020ff; echo "Removed "(string join ', ' $doomed)". Workspaces now: 1–$keep"; set_color normal
        # Apps that asked to save (or refused to close) are still open: say where
        sleep 1
        set -l left (hyprctl clients -j | jq -r --argjson k $keep '.[] | select(.workspace.id > $k) | "    " + (.workspace.id|tostring) + "  " + .class')
        if set -q left[1]
            set_color 0059e7; echo 'Still open (maybe asking to save):'; set_color e0dcff; printf '%s\n' $left; set_color normal
        end
        return
    end

    # wp -N: make N new ones after the last
    if set -l m (string match -r '^-([1-9][0-9]*)$' -- $arg)
        set -l count (__wp_count)
        set -l last (math $count + $m[2])
        for ws in (seq (math $count + 1) $last)
            hyprctl eval "hl.workspace_rule({ workspace = \"$ws\", persistent = true })" >/dev/null
        end
        echo $last > (__wp_state)
        set -l made (math $count + 1)
        test $made -ne $last; and set made "$made–$last"
        set_color --bold a020ff; echo "Made $made. Workspaces now: 1–$last"; set_color normal
        return
    end

    # wp N: go there
    if string match -qr '^[1-9][0-9]*$' -- $arg
        hyprctl dispatch "hl.dsp.focus({ workspace = $arg })" >/dev/null
        return
    end

    echo "Unknown: $arg   (wp -h for help)"
    return 1
end
