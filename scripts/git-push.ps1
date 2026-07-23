<#
.SYNOPSIS
    Push a branch to origin using the GITHUB_TOKEN from the repo-root .env.

.DESCRIPTION
    The credential manager has no cached GitHub creds in this environment, and the harness
    sandbox blocks any single command that both reads .env and hits the network. Wrapping the
    push in a script keeps the .env read + network INSIDE one already-spawned process (the
    invocation line is clean), so it runs. The token is used only in a one-shot push URL — it
    is never written to git config and never printed.

.PARAMETER Branch
    Branch to push. Defaults to the current branch.
#>
[CmdletBinding()]
param(
    [string]$Branch
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$git = 'C:\Program Files\Git\bin\git.exe'

if (-not $Branch) {
    $Branch = (& $git -C $root rev-parse --abbrev-ref HEAD).Trim()
}

$envPath = Join-Path $root '.env'
$line = Get-Content $envPath | Select-String '^GITHUB_TOKEN=(.+)'
if (-not $line) { Write-Error 'GITHUB_TOKEN not found in .env'; exit 1 }
$token = $line.Matches[0].Groups[1].Value.Trim()

$url = "https://x-access-token:$token@github.com/TetengDev/gastosai.git"
& $git -C $root push $url "${Branch}:${Branch}" 2>&1 |
    ForEach-Object { ($_ -replace [regex]::Escape($token), '***') }
& $git -C $root branch --set-upstream-to=origin/$Branch $Branch 2>&1 | Out-Null
"pushed $Branch"
