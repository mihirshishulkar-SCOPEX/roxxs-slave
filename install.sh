#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ROXX'S SLAVE — SELF-HEALING ONE-COMMAND INSTALLER v777                     ║
# ║  curl -sSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/        ║
# ║            roxxs-slave/main/install.sh | bash                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
R=$'\e[1;31m'; G=$'\e[1;32m'; Y=$'\e[1;33m'; C=$'\e[1;36m'; NC=$'\e[0m'; W=$'\e[1;37m'

banner() {
printf "${R}
██████╗  ██████╗ ██╗  ██╗██╗  ██╗    ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗
██╔══██╗██╔═══██╗╚██╗██╔╝╚██╗██╔╝    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║
██████╔╝██║   ██║ ╚███╔╝  ╚███╔╝     ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║
██╔══██╗██║   ██║ ██╔██╗  ██╔██╗     ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║
██║  ██║╚██████╔╝██╔╝ ██╗██╔╝ ██╗    ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗
╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝    ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝
${NC}"
printf "${R}  ╔═══════════════════════════════════════════════════════╗${NC}\n"
printf "${R}  ║  SELF-HEALING INSTALLER v777 — DEVILISH EDITION       ║${NC}\n"
printf "${R}  ║  After install: type  devil target.com                ║${NC}\n"
printf "${R}  ╚═══════════════════════════════════════════════════════╝${NC}\n\n"
}

log()     { printf "${G}[✓]${NC} %s\n" "$*"; }
warn()    { printf "${Y}[!]${NC} %s\n" "$*"; }
err()     { printf "${R}[✗]${NC} %s\n" "$*"; }
fixing()  { printf "${C}[⚙]${NC} AUTO-FIX: %s\n" "$*"; }
step()    { printf "\n${R}━━━ %s ${NC}\n" "$*"; }

banner

# ── Detect OS + package manager ───────────────────────────────────────────────
OS="$(uname -s)"
ARCH="$(uname -m)"
PKG_MGR=""
if command -v apt-get &>/dev/null; then PKG_MGR="apt"
elif command -v yum &>/dev/null;     then PKG_MGR="yum"
elif command -v pacman &>/dev/null;  then PKG_MGR="pacman"
elif command -v brew &>/dev/null;    then PKG_MGR="brew"
fi
log "System: $OS / $ARCH / pkg=$PKG_MGR"

INSTALL_DIR="$HOME/.roxx-slave"
BIN_DIR="/usr/local/bin"
# If no write access to /usr/local/bin, use ~/bin
if [[ ! -w "$BIN_DIR" ]]; then
  BIN_DIR="$HOME/bin"
  mkdir -p "$BIN_DIR"
fi
FINDINGS_DIR="$HOME/findings"
DASHBOARD_DIR="$HOME/roxx-dashboard"
RAW="https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main"
REPO="https://github.com/mihirshishulkar-SCOPEX/roxxs-slave"

mkdir -p "$INSTALL_DIR" "$FINDINGS_DIR" "$DASHBOARD_DIR"

# ── Self-healing system package install ───────────────────────────────────────
step "SYSTEM PACKAGES"
install_pkg() {
  local pkg="$1"
  case "$PKG_MGR" in
    apt)    apt-get install -y -q "$pkg" 2>/dev/null && log "$pkg installed" || warn "Could not install $pkg" ;;
    yum)    yum install -y -q "$pkg" 2>/dev/null && log "$pkg installed" || warn "Could not install $pkg" ;;
    pacman) pacman -S --noconfirm --quiet "$pkg" 2>/dev/null && log "$pkg installed" || warn "Could not install $pkg" ;;
    brew)   brew install "$pkg" 2>/dev/null && log "$pkg installed" || warn "Could not install $pkg" ;;
    *)      warn "Cannot auto-install $pkg — no supported package manager" ;;
  esac
}

SYS_PKGS=(curl wget git python3 python3-pip nmap masscan hydra \
           nikto whatweb feroxbuster ncrack jq unzip tar gzip \
           aircrack-ng hashcat john)
for pkg in "${SYS_PKGS[@]}"; do
  command -v "$pkg" &>/dev/null || { fixing "Installing $pkg..."; install_pkg "$pkg" || true; }
done

