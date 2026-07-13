<#
.SYNOPSIS
    Start GastosAI services for local development.

.DESCRIPTION
    Interactive launcher for the database, backend, and/or frontend.
    Shows a menu when run with no arguments; accepts flags for scripted use.

.PARAMETER Mode
    One of: all | db | backend | frontend | reset
    "reset" wipes the database volume before starting everything.

.PARAMETER ClearLogs
    Delete existing log files before starting.

.PARAMETER SkipChecks
    Skip the prerequisite check (Java, Node, Docker, .env).

.EXAMPLE
    .\scripts\start.ps1                        # interactive menu
    .\scripts\start.ps1 -Mode all             # start everything non-interactively
    .\scripts\start.ps1 -Mode reset           # wipe DB then start all
    .\scripts\start.ps1 -Mode all -ClearLogs  # clear logs then start all
    .\scripts\start.ps1 -Mode backend -SkipChecks
#>
param(
    [ValidateSet("all", "db", "backend", "frontend", "reset", "docker", "")]
    [string]$Mode = "",

    [switch]$ClearLogs,
    [switch]$SkipChecks
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# ── Paths ──────────────────────────────────────────────────────────────────────
$ROOT         = Split-Path $PSScriptRoot -Parent
$BACKEND_DIR  = Join-Path $ROOT "backend"
$FRONTEND_DIR = Join-Path $ROOT "frontend"
$COMPOSE_FILE = Join-Path $ROOT "docker-compose.yaml"
$MVNW         = Join-Path $BACKEND_DIR "mvnw.cmd"
$ENV_FILE     = Join-Path $ROOT ".env"
$ENV_FILE_LEGACY = Join-Path $BACKEND_DIR ".env"
$LOGS_DIR     = Join-Path $ROOT "logs"
$BACKEND_LOG  = Join-Path $LOGS_DIR "backend.log"
$BACKEND_ERR  = Join-Path $LOGS_DIR "backend-err.log"
$FRONTEND_LOG = Join-Path $LOGS_DIR "frontend.log"

# ── Output helpers ─────────────────────────────────────────────────────────────
function Write-Banner {
    Write-Host ""
    Write-Host "  ======================================" -ForegroundColor Cyan
    Write-Host "       GastosAI  Dev  Launcher          " -ForegroundColor Cyan
    Write-Host "  ======================================" -ForegroundColor Cyan
    Write-Host ""
}
function Write-Section {
    param([string]$T)
    Write-Host ""
    Write-Host "  >> $T" -ForegroundColor Cyan
    Write-Host "  $('-' * ($T.Length + 3))" -ForegroundColor DarkGray
}
function Write-Step { param([string]$T) Write-Host "     > $T" -ForegroundColor DarkGray }
function Write-Ok   { param([string]$T) Write-Host "    [OK]  $T" -ForegroundColor Green }
function Write-Warn { param([string]$T) Write-Host "    [!!]  $T" -ForegroundColor Yellow }
function Write-Fail { param([string]$T) Write-Host "    [XX]  $T" -ForegroundColor Red }
function Write-Info { param([string]$T) Write-Host "    [--]  $T" -ForegroundColor Gray }

# ── Prerequisites ──────────────────────────────────────────────────────────────
function Test-Prerequisites {
    Write-Section "Checking prerequisites"
    $ok = $true

    # Java
    $javaCmd = Get-Command java -ErrorAction SilentlyContinue
    if ($javaCmd) {
        Write-Ok "Java found at $($javaCmd.Source)"
    } else {
        Write-Fail "Java not found -- install JDK 25 from https://adoptium.net"
        $ok = $false
    }

    # Node.js
    $nodeVer = & node --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "Node.js $nodeVer"
    } else {
        Write-Fail "Node.js not found -- install LTS from https://nodejs.org"
        $ok = $false
    }

    # Docker
    & docker info 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "Docker is running"
    } else {
        Write-Fail "Docker is not running -- start Docker Desktop first"
        $ok = $false
    }

    # .env (repo root; legacy backend\.env still honored by the app)
    if (Test-Path $ENV_FILE) {
        Write-Ok ".env found (repo root)"
    } elseif (Test-Path $ENV_FILE_LEGACY) {
        Write-Ok "backend\.env found (legacy location)"
    } else {
        Write-Fail ".env not found -- copy .env.example to the repo root and fill in values"
        $ok = $false
    }

    if (-not $ok) {
        Write-Host ""
        Write-Fail "Fix the issues above then re-run."
        exit 1
    }
}

