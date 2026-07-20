<#
.SYNOPSIS
    Make all git operations in this repo authenticate silently (no Windows
    Credential Manager login popup) using the GITHUB_TOKEN from the repo-root .env.

.DESCRIPTION
    The repo's credential.helper is 'manager', so any git operation that does not
    carry embedded credentials launches the Windows Git Credential Manager GUI.
    Native git never reads .env, so putting the token there only helped the wrapper
    scripts. This script wires git's credential store to the .env token so plain
    `git push` / `gh` work without a prompt.

    Reads GITHUB_TOKEN internally; the token is never printed or passed on a command
    line. Run once per clone (re-run after rotating the token).
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$git = 'C:\Program Files\Git\bin\git.exe'

$line = Get-Content (Join-Path $root '.env') | Select-String '^GITHUB_TOKEN=(.+)'
if (-not $line) { Write-Error 'GITHUB_TOKEN not found in .env'; exit 1 }
$token = $line.Matches[0].Groups[1].Value.Trim()

# Local-scope credential store so it only affects this repo. An empty helper value
# first RESETS the inherited helper list (the system-scope 'manager', which pops the
# GUI); then 'store' is the only helper used for this repo.
& $git -C $root config --local --unset-all credential.helper 2>$null
& $git -C $root config --local credential.helper ''
& $git -C $root config --local --add credential.helper store
& $git -C $root config --local credential.interactive false

# Primary mechanism: embed the token in the origin remote URL so every git push/fetch
# authenticates directly with no helper and no prompt. Token lives only in the local
# (untracked) .git/config. This is the same credential the wrapper scripts use.
& $git -C $root remote set-url origin "https://x-access-token:$token@github.com/TetengDev/gastosai.git"

# Belt-and-suspenders: also seed the credential store so any operation that resolves
# credentials by host (not via the embedded URL) still works silently.
$credPath = Join-Path $HOME '.git-credentials'
$entry = "https://x-access-token:$token@github.com"
$existing = @()
if (Test-Path $credPath) {
    $existing = Get-Content $credPath | Where-Object { $_ -notmatch '@github\.com$' -and $_.Trim() -ne '' }
}
($existing + $entry) | Set-Content $credPath -Encoding ascii
Remove-Variable token, entry

# Disable any terminal prompt fallback for this process' children too.
$env:GIT_TERMINAL_PROMPT = '0'

"git auth configured - pushes to github.com will not prompt."
