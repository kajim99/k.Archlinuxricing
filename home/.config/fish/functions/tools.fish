# Placeholders: n° = a number, <name> = your own value.
# Cheat sheet for the terminal tools, folder shortcuts, nano and custom Hyprland keys (2026-11-03).
# Usage: tools [z|fzf|yazi|fd|bat|wp|nav|nano|hypr|cmds|phone|phonebox|fix]   (no argument = everything)
# Colors follow the theme: violet #8703ff/#a020ff headings, neon blue #0059e7 keys.

function __tools_head
    echo
    set_color --bold a020ff; echo "  $argv[1]"; set_color normal
    set_color 8703ff; echo "  "(string repeat -n (string length -- $argv[1]) ─); set_color normal
end

# Print "key  description" pairs: __tools_rows key1 desc1 key2 desc2 ...
function __tools_rows
    for i in (seq 1 2 (count $argv))
        set_color --bold 0059e7; printf '    %-22s ' $argv[$i]
        set_color e0dcff; echo $argv[(math $i + 1)]
    end
    set_color normal
end

function tools --description 'Show useful shortcuts for z, fzf, yazi, fd, bat, folders, nano and Hyprland'
    set -l section (string lower -- $argv[1])
    set -l all (test -z "$section"; and echo 1)

    if set -q all[1]; or contains -- $section z zoxide
        __tools_head 'z  — jump to folders (zoxide)'
        __tools_rows \
            'z <name>'      'jump to the best match of a visited folder' \
            'z <name> <name>' 'several words must all match' \
            'zi'            'pick from a list' \
            'z -'           'go back to the previous folder' \
            'zoxide query'  'show what it remembers'
    end

    if set -q all[1]; or contains -- $section fzf
        __tools_head 'fzf  — fuzzy search'
        __tools_rows \
            'Ctrl+T'        'find a file, pastes its path (try: nano + Ctrl+T)' \
            'Alt+C'         'find a folder and cd into it' \
            'Ctrl+R'        'search command history' \
            '↑ ↓  Enter'    'move / pick       Esc  cancel' \
            'Tab'           'mark several (Ctrl+T)' \
            "'word  ^start  end\$" 'exact / starts with / ends with'
    end

    if set -q all[1]; or contains -- $section yazi y
        __tools_head 'y  — yazi file manager'
        __tools_rows \
            '↑↓ / j k'      'move            ← →  back / open' \
            'Space'         'select           v  select range' \
            'y  x  p'       'copy / cut / paste' \
            'd  /  D'       'trash / delete forever' \
            'r'             'rename' \
            'a'             'new file (end with / for a folder)' \
            '/  n'          'find in folder / next match' \
            's  S'          'search names (fd) / contents (rg)' \
            '.'             'show hidden files' \
            'z'             'jump with zoxide' \
            'o  O'          'open / open with…' \
            't  1-9'        'new tab / switch tab' \
            '~'             'help (all keys)' \
            'q'             'quit and stay in that folder'
    end

    if set -q all[1]; or contains -- $section fd
        __tools_head 'fd  — find files'
        __tools_rows \
            'fd <name>'         'find by name, from here down' \
            'fd -e <ext> <folder>' 'by extension, in a folder' \
            'fd -H <name>'      'include hidden files' \
            'fd -t d <name>'    'folders only' \
            'fd <name> -x <cmd>' 'run a command on each result'
    end

    if set -q all[1]; or contains -- $section bat
        __tools_head 'bat  — view files with colors'
        __tools_rows \
            'bat <file>'        'show with colors + line numbers' \
            'bat -p <file>'     'plain, no numbers' \
            'bat -r n°:n° <file>' 'only lines n° to n°' \
            'q  /'              'quit / search (in the pager)'
    end

    if set -q all[1]; or contains -- $section wp workspaces
        __tools_head 'wp  — Hyprland workspaces'
        __tools_rows \
            'wp n°'             'go to workspace n' \
            'wp -n°'            'make n new workspaces after the last one' \
            'wp --n°'           'remove the last n (highest first), closing their apps — asks first' \
            'wp'                'list workspaces and their apps' \
            'wp -h'             'this help' \
            'Super+scroll'      'step through workspaces, up to the last one' \
            'logout / reboot'   'back to the base 5 (lock screen keeps them)'
    end

    if set -q all[1]; or contains -- $section nav folders
        __tools_head 'Folder shortcuts  (type, then Enter)'
        set -l rows
        for line in (abbr --show | string match '*cd *')
            set -l m (string match -r "abbr -a (?:-- )?(\S+) '?cd ([^']*)'?" -- $line)
            set -q m[3]; and set -a rows $m[2] $m[3]
        end
        __tools_rows $rows
    end

    if set -q all[1]; or contains -- $section nano
        __tools_head 'nano  — text editor'
        __tools_rows \
            'nano <file>'   'open (sudo nano for system files)' \
            'Ctrl+O Enter'  'save' \
            'Ctrl+X'        'exit (Y/N to save)' \
            'Ctrl+W'        'search      Alt+W  next match' \
            'Ctrl+K  Ctrl+U' 'cut line / paste' \
            'Ctrl+_'        'go to line' \
            'Alt+U'         'undo'
    end

    if set -q all[1]; or contains -- $section hypr hyprland keys
        __tools_head 'Hyprland  — your custom keys'
        set -l rows
        for line in (string match -r 'hl\.bind\("[^"]+".*description\s*=\s*"[^"]+"' < ~/.config/hypr/custom/keybinds.lua)
            set -l m (string match -r 'hl\.bind\("([^"]+)".*description\s*=\s*"([^"]+)"' -- $line)
            set -a rows (string replace -a -r '\s*\+\s*' '+' -- $m[2] | string replace -a SUPER Super | string replace -a CTRL Ctrl | string replace -a SHIFT Shift | string replace -a ALT Alt | string replace -a Slash /) $m[3]
        end
        __tools_rows $rows
        __tools_head 'Hyprland  — end-4 basics'
        __tools_rows \
            'Super+Q'           'close window' \
            'Super+Enter'       'terminal (kitty)' \
            'Super+E  Super+W'  'file manager / browser' \
            'Super+Tab'         'overview of all workspaces' \
            'Super+V  Super+.'  'clipboard history / emoji picker' \
            'Super+N'           'right sidebar (Super+A is Arduino now)' \
            'Super+J'           'show / hide the bar' \
            'Super+Alt+Space'   'float / tile window' \
            'Super+L'           'lock screen' \
            'Ctrl+Alt+Delete'   'session menu (logout, reboot…)' \
            'Ctrl+Super+R'      'restart the bar / desktop shell'
        set_color 4a3a6a
        echo '    Super+/ shows all of end-4\'s keys'
        echo '    Fantech keyboard: Super+LEFT Shift+S never arrives — use Super+Shift+Q or Right Shift'
        set_color normal
    end

    if set -q all[1]; or contains -- $section cmds commands
        __tools_head 'Your commands'
        __tools_rows \
            'tools <name>'      'this cheat sheet (one section)' \
            '/H-doctor'         'in a Claude chat: check + update everything, report, fix on OK' \
            'todo add <text>'   'add to the sidebar To Do (todo list / done / toggle n°)' \
            'dotfiles-sync'     'back up configs to ~/dotfiles + push to GitHub (runs daily)' \
            'dotfiles-public-sync' 'rebuild + push the public rice repo (leak-checked)' \
            'autofile'          'sort loose files in ~/Downloads + ~/Desktop now' \
            'cube-rebuild'      'rebuild only the hypr-cube plugin' \
            'claude-focus'      'jump to the terminal running Claude' \
            'media-focus'       'jump to the app that is playing music' \
            'screen-off'        'turn the laptop screen off (wakes on input)' \
            'phonebox-power'    'power off / reboot with a 5 s cancel (PhoneBox buttons)' \
            'phnet-watch'       'service: phone ethernet on when plugged in (systemctl --user restart phnet-watch)' \
            'wp …'              'workspaces (see the wp section)' \
            'power-mode …'      'saver / balanced / max (purple, firmware max) / cycle / get' \
            'roblox-theme'      'violet cursors + icons in Roblox (Sober); restart Roblox after' \
            'roblox-theme off'  'Roblox back to stock look' \
            'plugins-rebuild'   'rebuild hyprbars + hypr-cube after a Hyprland update' \
            'audio-panel'       'sound output switcher (also Super+Ctrl+V)' \
            'move-spotify-lyrics' 'move Liquid Lyrics exports to ~/Music/spotify-lyrics' \
            'arduino-ide'       'Arduino IDE (runs under XWayland so it opens)' \
            'phonebox-restart'  'restart the phone desk panel (see the phonebox section)' \
            'phnet on|off'      'phone USB ethernet + notifications (see the phone section)' \
            'phbx'              'PhoneBox back on on the phone' \
            'qs ipc -c ii call notifications dnd true|false' '' \
            ''                  'Do Not Disturb on / off' \
            'qs ipc -c ii call notifications discard <app> <title>' '' \
            ''                  'remove that notification from the list'
    end

    if set -q all[1]; or contains -- $section phone phnet
        __tools_head 'Phone  — USB ethernet + notifications (TECNO)'
        __tools_rows \
            'phnet on'          'USB ethernet on + phone notifications on the PC' \
            'phnet off'         'phone back to normal USB (notifications stay, over Wi-Fi)' \
            'phnet'             'show what is on' \
            'Auto'              'plugging the phone in turns it on by itself (phnet-watch)' \
            'phnet off'         '...stays off until you unplug the phone' \
            'Internet'          'stays on Wi-Fi; the cable is a private PC-phone link' \
            'Phone USB setting' 'Developer options → Default USB configuration → No data transfer' \
            'adb stuck?'        'toggle USB debugging off and on (after any USB mode change)'
    end

    if set -q all[1]; or contains -- $section phonebox pb
        __tools_head 'PhoneBox  — the phone desk panel'
        __tools_rows \
            'phbx'              'turn PhoneBox back on on the phone (after plugging it in)' \
            'phonebox-restart'  'restart it all + clean adb, then says what to do' \
            'phonebox-widgets'  'rebuild every page after editing a widget' \
            'phonebox-sync clear' 'empty the Inbox page' \
            'Settings page'     'http://127.0.0.1:8765 in the browser' \
            'Not showing?'      'phonebox-restart; if it says so, toggle USB debugging' \
            'Allow prompt'      'tap Allow + tick Always allow on the phone' \
            'Pages'             'tap the dots = All pages, tap one to jump'
    end

    if set -q all[1]; or contains -- $section fix fixes
        __tools_head 'Fix it  — when something breaks'
        __tools_rows \
            'Bar gone'          'Ctrl+Super+R (the watchdog also retries twice by itself)' \
            '"Top bar won\'t load"' 'watchdog gave up: Ctrl+Super+R, still broken → ask Claude' \
            'After Hyprland update' 'log out + back in, then plugins-rebuild' \
            'After Spotify update' 'spicetify apply (theme + extensions come back)' \
            'Spotify add-ons broken' 'Ctrl+R inside Spotify, or Super+Shift+Q then Super+S' \
            'After Roblox update' 'roblox-theme' \
            'App frozen'        'Super+Shift+Alt+Q force-closes the window' \
            'Phone panel blank' 'phonebox-restart'
    end

    if test -n "$section"; and not contains -- $section z zoxide fzf yazi y fd bat wp workspaces nav folders nano hypr hyprland keys cmds commands phone phnet phonebox pb fix fixes
        echo "Unknown section '$section'. Try: tools [z|fzf|yazi|fd|bat|wp|nav|nano|hypr|cmds|phone|phonebox|fix]"
        return 1
    end
    echo
    set_color 4a3a6a; echo '  n° = a number   <name> = your own value'
    set -q all[1]; and echo '  tools <name> shows one section: z fzf yazi fd bat wp nav nano hypr cmds phone phonebox fix'
    set_color normal; echo
end