# ── Log cleanup ────────────────────────────────────────────────────────────────
function Clear-Logs {
    Write-Section "Clearing log files"
    $files = @($BACKEND_LOG, $BACKEND_ERR, $FRONTEND_LOG)
    $count = 0
    foreach ($f in $files) {
        if (Test-Path $f) {
            Remove-Item $f -Force
            Write-Ok "Deleted $(Split-Path $f -Leaf)"
            $count++
        }
    }
    if ($count -eq 0) { Write-Info "No log files to delete" }
}

# ── Port helper ────────────────────────────────────────────────────────────────
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
    Start-Sleep -Milliseconds 500
    Write-Ok "Stopped $Name on port $Port"
}

# ── Database ───────────────────────────────────────────────────────────────────
function Start-Database {
    Write-Section "Database"
    Write-Step "Starting PostgreSQL 17 container..."
    & docker compose -f $COMPOSE_FILE up -d 2>&1 | Out-Null

    Write-Step "Waiting for Postgres to accept connections..."
    $ready = $false
    for ($i = 0; $i -lt 15; $i++) {
        Start-Sleep -Seconds 2
        $r = & docker exec gastosai-db-1 pg_isready -U postgres 2>&1
        if ($r -match "accepting connections") { $ready = $true; break }
    }
    if ($ready) {
        Write-Ok "PostgreSQL ready on localhost:5433"
    } else {
        Write-Fail "PostgreSQL did not become ready -- check Docker Desktop"
        exit 1
    }
}

function Reset-Database {
    Write-Section "Resetting database"
    Write-Step "Wiping Docker volume (all data will be deleted)..."
    & docker compose -f $COMPOSE_FILE down -v 2>&1 | Out-Null
    Write-Ok "Database volume wiped"
}

# ── Backend ────────────────────────────────────────────────────────────────────
function Start-Backend {
    Write-Section "Backend"
    Stop-Port -Port 8080 -Name "backend"
    Get-Process java -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500

    if (-not (Test-Path $LOGS_DIR)) { New-Item -ItemType Directory -Path $LOGS_DIR | Out-Null }
    Write-Step "Starting Spring Boot (logs -> logs\backend.log)..."

    Start-Process -NoNewWindow -FilePath $MVNW `
        -ArgumentList "spring-boot:run", "-Dspring-boot.run.jvmArguments=-XX:ErrorFile=`"$LOGS_DIR\hs_err_%p.log`"" `
        -WorkingDirectory $BACKEND_DIR `
        -RedirectStandardOutput $BACKEND_LOG `
        -RedirectStandardError  $BACKEND_ERR

    Write-Step "Waiting for startup (up to 90s)..."
    $deadline = (Get-Date).AddSeconds(90)
    $result   = "timeout"
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 3
        $content = Get-Content $BACKEND_LOG -Raw -ErrorAction SilentlyContinue
        if ($content -match "Started GastosaiApplication")       { $result = "ok";     break }
        if ($content -match "APPLICATION FAILED|already in use") { $result = "failed"; break }
    }

    switch ($result) {
        "ok" {
            Write-Ok "Backend ready   -> http://localhost:8080"
            Write-Info "Swagger UI    -> http://localhost:8080/swagger-ui.html"
        }
        "failed" {
            Write-Fail "Backend failed to start -- check logs\backend.log"
            exit 1
        }
        "timeout" {
            Write-Warn "Backend did not report ready within 90s (may still be compiling)"
            Write-Info "Tail the log: Get-Content logs\backend.log -Wait"
        }
    }
}

# ── Full Docker stack ──────────────────────────────────────────────────────────
function Start-FullDockerStack {
    Write-Section "Full Docker Stack"

    Stop-Port -Port 8080 -Name "backend (native)"
    Stop-Port -Port 5173 -Name "frontend (native)"
    Get-Process java -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

    Write-Step "Building and starting all services via docker compose --profile app (first build may take a few minutes)..."
    $composeOut = & docker compose -f $COMPOSE_FILE --profile app up -d --build 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "docker compose failed -- check Docker Desktop"
        $composeOut | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
        exit 1
    }
    Write-Ok "Containers started"

    Write-Step "Waiting for backend (up to 120s)..."
    $deadline = (Get-Date).AddSeconds(120)
    $backendReady = $false
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 3
        try {
            $r = Invoke-WebRequest -Uri "http://localhost:8080/actuator/info" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
            if ($r.StatusCode -eq 200) { $backendReady = $true; break }
        } catch { }
    }
    if ($backendReady) {
        Write-Ok "Backend ready   -> http://localhost:8080"
        Write-Info "Swagger UI    -> http://localhost:8080/swagger-ui.html"
    } else {
        Write-Warn "Backend did not become ready in 120s"
        Write-Info "Check logs:  docker compose logs backend"
    }

    Write-Step "Waiting for frontend (up to 30s)..."
    $deadline = (Get-Date).AddSeconds(30)
    $frontendReady = $false
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 2
        try {
            $r = Invoke-WebRequest -Uri "http://localhost:5173" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
            if ($r.StatusCode -eq 200) { $frontendReady = $true; break }
        } catch { }
    }
    if ($frontendReady) {
        Write-Ok "Frontend ready  -> http://localhost:5173"
    } else {
        Write-Warn "Frontend did not become ready in 30s"
        Write-Info "Check logs:  docker compose logs frontend"
    }
}

