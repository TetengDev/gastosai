<#
.SYNOPSIS
    Send files (screenshots, videos, reports) + a summary message to a Telegram chat.

.DESCRIPTION
    Used by the release-verification flow (see ai/skills/e2e-release-verification.md) to
    deliver E2E evidence to Telegram via the Bot API. Posts a summary message, then each
    file (png/jpg -> sendPhoto, webm/mp4 -> sendVideo with sendDocument fallback,
    everything else -> sendDocument).

    Reads TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID from the repo-root .env (gitignored).
    Create the bot with @BotFather; get the chat id by messaging the bot then calling
    getUpdates, or via @userinfobot. Uses curl.exe for multipart uploads (works on
    Windows PowerShell 5.1). Nothing printed reveals the token.

.PARAMETER Title
    Short headline for the summary message.

.PARAMETER SummaryText
    Body text (Markdown) for the summary message.

.PARAMETER Files
    One or more file paths to send.

.PARAMETER Chat
    Override chat id; defaults to TELEGRAM_CHAT_ID from .env.

.EXAMPLE
    .\scripts\notify-telegram.ps1 -Title "Slice B E2E" -SummaryText "All green" -Files a.png,b.webm
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$Title,
    [string]$SummaryText = "",
    [Parameter(Mandatory)] [string[]]$Files,
    [string]$Chat,
    # Files larger than this are NOT uploaded — they stay on disk and a notice
    # (name + size + path) is posted instead. Telegram's bot upload ceiling is ~50 MB.
    [int]$MaxMB = 45
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

$token = Get-EnvValue 'TELEGRAM_BOT_TOKEN'
if (-not $Chat) { $Chat = Get-EnvValue 'TELEGRAM_CHAT_ID' }

if (-not $token -or -not $Chat) {
    Write-Host "Telegram not configured: set TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID in $envPath" -ForegroundColor Yellow
    Write-Host "Artifacts left on disk (not sent):" -ForegroundColor Yellow
    $Files | ForEach-Object { Write-Host "  $_" }
    exit 2
}

$api = "https://api.telegram.org/bot$token"

function Invoke-Telegram([string]$method, [string[]]$fields) {
    $args = @('-s', '-S', '-F', "chat_id=$Chat") + ($fields | ForEach-Object { @('-F', $_) }) + "$api/$method"
    $raw = & curl.exe @args
    return $raw | ConvertFrom-Json
}

# 1) Summary message
$text = if ($SummaryText) { "*$Title*`n$SummaryText" } else { "*$Title*" }
$msg = Invoke-Telegram 'sendMessage' @("text=$text", "parse_mode=Markdown")
if (-not $msg.ok) { throw "sendMessage failed: $($msg.description)" }

# Telegram plays H.264 MP4 inline but not VP8/VP9 WebM (Playwright records WebM).
# Transcode to MP4 first when ffmpeg is available, so recordings are playable in-app.
$ffmpeg = (Get-Command ffmpeg -ErrorAction SilentlyContinue).Source
if (-not $ffmpeg) {
    $wingetFf = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\ffmpeg.exe'
    if (Test-Path $wingetFf) { $ffmpeg = $wingetFf }
}

# 2) Files
$sent = 0
$noted = 0
foreach ($f in $Files) {
    if (-not (Test-Path $f)) { Write-Host "[skip] missing: $f" -ForegroundColor Yellow; continue }
    $ext = [System.IO.Path]::GetExtension($f).ToLowerInvariant()
    $name = Split-Path $f -Leaf
    $send = $f

    # Transcode WebM/MKV to MP4 (sibling of source, so oversized files persist on disk).
    if ($ext -in @('.webm', '.mkv')) {
        if ($ffmpeg) {
            $mp4 = Join-Path (Split-Path -Parent $f) ([System.IO.Path]::GetFileNameWithoutExtension($f) + '.mp4')
            & $ffmpeg -y -i $f -c:v libx264 -crf 23 -pix_fmt yuv420p -movflags +faststart -an $mp4 2>$null
            if (Test-Path $mp4) { $send = $mp4; $ext = '.mp4'; $name = Split-Path $mp4 -Leaf; Write-Host "[conv] -> $name" -ForegroundColor Cyan }
        } else {
            Write-Host "[warn] ffmpeg not found — sending $name as-is (may not preview in Telegram)" -ForegroundColor Yellow
        }
    }

    # Too large to upload: leave on disk, post a notice with name/size/path instead.
    $sizeMB = [math]::Round((Get-Item $send).Length / 1MB, 2)
    if ($sizeMB -gt $MaxMB) {
        $abs = (Resolve-Path $send).Path
        $note = "[file too large to send: $sizeMB MB] $name`nSaved locally: $abs"
        Invoke-Telegram 'sendMessage' @("text=$note") | Out-Null
        $noted++
        Write-Host "[note] $name is $sizeMB MB (> $MaxMB) — left on disk, path sent" -ForegroundColor Yellow
        continue
    }

    switch -Regex ($ext) {
        '\.(png|jpg|jpeg|gif)$' { $method = 'sendPhoto';    $field = 'photo' }
        '\.(webm|mp4|mov)$'     { $method = 'sendVideo';    $field = 'video' }
        default                  { $method = 'sendDocument'; $field = 'document' }
    }

    $r = Invoke-Telegram $method @("$field=@$send")
    if (-not $r.ok -and $method -ne 'sendDocument') {
        # Telegram can reject some video containers — fall back to a plain document.
        $r = Invoke-Telegram 'sendDocument' @("document=@$send")
    }
    if ($r.ok) { $sent++; Write-Host "[ok] sent $name" -ForegroundColor Green }
    else { Write-Host "[fail] $name : $($r.description)" -ForegroundColor Red }
}

if ($sent -eq 0 -and $noted -eq 0) { throw "No files were sent." }
Write-Host "Sent $sent file(s)$(if ($noted) { " + $noted noted (too large)" }) to Telegram chat $Chat." -ForegroundColor Green
