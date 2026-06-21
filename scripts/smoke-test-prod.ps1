<#
.SYNOPSIS
    Post-deploy smoke test for the gastosai backend. Verifies the externally
    observable 0.46.0 security-hardening behaviors are live in production.

.DESCRIPTION
    Read-only verifier. Probes only non-destructive, externally observable
    behavior:
      1. Health   -- GET /actuator/health returns 200 / status UP.
      2. F-09     -- HSTS, CSP, Referrer-Policy, X-Content-Type-Options headers.
      3. F-05     -- public-endpoint throttle returns 429 (opt-in, see -IncludeRateLimit).
    Auth/data-gated checks (F-02, F-03, F-07, F-10, F-14) cannot be probed
    without prod credentials, so they are printed as a manual checklist.

    Exit code is 0 when every automated check passes, 1 otherwise.

.PARAMETER BaseUrl
    Backend origin, e.g. https://gastosai.duckdns.org (trailing slash trimmed).

.PARAMETER PublicRateLimit
    Expected per-minute public throttle, mirroring PUBLIC_RATE_LIMIT_PER_MINUTE
    (default 10). Drives how many requests the -IncludeRateLimit probe sends.

.PARAMETER IncludeRateLimit
    Run the F-05 throttle probe. Off by default because it sends bogus
    /auth/login POSTs (pollutes logs and trips the limiter for ~1 minute).

.EXAMPLE
    .\scripts\smoke-test-prod.ps1 -BaseUrl https://gastosai.duckdns.org

.EXAMPLE
    .\scripts\smoke-test-prod.ps1 -BaseUrl https://gastosai.duckdns.org -IncludeRateLimit
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$BaseUrl,
    [int]$PublicRateLimit = 10,
    [switch]$IncludeRateLimit
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$base = $BaseUrl.TrimEnd('/')
$failures = 0

function Write-Result {
    param([bool]$Ok, [string]$Name, [string]$Detail = '')
    $tag = if ($Ok) { 'PASS' } else { 'FAIL' }
    $color = if ($Ok) { 'Green' } else { 'Red' }
    $line = "[$tag] $Name"
    if ($Detail) { $line += " -- $Detail" }
    Write-Host $line -ForegroundColor $color
    if (-not $Ok) { $script:failures++ }
}

Write-Host "Smoke test against $base" -ForegroundColor Cyan
Write-Host ('-' * 60)

# --- Check 1 + 2: health + security headers (single request) ---
$healthResp = $null
try {
    $healthResp = Invoke-WebRequest -Uri "$base/actuator/health" -Method Get -UseBasicParsing -TimeoutSec 30
} catch {
    Write-Result $false 'Health (GET /actuator/health)' $_.Exception.Message
}

if ($null -ne $healthResp) {
    $healthOk = ($healthResp.StatusCode -eq 200) -and ($healthResp.Content -match '"status"\s*:\s*"UP"')
    Write-Result $healthOk 'Health (GET /actuator/health)' "HTTP $($healthResp.StatusCode)"

    $headers = $healthResp.Headers
    function Get-Header {
        param([string]$Key)
        foreach ($k in $headers.Keys) {
            if ($k -ieq $Key) { return [string]$headers[$k] }
        }
        return $null
    }

    $hsts = Get-Header 'Strict-Transport-Security'
    Write-Result ([bool]($hsts -and $hsts -match 'max-age=31536000' -and $hsts -match 'includeSubDomains')) `
        'F-09 HSTS' $hsts

    $csp = Get-Header 'Content-Security-Policy'
    Write-Result ([bool]($csp -and $csp -match "default-src 'self'")) `
        'F-09 CSP' $csp

    $ref = Get-Header 'Referrer-Policy'
    Write-Result ([bool]($ref -and $ref -match 'no-referrer')) `
        'F-09 Referrer-Policy' $ref

    $nosniff = Get-Header 'X-Content-Type-Options'
    Write-Result ([bool]($nosniff -and $nosniff -match 'nosniff')) `
        'F-09 X-Content-Type-Options' $nosniff
}

# --- Check 3: public-endpoint throttle (opt-in) ---
if ($IncludeRateLimit) {
    $attempts = $PublicRateLimit + 2
    $body = '{"email":"smoketest@invalid.example","password":"x"}'
    $saw429 = $false
    $codes = @()
    for ($i = 1; $i -le $attempts; $i++) {
        try {
            $r = Invoke-WebRequest -Uri "$base/auth/login" -Method Post `
                -ContentType 'application/json' -Body $body -UseBasicParsing -TimeoutSec 30
            $codes += [int]$r.StatusCode
        } catch {
            $resp = $_.Exception.Response
            if ($null -ne $resp -and $resp.PSObject.Properties.Name -contains 'StatusCode') {
                $code = [int]$resp.StatusCode
                $codes += $code
                if ($code -eq 429) { $saw429 = $true }
            } else {
                $codes += -1
            }
        }
    }
    Write-Result $saw429 "F-05 public throttle (429 within $attempts POSTs)" ("codes: " + ($codes -join ','))
} else {
    Write-Host "[SKIP] F-05 public throttle -- pass -IncludeRateLimit to probe" -ForegroundColor Yellow
}

# --- Manual checklist (auth/data-gated) ---
Write-Host ''
Write-Host 'Manual checks (need login / data -- not auto-probed):' -ForegroundColor Cyan
Write-Host "  F-02 CSV injection : create expense described =cmd|'/c calc'!A1, export CSV -> cell starts with '"
Write-Host '  F-03 absolute quota: user at AI_ABSOLUTE_MONTHLY_CAP gets 429 even in BYOK mode'
Write-Host '  F-07 JWT TTL       : decode a fresh token -> exp-iat ~= 8h (28800000 ms)'
Write-Host '  F-10 error leakage : force AI insight 500 -> generic "Failed to generate insight. Please try again later."'
Write-Host '  F-14 fail-fast     : already proven -- a clean prod boot means non-default secrets are set'

Write-Host ('-' * 60)
if ($failures -eq 0) {
    Write-Host 'All automated checks passed.' -ForegroundColor Green
    exit 0
} else {
    Write-Host "$failures automated check(s) FAILED." -ForegroundColor Red
    exit 1
}
