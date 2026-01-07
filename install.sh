#!/usr/bin/env bash
# ============================================================
# Linux Dev Environment Autoconfig - Installation Script
# ============================================================
# Automated setup for Linux development environments
# Optimized for Python/AI development with modern shell tools
#
# Usage: ./install.sh [--help] [--dry-run] [--skip-phase N]
# ============================================================

set -euo pipefail

# Script configuration
VERSION="1.0.0"
REPO_URL="https://github.com/seanGSISG/DGX-Spark-Autoconfig.git"

# Detect if running from curl pipe or locally
if [[ -f "${BASH_SOURCE[0]}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    # Running from curl pipe - clone repo first
    SCRIPT_DIR="/tmp/DGX-Spark-Autoconfig"
    echo -e "\033[0;34m[INFO]\033[0m Fetching repository..."
    rm -rf "$SCRIPT_DIR"
    git clone --depth=1 "$REPO_URL" "$SCRIPT_DIR"
fi

# Detect system architecture
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64)  DEB_ARCH="amd64"; TARBALL_ARCH="x86_64" ;;
    aarch64) DEB_ARCH="arm64"; TARBALL_ARCH="arm64" ;;
    arm64)   DEB_ARCH="arm64"; TARBALL_ARCH="arm64" ;;
    *)       echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac
TARGET_USER="${TARGET_USER:-$(whoami)}"
TARGET_HOME="${TARGET_HOME:-/home/$TARGET_USER}"
DEVENV_HOME="$TARGET_HOME/.devenv"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_step() { echo -e "${CYAN}[$1]${NC} $2"; }

# ============================================================
# Helper Functions
# ============================================================

show_help() {
    cat << EOF
Linux Dev Autoconfig v${VERSION}
================================
Automated setup for Linux development environments.

Usage: ./install.sh [OPTIONS]

Options:
    --help          Show this help message
    --dry-run       Show what would be done without making changes
    --skip-phase N  Skip a specific phase (1-6)
    --user USER     Target user (default: adminuser)

Phases:
    1. Base Dependencies    - Install apt packages
    2. User Setup          - Configure user permissions
    3. Filesystem          - Create directories
    4. Shell Setup         - zsh + Oh My Zsh + Powerlevel10k
    5. CLI Tools           - Modern CLI replacements (lsd, bat, etc.)
    6. AI Agents           - UV, Bun, Codex CLI, configs

Examples:
    ./install.sh                    # Full installation
    ./install.sh --dry-run          # Preview changes
    ./install.sh --skip-phase 2     # Skip user setup

EOF
}

# Check if running as root
check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "Do not run this script as root. Run as target user with sudo access."
        exit 1
    fi
}

# Check if command exists
has_cmd() {
    command -v "$1" &>/dev/null
}

# Run command as root
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

phase1_base_dependencies() {
    log_step "1/6" "Installing base dependencies..."

    # Update package lists
    as_root apt-get update -y

    # Install essential packages
    local packages=(
        curl
        git
        wget
        ca-certificates
        unzip
        tar
        xz-utils
        jq
        build-essential
        gnupg
        lsb-release
        zsh
        software-properties-common
    )

    as_root apt-get install -y "${packages[@]}"

    log_success "Base dependencies installed"
}

# ============================================================
# Phase 2: User Setup
# ============================================================

phase2_user_setup() {
    log_step "2/6" "Configuring user permissions..."

    # Ensure user is in docker group if docker exists
    if getent group docker &>/dev/null; then
        as_root usermod -aG docker "$TARGET_USER" 2>/dev/null || true
        log_success "Added $TARGET_USER to docker group"
    fi

    # Check for passwordless sudo
    if as_root grep -q "^${TARGET_USER}.*NOPASSWD" /etc/sudoers 2>/dev/null; then
        log_success "Passwordless sudo already configured"
    else
        log_warn "Passwordless sudo not detected - some operations may prompt"
    fi

    log_success "User setup complete"
}

# ============================================================
# Phase 3: Filesystem Setup
# ============================================================

phase3_filesystem() {
    log_step "3/6" "Setting up filesystem..."

    # Create directories
    mkdir -p "$TARGET_HOME/projects"
    mkdir -p "$TARGET_HOME/dev"
    mkdir -p "$DEVENV_HOME"
    mkdir -p "$TARGET_HOME/.local/bin"
    mkdir -p "$TARGET_HOME/.config/ghostty"
    mkdir -p "$TARGET_HOME/.claude/hooks"

    log_success "Directories created"
}

# ============================================================
# Phase 4: Shell Setup (zsh + Oh My Zsh + Powerlevel10k)
# ============================================================

