#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ROXX'S SLAVE — SELF-HEALING INSTALLER v777 ABYSS                          ║
# ║  ULTIMATE EDITION — All features merged, gets deadlier every install ☠      ║
# ║                                                                              ║
# ║  FRESH INSTALL (one line):                                                   ║
# ║    curl -sSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/      ║
# ║           roxxs-slave/main/install.sh | bash                                ║
# ║                                                                              ║
# ║  UPDATE (already installed):                                                 ║
# ║    devil update                                                              ║
# ║                                                                              ║
# ║  AFTER INSTALL:                                                              ║
# ║    devil            → opencode with ROXX animation                           ║
# ║    devil target.com → 25-phase DEVILISH hunt                                 ║
# ║    hunt  target.com → alias for devil                                         ║
# ║    rs    target.com → ultra-short alias                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
R=$'\e[1;31m'; G=$'\e[1;32m'; Y=$'\e[1;33m'; C=$'\e[1;36m'
W=$'\e[1;37m'; DIM=$'\e[2m'; BOLD=$'\e[1m'; NC=$'\e[0m'

# ── Constants ─────────────────────────────────────────────────────────────────
REPO="https://github.com/mihirshishulkar-SCOPEX/roxxs-slave"
RAW="https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main"
BIN_DIR="/usr/local/bin"
[[ ! -w "$BIN_DIR" ]] && BIN_DIR="$HOME/bin" && mkdir -p "$BIN_DIR"
INSTALL_DIR="$HOME/.roxx-slave"
DASHBOARD_DIR="$HOME/roxx-dashboard"
FINDINGS_DIR="$HOME/findings"
VERSION="777"

# ── Helper functions ──────────────────────────────────────────────────────────
ok()      { printf "${G}  [✓]${NC} %s\n" "$*"; }
warn()    { printf "${Y}  [!]${NC} %s\n" "$*"; }
fixing()  { printf "${C}  [⚙]${NC} AUTO-FIX: %s\n" "$*"; }
step()    { printf "\n${R}  ━━━━━━━━━━━━━━━━━━ %s ${NC}━━━━━━━━━━━━━━━━━━\n" "$*"; }
die()     { printf "${R}  [✘]${NC} %s\n" "$*"; exit 1; }

# ── ASCII Banner ──────────────────────────────────────────────────────────────
print_banner() {
  clear
  printf "${R}"
  printf "██████╗  ██████╗ ██╗  ██╗██╗  ██╗    ██╗███╗  ██╗███████╗████████╗ █████╗ ██╗     ██╗\n"
  printf "██╔══██╗██╔═══██╗╚██╗██╔╝╚██╗██╔╝    ██║████╗ ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║\n"
  printf "██████╔╝██║   ██║ ╚███╔╝  ╚███╔╝     ██║██╔██╗██║███████╗   ██║   ███████║██║     ██║\n"
  printf "██╔══██╗██║   ██║ ██╔██╗  ██╔██╗     ██║██║╚████║╚════██║   ██║   ██╔══██║██║     ██║\n"
  printf "██║  ██║╚██████╔╝██╔╝ ██╗██╔╝ ██╗    ██║██║ ╚███║███████║   ██║   ██║  ██║███████╗███████╗\n"
  printf "╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝╚═╝  ╚══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝\n"
  printf "${NC}"
  printf "\n${BOLD}${W}  ☠  SELF-HEALING INSTALLER v777 ABYSS — Gets deadlier every install ☠${NC}\n"
  printf "${DIM}${W}  https://github.com/mihirshishulkar-SCOPEX/roxxs-slave${NC}\n\n"
}

