#! /usr/bin/env bash

if !(type fish > /dev/null 2>&1); then
	sudo apt-add-repository ppa:fish-shell/release-3
	sudo apt-get update
	sudo apt install -y fish 
fi

if !(type peco > /dev/null 2>&1); then
	sudo apt-get update
	sudo apt install -y peco
fi


fish -c "curl https://git.io/fisher --create-dirs -sLo ~/.config/fish/functions/fisher.fish"
fish -c "fisher install jethrokuan/z"
fish -c "fisher install oh-my-fish/theme-agnoster"
mkdir -p ~/.config
mkdir -p ~/.config/fish

curl -L https://raw.githubusercontent.com/kakibara/fish_config/main/files/config.fish -o ~/.config/fish/config.fish
curl -L https://raw.githubusercontent.com/kakibara/fish_config/main/files/peco_select_history.fish -o ~/.config/fish/functions/peco_select_history.fish
