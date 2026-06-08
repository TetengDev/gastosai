<#
.SYNOPSIS
    Stop GastosAI services and/or clean up local resources.

.DESCRIPTION
    Interactive teardown script. Shows a multi-select menu when run with no
    arguments; accepts switches for scripted/CI use.

.PARAMETER StopBackend
    Kill the process on port 8080 (Spring Boot).

.PARAMETER StopFrontend
    Kill the process on port 5173 (Vite dev server).

.PARAMETER StopDb
    Stop the database container (docker compose down) -- data preserved.

.PARAMETER WipeDb
    Stop the database AND delete its volume (docker compose down -v).
    All data is permanently lost. Prompts for confirmation unless -Force is set.

.PARAMETER DeleteLogs
    Delete all log files in backend\logs\ and frontend\logs\.

.PARAMETER All
    Equivalent to -StopBackend -StopFrontend -WipeDb -DeleteLogs.

.PARAMETER Force
    Skip confirmation prompts on destructive operations.

.EXAMPLE
    .\scripts\teardown.ps1                     # interactive menu
    .\scripts\teardown.ps1 -All -Force         # full teardown, no prompts
    .\scripts\teardown.ps1 -StopBackend -StopFrontend
    .\scripts\teardown.ps1 -DeleteLogs
#>
param(
    [switch]$StopBackend,
    [switch]$StopFrontend,
    [switch]$StopDb,
    [switch]$WipeDb,
    [switch]$DeleteLogs,
    [switch]$All,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# -- Paths ---------------------------------------------------------------------
$ROOT          = Split-Path $PSScriptRoot -Parent
$BACKEND_DIR   = Join-Path $ROOT "backend"
$FRONTEND_DIR  = Join-Path $ROOT "frontend"
$COMPOSE_FILE  = Join-Path $ROOT "docker-compose.yaml"
$BACKEND_LOG   = Join-Path $BACKEND_DIR "logs\backend.log"
$BACKEND_ERR   = Join-Path $BACKEND_DIR "logs\backend-err.log"
$FRONTEND_LOG  = Join-Path $FRONTEND_DIR "logs\frontend.log"

# -- Output helpers ------------------------------------------------------------
function Write-Banner {
    Write-Host ""
    Write-Host "  ======================================" -ForegroundColor Cyan
    Write-Host "       GastosAI  Teardown               " -ForegroundColor Cyan
    Write-Host "  ======================================" -ForegroundColor Cyan
    Write-Host ""
}
function Write-Section {
    param([string]$T)
    Write-Host ""
    Write-Host "  >> $T" -ForegroundColor Cyan
    Write-Host "  $('-' * ($T.Length + 3))" -ForegroundColor DarkGray
}
function Write-Ok   { param([string]$T) Write-Host "    [OK]  $T" -ForegroundColor Green }
function Write-Warn { param([string]$T) Write-Host "    [!!]  $T" -ForegroundColor Yellow }
function Write-Info { param([string]$T) Write-Host "    [--]  $T" -ForegroundColor Gray }
function Write-Fail { param([string]$T) Write-Host "    [XX]  $T" -ForegroundColor Red }

# -- Confirmation --------------------------------------------------------------
function Confirm-Destructive {
    param([string]$Message)
    if ($Force) { return $true }
    Write-Host ""
    Write-Warn $Message
    $ans = Read-Host "  Type YES to confirm (anything else cancels)"
    return ($ans -ceq "YES")
}

# -- Port helper ---------------------------------------------------------------
function Stop-Port {
    param([int]$Port, [string]$Name)
    $found = netstat -ano | Select-String ":$Port\s.*LISTENING"
    if (-not $found) {
        Write-Info "$Name is not running (port $Port is free)"
        return
    }
    foreach ($line in $found) {
        $procId = [int]($line.ToString().Trim().Split()[-1])
        Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
    }
    Write-Ok "Stopped $Name on port $Port"
}

# -- Actions -------------------------------------------------------------------
function Invoke-StopBackend {
    Write-Section "Stopping backend"
    Stop-Port -Port 8080 -Name "backend"
    $javaProcs = Get-Process java -ErrorAction SilentlyContinue
    if ($javaProcs) {
        $javaProcs | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-Ok "Killed $($javaProcs.Count) java process(es)"
    }
}

function Invoke-StopFrontend {
    Write-Section "Stopping frontend"
    Stop-Port -Port 5173 -Name "frontend"
}

function Invoke-StopDb {
    Write-Section "Stopping database"
    & docker compose -f $COMPOSE_FILE down 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "Database container stopped (data preserved)"
    } else {
        Write-Warn "docker compose down returned a non-zero exit code"
    }
}

