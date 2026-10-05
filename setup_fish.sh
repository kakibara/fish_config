#!/usr/bin/env bash
set -euo pipefail

# Run from a checkout so unpublished local changes are installed as well.
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
for file in config.fish peco_select_history.fish fish_plugins; do
    if [[ ! -f "$script_dir/files/$file" ]]; then
        echo "Missing files/$file. Clone the repository and run bash setup_fish.sh." >&2
        exit 1
    fi
done

case "$(uname -s)" in
    Darwin)
        # Homebrew locations for Apple Silicon and Intel Macs.
        if ! command -v brew >/dev/null 2>&1; then
            for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
                if [[ -x "$brew_bin" ]]; then
                    eval "$("$brew_bin" shellenv bash)"
                    break
                fi
            done
        fi
        if ! command -v brew >/dev/null 2>&1; then
            echo "Install Homebrew first: https://brew.sh" >&2
            exit 1
        fi
        packages=()
        for package in fish peco curl; do
            command -v "$package" >/dev/null 2>&1 || packages+=("$package")
        done
        if (( ${#packages[@]} )); then
            brew install "${packages[@]}"
        fi
        ;;
    Linux)
        if ! command -v apt-get >/dev/null 2>&1; then
            echo "Install fish, peco and curl with your package manager first." >&2
            exit 1
        fi
        packages=()
        for package in fish peco curl; do
            command -v "$package" >/dev/null 2>&1 || packages+=("$package")
        done
        if (( ${#packages[@]} )); then
            elevate=()
            if (( EUID != 0 )); then elevate=(sudo); fi
            "${elevate[@]}" apt-get update
            "${elevate[@]}" apt-get install -y "${packages[@]}"
        fi
        ;;
    *) echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/fish"
mkdir -p "$config_dir"
if [[ -n "$(ls -A "$config_dir")" ]]; then
    backup_dir="$(mktemp -d "${config_dir}.backup.XXXXXXXX")"
    cp -R "$config_dir/." "$backup_dir/"
    echo "Existing fish configuration backed up to $backup_dir"
fi

# Download successfully before sourcing; do not mask curl errors in a pipeline.
fisher_file="$(mktemp)"
trap 'rm -f "$fisher_file"' EXIT
curl --fail --silent --show-error --location \
    https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish \
    --output "$fisher_file"
plugins=()
while IFS= read -r plugin || [[ -n "$plugin" ]]; do
    [[ -z "$plugin" || "$plugin" == \#* ]] && continue
    plugins+=("$plugin")
done < "$script_dir/files/fish_plugins"
if (( ${#plugins[@]} == 0 )); then
    echo "No plugins listed in files/fish_plugins." >&2
    exit 1
fi
# Pass each plugin as a separate argument; preserve other installed plugins.
fish --no-config -c 'source $argv[1]; and fisher install $argv[2..-1]' "$fisher_file" "${plugins[@]}"

mkdir -p "$config_dir/functions"
cp "$script_dir/files/config.fish" "$config_dir/config.fish"
cp "$script_dir/files/peco_select_history.fish" "$config_dir/functions/peco_select_history.fish"
fish --no-config --no-execute "$config_dir/config.fish"
fish --no-config --no-execute "$config_dir/functions/peco_select_history.fish"
echo "Setup complete. Run fish to start a new shell."
echo "To change your login shell, follow README.md using: $(command -v fish)"
