# shellcheck shell=bash disable=SC2034,SC1091
# ~/.devenv/zsh/devenv.zshrc
# Linux Dev Autoconfig - canonical zsh config (managed). Safe, fast, minimal duplication.
#
# SC2034: ZSH_THEME, plugins, PROMPT, RPROMPT are used by zsh/omz (not bash)
# SC1091: Dynamic source paths can't be followed by shellcheck

# --- SSH stty guard (prevents weird remote terminal settings) ---
if [[ -n "$SSH_CONNECTION" ]]; then
  stty() {
    case "$1" in
      *:*:*) return 0 ;;  # ignore colon-separated terminal settings
      *) command stty "$@" ;;
    esac
  }
fi

# --- Terminal type fallback (Ghostty, Kitty, etc.) ---
# Fall back to xterm-256color if current $TERM is unknown to the system.
# This fixes "unknown terminal type" errors with modern terminals like Ghostty.
if [[ -n "$TERM" ]] && ! infocmp "$TERM" &>/dev/null; then
  export TERM="xterm-256color"
fi

# --- CUDA paths (if CUDA is installed) ---
export PATH="/usr/local/cuda/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH:-}"
export CUDA_HOME="/usr/local/cuda"

# --- Paths (early) ---
export PATH="$HOME/.cargo/bin:$PATH"

# Go (support both apt-style and /usr/local/go)
export PATH="$HOME/go/bin:$PATH"
[[ -d /usr/local/go/bin ]] && export PATH="/usr/local/go/bin:$PATH"

# Bun
export BUN_INSTALL="$HOME/.bun"
[[ -d "$BUN_INSTALL/bin" ]] && export PATH="$BUN_INSTALL/bin:$PATH"
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# Atuin (installer default)
[[ -d "$HOME/.atuin/bin" ]] && export PATH="$HOME/.atuin/bin:$PATH"

# Ensure user-local binaries take precedence (e.g., native Claude install).
export PATH="$HOME/.local/bin:$PATH"

# --- Oh My Zsh ---
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Disable p10k configuration wizard - we provide a pre-configured ~/.p10k.zsh
# This is a fallback in case the config file is missing for some reason
typeset -g POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true

# Oh My Zsh auto-update
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 7

# Plugins
plugins=(
  git
  sudo
  colored-man-pages
  command-not-found
  docker
  docker-compose
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# Load OMZ if installed
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
fi

# --- Editor preference ---
if [[ -n "$SSH_CONNECTION" ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# --- Aliases (loaded from separate file) ---
[[ -f "$HOME/.devenv/zsh/aliases.zsh" ]] && source "$HOME/.devenv/zsh/aliases.zsh"

# --- Custom functions ---
mkcd() { mkdir -p "$1" && cd "$1" || return; }

extract() {
  if [[ -f "$1" ]]; then
    case "$1" in
      *.tar.bz2) tar xjf "$1" ;;
      *.tar.gz)  tar xzf "$1" ;;
      *.bz2)     bunzip2 "$1" ;;
      *.rar)     unrar x "$1" ;;
      *.gz)      gunzip "$1" ;;
      *.tar)     tar xf "$1" ;;
      *.tbz2)    tar xjf "$1" ;;
      *.tgz)     tar xzf "$1" ;;
      *.zip)     unzip "$1" ;;
      *.Z)       uncompress "$1" ;;
      *.7z)      7z x "$1" ;;
      *)         echo "'$1' cannot be extracted" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# --- Safe "ls after cd" via chpwd hook (no overriding cd) ---
# Uses MINIMAL lsd output (icons + names only)
autoload -U add-zsh-hook
_devenv_ls_after_cd() {
  # only in interactive shells
  [[ -o interactive ]] || return
  if command -v lsd &>/dev/null; then
    lsd --icon=always
  elif command -v eza &>/dev/null; then
    eza --icons
  else
    ls
  fi
}
add-zsh-hook chpwd _devenv_ls_after_cd

# --- Tool settings ---
export UV_LINK_MODE=copy

# Cargo env (if present)
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# nvm (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

