#! /usr/bin/env bash

sudo apt-add-repository ppa:fish-shell/release-3
sudo apt-get update
sudo apt install -y fish peco

fish -c "curl https://git.io/fisher --create-dirs -sLo ~/.config/fish/functions/fisher.fish"
fish -c "fisher install jethrokuan/z oh-my-fish/theme-agnoster oh-my-fish/peco"
mkdir -p ~/.config
mkdir -p ~/.config/fish

curl -L https://raw.githubusercontent.com/kakibara/fish_config/main/files/config.fish -o ~/.config/fish/config.fish
curl -L https://raw.githubusercontent.com/kakibara/fish_config/main/files/peco_select_history.fish -o ~/.config/fish/functions/peco_select_history.fish