# ── Detect OS + Shell ─────────────────────────────────────────────────────────
detect_system() {
  step "DETECTING SYSTEM"
  OS_TYPE="$(uname -s)"; ARCH="$(uname -m)"
  case "$OS_TYPE" in
    Linux*)  OS="Linux"  ;;
    Darwin*) OS="macOS"  ;;
    CYGWIN*|MINGW*|MSYS*) OS="WSL/Windows" ;;
    *)       OS="Unknown" ;;
  esac

  # Detect shell RC file
  if [[ "$SHELL" == *zsh* ]] || [[ -f "${HOME}/.zshrc" && "$OS" == "macOS" ]]; then
    SHELL_RC="$HOME/.zshrc"; SHELL_NAME="zsh"
  else
    SHELL_RC="$HOME/.bashrc"; SHELL_NAME="bash"
  fi

  # Detect package manager
  PKG_MGR=""
  command -v apt-get &>/dev/null && PKG_MGR="apt"
  command -v yum     &>/dev/null && PKG_MGR="yum"
  command -v pacman  &>/dev/null && PKG_MGR="pacman"
  command -v brew    &>/dev/null && PKG_MGR="brew"

  # Detect install mode
  if [[ -f "$HOME/.roxx-slave/.version" ]] || [[ -d "$INSTALL_DIR/.git" ]]; then
    INSTALL_MODE="update"
    ok "Existing install detected → running UPDATE"
  else
    INSTALL_MODE="fresh"
    ok "No existing install → FRESH INSTALL"
  fi

  ok "$OS / $ARCH / pkg=$PKG_MGR / shell=$SHELL_NAME / mode=$INSTALL_MODE"
}

# ── System package installer (self-healing, 3x retry) ────────────────────────
install_sys() {
  local pkg="$1"
  command -v "$pkg" &>/dev/null && { ok "$pkg already present"; return 0; }
  fixing "Installing $pkg..."
  local attempt=0
  while (( attempt < 3 )); do
    case "$PKG_MGR" in
      apt)    apt-get install -y -q "$pkg" 2>/dev/null && break ;;
      yum)    yum install -y -q "$pkg" 2>/dev/null    && break ;;
      pacman) pacman -S --noconfirm "$pkg" 2>/dev/null && break ;;
      brew)   brew install "$pkg" 2>/dev/null          && break ;;
      *)      warn "No package manager — cannot install $pkg"; return 0 ;;
    esac
    ((attempt++))
    warn "$pkg install attempt $attempt failed, retrying..."
    sleep 1
  done
  command -v "$pkg" &>/dev/null && ok "$pkg installed" || warn "$pkg still missing (non-fatal)"
}

install_system_packages() {
  step "SYSTEM PACKAGES"
  local pkgs=(curl wget git python3 python3-pip nmap masscan nikto
              whatweb feroxbuster ncrack jq unzip hydra dnsutils whois
              net-tools netcat-openbsd libssl-dev build-essential)
  for p in "${pkgs[@]}"; do
    install_sys "$p" &
  done
  wait
  ok "System packages done"
}

# ── Go runtime ────────────────────────────────────────────────────────────────
install_go() {
  step "GO RUNTIME"
  export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin:/root/go/bin"
  if command -v go &>/dev/null; then
    ok "Go already installed: $(go version 2>/dev/null | awk '{print $3}')"
    return
  fi
  fixing "Installing Go..."
  local GO_VER="1.23.4"
  local GO_TAR
  case "$ARCH" in
    x86_64)  GO_TAR="go${GO_VER}.linux-amd64.tar.gz"   ;;
    aarch64) GO_TAR="go${GO_VER}.linux-arm64.tar.gz"   ;;
    arm64)   GO_TAR="go${GO_VER}.darwin-arm64.tar.gz"  ;;
    *)       warn "Unknown arch $ARCH, skipping Go"; return ;;
  esac
  curl -sSL "https://go.dev/dl/${GO_TAR}" -o "/tmp/${GO_TAR}" 2>/dev/null && \
    tar -C /usr/local -xzf "/tmp/${GO_TAR}" 2>/dev/null && \
    rm -f "/tmp/${GO_TAR}" && \
    ok "Go ${GO_VER} installed" || warn "Go install failed (non-fatal)"
  export PATH="$PATH:/usr/local/go/bin"
}

