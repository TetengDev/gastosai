<#
.SYNOPSIS
    Run a gh CLI command with GH_TOKEN loaded from the repo-root .env.

.DESCRIPTION
    The sandbox blocks any single command that both reads .env and hits the network, so gh
    cannot be authenticated inline. This wrapper reads GITHUB_TOKEN internally (clean
    invocation line) and forwards all args to gh. The token is never printed.

.EXAMPLE
    .\scripts\gh.ps1 pr create --base master --head meta/x --title "..." --body-file b.md
#>
[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$gh = 'C:\Program Files\GitHub CLI\gh.exe'

$line = Get-Content (Join-Path $root '.env') | Select-String '^GITHUB_TOKEN=(.+)'
if (-not $line) { Write-Error 'GITHUB_TOKEN not found in .env'; exit 1 }
$env:GH_TOKEN = $line.Matches[0].Groups[1].Value.Trim()

& $gh @Args
