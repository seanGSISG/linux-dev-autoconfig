# Linux Dev Autoconfig - Aliases
# Separate aliases file for easy customization
# Sourced by devenv.zshrc

# =============================================================================
# Git
# =============================================================================
alias gs='git status'
alias gd='git diff'
alias gdc='git diff --cached'
alias gp='git push'
alias gpu='git pull'
alias gco='git checkout'
alias gcm='git commit -m'
alias gca='git commit -a -m'
alias gb='git branch'
alias glog='git log --oneline --graph --decorate'

# =============================================================================
# Docker
# =============================================================================
alias dc='docker compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dimg='docker images'
alias dex='docker exec -it'

# =============================================================================
# Navigation
# =============================================================================
alias dev='cd ~/dev'
alias claude='cd ~/dev/claude-home'

# =============================================================================
# System / Package Management
# =============================================================================
alias update='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'
alias install='sudo apt install'
alias search='apt search'

# =============================================================================
# AI Agents
# =============================================================================
# Update all agent CLIs
alias uca='~/.local/bin/claude update; bun install -g --trust @openai/codex@latest'

# Dangerous mode aliases ("vibe mode")
alias ccd='NODE_OPTIONS="--max-old-space-size=32768" ENABLE_BACKGROUND_TASKS=1 ~/.local/bin/claude --dangerously-skip-permissions'
alias cod='codex --dangerously-bypass-approvals-and-sandbox'

# =============================================================================
# Bun Project Helpers
# =============================================================================
alias br='bun run dev'
alias bl='bun run lint'
alias bt='bun run type-check'

# =============================================================================
# Modern CLI Tool Replacements (conditional)
# =============================================================================
# These replace standard commands with modern alternatives if installed

# lsd - Better ls with icons
if command -v lsd &>/dev/null; then
  alias ls='lsd --icon=always'
  alias ll='lsd -l --icon=always'
  alias la='lsd -la --icon=always'
  alias l='lsd --icon=always'
  alias tree='lsd --tree --icon=always'
elif command -v eza &>/dev/null; then
  alias ls='eza --icons'
  alias ll='eza -l --icons'
  alias la='eza -la --icons'
  alias l='eza --icons --classify'
  alias tree='eza --tree --icons'
else
  alias ll='ls -alF'
  alias la='ls -A'
  alias l='ls -CF'
fi

# bat - Better cat with syntax highlighting
command -v bat &>/dev/null && alias cat='bat'
command -v batcat &>/dev/null && alias cat='batcat'

# fd - Better find
command -v fd &>/dev/null && alias find='fd'
command -v fdfind &>/dev/null && alias find='fdfind'

# ripgrep - Better grep
command -v rg &>/dev/null && alias grep='rg'

# dust - Better du
command -v dust &>/dev/null && alias du='dust'

# btop - Better top
command -v btop &>/dev/null && alias top='btop'

# neovim - Better vim
command -v nvim &>/dev/null && alias vim='nvim'

# lazygit - Git TUI
command -v lazygit &>/dev/null && alias lg='lazygit'

# lazydocker - Docker TUI
command -v lazydocker &>/dev/null && alias lzd='lazydocker'