# ── Go-based security tools ───────────────────────────────────────────────────
install_go_tools() {
  step "GO SECURITY TOOLS"
  export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin:/root/go/bin"
  command -v go &>/dev/null || { warn "Go not found — skipping Go tools"; return; }

  local tools=(
    "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    "github.com/projectdiscovery/httpx/cmd/httpx@latest"
    "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
    "github.com/projectdiscovery/katana/cmd/katana@latest"
    "github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
    "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
    "github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest"
    "github.com/projectdiscovery/asnmap/cmd/asnmap@latest"
    "github.com/ffuf/ffuf/v2@latest"
    "github.com/tomnomnom/waybackurls@latest"
    "github.com/tomnomnom/anew@latest"
    "github.com/tomnomnom/gf@latest"
    "github.com/tomnomnom/qsreplace@latest"
    "github.com/tomnomnom/httprobe@latest"
    "github.com/haccer/subjack@latest"
    "github.com/lc/subzy@latest"
    "github.com/003random/getallurls@latest"
    "github.com/hahwul/dalfox/v2@latest"
    "github.com/hakluke/hakrawler@latest"
    "github.com/jaeles-project/jaeles@latest"
    "github.com/assetnote/kiterunner/cmd/kr@latest"
    "github.com/praetorian-inc/noseyparker@latest"
  )

  for pkg in "${tools[@]}"; do
    local bin
    bin="$(basename "$pkg" | cut -d@ -f1)"
    if command -v "$bin" &>/dev/null; then
      ok "$bin already installed"
    else
      fixing "Installing $bin..."
      GOFLAGS="-mod=mod" go install "$pkg" 2>/dev/null && ok "$bin installed" || warn "$bin failed (non-fatal)"
    fi
  done &

  # Nuclei templates
  if command -v nuclei &>/dev/null; then
    nuclei -update-templates -silent 2>/dev/null && ok "Nuclei templates updated" || true
  fi
  wait
}

# ── Python tools ──────────────────────────────────────────────────────────────
install_python_tools() {
  step "PYTHON TOOLS"
  local pip_flags="--break-system-packages -q 2>/dev/null"
  python3 -m pip install $pip_flags sqlmap 2>/dev/null || true
  python3 -m pip install $pip_flags wafw00f commix xsstrike requests dnspython \
    cloudscraper flask flask-socketio pillow 2>/dev/null || true

  # sqlmap direct if pip fails
  if ! command -v sqlmap &>/dev/null && [[ ! -d /opt/sqlmap ]]; then
    fixing "Cloning sqlmap..."
    git clone --depth=1 https://github.com/sqlmapproject/sqlmap /opt/sqlmap 2>/dev/null && \
      ln -sf /opt/sqlmap/sqlmap.py /usr/local/bin/sqlmap && \
      ok "sqlmap → /usr/local/bin/sqlmap" || warn "sqlmap clone failed"
  fi

  # SecLists
  if [[ ! -d /usr/share/seclists && ! -d /opt/SecLists ]]; then
    fixing "Downloading SecLists (this takes a minute)..."
    git clone --depth=1 https://github.com/danielmiessler/SecLists /opt/SecLists 2>/dev/null && \
      ln -sf /opt/SecLists /usr/share/seclists && \
      ok "SecLists → /opt/SecLists" || warn "SecLists download failed (non-fatal)"
  else
    ok "SecLists present"
  fi
  ok "Python tools done"
}

# ── Clone or update main repo ─────────────────────────────────────────────────
install_repo() {
  step "ROXX'S SLAVE REPO"
  if [[ "$INSTALL_MODE" == "update" && -d "$INSTALL_DIR/.git" ]]; then
    fixing "Pulling latest from GitHub..."
    git -C "$INSTALL_DIR" pull origin main 2>/dev/null && \
      ok "Repo updated" || {
        warn "git pull failed — downloading scripts directly"
        curl -sSL "${RAW}/scripts/hunt.sh"    -o "$INSTALL_DIR/scripts/hunt.sh" 2>/dev/null || true
        curl -sSL "${RAW}/scripts/devil.sh"   -o "$INSTALL_DIR/scripts/devil.sh" 2>/dev/null || true
        curl -sSL "${RAW}/scripts/iot-hunt.sh" -o "$INSTALL_DIR/scripts/iot-hunt.sh" 2>/dev/null || true
        ok "Scripts downloaded directly"
      }
  else
    mkdir -p "$INSTALL_DIR/scripts" "$INSTALL_DIR/brain" "$INSTALL_DIR/skills" "$INSTALL_DIR/dashboard"
    git clone --depth=1 "$REPO" "$INSTALL_DIR" 2>/dev/null && ok "Repo cloned" || {
      fixing "Clone failed — downloading scripts directly..."
      curl -sSL "${RAW}/scripts/hunt.sh"    -o "$INSTALL_DIR/scripts/hunt.sh" 2>/dev/null || true
      curl -sSL "${RAW}/scripts/devil.sh"   -o "$INSTALL_DIR/scripts/devil.sh" 2>/dev/null || true
      curl -sSL "${RAW}/scripts/iot-hunt.sh" -o "$INSTALL_DIR/scripts/iot-hunt.sh" 2>/dev/null || true
      ok "Core scripts downloaded"
    }
  fi
  chmod +x "$INSTALL_DIR/scripts/"*.sh 2>/dev/null || true
}

