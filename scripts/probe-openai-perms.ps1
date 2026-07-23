# Probes what the OPENAI_API_KEY in .env (root or backend/.env) is allowed to do.
# The app only needs chat completions; everything else should be denied on a restricted key.
# Never prints the key.
$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $PSScriptRoot

$key = $null
foreach ($f in @("$root\.env", "$root\backend\.env")) {
    if (Test-Path $f) {
        $m = Get-Content $f | Select-String '^OPENAI_API_KEY=(.+)$'
        if ($m) { $key = $m.Matches[0].Groups[1].Value.Trim('"'); break }
    }
}
if (-not $key) { Write-Output "no OPENAI_API_KEY found"; exit 1 }
$headers = @{ Authorization = "Bearer $key" }

function Probe($name, $script) {
    try {
        & $script | Out-Null
        Write-Output ("{0}: ALLOWED" -f $name)
    } catch {
        $status = $null
        try { $status = $_.Exception.Response.StatusCode.value__ } catch {}
        Write-Output ("{0}: DENIED (http {1})" -f $name, $status)
    }
}

# 1. Chat completions (REQUIRED by the app)
$body = @{ model = "gpt-4o-mini"; messages = @(@{ role = "user"; content = "pong" }); max_tokens = 3 } | ConvertTo-Json -Depth 5
Probe "chat.completions (REQUIRED)" { Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" -Method Post -Headers $headers -ContentType "application/json" -Body $body -TimeoutSec 30 }

# 2. Models list (read scope - optional, harmless)
Probe "models.list (optional)" { Invoke-RestMethod -Uri "https://api.openai.com/v1/models" -Headers $headers -TimeoutSec 15 }

# 3-6. Should be DENIED on a properly restricted key
Probe "files.list (should be DENIED)" { Invoke-RestMethod -Uri "https://api.openai.com/v1/files" -Headers $headers -TimeoutSec 15 }
Probe "fine_tuning.jobs (should be DENIED)" { Invoke-RestMethod -Uri "https://api.openai.com/v1/fine_tuning/jobs" -Headers $headers -TimeoutSec 15 }
Probe "assistants.list (should be DENIED)" { Invoke-RestMethod -Uri "https://api.openai.com/v1/assistants" -Headers ($headers + @{ "OpenAI-Beta" = "assistants=v2" }) -TimeoutSec 15 }
Probe "images.generate (should be DENIED)" { Invoke-RestMethod -Uri "https://api.openai.com/v1/images/generations" -Method Post -Headers $headers -ContentType "application/json" -Body '{"model":"dall-e-2","prompt":"x","n":1,"size":"256x256"}' -TimeoutSec 30 }
