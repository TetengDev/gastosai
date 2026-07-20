<#
.SYNOPSIS
    Render an HTML card to PNG with headless Chromium (no browser window) and send it
    to Telegram as an inline photo.

.DESCRIPTION
    Replaces the headed Playwright-MCP path for status cards. Renders silently via
    scripts/render-card.mjs (uses @playwright/test's chromium in headless mode,
    resolved from frontend/node_modules), then delivers the PNG through
    scripts/notify-telegram.ps1 (sendPhoto).

.EXAMPLE
    .\scripts\send-card.ps1 -Html C:\tmp\card.html -Title "Build green" -Summary "All checks pass"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$Html,
    [string]$Png,
    [Parameter(Mandatory)] [string]$Title,
    [string]$Summary = '',
    [int]$Width = 800,
    [int]$Height = 600,
    [switch]$KeepFiles
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
if (-not $Png) { $Png = [System.IO.Path]::ChangeExtension($Html, '.png') }

# Render headless. node may write to stderr; under StrictMode/Stop that would abort,
# so relax error handling around the native call and gate on the exit code instead.
$prev = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
& node (Join-Path $root 'scripts/render-card.mjs') $Html $Png $Width $Height 2>&1 | Write-Host
$code = $LASTEXITCODE
$ErrorActionPreference = $prev
if ($code -ne 0) { throw "render-card.mjs failed ($code)" }
if (-not (Test-Path $Png)) { throw "render produced no PNG at $Png" }

& (Join-Path $root 'scripts/notify-telegram.ps1') -Title $Title -SummaryText $Summary -Files $Png

if (-not $KeepFiles) {
    Remove-Item $Png -ErrorAction SilentlyContinue
}