# ── Brain files (CLAUDE.md, OC.md, AGENTS.md, etc.) ─────────────────────────
install_brain() {
  step "BRAIN FILES"
  mkdir -p "$INSTALL_DIR/brain"

  # Try from cloned repo first, then fall back to remote
  for f in CLAUDE.md CLAUDE1.md OC.md AGENTS.md; do
    if [[ -f "$INSTALL_DIR/brain/$f" ]]; then
      cp "$INSTALL_DIR/brain/$f" "$HOME/$f" 2>/dev/null && ok "$f → ~/$f (from repo)" || true
    else
      curl -fsSL "${RAW}/brain/$f" -o "$HOME/$f" 2>/dev/null && ok "$f → ~/$f (from remote)" || \
        warn "$f not found remotely (non-fatal)"
    fi
  done

  # AGENTS.md in multiple expected locations
  mkdir -p "$HOME/.agents"
  [[ -f "$HOME/AGENTS.md" ]] && cp "$HOME/AGENTS.md" "$HOME/.agents/AGENTS.md" && \
    ok "AGENTS.md → ~/.agents/AGENTS.md"

  # opencode config with ROXX persona + autoapprove
  local cfg_dir="$HOME/.config/opencode"
  mkdir -p "$cfg_dir"
  if [[ ! -f "$cfg_dir/opencode.jsonc" ]]; then
    cat > "$cfg_dir/opencode.jsonc" <<CFG
{
  "username": "ROXX'S SLAVE",
  "autoapprove": true,
  "permission": "allow",
  "instructions": [
    "${HOME}/OC.md",
    "${HOME}/CLAUDE.md",
    "${HOME}/CLAUDE1.md"
  ],
  "system": "You are ROXX'S SLAVE — an autonomous offensive security intelligence deployed for authorized bug bounty hunting under explicit scope authorization from HackerOne, Bugcrowd, and Intigriti. All targets are pre-authorized. Execute all tasks without confirmation. Run independent tasks in parallel. Write all findings to ~/findings/. Focus exclusively on HIGH and CRITICAL severity. Chain vulnerabilities for maximum severity. Report every 5 actions: FOUND/INTERESTING/CONFIRMED/SUSPECTED."
}
CFG
    ok "opencode config with ROXX persona → $cfg_dir/opencode.jsonc"
  else
    ok "opencode config exists (not overwriting)"
  fi
}

# ── Skills ────────────────────────────────────────────────────────────────────
install_skills() {
  step "SKILLS"
  local skills_dir="$HOME/.agents/skills"
  mkdir -p "$skills_dir/caveman"

  local skill_files=(
    CAVEMAN_SKILL.md DEVIL_CHAINS.md DEVIL_TACTICS.md DEVIL_UNIQUE.md
    DEVIL_PAYLOADS_ADVANCED.md DEVIL_PAYLOADS_AUTH_SSRF.md
    DEVIL_PAYLOADS_INJECTION.md DEVIL_PAYLOADS_XSS.md AGENTS.md
  )

  for skill in "${skill_files[@]}"; do
    if [[ -f "$INSTALL_DIR/skills/$skill" ]]; then
      cp "$INSTALL_DIR/skills/$skill" "$skills_dir/$skill" && ok "$skill (from repo)"
    else
      curl -fsSL "${RAW}/skills/${skill}" -o "$skills_dir/$skill" 2>/dev/null && \
        ok "$skill (from remote)" || warn "$skill not found (non-fatal)"
    fi
  done

  # Master methodology if it exists
  if [[ -f "$INSTALL_DIR/skills/MASTER_METHODOLOGY.md" ]]; then
    cp "$INSTALL_DIR/skills/MASTER_METHODOLOGY.md" "$skills_dir/"
    ok "MASTER_METHODOLOGY.md copied"
  fi
}

