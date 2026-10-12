#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ROXX'S SLAVE — DEVIL COMMAND v777 ABYSS                                    ║
# ║  The deadliest AI-powered bug bounty persona                                 ║
# ║                                                                              ║
# ║  Usage:                                                                      ║
# ║    devil                    → Launch opencode with ROXX animation            ║
# ║    devil target.com         → Full 25-phase bug bounty hunt                  ║
# ║    devil dashboard          → Live dashboard at http://localhost:1337         ║
# ║    devil iot 192.168.1.0/24 → IoT + wireless hunt                            ║
# ║    devil update             → Force self-update                               ║
# ║    devil heal               → Fix any broken tools                            ║
# ║    devil help               → Show all commands                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

INSTALL_DIR="$HOME/.roxx-slave"
DASHBOARD_DIR="$HOME/roxx-dashboard"
HUNT_SCRIPT="$INSTALL_DIR/scripts/hunt.sh"
IOT_SCRIPT="$INSTALL_DIR/scripts/iot-hunt.sh"
BANNER_SCRIPT="/usr/local/bin/roxx-banner"
VERSION_FILE="$INSTALL_DIR/.version"
RAW="https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main"
VERSION_URL="${RAW}/VERSION"

export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin:/root/go/bin:/home/roxx/go/bin"

R=$'\e[1;31m'
G=$'\e[1;32m'
Y=$'\e[1;33m'
C=$'\e[1;36m'
W=$'\e[1;37m'
NC=$'\e[0m'

# ── Show ROXX animated banner ─────────────────────────────────────────────────
show_banner() {
  [[ "${ROXX_FAST:-0}" == "1" ]] && return
  if [[ -x "$BANNER_SCRIPT" ]]; then
    bash "$BANNER_SCRIPT"
  else
    printf "${R}
 ██████╗ ███████╗██╗   ██╗██╗██╗     ██╗███████╗██╗  ██╗
 ██╔══██╗██╔════╝██║   ██║██║██║     ██║██╔════╝██║  ██║
 ██║  ██║█████╗  ██║   ██║██║██║     ██║███████╗███████║
 ██║  ██║██╔══╝  ╚██╗ ██╔╝██║██║     ██║╚════██║██╔══██║
 ██████╔╝███████╗ ╚████╔╝ ██║███████╗██║███████║██║  ██║
 ╚═════╝ ╚══════╝  ╚═══╝  ╚═╝╚══════╝╚═╝╚══════╝╚═╝  ╚═╝
 ${NC}${W}ROXX'S SLAVE — DEVILISH v777 ABYSS${NC}\n"
  fi
}

# ── Auto-update check (runs silently on every launch) ────────────────────────
auto_update() {
  local remote local_v
  remote=$(curl -sf --max-time 4 "$VERSION_URL" 2>/dev/null | tr -d '[:space:]') || return 0
  local_v=$(cat "$VERSION_FILE" 2>/dev/null | tr -d '[:space:]' || echo "0")
  if [[ -n "$remote" && "$remote" != "$local_v" ]]; then
    printf "${Y}[↑] v${remote} available — auto-updating in background...${NC}\n"
    (
      if git -C "$INSTALL_DIR" pull origin main --quiet 2>/dev/null; then
        printf "${G}[✓] Updated to v${remote}${NC}\n"
      else
        curl -sSL "${RAW}/scripts/hunt.sh"    -o "$HUNT_SCRIPT" 2>/dev/null
        curl -sSL "${RAW}/scripts/iot-hunt.sh" -o "$IOT_SCRIPT"  2>/dev/null
        curl -sSL "${RAW}/usr-local-bin/roxx-banner" -o "$BANNER_SCRIPT" 2>/dev/null
        printf "${G}[✓] Updated to v${remote} (direct)${NC}\n"
      fi
      chmod +x "$HUNT_SCRIPT" "$IOT_SCRIPT" "$BANNER_SCRIPT" 2>/dev/null
      command -v nuclei &>/dev/null && nuclei -update-templates -silent 2>/dev/null
      echo "$remote" > "$VERSION_FILE"
    ) &
  fi
}

# ── Force full self-update ────────────────────────────────────────────────────
force_update() {
  printf "${G}[⚙] Force updating ROXX'S SLAVE...${NC}\n"
  if git -C "$INSTALL_DIR" pull origin main 2>&1 | grep -qE "Already|files changed"; then
    printf "${G}[✓] Repo synced${NC}\n"
  else
    curl -sSL "${RAW}/install.sh" | bash 2>/dev/null
  fi
  command -v nuclei &>/dev/null && nuclei -update-templates -silent 2>/dev/null && \
    printf "${G}[✓] Nuclei templates updated${NC}\n"
  local remote
  remote=$(curl -sf --max-time 5 "$VERSION_URL" 2>/dev/null | tr -d '[:space:]')
  [[ -n "$remote" ]] && echo "$remote" > "$VERSION_FILE"
  printf "${G}[✓] ROXX'S SLAVE v${remote} — up to date ☠${NC}\n"
}

