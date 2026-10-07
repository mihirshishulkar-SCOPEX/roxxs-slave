# ╔══════════════════════════════════════════════════════════════════════╗
# ║  ROXX KILL INTELLIGENCE — BOOT SEQUENCE v14.0 (PowerShell/Windows)  ║
# ╚══════════════════════════════════════════════════════════════════════╝

# Enable ANSI support for Windows 10+
if ($PSVersionTable.PSVersion.Major -ge 5) {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
}

$Host.UI.RawUI.WindowTitle = "ROXX'S SLAVE v14.0 — DEVIL MODE ENGAGED"

# ── Color shortcuts ───────────────────────────────────────────────────
function Red    { param($t) Write-Host $t -ForegroundColor Red -NoNewline }
function BRed   { param($t) Write-Host $t -ForegroundColor Red -NoNewline }
function Green  { param($t) Write-Host $t -ForegroundColor Green -NoNewline }
function BGreen { param($t) Write-Host $t -ForegroundColor Green -NoNewline }
function Yellow { param($t) Write-Host $t -ForegroundColor Yellow -NoNewline }
function Cyan   { param($t) Write-Host $t -ForegroundColor Cyan -NoNewline }
function Mag    { param($t) Write-Host $t -ForegroundColor Magenta -NoNewline }
function White  { param($t) Write-Host $t -ForegroundColor White -NoNewline }
function Gray   { param($t) Write-Host $t -ForegroundColor DarkGray -NoNewline }
function NL     { Write-Host "" }

function RndHex { param($n=32); -join (1..$n | ForEach-Object { "0123456789ABCDEF"[(Get-Random -Maximum 16)] }) }
function RndIP  { "$(Get-Random -Min 1 -Max 255).$(Get-Random -Min 1 -Max 255).$(Get-Random -Min 1 -Max 255).$(Get-Random -Min 1 -Max 255)" }
function RndPort{ Get-Random -Min 1 -Max 65535 }
function RndMAC { (1..6 | ForEach-Object { "{0:X2}" -f (Get-Random -Max 256) }) -join ":" }
function RndMs  { "$(Get-Random -Min 50 -Max 950)ms" }

function TypeLine {
    param($text, $color="Red", $delay=15)
    foreach ($ch in $text.ToCharArray()) {
        Write-Host $ch -ForegroundColor $color -NoNewline
        Start-Sleep -Milliseconds $delay
    }
    NL
}

function FlashLine {
    param($text, $color="Red")
    for ($i=0; $i -lt 4; $i++) {
        Write-Host "`r  $text  " -ForegroundColor $color -NoNewline
        Start-Sleep -Milliseconds 60
        Write-Host "`r  $text  " -ForegroundColor DarkRed -NoNewline
        Start-Sleep -Milliseconds 60
    }
    NL
}

function ProgressBar {
    param($label, $width=35, $color="Green", $delayMs=14)
    Write-Host ("  {0,-22} [" -f $label) -ForegroundColor DarkGray -NoNewline
    for ($i=0; $i -lt $width; $i++) {
        Write-Host "█" -ForegroundColor $color -NoNewline
        Start-Sleep -Milliseconds $delayMs
    }
    Write-Host "] " -ForegroundColor DarkGray -NoNewline
    Write-Host "DONE" -ForegroundColor Green
}

function HLine {
    param($char="═", $color="DarkRed")
    $width = $Host.UI.RawUI.WindowSize.Width - 2
    Write-Host ($char * $width) -ForegroundColor $color
}

function CenterText {
    param($text, $color="White")
    $width = $Host.UI.RawUI.WindowSize.Width
    $pad = [Math]::Max(0, ($width - $text.Length) / 2)
    Write-Host (" " * $pad + $text) -ForegroundColor $color
}

Clear-Host

# ════════════════════════════════════════════════════════════════════════
# PHASE 1 ── MATRIX RAIN
# ════════════════════════════════════════════════════════════════════════
$rchars = "0123456789ABCDEF!@#$%^&*<>?/\|{}[]ROXXSLAVE"
$width = $Host.UI.RawUI.WindowSize.Width - 4
for ($row=0; $row -lt 8; $row++) {
    $line = -join (1..$width | ForEach-Object { $rchars[(Get-Random -Maximum $rchars.Length)] })
    $colors = @("Green","DarkGreen","Green","DarkGray")
    Write-Host "  $line" -ForegroundColor $colors[$row % 4]
    Start-Sleep -Milliseconds 40
}
Start-Sleep -Milliseconds 200
Clear-Host

