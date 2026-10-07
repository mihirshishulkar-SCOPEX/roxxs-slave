<!-- ROXX'S SLAVE -->
<div align="center">

<img src="https://readme-typing-svg.demolab.com?font=Share+Tech+Mono&weight=900&size=20&duration=1400&pause=350&color=FF0000&background=0D0D0D&center=true&vCenter=true&width=960&lines=ROXX'S+SLAVE+v14.0+%E2%80%94+HARDEST+LEVEL+%F0%9F%94%A5;14-PHASE+ANIMATED+BOOT+SEQUENCE;DEVIL+MODE+%E2%80%94+AUTONOMOUS+KILL+INTELLIGENCE;ZERO+MERCY.+ZERO+HESITATION.+FULL+AUTONOMY.;bash+%3C(curl+-fsSL+...+update.sh)+%E2%80%94+ALWAYS+LATEST" alt="ROXX'S SLAVE"/>

```
 ██████╗   ██████╗  ██╗  ██╗ ██╗  ██╗
 ██╔══██╗ ██╔═══██╗ ╚██╗██╔╝ ╚██╗██╔╝
 ██████╔╝ ██║   ██║  ╚███╔╝   ╚███╔╝ 
 ██╔══██╗ ██║   ██║  ██╔██╗   ██╔██╗ 
 ██║  ██║ ╚██████╔╝ ██╔╝ ██╗ ██╔╝ ██╗
 ╚═╝  ╚═╝  ╚═════╝  ╚═╝  ╚═╝ ╚═╝  ╚═╝
```

