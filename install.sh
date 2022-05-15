#!/usr/bin/env bash

set -Eeuo pipefail

# Ask for the root password upfront
sudo -v

# Keep-alive
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

############################################################################
# Enable Key Repeating 
############################################################################
defaults write -g ApplePressAndHoldEnabled -bool false
mkdir -p "${HOME}/Library/KeyBindings"
cp "${HOME}/.dotfiles/Library/KeyBindings/DefaultKeyBinding.dict" "${HOME}/Library/KeyBindings/"

############################################################################
# Homebrew
############################################################################
CI=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew bundle --file "${HOME}/.dotfiles/Brewfile" --force cleanup
brew bundle --file "${HOME}/.dotfiles/Brewfile"
