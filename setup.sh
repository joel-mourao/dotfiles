#!/usr/bin/env bash
set -Eeuo pipefail

# ========================================
# Configurações padrão
# ========================================
BREWFILE="${HOME}/.dotfiles/Brewfile"
DO_KEYS=0
DO_ALL=0
DO_BREWFILE=0
DO_UPDATE=0
DO_CLEANUP=0
KEEPALIVE=1

# ========================================
# Funções utilitárias
# ========================================

usage() {
  cat <<'EOF'
Uso: setup.sh [opções]

Operações (escolha uma):
  -a, --all          Atualiza tudo: Homebrew (update/upgrade), fórmulas e casks, aplica o Brewfile e faz cleanup opcional
  -b, --brewfile     Aplica apenas o Brewfile (instala o que faltar). Use --cleanup para remover o que não está no Brewfile
  -u, --update       Apenas 'brew update && brew upgrade && brew cleanup' (não mexe no Brewfile)

Opções:
  -f, --file PATH    Caminho do Brewfile (padrão: ~/.dotfiles/Brewfile)
      --cleanup      Ao usar --brewfile ou --all, remove itens fora do Brewfile (brew bundle cleanup --force)
      --keys         Aplica preferências de teclado (ApplePressAndHold) e copia KeyBindings
      --no-keepalive Não mantém sudo ativo em background
  -h, --help         Mostra esta ajuda
EOF
}

log()  { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[AVISO]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[ERRO]\033[0m %s\n" "$*" >&2; }

require_macos() {
  if [[ "${OSTYPE:-}" != darwin* ]]; then 
    warn "Etapas de macOS (defaults/KeyBindings) serão ignoradas."
  fi
}

ensure_sudo() {
  if command -v sudo >/dev/null 2>&1; then
    sudo -v || true
    if [[ "$KEEPALIVE" -eq 1 ]]; then
      while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    fi
  fi
}

install_homebrew_if_needed() {
  if ! command -v brew >/dev/null 2>&1; then
    log "Homebrew não encontrado. Instalando..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    log "Homebrew instalado."
    # Ajusta PATH (Apple Silicon)
    if [[ -d "/opt/homebrew/bin" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
  else
    log "Homebrew encontrado."
  fi
}

brew_update_all() {
  log "Atualizando fórmulas e casks..."
  brew update
  brew upgrade
  brew upgrade --cask || true
  brew cleanup
}

apply_brewfile() {
  local bf="$1"
  if [[ ! -f "$bf" ]]; then
    err "Brewfile não encontrado: $bf"
    exit 1
  fi
  log "Aplicando Brewfile: $bf"
  brew bundle --file="$bf"
  if [[ "$DO_CLEANUP" -eq 1 ]]; then
    log "Removendo itens fora do Brewfile (cleanup)..."
    brew bundle cleanup --force --file="$bf"
  fi
}

apply_key_prefs() {
  if [[ "${OSTYPE:-}" == darwin* ]]; then
    log "Aplicando preferências de teclado..."
    defaults write -g ApplePressAndHoldEnabled -bool false
    mkdir -p "${HOME}/Library/KeyBindings"
    if [[ -f "${HOME}/.dotfiles/Library/KeyBindings/DefaultKeyBinding.dict" ]]; then
      cp "${HOME}/.dotfiles/Library/KeyBindings/DefaultKeyBinding.dict" "${HOME}/Library/KeyBindings/"
      log "KeyBindings copiado."
    else
      warn "DefaultKeyBinding.dict não encontrado em ~/.dotfiles/Library/KeyBindings/"
    fi
  else
    warn "--keys ignorado (não macOS)."
  fi
}

# ========================================
# Parse de argumentos
# ========================================
if [[ $# -eq 0 ]]; then usage; exit 0; fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    -a|--all) DO_ALL=1; shift ;;
    -b|--brewfile) DO_BREWFILE=1; shift ;;
    -u|--update) DO_UPDATE=1; shift ;;
    -f|--file) BREWFILE="$2"; shift 2 ;;
    --cleanup) DO_CLEANUP=1; shift ;;
    --keys) DO_KEYS=1; shift ;;
    --no-keepalive) KEEPALIVE=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "Opção desconhecida: $1"; usage; exit 1 ;;
  esac
done

# Exatamente UMA operação principal
ops=$(( DO_ALL + DO_BREWFILE + DO_UPDATE ))
if (( ops != 1 )); then
  err "Escolha exatamente UMA: --all OU --brewfile OU --update."
  usage
  exit 1
fi

# ========================================
# Execução
# ========================================
require_macos
ensure_sudo
install_homebrew_if_needed

if [[ "$DO_KEYS" -eq 1 ]]; then
  apply_key_prefs
fi

if   [[ "$DO_UPDATE"   -eq 1 ]]; then
  brew_update_all
elif [[ "$DO_BREWFILE" -eq 1 ]]; then
  apply_brewfile "$BREWFILE"
elif [[ "$DO_ALL"      -eq 1 ]]; then
  brew_update_all
  apply_brewfile "$BREWFILE"
fi

log "Concluído."