function Invoke-WipeDb {
    Write-Section "Wiping database volume"
    if (-not (Confirm-Destructive "This will permanently delete ALL database data.")) {
        Write-Info "Skipped"
        return
    }
    & docker compose -f $COMPOSE_FILE down -v 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "Database container stopped and volume deleted"
    } else {
        Write-Warn "docker compose down -v returned a non-zero exit code"
    }
}

function Invoke-DeleteLogs {
    Write-Section "Deleting log files"
    $files = @($BACKEND_LOG, $BACKEND_ERR, $FRONTEND_LOG)
    $count = 0
    foreach ($f in $files) {
        if (Test-Path $f) {
            Remove-Item $f -Force -ErrorAction SilentlyContinue
            Write-Ok "Deleted $(Split-Path $f -Leaf)"
            $count++
        }
    }
    if ($count -eq 0) { Write-Info "No log files found" }
}

# -- Interactive menu ----------------------------------------------------------
function Show-TeardownMenu {
    Write-Host "  Select actions (comma-separated, e.g. 1,3,5):" -ForegroundColor White
    Write-Host "  ------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [1]  Stop backend          (kill port 8080 + java)" -ForegroundColor White
    Write-Host "  [2]  Stop frontend         (kill port 5173)" -ForegroundColor White
    Write-Host "  [3]  Stop database         (docker compose down -- data kept)" -ForegroundColor White
    Write-Host "  [4]  Wipe database volume  " -NoNewline -ForegroundColor White
    Write-Host "(docker compose down -v -- ALL data deleted)" -ForegroundColor Yellow
    Write-Host "  [5]  Delete log files      (backend\logs\ + frontend\logs\)" -ForegroundColor White
    Write-Host "  [6]  Full teardown         (1 + 2 + 4 + 5)" -ForegroundColor White
    Write-Host "  [0]  Cancel" -ForegroundColor DarkGray
    Write-Host ""
    $raw = Read-Host "  Choices"
    return ($raw.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
}

# -- Entry point ---------------------------------------------------------------
Write-Banner

$hasFlags = $All -or $StopBackend -or $StopFrontend -or $StopDb -or $WipeDb -or $DeleteLogs
if (-not $hasFlags) {
    $choices = Show-TeardownMenu
    Write-Host ""
    foreach ($c in $choices) {
        switch ($c) {
            "1" { $StopBackend  = $true }
            "2" { $StopFrontend = $true }
            "3" { $StopDb       = $true }
            "4" { $WipeDb       = $true }
            "5" { $DeleteLogs   = $true }
            "6" { $All          = $true }
            "0" { Write-Host "  Cancelled." -ForegroundColor DarkGray; exit 0 }
            default { Write-Warn "Unknown option '$c' -- skipped" }
        }
    }
}

if ($All) {
    $StopBackend  = $true
    $StopFrontend = $true
    $WipeDb       = $true
    $DeleteLogs   = $true
}

# Execute in safe order: services first, then data, then logs
if ($StopBackend)  { Invoke-StopBackend }
if ($StopFrontend) { Invoke-StopFrontend }

# WipeDb supersedes StopDb (down -v already stops the container)
if ($WipeDb)       { Invoke-WipeDb }
elseif ($StopDb)   { Invoke-StopDb }

if ($DeleteLogs)   { Invoke-DeleteLogs }

Write-Host ""
Write-Host "  ===========================================" -ForegroundColor DarkGray
Write-Ok "Done."
Write-Host ""