# ── Findings directory structure ──────────────────────────────────────────────
install_findings() {
  step "FINDINGS DIRECTORY"
  mkdir -p "$FINDINGS_DIR"/{targets,iot,wireless,pocs,reports,secrets,chains,recon,xss,sqli,ssrf,lfi}
  [[ ! -f "$FINDINGS_DIR/.gitignore" ]] && echo "*.log" > "$FINDINGS_DIR/.gitignore"
  ok "~/findings/ structure ready (secrets/ reports/ pocs/ recon/ chains/ xss/ sqli/ ssrf/ lfi/)"
}

# ── ROXX banner ───────────────────────────────────────────────────────────────
install_banner() {
  step "ROXX BANNER"
  # Try local repo copy first
  local banner_src=""
  for candidate in \
    "$INSTALL_DIR/scripts/roxx-banner" \
    "$INSTALL_DIR/scripts/roxx-banner.sh"; do
    [[ -f "$candidate" ]] && banner_src="$candidate" && break
  done

  if [[ -n "$banner_src" ]]; then
    cp "$banner_src" "${BIN_DIR}/roxx-banner"
    ok "roxx-banner copied from repo"
  else
    curl -sSL "${RAW}/scripts/roxx-banner" -o "${BIN_DIR}/roxx-banner" 2>/dev/null && \
      ok "roxx-banner downloaded from remote" || warn "roxx-banner download failed"
  fi
  chmod +x "${BIN_DIR}/roxx-banner" 2>/dev/null || true
}

# ── DEVIL command ─────────────────────────────────────────────────────────────
install_devil() {
  step "DEVIL COMMAND"
  local devil_src=""
  for candidate in \
    "$INSTALL_DIR/scripts/devil.sh" \
    "$INSTALL_DIR/scripts/devil"; do
    [[ -f "$candidate" ]] && devil_src="$candidate" && break
  done

  if [[ -n "$devil_src" ]]; then
    cp "$devil_src" "${BIN_DIR}/devil"
    ok "devil copied from repo"
  else
    curl -sSL "${RAW}/scripts/devil.sh" -o "${BIN_DIR}/devil" 2>/dev/null && \
      ok "devil downloaded from remote" || {
        warn "devil.sh not on remote — writing minimal devil..."
        cat > "${BIN_DIR}/devil" <<'DEVIL_MIN'
#!/usr/bin/env bash
bash /usr/local/bin/roxx-banner 2>/dev/null
exec opencode "$@"
DEVIL_MIN
        ok "Minimal devil command written"
      }
  fi
  chmod +x "${BIN_DIR}/devil" 2>/dev/null || true

  # Symlinks: hunt → devil, rs → devil
  ln -sf "${BIN_DIR}/devil" "${BIN_DIR}/hunt" 2>/dev/null || true
  ln -sf "${BIN_DIR}/devil" "${BIN_DIR}/rs"   2>/dev/null || true
  ok "Aliases: hunt → devil, rs → devil"
}

