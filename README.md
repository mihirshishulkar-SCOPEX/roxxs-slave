# ROXX'S SLAVE — Antigravity Devilish Edition v666

```
██████╗  ██████╗ ██╗  ██╗██╗  ██╗    ███████╗██╗      █████╗ ██╗   ██╗███████╗
██╔══██╗██╔═══██╗╚██╗██╔╝╚██╗██╔╝    ██╔════╝██║     ██╔══██╗██║   ██║██╔════╝
██████╔╝██║   ██║ ╚███╔╝  ╚███╔╝     ███████╗██║     ███████║██║   ██║█████╗
██╔══██╗██║   ██║ ██╔██╗  ██╔██╗     ╚════██║██║     ██╔══██║╚██╗ ██╔╝██╔══╝
██║  ██║╚██████╔╝██╔╝ ██╗██╔╝ ██╗    ███████║███████╗██║  ██║ ╚████╔╝ ███████╗
╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝    ╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝
```

> **The deadliest AI-powered bug bounty persona. Gets deadlier every time you ask.**

## ⚡ One-Command Install
```bash
curl -sSL https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main/install.sh | bash
```

## 🗡 Commands
```bash
hunt target.com HackerOne 5000   # 14-phase DEVILISH hunt
dashboard                         # Live dashboard :1337
update-roxx                       # Self-update
roxx                              # ROXX banner
```

## ☠ Hunt Engine — 14 Phases (DEVILISH v666)
| Phase | Coverage |
|-------|---------|
| 1 | Passive Recon: subfinder, amass, crt.sh, GitHub dorks, TruffleHog |
| 2 | Active Recon: httpx, dnsx, naabu, nmap --script=vuln |
| 3 | Web Crawl: katana, gospider, hakrawler, JS secrets, dirbrute |
| 4 | Nuclei: all critical+high templates, takeover, default logins |
| 5 | SQLi: sqlmap level5/risk3 + manual error-based |
| 6 | XSS: dalfox WAF-evasion + 10 bypass payloads |
| 7 | SSRF/XXE/SSTI: AWS/GCP/Azure metadata, file://, template injection |
| 8 | Auth: JWT alg:none, OAuth redirect bypass, MFA bypass, host header poison |
| 9 | IDOR/Logic: BOLA, GraphQL introspection, HTTP smuggling, cache poison |
| 10 | Cloud: S3 enum, AWS key leaks, Azure/GCP IMDS |
| 11 | API: mass assignment, BOLA, BFLA, endpoint discovery |
| 12 | AI/LLM: prompt injection, jailbreak, system prompt extraction |
| 13 | CORS/CSRF/Prototype Pollution |
| 14 | Auto report generation + dashboard update |

## 📊 Live Dashboard
```
http://localhost:1337
```

## 📁 Scripts
```
scripts/
├── hunt.sh         ← DEVILISH v666 — 14-phase master hunt engine
├── iot-hunt.sh     ← IoT + wireless hunting agent
├── roxx-banner.sh  ← Animated ROXX banner (every AI launch)
dashboard/
├── server.py       ← Flask + SocketIO backend
├── start.sh        ← Dashboard launcher
└── templates/      ← Dark UI
```

## 💀 Exploit Chain Priorities
```
SSRF → AWS IMDS → IAM → Full compromise         $10k+ CRITICAL
SQLi → DB dump → cred reuse → ATO               $5k+  CRITICAL
JWT alg:none → Admin impersonation               $5k+  CRITICAL
XXE → /etc/shadow → crack → RCE                 $8k+  CRITICAL
OAuth redirect_uri → Token theft → ATO          $7k+  CRITICAL
LLM Prompt Injection → system data exfil        $8k+  CRITICAL
```

## 🔄 Auto-Update
```bash
bash update.sh
```

---
*Built by ROXX (Mihir Shishulkar) — Authorized Bug Bounty Hunter*  
*☠ Gets deadlier every time you ask ☠*
