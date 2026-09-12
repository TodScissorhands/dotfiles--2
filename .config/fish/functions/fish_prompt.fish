function fish_prompt --description 'A compact two-line prompt with Git context'
    set -l last_status $status
    set -l cwd (prompt_pwd --full-length-dirs=2)

    set_color 89b4fa --bold
    echo -n '╭─'
    set_color a6e3a1 --bold
    echo -n $USER
    set_color 6c7086
    echo -n ' at '
    set_color f9e2af --bold
    echo -n $cwd

    if command -q git
        set -l branch (command git branch --show-current 2>/dev/null)
        if test -n "$branch"
            set_color 6c7086
            echo -n ' on '
            set_color 63b9aa --bold
            echo -n " $branch"
        end
    end

    echo
    set_color 89b4fa --bold
    echo -n '╰─'
    if test $last_status -eq 0
        set_color a6e3a1 --bold
        echo -n '❯ '
    else
        set_color f38ba8 --bold
        echo -n "❯ [$last_status] "
    end
    set_color normal
end
