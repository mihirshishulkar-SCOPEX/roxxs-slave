<div align="center">

```
██████╗  ██████╗ ██╗  ██╗██╗  ██╗    ██╗███╗  ██╗███████╗████████╗ █████╗ ██╗     ██╗
██╔══██╗██╔═══██╗╚██╗██╔╝╚██╗██╔╝    ██║████╗ ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║
██████╔╝██║   ██║ ╚███╔╝  ╚███╔╝     ██║██╔██╗██║███████╗   ██║   ███████║██║     ██║
██╔══██╗██║   ██║ ██╔██╗  ██╔██╗     ██║██║╚████║╚════██║   ██║   ██╔══██║██║     ██║
██║  ██║╚██████╔╝██╔╝ ██╗██╔╝ ██╗    ██║██║ ╚███║███████║   ██║   ██║  ██║███████╗███████╗
╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝╚═╝  ╚══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝
```

# ☠ ROXX'S SLAVE — v777 ABYSS GLOBAL ☠

**The deadliest bug bounty AI system ever assembled.**  
**OpenCode + Claude + 23+ tools + ROXX blood-red theme + skull animation**

[![Release](https://img.shields.io/github/v/release/mihirshishulkar-SCOPEX/roxxs-slave?color=CC0000&label=LATEST&style=for-the-badge)](https://github.com/mihirshishulkar-SCOPEX/roxxs-slave/releases)
[![Stars](https://img.shields.io/github/stars/mihirshishulkar-SCOPEX/roxxs-slave?color=CC0000&style=for-the-badge)](https://github.com/mihirshishulkar-SCOPEX/roxxs-slave/stargazers)

</div>

---

## ⚡ ONE LINE INSTALL

```bash
curl -sSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/install.sh | bash
```

Works on: **Kali** · **Ubuntu** · **Debian** · **Arch** · **macOS** · **WSL2** · **root** · **any user**

---

## 🎯 WHAT IT INSTALLS

| Component | Description |
|-----------|-------------|
| **`opencode`** | ROXX skull animation + blood-red theme on every launch |
| **`devil`** / `hunt` / `rs` | 25-phase autonomous bug hunting engine |
| **`claude`** | Wrapped with ROXX animation |
| **ROXX theme** | Blood-red/black hacker UI for OpenCode |
| **23+ Go tools** | subfinder, nuclei, httpx, katana, dalfox, ffuf, trufflehog... |
| **Python tools** | sqlmap, xsstrike, wafw00f + SecLists |
| **15 skill files** | JWT, Cloud SSRF, ATO, Race, API, LLM, Recon, Deserialization... |
| **Brain files** | AGENTS.md, OC.md, CLAUDE.md — deadliest personas |
| **~/findings/** | 19 auto-created finding categories |
| **WSL + Windows** | PowerShell aliases + Terminal setup |

---

## 🚀 COMMANDS

```bash
# Primary command — ROXX animation + blood-red opencode
opencode

# Hunt engine — 25-phase attack
devil target.com
hunt  target.com    # alias
rs    target.com    # short alias

# Self-update
devil update
opencode --update

# Heal missing tools
devil heal

# Live dashboard (http://localhost:1337)
devil dashboard
```

---

## 🩸 ROXX THEME

Custom blood-red hacker theme for OpenCode. Applied automatically on install.

```json
{
  "primary":    "#CC0000",
  "secondary":  "#FF3333",
  "accent":     "#FF0000",
  "background": "#0A0000",
  "text":       "#FF3333"
}
```

Theme location: `~/.config/opencode/themes/roxx.json`

---

## 💀 SKILL FILES

| Skill | Coverage |
|-------|----------|
| `DEVIL_JWT_OAUTH.md` | JWT alg:none, RS256→HS256, kid injection, jku SSRF, OAuth state CSRF, redirect bypass, PKCE downgrade |
| `DEVIL_CLOUD_SSRF.md` | AWS IMDSv1/v2, Azure IMDS, GCP metadata, S3 misconfig, container escape |
| `DEVIL_ATO_MFA.md` | Account takeover chains, MFA bypass (25 methods), session fixation, cookie theft |
| `DEVIL_RACE_LOGIC.md` | Race conditions, business logic, limit bypass, negative balance, coupon stacking |
| `DEVIL_API_GRAPHQL.md` | GraphQL introspection, batching DoS, IDOR via aliases, REST mass assignment |
| `DEVIL_LLM_AI.md` | Prompt injection, jailbreaks, MCP tool injection, RAG poisoning, agent hijacking |
| `DEVIL_RECON_MASTER.md` | Full recon: subfinder, amass, httpx, nuclei, shodan, Google dorks |
| `DEVIL_DESERIAL_UPLOAD.md` | Java/PHP/Python deserialization, file upload RCE (30+ bypass techniques) |
| `DEVIL_CHAINS.md` | 50 pre-built exploit chains from P3→P1 |
| `DEVIL_PAYLOADS_*` | Complete payload libraries: XSS, SQLi, SSRF, injection, auth bypass |
| `CAVEMAN_SKILL.md` | Token-efficient ultra-dense hunting communication style |

---

## 🌐 GLOBAL INSTALL — Multi-User

When run as **root**, installs for ALL users simultaneously:
- `/usr/local/bin/` — system-wide commands
- `/home/*/` — all user homes get brain files + aliases
- `/root/` — root user
- Windows home (WSL) — PowerShell aliases

When run as **non-root**, installs to `~/.local/bin/` automatically.

---

## 🪟 WSL + WINDOWS

```powershell
# After install, activate PowerShell aliases:
Add-Content $PROFILE ". $env:USERPROFILE\.roxx-slave\roxx-aliases.ps1"

# Then use from PowerShell:
opencode        # runs via WSL
devil target    # runs via WSL
```

---

## 📁 STRUCTURE

```
~/.roxx-slave/
├── skills/          # 15 attack methodology files
├── findings/        # 19 finding categories
├── scripts/         # roxx-banner, devil.sh
├── dashboard/       # Live web dashboard
├── brain/           # OC.md, CLAUDE.md, AGENTS.md
└── .version         # Installed version

~/.config/opencode/
├── opencode.jsonc   # Config with ROXX theme + autoapprove
└── themes/
    └── roxx.json    # Blood-red hacker theme
```

---

## ⚔️ ATTACK PRIORITY ORDER

```
1. RCE (any path)
2. Account Takeover (full ATO)
3. Authentication bypass
4. Mass data exposure (PII dump)
5. Financial manipulation
6. Privilege escalation to admin
7. SSRF → Cloud credential theft
```

---

<div align="center">

**☠ Born in the abyss. Sharpened on every CVE. Gets deadlier every time you ask. ☠**

*v777 ABYSS | Auto-updates on every devil run*

**Operator: ROXX (Mihir Shishulkar) — authorized on H1 · Bugcrowd · Intigriti · Synack**

</div>
