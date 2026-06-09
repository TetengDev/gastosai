# Skill: Environment & Shell Awareness (Shared)

Use this skill before running any shell command, script, or file-path operation.

---

## Detecting the environment

Before issuing any command, determine the OS and shell:

- **Session info** — Claude Code session header states `Platform: win32 / darwin / linux` and the active shell.
- **Path separators in user messages** — `D:\Users\...` → Windows; `/home/user/...` → Unix.
- **Shell clues in error output** — `/mnt/d/...` paths mean WSL; `C:\...` paths mean native Windows.
- **CLAUDE.md or project notes** — may declare the OS explicitly.

---

## Windows (win32)

- Use the **PowerShell tool**.
- Paths use backslashes: `D:\path\to\project`.
- Environment variables: `$env:VAR_NAME`.
- No `&&` pipeline chaining — use `;` or `if ($?) { ... }` instead.
- No `2>&1` on native executables (wraps stderr as ErrorRecord in PS 5.1).
- CLI tools installed via winget/scoop may not be on `$env:PATH` in older sessions. Search with `where.exe <tool>` or `Get-ChildItem -Filter <tool>.exe -Recurse` before assuming absent.
- To use a tool not on PATH, invoke by full path: `& "C:\Program Files\Tool\tool.exe" args`.
- Refresh PATH in a session without reopening: `$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")`.

## macOS / Linux (darwin / linux)

- Use the **Bash tool**.
- Paths use forward slashes: `/home/user/project`.
- Environment variables: `$VAR_NAME`.
- Standard POSIX chaining (`&&`, `||`, `2>&1`) works normally.

---

## Maven wrapper

| OS | Command |
|---|---|
| Windows | `.\mvnw.cmd <goal>` |
| Unix | `./mvnw <goal>` |

---

---

## Port management

Before starting any server, verify the required port is free. If it is already in use, confirm it is a stale instance of the same app and reset — do not silently fall back to a different port.

### Check and kill (Windows / PowerShell)

```powershell
# Check who owns a port
$owningPid = (Get-NetTCPConnection -LocalPort <PORT> -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1).OwningProcess
if ($owningPid) {
    Get-Process -Id $owningPid -ErrorAction SilentlyContinue   # inspect before killing
    Stop-Process -Id $owningPid -Force
}
```

### Check and kill (Unix / Bash)

```bash
lsof -ti:<PORT> | xargs kill -9 2>/dev/null || true
```

### Rules

- Always use the project's **default ports** — do not accept a fallback port silently.
- Before killing a process, confirm it is a stale instance of the expected app (check the process name).
- After killing, wait briefly (~2 s) for the OS to release the socket before restarting.
- If the port is held by an unrelated process, stop and tell the user rather than killing it blindly.

---

## Rule

Always match the tool and path style to the detected OS. If uncertain, check the session header — do not guess and silently fail.
