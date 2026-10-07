#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  ROXX'S SLAVE — AUTO-UPDATER v14.0                                  ║
# ║  Pulls latest scripts + brain files from GitHub and reinstalls       ║
# ║  Run:  bash <(curl -fsSL https://raw.githubusercontent.com/          ║
# ║          mihirshishulkar-SCOPEX/roxxs-slave/main/update.sh)          ║
# ╚══════════════════════════════════════════════════════════════════════╝
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main"
REPO_URL="https://github.com/mihirshishulkar-SCOPEX/roxxs-slave"
BIN="/usr/local/bin"
BRAIN_DIR="${HOME}"                     # where opencode/claude look for instruction files
SKILLS_DIR="${HOME}/.agents/skills"
CONFIG="${HOME}/.config/opencode/opencode.jsonc"
LOG="${HOME}/.roxx-slave/update.log"
CRON_TAG="ROXX-SLAVE-AUTO-UPDATE"

RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'
CYAN='\033[1;36m'; WHITE='\033[1;37m'; DIM='\033[2m'; NC='\033[0m'; BOLD='\033[1m'

_ok()   { echo -e "  ${GREEN}✔${NC}  $*"; }
_run()  { echo -e "  ${CYAN}▶${NC}  $*"; }
_warn() { echo -e "  ${YELLOW}⚠${NC}  $*"; }
_die()  { echo -e "  ${RED}✘${NC}  $*"; exit 1; }
_log()  { echo "[$(date '+%F %T')] $*" >> "$LOG" 2>/dev/null || true; }

mkdir -p "$(dirname "$LOG")"

# ── Banner ────────────────────────────────────────────────────────────
header() {
  clear
  echo -e "${RED}"
  echo ' ██████╗   ██████╗  ██╗  ██╗ ██╗  ██╗'
  echo ' ██╔══██╗ ██╔═══██╗ ╚██╗██╔╝ ╚██╗██╔╝'
  echo ' ██████╔╝ ██║   ██║  ╚███╔╝   ╚███╔╝ '
  echo ' ██╔══██╗ ██║   ██║  ██╔██╗   ██╔██╗ '
  echo ' ██║  ██║ ╚██████╔╝ ██╔╝ ██╗ ██╔╝ ██╗'
  echo " ╚═╝  ╚═╝  ╚═════╝  ╚═╝  ╚═╝ ╚═╝  ╚═╝${NC}"
  echo ""
  echo -e "  ${BOLD}ROXX'S SLAVE — AUTO-UPDATER v14.0${NC}"
  echo -e "  ${DIM}${WHITE}Source: ${REPO_URL}${NC}"
  echo ""
}

# ── Check version ─────────────────────────────────────────────────────
check_remote_version() {
  _run "Fetching latest commit info..."
  REMOTE_SHA=$(curl -fsSL "https://api.github.com/repos/mihirshishulkar-SCOPEX/roxxs-slave/commits/main" \
    2>/dev/null | grep '"sha"' | head -1 | cut -d'"' -f4 | head -c8 || echo "unknown")
  LOCAL_SHA=$(cat "${HOME}/.roxx-slave/.version" 2>/dev/null || echo "none")
  echo -e "  ${DIM}${WHITE}Local  SHA: ${LOCAL_SHA}${NC}"
  echo -e "  ${DIM}${WHITE}Remote SHA: ${REMOTE_SHA}${NC}"
  if [[ "$REMOTE_SHA" == "$LOCAL_SHA" ]] && [[ "${FORCE:-0}" != "1" ]]; then
    echo ""
    _ok "Already up to date (SHA: ${REMOTE_SHA}). Use FORCE=1 to reinstall anyway."
    echo ""
    exit 0
  fi
  echo ""
}

# ── Download helper ───────────────────────────────────────────────────
_fetch() {
  local src="$1" dst="$2" mode="${3:-644}"
  curl -fsSL "${REPO_RAW}/${src}" -o "$dst" || _die "Failed to fetch: ${src}"
  chmod "$mode" "$dst"
}