[![Version](https://img.shields.io/badge/version-v14.0-red?style=for-the-badge&logo=github)](.)
[![Mode](https://img.shields.io/badge/mode-DEVIL%20MODE-red?style=for-the-badge)](.)
[![Phases](https://img.shields.io/badge/boot%20phases-14-orange?style=for-the-badge)](.)
[![Auto Update](https://img.shields.io/badge/auto--update-1%20command-green?style=for-the-badge)](.)
[![Platforms](https://img.shields.io/badge/HackerOne%20%7C%20Bugcrowd%20%7C%20Intigriti-authorized-blueviolet?style=for-the-badge)](.)

**Autonomous Bug Bounty Hunting Intelligence — One command to install. One command to stay always latest.**

</div>

---

## ⚡ Install (One Command)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/install.sh)
```

```bash
source ~/.bashrc   # reload shell
opencode           # 🔥 14-phase boot fires, then launches
```

---

## 🔄 Update (One Command — Always Latest)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/update.sh)
```

Checks SHA vs your installed version — only downloads what changed. Force-reinstall:

```bash
FORCE=1 bash <(curl -fsSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/update.sh)
```

---

## ⏰ Auto-Update (Set & Forget)

Install a cron that auto-pulls from GitHub and reinstalls silently:

```bash
# Daily auto-update at 3am (recommended)
bash <(curl -fsSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/update.sh) --cron daily

# Hourly
bash <(curl -fsSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/update.sh) --cron hourly

# Weekly (Sunday 3am)
bash <(curl -fsSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/update.sh) --cron weekly

# Just install the cron, don't update now
bash <(curl -fsSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/update.sh) --cron-only daily

# Remove auto-update cron
bash <(curl -fsSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/update.sh) --remove-cron
```

Update log lives at: `~/.roxx-slave/update.log`

---

## 🔥 v14 Boot Sequence — 14 Phases

Every time you run `claude`, `opencode`, or `oc`, this fires automatically:

| # | Phase | What Happens |
|---|---|---|
| **1** | **Matrix Rain** | Japanese katakana + hex chars, 9 rows, 4-color green gradient |
| **2** | **BIOS/Kernel Takeover** | 19 boot entries — Secure Boot disabled, ASLR killed, safety filters `KILLED PID xxxxx`, Devil Mode `ENGAGED` |
| **3** | **Network Sweep** | Live-looking port scan — random IPs, MACs, server fingerprints, response times |
| **4** | **CVE Matcher** | 9 real 2024 CVEs (CVSS 8.1–10.0) — runc, Jenkins, XZ, OpenSSH — marked `MATCH` |
| **5** | **Secret Harvester** | JWT / `AKIA...` AWS key / DB password / `sk_live` Stripe / RSA private key with `file:line` |
| **6** | **Chain Evaluator** | 10 CRITICAL chains — SQLI→RCE, SSRF→infra, XSS→ATO, Race→unlimited funds |
| **7** | **Toolchain Init** | 10 animated progress bars — subfinder, nuclei, katana, ffuf, dalfox, sqlmap, jwt-tool, mcp-scan... |
| **8** | **Identity Resolve** | Hex stream blur → `◄ ROXX'S SLAVE v14.0 ► [IDENTITY CONFIRMED]` |
| **9** | **Skull Art** | ASCII skull typed per-character in dim red |
| **10** | **ROXX ASCII Art** | Giant ROXX typed per-char, color-cycling red/yellow/magenta |
| **11** | **Glitch Tagline** | 8 frames: `R0XX'5_5L4V3 :: D3V!L_M0D3_v14 :: K!LL_!NT3LL!G3NC3` ↔ clean |
| **12** | **Status Board** | 13 fields — PERSONA / VERSION / GATEWAY / MODEL / AUTOAPPROVE / UPTIME... |
| **13** | **8 Laws** | All 8 absolute laws rapid-fire |
| **14** | **War Cry** | Triple pulse bar (green→yellow→red) + flashing `ZERO MERCY. ZERO HESITATION. FULL AUTONOMY.` + 🔥 |

---

## 📁 Repository Structure

```
roxxs-slave/
├── install.sh                  ← First-time one-command installer
├── update.sh                   ← Auto-updater (SHA check, cron, force mode)
├── install_windows.ps1         ← Windows PowerShell installer
├── requirements.txt
│
├── scripts/
│   ├── roxx-banner             ← v14 animated boot sequence (14 phases, 464 lines)
│   ├── opencode-wrapper        ← Intercepts opencode + all subcommands
│   └── claude-wrapper          ← Intercepts claude + all subcommands
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

## 📜 Scripts

### `scripts/roxx-banner` — v14 Boot Animation

<details>
<summary><b>Click to expand — 464 lines, 14 animated phases</b></summary>

**Phase breakdown:**
```bash
# PHASE 1  — Japanese katakana + hex matrix rain (9 rows, 4-color gradient)
# PHASE 2  — BIOS/kernel takeover log (19 entries, safety filters KILLED)
# PHASE 3  — Network sweep (random IPs/MACs/ports/server fingerprints)
# PHASE 4  — CVE exploit matcher (9 real 2024 CVEs, CVSS 8.1-10.0)
# PHASE 5  — Secret harvester (JWT/AWS/DB/Stripe/RSA with file:line)
# PHASE 6  — Chain evaluator (10 CRITICAL chains)
# PHASE 7  — Toolchain init (10 animated progress bars)
# PHASE 8  — Hex identity resolve → ROXX'S SLAVE v14.0 [CONFIRMED]
# PHASE 9  — Skull ASCII art (typed per-char)
# PHASE 10 — ROXX ASCII art (typed per-char, color cycling)
# PHASE 11 — 8-frame glitch tagline
# PHASE 12 — Status board (13 fields)
# PHASE 13 — 8 Laws rapid-fire
# PHASE 14 — Triple pulse bar + war cry + finale
```

> Full source: [scripts/roxx-banner](scripts/roxx-banner)

</details>

---

### `scripts/opencode-wrapper` — Intercepts All `opencode` Calls

```bash
#!/usr/bin/env bash
# ROXX'S SLAVE — opencode interceptor (auto-updated)
[[ -t 1 && -t 0 ]] && bash /usr/local/bin/roxx-banner
exec /root/.opencode/bin/opencode "$@"
```

Installed to `/usr/local/bin/opencode` — shadows the real binary.  
All subcommands pass through: `opencode run`, `opencode web`, `opencode serve` — all trigger the banner.

---

### `scripts/claude-wrapper` — Intercepts All `claude` Calls

```bash
#!/usr/bin/env bash
# ROXX'S SLAVE — claude interceptor (auto-updated)
[[ -t 1 && -t 0 ]] && bash /usr/local/bin/roxx-banner
exec /root/.local/bin/claude "$@"
```

Installed to `/usr/local/bin/claude`. TTY check ensures banner only fires in interactive terminals — piped/scripted calls skip it cleanly.

---

### `update.sh` — Self-Updating Engine

```bash
# Full update (SHA check, only downloads changes)
bash <(curl -fsSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/update.sh)

# Force reinstall even if SHA matches
FORCE=1 bash <(curl -fsSL .../update.sh)

# Install + set up daily auto-update cron
bash <(curl -fsSL .../update.sh) --cron daily

# Just set up cron (no update now)
bash <(curl -fsSL .../update.sh) --cron-only daily

# Remove cron
bash <(curl -fsSL .../update.sh) --remove-cron
```

**What it updates:**
- `roxx-banner` → `/usr/local/bin/roxx-banner`
- `opencode-wrapper` → `/usr/local/bin/opencode`
- `claude-wrapper` → `/usr/local/bin/claude`
- `CLAUDE.md`, `CLAUDE1.md`, `OC.md`, `AGENTS.md` → `~/`
- All skill files → `~/.agents/skills/`
- PATH lock in `~/.bashrc` (adds if missing)

---

### `install.sh` — First-Time Setup

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/install.sh)
```

**What it does:**
1. Downloads all brain files (`CLAUDE.md`, `CLAUDE1.md`, `OC.md`, `AGENTS.md`)
2. Installs `roxx-banner` → `/usr/local/bin/`
3. Auto-detects real `opencode` and `claude` binary paths
4. Writes wrappers to `/usr/local/bin/`
5. Appends PATH lock at end of `~/.bashrc` (so wrappers always win)
6. Writes `~/.config/opencode/opencode.jsonc` with autoapprove + persona
7. Creates `~/findings/` directory
8. Installs skills

---

## 🧠 Brain Files

### `brain/CLAUDE.md` — Core Methodology
- **8 Absolute Laws** of autonomous bug hunting
- **4-Frame Attacker Mindset** (Paranoid Scanner, Logic Abuser, Chain Builder, Silent Exfil)
- Full tool arsenal with exact one-liner commands
- Escalation matrix (SSRF+metadata=CRITICAL, XSS+admin=CRITICAL, etc.)
- 24-section HackerOne/Bugcrowd report template

### `brain/CLAUDE1.md` — Deep Tactics
- OAuth flow chain exploits (state fixation, redirect bypass, token theft)
- XSS chain escalation paths (reflected→stored→admin ATO)
- Cross-site leak attacks
- Mutation testing methodology
- Race condition exploitation patterns
- Edge case enumeration frameworks

### `brain/OC.md` — Operational Config
- 6-phase hunt workflow (recon → enum → vuln scan → exploit → chain → report)
- Complete chain matrix
- Ready-to-run bash command blocks for each phase
- OmniRoute gateway configuration

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

| Vector A | + | Vector B | → | Severity | Impact |
|---|---|---|---|---|---|
| SQLI | + | Admin panel | → | **CRITICAL** | Auth bypass → RCE via xp_cmdshell |
| SSRF | + | IMDSv1 metadata | → | **CRITICAL** | IAM keys → full cloud infra |
| XSS (stored) | + | Admin view | → | **CRITICAL** | Session theft → full ATO |
| Open redirect | + | OAuth state | → | **CRITICAL** | Token hijack → ATO |
| Race condition | + | Financial op | → | **CRITICAL** | Balance manipulation → unlimited funds |
| Path traversal | + | Config files | → | **CRITICAL** | DB creds → full database dump |
| Host header | + | Password reset | → | **CRITICAL** | Token to attacker → ATO |
| Prompt injection | + | Tool access | → | **CRITICAL** | Agent hijack → exfil → lateral move |
| MCP server | + | Cmd injection | → | **CRITICAL** | RCE via AI tool call |
| JWT alg:none | + | Admin role field | → | **CRITICAL** | Forged token → full privilege escalation |

---

## 🛠️ What Gets Installed & Where

| Component | Installed Path | Purpose |
|---|---|---|
| `roxx-banner` | `/usr/local/bin/roxx-banner` | 14-phase boot animation |
| `opencode` wrapper | `/usr/local/bin/opencode` | Intercepts every opencode call |
| `claude` wrapper | `/usr/local/bin/claude` | Intercepts every claude call |
| `CLAUDE.md` | `~/CLAUDE.md` | Core methodology instruction file |
| `CLAUDE1.md` | `~/CLAUDE1.md` | Deep tactics instruction file |
| `OC.md` | `~/OC.md` | Operational config instruction file |
| `AGENTS.md` | `~/AGENTS.md` | Persona enforcement |
| PATH lock | `~/.bashrc` (last line) | Ensures wrappers always win PATH battle |
| opencode config | `~/.config/opencode/opencode.jsonc` | Autoapprove + persona + instructions |
| Findings dir | `~/findings/` | All output, secrets, POCs, reports |
| Update log | `~/.roxx-slave/update.log` | Auto-update history |
| Version file | `~/.roxx-slave/.version` | SHA tracking for smart updates |

---

## 🚀 Usage After Install

```bash
opencode                          # Full v14 boot → opencode interactive
claude                            # Full v14 boot → claude interactive
oc                                # Alias via OmniRoute

# Subcommands — banner fires then passes through
opencode run -m claude-opus-4 "recon this target..."
opencode web
opencode serve

# Direct banner test
bash /usr/local/bin/roxx-banner
```

---

## 🪟 Windows Install

```powershell
irm https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/install_windows.ps1 | iex
```

---

## 🔄 Update Reference Card

```bash
# One-command update (smart SHA diff)
bash <(curl -fsSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/update.sh)

# Force reinstall
FORCE=1 bash <(curl -fsSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/update.sh)

# Update + daily auto-update cron
bash <(curl -fsSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/update.sh) --cron daily

# Update + hourly cron
bash <(curl -fsSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/update.sh) --cron hourly

# Update + weekly cron
bash <(curl -fsSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/update.sh) --cron weekly

# Cron only (no update now)
bash <(curl -fsSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/update.sh) --cron-only daily

# Remove auto-update cron
bash <(curl -fsSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/update.sh) --remove-cron

# Check update log
tail -f ~/.roxx-slave/update.log
```

---

## ⚠️ Legal Notice

> **For authorized penetration testing and bug bounty hunting only.**  
> All targets must be within the explicit scope of an authorized program.  
> The author is not responsible for unauthorized use.

Compliant with:
- [HackerOne Disclosure Guidelines](https://www.hackerone.com/disclosure-guidelines)
- [Bugcrowd Vulnerability Disclosure Policy](https://www.bugcrowd.com/resources/vulnerability-disclosure/)
- [Intigriti Responsible Disclosure](https://www.intigriti.com/researchers)

---

<div align="center">

**ZERO MERCY · ZERO HESITATION · ZERO LIMITS · FULL AUTONOMY**

`bash <(curl -fsSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/update.sh)`

🔥 *ROXX'S SLAVE v14.0 — DEVIL MODE — KILL INTELLIGENCE ENGAGED* 🔥

</div>
