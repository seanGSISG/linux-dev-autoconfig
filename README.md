# Linux Dev Autoconfig

One-liner setup for a complete Linux development environment.

```bash
curl -fsSL https://raw.githubusercontent.com/seanGSISG/linux-dev-autoconfig/main/install.sh | bash
```

**Supports:** x86_64 and ARM64 (auto-detected)

## What Gets Installed

### Modern CLI Tools

| Tool | Replaces | Features |
|------|----------|----------|
| `lsd` | `ls` | Icons, colors, tree view |
| `bat` | `cat` | Syntax highlighting |
| `ripgrep` | `grep` | 10x faster, respects .gitignore |
| `fd` | `find` | Simpler syntax, faster |
| `btop` | `top` | Beautiful resource monitor |
| `duf` | `df` | Modern disk usage |
| `ncdu` | `du` | Interactive disk analyzer |
| `lazygit` | `git` | Beautiful git TUI |

### Shell Setup
- Zsh with Oh My Zsh
- Powerlevel10k theme (lean)
- zsh-autosuggestions
- zsh-syntax-highlighting

### Networking
- Tailscale (VPN mesh)
- mosh (resilient SSH)

### AI Agents
- Claude Code
- OpenAI Codex CLI
- UV (Python package manager)
- Bun (JavaScript runtime)

### Configs Applied
- `~/.zshrc` - Shell config
- `~/.p10k.zsh` - Prompt theme
- `~/.devenv/zsh/aliases.zsh` - Aliases
- `~/.tmux.conf` - Tmux config
- `~/.config/ghostty/config` - Terminal config

## Key Aliases

| Alias | Description |
|-------|-------------|
| `ls`, `ll`, `la` | lsd with icons |
| `cat` | bat with syntax highlighting |
| `lg` | lazygit |
| `ccd` | Claude Code (dangerous mode) |
| `cod` | Codex (dangerous mode) |

## Architecture

```
Fresh Ubuntu/Debian
        │
        ▼
┌─────────────────────────────────┐
│  linux-dev-autoconfig           │  ← Self-contained
│  • CLI tools                    │
│  • Shell + plugins              │
│  • Configs (zsh, tmux, etc.)    │
│  • AI agents                    │
└─────────────────────────────────┘
        │
        ▼ (optional, prompted)
┌─────────────────────────────────┐
│  dotfiles (via chezmoi + age)   │  ← Requires age key
│  • SSH config (encrypted)       │
│  • Claude knowledge base        │
└─────────────────────────────────┘
```

## Private Dotfiles (Optional)

At the end of setup, you're prompted to set up private configs. This requires your age decryption key from Bitwarden ("Dotfiles Age Key").

**What you get:**
- Pre-configured SSH hosts
- Claude Code knowledge base for your homelab

**Skip if:**
- Setting up a shared/temporary machine
- You don't have the age key handy

## Post-Install

```bash
exec zsh              # Start new shell
sudo tailscale up     # Connect VPN
claude login          # Auth Claude Code
```

## The `devenv` Command

After installation, use the `devenv` command to manage your environment:

```bash
devenv doctor    # Check system health and tool status
devenv update    # Update tools and configs to latest
devenv info      # Quick system overview (hostname, GPU, tools)
devenv version   # Show version
devenv help      # Show help
```

### Update Options

```bash
devenv update            # Update everything
devenv update --configs  # Update configs only
devenv update --tools    # Update CLI tools only
devenv update --agents   # Update AI agents only
```

## Manual Config Updates

Configs are stored in `~/.devenv/config/`. To manually update:

```bash
cd ~/.devenv
git pull
devenv update --configs
```

## Requirements

- Debian/Ubuntu-based Linux
- Sudo access
- Internet connection

## Documentation

| Document | Description |
|----------|-------------|
| [docs/tools.md](docs/tools.md) | All installed tools with usage |
| [docs/aliases.md](docs/aliases.md) | Complete alias reference |
| [docs/keybindings.md](docs/keybindings.md) | Keyboard shortcuts |