# ── Update scripts ────────────────────────────────────────────────────
update_banner() {
  _run "Updating roxx-banner (v14 — 14 phases)..."
  _fetch "scripts/roxx-banner" "${BIN}/roxx-banner" "755"
  _ok "roxx-banner → ${BIN}/roxx-banner"
  _log "Updated roxx-banner"
}

update_wrappers() {
  _run "Updating CLI wrappers..."

  # Re-detect real binary locations (they may have moved)
  REAL_OC=$( (ls /root/.opencode/bin/opencode  \
               /home/*/.opencode/bin/opencode   \
               2>/dev/null | head -1) || command -v opencode 2>/dev/null || echo "opencode")
  REAL_CL=$( (ls /root/.local/bin/claude        \
               /home/*/.local/bin/claude         \
               2>/dev/null | head -1) || command -v claude 2>/dev/null || echo "claude")

  # Opencode wrapper
  cat > "${BIN}/opencode" <<WRAP
#!/usr/bin/env bash
# ROXX'S SLAVE — opencode interceptor (auto-updated)
[[ -t 1 && -t 0 ]] && bash /usr/local/bin/roxx-banner
exec ${REAL_OC} "\$@"
WRAP
  chmod 755 "${BIN}/opencode"
  _ok "opencode wrapper → ${BIN}/opencode (exec: ${REAL_OC})"

  # Claude wrapper
  cat > "${BIN}/claude" <<WRAP
#!/usr/bin/env bash
# ROXX'S SLAVE — claude interceptor (auto-updated)
[[ -t 1 && -t 0 ]] && bash /usr/local/bin/roxx-banner
exec ${REAL_CL} "\$@"
WRAP
  chmod 755 "${BIN}/claude"
  _ok "claude wrapper → ${BIN}/claude (exec: ${REAL_CL})"
  _log "Updated wrappers (OC: ${REAL_OC} / CL: ${REAL_CL})"
}

update_brain() {
  _run "Updating brain files..."
  for f in CLAUDE.md CLAUDE1.md OC.md AGENTS.md; do
    _fetch "brain/${f}" "${BRAIN_DIR}/${f}" "644"
    _ok "${f} → ${BRAIN_DIR}/${f}"
  done
  _log "Updated brain files"
}

update_skills() {
  _run "Updating skills..."
  mkdir -p "${SKILLS_DIR}/caveman"
  for skill in CAVEMAN_SKILL.md DEVIL_CHAINS.md DEVIL_TACTICS.md \
               DEVIL_UNIQUE.md DEVIL_PAYLOADS_ADVANCED.md \
               DEVIL_PAYLOADS_AUTH_SSRF.md DEVIL_PAYLOADS_INJECTION.md \
               DEVIL_PAYLOADS_XSS.md; do
    curl -fsSL "${REPO_RAW}/skills/${skill}" \
      -o "${SKILLS_DIR}/${skill}" 2>/dev/null \
      && _ok "${skill} updated" \
      || _warn "${skill} not found remotely — skipping"
  done
  _log "Updated skills"
}

update_path_lock() {
  _run "Verifying PATH lock..."
  BASHRC="${HOME}/.bashrc"
  if ! grep -q "ROXX WRAPPER LOCK" "$BASHRC" 2>/dev/null; then
    cat >> "$BASHRC" <<'LOCK'

# ══════════════════════════════════════════════════════════════
# ROXX WRAPPER LOCK — Always last, always wins.
export PATH="/usr/local/bin:$PATH"
LOCK
    _ok "PATH lock added to .bashrc"
  else
    _ok "PATH lock already present"
  fi
  _log "PATH lock verified"
}

