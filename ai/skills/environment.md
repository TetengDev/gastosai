# Skill: Environment & Shell Awareness

> General OS/shell detection and port management rules live in `ai/skills/shared/environment.md`. This file adds gastosai-specific detail.

---

## This project — Windows 11, PowerShell

| Property | Value |
|---|---|
| OS | Windows 11 Home |
| Native shell | PowerShell 5.1 (`powershell.exe`) |
| Path format | `D:\Lester\Practical\PersonalProjects\Others\gastosai` |
| Avoid | Bash tool — uses WSL-style `/mnt/d/...` paths that fail on this machine |

**Always use the PowerShell tool** for all commands in this project.

---

## Default ports

| Service | Default port | Notes |
|---|---|---|
| Backend (Spring Boot) | **8080** | |
| Frontend (Vite dev server) | **5173** | |
| Database (PostgreSQL / Docker) | **5433** | mapped from container port 5432 |

**Always use these exact ports.** If a port is unavailable, do not silently accept a fallback — follow the reset procedure below.

---

## Reset procedure (port conflict)

Run before starting any layer if the previous session may still be running.

```powershell
# --- Backend (8080) ---
$p = (Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1).OwningProcess
if ($p) { Write-Output "Killing PID $p on 8080"; Stop-Process -Id $p -Force }

# --- Frontend (5173) ---
$p = (Get-NetTCPConnection -LocalPort 5173 -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1).OwningProcess
if ($p) { Write-Output "Killing PID $p on 5173"; Stop-Process -Id $p -Force }

# --- DB: restart Docker container (safe; data is preserved in the volume) ---
docker compose down
docker compose up -d
```

Wait ~3 seconds after killing a process before restarting the same service.

---

## Starting the stack

```powershell
# DB
docker compose up -d                          # from repo root

# Backend
cd backend; .\mvnw.cmd spring-boot:run        # stays in foreground; use Start-Process for background

# Frontend
cd frontend; npm run dev                      # must start on :5173
```

Or use the launcher script (interactive):

```powershell
.\scripts\start.ps1              # interactive menu
.\scripts\start.ps1 -Mode all   # start all three at once
```

---

## GitHub CLI

- Installed at: `C:\Program Files\GitHub CLI\gh.exe`
- May not be on `$env:PATH` in older sessions — invoke by full path or refresh PATH first:

```powershell
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
```

- Authentication token stored in repo root `.env` as `GITHUB_TOKEN`. Load it with:

```powershell
$env:GH_TOKEN = (Get-Content "D:\Lester\Practical\PersonalProjects\Others\gastosai\.env" |
    Select-String "GITHUB_TOKEN=(.+)" |
    ForEach-Object { $_.Matches[0].Groups[1].Value })
```

---

## Project commands quick reference

| Task | Command | Directory |
|---|---|---|
| Start DB | `docker compose up -d` | repo root |
| Stop DB | `docker compose down` | repo root |
| Start backend | `.\mvnw.cmd spring-boot:run` | `backend/` |
| Run backend tests | `.\mvnw.cmd test` | `backend/` |
| Compile backend | `.\mvnw.cmd compile` | `backend/` |
| Start frontend | `npm run dev` | `frontend/` |
| Lint frontend | `npm run lint` | `frontend/` |
| Build frontend | `npm run build` | `frontend/` |
| Full stack (script) | `.\scripts\start.ps1 -Mode all` | repo root |
| Teardown | `.\scripts\teardown.ps1 -All -Force` | repo root |
