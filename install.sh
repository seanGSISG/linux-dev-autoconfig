#!/usr/bin/env bash
# ============================================================
# Linux Dev Autoconfig - Complete Dev Environment Setup
# ============================================================
# Self-contained installer that sets up a full dev environment:
#   - CLI tools (bat, lsd, fd, rg, fzf, etc.)
#   - Shell (zsh + Oh My Zsh + Powerlevel10k)
#   - Configs (aliases, tmux, ghostty)
#   - AI agents (Claude Code, Codex)
#   - Optionally: private dotfiles via chezmoi
#
# Usage: curl -fsSL https://raw.githubusercontent.com/seanGSISG/linux-dev-autoconfig/main/install.sh | bash
# ============================================================

set -euo pipefail

VERSION="3.0.0"
REPO_URL="https://github.com/seanGSISG/linux-dev-autoconfig"
DOTFILES_REPO="seanGSISG/dotfiles"

# Detect architecture
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64)  DEB_ARCH="amd64"; TARBALL_ARCH="x86_64" ;;
    aarch64) DEB_ARCH="arm64"; TARBALL_ARCH="arm64" ;;
    arm64)   DEB_ARCH="arm64"; TARBALL_ARCH="arm64" ;;
    *)       echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

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
# Phase 1: Base Dependencies
# ============================================================

install_base_deps() {
    log_info "Installing base dependencies..."

    as_root apt-get update -y

    local packages=(
        curl git wget ca-certificates unzip tar xz-utils jq
        build-essential gnupg lsb-release zsh software-properties-common
    )

    as_root apt-get install -y "${packages[@]}"
    log_success "Base dependencies installed"
}

# ============================================================
# Phase 2: CLI Tools
# ============================================================

install_cli_tools() {
    log_info "Installing CLI tools..."

    # APT packages
    local apt_packages=(ripgrep tmux fzf direnv git-lfs mosh ncdu tldr)
    as_root apt-get install -y "${apt_packages[@]}" || true

    # duf
    if ! has_cmd duf; then
        as_root apt-get install -y duf 2>/dev/null || {
            local duf_version="0.8.1"
            curl -fsSL "https://github.com/muesli/duf/releases/download/v${duf_version}/duf_${duf_version}_linux_${DEB_ARCH}.deb" -o /tmp/duf.deb
            as_root dpkg -i /tmp/duf.deb && rm /tmp/duf.deb
        } || true
    fi

    # Tailscale
    if ! has_cmd tailscale; then
        log_info "Installing Tailscale..."
        curl -fsSL https://tailscale.com/install.sh | bash || log_warn "Tailscale installation failed"
    fi

    # lsd
    if ! has_cmd lsd; then
        as_root apt-get install -y lsd 2>/dev/null || {
            local lsd_version="1.1.5"
            curl -fsSL "https://github.com/lsd-rs/lsd/releases/download/v${lsd_version}/lsd_${lsd_version}_${DEB_ARCH}.deb" -o /tmp/lsd.deb
            as_root dpkg -i /tmp/lsd.deb && rm /tmp/lsd.deb
        }
    fi

    # bat, fd, btop, neovim, lazygit, gh
    as_root apt-get install -y bat fd-find btop neovim gh 2>/dev/null || true

    # lazygit fallback
    if ! has_cmd lazygit; then
        local lazygit_version="0.44.1"
        curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${lazygit_version}/lazygit_${lazygit_version}_Linux_${TARBALL_ARCH}.tar.gz" | tar xz -C /tmp lazygit
        as_root mv /tmp/lazygit /usr/local/bin/
    fi

    log_success "CLI tools installed"
}

# ============================================================
# Phase 3: Shell Setup (Oh My Zsh + Powerlevel10k)
# ============================================================

install_shell_plugins() {
    log_info "Installing shell plugins..."

    # Oh My Zsh
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Installing Oh My Zsh..."
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    # Powerlevel10k
    local p10k_dir="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
    if [[ ! -d "$p10k_dir" ]]; then
        log_info "Installing Powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
    fi

    # zsh-autosuggestions
    local autosuggestions_dir="$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    if [[ ! -d "$autosuggestions_dir" ]]; then
        git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$autosuggestions_dir"
    fi

    # zsh-syntax-highlighting
    local syntax_dir="$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    if [[ ! -d "$syntax_dir" ]]; then
        git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$syntax_dir"
    fi

    # Change default shell to zsh
    if [[ "$SHELL" != "$(which zsh)" ]]; then
        log_info "Changing default shell to zsh..."
        as_root chsh -s "$(which zsh)" "$(whoami)"
    fi

    log_success "Shell plugins installed"
}

