# Tests the OPENAI_API_KEY found in backend/.env (or root .env) with a minimal
# chat-completions call. Never prints the key.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

$key = $null
foreach ($f in @("$root\backend\.env", "$root\.env")) {
    if (Test-Path $f) {
        $m = Get-Content $f | Select-String '^OPENAI_API_KEY=(.+)$'
        if ($m) { $key = $m.Matches[0].Groups[1].Value.Trim('"'); break }
    }
}
if (-not $key) { Write-Output "RESULT: no OPENAI_API_KEY found in backend/.env or .env"; exit 1 }

$body = @{
    model = "gpt-4o-mini"
    messages = @(@{ role = "user"; content = "Reply with the single word: pong" })
    max_tokens = 5
} | ConvertTo-Json -Depth 5

try {
    $resp = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" -Method Post `
        -Headers @{ Authorization = "Bearer $key" } -ContentType "application/json" -Body $body
    Write-Output ("RESULT: OK model=" + $resp.model + " reply=" + $resp.choices[0].message.content.Trim())
} catch {
    $status = $_.Exception.Response.StatusCode.value__
    Write-Output "RESULT: FAILED http=$status"
    if ($_.ErrorDetails.Message) {
        $err = ($_.ErrorDetails.Message | ConvertFrom-Json).error
        Write-Output ("error.type=" + $err.type + " code=" + $err.code + " message=" + $err.message)
    }
    exit 1
}