# Atuin init (after PATH)
if command -v atuin &>/dev/null; then
  eval "$(atuin init zsh)"
fi

# Zoxide (better cd)
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# direnv
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"

# fzf integration (optional)
export FZF_DISABLE_KEYBINDINGS=1
[[ -f "$HOME/.fzf.zsh" ]] && source "$HOME/.fzf.zsh"

# --- Prompt config ---
if [[ "$TERM_PROGRAM" == "vscode" ]]; then
  PROMPT='%n@%m:%~%# '
  RPROMPT=''
else
  [[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"
fi

# --- Local overrides ---
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# --- Force Atuin bindings (must be last) ---
bindkey -e
if command -v atuin &>/dev/null; then
  bindkey -M emacs '^R' atuin-search 2>/dev/null
  bindkey -M viins '^R' atuin-search-viins 2>/dev/null
  bindkey -M vicmd '^R' atuin-search-vicmd 2>/dev/null
fi

# --- Env shim (optional) ---
[[ -f "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"

# --- Dev Environment CLI ---
# Provides `devenv <subcommand>` for post-install utilities
devenv() {
  local devenv_home="${DEVENV_HOME:-$HOME/.devenv}"
  local devenv_bin="$HOME/.local/bin/devenv"
  local cmd="${1:-help}"
  shift 1 2>/dev/null || true

  case "$cmd" in
    doctor|check)
      if [[ -f "$devenv_home/scripts/lib/doctor.sh" ]]; then
        bash "$devenv_home/scripts/lib/doctor.sh" "$@"
      elif [[ -x "$devenv_bin" ]]; then
        "$devenv_bin" doctor "$@"
      else
        echo "Error: doctor.sh not found"
        return 1
      fi
      ;;
    update)
      if [[ -f "$devenv_home/scripts/lib/update.sh" ]]; then
        bash "$devenv_home/scripts/lib/update.sh" "$@"
      elif [[ -x "$devenv_bin" ]]; then
        "$devenv_bin" update "$@"
      else
        echo "Error: update.sh not found"
        return 1
      fi
      ;;
    info|i)
      echo "Linux Dev Autoconfig Environment"
      echo "================================="
      echo "Hostname: $(hostname)"
      echo "User: $(whoami)"
      echo "Shell: $SHELL"
      echo "Arch: $(uname -m)"
      echo ""
      echo "CUDA: $(nvcc --version 2>/dev/null | grep release | awk '{print $6}' | tr -d ',' || echo 'not found')"
      echo "GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1 || echo 'not found')"
      echo ""
      echo "Python: $(python3 --version 2>/dev/null || echo 'not found')"
      echo "UV: $(uv --version 2>/dev/null || echo 'not installed')"
      echo "Claude: $(~/.local/bin/claude --version 2>/dev/null || echo 'not installed')"
      echo "Codex: $(codex --version 2>/dev/null || echo 'not installed')"
      ;;
    version|-v|--version)
      if [[ -f "$devenv_home/VERSION" ]]; then
        cat "$devenv_home/VERSION"
      else
        echo "Linux Dev Autoconfig version unknown"
      fi
      ;;
    help|-h|--help|*)
      echo "Linux Dev Autoconfig - Development Environment"
      echo ""
      echo "Usage: devenv <command>"
      echo ""
      echo "Commands:"
      echo "  info            Quick system overview (hostname, GPU, tools)"
      echo "  doctor          Check system health and tool status"
      echo "  update          Update tools to latest versions"
      echo "  version         Show version"
      echo "  help            Show this help message"
      ;;
  esac
}

# --- Keybindings (quality of life) ---
# Ctrl+Arrow for word movement
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

# Alt+Arrow for word movement
bindkey "^[[1;3C" forward-word
bindkey "^[[1;3D" backward-word
bindkey "^[^[[C" forward-word
bindkey "^[^[[D" backward-word

# Ctrl+Backspace and Ctrl+Delete
bindkey "^H" backward-kill-word
bindkey "^[[3;5~" kill-word

# Home/End keys
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
bindkey "^[[1~" beginning-of-line
bindkey "^[[4~" end-of-line