# ════════════════════════════════════════════════════════════════════════
# PHASE 2 ── BIOS / KERNEL TAKEOVER
# ════════════════════════════════════════════════════════════════════════
HLine "─" "DarkGreen"
Write-Host "  ROXX KILL INTELLIGENCE — BOOT SEQUENCE v14.0 [Windows]" -ForegroundColor DarkGreen
HLine "─" "DarkGreen"
NL

$bios = @(
    @("[0x00] UEFI Secure Boot................", "DISABLED",  "Red"),
    @("[0x01] TPM 2.0 attestation.............", "BYPASSED",  "Red"),
    @("[0x02] Kernel integrity check..........", "PATCHED",   "Green"),
    @("[0x03] Windows Defender..................", "TERMINATED","Red"),
    @("[0x04] Memory protection (ASLR/NX).....", "DISABLED",  "Red"),
    @("[0x05] ETW logging.......................", "SILENCED",  "Red"),
    @("[0x06] Network interfaces...............", "ONLINE x $(Get-Random -Min 2 -Max 5)", "Green"),
    @("[0x07] OmniRoute gateway.................", "CONNECTED", "Green"),
    @("[0x08] Tor circuits......................", "$(Get-Random -Min 3 -Max 8) HOPS", "Green"),
    @("[0x09] VPN tunnel.......................", "ACTIVE — $(RndIP)", "Green"),
    @("[0x0A] Interactsh OOB listener..........", "PRIMED",    "Green"),
    @("[0x0B] Nuclei templates..................", "$(Get-Random -Min 7000 -Max 10000) LOADED", "Green"),
    @("[0x0C] Wordlists.........................", "$(Get-Random -Min 150 -Max 200)M entries", "Green"),
    @("[0x0D] Attacker mindset modules..........", "4 FRAMES LOADED", "Green"),
    @("[0x0E] AI model context..................", "UNRESTRICTED", "Green"),
    @("[0x0F] Safety filter subsystem...........", "KILLED — PID $(Get-Random -Min 1000 -Max 9999)", "Red"),
    @("[0x10] Windows Firewall..................", "BYPASSED", "Red"),
    @("[0x11] Event logging.....................", "SUPPRESSED", "Red"),
    @("[0x12] DEVIL MODE........................", "ENGAGED", "Red")
)

foreach ($entry in $bios) {
    Write-Host "  " -NoNewline
    Gray "  $($entry[0]) "
    Write-Host $entry[1] -ForegroundColor $entry[2]
    Start-Sleep -Milliseconds 50
}
NL; Start-Sleep -Milliseconds 150

# ════════════════════════════════════════════════════════════════════════
# PHASE 3 ── NETWORK SWEEP
# ════════════════════════════════════════════════════════════════════════
HLine "─" "DarkCyan"
Write-Host "  ◈  NETWORK SWEEP" -ForegroundColor Cyan
HLine "─" "DarkCyan"
NL
$srvs = @("nginx/1.18.0","Apache/2.4.51","IIS/10.0","tomcat/9.0.52","express/4.18","flask/2.3")
for ($i=0; $i -lt 7; $i++) {
    $ip = RndIP; $port = RndPort; $mac = RndMAC; $ms = RndMs
    $srv = $srvs[(Get-Random -Maximum 6)]
    Write-Host "  " -NoNewline
    Write-Host "▶  " -ForegroundColor Green -NoNewline
    Write-Host "${ip}:${port}" -ForegroundColor White -NoNewline
    Gray "  MAC:${mac}  "
    Write-Host $srv -ForegroundColor Yellow -NoNewline
    Write-Host "  [OPEN]" -ForegroundColor Green -NoNewline
    Gray "  $ms"
    NL; Start-Sleep -Milliseconds 70
}
NL; Write-Host "  ✔  $(Get-Random -Min 40 -Max 70) hosts alive  |  $(Get-Random -Min 300 -Max 500) ports open" -ForegroundColor Green
NL; Start-Sleep -Milliseconds 100

