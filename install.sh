#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ROXX'S SLAVE — ONE-LINE SELF-HEALING INSTALLER v777                        ║
# ║                                                                              ║
# ║  FRESH INSTALL:                                                              ║
# ║    curl -sSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/      ║
# ║           roxxs-slave/main/install.sh | bash                                ║
# ║                                                                              ║
# ║  UPDATE (if already installed):                                              ║
# ║    devil update          ← one command                                       ║
# ║    bash install.sh       ← or re-run installer (safe, idempotent)           ║
# ║                                                                              ║
# ║  AFTER INSTALL:                                                              ║
# ║    devil            → opencode with ROXX animation                           ║
# ║    devil target.com → 25-phase hunt                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

R=$'\e[1;31m'; G=$'\e[1;32m'; Y=$'\e[1;33m'; C=$'\e[1;36m'; NC=$'\e[0m'; W=$'\e[1;37m'

print_banner() {
printf "${R}
██████╗  ██████╗ ██╗  ██╗██╗  ██╗    ██╗███╗  ██╗███████╗████████╗ █████╗ ██╗     ██╗
██╔══██╗██╔═══██╗╚██╗██╔╝╚██╗██╔╝    ██║████╗ ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║
██████╔╝██║   ██║ ╚███╔╝  ╚███╔╝     ██║██╔██╗██║███████╗   ██║   ███████║██║     ██║
██╔══██╗██║   ██║ ██╔██╗  ██╔██╗     ██║██║╚████║╚════██║   ██║   ██╔══██║██║     ██║
██║  ██║╚██████╔╝██╔╝ ██╗██╔╝ ██╗    ██║██║ ╚███║███████║   ██║   ██║  ██║███████╗███████╗
╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝╚═╝  ╚══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝
${NC}${W}  SELF-HEALING INSTALLER v777 — Gets deadlier every time you ask ☠${NC}\n\n"
}

ok()      { printf "${G}  [✓]${NC} %s\n" "$*"; }
warn()    { printf "${Y}  [!]${NC} %s\n" "$*"; }
fixing()  { printf "${C}  [⚙]${NC} AUTO-FIX: %s\n" "$*"; }
step()    { printf "\n${R}  ━━━ %s${NC}\n" "$*"; }

print_banner

REPO="https://github.com/mihirshishulkar-SCOPEX/roxxs-slave"
RAW="https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main"
INSTALL_DIR="$HOME/.roxx-slave"
BIN_DIR="/usr/local/bin"
[[ ! -w "$BIN_DIR" ]] && BIN_DIR="$HOME/bin" && mkdir -p "$BIN_DIR"
DASHBOARD_DIR="$HOME/roxx-dashboard"
FINDINGS_DIR="$HOME/findings"

# ── Detect if update or fresh install ─────────────────────────────────────────
if [[ -d "$INSTALL_DIR/.git" ]]; then
  INSTALL_MODE="update"
  ok "Existing install detected — running UPDATE"
else
  INSTALL_MODE="fresh"
  ok "Fresh install"
fi

mkdir -p "$INSTALL_DIR" "$DASHBOARD_DIR" "$FINDINGS_DIR"
mkdir -p "$FINDINGS_DIR"/{targets,iot,wireless,pocs,reports,secrets,chains,recon}

# ── Detect OS + package manager ───────────────────────────────────────────────
step "DETECTING SYSTEM"
OS="$(uname -s)"; ARCH="$(uname -m)"
PKG_MGR=""
command -v apt-get &>/dev/null && PKG_MGR="apt"
command -v yum     &>/dev/null && PKG_MGR="yum"
command -v pacman  &>/dev/null && PKG_MGR="pacman"
command -v brew    &>/dev/null && PKG_MGR="brew"
ok "$OS / $ARCH / pkg=$PKG_MGR / mode=$INSTALL_MODE"