phase4_shell_setup() {
    log_step "4/6" "Setting up shell environment..."

    # Install Oh My Zsh (unattended)
    if [[ ! -d "$TARGET_HOME/.oh-my-zsh" ]]; then
        log_info "Installing Oh My Zsh..."
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        log_success "Oh My Zsh already installed"
    fi

    # Install Powerlevel10k theme
    local p10k_dir="$TARGET_HOME/.oh-my-zsh/custom/themes/powerlevel10k"
    if [[ ! -d "$p10k_dir" ]]; then
        log_info "Installing Powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
    else
        log_success "Powerlevel10k already installed"
    fi

    # Install zsh-autosuggestions
    local autosuggestions_dir="$TARGET_HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    if [[ ! -d "$autosuggestions_dir" ]]; then
        log_info "Installing zsh-autosuggestions..."
        git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$autosuggestions_dir"
    else
        log_success "zsh-autosuggestions already installed"
    fi

    # Install zsh-syntax-highlighting
    local syntax_dir="$TARGET_HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    if [[ ! -d "$syntax_dir" ]]; then
        log_info "Installing zsh-syntax-highlighting..."
        git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$syntax_dir"
    else
        log_success "zsh-syntax-highlighting already installed"
    fi

    # Copy configuration files
    log_info "Installing shell configuration..."

    mkdir -p "$DEVENV_HOME/zsh"
    cp "$SCRIPT_DIR/config/zsh/devenv.zshrc" "$DEVENV_HOME/zsh/"
    cp "$SCRIPT_DIR/config/zsh/p10k.zsh" "$DEVENV_HOME/zsh/"
    cp "$SCRIPT_DIR/config/zsh/aliases.zsh" "$DEVENV_HOME/zsh/"

    # Create symlinks
    ln -sf "$DEVENV_HOME/zsh/devenv.zshrc" "$TARGET_HOME/.zshrc"
    ln -sf "$DEVENV_HOME/zsh/p10k.zsh" "$TARGET_HOME/.p10k.zsh"

    # Change default shell to zsh
    if [[ "$SHELL" != "$(which zsh)" ]]; then
        log_info "Changing default shell to zsh..."
        as_root chsh -s "$(which zsh)" "$TARGET_USER"
    fi

    log_success "Shell setup complete"
}

# ============================================================
# Phase 5: CLI Tools
# ============================================================

phase5_cli_tools() {
    log_step "5/6" "Installing CLI tools..."

    # Install modern CLI tools via apt
    local apt_packages=(
        ripgrep
        tmux
        fzf
        direnv
        git-lfs
    )

    as_root apt-get install -y "${apt_packages[@]}" || true

    # Install lsd (may need to try multiple methods)
    if ! has_cmd lsd; then
        log_info "Installing lsd..."
        as_root apt-get install -y lsd 2>/dev/null || {
            # Fallback: download from GitHub releases
            local lsd_version="1.1.5"
            local lsd_url="https://github.com/lsd-rs/lsd/releases/download/v${lsd_version}/lsd_${lsd_version}_${DEB_ARCH}.deb"
            curl -fsSL "$lsd_url" -o /tmp/lsd.deb && as_root dpkg -i /tmp/lsd.deb && rm /tmp/lsd.deb
        }
    fi

    # Install bat
    if ! has_cmd bat && ! has_cmd batcat; then
        log_info "Installing bat..."
        as_root apt-get install -y bat 2>/dev/null || true
    fi

    # Install fd-find
    if ! has_cmd fd && ! has_cmd fdfind; then
        log_info "Installing fd-find..."
        as_root apt-get install -y fd-find 2>/dev/null || true
    fi

    # Install btop
    if ! has_cmd btop; then
        log_info "Installing btop..."
        as_root apt-get install -y btop 2>/dev/null || true
    fi

    # Install neovim
    if ! has_cmd nvim; then
        log_info "Installing neovim..."
        as_root apt-get install -y neovim 2>/dev/null || true
    fi

    # Install lazygit
    if ! has_cmd lazygit; then
        log_info "Installing lazygit..."
        as_root apt-get install -y lazygit 2>/dev/null || {
            # Fallback installation
            local lazygit_version="0.44.1"
            local lazygit_url="https://github.com/jesseduffield/lazygit/releases/download/v${lazygit_version}/lazygit_${lazygit_version}_Linux_${TARBALL_ARCH}.tar.gz"
            curl -fsSL "$lazygit_url" | tar xz -C /tmp lazygit && \
            as_root mv /tmp/lazygit /usr/local/bin/
        } || true
    fi

    # Install GitHub CLI
    if ! has_cmd gh; then
        log_info "Installing GitHub CLI..."
        as_root apt-get install -y gh 2>/dev/null || true
    fi

    # Copy tmux configuration
    mkdir -p "$DEVENV_HOME/tmux"
    cp "$SCRIPT_DIR/config/tmux/tmux.conf" "$DEVENV_HOME/tmux/"
    ln -sf "$DEVENV_HOME/tmux/tmux.conf" "$TARGET_HOME/.tmux.conf"

    log_success "CLI tools installed"
}

# ============================================================
# Phase 6: AI Agents & Finalization
# ============================================================

