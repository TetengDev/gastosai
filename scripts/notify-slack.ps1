<#
.SYNOPSIS
    Upload files (screenshots, videos, reports) + a summary message to a Slack channel.

.DESCRIPTION
    Used by the release-verification flow (see ai/skills/e2e-release-verification.md) to
    deliver E2E evidence to Slack. Uses the current Slack file-upload API:
    files.getUploadURLExternal -> POST bytes -> files.completeUploadExternal (one message,
    all attachments, with the summary as the initial comment).

    Reads SLACK_BOT_TOKEN and SLACK_CHANNEL_ID from the repo-root .env (gitignored).
    The Slack app/bot must have scopes `files:write` + `chat:write` and be invited to the
    target channel. Nothing is printed that reveals the token.

.PARAMETER Title
    Short headline for the Slack message.

.PARAMETER SummaryText
    Body text (markdown) posted as the upload's initial comment.

.PARAMETER Files
    One or more file paths to attach (png/webm/md/...).

.PARAMETER Channel
    Override channel id; defaults to SLACK_CHANNEL_ID from .env.

.EXAMPLE
    .\scripts\notify-slack.ps1 -Title "Slice B E2E" -SummaryText "All green" -Files a.png,b.webm
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$Title,
    [string]$SummaryText = "",
    [Parameter(Mandatory)] [string[]]$Files,
    [string]$Channel
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$envPath = Join-Path $root '.env'
function Get-EnvValue([string]$key) {
    if (-not (Test-Path $envPath)) { return $null }
    $line = Get-Content $envPath | Select-String "^$key=(.+)"
    if ($line) { return $line.Matches[0].Groups[1].Value.Trim() }
    return $null
}

$token = Get-EnvValue 'SLACK_BOT_TOKEN'
if (-not $Channel) { $Channel = Get-EnvValue 'SLACK_CHANNEL_ID' }

if (-not $token -or -not $Channel) {
    Write-Host "Slack not configured: set SLACK_BOT_TOKEN and SLACK_CHANNEL_ID in $envPath" -ForegroundColor Yellow
    Write-Host "Artifacts left on disk (not sent):" -ForegroundColor Yellow
    $Files | ForEach-Object { Write-Host "  $_" }
    exit 2
}

$headers = @{ Authorization = "Bearer $token" }
$uploaded = @()

foreach ($f in $Files) {
    if (-not (Test-Path $f)) { Write-Host "[skip] missing: $f" -ForegroundColor Yellow; continue }
    $item = Get-Item $f
    $name = $item.Name
    $len = $item.Length

    $u = Invoke-RestMethod -Method Get -Headers $headers `
        -Uri "https://slack.com/api/files.getUploadURLExternal?filename=$([uri]::EscapeDataString($name))&length=$len"
    if (-not $u.ok) { throw "getUploadURLExternal failed for ${name}: $($u.error)" }

    Invoke-RestMethod -Method Post -Uri $u.upload_url -InFile $f -ContentType 'application/octet-stream' | Out-Null
    $uploaded += @{ id = $u.file_id; title = $name }
    Write-Host "[ok] uploaded $name ($([math]::Round($len/1KB,1)) KB)" -ForegroundColor Green
}

if ($uploaded.Count -eq 0) { throw "No files were uploaded." }

$comment = if ($SummaryText) { "*$Title*`n$SummaryText" } else { "*$Title*" }
$body = @{
    files           = $uploaded
    channel_id      = $Channel
    initial_comment = $comment
} | ConvertTo-Json -Depth 6

$c = Invoke-RestMethod -Method Post -Headers $headers `
    -ContentType 'application/json; charset=utf-8' `
    -Uri "https://slack.com/api/files.completeUploadExternal" -Body $body
if (-not $c.ok) { throw "completeUploadExternal failed: $($c.error)" }

Write-Host "Sent $($uploaded.Count) file(s) to Slack channel $Channel." -ForegroundColor Green