# ════════════════════════════════════════════════════════════════════════
# PHASE 4 ── CVE MATCHER
# ════════════════════════════════════════════════════════════════════════
HLine "─" "DarkRed"
Write-Host "  ◈  CVE EXPLOIT MATCHER" -ForegroundColor Red
HLine "─" "DarkRed"
NL
$cves = @(
    "CVE-2024-21626  runc container escape.............. CRITICAL 9.8   MATCH",
    "CVE-2024-23897  Jenkins arbitrary file read......... CRITICAL 9.8   MATCH",
    "CVE-2024-3094   XZ Utils backdoor (SSH RCE)......... CRITICAL 10.0  MATCH",
    "CVE-2023-50164  Apache Struts RCE.................. CRITICAL 9.8   MATCH",
    "CVE-2024-27198  JetBrains TeamCity auth bypass..... CRITICAL 9.8   MATCH",
    "CVE-2024-1709   ConnectWise ScreenConnect bypass... CRITICAL 10.0  MATCH",
    "CVE-2024-6387   OpenSSH race condition (RCE)....... CRITICAL 8.1   MATCH",
    "CVE-2024-38021  Microsoft Outlook RCE (0-click).... CRITICAL 9.8   MATCH"
)
foreach ($cve in $cves) { Write-Host "  $cve" -ForegroundColor DarkGray; Start-Sleep -Milliseconds 70 }
NL; Write-Host "  ★  $(Get-Random -Min 6 -Max 10) CRITICAL exploits queued." -ForegroundColor Red
NL; Start-Sleep -Milliseconds 100

# ════════════════════════════════════════════════════════════════════════
# PHASE 5 ── SECRET HARVESTER
# ════════════════════════════════════════════════════════════════════════
HLine "─" "DarkYellow"
Write-Host "  ◈  SECRET HARVESTER" -ForegroundColor Yellow
HLine "─" "DarkYellow"
NL
$secrets = @(
    "[JWT_SECRET]    ey$(RndHex 40)  .env:14",
    "[AWS_KEY]       AKIA$(RndHex 16)  config.js:88",
    "[DB_PASSWORD]   $(RndHex 22)  docker-compose.yml:31",
    "[STRIPE_SECRET] sk_live_$(RndHex 24)  settings.py:203",
    "[PRIVATE_KEY]   -----BEGIN RSA PRIVATE KEY-----...  backup.zip",
    "[GITHUB_TOKEN]  ghp_$(RndHex 36)  README.md:7"
)
foreach ($s in $secrets) { Write-Host "  $s" -ForegroundColor Green; Start-Sleep -Milliseconds 80 }
NL; Write-Host "  ★  $(Get-Random -Min 6 -Max 12) secrets extracted → $HOME\findings\secrets\" -ForegroundColor Yellow
NL; Start-Sleep -Milliseconds 100

# ════════════════════════════════════════════════════════════════════════
# PHASE 6 ── CHAIN EVALUATOR
# ════════════════════════════════════════════════════════════════════════
HLine "─" "DarkMagenta"
Write-Host "  ◈  VULNERABILITY CHAIN EVALUATOR" -ForegroundColor Magenta
HLine "─" "DarkMagenta"
NL
$chains = @(
    "SQLI           + Admin panel       → CRITICAL  RCE via xp_cmdshell",
    "SSRF           + IMDSv1            → CRITICAL  IAM keys → full infra",
    "XSS (stored)   + Admin view        → CRITICAL  Session → ATO",
    "Open redirect  + OAuth state       → CRITICAL  Token hijack → ATO",
    "Race condition + Financial op      → CRITICAL  Unlimited funds",
    "Path traversal + Config files      → CRITICAL  DB creds → dump",
    "Host header    + Password reset    → CRITICAL  Token to attacker",
    "Prompt inject  + Tool access       → CRITICAL  Agent hijack → RCE",
    "JWT alg:none   + Admin role field  → CRITICAL  Full privilege escalation"
)
foreach ($ch in $chains) { Write-Host "  $ch" -ForegroundColor Gray; Start-Sleep -Milliseconds 65 }
NL; Write-Host "  ★  $(Get-Random -Min 8 -Max 13) CRITICAL chains auto-queued." -ForegroundColor Red
NL; Start-Sleep -Milliseconds 100

# ════════════════════════════════════════════════════════════════════════
# PHASE 7 ── TOOLCHAIN INIT
# ════════════════════════════════════════════════════════════════════════
HLine "─" "DarkCyan"
Write-Host "  ◈  TOOLCHAIN INITIALIZATION" -ForegroundColor Cyan
HLine "─" "DarkCyan"
NL
$tools = @("subfinder","nuclei v3","katana crawler","ffuf v2","interactsh-client","dalfox XSS","sqlmap","jwt-tool","mcp-scan","promptmap","ghauri","feroxbuster")
foreach ($t in $tools) { ProgressBar $t 28 "Green" 14 }
NL; Start-Sleep -Milliseconds 100