phase6_agents_finalization() {
    log_step "6/6" "Setting up AI agents and finalizing..."

    # Install UV (Astral)
    if ! has_cmd uv; then
        log_info "Installing UV (Python package manager)..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
    else
        log_success "UV already installed"
    fi

    # Install Bun
    if ! has_cmd bun && [[ ! -x "$TARGET_HOME/.bun/bin/bun" ]]; then
        log_info "Installing Bun..."
        curl -fsSL https://bun.sh/install | bash
    else
        log_success "Bun already installed"
    fi

    # Source bun for this session
    export BUN_INSTALL="$TARGET_HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"

    # Check Claude Code (should already be installed)
    if [[ -x "$TARGET_HOME/.local/bin/claude" ]]; then
        log_success "Claude Code already installed"
    else
        log_warn "Claude Code not found - install manually with:"
        log_info "  curl -fsSL https://claude.ai/install.sh | bash"
    fi

    # Install Codex CLI via Bun
    if [[ -x "$TARGET_HOME/.bun/bin/bun" ]]; then
        log_info "Installing Codex CLI..."
        "$TARGET_HOME/.bun/bin/bun" install -g --trust @openai/codex@latest || {
            log_warn "Codex CLI installation failed - you can install manually later"
        }
    fi

    # Install Claude Code hooks
    log_info "Installing Claude Code hooks..."
    mkdir -p "$TARGET_HOME/.claude/hooks"
    cp "$SCRIPT_DIR/config/claude/hooks/git_safety_guard.py" "$TARGET_HOME/.claude/hooks/"
    chmod +x "$TARGET_HOME/.claude/hooks/git_safety_guard.py"

    # Only install settings.json if it doesn't exist (preserve user settings)
    if [[ ! -f "$TARGET_HOME/.claude/settings.json" ]]; then
        cp "$SCRIPT_DIR/config/claude/settings.json" "$TARGET_HOME/.claude/"
    else
        log_info "Claude settings.json exists - not overwriting"
    fi

    # Install Ghostty configuration
    log_info "Installing Ghostty configuration..."
    cp "$SCRIPT_DIR/config/ghostty/config" "$TARGET_HOME/.config/ghostty/config"

    # Copy DGX utilities
    mkdir -p "$DEVENV_HOME/scripts/lib"
    cp "$SCRIPT_DIR/scripts/lib/dgx.sh" "$DEVENV_HOME/scripts/lib/"

    # Create VERSION file
    echo "$VERSION" > "$DEVENV_HOME/VERSION"

    log_success "AI agents and configuration complete"
}

# ============================================================
# Main Installation Flow
# ============================================================

main() {
    local dry_run=false
    local skip_phases=()

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                show_help
                exit 0
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --skip-phase)
                skip_phases+=("$2")
                shift 2
                ;;
            --user)
                TARGET_USER="$2"
                TARGET_HOME="/home/$TARGET_USER"
                DEVENV_HOME="$TARGET_HOME/.devenv"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Header
    echo ""
    echo "=============================================="
    echo "  Linux Dev Autoconfig v${VERSION}"
    echo "  Development Environment Setup"
    echo "=============================================="
    echo ""

    if [[ "$dry_run" == "true" ]]; then
        log_warn "DRY RUN MODE - No changes will be made"
        echo ""
    fi

    # Pre-flight checks
    check_not_root

    # Source system utilities for preflight (optional - only on supported hardware)
    if [[ -f "$SCRIPT_DIR/scripts/lib/dgx.sh" ]]; then
        source "$SCRIPT_DIR/scripts/lib/dgx.sh"
        # Only run DGX-specific preflight on ARM64 systems (likely DGX Spark)
        if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
            dgx_preflight || log_warn "Some preflight checks failed - continuing anyway"
        fi
    fi

    echo ""

    # Run phases
    local phases=(
        "phase1_base_dependencies"
        "phase2_user_setup"
        "phase3_filesystem"
        "phase4_shell_setup"
        "phase5_cli_tools"
        "phase6_agents_finalization"
    )

    for i in "${!phases[@]}"; do
        local phase_num=$((i + 1))
        if [[ " ${skip_phases[*]} " =~ " ${phase_num} " ]]; then
            log_warn "Skipping phase $phase_num"
            continue
        fi

        if [[ "$dry_run" == "true" ]]; then
            log_info "Would run: ${phases[$i]}"
        else
            ${phases[$i]}
        fi
        echo ""
    done

    # Success message
    echo "=============================================="
    log_success "Linux Dev Autoconfig installation complete!"
    echo "=============================================="
    echo ""
    echo "Next steps:"
    echo "  1. Start a new terminal or run: exec zsh"
    echo "  2. Run 'devenv info' to verify setup"
    echo "  3. Run 'codex login' to authenticate Codex CLI"
    echo ""
    echo "Useful commands:"
    echo "  ls          - List files with icons (lsd)"
    echo "  ccd         - Claude Code (dangerously enabled)"
    echo "  cod         - Codex CLI (dangerously enabled)"
    echo "  uca         - Update agent CLIs"
    echo "  devenv      - Development environment utilities"
    echo ""
}

# Run main
main "$@"