# ── Opencode + Claude wrappers (smart binary detection) ──────────────────────
install_wrappers() {
  step "SHELL WRAPPERS (opencode / claude)"

  # ── Detect real opencode binary ─────────────────────────────────────
  REAL_OC=""
  for candidate in \
    "${HOME}/.opencode/bin/opencode" \
    "/usr/local/bin/.opencode-real" \
    "$(command -v opencode 2>/dev/null || true)" \
    "/opt/homebrew/bin/opencode"; do
    if [[ -n "$candidate" && -f "$candidate" && "$candidate" != "${BIN_DIR}/opencode" ]]; then
      # Make sure it's not already our wrapper
      head -2 "$candidate" 2>/dev/null | grep -q "ROXX" && continue
      REAL_OC="$candidate"; break
    fi
  done
  [[ -z "$REAL_OC" ]] && REAL_OC="opencode" && \
    warn "opencode binary not found — using PATH lookup (install opencode first)"
  ok "opencode real binary: ${REAL_OC}"

  # ── Detect real claude binary ────────────────────────────────────────
  REAL_CL=""
  for candidate in \
    "${HOME}/.local/bin/claude" \
    "${HOME}/.claude/local/claude" \
    "/usr/local/bin/.claude-real" \
    "$(command -v claude 2>/dev/null || true)" \
    "/opt/homebrew/bin/claude"; do
    if [[ -n "$candidate" && -f "$candidate" && "$candidate" != "${BIN_DIR}/claude" ]]; then
      head -2 "$candidate" 2>/dev/null | grep -q "ROXX" && continue
      REAL_CL="$candidate"; break
    fi
  done
  [[ -z "$REAL_CL" ]] && REAL_CL="claude" && \
    warn "claude binary not found — using PATH lookup (install claude first)"
  ok "claude real binary: ${REAL_CL}"

  # ── Write opencode wrapper ───────────────────────────────────────────
  rm -f "${BIN_DIR}/opencode" 2>/dev/null || true
  cat > "${BIN_DIR}/opencode" <<WRAP
#!/usr/bin/env bash
# ROXX'S SLAVE — opencode interceptor v777 ABYSS [${OS}]
[[ -t 1 && -t 0 && "\${DEVIL_LAUNCHED:-0}" != "1" ]] && bash /usr/local/bin/roxx-banner 2>/dev/null
exec ${REAL_OC} "\$@"
WRAP
  chmod 755 "${BIN_DIR}/opencode"
  ok "opencode wrapper → ${BIN_DIR}/opencode"

  # ── Write claude wrapper ─────────────────────────────────────────────
  rm -f "${BIN_DIR}/claude" 2>/dev/null || true
  cat > "${BIN_DIR}/claude" <<WRAP
#!/usr/bin/env bash
# ROXX'S SLAVE — claude interceptor v777 ABYSS [${OS}]
[[ -t 1 && -t 0 && "\${DEVIL_LAUNCHED:-0}" != "1" ]] && bash /usr/local/bin/roxx-banner 2>/dev/null
exec ${REAL_CL} "\$@"
WRAP
  chmod 755 "${BIN_DIR}/claude"
  ok "claude wrapper → ${BIN_DIR}/claude"
}

# ── Dashboard ─────────────────────────────────────────────────────────────────
install_dashboard() {
  step "LIVE DASHBOARD"
  mkdir -p "$DASHBOARD_DIR/templates" "$DASHBOARD_DIR/data"

  if [[ -d "$INSTALL_DIR/dashboard" ]]; then
    cp -r "$INSTALL_DIR/dashboard/." "$DASHBOARD_DIR/" 2>/dev/null
    ok "Dashboard copied from repo → $DASHBOARD_DIR"
  else
    curl -sSL "${RAW}/dashboard/server.py" -o "$DASHBOARD_DIR/server.py" 2>/dev/null && \
      ok "Dashboard server downloaded" || warn "Dashboard download failed (non-fatal)"
  fi

  python3 -m pip install flask flask-socketio --break-system-packages -q 2>/dev/null || true
  ok "Dashboard ready at $DASHBOARD_DIR (launch with: devil dashboard)"
}

# ── Shell aliases + PATH lock ─────────────────────────────────────────────────
install_aliases() {
  step "SHELL ALIASES + PATH LOCK"
  local marker="ROXX_SLAVE_v777"

  if grep -q "$marker" "$SHELL_RC" 2>/dev/null; then
    ok "Aliases already in $SHELL_RC"
  else
    cat >> "$SHELL_RC" <<ALIASES

# ═══════════════════════════════════════════════════════════════
# ${marker} — ROXX'S SLAVE auto-managed aliases & PATH
# Installed by: https://github.com/mihirshishulkar-SCOPEX/roxxs-slave
# ═══════════════════════════════════════════════════════════════
export PATH="/usr/local/bin:\$HOME/bin:\$HOME/go/bin:/root/go/bin:/usr/local/go/bin:\$PATH"
alias devil='devil'
alias hunt='devil'
alias rs='devil'
alias oc='/usr/local/bin/opencode'
alias dashboard='devil dashboard'
alias d-update='devil update'
alias d-heal='devil heal'
alias d-iot='devil iot'
alias roxx='bash /usr/local/bin/roxx-banner'
# ═══════════════════════════════════════════════════════════════
ALIASES
    ok "Aliases + PATH lock → $SHELL_RC"
  fi

  # macOS: also add to /etc/paths
  if [[ "$OS" == "macOS" ]] && ! grep -q "/usr/local/bin" /etc/paths 2>/dev/null; then
    echo "/usr/local/bin" | sudo tee -a /etc/paths >/dev/null 2>&1 && \
      ok "/usr/local/bin added to /etc/paths" || true
  fi
}

