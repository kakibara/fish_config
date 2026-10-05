function peco_select_history --description 'Search command history with peco'
    if not command -q peco
        return 1
    end

    set -l query (commandline --current-buffer)
    if test (count $argv) -gt 0
        set query (string join ' ' -- $argv)
    end

    set -l selected (history | peco --layout=bottom-up --query "$query")
    # Escape / Ctrl+C leaves the current command untouched.
    if test -n "$selected"
        commandline --replace -- "$selected"
    end
    commandline --function repaint
end
