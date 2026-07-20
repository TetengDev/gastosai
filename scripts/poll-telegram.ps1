<#
.SYNOPSIS
    Poll Telegram getUpdates and print new message text (counterpart to notify-telegram.ps1).

.DESCRIPTION
    Reads TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID from the repo-root .env (gitignored) and
    calls the Bot API getUpdates. Prints "<update_id>: <text>" for each message FROM THE
    TRUSTED CHAT ONLY — updates from any other chat are dropped unread and never acked, so
    a stranger who discovers the bot cannot inject text into the operator's console or
    solicit replies. The token is never printed. Use -Offset to acknowledge older updates
    (pass last_seen_update_id + 1).

.PARAMETER Offset
    getUpdates offset (last handled update_id + 1). Defaults to 0 (all buffered updates).

.PARAMETER NoAck
    Suppress the automatic "got it" acknowledgement. By default, whenever this poll
    finds one or more new messages it immediately sends a single ack back to the sender
    so the user knows the message was received and is being worked on (hard rule).

.EXAMPLE
    .\scripts\poll-telegram.ps1 -Offset 123456789
#>
[CmdletBinding()]
param(
    [long]$Offset = 0,
    [int]$TimeoutSec = 2,
    [switch]$NoAck
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
if (-not $token) { Write-Error 'TELEGRAM_BOT_TOKEN not found in .env'; exit 1 }
$trustedChat = Get-EnvValue 'TELEGRAM_CHAT_ID'
if (-not $trustedChat) { Write-Error 'TELEGRAM_CHAT_ID not found in .env'; exit 1 }

$uri = "https://api.telegram.org/bot$token/getUpdates?offset=$Offset&timeout=$TimeoutSec"
$resp = Invoke-RestMethod -Uri $uri -TimeoutSec ($TimeoutSec + 8)

# Only messages from the trusted chat are read or answered. Anything else is dropped
# without printing its text (untrusted input) and without an ack (no reply oracle).
$trusted = @($resp.result | Where-Object { $_.message -and "$($_.message.chat.id)" -eq $trustedChat })
$dropped = @($resp.result).Count - $trusted.Count
if ($dropped -gt 0) { Write-Warning "$dropped update(s) from untrusted chat(s) dropped" }

# Auto-ack (hard rule): the instant we read new message(s), tell the sender it landed
# and is being worked on — so acknowledgement never depends on the caller remembering.
# One ack per poll batch, best-effort (a Telegram hiccup must not fail the poll).
if (-not $NoAck -and $trusted.Count -gt 0) {
    try {
        $ackBody = @{ chat_id = $trustedChat; text = 'Got it - working on it.' }
        Invoke-RestMethod -Uri "https://api.telegram.org/bot$token/sendMessage" `
            -Method Post -Body $ackBody -TimeoutSec 10 | Out-Null
    } catch {
        Write-Warning "ack send failed (continuing): $($_.Exception.Message)"
    }
}

foreach ($u in $trusted) {
    "$($u.update_id): $($u.message.text)"
}