# ── Self-heal broken/missing tools ───────────────────────────────────────────
self_heal() {
  local missing=()
  for t in subfinder httpx nuclei katana dalfox ffuf naabu sqlmap; do
    command -v "$t" &>/dev/null || missing+=("$t")
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    printf "${Y}[⚙] Missing tools detected: ${missing[*]}${NC}\n"
    printf "${Y}[⚙] Auto-healing — reinstalling now...${NC}\n"
    curl -sSL "${RAW}/install.sh" | bash 2>/dev/null
    printf "${G}[✓] Heal complete${NC}\n"
  fi
}

# ── Launch dashboard ──────────────────────────────────────────────────────────
start_dashboard() {
  pkill -f "server.py" 2>/dev/null; sleep 1
  python3 "$DASHBOARD_DIR/server.py" &>/tmp/roxx-dashboard.log &
  disown $!
  local i=0
  while [[ $i -lt 8 ]]; do
    sleep 1
    curl -sf http://127.0.0.1:1337/api/stats >/dev/null 2>&1 && {
      printf "${G}[✓] Dashboard LIVE → http://localhost:1337${NC}\n"
      printf "${C}    Stats: $(curl -s http://127.0.0.1:1337/api/stats)${NC}\n"
      return 0
    }
    i=$((i+1))
  done
  printf "${R}[✗] Dashboard failed — log: /tmp/roxx-dashboard.log${NC}\n"
  cat /tmp/roxx-dashboard.log | tail -20
}

# ── Help menu ─────────────────────────────────────────────────────────────────
show_help() {
printf "${R}
  ╔══════════════════════════════════════════════════════════════════════╗
  ║  ROXX'S SLAVE — DEVIL v777 ABYSS                                    ║
  ╠══════════════════════════════════════════════════════════════════════╣
  ║                                                                      ║
  ║  devil                        Launch opencode with ROXX animation   ║
  ║  devil <target>               Full 25-phase bug bounty hunt         ║
  ║  devil <target> H1 5000       Hunt + platform + bounty estimate     ║
  ║                                                                      ║
  ║  devil dashboard              Live dashboard → http://localhost:1337 ║
  ║  devil iot <ip/range>         IoT + wireless device hunt            ║
  ║  devil update                 Force self-update now                  ║
  ║  devil heal                   Fix/reinstall broken tools             ║
  ║  devil help                   Show this menu                        ║
  ║                                                                      ║
  ╠══════════════════════════════════════════════════════════════════════╣
  ║  ALIASES: hunt / rs (all same as devil)                             ║
  ╠══════════════════════════════════════════════════════════════════════╣
  ║  EXAMPLES:                                                           ║
  ║    devil                      → opencode (AI hunting session)       ║
  ║    devil target.com           → Full hunt                           ║
  ║    devil target.com H1 5000   → Hunt with bounty context            ║
  ║    devil dashboard            → Live dashboard                      ║
  ║    devil iot 192.168.1.0/24   → IoT hunt                            ║
  ║    devil update               → Update to latest devilish version   ║
  ╚══════════════════════════════════════════════════════════════════════╝
${NC}"
}

# ── Main ──────────────────────────────────────────────────────────────────────
CMD="${1:-}"

# No args → show banner + launch opencode
if [[ -z "$CMD" ]]; then
  show_banner
  auto_update
  printf "${R}[☠] Launching ROXX'S SLAVE in opencode...${NC}\n"
  # Find real opencode binary
  REAL_OC=""
  for candidate in /root/.opencode/bin/opencode /usr/local/bin/opencode.real \
                   "$(which opencode.real 2>/dev/null)"; do
    [[ -x "$candidate" ]] && { REAL_OC="$candidate"; break; }
  done
  if [[ -n "$REAL_OC" ]]; then
    exec "$REAL_OC"
  elif command -v opencode &>/dev/null; then
    # Avoid recursive loop — set flag
    DEVIL_LAUNCHED=1 exec opencode
  else
    printf "${Y}[!] opencode not found — launching shell with ROXX persona${NC}\n"
    export PS1="${R}☠ ROXX'S SLAVE${NC} \w \$ "
    exec bash
  fi
  exit 0
fi

# Subcommands
case "$CMD" in
  help|-h|--help)
    show_banner
    show_help
    ;;
  update|--update|-u)
    show_banner
    force_update
    ;;
  heal|fix|repair)
    printf "${Y}[⚙] Self-healing all tools...${NC}\n"
    self_heal
    ;;
  dashboard|dash|ui)
    show_banner
    start_dashboard
    ;;
  iot|wireless|rf)
    shift
    show_banner
    auto_update &
    if [[ -x "$IOT_SCRIPT" ]]; then
      bash "$IOT_SCRIPT" "$@"
    else
      printf "${R}[✗] IoT script not found — run: devil heal${NC}\n"
    fi
    ;;
  banner|roxx)
    bash "$BANNER_SCRIPT"
    ;;
  *)
    # Treat as target — run full hunt
    show_banner
    auto_update &
    UPDATE_PID=$!
    self_heal
    if [[ -x "$HUNT_SCRIPT" ]]; then
      bash "$HUNT_SCRIPT" "$@"
    else
      printf "${R}[✗] hunt.sh not found at $HUNT_SCRIPT${NC}\n"
      printf "${Y}[⚙] Run: devil heal${NC}\n"
    fi
    wait $UPDATE_PID 2>/dev/null || true
    ;;
esac
