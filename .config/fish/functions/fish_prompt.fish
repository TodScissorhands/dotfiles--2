function fish_prompt --description 'A compact two-line prompt with Git context'
    set -l last_status $status
    set -l cwd (prompt_pwd --full-length-dirs=2)

    # Semantic colors from pywal16 (set by fish-colors.fish); fall back to safe defaults.
    set -l c_accent (set -q wal_accent; and echo $wal_accent; or echo 89b4fa)
    set -l c_accent2 (set -q wal_accent_secondary; and echo $wal_accent_secondary; or echo 63b9aa)
    set -l c_success (set -q wal_success; and echo $wal_success; or echo a6e3a1)
    set -l c_muted (set -q wal_fg_muted; and echo $wal_fg_muted; or echo 6c7086)
    set -l c_warning (set -q wal_warning; and echo $wal_warning; or echo f9e2af)
    set -l c_error (set -q wal_error; and echo $wal_error; or echo f38ba8)

    set_color $c_accent --bold
    echo -n '╭─'
    set_color $c_success --bold
    echo -n $USER
    set_color $c_muted
    echo -n ' at '
    set_color $c_warning --bold
    echo -n $cwd

    if command -q git
        set -l branch (command git branch --show-current 2>/dev/null)
        if test -n "$branch"
            set_color $c_muted
            echo -n ' on '
            set_color $c_accent2 --bold
            echo -n " $branch"
        end
    end

    echo
    set_color $c_accent --bold
    echo -n '╰─'
    if test $last_status -eq 0
        set_color $c_success --bold
        echo -n '❯ '
    else
        set_color $c_error --bold
        echo -n "❯ [$last_status] "
    end
    set_color normal
end
