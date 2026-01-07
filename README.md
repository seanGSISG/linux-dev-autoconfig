# Linux Dev Autoconfig

Automated development environment setup for **Linux systems** (Debian/Ubuntu). Provides a modern shell environment optimized for Python and AI development.

**Supports:** x86_64 and ARM64 architectures (auto-detected)

## Quick Start

**One-liner install:**
```bash
curl -fsSL https://raw.githubusercontent.com/seanGSISG/linux-dev-autoconfig/main/install.sh | bash
```

When prompted, you can optionally set up private configs (SSH, Claude knowledge base) by pasting your age decryption key from Bitwarden.

**After installation:**
```bash
exec zsh                    # Start new shell
sudo tailscale up           # Connect VPN (first time)
claude login                # Authenticate Claude Code
```

## How It Works

This installer uses a **two-stage approach**:

```
Stage 1: Bootstrap (this repo)
├── Install minimal deps (git, curl, age)
└── Install chezmoi

Stage 2: Dotfiles (seanGSISG/dotfiles)
├── Apply shell configs (zsh, p10k, aliases)
├── Decrypt private configs (SSH, Claude knowledge)
└── Run tool installation script
```

### With Private Configs (Recommended)
If you have the age decryption key, you get:
- Pre-configured SSH hosts
- Claude Code with full homelab knowledge
- All sensitive configs decrypted and ready

### Without Private Configs
Still installs all the tools - just skip when prompted for the key.

## Features

- **Shell**: zsh + Oh My Zsh + Powerlevel10k (lean theme)
- **CLI Tools**: lsd, bat, ripgrep, fzf, fd, btop, lazygit, neovim, ncdu, duf
- **VPS/Remote**: Tailscale (VPN), mosh (resilient SSH), tmux
- **Python**: UV (Astral) for fast venv/package management
- **AI Agents**: Claude Code + Codex CLI (with "vibe mode" aliases)
- **Configs**: Ghostty terminal, tmux, Claude Code git safety hooks

## Installed Tools

### Modern CLI Replacements

| Tool | Replaces | Features |
|------|----------|----------|
| `lsd` | `ls` | Icons, colors, tree view |
| `bat` | `cat` | Syntax highlighting |
| `ripgrep` | `grep` | 10x faster, respects .gitignore |
| `fd` | `find` | Simpler syntax, faster |
| `btop` | `top` | Beautiful resource monitor |
| `duf` | `df` | Modern disk usage |
| `ncdu` | `du` | Interactive disk analyzer |

### VPS & Remote Access

| Tool | Purpose |
|------|---------|
| `Tailscale` | VPN mesh networking - secure access without opening ports |
| `mosh` | Mobile shell - survives disconnects and roaming |
| `tmux` | Terminal multiplexer - persistent sessions |

### Key Aliases

| Alias | Description |
|-------|-------------|
| `ts` | Tailscale status |
| `tsup` | Connect to Tailscale |
| `ccd` | Claude Code (dangerous mode) |
| `lg` | Lazygit TUI |
| `help` | Simplified man pages (tldr) |

## Private Configs (Age Encryption)

Sensitive files are encrypted with [age](https://github.com/FiloSottile/age) and stored in the [dotfiles repo](https://github.com/seanGSISG/dotfiles):

| File | Contains |
|------|----------|
| `~/.ssh/config` | SSH hosts, IP addresses |
| `~/dev/claude-home/SSH.md` | Homelab documentation |

To decrypt, you need the age key stored in Bitwarden ("Dotfiles Age Key").

## Manual Setup

If the one-liner doesn't work:

```bash
# 1. Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)"

# 2. Save your age key
mkdir -p ~/.config/chezmoi
echo "AGE-SECRET-KEY-1..." > ~/.config/chezmoi/key.txt
chmod 600 ~/.config/chezmoi/key.txt

# 3. Initialize and apply
~/.local/bin/chezmoi init --apply seanGSISG/dotfiles
```

## Updating

```bash
chezmoi update    # Pull latest dotfiles and apply
```

## Requirements

- Debian/Ubuntu-based Linux (apt package manager)
- x86_64 or ARM64 architecture
- Sudo access
- Internet connection

## Documentation

| Document | Description |
|----------|-------------|
| [docs/tools.md](docs/tools.md) | All installed tools with usage examples |
| [docs/aliases.md](docs/aliases.md) | Complete shell alias reference |
| [docs/keybindings.md](docs/keybindings.md) | Ghostty, tmux, and shell shortcuts |

## License

MIT License