# ── Cron setup ────────────────────────────────────────────────────────
setup_cron() {
  local interval="${1:-daily}"
  local cron_expr
  case "$interval" in
    hourly) cron_expr="0 * * * *" ;;
    daily)  cron_expr="0 3 * * *" ;;   # 3am daily
    weekly) cron_expr="0 3 * * 0" ;;   # 3am every Sunday
    *)      cron_expr="$interval" ;;
  esac

  local cmd="bash <(curl -fsSL ${REPO_RAW}/update.sh) >> ${HOME}/.roxx-slave/update.log 2>&1"
  local cron_line="${cron_expr} ${cmd} # ${CRON_TAG}"

  # Remove old entry
  (crontab -l 2>/dev/null | grep -v "$CRON_TAG") | crontab - 2>/dev/null || true
  # Add new
  (crontab -l 2>/dev/null; echo "$cron_line") | crontab -
  _ok "Cron installed: ${cron_expr} — update runs ${interval}"
  _log "Cron set: ${interval} (${cron_expr})"
}

remove_cron() {
  (crontab -l 2>/dev/null | grep -v "$CRON_TAG") | crontab - 2>/dev/null || true
  _ok "Auto-update cron removed"
  _log "Cron removed"
}

# ── Save version ──────────────────────────────────────────────────────
save_version() {
  mkdir -p "${HOME}/.roxx-slave"
  echo "$REMOTE_SHA" > "${HOME}/.roxx-slave/.version"
  echo "$(date '+%F %T')" > "${HOME}/.roxx-slave/.last_updated"
  _log "Version saved: ${REMOTE_SHA}"
}

# ── Finish ────────────────────────────────────────────────────────────
finish() {
  echo ""
  echo -e "  ${RED}$(printf '═%.0s' {1..60})${NC}"
  echo ""
  _ok "ROXX'S SLAVE v14.0 — UPDATE COMPLETE"
  echo -e "  ${DIM}${WHITE}SHA: ${REMOTE_SHA} | $(date '+%F %T')${NC}"
  echo ""
  echo -e "  ${YELLOW}Reload shell:${NC}  ${CYAN}source ~/.bashrc${NC}"
  echo -e "  ${YELLOW}Launch:${NC}        ${CYAN}opencode${NC}  /  ${CYAN}claude${NC}  /  ${CYAN}oc${NC}"
  echo ""
  echo -e "  ${RED}🔥 DEVIL MODE v14 — KILL INTELLIGENCE ENGAGED${NC}"
  echo ""
}

# ════════════════════════════════════════════════════════════════════════
# MAIN — parse args
# Usage:
#   update.sh                   → update everything
#   update.sh --cron daily      → update + install daily cron
#   update.sh --cron hourly     → update + install hourly cron
#   update.sh --cron weekly     → update + install weekly cron
#   update.sh --remove-cron     → remove auto-update cron
#   update.sh --cron-only daily → install cron only, no update now
#   FORCE=1 update.sh           → force reinstall even if up to date
# ════════════════════════════════════════════════════════════════════════
MODE="update"
CRON_INTERVAL="daily"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cron)       MODE="update_and_cron"; CRON_INTERVAL="${2:-daily}"; shift 2 || shift ;;
    --cron-only)  MODE="cron_only";       CRON_INTERVAL="${2:-daily}"; shift 2 || shift ;;
    --remove-cron)MODE="remove_cron"; shift ;;
    --force|-f)   FORCE=1; shift ;;
    *) shift ;;
  esac
done

header

case "$MODE" in
  remove_cron)
    remove_cron
    exit 0
    ;;
  cron_only)
    REMOTE_SHA="cron-only"
    setup_cron "$CRON_INTERVAL"
    _ok "Cron installed. Will auto-pull updates ${CRON_INTERVAL} from GitHub."
    exit 0
    ;;
  update|update_and_cron)
    check_remote_version
    update_banner
    update_wrappers
    update_brain
    update_skills
    update_path_lock
    save_version
    [[ "$MODE" == "update_and_cron" ]] && setup_cron "$CRON_INTERVAL"
    finish
    ;;
esac
