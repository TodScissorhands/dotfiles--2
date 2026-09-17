if status is-interactive
    if test -f "$HOME/.cache/wal/fish-colors.fish"
        source "$HOME/.cache/wal/fish-colors.fish"
    else
        # Safe fallback if the volatile pywal16 cache has been cleared.
        set -g fish_color_command 89b4fa
        set -g fish_color_param cdd6f4
        set -g fish_color_quote a6e3a1
        set -g fish_color_redirection 63b9aa
        set -g fish_color_comment 6c7086
        set -g fish_color_error f38ba8
        set -g fish_color_operator 89dceb
        set -g fish_color_autosuggestion 6c7086
        set -g fish_pager_color_prefix f9e2af --bold
        set -g fish_pager_color_completion cdd6f4
    end

    # Quiet, readable interactive shell defaults.
    set -g fish_greeting

    alias y='yazi'
    function rmpc
        if test (count $argv) -eq 0
            rmpc-stop-on-exit
        else
            command rmpc $argv
        end
    end
    alias ls='eza --group-directories-first --icons=auto'
    alias ll='eza --long --group-directories-first --icons=auto --git'
    alias la='eza --all --long --group-directories-first --icons=auto --git'
    alias cat='bat'
    alias zed='zeditor'
end

if command -q zoxide
	zoxide init fish | source

	alias cd='z'
end

# Bun
set -gx BUN_INSTALL $HOME/.bun
set -gx PATH $BUN_INSTALL/bin $PATH
function sqlplus
    rlwrap -a -H ~/.sqlplus_history /usr/bin/sqlplus $argv
end