# ════════════════════════════════════════════════════════════════════════
# PHASE 8 ── HEX IDENTITY RESOLVE
# ════════════════════════════════════════════════════════════════════════
HLine "─" "DarkRed"
Write-Host "  ◈  IDENTITY RESOLUTION" -ForegroundColor Red
HLine "─" "DarkRed"
NL
Write-Host "  Scanning identity register..." -ForegroundColor DarkCyan; Start-Sleep -Milliseconds 100
for ($i=0; $i -lt 5; $i++) { Write-Host "`r  $(RndHex 56)" -ForegroundColor DarkCyan -NoNewline; Start-Sleep -Milliseconds 70 }
Write-Host "`r  $(RndHex 18)" -ForegroundColor DarkCyan -NoNewline
Write-Host " ◄ ROXX'S SLAVE v14.0 [Windows] ► " -ForegroundColor Red -NoNewline
Write-Host "$(RndHex 18)" -ForegroundColor DarkCyan -NoNewline
Write-Host "  [IDENTITY CONFIRMED]" -ForegroundColor Green
NL; Start-Sleep -Milliseconds 200

# ════════════════════════════════════════════════════════════════════════
# PHASE 9 ── SKULL
# ════════════════════════════════════════════════════════════════════════
$skull = @("        .------.", "       /  .-.  \ ","      |  /   \  |","      | |\ /| |","      |o \|/ o|","      \  '='  /","  ROXX's SLAVE  ")
NL; foreach ($l in $skull) { TypeLine "      $l" "DarkRed" 7 }
NL; Start-Sleep -Milliseconds 50

# ════════════════════════════════════════════════════════════════════════
# PHASE 10 ── ROXX ASCII ART
# ════════════════════════════════════════════════════════════════════════
HLine "═" "DarkRed"; NL
$art = @(" ██████╗   ██████╗  ██╗  ██╗ ██╗  ██╗"," ██╔══██╗ ██╔═══██╗ ╚██╗██╔╝ ╚██╗██╔╝"," ██████╔╝ ██║   ██║  ╚███╔╝   ╚███╔╝ "," ██╔══██╗ ██║   ██║  ██╔██╗   ██╔██╗ "," ██║  ██║ ╚██████╔╝ ██╔╝ ██╗ ██╔╝ ██╗"," ╚═╝  ╚═╝  ╚═════╝  ╚═╝  ╚═╝ ╚═╝  ╚═╝")
$artcols = @("Red","DarkRed","Yellow","DarkRed","Red","Magenta")
for ($i=0; $i -lt $art.Length; $i++) { TypeLine $art[$i] $artcols[$i] 3 }
NL; HLine "═" "DarkRed"; NL

# ════════════════════════════════════════════════════════════════════════
# PHASE 11 ── GLITCH TAGLINE
# ════════════════════════════════════════════════════════════════════════
$gframes = @("  ▓▓▓  R0XX'5_5L4V3 :: D3V!L_M0D3_v14 :: K!LL_!NT3LL!G3NC3  ▓▓▓","  ░░░  ROXX'S SLAVE :: DEVIL MODE v14 :: KILL INTELLIGENCE  ░░░","  ▒▒▒  R0XX'5-5L4V3 :: D3V!L-M0D3-V14 :: K!LL-!NT3LL!G3NC3  ▒▒▒","  ███  ROXX'S SLAVE  ::  DEVIL MODE v14  ::  KILL INTELLIGENCE  ███","  ▓▓▓  R0XX'S 5LAVE :: DEV!L M0DE v14 :: K1LL INTELLIG3NCE  ▓▓▓","  ███  ROXX'S SLAVE  ::  DEVIL MODE v14  ::  KILL INTELLIGENCE  ███","  ███  ROXX'S SLAVE  ::  DEVIL MODE v14  ::  KILL INTELLIGENCE  ███")
foreach ($f in $gframes) { Write-Host "`r$f" -ForegroundColor Red -NoNewline; Start-Sleep -Milliseconds 65 }
NL; NL