# ── Install system packages (self-healing) ────────────────────────────────────
step "SYSTEM PACKAGES"
install_sys() {
  local pkg="$1"
  command -v "$pkg" &>/dev/null && { ok "$pkg already present"; return; }
  fixing "Installing $pkg..."
  case "$PKG_MGR" in
    apt)    apt-get install -y -q "$pkg" 2>/dev/null || warn "$pkg apt failed" ;;
    yum)    yum install -y -q "$pkg" 2>/dev/null    || warn "$pkg yum failed" ;;
    pacman) pacman -S --noconfirm "$pkg" 2>/dev/null || warn "$pkg pacman failed" ;;
    brew)   brew install "$pkg" 2>/dev/null          || warn "$pkg brew failed" ;;
    *)      warn "No package manager — skipping $pkg" ;;
  esac
  command -v "$pkg" &>/dev/null && ok "$pkg installed" || warn "$pkg still missing"
}

for p in curl wget git python3 python3-pip nmap masscan hydra \
          nikto whatweb feroxbuster ncrack jq unzip; do
  install_sys "$p"
done

# ── Go runtime ────────────────────────────────────────────────────────────────
step "GO RUNTIME"
export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin:/root/go/bin"
if ! command -v go &>/dev/null; then
  fixing "Installing Go..."
  GO_VER="1.23.4"
  case "$ARCH" in
    x86_64)  GO_TAR="go${GO_VER}.linux-amd64.tar.gz" ;;
    aarch64) GO_TAR="go${GO_VER}.linux-arm64.tar.gz" ;;
    arm64)   GO_TAR="go${GO_VER}.darwin-arm64.tar.gz" ;;
    *)       GO_TAR="go${GO_VER}.linux-amd64.tar.gz" ;;
  esac
  curl -sSL "https://go.dev/dl/${GO_TAR}" -o /tmp/go.tar.gz 2>/dev/null && \
    rm -rf /usr/local/go && \
    tar -C /usr/local -xzf /tmp/go.tar.gz 2>/dev/null && \
    rm -f /tmp/go.tar.gz && ok "Go installed" || warn "Go install failed"
else
  ok "Go $(go version 2>/dev/null | awk '{print $3}')"
fi

# ── Go bug bounty tools (self-healing, 3x retry) ─────────────────────────────
step "GO TOOLS"
go_install() {
  local tool="$1" pkg="$2"
  command -v "$tool" &>/dev/null && { ok "$tool already installed"; return; }
  fixing "Installing $tool..."
  local attempt
  for attempt in 1 2 3; do
    GOPATH=$HOME/go GOBIN="$HOME/go/bin" go install "$pkg" 2>/dev/null && \
      { ok "$tool installed"; return; }
    warn "$tool attempt $attempt/3 failed — retrying..."
    sleep 2
  done
  warn "$tool could not be installed — will self-heal on next run"
}

go_install subfinder          "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
go_install httpx              "github.com/projectdiscovery/httpx/cmd/httpx@latest"
go_install nuclei             "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
go_install naabu              "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
go_install dnsx               "github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
go_install katana             "github.com/projectdiscovery/katana/cmd/katana@latest"
go_install interactsh-client  "github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest"
go_install dalfox             "github.com/hahwul/dalfox/v2@latest"
go_install ffuf               "github.com/ffuf/ffuf/v2@latest"
go_install waybackurls        "github.com/tomnomnom/waybackurls@latest"
go_install gau                "github.com/lc/gau/v2/cmd/gau@latest"
go_install hakrawler          "github.com/hakluke/hakrawler@latest"
go_install gospider           "github.com/jaeles-project/gospider@latest"
go_install gf                 "github.com/tomnomnom/gf@latest"
go_install anew               "github.com/tomnomnom/anew@latest"
go_install qsreplace          "github.com/tomnomnom/qsreplace@latest"
go_install assetfinder        "github.com/tomnomnom/assetfinder@latest"
go_install trufflehog         "github.com/trufflesecurity/trufflehog/v3@latest"

# ── Python tools ──────────────────────────────────────────────────────────────
step "PYTHON TOOLS"
py_install() {
  local pkg="$1"
  pip3 install "$pkg" --break-system-packages -q 2>/dev/null || \
  pip3 install "$pkg" -q 2>/dev/null || \
  pip install  "$pkg" -q 2>/dev/null || true
  ok "$pkg"
}
for p in sqlmap arjun uro wafw00f dirsearch; do py_install "$p"; done

