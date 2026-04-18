#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ─── Constants ───────────────────────────────────────────────────────────────
DOTFILES_DIR="$HOME/dotfiles"
SHELL_MARKER="# >>> dotfiles bootstrap <<<"
SHELL_MARKER_END="# <<< dotfiles bootstrap >>>"

# ─── Logging ─────────────────────────────────────────────────────────────────
log_info()    { printf '  \033[34m[INFO]\033[0m  %s\n' "$*"; }
log_ok()      { printf '  \033[32m[ OK ]\033[0m  %s\n' "$*"; }
log_warn()    { printf '  \033[33m[WARN]\033[0m  %s\n' "$*"; }
log_skip()    { printf '  \033[90m[SKIP]\033[0m  %s\n' "$*"; }
log_error()   { printf '  \033[31m[ERR ]\033[0m  %s\n' "$*" >&2; exit 1; }
log_section() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }

# ─── Temp dir cleanup ────────────────────────────────────────────────────────
_TMP_DIRS=()
_cleanup() {
  for d in "${_TMP_DIRS[@]+"${_TMP_DIRS[@]}"}"; do
    [[ -d "$d" ]] && rm -rf "$d"
  done
}
trap _cleanup EXIT

_mktemp_dir() {
  local d
  d=$(mktemp -d)
  _TMP_DIRS+=("$d")
  printf '%s' "$d"
}

# ─── Utilities ───────────────────────────────────────────────────────────────
has() { command -v "$1" &>/dev/null; }

sha256() {
  if [[ "$OS" == "macos" ]]; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    sha256sum "$1" | awk '{print $1}'
  fi
}

verify_sha256() {
  local file="$1" expected="$2" label="${3:-$1}"
  local actual
  actual=$(sha256 "$file")
  if [[ "$actual" != "$expected" ]]; then
    log_error "SHA256 mismatch for $label\n  expected: $expected\n  actual:   $actual"
  fi
  log_ok "SHA256 verified: $label"
}

# ─── Environment detection ───────────────────────────────────────────────────
OS=""
ARCH=""
IS_SSH=false
IS_HEADLESS=false

detect_env() {
  log_section "Detecting environment"

  case "$(uname -s)" in
    Darwin) OS="macos" ;;
    Linux)  OS="linux" ;;
    *)      log_error "Unsupported OS: $(uname -s)" ;;
  esac

  case "$(uname -m)" in
    x86_64)         ARCH="x64" ;;
    arm64|aarch64)  ARCH="arm64" ;;
    *)              log_error "Unsupported arch: $(uname -m)" ;;
  esac

  if [[ -n "${SSH_CLIENT:-}" || -n "${SSH_TTY:-}" || -n "${SSH_CONNECTION:-}" ]]; then
    IS_SSH=true
  fi

  log_info "OS=$OS  ARCH=$ARCH  IS_SSH=$IS_SSH  IS_HEADLESS=$IS_HEADLESS"
}

# ─── Package helpers ─────────────────────────────────────────────────────────
brew_ensure() {
  local pkg="$1"
  if brew list --formula 2>/dev/null | grep -qx "$pkg"; then
    log_skip "brew: $pkg already installed"
  else
    log_info "brew install $pkg"
    brew install "$pkg"
    log_ok "brew: $pkg installed"
  fi
}

apt_ensure() {
  local pkg="$1"
  local status
  status=$(dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null || true)
  if [[ "$status" == "install ok installed" ]]; then
    log_skip "apt: $pkg already installed"
  else
    log_info "apt install $pkg"
    sudo apt-get install -y -qq "$pkg"
    log_ok "apt: $pkg installed"
  fi
}

# ─── Homebrew ────────────────────────────────────────────────────────────────
install_homebrew() {
  log_section "Homebrew"
  if has brew; then
    log_skip "brew already in PATH"
    return
  fi
  local tmp
  tmp=$(_mktemp_dir)
  log_info "Downloading Homebrew installer..."
  curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$tmp/install.sh"
  bash "$tmp/install.sh"
  # Apple Silicon PATH fix
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  log_ok "Homebrew installed"
}

