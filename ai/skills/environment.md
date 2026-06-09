# Skill: Environment & Shell Awareness

Use this skill before running any shell command, script, or file-path operation.

Choosing the wrong shell or path format causes silent failures and wastes time. Always match the tool to the OS.

---

## Detecting the environment

Before issuing any command, check the platform context:

- **Claude Code session info** — the session header states `Platform: win32 / darwin / linux` and the active shell.
- **`CLAUDE.md` or project notes** — may declare the OS explicitly.
- **Path separators in user messages** — `D:\Lester\...` → Windows; `/home/user/...` → Unix.
- **Shell clues in error output** — `/mnt/d/...` paths mean WSL; `C:\...` paths mean native Windows.

---

## This project — Windows 11, PowerShell

| Property | Value |
|---|---|
| OS | Windows 11 Home |
| Native shell | PowerShell 5.1 (`powershell.exe`) |
| Path format | `D:\Lester\Practical\PersonalProjects\Others\gastosai` |
| Avoid | Bash tool — uses WSL-style `/mnt/d/...` paths that fail on this machine |

**Always use the PowerShell tool** for all commands in this project: git, Maven (`mvnw.cmd`), npm, Docker, file checks.

Only use the Bash tool if the user explicitly requests a POSIX/WSL command.

---

## General rules (any project)

### Windows (win32)

- Use the **PowerShell tool**.
- Paths use backslashes: `D:\path\to\project`.
- Maven wrapper: `mvnw.cmd` (not `./mvnw`).
- Environment variables: `$env:VAR_NAME`.
- No `&&` pipeline chaining — use `;` or `if ($?) { ... }` instead.
- No `2>&1` on native executables (wraps stderr as ErrorRecord in PS 5.1).

### macOS / Linux (darwin / linux)

- Use the **Bash tool**.
- Paths use forward slashes: `/home/user/project`.
- Maven wrapper: `./mvnw`.
- Environment variables: `$VAR_NAME`.
- Standard POSIX chaining (`&&`, `||`, `2>&1`) works normally.

---

## Path format quick reference

| Context | Windows | Unix |
|---|---|---|
| Project root | `D:\Lester\...\gastosai` | `/home/user/.../gastosai` |
| Backend | `backend\src\main\java\...` | `backend/src/main/java/...` |
| Frontend | `frontend\src\...` | `frontend/src/...` |
| Maven | `.\mvnw.cmd compile` | `./mvnw compile` |
| npm | `npm run dev` | `npm run dev` |

---

## Before running any command

1. Confirm the OS (session header, path style, or prior errors).
2. Select the correct tool (PowerShell vs Bash).
3. Use the correct path separator and executable names for that OS.
4. If uncertain, ask — do not guess and silently fail.
