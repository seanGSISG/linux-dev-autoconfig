#!/usr/bin/env bash
# ============================================================
# devenv doctor - System health check
# ============================================================
# Verifies all tools are installed and configs are in place.
# Usage: devenv doctor
# ============================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ok() { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
fail() { echo -e "${RED}[FAIL]${NC} $*"; }
info() { echo -e "${BLUE}[INFO]${NC} $*"; }

has_cmd() { command -v "$1" &>/dev/null; }

check_count=0
ok_count=0
warn_count=0
fail_count=0

check_tool() {
    local name="$1"
    local cmd="${2:-$1}"
    ((check_count++))

    if has_cmd "$cmd"; then
        local version
        version=$("$cmd" --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 || echo "?")
        ok "$name installed ($version)"
        ((ok_count++))
    else
        fail "$name not found"
        ((fail_count++))
    fi
}

check_file() {
    local path="$1"
    local desc="$2"
    ((check_count++))

    if [[ -f "$path" ]]; then
        ok "$desc exists"
        ((ok_count++))
    else
        fail "$desc missing: $path"
        ((fail_count++))
    fi
}

check_dir() {
    local path="$1"
    local desc="$2"
    ((check_count++))

    if [[ -d "$path" ]]; then
        ok "$desc exists"
        ((ok_count++))
    else
        warn "$desc missing: $path"
        ((warn_count++))
    fi
}

main() {
    echo ""
    echo "=============================================="
    echo "  devenv doctor - System Health Check"
    echo "=============================================="
    echo ""

    # Shell
    info "Checking shell..."
    check_tool "zsh"
    if [[ "$SHELL" == *"zsh"* ]]; then
        ok "Default shell is zsh"
        ((ok_count++))
    else
        warn "Default shell is not zsh (current: $SHELL)"
        ((warn_count++))
    fi
    ((check_count++))
    echo ""

    # CLI Tools
    info "Checking CLI tools..."
    check_tool "lsd"
    check_tool "bat" "batcat"  # Ubuntu names it batcat
    has_cmd bat || check_tool "bat (alt)" "bat"
    check_tool "ripgrep" "rg"
    check_tool "fd" "fdfind"  # Ubuntu names it fdfind
    has_cmd fd || check_tool "fd (alt)" "fd"
    check_tool "fzf"
    check_tool "btop"
    check_tool "lazygit"
    check_tool "tmux"
    check_tool "neovim" "nvim"
    check_tool "jq"
    check_tool "gh"
    echo ""

    # Networking
    info "Checking networking tools..."
    check_tool "tailscale"
    if has_cmd tailscale; then
        if tailscale status &>/dev/null; then
            ok "Tailscale connected"
            ((ok_count++))
        else
            warn "Tailscale installed but not connected"
            ((warn_count++))
        fi
        ((check_count++))
    fi
    check_tool "mosh"
    echo ""

    # AI Agents
    info "Checking AI agents..."
    check_tool "claude" "$HOME/.local/bin/claude"
    check_tool "codex"
    check_tool "uv"
    check_tool "bun" "$HOME/.bun/bin/bun"
    echo ""

    # Configs
    info "Checking configurations..."
    check_file "$HOME/.zshrc" "~/.zshrc"
    check_file "$HOME/.p10k.zsh" "~/.p10k.zsh"
    check_file "$HOME/.tmux.conf" "~/.tmux.conf"
    check_file "$HOME/.devenv/zsh/aliases.zsh" "~/.devenv/zsh/aliases.zsh"
    check_file "$HOME/.config/ghostty/config" "~/.config/ghostty/config"
    echo ""

    # Oh My Zsh
    info "Checking Oh My Zsh..."
    check_dir "$HOME/.oh-my-zsh" "Oh My Zsh"
    check_dir "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" "Powerlevel10k theme"
    check_dir "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" "zsh-autosuggestions"
    check_dir "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" "zsh-syntax-highlighting"
    echo ""

    # Summary
    echo "=============================================="
    echo -e "  Summary: ${GREEN}$ok_count OK${NC}, ${YELLOW}$warn_count WARN${NC}, ${RED}$fail_count FAIL${NC}"
    echo "=============================================="
    echo ""

    if [[ $fail_count -gt 0 ]]; then
        echo "Run 'devenv update' to fix missing tools."
        return 1
    elif [[ $warn_count -gt 0 ]]; then
        echo "Some optional items need attention."
        return 0
    else
        echo "All checks passed!"
        return 0
    fi
}

main "$@"