# ============================================================
# Phase 4: AI Agents
# ============================================================

install_ai_agents() {
    log_info "Installing AI agents..."

    # UV (Python package manager)
    if ! has_cmd uv; then
        curl -LsSf https://astral.sh/uv/install.sh | bash
    fi

    # Bun
    if ! has_cmd bun && [[ ! -x "$HOME/.bun/bin/bun" ]]; then
        curl -fsSL https://bun.sh/install | bash
    fi

    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"

    # Claude Code
    if [[ ! -x "$HOME/.local/bin/claude" ]]; then
        log_info "Installing Claude Code..."
        curl -fsSL https://claude.ai/install.sh | bash || log_warn "Claude Code installation failed"
    fi

    # Codex CLI
    if [[ -x "$HOME/.bun/bin/bun" ]]; then
        "$HOME/.bun/bin/bun" install -g --trust @openai/codex@latest || true
    fi

    log_success "AI agents installed"
}

# ============================================================
# Phase 5: Apply Configs
# ============================================================

apply_configs() {
    log_info "Applying configurations..."

    # Clone or update repo to ~/.devenv
    local repo_dir="$HOME/.devenv"
    if [[ -d "$repo_dir" ]]; then
        git -C "$repo_dir" pull --ff-only 2>/dev/null || true
    else
        git clone --depth=1 "$REPO_URL" "$repo_dir"
    fi

    # Create directories
    mkdir -p "$HOME/.config/ghostty"
    mkdir -p "$HOME/.devenv/zsh"
    mkdir -p "$HOME/dev/github"
    mkdir -p "$HOME/.local/bin"

    # Copy configs
    cp "$repo_dir/config/zsh/devenv.zshrc" "$HOME/.zshrc"
    cp "$repo_dir/config/zsh/p10k.zsh" "$HOME/.p10k.zsh"
    cp "$repo_dir/config/zsh/aliases.zsh" "$HOME/.devenv/zsh/aliases.zsh"
    cp "$repo_dir/config/tmux/tmux.conf" "$HOME/.tmux.conf"
    cp "$repo_dir/config/ghostty/config" "$HOME/.config/ghostty/config"

    log_success "Configurations applied"
}

# ============================================================
# Phase 6: Private Dotfiles (Optional)
# ============================================================

setup_private_dotfiles() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  Private Dotfiles Setup (Optional)${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "This will set up your private configs (SSH, Claude knowledge base)"
    echo "You'll need your age decryption key from Bitwarden."
    echo ""

    read -p "Set up private dotfiles? [y/N] " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping private dotfiles"
        return
    fi

    # Install age and chezmoi
    as_root apt-get install -y age
    if ! has_cmd chezmoi; then
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
        export PATH="$HOME/.local/bin:$PATH"
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
    log_info "Applying private dotfiles..."
    "$HOME/.local/bin/chezmoi" init --apply --source "$HOME/dev/github/dotfiles" "$DOTFILES_REPO"
    log_success "Private dotfiles applied"
}

# ============================================================
# Main
# ============================================================

main() {
    echo ""
    echo "=============================================="
    echo "  Linux Dev Autoconfig v${VERSION}"
    echo "=============================================="
    echo ""

    # Check not root
    if [[ $EUID -eq 0 ]]; then
        log_error "Do not run as root. Run as your normal user with sudo access."
        exit 1
    fi

    install_base_deps
    install_cli_tools
    install_shell_plugins
    install_ai_agents
    apply_configs
    setup_private_dotfiles

    echo ""
    echo "=============================================="
    log_success "Setup complete!"
    echo "=============================================="
    echo ""
    echo "Next steps:"
    echo "  1. Start zsh:        exec zsh"
    echo "  2. Connect VPN:      sudo tailscale up"
    echo "  3. Auth Claude:      claude login"
    echo ""
}

main "$@"
