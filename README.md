# Linux Dev Autoconfig

Automated development environment setup for **Linux systems** (Debian/Ubuntu). Provides a modern shell environment optimized for Python and AI development.

**Supports:** x86_64 and ARM64 architectures (auto-detected)

## Features

- **Shell**: zsh + Oh My Zsh + Powerlevel10k (lean theme)
- **CLI Tools**: lsd, bat, ripgrep, fzf, fd, btop, lazygit, neovim
- **Python**: UV (Astral) for fast venv/package management
- **AI Agents**: Claude Code + Codex CLI (with "vibe mode" aliases)
- **Configs**: Ghostty terminal, tmux, Claude Code git safety hooks

## Quick Start

**One-liner install:**
```bash
curl -fsSL https://raw.githubusercontent.com/seanGSISG/linux-dev-autoconfig/main/install.sh | bash
```

**Or clone and run:**
```bash
git clone https://github.com/seanGSISG/linux-dev-autoconfig.git
cd linux-dev-autoconfig
./install.sh
exec zsh
```

## Installation Phases

| Phase | Description |
|-------|-------------|
| 1 | Base dependencies (apt packages, zsh) |
| 2 | User setup (permissions, groups) |
| 3 | Filesystem (directories, configs) |
| 4 | Shell setup (Oh My Zsh, Powerlevel10k, plugins) |
| 5 | CLI tools (lsd, bat, ripgrep, tmux, etc.) |
| 6 | AI agents (UV, Bun, Codex CLI, hooks) |

## Key Customizations

### Minimal `ls` Output (lsd)

By default, `ls` shows only **icons + names** (no dates, sizes, permissions):

```bash
alias ls='lsd --icon=always'      # Minimal: icons + names only
alias ll='lsd -l --icon=always'   # Long format when needed
alias la='lsd -la --icon=always'  # All files with long format
```

### Agent Aliases ("Vibe Mode")

```bash
ccd   # Claude Code with --dangerously-skip-permissions
cod   # Codex CLI with --dangerously-bypass-approvals-and-sandbox
uca   # Update all agent CLIs
```

### Ghostty Keybindings

| Action | Keybinding |
|--------|------------|
| New tab | Ctrl+Shift+T |
| Close tab | Ctrl+Shift+W |
| Next/prev tab | Ctrl+Tab / Ctrl+Shift+Tab |
| Split right | Ctrl+Shift+D |
| Split down | Ctrl+Shift+E |
| Navigate splits | Ctrl+Shift+H/J/K/L |
| Font size +/- | Ctrl++/- |
| Reset font | Ctrl+0 |

## Directory Structure

```
~/.devenv/             # Main config directory
  zsh/
    devenv.zshrc       # Main shell config
    p10k.zsh           # Powerlevel10k config
  tmux/
    tmux.conf          # Tmux config
  scripts/lib/
    dgx.sh             # System utilities

~/.config/ghostty/     # Ghostty terminal config
~/.claude/             # Claude Code config
  hooks/
    git_safety_guard.py  # Git safety hook
```

## Commands

### devenv CLI

```bash
devenv info      # Show system info (GPU, CUDA, tools)
devenv doctor    # Check system health
devenv update    # Update tools
devenv version   # Show version
devenv help      # Show help
```

### Common Aliases

| Alias | Command |
|-------|---------|
| `gs` | `git status` |
| `gd` | `git diff` |
| `lg` | `lazygit` |
| `dev` | `cd ~/dev` |

## Requirements

- Debian/Ubuntu-based Linux (apt package manager)
- x86_64 or ARM64 architecture
- Sudo access
- Internet connection

## License

MIT License

---

Originally adapted from [WSL2-AI-AUTOCONFIG](https://github.com/seanGSISG/WSL2-AI-AUTOCONFIG).