# ── Go install (self-healing) ─────────────────────────────────────────────────
step "GO RUNTIME"
install_go() {
  fixing "Installing Go..."
  local GO_VER="1.23.4"
  local GO_URL="https://go.dev/dl/go${GO_VER}.linux-amd64.tar.gz"
  [[ "$ARCH" == "arm64" ]] && GO_URL="https://go.dev/dl/go${GO_VER}.linux-arm64.tar.gz"
  [[ "$OS" == "Darwin" ]] && GO_URL="https://go.dev/dl/go${GO_VER}.darwin-amd64.pkg"
  curl -sSL "$GO_URL" -o /tmp/go.tar.gz 2>/dev/null && \
    rm -rf /usr/local/go && tar -C /usr/local -xzf /tmp/go.tar.gz 2>/dev/null && \
    rm /tmp/go.tar.gz && log "Go installed" || warn "Go install failed"
}
export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin:/root/go/bin:/home/roxx/go/bin"
command -v go &>/dev/null || install_go

# ── Go tools (self-healing — retry on failure) ────────────────────────────────
step "GO BUG BOUNTY TOOLS"
go_install() {
  local tool="$1" pkg="$2"
  if ! command -v "$tool" &>/dev/null; then
    fixing "Installing $tool..."
    for attempt in 1 2 3; do
      GOPATH=$HOME/go go install "$pkg" 2>/dev/null && { log "$tool installed"; return; }
      warn "$tool attempt $attempt failed — retrying..."
      sleep 2
    done
    err "$tool could not be installed — skipping"
  else
    log "$tool already installed"
  fi
}

go_install subfinder   "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
go_install httpx       "github.com/projectdiscovery/httpx/cmd/httpx@latest"
go_install nuclei      "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
go_install naabu       "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
go_install dnsx        "github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
go_install katana      "github.com/projectdiscovery/katana/cmd/katana@latest"
go_install interactsh-client "github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest"
go_install dalfox      "github.com/hahwul/dalfox/v2@latest"
go_install ffuf        "github.com/ffuf/ffuf/v2@latest"
go_install waybackurls "github.com/tomnomnom/waybackurls@latest"
go_install gau         "github.com/lc/gau/v2/cmd/gau@latest"
go_install hakrawler   "github.com/hakluke/hakrawler@latest"
go_install gf          "github.com/tomnomnom/gf@latest"
go_install anew        "github.com/tomnomnom/anew@latest"
go_install qsreplace   "github.com/tomnomnom/qsreplace@latest"
go_install assetfinder "github.com/tomnomnom/assetfinder@latest"
go_install gospider    "github.com/jaeles-project/gospider@latest"
go_install trufflehog  "github.com/trufflesecurity/trufflehog/v3@latest"

# ── Python tools (self-healing) ───────────────────────────────────────────────
step "PYTHON TOOLS"
py_install() {
  local pkg="$1"
  pip3 install "$pkg" --break-system-packages -q 2>/dev/null || \
  pip3 install "$pkg" -q 2>/dev/null || \
  pip install "$pkg" -q 2>/dev/null || \
  warn "pip: $pkg failed"
  command -v "$pkg" &>/dev/null && log "$pkg installed" || true
}
for p in sqlmap arjun uro dirsearch wafw00f; do py_install "$p"; done

# ── Nuclei templates ─────────────────────────────────────────────────────────
step "NUCLEI TEMPLATES"
command -v nuclei &>/dev/null && {
  nuclei -update-templates -silent 2>/dev/null && log "Nuclei templates updated" || warn "Nuclei templates update failed"
}

# ── SecLists wordlists ────────────────────────────────────────────────────────
step "WORDLISTS"
if [[ ! -d "/usr/share/seclists" ]]; then
  fixing "Installing SecLists..."
  install_pkg "seclists" 2>/dev/null || {
    git clone --depth=1 https://github.com/danielmiessler/SecLists.git \
      /usr/share/seclists 2>/dev/null && log "SecLists installed" || warn "SecLists failed"
  }
else
  log "SecLists already present"
fi

# ── Clone/update roxxs-slave repo ────────────────────────────────────────────
step "ROXX'S SLAVE REPO"
if [[ -d "$INSTALL_DIR/.git" ]]; then
  fixing "Updating existing install..."
  git -C "$INSTALL_DIR" pull origin main 2>/dev/null && log "Updated" || warn "git pull failed"
