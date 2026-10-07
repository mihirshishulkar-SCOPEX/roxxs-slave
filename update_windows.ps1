# ╔══════════════════════════════════════════════════════════════════════╗
# ║  ROXX'S SLAVE — WINDOWS AUTO-UPDATER v14.0                          ║
# ║  irm https://raw.githubusercontent.com/                             ║
# ║    mihirshishulkar-SCOPEX/roxxs-slave/main/update_windows.ps1 | iex ║
# ╚══════════════════════════════════════════════════════════════════════╝

#Requires -Version 5.0
param(
    [switch]$Force,
    [string]$Cron = "",      # "daily" | "hourly" | "weekly"
    [switch]$CronOnly,
    [switch]$RemoveCron
)

$REPO_RAW  = "https://raw.githubusercontent.com/mihirshishulkar-SCOPEX/roxxs-slave/main"
$INSTALL_DIR = "$HOME\.roxx-slave"
$BIN_DIR   = "$HOME\.roxx-slave\bin"
$LOG_FILE  = "$INSTALL_DIR\update.log"
$VER_FILE  = "$INSTALL_DIR\.version"
$TASK_NAME = "ROXX-SLAVE-AUTO-UPDATE"

function OK   { param($m) Write-Host "  [OK]  $m" -ForegroundColor Green }
function RUN  { param($m) Write-Host "  [>>]  $m" -ForegroundColor Cyan }
function WARN { param($m) Write-Host "  [!!]  $m" -ForegroundColor Yellow }
function NL   { Write-Host "" }
function Log  { param($m) Add-Content -Path $LOG_FILE -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $m" -ErrorAction SilentlyContinue }

function Fetch {
    param($url, $dest)
    $dir = Split-Path $dest
    if ($dir -and !(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    (New-Object System.Net.WebClient).DownloadFile($url, $dest)
}

New-Item -ItemType Directory -Path $INSTALL_DIR -Force | Out-Null

# ── Check version ─────────────────────────────────────────────────────
function Check-Version {
    RUN "Checking for updates..."
    try {
        $commit = Invoke-RestMethod "https://api.github.com/repos/mihirshishulkar-SCOPEX/roxxs-slave/commits/main"
        $script:REMOTE_SHA = $commit.sha.Substring(0,8)
    } catch {
        $script:REMOTE_SHA = "unknown"
    }
    $script:LOCAL_SHA = if (Test-Path $VER_FILE) { Get-Content $VER_FILE -Raw | ForEach-Object { $_.Trim() } } else { "none" }
    Write-Host "  Local SHA : $($script:LOCAL_SHA)" -ForegroundColor DarkGray
    Write-Host "  Remote SHA: $($script:REMOTE_SHA)" -ForegroundColor DarkGray

    if ($script:REMOTE_SHA -eq $script:LOCAL_SHA -and !$Force) {
        NL; OK "Already up to date (SHA: $($script:REMOTE_SHA)). Use -Force to reinstall."
        NL; exit 0
    }
    NL
}

# ── Update scripts ────────────────────────────────────────────────────
function Update-Banner {
    RUN "Updating roxx-banner.ps1..."
    Fetch "$REPO_RAW/scripts/roxx-banner.ps1" "$BIN_DIR\roxx-banner.ps1"
    OK "roxx-banner.ps1 → $BIN_DIR\roxx-banner.ps1"
    Log "Updated roxx-banner.ps1"
}

function Update-Brain {
    RUN "Updating brain files..."
    foreach ($f in @("CLAUDE.md","CLAUDE1.md","OC.md","AGENTS.md")) {
        Fetch "$REPO_RAW/brain/$f" "$HOME\$f"
        OK "$f"
    }
    Copy-Item "$HOME\AGENTS.md" "$HOME\.agents\AGENTS.md" -Force -ErrorAction SilentlyContinue
    Log "Updated brain files"
}

function Update-Skills {
    RUN "Updating skills..."
    $skills = @("CAVEMAN_SKILL.md","DEVIL_CHAINS.md","DEVIL_TACTICS.md","DEVIL_UNIQUE.md",
                "DEVIL_PAYLOADS_ADVANCED.md","DEVIL_PAYLOADS_AUTH_SSRF.md",
                "DEVIL_PAYLOADS_INJECTION.md","DEVIL_PAYLOADS_XSS.md","AGENTS.md")
    foreach ($s in $skills) {
        try { Fetch "$REPO_RAW/skills/$s" "$HOME\.agents\skills\$s"; OK $s }
        catch { WARN "$s not found" }
    }
    Log "Updated skills"
}

function Save-Version {
    $script:REMOTE_SHA | Out-File $VER_FILE -Encoding ASCII
    (Get-Date -Format "yyyy-MM-dd HH:mm:ss") | Out-File "$INSTALL_DIR\.last_updated" -Encoding ASCII
    Log "Version saved: $($script:REMOTE_SHA)"
}

# ── Scheduled Task (Windows equivalent of cron) ───────────────────────
function Setup-ScheduledTask {
    param($interval)
    RUN "Installing Windows Scheduled Task: $interval..."
    $cmd  = "irm $REPO_RAW/update_windows.ps1 | iex"
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -Command `"$cmd`""

    switch ($interval) {
        "hourly" { $trigger = New-ScheduledTaskTrigger -RepetitionInterval (New-TimeSpan -Hours 1) -Once -At (Get-Date) }
        "weekly" { $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "03:00" }
        default  { $trigger = New-ScheduledTaskTrigger -Daily -At "03:00" }
    }

    $settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 10) -RunOnlyIfNetworkAvailable $true

    # Remove old task if exists
    Unregister-ScheduledTask -TaskName $TASK_NAME -Confirm:$false -ErrorAction SilentlyContinue

    Register-ScheduledTask -TaskName $TASK_NAME -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -Force | Out-Null
    OK "Scheduled Task '$TASK_NAME' registered ($interval)"
    Log "Scheduled task set: $interval"
}

function Remove-ScheduledTask {
    Unregister-ScheduledTask -TaskName $TASK_NAME -Confirm:$false -ErrorAction SilentlyContinue
    OK "Scheduled task '$TASK_NAME' removed"
    Log "Scheduled task removed"
}

function Show-Finish {
    NL
    Write-Host ("  " + "═" * 58) -ForegroundColor Red
    OK "ROXX'S SLAVE v14.0 — UPDATED (SHA: $($script:REMOTE_SHA))"
    NL
    Write-Host "  Restart PowerShell, then: opencode / claude / oc" -ForegroundColor Yellow
    Write-Host "  Update log: $LOG_FILE" -ForegroundColor DarkGray
    NL
    Write-Host "  🔥 DEVIL MODE v14 — ALWAYS LATEST" -ForegroundColor Red
    NL
}

# ── MAIN ─────────────────────────────────────────────────────────────
if ($RemoveCron) { Remove-ScheduledTask; exit 0 }
if ($CronOnly -and $Cron) {
    $script:REMOTE_SHA = "cron-only"
    Setup-ScheduledTask $Cron
    OK "Scheduled task installed. Will auto-update $Cron."
    exit 0
}

Check-Version
Update-Banner
Update-Brain
Update-Skills
Save-Version
if ($Cron) { Setup-ScheduledTask $Cron }
Show-Finish
