#!/usr/bin/env bash
# ============================================================
# devenv update - Update development environment
# ============================================================
# Pulls latest configs and updates tools.
# Usage: devenv update [--tools] [--configs] [--all]
# ============================================================

set -euo pipefail

DEVENV_HOME="${DEVENV_HOME:-$HOME/.devenv}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

has_cmd() { command -v "$1" &>/dev/null; }

as_root() {
    if [[ $EUID -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

update_repo() {
    log_info "Updating devenv repository..."
    if [[ -d "$DEVENV_HOME/.git" ]]; then
        git -C "$DEVENV_HOME" pull --ff-only
        log_success "Repository updated"
    else
        log_warn "Not a git repository: $DEVENV_HOME"
    fi
}

update_configs() {
    log_info "Updating configurations..."

    # Backup existing configs
    local backup_dir="$HOME/.devenv-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"

    for f in .zshrc .p10k.zsh .tmux.conf; do
        [[ -f "$HOME/$f" ]] && cp "$HOME/$f" "$backup_dir/"
    done
    log_info "Backed up existing configs to $backup_dir"

    # Copy new configs
    cp "$DEVENV_HOME/config/zsh/devenv.zshrc" "$HOME/.zshrc"
    cp "$DEVENV_HOME/config/zsh/p10k.zsh" "$HOME/.p10k.zsh"
    cp "$DEVENV_HOME/config/zsh/aliases.zsh" "$HOME/.devenv/zsh/aliases.zsh"
    cp "$DEVENV_HOME/config/tmux/tmux.conf" "$HOME/.tmux.conf"
    cp "$DEVENV_HOME/config/ghostty/config" "$HOME/.config/ghostty/config"

    log_success "Configurations updated"
}

update_shell_plugins() {
    log_info "Updating shell plugins..."

    # Powerlevel10k
    local p10k_dir="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
    if [[ -d "$p10k_dir" ]]; then
        git -C "$p10k_dir" pull --ff-only 2>/dev/null && log_success "Powerlevel10k updated" || log_warn "Powerlevel10k update failed"
    fi

    # zsh-autosuggestions
    local autosuggestions_dir="$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    if [[ -d "$autosuggestions_dir" ]]; then
        git -C "$autosuggestions_dir" pull --ff-only 2>/dev/null && log_success "zsh-autosuggestions updated" || log_warn "zsh-autosuggestions update failed"
    fi

    # zsh-syntax-highlighting
    local syntax_dir="$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    if [[ -d "$syntax_dir" ]]; then
        git -C "$syntax_dir" pull --ff-only 2>/dev/null && log_success "zsh-syntax-highlighting updated" || log_warn "zsh-syntax-highlighting update failed"
    fi
}

update_cli_tools() {
    log_info "Updating CLI tools..."

    # APT packages
    as_root apt-get update -y
    as_root apt-get upgrade -y ripgrep tmux fzf btop neovim gh 2>/dev/null || true
    log_success "APT packages updated"

    # lazygit (check for newer version)
    if has_cmd lazygit; then
        local current_version
        current_version=$(lazygit --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "0")
        local latest_version="0.44.1"  # Update this periodically

        if [[ "$current_version" != "$latest_version" ]]; then
            log_info "Updating lazygit ($current_version → $latest_version)..."
            local arch
            arch=$(uname -m)
            case "$arch" in
                x86_64)  arch="x86_64" ;;
                aarch64|arm64) arch="arm64" ;;
            esac
            curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${latest_version}/lazygit_${latest_version}_Linux_${arch}.tar.gz" | tar xz -C /tmp lazygit
            as_root mv /tmp/lazygit /usr/local/bin/
            log_success "lazygit updated to $latest_version"
        else
            log_success "lazygit already at latest ($current_version)"
        fi
    fi
}

update_ai_agents() {
    log_info "Updating AI agents..."

    # Claude Code
    if [[ -x "$HOME/.local/bin/claude" ]]; then
        "$HOME/.local/bin/claude" update 2>/dev/null && log_success "Claude Code updated" || log_warn "Claude Code update failed (try: claude update)"
    fi

    # Codex CLI
    if has_cmd bun || [[ -x "$HOME/.bun/bin/bun" ]]; then
        local bun_cmd="${HOME}/.bun/bin/bun"
        [[ -x "$bun_cmd" ]] || bun_cmd="bun"
        "$bun_cmd" install -g --trust @openai/codex@latest 2>/dev/null && log_success "Codex CLI updated" || log_warn "Codex CLI update failed"
    fi

    # UV
    if has_cmd uv; then
        uv self update 2>/dev/null && log_success "UV updated" || log_warn "UV update failed"
    fi
}

show_help() {
    echo "Usage: devenv update [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --all       Update everything (default)"
    echo "  --configs   Update configs only"
    echo "  --tools     Update CLI tools only"
    echo "  --agents    Update AI agents only"
    echo "  --plugins   Update shell plugins only"
    echo "  -h, --help  Show this help"
}

main() {
    local do_all=true
    local do_configs=false
    local do_tools=false
    local do_agents=false
    local do_plugins=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all) do_all=true ;;
            --configs) do_all=false; do_configs=true ;;
            --tools) do_all=false; do_tools=true ;;
            --agents) do_all=false; do_agents=true ;;
            --plugins) do_all=false; do_plugins=true ;;
            -h|--help) show_help; exit 0 ;;
            *) log_error "Unknown option: $1"; show_help; exit 1 ;;
        esac
        shift
    done

    echo ""
    echo "=============================================="
    echo "  devenv update"
    echo "=============================================="
    echo ""

    # Always update the repo first
    update_repo
    echo ""

    if $do_all || $do_configs; then
        update_configs
        echo ""
    fi

    if $do_all || $do_plugins; then
        update_shell_plugins
        echo ""
    fi

    if $do_all || $do_tools; then
        update_cli_tools
        echo ""
    fi

    if $do_all || $do_agents; then
        update_ai_agents
        echo ""
    fi

    echo "=============================================="
    log_success "Update complete!"
    echo "=============================================="
    echo ""
    echo "Restart your shell to apply changes: exec zsh"
    echo ""
}

main "$@"