else
  git clone --depth=1 "$REPO" "$INSTALL_DIR" 2>/dev/null && log "Cloned" || {
    fixing "Clone failed — downloading directly..."
    curl -sSL "${RAW}/scripts/hunt.sh" -o "$INSTALL_DIR/hunt.sh" 2>/dev/null || true
    curl -sSL "${RAW}/scripts/roxx-banner.sh" -o "$INSTALL_DIR/roxx-banner.sh" 2>/dev/null || true
  }
fi

# ── Install dashboard ─────────────────────────────────────────────────────────
step "DASHBOARD"
cp -r "$INSTALL_DIR/dashboard/"* "$DASHBOARD_DIR/" 2>/dev/null || {
  fixing "Downloading dashboard from GitHub..."
  mkdir -p "$DASHBOARD_DIR/templates" "$DASHBOARD_DIR/data"
  curl -sSL "${RAW}/dashboard/server.py" -o "$DASHBOARD_DIR/server.py" 2>/dev/null || true
}

# ── Install Flask + SocketIO ──────────────────────────────────────────────────
python3 -c "import flask_socketio" 2>/dev/null || {
  fixing "Installing Flask + SocketIO..."
  pip3 install flask flask-socketio eventlet --break-system-packages -q 2>/dev/null || \
  pip3 install flask flask-socketio eventlet -q 2>/dev/null || true
}

# ── Write the DEVIL master command ────────────────────────────────────────────
step "DEVIL COMMAND (easy launcher)"
cat > "${BIN_DIR}/devil" << 'DEVILCMD'
#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════╗
# ║  ROXX'S SLAVE — DEVIL LAUNCHER                        ║
# ║  Usage: devil <target> [platform] [bounty] [id]       ║
# ║         devil update                                  ║
# ║         devil dashboard                               ║
# ║         devil iot <ip/range>                          ║
# ║         devil help                                    ║
# ╚═══════════════════════════════════════════════════════╝
INSTALL_DIR="$HOME/.roxx-slave"
DASHBOARD_DIR="$HOME/roxx-dashboard"
HUNT="$INSTALL_DIR/scripts/hunt.sh"
IOT="$INSTALL_DIR/scripts/iot-hunt.sh"
BANNER="$INSTALL_DIR/scripts/roxx-banner.sh"
BIN_DIR="/usr/local/bin"
RAW="https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main"
VERSION_URL="${RAW}/VERSION"
VERSION_FILE="$INSTALL_DIR/.version"

R=$'\e[1;31m'; G=$'\e[1;32m'; Y=$'\e[1;33m'; NC=$'\e[0m'

PATH="$PATH:/usr/local/go/bin:$HOME/go/bin:/root/go/bin"
export PATH

# ── Auto-update check (runs every time) ───────────────────────────────────────
auto_update() {
  local remote local_v
  remote=$(curl -sf --max-time 5 "$VERSION_URL" 2>/dev/null | tr -d '[:space:]') || return
  local_v=$(cat "$VERSION_FILE" 2>/dev/null | tr -d '[:space:]') || local_v="0"
  if [[ "$remote" != "$local_v" ]]; then
    printf "${Y}[↑] New version ${remote} available — auto-updating...${NC}\n"
    self_update
  fi
}

# ── Self-healing update ────────────────────────────────────────────────────────
self_update() {
  printf "${G}[⚙] Self-update running...${NC}\n"
  # Try git pull first
  if git -C "$INSTALL_DIR" pull origin main 2>/dev/null; then
    printf "${G}[✓] Updated via git${NC}\n"
  else
    # Fall back to curl download
    printf "${Y}[!] git pull failed — downloading directly...${NC}\n"
    curl -sSL "${RAW}/scripts/hunt.sh" -o "$HUNT" 2>/dev/null && \
    curl -sSL "${RAW}/scripts/roxx-banner.sh" -o "$BANNER" 2>/dev/null && \
    curl -sSL "${RAW}/scripts/iot-hunt.sh" -o "$IOT" 2>/dev/null
    printf "${G}[✓] Updated via direct download${NC}\n"
  fi
  # Refresh nuclei templates
  command -v nuclei &>/dev/null && nuclei -update-templates -silent 2>/dev/null || true
  # Fix permissions
  chmod +x "$HUNT" "$IOT" "$BANNER" 2>/dev/null || true
  # Record version
  curl -sf --max-time 5 "$VERSION_URL" -o "$VERSION_FILE" 2>/dev/null || true
  printf "${G}[✓] ROXX'S SLAVE self-update complete${NC}\n"
}