# ─── zsh ─────────────────────────────────────────────────────────────────────
install_zsh() {
  log_section "zsh"
  if has zsh; then log_skip "zsh already installed"; return; fi
  if [[ "$OS" == "macos" ]]; then brew_ensure zsh
  else apt_ensure zsh; fi
}

install_omz() {
  log_section "oh-my-zsh"
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log_skip "oh-my-zsh already installed"
    return
  fi
  if ! has zsh; then
    log_warn "zsh not installed; skipping oh-my-zsh"
    return
  fi
  log_info "Installing oh-my-zsh (unattended)..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  log_ok "oh-my-zsh installed"
}

set_default_shell() {
  log_section "Default shell"
  local zsh_path
  zsh_path=$(command -v zsh || true)
  if [[ -z "$zsh_path" ]]; then
    log_warn "zsh not found; skipping default shell change"
    return
  fi
  local current
  current=$(getent passwd "$USER" 2>/dev/null | cut -d: -f7)
  if [[ "$current" == "$zsh_path" ]]; then
    log_skip "zsh is already the default shell"
    return
  fi
  log_info "Setting zsh as default shell for $USER..."
  if sudo chsh -s "$zsh_path" "$USER"; then
    log_ok "Default shell set to zsh (effective on next login)"
  else
    log_warn "Could not set default shell. Run manually: chsh -s $zsh_path"
  fi
}

# ─── Stow ────────────────────────────────────────────────────────────────────
install_stow() {
  log_section "stow"
  if has stow; then log_skip "stow already installed"; return; fi
  if [[ "$OS" == "macos" ]]; then brew_ensure stow
  else apt_ensure stow; fi
}

# ─── tmux ────────────────────────────────────────────────────────────────────
install_tmux() {
  log_section "tmux"
  if has tmux; then log_skip "tmux already installed"; return; fi
  if [[ "$OS" == "macos" ]]; then brew_ensure tmux
  else apt_ensure tmux; fi
}

# ─── zoxide ──────────────────────────────────────────────────────────────────
install_zoxide() {
  log_section "zoxide"
  if has zoxide; then log_skip "zoxide already installed"; return; fi

  if [[ "$OS" == "macos" ]]; then
    brew_ensure zoxide
    return
  fi

  # Use zoxide's official install script (installs to ~/.local/bin)
  log_info "Installing zoxide via official install script..."
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
  log_ok "zoxide installed"
}

# ─── Neovim ──────────────────────────────────────────────────────────────────
install_neovim() {
  log_section "Neovim"
  if has nvim; then log_skip "nvim already installed"; return; fi

  if [[ "$OS" == "macos" ]]; then
    brew_ensure neovim
    return
  fi

  local tmp asset_name base_url
  tmp=$(_mktemp_dir)

  if [[ "$ARCH" == "arm64" ]]; then
    asset_name="nvim-linux-arm64.tar.gz"
  else
    asset_name="nvim-linux-x86_64.tar.gz"
  fi

  base_url="https://github.com/neovim/neovim/releases/latest/download"
  log_info "Downloading $asset_name..."
  curl -fsSL "$base_url/$asset_name" -o "$tmp/$asset_name"

  log_info "Installing Neovim to /usr/local..."
  mkdir "$tmp/nvim"
  tar --strip-components=1 -xzf "$tmp/$asset_name" -C "$tmp/nvim"
  sudo cp -r "$tmp/nvim/." /usr/local/
  log_ok "Neovim installed"
}