# Flask + SocketIO for dashboard
python3 -c "import flask_socketio" 2>/dev/null || {
  fixing "Installing Flask + SocketIO..."
  pip3 install flask flask-socketio eventlet --break-system-packages -q 2>/dev/null || \
  pip3 install flask flask-socketio eventlet -q 2>/dev/null || true
  ok "Flask + SocketIO"
}

# ── SecLists ──────────────────────────────────────────────────────────────────
step "WORDLISTS"
if [[ ! -d "/usr/share/seclists" ]]; then
  fixing "Installing SecLists..."
  install_sys seclists 2>/dev/null || \
    git clone --depth=1 https://github.com/danielmiessler/SecLists.git \
      /usr/share/seclists 2>/dev/null && ok "SecLists installed" || warn "SecLists failed"
else
  ok "SecLists present"
fi

# ── Clone or update repo ──────────────────────────────────────────────────────
step "ROXX'S SLAVE REPO"
if [[ "$INSTALL_MODE" == "update" ]]; then
  fixing "Pulling latest from GitHub..."
  git -C "$INSTALL_DIR" pull origin main 2>/dev/null && ok "Repo updated" || {
    warn "git pull failed — downloading scripts directly"
    curl -sSL "${RAW}/scripts/hunt.sh"    -o "$INSTALL_DIR/scripts/hunt.sh" 2>/dev/null
    curl -sSL "${RAW}/scripts/iot-hunt.sh" -o "$INSTALL_DIR/scripts/iot-hunt.sh" 2>/dev/null
    ok "Scripts downloaded directly"
  }
else
  git clone --depth=1 "$REPO" "$INSTALL_DIR" 2>/dev/null && ok "Repo cloned" || {
    fixing "Clone failed — downloading scripts directly..."
    mkdir -p "$INSTALL_DIR/scripts" "$INSTALL_DIR/dashboard"
    curl -sSL "${RAW}/scripts/hunt.sh"    -o "$INSTALL_DIR/scripts/hunt.sh" 2>/dev/null
    curl -sSL "${RAW}/scripts/iot-hunt.sh" -o "$INSTALL_DIR/scripts/iot-hunt.sh" 2>/dev/null
    ok "Scripts downloaded directly"
  }
fi
chmod +x "$INSTALL_DIR/scripts/"*.sh 2>/dev/null || true

# ── Install dashboard ─────────────────────────────────────────────────────────
step "DASHBOARD"
cp -r "$INSTALL_DIR/dashboard/." "$DASHBOARD_DIR/" 2>/dev/null || \
  curl -sSL "${RAW}/dashboard/server.py" -o "$DASHBOARD_DIR/server.py" 2>/dev/null || true
ok "Dashboard at $DASHBOARD_DIR"

# ── Nuclei templates ──────────────────────────────────────────────────────────
step "NUCLEI TEMPLATES"
command -v nuclei &>/dev/null && {
  nuclei -update-templates -silent 2>/dev/null && ok "Nuclei templates updated" || warn "Nuclei template update failed"
}

# ── Install DEVIL command ─────────────────────────────────────────────────────
step "DEVIL COMMAND"
curl -sSL "${RAW}/scripts/devil.sh" -o "${BIN_DIR}/devil" 2>/dev/null || \
  cp "$INSTALL_DIR/scripts/devil.sh" "${BIN_DIR}/devil" 2>/dev/null || true
chmod +x "${BIN_DIR}/devil" 2>/dev/null || true
ok "devil installed at ${BIN_DIR}/devil"

# Symlinks
ln -sf "${BIN_DIR}/devil" "${BIN_DIR}/hunt" 2>/dev/null || true
ln -sf "${BIN_DIR}/devil" "${BIN_DIR}/rs"   2>/dev/null || true
ok "Aliases: hunt → devil, rs → devil"

# ── Install ROXX banner ───────────────────────────────────────────────────────
step "ROXX BANNER"
curl -sSL "${RAW}/scripts/roxx-banner" -o "${BIN_DIR}/roxx-banner" 2>/dev/null || \
  cp "$INSTALL_DIR/scripts/roxx-banner.sh" "${BIN_DIR}/roxx-banner" 2>/dev/null || \
  cp "$INSTALL_DIR/scripts/roxx-banner"    "${BIN_DIR}/roxx-banner" 2>/dev/null || true
