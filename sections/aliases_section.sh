#!/usr/bin/env bash

install_aliases_v2() {
  step "SHELL ALIASES + ENVIRONMENT (global, every user)"

  local ALIAS_BLOCK
  ALIAS_BLOCK='
# ════════════════════════════════════════════════════════════
# ☠ ROXX'"'"'S SLAVE v888 ABYSS OMEGA — Shell Environment
# ════════════════════════════════════════════════════════════

# roxx-path-fix
export PATH="$PATH:$HOME/.local/bin:$HOME/go/bin:/usr/local/go/bin:/root/go/bin:$HOME/.cargo/bin:$HOME/.npm-global/bin:/usr/local/npm/bin"
export COLORTERM="truecolor"
export OPENCODE_THEME="roxx"
export GOPATH="$HOME/go"
export GOFLAGS="-mod=mod"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" 2>/dev/null || true

# ── Primary commands ──────────────────────────────────────
alias oc="opencode"
alias devil="devil"
alias hunt="devil"
alias rs="devil"
alias h="devil"
alias heal="roxx-heal"
alias update="devil update"

# ── Recon shortcuts ───────────────────────────────────────
alias sf="subfinder -silent"
alias sfr="subfinder -recursive -silent"
alias hx="httpx -silent -status-code -title -tech-detect -cdn"
alias hxf="httpx -silent -status-code -title -tech-detect -follow-redirects -probe"
alias nc="nuclei -silent"
alias ncc="nuclei -silent -severity critical,high"
alias nca="nuclei -silent -severity critical,high,medium -stats"
alias kt="katana -silent -js-crawl -depth 5"
alias wu="waybackurls"
alias gau="gau --threads 5"
alias dnx="dnsx -silent"
alias sfx="subfinder -silent | httpx -silent | nuclei -silent -severity critical,high"

# ── Attack shortcuts ──────────────────────────────────────
alias dx="dalfox"
alias dxp="dalfox pipe"
alias sm="sqlmap --batch --level=5 --risk=3"
alias smbulk="sqlmap --batch --forms --crawl=3"
alias ff="ffuf -c -ac"
alias ffv="ffuf -c -v"
alias arj="arjun"
alias gfw="gf xss | dalfox pipe"

# ── Finding shortcuts ─────────────────────────────────────
alias findings="ls -la ~/findings/"
alias crit="ls ~/findings/critical/ 2>/dev/null && cat ~/findings/critical/*.md 2>/dev/null"
alias hi="ls ~/findings/high/ 2>/dev/null && cat ~/findings/high/*.md 2>/dev/null"
alias report="devil report"
alias newbug="devil newbug"

# ── Git shortcuts ─────────────────────────────────────────
alias gs="git status"
alias gp="git pull"

# ── Tool version check ────────────────────────────────────
alias toolcheck="echo -n subfinder: && subfinder -version 2>/dev/null | head -1; echo -n httpx: && httpx -version 2>/dev/null | head -1; echo -n nuclei: && nuclei -version 2>/dev/null | head -1; echo -n ffuf: && ffuf -V 2>/dev/null | head -1; echo -n dalfox: && dalfox version 2>/dev/null | head -1; echo -n sqlmap: && sqlmap --version 2>/dev/null | head -1; echo DONE"

# ── Quick target functions ────────────────────────────────
roxx_quick() {
  local target="$1"
  [[ -z "$target" ]] && echo "Usage: q <target>" && return 1
  mkdir -p ~/findings/"$target"
  echo "☠ Quick hunt: $target"
  subfinder -d "$target" -silent 2>/dev/null | httpx -silent 2>/dev/null | nuclei -silent -severity critical,high 2>/dev/null | tee ~/findings/"$target"/quick.txt
}
alias q="roxx_quick"
alias quick="roxx_quick"

roxx_full() {
  local target="$1"
  [[ -z "$target" ]] && echo "Usage: full <target>" && return 1
  devil "$target"
}
alias full="roxx_full"

# ── interactsh shortcut ───────────────────────────────────
alias oast="interactsh-client -v"
alias collab="interactsh-client -v"

# ── JWT shortcuts ─────────────────────────────────────────
alias jwt="jwt_tool"
alias jwtno="python3 -c \"import sys,base64,json; t=sys.argv[1].split(\".\"); h=json.loads(base64.b64decode(t[0]+\"==\")); h[\"alg\"]=\"none\"; p=base64.urlsafe_b64encode(json.dumps(h).encode()).rstrip(b\"=\").decode(); print(p+\".\"+t[1]+\".\")\" 2>/dev/null"

# ── Shodan shortcut ───────────────────────────────────────
alias shod="shodan"
alias shodip="shodan host"

# ── Dev/debug ─────────────────────────────────────────────
alias myip="curl -s ifconfig.me"
alias ports="netstat -tulnp 2>/dev/null || ss -tulnp"
alias listen="ss -tulnp | grep LISTEN"
alias psg="ps aux | grep"
alias reload="source ~/.bashrc 2>/dev/null; source ~/.zshrc 2>/dev/null; echo reloaded"

# ── ROXX banner ───────────────────────────────────────────
[[ -x "$HOME/.roxx-slave/scripts/roxx-banner" ]] && \
  alias banner="bash $HOME/.roxx-slave/scripts/roxx-banner"

echo "☠ ROXX'"'"'S SLAVE v888 ABYSS OMEGA — shell ready"
'

  # Install to all relevant rc files
  local RC_FILES=()
  [[ -f "$USER_HOME/.bashrc" ]] && RC_FILES+=("$USER_HOME/.bashrc")
  [[ -f "$USER_HOME/.zshrc" ]] && RC_FILES+=("$USER_HOME/.zshrc")
  [[ -f /root/.bashrc ]] && RC_FILES+=(/root/.bashrc)
  [[ -f /root/.zshrc ]] && RC_FILES+=(/root/.zshrc)

  if [[ $IS_ROOT -eq 1 ]]; then
    for uhome in /home/*/; do
      [[ -f "${uhome}.bashrc" ]] && RC_FILES+=("${uhome}.bashrc")
      [[ -f "${uhome}.zshrc" ]] && RC_FILES+=("${uhome}.zshrc")
    done
  fi

  for rc in "${RC_FILES[@]}"; do
    grep -q "ROXX'S SLAVE v888" "$rc" 2>/dev/null && { skip "aliases in $rc"; continue; }
    # Remove old version if present
    python3 -c "
import re
with open('$rc') as f: c=f.read()
c = re.sub(r'# .*ROXX.*SLAVE.*Shell.*\n.*?(?=\n# |$)', '', c, flags=re.DOTALL)
with open('$rc','w') as f: f.write(c)
" 2>/dev/null || true
    printf '\n%s\n' "$ALIAS_BLOCK" >> "$rc"
    ok "Aliases installed → $rc"
  done

  # Also write to /etc/profile.d/ if root
  if [[ $IS_ROOT -eq 1 ]]; then
    cat > /etc/profile.d/roxxs-slave.sh << 'PROFEOF'
#!/bin/sh
# ROXX'S SLAVE — system-wide environment
export PATH="$PATH:$HOME/.local/bin:$HOME/go/bin:/usr/local/go/bin:/root/go/bin"
export COLORTERM="truecolor"
export OPENCODE_THEME="roxx"
PROFEOF
    chmod 644 /etc/profile.d/roxxs-slave.sh 2>/dev/null
    ok "System-wide env → /etc/profile.d/roxxs-slave.sh"
  fi
}