# ── Frontend ───────────────────────────────────────────────────────────────────
function Start-Frontend {
    Write-Section "Frontend"
    Stop-Port -Port 5173 -Name "frontend"

    if (-not (Test-Path $LOGS_DIR)) { New-Item -ItemType Directory -Path $LOGS_DIR | Out-Null }

    if (-not (Test-Path (Join-Path $FRONTEND_DIR "node_modules"))) {
        Write-Step "node_modules not found -- running npm install..."
        & npm install --prefix $FRONTEND_DIR 2>&1 | Out-Null
        Write-Ok "npm install complete"
    }

    Write-Step "Starting Vite dev server (logs -> logs\frontend.log)..."
    Start-Process -NoNewWindow -FilePath "cmd.exe" `
        -ArgumentList "/c npm run dev > `"$FRONTEND_LOG`" 2>&1" `
        -WorkingDirectory $FRONTEND_DIR

    $deadline = (Get-Date).AddSeconds(20)
    $ready    = $false
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 1
        $content = Get-Content $FRONTEND_LOG -Raw -ErrorAction SilentlyContinue
        if ($content -match "ready in") { $ready = $true; break }
    }

    if ($ready) {
        Write-Ok "Frontend ready  -> http://localhost:5173"
    } else {
        Write-Warn "Frontend did not report ready in time -- check logs\frontend.log"
    }
}

# ── Interactive menu ───────────────────────────────────────────────────────────
function Show-StartMenu {
    Write-Host "  Select what to start:" -ForegroundColor White
    Write-Host "  ------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [1]  All services  (DB -> Backend -> Frontend, native)" -ForegroundColor White
    Write-Host "  [2]  Database only" -ForegroundColor White
    Write-Host "  [3]  Backend only  (native mvnw)" -ForegroundColor White
    Write-Host "  [4]  Frontend only (native npm)" -ForegroundColor White
    Write-Host "  [5]  Reset + start all  " -NoNewline -ForegroundColor White
    Write-Host "(wipes DB volume -- all data deleted)" -ForegroundColor Yellow
    Write-Host "  [6]  Full Docker stack  " -NoNewline -ForegroundColor White
    Write-Host "(DB + Backend + Frontend via docker compose)" -ForegroundColor Cyan
    Write-Host "  [0]  Exit" -ForegroundColor DarkGray
    Write-Host ""
    return (Read-Host "  Choice")
}

# ── Entry point ────────────────────────────────────────────────────────────────
Write-Banner

if (-not $SkipChecks) { Test-Prerequisites }

if ([string]::IsNullOrEmpty($Mode)) {
    $choice = Show-StartMenu
    Write-Host ""
    switch ($choice) {
        "1"     { $Mode = "all" }
        "2"     { $Mode = "db" }
        "3"     { $Mode = "backend" }
        "4"     { $Mode = "frontend" }
        "5"     { $Mode = "reset" }
        "6"     { $Mode = "docker" }
        "0"     { Write-Host "  Cancelled." -ForegroundColor DarkGray; exit 0 }
        default { Write-Fail "Invalid choice '$choice'."; exit 1 }
    }

    if (-not $ClearLogs) {
        Write-Host ""
        $ans = Read-Host "  Clear log files before starting? [y/N]"
        if ($ans -match "^[yY]$") { $ClearLogs = $true }
    }
}

if ($ClearLogs) { Clear-Logs }

switch ($Mode) {
    "all" {
        Start-Database
        Start-Backend
        Start-Frontend
    }
    "db"       { Start-Database }
    "backend"  { Start-Backend }
    "frontend" { Start-Frontend }
    "docker"   { Start-FullDockerStack }
    "reset" {
        Stop-Port -Port 8080 -Name "backend"
        Stop-Port -Port 5173 -Name "frontend"
        Get-Process java -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        if ($ClearLogs) { Clear-Logs }
        Reset-Database
        Start-Database
        Start-Backend
        Start-Frontend
    }
}

Write-Host ""
Write-Host "  ===========================================" -ForegroundColor DarkGray
Write-Ok "All done."
Write-Host ""