# Homebrew must also be available when fish starts as a login shell.
if test (uname) = Darwin
    for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew
        if test -x $brew_bin
            $brew_bin shellenv fish | source
            break
        end
    end
end

if status is-interactive
    function fish_user_key_bindings
        bind \cr peco_select_history
    end
end

# Singularity / Apptainer container settings.
set -gx SINGULARITY_NV true
set -gx SINGULARITY_HOSTNAME SNG-(string split . (hostname))[1]

if set -q SINGULARITY_CONTAINER; or set -q APPTAINER_CONTAINER
    set -gx WORKON_HOME $HOME/in_singularity/pipenv/venv
    set -gx POETRY_CACHE_DIR $HOME/in_singularity/pypoetry
else
    set -gx WORKON_HOME $HOME/.local/share/virtualenvs
    set -gx POETRY_CACHE_DIR $HOME/.local/share/pypoetry
end