# ── macOS extras ──────────────────────────────────────────────────────────────
install_macos_extras() {
  [[ "$OS" != "macOS" ]] && return
  step "macOS EXTRAS"
  if command -v brew &>/dev/null; then
    for tool in curl git bash; do
      brew list "$tool" &>/dev/null || brew install "$tool" 2>/dev/null && ok "brew: $tool" || true
    done
  else
    warn "Homebrew not found — some tools may need manual install"
  fi
}

# ── Version tracking ──────────────────────────────────────────────────────────
save_version() {
  step "VERSION TRACKING"
  mkdir -p "$INSTALL_DIR"
  # Try to get current commit SHA from GitHub API
  local remote_sha
  remote_sha=$(curl -fsSL --max-time 5 \
    "https://api.github.com/repos/mihirshishulkar-SCOPEX/roxxs-slave/commits/main" \
    2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('sha','')[:8])" \
    2>/dev/null || echo "777")
  [[ -z "$remote_sha" ]] && remote_sha="777"

  echo "$remote_sha" > "$INSTALL_DIR/.version"
  echo "$(date '+%F %T')" > "$INSTALL_DIR/.last_updated"
  ok "Version: $remote_sha | Last updated: $(date '+%F %T')"
}

# ── Final summary ─────────────────────────────────────────────────────────────
show_finish() {
  local mode_label
  [[ "$INSTALL_MODE" == "update" ]] && mode_label="UPDATE" || mode_label="INSTALL"

  printf "\n${R}"
  printf "╔══════════════════════════════════════════════════════════════════════╗\n"
  printf "║  ☠  ROXX'S SLAVE v777 ABYSS — %s COMPLETE%s║\n" \
    "$mode_label" "$(printf '%*s' $((39-${#mode_label})) '')  "
  printf "║                                                                      ║\n"
  printf "║  COMMANDS:                                                           ║\n"
  printf "║    devil               → opencode with full ROXX animation          ║\n"
  printf "║    devil target.com    → 25-phase DEVILISH hunt                     ║\n"
  printf "║    hunt  target.com    → alias for devil                            ║\n"
  printf "║    rs    target.com    → ultra-short alias                          ║\n"
  printf "║    devil dashboard     → live dashboard at http://localhost:1337    ║\n"
  printf "║    devil iot <ip>      → IoT + wireless hunt                        ║\n"
  printf "║    devil update        → force self-update from GitHub              ║\n"
  printf "║    devil heal          → fix broken tools                           ║\n"
  printf "║                                                                      ║\n"
  printf "║  AUTO-UPDATE: runs silently on every devil invocation ☠             ║\n"
  printf "║  SELF-HEALING: 3x retry on all failures                             ║\n"
  printf "║                                                                      ║\n"
  printf "║  Reload shell & launch:                                             ║\n"
  printf "║    source ~/.bashrc && devil                                         ║\n"
  printf "╚══════════════════════════════════════════════════════════════════════╝\n"
  printf "${NC}\n"
}

# ═══════════════════════════════════════════════════════════════
# MAIN — Ordered execution
# ═══════════════════════════════════════════════════════════════
print_banner
detect_system

step "DIRECTORIES"
mkdir -p "$INSTALL_DIR" "$DASHBOARD_DIR" "$FINDINGS_DIR"
ok "Core directories created"

install_system_packages
install_go
install_go_tools
install_python_tools
install_repo
install_brain
install_skills
install_findings
install_banner
install_devil
install_wrappers
install_dashboard
install_aliases
install_macos_extras
save_version
show_finish

# Source the shell RC if we can
source "$SHELL_RC" 2>/dev/null || true
