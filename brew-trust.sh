#!/usr/bin/env bash
set -Eeuo pipefail

# Autorizações explícitas para dependências de taps externos do Brewfile.
brew trust --formula kong/deck/deck
brew trust --cask stablyai/orca/orca
