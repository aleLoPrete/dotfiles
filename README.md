# Dotfiles

Config for neovim, tmux, ghostty.

## Bootstrap

Clone into `~`:

```bash
git clone git@github.com:aleLoPrete/dotfiles.git ~/dotfiles
```

Run the install script:

```bash
cd ~/dotfiles && bash install.sh
```

The script will show all external sources it fetches from and ask for confirmation before proceeding. To skip:

```bash
bash install.sh --yes
```

### What it installs

| Tool | Method |
|---|---|
| stow, tmux | apt / brew |
| zoxide | official install script |
| neovim | GitHub release + SHA256 verified |
| lazygit | GitHub release |
| fnm | GitHub release |
| node (LTS) | fnm + SHA256 pre-verified |
| pnpm | corepack |
| TPM | git clone |

### What it configures

- Stows `nvim`, `tmux` (and `ghostty` if not on SSH)
- Appends fnm + zoxide init to `~/.zshrc` / `~/.bashrc` with idempotent marker guards

Re-running is safe — everything checks before acting.