# ─── lazygit ─────────────────────────────────────────────────────────────────
install_lazygit() {
  log_section "lazygit"
  if has lazygit; then log_skip "lazygit already installed"; return; fi

  if [[ "$OS" == "macos" ]]; then
    brew_ensure lazygit
    return
  fi

  local tmp version arch_name
  tmp=$(_mktemp_dir)

  version=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
    | grep -Po '"tag_name": *"v\K[^"]*')

  if [[ "$ARCH" == "arm64" ]]; then arch_name="arm64"; else arch_name="x86_64"; fi

  log_info "Downloading lazygit $version..."
  curl -Lo "$tmp/lazygit.tar.gz" \
    "https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_${arch_name}.tar.gz"
  tar xf "$tmp/lazygit.tar.gz" -C "$tmp" lazygit
  sudo install "$tmp/lazygit" -D -t /usr/local/bin/
  log_ok "lazygit $version installed"
}

# ─── fnm ─────────────────────────────────────────────────────────────────────
install_fnm() {
  log_section "fnm"
  if has fnm; then log_skip "fnm already installed"; return; fi

  if [[ "$OS" == "macos" ]]; then
    brew_ensure fnm
    return
  fi

  apt_ensure unzip

  local tmp asset_name
  tmp=$(_mktemp_dir)

  if [[ "$ARCH" == "arm64" ]]; then
    asset_name="fnm-arm64.zip"
  else
    asset_name="fnm-linux.zip"
  fi

  local dl_url
  dl_url=$(curl -fsSL https://api.github.com/repos/Schniz/fnm/releases/latest \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(next(a['browser_download_url'] for a in d['assets'] if a['name']=='${asset_name}'))")

  log_info "Downloading $asset_name..."
  curl -fsSL "$dl_url" -o "$tmp/$asset_name"

  mkdir -p "$HOME/.local/bin"
  unzip -q "$tmp/$asset_name" -d "$tmp/fnm_out"
  install -m755 "$tmp/fnm_out/fnm" "$HOME/.local/bin/fnm"

  # Make available in current session
  export PATH="$HOME/.local/bin:$PATH"
  log_ok "fnm installed to ~/.local/bin"
}

# ─── Node ─────────────────────────────────────────────────────────────────────
install_node() {
  log_section "Node.js (LTS)"

  # Ensure fnm is in PATH
  if ! has fnm; then
    if [[ -x "$HOME/.local/bin/fnm" ]]; then
      export PATH="$HOME/.local/bin:$PATH"
    else
      log_error "fnm not found; cannot install Node"
    fi
  fi
  eval "$(fnm env)"

  # Determine latest LTS version
  local lts_version=""
  if has python3; then
    log_info "Fetching latest LTS version from nodejs.org..."
    lts_version=$(curl -fsSL https://nodejs.org/dist/index.json \
      | python3 -c "import sys,json; d=json.load(sys.stdin); print(next(x['version'] for x in d if x.get('lts')))")
    log_info "Latest LTS: $lts_version"
  else
    log_warn "python3 not found — skipping SHA256 pre-verification"
  fi

  # Check if already installed
  if [[ -n "$lts_version" ]] && fnm list 2>/dev/null | grep -qF "$lts_version"; then
    log_skip "Node $lts_version already installed via fnm"
    fnm use "$lts_version"
    fnm default "$lts_version"
    return
  fi

  # Pre-verify tarball if we know the version
  if [[ -n "$lts_version" ]] && has python3; then
    local tmp node_os node_arch asset_name shasums_url dl_url
    tmp=$(_mktemp_dir)

    if [[ "$OS" == "macos" ]]; then node_os="darwin"; else node_os="linux"; fi
    node_arch="$ARCH"  # x64 / arm64 match nodejs naming

    asset_name="node-${lts_version}-${node_os}-${node_arch}.tar.gz"
    dist_base="https://nodejs.org/dist/${lts_version}"

    log_info "Pre-verifying Node tarball SHA256..."
    curl -fsSL "$dist_base/$asset_name"    -o "$tmp/$asset_name"
    curl -fsSL "$dist_base/SHASUMS256.txt" -o "$tmp/SHASUMS256.txt"

    local expected_hash
    expected_hash=$(grep "$asset_name" "$tmp/SHASUMS256.txt" | awk '{print $1}')
    verify_sha256 "$tmp/$asset_name" "$expected_hash" "$asset_name"
  fi

  if [[ -n "$lts_version" ]]; then
    fnm install "$lts_version"
    fnm use "$lts_version"
    fnm default "$lts_version"
    log_ok "Node $lts_version installed and set as default"
  else
    fnm install --lts
    fnm use lts-latest
    fnm default lts-latest
    log_ok "Node LTS installed"
  fi
}

# ─── pnpm ────────────────────────────────────────────────────────────────────
install_pnpm() {
  log_section "pnpm"
  if has pnpm; then log_skip "pnpm already installed"; return; fi

  if ! has node; then
    log_warn "node not in PATH for current session; pnpm may not activate"
  fi

  log_info "Enabling corepack and activating pnpm..."
  corepack enable
  corepack prepare pnpm@latest --activate
  log_ok "pnpm installed via corepack"
}

# ─── ghostty terminfo ────────────────────────────────────────────────────────
install_ghostty_terminfo() {
  log_section "ghostty terminfo"
  if infocmp xterm-ghostty &>/dev/null; then
    log_skip "xterm-ghostty terminfo already installed"
    return
  fi
  apt_ensure ncurses-bin
  log_info "Installing ghostty terminfo..."
  local tmp
  tmp=$(_mktemp_dir)
  curl -fsSL https://raw.githubusercontent.com/ghostty-org/ghostty/main/src/terminfo/ghostty.terminfo \
    -o "$tmp/ghostty.terminfo"
  tic -x "$tmp/ghostty.terminfo"
  log_ok "ghostty terminfo installed"
}

# ─── TPM ─────────────────────────────────────────────────────────────────────
install_tpm() {
  log_section "TPM (Tmux Plugin Manager)"
  local target="$HOME/.config/tmux/plugins/tpm"
  if [[ -d "$target/.git" ]]; then
    log_skip "TPM already cloned at $target"
    return
  fi
  mkdir -p "$(dirname "$target")"
  git clone --depth=1 https://github.com/tmux-plugins/tpm "$target"
  log_ok "TPM cloned"
}

# ─── Stow dotfiles ───────────────────────────────────────────────────────────
stow_dotfiles() {
  log_section "Stow dotfiles"

  local pkgs=("nvim" "tmux")
  if [[ "$IS_SSH" == "false" && "$IS_HEADLESS" == "false" ]]; then
    pkgs+=("ghostty")
  else
    log_skip "ghostty (SSH/VM session)"
  fi

  pushd "$DOTFILES_DIR" >/dev/null
  for pkg in "${pkgs[@]}"; do
    if [[ ! -d "$pkg" ]]; then
      log_warn "Package dir not found, skipping: $pkg"
      continue
    fi
    log_info "stow --restow $pkg"
    if stow --restow "$pkg" 2>&1; then
      log_ok "stowed: $pkg"
    else
      log_warn "stow conflict for $pkg — skipped (manual resolution may be needed)"
    fi
  done
  popd >/dev/null
}

# ─── Shell init ──────────────────────────────────────────────────────────────
configure_shell_init() {
  log_section "Shell init"

  SHELLS=("zsh"      "bash")
  SHELL_RCS=("$HOME/.zshrc" "$HOME/.bashrc")

  local wrote_any=false

  for i in "${!SHELLS[@]}"; do
    local shell="${SHELLS[$i]}"
    local rc="${SHELL_RCS[$i]}"

    [[ -f "$rc" ]] || continue

    if grep -qF "$SHELL_MARKER" "$rc" 2>/dev/null; then
      log_skip "$rc already has bootstrap block"
      wrote_any=true
      continue
    fi

    log_info "Appending bootstrap block to $rc"
    cat >> "$rc" <<BLOCK

$SHELL_MARKER
export PATH="\$HOME/.local/bin:\$PATH"
eval "\$(fnm env --use-on-cd --shell ${shell})"
eval "\$(zoxide init ${shell})"
$SHELL_MARKER_END
BLOCK
    log_ok "Appended to $rc"
    wrote_any=true
  done

  # If neither rc existed, create ~/.zshrc
  if [[ "$wrote_any" == "false" ]]; then
    local rc="$HOME/.zshrc"
    log_info "No rc files found; creating $rc"
    cat > "$rc" <<BLOCK
$SHELL_MARKER
export PATH="\$HOME/.local/bin:\$PATH"
eval "\$(fnm env --use-on-cd --shell zsh)"
eval "\$(zoxide init zsh)"
$SHELL_MARKER_END
BLOCK
    log_ok "Created $rc with bootstrap block"
  fi
}

# ─── Source review ───────────────────────────────────────────────────────────
confirm_sources() {
  local _ok='\033[32m✔ SHA256\033[0m'
  local _no='\033[33m✘ none \033[0m'
  local _apt='\033[34m  apt  \033[0m'
  local _brew='\033[35m  brew \033[0m'

  printf '\n\033[1mExternal sources this script will fetch from:\033[0m\n\n'
  printf '  %-10s  %b  %s\n' "[apt/brew]"  "$_apt"  "system package manager (stow, tmux)"
  if [[ "$OS" == "macos" ]]; then
  printf '  %-10s  %b  %s\n' "[homebrew]"  "$_no"   "raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
  fi
  printf '  %-10s  %b  %s\n' "[omz]"       "$_no"   "raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
  printf '  %-10s  %b  %s\n' "[zoxide]"    "$_no"   "raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh"
  printf '  %-10s  %b  %s\n' "[neovim]"    "$_no"   "github.com/neovim/neovim/releases/latest"
  printf '  %-10s  %b  %s\n' "[lazygit]"   "$_no"   "github.com/jesseduffield/lazygit/releases/latest"
  printf '  %-10s  %b  %s\n' "[fnm]"       "$_no"   "github.com/Schniz/fnm/releases/latest"
  printf '  %-10s  %b  %s\n' "[node]"      "$_ok"   "nodejs.org/dist/ (LTS)"
  printf '  %-10s  %b  %s\n' "[pnpm]"      "$_ok"   "corepack via npm registry (bundled integrity)"
  printf '  %-10s  %b  %s\n' "[tpm]"       "$_no"   "github.com/tmux-plugins/tpm (git clone)"
  printf '\n'
  printf '  \033[32m✔ SHA256\033[0m  checksum verified before install\n'
  printf '  \033[33m✘ none \033[0m  trusted over HTTPS only\n'
  printf '\n'
  printf 'Proceed? [y/N] '
  read -r answer
  [[ "$answer" =~ ^[Yy]$ ]] || { printf 'Aborted.\n'; exit 0; }
  printf '\n'
}

# ─── Main ────────────────────────────────────────────────────────────────────
SKIP_CONFIRM=false

main() {
  detect_env

  if [[ "$SKIP_CONFIRM" == "false" ]]; then
    confirm_sources
  fi

  if [[ "$OS" == "macos" ]]; then
    install_homebrew
  else
    log_section "apt update"
    sudo apt-get update -qq
    apt_ensure curl
  fi

  install_zsh
  install_omz
  install_stow
  install_tmux
  install_zoxide
  install_neovim
  install_lazygit
  install_fnm
  install_node
  install_pnpm
  install_tpm
  if [[ "$IS_HEADLESS" == "true" ]]; then
    install_ghostty_terminfo
  fi
  stow_dotfiles
  configure_shell_init
  set_default_shell

  printf '\n\033[1;32m✓ Bootstrap complete.\033[0m\n'
  printf '  Restart your shell or: source ~/.zshrc / source ~/.bashrc\n\n'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -y|--yes) SKIP_CONFIRM=true ;;
    --vm)     IS_HEADLESS=true ;;
    *) log_error "Unknown argument: $1" ;;
  esac
  shift
done

main
