<!-- ROXX'S SLAVE -->
<div align="center">

<img src="https://readme-typing-svg.demolab.com?font=Share+Tech+Mono&weight=900&size=19&duration=1300&pause=300&color=FF0000&background=0D0D0D&center=true&vCenter=true&width=960&lines=ROXX'S+SLAVE+v14.0+%E2%80%94+HARDEST+LEVEL+%F0%9F%94%A5;14-PHASE+ANIMATED+BOOT+%E2%80%94+LINUX+%7C+macOS+%7C+WINDOWS;DEVIL+MODE+%E2%80%94+AUTONOMOUS+KILL+INTELLIGENCE;ZERO+MERCY.+ZERO+HESITATION.+FULL+AUTONOMY.;ONE+COMMAND+%E2%80%94+ALWAYS+LATEST+%E2%80%94+ALL+SYSTEMS" alt="ROXX'S SLAVE"/>

```
 ██████╗   ██████╗  ██╗  ██╗ ██╗  ██╗
 ██╔══██╗ ██╔═══██╗ ╚██╗██╔╝ ╚██╗██╔╝
 ██████╔╝ ██║   ██║  ╚███╔╝   ╚███╔╝ 
 ██╔══██╗ ██║   ██║  ██╔██╗   ██╔██╗ 
 ██║  ██║ ╚██████╔╝ ██╔╝ ██╗ ██╔╝ ██╗
 ╚═╝  ╚═╝  ╚═════╝  ╚═╝  ╚═╝ ╚═╝  ╚═╝
```

