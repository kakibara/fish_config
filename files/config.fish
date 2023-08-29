function fish_user_key_bindings
  bind \cr peco_select_history # Bind for peco select history to Ctrl+R
end

# singularity config
set -x SINGULARITY_NV true
set -x SINGULARITY_HOSTNAME SNG-(string split . (hostname) | head -n 1)

if set -q SINGULARITY_CONTAINER
  set -x WORKON_HOME $HOME/in_singularity/pipenv/venv
  set -x POETRY_CACHE_DIR $HOME/in_singularity/pypoetry
else
  set -x WORKON_HOME $HOME/.local/share/virtualenvs
  set -x POETRY_CACHE_DIR $HOME/.local/share/pypoetry
end
