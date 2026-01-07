# CLAUDE.md - Linux Dev Autoconfig

## Project Overview

This repository provides automated development environment setup for **Linux systems** (Debian/Ubuntu). It configures a modern shell environment optimized for Python and AI development.

## Target Systems

| Component | Specification |
|-----------|---------------|
| OS | Debian/Ubuntu-based Linux |
| Architecture | x86_64 or ARM64 (auto-detected) |
| Package Manager | apt |

## Repository Structure

```
linux-dev-autoconfig/
├── install.sh                    # Main installer (6 phases)
├── config/
│   ├── zsh/
│   │   ├── devenv.zshrc         # Main shell configuration
│   │   └── p10k.zsh             # Powerlevel10k theme config
│   ├── tmux/tmux.conf           # Tmux configuration
│   ├── ghostty/config           # Ghostty terminal config
│   └── claude/
│       ├── settings.json        # Claude Code hook settings
│       └── hooks/git_safety_guard.py  # Git safety hook
└── scripts/lib/
    └── dgx.sh                   # System utilities
```

## Installation Phases

1. **Base Dependencies** - apt packages (zsh, curl, git, build-essential)
2. **User Setup** - permissions, docker group
3. **Filesystem** - create ~/projects, ~/.devenv, ~/.claude
4. **Shell Setup** - zsh + Oh My Zsh + Powerlevel10k + plugins
5. **CLI Tools** - lsd, bat, ripgrep, fzf, fd, btop, lazygit, tmux
6. **AI Agents** - UV (Astral), Bun, Codex CLI, Claude Code hooks

## Key Design Decisions

### Architecture Detection
The installer auto-detects system architecture and downloads appropriate binaries:
- x86_64 → amd64 packages
- aarch64/arm64 → arm64 packages

### Minimal ls Output
The `ls` alias uses `lsd --icon=always` for minimal output (icons + names only, no dates/sizes/permissions).

### Agent Configuration
- **Claude Code**: Assumed pre-installed; script configures hooks only
- **Codex CLI**: Installed via Bun (not npm/node)

### Dangerous Mode Aliases
```bash
ccd   # Claude Code with --dangerously-skip-permissions
cod   # Codex CLI with --dangerously-bypass-approvals-and-sandbox
```

### Git Safety Hook
The `git_safety_guard.py` hook blocks destructive git commands:
- `git reset --hard`
- `git push --force` (without --force-with-lease)
- `git clean -f`
- `git checkout .`
- `rm -rf` outside /tmp

## Commands

```bash
./install.sh              # Full installation
./install.sh --dry-run    # Preview without changes
./install.sh --skip-phase N  # Skip specific phase
devenv info               # Show system info
devenv doctor             # Health check
```

## Development Notes

- Scripts support both x86_64 and ARM64 architectures
- Use `as_root` helper instead of direct `sudo` calls
- Fallback installations for tools not in Ubuntu repos (lazygit, lsd)
- Configs are symlinked from ~/.devenv/ to home directory
- Preserve existing ~/.claude/settings.json if present