chmod +x "${BIN_DIR}/roxx-banner" 2>/dev/null || true
ok "roxx-banner installed"

# ── Wrap opencode + claude with animation ────────────────────────────────────
step "SHELL WRAPPERS (opencode / claude)"
wrap_tool() {
  local name="$1" real="$2"
  [[ -z "$real" ]] && return
  # Skip if already wrapped
  head -2 "$real" 2>/dev/null | grep -q "ROXX" && return
  cp "$real" "${real}.real" 2>/dev/null || true
  cat > "$real" << WRAPEOF
#!/usr/bin/env bash
# ROXX'S SLAVE — ${name} launcher (auto-wrapped by install.sh)
[[ -t 1 && -t 0 && "\${DEVIL_LAUNCHED:-0}" != "1" ]] && bash ${BIN_DIR}/roxx-banner 2>/dev/null
exec "${real}.real" "\$@"
WRAPEOF
  chmod +x "$real"
  ok "Wrapped: $name"
}
wrap_tool "opencode" "$(command -v opencode 2>/dev/null)" 2>/dev/null || true
wrap_tool "claude"   "$(command -v claude   2>/dev/null)" 2>/dev/null || true

# ── Shell aliases ─────────────────────────────────────────────────────────────
step "SHELL ALIASES"
BASHRC="$HOME/.bashrc"
grep -q "ROXX_SLAVE_INSTALL" "$BASHRC" 2>/dev/null || cat >> "$BASHRC" << 'ALIASES'

# ═══════════════════════════════════════════════════════════════════════
# ROXX_SLAVE_INSTALL — ROXX'S SLAVE auto-managed aliases
export PATH="/usr/local/bin:$HOME/bin:$HOME/go/bin:/root/go/bin:/usr/local/go/bin:$PATH"
alias devil='devil'
alias hunt='devil'
alias rs='devil'
alias dashboard='devil dashboard'
alias d-update='devil update'
alias d-heal='devil heal'
alias d-iot='devil iot'
alias roxx='bash /usr/local/bin/roxx-banner'
# ═══════════════════════════════════════════════════════════════════════
ALIASES
ok "Aliases added to ~/.bashrc"

# ── AGENTS.md persona ────────────────────────────────────────────────────────
step "PERSONA FILES"
curl -sSL "${RAW}/AGENTS.md" -o "$HOME/AGENTS.md" 2>/dev/null && ok "AGENTS.md installed" || true

# ── VERSION tracking ──────────────────────────────────────────────────────────
step "VERSION"
REMOTE_VER=$(curl -sf --max-time 5 "${RAW}/VERSION" 2>/dev/null | tr -d '[:space:]' || echo "777")
echo "$REMOTE_VER" > "$INSTALL_DIR/.version"
ok "Version: $REMOTE_VER"

# ── DONE ──────────────────────────────────────────────────────────────────────
printf "\n${R}"
printf "╔══════════════════════════════════════════════════════════════════════╗\n"
printf "║  ☠  ROXX'S SLAVE v%s — %s COMPLETE                          ║\n" "$REMOTE_VER" "$([[ $INSTALL_MODE == update ]] && echo UPDATE || echo INSTALL)"
printf "║                                                                      ║\n"
printf "║  COMMANDS:                                                           ║\n"
printf "║    devil               → opencode with full ROXX animation          ║\n"
printf "║    devil target.com    → Full 25-phase devilish hunt                ║\n"
printf "║    hunt  target.com    → Same (alias)                               ║\n"
printf "║    rs    target.com    → Ultra-short alias                          ║\n"
printf "║    devil dashboard     → Live dashboard at http://localhost:1337     ║\n"
printf "║    devil iot <ip>      → IoT + wireless hunt                        ║\n"
printf "║    devil update        → Force self-update                          ║\n"
printf "║    devil heal          → Fix broken tools                           ║\n"
printf "║                                                                      ║\n"
printf "║  Auto-updates on every run. Self-heals broken tools. ☠              ║\n"
printf "║                                                                      ║\n"
printf "║  Run now:  source ~/.bashrc && devil                                 ║\n"
printf "╚══════════════════════════════════════════════════════════════════════╝\n"
printf "${NC}\n"

source "$HOME/.bashrc" 2>/dev/null || true
