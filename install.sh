#!/usr/bin/env bash
# ============================================================
# Linux Dev Autoconfig - Bootstrap Installer
# ============================================================
# Two-stage installer:
#   Stage 1: Install minimal deps + chezmoi (this script)
#   Stage 2: chezmoi applies configs and runs tool installation
#
# Usage: curl -fsSL https://raw.githubusercontent.com/seanGSISG/linux-dev-autoconfig/main/install.sh | bash
# ============================================================

set -euo pipefail

VERSION="2.0.0"
DOTFILES_REPO="seanGSISG/dotfiles"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

# ============================================================
# Stage 1: Minimal Bootstrap
# ============================================================

install_minimal_deps() {
    log_info "Installing minimal dependencies..."
    as_root apt-get update -y
    as_root apt-get install -y curl git age
    log_success "Minimal dependencies installed"
}

install_chezmoi() {
    if has_cmd chezmoi; then
        log_success "chezmoi already installed"
        return
    fi

    log_info "Installing chezmoi..."
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH"
    log_success "chezmoi installed"
}

# ============================================================
# Stage 2: Chezmoi Dotfiles
# ============================================================

setup_dotfiles() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  Private Dotfiles Setup${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "This will set up your private configs (SSH, Claude knowledge base, etc.)"
    echo "You'll need your age decryption key from Bitwarden."
    echo ""

    read -p "Set up private dotfiles? [Y/n] " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log_warn "Skipping dotfiles setup"
        log_info "You can set up later with: chezmoi init --apply $DOTFILES_REPO"
        return
    fi

    # Check for age key
    if [[ ! -f "$HOME/.config/chezmoi/key.txt" ]]; then
        echo ""
        echo -e "${YELLOW}Age decryption key not found.${NC}"
        echo ""
        echo "To decrypt your private configs, paste your age key from Bitwarden."
        echo "It looks like: AGE-SECRET-KEY-1ABC..."
        echo ""

        mkdir -p "$HOME/.config/chezmoi"
        read -p "Paste your age key (or press Enter to skip): " age_key

        if [[ -n "$age_key" ]]; then
            echo "$age_key" > "$HOME/.config/chezmoi/key.txt"
            chmod 600 "$HOME/.config/chezmoi/key.txt"
            log_success "Age key saved"
        else
            log_warn "No age key provided - encrypted files will not be decrypted"
        fi
    else
        log_success "Age key already configured"
    fi

    # Initialize and apply chezmoi
    log_info "Applying dotfiles..."
    "$HOME/.local/bin/chezmoi" init --apply "$DOTFILES_REPO"
    log_success "Dotfiles applied"
}

# ============================================================
# Main
# ============================================================

main() {
    echo ""
    echo "=============================================="
    echo "  Linux Dev Autoconfig v${VERSION}"
    echo "  Bootstrap Installer"
    echo "=============================================="
    echo ""

    # Check not root
    if [[ $EUID -eq 0 ]]; then
        log_error "Do not run as root. Run as your normal user with sudo access."
        exit 1
    fi

    # Stage 1: Minimal deps
    install_minimal_deps
    install_chezmoi

    # Stage 2: Dotfiles (optional)
    setup_dotfiles

    echo ""
    echo "=============================================="
    log_success "Bootstrap complete!"
    echo "=============================================="
    echo ""
    echo "Next steps:"
    echo "  1. Start zsh:        exec zsh"
    echo "  2. Connect VPN:      sudo tailscale up"
    echo "  3. Auth Claude:      claude login"
    echo ""
}

main "$@"