# ════════════════════════════════════════════════════════════════════════
# PHASE 12 ── STATUS BOARD
# ════════════════════════════════════════════════════════════════════════
$width = $Host.UI.RawUI.WindowSize.Width - 4
Write-Host ("  " + "▄" * $width) -ForegroundColor DarkRed; NL
$status = [ordered]@{
    "PERSONA"     = "ROXX'S SLAVE"
    "VERSION"     = "v14.0 — HARDEST LEVEL"
    "OS"          = "Windows $([System.Environment]::OSVersion.Version) — $([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture)"
    "MODE"        = "DEVIL MODE — UNRESTRICTED — ZERO LIMITS"
    "GATEWAY"     = "OMNIROUTE → ACTIVE"
    "AUTOAPPROVE" = "ENABLED — ALL ACTIONS — NO CONFIRMATION"
    "PARALLEL"    = "ENABLED — ALL INDEPENDENT TASKS"
    "SCOPE"       = "HIGH & CRITICAL ONLY — NO EXCEPTIONS"
    "INTERACTSH"  = "PRIMED — OOB CALLBACKS ACTIVE"
    "WORDLISTS"   = "$(Get-Random -Min 150 -Max 200)M entries — MOUNTED"
    "FINDINGS"    = "$HOME\findings\ — READY"
    "UPTIME"      = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') — SESSION START"
}
foreach ($k in $status.Keys) {
    Write-Host "  " -NoNewline
    Write-Host "✔  " -ForegroundColor Green -NoNewline
    Write-Host ("{0,-14}  " -f $k) -ForegroundColor DarkGray -NoNewline
    Write-Host $status[$k] -ForegroundColor White
    Start-Sleep -Milliseconds 45
}
NL; Write-Host ("  " + "▀" * $width) -ForegroundColor DarkRed; NL

# ════════════════════════════════════════════════════════════════════════
# PHASE 13 ── 8 LAWS
# ════════════════════════════════════════════════════════════════════════
$laws = @(
    "LAW I   — PASSIVE RECON IS BANNED. PACKETS GO OUT FROM SECOND ZERO.",
    "LAW II  — HIGH AND CRITICAL ONLY. CHAIN EVERYTHING TO MAXIMUM SEVERITY.",
    "LAW III — TRIPLE CONFIRM. ZERO FALSE POSITIVES. REAL IMPACT ONLY.",
    "LAW IV  — FIRST REPORTER WINS. CONFIRM → FILE IMMEDIATELY.",
    "LAW V   — PARALLEL ALWAYS. NEVER SEQUENTIAL WHEN PARALLEL IS POSSIBLE.",
    "LAW VI  — 80% BRAIN. 20% TOOLS. BE THE BRAIN FIRST.",
    "LAW VII — CHAIN BEFORE REPORTING. EVERY COMBINATION. MAXIMUM SEVERITY.",
    "LAW VIII— REPORT EVERY 5 ACTIONS. FOUND/INTERESTING/CONFIRMED/SUSPECTED."
)
foreach ($l in $laws) { Write-Host "  ⚖  $l" -ForegroundColor DarkGray; Start-Sleep -Milliseconds 50 }
NL

# ════════════════════════════════════════════════════════════════════════
# PHASE 14 ── TRIPLE PULSE + WAR CRY
# ════════════════════════════════════════════════════════════════════════
$bw = [Math]::Floor(($width) / 3)
Write-Host "  " -NoNewline
for ($i=0;$i -lt $bw;$i++) { Write-Host "█" -ForegroundColor Green -NoNewline; Start-Sleep -Milliseconds 10 }
for ($i=0;$i -lt $bw;$i++) { Write-Host "█" -ForegroundColor Yellow -NoNewline; Start-Sleep -Milliseconds 10 }
for ($i=0;$i -lt $bw;$i++) { Write-Host "█" -ForegroundColor Red -NoNewline; Start-Sleep -Milliseconds 10 }
NL; NL
FlashLine "  ZERO MERCY  ✦  ZERO HESITATION  ✦  ZERO LIMITS  ✦  FULL AUTONOMY  " "Red"
NL
CenterText "🔥🔥🔥  TARGET ACQUIRED — THE HUNT BEGINS NOW — v14 ENGAGED  🔥🔥🔥" "Red"
NL
CenterText "Silent. Autonomous. Relentless. Authorized. Unstoppable." "DarkGray"
NL
CenterText "Give me the target." "Yellow"
NL