# ── Self-healing tool check ────────────────────────────────────────────────────
self_heal() {
  local missing=()
  for tool in subfinder httpx nuclei katana dalfox ffuf naabu sqlmap; do
    command -v "$tool" &>/dev/null || missing+=("$tool")
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    printf "${Y}[!] Missing tools: ${missing[*]} — auto-fixing...${NC}\n"
    curl -sSL "${RAW}/install.sh" | bash 2>/dev/null || true
  fi
}

# ── Banner ────────────────────────────────────────────────────────────────────
show_banner() {
  [[ "${ROXX_FAST:-0}" == "1" ]] && return
  bash "$BANNER" 2>/dev/null || printf "${R}☠ ROXX'S SLAVE — DEVILISH v777 ABYSS${NC}\n"
}

# ── Dashboard launcher ────────────────────────────────────────────────────────
start_dashboard() {
  pkill -f "server.py" 2>/dev/null || true
  sleep 1
  python3 "$DASHBOARD_DIR/server.py" &>/tmp/roxx-dashboard.log &
  disown
  sleep 3
  curl -sf http://127.0.0.1:1337/api/stats >/dev/null 2>&1 && \
    printf "${G}[✓] Dashboard LIVE → http://localhost:1337${NC}\n" || \
    printf "${R}[✗] Dashboard failed — check /tmp/roxx-dashboard.log${NC}\n"
}

# ── Help ─────────────────────────────────────────────────────────────────────
show_help() {
printf "${R}
  ╔═══════════════════════════════════════════════════════════════╗
  ║  ROXX'S SLAVE — DEVIL COMMAND REFERENCE                      ║
  ╠═══════════════════════════════════════════════════════════════╣
  ║  devil <target>                  Full 25-phase hunt           ║
  ║  devil <target> <platform>       Hunt on specific platform    ║
  ║  devil <target> H1 5000 t001     Full args (target/plat/\$)   ║
  ║                                                               ║
  ║  devil dashboard                 Launch live dashboard :1337  ║
  ║  devil iot <ip/range>            IoT + wireless hunt          ║
  ║  devil update                    Force self-update            ║
  ║  devil heal                      Fix broken tools             ║
  ║  devil help                      Show this menu               ║
  ╠═══════════════════════════════════════════════════════════════╣
  ║  EXAMPLES:                                                    ║
  ║  devil target.com                                             ║
  ║  devil target.com HackerOne 5000                              ║
  ║  devil dashboard                                              ║
  ║  devil iot 192.168.1.0/24                                     ║
  ║  devil update                                                 ║
  ╚═══════════════════════════════════════════════════════════════╝
${NC}"
}

# ── Main dispatch ─────────────────────────────────────────────────────────────
CMD="${1:-}"

case "$CMD" in
  "")
    show_help; exit 0 ;;
  "help"|"-h"|"--help")
    show_banner; show_help; exit 0 ;;
  "update"|"--update"|"-u")
    show_banner; self_update; exit 0 ;;
  "heal"|"fix"|"repair")
    printf "${Y}[⚙] Self-healing all tools...${NC}\n"
    curl -sSL "${RAW}/install.sh" | bash; exit 0 ;;
  "dashboard"|"dash"|"ui")
    show_banner; start_dashboard; exit 0 ;;
  "iot"|"wireless"|"rf")
    shift
    show_banner
    auto_update &
    bash "$IOT" "$@"; exit 0 ;;
  "banner"|"roxx")
    bash "$BANNER"; exit 0 ;;
  *)
    # It's a target — run hunt
    show_banner
    # Auto-update silently in background
    auto_update &
    UPDATE_PID=$!
    # Self-heal check
    self_heal
    # Run hunt
    bash "$HUNT" "$@"
    wait $UPDATE_PID 2>/dev/null || true
    ;;
esac
DEVILCMD

chmod +x "${BIN_DIR}/devil"
log "'devil' command installed at ${BIN_DIR}/devil"

# ── Symlinks for even easier access ──────────────────────────────────────────
ln -sf "${BIN_DIR}/devil" "${BIN_DIR}/hunt"   2>/dev/null || true
ln -sf "${BIN_DIR}/devil" "${BIN_DIR}/rs"     2>/dev/null || true   # ultra-short
log "Aliases: hunt → devil, rs → devil"

