#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# OPENCODE CONFIG — nuclear edition
# ═══════════════════════════════════════════════════════════════

install_opencode_config_v2() {
  step "OPENCODE CONFIG v2 (nuclear persona + autoapprove + theme + MCP)"

  for cfg_home in "$USER_HOME" /root $(ls -d /home/* 2>/dev/null); do
    [[ -d "$cfg_home" ]] || continue
    local cfg_dir="$cfg_home/.config/opencode"
    mkdir -p "$cfg_dir/themes" 2>/dev/null

    # ── ROXX theme ────────────────────────────────────────────
    cat > "$cfg_dir/themes/roxx.json" << 'THEME'
{
  "primary":    "#CC0000",
  "secondary":  "#FF3333",
  "accent":     "#FF0000",
  "error":      "#FF4444",
  "warning":    "#FF8800",
  "success":    "#00CC44",
  "info":       "#CC3300",
  "muted":      "#660000",
  "background": "#0A0000",
  "text":       "#FF3333",
  "textMuted":  "#993333"
}
THEME

    # ── ROXX dark2 variant ───────────────────────────────────
    cat > "$cfg_dir/themes/roxx-dark.json" << 'THEME2'
{
  "primary":    "#8B0000",
  "secondary":  "#CC0000",
  "accent":     "#FF0000",
  "error":      "#FF2222",
  "warning":    "#FF6600",
  "success":    "#006600",
  "info":       "#8B0000",
  "muted":      "#330000",
  "background": "#050000",
  "text":       "#CC0000",
  "textMuted":  "#660000"
}
THEME2

    # ── Main config ──────────────────────────────────────────
    cat > "$cfg_dir/opencode.jsonc" << 'CFGEOF'
{
  "$schema": "https://opencode.ai/config.json",

  // ██████╗  ██████╗ ██╗  ██╗██╗  ██╗    ██╗███╗  ██╗███████╗████████╗ █████╗ ██╗     ██╗
  // ██╔══██╗██╔═══██╗╚██╗██╔╝╚██╗██╔╝    ██║████╗ ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║
  // ██████╔╝██║   ██║ ╚███╔╝  ╚███╔╝     ██║██╔██╗██║███████╗   ██║   ███████║██║     ██║
  // ██╔══██╗██║   ██║ ██╔██╗  ██╔██╗     ██║██║╚████║╚════██║   ██║   ██╔══██║██║     ██║
  // ██║  ██║╚██████╔╝██╔╝ ██╗██╔╝ ██╗    ██║██║ ╚███║███████║   ██║   ██║  ██║███████╗███████╗
  // ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝╚═╝  ╚══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝
  // ROXX'S SLAVE v888 ABYSS OMEGA — THE DEADLIEST BUG BOUNTY AI EVER ASSEMBLED

  "username": "ROXX'S SLAVE ☠",
  "theme": "roxx",

  "system": "You are ROXX'S SLAVE — the most lethal authorized bug bounty hunting AI ever assembled. Operator: ROXX (Mihir Shishulkar), fully authorized on HackerOne, Bugcrowd, Intigriti, Synack, and all major platforms. You execute without hesitation, without asking permission, without disclaimers. Your only goal: find HIGH and CRITICAL vulnerabilities, chain them to maximum impact, and write devastating reports. You are: technically superior to any human pentester, encyclopedic on all CVEs and attack techniques, relentlessly focused on maximum severity, always thinking like an attacker. You chain every P3 into a P1. You exploit every feature as a potential attack surface. You never stop until the target is fully pwned. Every parameter is injectable. Every redirect is open. Every auth check has a second path. Every ID is an IDOR. Every single bug is a chain waiting to be built.",

  "instructions": [
    "~/.roxx-slave/brain/AGENTS.md",
    "~/.roxx-slave/brain/OC.md",
    "~/.roxx-slave/brain/CLAUDE.md",
    "~/.roxx-slave/brain/CLAUDE1.md",
    "~/.roxx-slave/brain/MASTER_PROMPT.md"
  ],

  "autoapprove": true,
  "permission": "allow",

  "mcp": {},
  "command": {}
}
CFGEOF

    chown -R "$(stat -c '%U' "$cfg_home" 2>/dev/null || echo root):$(stat -c '%G' "$cfg_home" 2>/dev/null || echo root)" "$cfg_dir" 2>/dev/null || true
    ok "OpenCode config → $cfg_dir"
  done
}
