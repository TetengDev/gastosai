<#
.SYNOPSIS
    Lists merged remote branches and deletes them with explicit per-branch confirmation.

.DESCRIPTION
    Fetches all remote branches, identifies those whose PRs are merged (via GitHub API),
    excludes master and release/* branches, and prompts for deletion of each candidate.

.PARAMETER Force
    Skip confirmation prompt and delete all merged branches automatically.
    Use with caution — you will not be asked.

.EXAMPLE
    .\scripts\cleanup-branches.ps1
    .\scripts\cleanup-branches.ps1 -Force
#>
param(
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$envFile = Join-Path (Split-Path $PSScriptRoot -Parent) ".env"
if (Test-Path $envFile) {
    $token = Get-Content $envFile | Select-String "GITHUB_TOKEN=(.+)" | ForEach-Object { $_.Matches[0].Groups[1].Value }
    if ($token) { $env:GH_TOKEN = $token }
}
if (-not $env:GH_TOKEN) {
    Write-Error "GH_TOKEN not set and not found in .env. Set it before running this script."
    exit 1
}

$headers = @{
    Authorization       = "Bearer $env:GH_TOKEN"
    Accept              = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}

function Invoke-GH($path) {
    Invoke-RestMethod -Uri "https://api.github.com$path" -Headers $headers
}

Write-Host "`nFetching branches from remote..." -ForegroundColor Cyan

$repo = "TetengDev/gastosai"
$allBranches = Invoke-GH "/repos/$repo/branches?per_page=100" | ForEach-Object { $_.name }

$protected = @("master")
$candidates = $allBranches | Where-Object {
    $b = $_
    $b -ne "master" -and $b -notmatch "^release/"
}

if (-not $candidates) {
    Write-Host "No candidate branches found (only master and release/* exist)." -ForegroundColor Green
    exit 0
}

Write-Host "`nChecking PR merge status for $($candidates.Count) branch(es)..." -ForegroundColor Cyan

$toDelete = @()
foreach ($branch in $candidates) {
    $prs = Invoke-GH "/repos/$repo/pulls?head=TetengDev:$([Uri]::EscapeDataString($branch))&state=closed&per_page=5"
    $merged = $prs | Where-Object { $_.merged_at -ne $null }
    if ($merged) {
        $pr = $merged | Sort-Object merged_at -Descending | Select-Object -First 1
        $toDelete += [PSCustomObject]@{
            Branch   = $branch
            PR       = "#$($pr.number)"
            MergedAt = ([datetime]$pr.merged_at).ToString("yyyy-MM-dd")
            Title    = $pr.title.Substring(0, [Math]::Min(60, $pr.title.Length))
        }
    }
}

if (-not $toDelete) {
    Write-Host "`nNo merged branches found that are safe to delete." -ForegroundColor Green
    exit 0
}

Write-Host "`nMerged branches eligible for deletion:" -ForegroundColor Yellow
Write-Host ("-" * 70)
$toDelete | Format-Table Branch, PR, MergedAt, Title -AutoSize
Write-Host ("-" * 70)
Write-Host "Protected (never deleted): master, release/*" -ForegroundColor DarkGray
Write-Host ""

$deleted = 0
$skipped = 0

foreach ($item in $toDelete) {
    if ($Force) {
        $answer = "y"
    } else {
        $answer = Read-Host "Delete '$($item.Branch)' (merged via $($item.PR) on $($item.MergedAt))? [y/N]"
    }

    if ($answer -eq "y" -or $answer -eq "Y") {
        try {
            Invoke-RestMethod -Method DELETE -Uri "https://api.github.com/repos/$repo/git/refs/heads/$([Uri]::EscapeDataString($item.Branch))" -Headers $headers | Out-Null
            Write-Host "  Deleted: $($item.Branch)" -ForegroundColor Green
            $deleted++
        } catch {
            Write-Host "  Failed to delete $($item.Branch): $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  Skipped: $($item.Branch)" -ForegroundColor DarkGray
        $skipped++
    }
}

Write-Host "`nDone. Deleted: $deleted  Skipped: $skipped" -ForegroundColor Cyan