# ── Copy hunt scripts to install dir ─────────────────────────────────────────
step "HUNT SCRIPTS"
mkdir -p "$INSTALL_DIR/scripts"
cp "$INSTALL_DIR/scripts/hunt.sh" "$INSTALL_DIR/scripts/hunt.sh" 2>/dev/null || \
  curl -sSL "${RAW}/scripts/hunt.sh" -o "$INSTALL_DIR/scripts/hunt.sh" 2>/dev/null || true
chmod +x "$INSTALL_DIR/scripts/"*.sh 2>/dev/null || true

# ── ROXX banner on claude/agy/opencode ───────────────────────────────────────
step "SHELL INTEGRATION"
BANNER_SRC="$INSTALL_DIR/scripts/roxx-banner.sh"
for wrapper in claude opencode agy; do
  real=$(command -v "$wrapper" 2>/dev/null || echo "")
  [[ -z "$real" ]] && continue
  # Only wrap if not already wrapped
  head -1 "$real" 2>/dev/null | grep -q "roxx-banner" && continue
  mv "$real" "${real}.real" 2>/dev/null || true
  cat > "$real" << WRAP
#!/usr/bin/env bash
[[ "\${ROXX_FAST:-0}" != "1" ]] && bash "${BANNER_SRC}" 2>/dev/null
exec "${real}.real" "\$@"
WRAP
  chmod +x "$real"
  log "Wrapped: $wrapper"
done

# ── Shell aliases ─────────────────────────────────────────────────────────────
BASHRC="$HOME/.bashrc"
grep -q "ROXX_SLAVE_INSTALL" "$BASHRC" 2>/dev/null || cat >> "$BASHRC" << 'SHELL_ALIASES'

# ═══ ROXX'S SLAVE — AUTO-INSTALLED ═══════════════════════════════════════════
# ROXX_SLAVE_INSTALL
export PATH="/usr/local/bin:$HOME/bin:$HOME/go/bin:/root/go/bin:/usr/local/go/bin:$PATH"
alias devil='devil'                  # Full 25-phase hunt: devil target.com
alias hunt='devil'                   # Same: hunt target.com
alias rs='devil'                     # Ultra-short: rs target.com
alias dashboard='devil dashboard'    # Launch dashboard
alias d-update='devil update'        # Force update
alias d-heal='devil heal'            # Fix broken tools
alias d-iot='devil iot'              # IoT hunt
alias roxx='bash ~/.roxx-slave/scripts/roxx-banner.sh'
# ═════════════════════════════════════════════════════════════════════════════
SHELL_ALIASES

# ── Write VERSION file ────────────────────────────────────────────────────────
echo "777" > "$INSTALL_DIR/.version"
echo "777" > "${BIN_DIR}/.roxx_version" 2>/dev/null || true

# ── Done ──────────────────────────────────────────────────────────────────────
step "DONE"
printf "\n${R}╔═══════════════════════════════════════════════════════════════╗${NC}\n"
printf "${R}║  ☠  ROXX'S SLAVE INSTALLED — DEVILISH v777 ABYSS             ║${NC}\n"
printf "${R}║                                                               ║${NC}\n"
printf "${R}║  COMMANDS (all do the same thing):                            ║${NC}\n"
printf "${R}║  devil target.com          ← Full 25-phase hunt              ║${NC}\n"
printf "${R}║  hunt  target.com          ← Same (alias)                    ║${NC}\n"
printf "${R}║  rs    target.com          ← Ultra-short alias               ║${NC}\n"
printf "${R}║  devil dashboard           ← Live dashboard :1337            ║${NC}\n"
printf "${R}║  devil iot 192.168.1.0/24  ← IoT/wireless hunt               ║${NC}\n"
printf "${R}║  devil update              ← Force update now                ║${NC}\n"
printf "${R}║  devil heal                ← Fix any broken tools            ║${NC}\n"
printf "${R}║                                                               ║${NC}\n"
printf "${R}║  Auto-updates itself on every run.                           ║${NC}\n"
printf "${R}║  Self-heals broken tools automatically.                      ║${NC}\n"
printf "${R}║                                                               ║${NC}\n"
printf "${R}║  Run: source ~/.bashrc && devil help                         ║${NC}\n"
printf "${R}╚═══════════════════════════════════════════════════════════════╝${NC}\n\n"

source "$HOME/.bashrc" 2>/dev/null || true