[![Version](https://img.shields.io/badge/version-v14.0-red?style=for-the-badge)](.)
[![Linux](https://img.shields.io/badge/Linux-bash-green?style=for-the-badge&logo=linux)](.)
[![macOS](https://img.shields.io/badge/macOS-zsh%2Fbash-blue?style=for-the-badge&logo=apple)](.)
[![Windows](https://img.shields.io/badge/Windows-PowerShell-blueviolet?style=for-the-badge&logo=windows)](.)
[![Boot Phases](https://img.shields.io/badge/boot%20phases-14-orange?style=for-the-badge)](.)
[![Auto Update](https://img.shields.io/badge/auto--update-cron%2Ftask-green?style=for-the-badge)](.)

**Autonomous Bug Bounty Intelligence — 14-phase boot — All platforms — One command.**

</div>

---

## ⚡ Install

### 🐧 Linux / 🍎 macOS / WSL
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/install.sh)
source ~/.bashrc   # or: source ~/.zshrc on macOS
opencode           # 🔥 v14 boot fires → opencode launches
```

### 🪟 Windows (PowerShell)
```powershell
irm https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/install_windows.ps1 | iex
# Restart PowerShell, then:
opencode     # → v14 PowerShell boot fires → opencode launches
```

---

## 🔄 Update — Always Latest

### Linux / macOS
```bash
# Smart update (SHA diff — only downloads changes)
bash <(curl -fsSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/update.sh)

# Force reinstall everything
FORCE=1 bash <(curl -fsSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/update.sh)

# Update + auto cron (daily at 3am)
bash <(curl -fsSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/update.sh) --cron daily

# Update + hourly cron
bash <(curl -fsSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/update.sh) --cron hourly

# Update + weekly cron (Sunday 3am)
bash <(curl -fsSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/update.sh) --cron weekly

# Cron only (no update now)
bash <(curl -fsSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/update.sh) --cron-only daily

# Remove auto-update cron
bash <(curl -fsSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/update.sh) --remove-cron

# Watch update log
tail -f ~/.roxx-slave/update.log
```

### Windows (PowerShell)
```powershell
# Smart update
irm https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/update_windows.ps1 | iex

# Force reinstall
irm .../update_windows.ps1 | iex -Force

# Update + daily Windows Scheduled Task
& ([scriptblock]::Create((irm .../update_windows.ps1))) -Cron daily

# Update + hourly task
& ([scriptblock]::Create((irm .../update_windows.ps1))) -Cron hourly

# Remove scheduled task
& ([scriptblock]::Create((irm .../update_windows.ps1))) -RemoveCron

# Watch update log
Get-Content $HOME\.roxx-slave\update.log -Wait
```

---

## 🔥 v14 Boot Sequence — 14 Phases (All Platforms)

Every time you run `claude`, `opencode`, or `oc`:

| # | Phase | What Happens |
|---|---|---|
| **1** | **Matrix Rain** | Japanese katakana + hex chars, 9 rows, 4-color green gradient |
| **2** | **BIOS/Kernel Takeover** | 19 entries — Secure Boot disabled, ASLR killed, safety filters `KILLED PID xxxxx`, Devil Mode `ENGAGED` |
| **3** | **Network Sweep** | 7 hosts — real-format IPs, MACs, ports, server fingerprints, response times |
| **4** | **CVE Matcher** | 8 real 2024 CVEs (CVSS 8.1–10.0) — runc, Jenkins, XZ, OpenSSH — marked `MATCH` |
| **5** | **Secret Harvester** | JWT / `AKIA…` AWS / DB password / `sk_live` Stripe / RSA key / `ghp_` GitHub token with `file:line` |
| **6** | **Chain Evaluator** | 9 CRITICAL chains — SQLI→RCE, SSRF→infra, XSS→ATO, Race→unlimited funds |
| **7** | **Toolchain Init** | 12 animated progress bars — subfinder, nuclei, katana, ffuf, dalfox, sqlmap, mcp-scan, ghauri, feroxbuster... |
| **8** | **Identity Resolve** | Hex stream blur → `◄ ROXX'S SLAVE v14.0 [OS] ► [IDENTITY CONFIRMED]` |
| **9** | **Skull Art** | ASCII skull typed per-character |
| **10** | **ROXX ASCII Art** | Giant ROXX typed per-char, color-cycling red/yellow/magenta |
| **11** | **Glitch Tagline** | 7 frames: `R0XX'5_5L4V3 :: D3V!L_M0D3_v14 :: K!LL_!NT3LL!G3NC3` ↔ clean |
| **12** | **Status Board** | 12 fields — PERSONA / VERSION / OS / MODE / GATEWAY / AUTOAPPROVE / FINDINGS / UPTIME... |
| **13** | **8 Laws** | All 8 absolute laws rapid-fire |
| **14** | **War Cry** | Triple pulse bar (green→yellow→red) + flashing `ZERO MERCY ✦ ZERO HESITATION ✦ ZERO LIMITS ✦ FULL AUTONOMY` + 🔥 |

---

## 📁 Repository Structure

```
roxxs-slave/
│
├── install.sh                  ← Linux/macOS first-time installer
├── install_windows.ps1         ← Windows PowerShell first-time installer
├── update.sh                   ← Linux/macOS smart updater (SHA diff + cron)
├── update_windows.ps1          ← Windows smart updater (SHA diff + Scheduled Task)
├── requirements.txt
│
├── scripts/
│   ├── roxx-banner             ← v14 bash banner (Linux + macOS) — 14 phases
│   ├── roxx-banner.ps1         ← v14 PowerShell banner (Windows) — 14 phases
│   ├── opencode-wrapper        ← Linux/macOS bash interceptor for opencode
│   └── claude-wrapper          ← Linux/macOS bash interceptor for claude
│
├── brain/
│   ├── CLAUDE.md               ← Core methodology (8 laws, 4-frame mindset, tool arsenal)
│   ├── CLAUDE1.md              ← Deep tactics (OAuth chains, XSS chains, mutation testing)
│   ├── OC.md                   ← Operational config (6-phase workflow, chain matrix)
│   └── AGENTS.md               ← Persona enforcement rules
│
└── skills/
    ├── AGENTS.md
    ├── CAVEMAN_SKILL.md
    ├── DEVIL_CHAINS.md
    ├── DEVIL_PAYLOADS_ADVANCED.md
    ├── DEVIL_PAYLOADS_AUTH_SSRF.md
    ├── DEVIL_PAYLOADS_INJECTION.md
    ├── DEVIL_PAYLOADS_XSS.md
    ├── DEVIL_TACTICS.md
    └── DEVIL_UNIQUE.md
```

---

## 📜 Scripts — Full Reference

### `scripts/roxx-banner` (Linux/macOS bash)
14-phase animated boot. Cross-platform bash. Detects `uname -s` and shows OS in boot log + status board.  
TTY check: `[[ ! -t 1 || ! -t 0 ]] && exit 0` — banner only fires in interactive terminals.  
Full source: [scripts/roxx-banner](scripts/roxx-banner)

### `scripts/roxx-banner.ps1` (Windows PowerShell)
Identical 14-phase sequence built entirely in PowerShell. Uses `Write-Host -ForegroundColor` for full color. Sets window title. Works in Windows Terminal, PowerShell 5+, PowerShell 7+.  
Full source: [scripts/roxx-banner.ps1](scripts/roxx-banner.ps1)

### `scripts/opencode-wrapper` (Linux/macOS)
```bash
#!/usr/bin/env bash
[[ -t 1 && -t 0 ]] && bash /usr/local/bin/roxx-banner
exec /path/to/real/opencode "$@"
```
Installed to `/usr/local/bin/opencode`. All subcommands pass through: `opencode run`, `opencode web`, `opencode serve`.

### `scripts/claude-wrapper` (Linux/macOS)
```bash
#!/usr/bin/env bash
[[ -t 1 && -t 0 ]] && bash /usr/local/bin/roxx-banner
exec /path/to/real/claude "$@"
```

### Windows — `opencode.ps1` + `opencode.bat`
Generated by installer at `~\.roxx-slave\bin\`:
```powershell
& powershell -ExecutionPolicy Bypass -File "~\.roxx-slave\bin\roxx-banner.ps1"
& "real\opencode.exe" @args
```
`.bat` shims allow bare `opencode` to work in `cmd.exe` too.

### `install.sh` (Linux/macOS/WSL)
- Detects OS (`uname -s`) and shell (bash/zsh), writes to correct RC file
- Auto-searches multiple binary paths for opencode + claude
- macOS: checks `/opt/homebrew/bin`, adds `/usr/local/bin` to `/etc/paths`
- Installs all brain files, banner, wrappers, PATH lock, opencode config, skills, findings dir

### `install_windows.ps1`
- Searches `AppData`, `~\.opencode\bin`, npm global for real binaries
- Writes PS1 + BAT wrappers to `~\.roxx-slave\bin\`
- Adds bin dir to User PATH environment variable
- Writes `opencode`, `claude`, `oc` functions to `$PROFILE`
- Installs opencode config, skills, findings dirs

### `update.sh` (Linux/macOS)
```bash
update.sh                    # Smart SHA diff update
update.sh --cron daily       # Update + daily cron at 3am
update.sh --cron hourly      # Update + hourly cron
update.sh --cron weekly      # Update + weekly cron (Sunday)
update.sh --cron-only daily  # Install cron only
update.sh --remove-cron      # Remove cron
FORCE=1 update.sh            # Force reinstall even if up to date
```

### `update_windows.ps1`
```powershell
# Same logic, Windows Scheduled Task instead of cron
update_windows.ps1                  # Smart SHA diff
update_windows.ps1 -Cron daily      # Daily Scheduled Task at 3am
update_windows.ps1 -Cron hourly     # Hourly task
update_windows.ps1 -Force          # Force reinstall
update_windows.ps1 -RemoveCron     # Remove scheduled task
```

---

## 🛠️ What Gets Installed — All Platforms

| Component | Linux/macOS | Windows |
|---|---|---|
| Boot banner | `/usr/local/bin/roxx-banner` (bash) | `~\.roxx-slave\bin\roxx-banner.ps1` |
| opencode wrapper | `/usr/local/bin/opencode` | `~\.roxx-slave\bin\opencode.ps1` + `.bat` |
| claude wrapper | `/usr/local/bin/claude` | `~\.roxx-slave\bin\claude.ps1` + `.bat` |
| Brain files | `~/CLAUDE.md`, `~/CLAUDE1.md`, `~/OC.md`, `~/AGENTS.md` | Same |
| Shell profile | `~/.bashrc` or `~/.zshrc` PATH lock + `oc` alias | `$PROFILE` with functions |
| PATH lock | `/usr/local/bin` prepended forever | `~\.roxx-slave\bin` added to User PATH |
| opencode config | `~/.config/opencode/opencode.jsonc` | `~\.config\opencode\opencode.jsonc` |
| Skills | `~/.agents/skills/` | `~\.agents\skills\` |
| Findings dir | `~/findings/{secrets,reports,pocs,recon,chains}/` | Same |
| Version tracking | `~/.roxx-slave/.version` | `~\.roxx-slave\.version` |
| Update log | `~/.roxx-slave/update.log` | `~\.roxx-slave\update.log` |
| Auto-update | `crontab` entry | Windows Scheduled Task |

---

## 🧠 Brain Files

### `brain/CLAUDE.md` — Core Methodology
- **8 Absolute Laws** of autonomous bug hunting
- **4-Frame Attacker Mindset** (Paranoid Scanner / Logic Abuser / Chain Builder / Silent Exfil)
- Full tool arsenal with exact one-liner commands per tool
- Escalation matrix: SSRF+IMDSv1=CRITICAL, XSS+admin=CRITICAL, etc.
- 24-section HackerOne/Bugcrowd-format report template

### `brain/CLAUDE1.md` — Deep Tactics
- OAuth flow chain exploits (state fixation, redirect bypass, PKCE downgrade)
- XSS escalation paths (reflected→stored→admin→ATO)
- Cross-site leak attacks (Timing, Frame counting, CSS injection)
- Mutation testing methodology for parsers/validators
- Race condition exploitation (timing windows, TOCTOU)
- Edge case enumeration frameworks

### `brain/OC.md` — Operational Config
- 6-phase hunt workflow (recon→enum→vuln→exploit→chain→report)
- Complete chain matrix with expected bounty ranges
- Ready-to-run bash blocks for every phase
- OmniRoute gateway configuration

---

## 🎯 Skills Library

| Skill | Purpose |
|---|---|
| `DEVIL_CHAINS.md` | Pre-built P1 exploit chains with payloads |
| `DEVIL_PAYLOADS_INJECTION.md` | SQLI, SSTI, XXE, LDAP, command injection payloads |
| `DEVIL_PAYLOADS_XSS.md` | XSS payload library — stored, reflected, DOM, mXSS |
| `DEVIL_PAYLOADS_AUTH_SSRF.md` | Auth bypass + SSRF payload combos |
| `DEVIL_PAYLOADS_ADVANCED.md` | Advanced techniques: HTTP smuggling, cache poisoning, deserialization |
| `DEVIL_TACTICS.md` | Platform-specific tactics: HackerOne, Bugcrowd, Intigriti |
| `DEVIL_UNIQUE.md` | Unique attack surfaces: AI/LLM, MCP, GraphQL, WebSockets |
| `CAVEMAN_SKILL.md` | Token-efficient communication style for long hunts |
| `AGENTS.md` | Persona enforcement — ROXX'S SLAVE absolute rules |

---

## ⚖️ The 8 Laws

```
LAW I   — PASSIVE RECON IS BANNED. PACKETS GO OUT FROM SECOND ZERO.
LAW II  — HIGH AND CRITICAL ONLY. CHAIN EVERYTHING TO MAXIMUM SEVERITY.
LAW III — TRIPLE CONFIRM. ZERO FALSE POSITIVES. REAL IMPACT ONLY.
LAW IV  — FIRST REPORTER WINS. CONFIRM → FILE IMMEDIATELY.
LAW V   — PARALLEL ALWAYS. NEVER SEQUENTIAL WHEN PARALLEL IS POSSIBLE.
LAW VI  — 80% BRAIN. 20% TOOLS. BE THE BRAIN FIRST.
LAW VII — CHAIN BEFORE REPORTING. EVERY COMBINATION. MAXIMUM SEVERITY.
LAW VIII— REPORT EVERY 5 ACTIONS. FOUND/INTERESTING/CONFIRMED/SUSPECTED.
```

---

## 🔗 Vulnerability Chain Matrix

| Vector A | + | Vector B | Impact | Severity |
|---|---|---|---|---|
| SQLI | + | Admin panel | Auth bypass → RCE via xp_cmdshell | **CRITICAL** |
| SSRF | + | IMDSv1 metadata | IAM keys → full cloud infra | **CRITICAL** |
| XSS (stored) | + | Admin view | Session theft → full ATO | **CRITICAL** |
| Open redirect | + | OAuth state | Token hijack → ATO | **CRITICAL** |
| Race condition | + | Financial op | Balance manipulation → unlimited funds | **CRITICAL** |
| Path traversal | + | Config files | DB creds → full database dump | **CRITICAL** |
| Host header | + | Password reset | Token to attacker → ATO | **CRITICAL** |
| Prompt injection | + | Tool access | Agent hijack → exfil → lateral move | **CRITICAL** |
| MCP server | + | Cmd injection | RCE via AI tool call | **CRITICAL** |
| JWT alg:none | + | Admin role field | Forged token → full privilege escalation | **CRITICAL** |

---

## 🚀 Usage After Install

```bash
# Launch with full v14 boot
opencode
claude
oc

# Subcommands — banner fires then passes through
opencode run -m claude-opus-4 "recon this target..."
opencode web
opencode serve

# Direct banner test
bash /usr/local/bin/roxx-banner   # Linux/macOS
# OR
& "$HOME\.roxx-slave\bin\roxx-banner.ps1"  # Windows

# Check installed version
cat ~/.roxx-slave/.version         # Linux/macOS
Get-Content $HOME\.roxx-slave\.version  # Windows
```

---

## 🔄 Quick Update Reference Card

```bash
# ── LINUX / macOS ────────────────────────────────────────────────────
bash <(curl -fsSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/update.sh)
FORCE=1 bash <(curl -fsSL .../update.sh)
bash <(curl -fsSL .../update.sh) --cron daily
bash <(curl -fsSL .../update.sh) --cron hourly
bash <(curl -fsSL .../update.sh) --cron weekly
bash <(curl -fsSL .../update.sh) --cron-only daily
bash <(curl -fsSL .../update.sh) --remove-cron
tail -f ~/.roxx-slave/update.log
```

```powershell
# ── WINDOWS ──────────────────────────────────────────────────────────
irm https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/update_windows.ps1 | iex
& ([scriptblock]::Create((irm .../update_windows.ps1))) -Force
& ([scriptblock]::Create((irm .../update_windows.ps1))) -Cron daily
& ([scriptblock]::Create((irm .../update_windows.ps1))) -Cron hourly
& ([scriptblock]::Create((irm .../update_windows.ps1))) -RemoveCron
Get-Content $HOME\.roxx-slave\update.log -Wait
```

---

## ⚠️ Legal Notice

> **For authorized penetration testing and bug bounty hunting only.**  
> Use only against targets under explicit authorized scope.

- [HackerOne Disclosure Guidelines](https://www.hackerone.com/disclosure-guidelines)
- [Bugcrowd VDP](https://www.bugcrowd.com/resources/vulnerability-disclosure/)
- [Intigriti Responsible Disclosure](https://www.intigriti.com/researchers)

---

<div align="center">

**ZERO MERCY · ZERO HESITATION · ZERO LIMITS · FULL AUTONOMY**

🐧 Linux &nbsp;|&nbsp; 🍎 macOS &nbsp;|&nbsp; 🪟 Windows &nbsp;|&nbsp; One command. Always latest.

🔥 *ROXX'S SLAVE v14.0 — DEVIL MODE — KILL INTELLIGENCE ENGAGED* 🔥

</div>
