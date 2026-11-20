# Quick folder jumps and search tools (added 2026-11-03). Type `nav` to list them.
if status is-interactive
    # Folder shortcuts: type the word, press Enter
    abbr -a home 'cd ~'
    abbr -a dl   'cd ~/Downloads'
    abbr -a doc  'cd ~/Documents'
    abbr -a pj   'cd ~/Projects'
    abbr -a cl   'cd ~/Projects/Cloned'
    abbr -a ard  'cd ~/Projects/Arduino'
    abbr -a games 'cd ~/Games'
    abbr -a bk   'cd ~/Backups'
    abbr -a iso  'cd ~/ISOs'
    abbr -a tl   'cd ~/Tools'
    abbr -a vid  'cd ~/Videos'
    abbr -a rec  'cd ~/Videos/Screen-Recordings'
    abbr -a wap  'cd ~/Videos/Wallpapers'
    abbr -a pics 'cd ~/Pictures'
    abbr -a shots 'cd ~/Pictures/Screenshots'
    abbr -a mus  'cd ~/Music'
    abbr -a cfg  'cd ~/.config'
    abbr -a hyp  'cd ~/.config/hypr'
    abbr -a ts   'cd ~/.theme-setup'

    # zoxide: `z name` jumps to a folder you've been in, `zi` picks from a list
    type -q zoxide; and zoxide init fish | source

    # fzf: Ctrl+T finds files, Alt+C jumps to folders, Ctrl+R searches history
    if type -q fzf
        if type -q fd
            set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --exclude .git --exclude .cache'
            set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
            set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --exclude .git --exclude .cache'
        end
        type -q bat; and set -gx FZF_CTRL_T_OPTS "--preview 'bat --color=always --style=plain --line-range :200 {}'"
        set -gx FZF_DEFAULT_OPTS '--color=bg+:#1a0033,hl:#8703ff,hl+:#a020ff,fg+:#ffffff,info:#0059e7,prompt:#8703ff,pointer:#8703ff,marker:#0059e7,spinner:#0059e7,header:#0059e7,border:#8703ff --border=rounded'
        fzf --fish | source
    end

    # yazi: `y` opens it and leaves you in the folder you were in when you quit
    if type -q yazi
        function y
            set tmp (mktemp -t "yazi-cwd.XXXXXX")
            yazi $argv --cwd-file="$tmp"
            if read -z cwd < "$tmp"; and test -n "$cwd"; and test "$cwd" != "$PWD"
                builtin cd -- "$cwd"
            end
            rm -f -- "$tmp"
        end
    end

    function nav --description 'List folder shortcuts'
        for line in (abbr --show | string match "*cd *")
            string replace -r "abbr -a (?:-- )?(\S+) '?cd ([^']*)'?" '  $1\t→ $2' -- $line
        end
        echo
        echo '  z <name>   jump to any visited folder     zi   pick from a list'
        echo '  Ctrl+T     find a file                    Alt+C  jump to a folder'
        echo '  y          yazi file manager              open <file>  open in its app'
    end
end
