# Skill: Environment & Shell Awareness

> General OS/shell detection rules live in `ai/skills/shared/environment.md`. This file adds gastosai-specific detail.

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

## GitHub CLI

- Installed at: `C:\Program Files\GitHub CLI\gh.exe`
- May not be on `$env:PATH` in older sessions — invoke by full path or refresh PATH first.
- Authentication token is stored in the repo root `.env` file as `GITHUB_TOKEN`.
- Load it for `gh` with:

```powershell
$env:GH_TOKEN = (Get-Content "D:\Lester\Practical\PersonalProjects\Others\gastosai\.env" |
    Select-String "GITHUB_TOKEN=(.+)" |
    ForEach-Object { $_.Matches[0].Groups[1].Value })
```

---

## Project commands quick reference

| Task | Windows command (run from indicated dir) |
|---|---|
| Start DB | `docker compose up -d` (repo root) |
| Start backend | `.\mvnw.cmd spring-boot:run` (backend/) |
| Run backend tests | `.\mvnw.cmd test` (backend/) |
| Start frontend | `npm run dev` (frontend/) |
| Lint frontend | `npm run lint` (frontend/) |
| Build frontend | `npm run build` (frontend/) |
| Full stack | `.\scripts\start.ps1 -Mode all` (repo root) |
